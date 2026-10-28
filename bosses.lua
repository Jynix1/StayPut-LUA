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
        instance.fixture = love.physics.newFixture(instance.newBody, instance.shape, 1)
        instance.newBody:setGravityScale(0.9)
        instance.newBody:setLinearDamping(1)

		instance.bounds = {
			["top"] = 0,
			["left"] = 190,
			["right"] = 878,
		}

		instance.behaviors = {
			["follow"] = function()
				local px, py = player.newBody:getPosition()
				local cx, cy = instance.newBody:getPosition()
                local targetY = cy + 35
				local spd = 100

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
                
                world:rayCast(px-20,py+20,px+20,py+20, function(fixture,fx,fy,xn,yn,fraction)
                    local fData = fixture:getUserData()
                    if not fixture:isSensor() and fData.obj ~= "tripmine" and canjump and instance.jumpCooldown <= 0 then


                        
                        canjump = false
                        instance.jumpCooldown = 1
                    end
                end)

				if px > x then
					instance.newBody:applyLinearImpulse(-spd, 0)
				elseif px < x then
					instance.newBody:applyLinearImpulse(spd, 0)
				end
			end,
			["charge"] = function()
				-- todo
			end,
		}
	end
end

function boss:update(dt) -------------------------------------------------------------------------------------------------------------------------
    if self.bo == "clone" then
        if self.jumpCooldown and self.jumpCooldown > 0 then
            self.jumpCooldown = self.jumpCooldown - dt
        end
    end
end

function boss:draw() ------------------------------------------------------------------------------------------------------------------------------
    if self.bo == "clone" then
        local x,y = self.newBody:getPosition()
        love.graphics.setColor(1,0,0,1)
        love.graphics.circle("line", x,y, self.size)
    end
end

return boss
