-- Lets the player drop an already-equipped turret anywhere on their own
-- plot: shows a ghost marker that follows the mouse (green if the spot is
-- valid, red if it's outside the platform), confirms on left-click, and
-- cancels on Escape or right-click.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local PlacementController = {}

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local active = false
local activeSlot = nil
local ghost
local heartbeatConn
local inputConn

local remotes, gameState

local function getPlatform()
	local plotId = gameState and gameState.PlotId
	if not plotId then
		return nil
	end
	local plots = Workspace:FindFirstChild("Plots")
	local plotModel = plots and plots:FindFirstChild("Plot" .. plotId)
	return plotModel and plotModel:FindFirstChild("Platform")
end

local function makeGhost()
	local part = Instance.new("Part")
	part.Name = "PlacementGhost"
	part.Size = Vector3.new(3, 4, 3)
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Transparency = 0.4
	part.Material = Enum.Material.ForceField
	part.Color = Color3.fromRGB(90, 220, 120)
	part.Parent = Workspace
	return part
end

local function clampToPlatform(platform, worldPoint)
	local halfX = platform.Size.X / 2 - 3
	local halfZ = platform.Size.Z / 2 - 3
	local localPoint = platform.CFrame:PointToObjectSpace(worldPoint)
	local valid = math.abs(localPoint.X) <= halfX and math.abs(localPoint.Z) <= halfZ
	local clampedLocal = Vector3.new(math.clamp(localPoint.X, -halfX, halfX), 0, math.clamp(localPoint.Z, -halfZ, halfZ))
	return clampedLocal, valid
end

function PlacementController.Stop()
	active = false
	activeSlot = nil
	if ghost then
		ghost:Destroy()
		ghost = nil
	end
	if heartbeatConn then
		heartbeatConn:Disconnect()
		heartbeatConn = nil
	end
	if inputConn then
		inputConn:Disconnect()
		inputConn = nil
	end
end

function PlacementController.Init(remotesTable, GameState)
	remotes = remotesTable
	gameState = GameState
end

function PlacementController.IsActive()
	return active
end

function PlacementController.Begin(slotIndex)
	PlacementController.Stop()

	local platform = getPlatform()
	if not platform then
		return
	end

	active = true
	activeSlot = slotIndex
	ghost = makeGhost()

	heartbeatConn = RunService.Heartbeat:Connect(function()
		local hit = mouse.Hit
		if not hit then
			return
		end

		local clampedLocal, valid = clampToPlatform(platform, hit.Position)
		local worldPoint = platform.CFrame:PointToWorldSpace(clampedLocal)
		ghost.Position = Vector3.new(worldPoint.X, platform.Position.Y + platform.Size.Y / 2 + 2, worldPoint.Z)
		ghost.Color = valid and Color3.fromRGB(90, 220, 120) or Color3.fromRGB(220, 80, 80)
	end)

	inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if input.KeyCode == Enum.KeyCode.Escape or input.UserInputType == Enum.UserInputType.MouseButton2 then
			PlacementController.Stop()
			return
		end

		if gameProcessed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end

		local hit = mouse.Hit
		if not hit then
			return
		end

		local clampedLocal = clampToPlatform(platform, hit.Position)
		local slot = activeSlot
		PlacementController.Stop()
		remotes.PlaceDefense:InvokeServer(slot, clampedLocal)
	end)
end

return PlacementController
