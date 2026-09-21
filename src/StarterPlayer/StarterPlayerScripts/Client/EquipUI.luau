local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponData = require(ReplicatedStorage.Modules.WeaponData)
local DefenseData = require(ReplicatedStorage.Modules.DefenseData)
local Config = require(ReplicatedStorage.Modules.Config)

local EquipUI = {}

local function makeRow(parent, text, color)
	local row = Instance.new("TextButton")
	row.Size = UDim2.new(1, 0, 0, 40)
	row.BackgroundColor3 = color or Color3.fromRGB(40, 40, 50)
	row.Font = Enum.Font.GothamBold
	row.TextScaled = true
	row.TextColor3 = Color3.new(1, 1, 1)
	row.Text = text
	row.Parent = parent
	return row
end

function EquipUI.Init(player, remotes, GameState)
	local playerGui = player:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "EquipUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local toggleButton = Instance.new("TextButton")
	toggleButton.Size = UDim2.new(0, 140, 0, 44)
	toggleButton.Position = UDim2.new(0, 170, 1, -60)
	toggleButton.AnchorPoint = Vector2.new(0, 1)
	toggleButton.Text = "Loadout"
	toggleButton.Font = Enum.Font.GothamBold
	toggleButton.TextScaled = true
	toggleButton.BackgroundColor3 = Color3.fromRGB(70, 130, 200)
	toggleButton.TextColor3 = Color3.new(1, 1, 1)
	toggleButton.Parent = screenGui

	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(0, 460, 0, 440)
	panel.Position = UDim2.new(0, 170, 1, -500)
	panel.AnchorPoint = Vector2.new(0, 1)
	panel.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
	panel.Visible = false
	panel.Parent = screenGui

	local weaponLabel = Instance.new("TextLabel")
	weaponLabel.Size = UDim2.new(1, 0, 0, 26)
	weaponLabel.Position = UDim2.new(0, 12, 0, 6)
	weaponLabel.BackgroundTransparency = 1
	weaponLabel.Text = "Weapon"
	weaponLabel.Font = Enum.Font.GothamBold
	weaponLabel.TextScaled = true
	weaponLabel.TextColor3 = Color3.new(1, 1, 1)
	weaponLabel.Parent = panel

	local weaponList = Instance.new("Frame")
	weaponList.Size = UDim2.new(1, -24, 0, 180)
	weaponList.Position = UDim2.new(0, 12, 0, 34)
	weaponList.BackgroundTransparency = 1
	weaponList.Parent = panel

	local weaponLayout = Instance.new("UIListLayout")
	weaponLayout.Padding = UDim.new(0, 6)
	weaponLayout.Parent = weaponList

	local defenseLabel = Instance.new("TextLabel")
	defenseLabel.Size = UDim2.new(1, 0, 0, 26)
	defenseLabel.Position = UDim2.new(0, 12, 0, 220)
	defenseLabel.BackgroundTransparency = 1
	defenseLabel.Text = "Defenses (choose a slot, then a turret)"
	defenseLabel.Font = Enum.Font.GothamBold
	defenseLabel.TextScaled = true
	defenseLabel.TextColor3 = Color3.new(1, 1, 1)
	defenseLabel.Parent = panel

	local slotTabs = Instance.new("Frame")
	slotTabs.Size = UDim2.new(1, -24, 0, 30)
	slotTabs.Position = UDim2.new(0, 12, 0, 250)
	slotTabs.BackgroundTransparency = 1
	slotTabs.Parent = panel

	local slotTabLayout = Instance.new("UIListLayout")
	slotTabLayout.FillDirection = Enum.FillDirection.Horizontal
	slotTabLayout.Padding = UDim.new(0, 6)
	slotTabLayout.Parent = slotTabs

	local defenseList = Instance.new("Frame")
	defenseList.Size = UDim2.new(1, -24, 0, 150)
	defenseList.Position = UDim2.new(0, 12, 0, 286)
	defenseList.BackgroundTransparency = 1
	defenseList.Parent = panel

	local defenseLayout = Instance.new("UIListLayout")
	defenseLayout.Padding = UDim.new(0, 6)
	defenseLayout.Parent = defenseList

	local selectedSlot = 1

	local function refreshWeapons()
		for _, child in ipairs(weaponList:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		for _, weapon in ipairs(WeaponData.List) do
			if GameState.OwnedWeapons[weapon.id] then
				local equipped = GameState.EquippedWeapon == weapon.id
				local row = makeRow(
					weaponList,
					("%s%s"):format(weapon.name, equipped and "  [Equipped]" or ""),
					equipped and Color3.fromRGB(60, 140, 90) or nil
				)
				row.MouseButton1Click:Connect(function()
					local result = remotes.EquipWeapon:InvokeServer(weapon.id)
					if result.ok then
						GameState.EquippedWeapon = result.weaponId
						GameState.Notify()
					end
				end)
			end
		end
	end

	local function refreshDefenses()
		for _, child in ipairs(defenseList:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		for _, defense in ipairs(DefenseData.List) do
			if GameState.OwnedDefenses[defense.id] then
				local equipped = GameState.EquippedDefenses[selectedSlot] == defense.id
				local row = makeRow(
					defenseList,
					("%s%s"):format(defense.name, equipped and "  [Equipped]" or ""),
					equipped and Color3.fromRGB(60, 140, 90) or nil
				)
				row.MouseButton1Click:Connect(function()
					local result = remotes.EquipDefense:InvokeServer(selectedSlot, defense.id)
					if result.ok then
						GameState.EquippedDefenses[selectedSlot] = defense.id
						GameState.Notify()
					end
				end)
			end
		end
	end

	local function refreshSlotTabs()
		for _, child in ipairs(slotTabs:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		for slotIndex = 1, Config.TurretSlotsPerPlot do
			local tab = makeRow(
				slotTabs,
				"Slot " .. slotIndex,
				slotIndex == selectedSlot and Color3.fromRGB(70, 130, 200) or nil
			)
			tab.Size = UDim2.new(0, 100, 1, 0)
			tab.MouseButton1Click:Connect(function()
				selectedSlot = slotIndex
				refreshSlotTabs()
				refreshDefenses()
			end)
		end
	end

	GameState.OnChange(function()
		refreshWeapons()
		refreshDefenses()
	end)

	toggleButton.MouseButton1Click:Connect(function()
		panel.Visible = not panel.Visible
		if panel.Visible then
			refreshWeapons()
			refreshSlotTabs()
			refreshDefenses()
		end
	end)

	refreshSlotTabs()
end

return EquipUI
