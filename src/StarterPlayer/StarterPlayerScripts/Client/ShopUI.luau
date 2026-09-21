local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local WheelData = require(ReplicatedStorage.Modules.WheelData)
local Rarity = require(ReplicatedStorage.Modules.Rarity)

local ShopUI = {}

local WHEEL_DIAMETER = 120
local EXTRA_SPINS = 4 * 360
local SPIN_TIME = 2.2

local function rounded(instance, scale)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(scale or 0.5, 0)
	corner.Parent = instance
	return corner
end

-- Builds one circular wheel: an outer ring, a rotating disc with a colored
-- segment per reward (tinted by rarity), a center hub, and a fixed pointer.
-- Clicking Spin calls the server, then spins the disc to land the real
-- winning segment under the pointer.
local function buildWheelWidget(parent, wheel, remotes, GameState)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(0, 140, 1, 0)
	container.BackgroundTransparency = 1
	container.Parent = parent

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 20)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.Text = wheel.name
	nameLabel.Parent = container

	local wheelHolder = Instance.new("Frame")
	wheelHolder.Size = UDim2.fromOffset(WHEEL_DIAMETER, WHEEL_DIAMETER)
	wheelHolder.Position = UDim2.new(0.5, 0, 0, 26)
	wheelHolder.AnchorPoint = Vector2.new(0.5, 0)
	wheelHolder.BackgroundTransparency = 1
	wheelHolder.Parent = container

	local ring = Instance.new("Frame")
	ring.Size = UDim2.fromScale(1, 1)
	ring.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	ring.Parent = wheelHolder
	rounded(ring)

	local disc = Instance.new("Frame")
	disc.Name = "Disc"
	disc.Size = UDim2.fromScale(0.88, 0.88)
	disc.AnchorPoint = Vector2.new(0.5, 0.5)
	disc.Position = UDim2.fromScale(0.5, 0.5)
	disc.BackgroundColor3 = Color3.fromRGB(55, 45, 30)
	disc.Parent = ring
	rounded(disc)

	local segmentAngle = 360 / #wheel.rewards
	local segmentRotations = {} -- [reward table] = disc-local rotation (degrees)

	for i, reward in ipairs(wheel.rewards) do
		local segment = Instance.new("Frame")
		segment.AnchorPoint = Vector2.new(0.5, 1)
		segment.Position = UDim2.fromScale(0.5, 0.5)
		segment.Size = UDim2.new(0, 12, 0, WHEEL_DIAMETER * 0.36)
		segment.BackgroundColor3 = Rarity.Color[reward.rarity] or Color3.new(1, 1, 1)
		segment.BorderSizePixel = 0
		segment.Rotation = (i - 1) * segmentAngle
		segment.Parent = disc
		rounded(segment, 0.4)
		segmentRotations[reward] = segment.Rotation
	end

	local hub = Instance.new("Frame")
	hub.AnchorPoint = Vector2.new(0.5, 0.5)
	hub.Position = UDim2.fromScale(0.5, 0.5)
	hub.Size = UDim2.fromScale(0.34, 0.34)
	hub.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
	hub.ZIndex = 2
	hub.Parent = disc
	rounded(hub)

	local pointer = Instance.new("Frame")
	pointer.AnchorPoint = Vector2.new(0.5, 0)
	pointer.Position = UDim2.new(0.5, 0, 0, -6)
	pointer.Size = UDim2.fromOffset(14, 14)
	pointer.Rotation = 45
	pointer.BackgroundColor3 = Color3.fromRGB(255, 220, 80)
	pointer.BorderSizePixel = 0
	pointer.ZIndex = 3
	pointer.Parent = wheelHolder

	local spinButton = Instance.new("TextButton")
	spinButton.Size = UDim2.new(1, 0, 0, 30)
	spinButton.Position = UDim2.new(0, 0, 1, -30)
	spinButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	spinButton.Font = Enum.Font.GothamBold
	spinButton.TextScaled = true
	spinButton.TextColor3 = Color3.new(1, 1, 1)
	spinButton.Text = ("Spin -- %d"):format(wheel.cost)
	spinButton.Parent = container

	local spinning = false

	spinButton.MouseButton1Click:Connect(function()
		if spinning then
			return
		end

		local result = remotes.SpinWheel:InvokeServer(wheel.id)
		if not result.ok then
			return
		end

		spinning = true
		spinButton.Text = "..."

		-- Match the server's result back to this wheel's local reward table
		-- by index (not by reference -- RemoteFunction results are copies),
		-- so the disc lands on the segment that actually won.
		local localReward = result.reward.index and wheel.rewards[result.reward.index]
		local landingRotation = localReward and segmentRotations[localReward]

		if landingRotation then
			local targetOffset = (-landingRotation) % 360
			local currentMod = disc.Rotation % 360
			local delta = EXTRA_SPINS + ((targetOffset - currentMod) % 360)

			local tween = TweenService:Create(
				disc,
				TweenInfo.new(SPIN_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				{ Rotation = disc.Rotation + delta }
			)
			tween:Play()
			tween.Completed:Wait()
		end

		GameState.Currency = result.currency
		GameState.Luck = result.luck
		GameState.Notify()

		spinButton.Text = ("[%s]"):format(result.reward.rarity)
		task.delay(1.2, function()
			if spinButton.Parent then
				spinButton.Text = ("Spin -- %d"):format(wheel.cost)
			end
			spinning = false
		end)
	end)
end

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
	panel.Size = UDim2.new(0, 460, 0, 320)
	panel.Position = UDim2.new(0, 20, 1, -400)
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
	title.LayoutOrder = 0
	title.Parent = panel

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 10)
	list.Parent = panel

	local listPadding = Instance.new("UIPadding")
	listPadding.PaddingTop = UDim.new(0, 8)
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

	local wheelsRow = Instance.new("Frame")
	wheelsRow.Size = UDim2.new(1, 0, 0, 190)
	wheelsRow.BackgroundTransparency = 1
	wheelsRow.LayoutOrder = 2
	wheelsRow.Parent = panel

	local wheelsLayout = Instance.new("UIListLayout")
	wheelsLayout.FillDirection = Enum.FillDirection.Horizontal
	wheelsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	wheelsLayout.Padding = UDim.new(0, 10)
	wheelsLayout.Parent = wheelsRow

	for _, wheel in ipairs(WheelData.List) do
		buildWheelWidget(wheelsRow, wheel, remotes, GameState)
	end

	toggleButton.MouseButton1Click:Connect(function()
		panel.Visible = not panel.Visible
	end)
end

return ShopUI
