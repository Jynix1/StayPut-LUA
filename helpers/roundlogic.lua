local roundlogic = {}

function roundlogic.roundUpdate(dt,object)
    if RoundData.ongoing and not GAMEOVER then -- round stuff including timer, spawning objs, etc
        RoundData.time = RoundData.time - dt
        RoundData.spawnTimer = RoundData.spawnTimer - dt
        if player.hp > 0 then
            AchievementData.surviveTime = AchievementData.surviveTime + dt
        end

        if RoundData.spawnTimer <= 0 then -- spawn now
            if #RoundData.enemiesActive > 0 then
                local random = love.math.random(1, #RoundData.enemiesActive)
                local enemyIdToSpawn = RoundData.enemiesActive[random]
                local tripwireExists = false

                if enemyIdToSpawn == "tripwire" then -- anti stopwire
                    if objects and #objects > 0 then
                        for _, obj in ipairs(objects) do
                            if obj.obj == "tripwire" then
                                tripwireExists = true
                            end
                        end
                    end
                end

                if tripwireExists then -- anti stopwire
                    repeat
                        random = love.math.random(1, #RoundData.enemiesActive)
                        enemyIdToSpawn = RoundData.enemiesActive[random]
                    until enemyIdToSpawn ~= "tripwire"
                end

                if --make sure annoying enemies don't spawn twice in a row, if there are other enemies to spawn
                    lastEnemy ~= nil
                    and lastEnemy == "tripwire"
                    and enemyIdToSpawn == "tripwire"
                    and #RoundData.enemiesActive > 1
                then
                    repeat
                        random = love.math.random(1, #RoundData.enemiesActive)
                        enemyIdToSpawn = RoundData.enemiesActive[random]
                    until enemyIdToSpawn ~= "tripwire"
                end

                if --make sure annoying enemies don't spawn twice in a row, if there are other enemies to spawn
                    lastEnemy ~= nil
                    and lastEnemy == "musicbox"
                    and enemyIdToSpawn == "musicbox"
                    and #RoundData.enemiesActive > 1
                then
                    repeat
                        random = love.math.random(1, #RoundData.enemiesActive)
                        enemyIdToSpawn = RoundData.enemiesActive[random]
                    until enemyIdToSpawn ~= "musicbox"
                end

                lastEnemy = enemyIdToSpawn

                local spawnX = love.math.random(200, 866)

                local enemyCD = 0
                for _, option in ipairs(EnemyOptions) do -- get enemy's added spawn cd and add it to the TBO timer
                    if option.id == enemyIdToSpawn then
                        enemyCD = option.cd or 0
                    end
                end

                local newEnemy = object:new(spawnX, -100, enemyIdToSpawn)
                table.insert(objects, newEnemy)
                RoundData.spawnTimer = RoundData.difficultyTBO + enemyCD
            end
        end
    end
end

function roundlogic.onRoundEnd()
    local result = nil

    RoundData.ongoing = false

    clearAllObjects()
    greenFlashAlpha = 0.5

    RoundData.level = RoundData.level + 1
    RoundData.starttime = RoundData.starttime + 3
    RoundData.time = RoundData.starttime
    RoundData.difficultyTBO = RoundData.difficultyTBO - 0.2

    if RoundData.level % 10 == 0 and RoundData.level ~= 0 then
        RoundData.upgradePicker = true
        result = "upgrade"
    elseif RoundData.level % 2 == 0 or RoundData.level == 1 then
        RoundData.enemyPicker = true
        result = "enemy"
    else
        RoundData.ongoing = true
        result = "continue"
    end

    player:QueueHeal(2, 4, 50)
    if player.hpBar < 100 then
        barRecoverSound:play()
    end

    return result
end

return roundlogic
