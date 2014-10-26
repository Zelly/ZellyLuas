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
  
Optional: Two Variables at the top of the determine the output of the lua  
`local _printDebug = false` true if you want it to print to console | false if not  
`local _logDebug   = false` true if you want it to log to server log | false if not ( Requires _printDebug = true )  
