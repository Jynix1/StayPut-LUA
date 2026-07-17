local Menu = {}
Menu.__index = Menu

function Menu.new()
    local self = setmetatable({}, Menu)

    self.cursorImage = love.graphics.newImage("sprites/you.png")
    self.cursorImage:setFilter("nearest", "nearest")

    self.font = love.graphics.newFont("fonts/tiny5.ttf", 36)

    self.items = {
        "Start Game",
        "Settings",
        "StayPut Made With TurboWarp",
        "Quit"
    }

    self.settingsitems = {
        "Back",
        "Fullscreen",
    }

    self.selectedIndex = 1
    self.gameStarted = false
    self.itemHeight = 50
    self.startY = 150
    self.textX = 300
    self.currentScreen = "menu"
    return self
end

function Menu:update()
    -- intentionally left empty cuz input is handled in main.lua
end

function Menu:setScreen(screen)
    self.currentScreen = screen
    self.selectedIndex = 1
end

function Menu:getActiveItems()
    if self.currentScreen == "settings" then
        return self.settingsitems
    else
        return self.items
    end
end

function Menu:selectUp()

    local active = self:getActiveItems()
    local target

    if self.currentScreen == "settings" then
        target = 2
    else
        target = 4
    end

    self.selectedIndex = self.selectedIndex - 1
    if self.selectedIndex == 0 then
        self.selectedIndex = #active
    end
end

function Menu:selectDown()

    local active = self:getActiveItems()
    local target

    if self.currentScreen == "settings" then
        target = 2
    else
        target = 4
    end

    self.selectedIndex = self.selectedIndex + 1
    if self.selectedIndex > target then
        self.selectedIndex = 1
    end
end

function Menu:setGameStarted(started)
    self.gameStarted = started
    if started then
        self.items[1] = "Resume Game"
    else
        self.items[1] = "Start Game"
    end
end

function Menu:draw()
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.font)

    local active = self:getActiveItems()

    for i = 1, #active do
        local itemY = self.startY + (i - 1) * self.itemHeight

        if active[i] == "Settings" and self.gameStarted then
            love.graphics.setColor(0.5, 0.5, 0.5)
        else
            if i == self.selectedIndex then
                love.graphics.setColor(1, 1, 0)
            else
                love.graphics.setColor(1, 1, 1)
            end
        end

        if active[i] == "Fullscreen" then
            if Fullscreen == true then
                love.graphics.print("Fullscreen: (true)", self.textX, itemY)
            else
                love.graphics.print("Fullscreen: (false)", self.textX, itemY)
            end
        else
            love.graphics.print(active[i], self.textX, itemY)
        end

        if i == self.selectedIndex then
            love.graphics.draw(self.cursorImage, self.textX - 45, itemY + 8, 0, 3, 3)
        end
    end

    love.graphics.setColor(1, 1, 1)
end

function Menu:getSelectedItem()
    local active = self:getActiveItems()
    return active[self.selectedIndex]
end

function Menu:getSelectedIndex()
    return self.selectedIndex
end

return Menu
