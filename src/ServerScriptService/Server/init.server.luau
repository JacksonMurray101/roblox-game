local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")

local RemoteDefinitions = require(ReplicatedStorage.Modules.RemoteDefinitions)
local WeaponData = require(ReplicatedStorage.Modules.WeaponData)

local DataService = require(script.DataService)
local PlotManager = require(script.PlotManager)
local ZombieAI = require(script.ZombieAI)
local TurretController = require(script.TurretController)
local CurrencyService = require(script.CurrencyService)
local WaveManager = require(script.WaveManager)
local EquipmentService = require(script.EquipmentService)
local WheelService = require(script.WheelService)
local WeaponVisuals = require(script.WeaponVisuals)

local function setupAtmosphere()
	Lighting.ClockTime = 18.4
	Lighting.Brightness = 1.6
	Lighting.Ambient = Color3.fromRGB(35, 38, 45)
	Lighting.OutdoorAmbient = Color3.fromRGB(60, 65, 75)
	Lighting.FogColor = Color3.fromRGB(90, 100, 110)
	Lighting.FogStart = 220
	Lighting.FogEnd = 850

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.35
	atmosphere.Offset = 0.2
	atmosphere.Color = Color3.fromRGB(150, 150, 160)
	atmosphere.Decay = Color3.fromRGB(80, 70, 70)
	atmosphere.Glare = 0.15
	atmosphere.Haze = 1.8
	atmosphere.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.6
	bloom.Size = 24
	bloom.Threshold = 1.4
	bloom.Parent = Lighting

	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Saturation = -0.15
	colorCorrection.Contrast = 0.08
	colorCorrection.TintColor = Color3.fromRGB(225, 235, 230)
	colorCorrection.Parent = Lighting
end

setupAtmosphere()

local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "Remotes"
remotesFolder.Parent = ReplicatedStorage

local remotes = {}
for _, def in ipairs(RemoteDefinitions) do
	local remote = Instance.new(def.kind)
	remote.Name = def.name
	remote.Parent = remotesFolder
	remotes[def.name] = remote
end

PlotManager.Init()
ZombieAI.Init()
TurretController.Init()
DataService.Init()
CurrencyService.Init(remotes)
WaveManager.Init(remotes)

local function setupLeaderstats(player, data)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local currency = Instance.new("IntValue")
	currency.Name = "Currency"
	currency.Value = data.Currency
	currency.Parent = leaderstats

	local luck = Instance.new("IntValue")
	luck.Name = "Luck"
	luck.Value = data.Luck
	luck.Parent = leaderstats

	leaderstats.Parent = player
end

Players.PlayerAdded:Connect(function(player)
	local data = DataService.Load(player)
	setupLeaderstats(player, data)

	local plot = PlotManager.Assign(player)
	if plot then
		EquipmentService.ApplyLoadout(player)

		player.CharacterAdded:Connect(function(character)
			local hrp = character:WaitForChild("HumanoidRootPart", 5)
			if hrp then
				hrp.CFrame = plot.spawnPoint.CFrame
			end
			character:WaitForChild("RightHand", 2)
			WeaponVisuals.Attach(player, data.EquippedWeapon)
		end)
	end

	remotes.StateUpdate:FireClient(player, {
		currency = data.Currency,
		luck = data.Luck,
		ownedWeapons = data.OwnedWeapons,
		ownedDefenses = data.OwnedDefenses,
		equippedWeapon = data.EquippedWeapon,
		equippedDefenses = data.EquippedDefenses,
		plotId = plot and plot.id,
	})
end)

Players.PlayerRemoving:Connect(function(player)
	PlotManager.Release(player)
end)

remotes.ToggleWaveParticipation.OnServerEvent:Connect(function(player, optedIn)
	PlotManager.SetOptedIn(player, optedIn and true or false)
end)

remotes.EquipWeapon.OnServerInvoke = function(player, weaponId)
	return EquipmentService.EquipWeapon(player, weaponId)
end

remotes.EquipDefense.OnServerInvoke = function(player, slotIndex, defenseId)
	return EquipmentService.EquipDefense(player, slotIndex, defenseId)
end

remotes.PlaceDefense.OnServerInvoke = function(player, slotIndex, localOffset)
	return EquipmentService.PlaceDefense(player, slotIndex, localOffset)
end

remotes.SpinWheel.OnServerInvoke = function(player, wheelId)
	return WheelService.Spin(player, wheelId)
end

remotes.BuyLuckUpgrade.OnServerInvoke = function(player)
	return WheelService.BuyLuckUpgrade(player)
end

local lastFireTimes = {} -- [player] = os.clock() of last accepted shot, kept server-side only

Players.PlayerRemoving:Connect(function(player)
	lastFireTimes[player] = nil
end)

remotes.FireWeapon.OnServerEvent:Connect(function(player, targetPosition)
	if typeof(targetPosition) ~= "Vector3" then
		return
	end

	local data = DataService.Get(player.UserId)
	if not data then
		return
	end

	local weapon = WeaponData.ById[data.EquippedWeapon]
	if not weapon then
		return
	end

	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	local now = os.clock()
	if now - (lastFireTimes[player] or 0) < 1 / weapon.fireRate then
		return
	end
	lastFireTimes[player] = now

	local origin = hrp.Position
	local direction = targetPosition - origin
	if direction.Magnitude > weapon.range then
		direction = direction.Unit * weapon.range
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = { ZombieAI.GetZombiesFolder() }

	local result = Workspace:Raycast(origin, direction, raycastParams)
	local endPoint = result and result.Position or (origin + direction)

	local tracerDistance = (endPoint - origin).Magnitude
	local tracer = Instance.new("Part")
	tracer.Anchored = true
	tracer.CanCollide = false
	tracer.CanQuery = false
	tracer.Material = Enum.Material.Neon
	tracer.Color = weapon.tracerColor or Color3.new(1, 1, 1)
	tracer.Size = Vector3.new(0.15, 0.15, tracerDistance)
	tracer.CFrame = CFrame.lookAt(origin, endPoint) * CFrame.new(0, 0, -tracerDistance / 2)
	tracer.Parent = Workspace
	Debris:AddItem(tracer, 0.06)

	if result then
		-- Zombies are Models (torso/head/limbs); a hit part's Parent is the
		-- owning Model, which is where Health/PlotId attributes live.
		local zombieModel = result.Instance.Parent
		if zombieModel and zombieModel:GetAttribute("Health") then
			ZombieAI.Damage(zombieModel, weapon.damage, player)
		end
	end
end)

print("Spin & Survive server initialized.")
