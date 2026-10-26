MusicData = {
    current = nil,
    pitch = 1,
}

local Music = {
    --["intermission"] = "sounds/music/intermission.mp3",
    ["1-9"] = love.audio.newSource("sounds/mus/1-9.mp3", "stream"),
}
local pausedAt = nil

Music["1-9"]:setLooping(true)

local function play()
    for name, music in pairs(Music) do
        if name ~= MusicData.current then
            if music:isPlaying() then
                music:stop()
            end
        end
    end

    local music = Music[MusicData.current]
    if music == nil then
        return
    end

    local shouldPlay = RoundData.ongoing and gameRunning and not GAMEOVER
    if shouldPlay then
        music:setPitch(MusicData.pitch)
        if not music:isPlaying() then
            if pausedAt ~= nil then
                music:seek(pausedAt, "seconds")
                pausedAt = nil
            end
            music:play()
        end
    elseif music:isPlaying() then
        pausedAt = music:tell("seconds")
        music:pause()
    end
end

local function update(dt)
    if RoundData.ongoing then
        if RoundData.level > 0 and RoundData.level < 10 then
            if MusicData.current ~= "1-9" then
                MusicData.current = "1-9"
            end
        end
    end
    play()
end

local function reset()
    for _, music in pairs(Music) do
        music:stop()
        music:seek(0,"seconds")
    end

    MusicData.current = nil
    MusicData.pitch = 1
    pausedAt = nil
end

return {
    update = update,
    MusicData = MusicData,
    reset = reset,
}