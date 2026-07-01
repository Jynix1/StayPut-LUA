if os.getenv("LOVE2D_TOOLS") then pcall(require, "_love2d_tools_bridge") end

local Player = require("baller")
local object = require("objects")

objects = {}

local Menu = require("menu")

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

    -- Game state flags
    menuVisible = true
    gameRunning = false
    gameStarted = false
    settingsVisible = false
    
    -- Load font for settings menu
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
end

function love.update(dt)
    -- Only update gameplay if the menu is not visible
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
        -- !!!                                                                                                                                 !!!!!!!!!!!!!!!!!!!
    end

    if menuVisible then
        menu:update()
    end
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
    if key == "1" then                                                                                                                  --placeholder dev spawn key
        local newObject = object:new(533, 0, "square")
        table.insert(objects, newObject)
    end
    if key == "2" then                                                                                                                  --placeholder dev spawn key
        local newObject = object:new(533, 0, "follower")
        table.insert(objects, newObject)
    end
    if key == "3" then                                                                                                                  --placeholder dev spawn key
        local newObject = object:new(533, 0, "bomb")
        table.insert(objects, newObject)
    end
    -- ESC toggles the menu visibility or closes settings
    if key == "escape" then
        if settingsVisible then
            -- Close settings and return to main menu
            settingsVisible = false
            menuVisible = true
        else
            -- Toggle main menu
            menuVisible = not menuVisible
            gameRunning = not gameRunning
        end
        return  -- Don't process other input when toggling menu
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
            
        elseif selectedItem == "Settings" then
            if not gameStarted then
                -- Open the settings menu
                menuVisible = false
                settingsVisible = true
            else
                errorSound:play()  -- Play error sound
                -- Gray out Settings button when game has not been started
                -- Do nothing (or show a message if desired)
            end
        elseif selectedItem == "StayPut Made With TurboWarp" then
            -- Open an external URL
            love.system.openURL("https://stayput.my.canva.site/")
            
        elseif selectedItem == "Quit" then
            -- Close the game
            love.event.quit()
        end
    end
end

