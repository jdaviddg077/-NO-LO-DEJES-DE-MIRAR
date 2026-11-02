Slocal TouchPart = game.Workspace:WaitForChild("gui 2") -- se cambia segun la cantidad de guis que hay 
local gui = script.Parent -- screen gui
TouchPart.Touched:Connect(function(hit)
	if hit.Parent:FindFirstChild("Humanoid") and hit.Parent == game.Players.LocalPlayer.Character then
		gui.Enabled = true
	end
end)