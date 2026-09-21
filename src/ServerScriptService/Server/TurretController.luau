-- Builds a distinct multi-part model per defense type at a plot's slot pad
-- and runs the auto-fire loop for every built turret.
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local DefenseData = require(game:GetService("ReplicatedStorage").Modules.DefenseData)

local ZombieAI = require(script.Parent.ZombieAI)

local TurretController = {}

local activeTurrets = {} -- [turretModel] = state
local zombiesFolder

-- A cylinder Part's native long axis is local X; rotating 90 degrees around
-- Y points it along Z so `position` + `tilt` reads as a barrel aimed
-- forward with an optional up/down pitch.
local function barrel(model, length, radius, position, tilt, color, material)
	local part = Instance.new("Part")
	part.Name = "Barrel"
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(length, radius * 2, radius * 2)
	part.Color = color
	part.Material = material or Enum.Material.Metal
	part.Anchored = true
	part.CanCollide = false
	part.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(tilt or 0, 0, 0)
	part.Parent = model
	return part
end

local function buildTurretModel(defense)
	local model = Instance.new("Model")
	model.Name = defense.name

	local base = Instance.new("Part")
	base.Name = "Base"
	base.Shape = Enum.PartType.Cylinder
	base.Size = Vector3.new(1.2, 3.4, 3.4)
	base.CFrame = CFrame.new(0, 1.7, 0) * CFrame.Angles(0, 0, math.rad(90))
	base.Color = defense.color
	base.Material = Enum.Material.Metal
	base.Anchored = true
	base.CanCollide = true
	base.Parent = model

	if defense.id == "basic_turret" then
		barrel(model, 2.4, 0.35, Vector3.new(0, 2.6, -1), 0, defense.color)
	elseif defense.id == "rapid_turret" then
		barrel(model, 2, 0.22, Vector3.new(-0.3, 2.5, -1), 0, defense.color)
		barrel(model, 2, 0.22, Vector3.new(0.3, 2.5, -1), 0, defense.color)
	elseif defense.id == "cannon_turret" then
		barrel(model, 3.6, 0.85, Vector3.new(0, 2.5, -1.6), math.rad(-6), Color3.fromRGB(55, 55, 65))
	elseif defense.id == "frost_turret" then
		local crystal = Instance.new("Part")
		crystal.Name = "Crystal"
		crystal.Size = Vector3.new(1, 2.4, 1)
		crystal.Color = defense.color
		crystal.Material = Enum.Material.Ice
		crystal.Transparency = 0.15
		crystal.Anchored = true
		crystal.CanCollide = false
		crystal.CFrame = CFrame.new(0, 3.6, 0) * CFrame.Angles(0, math.rad(45), 0)
		crystal.Parent = model
	elseif defense.id == "flame_turret" then
		local nozzle = barrel(model, 2, 0.4, Vector3.new(0, 2.4, -1.2), 0, Color3.fromRGB(80, 40, 30))
		local tip = Instance.new("Part")
		tip.Name = "Tip"
		tip.Shape = Enum.PartType.Ball
		tip.Size = Vector3.new(0.6, 0.6, 0.6)
		tip.Color = Color3.fromRGB(255, 140, 40)
		tip.Material = Enum.Material.Neon
		tip.Anchored = true
		tip.CanCollide = false
		tip.CFrame = nozzle.CFrame * CFrame.new(0, 0, -1.1)
		tip.Parent = model
	elseif defense.id == "tesla_turret" then
		local rod = Instance.new("Part")
		rod.Name = "Rod"
		rod.Shape = Enum.PartType.Cylinder
		rod.Size = Vector3.new(3, 0.36, 0.36)
		rod.Color = Color3.fromRGB(180, 180, 190)
		rod.Material = Enum.Material.Metal
		rod.Anchored = true
		rod.CanCollide = false
		rod.CFrame = CFrame.new(0, 3.2, 0) * CFrame.Angles(0, 0, math.rad(90))
		rod.Parent = model

		local orb = Instance.new("Part")
		orb.Name = "Orb"
		orb.Shape = Enum.PartType.Ball
		orb.Size = Vector3.new(1.1, 1.1, 1.1)
		orb.Color = defense.color
		orb.Material = Enum.Material.Neon
		orb.Anchored = true
		orb.CanCollide = false
		orb.CFrame = CFrame.new(0, 4.8, 0)
		orb.Parent = model
	end

	model.PrimaryPart = base
	return model
end

local function findTarget(plot, range)
	local turretPos = plot.core.Position
	local closest, closestDist

	for _, zombieModel in ipairs(zombiesFolder:GetChildren()) do
		if zombieModel:IsA("Model") and zombieModel:GetAttribute("PlotId") == plot.id and zombieModel.PrimaryPart then
			local dist = (zombieModel.PrimaryPart.Position - turretPos).Magnitude
			if dist <= range and (not closestDist or dist < closestDist) then
				closest = zombieModel
				closestDist = dist
			end
		end
	end

	return closest
end

local function fire(turretModel, state)
	local target = findTarget(state.plot, state.range)
	if not target then
		return
	end

	local originPos = state.origin.Position
	local targetPos = target.PrimaryPart.Position
	local distance = (targetPos - originPos).Magnitude

	local beam = Instance.new("Part")
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.Material = Enum.Material.Neon
	beam.Color = state.color
	beam.Size = Vector3.new(0.2, 0.2, distance)
	beam.CFrame = CFrame.lookAt(originPos, targetPos) * CFrame.new(0, 0, -distance / 2)
	beam.Parent = Workspace
	Debris:AddItem(beam, 0.08)

	ZombieAI.Damage(target, state.damage, state.plot.owner)

	if state.slowFactor then
		ZombieAI.ApplySlow(target, state.slowFactor, state.slowDuration)
	end
end

function TurretController.Init()
	zombiesFolder = ZombieAI.GetZombiesFolder()

	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		for turretModel, state in pairs(activeTurrets) do
			if not turretModel.Parent then
				activeTurrets[turretModel] = nil
				continue
			end
			if now >= state.nextFireTime then
				state.nextFireTime = now + (1 / state.fireRate)
				fire(turretModel, state)
			end
		end
	end)
end

function TurretController.Build(plot, slotIndex, defenseId)
	local defense = DefenseData.ById[defenseId]
	if not defense then
		return
	end

	local existing = plot.turrets[slotIndex]
	if existing then
		activeTurrets[existing] = nil
		existing:Destroy()
	end

	local slotPad = plot.slots:FindFirstChild("Slot" .. slotIndex)
	if not slotPad then
		return
	end

	local model = buildTurretModel(defense)
	model.Parent = plot.model
	model:PivotTo(CFrame.new(slotPad.Position))

	plot.turrets[slotIndex] = model

	activeTurrets[model] = {
		plot = plot,
		origin = model.PrimaryPart,
		color = defense.color,
		range = defense.range,
		damage = defense.damage,
		fireRate = defense.fireRate,
		slowFactor = defense.slowFactor,
		slowDuration = defense.slowDuration,
		nextFireTime = 0,
	}
end

return TurretController
