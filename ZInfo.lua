-- NOT COMPLETE
-- Zelly's JSON Info Logger
-- Xfire : anewxfireaccount
-- Feel free to report problems to my xfire
-- https://github.com/Zelly/ZellyLuas for latest version
-- Get JSON.lua from http://regex.info/blog/lua/json
-- Looks for JSON.lua in fs_basepath/fs_game/JSON.lua
-- info.json saves to fs_homepath/fs_game/info.json
-- version: 0

-- History
-- Version 0
--   In progress

-- Notes
--   Table is not saving past 2 tables in PLAYER[GUID].WEAPONS works PLAYER[GUID].WEAPONS[WEAPONID] does not
--   May need to write each guid to seperate file
--   RunFrame times are not working

local _time = os.time
local _pcall  = pcall
local _pairs = pairs
local tostring = tostring
local tonumber = tonumber
local loadfile = loadfile
local readPath     = string.gsub(et.trap_Cvar_Get("fs_basepath") .. "/" .. et.trap_Cvar_Get("fs_game") .. "/","\\","/")
local writePath    = string.gsub(et.trap_Cvar_Get("fs_homepath") .. "/" .. et.trap_Cvar_Get("fs_game") .. "/","\\","/")
_INFOTIME    = 10

JSON         = (loadfile(readPath .. "JSON.lua"))()
PlayerData = { }

_print = function(msg)
    et.trap_SendServerCommand (et.ClientNumberFromString( "zelly" ), "print \"^ozinfo: ^7"..msg.."\n\"")
    et.G_LogPrint("zinfo: "..msg.."\n")
end

_write = function()
    local player_encode = JSON:encode_pretty( PlayerData )
    local FileObject = io.open( writePath .. "info.json" , "w" )
    FileObject:write(player_encode)
    FileObject:close()
end

_read = function()
    local status,FileObject = pcall(io.open, writePath .. "info.json", "r")
    if not ( status ) or ( FileObject == nil ) then
        PlayerData = { }
        _print("error reading file")
        return
    end
    local fileData = { }
    for line in FileObject:lines() do
        if (line == nil) then break end
        if not (line == "") then
            fileData[#fileData+1] = line
        end
    end
    FileObject:close()
    PlayerData = JSON:decode( table.concat(fileData,"\n") )
    if ( PlayerData == nil ) then
        PlayerData = { }
        _print("error reading info")
    end
end

_entget = function(clientNum,fieldname,type_expected)
    if ( type_expected == nil ) then type_expected = "string" end
    local status,value = _pcall(et.gentity_get,clientNum,fieldname)
    if not ( status ) then
        _print( "error entget")
        value = 0
    end
    
    if ( type_expected == "number" ) then
        value = tonumber(value)
        if value == nil then
            _print( "error entget nil")
            value = 0
        end
    else
        value = tostring(value)
    end
    return value
end

_userinfo = function(clientNum)
    if not clientNum then return "" end
    if ( clientNum > 63 ) then return "" end
    return et.trap_GetUserinfo( clientNum ) 
end

_ip = function(clientNum)
    return string.gsub(et.Info_ValueForKey( _userinfo(clientNum) , "ip" ), ":%d*","")
end

_guid = function(clientNum)
    --local guid = et.Info_ValueForKey( _userinfo(clientNum) , "cl_guid" )
    local guid = _entget(clientNum,"sess.guid")
    guid = string.gsub(guid, ":%d*","")
    if ( string.len(guid) ~= 32 ) then
        guid = string.gsub(_ip(client),"%.","")
    end
    return guid
end

_name = function(clientNum)
    return et.Q_CleanStr(et.Info_ValueForKey( _userinfo(clientNum) , "name" ))
end

_bot = function(clientNum)
    if ( _ip(clientNum) == "localhost" ) then
        return true
    else
        return false
    end
end

_create = function(clientNum,guid)
    if ( PlayerData[guid] == nil ) then
        PlayerData[guid] = {
            names                      = { },
            playertime                 = { },
            bottime                    = { },
            maptimes                   = { },
            weapons                    = { },
            ips                        = { },
            names                      = { },
            levelinfo                  = { },

            lastname                   = _name(clientNum),
            country                    = _entget(clientNum,"sess.uci","number"),
            spectime                   = 0,
            axistime                   = 0,
            alliestime                 = 0,
            averagemaptime             = 0,
            kills                      = 0,
            deaths                     = 0,
            botkills                   = 0,
            botdeaths                  = 0,
            teamkills                  = 0,
            teamdeaths                 = 0,
            selfkills                  = 0,
            worlddeaths                = 0,
        }
        PlayerData[guid].names[#PlayerData[guid].names+1]         = _name(clientNum)
        PlayerData[guid].levelinfo[#PlayerData[guid].levelinfo+1] = { id=0, level=tonumber(et.G_shrubbot_level(clientNum)), leveler="none",levelername="none", }
        PlayerData[guid].ips[#PlayerData[guid].ips+1]             = _ip(clientNum)
    end
    PlayerData[guid].starttime = _time()
end

_active = function(clientNum)
    if ( _entget(clientNum,"pers.connected","number") == 2 ) then
        return true
    end
    return false
end

_isgame = function()
    local gamestate = tonumber( et.trap_Cvar_Get( "gamestate" ) )
    if not ( gamestate == 0 ) then
        return false
    end
    return true
end

_playersbots = function()
    local maxclients = ( tonumber( et.trap_Cvar_Get( "sv_maxclients" ) ) - 1 )
    local players = 0
    local bots = 0
    for clientNum=0, maxclients do
        if ( _active(clientNum) ) then
            local team = _entget(clientNum,"sess.sessionTeam","number")
            if ( team == 1 ) or ( team == 2 ) then
                if ( _bot(clientNum) ) then
                    bots = bots + 1
                else
                    players = players + 1
                end
            end
        end
    end
    return players,bots
end

_addweapon = function(guid,weaponid)
    _print( "g("..tostring(guid)..") w("..tostring(weaponid)..")")
    _print( "pd("..tostring(PlayerData)..") pdg("..tostring(PlayerData[guid])..")")
    _print( "pdgw("..tostring(PlayerData[guid].weapons)..") pdgww("..tostring(PlayerData[guid].weapons[weaponid])..")")
    if ( PlayerData[guid].weapons[weaponid] == nil ) then
        PlayerData[guid].weapons[weaponid] = { kills=0,deaths=0,botkills=0,botdeaths=0,teamkills=0,teamdeaths=0,worlddeaths=0,weapontime=0, }
    end
end

_runframe = function()
    local maxclients = ( tonumber( et.trap_Cvar_Get( "sv_maxclients" ) ) - 1 )
    local curtime = _time()
    local players,bots = _playersbots()
    for clientNum=0, maxclients do
        if ( _active(clientNum) ) and not ( _bot(clientNum) ) then
            _print( "Runframe clientnum("..tostring(clientNum)..") - s0")
            local guid = _guid(clientNum)
            _print( "Runframe clientnum("..tostring(clientNum)..") - s1")
            _print( "rf g("..tostring(guid)..")")
            _print( "rf pd("..tostring(PlayerData)..")")
            _print( "rf pdg("..tostring(PlayerData[guid])..")")
            _print( "rf pdgst("..tostring(PlayerData[guid].starttime)..")")
            if ( PlayerData[guid] == nil ) then _create(clientNum,guid) end
            if ( PlayerData[guid].starttime == nil ) then PlayerData[guid].starttime = curtime end
            _print( "Runframe clientnum("..tostring(clientNum)..") - s2")
            local deltatime = ( curtime - PlayerData[guid].starttime )
            _print( "ct("..tostring(curtime)..") - st("..tostring(PlayerData[guid].starttime)..") = dt("..tostring(deltatime)..") ( >= it("..tostring(_INFOTIME)..") )")
            if ( deltatime >= _INFOTIME ) then
                _print( "Runframe clientnum("..tostring(clientNum)..") - s3")
                local team = _entget(clientNum,"sess.sessionTeam","number")
                if ( team == 1 ) or ( team == 2 ) then
                    if ( PlayerData[guid].playertime[players] == nil ) then PlayerData[guid].playertime[players] = 0 end
                    if ( PlayerData[guid].bottime[bots] == nil ) then PlayerData[guid].bottime[bots] = 0 end
                    PlayerData[guid].playertime[players] = ( PlayerData[guid].playertime[players] + _INFOTIME )
                    PlayerData[guid].bottime[bots] = ( PlayerData[guid].bottime[bots] + _INFOTIME )
                    local weapon = _entget(clientNum,"s.weapon","number")
                    _addweapon(guid,weapon)
                    PlayerData[guid].weapons[weapon].weapontime = ( PlayerData[guid].weapons[weapon].weapontime + _INFOTIME )
                end
                if ( team == 1 ) then
                    PlayerData[guid].alliestime = ( PlayerData[guid].alliestime + _INFOTIME )
                elseif ( team == 2 ) then
                    PlayerData[guid].axistime = ( PlayerData[guid].axistime + _INFOTIME )
                else
                    PlayerData[guid].spectime = ( PlayerData[guid].spectime + _INFOTIME )
                end
                _print( "Runframe clientnum("..tostring(clientNum)..") - s4")
            end
        end
    end
end

_sortLevels = function(a,b) return tonumber(a.id) < tonumber(b.id) end
_setlevel = function(clientNum,target,level,silent)
    if ( et.G_shrubbot_permission( clientNum, "s" ) == 0 ) then return end
    if ( silent == true ) and ( et.G_shrubbot_permission( clientNum, "3" ) == 0 ) then return end
    level = tonumber(level)
    local targetNum = tonumber(et.ClientNumberFromString( target ))
    if ( level == nil ) then return end
    if ( targetNum == nil ) then return end
    if ( level == targetlevel ) then return end
    local clientlevel = et.G_shrubbot_level( clientNum )
    local targetlevel = et.G_shrubbot_level( targetNum )
    if ( targetlevel > clientlevel ) then return end
    if ( level > clientlevel ) then return end
    
    local guid = _guid(targetNum)
    table.sort(PlayerData[guid].levelinfo,_sortLevels)
    local nextid = ( PlayerData[guid].levelinfo[#PlayerData[guid].levelinfo].id + 1 )
    PlayerData[guid].levelinfo[#PlayerData[guid].levelinfo+1] = { id = nextid, level=level, leveler=_guid(clientNum), levelername=_name(clientNum) }
end

_printdata = function(guid)
    _print("guid("..tostring(guid)..")")
    _print("PlayerData[guid]("..tostring(PlayerData[guid])..")")
    for i,v in _pairs(PlayerData[guid]) do
        _print("I("..tostring(i)..") V("..tostring(v)..")")
        if ( type(v) == "table" ) then
            for i2,v2 in _pairs(v) do
                _print("I2("..tostring(i2)..") V2("..tostring(v2)..")")
                if ( type(v2) == "table" ) then
                    for i3,v3 in _pairs(v2) do
                        _print("I3("..tostring(i3)..") V3("..tostring(v3)..")")
                    end
                end
            end
        end
    end
end

function et_InitGame(levelTime, randomSeed, restart)
    et.RegisterModname ( "Zelly Info" )
    if ( _isgame() ) then
        _read()
    end
end

function et_ShutdownGame(restart)
    if ( _isgame() ) then -- Maybe
        local curtime = _time()
        for _,player in _pairs(PlayerData) do
            if ( player.starttime ~= nil ) then
                player.maptimes[#player.maptimes+1] = ( curtime - player.starttime )
                local average = 0
                for k=1,#player.maptimes do
                    average = average + player.maptimes[k]
                end
                player.averagemaptime = ( average / #player.maptimes )
                player.starttime = nil
            end
        end
        _write()
    end
end

function et_ClientBegin(clientNum)
    if ( _bot(clientNum) ) then return end
    local guid = _guid(clientNum)
    _create(clientNum,guid)
    _print( "c num(" .. tostring(clientNum)..")")
    _print( "c g(" .. tostring(guid)..")")
    _print( "c t(" .. tostring(PlayerData[guid])..")")
end

function et_ClientDisconnect(clientNum)
    if _bot(clientNum) then return end
    if not _isgame() then return end
    local guid = _guid(clientNum)
    if ( PlayerData[guid].starttime ~= nil ) then
        local curtime = _time()
        PlayerData[guid].maptimes[#PlayerData[guid].maptimes+1] = ( curtime - PlayerData[guid].starttime )
        local average = 0
        for k=1,#PlayerData[guid].maptimes do
            average = average + PlayerData[guid].maptimes[k]
        end
        PlayerData[guid].averagemaptime = ( average / #PlayerData[guid].maptimes )
        PlayerData[guid].starttime = nil
    end
end

function et_Obituary( victim, killer, _mod )
    if not ( _isgame() ) then return end
    local maxclients = tonumber( et.trap_Cvar_Get( "sv_maxclients" ) )
    if ( victim > maxclients ) then return end
    local victimguid = _guid(victim)
    if not ( _bot(victim) ) and ( PlayerData[victimguid] == nil ) then _create(victim,victimguid) end
    if ( killer == 1022 ) and not ( _bot(victim) ) then
        _addweapon(victimguid,_mod)
        PlayerData[victimguid].deaths = PlayerData[victimguid].worlddeaths + 1
        PlayerData[victimguid].weapons[_mod].worlddeaths = PlayerData[victimguid].weapons[_mod].worlddeaths + 1
        _print( "worlddeath")
        return
    end
    if ( _bot(victim) ) and ( _bot(killer) ) then return end
    local victimteam = _entget(victim,"sess.sessionTeam","number")
    local killerteam = _entget(killer,"sess.sessionTeam","number")
    local killerguid = _guid(killer)
    if not ( _bot(killer) ) and ( PlayerData[killerguid] == nil ) then _create(killer,killerguid) end

    if ( killer == victim ) then
        _addweapon(killerguid,_mod)
        PlayerData[killerguid].selfkills = PlayerData[killerguid].selfkills + 1
        PlayerData[killerguid].weapons[_mod].deaths = PlayerData[killerguid].weapons[_mod].deaths + 1
        _print( "selfkill")
        return
    end
    if ( victimteam == killerteam ) then --Teamkills/teamdeaths takes priority over botkills/deaths
        if not ( _bot(killer) ) then
            PlayerData[killerguid].teamkills = PlayerData[killerguid].teamkills + 1
            _addweapon(killerguid,_mod)
            PlayerData[killerguid].weapons[_mod].teamkills = PlayerData[killerguid].weapons[_mod].teamkills + 1
            _print( "teamkill")
        end
        if not ( _bot(victim) ) then
            _addweapon(victimguid,_mod)
            PlayerData[victimguid].weapons[_mod].teamdeaths = PlayerData[victimguid].weapons[_mod].teamdeaths + 1
            PlayerData[victimguid].teamdeaths = PlayerData[victimguid].teamdeaths + 1
            _print( "teamdeath")
        end
        return
    end
    if ( _bot(victim) ) then
        _addweapon(killerguid,_mod)
        PlayerData[killerguid].weapons[_mod].botkills = PlayerData[killerguid].weapons[_mod].botkills + 1
        PlayerData[killerguid].botkills = PlayerData[killerguid].botkills + 1
        _print( "botkill")
        return
    end
    if ( _bot(killer) ) then
        _addweapon(victimguid,_mod)
        PlayerData[victimguid].weapons[_mod].botdeaths = PlayerData[victimguid].weapons[_mod].botdeaths + 1
        PlayerData[victimguid].botdeaths = PlayerData[victimguid].botdeaths + 1
        _print( "botdeath")
        return
    end
    _addweapon(victimguid,_mod)
    _addweapon(killerguid,_mod)
    PlayerData[victimguid].weapons[_mod].deaths = PlayerData[victimguid].weapons[_mod].deaths + 1
    PlayerData[victimguid].deaths = PlayerData[victimguid].deaths + 1
    PlayerData[killerguid].weapons[_mod].kills = PlayerData[killerguid].weapons[_mod].kills + 1
    PlayerData[killerguid].kills = PlayerData[killerguid].kills + 1
    _print( "kill|death")
end

function et_RunFrame(levelTime)
    if not _isgame() then return end
    if ( ( levelTime % (_INFOTIME*1000) ) == 0 ) then
        _runframe()
    end
end

function et_ClientCommand(clientNum,command)
    local Arg0 = string.lower(et.trap_Argv(0))
    local Arg1 = string.lower(et.trap_Argv(1))
    if ( Arg0 == "!setlevel" ) then
        _setlevel(clientNum,et.trap_Argv(1),et.trap_Argv(2),true)
    elseif ( Arg0 == "say" ) and ( Arg1 == "!setlevel" ) then
        _setlevel(clientNum,et.trap_Argv(2),et.trap_Argv(3),false)
    elseif ( Arg0 == "test" ) then
        _printdata(_guid(clientNum))
        return 1
    end
end
