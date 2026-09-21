-- Turrets: placed on a plot's slot pads, fire automatically at zombies targeting that plot.
local DefenseData = {}

DefenseData.List = {
	{
		id = "basic_turret",
		name = "Basic Turret",
		rarity = "Common",
		damage = 10,
		fireRate = 2,
		range = 45,
		color = Color3.fromRGB(150, 150, 150),
	},
	{
		id = "rapid_turret",
		name = "Rapid Turret",
		rarity = "Common",
		damage = 5,
		fireRate = 6,
		range = 40,
		color = Color3.fromRGB(120, 170, 120),
	},
	{
		id = "cannon_turret",
		name = "Cannon Turret",
		rarity = "Rare",
		damage = 60,
		fireRate = 0.9,
		range = 55,
		color = Color3.fromRGB(90, 90, 200),
	},
	{
		id = "frost_turret",
		name = "Frost Turret",
		rarity = "Rare",
		damage = 8,
		fireRate = 2.5,
		range = 40,
		slowFactor = 0.5,
		slowDuration = 2.5,
		color = Color3.fromRGB(120, 200, 255),
	},
	{
		id = "flame_turret",
		name = "Flame Turret",
		rarity = "Epic",
		damage = 14,
		fireRate = 5,
		range = 30,
		color = Color3.fromRGB(255, 120, 40),
	},
	{
		id = "tesla_turret",
		name = "Tesla Turret",
		rarity = "Legendary",
		damage = 35,
		fireRate = 3,
		range = 50,
		color = Color3.fromRGB(255, 230, 60),
	},
}

DefenseData.ById = {}
for _, defense in ipairs(DefenseData.List) do
	DefenseData.ById[defense.id] = defense
end

return DefenseData
