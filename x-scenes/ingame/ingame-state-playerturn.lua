local card = require("x-scenes.ingame.ingame-card")
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
    context:markerTo(1)
    local continue = function()
        local hand = context.modelstate.hand[#context.modelstate.hand]
        local activeMonster = context.modelstate.monsters[1]
        hand:makeDraggable()
        activeMonster:makeDraggable()
        if hand.type == "power" then
            hand:setTargets({
                context.modelstate.powerOfClicheDeck[#context.modelstate.powerOfClicheDeck]
            })
        elseif hand.type == "attack" or hand.type == "defence" then
            hand:setTargets({
                context.modelstate.monsters[1],
                context.modelstate.monsters[2],
                context.modelstate.monsters[3],
            })
        end
        activeMonster:setTargets({
            context.modelstate.opponents[1],
        })
    end
    continue()
end

function state:cardAttached(source, dest)
    local context = self.context
    if (source.deck == "hand" and dest.deck == "powerOfClicheDeck") then
        context:removeHandlersFromAllDecks()
        self:handToPower(source)
    end
    if (source.deck == "monster" and dest.deck == "opponents") then
        context:removeHandlersFromAllDecks()
        self:attack()
    end
    if (source.deck == "hand" and dest.deck == "monster") then
        context:removeHandlersFromAllDecks()
        self:upgrade(source, dest)
    end
end

function state:upgrade(source, dest)
    local context = self.context
    controller:moveToBottom(source, context.modelstate.hand, { x = 135, y = 480 })
        :thenCall(function() return context:upgradeCard(source, dest) end)
        :thenCall(function()
            context:transitionTo(states.retreatOrStay)
        end)
        :catchAndPrint()
end

function state:attack()
    local context = self.context
    local modelstate = context.modelstate
    local opponents = modelstate.opponents
    local oppHealth = opponents[1].stats.health
    opponents[1]:takeDamage(modelstate.monsters[1].stats.attack)
        :thenCall(function()
            local oppHealthAfter = opponents[1].stats.health
            local x, y = display.contentWidth / 2 + 100, display.contentHeight / 2 - 200
            if oppHealthAfter == 0 then
                return context:showTimedDialog({
                    text = "ARGG!",
                    x = x, y = y
                }, 3000)
                    :thenCall(function()
                        return effects:dead(opponents[1])
                    end)
                    :thenCall(function()
                        opponents[1]:dispose()
                        table.remove(opponents, 1)
                    end)
                    :catchAndPrint()
            elseif oppHealth == oppHealthAfter then
                messageBus:post(messageBus.play_sfx, { name = "defence" })
                local waitForCardToReturn = promise(function(resolve) timer.performWithDelay(500,
                        function() resolve() end)
                end)
                return waitForCardToReturn
            else
                return context:showTimedDialog({
                    text = "\ngrrr!",
                    x = x, y = y
                }, 2000)
            end
        end)
        :thenCall(function()
            if #opponents > 0 then
                context:transitionTo(states.retreatOrStay)
            else
                context:transitionTo(states.win)
            end
        end)
        :catchAndPrint()
end

function state:handToPower(source)
    local context = self.context
    local modelstate = context.modelstate
    local clicheDeck = modelstate.powerOfClicheDeck
    local handDeck = modelstate.hand
    local topClicheCard = clicheDeck[#clicheDeck]

    controller:moveToBottom(source, handDeck, { x = 135, y = 480 })
        :thenCall(function() return controller:turnCard(handDeck[#handDeck]) end)
        :thenCall(function() return controller:turnCard(clicheDeck[#clicheDeck]) end)
        :thenCall(function() return effects:moveCardToPos(
                topClicheCard,
                {
                    x = display.contentWidth / 2,
                    y = display.contentHeight / 2,
                })
        end)
        :thenCall(function()
            return effects:scaleCard(topClicheCard, 1)
        end)
        :thenCall(function()
            topClicheCard:showDraggable(true)
            local p = promise(function(resolve)
                topClicheCard:addHandler({
                    view = topClicheCard:getView(),
                    event = "touch",
                    h = function()
                        topClicheCard:removeHandlers()
                        effects:scaleCard(topClicheCard, 0.5)
                            :thenCall(function() resolve() end)
                            :catchAndPrint()
                    end
                })
            end)
            return p
        end)
        :thenCall(function() return effects:positionDeck({ topClicheCard }, easing.inCubic, { x = 833, y = 462 }) end)
        :thenCall(function() return self:powerCard(topClicheCard) end)
        :thenCall(function() return controller:moveToBottom(topClicheCard, clicheDeck, { x = 135, y = 190 }) end)
        :thenCall(function() context:transitionTo(states.retreatOrStay) end)
        :catchAndPrint()
    return
end

function state:powerCard(card)
    if card.type == "cliche9" then return self:cliche9() end
    if card.type == "cliche8" then return self:cliche8() end
    if card.type == "cliche7" then return self:cliche7() end
    if card.type == "cliche6" then return self:cliche6() end
    if card.type == "cliche5" then return self:cliche5() end
    if card.type == "cliche4" then return self:cliche4() end
    if card.type == "cliche3" then return self:cliche3() end
    if card.type == "cliche2" then return self:cliche2() end
    if card.type == "cliche1" then return self:cliche1() end
    assert(false, "UNKNOWN CLICHE CARD!")
end

function state:cliche9()
    local context = self.context
    local actions = {}
    for i = 1, #context.modelstate.monsters do
        local card = context.modelstate.monsters[i]
        local attack = card.stats.attack
        local defence = card.stats.defence
        if attack > 0 then
            actions[#actions + 1] = card:addAttack(-attack)
        end
        if defence > 0 then
            actions[#actions + 1] = card:addDefence(-defence)
        end
    end
    return promise.all(actions)
        :catchAndPrint()
end

function state:cliche8()
    local context = self.context
    local actions = {}
    local monster = context.modelstate.monsters[1]
    local opponent = context.modelstate.opponents[1]
    local myAttack = monster.stats.attack
    local myDefence = monster.stats.defence
    local hisAttack = opponent.stats.attack
    local hisDefence = opponent.stats.defence
    actions[#actions + 1] = monster:addAttack(-myAttack + hisAttack)
    actions[#actions + 1] = monster:addDefence(-myDefence + hisDefence)
    actions[#actions + 1] = opponent:addAttack(-hisAttack + myAttack)
    actions[#actions + 1] = opponent:addDefence(-hisDefence + myDefence)
    return promise.all(actions)
        :catchAndPrint()
end

function state:cliche7()
    local context = self.context
    local actions = {}
    local monster = context.modelstate.monsters[1]
    actions[#actions + 1] = monster:addDefence(2)
    return promise.all(actions)
        :catchAndPrint()
end

function state:cliche6()
    local context = self.context
    local actions = {}
    local monsterDeck = context.modelstate.monsters
    if #monsterDeck == 3 then return end

    local hasMonster = function(type)
        for i = 1, #monsterDeck do
            local card = monsterDeck[i]
            if card.type == type then
                return card
            end
        end
        return nil
    end

    local insertNewMonster = function(type)
        local view = context.modelstate.cardView
        local newcard = card:new(view, type)
        newcard.front:toBack();
        newcard.back:toBack();
        monsterDeck[#monsterDeck + 1] = newcard
        return controller:rotateMonsters(monsterDeck)
            :thenCall(function() return newcard:flipCard() end)
            :catchAndPrint()
    end

    if not hasMonster("monster1") then
        actions[#actions + 1] = insertNewMonster("monster1")
    elseif not hasMonster("monster2") then
        actions[#actions + 1] = insertNewMonster("monster2")
    elseif not hasMonster("monster3") then
        actions[#actions + 1] = insertNewMonster("monster3")
    end

    return promise.all(actions)
        :catchAndPrint()
end

function state:cliche5()
    local actions = {}
    local context = self.context
    local monsterDeck = context.modelstate.monsters
    local randomIndex = math.random(1, #monsterDeck)
    local card = monsterDeck[randomIndex]
    local myAttack = card.stats.attack
    local myDefence = card.stats.defence
    actions[#actions + 1] = card:addAttack(-myAttack + myDefence)
    actions[#actions + 1] = card:addDefence(-myDefence + myAttack)
    return promise.all(actions)
        :catchAndPrint()
end

function state:cliche4()
    local actions = {}
    local context = self.context
    local monsterDeck = context.modelstate.monsters
    for i = 1, #monsterDeck do
        local card = monsterDeck[i]
        actions[#actions + 1] = card:addHealth(2)
    end
    return promise.all(actions)
        :catchAndPrint()
end

function state:cliche3()
    local actions = {}
    local context = self.context
    local monsterDeck = context.modelstate.monsters
    local card = monsterDeck[1]
    actions[#actions + 1] = card:addDefence(-card.stats.defence)
    return promise.all(actions)
        :catchAndPrint()
end

function state:cliche2()
    local context = self.context
    local handDeck = context.modelstate.hand
    local skipShuffle = true
    local topCard = handDeck[#handDeck]
    for i = #handDeck, 1, -1 do
        local card = handDeck[i]
        if card.type == "power" then
            local powerCard = table.remove(handDeck, i)
            handDeck[#handDeck + 1] = powerCard
        end
    end
    return controller:turnCard(topCard)
        :thenCall(function() return controller:shuffleDeck(handDeck, { x = 135, y = 480 }, skipShuffle) end)
        :thenCall(function() return controller:turnCard(handDeck[#handDeck]) end)
        :catchAndPrint()
end

function state:cliche1()
    local context = self.context
    local monsterDeck = context.modelstate.monsters
    local avg = 0
    local statCount = 0
    for i = 1, #monsterDeck do
        local card = monsterDeck[i]
        avg = avg + card.stats.attack
        avg = avg + card.stats.defence
        avg = avg + card.stats.health
        statCount = statCount + 3
    end
    avg = math.floor(avg / statCount)
    if avg == 0 then avg = 1 end
    local a = promise(function(resolve) resolve() end)
    for i = 1, #monsterDeck do
        local card = monsterDeck[i]
        a = a:thenCall(function() return promise.all({
                card:addAttack(-card.stats.attack + avg),
                card:addHealth(-card.stats.health + avg),
                card:addDefence(-card.stats.defence + avg),
            })
        end)

    end
    return a
        :catchAndPrint()
end

return state
