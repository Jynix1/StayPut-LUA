local https = require("https")
local json = require("lib/json")

local url = "https://api.github.com/repos/Jynix1/StayPut-LUA/releases/latest"
local everythingOK, status, body = pcall(https.request, url, {
	method = "GET",
	headers = {
		["User-Agent"] = "StayPutLUA",
		["Accept"] = "application/vnd.github+json",
	},
})

local updStatus = ""

if not everythingOK then
	updStatus = "HTTPS GitHub request error:" .. status
    love.thread.getChannel("result"):push(updStatus)
	return updStatus
end

if status ~= 200 then
	if status == 0 then
		updStatus = "Failed to request a check for updates. No internet?"
        love.thread.getChannel("result"):push(updStatus)
		return updStatus
	else
		updStatus = status .. " error; " .. body
        love.thread.getChannel("result"):push(updStatus)
		return updStatus
	end
end

local decodeOK, data = pcall(json.decode, body)
local latestVer = data.tag_name

if latestVer ~= GAME_VER then
	updStatus = "outdated"
elseif latestVer == GAME_VER then
	updStatus = "uptodate"
end

love.thread.getChannel("result"):push(updStatus)