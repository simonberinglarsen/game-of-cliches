local messageBus = require("x-framework.message-bus")
local effects = require("x-scenes.ingame.ingame-effects")
local controller = require("x-scenes.ingame.ingame-controller")
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
    local playerCard = context.modelstate.monsters[1]
    local opponentCard = context.modelstate.opponents[1]
    local warn = function()
        return context:showTimedDialog({
            text = "MY turn!\n..let me see..",
            x = display.contentWidth / 2 + 100,
            y = display.contentHeight / 2 - 200,
        }, 3000)
    end
    local upgrade = function()
        return context:showTimedDialog({
            text = "...hmm...\nupgrade",
            x = display.contentWidth / 2 + 100,
            y = display.contentHeight / 2 - 200,
        }, 3000)
            :thenCall(function()
                messageBus:post(messageBus.play_sfx, { name = "drawsword", delay = 500 })
                return opponentCard:addAttack(1)
            end)
            :catchAndPrint()
    end
    local attack = function()
        return effects:opponentAttacks(opponentCard, playerCard)
            :thenCall(function() return playerCard:takeDamage(opponentCard.stats.attack) end)
            :thenCall(function()
                local card = playerCard
                if card.stats.health == 0 then
                    messageBus:post(messageBus.play_sfx, { name = "deadcard" })
                    return effects:dead(card)
                        :thenCall(function()
                            card:dispose()
                            table.remove(context.modelstate.monsters, 1)
                            if #context.modelstate.monsters > 0 then
                                return controller:rotateMonsters(context.modelstate.monsters)
                            end
                            messageBus:post(messageBus.play_sfx, { name = "gameover" })
                            messageBus:post(messageBus.show_game_over_screen)
                        end)
                        :catchAndPrint()
                end
            end)
            :catchAndPrint()
    end

    -- determine action!
    local computerAttack = opponentCard.stats.attack
    local playerDefence = playerCard.stats.defence
    context:markerTo(4)
    local seq = warn()
    if computerAttack > playerDefence then
        seq = seq:thenCall(function() return attack() end)
    else
        seq = seq:thenCall(function() return upgrade() end)
    end
    seq
        :thenCall(function() context:transitionTo(states.playerTurn) end)
        :catchAndPrint()
end

return state
