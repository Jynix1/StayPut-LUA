local Menu = {}
Menu.__index = Menu

function Menu.new()
    local self = setmetatable({}, Menu)

    self.cursorImage = love.graphics.newImage("sprites/you.png")
    self.cursorImage:setFilter("nearest", "nearest")

    self.cursorSX = 3
    self.cursorSY = 3

    self.quitCount = 0

    self.font = love.graphics.newFont("fonts/tiny5.ttf", 40)

    self.fullscreenstatus = tostring(Fullscreen)
    local playstring
    local quitstring
    if gameStarted then
        playstring = "Resume"
        quitstring = "("..self.quitCount.."/4)"
    else
        playstring = "Play"
        quitstring = ""
    end
    
    self.screens = {
        menu = {
            [1] = playstring,
            [2] = "Settings",
            [3] = "Play Original StayPut",
            [4] = "Quit "..quitstring
        },
        settings = {
            [1] = "Back",
            [2] = "Fullscreen: "..self.fullscreenstatus,
            [3] = "Keybinds",
            [4] = "Audio Settings",
            [5] = "FPS Counter: "..tostring(FPSCountToggle)
        },
        keybinds = {
            [1] = "Back",
            [2] = "Jump: "..Keybinds["Jump"],
            [3] = "Left: "..Keybinds["Left"],
            [4] = "Right: "..Keybinds["Right"],
            [5] = "Down: "..Keybinds["Down"],
            [6] = "Dash: "..Keybinds["Dash"],
        },
        audiosettings = {
            [1] = "Back",
            [2] = "Master Volume: "..math.floor(MasterVolume*100).."%"
        },
        oldstayputs = {
            [1] = "Back",
            [2] = "CodeTorch",
            [3] = "Standalone / Custom Site"
        },
    }

    self.selectedIndex = 1
    
    self.gameStarted = false
    self.itemHeight = 50
    self.realY = 550
    self.startY = 350
    self.textX = 150
    self.currentScreen = "menu"
    return self
end

function Menu:update()
    -- input is handled in main.lua
    self.fullscreenstatus = tostring(Fullscreen)
    self.screens.settings[2] = "Fullscreen: " .. tostring(Fullscreen)
    self.realY = self.realY + ((self.startY - self.realY)/24)
    self:refresh()
end

function Menu:setScreen(screen)
    self.currentScreen = screen
    self.selectedIndex = 1
end

function Menu:getActiveItems()
    return self.screens[self.currentScreen]
end

function Menu:selectUp()
    self.selectedIndex = self.selectedIndex - 1
    local items = self:getActiveItems()
    if self.selectedIndex < 1 then
        self.selectedIndex = #items
    end
end

function Menu:selectDown()
    self.selectedIndex = self.selectedIndex + 1
    local items = self:getActiveItems()
    if self.selectedIndex > #items then
        self.selectedIndex = 1
    end
end

function Menu:getSelectedItem()
    local screen = self.currentScreen
    local cur = self.selectedIndex
end

function Menu:draw()
    love.graphics.setColor(0, 0, 0, 0.418)
    love.graphics.rectangle("fill",0,0,1066,800)

    love.graphics.setFont(self.font)
    local items = self:getActiveItems()
    local curitem = items[self.selectedIndex]

    if self.currentScreen ~= "keybinds" and self.currentScreen ~= "settings" then
        self.startY = 350
    else
        self.startY = 300
    end
    for i = 1, #items do
        local x,y = self.textX,self.realY + (48*(i-1))
        local g = 0.75 - (math.cos(love.timer.getTime()*5) )/4

        if i == self.selectedIndex then
            love.graphics.setColor(1,1,1,1)
            love.graphics.draw(self.cursorImage,x - 44,y+9,0,self.cursorSX,self.cursorSY)
            if (keybind_WIP_timer <= 0) and not editingMasterVolume then love.graphics.setColor(1, g, 0, 1) else love.graphics.setColor(1,0,1,1) end
        else
            love.graphics.setColor(1,1,1,1)
        end
        love.graphics.print(items[i],x,y,0,1,1)

    end

end

function Menu:refresh()
    self.fullscreenstatus = tostring(Fullscreen)
    local playstring
    local quitstring
    if gameStarted then
        playstring = "Resume"
        quitstring = "("..self.quitCount.."/4)"
    else
        playstring = "Play"
        quitstring = ""
    end
    
    self.screens = {
        menu = {
            [1] = playstring,
            [2] = "Settings",
            [3] = "Play Original StayPut",
            [4] = "Quit "..quitstring
        },
        settings = {
            [1] = "Back",
            [2] = "Fullscreen: "..self.fullscreenstatus,
            [3] = "Keybinds",
            [4] = "Audio Settings",
            [5] = "FPS Counter: "..tostring(FPSCountToggle)
        },
        keybinds = {
            [1] = "Back",
            [2] = "Jump: "..Keybinds["Jump"],
            [3] = "Left: "..Keybinds["Left"],
            [4] = "Right: "..Keybinds["Right"],
            [5] = "Down: "..Keybinds["Down"],
            [6] = "Dash: "..Keybinds["Dash"],
        },
        audiosettings = {
            [1] = "Back",
            [2] = "Master Volume: "..math.floor(MasterVolume*100).."%"
        },
        oldstayputs = {
            [1] = "Back",
            [2] = "CodeTorch",
            [3] = "Standalone / Custom Site"
        },
    }
end

return Menu
