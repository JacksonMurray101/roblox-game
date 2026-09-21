-- Declares every client<->server remote the bootstrap script creates under
-- ReplicatedStorage.Remotes, and whether each is an event (fire-and-forget)
-- or a function (request/response).
return {
	{ name = "ToggleWaveParticipation", kind = "RemoteEvent" },
	{ name = "FireWeapon", kind = "RemoteEvent" },
	{ name = "StateUpdate", kind = "RemoteEvent" },
	{ name = "WaveStateUpdate", kind = "RemoteEvent" },
	{ name = "EquipWeapon", kind = "RemoteFunction" },
	{ name = "EquipDefense", kind = "RemoteFunction" },
	{ name = "SpinWheel", kind = "RemoteFunction" },
	{ name = "BuyLuckUpgrade", kind = "RemoteFunction" },
}
