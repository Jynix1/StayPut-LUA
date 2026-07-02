local Player = {}
Player.__index = Player

-- debug ray visualization (temporary)
local debugRays = {}
local debugRayEnabled = false
local function addDebugRay(x1,y1,x2,y2, hitX,hitY, nx,ny, ttl)
    if not debugRayEnabled then return end
    ttl = ttl or 0.12
    table.insert(debugRays, {x1=x1,y1=y1,x2=x2,y2=y2, hitX=hitX, hitY=hitY, nx=nx, ny=ny, t=love.timer.getTime(), ttl=ttl})
end

-- new player
function Player.new(world, x, y)
    local instance = setmetatable({}, Player)

    instance.hp = 4
    instance.maxHP = 4
    instance.hpBar = 100
    instance.hpBarMax = 100
    instance.invulnTimer = 0        -- seconds left of i-frames
    instance.invulnDuration = 3 
    instance.backupinvulnduration = 0.05
    instance.backupinvulntimer = 0
    instance.damageParticleDelay = 0
    instance.damageParticleDelayDuration = 1/60
    instance.hpRefill = 0

    instance.body = love.physics.newBody(world, x, y, "dynamic")
    instance.shape = love.physics.newCircleShape(25)
    instance.fixture = love.physics.newFixture(instance.body, instance.shape, 1)
    instance.fixture:setRestitution(0.6)
    instance.fixture:setFriction(0.9)
    instance.body:setLinearDamping(0.3)
    instance.body:setAngularDamping(2)

    instance.fixture:setUserData({ type = "player", owner = instance })

    instance.imagemint0 = love.graphics.newImage("sprites/mint/mint0.png")
    instance.imagemint1 = love.graphics.newImage("sprites/mint/mint1.png")
    instance.imagemint2 = love.graphics.newImage("sprites/mint/mint2.png")
    instance.imagemint3 = love.graphics.newImage("sprites/mint/mint3.png")
    instance.imagemint4 = love.graphics.newImage("sprites/mint/mint4.png")
    instance.currentImage = nil

    instance.canJump = true
    instance.dashcolor = false
    instance.dashcooldown = 0
    instance.hurtShakeTime = 0
    instance.hurtShakeAmount = 6
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
        love.graphics.setColor(0.169, 0, 1)

        local points = {}
        local spikes = 5
        for i = 1, spikes * 2 do
            local angle = (i - 1) * math.pi / spikes
            local r = (i % 2 == 0) and 10 or 5
            points[#points + 1] = 12 + math.cos(angle) * r
            points[#points + 1] = 12 + math.sin(angle) * r
        end

    love.graphics.polygon("fill", points)
    end)

    instance.starbouncePSystem = love.graphics.newParticleSystem(starbounceCanvas, 80)
    instance.starbouncePSystem:setParticleLifetime(0.5, 1.0)
    instance.starbouncePSystem:setEmissionRate(0)
    instance.starbouncePSystem:setSpeed(350, 420)
    instance.starbouncePSystem:setSpread(math.pi * 2)
    instance.starbouncePSystem:setLinearDamping(2, 4)
    instance.starbouncePSystem:setSizes(2.2, 1.4, 0)
    instance.starbouncePSystem:setColors(1, 1, 0.4, 0.9, 1, 1, 0.2, 0)

    return instance
end

-- render player
function Player:draw()--------------------------------------------------------------------------------------------------------- DRAW function

    local alpha = 1
    if self.invulnTimer and self.invulnTimer > 0 then
        alpha = 0.2 + 0.8 * math.abs(math.sin(love.timer.getTime() * 10))
    end

    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.draw(self.pSystem, 0, 0)
    love.graphics.draw(self.damagePSystem, 0, 0)
    love.graphics.draw(self.starbouncePSystem, 0, 0)
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

    -- dash outline
    if self.dashcooldown and self.dashcooldown > 0 then
        local ratio = self.dashcooldown / 2.5
        local alpha2 = 0.8 - ratio
        local outlineRadius = radius + ratio * 100

        love.graphics.setColor(0.9, 0.9, 1, alpha2)
        love.graphics.setLineWidth(6)
        love.graphics.circle("line", px, py, outlineRadius-5)
    end
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.draw(self.currentImage,px,py,angle,scaleX,scaleY,iw/2,ih/2)

    love.graphics.setColor(1, 1, 1, 1)

    -- debug ray visualization
    if debugRayEnabled then
        for _, r in ipairs(debugRays) do
            local age = love.timer.getTime() - r.t
            local a = 1 - (age / r.ttl)
            a = math.max(0, math.min(1, a))
            love.graphics.setColor(1, 0, 0, a)
            love.graphics.setLineWidth(2)
            love.graphics.line(r.x1, r.y1, r.x2, r.y2)
            if r.hitX then
                love.graphics.setColor(1, 1, 0, a)
                love.graphics.circle("fill", r.hitX, r.hitY, 3)
                if r.nx and r.ny then
                    love.graphics.setColor(0, 1, 0, a)
                    love.graphics.line(r.hitX, r.hitY, r.hitX + r.nx * 12, r.hitY + r.ny * 12)
                end
            end
        end
        love.graphics.setColor(1,1,1,1)
    end

    self:HPbarDraw()

end

function Player:jump()
    local cx = self.body:getX() - 20
    local cy = self.body:getY()
    local targetY = cy + 40
    local standingOnGround = false

    for i = 1, 5 do
        local newX = cx + (i - 1) * 10

        -- draw tentative ray (will be overwritten with hit info if any)
        addDebugRay(newX, cy, newX, targetY, nil, nil, nil, nil, 0.12)

        world:rayCast(newX, cy, newX, targetY, function(fixture, x, y, xn, yn, fraction)
            if fixture ~= self.fixture then
                standingOnGround = true
                -- record hit for visualization
                addDebugRay(newX, cy, newX, targetY, x, y, xn, yn, 1.2)
                return 0
            end

            return 1
        end)
    end

    if standingOnGround then
        local vx,vy = self.body:getLinearVelocity()
        self.body:setLinearVelocity(vx, -600)
        self.canJump = false

        self.pSystem:setPosition(cx, cy)
        self.pSystem:emit(30)
    end
end

function Player:dash(dx, dy)
    if self.dashcooldown > 0 then
        return
    end

    if dx == 0 and dy == 0 then
        -- fallback to current movement direction
        local vx, vy = self.body:getLinearVelocity()
        dx, dy = vx, vy
        if dx == 0 and dy == 0 then
            return
        end
    end

    local length = math.sqrt(dx * dx + dy * dy)
    dx = dx / length
    dy = dy / length

    local dashSpeed = 900
    self.body:setLinearVelocity(dx * dashSpeed, dy * dashSpeed)
    self.dashcooldown = 2.5
    self.starbouncePSystem:setPosition(self.body:getX(), self.body:getY())
    self.starbouncePSystem:emit(10)
end

function Player:wallbounce()
    local cx = self.body:getX()
    local cy = self.body:getY()
    local targetXLeft = cx - 35
    local targetXRight = cx + 35
    local wallOnLeft = false
    local wallOnRight = false
    addDebugRay(cx, cy, targetXLeft, cy, nil, nil, nil, nil, 0.12)
    world:rayCast(cx, cy, targetXLeft, cy, function(fixture, x, y, xn, yn, fraction)
        if fixture ~= self.fixture then
            wallOnLeft = true
            addDebugRay(cx, cy, targetXLeft, cy, x, y, xn, yn, 1.2)
            return 0
        end

        return 1
    end)
    addDebugRay(cx, cy, targetXRight, cy, nil, nil, nil, nil, 0.12)
    world:rayCast(cx, cy, targetXRight, cy, function(fixture, x, y, xn, yn, fraction)
        if fixture ~= self.fixture then
            wallOnRight = true
            addDebugRay(cx, cy, targetXRight, cy, x, y, xn, yn, 1.2)
            return 0
        end

        return 1
    end)

    if wallOnLeft then
        local vx, vy = self.body:getLinearVelocity()
        self.body:setLinearVelocity(450, -350)

        self.starbouncePSystem:setPosition(cx, cy)
        self.starbouncePSystem:emit(3)
    elseif wallOnRight then
        local vx, vy = self.body:getLinearVelocity()
        self.body:setLinearVelocity(-450, -350)

        self.starbouncePSystem:setPosition(cx, cy)
        self.starbouncePSystem:emit(3)
    end
end

function Player:OffStageRespawn()
    if self.body:getY()>800 or self.body:getX()>1266 or self.body:getX()<-200 then

        self:TakeDamage(1)

        self.body:setPosition(533, 200)

        self.body:setLinearVelocity(0, 0)
        self.body:setAngularVelocity(0)
    end
end

function Player:TakeDamage(amount)
    if self.invulnTimer and self.invulnTimer > 0 then
        return
    end

    self.hp = self.hp - 1
    self.invulnTimer = self.invulnDuration
    self.damageParticleDelay = self.damageParticleDelayDuration
    self.hurtShakeTime = 0.12
    
    if self.hp <= 0 then
        love.event.quit()  ------------------------------------------------------ death event
    end
    
end

function Player:takeBarDamage(amount)
    if self.backupinvulntimer and self.backupinvulntimer > 0 then
        return
    end
    if self.invulnTimer and self.invulnTimer > 0 then
        return
    end

    self.hpBar = math.max(0, self.hpBar - amount)
    self.backupinvulntimer = self.backupinvulnduration
    self.hurtShakeTime = 0.12

    if self.hpBar <= 0 then

        self:TakeDamage(1)

        self.damageParticleDelay = self.damageParticleDelayDuration
        self.hpBar = self.hpBarMax
    end
end

function Player:control(up, down, left, right, dash, force)                         -------------------------------------------- player control

    function love.keyreleased(key)
        if key == up then
            self.canJump = true
        end
        if key == "f3" then
            debugRayEnabled = not debugRayEnabled
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
        self.body:applyForce(0, force*2)
    end

    if love.keyboard.isDown(dash) then
        local dx, dy = 0, 0
        if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
            dx = dx - 1
        end
        if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
            dx = dx + 1
        end
        if love.keyboard.isDown("w") or love.keyboard.isDown("up") then
            dy = dy - 1
        end
        if love.keyboard.isDown("s") or love.keyboard.isDown("down") then
            dy = dy + 1
        end
        self:dash(dx,dy)
    end
end

function Player:update(dt)                                                     --------------------------------------------------- Player Update

    if self.dashcooldown > 0 then
        self.dashcooldown = math.max(0, self.dashcooldown - dt)
    end

    if self.invulnTimer > 0 then
        self.invulnTimer = math.max(0, self.invulnTimer - dt)
    end

    if self.backupinvulntimer > 0 then
        self.backupinvulntimer = math.max(0, self.backupinvulntimer - dt)
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

    if self.hurtShakeTime and self.hurtShakeTime > 0 then
        self.hurtShakeTime = math.max(0, self.hurtShakeTime - dt)
    end

    self.pSystem:update(dt)
    self.damagePSystem:update(dt)
    self.starbouncePSystem:update(dt)

    -- prune debug rays
    local now = love.timer.getTime()
    for i = #debugRays, 1, -1 do
        if now - debugRays[i].t > debugRays[i].ttl then
            table.remove(debugRays, i)
        end
    end

    local px = self.body:getX()
    local py = self.body:getY()
    local vx, vy = self.body:getLinearVelocity()
    local speed = math.sqrt(vx * vx + vy * vy)

    if speed > 200 then
        self.pSystem:setPosition(px, py)
        self.pSystem:emit(1)
    end

    if self.hpBar < 100 then
       self.hpRefill = self.hpRefill + dt
       if self.hpRefill >= 1.5 then
           self.hpBar = math.min(self.hpBarMax, self.hpBar + 1)
           self.hpRefill = 0
       end 
    end
end

function Player:HPbarDraw()
    local hpBar = self.hpBar or 100
    local hpBarMax = self.hpBarMax or 100
    local pct = math.max(0, math.min(1, hpBar / hpBarMax))

    local barX, barY, barW, barH = 25, 60, 200, 18
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

    love.graphics.setColor(1, 0.2 * (1 - pct), 0.2)
    love.graphics.rectangle("fill", barX, barY, fillW, barH)

    if self.invulnTimer and self.invulnTimer > 0 then
        love.graphics.setColor(0, 0.882, 1)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
    love.graphics.rectangle("line", barX, barY, barW, barH)

    local font = love.graphics.newFont("fonts/tiny5.ttf", 30)
    love.graphics.setFont(font)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(tostring(math.floor(hpBar)) .. "%", barX + barW + 12, barY - 8)


    font = love.graphics.newFont("fonts/tiny5.ttf", 36)
    love.graphics.setFont(font)

    love.graphics.print("HP: " .. (self.hp or 0) .. "/" .. (self.maxHP or 4), 35, 10)

    love.graphics.pop()
end

return Player