local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Config = require(game:GetService("ReplicatedStorage").Modules.Config)

local DataService = {}

local store = DataStoreService:GetDataStore(Config.DataStoreName)
local cache = {} -- [userId] = data table
local dirty = {} -- [userId] = true if it needs saving

local function defaultData()
	return {
		Currency = Config.StartingCurrency,
		Luck = Config.StartingLuck,
		LuckUpgradesBought = 0,
		HighestWave = 0,
		OwnedWeapons = { [Config.StarterWeaponId] = true },
		OwnedDefenses = { [Config.StarterDefenseId] = true },
		EquippedWeapon = Config.StarterWeaponId,
		EquippedDefenses = { Config.StarterDefenseId },
	}
end

function DataService.Get(userId)
	return cache[userId]
end

function DataService.MarkDirty(userId)
	dirty[userId] = true
end

function DataService.Load(player)
	local userId = player.UserId
	local ok, result = pcall(function()
		return store:GetAsync("Player_" .. userId)
	end)

	local data
	if ok and result then
		data = result
		local defaults = defaultData()
		for key, value in pairs(defaults) do
			if data[key] == nil then
				data[key] = value
			end
		end
	else
		data = defaultData()
	end

	cache[userId] = data
	return data
end

function DataService.Save(userId)
	local data = cache[userId]
	if not data then
		return
	end

	local ok, err = pcall(function()
		store:SetAsync("Player_" .. userId, data)
	end)

	if ok then
		dirty[userId] = nil
	else
		warn(("DataService: failed to save data for %d: %s"):format(userId, tostring(err)))
	end
end

function DataService.Release(userId)
	if dirty[userId] then
		DataService.Save(userId)
	end
	cache[userId] = nil
	dirty[userId] = nil
end

function DataService.Init()
	Players.PlayerRemoving:Connect(function(player)
		DataService.Release(player.UserId)
	end)

	task.spawn(function()
		while true do
			task.wait(Config.AutosaveInterval)
			for userId in pairs(dirty) do
				DataService.Save(userId)
			end
		end
	end)

	game:BindToClose(function()
		for userId in pairs(cache) do
			DataService.Save(userId)
		end
	end)
end

return DataService
