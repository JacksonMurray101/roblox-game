-- Wheel reward kinds: "currency" (amount), "luck" (amount), "weapon" (id), "defense" (id).
-- Each reward's weight is shifted by the spinning player's Luck stat: see WheelService.
local WheelData = {}

WheelData.List = {
	{
		id = "bronze",
		name = "Bronze Wheel",
		cost = 100,
		rewards = {
			{ rarity = "Common", weight = 70, kind = "currency", amount = 80 },
			{ rarity = "Common", weight = 20, kind = "weapon", id = "smg" },
			{ rarity = "Rare", weight = 8, kind = "defense", id = "cannon_turret" },
			{ rarity = "Rare", weight = 2, kind = "luck", amount = 1 },
		},
	},
	{
		id = "silver",
		name = "Silver Wheel",
		cost = 500,
		rewards = {
			{ rarity = "Common", weight = 45, kind = "currency", amount = 400 },
			{ rarity = "Rare", weight = 30, kind = "weapon", id = "shotgun" },
			{ rarity = "Rare", weight = 15, kind = "weapon", id = "sniper" },
			{ rarity = "Epic", weight = 8, kind = "defense", id = "flame_turret" },
			{ rarity = "Epic", weight = 2, kind = "luck", amount = 2 },
		},
	},
	{
		id = "gold",
		name = "Gold Wheel",
		cost = 2000,
		rewards = {
			{ rarity = "Rare", weight = 35, kind = "currency", amount = 1500 },
			{ rarity = "Epic", weight = 30, kind = "weapon", id = "laser_rifle" },
			{ rarity = "Epic", weight = 20, kind = "defense", id = "tesla_turret" },
			{ rarity = "Legendary", weight = 10, kind = "weapon", id = "rocket_launcher" },
			{ rarity = "Legendary", weight = 5, kind = "luck", amount = 5 },
		},
	},
}

WheelData.ById = {}
for _, wheel in ipairs(WheelData.List) do
	WheelData.ById[wheel.id] = wheel
end

return WheelData
