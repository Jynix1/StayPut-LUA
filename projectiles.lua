local Projectile = {}
Projectile.__index = Projectile

function Projectile.new(world, x, y, direction, type)
    local self = setmetatable({}, Projectile)

    self.x = x
    self.y = y
    self.type = type
    self.hasHit = false -- Track if it's already hit the player

    if type == "bullet" then
        self.speed = 350
        self.damage = 19
        self.lifetime = 3
        self.shape = "circle"
        self.radius = 5
        
        -- Create kinematic body (unaffected by gravity/forces)
        self.body = love.physics.newBody(world, x, y, "kinematic")
        self.fixture = love.physics.newFixture(self.body, love.physics.newCircleShape(self.radius), 1)
        self.fixture:setUserData({ type = "projectile", owner = self })
        self.fixture:setSensor(true) -- Make it a sensor so it doesn't collide physically
        
        -- Convert direction angle to velocity components
        local vx = self.speed * math.cos(direction)
        local vy = self.speed * math.sin(direction)
        self.body:setLinearVelocity(vx, vy)
    end
    if type == "big" then ----------------------------------------------------------------------------- requires testing
        self.speed = 150
        self.damage = 50
        self.lifetime = 8
        self.shape = "circle"
        self.radius = 25
        
        -- Create kinematic body (unaffected by gravity/forces)
        self.body = love.physics.newBody(world, x, y, "kinematic")
        self.fixture = love.physics.newFixture(self.body, love.physics.newCircleShape(self.radius), 1)
        self.fixture:setUserData({ type = "projectile", owner = self })
        self.fixture:setSensor(true) -- Make it a sensor so it doesn't collide physically
        
        -- Convert direction angle to velocity components
        local vx = self.speed * math.cos(direction)
        local vy = self.speed * math.sin(direction)
        self.body:setLinearVelocity(vx, vy)
    end

    return self
end

function Projectile:update(dt)
    if not self.body then return end

    -- Decrease lifetime
    self.lifetime = self.lifetime - dt

    -- Check collision with player
    if player and not self.hasHit then -- Fix Collision check cuz it should stop when  it hits an object
        local dx = player.body:getX() - self.body:getX()
        local dy = player.body:getY() - self.body:getY()
        local distance = math.sqrt(dx * dx + dy * dy)
        
        if distance < (30 + self.radius) then
            self:onHitPlayer()
        end
    end
end

function Projectile:onHitPlayer()
    player:takeBarDamage(self.damage)
    self.hasHit = true
    self.lifetime = 0
end

function Projectile:draw()
    if self.shape == "circle" then
        love.graphics.setColor(1, 0, 0)
        love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.radius)
    end
end

return Projectile