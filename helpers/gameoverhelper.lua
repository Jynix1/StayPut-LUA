local gameoverHelper = {}

function gameoverHelper.drawGAMEOVER(gameoverTimeAt,gameoverOptions,gameoverSelected)
	local elapsed = love.timer.getTime() - gameoverTimeAt - 1

	local rgb, alpha

	if elapsed < 2 then
		rgb = math.max(0, 1 - (elapsed / 2))
		alpha = 1
	else
		rgb = 0
		alpha = math.max(0, 1 - ((elapsed - 2) / 3))
	end

	love.graphics.setColor(1, 1, 1, 1)
	local y = 75
	love.graphics.setFont(consolefont)
	love.graphics.print("THE PLAYER HAS REACHED AN END",50,y) love.graphics.setColor(1,0,0,0.4) love.graphics.print("[ERR 0x0001; HP IS ZERO]", 575,y)
	y=y+35
	love.graphics.setColor(1, 1, 1, 0.4)
	love.graphics.print("-- SELECT AN OPTION BELOW",50,y)
	y=y+150
	for i, item in ipairs(gameoverOptions) do
		if gameoverSelected ~= i then
			love.graphics.setColor(1,1,1,0.65)
			love.graphics.print(item,80,y)
		else
			love.graphics.setColor(1,1,1,1)
			love.graphics.print("> "..item,80,y)
		end
		y = y + 35
	end
	y = 500
	if gameoverInfoShown then
		love.graphics.setColor(1,1,1,0.75)

		love.graphics.print("PLAYER RECIEVED "..AchievementData.chipDamageTaken.." CHIP DAMAGE", 75, y)
		y=y-35
		love.graphics.print("PLAYER RECIEVED "..AchievementData.damageTaken.." FULL HITS", 75, y)
		y=y-35
		love.graphics.print("PLAYER SURVIVED FOR "..math.floor(AchievementData.surviveTime).." SECONDS", 75, y)
		y=y-35
		love.graphics.print("PLAYER REACHED LEVEL "..math.floor(RoundData.level), 75, y)
	end
	love.graphics.setColor(rgb, rgb, rgb, alpha)
	love.graphics.rectangle("fill", 0, 0, 1066, 800)
end

return gameoverHelper