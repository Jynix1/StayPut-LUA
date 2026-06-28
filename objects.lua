local object = {}
object.__index = object

function object:new(x, y, obj)
    local instance = setmetatable({}, object)
    instance.x = x
    instance.y = y
    instance.obj = obj

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

 return instance

end

function object:draw()
    if not self.newBody or not self.shape then
        return
    end

    if self.obj == "square" then
        love.graphics.setColor(1, 1, 1)
        love.graphics.setLineStyle("smooth")
        love.graphics.setLineWidth(4)
        love.graphics.polygon("line", self.newBody:getWorldPoints(self.shape:getPoints()))
    elseif self.obj == "follower" then
        love.graphics.setColor(0.8, 0.8, 1)
        love.graphics.setLineStyle("smooth")
        love.graphics.setLineWidth(8)
        love.graphics.circle("line", self.newBody:getX(), self.newBody:getY(), self.shape:getRadius())
    end
end

function object:update(dt)
    if not self.newBody or not self.shape then
        return
    end

    self.lifetime = self.lifetime - dt

    if self.lifetime <= 0 then
        if self.newBody then
            self.newBody:destroy()
        end
        self.newBody = nil
        self.shape = nil
        self.fixture = nil
        return
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