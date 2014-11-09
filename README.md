ZellyLuas
=========
  
Luas created by zelly.  
  
  
Zelly XpSave Lua
================
This is a simple flatfile xpsave using JSON  
Built for the etlegacy rc4  
It was made for jemstar <3  
  
To use it:  
1. Download ZXpSave.lua and move it to fs_basepath/legacy/ZXpSave.lua  
2. Download JSON.lua from http://regex.info/blog/lua/json and move it to fs_basepath/legacy/JSON.lua  
3. add "ZXpSave.lua" to your lua_modules. ( set lua_modules "ZXpSave.lua" )  
4. Start server. Should save.  
  
Configuring:  
`local _saveTime      = 30` Seconds in between each runframe save  
`local _printDebug    = false` If you want to print to console  
`local _logPrintDebug = false` If you want it to log to server log ( Requires _printDebug = true )  
`local _logDebug      = true` If you want it to log to xpsave.log  
`local _logStream     = true` If you want it to update xpsave.log every message, false if just at end of round. ( Requires _logDebug = true )  
  
Zelly VoiceChat Debug
=====================
This was just built to debug voicechat because we were having troubles with it   
`local _StreamFile = true`    -- If you want it to save after each new log, then set this true, false saves at end of round  
`local _PrintChat  = false`   -- Set to true if you want to debug while your ingame, probably more useful now that I think about it  
  
Zelly Info
==========
Logs certain a bunch of info to json file  
Was planning on just interpretting it in python or something to see where the majority of players are from and what they generally are doing while they are ingame.  
Not complete yet  

Zelly Print Global
==================
Prints luas global variables for et  
Also tested some chargetimes in this lua  
