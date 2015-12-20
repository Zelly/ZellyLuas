--[[
Modified by Klassifyed
Forked from Zelly's JSON Legacy Mod XpSave Lua
Evolve : ZellyEllyBear
Steam  : ZellyElly
Mygamintalk.com : Zelly
Etlegacy : Zelly
Made for jemstar <3
Feel free to report problems to me
https://github.com/Zelly/ZellyLuas for latest version
Get JSON.lua from http://regex.info/blog/lua/json
Looks for JSON.lua in fs_basepath/fs_game/JSON.lua
xpsave.json saves to fs_homepath/fs_game/xpsave.json
To find fs_basepath , fs_homepath , and fs_game type them in the server console or rcon
Lua module version 7.2
Compatiable with ET:Legacy 2.74
Modified in Sublime Text 3 - Tab Size: 2
--]]
local scriptName = "Zelly's JSON Legacy Mod XpSave Lua"
local version = "7.1"

--[[
Version 7.1
    FIX:    Skills lost after restart of map or starting match but XP remained correct,
            selecting a class and joining game cause skills to appear, and on map,
            restart, selecting a new class caused skills to appear, moving _loadXp
            to function et_ClientConnect corrected the issue
    FIX:    Issue of sess.skillpoints being stored as decimal values instead of whole numbers
            this caused et.G_XP_set to only grant the first stat BATTLESENSE -- float error resolved
    UPD:    Cleaned up code for efficiency (IMO)
    ADD:    Server XP reset timer using server admin variable XP_RESET_FLAG -- In Progress
    ADD:    Reset XP command !resetxp
    ADD:    Load XP command !loadxp
    ADD:    Advertise players command !players
Version 7
    ADD:    option to disable xpsave for bots
    ADD:    option for max xp
Version 6
    FIX:    everything that i added in version 4 and 5 :P
Version 5.1:
    FIX:    _saveLog nil i think
Version 5: 
    FIX:    Client saving 0 when client crash
    ADD:    Seperate log saving
    ADD:    Version 4 added a _saveAllXp function that runs every _saveTime seconds
    BUG:    Version 3 and below Xp will not save on shutdown
--]]

--[[
        USER EDITABLE VARIABLES - Server Admin Section
--]]
local XP_RESET_FLAG     = 4     -- Number in weeks to do a Server Wide XP Reset (UNDER CONSTRUCTION)

local _saveTime         = 30    -- Seconds in between each runframe save
local _printDebug       = false -- If you want to print to console
local _logPrintDebug    = false -- If you want it to log to server log ( Requires _printDebug = true )
local _logDebug         = true  -- If you want it to log to xpsave.log
local _logStream        = true  -- If you want it to update xpsave.log every message, false if just at end of round. ( Requires _logDebug = true )
local _xpSaveForBots    = false -- If you want to save xp for bots

--[[
        DO NOT MODIFY REMAINDER OF SCRIPT
--]]
local readPath          = string.gsub(et.trap_Cvar_Get("fs_basepath") .. "/" .. et.trap_Cvar_Get("fs_game") .. "/","\\","/")
local writePath         = string.gsub(et.trap_Cvar_Get("fs_homepath") .. "/" .. et.trap_Cvar_Get("fs_game") .. "/","\\","/")

local JSON              = (loadfile(readPath .. "JSON.lua"))()

local XP_FILE           = writePath .. "xpsave.json" -- If you want you can replace writePath with readPath here I think
local XP_LOGFILE        = writePath .. "xpsave.log"

local BATTLESENSE       = 0
local ENGINEERING       = 1
local MEDIC             = 2
local FIELDOPS          = 3
local LIGHTWEAPONS      = 4
local HEAVYWEAPONS      = 5
local COVERTOPS         = 6

--[[
        DATE CONSTANTS -- UNDER CONSTRUCTION
--]]
local DATE_EPOCH        = os.time()
local WEEK              = 604800   -- ( 60 * 60 * 24 * 7 )

local XP                = { }
local LogFile           = { }

--[[
        SCRIPT FUNCTIONS
--]]
function _saveLog ()
    if ( LogFile ~= nil ) or ( next(LogFile) ~= nil ) then
        local FileObject = io.open(XP_LOGFILE, "a")
        for k=1, #LogFile do
            FileObject:write(LogFile[k].."\n")
        end
        FileObject:close()
        LogFile = { }
    end
end

function _print (msg)
    if ( msg ~= nil ) then
        msg = et.Q_CleanStr(msg)
        if ( string.len(msg) >= 1 ) then
            if ( _logPrintDebug ) then
                et.G_LogPrint("ZXPSAVE: " .. msg .. "\n")
            elseif ( _printDebug ) then
                et.G_Print("ZXPSAVE: " .. msg .. "\n")
            end
            if ( _logDebug ) then
                LogFile[#LogFile+1] = os.date("[%X]") .. " " .. msg
                if ( _logStream ) then
                    _saveLog()
                end
            end
        end
    end
end

function _write ()
    _print("_write() XP(".. tostring(XP) .. ") XP_FILE(" .. tostring(XP_FILE) .. ")")
    local xp_encoded = JSON:encode_pretty(XP)
    local FileObject = io.open(XP_FILE, "w")
    FileObject:write(xp_encoded)
    FileObject:close()
end

function _read ()
    _print("_read() XP(" .. tostring(XP) .. ") XP_FILE(" .. tostring(XP_FILE) .. ")")
    local status, FileObject = pcall(io.open, XP_FILE, "r")
    _print("_read() FileObject(" .. tostring(FileObject) .. ")")
    if ( status ) and ( FileObject ~= nil ) then
        local fileData = { }
        for line in FileObject:lines() do
            if ( line ~= nil ) and ( line ~= "" ) then
                fileData[#fileData+1] = line
            end
        end
        FileObject:close()
        _print("_read() Successfully read " .. tostring(#fileData) .. " lines from " .. tostring(XP_FILE))
        return JSON:decode( table.concat(fileData,"\n") )  
    else
        _print("_read() " .. tostring(XP_FILE) .. " not found. Will be created on next shutdown")
        return { }
    end
end

function _message (pos, text, cno)
    et.trap_SendServerCommand((cno or -1), pos .. " \"" .. text .. "\n\"")
end

function _getGUID (clientNum)
    return et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "cl_guid")
end

function _validateGUID (clientNum, guid)
    -- allow only alphanumeric characters in guid
    if ( guid == nil ) or ( string.match(guid, "%W") ) or ( string.lower(guid) == "no_guid" ) or ( string.lower(guid) == "unknown" ) or ( string.len(guid) < 32 ) then -- Invalid characters detected.
        _print("_validateGUID Client(" .. tostring(clientNum) .. ") has an invalid guid(" .. tostring(guid) .. ") will not store xp for player")
        _message("cp", "^1WARNING: ^7Your XP won't be saved because you have an invalid cl_guid.", clientNum)
        return false
    end
    _print("_validateGUID Client(" .. tostring(clientNum) .. ") has a valid guid(" .. tostring(guid) .. ")")
    return true
end

-- This function was added by Klassifyed to identify OMNIBOT GUIDs
function _trackOmniBotXP (clientNum)
    local guid = _getGUID(clientNum)
    -- Verify if server admin wants to track XP for OmniBots
    if string.match( tostring(guid), "OMNIBOT" ) then
        return _xpSaveForBots -- server admin editable boolean variable at top of script
    end
    return true
end

function _setSkillPoints (clientNum, guid, skillNum)
    local sp = math.floor(et.gentity_get(clientNum, "sess.skillpoints", skillNum)) -- math.floor correct float error, rounding the number produces inaccurate XP
    if ( sp > XP[guid].skills[skillNum+1] ) then -- sp should always be equal to or greater than
        XP[guid].skills[skillNum+1] = sp
    end
end

function _resetXp (clientNum)
    local guid = _getGUID(clientNum)
    if ( _validateGUID(clientNum, guid) ) then
        _print("_resetXp Client(" .. tostring(clientNum) .. ") guid(" .. tostring(guid) .. ")")
        for k=BATTLESENSE+1, COVERTOPS+1 do
            XP[guid].skills[k] = 0
        end
        _print("_resetXp (" .. tostring(guid) .. ") " .. tostring(XP[guid].skills[BATTLESENSE+1]) .. " " .. tostring(XP[guid].skills[ENGINEERING+1]) .. " " .. tostring(XP[guid].skills[MEDIC+1]) .. " " .. tostring(XP[guid].skills[FIELDOPS+1]) .. " " .. tostring(XP[guid].skills[LIGHTWEAPONS+1]) .. " " .. tostring(XP[guid].skills[HEAVYWEAPONS+1]) .. " " .. tostring(XP[guid].skills[COVERTOPS+1]) )
        et.G_ResetXP(clientNum)
    end
end

function _saveXp (clientNum)
    local guid = _getGUID(clientNum)
    if ( _validateGUID(clientNum, guid) ) then
        _print("_saveXp Client(" .. tostring(clientNum) .. ") guid(" .. tostring(guid) .. ")")
        if ( XP[guid] == nil ) or ( next(XP[guid]) == nil ) then
            XP[guid] = { }
            _print("_saveXp new xpsave table created for (" .. tostring(guid) .. ")")
        end
        if ( XP[guid].skills == nil ) or ( next(XP[guid].skills) == nil ) then -- Check Separately just in-case for some reason this doesn't exist.
            XP[guid].skills = { }
        end
        for k=BATTLESENSE, COVERTOPS do
            _setSkillPoints(clientNum, guid, k)
        end
        _print("_saveXp (" .. tostring(guid) .. ") " .. tostring(XP[guid].skills[BATTLESENSE+1]) .. " " .. tostring(XP[guid].skills[ENGINEERING+1]) .. " " .. tostring(XP[guid].skills[MEDIC+1]) .. " " .. tostring(XP[guid].skills[FIELDOPS+1]) .. " " .. tostring(XP[guid].skills[LIGHTWEAPONS+1]) .. " " .. tostring(XP[guid].skills[HEAVYWEAPONS+1]) .. " " .. tostring(XP[guid].skills[COVERTOPS+1]) )
        -- Check if player has referee status
        if ( et.gentity_get(clientNum, "sess.referee") == 1 ) then
            XP[guid].referee = true
            _print("_saveXp Client("..tostring(clientNum)..") saved referee status")
        else
            XP[guid].referee = false
        end
        -- Update last seen for player
        XP[guid].lastseen = os.date("%x %X")
    end
end

function _loadXp (clientNum)
    local guid = _getGUID(clientNum)
    if ( _validateGUID(clientNum, guid) ) then
        _print("_loadXp Client(" .. tostring(clientNum) .. ") guid(" .. tostring(guid) .. ")")
        if ( XP[guid] == nil ) or ( next(XP[guid]) == nil ) then
            XP[guid] = { }
            _print("_loadXp new xpsave table created for (" .. tostring(guid) .. ")")
        end
        if ( XP[guid].skills == nil ) or ( next(XP[guid].skills) == nil ) then -- Check Separately just in-case for some reason this doesn't exist.
            XP[guid].skills = { }
        end
        for k=BATTLESENSE+1, COVERTOPS+1 do
            if ( XP[guid].skills[k] == nil ) then
                XP[guid].skills[k] = 0
            end
        end
        _print("_loadXp (" .. tostring(guid) .. ") " .. tostring(XP[guid].skills[BATTLESENSE+1]) .. " " .. tostring(XP[guid].skills[ENGINEERING+1]) .. " " .. tostring(XP[guid].skills[MEDIC+1]) .. " " .. tostring(XP[guid].skills[FIELDOPS+1]) .. " " .. tostring(XP[guid].skills[LIGHTWEAPONS+1]) .. " " .. tostring(XP[guid].skills[HEAVYWEAPONS+1]) .. " " .. tostring(XP[guid].skills[COVERTOPS+1]) )
        for k=BATTLESENSE, COVERTOPS do
            et.G_XP_Set(clientNum, XP[guid].skills[k+1], k, 0)
        end
        if ( XP[guid].referee ) then
            _print("_loadXp Client("..tostring(clientNum)..") granted referee status")
            et.gentity_set(clientNum, "sess.referee",1)
        end
    end
end

function _printFinger (clientNum, targetNum)
    _print("_printFinger Client(" .. tostring(clientNum) .. ") Target(" .. tostring(targetNum) .. ")")
    if ( et.gentity_get(clientNum, "sess.referee") == 1 ) then
        local ui        = et.trap_GetUserinfo(targetNum)
        local name      = et.Info_ValueForKey(ui, "name")
        local guid      = et.Info_ValueForKey(ui, "cl_guid")
        local ip        = et.Info_ValueForKey(ui, "ip")
        local etversion = et.Info_ValueForKey(ui, "cg_etVersion")
        local protocol  = et.Info_ValueForKey(ui, "protocol")
        local port      = et.Info_ValueForKey(ui, "qport")
        _message("chat", "^ofinger: ^7Fingered info for " .. tostring(name), clientNum)
        _message("print", "IP(" .. tostring(ip) .. ") GUID(" .. tostring(guid) .. ") QPORT(" .. tostring(port), clientNum)
        _message("print", "ETVERSION(" .. tostring(etversion) .. ") PROTOCOL(" .. tostring(protocol), clientNum)
    else
        _message("chat", "^ofinger: ^7You do not have access to this command", clientNum)
    end
end

function _saveXpAll ()
    for clientNum=0, tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
        local connected = et.gentity_get(clientNum, "pers.connected")
        -- 0 = Disconnected
        -- 1 = Connecting  -- Might want to do 1 too which is 'currently connecting' but im not sure if their xp is readable then so maybe not...
        -- 2 = Connected
        if ( connected == 2 ) and ( _trackOmniBotXP(clientNum) ) then
            _print("_saveXpAll Client(" .. clientNum .. ") is connected, saving their xp")
            _saveXp(clientNum)
        end
    end
end

function _map ()
    return tostring(et.trap_Cvar_Get("mapname"))
end

local _laststate = -1
function _gamestate ()
    local gs = tonumber(et.trap_Cvar_Get("gamestate"))
    if ( gs == 0 ) then
        if ( laststate == 2 ) then
            return "warmup end"
        end
        return "game"
    elseif ( gs == -1 ) then
        return "game end"
    elseif ( gs == 2 ) then
        _laststate = 2
        return "warmup"
    else
        return tostring(gs)
    end
end

function _advPlayers (clientNum)
    _message("print", "^3 ID ^1: ^3Player                     Rate  Snaps", clientNum)
    _message("print", "^1--------------------------------------------", clientNum)
    local team = {
        "^1X", -- Axis
        "^4L", -- Allies
        "^3S"  -- Spectator
    }
    local playerCount = 0
    local spa = 24
    for i=0, tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
        local teamNumber = et.gentity_get(i, "sess.sessionTeam")
        local clientName = et.Info_ValueForKey(et.trap_GetUserinfo(i), "name")
        local rate       = et.Info_ValueForKey(et.trap_GetUserinfo(i), "rate")
        local snaps      = et.Info_ValueForKey(et.trap_GetUserinfo(i), "snaps")
        local name       = string.lower(et.Q_CleanStr(clientName))
        local namel      = string.len(name) - 1
        local nameSpa    = spa - namel
        local space      = string.rep(" ", nameSpa)
        local ref        = et.gentity_get(i, "sess.referee")
        if ( ref == 1 ) then
            ref = "^3REF"
        else
            ref = ""
        end
        if ( et.gentity_get(i, "pers.connected") == 2 ) then
            _message("print", string.format("%s^7%2s ^1:^7 %s%s %5s  %5s %s", team[teamNumber], i, name, space, rate, snaps, ref), clientNum)
            playerCount = playerCount + 1
        end
    end
    _message("print", "\n^3 " .. playerCount .. " ^7total players\n", clientNum)
end

--[[
        _getNextXpReset is UNDER CONSTRUCTION
--]]
function _getNextXpReset ()
    if     ( XP_RESET_FLAG == 0 ) then -- Reset everyday
    elseif ( XP_RESET_FLAG == 1 ) then -- Reset every Tuesday
    elseif ( XP_RESET_FLAG == 2 ) then -- Reset every month on the 1st
    elseif ( XP_RESET_FLAG == 3 ) then -- Reset every year on Janurary 1st
        --if ( XP["SERVER_XP_RESET"].nextresetdate == nil ) or ( DATE_EPOCH > XP["SERVER_XP_RESET"].nextresetdate ) then
            --XP["SERVER_XP_RESET"].nextresetdate = CUR_DATE_TIME-- + YEAR
        --end
    end
end

function et_InitGame (levelTime, randomSeed, restart)
    et.RegisterModname("ZXPSave")
    _print(scriptName .. " " .. version .. " Init - " .. _gamestate() .. " - " .. _map())
    _print("Load Path : " .. tostring(readPath))
    _print("Write Path : " .. tostring(writePath))
    XP = _read()
    if ( XP["SERVER_XP_RESET"] == nil ) or ( next(XP["SERVER_XP_RESET"]) == nil ) then
        XP["SERVER_XP_RESET"] = { }
        XP["SERVER_XP_RESET"].lastreset = "never"
    end
    _getNextXpReset()
end

function et_ShutdownGame (restart)
    _print(scriptName .. " " .. version .. " Shutdown - " .. _gamestate() .. " - " .. _map())
    _saveXpAll()
    _write()
    _saveLog()
end

function et_RunFrame (levelTime)
    if ( (levelTime % (_saveTime * 1000)) == 0 ) then
        _print("et_Runframe saving all active clients")
        _saveXpAll()
    end
end

function et_ClientCommand (clientNum, command)
    local Arg0 = string.lower(et.trap_Argv(0))
    local Arg1 = string.lower(et.trap_Argv(1))
    if ( Arg0 == "say" )  then
        if ( Arg1 == "!finger" ) then
            local targetNum = et.ClientNumberFromString(et.trap_Argv(2))
            _printFinger(clientNum, targetNum)
            return 1
        elseif ( Arg1 == "!loadxp" ) then
            _loadXp(clientNum)
            _message("cp", "^oLoadXp: ^7Your xp has been loaded", clientNum)
            return 1
        elseif ( Arg1 == "!savexp" ) then
            _saveXp(clientNum)
            _message("cp", "^oSaveXp: ^7Your xp has been saved", clientNum)
            return 1
        elseif ( Arg1 == "!resetxp" ) then
            _resetXp(clientNum)
            _message("cp", "^oResetXp: ^7Your xp has been reset", clientNum)
            return 1
        elseif ( Arg1 == "!players" ) then
            _advPlayers(clientNum)
            return 1
        end
    end
end

function et_ClientConnect (clientNum)
    if ( _trackOmniBotXP(clientNum) ) then
        _print("et_ClientBegin Client(" .. clientNum .. ") connected, loading their xp")
        _loadXp(clientNum)
    end
end

function et_ClientBegin (clientNum)
    local name = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "name")
    _message("cpm", "^3Welcome ^7" .. name .. "^3! You are playing on an XP save server", clientNum)
end

function et_ClientDisconnect (clientNum)
    if ( _trackOmniBotXP(clientNum) ) then
        _print("et_ClientDisconnect Client(" .. clientNum .. ") disconnected, saving their xp")
        _saveXp(clientNum)
    end
end