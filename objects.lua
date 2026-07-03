local object = {}
object.__index = object

local Projectile = require("projectiles")
projectiles = projectiles or {}

function object:new(x, y, obj)
    local instance = setmetatable({}, object)
    instance.x = x
    instance.y = y
    instance.obj = obj

    local exCanvas = love.graphics.newCanvas(70, 70)
    exCanvas:renderTo(function()
        love.graphics.clear(0,0,0,0)
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("fill", 35, 35, 35)
    end)

    instance.exParticleSystem = love.graphics.newParticleSystem(exCanvas, 100)
    instance.exParticleSystem:setParticleLifetime(0.5, 1)
    instance.exParticleSystem:setEmissionRate(0)
    instance.exParticleSystem:setSizeVariation(1)
    instance.exParticleSystem:setSpeed(100, 200)
    instance.exParticleSystem:setSpread(math.pi * 2)
    instance.exParticleSystem:setColors(1, 0, 0, 0.35, 0.25, 0, 1, 0)

    if obj == "square" then
        instance.lifetime = 8

        instance.newBody = love.physics.newBody(world, x, y, "dynamic")
        instance.shape = love.physics.newRectangleShape(150, 150)
        instance.fixture = love.physics.newFixture(instance.newBody, instance.shape, 2)

        instance.newBody:setLinearDamping(0.5)
        instance.newBody:setAngularDamping(0.5)

    end

    if obj == "follower" then
        instance.lifetime = 8

        instance.newBody = love.physics.newBody(world, x, y, "dynamic")
        instance.shape = love.physics.newCircleShape(25)
        instance.fixture = love.physics.newFixture(instance.newBody, instance.shape, 1)

        instance.newBody:setLinearDamping(1)
        instance.newBody:setAngularDamping(2)

    end

    if obj == "bomb" then
        instance.lifetime = 8

        instance.newBody = love.physics.newBody(world, x, y, "dynamic")
        instance.shape = love.physics.newCircleShape(40)
        instance.fixture = love.physics.newFixture(instance.newBody, instance.shape, 1)
        instance.newBody:setGravityScale(0.5) -- Reduce gravity effect on the bomb
        instance.fixture:setRestitution(0.8) -- Make it bouncy

        instance.fusetime = 3 -- seconds until explosion
        instance.timeAfterExplosion = 2 -- seconds after explosion before removal
        instance.exploded = false
        instance.lastX = 0
        instance.lastY = 0

        instance.newBody:setLinearDamping(1)
        instance.newBody:setAngularDamping(2)

    end

    instance.fixture:setUserData({ type = instance.obj, owner = instance })

    return instance
end

function object:draw() ----------------                                                                                         --------- drawing
    if not self.newBody or not self.shape then
        return
    end

    -- draw particle system centered on the 150x150 canvas at the body's position
    love.graphics.draw(self.exParticleSystem, self.lastX, self.lastY, 0, 1, 1, 0,0)

    local alpha = 1
    if self.lifetime and self.lifetime < 2 then
        alpha = 0.3 + 0.7 * (0.5 + 0.5 * math.sin(love.timer.getTime() * 20))
    end

    if self.obj == "square" then
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.setLineStyle("smooth")
        love.graphics.setLineWidth(4)
        love.graphics.polygon("line", self.newBody:getWorldPoints(self.shape:getPoints()))
        love.graphics.setColor(1, 1, 1, 1)
    elseif self.obj == "follower" then
        love.graphics.setColor(0.8, 0.8, 1, alpha)
        love.graphics.setLineStyle("smooth")
        love.graphics.setLineWidth(8)
        love.graphics.circle("line", self.newBody:getX(), self.newBody:getY(), self.shape:getRadius())
        love.graphics.setColor(1, 1, 1, 1)
    elseif self.obj == "bomb" then
        if self.exploded == false then
            local cx, cy = self.newBody:getX(), self.newBody:getY()
            local r = self.shape:getRadius() - 4
            local rot = self.newBody:getAngle()

            love.graphics.setColor(1, 0.2, 0.3, alpha)
            love.graphics.setLineWidth(12)
            love.graphics.setLineStyle("smooth")
            love.graphics.circle("line", cx, cy, r)

            local spikes = 12
            local spikeL = r * 0.3
            local baseInsert = 1
            love.graphics.setColor(0.9, 0.1, 0.2, alpha)
            for i = 0, spikes - 1 do
                local ang = (i / spikes) * math.pi * 2 + rot
                local baseAngOffset = (math.pi / spikes) * 2
                local bx1 = cx + math.cos(ang - baseAngOffset) * (r - baseInsert)
                local by1 = cy + math.sin(ang - baseAngOffset) * (r - baseInsert)
                local bx2 = cx + math.cos(ang + baseAngOffset) * (r - baseInsert)
                local by2 = cy + math.sin(ang + baseAngOffset) * (r - baseInsert)
                local tipx = cx + math.cos(ang) * (r + spikeL)
                local tipy = cy + math.sin(ang) * (r + spikeL)
                love.graphics.polygon("fill", bx1, by1, bx2, by2, tipx, tipy)
            end
            love.graphics.setColor(1, 1, 1, 1)
        end
    end
end

function object:update(dt)
    if not self.newBody or not self.shape then
        return
    end

    self.lifetime = self.lifetime - dt

    if self.lifetime <= 0 then
        if self.timeAfterExplosion then
            self.timeAfterExplosion = self.timeAfterExplosion - dt
            if self.timeAfterExplosion <= 0 then
                if self.newBody then
                    self.newBody:destroy()
                end
                self.newBody, self.shape, self.fixture = nil, nil, nil
                return
            end
        else
            if self.newBody then
                self.newBody:destroy()
            end
            self.newBody, self.shape, self.fixture = nil, nil, nil
            return
        end
    end

    self.exParticleSystem:update(dt)

    if self.obj == "bomb" then
        self.fusetime = self.fusetime - dt
        if self.fusetime <= 0 and not self.exploded then
            self.exploded = true

            local bombX = self.newBody:getX()
            local bombY = self.newBody:getY()
            local r = self.shape:getRadius()
            self.lastX = bombX
            self.lastY = bombY

            if self.fixture then self.fixture:setSensor(true) end
            if self.newBody then self.newBody:setActive(false) end

            world:queryBoundingBox(bombX - r - 20, bombY - r - 20, bombX + r + 20, bombY + r + 20, function(fixture)
                local body = fixture:getBody()
                if body ~= self.newBody then
                    body:setAwake(true)
                end
                return true
            end)

            -- emit at PS-local origin (0,0). draw() will place the PS at the bomb coordinates
            self.exParticleSystem:setPosition(0, 0)
            self.exParticleSystem:emit(100)
            local numProjectiles = 12
            local spawnDistance = 5  -- How far from bomb center to spawn

            for i = 0, numProjectiles - 1 do
                local angle = (i / numProjectiles) * math.pi * 2
                local spawnX = bombX + math.cos(angle) * spawnDistance
                local spawnY = bombY + math.sin(angle) * spawnDistance
                local newProjectile = Projectile.new(world, spawnX, spawnY, angle, "bullet")
                table.insert(projectiles, newProjectile)
            end
            
        end
    end

    if self.obj == "follower" then
        local playerX, playerY = player.body:getPosition()
        local followerX, followerY = self.newBody:getPosition()

        local dx = playerX - followerX
        local dy = playerY - followerY
        local distance = math.sqrt(dx * dx + dy * dy)

        if distance > 0 then
            local forceMagnitude = 500
            local forceX = (dx / distance) * forceMagnitude
            local forceY = (dy / distance) * forceMagnitude

            self.newBody:applyForce(forceX, forceY)

            -- if it falls too low, jump very high
            if followerY > 650 then
                self.newBody:applyLinearImpulse(0, -700)
            end
            if followerY < 0 then
                self.newBody:applyLinearImpulse(0, 15)
            end

            -- simple obstacle check ahead, ignoring the player body
            local checkX = followerX + (dx / distance) * 80
            local checkY = followerY + (dy / distance) * 80

            local hit = false
            world:rayCast(followerX, followerY, checkX, checkY, function(fixture, x, y, xn, yn, fraction)
                if fixture ~= player.fixture then
                    hit = true
                    return 1
                end
                return 1
            end)

            if hit and not self.jumpCooldown then
                self.newBody:applyLinearImpulse(forceX * 0.2, forceMagnitude * -0.75)
                self.jumpCooldown = 0.6
            end
        end

        if self.jumpCooldown then
            self.jumpCooldown = self.jumpCooldown - dt
            if self.jumpCooldown <= 0 then
                self.jumpCooldown = nil
            end
        end
    end
end

return object
