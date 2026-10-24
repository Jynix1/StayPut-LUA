MusicData = {
    current = nil,
    pitch = 1,
}

local Music = {
    --["intermission"] = "sounds/music/intermission.mp3",
    ["1-10"] = love.audio.newSource("sounds/mus/1-10.mp3", "stream"),
}
local pausedAt = nil

Music["1-10"]:setLooping(true)

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
        if RoundData.level > 0 and RoundData.level < 11 then
            if MusicData.current ~= "1-10" then
                MusicData.current = "1-10"
            end
        end
    end
    play()
end

return {
    update = update,
    MusicData = MusicData,
}