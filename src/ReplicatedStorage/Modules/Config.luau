local Config = {}

Config.MaxPlots = 6
Config.PlotRadius = 140
Config.PlotSize = Vector3.new(40, 1, 40)
Config.MapCenter = Vector3.new(0, 5, 0)

Config.WaveCountdown = 20 -- seconds before a wave starts
Config.WaveCooldown = 15 -- seconds after a wave ends before the next countdown
Config.BaseZombiesPerWave = 4
Config.ZombiesPerWaveGrowth = 2
Config.BossWaveEvery = 5

Config.CurrencyPerSecondSurvived = 2
Config.CurrencyPerKill = 5
Config.WaveClearBonus = 50

Config.CoreMaxHealth = 500
Config.CoreRegenPerWaveCooldown = 100 -- healed between waves if the core survived

Config.StartingCurrency = 150
Config.StartingLuck = 0
Config.LuckUpgradeBaseCost = 200
Config.LuckUpgradeCostGrowth = 1.35
Config.LuckPerUpgrade = 1
Config.LuckWheelWeightBonus = 0.04 -- +4% weight shift toward non-Common rewards per luck point

Config.TurretSlotsPerPlot = 4
Config.PlacementEdgeMargin = 3 -- studs kept clear from a plot's platform edge when placing a turret

-- Default turret positions before a player has customized placement, as
-- offsets from the plot platform's own center (local space, so they follow
-- each plot's rotation automatically).
Config.DefaultTurretOffsets = {
	Vector3.new(-15, 0, -15),
	Vector3.new(15, 0, -15),
	Vector3.new(-15, 0, 15),
	Vector3.new(15, 0, 15),
}

Config.StarterWeaponId = "pistol"
Config.StarterDefenseId = "basic_turret"

Config.DataStoreName = "SpinAndSurvive_PlayerData_v1"
Config.AutosaveInterval = 120

return Config
