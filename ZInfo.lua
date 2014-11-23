--- NOT COMPLETE
--- Zelly's JSON Info Logger
--- Xfire : anewxfireaccount
--- Feel free to report problems to my xfire
--- https://github.com/Zelly/ZellyLuas for latest version
--- Get JSON.lua from http://regex.info/blog/lua/json
--- Looks for JSON.lua in fs_basepath/fs_game/JSON.lua
--- info.json saves to fs_homepath/fs_game/info.json
--- version: 2

--- History
--- Version 2
---   Fixed startup errors should run now
--- Version 1
---   Ready for testing

--- Notes
--TODO Make a tad prettier particularly handling weapons
--TODO If value == 0 then dont save ( Save a little on info.json )
local _time = os.time
local _pcall  = pcall
local _pairs = pairs
local tostring = tostring
local tonumber = tonumber
local loadfile = loadfile
local readPath     = string.gsub(et.trap_Cvar_Get("fs_basepath") .. "/" .. et.trap_Cvar_Get("fs_game") .. "/","\\","/")
local writePath    = string.gsub(et.trap_Cvar_Get("fs_homepath") .. "/" .. et.trap_Cvar_Get("fs_game") .. "/","\\","/")
_INFOTIME    = 2

JSON         = (loadfile(readPath .. "JSON.lua"))()
PlayerData = { }

local _debuglevel   = 1
local _debugto      = "" -- "zelly" for printing to clients wiht zelly in their name
local LEVEL_NONE    = 0
local LEVEL_INFO    = 1
local LEVEL_WARNING = 2
local LEVEL_DEBUG   = 4

local _print = function(msg,level)
    if ( level == nil ) then return end
    if ( level <= LEVEL_NONE ) then return end
    if ( _debuglevel <= LEVEL_NONE ) then return end
    if ( level == LEVEL_INFO ) and ( _debuglevel >= LEVEL_INFO ) then
        msg = "^ozinfo(info ): ^7" .. msg
    elseif ( level == LEVEL_WARNING ) and ( _debuglevel >= LEVEL_WARNING ) then
        msg = "^ozinfo(warn ): ^7" .. msg
    elseif ( level == LEVEL_DEBUG ) and ( _debuglevel >= LEVEL_DEBUG ) then
        msg = "^ozinfo(debug): ^7" .. msg
    else
        return
    end
    if ( _debugto ~= "" ) then
        et.trap_SendServerCommand (et.ClientNumberFromString( _debugto ), "print \""..msg.."\n\"")
    end
    et.G_LogPrint(et.Q_CleanStr(msg) .. "\n")
end

local _write = function()
    _print("Writing file...",LEVEL_DEBUG)
    local player_encode = JSON:encode( PlayerData )
    local FileObject = io.open( writePath .. "info.json" , "w" )
    FileObject:write(player_encode)
    FileObject:close()
    _print("Successfully wrote file...",LEVEL_DEBUG)
end

local _read = function()
    _print("Reading file...",LEVEL_DEBUG)
    local status,FileObject = pcall(io.open, writePath .. "info.json", "r")
    if not ( status ) or ( FileObject == nil ) then
        PlayerData = { }
        _print("Error reading file",LEVEL_WARNING)
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
        _print("Error reading info",LEVEL_WARNING)
    end
    _print("Done reading file...",LEVEL_DEBUG)
end

local _entget = function(clientNum,fieldname,type_expected)
    if ( type_expected == nil ) then type_expected = "string" end
    local status,value = _pcall(et.gentity_get,clientNum,fieldname)
    if not ( status ) then
        _print( "Error entget",LEVEL_WARNING)
        value = 0
    end
    
    if ( type_expected == "number" ) then
        value = tonumber(value)
        if value == nil then
            _print( "Error entget nil",LEVEL_WARNING)
            value = 0
        end
    else
        value = tostring(value)
    end
    return value
end

local _userinfo = function(clientNum)
    if not clientNum then return "" end
    if ( clientNum > 63 ) then return "" end
    return et.trap_GetUserinfo( clientNum ) 
end

local _ip = function(clientNum)
    return string.gsub(et.Info_ValueForKey( _userinfo(clientNum) , "ip" ), ":%d*","")
end

local _guid = function(clientNum)
    --local guid = et.Info_ValueForKey( _userinfo(clientNum) , "cl_guid" )
    local guid = _entget(clientNum,"sess.guid")
    guid = string.gsub(guid, ":%d*","")
    if ( string.len(guid) ~= 32 ) then
        guid = string.gsub(_ip(client),"%.","")
    end
    return guid
end

local _name = function(clientNum)
    return et.Q_CleanStr(et.Info_ValueForKey( _userinfo(clientNum) , "name" ))
end

local _bot = function(clientNum)
    if ( _ip(clientNum) == "localhost" ) then
        return true
    else
        return false
    end
end

local _create = function(clientNum,guid)
    if ( PlayerData[guid] == nil ) then
        _print("Creating guid slot " .. guid,LEVEL_DEBUG)
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
        PlayerData[guid].levelinfo[#PlayerData[guid].levelinfo+1] = { id=0, level=tonumber(et.G_shrubbot_level(clientNum)), leveler="none",levelername="none", }
        PlayerData[guid].ips[#PlayerData[guid].ips+1]             = _ip(clientNum)
        PlayerData[guid].names[#PlayerData[guid].names+1]         = _name(clientNum)
    end
    PlayerData[guid].starttime = _time()
end

local _active = function(clientNum)
    if ( _entget(clientNum,"pers.connected","number") == 2 ) then
        return true
    end
    return false
end

local _isgame = function(num)
    if num == nil then num = 0 end
    local gamestate = tonumber( et.trap_Cvar_Get( "gamestate" ) )
    if not ( gamestate == num ) then
        return false
    end
    return true
end

local _playersbots = function()
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

local _weapon = function(guid,weaponid)
    for k=1,#PlayerData[guid].weapons do
        if ( PlayerData[guid].weapons[k].id == weaponid ) then
            _print( "Found weapon " .. weaponid .. " in " .. guid,LEVEL_DEBUG)
            return PlayerData[guid].weapons[k]
        end
    end
    _print( "Created weapon " .. weaponid .. " in " .. guid,LEVEL_DEBUG)
    PlayerData[guid].weapons[#PlayerData[guid].weapons+1] = { id = weaponid, kills=0,deaths=0,botkills=0,botdeaths=0,teamkills=0,teamdeaths=0,worlddeaths=0,weapontime=0, }
    return PlayerData[guid].weapons[#PlayerData[guid].weapons]
end

local _addtime  = function(guid,players,bots)
    -- Kind of a over complex way of storing this stuff,but json wont allow me to save bottime[botamount] if 1 through botamount doesnt have a value
    -- Might find another way later, for now this is fine
    if ( players >= 0 ) then
        local f = false
        for k=1,#PlayerData[guid].playertime do
            if ( players == PlayerData[guid].playertime[k].players ) then
                PlayerData[guid].playertime[k].time = ( PlayerData[guid].playertime[k].time + _INFOTIME )
                f=true
            end
        end
        if not f then
            PlayerData[guid].playertime[#PlayerData[guid].playertime+1] = { players=players,time=_INFOTIME }
        end
    end
    if ( bots >= 0 ) then
        local f = false
        for k=1,#PlayerData[guid].bottime do
            if ( bots == PlayerData[guid].bottime[k].bots ) then
                PlayerData[guid].bottime[k].time = ( PlayerData[guid].bottime[k].time + _INFOTIME )
                f=true
            end
        end
        if not f then
            PlayerData[guid].bottime[#PlayerData[guid].bottime+1] = { bots=bots,time=_INFOTIME }
        end
    end
end

local _addipname = function(clientNum,guid)
    local name = et.Q_CleanStr(_name(clientNum))
    local ip   = _ip(clientNum)
    local f    = false
    local ff   = false
    for k=1,#PlayerData[guid].ips do
        if ( PlayerData[guid].ips[k] == ip ) then
            f = true
        end
    end
    for k=1,#PlayerData[guid].names do
        if ( PlayerData[guid].names[k] == name ) then
            ff = true
        end
    end
    if not ( f ) then PlayerData[guid].ips[#PlayerData[guid].ips+1] = ip end
    if not ( ff ) then
        PlayerData[guid].names[#PlayerData[guid].names+1] = name
        PlayerData[guid].lastname = name
    end
end

local _runframe = function()
    local maxclients = ( tonumber( et.trap_Cvar_Get( "sv_maxclients" ) ) - 1 )
    local curtime = _time()
    local players,bots = _playersbots()
    for clientNum=0, maxclients do
        if ( _active(clientNum) ) and not ( _bot(clientNum) ) then
            local guid = _guid(clientNum)
            if ( PlayerData[guid] == nil ) then _create(clientNum,guid) end
            if ( PlayerData[guid].starttime == nil ) then PlayerData[guid].starttime = curtime end
            local deltatime = ( curtime - PlayerData[guid].starttime )
            if ( deltatime >= _INFOTIME ) then
                _addipname(clientNum,guid)
                local team = _entget(clientNum,"sess.sessionTeam","number")
                if ( team == 1 ) or ( team == 2 ) then
                    local weapon = _weapon(guid,_entget(clientNum,"s.weapon","number"))
                    weapon.weapontime = ( weapon.weapontime + _INFOTIME )
                    _addtime(guid,players,bots)
                end
                if ( team == 2 ) then
                    PlayerData[guid].alliestime = ( PlayerData[guid].alliestime + _INFOTIME )
                elseif ( team == 1 ) then
                    PlayerData[guid].axistime = ( PlayerData[guid].axistime + _INFOTIME )
                else
                    PlayerData[guid].spectime = ( PlayerData[guid].spectime + _INFOTIME )
                end
            end
        end
    end
end

local _sortLevels = function(a,b) return tonumber(a.id) < tonumber(b.id) end
local _setlevel = function(clientNum,target,level,silent)
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

local _printdata = function(guid)
    _print("guid("..tostring(guid)..")",LEVEL_INFO)
    _print("PlayerData[guid]("..tostring(PlayerData[guid])..")",LEVEL_INFO)
    for i,v in _pairs(PlayerData[guid]) do
        _print( tostring(i)..": "..tostring(v),LEVEL_INFO)
        if ( type(v) == "table" ) then
            for i2,v2 in _pairs(v) do
                _print("  ^z"..tostring(i2)..": "..tostring(v2),LEVEL_INFO)
                if ( type(v2) == "table" ) then
                    for i3,v3 in _pairs(v2) do
                        _print("    ^z"..tostring(i3)..": "..tostring(v3),LEVEL_INFO)
                    end
                end
            end
        end
    end
end

function et_InitGame(levelTime, randomSeed, restart)
    et.RegisterModname ( "Zelly Info" )
    _read()
end

function et_ShutdownGame(restart)
    _print("gamestate: " .. tostring(et.trap_Cvar_Get( "gamestate" )),LEVEL_DEBUG)
    local curtime = _time()
    for guid,player in _pairs(PlayerData) do
        if ( string.len(guid) ~= 32 ) then player = nil end
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

function et_ClientBegin(clientNum)
    if not ( _isgame() ) then return end
    if ( _bot(clientNum) ) then return end
    local guid = _guid(clientNum)
    _create(clientNum,guid)
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
        PlayerData[victimguid].deaths = PlayerData[victimguid].worlddeaths + 1

        local weapon =_weapon(victimguid,_mod)
        weapon.worlddeaths = ( weapon.worlddeaths + 1 )

        _print( "worlddeath",LEVEL_DEBUG)
        return
    end
    if ( _bot(victim) ) and ( _bot(killer) ) then return end
    local victimteam = _entget(victim,"sess.sessionTeam","number")
    local killerteam = _entget(killer,"sess.sessionTeam","number")
    local killerguid = _guid(killer)
    if not ( _bot(killer) ) and ( PlayerData[killerguid] == nil ) then _create(killer,killerguid) end

    if ( killer == victim ) then
        PlayerData[killerguid].selfkills = PlayerData[killerguid].selfkills + 1
        local weapon = _weapon(killerguid,_mod)
        weapon.deaths = ( weapon.deaths + 1 )
        _print( "selfkill",LEVEL_DEBUG)
        return
    end
    if ( victimteam == killerteam ) then --Teamkills/teamdeaths takes priority over botkills/deaths
        if not ( _bot(killer) ) then
            PlayerData[killerguid].teamkills = PlayerData[killerguid].teamkills + 1
            local weapon = _weapon(killerguid,_mod)
            weapon.teamkills = ( weapon.teamkills + 1 )
            _print( "teamkill",LEVEL_DEBUG)
        end
        if not ( _bot(victim) ) then
            local weapon = _weapon(victimguid,_mod)
            weapon.teamdeaths = ( weapon.teamdeaths + 1 )
            _print( "teamdeath",LEVEL_DEBUG)
        end
        return
    end
    if ( _bot(victim) ) then
        PlayerData[killerguid].botkills = PlayerData[killerguid].botkills + 1
        local weapon = _weapon(killerguid,_mod)
        weapon.botkills = ( weapon.botkills + 1 )
        _print( "botkill",LEVEL_DEBUG)
        return
    end
    if ( _bot(killer) ) then
        PlayerData[victimguid].botdeaths = PlayerData[victimguid].botdeaths + 1
        local weapon = _weapon(victimguid,_mod)
        weapon.botdeaths = ( weapon.botdeaths + 1 )
        _print( "botdeath",LEVEL_DEBUG)
        return
    end
    PlayerData[victimguid].deaths = PlayerData[victimguid].deaths + 1
    PlayerData[killerguid].kills = PlayerData[killerguid].kills + 1
    
    local kweapon = _weapon(killerguid,_mod)
    local vweapon = _weapon(victimguid,_mod)
    kweapon.kills = ( kweapon.kills + 1 )
    vweapon.deaths = ( vweapon.deaths + 1 )
    _print( "kill|death",LEVEL_DEBUG)
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
--[[
    elseif ( Arg0 == "test" ) then
        _printdata(_guid(clientNum))
        return 1
    elseif ( Arg0 == "save" ) then
        _print("Writing table")
        _write()
        return 1
    elseif ( Arg0 == "getteam" ) then   
        local team = _entget(clientNum,"sess.sessionTeam","number")
        _print( tostring(team) )
        return 1]]---
    end
end
