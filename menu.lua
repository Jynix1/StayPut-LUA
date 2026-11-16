local Menu = {}
Menu.__index = Menu

function Menu.new()
	local self = setmetatable({}, Menu)

	self.cursorImage = love.graphics.newImage("sprites/you.png")
	self.cursorImage:setFilter("nearest", "nearest")

	self.cursorSX = 3
	self.cursorSY = 3

	self.quitCount = 0

	self.font = love.graphics.newFont("fonts/tiny5.ttf", 32)

	self.screen = "main"
	self.selected = 1

	self.quitCount = 0

	self.menus = {
		main = {
			{
				text = "Begin",
				x = 100,
				y = 400,
				w = 150,
				h = 100,

				hovered = false,
				toggle = false,
				action = function()
					menuVisible = false
					gameRunning = true
					gameStarted = true
					settingsVisible = false
					IntroPlaying = true
					IntroFrame = 1

					--updateDiscordPresence()
				end,
			},
			{
				text = "Settings",
				x = 300,
				y = 400,
				w = 150,
				h = 100,

				hovered = false,
				toggle = false,
				action = function()
					self:setScreen("settings")
					menuVisible = true
					settingsVisible = true
				end,
			},
			{
				text = "Original StayPut",
				x = 500,
				y = 400,
				w = 150,
				h = 100,

				hovered = false,
				toggle = false,
				action = function()
					self:setScreen("oldstayputs")
					menuVisible = true
				end,
			},
			{
				text = "Quit",
				x = 700,
				y = 400,
				w = 150,
				h = 100,

				hovered = false,
				toggle = false,
				action = function()
					if gameStarted then
						if quitCount >= 3 then
							love.event.quit()
						else
							quitCount = quitCount + 1
						end
					else
						love.event.quit()
					end
				end,
			},
		},
		pause = {
			{
				text = "Resume",
				x = 100,
				y = 400,
				w = 150,
				h = 100,

				hovered = false,
				toggle = false,
				action = function()
					menuVisible = false
					gameRunning = true
					gameStarted = true
					settingsVisible = false
					IntroPlaying = true
					IntroFrame = 1

					--updateDiscordPresence()
				end,
			},
			{
				text = "Settings",
				x = 300,
				y = 400,
				w = 150,
				h = 100,

				hovered = false,
				toggle = false,
				action = function()
					self:setScreen("settings")
					menuVisible = true
					settingsVisible = true
				end,
			},
			{
				text = "Quit",
				x = 700,
				y = 400,
				w = 150,
				h = 100,

				hovered = false,
				toggle = false,
				action = function()
					if gameStarted then
						if self.quitCount >= 3 then
							love.event.quit()
						else
							self.quitCount = self.quitCount + 1
						end
					else
						love.event.quit()
					end
				end,
			},
		},
		settings = {
			{
				text = "Close",
				x = 0,
				y = 0,
				w = 150,
				h = 100,

				hovered = false,
				toggle = false,
				action = function()
					menuVisible = true
					menu:setScreen("main")
				end,
			},
			{
				getText = function()
					return "Fullscreen: " .. tostring(Fullscreen)
				end,
				x = 0,
				y = 0,
				w = 150,
				h = 100,

				hovered = false,
				toggle = false,
				action = function()
					Fullscreen = not Fullscreen
					love.window.setFullscreen(Fullscreen)
					equipSound:clone():play()
				end,
			},
			{
				text = "Keybinds",
				x = 0,
				y = 0,
				w = 150,
				h = 100,

				hovered = false,
				toggle = false,
				action = function()
					self:setScreen("keybinds")
					menuVisible = true
				end,
			},
			{
				text = "Audio Settings",
				x = 0,
				y = 0,
				w = 150,
				h = 100,

				hovered = false,
				toggle = false,
				action = function()
					self:setScreen("audiosettings")
					menuVisible = true
				end,
			},
			{
				getText = function()
					return "FPS Counter: " .. tostring(FPSCountToggle)
				end,
				x = 0,
				y = 0,
				w = 150,
				h = 100,

				hovered = false,
				toggle = false,
				action = function()
					FPSCountToggle = not FPSCountToggle
					equipSound:clone():play()
				end,
			},
		},
		keybinds = {
			{
				text = "Back",
				x = 0,
				y = 0,
				w = 150,
				h = 100,

				hovered = false,
				toggle = false,
				action = function()
					self:setScreen("settings")
				end,
			},
			{
				getText = function()
					return "Jump: " .. Keybinds["Jump"]
				end,
				x = 0,
				y = 0,
				w = 150,
				h = 100,

				hovered = false,
				toggle = false,
				action = function()
					keybind_WIP_timer = 5
					keybind_toBeEdited = "Jump"
				end,
			},
			{
				getText = function()
					return "Left: " .. Keybinds["Left"]
				end,
				x = 0,
				y = 0,
				w = 150,
				h = 100,

				hovered = false,
				toggle = false,
				action = function()
					keybind_WIP_timer = 5
					keybind_toBeEdited = "Left"
				end,
			},
			{
				getText = function()
					return "Right: " .. Keybinds["Right"]
				end,
				x = 0,
				y = 0,
				w = 150,
				h = 100,

				hovered = false,
				toggle = false,
				action = function()
					keybind_WIP_timer = 5
					keybind_toBeEdited = "Right"
				end,
			},
			{
				getText = function()
					return "Down: " .. Keybinds["Down"]
				end,
				x = 0,
				y = 0,
				w = 150,
				h = 100,

				hovered = false,
				toggle = false,
				action = function()
					keybind_WIP_timer = 5
					keybind_toBeEdited = "Down"
				end,
			},
			{
				getText = function()
					return "Dash: " .. Keybinds["Dash"]
				end,
				x = 0,
				y = 0,
				w = 150,
				h = 100,

				hovered = false,
				toggle = false,
				action = function()
					keybind_WIP_timer = 5
					keybind_toBeEdited = "Dash"
				end,
			},
		},
		audiosettings = {
			{
				text = "Back",
				x = 0,
				y = 0,
				w = 150,
				h = 100,

				hovered = false,
				toggle = false,
				action = function()
					self:setScreen("settings")
				end,
			},
			{
				getText = function()
					return "Master Volume: " .. math.floor(MasterVolume * 100) .. "%"
				end,
				x = 0,
				y = 0,
				w = 150,
				h = 100,

				hovered = false,
				toggle = false,
				action = function()
					keyEditing.editingMasterVolume = true
				end,
			},
		},
		oldstayputs = {
			{
				text = "Back",
				x = 0,
				y = 0,
				w = 150,
				h = 100,

				hovered = false,
				toggle = false,
				action = function()
					self:setScreen("main")
				end,
			},
			{
				text = "CodeTorch",
				x = 0,
				y = 0,
				w = 150,
				h = 100,

				hovered = false,
				toggle = false,
				action = function()
					love.system.openURL("https://codetorch.net/en/projects/117367")
				end,
			},
			{
				text = "Standalone / Custom Site",
				x = 0,
				y = 0,
				w = 150,
				h = 100,

				hovered = false,
				toggle = false,
				action = function()
					love.system.openURL("https://stayput.my.canva.site/")
				end,
			},
		},
	}

	return self
end

function Menu:setScreen(screen)
	self.selected = 1
	self.screen = screen
end

function Menu:getSelectedButton()
	local curScreen = self.screen
	local curSelect = self.selected
	return self.menus[curScreen][curSelect]
end

function Menu:selectNext()
	self.selected = self.selected + 1
end

function Menu:selectLast()
	self.selected = self.selected - 1
end

function Menu:update()
	local mx,my = getVirtualMousePosition(love.mouse.getPosition())
	for _, button in ipairs(self.menus[self.screen]) do
		local withinBounds = mx > button.x and mx < button.x+button.w and my > button.y and my < button.y+button.h
		if withinBounds then
			button.hovered = true
		else
			button.hovered = false
		end
	end
end

function Menu:mousepressed(px,py,b)
	local mx, my = getVirtualMousePosition(px,py)
	for _, button in ipairs(self.menus[self.screen]) do
		local withinBounds = mx > button.x and mx < button.x + button.w and my > button.y and my < button.y + button.h
		if withinBounds then
			button.action()
		end
	end
end

function Menu:draw()
	for _, button in ipairs(self.menus[self.screen]) do
        -- then use buttons predefined x and y, !!(maybe w and h)!! to detect if mouse is on and clicking for input detection.
		local x,y,w,h = button.x,button.y,button.w,button.h
		local renderText = button.text
		if button.getText then
			renderText = button:getText() or button.text
		end

		love.graphics.setFont(self.font)

		love.graphics.setColor(0, 0, 0, 0.5)
		love.graphics.rectangle("fill", x,y,w,h)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.rectangle("line", x, y, w, h)
		love.graphics.printf(renderText, x, y+12, w, "center")
	end
end

return Menu
