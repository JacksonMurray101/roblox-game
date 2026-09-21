-- Builds turret Parts at a plot's slot pads and runs their auto-fire loop.
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local DefenseData = require(game:GetService("ReplicatedStorage").Modules.DefenseData)

local ZombieAI = require(script.Parent.ZombieAI)

local TurretController = {}

local activeTurrets = {} -- [turretPart] = state
local zombiesFolder

local function findTarget(plot, range)
	local turretPos = plot.core.Position
	local closest, closestDist

	for _, zombiePart in ipairs(zombiesFolder:GetChildren()) do
		if zombiePart:IsA("BasePart") and zombiePart:GetAttribute("PlotId") == plot.id then
			local dist = (zombiePart.Position - turretPos).Magnitude
			if dist <= range and (not closestDist or dist < closestDist) then
				closest = zombiePart
				closestDist = dist
			end
		end
	end

	return closest
end

local function fire(turretPart, state)
	local target = findTarget(state.plot, state.range)
	if not target then
		return
	end

	local distance = (target.Position - turretPart.Position).Magnitude
	local beam = Instance.new("Part")
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.Material = Enum.Material.Neon
	beam.Color = turretPart.Color
	beam.Size = Vector3.new(0.2, 0.2, distance)
	beam.CFrame = CFrame.lookAt(turretPart.Position, target.Position) * CFrame.new(0, 0, -distance / 2)
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
		for turretPart, state in pairs(activeTurrets) do
			if not turretPart.Parent then
				activeTurrets[turretPart] = nil
				continue
			end
			if now >= state.nextFireTime then
				state.nextFireTime = now + (1 / state.fireRate)
				fire(turretPart, state)
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

	local turretPart = Instance.new("Part")
	turretPart.Name = defense.name
	turretPart.Anchored = true
	turretPart.CanCollide = true
	turretPart.Size = Vector3.new(3, 4, 3)
	turretPart.Position = slotPad.Position + Vector3.new(0, 2.2, 0)
	turretPart.Color = defense.color
	turretPart.Material = Enum.Material.Metal
	turretPart.Parent = plot.model

	plot.turrets[slotIndex] = turretPart

	activeTurrets[turretPart] = {
		plot = plot,
		range = defense.range,
		damage = defense.damage,
		fireRate = defense.fireRate,
		slowFactor = defense.slowFactor,
		slowDuration = defense.slowDuration,
		nextFireTime = 0,
	}
end

return TurretController
