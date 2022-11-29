local effects = require("x-scenes.ingame.ingame-effects")
local messageBus = require("x-framework.message-bus")
local promise = require("x-framework.promise")
local easing = require("easing")
local controller = {}

function controller:shuffleArray(arr)
    local shuffled = {}
    while #arr > 0 do
        local randomIndex = math.random(1, #arr)
        local card = table.remove(arr, randomIndex)
        shuffled[#shuffled + 1] = card

    end
    for i = 1, #shuffled do
        arr[i] = shuffled[i]
    end
end

function controller:shuffleDeck(deck, p, skipShuffle)
    return promise(function(resolve)
        if not skipShuffle then self:shuffleArray(deck) end
        effects:deckToFront(deck)
        effects:shuffleDeck(deck, p)
            :thenCall(function() resolve() end)
            :catchAndPrint()
    end)
end

function controller:rotateMonsters(deck)
    local p1, p2, p3 = { x = 475, y = 180 }, { x = 440, y = 480 }, { x = 610, y = 480 }
    if #deck == 1 then
        return effects:rotateMonsters({ deck[1] }, { p1 })
    elseif #deck == 2 then
        local m1, m2 = deck[1], deck[2]
        deck[1] = m2
        deck[2] = m1
        return effects:rotateMonsters({ deck[1], deck[2] }, { p1, p2 })
    else
        local m1, m2, m3 = deck[1], deck[2], deck[3]
        deck[1] = m3
        deck[2] = m1
        deck[3] = m2
        return effects:rotateMonsters({ deck[1], deck[2], deck[3], }, { p1, p2, p3 })
    end
end

function controller:turnCard(card)
    return promise(function(resolve)
        card:flipCard()
            :thenCall(function() resolve() end)
            :catchAndPrint()
    end)
end

function controller:moveToBottom(card, deck, pos)
    return promise(function(resolve)
        local r = 400
        -- move card to pos 1
        for i = 1, #deck do
            if deck[i] == card then
                table.remove(deck, i)
                break
            end
        end
        table.insert(deck, 1, card)
        effects:deckToFront(deck)
        local tempDeck = {}
        for i = 2, #deck do
            tempDeck[i - 1] = deck[i]
        end
        effects:lineSpreadDeck(tempDeck, r)
            :thenCall(function() return effects:moveCardToPos(card, pos) end)
            :thenCall(function() return effects:flipCard(card, true) end)
            :thenCall(function()
                effects:deckToFront(deck)
                messageBus:post(messageBus.play_sfx, { name = "shuffleshort" })
                return effects:positionDeck(tempDeck, easing.inCubic, pos)
            end)
            :thenCall(function() resolve() end)
            :catchAndPrint()

    end)
end

function controller:removeHandlersFromDeck(deck)
    for i = 1, #deck do
        deck[i]:removeHandlers()
    end
end

function controller:removeHandlersFromDecks(decks)
    for j = 1, #decks do
        local deck = decks[j]
        for i = 1, #deck do
            deck[i]:removeHandlers()
        end
    end
end

return controller;
