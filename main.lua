-- StayPut 2. A passion project made to learn Lua and LÖVE2D.
-- Originating from a game made in TurboWarp/Scratch. This is a remake of the original game in Lua using the LÖVE2D framework.

-- Dependencies and version
if os.getenv("LOVE2D_TOOLS") then
	pcall(require, "_love2d_tools_bridge")
end

GAME_VER = "v0.1.4"

local updNotifTime = 0

objects = {}
bosses = {}

-- getting helpers -----------------------------------

local Menu = require("menu")
local discordRPC = require("lib/discordRPC")

local Player = require("baller")
local object = require("objects")
local boss = require("bosses")

local https = require("https")
local json = require("lib/json")

local Musichandler = require("/helpers/musichandler")
local drawButtons = require("/helpers/drawbuttons")
local gameoverHelper = require("/helpers/gameoverhelper")
local otherrenders = require("/helpers/otherrenders")
local roundlogic = require("/helpers/roundlogic")
------ drawButtons.lua
local drawChoiceButtons = drawButtons.drawChoiceButtons
local drawUpgradeChoiceButtons = drawButtons.drawUpgradeChoiceButtons
-- gameoverhelper.lua
local drawGAMEOVER = gameoverHelper.drawGAMEOVER
-- otherrenders.lua
local drawPlayerUI = otherrenders.drawPlayerUI
local drawIndicator = otherrenders.drawIndicator
local drawFloor = otherrenders.drawFloor
-- roundlogic.lua
local roundUpdate = roundlogic.roundUpdate
-- ^ applying helper functions ^ ---------------------

local lastEnemy = nil

local discordrefreshTimer = 0

-- Runtime state
local gameoverOptions = {
	[1] = "RESTART EXPERIMENT",
	[2] = "STOP PROGRAM",
	[3] = "VIEW INFORMATION"
}
local gameoverSelected = 0
local gameoverTimeAt = nil
greenFlashAlpha = 0

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

-- Click effects
local clickfx = love.graphics.newCanvas(240,200)
clickfx:renderTo(function ()
	love.graphics.rectangle("fill",0,0,240,200)
end)
local clickfxSquareSystem = love.graphics.newParticleSystem(clickfx)
clickfxSquareSystem:setSizes(1,0)
clickfxSquareSystem:setParticleLifetime(0.4)
clickfxSquareSystem:setSpeed(0)
clickfxSquareSystem:setColors(1,0,0,1,1,0,0,0)

-- +==========================================================================+
-- | GAME DATA AND OPTIONS                                                    |
-- +==========================================================================+
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

-- Enemy and upgrade options
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

-- choice UI state and selection
ChoiceButtons = {
	{ x = 115, y = 100, width = 240, height = 200, id = "", title = "", desc = "" },
	{ x = 413, y = 100, width = 240, height = 200, id = "", title = "", desc = "" },
	{ x = 711, y = 100, width = 240, height = 200, id = "", title = "", desc = "" },
}

UpgradeChoiceButtons = {
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
	["0"] = "clone",
}

-- Discord presence

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

-- +==========================================================================+
-- | LÖVE INITIALIZATION                                                      |
-- +==========================================================================+
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

	Camera = require("lib/camera")
	Flux = require("lib/flux")
	cam = Camera(533, 300)
	camZoom = 1
	camZoom2 = 1

	FPSCountToggle = false
	FPSCount = love.timer.getFPS()

	floorBody = love.physics.newBody(world, 533, floorCenterY, "static")
	floorShape = love.physics.newRectangleShape(floorWidth, floorHeight)
	floorFixture = love.physics.newFixture(floorBody, floorShape)
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

	hpImg = love.graphics.newImage("sprites/mint/hp.png")

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

	local versioncheck = love.thread.newThread("helpers/versioncheck.lua")
	versioncheck:start(GAME_VER)
	UpdateStatus = nil

	--gameCanvas = love.graphics.newCanvas(gameWidth, gameHeight)
	--gameCanvas:setFilter("nearest", "nearest")
end

-- Background effects
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

			if RoundData.level < 10 then
				love.graphics.setColor(0.247, 0.129, 0.129, 0.5)
			else
				love.graphics.setColor(0.408, 0, 0.459, 0.5)
			end

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
					love.graphics.setColor(1, 0, 0, 0.010)
					love.graphics.circle("fill",element.x,element.y,12)
					love.graphics.setBlendMode("alpha")
				end
				if element.type == "dot2" then
					love.graphics.setBlendMode("alpha")
					love.graphics.setColor(0.882, 0, 1, 0.01)
					love.graphics.circle("fill",element.x,element.y,6)
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
local bgParticleTime = 0

local function updateBG(dt)
	bgParticleTime = bgParticleTime + dt
    local phase = bgParticleTime % (15 * math.pi)

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
		local typetomake = ""
		
		if RoundData.level < 10 then
			dir,spread = math.rad(225),math.rad(math.cosh(phase)*115)
			typetomake = "dot"
		elseif RoundData.level < 20 then
			dir,spread = math.rad(225),math.rad(math.cos(phase)*115)
			typetomake = "dot2"
		else
			dir,spread = math.rad(225),math.rad(math.tan(phase)*115)
			typetomake = "dot"
		end

		local angle = dir + (i - 2.5) * (spread / 4)
		local dx = math.cos(angle) * (40)
		local dy = math.sin(angle) * (40)
		createBgElement(typetomake,160,90,dx,dy,8)
		particleSpawnTimer = 0.001
	end
	else
		particleSpawnTimer = particleSpawnTimer - dt
	end
end

-- +==========================================================================+
-- | MAIN UPDATE LOOP                                                         |
-- +==========================================================================+
function love.update(dt) --                                                                   ----  v v v  | main game loop |  v v v  ----
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
				if key ~= "0" then
					spawnHold[key] = {
						timer = 0,
						repeatTimer = 0,
						type = objType,
					}
					local newObject = object:new(533, 0, objType)
					table.insert(objects, newObject)
				else
					spawnHold[key] = {
						timer = 0,
						repeatTimer = 0,
						type = objType,
					}
					local newBoss = boss:new(533,0,"clone")
					table.insert(bosses,newBoss)
				end

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

	local threadReturns = love.thread.getChannel("result"):pop()

	if (UpdateStatus == nil or UpdateStatus == "") and threadReturns ~= nil then
		UpdateStatus = threadReturns
	end

	if UpdateStatus ~= "" and UpdateStatus ~= nil then
		updNotifTime = updNotifTime + dt
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
			Flux.update(dt)

			local moveForce = 600
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

			for i = #bosses, 1, -1 do
				local bos = bosses[i]
				bos:update(dt)
			end

			if GAMEOVER then
				RoundData.enemyPicker = false
				RoundData.upgradePicker = false
				RoundData.ongoing = true
				Musichandler:reset()
				clearAllObjects()
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

			roundUpdate(dt,object)

			if RoundData.time <= 0 then -- round end
				updateDiscordPresence()

				local result = roundlogic.onRoundEnd()

				if result == "upgrade" then
					refreshUpgradeChoiceButtons()
				elseif result == "enemy" then
					refreshChoiceButtons()
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

-- LÖVE shutdown callback
function love.quit()
	if discordEnabled then
		discordRPC.clearPresence()
		discordRPC.shutdown()
	end
	return false
end

-- Main draw callback
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
		drawGAMEOVER(gameoverTimeAt,gameoverOptions,gameoverSelected)
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

	if UpdateStatus ~= "" and UpdateStatus ~= nil then
		drawUpdNotification(updNotifTime)
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

	for _, boss in ipairs(bosses) do
		boss:draw()
	end

	love.graphics.setColor(1,1,1,1)
	love.graphics.draw(clickfxSquareSystem)
	love.graphics.draw(clickParticleSystem)

	player:draw() -- drawing one player

	cam:detach() --------------

	drawIndicator()
end

-- +==========================================================================+
-- | INPUT CALLBACKS                                                          |
-- +==========================================================================+
-- Handles keyboard input for menus and developer controls.
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

-- Mouse input and coordinate conversion cuz the game runs on canvas
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

-- Discord presence refresh
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

-- +==========================================================================+
-- | GAME STATE MANAGEMENT                                                    |
-- +==========================================================================+
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
	cam:zoomTo(camZoom2 * (Dev and Dev.cameraZoomMultiplier or 1))
end

-- World and game-over rendering
	-- moved to new file; see otherrenders.lua
--

-- Choice rendering
--[[
function drawChoiceButtons()
	moved to new file; see drawButtons.lua
end
]]
--[[
function drawUpgradeChoiceButtons()
	moved to new file; see drawButtons.lua
end
]]

--[[ function checkVersion()
	moved to new file; see versioncheck.lua
end]]

-- Update notification
function drawUpdNotification(timeAlive)
	local time = love.timer.getTime()
	local c = math.cos(time*10)/2
	local x, y = 45,55

	local texttoshow = ""
	if UpdateStatus == "" or UpdateStatus == nil then return end
	if UpdateStatus == "outdated" then
		love.graphics.setColor(1,1,0.5+c,1-(timeAlive/10))
		texttoshow = "Game version mismatch! Could be outdated. Download the latest release on the Repo."
	elseif UpdateStatus == "uptodate" then
		love.graphics.setColor(0.5+c,1,0.5+c,1-(timeAlive/10))
		texttoshow = "Validated game version with GitHub. Up to date!"
	else
		love.graphics.setColor(1,0.5+c,0.5+c,1-(timeAlive/10))
		texttoshow = UpdateStatus
	end

	love.graphics.setFont(tobyfont)
	
	love.graphics.print(texttoshow, x,y,0,0.55,0.55)
end

Dev = require("dev")