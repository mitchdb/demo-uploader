#pragma semicolon 1
#include <sourcemod>
#include <cURL>

// TODO: This should post to a different API endpoint. 
// Or it should request a set of upload params to send to S3


#define VERSION "1.0.0"

// Define some max string sizes
#define APIKEY_SIZE 33
#define APISECRET_SIZE 33

// API ENDPOINTS
#define MDB_URL_DEMO        "http://api.mitchdb.net/api/v2/demo"

public Plugin:myinfo = 
{
  name = "MitchDB Demo Uploader",
  author = "Mitch Dempsey (WebDestroya)",
  description = "MitchDB.com Demo Uploader",
  version = VERSION,
  url = "http://www.mitchdb.com/"
};

new CURL_Default_opt[][2] = {
  {_:CURLOPT_NOSIGNAL,1},
  {_:CURLOPT_NOPROGRESS,1},
  {_:CURLOPT_TIMEOUT,40},
  {_:CURLOPT_CONNECTTIMEOUT,30},
  {_:CURLOPT_VERBOSE,0}
};

#define CURL_DEFAULT_OPT(%1) curl_easy_setopt_int_array(%1, CURL_Default_opt, sizeof(CURL_Default_opt))

// Console variables
new Handle:convar_mdb_apikey = INVALID_HANDLE; // ApiKey Console Variable
new Handle:convar_mdb_apisecret = INVALID_HANDLE; // Api Secret Console Variable
new Handle:convar_mdb_serverid = INVALID_HANDLE; // ServerID Console Variable

new bool:is_recording = false;
new String:demoPath[PLATFORM_MAX_PATH];

public OnPluginStart() {

  convar_mdb_apikey = CreateConVar("mdb_apikey", "none", "The API key used to communicate with MitchDB", FCVAR_PROTECTED);
  convar_mdb_apisecret = CreateConVar("mdb_apisecret", "none", "The API secret used to communicate with MitchDB", FCVAR_PROTECTED);
  convar_mdb_serverid = CreateConVar("mdb_serverid", "0", "The MitchDB ServerID for this server.", FCVAR_PROTECTED);
  
  AddCommandListener(Listener_Record, "tv_record");
  AddCommandListener(Listener_StopRecord, "tv_stoprecord");
}

public OnMapStart() {
  if(GetConVarValueInt("tv_enable") != 1) {
    SetFailState("SourceTV System is disabled.");
    return;
  }

  is_recording = false;
}

// Reload Admin List
public Action:Listener_Record(client, const String:command[], argc) {
  if(is_recording) {
    return;
  }

  GetCmdArg(1, demoPath, sizeof(demoPath));

  if(!StrEqual(demoPath, "")) {
    is_recording = true;
  }
  
  if(strlen(demoPath) < 4 || strncmp(demoPath[strlen(demoPath)-4], ".dem", 4, false) != 0) {
    Format(demoPath, sizeof(demoPath), "%s.dem", demoPath);
  }
}

// Request completed, so update the admin cache
public Action:Listener_StopRecord(client, const String:command[], argc) {
  if(!is_recording) {
    return;
  }

  new Handle:dataPack = CreateDataPack();
  CreateDataTimer(5.0, Timer_UploadDemo, dataPack);
  WritePackString(dataPack, demoPath);

  is_recording = false;
}

public Action:Timer_UploadDemo(Handle:timer, Handle:dataPack) {
  ResetPack(dataPack);

  decl String:tmpDemoPath[PLATFORM_MAX_PATH];
  ReadPackString(dataPack, tmpDemoPath, sizeof(tmpDemoPath));

  new Handle:curl = curl_easy_init();
  if(curl == INVALID_HANDLE) {
    CurlError("admin group list");
    return Plugin_Handled;
  }

  CURL_DEFAULT_OPT(curl);

  decl String:apikey[APIKEY_SIZE];
  decl String:apisecret[APISECRET_SIZE];
  decl String:serverid[11];
  decl String:servertime[11];
  decl String:sig_request[256];
  decl String:signature[128];
  
  Format(servertime, sizeof(servertime), "%d", GetTime());
  GetConVarString(convar_mdb_apikey, apikey, sizeof(apikey));
  GetConVarString(convar_mdb_apisecret, apisecret, sizeof(apisecret));
  GetConVarString(convar_mdb_serverid, serverid, sizeof(serverid));
  
  new Handle:demo_upload_form = curl_httppost();
  curl_formadd(demo_upload_form, CURLFORM_COPYNAME, "api_key", CURLFORM_COPYCONTENTS, apikey, CURLFORM_END);
  curl_formadd(demo_upload_form, CURLFORM_COPYNAME, "server_id", CURLFORM_COPYCONTENTS, serverid, CURLFORM_END);
  curl_formadd(demo_upload_form, CURLFORM_COPYNAME, "servertime", CURLFORM_COPYCONTENTS, servertime, CURLFORM_END);
  curl_formadd(demo_upload_form, CURLFORM_COPYNAME, "demofile", CURLFORM_FILE, tmpDemoPath, CURLFORM_END);
  // Signature
  Format(sig_request, sizeof(sig_request), "%s%s%s%s", apisecret, apikey, servertime, serverid);
  curl_hash_string(sig_request, strlen(sig_request), Openssl_Hash_SHA1, signature, sizeof(signature));

  // add the signature to the request
  curl_formadd(demo_upload_form, CURLFORM_COPYNAME, "signature", CURLFORM_COPYCONTENTS, signature, CURLFORM_END);

  curl_easy_setopt_string(curl, CURLOPT_URL, MDB_URL_DEMO);
  curl_easy_setopt_handle(curl, CURLOPT_HTTPPOST, demo_upload_form);

  curl_easy_perform_thread(curl, onDemoUploadCompleted, demo_upload_form);

  return Plugin_Handled;
}

// Request completed, so update the admin cache
public onDemoUploadCompleted(Handle:hndl, CURLcode: code, any:demo_upload_form) {
  // close the handle
  CloseHandle(demo_upload_form);

  if(code != CURLE_OK) {
    Format(demoPath, sizeof(demoPath), "");
    CurlFailure("demo upload", code);
    CloseHandle(hndl);
    return;
  }

  // find out the response code from the server
  new responseCode;
  curl_easy_getinfo_int(hndl, CURLINFO_RESPONSE_CODE, responseCode);
  CloseHandle(hndl);

  if(responseCode == 201) {
    // clear the demo file
    DeleteFile(demoPath);

    LogToGame("[MitchDB] Successfully uploaded demo '%s' to MitchDB", demoPath);
  } else {
    LogToGame("[MitchDB] Failed to upload demo '%s' to MitchDB. (HTTP %d)", demoPath, responseCode);
  }

  // reset the file name
  Format(demoPath, sizeof(demoPath), "");
}



/////// UTILS

stock CurlError(const String:info[]) {
  LogToGame("[MitchDB] ERROR: Unable to create cURL resource. (%s)", info);
}

stock CurlFailure(const String:info[], CURLcode:code) {
  if(code == CURLE_COULDNT_RESOLVE_HOST) {
    LogToGame("[MitchDB] ERROR: Network error contacting API. [unable to resolve host] (%s)", info);
  } else if(code==CURLE_OPERATION_TIMEDOUT) {
    LogToGame("[MitchDB] ERROR: Network error contacting API. [timed out] (%s)", info);
  } else {
    LogToGame("[MitchDB] ERROR: Network error contacting API. [curlcode=%d] (%s)", code, info);
  }
}


public GetConVarValueInt(const String:sConVar[]) {
  new Handle:hConVar = FindConVar(sConVar);
  new iResult = GetConVarInt(hConVar);
  CloseHandle(hConVar);
  return iResult;
}