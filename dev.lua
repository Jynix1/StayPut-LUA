local Dev = {
	open = false,
	selected = 1,
	screen = "main",
	cameraZoomMultiplier = 1,
}

local mainOptions = {
	"close",
	"spawn",
	"upgrades",
	"camera controls",
	"FPS counter",
	"heal",
	"extend round",
}

local spawnOptions = {
	{ name = "Square", type = "object", id = "square" },
	{ name = "Follower", type = "object", id = "follower" },
	{ name = "Bomb", type = "object", id = "bomb" },
	{ name = "Tripwire", type = "object", id = "tripwire" },
	{ name = "Zip", type = "object", id = "zip" },
	{ name = "Music Box", type = "object", id = "musicbox" },
	{ name = "Tripmine", type = "object", id = "tripmine" },
	{ name = "Cannon", type = "object", id = "cannon" },
	{ name = "Popper", type = "object", id = "popper" },
	{ name = "Boss: Clone", type = "boss", id = "clone" },
	{ name = "Back", type = "back" },
}

local menuFont

local function close()
	Dev.open = false
	Dev.screen = "main"
	Dev.selected = 1
end

local function spawnSelected()
	local option = spawnOptions[Dev.selected]
	if option.type == "back" then
		Dev.screen = "main"
		Dev.selected = 2
	elseif option.type == "object" then
		local object = require("objects")
		table.insert(objects, object:new(533, 0, option.id))
	elseif option.type == "boss" then
		local boss = require("bosses")
		table.insert(bosses, boss:new(533, 0, option.id))
	end
end

local function upgradeOptions()
	local options = {}
	local activeUpgradeGroups = {}

	if RoundData and RoundData.upgradesActive then
		for _, id in ipairs(RoundData.upgradesActive) do
			activeUpgradeGroups[id:gsub("%d+$", "")] = true
		end
	end

	if player and RoundData and RoundData.upgradesActive and UpgradeOptions then
		for _, upgrade in ipairs(UpgradeOptions) do
			local group = upgrade.id:gsub("%d+$", "")
			if not activeUpgradeGroups[group] then
				local tier = upgrade.id:match("%d+$") and "II" or "I"
				table.insert(options, {
					name = upgrade.title .. " (" .. tier .. ")",
					type = "upgrade",
					id = upgrade.id,
				})
			end
		end
	end

	if #options == 0 then
		local message = player and RoundData and RoundData.upgradesActive
			and "All upgrades obtained" or "Player unavailable"
		table.insert(options, { name = message, type = "info" })
	end
	table.insert(options, { name = "Back", type = "back" })
	return options
end

local function selectUpgradeOption()
	local option = upgradeOptions()[Dev.selected]
	if option.type == "back" then
		Dev.screen = "main"
		Dev.selected = 3
	elseif option.type == "upgrade" then
		table.insert(RoundData.upgradesActive, option.id)
	end
end

local function selectMainOption()
	if Dev.selected == 1 then
		close()
	elseif Dev.selected == 2 then
		Dev.screen = "spawn"
		Dev.selected = 1
	elseif Dev.selected == 3 then
		Dev.screen = "upgrades"
		Dev.selected = 1
	elseif Dev.selected == 4 then
		Dev.screen = "camera"
		Dev.selected = 1
	elseif Dev.selected == 5 then
		FPSCountToggle = not FPSCountToggle
	elseif Dev.selected == 6 then
		if player then
			player.hp = math.min(player.maxHP, player.hp + 1)
		end
	elseif Dev.selected == 7 then
		if RoundData then
			RoundData.time = RoundData.time + 30
		end
	end
end

local function currentOptions()
	if Dev.screen == "spawn" then
		return spawnOptions
	elseif Dev.screen == "upgrades" then
		return upgradeOptions()
	elseif Dev.screen == "camera" then
		return {}
	end
	return mainOptions
end

local function returnToMain(selected)
	Dev.screen = "main"
	Dev.selected = selected
end

local function handleCameraKey(key)
	if key == "escape" then
		returnToMain(4)
	elseif key == "up" or key == "w" then
		cam:move(0, -30)
	elseif key == "down" or key == "s" then
		cam:move(0, 30)
	elseif key == "left" or key == "a" then
		cam:move(-30, 0)
	elseif key == "right" or key == "d" then
		cam:move(30, 0)
	elseif key == "-" or key == "kp-" then
		Dev.cameraZoomMultiplier = math.max(0.25, Dev.cameraZoomMultiplier - 0.1)
	elseif key == "=" or key == "+" or key == "kp+" then
		Dev.cameraZoomMultiplier = math.min(2, Dev.cameraZoomMultiplier + 0.1)
	elseif key == "r" then
		cam:lookAt(533, 300)
		Dev.cameraZoomMultiplier = 1
	end
end

function Dev.keypressed(key)
	if key == "grave" or key == "`" then
		Dev.open = not Dev.open
		if Dev.open then
			Dev.screen = "main"
			Dev.selected = 1
		end
		return true
	end

	if not Dev.open then
		return false
	end

	if Dev.screen == "camera" then
		handleCameraKey(key)
		return true
	end

	if key == "escape" then
		if Dev.screen == "spawn" then
			returnToMain(2)
		elseif Dev.screen == "upgrades" then
			returnToMain(3)
		else
			close()
		end
	elseif key == "up" or key == "w" then
		Dev.selected = (Dev.selected - 2) % #currentOptions() + 1
	elseif key == "down" or key == "s" then
		Dev.selected = Dev.selected % #currentOptions() + 1
	elseif key == "return" or key == "z" then
		if Dev.screen == "spawn" then
			spawnSelected()
		elseif Dev.screen == "upgrades" then
			selectUpgradeOption()
		else
			selectMainOption()
		end
	end

	return true
end

function Dev.draw()
	if not Dev.open then
		return
	end

	local virtualWidth = gameWidth or 1066
	local virtualHeight = gameHeight or 600
	local scale = math.min(
		love.graphics.getWidth() / virtualWidth,
		love.graphics.getHeight() / virtualHeight
	)
	local offsetX = (love.graphics.getWidth() - virtualWidth * scale) / 2
	local offsetY = (love.graphics.getHeight() - virtualHeight * scale) / 2
	local options = currentOptions()
	local width = 370
	local isSubmenu = Dev.screen ~= "main"
	local height = Dev.screen == "camera" and 260 or (isSubmenu and (132 + #options * 26) or 356)
	local x, y = 24, 24
	local playerHP = player and player.hp or 0
	local playerMaxHP = player and player.maxHP or 0
	local level = RoundData and RoundData.level or 0
	local time = RoundData and RoundData.time or 0
	if not menuFont then
		menuFont = love.graphics.newFont(16)
	end

	love.graphics.push("all")
	love.graphics.translate(offsetX, offsetY)
	love.graphics.scale(scale, scale)
	love.graphics.setColor(0, 0, 0, 0.88)
	love.graphics.rectangle("fill", x, y, width, height)
	love.graphics.setColor(1, 1, 0)
	love.graphics.setLineWidth(2)
	love.graphics.rectangle("line", x, y, width, height)

	love.graphics.setFont(menuFont)
	love.graphics.setColor(1, 1, 0, 1)
	local title = Dev.screen == "spawn" and "SPAWN"
		or (Dev.screen == "upgrades" and "GIVE UPGRADES"
			or (Dev.screen == "camera" and "CAMERA CONTROLS" or "debugger and tester"))
	love.graphics.print(title, x + 18, y + 14)

	local firstOptionY
	if Dev.screen == "camera" then
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.print(("Position: %.0f, %.0f"):format(cam.x, cam.y), x + 18, y + 58)
		love.graphics.print(("Zoom: %.2fx"):format(cam.scale), x + 18, y + 82)
		love.graphics.print("Arrow keys / W A S D: move camera", x + 18, y + 122)
		love.graphics.print("-: zoom out    +: zoom in", x + 18, y + 148)
		love.graphics.print("R: reset position and zoom", x + 18, y + 174)
	elseif isSubmenu then
		firstOptionY = y + 54
	else
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.print(("Level: %d    Time: %.1f"):format(level, time), x + 18, y + 48)
		love.graphics.print(("Player HP: %d/%d"):format(playerHP, playerMaxHP), x + 18, y + 72)
		love.graphics.print(("FPS: %d"):format(love.timer.getFPS()), x + 18, y + 96)
		firstOptionY = y + 140
	end

	for index, option in ipairs(options) do
		local optionY = firstOptionY + (index - 1) * 26
		local label = type(option) == "table" and option.name or option
		if index == Dev.selected then
			love.graphics.setColor(1, 1, 0, 1)
			love.graphics.print("> " .. label, x + 18, optionY)
		else
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.print("  " .. label, x + 18, optionY)
		end
	end

	love.graphics.setColor(0.75, 0.75, 0.75, 1)
	local controls = Dev.screen == "camera" and "Esc: back to menu"
		or (Dev.screen == "spawn" and "W/S: move  Enter: spawn  Esc: back"
		or (Dev.screen == "upgrades" and "W/S: move  Enter: give  Esc: back"
			or "W/S: move  Enter: select  `: close"))
	love.graphics.print(controls, x + 18, y + height - 27)
	love.graphics.pop()
end

local previousKeypressed = love.keypressed
love.keypressed = function(key, ...)
	if Dev.keypressed(key) then
		return
	end
	if previousKeypressed then
		return previousKeypressed(key, ...)
	end
end

local previousDraw = love.draw
love.draw = function(...)
	if previousDraw then
		previousDraw(...)
	end
	Dev.draw()
end

return Dev