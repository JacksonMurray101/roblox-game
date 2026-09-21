local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WheelData = require(ReplicatedStorage.Modules.WheelData)
local Rarity = require(ReplicatedStorage.Modules.Rarity)

local ShopUI = {}

function ShopUI.Init(player, remotes, GameState)
	local playerGui = player:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ShopUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local toggleButton = Instance.new("TextButton")
	toggleButton.Size = UDim2.new(0, 140, 0, 44)
	toggleButton.Position = UDim2.new(0, 20, 1, -60)
	toggleButton.AnchorPoint = Vector2.new(0, 1)
	toggleButton.Text = "Wheels"
	toggleButton.Font = Enum.Font.GothamBold
	toggleButton.TextScaled = true
	toggleButton.BackgroundColor3 = Color3.fromRGB(200, 160, 40)
	toggleButton.TextColor3 = Color3.new(1, 1, 1)
	toggleButton.Parent = screenGui

	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(0, 420, 0, 380)
	panel.Position = UDim2.new(0, 20, 1, -420)
	panel.AnchorPoint = Vector2.new(0, 1)
	panel.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
	panel.Visible = false
	panel.Parent = screenGui

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 34)
	title.BackgroundTransparency = 1
	title.Text = "Luck Wheels"
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Parent = panel

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 10)
	list.Parent = panel

	local listPadding = Instance.new("UIPadding")
	listPadding.PaddingTop = UDim.new(0, 40)
	listPadding.PaddingLeft = UDim.new(0, 12)
	listPadding.PaddingRight = UDim.new(0, 12)
	listPadding.Parent = panel

	local luckRow = Instance.new("TextButton")
	luckRow.Size = UDim2.new(1, 0, 0, 56)
	luckRow.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
	luckRow.Font = Enum.Font.GothamBold
	luckRow.TextScaled = true
	luckRow.TextColor3 = Color3.new(1, 1, 1)
	luckRow.Text = "Buy Luck +1"
	luckRow.LayoutOrder = 1
	luckRow.Parent = panel

	for index, wheel in ipairs(WheelData.List) do
		local row = Instance.new("TextButton")
		row.Size = UDim2.new(1, 0, 0, 56)
		row.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		row.Font = Enum.Font.GothamBold
		row.TextScaled = true
		row.TextColor3 = Color3.new(1, 1, 1)
		row.Text = ("%s -- %d coins"):format(wheel.name, wheel.cost)
		row.LayoutOrder = 1 + index
		row.Parent = panel

		row.MouseButton1Click:Connect(function()
			local result = remotes.SpinWheel:InvokeServer(wheel.id)
			if not result.ok then
				return
			end

			local reward = result.reward
			local text
			if reward.kind == "currency" then
				text = ("+%d coins"):format(reward.amount)
			elseif reward.kind == "luck" then
				text = ("+%d Luck!"):format(reward.amount)
			elseif reward.kind == "weapon" then
				text = "New weapon: " .. reward.id
			elseif reward.kind == "defense" then
				text = "New defense: " .. reward.id
			end

			row.Text = ("[%s] %s"):format(reward.rarity, text)
			row.TextColor3 = Rarity.Color[reward.rarity] or Color3.new(1, 1, 1)
			task.delay(1.5, function()
				if row.Parent then
					row.Text = ("%s -- %d coins"):format(wheel.name, wheel.cost)
					row.TextColor3 = Color3.new(1, 1, 1)
				end
			end)

			GameState.Currency = result.currency
			GameState.Luck = result.luck
			GameState.Notify()
		end)
	end

	luckRow.MouseButton1Click:Connect(function()
		local result = remotes.BuyLuckUpgrade:InvokeServer()
		if not result.ok then
			return
		end
		luckRow.Text = ("Luck is now %d"):format(result.luck)
		task.delay(1.5, function()
			if luckRow.Parent then
				luckRow.Text = "Buy Luck +1"
			end
		end)
		GameState.Luck = result.luck
		GameState.Notify()
	end)

	toggleButton.MouseButton1Click:Connect(function()
		panel.Visible = not panel.Visible
	end)
end

return ShopUI
