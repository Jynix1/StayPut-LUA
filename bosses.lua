local boss = {}
boss.__index = boss

function boss:new(x, y, bo) -----------------------------------------------------------------------------------------------------------------------
	local instance = setmetatable({}, boss)

	if bo == "clone" then
		instance.bo = bo
		instance.hp = 100

		instance.size = 25
		instance.currentbehavior = nil
		instance.newBody = love.physics.newBody(world, x, y, "dynamic")
		instance.shape = love.physics.newCircleShape(instance.size)
		instance.fixture = love.physics.newFixture(instance.newBody, instance.shape, 1.75)
		instance.newBody:setGravityScale(1.2)
		instance.newBody:setLinearDamping(1)
		instance.fixture:setRestitution(0.25)

		instance.texture = love.graphics.newImage("sprites/mint/mint4.png")

		local canvas = love.graphics.newCanvas(50, 50)
		canvas:renderTo(function ()
			love.graphics.clear(0,0,0,0)
			love.graphics.setColor(1,0,0,1)
			love.graphics.circle("line",25,25,25)
		end)

		instance.jumpCooldown = 0

		instance.dashActive = nil
		instance.dashCooldown = 1
		instance.dashMaxWindup = 0.5
		instance.dashWindup = 0
		instance.dashMaxCooldown = 2
		instance.dashDamageTimer = 0

		instance.dashRandomIntervalmin,instance.dashRandomIntervalmax = 2.5,11.0
		instance.dashRandomTimer = 0
		instance.dashSelectedInterval = 10
		instance.dashLastWindup = 0

	    instance.dashsfx = love.audio.newSource("sounds/sfx/dash.mp3","static")
    	instance.dashsfx:setPitch(0.6)
    	instance.dashsfx:setVolume(0.35)

		instance.warnsfx = love.audio.newSource("sounds/sfx/bos_clone/warn.mp3","static")
		instance.warnsfx:setPitch(0.85)
		instance.warnsfx:setVolume(0.4)

		instance.stopsfx = love.audio.newSource("sounds/sfx/bos_clone/stop.mp3","static")
		instance.stopsfx:setVolume(0.4)

		instance.recoversfx = love.audio.newSource("sounds/sfx/bos_clone/recover.mp3","static")
		instance.recoversfx:setVolume(0.3)

		instance.unstuckThreshold = 1
		instance.unstuckTimer = 0
		--

		instance.outOfBounds = 0

		instance.dashfunc = function(force, angle, windup, winduptime, damageTime)
			local cx, cy = instance.newBody:getPosition()
			local px, py = player.body:getPosition()
			local dt = love.timer.getDelta()
			local dash = instance.dashActive

			instance.dashMaxWindup = winduptime

			if angle == "player" then
				angle = math.atan2(py-cy,px-cx)
			end

			if windup then
				if instance.dashWindup < instance.dashMaxWindup then
					instance.dashWindup = instance.dashWindup + dt
					instance.fixture:setDensity(5)
					if instance.outOfBounds >= 1 then
						if cx < 533 then
							instance.newBody:setLinearVelocity(-325, -10)
							angle = math.rad(-75)
							instance.newBody:setAngularVelocity(50)
						else
							instance.newBody:setLinearVelocity(325, -10)
							angle = math.rad(-115)
							instance.newBody:setAngularVelocity(-50)
						end
					else
						instance.newBody:setLinearVelocity(0, 0)
					end
				else
					instance.fixture:setDensity(1.5)
					if instance.outOfBounds >= 1 then
						if cx < 533 then
							angle = math.rad(-75)
						else
							angle = math.rad(-115)
						end
					end
				end
			end

			local dx, dy = math.cos(angle), math.sin(angle)
			local Avx, Avy = dx * force, dy * force

			if (not windup) or instance.dashWindup >= instance.dashMaxWindup then
				instance.newBody:applyLinearImpulse(Avx, Avy)
				instance.outOfBounds = 0
				instance.dashWindup = 0
				instance.dashDamageTimer = damageTime
				instance.dashLastWindup = winduptime
				instance.fixture:setDensity(1.5)

				if windup then instance.recoversfx:clone():play() else instance.dashsfx:clone():play() end

				return true -- dashed!
				end

			return false -- didnt :(
		end

		instance.trydash = function(force, angle, windup, winduptime, damageTime)
			if instance.dashActive then
				return false
			end

			instance.dashActive = {
				force = force,
				angle = angle,
				windup = windup,
				winduptime = winduptime,
				damageTime = damageTime
			}
			return true
		end

		instance.jumpfunc = function(force)
			instance.newBody:applyLinearImpulse(0, -force)
		end

		instance.bounds = {
			["top"] = 0,
			["left"] = 190,
			["right"] = 878,
		}

		instance.behaviors = {
			["follow"] = function()
				local px, py = player.body:getPosition()
				local cx, cy = instance.newBody:getPosition()
				local vx, vy = instance.newBody:getLinearVelocity()
				local targetY = cy + 35
				local spd = 1100
				local jp = 600
				local dt = love.timer.getDelta()

				local canjump = false
				for i = 1, 5 do
					local newX = cx + (i - 1) * 10

					world:rayCast(newX, cy, newX, targetY, function(fixture, x, y, xn, yn, fraction)
						if fixture == floorFixture then
							canjump = true
							return 0
						end

						return 1
					end)
				end

				world:rayCast(px - 20, py + 20, px + 20, py + 20, function(fixture, fx, fy, xn, yn, fraction)
					local fData = fixture:getUserData()
					if fData and not fixture:isSensor() and fData.obj ~= "tripmine" and fixture ~= player.fixture and canjump and instance.jumpCooldown <= 0 then
						instance.jumpfunc(jp)

						canjump = false
						instance.jumpCooldown = 1
						return 0
					end
					return 1
				end)

				if py + 50 < cy and canjump and instance.jumpCooldown <= 0 then
					instance.jumpfunc(jp)

					canjump = false
					instance.jumpCooldown = 1
				end

				if px > instance.bounds["left"] and px < instance.bounds["right"] then
					if px > cx then
						instance.newBody:applyLinearImpulse(spd * dt, 0)
						if vx < 0 then
							instance.newBody:applyLinearImpulse(spd / 5 * dt, 0)
							instance.newBody:applyAngularImpulse(spd/10)
						end
					elseif px < cx then
						instance.newBody:applyLinearImpulse(-(spd * dt), 0)
						if vx > 0 then
							instance.newBody:applyLinearImpulse(-(spd / 5 * dt), 0)
							instance.newBody:applyAngularImpulse(-spd/10)
						end
					end
				end

				if cx < instance.bounds["left"] + 30 or cx > instance.bounds["right"] - 30 then
					if cx < instance.bounds["left"] + 30 then
						instance.newBody:applyLinearImpulse((spd * dt) * 1.25, 0)
					end
					if cx > instance.bounds["right"] - 30 then
						instance.newBody:applyLinearImpulse(-(spd * dt) * 1.25, 0)
					end
					instance.outOfBounds = instance.outOfBounds + dt
				end

				if instance.outOfBounds > 1 then
					if instance.trydash(550, 0, true, 0.6,0.75) then instance.stopsfx:clone():play() end
				end

				if cy < py
					and cx < px+35
					and cx > px-35
				then
					if instance.unstuckTimer > instance.unstuckThreshold then
						if cx <= 533 then
							instance.trydash(550,math.rad(45),false,0,0.2)
						else
							instance.trydash(550,math.rad(130),false,0,0.2)
						end
						instance.unstuckTimer = 0
					end
					instance.unstuckTimer = instance.unstuckTimer + dt
				end

				if not instance.dashActive then
					instance.dashRandomTimer = instance.dashRandomTimer + dt
				end

				if instance.dashRandomTimer > instance.dashSelectedInterval then

					local angle = math.atan2(py-cy,px-cx)

					if instance.dashWindup <= 0 then instance.stopsfx:clone():play() end


					if instance.trydash(1350,"player",true,0.75,1) then
						instance.warnsfx:clone():play()
						instance.dashRandomTimer = 0
						instance.dashSelectedInterval = love.math.random(instance.dashRandomIntervalmin,instance.dashRandomIntervalmax)
					end
				end
			end,
			["charge"] = function()
				-- todo
			end,
		}
	end

	return instance
end

function boss:update(dt) -------------------------------------------------------------------------------------------------------------------------
	if self.bo == "clone" then
		if self.jumpCooldown and self.jumpCooldown > 0 then
			self.jumpCooldown = self.jumpCooldown - dt
		end
		if self.dashDamageTimer > 0 then
			local px, py = player.body:getPosition()
			local x, y = self.newBody:getPosition()

			local dx = px - x
			local dy = py - y
			local dist = math.sqrt(dx * dx + dy * dy)

			local vx, vy = self.newBody:getLinearVelocity()
			local spd = math.sqrt(vx * vx + vy * vy)

			if dist <= 55 then
				local windtime = self.dashLastWindup or 0
				player:takeBarDamage(math.floor((spd * 0.025) + (windtime * 50)))
				self.dashDamageTimer = 0
			end

			self.dashDamageTimer = self.dashDamageTimer - dt
		end

		self.currentbehavior = "follow"

		self.behaviors[self.currentbehavior]()

		local dash = self.dashActive
		if dash and self.dashfunc(dash.force, dash.angle, dash.windup, dash.winduptime, dash.damageTime) then
			self.dashActive = nil
		end
	end
end

function boss:draw() ------------------------------------------------------------------------------------------------------------------------------
	if self.bo == "clone" then
		local x, y = self.newBody:getPosition()
		local r = self.newBody:getAngle()
		local dix,diy = self.texture:getDimensions()
		local tw,th = self.size/dix*2,self.size/diy*2

		love.graphics.setColor(1, 0, 0, 1)
		love.graphics.draw(self.texture,x,y,r,tw,th,dix/2,diy/2)
	end
end

function boss:takeDamage(amount) ----------------------------------------------------------------------------------------------------------------------
	self.hp = self.hp - amount
	if self.hp <= 0 then
		self:die()
	end
end

return boss
