-- Server-wide wave loop: Countdown -> Active -> Cooldown -> repeat.
-- Every player in the server shares the same wave; each can opt in/out
-- individually via PlotManager.SetOptedIn.
local Workspace = game:GetService("Workspace")

local Config = require(game:GetService("ReplicatedStorage").Modules.Config)
local ZombieData = require(game:GetService("ReplicatedStorage").Modules.ZombieData)

local PlotManager = require(script.Parent.PlotManager)
local ZombieAI = require(script.Parent.ZombieAI)
local CurrencyService = require(script.Parent.CurrencyService)

local WaveManager = {}

local waveNumber = 0
local state = "Cooldown" -- Cooldown | Countdown | Active
local stateEndsAt = 0
local remotes

local function eligibleZombieTypes(wave)
	local types = {}
	for _, zombie in ipairs(ZombieData.List) do
		if wave >= zombie.minWave and not zombie.isBoss then
			table.insert(types, zombie)
		end
	end
	return types
end

local function pickTargetPlot()
	local candidates = {}
	for _, plot in ipairs(PlotManager.GetAll()) do
		if plot.owner and plot.optedIn and plot.core:GetAttribute("Health") > 0 then
			table.insert(candidates, plot)
		end
	end
	if #candidates == 0 then
		return nil
	end
	return candidates[math.random(1, #candidates)]
end

local function anyoneOptedIn()
	for _, plot in ipairs(PlotManager.GetAll()) do
		if plot.owner and plot.optedIn then
			return true
		end
	end
	return false
end

local function broadcastWaveState()
	remotes.WaveStateUpdate:FireAllClients({
		wave = waveNumber,
		state = state,
		endsAt = stateEndsAt,
		zombiesLeft = ZombieAI.GetActiveCount(),
	})
end

local function healCores()
	for _, plot in ipairs(PlotManager.GetAll()) do
		if plot.owner and plot.core:GetAttribute("Health") > 0 then
			local health = plot.core:GetAttribute("Health")
			local maxHealth = plot.core:GetAttribute("MaxHealth")
			plot.core:SetAttribute("Health", math.min(health + Config.CoreRegenPerWaveCooldown, maxHealth))
		end
	end
end

local function runCountdown()
	state = "Countdown"
	stateEndsAt = Workspace:GetServerTimeNow() + Config.WaveCountdown
	broadcastWaveState()
	task.wait(Config.WaveCountdown)
end

local function runWave()
	waveNumber += 1
	state = "Active"

	local isBossWave = waveNumber % Config.BossWaveEvery == 0
	local zombieCount = Config.BaseZombiesPerWave + (waveNumber - 1) * Config.ZombiesPerWaveGrowth
	local types = eligibleZombieTypes(waveNumber)
	local spawnInterval = math.max(0.15, 1.2 - waveNumber * 0.02)

	stateEndsAt = Workspace:GetServerTimeNow() + zombieCount * spawnInterval + 15
	broadcastWaveState()

	task.spawn(function()
		for _ = 1, zombieCount do
			local plot = pickTargetPlot()
			if plot and #types > 0 then
				local template = types[math.random(1, #types)]
				ZombieAI.Spawn(template.id, waveNumber, plot.id)
			end
			task.wait(spawnInterval)
		end

		if isBossWave then
			local plot = pickTargetPlot()
			if plot then
				ZombieAI.Spawn("boss", waveNumber, plot.id)
			end
		end
	end)

	local hardDeadline = os.clock() + zombieCount * spawnInterval + 90
	task.wait(zombieCount * spawnInterval + 2)
	while ZombieAI.GetActiveCount() > 0 and os.clock() < hardDeadline do
		task.wait(1)
	end
end

local function runCooldown()
	state = "Cooldown"
	stateEndsAt = Workspace:GetServerTimeNow() + Config.WaveCooldown
	broadcastWaveState()

	for _, plot in ipairs(PlotManager.GetAll()) do
		if plot.owner and plot.core:GetAttribute("Health") > 0 then
			CurrencyService.Award(plot.owner, Config.WaveClearBonus, "wave_clear")
		end
	end

	healCores()
	task.wait(Config.WaveCooldown)
end

function WaveManager.Init(remotesTable)
	remotes = remotesTable

	task.spawn(function()
		while true do
			if not anyoneOptedIn() then
				state = "Cooldown"
				stateEndsAt = Workspace:GetServerTimeNow() + 3
				broadcastWaveState()
				task.wait(3)
				continue
			end

			runCountdown()
			runWave()
			runCooldown()
		end
	end)
end

function WaveManager.GetWaveNumber()
	return waveNumber
end

return WaveManager
