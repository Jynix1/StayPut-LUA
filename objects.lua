local object = {}
object.__index = object

function object:new(x, y, obj)
    local instance = setmetatable({}, object)
    instance.x = x
    instance.y = y
    instance.obj = obj

    if obj == "square" then
        instance.lifetime = 5

        instance.newBody = love.physics.newBody(world, x, y, "dynamic")
        instance.shape = love.physics.newRectangleShape(50, 50)
        instance.fixture = love.physics.newFixture(instance.newBody, instance.shape, 1)

        instance.newBody:setLinearDamping(0.3)
        instance.newBody:setAngularDamping(2)

    end

 return instance

end

function object:draw()
    if self.obj == "square" then
        love.graphics.setColor(1, 1, 1)
        love.graphics.polygon("fill", self.newBody:getWorldPoints(self.shape:getPoints()))
    end
end

function object:update(dt)

   self.lifetime = self.lifetime - dt

    if self.lifetime <= 0 then
         self.newBody:destroy()
           self.newBody = nil
        self.shape = nil
           self.fixture = nil
    end

end

return object