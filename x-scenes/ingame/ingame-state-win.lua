local messageBus = require("x-framework.message-bus")


local state = {}
state.__index = state

function state:new(context)
    local o = {}
    setmetatable(o, state)
    o.context = context
    return o
end

function state:init()
    messageBus:post(messageBus.show_levelcomplete_screen)
end

return state
