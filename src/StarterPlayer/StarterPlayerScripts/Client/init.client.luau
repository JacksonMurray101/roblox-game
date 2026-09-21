local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")

local remotes = {}
for _, child in ipairs(remotesFolder:GetChildren()) do
	remotes[child.Name] = child
end

local GameState = require(script.GameState)

remotes.StateUpdate.OnClientEvent:Connect(function(payload)
	if payload.currency ~= nil then
		GameState.Currency = payload.currency
	end
	if payload.luck ~= nil then
		GameState.Luck = payload.luck
	end
	if payload.ownedWeapons ~= nil then
		GameState.OwnedWeapons = payload.ownedWeapons
	end
	if payload.ownedDefenses ~= nil then
		GameState.OwnedDefenses = payload.ownedDefenses
	end
	if payload.equippedWeapon ~= nil then
		GameState.EquippedWeapon = payload.equippedWeapon
	end
	if payload.equippedDefenses ~= nil then
		GameState.EquippedDefenses = payload.equippedDefenses
	end
	if payload.plotId ~= nil then
		GameState.PlotId = payload.plotId
	end
	GameState.Notify()
end)

remotes.WaveStateUpdate.OnClientEvent:Connect(function(payload)
	GameState.Wave = payload.wave
	GameState.WaveState = payload.state
	GameState.WaveEndsAt = payload.endsAt
	GameState.ZombiesLeft = payload.zombiesLeft
	GameState.Notify()
end)

local HUD = require(script.HUD)
local ShopUI = require(script.ShopUI)
local EquipUI = require(script.EquipUI)
local WeaponController = require(script.WeaponController)

HUD.Init(player, remotes, GameState)
ShopUI.Init(player, remotes, GameState)
EquipUI.Init(player, remotes, GameState)
WeaponController.Init(player, remotes, GameState)
