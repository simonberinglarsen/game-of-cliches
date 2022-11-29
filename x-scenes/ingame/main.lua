local state = require("state")
local transition = require("transition")
local settings = require("x-framework.settings")
local messageBus = require("x-framework.message-bus")
local effects = require("x-scenes.ingame.ingame-effects")
local eventListeners = require("x-framework.event-listeners")
local controller = require("x-scenes.ingame.ingame-controller")
local card = require("x-scenes.ingame.ingame-card")
local promise = require("x-framework.promise")
local stateReady = require("x-scenes.ingame.ingame-state-ready")
local stateRetreatOrStay = require("x-scenes.ingame.ingame-state-retreatorstay")
local stateHeal = require("x-scenes.ingame.ingame-state-heal")
local stateWin = require("x-scenes.ingame.ingame-state-win")
local statePlayerturn = require("x-scenes.ingame.ingame-state-playerturn")
local stateComputerturn = require("x-scenes.ingame.ingame-state-computerturn")
local states = require("x-scenes.ingame.ingame-states")
local main = {}
main.__index = main

--[[
RULES:

start
1) shuffle hand
2) shuffle power of cliches
3) deal monsters
4) turn first card on hand

@your turn
1) Action:
 A) attack ->
  him.hp -= max(me.attack - him.shield, 0)
  if him.hp <= 0 then "WIN!"
  after play -> insert card in bottom of hand
 B) play card
  if power: turn next cliche and apply
  if attack: +1 attack to any monster
  if shield: +1 defence to any monster
  after play -> insert card in bottom of hand
2) Retreat or stay?
3) All monsters in queue +1 HP

@computer turn
1) if him.attack > you.shield
  attack
 else
  him.attack += 1
2) (maybe have AI abilities?) <-- dont implement this to begin with

]]

function main:closeAllDialogs()
    for i = 1, self.modelstate.dialogView.numChildren do
        local v = self.modelstate.dialogView[i]
        if v.isClosing == false then
            v.isClosing = true
            effects:closeDialog(v)
        end
    end
end

function main:closeDialog(id)
    for i = 1, self.modelstate.dialogView.numChildren do
        local v = self.modelstate.dialogView[i]
        if v.isClosing == false and v.id == id then
            v.isClosing = true
            effects:closeDialog(v)
        end
    end
end

function main:createCards(view)
    local attackCard = function() return card:new(view, "attack") end
    local defenceCard = function() return card:new(view, "defence") end
    local powerCard = function() return card:new(view, "power") end
    local clicheCard = function(i) return card:new(view, "cliche" .. i) end
    self.modelstate.hand = {}
    local selectedOpponent = state:getSelectedOpponent()
    for i = 1, selectedOpponent.cardconfig[1] do
        self.modelstate.hand[#self.modelstate.hand + 1] = attackCard()
    end
    for i = 1, selectedOpponent.cardconfig[2] do
        self.modelstate.hand[#self.modelstate.hand + 1] = defenceCard()
    end
    for i = 1, selectedOpponent.cardconfig[3] do
        self.modelstate.hand[#self.modelstate.hand + 1] = powerCard()
    end
    self.modelstate.powerOfClicheDeck = {
        clicheCard(1),
        clicheCard(2),
        clicheCard(3),
        clicheCard(4),
        clicheCard(5),
        clicheCard(6),
        clicheCard(7),
        clicheCard(8),
        clicheCard(9),
    }
    self.modelstate.opponents = {
        card:new(view, selectedOpponent.type)
    }
    if selectedOpponent.monsters == 3 then
        self.modelstate.monsters = { card:new(view, "monster1"), card:new(view, "monster2"), card:new(view, "monster3"), }
    elseif selectedOpponent.monsters == 2 then
        self.modelstate.monsters = { card:new(view, "monster1"), card:new(view, "monster2") }
    elseif selectedOpponent.monsters == 1 then
        self.modelstate.monsters = { card:new(view, "monster1") }
    end
end

local dialogId = 0
function main:showDialog(options)
    local g = display.newGroup()
    self.modelstate.dialogView:insert(g)
    g.x = options.x - 100
    g.y = options.y
    g.alpha = 0
    g.isClosing = false
    dialogId = dialogId + 1
    g.id = dialogId
    local xofs = 20
    local yofs = 0
    local bobble
    if options.paperScroll then
        yofs = 30
        xofs = 50
        bobble = display.newImage(g, "x-assets/gfx/scroll.png", 0, 0)
    else
        bobble = display.newImage(g, "x-assets/gfx/speechbubble.png", 0, 0)
    end
    if options.reverse then
        bobble.xScale = -1
        xofs = 40
    end
    local label = display.newText(g, options.text, -bobble.width / 2 + xofs, -bobble.height / 2 * 0.9 + yofs,
        "x-assets/fonts/rabiohead.ttf"
        , 40)
    label.anchorX = 0
    label.anchorY = 0
    label.fill = { 0, 0, 0 }
    if options.onClick then
        local handler = function(e)
            if e.phase ~= "ended" then return end
            options.onClick()
        end
        bobble:addEventListener("touch", handler)
        g.removeHandlers = function()
            bobble:removeEventListener("touch", handler)
        end
    else
        g.removeHandlers = function() end
    end
    effects:showDialog(g, options.x)
    return g.id
end

function main:showTimedDialog(options, delay)
    return promise(function(resolve)
        local id = self:showDialog(options)
        timer.performWithDelay(delay * settings.animationSpeed, function()
            self:closeDialog(id)
            timer.performWithDelay(400 * settings.animationSpeed, function() resolve() end)
        end)
    end)
end

function main:upgradeCard(source, dest)
    if source.type == "attack" then
        messageBus:post(messageBus.play_sfx, { name = "drawsword", delay = 500 })
        dest:addAttack(1)
    elseif source.type == "defence" then
        messageBus:post(messageBus.play_sfx, { name = "defence", delay = 500 })
        dest:addDefence(1)
    end
    return controller:turnCard(self.modelstate.hand[#self.modelstate.hand])
end

function main:indicatorStatus(showDraggables)
    if showDraggables ~= nil then
        local decks = {
            self.modelstate.hand,
            self.modelstate.opponents,
            self.modelstate.monsters,
            self.modelstate.powerOfClicheDeck,
        }
        for i = 1, #decks do
            local deck = decks[i]
            for j = 1, #deck do
                local card = deck[j]
                card:showDraggable(card.isDraggable and showDraggables)
            end
        end
    end
end

function main:cardAttached(source, dest)
    local s = self.modelstate.currentState
    if s and s.cardAttached then
        s:cardAttached(source, dest)
    end
end

function main:new(parentView)
    local o = {}
    setmetatable(o, main)

    local myView = display.newGroup()
    parentView:insert(myView)
    o.view = myView
    o.eventRegistrations = {}
    local modelstate = {
        cardView = nil,
        dialogView = nil,
        hand = {},
        powerOfClicheDeck = {},
        monsters = {},
        opponents = {},
        tutorial = false,
        currentState = nil
    }

    local actions = {
        continue = "continue",
        attack = "attack",
        play_hand = "play_hand",
        retreat = "retreat",
        stay = "stay",
        win = "win",
    }
    self.stateTypeMap = {}
    self.stateTypeMap[states.computerTurn] = stateComputerturn
    self.stateTypeMap[states.heal] = stateHeal
    self.stateTypeMap[states.playerTurn] = statePlayerturn
    self.stateTypeMap[states.ready] = stateReady
    self.stateTypeMap[states.retreatOrStay] = stateRetreatOrStay
    self.stateTypeMap[states.win] = stateWin


    local chiken = display.newImage(o.view, "x-assets/gfx/chiken.png", 860, 410)
    chiken.xScale = 0.5
    chiken.yScale = 0.5
    o:smartListener(chiken, "tap",
        function()
            transition.cancelAll()
            messageBus:post(messageBus.play_sfx, { name = "chicken" })
            messageBus:post(messageBus.show_game_over_screen)
        end)

    modelstate.cardView = display.newGroup()
    modelstate.dialogView = display.newGroup()
    modelstate.markerView = o:createMarkerIndicator()
    o.view:insert(modelstate.markerView)
    o.view:insert(modelstate.cardView)
    o.view:insert(modelstate.dialogView)
    o.actions = actions
    o.modelstate = modelstate
    o.markerPos = 1

    o:setupEvents()

    o:transitionTo(states.ready)
    return o
end

function main:createMarkerIndicator()
    local g = display.newGroup()
    local rect = display.newRoundedRect(g, 0, 0, 0, 0, 20)
    rect.fill = { 1, 1, 0.5, 0.8 }
    rect.isVisible = false
    rect.width = 80
    rect.height = 80
    rect.fill.effect = "filter.vignetteMask"
    rect.fill.effect.innerRadius = 0.5
    rect.fill.effect.outerRadius = 0.4
    display.newImage(g, "x-assets/gfx/marker.png")
    g.x = display.contentWidth / 2
    g.y = -100
    return g
end

function main:markerTo(pos)
    local moves = {}
    messageBus:post(messageBus.play_sfx, { name = "slidewood" })
    if pos == 1 then
        if self.markerPos == 4 then
            moves[#moves + 1] = { x = 909, y = 28, t = 250 }
            moves[#moves + 1] = { x = 363, y = 28, t = 250 }
        end
        moves[#moves + 1] = { x = 363, y = 102, t = 600 }
    elseif pos == 2 then
        moves[#moves + 1] = { x = 367, y = 168, t = 1000 }
    elseif pos == 3 then
        moves[#moves + 1] = { x = 367, y = 236, t = 1000 }
    elseif pos == 4 then
        if self.markerPos == 3 then
            moves[#moves + 1] = { x = 363, y = 329, t = 250 }
            moves[#moves + 1] = { x = 909, y = 329, t = 250 }
        end
        moves[#moves + 1] = { x = 909, y = 96, t = 600 }
    end
    self.markerPos = pos
    local v = self.modelstate.markerView
    local m
    m = function(index)
        if index > #moves then
            self.modelstate.markerView[1].isVisible = pos == 2
            return
        end
        local x, y = moves[index].x, moves[index].y
        local t = moves[index].t
        transition.to(v, {
            time = t * settings.animationSpeed,
            transition = easing.outSine,
            x = x,
            y = y,
            onComplete = function() m(index + 1) end
        })
    end
    m(1)
end

function main:endGame(win)
    local img
    self:removeAllHandlers()
    if win then
        messageBus:post(messageBus.play_sfx, { name = "cheer" })
        img = display.newImage(self.view, "x-assets/gfx/win.png", display.contentWidth / 2, display.contentHeight / 2)
        img:addEventListener("tap",
            function()
                print("YES")
                transition.cancelAll()
                state:activeDefaultedActivateNext()
                state:commit()
                messageBus:post(messageBus.show_opponent_screen)
            end)
    else
        messageBus:post(messageBus.play_sfx, { name = "gameover" })
        img = display.newImage(self.view, "x-assets/gfx/gameover.png", display.contentWidth / 2,
            display.contentHeight / 2)
        img:addEventListener("tap",
            function()
                transition.cancelAll()
                messageBus:post(messageBus.show_opponent_screen)
            end)
    end
end

function main:removeAllHandlers()
    self:removeHandlersFromAllDecks()
    for i = 1, #self.eventRegistrations do
        local object = self.eventRegistrations[i][1]
        local event = self.eventRegistrations[i][2]
        local fn = self.eventRegistrations[i][3]
        object:removeEventListener(event, fn)
    end
    self.eventRegistrations = {}
end

function main:smartListener(object, event, fn)
    object:addEventListener(event, fn)
    self.eventRegistrations[#self.eventRegistrations + 1] = { object, event, fn }
end

function main:removeHandlersFromAllDecks()
    controller:removeHandlersFromDecks({
        self.modelstate.hand,
        self.modelstate.powerOfClicheDeck,
        self.modelstate.monsters,
        self.modelstate.opponents,
    })
end

function main:transitionTo(stateType)
    local s = self.stateTypeMap[stateType]:new(self)
    self.modelstate.currentState = s
    self:closeAllDialogs()
    self:removeHandlersFromAllDecks();
    s:init()
end

function main:setupEvents()
    self.eventListeners = eventListeners:new({
        { messageBus.card_attached, function(o) self:cardAttached(o.source, o.dest) end },
        { messageBus.screen_shake, function() effects:screenShake(self.view) end },
        { messageBus.indicator_status, function(o) self:indicatorStatus(o.showDraggables) end },
        { messageBus.show_game_over_screen, function() self:endGame(false) end },
        { messageBus.show_levelcomplete_screen, function() self:endGame(true) end },
    })
end

function main:destroy()
    self.eventListeners:destroy()
    self.view:removeSelf()
    self.view = nil
end

return main
