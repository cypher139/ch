#!/bin/sh

java --add-opens java.base/java.lang.reflect=ALL-UNNAMED --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.util=ALL-UNNAMED --add-opens java.prefs/java.util.prefs=ALL-UNNAMED -Xrs -jar commandhelper.jar cmdline MethodScript/LocalPackages/Chat/CoreStartup.ms 

