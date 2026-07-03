-- StayPut. A passion project made to learn Lua and LÖVE2D.
-- Originating from a game made in TurboWarp/Scratch. This is a rewrite of the original game in Lua using the LÖVE2D framework.
-- AI partially used to assist learning.

if os.getenv("LOVE2D_TOOLS") then pcall(require, "_love2d_tools_bridge") end

local Player = require("baller")
local object = require("objects")

objects = {}
local spawnHold = {}
local spawnHoldDelay = 0.75
local spawnHoldRepeatInterval = 0.01
local spawnKeyConfig = {
    ["1"] = "square",
    ["2"] = "follower",
    ["3"] = "bomb",
}

local Menu = require("menu")
local discordRPC = require("discordRPC")
local discordAppId = os.getenv("DISCORD_APP_ID") or "1522718970082365480"
local discordEnabled = false
local discordPresenceStart = nil

local function setDiscordPresence(details, state)
    if not discordEnabled then
        return
    end

    discordRPC.updatePresence({
        details = details,
        state = state,
        startTimestamp = discordPresenceStart or os.time(),
        instance = 0,
    })
end

local function updateDiscordPresence()
    if not discordEnabled then
        return
    end

    if menuVisible then
        setDiscordPresence("In the menu")
    elseif gameRunning then
        setDiscordPresence("Playing StayPut, "..player.hp.." Hits left.")
    else
        setDiscordPresence("Paused", "Taking a break")
    end
end

function love.load()
    -- Set pixel-perfect filtering (no blur on scaled images)
    love.graphics.setDefaultFilter("nearest", "nearest")
    
    love.physics.setMeter(64)
    world = love.physics.newWorld(0, 15 * 64, true)

    player = Player.new(world, 533, 200)

    floorBody = love.physics.newBody(world, 533, 550, "static")
    floorShape = love.physics.newRectangleShape(700,125 )
    floorFixture = love.physics.newFixture(floorBody, floorShape)
    floorFixture:setFriction(1)
    
    -- Initialize the menu
    menu = Menu.new()

    errorSound = love.audio.newSource("sounds/sfx/error.mp3", "static")
    movemenuSound = love.audio.newSource("sounds/sfx/move.mp3", "static")
    selectSound = love.audio.newSource("sounds/sfx/select.mp3", "static")
    equipSound = love.audio.newSource("sounds/sfx/equip.mp3", "static")

    menuVisible = true
    gameRunning = false
    gameStarted = false
    settingsVisible = false

    discordPresenceStart = os.time()
    if discordRPC.available and discordAppId and discordAppId ~= "" then
        discordRPC.initialize(discordAppId, true, nil)
        discordEnabled = true
    else
        print("Discord Rich Presence unavailable:", discordRPC.status)
    end
    updateDiscordPresence()
    
    settingsFont = love.graphics.newFont("fonts/tiny5.ttf", 36)

    function beginContact(a, b, contact)
        local dataA = a:getUserData()
        local dataB = b:getUserData()

        local projectile = nil

        if dataA and dataA.type == "projectile" then
            projectile = dataA.owner
        elseif dataB and dataB.type == "projectile" then
            projectile = dataB.owner
        end

        if projectile and not projectile.hasHit then
            projectile.hasHit = true
            projectile.lifetime = 0
        end
    end
    print("discordRPC.available =", discordRPC.available)
    print("discordRPC.status =", discordRPC.status)
end

function love.update(dt)
    if discordEnabled then
        discordRPC.runCallbacks()
    end

    for key, objType in pairs(spawnKeyConfig) do  --------------------------------------------              place holder dev key
        if love.keyboard.isDown(key) then
            local data = spawnHold[key]
            if not data then
                spawnHold[key] = {
                    timer = 0,
                    repeatTimer = 0,
                    type = objType,
                }
                local newObject = object:new(533, 0, objType)
                table.insert(objects, newObject)
            else
                data.timer = data.timer + dt
                data.repeatTimer = data.repeatTimer - dt
                if data.timer >= spawnHoldDelay and data.repeatTimer <= 0 then
                    local newObject = object:new(533, 0, objType)
                    table.insert(objects, newObject)
                    data.repeatTimer = spawnHoldRepeatInterval
                end
            end
        else
            spawnHold[key] = nil
        end
    end

    if gameRunning then

        for i = #objects, 1, -1 do
            local obj = objects[i]
            obj:update(dt)
            if obj.lifetime <= 0 then
                table.remove(objects, i)
            end
        end

        for i = #projectiles, 1, -1 do
            local proj = projectiles[i]
            proj:update(dt)
            if proj.lifetime <= 0 then
                if proj.body then
                    proj.body:destroy()
                end
                table.remove(projectiles, i)
            end
        end

        world:update(dt)
        player:update(dt)
        player:control("space","s","a","d","lshift",500)
        player:OffStageRespawn()
    end

    if menuVisible then
        menu:update()
    end
end

function love.quit()
    if discordEnabled then
        discordRPC.clearPresence()
        discordRPC.shutdown()
    end
    return false
end

function love.draw()

    if not menuVisible and not settingsVisible then

        for _, proj in ipairs(projectiles) do
            proj:draw()
        end

        for _, obj in ipairs(objects) do
            obj:draw()
        end
        
        player:draw()

        local fx = floorBody:getX()-350
        local fy = floorBody:getY()-62.5
        love.graphics.setLineStyle("smooth")
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line",fx,fy,700,125)
    end
    
    -- Draw the menu if it's visible
    if menuVisible then
        menu:draw()
    end
    
    -- Draw the settings menu if it's visible
    if settingsVisible then
        -- Draw a semi-transparent black background
        love.graphics.setColor(0, 0, 0, 0.7)  -- Black with 70% opacity
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        
        -- Set text color to white and font
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(settingsFont)
        
        -- Draw settings title
        love.graphics.print("SETTINGS", 300, 150)
        
        -- Draw placeholder text
        love.graphics.setFont(love.graphics.newFont("fonts/tiny5.ttf", 24))
        love.graphics.print("(Settings coming soon)", 300, 250)
        love.graphics.print("Press ESC to go back", 300, 320)
    end
end

-- Handle keyboard input for menu and game controls
function love.keypressed(key)

    if key == "escape" then
        if settingsVisible then
            settingsVisible = false
            menuVisible = true
        else
            menuVisible = not menuVisible
            gameRunning = not gameRunning
        end
        updateDiscordPresence()
        return
    end

    -- Handle menu navigation (up/down) when menu is visible
    if menuVisible and not settingsVisible then
        if key == "up" or key == "w" then  
            movemenuSound:play()
            menu:selectUp()
            return
        elseif key == "down" or key == "s" then
            movemenuSound:play()
            menu:selectDown()
            return
        end
    end

    -- Handle menu item selection when menu is visible
    if menuVisible and not settingsVisible and (key == "return" or key == "z") then

        selectSound:play()
        local selectedItem = menu:getSelectedItem()

        if selectedItem == "Start Game" or selectedItem == "Resume Game" then
            menuVisible = false
            gameRunning = true
            gameStarted = true
            menu:setGameStarted(true)
            updateDiscordPresence()

        elseif selectedItem == "Settings" then
            if not gameStarted then
                menuVisible = false
                settingsVisible = true
                updateDiscordPresence()
            else
                errorSound:play()
            end
        elseif selectedItem == "StayPut Made With TurboWarp" then
            love.system.openURL("https://stayput.my.canva.site/")
            
        elseif selectedItem == "Quit" then
            love.event.quit()
        end
    end
end