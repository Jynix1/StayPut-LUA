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

    self.selectedIndex = 1
    self.gameStarted = false
    self.itemHeight = 50
    self.startY = 150
    self.textX = 300
    return self
end

function Menu:update()
    -- intentionally left empty cuz input is handled in main.lua
end

function Menu:selectUp()
    self.selectedIndex = self.selectedIndex - 1
    if self.selectedIndex < 1 then
        self.selectedIndex = #self.items
    end
end

function Menu:selectDown()
    self.selectedIndex = self.selectedIndex + 1
    if self.selectedIndex > #self.items then
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

    for i = 1, #self.items do
        local itemY = self.startY + (i - 1) * self.itemHeight

        if self.items[i] == "Settings" and self.gameStarted then
            love.graphics.setColor(0.5, 0.5, 0.5)
        else
            if i == self.selectedIndex then
                love.graphics.setColor(1, 1, 0)
            else
                love.graphics.setColor(1, 1, 1)
            end
        end

        love.graphics.print(self.items[i], self.textX, itemY)

        if i == self.selectedIndex then
            love.graphics.draw(self.cursorImage, self.textX - 45, itemY + 8, 0, 3, 3)
        end
    end

    love.graphics.setColor(1, 1, 1)
end

function Menu:getSelectedItem()
    return self.items[self.selectedIndex]
end

function Menu:getSelectedIndex()
    return self.selectedIndex
end

return Menu
