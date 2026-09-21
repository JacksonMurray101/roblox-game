-- Plain shared state table, updated from server remotes and read by the UI modules.
local GameState = {}

GameState.Currency = 0
GameState.Luck = 0
GameState.OwnedWeapons = {}
GameState.OwnedDefenses = {}
GameState.EquippedWeapon = nil
GameState.EquippedDefenses = {}
GameState.PlotId = nil

GameState.Wave = 0
GameState.WaveState = "Cooldown"
GameState.WaveEndsAt = 0
GameState.ZombiesLeft = 0

GameState._listeners = {}

function GameState.OnChange(fn)
	table.insert(GameState._listeners, fn)
end

function GameState.Notify()
	for _, fn in ipairs(GameState._listeners) do
		fn()
	end
end

return GameState
