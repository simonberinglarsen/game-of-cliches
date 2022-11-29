local game = require("game")
local promise = require("x-framework.promise")
local messageBus = require("x-framework.message-bus")
local settings = require("x-framework.settings")

game:init()
display.setStatusBar(display.HiddenStatusBar)
messageBus:post(messageBus.show_title_screen)

if false then
    settings.animationSpeed = 0
    local debug = display.newRoundedRect(50, 25, 100, 50, 10, 10)
    local txt = display.newText("fast", 50, 25)
    debug.fill = { 1, 1, 1, .75 }
    txt.fill = { 0, 0, 0, .75 }

    debug:addEventListener("tap", function()
        if settings.animationSpeed == 0 then
            settings.animationSpeed = 1
            txt.text = "normal"
        else
            settings.animationSpeed = 0
            txt.text = "fast"
        end
    end)
end
