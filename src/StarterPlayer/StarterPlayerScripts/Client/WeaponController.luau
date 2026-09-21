local UserInputService = game:GetService("UserInputService")

local PlacementController = require(script.Parent.PlacementController)

local WeaponController = {}

function WeaponController.Init(player, remotes, GameState)
	local mouse = player:GetMouse()

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		if not GameState.EquippedWeapon then
			return
		end
		if PlacementController.IsActive() then
			return
		end

		local target = mouse.Hit and mouse.Hit.Position
		if not target then
			return
		end

		remotes.FireWeapon:FireServer(target)
	end)
end

return WeaponController
