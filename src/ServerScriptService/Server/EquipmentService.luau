local WeaponData = require(game:GetService("ReplicatedStorage").Modules.WeaponData)
local DefenseData = require(game:GetService("ReplicatedStorage").Modules.DefenseData)
local Config = require(game:GetService("ReplicatedStorage").Modules.Config)

local DataService = require(script.Parent.DataService)
local PlotManager = require(script.Parent.PlotManager)
local TurretController = require(script.Parent.TurretController)

local EquipmentService = {}

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
		TurretController.Build(plot, slotIndex, defenseId)
	end

	return { ok = true, slotIndex = slotIndex, defenseId = defenseId }
end

function EquipmentService.ApplyLoadout(player)
	local data = DataService.Get(player.UserId)
	local plot = PlotManager.GetByOwner(player)
	if not data or not plot then
		return
	end

	for slotIndex, defenseId in pairs(data.EquippedDefenses) do
		TurretController.Build(plot, slotIndex, defenseId)
	end
end

return EquipmentService
