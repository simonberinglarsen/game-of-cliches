local messageBus = require("x-framework.message-bus")
local effects = require("x-scenes.ingame.ingame-effects")
local controller = require("x-scenes.ingame.ingame-controller")
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
    context:createCards(context.modelstate.cardView)
    messageBus:post(messageBus.play_sfx, { name = "shuffle" })
    -- skip shuffling when debugging sometimes help
    local skipShuffle = false
    controller:shuffleDeck(context.modelstate.hand, { x = 135, y = 480 }, skipShuffle)
        :thenCall(function()
            messageBus:post(messageBus.play_sfx, { name = "shuffle" })
            return controller:shuffleDeck(context.modelstate.powerOfClicheDeck, { x = 135, y = 190 },
                skipShuffle)
        end)
        :thenCall(function()
            return promise.all({
                controller:turnCard(context.modelstate.hand[#context.modelstate.hand]),
                effects:dealDeck({
                    context.modelstate.opponents[1],
                    context.modelstate.monsters[1],
                    context.modelstate.monsters[2],
                    context.modelstate.monsters[3],
                }, {
                    { x = 800, y = 180 },
                    { x = 475, y = 180 },
                    { x = 440, y = 480 },
                    { x = 610, y = 480 },
                })
            })
        end)
        :thenCall(function()
            context:transitionTo(states.playerTurn)
        end)
        :catchAndPrint()
end

return state
