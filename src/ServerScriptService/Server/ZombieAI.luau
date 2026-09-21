-- Zombies are plain Parts (no Humanoid) driven by a single Heartbeat loop:
-- walk toward the target plot's Core, deal damage on contact, die on 0 HP.
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(game:GetService("ReplicatedStorage").Modules.Config)
local ZombieData = require(game:GetService("ReplicatedStorage").Modules.ZombieData)

local PlotManager = require(script.Parent.PlotManager)
local CurrencyService = require(script.Parent.CurrencyService)

local ZombieAI = {}

local active = {} -- [part] = zombieState
local zombiesFolder

local WAVE_HEALTH_SCALE = 0.12 -- +12% health per wave
local WAVE_DAMAGE_SCALE = 0.06 -- +6% damage per wave
local MELEE_RANGE = 8
local ATTACK_INTERVAL = 1

local function scaledStat(base, wave, scalePerWave)
	return base * (1 + (wave - 1) * scalePerWave)
end

local function pickAnyEligiblePlot()
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

function ZombieAI.Init()
	zombiesFolder = Instance.new("Folder")
	zombiesFolder.Name = "Zombies"
	zombiesFolder.Parent = Workspace

	RunService.Heartbeat:Connect(function(dt)
		ZombieAI._step(dt)
	end)
end

function ZombieAI.GetZombiesFolder()
	return zombiesFolder
end

function ZombieAI.GetActiveCount()
	local count = 0
	for _ in pairs(active) do
		count += 1
	end
	return count
end

function ZombieAI.Spawn(zombieTypeId, waveNumber, plotId)
	local template = ZombieData.ById[zombieTypeId]
	if not template then
		return nil
	end

	local angle = math.random() * math.pi * 2
	local radius = Config.PlotRadius + 60
	local spawnPos = Config.MapCenter + Vector3.new(math.cos(angle) * radius, 4, math.sin(angle) * radius)

	local part = Instance.new("Part")
	part.Name = template.name
	part.Size = template.isBoss and Vector3.new(8, 12, 8) or Vector3.new(3, 6, 3)
	part.Position = spawnPos
	part.Color = template.color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.Parent = zombiesFolder

	local maxHealth = scaledStat(template.health, waveNumber, WAVE_HEALTH_SCALE)
	local damage = scaledStat(template.damage, waveNumber, WAVE_DAMAGE_SCALE)

	part:SetAttribute("Health", maxHealth)
	part:SetAttribute("MaxHealth", maxHealth)
	part:SetAttribute("PlotId", plotId)

	local hpGui = Instance.new("BillboardGui")
	hpGui.Size = UDim2.fromOffset(50, 10)
	hpGui.StudsOffset = Vector3.new(0, 4, 0)
	hpGui.AlwaysOnTop = true
	hpGui.Parent = part

	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	bg.BorderSizePixel = 0
	bg.Parent = hpGui

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
	fill.BorderSizePixel = 0
	fill.Parent = bg

	active[part] = {
		part = part,
		plotId = plotId,
		speed = template.speed,
		damage = damage,
		reward = template.reward + math.floor(waveNumber * 0.5),
		attackRange = template.ranged and template.attackRange or MELEE_RANGE,
		hpFill = fill,
		nextAttackTime = 0,
		slowUntil = 0,
		slowFactor = 1,
	}

	return part
end

function ZombieAI.Damage(part, amount, killerPlayer)
	local state = active[part]
	if not state then
		return false
	end

	local health = (part:GetAttribute("Health") or 0) - amount
	part:SetAttribute("Health", math.max(health, 0))

	local maxHealth = part:GetAttribute("MaxHealth") or 1
	state.hpFill.Size = UDim2.fromScale(math.clamp(health / maxHealth, 0, 1), 1)

	if health <= 0 then
		ZombieAI._kill(part, killerPlayer)
		return true
	end

	return false
end

function ZombieAI.ApplySlow(part, factor, duration)
	local state = active[part]
	if not state then
		return
	end
	state.slowFactor = factor
	state.slowUntil = os.clock() + duration
end

function ZombieAI._kill(part, killerPlayer)
	local state = active[part]
	if not state then
		return
	end
	active[part] = nil

	if killerPlayer then
		CurrencyService.Award(killerPlayer, state.reward, "kill")
	end

	part:Destroy()
end

function ZombieAI._retarget(state)
	local plot = pickAnyEligiblePlot()
	if not plot then
		return false
	end
	state.plotId = plot.id
	state.part:SetAttribute("PlotId", plot.id)
	return true
end

function ZombieAI._step(dt)
	local now = os.clock()

	for part, state in pairs(active) do
		if not part.Parent then
			active[part] = nil
			continue
		end

		local plot = PlotManager.GetById(state.plotId)
		if not plot or not plot.owner or not plot.optedIn or plot.core:GetAttribute("Health") <= 0 then
			if not ZombieAI._retarget(state) then
				continue
			end
			plot = PlotManager.GetById(state.plotId)
		end

		local corePos = plot.core.Position
		local toCore = corePos - part.Position
		toCore = Vector3.new(toCore.X, 0, toCore.Z)
		local distance = toCore.Magnitude

		local speed = state.speed
		if now < state.slowUntil then
			speed *= state.slowFactor
		end

		if distance > state.attackRange then
			local direction = toCore.Unit
			local newPos = part.Position + direction * speed * dt
			part.CFrame = CFrame.lookAt(newPos, newPos + direction)
		elseif now >= state.nextAttackTime then
			state.nextAttackTime = now + ATTACK_INTERVAL
			local coreHealth = math.max((plot.core:GetAttribute("Health") or 0) - state.damage, 0)
			plot.core:SetAttribute("Health", coreHealth)
		end
	end
end

return ZombieAI
