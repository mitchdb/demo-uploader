# MitchDB Demo Upload SourceMod Plugin
This plugin lets players to submit a demo for admin review.


## Requirements
* A [MitchDB](http://www.mitchdb.com/) account with at least one server added.
* [SourceMod](http://www.sourcemod.net/)
* [sourcemod-curl-extension](http://code.google.com/p/sourcemod-curl-extension/)



## Configuration
This plugin requires the following console variables to be specified:

* `mdb_apikey` - This should be set to your MitchDB API Key.
  * You can obtain this key by accessing your account and clicking on the "Servers" tab.
* `mdb_apisecret` - This should be set to your MitchDB API Secret. 
  * You can obtain this by accessing your account and clicking on the "Servers" tab.
* `mdb_serverid` - This should be the MitchDB server ID for the server you are using.
  * Each server in your account has a different ID.

### Player Commands
* `mdb_upload_demo <DemoFile>` - This will submit the demo file for review. This might take some time depending on how big the demo is.


## Help & Support
If you have trouble with this plugin, please contact MitchDB support. If you find bugs/issues with this plugin, feel free to [submit an issue](https://github.com/mitchdb/demo-uploader/issues) to the GitHub issue tracker.

## Development
You can use `make compile` to compile the plugin. If you want to create a Zip archive to install on your game server, you can run `make zip` which will create a zip archive inside the root folder.
