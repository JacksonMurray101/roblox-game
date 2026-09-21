local ZombieData = {}

ZombieData.List = {
	{
		id = "walker",
		name = "Walker",
		health = 40,
		speed = 8,
		damage = 6,
		reward = 4,
		color = Color3.fromRGB(80, 120, 80),
		minWave = 1,
	},
	{
		id = "runner",
		name = "Runner",
		health = 25,
		speed = 16,
		damage = 4,
		reward = 5,
		color = Color3.fromRGB(150, 170, 60),
		minWave = 2,
	},
	{
		id = "brute",
		name = "Brute",
		health = 160,
		speed = 6,
		damage = 15,
		reward = 12,
		color = Color3.fromRGB(90, 60, 60),
		minWave = 3,
	},
	{
		id = "spitter",
		name = "Spitter",
		health = 55,
		speed = 7,
		damage = 8,
		reward = 8,
		ranged = true,
		attackRange = 25,
		color = Color3.fromRGB(120, 60, 150),
		minWave = 4,
	},
	{
		id = "boss",
		name = "Zombie Titan",
		health = 1200,
		speed = 5,
		damage = 40,
		reward = 150,
		color = Color3.fromRGB(40, 20, 20),
		minWave = 5,
		isBoss = true,
	},
}

ZombieData.ById = {}
for _, zombie in ipairs(ZombieData.List) do
	ZombieData.ById[zombie.id] = zombie
end

return ZombieData
