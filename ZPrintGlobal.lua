-- Zelly's Global Printer
-- Xfire : anewxfireaccount
-- Feel free to report problems to my xfire
-- https://github.com/Zelly/ZellyLuas for latest version
-- version: 1

-- get _G (lua globals) table /gettable
-- get et global table /gettable et

-- following commands were for my custom legacy build:
-- they require ps.classWeaponTime to be registered
-- get chargetime /getct
-- set chargetime full /setct

local _longestString = function(t)
    local longest = 0
    for k=1, #t do
        local length = string.len(tostring(et.Q_CleanStr(t[k])))
        if ( length > longest ) then
            longest = length
        end
    end
    return longest
end

local _staticString = function(str,length,sep,center)
    if ( str == nil) then str = " " end -- Make sure there is something
    str = tostring(str) -- Make sure its some sort of string
    if ( length == nil ) then return str end
    if ( sep == nil ) then
        sep = " "
    end
    local strlength = string.len(et.Q_CleanStr(str))
    if ( center ~= true ) then
        center = false
    end

    if ( tonumber(length) == nil ) then -- If it was a string, make it that strings length
        length = string.len(et.Q_CleanStr(length))
    end
    length = tonumber(length) -- If it was a string number then make sure its in number form

    if ( strlength > length ) then
        str = string.sub(et.Q_CleanStr(str),1,length) -- Have to lose colors here, or else its going to be wrong
        return str
    end
    if ( center ) then
        local pad_max = math.floor(( length - strlength ) / 2)
        local padding = ""
        for x=0, pad_max-1 do
            padding = padding .. sep
        end
        str = padding .. str .. padding
    end
    for x = string.len(et.Q_CleanStr(str)),(length-1),1 do
        str =  str .. sep
    end
    return str
end

local _formatTable = function(Data,Padding,Banner,Center)
    if ( Center ~= true ) then Center = false end
    if ( type(Banner) == "table" ) then -- Vertical Table (Data is table of tables) (Length of each column determined by BannerKey)
        local datastring = ""
        local Str = { }
        Str[1] = ""
        Str[2] = Padding
        for k=1, #Banner do
            Str[2] = Str[2] .. " " .. _staticString(Banner[k],Banner[k]," ",true) .. " " .. Padding
        end
        for c=2,string.len(et.Q_CleanStr(Str[2])) do
            datastring = datastring .. Padding
        end
        Str[1] = Padding .. et.Q_CleanStr(datastring)
        for x=1,#Data do
            datastring = Padding
            for y=1, #Data[x] do
                datastring = datastring .. " " .. _staticString(Data[x][y],Banner[y]," ",true) .. " " .. Padding
            end
            Str[#Str+1] = datastring
        end
        Str[#Str+1] = Str[1]
        return Str
    elseif ( type(Banner) == "number" ) then -- Horizontal Table (Data is one table) ( Length of column determined by greatest length in data )
        local length = _longestString(Data)+1 -- HOTFIX Some data are stuck together
        local Str = { }
        local l = ( 3 ) + ( length * ( Banner ) ) -- [START][SPACE][LENGTH*BANNER][SPACE][END]
        Str[1] = Padding
        for a=1, l do
            Str[1] = Str[1] .. et.Q_CleanStr(Padding)
        end
        
        local datastring = ""
        for b=1,#Data do
            datastring = datastring .. _staticString(Data[b],length," ",Center)
            if ( b == #Data ) then
                local x = (Banner - ( #Data - ( math.floor( #Data / Banner ) * Banner)))
                if ( #Data <= Banner ) then
                    x = Banner - #Data
                end
                if ( x == Banner ) then
                     x = 0
                end
                datastring = datastring .. _staticString(" ",x * length," ",Center)
                Str[#Str+1] = Padding .. " " .. datastring .. " " .. Padding
            elseif ( b % Banner == 0 ) then
                Str[#Str+1] = Padding .. " " .. datastring .. " " .. Padding
                datastring = ""
            end
        end
        Str[#Str+1] = Str[1]
        return Str
    end
end

local _print = function(msg)
    et.trap_SendServerCommand (-1, "print \""..msg.."\n\"")
end

_printTables = function(t,tName)
    local Data = { }
    Data[#Data+1] = { tName, type(t),tostring(t),}
    for key,value in pairs(t) do
        Data[#Data+1] = { tostring(key),type(value),tostring(value), }
        if ( type(value) == "table" ) then
            --[[local nextTable = _printTables(value,key)
            for k=1,#nextTable do
                Data[#Data+1] = nextTable[k]
            end
            --]]
        end
    end
    return Data
end
function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
	 table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end
local _getTableName = function(str)
    if ( str == nil ) then return _G end
    if ( str == "_G" ) then return _G end
    local splitstr = split(str,"%.")
    local t = _G
    for k=1,#splitstr do
        _print("k"..k..": " .. splitstr[k])
        t=t[splitstr[k]]
    end
    return t
end
local _currentLevelTime = 0
local _nextLevelTime = -1

function et_RunFrame(levelTime)
    _currentLevelTime = levelTime
    if ( _nextLevelTime == levelTime ) then
        _print("Charge Complete")
    end
end


function et_ClientCommand(clientNum,command)
    local Arg0 = string.lower(et.trap_Argv(0))
    
    if ( Arg0 == "gettable"  ) then
        local TableName = _getTableName(et.trap_Argv(1))
        local Data = _printTables(TableName,Args)
        local PT = _formatTable(Data,"-",{ "         DATANAME          ", "  TYPE  " , "                        DATA                        ",})
        for k=1,#PT do
            _print(PT[k])
        end
        return 1
    elseif ( Arg0 == "getct" ) then
        _nextLevelTime = tonumber(et.gentity_get(clientNum,"ps.classWeaponTime"))
        _print("<->NLT(" .. tostring(_nextLevelTime) .. ") - CLT(" .. tostring(_currentLevelTime) .. ") ="  .. tostring( _currentLevelTime - _nextLevelTime))
        return 1
    elseif ( Arg0 == "setct" ) then
        et.gentity_set(clientNum,"ps.classWeaponTime",-999999)
        return 1
    end
end
