local messageBus = {
    listeners = {},
    show_credits_screen = 'show_credits_screen',
    show_game_over_screen = 'show_game_over_screen',
    show_ingame_screen = 'show_ingame_screen',
    show_opponent_screen = 'show_opponent_screen',
    show_levelcomplete_screen = 'levelcomplete',
    show_title_screen = 'show_title_screen',
    start_music = 'start_music',
    play_sfx = 'play_sfx',
    game_update = 'game_update',
    game_render = 'game_render',
    card_attached = 'card_attached',
    screen_shake = 'screen_shake',
    indicator_status = 'indicator_status',
}

function messageBus:register(eventName, fn)
    if self.listeners[eventName] == nil then
        self.listeners[eventName] = {}
    end
    local listeners = self.listeners[eventName]
    listeners[#listeners + 1] = fn
end

function messageBus:remove(eventName, fn)
    if self.listeners[eventName] == nil then
        return
    end
    local listeners = self.listeners[eventName]
    for i = 1, #listeners do
        if listeners[i] == fn then
            table.remove(listeners, i)
            return
        end
    end
end

function messageBus:post(eventName, options)
    if self.listeners[eventName] == nil then
        return
    end
    local listeners = self.listeners[eventName]
    for i = 1, #listeners do
        listeners[i](options)
    end
end

return messageBus
