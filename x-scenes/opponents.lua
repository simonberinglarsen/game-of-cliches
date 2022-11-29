local transition = require("transition")
local easing = require("easing")
local card = require("x-scenes.ingame.ingame-card")
local composer = require("composer")
local messageBus = require("x-framework.message-bus")
local settings = require("x-framework.settings")
local scene = composer.newScene()
local state = require("state")

local cardView

function scene:setup()
    cardView = display.newGroup()
    self.view:insert(cardView)
    local opponents = state.s.opponents
    for i = 1, #opponents do
        local opponent = opponents[i]
        local card = card:new(cardView, opponent.type)
        local x, y = math.floor((i - 1) % 4), math.floor((i - 1) / 4)
        local w, h = 200, 300
        card:getView().x = 200 + x * w
        card:getView().y = 200 + y * h
        if opponent.activated then
            card:flipCard()
                :thenCall(function()
                    local v = card:getView()
                    v:addEventListener("tap", function()
                        state.s.selectedOpponentIndex = i
                        messageBus:post(messageBus.show_ingame_screen)
                    end)

                    if not opponent.defeated then
                        local pulse
                        pulse = function(zoomOut)
                            local s = 0.6
                            if zoomOut then
                                s = 0.55
                            end
                            local t = 250 * settings.animationSpeed
                            if t < 100 then t = 100 end
                            transition.to(v, {
                                time = t,
                                transition = easing.inOutQuad,
                                xScale = s,
                                yScale = s,
                                onComplete = function() pulse(not zoomOut) end
                            })
                        end
                        pulse(true)
                        card:showDraggable(true)
                        return
                    end
                    local g = display.newGroup()
                    local img = display.newImage(g, "x-assets/gfx/ribbon.png", -5, 85)
                    img.xScale = 0.7
                    img.yScale = 0.7
                    local starsEarned = 3
                    for j = 1, starsEarned do
                        img = display.newImage(g, "x-assets/gfx/star.png",
                            -60 + 30 * j - 5, 70)
                        img.xScale = 0.5
                        img.yScale = 0.5
                    end
                    cardView:insert(g)
                    g.x = card:getView().x
                    g.y = card:getView().y
                    g.rotation = card:getView().rotation
                end)
                :catchAndPrint()
        else
            display.newImage(cardView, "x-assets/gfx/lock.png", card:getView().x, card:getView().y)
        end
    end
    local chiken = display.newImage(cardView, "x-assets/gfx/chiken.png", 860, 550)
    chiken.xScale = 0.7
    chiken.yScale = 0.7
    chiken:addEventListener("tap",
        function()
            transition.cancelAll()
            messageBus:post(messageBus.play_sfx, { name = "chicken" })
            messageBus:post(messageBus.show_title_screen)
        end)
end

function scene:cleanup()
    cardView:removeSelf()
end

function scene:create(event)
    local d = display.newImage(self.view, "x-assets/gfx/opponents.jpg", display.contentWidth / 2,
        display.contentHeight / 2)
end

function scene:show(event)
    local phase = event.phase
    if (phase == "did") then
        self:setup()
    end
end

function scene:hide(event)
    local phase = event.phase
    if (phase == "will") then
        self:cleanup()
    end
end

function scene:destroy(event)
end

-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)
-- -----------------------------------------------------------------------------------
return scene
