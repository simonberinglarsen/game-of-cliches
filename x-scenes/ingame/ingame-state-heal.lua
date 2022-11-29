local settings = require("x-framework.settings")
local messageBus = require("x-framework.message-bus")
local promise = require("x-framework.promise")
local states = require("x-scenes.ingame.ingame-states")


local state = {}
state.__index = state

function state:new(context)
    local o = {}
    setmetatable(o, state)
    o.context = context
    return o
end

function state:init()
    local context = self.context
    context:markerTo(3)
    local animations = {}
    for i = 2, #context.modelstate.monsters do
        animations[#animations + 1] = promise(function(resolve)
            timer.performWithDelay((500 * (i - 1)) * settings.animationSpeed, function()
                local card = context.modelstate.monsters[i]
                messageBus:post(messageBus.play_sfx, { name = "healing", delay = 500 })
                card:addHealth(1)
                    :thenCall(function() resolve() end)
                    :catchAndPrint()
            end)
        end)
    end
    promise.all(animations)
        :thenCall(function() context:transitionTo(states.computerTurn) end)
        :catchAndPrint()
end

return state
