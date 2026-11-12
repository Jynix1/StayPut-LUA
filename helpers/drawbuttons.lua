local drawButtons = {}

function drawButtons.drawChoiceButtons()
	for i, btn in ipairs(ChoiceButtons) do
		local designY = btn.y + math.sin(love.timer.getTime()) * 10
		local btnY = designY + 50
		local mx, my = getVirtualMousePosition(love.mouse.getPosition())

		if
			mx < btn.x + btn.width
			and mx > btn.x
			and my < btn.y + btn.height
			and my > btn.y
			and btn.title ~= "No Option"
			and gameRunning
		then
			love.graphics.setColor(1, 0, 0, 0.15)
		else
			love.graphics.setColor(0, 0, 0, 0.5)
		end

		love.graphics.rectangle("fill", btn.x, designY, btn.width, btn.height)

		love.graphics.setColor(1, 0, 0)
		love.graphics.setLineWidth(2)
		love.graphics.rectangle("line", btn.x, designY, btn.width, btn.height)
		love.graphics.line(btn.x, btnY, btn.x + btn.width, btnY)

		love.graphics.setFont(tobyfont)
		love.graphics.setColor(1, 1, 1)
		love.graphics.printf(btn.title, btn.x, designY + 5, btn.width, "center")

		love.graphics.setFont(toby2font)
		love.graphics.printf(btn.desc, btn.x + 10, designY + 60, btn.width - 20, "left")
	end
end

function drawButtons.drawUpgradeChoiceButtons()
	for i, btn in ipairs(UpgradeChoiceButtons) do
		local designY = btn.y + math.sin(love.timer.getTime()) * 10
		local btnY = designY + 50
		local mx, my = getVirtualMousePosition(love.mouse.getPosition())

		if
			mx < btn.x + btn.width
			and mx > btn.x
			and my < btn.y + btn.height
			and my > btn.y
			and btn.title ~= "No Option"
			and gameRunning
		then
			love.graphics.setColor(0, 0.8, 1, 0.15)
		else
			love.graphics.setColor(0, 0, 0, 0.5)
		end

		love.graphics.rectangle("fill", btn.x, designY, btn.width, btn.height)

		love.graphics.setColor(0, 0.8, 1)
		love.graphics.setLineWidth(2)
		love.graphics.rectangle("line", btn.x, designY, btn.width, btn.height)
		love.graphics.line(btn.x, btnY, btn.x + btn.width, btnY)

		love.graphics.setFont(tobyfont)
		love.graphics.setColor(1, 1, 1)
		love.graphics.printf(btn.title, btn.x, designY + 5, btn.width, "center")

		love.graphics.setFont(toby2font)
		love.graphics.printf(btn.desc, btn.x + 10, designY + 60, btn.width - 20, "left")
	end
end

return drawButtons