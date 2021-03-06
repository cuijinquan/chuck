package.path = './lib/?.lua;'
package.cpath = './lib/?.so;'

local protobuf = require "protobuf"
local chuck = require("chuck")
local socket = chuck.socket
local event_loop = chuck.event_loop.New()
local log = chuck.log

local addr = io.open("test/lua/addressbook.pb","rb")
local pb_buffer = addr:read "*a"
addr:close()

protobuf.register(pb_buffer)

local event_loop = chuck.event_loop.New()

socket.stream.ip4.dail(event_loop,"127.0.0.1",8010,function (fd,errCode)
	if 0 ~= errCode then
		print("connect error:" .. errCode)
		return
	end
	local conn = socket.stream.New(fd,4096)
	if conn then

		print("connect ok")

		local addressbook = {
			name = "Alice",
			id = 12345,
			phone = {
				{ number = "1301234567" },
				{ number = "87654321", type = "WORK" },
			}
		}

		local buff = chuck.buffer.New()
		local code = protobuf.encode("tutorial.Person", addressbook)
		buff:AppendStr(code)
		conn:Send(buff,function ()
			conn:Close()
			print("send finish")
			print("PendingSendSize:" .. conn:PendingSendSize())
			event_loop:Stop()
		end)
		print("PendingSendSize:" .. conn:PendingSendSize())

		conn:Start(event_loop,function (data)
			if data then 
				print("got response")
				conn:Close()
			else
				print("client disconnected") 
				conn:Close()
			end
		end)
	end
end)

event_loop:WatchSignal(chuck.signal.SIGINT,function()
	print("recv SIGINT stop client")
	event_loop:Stop()
end)

event_loop:Run()