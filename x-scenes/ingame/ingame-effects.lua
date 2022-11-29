local settings = require("x-framework.settings")
local messageBus = require("x-framework.message-bus")
local promise = require("x-framework.promise")
local transition = require("transition")
local easing = require("easing")

local effects = {}
local cardAngleMistake = 4

function effects:closeDialog(v)
    v.removeHandlers()
    transition.to(v, {
        time = 500 * settings.animationSpeed,
        transition = easing.outQuad,
        y = v.y - 50,
        alpha = 0,
        onComplete = function() v:removeSelf() end
    })
end

function effects:showDialog(v, x)
    transition.to(v, {
        time = 300 * settings.animationSpeed,
        transition = easing.outCirc,
        x = x,
        alpha = 1
    })
end

function effects:centerDeck(deck, easingType)
    return promise(function(resolve)
        local completed = 0
        local dt = 150 / #deck
        for i = 1, #deck do
            transition.to(deck[i]:getView(), {
                time = (150 + dt * i) * settings.animationSpeed,
                transition = easingType,
                x = display.contentWidth / 2,
                y = display.contentHeight / 2,
                rotation = math.random(-cardAngleMistake, cardAngleMistake),
                onComplete = function()
                    completed = completed + 1
                    if completed == #deck then
                        resolve()
                    end
                end
            })
        end
    end)
end

function effects:opponentAttacks(opponentCard, playerCard)
    return promise(function(resolve)
        local oppv = opponentCard:getView()
        local playerv = playerCard:getView()
        local x1, y1, x2, y2 = oppv.x, oppv.y, playerv.x, playerv.y
        oppv:toFront()
        transition.to(oppv, {
            time = 400 * settings.animationSpeed,
            transition = easing.inOutCubic,
            x = x2,
            y = y2,
            rotation = 45,
            onComplete = function()
                oppv:toBack()
                resolve()
                transition.to(oppv, {
                    time = 200 * settings.animationSpeed,
                    transition = easing.inOutCubic,
                    x = x1,
                    y = y1,
                    rotation = math.random(-cardAngleMistake, cardAngleMistake),
                    onComplete = function()
                    end
                })
            end
        })
    end)
end

function effects:randomSpreadDeck(deck, easingType)
    return promise(function(resolve)
        local completed = 0
        for i = 1, #deck do
            local r = 150
            local t = math.random() * math.pi * 2
            transition.to(deck[i]:getView(), {
                time = (150 + 10 * i) * settings.animationSpeed,
                transition = easingType,
                x = math.cos(t) * (r + math.random(1, 50)) + display.contentWidth / 2,
                y = math.sin(t) * (r + math.random(1, 50)) + display.contentHeight / 2,
                rotation = math.random(-45, 45),
                onComplete = function()
                    completed = completed + 1
                    if completed == #deck then
                        resolve()
                    end
                end
            })
        end
    end)
end

function effects:positionDeck(deck, easingType, p)
    return promise(function(resolve)
        local completed = 0
        for i = 1, #deck do
            transition.to(deck[i]:getView(), {
                time = (200 + 40 * i) * settings.animationSpeed,
                transition = easingType,
                x = p.x + i * 1,
                y = p.y - i * 2,
                rotation = math.random(-cardAngleMistake, cardAngleMistake),
                onComplete = function()
                    completed = completed + 1
                    if completed == #deck then
                        resolve()
                    end
                end
            })
        end
    end)
end

function effects:shuffleDeck(deck, p)
    return self:centerDeck(deck, easing.inOutSine)
        :thenCall(function() return self:spreadIntoTwo(deck) end)
        :thenCall(function() return self:centerDeck(deck, easing.inOutSine) end)
        :thenCall(function() return self:positionDeck(deck, easing.inCubic, p) end)
        :catchAndPrint()
end

function effects:spreadIntoTwo(deck)
    return promise(function(resolve)
        local completed = 0
        local halfDeckSize = #deck / 2
        local dt = 600 / #deck
        for i = 1, #deck do
            local card = deck[i]
            local x = display.contentWidth / 2
            local r = i / #deck * 45
            if i % 2 == 0 then
                x = x - (50 + i * 10)
                r = -r
            else
                x = x + (50 + i * 10)
            end
            timer.performWithDelay(i * dt, function()
                transition.to(deck[i]:getView(), {
                    time = 300 * settings.animationSpeed,
                    x = x,
                    y = display.contentHeight / 2 + (i - halfDeckSize) * 5,
                    transition = easing.inOutCubic,
                    rotation = r,
                    onComplete = function()
                        completed = completed + 1
                        if completed == #deck then
                            resolve()
                        end
                    end
                })
            end)
        end
    end)
end

function effects:flipCard(card, toBack)
    return promise(function(resolve)
        local maxScale = card:getView().xScale
        local minScale = 0.01
        local flipAngle = math.random(-25, 25)
        if toBack then
            card:getView():toBack()
        end
        transition.to(card:getView(), {
            time = 200 * settings.animationSpeed,
            transition = easing.inCubic,
            rotation = flipAngle,
            xScale = minScale,
            onComplete = function()
                card.front.isVisible = not card.front.isVisible
                card.back.isVisible = not card.back.isVisible
                card:getView().rotation = flipAngle
                card:getView().xScale = minScale
                if toBack then
                    card:getView():toBack()
                else
                    card:getView():toFront()
                end
                transition.to(card:getView(), {
                    time = 200 * settings.animationSpeed,
                    rotation = math.random(-cardAngleMistake, cardAngleMistake),
                    transition = easing.inCubic,
                    xScale = maxScale,
                    onComplete = function() resolve() end
                })
            end
        })
    end)
end

function effects:dead(card)
    return promise(function(resolve)
        local v = card:getView()
        transition.to(v, {
            time = 1000 * settings.animationSpeed,
            rotation = -90,
            onComplete = function()
                transition.to(v, {
                    time = 1000 * settings.animationSpeed,
                    alpha = 0,
                    y = v.y - 100,
                    xScale = 0.75,
                    yScale = 0.75,
                    onComplete = function() resolve() end
                })
            end
        })
    end)
end

function effects:angleInDeck(deck, r)
    return promise(function(resolve)
        local completed = 0
        for i = 1, #deck do
            local v = deck[i]:getView()
            transition.to(v, {
                time = (200 + 100 * i) * settings.animationSpeed,
                x = display.contentWidth / 2 + math.cos(math.pi / 4) * r - i * 10,
                y = 0.75 * display.contentHeight - math.sin(math.pi / 4) * r,
                rotation = 45,
                onComplete = function()
                    completed = completed + 1
                    if completed == #deck then
                        resolve()
                    end
                end
            })
        end
    end)
end

function effects:circleSpreadDeck(deck, r)
    local d = (math.pi / 2) / (#deck - 1)
    local dDegree = 90 / (#deck - 1)
    return promise(function(resolve)
        local completed = 0
        for i = 1, #deck do
            local v = deck[i]:getView()
            transition.to(v, {
                time = 300 * settings.animationSpeed,
                transition = easing.inOutCubic,
                x = display.contentWidth / 2 + math.cos(d * (i - 1) + math.pi / 4) * r,
                y = 0.75 * display.contentHeight - math.sin(d * (i - 1) + math.pi / 4) * r,
                rotation = 45 - dDegree * (i - 1),
                onComplete = function()
                    completed = completed + 1
                    if completed == #deck then
                        resolve()
                    end
                end
            })
        end
    end)
end

function effects:lineSpreadDeck(deck, r)
    local d = (math.pi / 2) / (#deck - 1)
    local dDegree = 90 / (#deck - 1)
    return promise(function(resolve)
        local completed = 0
        for i = 1, #deck do
            local v = deck[i]:getView()
            transition.to(v, {
                time = 300 * settings.animationSpeed,
                transition = easing.inOutCubic,
                x = display.contentWidth / 2 + math.cos(-d * (i - 1) + 0.75 * math.pi) * r,
                y = 0.5 * display.contentHeight - 0.5 * math.sin(-d * (i - 1) + 0.75 * math.pi) * r,
                rotation = -45 + dDegree * (i - 1),
                onComplete = function()
                    completed = completed + 1
                    if completed == #deck then
                        resolve()
                    end
                end
            })
        end
    end)
end

function effects:rotateMonsters(deck, pos)
    return promise(function(resolve)
        local completed = 0
        messageBus:post(messageBus.play_sfx, { name = "slide" })
        for i = 1, #deck do
            local v = deck[i]:getView()
            transition.to(v, {
                time = 500 * settings.animationSpeed,
                transition = easing.outCubic,
                x = pos[i].x,
                y = pos[i].y,
                rotation = math.random(-cardAngleMistake, cardAngleMistake),
                onComplete = function()
                    completed = completed + 1
                    if completed == #deck then
                        resolve()
                    end
                end
            })
        end
    end)
end

function effects:positionCardsInDeck(deck, pos)
    return promise(function(resolve)
        local completed = 0
        for i = 1, #deck do
            timer.performWithDelay(((i - 1) * 250) * settings.animationSpeed, function()
                messageBus:post(messageBus.play_sfx, { name = "slide" })
                local v = deck[i]:getView()
                transition.to(v, {
                    time = 500 * settings.animationSpeed,
                    transition = easing.outCubic,
                    x = pos[i].x,
                    y = pos[i].y,
                    rotation = math.random(-cardAngleMistake, cardAngleMistake),
                    onComplete = function()
                        completed = completed + 1
                        if completed == #deck then
                            resolve()
                        end
                    end
                })
            end)
        end
    end)
end

function effects:punchCard(card)
    local orgX = card:getView().x
    local x = function(angle, s, xofs)
        return promise(function(resolve)
            local v = card:getView()
            transition.to(v, {
                time = 150 * settings.animationSpeed,
                transition = easing.outCubic,
                rotation = angle,
                xScale = s,
                yScale = s,
                x = orgX + xofs,
                onComplete = function() resolve() end
            })
        end)
    end
    return x(-10, 1, 100)
        :thenCall(function() return x(10, 0.3, -10) end)
        :thenCall(function() return x(math.random(-cardAngleMistake, cardAngleMistake), 0.5, 0) end)
        :catchAndPrint()
end

function effects:shakeCard(card)
    local x = function(angle)
        return promise(function(resolve)
            local v = card:getView()
            transition.to(v, {
                time = 60 * settings.animationSpeed,
                transition = easing.linear,
                rotation = angle,
                onComplete = function() resolve() end
            })
        end)
    end
    return x(-25)
        :thenCall(function() return x(25) end)
        :thenCall(function() return x(-25) end)
        :thenCall(function() return x(25) end)
        :thenCall(function() return x(-25) end)
        :thenCall(function() return x(math.random(-cardAngleMistake, cardAngleMistake)) end)
        :catchAndPrint()
end

function effects:scaleCard(card, s)
    return promise(function(resolve)
        local v = card:getView()
        transition.to(v, {
            time = 200 * settings.animationSpeed,
            transition = easing.linear,
            xScale = s,
            yScale = s,
            onComplete = function() resolve() end
        })
    end)
end

function effects:moveCardToPos(card, pos)
    return promise(function(resolve)
        messageBus:post(messageBus.play_sfx, { name = "slide" })
        local v = card:getView()
        transition.to(v, {
            time = 100 * settings.animationSpeed,
            transition = easing.outCubic,
            x = pos.x,
            y = pos.y,
            rotation = math.random(-cardAngleMistake, cardAngleMistake),
            onComplete = function() resolve() end
        })
    end)
end

function effects:flipAllCardsInDeck(deck)
    return promise(function(resolve)
        local completed = 0
        for i = 1, #deck do
            timer.performWithDelay(((i - 1) * 500) * settings.animationSpeed, function()
                deck[i]:flipCard()
                    :thenCall(function()
                        completed = completed + 1
                        if completed == #deck then
                            resolve()
                        end
                    end)
                    :catchAndPrint()
            end)
        end
    end)
end

function effects:deckToFront(deck)
    for i = 1, #deck do
        deck[i]:getView():toFront()
    end
end

function effects:dealDeck(deck, pos)
    return promise(function(resolve)
        local r = 200
        self:angleInDeck(deck, r)
            :thenCall(function() return self:circleSpreadDeck(deck, r) end)
            :thenCall(function() return self:positionCardsInDeck(deck, pos) end)
            :thenCall(function() return self:flipAllCardsInDeck(deck) end)
            :thenCall(function() resolve() end)
            :catchAndPrint()
    end)
end

function effects:screenShake(view)
    local startX, startY = view.x, view.y
    local d = 10
    local shake
    shake = function(iterations)
        local x = startX + math.random(-d, d)
        local y = startY + math.random(-d, d)
        if iterations == 0 then
            return
        elseif iterations == 1 then
            x = startX
            y = startY
        end
        transition.to(view, {
            time = 25,
            transition = easing.outCirc,
            x = x,
            y = y,
            onComplete = function() shake(iterations - 1) end
        })
    end
    shake(15)

end

return effects;
