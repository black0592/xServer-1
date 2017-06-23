local skynet = require "skynet"
local cluster = require "skynet.cluster"
require "skynet.manager"

skynet.start(function()
    -- start logindb
    local gamedb = skynet.newservice("xmysql", "master", assert(tonumber(skynet.getenv("db_instance"))))
    skynet.name(".gamedb", gamedb)
    -- start gamesvr
    local gamesvr = skynet.uniqueservice("gamesvr")
    skynet.name(".gamesvr", gamesvr)
    cluster.open("gamesvr")
    -- start gamegate
    -- tcp gate
    local game_port_tcp = assert(tonumber(skynet.getenv("game_port_tcp")))
    local game_address = assert(skynet.getenv("game_address"))
    local conf = {
        address = game_address,
        port = game_port_tcp,
        maxclient = assert(tonumber(skynet.getenv("maxclient"))),
        nodelay = skynet.getenv("nodelay") == "true"
    }
    local gamegate_tcp = skynet.newservice("xgate_tcp", gamesvr)
    skynet.call(gamegate_tcp, "lua", "open", conf)
    -- websocket gate
    local game_port_ws = assert(tonumber(skynet.getenv("game_port_ws")))
    local gamegate_ws = skynet.newservice("xgate_ws", gamesvr)
    skynet.call(gamegate_ws, "lua", "open", string.format("%s:%d", game_address, game_port_ws))
    -- start debug console
    local debug_console_port = assert(tonumber(skynet.getenv("debug_console_port")))
    skynet.newservice("debug_console", "0.0.0.0", debug_console_port)
    skynet.newservice("xconsole")
    skynet.exit()
end)