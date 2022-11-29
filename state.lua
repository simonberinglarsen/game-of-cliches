local json = require("json")
local FILENAME = "state.json"
local state = {
    s = { version = 1 },
}

function state:setDefaultState()
    local s = self.s
    s.selectedOpponentIndex = 1
    s.opponents = {
        { type = "opponent0", activated = true, defeated = false, monsters = 3, cardconfig = { 4, 4, 4 } },
        { type = "opponent1", activated = false, defeated = false, monsters = 3, cardconfig = { 6, 2, 4 } },
        { type = "opponent2", activated = false, defeated = false, monsters = 3, cardconfig = { 2, 2, 8 } },
        { type = "opponent3", activated = false, defeated = false, monsters = 3, cardconfig = { 8, 0, 4 } },
        { type = "opponent4", activated = false, defeated = false, monsters = 3, cardconfig = { 0, 4, 8 } },
        { type = "opponent5", activated = false, defeated = false, monsters = 2, cardconfig = { 2, 2, 8 } },
        { type = "opponent6", activated = false, defeated = false, monsters = 3, cardconfig = { 4, 4, 4 } },
    }
end

function state:getSelectedOpponent()
    return self.s.opponents[state.s.selectedOpponentIndex]
end

function state:activeDefaultedActivateNext()
    print("activateNextOpponent")
    local all = self.s.opponents
    for i = 1, #all do
        print("forloop")
        local opp = all[i]
        print(tostring(opp.activated) .. ", " .. tostring(opp.defeated))
        if opp.activated and not opp.defeated then
            print("set defeated")
            opp.defeated = true
            if i < #all then
                print("set activatd")
                all[i + 1].activated = true
            end

            return
        end
    end

end

function state:commit()
    print("COMMIT")
    local encoded = json.encode(self.s)
    print(encoded)
    local path = system.pathForFile(FILENAME, system.ApplicationSupportDirectory)
    local fh, reason = io.open(path, "w")
    if not fh then
        return
    end
    fh:write(encoded)
    io.close(fh)
end

function state:load()
    local path = system.pathForFile(FILENAME, system.ApplicationSupportDirectory)
    local decoded, pos, msg = json.decodeFile(path)

    if not decoded then
        print("CREATING STATE FILE")
        self:setDefaultState()
        self:commit()
        return
    end

    self.s = decoded
end

return state
