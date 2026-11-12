local otherrenders = {}

function otherrenders.drawPlayerUI() -- drawing all the player UI elements like health bar, status effects, etc
	local self = player
	local hpBar = self.hpBar or 100
	local hpBarMax = self.hpBarMax or 100
	local pct = math.max(0, math.min(1, hpBar / hpBarMax))
	local i_frame_pct = math.max(0, math.min(1, self.invulnTimer / 4))

	local barX, barY, barW, barH = 135, 40, 85, 7
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

	if self.invulnTimer and self.invulnTimer > 0 then
		love.graphics.setColor(1, 1, 1)
	else
		if self.hpBar < 30 then
			love.graphics.setColor(1, 0, 0, 1)
		else
			love.graphics.setColor(1, 1, 1, 1)
		end
	end
	love.graphics.rectangle("fill", barX, barY, fillW, barH)

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.rectangle("line", barX, barY, barW, barH)

	if self.invulnTimer > 0 then
		love.graphics.setColor(0, 0.718, 1)
		local currentW = barW * i_frame_pct
		-- Top line
		love.graphics.line(barX, barY, barX + currentW, barY)
		-- Bottom line
		love.graphics.line(barX, barY + barH, barX + currentW, barY + barH)
		-- Left tiny line
		love.graphics.line(barX, barY - 1.5, barX, barY + barH + 1.5)
	end

	local font = love.graphics.newFont("fonts/tiny5.ttf", 24)
	love.graphics.setDefaultFilter("linear")
	love.graphics.setFont(font)

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.print(tostring(math.floor(hpBar)) .. "%", barX - 2 + barW + 12, barY - 5,0,0.6,0.6)

	local font2 = love.graphics.newFont("fonts/tiny5.ttf", 32)
	love.graphics.setFont(font2)

	tx,ty = hpImg:getDimensions()
	sx,sy = 48/tx,48/ty

	love.graphics.draw(hpImg, 30, 20,0,sx,sy)

	love.graphics.print(self.hp, 97, 22,0,1.2,1.2)

	-- -- -- -- Status Effects
	if next(player.statusEffects) ~= nil then
		local font = love.graphics.newFont("fonts/tiny5.ttf", 16)
		love.graphics.setDefaultFilter("linear")
		love.graphics.setFont(font)

		local x,y = 10,200
		local width,height = 150,50
		
		for _, effect in ipairs(player.statusEffects) do
			love.graphics.setColor(0,0,0,0.5)
			love.graphics.rectangle("fill",x,y,width,height)

			love.graphics.setFont(font)
			love.graphics.setColor(1,1,1,0.75)
			love.graphics.printf(effect.name.." "..effect.level,x+10,y, width,"left")

			local dur = string.format("%.2f",effect.duration)
			love.graphics.setFont(font2)
			love.graphics.setColor(1,1,1,0.5)
			love.graphics.printf(dur,x+10,y+15,width,"left")
			y = y + 50
		end
	end

	if love.keyboard.isDown("tab") and next(RoundData.enemiesActive) ~= nil then
		local x,y,w,h = 533,300,600,400
		love.graphics.setColor(0,0,0,0.5)
		love.graphics.rectangle("fill",x - w/2, y - h/2, w,h)
		love.graphics.setColor(1,0,0,1)
		love.graphics.rectangle("line",x - w/2, y - h/2, w,h)
		for _, item in ipairs(RoundData.enemiesActive) do
			local id = item
			local title
			for _, item in ipairs(EnemyOptions) do
				if id == item.id then
					title = item.title
				end
			end
			love.graphics.setColor(1,1,1,1)
			love.graphics.printf(title,(x+15)-w/2,(y+20)-h/2,w,"left")

			y = y+35

			-- when adding more objects itll eventually go under the window, so make it go to the other side
		end
	end

	love.graphics.pop()
end

function otherrenders.drawIndicator() -- Drawing the player indicator on the screen when the player is offscreen
	local px, py = player.body:getPosition()
	local tW, tY = indicator:getDimensions()
	local screenX, screenY = cam:cameraCoords(px, py, 0, 0, gameWidth, gameHeight)

	local sX = (screenX < gameWidth / 2) and (-75 / tW) or (75 / tW)
	local sY = 75 / tY

	local ox = indicator:getWidth() / 2
	local oy = indicator:getHeight() / 2
	local offset = 65
	local indicateIMAGE = indicator

	if screenX < 0 or screenX > gameWidth or screenY < 0 or screenY > gameHeight then
		if screenY > gameHeight then
			indicateIMAGE = indicatorD
		end
		if screenY < 0 then
			indicateIMAGE = indicatorU
		end

		showIndicator = true
		ix = math.max(offset, math.min(gameWidth - offset, screenX))
		iy = math.max(offset, math.min(gameHeight - offset, screenY))
	else
		showIndicator = false
	end

	if showIndicator then
		love.graphics.setColor(1,1,1,1)
		love.graphics.draw(indicateIMAGE, ix, iy, 0, sX, sY, ox, oy)
	end
end

function otherrenders.drawFloor()
	local floorWidth = 700
	local floorHeight = 400

	local fx = floorBody:getX() - (floorWidth / 2)
	local fy = floorBody:getY() - (floorHeight / 2)

	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.rectangle("fill", fx, fy, floorWidth, floorHeight)

	love.graphics.setLineStyle("smooth")
	love.graphics.setLineWidth(2)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.rectangle("line", fx, fy, floorWidth, floorHeight)
end

return otherrenders