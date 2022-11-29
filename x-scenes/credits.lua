local composer = require("composer")
local messageBus = require("x-framework.message-bus")
local eventListeners = require("x-framework.event-listeners")
local scene = composer.newScene()

local function update()
end

function scene:create(event)
    local d = display.newImage(self.view, "x-assets/gfx/credits.jpg", display.contentWidth / 2, display.contentHeight / 2)
    d:addEventListener("tap", function()
        messageBus:post(messageBus.show_title_screen)
    end)
end

function scene:show(event)
    local phase = event.phase
    if (phase == "did") then
        self.eventListeners = eventListeners:new({
            { messageBus.game_update, function() update() end },
        })
    end
end

function scene:hide(event)
    local phase = event.phase
    if (phase == "will") then
        self.eventListeners:destroy()
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
