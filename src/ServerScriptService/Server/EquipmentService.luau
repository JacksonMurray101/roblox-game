local WeaponData = require(game:GetService("ReplicatedStorage").Modules.WeaponData)
local DefenseData = require(game:GetService("ReplicatedStorage").Modules.DefenseData)
local Config = require(game:GetService("ReplicatedStorage").Modules.Config)

local DataService = require(script.Parent.DataService)
local PlotManager = require(script.Parent.PlotManager)
local TurretController = require(script.Parent.TurretController)
local WeaponVisuals = require(script.Parent.WeaponVisuals)

local EquipmentService = {}

local function storedOffset(data, slotIndex)
	local stored = data.DefensePositions and data.DefensePositions[slotIndex]
	return stored and Vector3.new(stored.x, 0, stored.z) or nil
end

function EquipmentService.EquipWeapon(player, weaponId)
	local data = DataService.Get(player.UserId)
	if not data or not WeaponData.ById[weaponId] then
		return { ok = false, error = "invalid" }
	end
	if not data.OwnedWeapons[weaponId] then
		return { ok = false, error = "not_owned" }
	end

	data.EquippedWeapon = weaponId
	DataService.MarkDirty(player.UserId)
	WeaponVisuals.Attach(player, weaponId)
	return { ok = true, weaponId = weaponId }
end

function EquipmentService.EquipDefense(player, slotIndex, defenseId)
	local data = DataService.Get(player.UserId)
	if not data or not DefenseData.ById[defenseId] then
		return { ok = false, error = "invalid" }
	end
	if not data.OwnedDefenses[defenseId] then
		return { ok = false, error = "not_owned" }
	end
	if slotIndex < 1 or slotIndex > Config.TurretSlotsPerPlot then
		return { ok = false, error = "invalid_slot" }
	end

	data.EquippedDefenses[slotIndex] = defenseId
	DataService.MarkDirty(player.UserId)

	local plot = PlotManager.GetByOwner(player)
	if plot then
		-- Swapping a slot's turret type keeps whatever custom position was
		-- placed there, rather than resetting to the default corner spot.
		TurretController.Build(plot, slotIndex, defenseId, storedOffset(data, slotIndex))
	end

	return { ok = true, slotIndex = slotIndex, defenseId = defenseId }
end

-- Moves the turret already equipped in `slotIndex` to `localOffset`, a
-- position relative to the plot platform's own center, clamped to stay
-- clear of the platform's edge. Persists so it survives respawns/rejoins.
function EquipmentService.PlaceDefense(player, slotIndex, localOffset)
	local data = DataService.Get(player.UserId)
	if not data then
		return { ok = false, error = "no_data" }
	end
	if slotIndex < 1 or slotIndex > Config.TurretSlotsPerPlot then
		return { ok = false, error = "invalid_slot" }
	end
	if typeof(localOffset) ~= "Vector3" then
		return { ok = false, error = "invalid_position" }
	end

	local defenseId = data.EquippedDefenses[slotIndex]
	if not defenseId then
		return { ok = false, error = "slot_empty" }
	end

	local halfX = Config.PlotSize.X / 2 - Config.PlacementEdgeMargin
	local halfZ = Config.PlotSize.Z / 2 - Config.PlacementEdgeMargin
	local clampedX = math.clamp(localOffset.X, -halfX, halfX)
	local clampedZ = math.clamp(localOffset.Z, -halfZ, halfZ)

	data.DefensePositions = data.DefensePositions or {}
	data.DefensePositions[slotIndex] = { x = clampedX, z = clampedZ }
	DataService.MarkDirty(player.UserId)

	local plot = PlotManager.GetByOwner(player)
	if plot then
		TurretController.Build(plot, slotIndex, defenseId, Vector3.new(clampedX, 0, clampedZ))
	end

	return { ok = true, slotIndex = slotIndex, x = clampedX, z = clampedZ }
end

function EquipmentService.ApplyLoadout(player)
	local data = DataService.Get(player.UserId)
	local plot = PlotManager.GetByOwner(player)
	if not data or not plot then
		return
	end

	for slotIndex, defenseId in pairs(data.EquippedDefenses) do
		TurretController.Build(plot, slotIndex, defenseId, storedOffset(data, slotIndex))
	end
end

return EquipmentService
