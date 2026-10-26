local Projectile = {}
Projectile.__index = Projectile

function Projectile.new(world, x, y, direction, type)
    local self = setmetatable({}, Projectile)

    self.x = x
    self.y = y
    self.type = type
    self.hasHit = false

    if type == "bullet" then
        self.speed = 275
        self.damage = 30
        self.lifetime = 6
        self.radius = 11
        self.shape = love.physics.newCircleShape(self.radius)
        
        self.body = love.physics.newBody(world, x, y, "kinematic")
        self.fixture = love.physics.newFixture(self.body, self.shape, 1)
        self.fixture:setUserData({ type = "projectile", owner = self })
        self.fixture:setSensor(true)
        self.dieonplayerhit = true

        self.drawfunc = function ()
            love.graphics.setColor(1, 0, 0)
            love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.radius)
        end

        local canvas = love.graphics.newCanvas(self.radius * 2, self.radius * 2)
        canvas:renderTo(function()
            love.graphics.clear(0,0,0,0)
            love.graphics.setColor(1, 0, 0)
            love.graphics.circle("fill", self.radius, self.radius, self.radius)
        end
        )
        self.afterimageParticles = love.graphics.newParticleSystem(canvas)

        self.afterimageParticles:setParticleLifetime(0.2)
        self.afterimageParticles:setSpeed(0)
        self.afterimageParticles:setColors(1,1,1,0.5,1,1,1,0)
        self.afterimageParticles:setEmissionRate(14)
        self.afterimageParticles:setSizes(1)
        
        local vx = self.speed * math.cos(direction)
        local vy = self.speed * math.sin(direction)
        self.body:setLinearVelocity(vx, vy)
    end
    if type == "big" then ----------------------------------------------------------------------------- requires testing
        self.speed = 150
        self.damage = 50
        self.lifetime = 8
        self.radius = 35
        self.shape = love.physics.newCircleShape(self.radius)
        
        self.body = love.physics.newBody(world, x, y, "kinematic")
        self.fixture = love.physics.newFixture(self.body, self.shape, 1)
        self.fixture:setUserData({ type = "projectile", owner = self })
        self.fixture:setSensor(true)
        self.dieonplayerhit = true

        self.draw = function ()
            love.graphics.setColor(1, 0, 0)
            love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.radius)
        end
        
        local vx = self.speed * math.cos(direction)
        local vy = self.speed * math.sin(direction)
        self.body:setLinearVelocity(vx, vy)
    end

    if type == "cannonball" then
        self.speed = 585
        self.damage = 35
        self.lifetime = 10
        self.radius = 25
        self.shape = love.physics.newCircleShape(self.radius)
        
        self.body = love.physics.newBody(world, x, y, "kinematic")
        self.fixture = love.physics.newFixture(self.body,self.shape, 1)
        self.fixture:setUserData({ type = "projectile", owner = self })
        self.fixture:setSensor(true)
        self.dieonplayerhit = false

        self.drop = 0
        self.droprate = 3
        self.canKB = true
        self.timepassed = 0

        self.draw = function ()
            local rand = love.math.random(5, 16)
            love.graphics.setLineWidth(rand)
            love.graphics.setColor(0.4, 0.4, 0.4,0.5)
            love.graphics.circle("line", self.body:getX(), self.body:getY(), self.radius+5)
            love.graphics.setColor(0.05, 0.05, 0.05)
            love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.radius)
        end

        local vx = self.speed * math.cos(direction)
        local vy = self.speed * math.sin(direction)
        self.body:setLinearVelocity(vx, vy)
    end

    if type == "pop" then
        local rand = love.math.random(300,480)
        self.speed = rand
        self.damage = 15
        self.lifetime = 5
        self.width,self.height = 25,13
        self.radius = 15

        self.shape = love.physics.newRectangleShape(self.width,self.height)
        self.body = love.physics.newBody(world,x,y,"kinematic")
        self.fixture = love.physics.newFixture(self.body,self.shape,1)
        self.fixture:setSensor(true)
        self.fixture:setUserData({ type = "projectile", owner = self })
        self.dieonplayerhit = false
        self.body:setAngularVelocity(6)

        self.timepassed = 0.2 -- starts at later number so it drops earlier cuz im lazy
        self.drop = 0
        self.droprate = 6
        self.hasHit = false

        self.draw = function ()
            local x,y = self.body:getPosition()
            love.graphics.setColor(1,1,1,self.timepassed*2)

            love.graphics.push()
                love.graphics.translate(x,y)
                love.graphics.rotate(self.body:getAngle())
                love.graphics.rectangle("fill", -self.width / 2, -self.height / 2, self.width, self.height)
            love.graphics.pop()
        end

        local vx = self.speed * math.cos(direction)
        local vy = self.speed * math.sin(direction)
        self.body:setLinearVelocity(vx, vy)
    end

    return self
end

function Projectile:update(dt)
    if not self.body then return end
    local dx = player.body:getX() - self.body:getX()
    local dy = player.body:getY() - self.body:getY()
    local distance = math.sqrt(dx * dx + dy * dy)
    if self.timepassed then self.timepassed = self.timepassed + dt end

    if self.drop then 
        if self.timepassed > 0.4 then
            self.drop = self.drop + self.droprate*dt
        end
        self.body:setPosition(self.body:getX(), self.body:getY() + self.drop)
    end

    self.lifetime = self.lifetime - dt

    if self.type == "bullet" then
        self.afterimageParticles:setPosition(
        self.body:getX(),
        self.body:getY()
    )
        self.afterimageParticles:update(dt)
    end

    if player and not self.hasHit then
        if distance < (15 + self.radius) then
            self:onHitPlayer()
            if self.dieonplayerhit then
                self.lifetime = 0
            end
        end
    end
end

function Projectile:onHitPlayer()

    local noplayerinvuln = player.invulnTimer <= 0 and player.backupinvulntimer <= 0

    player:takeBarDamage(self.damage)
    self.hasHit = true

    if self.type == "cannonball" and self.canKB then
        local px, py = player.body:getPosition()
        local bx, by = self.body:getPosition()
        local dx = px - bx
        local dy = py - by
        local distance = math.sqrt(dx * dx + dy * dy)
        table.insert(player.statusEffects, { id = "slowness", name = "Slowness", duration = 0.35, level = 3 })
        table.insert(player.statusEffects, { id = "slowness", name = "Slowness", duration = 3, level = 3 })

        if distance > 0 then
            local KBforce = 625
            local KBx = (dx / distance) * KBforce
            local KBy = (dy / distance) * KBforce
            player.body:applyLinearImpulse(KBx, KBy)
        end
    end

    if self.type == "bullet" and noplayerinvuln then
        table.insert(player.statusEffects,{ id = "vulnerable", name = "Vulnerable", duration = 8, level = 1 })
    end
end

function Projectile:draw()
    if self.type == "bullet" then
        love.graphics.draw(self.afterimageParticles)
    end
    self.drawfunc()
end

return Projectile