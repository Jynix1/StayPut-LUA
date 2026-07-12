-- StayPut. A passion project made to learn Lua and LÖVE2D.
-- Originating from a game made in TurboWarp/Scratch. This is a rewrite of the original game in Lua using the LÖVE2D framework.
-- AI partially used to assist learning.

if os.getenv("LOVE2D_TOOLS") then pcall(require, "_love2d_tools_bridge") end

local Player = require("baller")
local object = require("objects")

local discordrefreshTimer = 0

RoundData =
{

    ongoing = true,

    level = 0,
    time = 1,
    starttime = 20,

    difficultyTBO = 3,
    spawnTimer = 3,

    enemyPicker = false,
    enemiesActive = {}

}

EnemyOptions =
{
    { id = "square", title = "Square", desc = "A heavy box. Falls to get in your way.", cd = -1 },
    { id = "follower", title = "Follower", desc = "Follows and pushes the player.", cd = 0 },
    { id = "bomb", title = "Bomb", desc = "Weak object, explodes with projectiles in all directions.", cd = 1 }
}

local ChoiceButtons = {
    { x = 115, y = 100, width = 240, height = 200, id = "", title = "", desc = "" },
    { x = 413, y = 100, width = 240, height = 200, id = "", title = "", desc = "" },
    { x = 711, y = 100, width = 240, height = 200, id = "", title = "", desc = "" },
}

local function refreshChoiceButtons()
    
    local pool = {}
    for i, option in ipairs(EnemyOptions) do 
        local alreadyingame = false

        for _, activeId in ipairs(RoundData.enemiesActive) do
            if option.id == activeId then
                alreadyingame = true
            end
        end

        if not alreadyingame then
            table.insert(pool,option)
        end

    end
    
    if #pool == 0 then
        RoundData.enemyPicker = false
        RoundData.ongoing = true
        return
    end

    for i = 1, 3 do
        if #pool > 0 then
        local randomIndex = love.math.random(1,#pool)
        local chosenEnemy = table.remove(pool, randomIndex)

        ChoiceButtons[i].id = chosenEnemy.id
        ChoiceButtons[i].title = chosenEnemy.title
        ChoiceButtons[i].desc = chosenEnemy.desc
        else
            ChoiceButtons[i].id = nil -- Placeholder ID
            ChoiceButtons[i].title = "No Option"
            ChoiceButtons[i].desc = ""
        end
        
    end
end

objects = {}
local spawnHold = {}                               --                                         -----------------------  Dev utility to spawn stuff                            
local spawnHoldDelay = 0.75                        --
local spawnHoldRepeatInterval = 0.01               --
local spawnKeyConfig = {                           --
    ["1"] = "square",
    ["2"] = "follower",
    ["3"] = "bomb",
    ["4"] = "tripwire"
}                                                  --

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
        setDiscordPresence("Playing StayPut, "..player.hp.." Hits left, on level "..RoundData.level)
    else
        setDiscordPresence("Paused", "Taking a break")
    end
end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    
    love.physics.setMeter(64)
    world = love.physics.newWorld(0, 15 * 64, true)

    floorBody = love.physics.newBody(world, 533, 550, "static")
    floorShape = love.physics.newRectangleShape(700,125 )
    floorFixture = love.physics.newFixture(floorBody, floorShape)
    floorFixture:setFriction(1)
    
    -- Initialize the menu
    menu = Menu.new()

    errorSound = love.audio.newSource("sounds/sfx/error.mp3", "static")
    movemenuSound = love.audio.newSource("sounds/sfx/move.mp3", "static")
    IntroSound = love.audio.newSource("sounds/sfx/move.mp3", "static")
    IntroSound2 = love.audio.newSource("sounds/sfx/select.mp3", "static")
    selectSound = love.audio.newSource("sounds/sfx/select.mp3", "static")
    equipSound = love.audio.newSource("sounds/sfx/equip.mp3", "static")
    barRecoverSound = love.audio.newSource("sounds/sfx/barheal.mp3","static")
    barRecoverSound:setPitch(1.2)

    menuVisible = true
    gameRunning = false
    gameStarted = false
    settingsVisible = false
    IntroPlaying = false
    IntroFrame = 1
    IntroFrameDelay = 0.5
    IntroPlayedBefore = false

    IntroFrames = {
        love.graphics.newImage("sprites/mspawn/mspawn1.png"),
        love.graphics.newImage("sprites/mspawn/mspawn2.png"),
        love.graphics.newImage("sprites/mspawn/mspawn3.png"),
        love.graphics.newImage("sprites/mspawn/mspawn4.png"),
        love.graphics.newImage("sprites/mspawn/mspawn4.png"),
    }

    player = Player.new(world, 533, 200)

    discordPresenceStart = os.time()
    if discordRPC.available and discordAppId and discordAppId ~= "" then
        discordRPC.initialize(discordAppId, true, nil)
        discordEnabled = true
    else
        print("Discord Rich Presence unavailable:", discordRPC.status)
    end
    updateDiscordPresence()
    
    settingsFont = love.graphics.newFont("fonts/tiny5.ttf", 36)
    tobyfont = love.graphics.newFont("fonts/toby.otf",32)
    smalltobyfont = love.graphics.newFont("fonts/toby.otf",18)

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

function love.update(dt)--                                                                                               ----  v v v  | main game loop |  v v v  ----

    if discordEnabled then
        discordRPC.runCallbacks()
        passivediscordupdate(dt)
    end

    for key, objType in pairs(spawnKeyConfig) do  --------------------------------------------  place holder dev key
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
        if not IntroPlaying or IntroPlayedBefore then
            IntroPlaying = false

            for i = #objects, 1, -1 do -- update objects
                local obj = objects[i]
                obj:update(dt)
                if obj.lifetime <= 0 then
                    table.remove(objects, i)
                end
            end

            for i = #projectiles, 1, -1 do -- update projectiles
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
            player:control("space", "s", "a", "d", "lshift", 500)
            player:OffStageRespawn()

            if RoundData.ongoing then
                RoundData.time = RoundData.time - dt
                RoundData.spawnTimer = RoundData.spawnTimer - dt

                if RoundData.spawnTimer <= 0 then
                    if #RoundData.enemiesActive > 0 then

                        local random = love.math.random(1, #RoundData.enemiesActive)
                        local enemyIdToSpawn = RoundData.enemiesActive[random]

                        local spawnX = love.math.random(200, 866) 

                        local enemyCD = 0
                        for _, option in ipairs(EnemyOptions) do
                            if option.id == enemyIdToSpawn then
                                enemyCD = option.cd or 0
                            end
                        end

                        local newEnemy = object:new(spawnX, -50, enemyIdToSpawn)
                        table.insert(objects, newEnemy)
                        RoundData.spawnTimer = RoundData.difficultyTBO + enemyCD

                    end
                end
            end                                                                                     -- round stuff --

            if RoundData.time <= 0 then
                
                RoundData.ongoing = false
                RoundData.enemyPicker = true

                RoundData.level = RoundData.level + 1
                RoundData.starttime = RoundData.starttime + 3
                RoundData.time = RoundData.starttime
                RoundData.difficultyTBO = RoundData.difficultyTBO - 0.1
                refreshChoiceButtons()
                updateDiscordPresence()

                player:QueueHeal(2,4,50)
                if player.hpBar < 100 then
                    barRecoverSound:play()
                end

            end


        else
            IntroFrameDelay = IntroFrameDelay - dt
            if IntroFrameDelay <= 0 then

                IntroFrame = IntroFrame + 1
                IntroSound:setPitch(2)
                IntroSound:play()

                IntroFrameDelay = 0.5

                if IntroFrame > 5 then

                    IntroPlaying = false
                    IntroPlayedBefore = true
                    IntroFrameDelay = 0.05

                    IntroSound2:setPitch(2)
                    IntroSound2:play()

                end

            end
        end
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

function love.draw()--                                                                                        ----  v v v  | all drawing |  v v v  ----

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

        local ww = love.graphics.getWidth()
        local wh = love.graphics.getHeight()

        if not RoundData.enemyPicker then
            love.graphics.printf(string.format("%.1f",RoundData.time),0,35,ww,"center")
        end
        love.graphics.setFont(smalltobyfont)
        love.graphics.printf(RoundData.level,0,10,ww,"center")
    end

    if RoundData.enemyPicker and gameStarted and not IntroPlaying then                                          -------------------- drawing choice buttons
        love.mouse.setCursor()
        for i, btn in ipairs(ChoiceButtons) do

            local designY = btn.y + math.sin(love.timer.getTime())*10
            local btnY = designY + 50
            local mx,my = love.mouse.getPosition()

            if mx < btn.x + btn.width and mx > btn.x and my < btn.y + btn.height and my > btn.y then
                local cur = love.mouse.getSystemCursor("hand")
                love.mouse.setCursor(cur)
                love.graphics.setColor(1, 0, 0,0.15)
            else
                love.graphics.setColor(0, 0, 0,0.5)

            end

            love.graphics.rectangle("fill", btn.x, designY, btn.width, btn.height)

            love.graphics.setColor(1, 0, 0)
            love.graphics.rectangle("line", btn.x, designY, btn.width, btn.height)
            love.graphics.line(btn.x,btnY,btn.x + btn.width,btnY)

            love.graphics.setFont(tobyfont)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(btn.title, btn.x, designY + 5, btn.width, "center")

            love.graphics.setFont(smalltobyfont)
            love.graphics.printf(btn.desc, btn.x + 10, designY + 60, btn.width - 20, "left")

        end
    end

    if menuVisible then -- drawing menu
        menu:draw()
    end

    if settingsVisible then                                                                                         ---------------- drawing settings menu
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(settingsFont)

        love.graphics.print("SETTINGS", 300, 150)

        love.graphics.setFont(love.graphics.newFont("fonts/tiny5.ttf", 24))
        love.graphics.print("(Not yet implemented)", 300, 250)
        love.graphics.print("Press ESC to go back", 300, 320)
    end
end

-- Handle keyboard input for menu and game controls
function love.keypressed(key)

    if key == "escape" and not IntroPlaying then
        if settingsVisible then
            settingsVisible = false
            menuVisible = true
        else
            if gameStarted then
                menuVisible = not menuVisible
                gameRunning = not gameRunning
            end
        end
        updateDiscordPresence()
        return
    end

    if key == "backspace" then
        RoundData.time = 0
    end

    if menuVisible and not settingsVisible then
        if key == "up" or key == "w" then  
            movemenuSound:clone():play()
            menu:selectUp()
            return
        elseif key == "down" or key == "s" then
            movemenuSound:clone():play()
            menu:selectDown()
            return
        end
    end

    if menuVisible and not settingsVisible and (key == "return" or key == "z") then

        selectSound:clone():play()
        local selectedItem = menu:getSelectedItem()

        if selectedItem == "Start Game" or selectedItem == "Resume Game" then

            menuVisible = false
            gameRunning = true
            gameStarted = true
            IntroPlaying = true
            IntroFrame = 1

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

function love.mousepressed(mx,my,button)
    if RoundData.enemyPicker and button == 1 then
        for i, btn in ipairs(ChoiceButtons) do
            if mx >= btn.x and mx <= btn.x + btn.width and my >= btn.y and my <= btn.y + btn.height then

                if btn.id ~= nil then
                    table.insert(RoundData.enemiesActive,btn.id)
                    RoundData.enemyPicker = false
                    RoundData.ongoing = true
                    break
                end
            end
        end
    end
end

function passivediscordupdate(dt)
    discordrefreshTimer = discordrefreshTimer - dt
    if discordrefreshTimer <= 0 then
        discordrefreshTimer = 7
        updateDiscordPresence()
    end
end

-- TODO: Add enemy spawning and improve timer UI.