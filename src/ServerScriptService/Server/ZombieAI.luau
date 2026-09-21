-- Zombies are small multi-part Models (no Humanoid) driven by a single
-- Heartbeat loop: walk toward the target plot's Core, deal damage on
-- contact, die on 0 HP. Movement uses Model:PivotTo so the whole rig
-- (torso/head/limbs) moves and turns together as one rigid body.
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(game:GetService("ReplicatedStorage").Modules.Config)
local ZombieData = require(game:GetService("ReplicatedStorage").Modules.ZombieData)

local PlotManager = require(script.Parent.PlotManager)
local CurrencyService = require(script.Parent.CurrencyService)

local ZombieAI = {}

local active = {} -- [model] = zombieState
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

-- Builds a blocky humanoid zombie rig (torso, head, glowing eyes, limbs
-- rotated into a forward "reach" pose) at the world origin; callers move
-- the finished model into place with Model:PivotTo.
local function buildZombieModel(template)
	local model = Instance.new("Model")
	model.Name = template.name

	local scale = template.isBoss and 2.2 or 1
	local skinColor = template.color
	local clothColor = Color3.new(skinColor.R * 0.55, skinColor.G * 0.55, skinColor.B * 0.55)

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1) * scale
	torso.Color = clothColor
	torso.Material = Enum.Material.Slate
	torso.Anchored = true
	torso.CanCollide = false
	torso.CFrame = CFrame.new(0, 3 * scale, 0)
	torso.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.2, 1.2, 1.2) * scale
	head.Color = skinColor
	head.Material = Enum.Material.Slate
	head.Anchored = true
	head.CanCollide = false
	head.CFrame = torso.CFrame * CFrame.new(0, 1.6 * scale, 0) * CFrame.Angles(math.rad(15), 0, 0)
	head.Parent = model

	local function eye(offsetX)
		local eyePart = Instance.new("Part")
		eyePart.Name = "Eye"
		eyePart.Shape = Enum.PartType.Ball
		eyePart.Size = Vector3.new(0.22, 0.22, 0.1) * scale
		eyePart.Color = Color3.fromRGB(255, 30, 30)
		eyePart.Material = Enum.Material.Neon
		eyePart.Anchored = true
		eyePart.CanCollide = false
		eyePart.CFrame = head.CFrame * CFrame.new(offsetX * scale, 0.1 * scale, -0.62 * scale)
		eyePart.Parent = model
	end
	eye(-0.3)
	eye(0.3)

	local function limb(name, offsetX, isArm)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = (isArm and Vector3.new(0.6, 1.8, 0.6) or Vector3.new(0.7, 2, 0.7)) * scale
		part.Color = skinColor
		part.Material = Enum.Material.Slate
		part.Anchored = true
		part.CanCollide = false
		if isArm then
			-- Reach the arm forward and slightly out -- the classic zombie pose.
			part.CFrame = torso.CFrame
				* CFrame.new(offsetX * 1.5 * scale, 0.2 * scale, 0)
				* CFrame.Angles(math.rad(-100), 0, math.rad(offsetX * 10))
				* CFrame.new(0, -0.9 * scale, 0)
		else
			part.CFrame = torso.CFrame * CFrame.new(offsetX * 0.6 * scale, -1.9 * scale, 0)
		end
		part.Parent = model
		return part
	end

	limb("LeftArm", -1, true)
	limb("RightArm", 1, true)
	limb("LeftLeg", -1, false)
	limb("RightLeg", 1, false)

	if template.isBoss then
		local function shoulderSpike(offsetX)
			local spike = Instance.new("WedgePart")
			spike.Name = "Spike"
			spike.Size = Vector3.new(0.5, 1.4, 0.5) * scale
			spike.Color = Color3.fromRGB(20, 20, 20)
			spike.Material = Enum.Material.Slate
			spike.Anchored = true
			spike.CanCollide = false
			spike.CFrame = torso.CFrame
				* CFrame.new(offsetX * 1.1 * scale, 1.3 * scale, 0)
				* CFrame.Angles(0, 0, math.rad(offsetX * -90))
			spike.Parent = model
		end
		shoulderSpike(-1)
		shoulderSpike(1)
	end

	model.PrimaryPart = torso
	return model
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

	local model = buildZombieModel(template)
	model.Parent = zombiesFolder
	model:PivotTo(CFrame.lookAt(spawnPos, Config.MapCenter))

	local maxHealth = scaledStat(template.health, waveNumber, WAVE_HEALTH_SCALE)
	local damage = scaledStat(template.damage, waveNumber, WAVE_DAMAGE_SCALE)

	model:SetAttribute("Health", maxHealth)
	model:SetAttribute("MaxHealth", maxHealth)
	model:SetAttribute("PlotId", plotId)

	local hpGui = Instance.new("BillboardGui")
	hpGui.Size = UDim2.fromOffset(50, 10)
	hpGui.StudsOffset = Vector3.new(0, template.isBoss and 5 or 3, 0)
	hpGui.AlwaysOnTop = true
	hpGui.Parent = model.PrimaryPart

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

	active[model] = {
		model = model,
		rootPart = model.PrimaryPart,
		plotId = plotId,
		speed = template.speed,
		damage = damage,
		reward = template.reward + math.floor(waveNumber * 0.5),
		attackRange = template.ranged and template.attackRange or MELEE_RANGE,
		hpFill = fill,
		nextAttackTime = 0,
		slowUntil = 0,
		slowFactor = 1,
		facing = Vector3.new(0, 0, -1),
	}

	return model
end

function ZombieAI.Damage(model, amount, killerPlayer)
	local state = active[model]
	if not state then
		return false
	end

	local health = (model:GetAttribute("Health") or 0) - amount
	model:SetAttribute("Health", math.max(health, 0))

	local maxHealth = model:GetAttribute("MaxHealth") or 1
	state.hpFill.Size = UDim2.fromScale(math.clamp(health / maxHealth, 0, 1), 1)

	if health <= 0 then
		ZombieAI._kill(model, killerPlayer)
		return true
	end

	return false
end

function ZombieAI.ApplySlow(model, factor, duration)
	local state = active[model]
	if not state then
		return
	end
	state.slowFactor = factor
	state.slowUntil = os.clock() + duration
end

function ZombieAI._kill(model, killerPlayer)
	local state = active[model]
	if not state then
		return
	end
	active[model] = nil

	if killerPlayer then
		CurrencyService.Award(killerPlayer, state.reward, "kill")
	end

	model:Destroy()
end

function ZombieAI._retarget(state)
	local plot = pickAnyEligiblePlot()
	if not plot then
		return false
	end
	state.plotId = plot.id
	state.model:SetAttribute("PlotId", plot.id)
	return true
end

function ZombieAI._step(dt)
	local now = os.clock()

	for model, state in pairs(active) do
		if not model.Parent then
			active[model] = nil
			continue
		end

		local plot = PlotManager.GetById(state.plotId)
		if not plot or not plot.owner or not plot.optedIn or plot.core:GetAttribute("Health") <= 0 then
			if not ZombieAI._retarget(state) then
				continue
			end
			plot = PlotManager.GetById(state.plotId)
		end

		local currentPos = state.rootPart.Position
		local toCore = plot.core.Position - currentPos
		toCore = Vector3.new(toCore.X, 0, toCore.Z)
		local distance = toCore.Magnitude
		local direction = distance > 0.01 and toCore.Unit or state.facing

		local speed = state.speed
		if now < state.slowUntil then
			speed *= state.slowFactor
		end

		local targetPos = currentPos
		if distance > state.attackRange then
			targetPos = currentPos + direction * speed * dt
		elseif now >= state.nextAttackTime then
			state.nextAttackTime = now + ATTACK_INTERVAL
			local previousHealth = plot.core:GetAttribute("Health") or 0
			if previousHealth > 0 then
				local coreHealth = math.max(previousHealth - state.damage, 0)
				plot.core:SetAttribute("Health", coreHealth)
				if coreHealth <= 0 then
					PlotManager.OnCoreDestroyed(plot)
				else
					PlotManager.UpdateCoreVisual(plot)
				end
			end
		end

		state.facing = direction
		state.model:PivotTo(CFrame.lookAt(targetPos, targetPos + direction))
	end
end

return ZombieAI
