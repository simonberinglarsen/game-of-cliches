local composer = require("composer")
local messageBus = require("x-framework.message-bus")
local state = require("state")

local game = {}

function game:init()
    print("LOAD")
    state:load()

    --music
    --https://freesound.org/browse/tags/game-sound/
    self.gamemusic = audio.loadStream("x-assets/sfx/music.mp3")
    self.sounds = {
        select = audio.loadSound("x-assets/sfx/select.mp3"),
        back = audio.loadSound("x-assets/sfx/button.ogg"),
        shuffle = audio.loadSound("x-assets/sfx/shuffle.mp3"),
        flipcard = audio.loadSound("x-assets/sfx/flipcard.wav"),
        slide = audio.loadSound("x-assets/sfx/slide.ogg"),
        apply = audio.loadSound("x-assets/sfx/apply.wav"),
        shuffleshort = audio.loadSound("x-assets/sfx/shuffleshort.mp3"),
        anvil = audio.loadSound("x-assets/sfx/anvil.wav"),
        defence = audio.loadSound("x-assets/sfx/defence.mp3"),
        drawsword = audio.loadSound("x-assets/sfx/drawsword.mp3"),
        punch = audio.loadSound("x-assets/sfx/punch.mp3"),
        pling = audio.loadSound("x-assets/sfx/pling.mp3"),
        healing = audio.loadSound("x-assets/sfx/healing.wav"),
        smash = audio.loadSound("x-assets/sfx/smash.mp3"),
        deadcard = audio.loadSound("x-assets/sfx/deadcard.wav"),
        gameover = audio.loadSound("x-assets/sfx/gameover.wav"),
        slidewood = audio.loadSound("x-assets/sfx/slidewood.mp3"),
        chicken = audio.loadSound("x-assets/sfx/chicken.wav"),
        cheer = audio.loadSound("x-assets/sfx/cheer.mp3"),
    }

    messageBus:register(messageBus.start_music, function() self:startMusic() end)
    messageBus:register(messageBus.play_sfx, function(o) self:playSfx(o.name, o.delay) end)

    messageBus:register(messageBus.show_ingame_screen, function() self:showScreen("ingame", true) end)
    messageBus:register(messageBus.show_opponent_screen, function() self:showScreen("opponents", true) end)
    messageBus:register(messageBus.show_title_screen, function() self:showScreen("title") end)
    messageBus:register(messageBus.show_credits_screen, function() self:showScreen("credits") end)

    messageBus:post(messageBus.start_music)
end

function game:playSfx(name, delay)
    if delay then
        timer.performWithDelay(delay, function() audio.play(self.sounds[name]) end)
    else
        audio.play(self.sounds[name])
    end
end

function game:startMusic()
    audio.play(self.gamemusic, { loops = -1 })
end

function game:showScreen(name, startGame)
    messageBus:post(messageBus.play_sfx, { name = "back" })
    composer.gotoScene("x-scenes." .. name, { effect = "slideLeft", time = 200, })
end

return game
