local Player = {}
Player.__index = Player

-- new player
function Player.new(world, x, y)
    local instance = setmetatable({}, Player)

    instance.hp = 4
    instance.maxHP = 4
    instance.invulnTimer = 0        -- seconds left of i-frames
    instance.invulnDuration = 3     -- i-frames duration after taking damage
    instance.damageParticleDelay = 0
    instance.damageParticleDelayDuration = 1/60

    instance.body = love.physics.newBody(world, x, y, "dynamic")
    instance.shape = love.physics.newCircleShape(25)
    instance.fixture = love.physics.newFixture(instance.body, instance.shape, 1)
    instance.fixture:setRestitution(0.6)
    instance.fixture:setFriction(0.9)
    instance.body:setLinearDamping(0.3)
    instance.body:setAngularDamping(2)

    instance.imagemint0 = love.graphics.newImage("sprites/mint/mint0.png")
    instance.imagemint1 = love.graphics.newImage("sprites/mint/mint1.png")
    instance.imagemint2 = love.graphics.newImage("sprites/mint/mint2.png")
    instance.imagemint3 = love.graphics.newImage("sprites/mint/mint3.png")
    instance.imagemint4 = love.graphics.newImage("sprites/mint/mint4.png")
    instance.currentImage = nil

    instance.canJump = true
    instance.dashcolor = false

    -- particles
    local pCanvas = love.graphics.newCanvas(8, 8)
    pCanvas:renderTo(function()
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("fill", 4, 4, 3)
    end)

    instance.pSystem = love.graphics.newParticleSystem(pCanvas, 100)

    instance.pSystem:setParticleLifetime(0.4, 0.8) 
    instance.pSystem:setEmissionRate(0)
    instance.pSystem:setSpeed(40,100)              
    
    instance.pSystem:setSpread(math.pi * 2)        
    instance.pSystem:setLinearAcceleration(0, 50)  
    
    instance.pSystem:setColors(1, 1, 1, 0.6, 1, 1, 1, 0)
    instance.pSystem:setSizes(1, 0.5, 0)

    local triCanvas = love.graphics.newCanvas(24, 24)
    triCanvas:renderTo(function()
        love.graphics.clear()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.polygon("fill", 12, 4, 4, 20, 20, 20)
    end)

    instance.damagePSystem = love.graphics.newParticleSystem(triCanvas, 80)
    instance.damagePSystem:setParticleLifetime(0.5, 1.0)
    instance.damagePSystem:setEmissionRate(0)
    instance.damagePSystem:setSpeed(200, 325)
    instance.damagePSystem:setSpread(math.pi * 2)
    instance.damagePSystem:setLinearDamping(2, 4)
    instance.damagePSystem:setSizes(1.2, 0.4, 0)
    instance.damagePSystem:setColors(1, 0.4, 0.4, 0.9, 1, 0.2, 0.2, 0)

    local starbounceCanvas = love.graphics.newCanvas(24, 24)
    starbounceCanvas:renderTo(function()
        love.graphics.clear()
        love.graphics.setColor(0.635, 0, 1)
        love.graphics.polygon("fill", 12, 4, 4, 20, 20, 20)
    end)

    instance.starbouncePSystem = love.graphics.newParticleSystem(starbounceCanvas, 80)
    instance.starbouncePSystem:setParticleLifetime(0.5, 1.0)
    instance.starbouncePSystem:setEmissionRate(0)
    instance.starbouncePSystem:setSpeed(200, 325)
    instance.starbouncePSystem:setSpread(math.pi * 2)
    instance.starbouncePSystem:setLinearDamping(2, 4)
    instance.starbouncePSystem:setSizes(1.2, 0.4, 0)
    instance.starbouncePSystem:setColors(1, 1, 0.4, 0.9, 1, 1, 0.2, 0)

    return instance
end

-- render player
function Player:draw()

    local alpha = 1
    if self.invulnTimer and self.invulnTimer > 0 then
        alpha = 0.2 + 0.8 * math.abs(math.sin(love.timer.getTime() * 8))
    end

    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.draw(self.pSystem, 0, 0)
    
    if self.hp == 4 then
        self.currentImage = self.imagemint4
    elseif self.hp == 3 then
        self.currentImage = self.imagemint3
    elseif self.hp == 2 then
        self.currentImage = self.imagemint2
    elseif self.hp == 1 then
        self.currentImage = self.imagemint1
    elseif self.hp <= 0 then
        self.currentImage = self.imagemint0
    end

    local px = self.body:getX()
    local py = self.body:getY()
    local angle = self.body:getAngle()
    local iw = self.currentImage:getWidth()
    local ih = self.currentImage:getHeight()
    local radius = self.shape:getRadius()
    local scaleX = (radius*2)/iw
    local scaleY = (radius*2)/ih
    love.graphics.draw(self.currentImage,px,py,angle,scaleX,scaleY,iw/2,ih/2)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.damagePSystem, 0, 0)
    local font = love.graphics.newFont("fonts/tiny5.ttf", 36)
    love.graphics.setFont(font)
    love.graphics.print("HP: " .. self.hp .. "/" .. self.maxHP, 25, 10)

end

function Player:jump()
    local cx = self.body:getX()
    local cy = self.body:getY()
    local targetY = cy + 40
    local standingOnGround = false
    world:rayCast(cx, cy, cx, targetY, function(fixture, x, y, xn, yn, fraction)
        if fixture ~= self.fixture then
            standingOnGround = true
            return 0
        end

        return 1
    end)
    if standingOnGround then
        local vx,vy = self.body:getLinearVelocity()
        self.body:setLinearVelocity(vx, -600)
        self.canJump = false

        self.pSystem:setPosition(cx, cy)
        self.pSystem:emit(30)
    end
end

function Player:wallbounce()
    local cx = self.body:getX()
    local cy = self.body:getY()
    local targetXLeft = cx - 35
    local targetXRight = cx + 35
    local wallOnLeft = false
    local wallOnRight = false

    world:rayCast(cx, cy, targetXLeft, cy, function(fixture, x, y, xn, yn, fraction)
        if fixture ~= self.fixture then
            wallOnLeft = true
            return 0
        end

        return 1
    end)

    world:rayCast(cx, cy, targetXRight, cy, function(fixture, x, y, xn, yn, fraction)
        if fixture ~= self.fixture then
            wallOnRight = true
            return 0
        end

        return 1
    end)

    if wallOnLeft then
        local vx, vy = self.body:getLinearVelocity()
        self.body:setLinearVelocity(400, -350)

        self.starbouncePSystem:setPosition(cx, cy)
        self.starbouncePSystem:emit(30)
    elseif wallOnRight then
        local vx, vy = self.body:getLinearVelocity()
        self.body:setLinearVelocity(-400, -350)

        self.starbouncePSystem:setPosition(cx, cy)
        self.starbouncePSystem:emit(30)
    end
end

function Player:OffStageRespawn()
    if self.body:getY()>800 or self.body:getX()>1266 or self.body:getX()<-200 then

        if (not self.invulnTimer) or self.invulnTimer <= 0 then
            self.hp = self.hp - 1
            self.invulnTimer = self.invulnDuration
            self.damageParticleDelay = self.damageParticleDelayDuration

            if self.hp <= 0 then
                love.event.quit()
            end
        end

        self.body:setPosition(533, 200)

        self.body:setLinearVelocity(0, 0)
        self.body:setAngularVelocity(0)
    end
end

function Player:control(up, down, left, right, force)

    function love.keyreleased(key)
        if key == up then
            self.canJump = true
        end
    end

    if love.keyboard.isDown(left) then
        self.body:applyForce(0 - force, 0)
        self.body:applyAngularImpulse(-25,0)
    end

    if love.keyboard.isDown(right) then
        self.body:applyForce(force, 0)
        self.body:applyAngularImpulse(25,0)
    end

    if love.keyboard.isDown(up) and self.canJump then
        self:jump()
        self:wallbounce()
    end

    if love.keyboard.isDown(down) then
        self.body:applyForce(0, force*1.2)
    end
end

function Player:update(dt)

    if self.invulnTimer and self.invulnTimer > 0 then
        self.invulnTimer = math.max(0, self.invulnTimer - dt)
    end

    if self.damageParticleDelay and self.damageParticleDelay > 0 then
        self.damageParticleDelay = self.damageParticleDelay - dt
        if self.damageParticleDelay <= 0 then
            local px = self.body:getX()
            local py = self.body:getY()
            self.damagePSystem:setPosition(px, py)
            self.damagePSystem:emit(45)
        end
    end

    self.pSystem:update(dt)
    self.damagePSystem:update(dt)
    self.starbouncePSystem:update(dt)

    local px = self.body:getX()
    local py = self.body:getY()
    local vx, vy = self.body:getLinearVelocity()
    local speed = math.sqrt(vx * vx + vy * vy)

    if speed > 200 then
        self.pSystem:setPosition(px, py)
        self.pSystem:emit(1)
    end

end

return Player