local composer = require("composer")
local scene = composer.newScene()
local main = require("x-scenes.ingame.main")


local sceneLogic

function scene:create(event)
    display.newImage(self.view, "x-assets/gfx/ingame.jpg", display.contentWidth / 2, display.contentHeight / 2)

    self.view:addEventListener("touch", function(e)
        if e.phase == "began" then
            print("x,y = " .. e.x .. ", " .. e.y)
        end
    end)

end

function scene:show(event)
    local phase = event.phase
    if (phase == "did") then
        sceneLogic = main:new(self.view)
    end
end

function scene:hide(event)
    local phase = event.phase
    if (phase == "will") then
        sceneLogic:destroy()
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
