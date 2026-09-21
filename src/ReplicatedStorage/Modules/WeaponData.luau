-- Player hand-weapons: hitscan, fired manually by the player at zombies.
local WeaponData = {}

WeaponData.List = {
	{
		id = "pistol",
		name = "Pistol",
		rarity = "Common",
		damage = 12,
		fireRate = 3, -- shots per second
		range = 60,
	},
	{
		id = "smg",
		name = "SMG",
		rarity = "Common",
		damage = 7,
		fireRate = 8,
		range = 55,
	},
	{
		id = "shotgun",
		name = "Shotgun",
		rarity = "Rare",
		damage = 45,
		fireRate = 1.2,
		range = 30,
	},
	{
		id = "sniper",
		name = "Sniper",
		rarity = "Rare",
		damage = 90,
		fireRate = 0.8,
		range = 150,
	},
	{
		id = "laser_rifle",
		name = "Laser Rifle",
		rarity = "Epic",
		damage = 25,
		fireRate = 6,
		range = 90,
	},
	{
		id = "rocket_launcher",
		name = "Rocket Launcher",
		rarity = "Legendary",
		damage = 150,
		fireRate = 0.5,
		range = 100,
	},
}

WeaponData.ById = {}
for _, weapon in ipairs(WeaponData.List) do
	WeaponData.ById[weapon.id] = weapon
end

return WeaponData
