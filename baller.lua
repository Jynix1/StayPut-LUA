local Player = {}
Player.__index = Player

-- new player
function Player.new(world, x, y)
    local instance = setmetatable({}, Player)

    instance.hp = 4
    instance.maxHP = 4
    instance.hpBar = 100
    instance.hpBarMax = 100
    instance.invulnTimer = 0
    instance.invulnDuration = 2.5
    instance.backupinvulnduration = 0.05
    instance.backupinvulntimer = 0
    instance.damageParticleDelay = 0
    instance.damageParticleDelayDuration = 1/60
    instance.maxDoubleJumps = 0
    instance.DoubleJumps = 0

    instance.isTweeningR = false

    instance.statusEffects = {}

    --[[ 
    
    instance.statusEffects = {
    
    { id = "slowness", name = "Slowness", duration = 5, level = 2 },
    
    }

    example
    ]]

    instance.hpRefill = 0
    instance.healQueue = 0
    instance.barHealQueue = 0
    instance.healTime = 0
    instance.barHealTime = 0 

    instance.body = love.physics.newBody(world, x, y, "dynamic")
    instance.radius = 25
    instance.shape = love.physics.newCircleShape(instance.radius)
    instance.fixture = love.physics.newFixture(instance.body, instance.shape, 1)
    instance.fixture:setRestitution(0.6)
    instance.fixture:setFriction(0.9)
    instance.body:setLinearDamping(1)
    instance.body:setAngularDamping(2)

    instance.fixture:setUserData({ type = "player", owner = instance })

    instance.imagemint0 = love.graphics.newImage("sprites/mint/mint0.png")
    instance.imagemint1 = love.graphics.newImage("sprites/mint/mint1.png")
    instance.imagemint2 = love.graphics.newImage("sprites/mint/mint2.png")
    instance.imagemint3 = love.graphics.newImage("sprites/mint/mint3.png")
    instance.imagemint4 = love.graphics.newImage("sprites/mint/mint4.png")
    instance.currentImage = nil
    instance.redness = 0

    instance.sfx_power = love.audio.newSource("sounds/sfx/power.mp3","static")
    instance.sfx_chipdmg = love.audio.newSource("sounds/sfx/tick.mp3","static")
    instance.sfx_chipdmg:setPitch(0.25)

    instance.sfx_dmg = love.audio.newSource("sounds/sfx/hurt.mp3","static")
    instance.dashsfx = love.audio.newSource("sounds/sfx/dash.mp3","static")
    instance.dashsfx:setPitch(1.1)
    instance.dashsfx:setVolume(0.4)

    instance.doublejumpsfx = love.audio.newSource("sounds/sfx/doublejump.mp3","static")
    instance.doublejumpsfx:setVolume(0.2 )

    instance.canJump = true
    instance.dashcolor = false
    instance.dashcooldown = 0
    instance.dashCDReduction = 0

    instance.dashDamageTimer = 0

    instance.maxwallbounceFXcd = 0.35
    instance.wallbounceFXcd = 0
    instance.hurtShakeTime = 0
    instance.hurtShakeAmount = 12
    instance.emitD = 0

    instance.moving = false

    local pCanvas = love.graphics.newCanvas(8, 8)
    pCanvas:renderTo(function()
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("fill", 4, 4, 3)
    end)

    instance.pSystem = love.graphics.newParticleSystem(pCanvas, 100)

    instance.pSystem:setParticleLifetime(0.4, 0.8) 
    instance.pSystem:setEmissionRate(0)
    instance.pSystem:setSpeed(10,20)              

    instance.pSystem:setSpread(math.pi * 2)        
    instance.pSystem:setLinearAcceleration(0, 50)

    instance.pSystem:setColors(1, 1, 1, 0.6, 1, 1, 1, 0)
    instance.pSystem:setSizes(1, 0.5, 0)

    instance.pSystem2 = love.graphics.newParticleSystem(pCanvas, 100)
    instance.pSystem2:setParticleLifetime(0.3, 0.5)
    instance.pSystem2:setEmissionRate(0)
    instance.pSystem2:setSpeed(100,120)
    instance.pSystem2:setSpread(math.pi * 2)
    instance.pSystem2:setLinearAcceleration(0, 400)

    instance.pSystem2:setColors(1, 1, 1, 0.6, 1, 1, 1, 0)
    instance.pSystem2:setSizes(1.5, 0.5, 0)
    
    local triCanvas = love.graphics.newCanvas(200, 200)
    triCanvas:renderTo(function()
        love.graphics.clear()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.polygon("fill", 0,200, 100,0, 200,200)
    end)


    instance.damagePSystem = love.graphics.newParticleSystem(triCanvas, 80)
    instance.damagePSystem:setParticleLifetime(1.5, 2)
    instance.damagePSystem:setEmissionRate(0)
    instance.damagePSystem:setSpeed(700)
    instance.damagePSystem:setSpread(math.pi * 2)
    instance.damagePSystem:setLinearDamping(5)
    instance.damagePSystem:setSizes(0.1)
    instance.damagePSystem:setSpin(15,0)
    instance.damagePSystem:setLinearAcceleration(0, 250, 0, 900)
    instance.damagePSystem:setColors(
        1, 1, 1, 1,
        1, 0, 0, 0
    )

    local starbounceCanvas = love.graphics.newCanvas(200, 200)
    starbounceCanvas:renderTo(function()
        love.graphics.clear()
        love.graphics.setColor(1, 1, 1)

        local points = {}
        local spikes = 5
        for i = 1, spikes * 2 do
            local angle = (i - 1) * math.pi / spikes
            local r = (i % 2 == 0) and 100 or 50
            points[#points + 1] = 100 + math.cos(angle) * r
            points[#points + 1] = 100 + math.sin(angle) * r
        end

    love.graphics.polygon("fill", points)
    end)

    instance.starbouncePSystem = love.graphics.newParticleSystem(starbounceCanvas, 80)
    instance.starbouncePSystem:setParticleLifetime(0.75, 1.5)
    instance.starbouncePSystem:setEmissionRate(0)
    instance.starbouncePSystem:setSpeed(350)
    instance.starbouncePSystem:setSpin(12,1)
    instance.starbouncePSystem:setSpread(math.pi/2)
    instance.starbouncePSystem:setLinearDamping(3)
    instance.starbouncePSystem:setLinearAcceleration(0,250,0,750)
    instance.starbouncePSystem:setSizes(0.135)
    instance.starbouncePSystem:setColors(1,1,1,1,1,1,1,0)
    for i = 1, 5 do
        IntroFrames[i] = love.graphics.newImage("sprites/mspawn/mspawn" .. i .. ".png")
    end

    instance.dmgfont = love.graphics.newFont("fonts/byteb.ttf",58)
    instance.damageNumbers = {}

    return instance
end

function Player:draw()--------------------------------------------------------------------------------------------------------- drawing function

    local alpha = 1
    if self.invulnTimer and self.invulnTimer > 0 then
        alpha = 0.2 + 0.8 * math.abs(math.sin(love.timer.getTime() * 10))
    end

    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.draw(self.pSystem, 0, 0)
    love.graphics.draw(self.pSystem2, 0, 0)
    love.graphics.draw(self.damagePSystem, 0, 0)
    love.graphics.draw(self.starbouncePSystem, 0, 0)

    if not IntroPlaying then
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
    else
        self.currentImage = IntroFrames[IntroFrame]
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
    love.graphics.setColor(1, 1-self.redness, 1-self.redness, alpha)
    love.graphics.draw(self.currentImage,px,py,angle,scaleX,scaleY,iw/2,ih/2)

    love.graphics.setColor(1, 1, 1, 1)

    love.graphics.setFont(self.dmgfont)
    if #self.damageNumbers > 0 then
        for _, item in ipairs(self.damageNumbers) do
            love.graphics.setColor(item.r, item.g, item.b, 1)
            love.graphics.print(item.num,item.x,item.y,0,1-item.bouncy,1+item.bouncy)
        end
    end
end

function Player:jump(force)
    local cx = self.body:getX() - 20
    local cy = self.body:getY()
    local targetY = cy + 35
    local standingOnGround = false

    for i = 1, 5 do
        local newX = cx + (i - 1) * 10

        world:rayCast(newX, cy, newX, targetY, function(fixture, x, y, xn, yn, fraction)

            if fixture == floorFixture then
                standingOnGround = true
                return 0
            end

            return 1
        end)
    end

    targetY = cy + 30
    cx = self.body:getX() - 10
    local hitBody = nil
    local hitBodyX, hitBodyY = 0, 0

    for i = 1, 5 do
        local newX = cx + (i - 1) * 5

        world:rayCast(newX, cy, newX, targetY, function(fixture, x, y, xn, yn, fraction)

            if fixture ~= self.fixture and not fixture:isSensor() then
                standingOnGround = true
                hitBody = fixture:getBody()
                if hitBody:getType() == "dynamic" then
                    hitBody:applyLinearImpulse(0, force*0.35)
                end
                return 0
            end

            return 1
        end)
    end

    if hitBody then
        hitBodyX, hitBodyY = hitBody:getLinearVelocity()
    end

    if standingOnGround then
        local vx,vy = self.body:getLinearVelocity()
        self.body:setLinearVelocity(vx, (-force*1.13) + (hitBodyY * 0.25))
        self.canJump = false

        self.pSystem2:setPosition(cx+15, cy+25)
        self.pSystem2:emit(30)
    else
        if self.DoubleJumps > 0 then
            local vx,vy = self.body:getLinearVelocity()
            self.body:setLinearVelocity(vx, -force*1.12)
            self.DoubleJumps = self.DoubleJumps - 1
            self.canJump = false
            self.doublejumpsfx:clone():play()

            self.pSystem2:setPosition(cx+15, cy+25)
            self.pSystem2:emit(30)
        end
    end
end

function Player:dash(dx, dy, force)
    if self.dashcooldown > 0 then
        return
    end

    local vx, vy = self.body:getLinearVelocity()

    if dx == 0 and dy == 0 then
        -- fallback to current movement direction

        dx, dy = vx, vy
        if dx == 0 and dy == 0 then
            return
        end
    end

    local length = math.sqrt(dx * dx + dy * dy)
    dx = dx / length
    dy = dy / length
    local dashangle = math.atan2(dy,dx)

    local dashSpeed = force * 1.8

    self.dashsfx:clone():play()

    self.body:setLinearVelocity((vx/2) + dx * dashSpeed,(vy/2) + dy * dashSpeed)

    self.dashcooldown = 2.5 - (self.dashCDReduction)
    self.dashDamageTimer = 0.5
    self.starbouncePSystem:setPosition(self.body:getX(), self.body:getY())
    self.starbouncePSystem:setDirection(dashangle-math.pi)
    self.starbouncePSystem:emit(5)
end

function Player:wallbounce(force)
    local cx,cy = self.body:getPosition()
    local vx,vy = self.body:getLinearVelocity()
    local targetXLeft,targetXRight = cx - 35,cx + 35
    local wallOnLeft,wallOnRight = false,false

    -- check wall on the left
    world:rayCast(cx, cy, targetXLeft, cy, function(fixture, x, y, xn, yn, fraction)
        if fixture ~= self.fixture and not fixture:isSensor() then
            local body = fixture:getBody()
            local hitforce = -math.abs(vx/2+force/4)

            wallOnLeft = true
            body:applyLinearImpulse(hitforce,0)
            return 0
        end

        return 1
    end)

    -- check wall on the right
    world:rayCast(cx, cy, targetXRight, cy, function(fixture, x, y, xn, yn, fraction)
        if fixture ~= self.fixture and not fixture:isSensor() then
            local body = fixture:getBody()
            local hitforce = math.abs(vx/2+force/4)

            wallOnRight = true
            body:applyLinearImpulse(hitforce,0)
            return 0
        end

        return 1
    end)

    if wallOnLeft then
        self.body:setLinearVelocity(force/1.3, -force/1.95)

        if self.wallbounceFXcd <= 0 then
            self.starbouncePSystem:setPosition(cx, cy)
            self.starbouncePSystem:setDirection(-math.pi)
            self.starbouncePSystem:emit(3)
            self.wallbounceFXcd = self.maxwallbounceFXcd
        end
    elseif wallOnRight then
        self.body:setLinearVelocity(-force/1.3, -force/1.95)

        if self.wallbounceFXcd <= 0 then
            self.starbouncePSystem:setPosition(cx, cy)
            self.starbouncePSystem:setDirection(0)
            self.starbouncePSystem:emit(3)
            self.wallbounceFXcd = self.maxwallbounceFXcd
        end
    end
end

function Player:resetDoubleJumps()

    local cx = self.body:getX() - 20
    local cy = self.body:getY()
    local targetY = cy + 35
    local standingOnGround = false

    for i = 1, 5 do
        local newX = cx + (i - 1) * 10

        world:rayCast(newX, cy, newX, targetY, function(fixture, x, y, xn, yn, fraction)

            if fixture == floorFixture then
                standingOnGround = true
                return 0
            end

            return 1
        end)
    end

    targetY = cy + 30
    cx = self.body:getX() - 10

    for i = 1, 5 do
        local newX = cx + (i - 1) * 5

        world:rayCast(newX, cy, newX, targetY, function(fixture, x, y, xn, yn, fraction)

            if fixture ~= self.fixture and not fixture:isSensor() then
                standingOnGround = true
                return 0
            end

            return 1
        end)
    end

    if standingOnGround then
        self.DoubleJumps = self.maxDoubleJumps
    end
end

function Player:OffStageRespawn()
    local deathradius = 300
    if self.body:getY()>800 or self.body:getX()>1066+deathradius or self.body:getX() < -deathradius then

        if self.isTweeningR then return end
        self.isTweeningR = true

        self:TakeDamage(1)

        self.body:setLinearVelocity(0, 0)
        self.body:setAngularVelocity(0)
        self.fixture:setSensor(true)

        local pxy = {x = self.body:getX(), y = self.body:getY()}

        Flux.to(pxy, 0.75, {x = 533, y = 200}):ease("backout")
        :onupdate(function()
            self.body:setPosition(pxy.x,pxy.y)
        end)
        :oncomplete(function()
            self.body:setLinearVelocity(0, 0)
            self.body:setAngularVelocity(0)
            self.fixture:setSensor(false)

            self.isTweeningR = false
        end)
        -- self.body:setPosition(533, 200)
    end
end

function Player:TakeDamage(amount)

    if self.invulnTimer and self.invulnTimer > 0 then
        return
    end

    self.redness = 1

    self.hpRefill = 3
    self.hp = self.hp - amount
    AchievementData.damageTaken = AchievementData.damageTaken + amount
    self.invulnTimer = self.invulnDuration
    self.damageParticleDelay = self.damageParticleDelayDuration
    self.hurtShakeTime = 0.12
    self.sfx_dmg:clone():play()

    if self.hp <= 0 then
        GAMEOVER = true  ------------------------------------------------------ death event
    end
    
end

function Player:takeBarDamage(amount)
    if self.backupinvulntimer and self.backupinvulntimer > 0 then
        return
    end
    if self.invulnTimer and self.invulnTimer > 0 then
        return
    end

    local vulnerable = 0
    for _, effect in ipairs(self.statusEffects) do
        if effect.id == "vulnerable" then
            vulnerable = vulnerable + effect.level
        end
    end

    local finalamount = amount * (1 + vulnerable/10)

    self.hpBar = math.max(0, self.hpBar - finalamount)
    AchievementData.chipDamageTaken = AchievementData.chipDamageTaken + amount
    self.backupinvulntimer = self.backupinvulnduration
    self.hurtShakeTime = 0.12

    if self.hpBar <= 0 then

        self:TakeDamage(1)

        self.damageParticleDelay = self.damageParticleDelayDuration
        self.hpBar = self.hpBarMax

    else
        self.sfx_chipdmg:clone():play()
    end

    local x,y = self.body:getPosition()
    self:spawndmgnum(finalamount,3,x+20,y-20,1,1)
    
    if self.hp <= 0 then
        GAMEOVER = true  ------------------------------------------------------ death event
    end
end

function Player:control(up, down, left, right, dash, force)                        -------------------------------------------- player control

    local slowness = 0
    for _, effect in ipairs(self.statusEffects) do
        if effect.id == "slowness" then
            slowness = slowness + effect.level
        end
    end

    oldForce = force
    force = math.max(0,(force * self.fixture:getDensity()) * (1 - slowness/10))

    if love.keyboard.isDown(up) or love.keyboard.isDown(down) or love.keyboard.isDown(left) or love.keyboard.isDown(right) or love.keyboard.isDown(dash) then
        self.moving = true
    else
        self.moving = false
    end

    function love.keyreleased(key)
        if key == up then
            self.canJump = true
        end
    end

    if love.keyboard.isDown(left) then
        self.body:applyForce(-force, 0)
        self.body:applyAngularImpulse(-25,0)
    end

    if love.keyboard.isDown(right) then
        self.body:applyForce(force, 0)
        self.body:applyAngularImpulse(25,0)
    end

    if love.keyboard.isDown(up) and self.canJump then
        self:wallbounce(oldForce)
        self:jump(oldForce)
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
        self:dash(dx,dy,oldForce)
    end
end

function Player:Heal(H,B)

    if H > 0 and self.hp < 4 then
        self.sfx_power:clone():play()    
    end

    self.hp = math.min(4,math.max(0,self.hp + H))
    self.hpBar = math.min(100,math.max(0,self.hpBar + B))

end

function Player:QueueHeal(H,giveInvuln,recoverBar)

    self.healQueue = self.healQueue + H
    self.barHealQueue = self.barHealQueue + recoverBar

    self.invulnTimer = giveInvuln

end

function Player:update(dt)                                                     --------------------------------------------------- Player Update

    local extraJumps = 0
    local extraDensity = 0
    local lessDashCD = 0
    for _, upgrade in ipairs(RoundData.upgradesActive) do
        if upgrade == "DoubleJump" then
            extraJumps = extraJumps + 1
        end
        if upgrade == "DoubleJump2" then
            extraJumps = extraJumps + 1
        end
        if upgrade == "DensityUp" then
            extraDensity = extraDensity + 0.5
        end
        if upgrade == "DensityUp2" then
            extraDensity = extraDensity + 0.5
        end
        if upgrade == "DashCDDown" then
            lessDashCD = lessDashCD + 0.55
        end
        if upgrade == "DashCDDown2" then
            lessDashCD = lessDashCD + 0.55
        end
    end

    self.redness = math.min(1,math.max(0,self.redness - dt))

    local targetDensity = 1 + extraDensity
    local currentDensity = self.fixture:getDensity()
    if currentDensity ~= targetDensity then
        self.fixture:setDensity(targetDensity)
        self.body:resetMassData()
    end

    self.maxDoubleJumps = extraJumps
    self:resetDoubleJumps()
    self.dashCDReduction = lessDashCD
    
    self.dashDamageTimer = math.max(0, self.dashDamageTimer - dt)

    if self.dashDamageTimer > 0 then
        for _, boss in ipairs(bosses) do
            if boss and boss.newBody and boss.fixture then
                local bx, by = boss.newBody:getPosition()
                local px, py = self.body:getPosition()

                local vx, vy = self.body:getLinearVelocity()
                local spd = math.sqrt(vx * vx + vy * vy)

                local distance = math.sqrt((bx - px)^2 + (by - py)^2)
                if distance <= (self.radius + boss.size + 4) then
                    local damage = 2 + math.floor(spd * 0.025 + 15-(self.dashDamageTimer*30))
                    boss:takeDamage(damage)
                    self:spawndmgnum(damage,3,bx,by,1,1,{1, 0, 0})
                    self.dashDamageTimer = 0
                    break
                end
            end
        end
    end

    self.dashcooldown = math.max(0, self.dashcooldown - dt)

    self.wallbounceFXcd = math.max(0, self.wallbounceFXcd - dt)

    self.invulnTimer = math.max(0, self.invulnTimer - dt)

    self.backupinvulntimer = math.max(0, self.backupinvulntimer - dt)

    if self.healQueue > 0 then
        self.healTime = self.healTime - dt
        if self.healTime <= 0 then
            self.healTime = 1
            self:Heal(1,0)
            self.healQueue = self.healQueue - 1
        end
    end

    if self.barHealQueue > 0 then
        self.barHealTime = self.barHealTime - dt
        if self.barHealTime <= 0 then
            self.barHealTime = 0.04
            self:Heal(0,1)
            self.barHealQueue = self.barHealQueue - 1
        end
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
    self.pSystem2:update(dt)
    self.damagePSystem:update(dt)
    self.starbouncePSystem:update(dt)

    if next(self.statusEffects) ~= nil then
        for i = #self.statusEffects, 1, -1 do
            local effect = self.statusEffects[i]
            effect.duration = effect.duration - dt
            if effect.duration < 0 then
                table.remove(self.statusEffects,i)
            end
        end
    end

    local px = self.body:getX()
    local py = self.body:getY()
    local vx, vy = self.body:getLinearVelocity()
    local speed = math.sqrt(vx * vx + vy * vy)

    if speed > 200 then
        if self.emitD <= 0 then
            self.pSystem:setPosition(px, py)
            self.pSystem:emit(1)
            self.emitD = 0.05
        end
        self.emitD = self.emitD - dt
    end

    if self.hpBar < 100 and RoundData.ongoing then
       self.hpRefill = self.hpRefill + dt
       if self.hpRefill >= 1.5 then
           self.hpBar = math.min(self.hpBarMax, self.hpBar + 1)
           self.hpRefill = 0
       end 
    end

    for i = #self.damageNumbers, 1, -1 do
        local item = self.damageNumbers[i]
        
        item.x = item.x + item.vx*dt
        item.y = item.y + item.vy*dt
        item.vx = item.vx * (1 - 4*dt)
        item.bouncy = item.bouncy * (1 - 4*dt)

        item.vy = item.vy + (1500*dt)
        if item.y >= item.spawnY then
            if item.bounces > 0 then
                item.vy = item.spawnvy*(item.bounces/item.spawnbounces)
                item.bounces = item.bounces - 1
            else
                item.vy = 0
            end
        end

        item.lifetime = item.lifetime - dt
        if item.lifetime <= 0 then
            table.remove(self.damageNumbers,i)
        end
    end
end

function Player:spawndmgnum(num,lifetime,x,spawnY,sx,sy,color)
    local rgb = color or {1, 1, 1}
    table.insert(self.damageNumbers, {
        num = num or 0,
        lifetime = lifetime or 3,
        x = x or 0,
        spawnY = spawnY or 0,
        y = spawnY,
        sx = sx or 1,
        sy = sy or 1,
        vx = 350,
        spawnvy = -350,
        vy = -400,
        spawnbounces = 3,
        bounces = 3,
        bouncy = 1,
        r = rgb[1] or 1,
        g = rgb[2] or 1,
        b = rgb[3] or 1,
    })
end

function Player:GG()
    if self.body and not self.body:isDestroyed() then
        self.body:destroy()
        self.body = nil
    end
end

return Player