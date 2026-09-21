-- Builds the plots (base platform + health core + turret slots) procedurally
-- at server start, and assigns one to each player as they join.
local Workspace = game:GetService("Workspace")

local Config = require(game:GetService("ReplicatedStorage").Modules.Config)

local PlotManager = {}

local plots = {}
local plotByOwner = {} -- [userId] = plot
local plotsFolder

local slotOffsets = {
	Vector3.new(-15, 0, -15),
	Vector3.new(15, 0, -15),
	Vector3.new(-15, 0, 15),
	Vector3.new(15, 0, 15),
}

local function buildGround()
	local ground = Instance.new("Part")
	ground.Name = "Ground"
	ground.Anchored = true
	ground.Size = Vector3.new(600, 4, 600)
	ground.Position = Config.MapCenter - Vector3.new(0, 2, 0)
	ground.Color = Color3.fromRGB(40, 60, 40)
	ground.Material = Enum.Material.Grass
	ground.Parent = Workspace

	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "DefaultSpawn"
	spawnLocation.Anchored = true
	spawnLocation.Size = Vector3.new(10, 1, 10)
	spawnLocation.Position = Config.MapCenter + Vector3.new(0, 2, 0)
	spawnLocation.Material = Enum.Material.Neon
	spawnLocation.Color = Color3.fromRGB(80, 80, 200)
	spawnLocation.Parent = Workspace
end

local function buildPlot(index)
	local angle = (index - 1) / Config.MaxPlots * math.pi * 2
	local center = Config.MapCenter + Vector3.new(math.cos(angle) * Config.PlotRadius, 0, math.sin(angle) * Config.PlotRadius)
	local lookAt = CFrame.lookAt(center, Config.MapCenter)

	local model = Instance.new("Model")
	model.Name = "Plot" .. index

	local platform = Instance.new("Part")
	platform.Name = "Platform"
	platform.Anchored = true
	platform.Size = Config.PlotSize
	platform.CFrame = lookAt * CFrame.new(0, 0, 10)
	platform.Color = Color3.fromRGB(60, 60, 70)
	platform.Material = Enum.Material.Concrete
	platform.Parent = model

	local core = Instance.new("Part")
	core.Name = "Core"
	core.Shape = Enum.PartType.Ball
	core.Anchored = true
	core.CanCollide = true
	core.Size = Vector3.new(6, 6, 6)
	core.Position = platform.Position + Vector3.new(0, 4, 0)
	core.Color = Color3.fromRGB(70, 200, 90)
	core.Material = Enum.Material.Neon
	core:SetAttribute("Health", Config.CoreMaxHealth)
	core:SetAttribute("MaxHealth", Config.CoreMaxHealth)
	core:SetAttribute("PlotId", index)
	core.Parent = model

	local hpGui = Instance.new("BillboardGui")
	hpGui.Name = "HealthGui"
	hpGui.Size = UDim2.fromOffset(140, 36)
	hpGui.StudsOffset = Vector3.new(0, 5, 0)
	hpGui.AlwaysOnTop = true
	hpGui.Parent = core

	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 0.5)
	bg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	bg.BorderSizePixel = 0
	bg.Parent = hpGui

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(70, 220, 90)
	fill.BorderSizePixel = 0
	fill.Parent = bg

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "OwnerLabel"
	nameLabel.Size = UDim2.fromScale(1, 0.5)
	nameLabel.Position = UDim2.fromScale(0, 0.5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "Empty Plot"
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = hpGui

	local bubble = Instance.new("Part")
	bubble.Name = "Bubble"
	bubble.Shape = Enum.PartType.Ball
	bubble.Anchored = true
	bubble.CanCollide = false
	bubble.CanQuery = false
	bubble.Material = Enum.Material.ForceField
	bubble.Color = Color3.fromRGB(120, 200, 255)
	bubble.Size = Vector3.new(34, 34, 34)
	bubble.Position = platform.Position + Vector3.new(0, 4, 0)
	bubble.Transparency = 1 -- hidden unless the owner opts out of the current wave
	bubble.Parent = model

	local slotsFolder = Instance.new("Folder")
	slotsFolder.Name = "TurretSlots"
	slotsFolder.Parent = model

	for slotIndex = 1, Config.TurretSlotsPerPlot do
		local offset = slotOffsets[slotIndex] or Vector3.new(0, 0, 0)
		local pad = Instance.new("Part")
		pad.Name = "Slot" .. slotIndex
		pad.Anchored = true
		pad.CanCollide = false
		pad.Size = Vector3.new(5, 0.4, 5)
		pad.Color = Color3.fromRGB(90, 90, 100)
		pad.Material = Enum.Material.Metal
		pad.CFrame = lookAt * CFrame.new(offset.X, 0, offset.Z + 10)
		pad.Parent = slotsFolder
	end

	local spawnPoint = Instance.new("Part")
	spawnPoint.Name = "SpawnPoint"
	spawnPoint.Anchored = true
	spawnPoint.CanCollide = false
	spawnPoint.Transparency = 1
	spawnPoint.Size = Vector3.new(6, 1, 6)
	spawnPoint.CFrame = lookAt * CFrame.new(0, 3, 18)
	spawnPoint.Parent = model

	model.Parent = plotsFolder

	return {
		id = index,
		model = model,
		platform = platform,
		core = core,
		bubble = bubble,
		hpFill = fill,
		ownerLabel = nameLabel,
		slots = slotsFolder,
		spawnPoint = spawnPoint,
		owner = nil,
		optedIn = true,
		turrets = {}, -- [slotIndex] = turret Part
	}
end

function PlotManager.Init()
	buildGround()

	plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "Plots"
	plotsFolder.Parent = Workspace

	for i = 1, Config.MaxPlots do
		plots[i] = buildPlot(i)
	end
end

function PlotManager.GetAll()
	return plots
end

function PlotManager.GetById(plotId)
	return plots[plotId]
end

function PlotManager.GetByOwner(player)
	return plotByOwner[player.UserId]
end

function PlotManager.Assign(player)
	for _, plot in ipairs(plots) do
		if not plot.owner then
			plot.owner = player
			plot.optedIn = true
			plot.ownerLabel.Text = player.Name
			plotByOwner[player.UserId] = plot
			return plot
		end
	end
	return nil
end

function PlotManager.Release(player)
	local plot = plotByOwner[player.UserId]
	if not plot then
		return
	end

	plot.owner = nil
	plot.ownerLabel.Text = "Empty Plot"
	plot.optedIn = true
	plot.bubble.Transparency = 1

	for _, turret in pairs(plot.turrets) do
		turret:Destroy()
	end
	plot.turrets = {}

	plotByOwner[player.UserId] = nil
end

function PlotManager.SetOptedIn(player, optedIn)
	local plot = plotByOwner[player.UserId]
	if not plot then
		return
	end
	plot.optedIn = optedIn
	plot.bubble.Transparency = optedIn and 1 or 0.75
end

return PlotManager
