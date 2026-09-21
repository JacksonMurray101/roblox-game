local Config = require(game:GetService("ReplicatedStorage").Modules.Config)
local WheelData = require(game:GetService("ReplicatedStorage").Modules.WheelData)

local DataService = require(script.Parent.DataService)
local CurrencyService = require(script.Parent.CurrencyService)

local WheelService = {}

-- Higher Luck shifts weight away from Common rewards and toward everything else.
local function weightedPick(rewards, luck)
	local weighted = {}
	local total = 0

	for _, reward in ipairs(rewards) do
		local weight = reward.weight
		if reward.rarity ~= "Common" then
			weight *= (1 + luck * Config.LuckWheelWeightBonus)
		end
		total += weight
		table.insert(weighted, { reward = reward, cumulative = total })
	end

	local roll = math.random() * total
	for _, entry in ipairs(weighted) do
		if roll <= entry.cumulative then
			return entry.reward
		end
	end

	return weighted[#weighted].reward
end

function WheelService.Spin(player, wheelId)
	local wheel = WheelData.ById[wheelId]
	if not wheel then
		return { ok = false, error = "unknown_wheel" }
	end

	local data = DataService.Get(player.UserId)
	if not data then
		return { ok = false, error = "no_data" }
	end

	if not CurrencyService.Spend(player, wheel.cost) then
		return { ok = false, error = "insufficient_currency" }
	end

	local reward = weightedPick(wheel.rewards, data.Luck)

	if reward.kind == "currency" then
		CurrencyService.Award(player, reward.amount, "wheel")
	elseif reward.kind == "luck" then
		data.Luck += reward.amount
	elseif reward.kind == "weapon" then
		data.OwnedWeapons[reward.id] = true
	elseif reward.kind == "defense" then
		data.OwnedDefenses[reward.id] = true
	end

	DataService.MarkDirty(player.UserId)

	return {
		ok = true,
		reward = reward,
		currency = data.Currency,
		luck = data.Luck,
	}
end

function WheelService.BuyLuckUpgrade(player)
	local data = DataService.Get(player.UserId)
	if not data then
		return { ok = false, error = "no_data" }
	end

	local cost = math.floor(Config.LuckUpgradeBaseCost * (Config.LuckUpgradeCostGrowth ^ data.LuckUpgradesBought))

	if not CurrencyService.Spend(player, cost) then
		return { ok = false, error = "insufficient_currency" }
	end

	data.Luck += Config.LuckPerUpgrade
	data.LuckUpgradesBought += 1
	DataService.MarkDirty(player.UserId)

	return { ok = true, luck = data.Luck }
end

return WheelService
