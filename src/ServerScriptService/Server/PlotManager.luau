-- Builds the plots (base platform + health core + turret slots) procedurally
-- at server start, and assigns one to each player as they join.
local Workspace = game:GetService("Workspace")

local Config = require(game:GetService("ReplicatedStorage").Modules.Config)

local PlotManager = {}

local plots = {}
local plotByOwner = {} -- [userId] = plot
local plotsFolder

local function scatterDebris()
	local debrisFolder = Instance.new("Folder")
	debrisFolder.Name = "Debris"
	debrisFolder.Parent = Workspace

	for _ = 1, 90 do
		local angle = math.random() * math.pi * 2
		local radius = math.random(Config.PlotRadius + 90, Config.PlotRadius + 220)
		local position = Config.MapCenter + Vector3.new(math.cos(angle) * radius, 3, math.sin(angle) * radius)

		local rock = Instance.new("Part")
		rock.Name = "Rock"
		rock.Anchored = true
		rock.CanCollide = false
		local size = math.random(15, 45) / 10
		rock.Size = Vector3.new(size, size * (math.random(6, 12) / 10), size)
		rock.Color = Color3.fromRGB(math.random(45, 70), math.random(45, 65), math.random(45, 60))
		rock.Material = Enum.Material.Rock
		rock.CFrame = CFrame.new(position) * CFrame.Angles(0, math.random() * math.pi * 2, 0)
		rock.Parent = debrisFolder
	end
end

local function buildPerimeterWall()
	local wallFolder = Instance.new("Folder")
	wallFolder.Name = "PerimeterWall"
	wallFolder.Parent = Workspace

	local wallRadius = Config.PlotRadius + 260
	local segmentCount = 48
	local segmentWidth = (2 * math.pi * wallRadius) / segmentCount

	for i = 1, segmentCount do
		local angle = (i - 1) / segmentCount * math.pi * 2
		local position = Config.MapCenter + Vector3.new(math.cos(angle) * wallRadius, 0, math.sin(angle) * wallRadius)
		local lookAt = CFrame.lookAt(position, Config.MapCenter)

		local height = math.random(10, 16)
		local segment = Instance.new("Part")
		segment.Name = "WallSegment"
		segment.Anchored = true
		segment.CanCollide = true
		segment.Size = Vector3.new(segmentWidth * 1.05, height, 2)
		segment.Color = Color3.fromRGB(45, 45, 50)
		segment.Material = Enum.Material.Concrete
		segment.CFrame = lookAt * CFrame.new(0, height / 2 - 2, 0)
		segment.Parent = wallFolder
	end
end

local function buildGround()
	local ground = Instance.new("Part")
	ground.Name = "Ground"
	ground.Anchored = true
	ground.Size = Vector3.new(1150, 4, 1150)
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

	scatterDebris()
	buildPerimeterWall()
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
	platform.CFrame = lookAt * CFrame.new(0, 0, 18)
	platform.Color = Color3.fromRGB(60, 60, 70)
	platform.Material = Enum.Material.Concrete
	platform.Parent = model

	-- A reactor-style core: a metal pedestal holding up a glowing orb caged
	-- by tilted containment rings, instead of a plain floating sphere.
	local pedestal = Instance.new("Part")
	pedestal.Name = "CorePedestal"
	pedestal.Shape = Enum.PartType.Cylinder
	pedestal.Anchored = true
	pedestal.CanCollide = true
	pedestal.Size = Vector3.new(2, 6, 6)
	pedestal.Color = Color3.fromRGB(55, 55, 62)
	pedestal.Material = Enum.Material.Metal
	pedestal.CFrame = platform.CFrame * CFrame.new(0, platform.Size.Y / 2 + 1, 0) * CFrame.Angles(0, 0, math.rad(90))
	pedestal.Parent = model

	local core = Instance.new("Part")
	core.Name = "Core"
	core.Shape = Enum.PartType.Ball
	core.Anchored = true
	core.CanCollide = true
	core.Size = Vector3.new(7, 7, 7)
	core.Position = pedestal.Position + Vector3.new(0, 5.5, 0)
	core.Color = Color3.fromRGB(70, 200, 90)
	core.Material = Enum.Material.Neon
	core:SetAttribute("Health", Config.CoreMaxHealth)
	core:SetAttribute("MaxHealth", Config.CoreMaxHealth)
	core:SetAttribute("PlotId", index)
	core.Parent = model

	local function containmentRing(tiltX, tiltZ)
		local ring = Instance.new("Part")
		ring.Name = "ContainmentRing"
		ring.Shape = Enum.PartType.Cylinder
		ring.Anchored = true
		ring.CanCollide = false
		ring.Size = Vector3.new(0.4, 9.5, 9.5)
		ring.Color = Color3.fromRGB(70, 70, 78)
		ring.Material = Enum.Material.Metal
		ring.CFrame = core.CFrame * CFrame.Angles(math.rad(tiltX), 0, math.rad(tiltZ))
		ring.Parent = model
	end
	containmentRing(55, 0)
	containmentRing(-55, 30)

	local hpGui = Instance.new("BillboardGui")
	hpGui.Name = "HealthGui"
	hpGui.Size = UDim2.fromOffset(220, 60)
	hpGui.StudsOffset = Vector3.new(0, 7, 0)
	hpGui.AlwaysOnTop = true
	hpGui.Parent = core

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "OwnerLabel"
	nameLabel.Size = UDim2.new(1, 0, 0, 22)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "Empty Plot"
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = hpGui

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 0, 24)
	bg.Position = UDim2.new(0, 0, 0, 26)
	bg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	bg.BorderSizePixel = 0
	bg.Parent = hpGui

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0.3, 0)
	bgCorner.Parent = bg

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(70, 220, 90)
	fill.BorderSizePixel = 0
	fill.Parent = bg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0.3, 0)
	fillCorner.Parent = fill

	local healthText = Instance.new("TextLabel")
	healthText.Name = "HealthText"
	healthText.Size = UDim2.fromScale(1, 1)
	healthText.BackgroundTransparency = 1
	healthText.Font = Enum.Font.GothamBold
	healthText.TextScaled = true
	healthText.TextColor3 = Color3.new(1, 1, 1)
	healthText.TextStrokeTransparency = 0.5
	healthText.Text = ("%d / %d"):format(Config.CoreMaxHealth, Config.CoreMaxHealth)
	healthText.ZIndex = 2
	healthText.Parent = bg

	local bubble = Instance.new("Part")
	bubble.Name = "Bubble"
	bubble.Shape = Enum.PartType.Ball
	bubble.Anchored = true
	bubble.CanCollide = false
	bubble.CanQuery = false
	bubble.Material = Enum.Material.ForceField
	bubble.Color = Color3.fromRGB(120, 200, 255)
	bubble.Size = Vector3.new(50, 50, 50)
	bubble.Position = core.Position
	bubble.Transparency = 1 -- hidden unless the owner opts out of the current wave
	bubble.Parent = model

	local slotsFolder = Instance.new("Folder")
	slotsFolder.Name = "TurretSlots"
	slotsFolder.Parent = model

	for slotIndex = 1, Config.TurretSlotsPerPlot do
		local offset = Config.DefaultTurretOffsets[slotIndex] or Vector3.new(0, 0, 0)
		local pad = Instance.new("Part")
		pad.Name = "Slot" .. slotIndex
		pad.Anchored = true
		pad.CanCollide = false
		pad.Size = Vector3.new(5, 0.4, 5)
		pad.Color = Color3.fromRGB(90, 90, 100)
		pad.Material = Enum.Material.Metal
		pad.CFrame = platform.CFrame * CFrame.new(offset.X, platform.Size.Y / 2 + 0.05, offset.Z)
		pad.Parent = slotsFolder
	end

	local function lightPole(offsetX, offsetZ)
		local pole = Instance.new("Part")
		pole.Name = "LightPole"
		pole.Anchored = true
		pole.CanCollide = false
		pole.Size = Vector3.new(0.6, 8, 0.6)
		pole.Color = Color3.fromRGB(50, 50, 55)
		pole.Material = Enum.Material.Metal
		pole.CFrame = platform.CFrame * CFrame.new(offsetX, 4 + platform.Size.Y / 2, offsetZ)
		pole.Parent = model

		local lamp = Instance.new("Part")
		lamp.Name = "Lamp"
		lamp.Shape = Enum.PartType.Ball
		lamp.Anchored = true
		lamp.CanCollide = false
		lamp.Size = Vector3.new(1.2, 1.2, 1.2)
		lamp.Color = Color3.fromRGB(255, 220, 150)
		lamp.Material = Enum.Material.Neon
		lamp.CFrame = pole.CFrame * CFrame.new(0, 4.3, 0)
		lamp.Parent = model

		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 210, 140)
		light.Range = 24
		light.Brightness = 2
		light.Parent = lamp
	end

	local cornerInset = Config.PlotSize.X / 2 - 4
	lightPole(-cornerInset, -cornerInset)
	lightPole(cornerInset, -cornerInset)
	lightPole(-cornerInset, cornerInset)
	lightPole(cornerInset, cornerInset)

	local spawnPoint = Instance.new("Part")
	spawnPoint.Name = "SpawnPoint"
	spawnPoint.Anchored = true
	spawnPoint.CanCollide = false
	spawnPoint.Transparency = 1
	spawnPoint.Size = Vector3.new(6, 1, 6)
	spawnPoint.CFrame = lookAt * CFrame.new(0, 3, 32)
	spawnPoint.Parent = model

	model.Parent = plotsFolder

	return {
		id = index,
		model = model,
		platform = platform,
		core = core,
		bubble = bubble,
		hpFill = fill,
		hpText = healthText,
		ownerLabel = nameLabel,
		slots = slotsFolder,
		spawnPoint = spawnPoint,
		owner = nil,
		optedIn = true,
		turrets = {}, -- [slotIndex] = turret Model
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

-- Recolors the core (green -> yellow -> red -> dark/destroyed) and resizes
-- its health-bar fill to match its current Health attribute.
function PlotManager.UpdateCoreVisual(plot)
	local health = plot.core:GetAttribute("Health") or 0
	local maxHealth = plot.core:GetAttribute("MaxHealth") or 1
	local pct = math.clamp(health / maxHealth, 0, 1)

	plot.hpFill.Size = UDim2.fromScale(pct, 1)
	plot.hpText.Text = ("%d / %d"):format(math.ceil(health), math.ceil(maxHealth))

	if pct <= 0 then
		plot.core.Material = Enum.Material.Slate
		plot.core.Color = Color3.fromRGB(40, 40, 40)
	else
		plot.core.Material = Enum.Material.Neon
		if pct > 0.5 then
			plot.core.Color = Color3.fromRGB(70, 200, 90)
		elseif pct > 0.2 then
			plot.core.Color = Color3.fromRGB(230, 200, 60)
		else
			plot.core.Color = Color3.fromRGB(220, 70, 60)
		end
	end
end

-- Called the moment a plot's core hits 0 HP: kills the owner's character as
-- the real, felt consequence of letting a base fall.
function PlotManager.OnCoreDestroyed(plot)
	local player = plot.owner
	if not player then
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		humanoid.Health = 0
	end

	PlotManager.UpdateCoreVisual(plot)
end

return PlotManager
