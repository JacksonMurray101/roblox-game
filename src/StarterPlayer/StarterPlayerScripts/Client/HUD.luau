local Workspace = game:GetService("Workspace")

local HUD = {}

function HUD.Init(player, remotes, GameState)
	local playerGui = player:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HUD"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.Size = UDim2.new(1, 0, 0, 60)
	topBar.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	topBar.BackgroundTransparency = 0.2
	topBar.BorderSizePixel = 0
	topBar.Parent = screenGui

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 20)
	layout.Parent = topBar

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 20)
	padding.Parent = topBar

	local function makeStat(name, prefix)
		local label = Instance.new("TextLabel")
		label.Name = name
		label.Size = UDim2.new(0, 160, 1, 0)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Text = prefix .. "0"
		label.Parent = topBar
		return label
	end

	local currencyLabel = makeStat("Currency", "Coins: ")
	local luckLabel = makeStat("Luck", "Luck: ")
	local waveLabel = makeStat("Wave", "Wave: ")

	local optButton = Instance.new("TextButton")
	optButton.Name = "OptButton"
	optButton.Size = UDim2.new(0, 180, 0, 40)
	optButton.AnchorPoint = Vector2.new(1, 0.5)
	optButton.Position = UDim2.new(1, -20, 0.5, 0)
	optButton.Font = Enum.Font.GothamBold
	optButton.TextScaled = true
	optButton.Text = "Opted In"
	optButton.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
	optButton.TextColor3 = Color3.new(1, 1, 1)
	optButton.Parent = topBar

	local optedIn = true
	optButton.MouseButton1Click:Connect(function()
		optedIn = not optedIn
		remotes.ToggleWaveParticipation:FireServer(optedIn)
		optButton.Text = optedIn and "Opted In" or "Opted Out (Shielded)"
		optButton.BackgroundColor3 = optedIn and Color3.fromRGB(60, 180, 90) or Color3.fromRGB(180, 70, 70)
	end)

	local timerLabel = Instance.new("TextLabel")
	timerLabel.Name = "Timer"
	timerLabel.Size = UDim2.new(0, 320, 0, 34)
	timerLabel.AnchorPoint = Vector2.new(0.5, 0)
	timerLabel.Position = UDim2.new(0.5, 0, 0, 66)
	timerLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	timerLabel.BackgroundTransparency = 0.3
	timerLabel.Font = Enum.Font.GothamBold
	timerLabel.TextScaled = true
	timerLabel.TextColor3 = Color3.new(1, 1, 1)
	timerLabel.Text = ""
	timerLabel.Parent = screenGui

	GameState.OnChange(function()
		currencyLabel.Text = "Coins: " .. GameState.Currency
		luckLabel.Text = "Luck: " .. GameState.Luck
		waveLabel.Text = "Wave: " .. GameState.Wave
	end)

	task.spawn(function()
		while screenGui.Parent do
			local remaining = math.max(0, math.floor(GameState.WaveEndsAt - Workspace:GetServerTimeNow()))
			if GameState.WaveState == "Countdown" then
				timerLabel.Text = ("Next wave in %ds"):format(remaining)
			elseif GameState.WaveState == "Active" then
				timerLabel.Text = ("Wave %d -- %d zombies left"):format(GameState.Wave, GameState.ZombiesLeft)
			else
				timerLabel.Text = "Rebuilding..."
			end
			task.wait(0.5)
		end
	end)
end

return HUD
