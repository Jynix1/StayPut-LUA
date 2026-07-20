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
        love.graphics.clear(0, 0, 0, 0)
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
        instance.fixture = love.physics.newFixture(instance.newBody, instance.shape, 1.75)

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
        instance.fixture:setRestitution(0.8)  -- Make it bouncy

        instance.fusetime = 3                 -- seconds until explosion
        instance.timeafterdead = 2       -- seconds after explosion before removal
        instance.exploded = false
        instance.lastX = 0
        instance.lastY = 0

        instance.newBody:setLinearDamping(1)
        instance.newBody:setAngularDamping(2)
    end

    if obj == "tripwire" then
        instance.lifetime = 10

        instance.newBody = love.physics.newBody(world, x, y, "dynamic")
        instance.shape = love.physics.newRectangleShape(60, 60)
        instance.fixture = love.physics.newFixture(instance.newBody, instance.shape, 1.35)

        instance.fixture:setRestitution(0.8)
        instance.newBody:setAngle(math.pi / 4)
        instance.newBody:setFixedRotation(true)
        instance.newBody:setGravityScale(0.75)
        instance.newBody:setLinearDamping(2)

        instance.checkTime = 2
        instance.RequiredStillTime = 0.5
        instance.StillTimer = 0
        instance.delay = 0.75

        local ticksnd = love.audio.newSource("sounds/sfx/tripwire/tick.mp3", "static")
        ticksnd:setPitch(2)
        instance.TickSound = ticksnd
        instance.TickInterval = 0.3

        instance.ClearSound = love.audio.newSource("sounds/sfx/tripwire/clear.mp3", "static")
        instance.DangerSound = love.audio.newSource("sounds/sfx/tripwire/danger.mp3", "static")
        instance.DangerSound:setPitch(2)
        instance.FailSound = love.audio.newSource("sounds/sfx/tripwire/fail.mp3", "static")
        instance.AppearSound = love.audio.newSource("sounds/sfx/tripwire/appear.mp3", "static")



        instance.AppearSound:clone():play()
    end

    if obj == "zip" then
        instance.lifetime = math.max(4,3 * RoundData.difficultyTBO)

        instance.newBody = love.physics.newBody(world, x, y, "dynamic")
        instance.shape = love.physics.newRectangleShape(70, 70)
        instance.fixture = love.physics.newFixture(instance.newBody, instance.shape, 1.25)

        instance.texture = love.graphics.newImage("sprites/zip.png")

        instance.fixture:setRestitution(1)
        instance.newBody:setFixedRotation(true)
        instance.newBody:setGravityScale(0.1)
        instance.newBody:setLinearDamping(3)

        instance.spinVelocity = 0
        instance.dashTime = 1
        instance.dashTimer = 1

        instance.dashDelay = 1
        instance.dashDelayTimer = 1
        instance.dashWait = 0.1

        instance.dashAmount = 8
        instance.dashCount = 8

        instance.px    = nil
        instance.py    = nil
        instance.playx = nil
        instance.playy = nil
        instance.angle = nil
    end

    if obj == "musicbox" then
        instance.lifetime = 7

        instance.width = 55
        instance.height = 55
        
        instance.newBody = love.physics.newBody(world,x,y,"dynamic")
        instance.shape = love.physics.newRectangleShape(instance.width,instance.height)
        instance.fixture = love.physics.newFixture(instance.newBody,instance.shape,1.4)

        instance.texture = love.graphics.newImage("sprites/musicbox.png")

        local particle = love.graphics.newImage("sprites/notes.png")
        instance.musicnote = love.graphics.newParticleSystem(particle,50)
        instance.musicnote:setSizes(0.08,0.02)
        instance.musicnote:setParticleLifetime(1, 1.5)
        instance.musicnote:setEmissionRate(4)
        instance.musicnote:setDirection(0)
        instance.musicnote:setSpread(math.pi * 2)
        instance.musicnote:setSpeed(100, 150)
        instance.musicnote:setColors(1,1,1,1,1,1,1,0)
        instance.musicnote:setSpin(1.5)

        instance.fixture:setRestitution(0.9)
        instance.newBody:setGravityScale(0.8)
        instance.newBody:setLinearDamping(5)

        instance.windup = 1.5
        instance.slowAmount = 225
        instance.range = 225
        instance.soundrange = 400

        instance.sound = love.audio.newSource("sounds/sfx/musicbox/copywrite.mp3","static")
        instance.sound:setLooping(true)
        instance.sound:setVolume(0)
        instance.sound:play()
    end

    if obj == "tripmine" then
        instance.lifetime = 10

        instance.width = 55
        instance.height = 55

        instance.newBody = love.physics.newBody(world,x,y,"dynamic")
        instance.shape = love.physics.newRectangleShape(instance.width,instance.height)
        instance.fixture = love.physics.newFixture(instance.newBody,instance.shape,0.6)
        instance.newBody:setGravityScale(0.85)
        instance.texture = love.graphics.newImage("sprites/trih.png")

        local particle = love.graphics.newImage("sprites/trihp.png")
        instance.explodep = love.graphics.newParticleSystem(particle,50)
        instance.explodep:setSizes(0.28,0.22)
        instance.explodep:setParticleLifetime(1, 1.5)
        instance.explodep:setEmissionRate(0)
        instance.explodep:setDirection(0)
        instance.explodep:setSpread(math.pi * 2)
        instance.explodep:setSpeed(100,450)
        instance.explodep:setColors(
            0,1,1,1,
            1,0.8,0.8,0
        )
        instance.explodep:setSpin(15,0)

        instance.spawn = love.audio.newSource("sounds/sfx/tripmine/spawn.mp3","static")
        instance.boom = love.audio.newSource("sounds/sfx/tripmine/boom.mp3","static")
        instance.delay = 2
        instance.halfdead = false -- delete body/shape/fixture or turn into invis sensor, keep particles visible
        instance.timeafterdead = 3 -- then delete obj

        instance.spawn:clone():play()
    end

    instance.fixture:setUserData({ type = instance.obj, owner = instance })

    return instance
end

function object:draw() ----------------                                                                                         --------- drawing
    if not self.newBody or not self.shape then
        return
    end

    love.graphics.draw(self.exParticleSystem, self.lastX, self.lastY, 0, 1, 1, 0, 0)

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
        love.graphics.setColor(1, 1, 1, alpha)
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
    elseif self.obj == "tripwire" then
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.setLineStyle("smooth")
        love.graphics.setLineWidth(4)
        love.graphics.polygon("line", self.newBody:getWorldPoints(self.shape:getPoints()))
    elseif self.obj == "zip" then
        local vx,vy = self.newBody:getLinearVelocity()
        local spd   = math.sqrt(vx ^ 2 + vy ^ 2)
        local px,py = self.newBody:getPosition()
        local tW,tY = self.texture:getDimensions()
        local sX    = 35 / tW + spd/15000
        local sY    = 35 / tY + spd/15000

        love.graphics.setColor(1, 1, 1 - spd / 1000, alpha)
        love.graphics.setLineStyle("rough")
        love.graphics.setLineWidth(7)
        love.graphics.polygon("line", self.newBody:getWorldPoints(self.shape:getPoints()))

        love.graphics.draw(self.texture,px,py,0,sX,sY,300,300)
    elseif self.obj == "musicbox" then
        love.graphics.setColor(1,1,1,alpha)
        love.graphics.draw(self.musicnote,0,0)
        local px,py = self.newBody:getPosition()
        local playerX, playerY = player.body:getPosition()

        local dx = playerX - px
        local dy = playerY - py
        local distance = math.sqrt(dx * dx + dy * dy)

        local tW,tH = self.texture:getDimensions()
        local sX = self.width / tW
        local sY = self.height / tH
        local r = self.newBody:getAngle()

        if distance <= self.range then
            love.graphics.setLineStyle("smooth")
            love.graphics.setLineWidth(math.random(8.1,16.45))
            love.graphics.setColor(1, 1, 1)
            love.graphics.line(px,py,playerX,playerY)
        end

        love.graphics.draw(self.texture,px,py,r,sX,sY,tW/2,tH/2)

        love.graphics.setLineStyle("smooth")
        love.graphics.setLineWidth(2)
        love.graphics.setColor(0.9,0.9,1,0.5)
        love.graphics.circle("line",px,py,self.range)
        
    elseif self.obj == "tripmine" then
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(self.explodep,0,0)
        love.graphics.setColor(1,1,1,alpha)

        local x,y = self.newBody:getPosition()
        local tW,tH = self.texture:getDimensions()
        local sx,sy = self.width/tW,self.height/tH
        local r = self.newBody:getAngle()

        if not self.halfdead then
            love.graphics.draw(self.texture,x,y,r,sx*1.4,sy*1.4,tW/2,tH/2)
        end
    end
end

function object:update(dt)
    if not self.newBody or self.newBody:isDestroyed() or not self.shape then
        return
    end

    self.lifetime = self.lifetime - dt

    if self.lifetime <= 0 then -- -- -- -- - - - - - - - lifetime stuff
        if self.timeafterdead then
            self.timeafterdead = self.timeafterdead - dt
            if self.timeafterdead <= 0 then
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
            if self.obj == "musicbox" then
                self.sound:stop()
            end
            return
        end
    end -- - - - - - - - - - - - -  - - - - -  - - - - --

    self.exParticleSystem:update(dt)
    --
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

            self.exParticleSystem:setPosition(0, 0)
            self.exParticleSystem:emit(100)

            local numProjectiles = 14
            if math.ceil(14 - RoundData.level / 2) < 5 then
                numProjectiles = 5
            else
                numProjectiles = math.ceil(14 - RoundData.level / 2)
            end

            local spawnDistance = 5

            for i = 0, numProjectiles - 1 do
                local angle = (i / numProjectiles) * math.pi * 2
                local spawnX = bombX + math.cos(angle) * spawnDistance
                local spawnY = bombY + math.sin(angle) * spawnDistance
                local newProjectile = Projectile.new(world, spawnX, spawnY, angle, "bullet")
                table.insert(projectiles, newProjectile)
            end
        end
    end
    --
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

            if followerY > 650 then
                self.newBody:applyLinearImpulse(0, -700)
            end
            if followerY < 0 then
                self.newBody:applyLinearImpulse(0, 15)
            end

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

    if self.obj == "tripwire" then
        local cx, cy = self.newBody:getPosition()

        if self.delay < 0 then
            if not player.moving then self.StillTimer = self.StillTimer + dt end
            if player.moving then
                self.checkTime = self.checkTime - dt
                self.StillTimer = 0
            end
        else
            self.delay = self.delay - dt
        end

        if cy > 200 then
            self.newBody:applyLinearImpulse(0, -8)
        end

        if self.checkTime <= 0 then
            player:TakeDamage(1)
            self.newBody:destroy()
            self.newBody = nil
            self.shape = nil
            self.fixture = nil
            self.FailSound:clone():play()
            return
        end

        if self.StillTimer > self.RequiredStillTime then
            self.ClearSound:clone():play()
            self.newBody:destroy()
            self.newBody = nil
            self.shape = nil
            self.fixture = nil
            return
        end

        self.TickInterval = self.TickInterval - dt

        if self.TickInterval <= 0 then
            if self.checkTime > 1 then
                self.TickSound:clone():play()
                self.TickInterval = 0.1
            else
                self.DangerSound:clone():play()
                self.TickInterval = 0.2
            end
        end

        print("1 " .. tostring(player.moving))
        print("2 " .. self.StillTimer)
        print("3 " .. self.checkTime)
    end

    if self.obj == "zip" then

        local px,py = self.newBody:getPosition()

        self.newBody:setAngle(self.newBody:getAngle() + self.spinVelocity)

        local function IsTouchingAnything(body)
            local contacts = body:getContacts()
            return #contacts > 0
        end

        if py > 475 then 
            self.newBody:applyLinearImpulse(0,-50)
        end
        if py < 0 + 60 then 
            self.newBody:applyLinearImpulse(0,15)
        end
        if px > 1066 - 60 then
            self.newBody:applyLinearImpulse(-15,0)
        end
        if px < 0 + 60 then
            self.newBody:applyLinearImpulse(15,0)
        end

        if not IsTouchingAnything(self.newBody) then
            self.spinVelocity = math.min(0.05, self.spinVelocity + 0.0002)
        else
            self.spinVelocity = math.max(0, math.min(0.2, self.spinVelocity - 0.00015))
        end

        if self.dashDelayTimer <= 0 then
            if self.dashCount > 0 then
                if self.dashWait <= 0 then

                    if self.dashCount == self.dashAmount or self.angle == nil then
                        local pyx,pyy = player.body:getPosition()
                        self.px = px
                        self.py = py
                        self.playx = pyx
                        self.playy = pyy
                        self.angle = math.atan2(self.playy - py, self.playx - px)
                    end

                    local forceX = math.cos(self.angle) * 500
                    local forceY = math.sin(self.angle) * 500

                    self.newBody:applyLinearImpulse(forceX, forceY)
                    self.dashCount = self.dashCount - 1
                    self.dashWait = 0.07
                else
                    self.dashWait = self.dashWait - dt
                end
            end
            if self.dashCount <= 0 then
                self.dashCount = self.dashAmount
                self.dashDelayTimer = self.dashDelay
            end
        else
            self.dashDelayTimer = self.dashDelayTimer - dt
        end
    end

    if self.obj == "musicbox" then
        local x,y = self.newBody:getPosition()
        local px,py = player.body:getPosition()
        local dx,dy = px-x,py-y
        local dist = math.sqrt(dx^2 + dy^2)

        self.musicnote:setPosition(x,y)
        self.musicnote:update(dt)

        self.sound:setVolume(0.1-(dist/self.soundrange)/10)
    end

    if self.obj == "tripmine" then
        local mineX, mineY = self.newBody:getPosition()
        local playerX, playerY = player.body:getPosition()

        self.explodep:setPosition(mineX,mineY)
        self.explodep:update(dt)

        local dx = playerX - mineX
        local dy = playerY - mineY

        local triggerDistance = 57

        if dx * dx + dy * dy <= triggerDistance * triggerDistance and self.halfdead == false then
            self.boom:clone():play()
            player:takeBarDamage(75)
            self.lifetime = 1
            self.halfdead = true
            if self.fixture then self.fixture:setSensor(true) end
            if self.newBody then self.newBody:setActive(false) end
            self.explodep:emit(40)
            self.boom:clone():play()
        end
    end
end

return object