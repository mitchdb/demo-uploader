SOURCEMOD=../sourcemod/sourcemod-1.5.0-hg3832/addons/sourcemod/scripting
CURL=../sourcemod/curl/scripting/include
PLUGINS=addons/sourcemod/plugins
SCRIPTING=addons/sourcemod/scripting

compile: clean
	$(SOURCEMOD)/spcomp $(SCRIPTING)/mitchdb_demo_uploader.sp -o$(PLUGINS)/mitchdb_demo_uploader.smx -i$(SCRIPTING) -i$(SOURCEMOD)/include -i$(CURL) -v2

clean:
	rm -f $(PLUGINS)/mitchdb_demo_uploader.smx

zip: compile
	rm -f mitchdb_demo_uploader.zip
	zip -r mitchdb_demo_uploader.zip $(PLUGINS)/mitchdb_demo_uploader.smx

tag: compile
	# git tag -a v2.0.0 -m "Version 2.0.0"
	# git push --tags