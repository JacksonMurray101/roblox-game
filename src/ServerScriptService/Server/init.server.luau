local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

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
	if result and result.Instance:GetAttribute("Health") then
		ZombieAI.Damage(result.Instance, weapon.damage, player)
	end
end)

print("Spin & Survive server initialized.")
