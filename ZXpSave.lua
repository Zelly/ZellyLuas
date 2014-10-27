-- Zelly's JSON Legacy Mod XpSave Lua
-- Xfire : anewxfireaccount
-- Made for jemstar <3
-- Feel free to report problems to my xfire
-- https://github.com/Zelly/ZellyLuas for latest version
-- Get JSON.lua from http://regex.info/blog/lua/json
-- Looks for JSON.lua in fs_basepath/fs_game/JSON.lua
-- xpsave.json saves to fs_homepath/fs_game/xpsave.json
-- version: 3

-- BUG: I guess it currently does not save xp on shutdown. I have fixed this in my LuaESMod, but I am not sure how I will fix it here.
--      HOTFIX: You can either disconnect before game ends(At intermission) or type !savexp

local _printDebug = false -- If you want to print to console
local _logDebug   = false -- If you want it to log to server log ( Requires _printDebug = true )
local _print = function(msg)
    if not ( _printDebug ) then return end
    msg = et.Q_CleanStr(msg)
    if ( string.len(msg) <= 0 ) then return end
    if ( _logDebug ) then
        et.G_LogPrint("ZXPSAVE: " .. msg .. "\n")
    else
        et.G_Print("ZXPSAVE: " .. msg .. "\n")
    end
end

local readPath     = string.gsub(et.trap_Cvar_Get("fs_basepath") .. "/" .. et.trap_Cvar_Get("fs_game") .. "/","\\","/")
local writePath    = string.gsub(et.trap_Cvar_Get("fs_homepath") .. "/" .. et.trap_Cvar_Get("fs_game") .. "/","\\","/")

_print("Load Path : " .. tostring(readPath))
_print("Write Path : " .. tostring(writePath))

JSON               = (loadfile(readPath .. "JSON.lua"))()

local XP_FILE      = writePath .. "xpsave.json" -- If you want you can replace writePath with readPath here I think
local BATTLESENSE  = 0
local ENGINEERING  = 1
local MEDIC        = 2
local FIELDOPS     = 3
local LIGHTWEAPONS = 4
local HEAVYWEAPONS = 5
local COVERTOPS    = 6


local XP = {}


local _write = function()
    _print( "_write() XP(".. tostring(XP) .. ") XP_FILE(".. tostring(XP_FILE) .. ")" )
    local xp_encoded = JSON:encode_pretty( XP )
    local FileObject = io.open( XP_FILE , "w" )
    FileObject:write(xp_encoded)
    FileObject:close()
end

local _read  = function()
    _print( "_read() XP(".. tostring(XP) .. ") XP_FILE(".. tostring(XP_FILE) .. ")" )
    local status,FileObject = pcall(io.open,XP_FILE, "r")
    _print( "_read() FileObject(".. tostring(FileObject) .. ")" )
    if not ( status ) or ( FileObject == nil ) then
        _print("_read() " .. tostring(XP_FILE) .. " not found. Will be created on next shutdown")
        return { }
    end
    local fileData = { }
    for line in FileObject:lines() do
        if (line == nil) then break end
        if not (line == "") then
            fileData[#fileData+1] = line
        end
    end
    FileObject:close()
    _print("_read() Successfully read " .. tostring(#fileData) .. " lines from " .. tostring(XP_FILE))
    return JSON:decode( table.concat(fileData,"\n") )
end

local _validateGUID = function (clientNum, guid)
    -- allow only alphanumeric characters in guid
    if ( guid == nil ) or ( string.match(guid, "%W") ) or ( string.lower(guid) == "no_guid" ) or ( string.lower(guid) == "unknown" ) or ( string.len(guid) < 32 ) then -- Invalid characters detected. We should probably drop this client
        _print("_validateGUID Client(" .. tostring(clientNum) .. ") has an invalid guid(" .. tostring(guid) .. ") will not store xp for him")
        et.trap_SendServerCommand (clientNum, "chat \"^1WARNING: ^7Your XP won't be saved because you have an invalid cl_guid.\n\"")
        return false
    end
    _print("_validateGUID Client(" .. tostring(clientNum) .. ") has a valid guid(" .. tostring(guid) .. ")")
    return true
end

local _saveXp = function(clientNum)
    --local name = et.Info_ValueForKey( et.trap_GetUserinfo( clientNum ), "name" )
    local GUID = et.Info_ValueForKey( et.trap_GetUserinfo( clientNum ), "cl_guid" )
    if not ( _validateGUID(clientNum,GUID) ) then return end
    _print("_saveXp Client(" .. tostring(clientNum) .. ") guid(" .. tostring(GUID) .. ")")
    if ( XP[GUID] == nil or next(XP[GUID]) == nil ) then
        XP[GUID] = { }
        _print("_saveXp new xpsave table created for (" .. tostring(guid) .. ")")
    end
    if ( XP[GUID].skills == nil or next(XP[GUID].skills) == nil ) then -- Check Separately just in-case for some reason this doesn't exist.
        XP[GUID].skills = { }
    end
    GUID = string.upper(GUID)
    XP[GUID].skills[BATTLESENSE+1]  = et.gentity_get(clientNum, "sess.skillpoints", BATTLESENSE)
    XP[GUID].skills[ENGINEERING+1]  = et.gentity_get(clientNum, "sess.skillpoints", ENGINEERING)
    XP[GUID].skills[MEDIC+1]        = et.gentity_get(clientNum, "sess.skillpoints", MEDIC)
    XP[GUID].skills[FIELDOPS+1]     = et.gentity_get(clientNum, "sess.skillpoints", FIELDOPS)
    XP[GUID].skills[LIGHTWEAPONS+1] = et.gentity_get(clientNum, "sess.skillpoints", LIGHTWEAPONS)
    XP[GUID].skills[HEAVYWEAPONS+1] = et.gentity_get(clientNum, "sess.skillpoints", HEAVYWEAPONS)
    XP[GUID].skills[COVERTOPS+1]    = et.gentity_get(clientNum, "sess.skillpoints", COVERTOPS)
    if ( et.gentity_get(clientNum,"sess.referee") == 1 ) then
        XP[GUID].referee = true
        _print("_saveXp Client("..tostring(clientNum)..") saved referee status")
    else
        XP[GUID].referee = false
    end
end

local _loadXp = function(clientNum)
    local GUID = et.Info_ValueForKey( et.trap_GetUserinfo( clientNum ), "cl_guid" )
    if not ( _validateGUID(clientNum,GUID) ) then return end
    _print("_loadXp Client(" .. tostring(clientNum) .. ") guid(" .. tostring(GUID) .. ")")
    if ( XP[GUID] == nil or next(XP[GUID]) == nil ) then
        XP[GUID] = { }
        _print("_loadXp new xpsave table created for (" .. tostring(guid) .. ")")
    end
    if ( XP[GUID].skills == nil or next(XP[GUID].skills) == nil ) then -- Check Separately just in-case for some reason this doesn't exist.
        XP[GUID].skills = { }
    end
    for k=BATTLESENSE+1, COVERTOPS+1 do
        if ( XP[GUID].skills[k] == nil ) then
            XP[GUID].skills[k] = 0
        end
    end
    _print("_loadXp (" .. tostring(guid) .. ") " .. tostring(XP[GUID].skills[BATTLESENSE+1]) .. " " .. tostring(XP[GUID].skills[ENGINEERING+1]) .. " " .. tostring(XP[GUID].skills[MEDIC+1]) .. " " .. tostring(XP[GUID].skills[FIELDOPS+1]) .. " " .. tostring(XP[GUID].skills[LIGHTWEAPONS+1]) .. " " .. tostring(XP[GUID].skills[HEAVYWEAPONS+1]) .. " " .. tostring(XP[GUID].skills[COVERTOPS+1]) )
    et.G_XP_Set( clientNum, XP[GUID].skills[BATTLESENSE+1]  , BATTLESENSE  , 0)
    et.G_XP_Set( clientNum, XP[GUID].skills[ENGINEERING+1]  , ENGINEERING  , 0)
    et.G_XP_Set( clientNum, XP[GUID].skills[MEDIC+1]        , MEDIC        , 0)
    et.G_XP_Set( clientNum, XP[GUID].skills[FIELDOPS+1]     , FIELDOPS     , 0)
    et.G_XP_Set( clientNum, XP[GUID].skills[LIGHTWEAPONS+1] , LIGHTWEAPONS , 0)
    et.G_XP_Set( clientNum, XP[GUID].skills[HEAVYWEAPONS+1] , HEAVYWEAPONS , 0)
    et.G_XP_Set( clientNum, XP[GUID].skills[COVERTOPS+1]    , COVERTOPS    , 0)
    if ( XP[GUID].referee ) then
        _print("_loadXp Client("..tostring(clientNum)..") granted referee status")
        et.gentity_set(clientNum,"sess.referee",1)
    end
end

local _printFinger = function(clientNum,targetNum)
    _print("_printFinger Client("..tostring(clientNum)..") Target("..tostring(targetNum)..")")
    if ( et.gentity_get(clientNum,"sess.referee") ~= 1 ) then
        et.trap_SendServerCommand (clientNum, "chat \"^ofinger: ^7You do not have access to this command\"")
        return
    end
    local ui        = et.trap_GetUserinfo( targetNum )
    local name      = et.Info_ValueForKey( ui , "name" )
    local guid      = et.Info_ValueForKey( ui , "cl_guid" )
    local ip        = et.Info_ValueForKey( ui , "ip" )
    local etversion = et.Info_ValueForKey( ui , "cg_etVersion" )
    local protocol  = et.Info_ValueForKey( ui , "protocol" )
    local port      = et.Info_ValueForKey( ui , "qport" )
    et.trap_SendServerCommand (clientNum, "chat \"^ofinger: ^7Fingered info for " .. tostring(name) .. "\"")
    et.trap_SendServerCommand (clientNum, "print \"IP("..tostring(ip)..") GUID("..tostring(guid)..") QPORT("..tostring(port)..")\n\"")
    et.trap_SendServerCommand (clientNum, "print \"ETVERSION("..tostring(etversion)..") PROTOCOL("..tostring(protocol)..")\n\"")
end

function et_InitGame(levelTime, randomSeed, restart)
    et.RegisterModname ( "ZXPSave" )
    _print("Zelly's JSON Legacy Mod XpSave Lua Loaded")
    XP = _read()
end

function et_ShutdownGame(restart)
    for clientNum=0, tonumber(et.trap_Cvar_Get("sv_maxclients")) - 1 do
        local connected = et.gentity_get(clientNum,"pers.connected")
        -- 0 = Disconnected
        -- 1 = Connecting  -- Might want to do 1 too which is 'currently connecting' but im not sure if their xp is readable then so maybe not...
        -- 2 = Connected
        if ( connected == 2 ) then
            _print("et_ShutdownGame Client("..clientNum..") is connected, saving their xp")
            _saveXp(clientNum)
        end
    end
    _write()
end

function et_ClientCommand(clientNum,command)
    local Arg0 = string.lower(et.trap_Argv(0))
    local Arg1 = string.lower(et.trap_Argv(1))
    
    if ( Arg0 == "say"  and Arg1 == "!finger" )  then
        local targetNum = et.ClientNumberFromString(et.trap_Argv(2))
        _printFinger(clientNum,targetNum)
        return 0
    elseif ( Arg0 == "!finger" ) then
        local targetNum = et.ClientNumberFromString(et.trap_Argv(2))
        _printFinger(clientNum,targetNum)
        return 1
    elseif ( Arg0 == "!savexp" ) then
        _saveXp(clientNum)
        et.trap_SendServerCommand (clientNum, "chat \"^osavexp: ^7Your xp has been saved\"")
        return 1
    end
end

function et_ClientBegin(clientNum)
    _print("et_ClientBegin Client("..clientNum..") connected, loading their xp")
    _loadXp(clientNum)
end

function et_ClientDisconnect(clientNum)
    _print("et_ClientDisconnect Client("..clientNum..") disconnected, saving their xp")
    _saveXp(clientNum)
end
