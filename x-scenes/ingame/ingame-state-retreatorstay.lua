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
    context:markerTo(2)
    local activeMonster = context.modelstate.monsters[1]
    if #context.modelstate.monsters > 1 then
        activeMonster:makeDraggable()
    end
    activeMonster:setTargets({
        context.modelstate.monsters[2],
    })
    self:addMarkerHandler()
end

function state:addMarkerHandler()
    self.markerHandler = function(e)
        if e.phase == "began" and self.context.markerPos == 2 then
            self:removeMarkerHandler()
            self.context:transitionTo(states.heal)
        end
    end
    self.context.modelstate.markerView:addEventListener("touch", self.markerHandler)
end

function state:removeMarkerHandler()
    if self.markerHandler then
        print("removeMarkerHandler")
        self.context.modelstate.markerView:removeEventListener("touch", self.markerHandler)
    end
end

function state:cardAttached(source, dest)
    local context = self.context
    -- IF your monster rotates ->
    if (source.deck == "monster" and dest.deck == "monster") then
        controller:rotateMonsters(context.modelstate.monsters)
            :thenCall(function()
                self:removeMarkerHandler()
                context:transitionTo(states.heal)
            end)
            :catchAndPrint()
        return
    end
end

return state
