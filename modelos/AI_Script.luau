local npc = script.Parent
local humanoid = npc:WaitForChild("Humanoid")
local npcRoot = npc:WaitForChild("HumanoidRootPart")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")

local jumpscareEvent = ReplicatedStorage:WaitForChild("JumpscareEvent")

local VELOCIDAD_PERSECUCION = 100
local DISTANCIA_KILL = 4

-- Configuración del Raycast para detectar visión (con cristales)
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = true

local function isPlayerLooking(player)
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Head") then return false end

	local root = character.HumanoidRootPart
	local head = character.Head

	local toNPC = (npcRoot.Position - root.Position).Unit
	local lookVector = root.CFrame.LookVector

	local dot = lookVector:Dot(toNPC)
	if dot <= 0.2 then 
		return false 
	end

	raycastParams.FilterDescendantsInstances = {character, npc}
	local origen = head.Position
	local destino = npcRoot.Position + Vector3.new(0, 2, 0)
	local direccion = destino - origen

	local resultadoRaycast = workspace:Raycast(origen, direccion, raycastParams)

	if resultadoRaycast then
		local parteImpactada = resultadoRaycast.Instance
		
		if parteImpactada.Transparency > 0 or parteImpactada.Name:lower():find("cristal") or parteImpactada.Name:lower():find("ventana") then
			return false 
		else
			return true
		end
	end

	return true
end

local function moverHacia(destinoPos)
	local path = PathfindingService:CreatePath({
		AgentRadius = 2,      -- Radio del NPC (ancho)
		AgentHeight = 5,      -- Altura del NPC
		AgentCanJump = true,  -- Permitir que salte si hay pequeños baches
	})

	local success, errorMessage = pcall(function()
		path:ComputeAsync(npcRoot.Position, destinoPos)
	end)

	if success and path.Status == Enum.PathStatus.Success then
		local waypoints = path:GetWaypoints()

		
		if #waypoints >= 2 then
			humanoid:MoveTo(waypoints[2].Position)
		else
			humanoid:MoveTo(destinoPos)
		end
	else
		
		humanoid:MoveTo(destinoPos)
	end
end

task.spawn(function()
	while task.wait(0.2) do -- Un pequeño intervalo de 0.2 segundos va perfecto para calcular rutas sin saturar el juego
		local closestPlayer = nil
		local shortestDistance = math.huge
		local beingWatched = false

		for _, player in pairs(Players:GetPlayers()) do
			local char = player.Character
			if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
				local dist = (npcRoot.Position - char.HumanoidRootPart.Position).Magnitude

				if dist < shortestDistance then
					shortestDistance = dist
					closestPlayer = player
				end

				if isPlayerLooking(player) then
					beingWatched = true
				end
			end
		end

		if beingWatched then
			-- Si alguien lo mira directamente (sin cristales), se detiene
			humanoid.WalkSpeed = 0
			humanoid:MoveTo(npcRoot.Position)
		else
			
			humanoid.WalkSpeed = VELOCIDAD_PERSECUCION
			if closestPlayer and closestPlayer.Character then
				local targetRoot = closestPlayer.Character.HumanoidRootPart

				
				moverHacerDestino = targetRoot.Position
				moverHacia(targetRoot.Position)

				if shortestDistance <= DISTANCIA_KILL then
					local targetHumanoid = closestPlayer.Character:FindFirstChild("Humanoid")
					if targetHumanoid and targetHumanoid.Health > 0 then
						jumpscareEvent:FireClient(closestPlayer)
						targetHumanoid.Health = 0
					end
				end
			end
		end
	end
end)