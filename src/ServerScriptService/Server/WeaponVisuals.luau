-- Builds a small distinct gun model per weapon type and welds it into a
-- player's hand so everyone in the server can see what they're holding.
-- Welded (not anchored) so it rides along with the character's rig.
local WeaponData = require(game:GetService("ReplicatedStorage").Modules.WeaponData)

local WeaponVisuals = {}

local DARK_METAL = Color3.fromRGB(35, 35, 40)
local MODEL_NAME = "HeldWeapon"

local function part(model, name, size, cframe, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.Metal
	p.CanCollide = false
	p.Parent = model
	return p
end

-- A cylinder Part's native long axis is local X; rotating 90 degrees
-- around Y points it along Z so it reads as a barrel aimed forward.
local function cylinderPart(model, name, length, radius, cframe, color, material)
	local p = part(model, name, Vector3.new(length, radius * 2, radius * 2), cframe * CFrame.Angles(0, math.rad(90), 0), color, material)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function buildWeaponModel(weapon)
	local model = Instance.new("Model")
	model.Name = MODEL_NAME

	local grip = part(model, "Grip", Vector3.new(0.5, 0.5, 0.5), CFrame.new(), DARK_METAL)

	if weapon.id == "pistol" then
		part(model, "Body", Vector3.new(0.6, 0.9, 1.6), grip.CFrame * CFrame.new(0, 0.3, -0.5), DARK_METAL)
		cylinderPart(model, "Barrel", 1.2, 0.14, grip.CFrame * CFrame.new(0, 0.5, -1.5), DARK_METAL)
	elseif weapon.id == "smg" then
		part(model, "Body", Vector3.new(0.6, 0.8, 2), grip.CFrame * CFrame.new(0, 0.3, -1), DARK_METAL)
		cylinderPart(model, "Barrel", 1.4, 0.14, grip.CFrame * CFrame.new(0, 0.5, -2.4), DARK_METAL)
		part(model, "Foregrip", Vector3.new(0.5, 0.9, 0.5), grip.CFrame * CFrame.new(0, -0.4, -1.6), DARK_METAL)
	elseif weapon.id == "shotgun" then
		part(model, "Body", Vector3.new(0.7, 0.9, 1.6), grip.CFrame * CFrame.new(0, 0.3, -0.6), Color3.fromRGB(90, 60, 35), Enum.Material.Wood)
		cylinderPart(model, "BarrelA", 2.6, 0.16, grip.CFrame * CFrame.new(-0.15, 0.5, -2.4), DARK_METAL)
		cylinderPart(model, "BarrelB", 2.6, 0.16, grip.CFrame * CFrame.new(0.15, 0.5, -2.4), DARK_METAL)
	elseif weapon.id == "sniper" then
		part(model, "Body", Vector3.new(0.5, 0.7, 2.2), grip.CFrame * CFrame.new(0, 0.3, -1.1), DARK_METAL)
		cylinderPart(model, "Barrel", 3.4, 0.12, grip.CFrame * CFrame.new(0, 0.45, -3.6), DARK_METAL)
		part(model, "Scope", Vector3.new(0.3, 0.3, 1), grip.CFrame * CFrame.new(0, 0.75, -1.2), Color3.fromRGB(20, 20, 20))
	elseif weapon.id == "assault_rifle" then
		part(model, "Body", Vector3.new(0.6, 0.9, 2.2), grip.CFrame * CFrame.new(0, 0.3, -1.1), Color3.fromRGB(60, 65, 55))
		cylinderPart(model, "Barrel", 1.8, 0.13, grip.CFrame * CFrame.new(0, 0.5, -2.8), DARK_METAL)
		part(model, "Magazine", Vector3.new(0.4, 1, 0.5), grip.CFrame * CFrame.new(0, -0.5, -0.9), DARK_METAL)
		part(model, "Sight", Vector3.new(0.2, 0.35, 0.4), grip.CFrame * CFrame.new(0, 0.75, -1), Color3.fromRGB(20, 20, 20))
	elseif weapon.id == "laser_rifle" then
		part(model, "Body", Vector3.new(0.6, 0.8, 1.8), grip.CFrame * CFrame.new(0, 0.3, -0.9), Color3.fromRGB(60, 70, 80))
		cylinderPart(model, "Barrel", 2, 0.15, grip.CFrame * CFrame.new(0, 0.45, -2.4), Color3.fromRGB(80, 255, 140), Enum.Material.Neon)
	elseif weapon.id == "rocket_launcher" then
		cylinderPart(model, "Tube", 3.4, 0.5, grip.CFrame * CFrame.new(0, 0.6, -1.8), Color3.fromRGB(70, 65, 55))
		part(model, "Sight", Vector3.new(0.2, 0.4, 0.2), grip.CFrame * CFrame.new(0, 1.15, -0.6), Color3.fromRGB(20, 20, 20))
	elseif weapon.id == "minigun" then
		part(model, "Body", Vector3.new(0.8, 1, 1.4), grip.CFrame * CFrame.new(0, 0.2, -0.8), DARK_METAL)
		cylinderPart(model, "BarrelA", 2.2, 0.1, grip.CFrame * CFrame.new(-0.2, 0.4, -2), Color3.fromRGB(120, 30, 30))
		cylinderPart(model, "BarrelB", 2.2, 0.1, grip.CFrame * CFrame.new(0, 0.4, -2), Color3.fromRGB(120, 30, 30))
		cylinderPart(model, "BarrelC", 2.2, 0.1, grip.CFrame * CFrame.new(0.2, 0.4, -2), Color3.fromRGB(120, 30, 30))
	end

	model.PrimaryPart = grip
	return model
end

-- Removes any previous held model, builds the one for `weaponId`, and welds
-- it to the character's hand (R15 RightHand, falling back to R6 Right Arm).
function WeaponVisuals.Attach(player, weaponId)
	local weapon = WeaponData.ById[weaponId]
	if not weapon then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local existing = character:FindFirstChild(MODEL_NAME)
	if existing then
		existing:Destroy()
	end

	local handPart = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	if not handPart then
		return
	end

	local model = buildWeaponModel(weapon)
	model.Parent = character

	local heldOffset = CFrame.new(0.15, -0.1, -0.4) * CFrame.Angles(math.rad(-90), 0, 0)
	model:PivotTo(handPart.CFrame * heldOffset)

	local weldConstraint = Instance.new("WeldConstraint")
	weldConstraint.Part0 = handPart
	weldConstraint.Part1 = model.PrimaryPart
	weldConstraint.Parent = model.PrimaryPart
end

return WeaponVisuals
