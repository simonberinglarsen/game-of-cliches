local messageBus = require("x-framework.message-bus")
local promise = require("x-framework.promise")
local effects = require("x-scenes.ingame.ingame-effects")
local transition = require("transition")
local easing = require("easing")
local settings = require("x-framework.settings")

local card = {}
card.__index = card

local cardMap = {}
cardMap["opponent0"] = { img = "card_opponent0.png", deck = "opponents", attack = 1, defence = 0, health = 10 }
cardMap["opponent1"] = { img = "card_opponent1.png", deck = "opponents", attack = 2, defence = 1, health = 20 }
cardMap["opponent2"] = { img = "card_opponent2.png", deck = "opponents", attack = 3, defence = 2, health = 25 }
cardMap["opponent3"] = { img = "card_opponent3.png", deck = "opponents", attack = 4, defence = 3, health = 30 }
cardMap["opponent4"] = { img = "card_opponent4.png", deck = "opponents", attack = 5, defence = 4, health = 35 }
cardMap["opponent5"] = { img = "card_opponent5.png", deck = "opponents", attack = 6, defence = 5, health = 40 }
cardMap["opponent6"] = { img = "card_opponent6.png", deck = "opponents", attack = 7, defence = 6, health = 45 }
cardMap["monster1"] = { img = "card_monster1.png", deck = "monster", attack = 0, defence = 0, health = 5 }
cardMap["monster2"] = { img = "card_monster2.png", deck = "monster", attack = 0, defence = 0, health = 5 }
cardMap["monster3"] = { img = "card_monster3.png", deck = "monster", attack = 0, defence = 0, health = 5 }
cardMap["attack"] = { img = "card_attack.png", deck = "hand" }
cardMap["power"] = { img = "card_power.png", deck = "hand" }
cardMap["defence"] = { img = "card_defence.png", deck = "hand" }
cardMap["cliche1"] = { img = "card_cliche.png", deck = "powerOfClicheDeck", title = "  read\nbetween\nthe lines",
    description = "average out all\n monster stats" }
cardMap["cliche2"] = { img = "card_cliche.png", deck = "powerOfClicheDeck", title = "   play\nyour cards\n  right",
    description = "put all power\ncards on top" }
cardMap["cliche3"] = { img = "card_cliche.png", deck = "powerOfClicheDeck", title = "it's an\nuphill\nbattle",
    description = "attacking card\nlooses shield" }
cardMap["cliche4"] = { img = "card_cliche.png", deck = "powerOfClicheDeck", title = "better safe\nthan sorry",
    description = "+2 HP to all\nmonsters" }
cardMap["cliche5"] = { img = "card_cliche.png", deck = "powerOfClicheDeck",
    title = "you can't judge\n    a book\n by its cover",
    description = "swap health and attack\non a random card" }
cardMap["cliche6"] = { img = "card_cliche.png", deck = "powerOfClicheDeck", title = "bring something\n  to the table",
    description = "revive a monster\nif you have less\nthan 3 monsters" }
cardMap["cliche7"] = { img = "card_cliche.png", deck = "powerOfClicheDeck", title = "low-hanging\n   fruit",
    description = "+2 on defence" }
cardMap["cliche8"] = { img = "card_cliche.png", deck = "powerOfClicheDeck",
    title = "grass is always\ngreener on the\nother side", description = "  swap stats\nwith opponent" }
cardMap["cliche9"] = { img = "card_cliche.png", deck = "powerOfClicheDeck", title = "ignorance\n  is bliss",
    description = "Reset all your monsters\nso they have\nzero shield\n..and zero attack" }



function card:new(parent, type)
    local o = {}
    local view = parent
    setmetatable(o, card)
    o.type = type
    o.deck = cardMap[type].deck

    o.back = display.newImage(view, "x-assets/gfx/card_bg.png", display.contentWidth / 2, -display.contentHeight)
    local c1 = { 1, 1, 0.5, 0.8 }
    local c2 = { 0, 1, 0, 0.5 }
    o.selectionIndicator = o:createGlowRect(view, c1)
    o.targetIndicator = o:createGlowRect(view, c2)
    o.draggableIndicator = o:createGlowRect(view, c1)
    o.isDraggable = false
    local img = cardMap[type].img


    o.front = display.newGroup()
    display.newImage(o.front, "x-assets/gfx/" .. img, 0, 0)
    o.front.isVisible = false
    o.front:scale(0.5, 0.5)
    o.front.x = display.contentWidth / 2
    o.front.y = -display.contentHeight
    if o.deck == "powerOfClicheDeck" then
        o:setupClicheCard(cardMap[type])
    end
    o.defenceLabel = display.newText(o.front, "", -89, 163, "x-assets/fonts/rabiohead.ttf", 56)
    o.defenceLabel.fill = { 0, 0, 0 }
    o.attackLabel = display.newText(o.front, "", 89, 163, "x-assets/fonts/rabiohead.ttf", 56)
    o.attackLabel.fill = { 0, 0, 0 }
    o.healthLabel = display.newText(o.front, "", 2, 135, "x-assets/fonts/rabiohead.ttf", 56)
    o.healthLabel.fill = { 0, 0, 0 }
    if type == "attack" or type == "defence" or type == "power" then
        o.defenceLabel.isVisible = false
        o.attackLabel.isVisible = false
        o.healthLabel.isVisible = false
    end
    o.stats = {
        defence = cardMap[type].defence,
        health = cardMap[type].health,
        attack = cardMap[type].attack,
    }
    if o.type:sub(1, -2) == "monster" then
        o.type = "monster"
    end
    o:updateStats()
    view:insert(o.front)
    o.back:scale(0.5, 0.5)
    o.handlers = {}
    o.targets = {}
    return o
end

function card:setupClicheCard(settings)
    local title, description = settings.title, settings.description
    local text
    text = display.newText(self.front, title, 0, -80, "x-assets/fonts/rabiohead.ttf", 44)
    text.fill = { 0, 0, 0 }
    text = display.newText(self.front, description, 0, 90, "x-assets/fonts/rabiohead.ttf", 33)
    text.fill = { 0, 0, 0 }
end

function card:createGlowRect(view, color)
    local rect = display.newRoundedRect(view, 0, 0, 0, 0, 20)
    rect.fill = color
    rect.isVisible = false
    rect.width = 210 * 1.1
    rect.height = 270 * 1.1
    rect.fill.effect = "filter.vignetteMask"
    rect.fill.effect.innerRadius = 0.5
    rect.fill.effect.outerRadius = 0.4
    return rect
end

function card:dispose()
    self.selectionIndicator:removeSelf()
    self.back:removeSelf()
    self.front:removeSelf()
end

function card:takeDamage(incommingAttack)
    local p = promise(function(resolve)
        local defence = self.stats.defence
        if defence >= incommingAttack then
            resolve()
            return
        end
        local newHealth = math.max(0, self.stats.health - (incommingAttack - defence))
        messageBus:post(messageBus.play_sfx, { name = "punch" })
        messageBus:post(messageBus.screen_shake)
        effects:punchCard(self)
            :thenCall(function() return effects:shakeCard(self) end)
            :thenCall(function()
                self.stats.health = newHealth
                self:updateStats()
                messageBus:post(messageBus.play_sfx, { name = "smash" })
                return self:spawnPlusOne(self.healthLabel.x, self.healthLabel.y, "heart_black")
            end)
            :thenCall(function() resolve() end)
            :catchAndPrint()

    end)
    return p
end

function card:updateStats()
    self.defenceLabel.text = self.stats.defence
    self.healthLabel.text = self.stats.health
    self.attackLabel.text = self.stats.attack
end

function card:isSelected()
    return self.selectionIndicator.isVisible
end

function card:addAttack(n)
    self.stats.attack = self.stats.attack + n
    self:updateStats()
    return self:spawnPlusOne(self.attackLabel.x, self.attackLabel.y)
end

function card:addHealth(n)
    self.stats.health = self.stats.health + n
    self:updateStats()
    return self:spawnPlusOne(self.healthLabel.x, self.healthLabel.y, "heart")
end

function card:addDefence(n)
    self.stats.defence = self.stats.defence + n
    self:updateStats()
    return self:spawnPlusOne(self.defenceLabel.x, self.defenceLabel.y)
end

function card:getImage(x, y, type)
    local img
    if type then
        img = display.newImage(self.front, "x-assets/gfx/" .. type .. ".png", x, y)
    else
        img = display.newImage(self.front, "x-assets/gfx/star.png", x, y)
    end
    return img
end

function card:spawnPlusOne(x, y, type)
    local img = self:getImage(x, y, type)
    img:scale(3, 3)
    return promise(function(resolve) transition.to(img, {
            time = 500 * settings.animationSpeed,
            transition = easing.inCirc,
            x = x,
            xScale = 0.5,
            yScale = 0.5,
            onComplete = function()
                img:removeSelf()
                local d = math.pi * 2 / 10
                transition.to(self:getView(), {
                    time = 200 * settings.animationSpeed,
                    rotation = math.random(-5, 5)
                })
                for i = 1, 10 do
                    local smallImg = self:getImage(x, y, type)
                    transition.to(smallImg, {
                        time = 500 * settings.animationSpeed,
                        transition = easing.outQuad,
                        x = x + math.cos(d * i) * 150,
                        y = y + math.sin(d * i) * 150,
                        xScale = 0.5,
                        yScale = 0.5,
                        alpha = 0,
                        onComplete = function()
                            smallImg:removeSelf()
                            resolve()
                        end
                    })
                end
            end
        })
    end)
end

function card:setTargets(targets)
    self.targets = targets
end

function card:getView()
    if self.front.isVisible then
        return self.front
    else
        return self.back
    end
end

function card:flipCard()
    return promise(function(resolve)
        messageBus:post(messageBus.play_sfx, { name = "flipcard" })
        local source, dest
        if self.back.isVisible then
            source, dest = self.back, self.front
        else
            source, dest = self.front, self.back
        end
        dest.x = source.x
        dest.y = source.y
        dest.xScale = source.xScale
        dest.yScale = source.yScale
        dest.rotation = source.rotation
        effects:flipCard(self)
            :thenCall(function() resolve() end)
            :catchAndPrint()
    end)
end

function card:showIndicator(t, show)
    if show then
        local v = self:getView()
        t.x = v.x
        t.y = v.y
        t:toBack()
        t.xScale = v.xScale * 2
        t.yScale = v.yScale * 2
    end
    t.isVisible = show
end

function card:showDraggable(show)
    self:showIndicator(self.draggableIndicator, show)
end

function card:showTargets(show)
    for i = 1, #self.targets do
        self.targets[i]:showIndicator(self.targets[i].targetIndicator, show)
    end
end

function card:showSelection(show)
    local v = self:getView()
    if self.selectionIndicator.isVisible == show then return end
    if show then
        messageBus:post(messageBus.play_sfx, { name = "slide" })
        self.selectionIndicator.x = v.x
        self.selectionIndicator.y = v.y
        self.selectionIndicator:toBack()
        self.selectionIndicator.isVisible = true
        -- hack!!
        self.selectionIndicator.alpha = 0
        local rotation
        if math.random() > 0.5 then
            rotation = 20
        else
            rotation = -20
        end
        transition.to(self:getView(), {
            time = 200 * settings.animationSpeed,
            transition = easing.inCubic,
            rotation = rotation,
        })
    else
        self.selectionIndicator.isVisible = false
        transition.to(self:getView(), {
            time = 200 * settings.animationSpeed,
            transition = easing.inCubic,
            rotation = math.random(-5, 5)
        })
    end
end

function card:makeDraggable()
    local v = self:getView()
    local grabbed = false
    local startPos = { x = v.x, y = v.y }
    local debug = { lastPhase = "unknown" }
    local handler = function(e)
        if debug.lastPhase ~= e.phase then
            debug.lastPhase = e.phase
        end
        if e.phase == "began" then
            messageBus:post(messageBus.indicator_status, { showDraggables = false })
            self:showTargets(true)
            display.getCurrentStage():setFocus(e.target, e.id)
            grabbed = true
            v:toFront()
            transition.to(v, {
                time = 100,
                x = e.x,
                y = e.y,
            })

        elseif grabbed and e.phase == "ended" then
            self:showTargets(false)
            display.getCurrentStage():setFocus(e.target, nil)
            grabbed = false
            local slideBack = true
            for i = 1, #self.targets do
                local t = self.targets[i]
                if t:isSelected() then
                    messageBus:post(messageBus.card_attached, { source = self, dest = t })
                    if self.type == "monster" and t.type == "monster" then
                        slideBack = false
                    end
                end
                t:showSelection(false)
            end
            if slideBack then
                messageBus:post(messageBus.play_sfx, { name = "slide" })
                transition.to(self:getView(), {
                    time = 200 * settings.animationSpeed,
                    transition = easing.inCubic,
                    x = startPos.x,
                    y = startPos.y,
                    onComplete = function()
                        messageBus:post(messageBus.indicator_status, { showDraggables = true })
                    end
                })
            else
                --messageBus:post(messageBus.indicator_status, { showDraggables = true })
            end
        elseif grabbed and e.phase == "moved" then
            transition.cancel(v)
            v.x = e.x
            v.y = e.y

            local target = nil
            for i = 1, #self.targets do
                local t = self.targets[i]
                local bounds = t:getView().contentBounds
                if bounds.xMin < v.x and v.x < bounds.xMax
                    and bounds.yMin < v.y and v.y < bounds.yMax then
                    target = t
                    break
                end
            end

            for i = 1, #self.targets do
                local t = self.targets[i]
                if t == target then
                    t:showSelection(true)
                else
                    t:showSelection(false)
                end
            end

        end
    end
    self.isDraggable = true
    messageBus:post(messageBus.indicator_status, { showDraggables = true })
    self:addHandler({ view = v, event = "touch", h = handler })
end

function card:addHandler(options)
    for i = 1, #self.handlers do
        if self.handlers[i].h == options.h then
            print("ERROR!")
        end
    end
    self.handlers[#self.handlers + 1] = options
    options.view:addEventListener(options.event, options.h)
end

function card:removeHandlers()
    messageBus:post(messageBus.indicator_status, { showDraggables = false })
    self.isDraggable = false
    for i = 1, #self.handlers do
        local options = self.handlers[i]
        options.view:removeEventListener(options.event, options.h)
    end
end

return card
