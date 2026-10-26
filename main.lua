-- StayPut 2. A passion project made to learn Lua and LÖVE2D.
-- Originating from a game made in TurboWarp/Scratch. This is a remake of the original game in Lua using the LÖVE2D framework.

if os.getenv("LOVE2D_TOOLS") then
	pcall(require, "_love2d_tools_bridge")
end

local Player = require("baller")
local object = require("objects")
local Musichandler = require("musichandler")
local lastEnemy = nil

local discordrefreshTimer = 0

local gameoverOptions = {
	[1] = "RESTART EXPERIMENT",
	[2] = "STOP PROGRAM",
	[3] = "VIEW INFORMATION"
}
local gameoverSelected = 0
local gameoverTimeAt = nil
local greenFlashAlpha = 0

local quitCount = 0
local quitCountTimer = 3
local function removenum(id)
	return id:gsub("%d", "")
end

local function tableContains(table, val)
	for _, value in ipairs(table) do
		if value == val then
			return true
		end
	end
	return false
end

local clickimg = love.graphics.newImage("sprites/skullparti.png")
local clickParticleSystem = love.graphics.newParticleSystem(clickimg)
clickParticleSystem:setSpinVariation(1)
clickParticleSystem:setParticleLifetime(1.5,2)
clickParticleSystem:setEmissionArea("normal",0,0)
clickParticleSystem:setSpread(math.pi * 2)
clickParticleSystem:setSpeed(75,125)
clickParticleSystem:setColors(1,1,1,0,1,1,1,0.5,1,1,1,0)
clickParticleSystem:setSizes(0.06)
clickParticleSystem:setLinearAcceleration(0,300)
keybind_WIP_timer = 0
keybind_toBeEdited = nil
editingMasterVolume = false

local clickfx = love.graphics.newCanvas(240,200)
clickfx:renderTo(function ()
	love.graphics.rectangle("fill",0,0,240,200)
end)
local clickfxSquareSystem = love.graphics.newParticleSystem(clickfx)
clickfxSquareSystem:setSizes(1,0)
clickfxSquareSystem:setParticleLifetime(0.4)
clickfxSquareSystem:setSpeed(0)
clickfxSquareSystem:setColors(1,0,0,1,1,0,0,0)

RoundData = {

	ongoing = true,

	level = 0,
	time = 1,
	starttime = 20,

	difficultyTBO = 3,
	spawnTimer = 3,

	enemyPicker = false,
	upgradePicker = false,
	enemiesActive = {},
	upgradesActive = {},
}

AchievementData = {
	surviveTime = 0,
	damageTaken = 0,
	chipDamageTaken = 0,
}

EnemyOptions = {
	{
		id = "square",
		title = "Box",
		desc = "A heavy box. Appears in random sizes, Falls to get in your way.",
		cd = -RoundData.difficultyTBO / 3,
		lvl = 0
	},
	{ 
		id = "follower",
		title = "Follower",
		desc = "Follows and pushes the player.",
		cd = 0,
		lvl = 0
	},
	{
		id = "bomb",
		title = "Bomb",
		desc = "Weak object, explodes with projectiles in all directions.",
		cd = RoundData.difficultyTBO * 0.15,
		lvl = 0
	},
	{
		id = "zip",
		title = "Zip",
		desc = "A quick and strong object that dashes toward the player multiple times.",
		cd = RoundData.difficultyTBO * 0.35,
		lvl = 5
	},
	{
		id = "tripwire",
		title = "Stopwire",
		desc = "A weak and light object that watches your movement, sit still for a moment to avoid getting hurt.",
		cd = -RoundData.difficultyTBO / 3,
		lvl = 5
	},
	{
		id = "musicbox",
		title = "Music Box",
		desc = "A familiar object that slows down the player as they come near.",
		cd = RoundData.difficultyTBO * 0.1,
		lvl = 5
	},
	{
		id = "tripmine",
		title = "Tripmine",
		desc = "Touching this small and light object will deal 75 chip damage. The corners are safe.",
		cd = 0,
		lvl = 0
	},
	{
		id = "cannon",
		title = "Cannon",
		desc = "A floating weapon that fires strong projectiles at the player.",
		cd = RoundData.difficultyTBO * 0.5,
		lvl = 5
	},
	{
		id = "popper",
		title = "Popper",
		desc = "Releases dangerous mid-ranged confetti toward the player.",
		cd = RoundData.difficultyTBO * 0.5,
		lvl = 5,
	}
}

UpgradeOptions = {
	{
		id = "DoubleJump",
		title = "Double Jump",
		desc = "Grants an extra jump.",
	},
	{
		id = "DoubleJump2",
		title = "Double Jump",
		desc = "Grants an extra jump.",
	},
	{
		id = "DensityUp",
		title = "Density Up",
		desc = "+0.5x Density\n\nMakes you heavier, making you more resilliant to knockback.",
	},
	{
		id = "DensityUp2",
		title = "Density Up",
		desc = "+0.5x Density\n\nMakes you heavier, making you more resilliant to knockback.",
	},
	{
		id = "DashCDDown",
		title = "Dash CD Down",
		desc = "-0.55s Dash Cooldown\n\nReduces the cooldown of your dash.",
	},
	{
		id = "DashCDDown2",
		title = "Dash CD Down",
		desc = "-0.55s Dash Cooldown\n\nReduces the cooldown of your dash.",
	}
}
-- starter enemies possibly
OffensiveEnemies = {
	{ id = "follower" },
	{ id = "bomb" },
	{ id = "tripmine" },
}

local ChoiceButtons = {
	{ x = 115, y = 100, width = 240, height = 200, id = "", title = "", desc = "" },
	{ x = 413, y = 100, width = 240, height = 200, id = "", title = "", desc = "" },
	{ x = 711, y = 100, width = 240, height = 200, id = "", title = "", desc = "" },
}

local UpgradeChoiceButtons = {
	{ x = 115, y = 100, width = 240, height = 200, id = "", title = "", desc = "" },
	{ x = 413, y = 100, width = 240, height = 200, id = "", title = "", desc = "" },
	{ x = 711, y = 100, width = 240, height = 200, id = "", title = "", desc = "" },
}

local function refreshChoiceButtons()
	local pool = {}
	for i, option in ipairs(EnemyOptions) do
		local invalid = false

		for _, activeId in ipairs(RoundData.enemiesActive) do
			if option.id == activeId then
				invalid = true
			end
		end
		if option.lvl > RoundData.level then
			invalid = true
		end

		if not invalid then
			table.insert(pool, option)
		end
	end

	if #pool == 0 then
		RoundData.enemyPicker = false
		RoundData.ongoing = true
		return
	end

	for i = 1, 3 do
		if #pool > 0 then
			local randomIndex = love.math.random(1, #pool)
			local chosenEnemy = table.remove(pool, randomIndex)

			ChoiceButtons[i].id = chosenEnemy.id
			ChoiceButtons[i].title = chosenEnemy.title
			ChoiceButtons[i].desc = chosenEnemy.desc
		else
			ChoiceButtons[i].id = nil
			ChoiceButtons[i].title = "No Option"
			ChoiceButtons[i].desc = "All out of obstacle choices."
		end
	end
end

local function refreshUpgradeChoiceButtons()
	local pool = {}

	for i, option in ipairs(UpgradeOptions) do
		local alreadyingame = false

		for _, activeId in ipairs(RoundData.upgradesActive) do
			if option.id == activeId then
				alreadyingame = true
			end
		end

		if not alreadyingame then
			table.insert(pool, option)
		end
	end

	if #pool == 0 then
		RoundData.upgradePicker = false
		RoundData.ongoing = true
	end

	for i = 1, 3 do
		if #pool > 0 then
			local randomIndex = love.math.random(1, #pool)
			local chosenUpgrade = table.remove(pool, randomIndex)
			local backupi = i
			for i = #pool, 1, -1 do
			    local item = pool[i]
				local id = removenum(chosenUpgrade.id)
			    if item.id:match(id) then
			        table.remove(pool, i)
			    end
			end
			i = backupi
			UpgradeChoiceButtons[i].id = chosenUpgrade.id
			UpgradeChoiceButtons[i].title = chosenUpgrade.title
			UpgradeChoiceButtons[i].desc = chosenUpgrade.desc
		else
			UpgradeChoiceButtons[i].id = nil
			UpgradeChoiceButtons[i].title = "No Option"
			UpgradeChoiceButtons[i].desc = "All out of upgrade choices."
		end
	end
end

objects = {}

local spawnHold = {} --                                         -----------------------  Dev utility to spawn stuff
local spawnHoldDelay = 0.75 --
local spawnHoldRepeatInterval = 0.01 --
local spawnKeyConfig = { --
	["1"] = "square",
	["2"] = "follower",
	["3"] = "bomb",
	["4"] = "tripwire",
	["5"] = "zip",
	["6"] = "musicbox",
	["7"] = "tripmine",
	["8"] = "cannon",
	["9"] = "popper",
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
		setDiscordPresence("Playing StayPut, " .. player.hp .. " Hits left, on level " .. RoundData.level)
	else
		setDiscordPresence("Paused", "Taking a break")
	end
end

function love.load()
	love.graphics.setDefaultFilter("linear", "linear")

	love.physics.setMeter(64)
	world = love.physics.newWorld(0, 15 * 64, true)

	Keybinds = {
		["Jump"] = "space",
		["Left"] = "a",
		["Right"] = "d",
		["Down"] = "s",
		["Dash"] = "lshift",
	}

	local floorWidth = 700
	local floorHeight = 400

	local floorTopY = 490
	local floorCenterY = floorTopY + (floorHeight / 2)

	Camera = require("camera")
	cam = Camera(533, 300)
	camZoom = 1
	camZoom2 = 1

	FPSCountToggle = false
	FPSCount = love.timer.getFPS()

	floorBody = love.physics.newBody(world, 533, floorCenterY, "static")
	floorShape = love.physics.newRectangleShape(floorWidth, floorHeight)
	floorFixture = love.physics.newFixture(floorBody, floorShape)
	floorFixture:setFriction(1)
	floorFixture:setFriction(1)

	GAMEOVER = false
	gameoverInfoShown = false

	errorSound = love.audio.newSource("sounds/sfx/error.mp3", "static")
	movemenuSound = love.audio.newSource("sounds/sfx/move.mp3", "static")
	movemenuSound:setVolume(0.4)
	IntroSound = love.audio.newSource("sounds/sfx/move.mp3", "static")
	IntroSound2 = love.audio.newSource("sounds/sfx/select.mp3", "static")
	selectSound = love.audio.newSource("sounds/sfx/select.mp3", "static")
	selectSound:setVolume(0.8)
	equipSound = love.audio.newSource("sounds/sfx/equip.mp3", "static")
	sfx_crit = love.audio.newSource("sounds/sfx/crit.mp3", "static")
	selectbadSound = love.audio.newSource("sounds/sfx/selectbad.mp3","static")
	selectbadSound:setVolume(0.75)

	barRecoverSound = love.audio.newSource("sounds/sfx/barheal.mp3", "static")
	barRecoverSound:setPitch(1.3)
	barRecoverSound:setVolume(0.65)

	menuVisible = true
	gameRunning = false
	gameStarted = false
	settingsVisible = false
	IntroPlaying = false
	IntroFrame = 1
	IntroFrameDelay = 0.5
	IntroPlayedBefore = false
	Fullscreen = false
	MasterVolume = 1

	IntroFrames = {
		love.graphics.newImage("sprites/mspawn/mspawn1.png"),
		love.graphics.newImage("sprites/mspawn/mspawn2.png"),
		love.graphics.newImage("sprites/mspawn/mspawn3.png"),
		love.graphics.newImage("sprites/mspawn/mspawn4.png"),
		love.graphics.newImage("sprites/mspawn/mspawn4.png"),
	}

	indicator = love.graphics.newImage("sprites/mint/indicator.png")
	indicatorU = love.graphics.newImage("sprites/mint/indicatorUP.png")
	indicatorD = love.graphics.newImage("sprites/mint/indicatorDOWN.png")

	player = Player.new(world, 533, 200)

	discordPresenceStart = os.time()
	if discordRPC.available and discordAppId and discordAppId ~= "" then
		discordRPC.initialize(discordAppId, true, nil)
		discordEnabled = true
	else
		print("Discord Rich Presence unavailable:", discordRPC.status)
	end
	updateDiscordPresence()

	love.graphics.setDefaultFilter("nearest", "nearest")
	settingsFont = love.graphics.newFont("fonts/tiny5.ttf", 35)
	timerFont = love.graphics.newFont("fonts/tiny5.ttf", 48)
	tobyfont = love.graphics.newFont("fonts/toby.otf", 32)
	toby2font = love.graphics.newFont("fonts/toby.otf", 16)
	smalltobyfont = love.graphics.newFont("fonts/toby.otf", 24)
	consolefont = love.graphics.newFont("fonts/console.ttf",24)

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

	gameWidth = 1066
	gameHeight = 600

	canvas = love.graphics.newCanvas(160, 90)
	canvas:setFilter("linear", "linear")

	menu = Menu.new()

	randomStartingCard()

	--gameCanvas = love.graphics.newCanvas(gameWidth, gameHeight)
	--gameCanvas:setFilter("nearest", "nearest")
end

local backgroundElements = {}
local function createBgElement(type,x,y,dx,dy,lifetime)

	local e = {
		type = type,
		x = x or 0,
		y = y or 0,
		dx = dx or 0,
		dy = dy or 0,
		lifetime = lifetime,
	}
	table.insert(backgroundElements,e)
end

local function drawBG(screenWidth, screenHeight)
	local t = love.timer.getTime()

	canvas:renderTo(function()
		if RoundData.level == 0 or not RoundData.ongoing then
			love.graphics.clear(0, 0, 0)

			love.graphics.setColor(0.2, 0.2, 0.2, 0.5)

			local amount = 4
			local h = 90 / amount
			local xvar = 0
			for i = 1, amount do
				local y = (i - 1) * h
				love.graphics.rectangle("line", 20 + xvar / i, y, h, h)
			end
		else
			love.graphics.clear(0.04, 0.02, 0.08)

			love.graphics.setColor(0.1, 0.04, 0.22, 0.5)

			local amount = 2
			local h = 90 / amount
			local xvar = math.cos(t * 2) * 5
			for i = 1, amount do
				local y = (i - 1) * h
				love.graphics.rectangle("line", 20 + xvar / i, y, h, h)
			end

			for _, element in ipairs(backgroundElements) do
				if element.type == "dot" then
					love.graphics.setBlendMode("alpha")
					love.graphics.setColor(0.349, 0, 1, 0.014)
					love.graphics.circle("fill",element.x,element.y,8)
					love.graphics.setBlendMode("alpha")
				end
			end
		end
	end)

	local halfW = screenWidth / 2
	local halfH = screenHeight / 2

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(canvas, 0, 0, 0, halfW / 160, halfH / 90)
	love.graphics.draw(canvas, screenWidth, 0, 0, -halfW / 160, halfH / 90)
	love.graphics.draw(canvas, 0, screenHeight, 0, halfW / 160, -halfH / 90)
	love.graphics.draw(canvas, screenWidth, screenHeight, 0, -halfW / 160, -halfH / 90)
end

local particleSpawnTimer = 0.1
local function updateBG(dt)
	for i = #backgroundElements, 1, -1 do
		local element = backgroundElements[i]

		if element.lifetime > 0 then
			element.lifetime = element.lifetime - dt
		end
		if element.lifetime <= 0 then
			table.remove(backgroundElements,i)
		else

			element.x = element.x + element.dx*dt
			element.y = element.y + element.dy*dt

		end
	end

	if particleSpawnTimer <= 0 then
	for i = 1, 4 do
		local dir,spread

		if RoundData.level < 10 then
			dir,spread = math.rad(225),math.rad(math.cosh(love.timer.getTime()*1)*115)
		elseif RoundData.level < 20 then
			dir,spread = math.rad(225),math.rad(math.cos(love.timer.getTime()*1)*115)
		else
			dir,spread = math.rad(225),math.rad(math.tan(love.timer.getTime()*1)*115)
		end

		local angle = dir + (i - 2.5) * (spread / 4)
		local dx = math.cos(angle) * (40)
		local dy = math.sin(angle) * (40)
		createBgElement("dot",160,90,dx,dy,8)
		particleSpawnTimer = 0.001
	end
	else
		particleSpawnTimer = particleSpawnTimer - dt
	end
end

function love.update(dt) --                                                                                               ----  v v v  | main game loop |  v v v  ----
	if discordEnabled then
		discordRPC.runCallbacks()
		passivediscordupdate(dt)
	end
	FPSCount = love.timer.getFPS()

	menu.quitCount = quitCount

	greenFlashAlpha = greenFlashAlpha - (0.4 * dt)

	if quitCount > 0 then
		quitCountTimer = quitCountTimer - dt
	end
	if quitCountTimer <= 0 then
		quitCountTimer = 3
		quitCount = 0
	end

	if gameRunning then
		updateBG(dt)
		clickParticleSystem:update(dt)
		clickfxSquareSystem:update(dt)
	end

	love.audio.setVolume(MasterVolume)

	for key, objType in pairs(spawnKeyConfig) do --------------------------------------------  place holder dev key
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

	Musichandler.update(dt)
	
	if gameRunning then
		if not IntroPlaying or IntroPlayedBefore then
			IntroPlaying = false

			for i = #objects, 1, -1 do -- update objects
				local obj = objects[i]
				obj:update(dt)
				if obj.lifetime <= 0 and (not obj.timeafterdead or obj.timeafterdead <= 0) then
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

			updateCamera()

			local moveForce = 500
			for _, obj in ipairs(objects) do
				if obj.obj == "musicbox" and obj.newBody then
					local px, py = player.body:getPosition()
					local bx, by = obj.newBody:getPosition()

					local dx = px - bx
					local dy = py - by
					local dist = math.sqrt(dx * dx + dy * dy)

					if dist <= obj.range then
						moveForce = math.max(0, moveForce - obj.slowAmount)
						break
					end
				end
			end

			if GAMEOVER then
				RoundData.enemyPicker = false
				RoundData.upgradePicker = false
				RoundData.ongoing = true
				Musichandler:reset()
				if gameoverTimeAt == nil then
					gameoverTimeAt = love.timer.getTime()
					sfx_crit:clone():play()
				end
			end

			if not GAMEOVER then -- update all
				world:update(dt)
				player:update(dt)
				player:control(
					Keybinds["Jump"],
					Keybinds["Down"],
					Keybinds["Left"],
					Keybinds["Right"],
					Keybinds["Dash"],
					moveForce
				)
				player:OffStageRespawn()
			end

			if RoundData.ongoing and not GAMEOVER then -- round stuff including timer, spawning objs, etc
				RoundData.time = RoundData.time - dt
				RoundData.spawnTimer = RoundData.spawnTimer - dt
				if player.hp > 0 then
					AchievementData.surviveTime = AchievementData.surviveTime + dt
				end

				if RoundData.spawnTimer <= 0 then -- spawn now
					if #RoundData.enemiesActive > 0 then
						local random = love.math.random(1, #RoundData.enemiesActive)
						local enemyIdToSpawn = RoundData.enemiesActive[random]
						local tripwireExists = false

						if enemyIdToSpawn == "tripwire" then -- anti stopwire
							if objects and #objects > 0 then
								for _, obj in ipairs(objects) do
									if obj.obj == "tripwire" then
										tripwireExists = true
									end
								end
							end
						end

						if tripwireExists then -- anti stopwire
							repeat
								random = love.math.random(1, #RoundData.enemiesActive)
								enemyIdToSpawn = RoundData.enemiesActive[random]
							until enemyIdToSpawn ~= "tripwire"
						end

						if--make sure annoying enemies don't spawn twice in a row, if there are other enemies to spawn
							lastEnemy ~= nil
							and lastEnemy == "tripwire"
							and enemyIdToSpawn == "tripwire"
							and #RoundData.enemiesActive > 1
						then
							repeat
								random = love.math.random(1, #RoundData.enemiesActive)
								enemyIdToSpawn = RoundData.enemiesActive[random]
							until enemyIdToSpawn ~= "tripwire"
						end

						if--make sure annoying enemies don't spawn twice in a row, if there are other enemies to spawn
							lastEnemy ~= nil
							and lastEnemy == "musicbox"
							and enemyIdToSpawn == "musicbox"
							and #RoundData.enemiesActive > 1
						then
							repeat
								random = love.math.random(1, #RoundData.enemiesActive)
								enemyIdToSpawn = RoundData.enemiesActive[random]
							until enemyIdToSpawn ~= "musicbox"
						end

						lastEnemy = enemyIdToSpawn

						local spawnX = love.math.random(200, 866)

						local enemyCD = 0
						for _, option in ipairs(EnemyOptions) do -- get enemy's added spawn cd and add it to the TBO timer
							if option.id == enemyIdToSpawn then
								enemyCD = option.cd or 0
							end
						end

						local newEnemy = object:new(spawnX, -100, enemyIdToSpawn)
						table.insert(objects, newEnemy)
						RoundData.spawnTimer = RoundData.difficultyTBO + enemyCD
					end
				end
			end

			if RoundData.time <= 0 then -- round end
				RoundData.ongoing = false

				clearAllObjects()
				greenFlashAlpha = 0.5

				RoundData.level = RoundData.level + 1
				RoundData.starttime = RoundData.starttime + 3
				RoundData.time = RoundData.starttime
				RoundData.difficultyTBO = RoundData.difficultyTBO - 0.2
				updateDiscordPresence()

				if RoundData.level % 10 == 0 and RoundData.level ~= 0 then
					RoundData.upgradePicker = true
					refreshUpgradeChoiceButtons()
				elseif RoundData.level % 2 == 0 or RoundData.level == 1 then
					RoundData.enemyPicker = true
					refreshChoiceButtons()
				else
					RoundData.ongoing = true
				end

				player:QueueHeal(2, 4, 50)
				if player.hpBar < 100 then
					barRecoverSound:play()
				end
			end
		else -- if intro hasnt been played before then
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
		end -- intro check end
	end
	menu:update()
end

function love.quit()
	if discordEnabled then
		discordRPC.clearPresence()
		discordRPC.shutdown()
	end
	return false
end

function love.draw() --                                                                                        ----  v v v  | all drawing |  v v v  ----
	-------------

	love.graphics.clear(0, 0, 0)

	local windowWidth = love.graphics.getWidth()
	local windowHeight = love.graphics.getHeight()
	local scale = math.min(windowWidth / gameWidth, windowHeight / gameHeight)
	local offsetX = (windowWidth - (gameWidth * scale)) / 2
	local offsetY = (windowHeight - (gameHeight * scale)) / 2

	if gameStarted and not GAMEOVER then
		drawBG(windowWidth, windowHeight)
	end

	love.graphics.push()
	love.graphics.translate(math.floor(offsetX), math.floor(offsetY))
	love.graphics.scale(scale, scale)

	if FPSCountToggle then
		love.graphics.setFont(smalltobyfont)
		love.graphics.setColor(1, 1, 1, 0.5)
		love.graphics.print(FPSCount, 10, 565)
	end

	if gameStarted and not GAMEOVER then
		drawGame()
	end

	if GAMEOVER and gameoverTimeAt then
		drawGAMEOVER()
	end

	if gameStarted and not GAMEOVER then
		local ww = gameWidth
		local wh = gameHeight
		love.graphics.setFont(timerFont)
		love.graphics.setColor(1, 1, 1, 1)
		if not RoundData.enemyPicker then
			love.graphics.printf(string.format("%.1f", RoundData.time), 0, 40, ww, "center")
		end
		love.graphics.setFont(smalltobyfont)
		love.graphics.printf(RoundData.level, 0, 10, ww, "center")
	end

	if RoundData.enemyPicker and gameStarted and not IntroPlaying and not GAMEOVER then -------------------- drawing choice buttons
		drawChoiceButtons()
	end

	if RoundData.upgradePicker and gameStarted and not IntroPlaying and not GAMEOVER then -------------------- drawing upgrade choice buttons
		drawUpgradeChoiceButtons()
	end

	if not GAMEOVER and gameStarted then
		drawPlayerUI()
	end

	if gameStarted and not GAMEOVER and RoundData.level > 1 then
		love.graphics.setBlendMode("multiply","premultiplied")
		love.graphics.setColor(1-(greenFlashAlpha*2),1,1-(greenFlashAlpha*1.8),1)
		love.graphics.rectangle("fill",0,0,gameWidth,gameHeight)
		love.graphics.setBlendMode("alpha","alphamultiply")
		love.graphics.setColor(0,1,0,greenFlashAlpha/5)
		love.graphics.rectangle("fill",0,0,gameWidth,gameHeight)
	end

	if menuVisible then --------------- drawing menu
		menu:draw()
	end

	-------------------
	love.graphics.pop()
end

function drawGame()
	cam:attach(0, 0, gameWidth, gameHeight, true)

	drawFloor()

	for _, obj in ipairs(objects) do -- drawing objects
		obj:draw()
	end

	for _, proj in ipairs(projectiles) do -- drawing projectiles
		proj:draw()
	end

	love.graphics.setColor(1,1,1,1)
	love.graphics.draw(clickfxSquareSystem)
	love.graphics.draw(clickParticleSystem)

	player:draw() -- drawing one player

	cam:detach() --------------

	drawIndicator()
end

-- handle keyboard input for menu and dev controls
function love.keypressed(key)
	if key == "f1" then
		for i, item in pairs(RoundData.enemiesActive) do
			print(i, item)
		end
	end

	if key == "f4" then -- clear console
		print(string.rep("\n", 100))
	end

	local currentscreen = menu.currentScreen
	if (keybind_WIP_timer <= 0) and (not editingMasterVolume) then
		if key == "escape" and not IntroPlaying and not GAMEOVER then
			if currentscreen == "settings" then
				menuVisible = true
				menu:setScreen("menu")
			else
				if gameStarted then
					if menuVisible then
						menuVisible = false
						gameRunning = true
					else
						menuVisible = true
						gameRunning = false
					end
				end
			end
			updateDiscordPresence()
			return
		end

		if key == "backspace" then
			RoundData.time = 0
		end

		if key == "f11" then
			Fullscreen = not Fullscreen
			love.window.setFullscreen(Fullscreen)
			equipSound:clone():play()
		end

		if menuVisible then
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

		if menuVisible and (key == "return" or key == "z") then -- lovely code
			local selectedItem = menu.selectedIndex
			local currentscreen = menu.currentScreen
			selectSound:clone():play()
			if currentscreen == "menu" and selectedItem == 1 then
				menuVisible = false
				gameRunning = true
				gameStarted = true
				settingsVisible = false
				IntroPlaying = true
				IntroFrame = 1

				updateDiscordPresence()
			end
			if currentscreen == "menu" and selectedItem == 2 then
				menu:setScreen("settings")
				menuVisible = true
				settingsVisible = true
			end

			if currentscreen == "menu" and selectedItem == 3 then
				menu:setScreen("oldstayputs")
				menuVisible = true
			end

			if currentscreen == "oldstayputs" and selectedItem == 1 then
				menu:setScreen("menu")
				menuVisible = true
			end

			if currentscreen == "oldstayputs" and selectedItem == 2 then
				love.system.openURL("https://codetorch.net/en/projects/117367")
			end

			if currentscreen == "oldstayputs" and selectedItem == 3 then
				love.system.openURL("https://stayput.my.canva.site/")
			end

			if currentscreen == "menu" and selectedItem == 4 then
				if gameStarted then
					if quitCount >= 3 then
						love.event.quit()
					else
						quitCount = quitCount + 1
					end
				else
					love.event.quit()
				end
			end

			if currentscreen == "settings" and selectedItem == 1 then
				menuVisible = true
				menu:setScreen("menu")
			end

			if currentscreen == "settings" and selectedItem == 2 then
				Fullscreen = not Fullscreen
				love.window.setFullscreen(Fullscreen)
				equipSound:clone():play()
			end

			if currentscreen == "settings" and selectedItem == 3 then
				menuVisible = true
				menu:setScreen("keybinds")
			end

			if currentscreen == "settings" and selectedItem == 4 then
				menuVisible = true
				menu:setScreen("audiosettings")
			end

			if currentscreen == "settings" and selectedItem == 5 then
				FPSCountToggle = not FPSCountToggle
				equipSound:clone():play()
			end

			if currentscreen == "keybinds" and selectedItem == 1 then
				menuVisible = true
				menu:setScreen("settings")
			end

			if currentscreen == "audiosettings" and selectedItem == 1 then
				menuVisible = true
				menu:setScreen("settings")
			end

			if currentscreen == "keybinds" and selectedItem == 2 then
				keybind_WIP_timer = 5
				keybind_toBeEdited = "Jump"
			end

			if currentscreen == "keybinds" and selectedItem == 2 then
				keybind_WIP_timer = 5
				keybind_toBeEdited = "Jump"
			end

			if currentscreen == "keybinds" and selectedItem == 3 then
				keybind_WIP_timer = 5
				keybind_toBeEdited = "Left"
			end

			if currentscreen == "keybinds" and selectedItem == 4 then
				keybind_WIP_timer = 5
				keybind_toBeEdited = "Right"
			end

			if currentscreen == "keybinds" and selectedItem == 5 then
				keybind_WIP_timer = 5
				keybind_toBeEdited = "Down"
			end

			if currentscreen == "keybinds" and selectedItem == 6 then
				keybind_WIP_timer = 5
				keybind_toBeEdited = "Dash"
			end

			if currentscreen == "audiosettings" and selectedItem == 2 then
				editingMasterVolume = true
			end
		end

		local elapsed
		if gameoverTimeAt == nil then
			elapsed = 0
		else
			elapsed = (love.timer.getTime() - gameoverTimeAt)
		end

		if GAMEOVER and (key == "w" or key == "up") and elapsed > 3 then
			if gameoverSelected == 0 then
				gameoverSelected = 1
			end
			gameoverSelected = gameoverSelected -1
			if gameoverSelected < 1 then gameoverSelected = #gameoverOptions end
		end

		if GAMEOVER and (key == "s" or key == "down") and elapsed > 3 then
			if gameoverSelected == 0 then
				gameoverSelected = 1
			end
			gameoverSelected = gameoverSelected +1
			if gameoverSelected > #gameoverOptions then gameoverSelected = 1 end
		end

		if GAMEOVER and (key == "z" or key == "return") then
			if gameoverSelected == 1 then
				resetGame()
			end

			if gameoverSelected == 2 then
				love.event.quit()
			end

			if gameoverSelected == 3 then
				gameoverInfoShown = true
				selectSound:clone():play()
			end
		end
		if key == "0" then --dev key
			player.hp = 0
		end
	else
		if keybind_WIP_timer > 0 then
			if key == "escape" then
				errorSound:clone():play()
				keybind_WIP_timer = 0
			else
				equipSound:clone():play()
				Keybinds[keybind_toBeEdited] = key
				keybind_WIP_timer = 0
			end
		end
		if editingMasterVolume then
			if key == "up" or key == "w" then
				movemenuSound:clone():play()
				MasterVolume = math.max(0,math.min(1,MasterVolume + (0.05)))
			elseif key == "down" or key == "s" then
				movemenuSound:clone():play()
				MasterVolume = math.max(0,math.min(1,MasterVolume - (0.05)))
			end
			if key == "z" or key == "return" then
				equipSound:clone():play()
				editingMasterVolume = false
				return
			end
		end
	end
end

function love.mousepressed(mx, my, button)
	local newx, newy = getVirtualMousePosition(mx, my)
	if RoundData.enemyPicker and button == 1 and not GAMEOVER then
		for i, btn in ipairs(ChoiceButtons) do
			if newx >= btn.x and newx <= btn.x + btn.width and newy >= btn.y and newy <= btn.y + btn.height and gameRunning then
				if btn.id ~= nil then
					table.insert(RoundData.enemiesActive, btn.id)
					RoundData.enemyPicker = false
					RoundData.ongoing = true
					clickParticleSystem:setPosition(newx,newy)
					clickParticleSystem:emit(7)
					clickfxSquareSystem:setPosition(btn.x+btn.width/2,btn.y+btn.height/2)
					clickfxSquareSystem:emit(1)
					selectbadSound:clone():play()
					break
				end
			end
		end
	end

	if RoundData.upgradePicker and button == 1 and not GAMEOVER then
		for i, btn in ipairs(UpgradeChoiceButtons) do
			if newx >= btn.x and newx <= btn.x + btn.width and newy >= btn.y and newy <= btn.y + btn.height and gameRunning then
				if btn.id ~= nil then
					table.insert(RoundData.upgradesActive, btn.id)
					RoundData.upgradePicker = false
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

function getVirtualMousePosition(mx, my)
	local windowWidth = love.graphics.getWidth()
	local windowHeight = love.graphics.getHeight()
	local scale = math.min(windowWidth / gameWidth, windowHeight / gameHeight)
	local offsetX = (windowWidth - (gameWidth * scale)) / 2
	local offsetY = (windowHeight - (gameHeight * scale)) / 2

	local vx = (mx - offsetX) / scale
	local vy = (my - offsetY) / scale
	return vx, vy
end

function clearAllObjects()
	for i = #objects, 1, -1 do
		local obj = objects[i]

		if obj.obj == "musicbox" and obj.sound then
			obj.sound:stop()
		end
		if obj.newBody and not obj.newBody:isDestroyed() then
			obj.newBody:destroy()
			obj.newBody = nil
			obj.lifetime = 0
		end
		table.remove(objects, i)
	end
end

function resetGame()
	if player then
		player:GG()
		player = nil
	end

	clearAllObjects()
	projectiles = {}

	RoundData = {
		ongoing = true,
		level = 0,
		time = 1,
		starttime = 20,
		difficultyTBO = 3,
		spawnTimer = 3,
		enemyPicker = false,
		upgradePicker = false,
		enemiesActive = {},
		upgradesActive = {},
	}

	menuVisible = false
	gameRunning = true
	gameStarted = true
	settingsVisible = false
	IntroPlaying = true
	IntroFrame = 1
	GAMEOVER = false
	gameoverInfoShown = false
	IntroPlayedBefore = false
	gameoverTimeAt = nil
	gameoverSelected = 0

	randomStartingCard()

	player = Player.new(world, 533, 200)
end

function randomStartingCard()
	local rand = love.math.random(1, #OffensiveEnemies)
	local tbi = OffensiveEnemies[rand].id
	if not tableContains(OffensiveEnemies, tbi) then
		table.insert(RoundData.enemiesActive, tbi)
	end
end

function updateCamera()
	local amountOfObjects = #objects
	camZoom = 1 - (math.min(amountOfObjects, 30) * 0.01)
	camZoom2 = camZoom2 + ((camZoom - camZoom2) / 24)
	cam:zoomTo(camZoom2)
end

function drawPlayerUI()
	local self = player
	local hpBar = self.hpBar or 100
	local hpBarMax = self.hpBarMax or 100
	local pct = math.max(0, math.min(1, hpBar / hpBarMax))
	local i_frame_pct = math.max(0, math.min(1, self.invulnTimer / 4))

	local barX, barY, barW, barH = 30, 55, 125, 8
	local fillW = math.max(0, pct * barW)

	local shakeTime = self.hurtShakeTime or 0
	local shakeAmount = self.hurtShakeAmount or 0
	local shake = shakeTime > 0 and math.min(1, shakeTime / 0.12) or 0
	local offsetX = ((math.random() * 2) - 1) * shakeAmount * shake
	local offsetY = ((math.random() * 2) - 1) * shakeAmount * shake

	love.graphics.push()
	love.graphics.translate(offsetX, offsetY)

	love.graphics.setLineWidth(3)
	love.graphics.setLineStyle("rough")

	love.graphics.setColor(0, 0, 0, 0.6)
	love.graphics.rectangle("fill", barX - 2, barY - 2, barW + 4, barH + 4)

	if self.invulnTimer and self.invulnTimer > 0 then
		love.graphics.setColor(0.855, 1, 0.851)
	else
		if self.hpBar < 30 then
			love.graphics.setColor(1, 0, 0, 1)
		else
			love.graphics.setColor(1, 1, 1, 1)
		end
	end
	love.graphics.rectangle("fill", barX, barY, fillW, barH)

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.rectangle("line", barX, barY, barW, barH)

	if self.invulnTimer > 0 then
		love.graphics.setColor(0, 0.718, 1)
		local currentW = barW * i_frame_pct
		-- Top line
		love.graphics.line(barX, barY, barX + currentW, barY)
		-- Bottom line
		love.graphics.line(barX, barY + barH, barX + currentW, barY + barH)
		-- Left tiny line
		love.graphics.line(barX, barY - 1.5, barX, barY + barH + 1.5)
	end

	local font = love.graphics.newFont("fonts/tiny5.ttf", 18)
	love.graphics.setDefaultFilter("linear")
	love.graphics.setFont(font)

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.print(tostring(math.floor(hpBar)) .. "%", barX - 2 + barW + 12, barY - 6)

	local font2 = love.graphics.newFont("fonts/tiny5.ttf", 32)
	love.graphics.setFont(font2)

	love.graphics.print("HP: " .. (self.hp or 0) .. "/" .. (self.maxHP or 4), 35, 10)

	-- -- -- -- Status Effects
	if next(player.statusEffects) ~= nil then
		local x,y = 10,200
		local width,height = 150,50
		
		for _, effect in ipairs(player.statusEffects) do
			love.graphics.setColor(0,0,0,0.5)
			love.graphics.rectangle("fill",x,y,width,height)

			love.graphics.setFont(font)
			love.graphics.setColor(1,1,1,0.75)
			love.graphics.printf(effect.name.." "..effect.level,x+10,y, width,"left")

			local dur = string.format("%.2f",effect.duration)
			love.graphics.setFont(font2)
			love.graphics.setColor(1,1,1,0.5)
			love.graphics.printf(dur,x+10,y+15,width,"left")
			y = y + 50
		end
	end

	if love.keyboard.isDown("tab") and next(RoundData.enemiesActive) ~= nil then
		local x,y,w,h = 533,300,600,400
		love.graphics.setColor(0,0,0,0.5)
		love.graphics.rectangle("fill",x - w/2, y - h/2, w,h)
		love.graphics.setColor(1,0,0,1)
		love.graphics.rectangle("line",x - w/2, y - h/2, w,h)
		for _, item in ipairs(RoundData.enemiesActive) do
			local id = item
			local title
			for _, item in ipairs(EnemyOptions) do
				if id == item.id then
					title = item.title
				end
			end
			love.graphics.setColor(1,1,1,1)
			love.graphics.printf(title,(x+15)-w/2,(y+20)-h/2,w,"left")

			y = y+35

			-- when adding more objects itll eventually go under the window, so make it go to the other side
		end
	end

	love.graphics.pop()
end

function drawFloor()
	local floorWidth = 700
	local floorHeight = 400

	local fx = floorBody:getX() - (floorWidth / 2)
	local fy = floorBody:getY() - (floorHeight / 2)

	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.rectangle("fill", fx, fy, floorWidth, floorHeight)

	love.graphics.setLineStyle("smooth")
	love.graphics.setLineWidth(2)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.rectangle("line", fx, fy, floorWidth, floorHeight)
end

function drawIndicator()
	local px, py = player.body:getPosition()
	local tW, tY = indicator:getDimensions()
	local screenX, screenY = cam:cameraCoords(px, py, 0, 0, gameWidth, gameHeight)

	local sX = (screenX < gameWidth / 2) and (-75 / tW) or (75 / tW)
	local sY = 75 / tY

	local ox = indicator:getWidth() / 2
	local oy = indicator:getHeight() / 2
	local offset = 65
	local indicateIMAGE = indicator

	if screenX < 0 or screenX > gameWidth or screenY < 0 or screenY > gameHeight then
		if screenY > gameHeight then
			indicateIMAGE = indicatorD
		end
		if screenY < 0 then
			indicateIMAGE = indicatorU
		end

		showIndicator = true
		ix = math.max(offset, math.min(gameWidth - offset, screenX))
		iy = math.max(offset, math.min(gameHeight - offset, screenY))
	else
		showIndicator = false
	end

	if showIndicator then
		love.graphics.draw(indicateIMAGE, ix, iy, 0, sX, sY, ox, oy)
	end
end

function drawGAMEOVER()
	local elapsed = love.timer.getTime() - gameoverTimeAt - 1

	local rgb, alpha

	if elapsed < 2 then
		rgb = math.max(0, 1 - (elapsed / 2))
		alpha = 1
	else
		rgb = 0
		alpha = math.max(0, 1 - ((elapsed - 2) / 3))
	end

	love.graphics.setColor(1, 1, 1, 1)
	local y = 75
	love.graphics.setFont(consolefont)
	love.graphics.print("THE PLAYER HAS REACHED AN END",50,y) love.graphics.setColor(1,0,0,0.4) love.graphics.print("[ERR 0x0001; HP IS ZERO]", 575,y)
	y=y+35
	love.graphics.setColor(1, 1, 1, 0.4)
	love.graphics.print("-- SELECT AN OPTION BELOW",50,y)
	y=y+150
	for i, item in ipairs(gameoverOptions) do

		--if this wasn't a comment then
		--	 local dist = 250
		--	 local totalSpan = (#gameoverOptions - 1) * dist
		--	 local startx = 533 - (totalSpan / 2)
		--	 local textwidth = tobyfont:getWidth(item)
		--	 local x = startx + (i - 1) * dist - (textwidth / 2)
		--	 local spread = (math.cos(love.timer.getTime()) * 4) + 1
		--	 local color1
		--	 local color2
		--	 if gameoverSelected ~= i then
		--	 	color1 = { 1, 1, 1, 0.25 }
		--	 	color2 = { 1, 1, 1, 1 }
		--	 else
		--	 	color1 = { 1, 1, 0, 0.25 }
		--	 	color2 = { 1, 1, 0, 1 }
		--	 end
		--	 if elapsed > 2 and gameoverSelected == i and gameoverSelected ~= 0 then
		--	 	if cx == nil then
		--	 		cx = 533
		--	 	end
		--	 	cx = cx + ((x + (tobyfont:getWidth(item) / 2) - cx) / 6)
		--	 	love.graphics.draw(youblur, cx, 520, 0, 3, 3, youblur:getWidth() / 2, youblur:getHeight() / 2)
		--	 elseif gameoverSelected == 0 then
		--	 	love.graphics.draw(youblur, 533, 520, 0, 2, 2, youblur:getWidth() / 2, youblur:getHeight() / 2)
		--	 end
		--	 love.graphics.setColor(color1)
		--	 love.graphics.print(item, x - spread, 500, 0, 1, 1)
		--	 love.graphics.print(item, x + spread, 500, 0, 1, 1)
		--	 love.graphics.print(item, x, 500 - spread, 0, 1, 1)
		--	 love.graphics.print(item, x, 500 + spread, 0, 1, 1)
		--	 love.graphics.setColor(color2)
		--	 love.graphics.print(item, x, 500, 0, 1, 1)
		--end

		if gameoverSelected ~= i then
			love.graphics.setColor(1,1,1,0.65)
			love.graphics.print(item,80,y)
		else
			love.graphics.setColor(1,1,1,1)
			love.graphics.print("> "..item,80,y)
		end
		y = y + 35
	end
	y = 500
	if gameoverInfoShown then
		love.graphics.setColor(1,1,1,0.75)
		
		love.graphics.print("PLAYER RECIEVED "..AchievementData.chipDamageTaken.." CHIP DAMAGE", 75, y)
		y=y-35
		love.graphics.print("PLAYER RECIEVED "..AchievementData.damageTaken.." FULL HITS", 75, y)
		y=y-35
		love.graphics.print("PLAYER SURVIVED FOR "..math.floor(AchievementData.surviveTime).." SECONDS", 75, y)
		y=y-35
		love.graphics.print("PLAYER REACHED LEVEL "..math.floor(RoundData.level), 75, y)
	end
	love.graphics.setColor(rgb, rgb, rgb, alpha)
	love.graphics.rectangle("fill", 0, 0, 1066, 800)
	

end

function drawChoiceButtons()
	for i, btn in ipairs(ChoiceButtons) do
		local designY = btn.y + math.sin(love.timer.getTime()) * 10
		local btnY = designY + 50
		local mx, my = getVirtualMousePosition(love.mouse.getPosition())

		if
			mx < btn.x + btn.width
			and mx > btn.x
			and my < btn.y + btn.height
			and my > btn.y
			and btn.title ~= "No Option"
			and gameRunning
		then
			love.graphics.setColor(1, 0, 0, 0.15)
		else
			love.graphics.setColor(0, 0, 0, 0.5)
		end

		love.graphics.rectangle("fill", btn.x, designY, btn.width, btn.height)

		love.graphics.setColor(1, 0, 0)
		love.graphics.setLineWidth(2)
		love.graphics.rectangle("line", btn.x, designY, btn.width, btn.height)
		love.graphics.line(btn.x, btnY, btn.x + btn.width, btnY)

		love.graphics.setFont(tobyfont)
		love.graphics.setColor(1, 1, 1)
		love.graphics.printf(btn.title, btn.x, designY + 5, btn.width, "center")

		love.graphics.setFont(toby2font)
		love.graphics.printf(btn.desc, btn.x + 10, designY + 60, btn.width - 20, "left")
	end
end

function drawUpgradeChoiceButtons()
	for i, btn in ipairs(UpgradeChoiceButtons) do
		local designY = btn.y + math.sin(love.timer.getTime()) * 10
		local btnY = designY + 50
		local mx, my = getVirtualMousePosition(love.mouse.getPosition())

		if
			mx < btn.x + btn.width
			and mx > btn.x
			and my < btn.y + btn.height
			and my > btn.y
			and btn.title ~= "No Option"
			and gameRunning
		then
			love.graphics.setColor(0, 0.8, 1, 0.15)
		else
			love.graphics.setColor(0, 0, 0, 0.5)
		end

		love.graphics.rectangle("fill", btn.x, designY, btn.width, btn.height)

		love.graphics.setColor(0, 0.8, 1)
		love.graphics.setLineWidth(2)
		love.graphics.rectangle("line", btn.x, designY, btn.width, btn.height)
		love.graphics.line(btn.x, btnY, btn.x + btn.width, btnY)

		love.graphics.setFont(tobyfont)
		love.graphics.setColor(1, 1, 1)
		love.graphics.printf(btn.title, btn.x, designY + 5, btn.width, "center")

		love.graphics.setFont(toby2font)
		love.graphics.printf(btn.desc, btn.x + 10, designY + 60, btn.width - 20, "left")
	end
end
-- TODO: improve menu UI maybe. finish gameover. stayput title card/icon on menu? add fillings to objects that look werid without background (box,stopwire)
-- TODO: add SFX for clicking cards, for rounds ending, etc
