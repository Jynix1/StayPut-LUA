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

-- Handle keyboard input (up/down arrow keys)
function Menu:update()
    -- This function is intentionally left empty because input handling is done in main.lua
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

-- Draw the menu on screen
function Menu:draw()
    -- Draw a semi-transparent black background
    love.graphics.setColor(0, 0, 0, 0.7)  -- Black with 70% opacity
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Set text color to white
    love.graphics.setColor(1, 1, 1)
    
    -- Set the font for menu items
    love.graphics.setFont(self.font)
    
    -- Loop through each menu item
    for i = 1, #self.items do
        -- Calculate the Y position for this item
        local itemY = self.startY + (i - 1) * self.itemHeight
        
        -- Set color based on whether this item is disabled
        if self.items[i] == "Settings" and self.gameStarted then
            -- Gray out Settings button when game has been started
            love.graphics.setColor(0.5, 0.5, 0.5)
        else
            if i == self.selectedIndex then
                -- Highlight the selected item in yellow
                love.graphics.setColor(1, 1, 0)
            else
                -- Normal white color for unselected items
                love.graphics.setColor(1, 1, 1)
            end
        end
        
        -- Draw the menu item text
        love.graphics.print(self.items[i], self.textX, itemY)
        
        if i == self.selectedIndex then
            love.graphics.draw(self.cursorImage, self.textX - 45, itemY + 8, 0, 3, 3)
        end
    end
    
    -- Reset color to white (in case other code uses it)
    love.graphics.setColor(1, 1, 1)
end

-- Helper function to get which item is currently selected
function Menu:getSelectedItem()
    return self.items[self.selectedIndex]
end

-- Helper function to get the index of the selected item
function Menu:getSelectedIndex()
    return self.selectedIndex
end

return Menu
