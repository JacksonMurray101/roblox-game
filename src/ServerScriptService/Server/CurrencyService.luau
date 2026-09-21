local Config = require(game:GetService("ReplicatedStorage").Modules.Config)

local DataService = require(script.Parent.DataService)
local PlotManager = require(script.Parent.PlotManager)

local CurrencyService = {}

local remotes

local function syncLeaderstat(player, data)
	local leaderstats = player:FindFirstChild("leaderstats")
	local currencyValue = leaderstats and leaderstats:FindFirstChild("Currency")
	if currencyValue then
		currencyValue.Value = data.Currency
	end
end

function CurrencyService.Init(remotesTable)
	remotes = remotesTable

	task.spawn(function()
		while true do
			task.wait(1)
			CurrencyService._tickSurvival()
		end
	end)
end

function CurrencyService.Award(player, amount, reason)
	local data = DataService.Get(player.UserId)
	if not data then
		return
	end

	data.Currency += amount
	DataService.MarkDirty(player.UserId)
	syncLeaderstat(player, data)

	if remotes then
		remotes.StateUpdate:FireClient(player, { currency = data.Currency, lastGain = amount, reason = reason })
	end
end

function CurrencyService.Spend(player, amount)
	local data = DataService.Get(player.UserId)
	if not data or data.Currency < amount then
		return false
	end

	data.Currency -= amount
	DataService.MarkDirty(player.UserId)
	syncLeaderstat(player, data)

	return true
end

function CurrencyService._tickSurvival()
	for _, plot in ipairs(PlotManager.GetAll()) do
		if plot.owner and plot.optedIn and plot.core:GetAttribute("Health") > 0 then
			CurrencyService.Award(plot.owner, Config.CurrencyPerSecondSurvived, "survival")
		end
	end
end

return CurrencyService
