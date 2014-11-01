-- Zelly's VoiceChat Debugger
-- Xfire : anewxfireaccount
-- Made for jemstar <3
-- Feel free to report problems to my xfire
-- https://github.com/Zelly/ZellyLuas for latest version
-- Log saves to fs_homepath/fs_game/voicechat.log
-- You can have it stream a log or just have it save the entire log at the end of the round
-- version: 3
-- VERSION HISTORY:
-- 3 Added ability to print to chat when voice chat happens
-- 2 Fixed some errors
-- 1 Intial release

local _writePath  = string.gsub(et.trap_Cvar_Get("fs_homepath") .. "/" .. et.trap_Cvar_Get("fs_game") .. "/voicechat.log","\\","/")
local _StreamFile = true    -- If you want it to save after each new log, then set this true, false saves at end of round
local _PrintChat  = false   -- Set to true if you want to debug while your ingame, probably more useful now that I think about it

local LogFile = { }

local _Save = function()
    if ( LogFile == nil ) or ( next(LogFile) == nil ) then return end
    local FileObject = io.open( _writePath , "a" )
        for k=1,#LogFile do
            FileObject:write(LogFile[k])
        end
    FileObject:close()
    LogFile = { }
end

local _Log = function(message)
    et.G_LogPrint( "VSAY_CHECK: " .. message .. "\n")
    LogFile[#LogFile+1] = os.date("[%X]") .. " " .. message .. "\n"
    if ( _PrintChat  ) then
        et.trap_SendServerCommand (clientNum, "chat \"^ovcdebug: ^7"..message.."\"")
    end
    if ( _StreamFile ) then
        _Save()
    end
end

function et_ClientCommand(clientNum,command)
    local Arg0 = string.lower(et.trap_Argv(0))
    if ( string.find(Arg0,"vsay",1,true) ) then
        _Log("(" .. tostring(clientNum) .. ") " .. tostring(et.ConcatArgs(0)))
        return 0
    end
end

function et_ShutdownGame(restart)
    _Save()
end
