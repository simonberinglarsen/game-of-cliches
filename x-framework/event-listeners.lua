local messageBus = require('x-framework.message-bus')

local eventListeners = {}
eventListeners.__index = eventListeners

function eventListeners:new(listeners)
    local o = {}
    setmetatable(o, eventListeners)
    o.myEventListeners = listeners
    for i = 1, #o.myEventListeners do
        local listener = o.myEventListeners[i]
        messageBus:register(listener[1], listener[2])
    end
    return o
end

function eventListeners:destroy()
    if not self.myEventListeners then
        return
    end
    for i = 1, #self.myEventListeners do
        local listener = self.myEventListeners[i]
        messageBus:remove(listener[1], listener[2])
    end
    self.myEventListeners = nil
end

return eventListeners
