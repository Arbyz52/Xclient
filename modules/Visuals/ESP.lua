local module = {
	Name = "ESP",
	Category = "Visuals",
	Enabled = false,

	_objects = {},
	_connections = {},
	_npcTimer = 0,
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local HAS_DRAWING = pcall(function()
	local x = Drawing.new("Line")
	x:Remove()
end)

local CFG = {
	ShowBox = true,
	ShowName = true,
	ShowHealthBar = true,
	ShowTracer = false,
	ShowHighlight = true,
	ShowNPCs = true,

	TeamCheck = true,
	MaxDistance = 5000,
	NPCScanRate = 2,

	TextSize = 15,
	BoxThickness = 1.5,

	HLFillAlpha = 0.75,
	HLOutAlpha = 0,

	EnemyColor = Color3.fromRGB(255, 50, 50),
	BotColor = Color3.fromRGB(255, 170, 40),
}

local function disconnect(conn)
	if conn then
		pcall(function()
			conn:Disconnect()
		end)
	end
end

local function setConnection(key, conn)
	disconnect(module._connections[key])
	module._connections[key] = conn
end

local function healthColor(ratio)
	ratio = math.clamp(ratio, 0, 1)

	if ratio > 0.5 then
		return Color3.fromRGB((1 - ratio) * 2 * 255, 255, 0)
	else
		return Color3.fromRGB(255, ratio * 2 * 255, 0)
	end
end

local function isPlayerAlly(player)
	if not player then
		return false
	end

	if player == LocalPlayer then
		return true
	end

	if not CFG.TeamCheck then
		return false
	end

	if not LocalPlayer.Team or not player.Team then
		return false
	end

	return LocalPlayer.Team == player.Team
end

local function isNPCAlly(model)
	if not CFG.TeamCheck or not model then
		return false
	end

	local myTeam = LocalPlayer.Team
	if not myTeam then
		return false
	end

	local teamObj = model:FindFirstChild("Team")
	if teamObj and teamObj:IsA("ObjectValue") and teamObj.Value == myTeam then
		return true
	end

	local teamColor = model:FindFirstChild("TeamColor")
	if teamColor and teamColor:IsA("BrickColorValue") then
		if teamColor.Value == myTeam.TeamColor then
			return true
		end
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local humTeam = humanoid:FindFirstChild("Team")
		if humTeam and humTeam:IsA("ObjectValue") and humTeam.Value == myTeam then
			return true
		end

		local humTeamColor = humanoid:FindFirstChild("TeamColor")
		if humTeamColor and humTeamColor:IsA("BrickColorValue") then
			if humTeamColor.Value == myTeam.TeamColor then
				return true
			end
		end
	end

	local parent = model.Parent
	if parent and parent.Name == myTeam.Name then
		return true
	end

	return false
end

local function makeText(size)
	local t = Drawing.new("Text")
	t.Size = size
	t.Font = 2
	t.Center = true
	t.Outline = true
	t.OutlineColor = Color3.new(0, 0, 0)
	t.Transparency = 1
	t.Visible = false
	return t
end

local function createDrawings()
	if not HAS_DRAWING then
		return nil
	end

	local d = {}

	d.boxOutline = Drawing.new("Square")
	d.boxOutline.Thickness = 3
	d.boxOutline.Color = Color3.new(0, 0, 0)
	d.boxOutline.Filled = false
	d.boxOutline.Transparency = 1
	d.boxOutline.Visible = false

	d.box = Drawing.new("Square")
	d.box.Thickness = CFG.BoxThickness
	d.box.Filled = false
	d.box.Transparency = 1
	d.box.Visible = false

	d.name1 = makeText(CFG.TextSize)
	d.name2 = makeText(CFG.TextSize)
	d.name3 = makeText(CFG.TextSize)

	d.hpBg = Drawing.new("Square")
	d.hpBg.Filled = true
	d.hpBg.Color = Color3.fromRGB(15, 15, 15)
	d.hpBg.Transparency = 0.35
	d.hpBg.Visible = false

	d.hpOutline = Drawing.new("Square")
	d.hpOutline.Filled = false
	d.hpOutline.Color = Color3.new(0, 0, 0)
	d.hpOutline.Thickness = 1
	d.hpOutline.Transparency = 1
	d.hpOutline.Visible = false

	d.hpFill = Drawing.new("Square")
	d.hpFill.Filled = true
	d.hpFill.Transparency = 1
	d.hpFill.Visible = false

	d.tracer = Drawing.new("Line")
	d.tracer.Thickness = 1
	d.tracer.Transparency = 1
	d.tracer.Visible = false

	return d
end

local function hideDrawings(draw)
	if not draw then
		return
	end

	for _, obj in pairs(draw) do
		pcall(function()
			obj.Visible = false
		end)
	end
end

local function removeDrawings(draw)
	if not draw then
		return
	end

	for _, obj in pairs(draw) do
		pcall(function()
			obj:Remove()
		end)
	end
end

local function getCharacterRoot(model)
	return model:FindFirstChild("HumanoidRootPart")
		or model:FindFirstChild("UpperTorso")
		or model:FindFirstChild("Torso")
		or model:FindFirstChild("Head")
end

local function getHumanoid(model)
	return model and model:FindFirstChildOfClass("Humanoid")
end

local function getDistanceFromLocal(pos)
	local char = LocalPlayer.Character
	if not char then
		return math.huge
	end

	local root = getCharacterRoot(char)
	if not root then
		return math.huge
	end

	return (root.Position - pos).Magnitude
end

local function destroyEntry(model)
	local entry = module._objects[model]
	if not entry then
		return
	end

	hideDrawings(entry.draw)
	removeDrawings(entry.draw)

	if entry.highlight then
		pcall(function()
			entry.highlight:Destroy()
		end)
	end

	module._objects[model] = nil
end

local function createHighlight(model, color)
	local ok, hl = pcall(function()
		local old = model:FindFirstChild("__ESPHighlight")
		if old and old:IsA("Highlight") then
			old:Destroy()
		end

		local h = Instance.new("Highlight")
		h.Name = "__ESPHighlight"
		h.Adornee = model
		h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		h.FillTransparency = CFG.HLFillAlpha
		h.OutlineTransparency = CFG.HLOutAlpha
		h.FillColor = color
		h.OutlineColor = color
		h.Parent = model
		return h
	end)

	return ok and hl or nil
end

local function addEntity(model, player)
	if not model or module._objects[model] then
		return
	end

	if model == LocalPlayer.Character then
		return
	end

	if player then
		if isPlayerAlly(player) then
			return
		end
	else
		if isNPCAlly(model) then
			return
		end
	end

	local isNPC = player == nil
	local color = isNPC and CFG.BotColor or CFG.EnemyColor

	local entry = {
		model = model,
		player = player,
		isNPC = isNPC,
		name = isNPC and "BOT" or (player.DisplayName or player.Name),
		draw = createDrawings(),
		highlight = nil,
	}

	if CFG.ShowHighlight then
		entry.highlight = createHighlight(model, color)
	end

	module._objects[model] = entry
end

local function getBoxPoints(model, root, camera)
	local head = model:FindFirstChild("Head")

	if head then
		local top = camera:WorldToViewportPoint((head.CFrame * CFrame.new(0, 0.8, 0)).Position)
		local bottom = camera:WorldToViewportPoint((root.CFrame * CFrame.new(0, -3, 0)).Position)

		if top.Z > 0 and bottom.Z > 0 then
			return Vector2.new(top.X, top.Y), Vector2.new(bottom.X, bottom.Y)
		end
	end

	local top = camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3.5, 0))
	local bottom = camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3.5, 0))

	if top.Z <= 0 or bottom.Z <= 0 then
		return nil, nil
	end

	return Vector2.new(top.X, top.Y), Vector2.new(bottom.X, bottom.Y)
end

local function updateEntry(entry)
	local model = entry.model
	if not model or not model.Parent then
		return false
	end

	if entry.player and not entry.player.Parent then
		return false
	end

	if entry.player and isPlayerAlly(entry.player) then
		hideDrawings(entry.draw)
		if entry.highlight then
			entry.highlight.Enabled = false
		end
		return true
	end

	if entry.isNPC and isNPCAlly(model) then
		hideDrawings(entry.draw)
		if entry.highlight then
			entry.highlight.Enabled = false
		end
		return true
	end

	local humanoid = getHumanoid(model)
	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	local root = getCharacterRoot(model)
	if not root then
		hideDrawings(entry.draw)
		return true
	end

	local camera = Workspace.CurrentCamera
	if not camera then
		hideDrawings(entry.draw)
		return true
	end

	local distance = getDistanceFromLocal(root.Position)
	if distance > CFG.MaxDistance then
		hideDrawings(entry.draw)
		if entry.highlight then
			entry.highlight.Enabled = false
		end
		return true
	end

	local screenPoint, onScreen = camera:WorldToViewportPoint(root.Position)
	if not onScreen or screenPoint.Z <= 0 then
		hideDrawings(entry.draw)
		if entry.highlight then
			entry.highlight.Enabled = false
		end
		return true
	end

	local topV, bottomV = getBoxPoints(model, root, camera)
	if not topV or not bottomV then
		hideDrawings(entry.draw)
		if entry.highlight then
			entry.highlight.Enabled = false
		end
		return true
	end

	local boxH = math.abs(bottomV.Y - topV.Y)
	local boxW = boxH * 0.55
	local centerX = (topV.X + bottomV.X) * 0.5
	local boxX = centerX - boxW * 0.5
	local boxY = topV.Y

	local color = entry.isNPC and CFG.BotColor or CFG.EnemyColor
	local hpRatio = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
	local hpCol = healthColor(hpRatio)

	local d = entry.draw
	if d then
		if CFG.ShowBox then
			d.boxOutline.Position = Vector2.new(boxX, boxY)
			d.boxOutline.Size = Vector2.new(boxW, boxH)
			d.boxOutline.Visible = true

			d.box.Position = Vector2.new(boxX, boxY)
			d.box.Size = Vector2.new(boxW, boxH)
			d.box.Color = color
			d.box.Visible = true
		else
			d.boxOutline.Visible = false
			d.box.Visible = false
		end

		if CFG.ShowName then
			local nameY = boxY - CFG.TextSize - 4
			local text = entry.name

			d.name1.Text = text
			d.name1.Position = Vector2.new(centerX, nameY)
			d.name1.Color = color
			d.name1.Visible = true

			d.name2.Text = text
			d.name2.Position = Vector2.new(centerX + 1, nameY)
			d.name2.Color = color
			d.name2.Visible = true

			d.name3.Text = text
			d.name3.Position = Vector2.new(centerX - 1, nameY)
			d.name3.Color = color
			d.name3.Visible = true
		else
			d.name1.Visible = false
			d.name2.Visible = false
			d.name3.Visible = false
		end

		if CFG.ShowHealthBar then
			local bw = 3
			local bx = boxX - bw - 3
			local fillH = math.max(boxH * hpRatio, 1)

			d.hpBg.Position = Vector2.new(bx - 1, boxY - 1)
			d.hpBg.Size = Vector2.new(bw + 2, boxH + 2)
			d.hpBg.Visible = true

			d.hpOutline.Position = Vector2.new(bx - 1, boxY - 1)
			d.hpOutline.Size = Vector2.new(bw + 2, boxH + 2)
			d.hpOutline.Visible = true

			d.hpFill.Position = Vector2.new(bx, boxY + (boxH - fillH))
			d.hpFill.Size = Vector2.new(bw, fillH)
			d.hpFill.Color = hpCol
			d.hpFill.Visible = true
		else
			d.hpBg.Visible = false
			d.hpOutline.Visible = false
			d.hpFill.Visible = false
		end

		if CFG.ShowTracer then
			local vs = camera.ViewportSize
			d.tracer.From = Vector2.new(vs.X * 0.5, vs.Y)
			d.tracer.To = Vector2.new(centerX, boxY + boxH)
			d.tracer.Color = color
			d.tracer.Visible = true
		else
			d.tracer.Visible = false
		end
	end

	if entry.highlight then
		entry.highlight.Enabled = CFG.ShowHighlight
		entry.highlight.FillColor = color
		entry.highlight.OutlineColor = color
	end

	return true
end

local function isPlayerCharacter(model)
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character == model then
			return true
		end
	end
	return false
end

local function scanNPCs()
	if not module.Enabled or not CFG.ShowNPCs then
		return
	end

	for _, obj in ipairs(Workspace:GetChildren()) do
		if obj:IsA("Model") and obj ~= LocalPlayer.Character and not module._objects[obj] then
			local humanoid = getHumanoid(obj)
			if humanoid and humanoid.Health > 0 then
				if not isPlayerCharacter(obj) and not isNPCAlly(obj) then
					addEntity(obj, nil)
				end
			end
		end
	end
end

local function removePlayerEntry(player)
	for model, entry in pairs(module._objects) do
		if entry.player == player then
			destroyEntry(model)
		end
	end
end

local function setupPlayer(player)
	if player == LocalPlayer then
		return
	end

	local function onCharacter(character)
		removePlayerEntry(player)

		task.defer(function()
			if not module.Enabled then
				return
			end

			if not character or not character.Parent then
				return
			end

			local humanoid = getHumanoid(character) or character:WaitForChild("Humanoid", 5)
			if not humanoid or humanoid.Health <= 0 then
				return
			end

			if isPlayerAlly(player) then
				return
			end

			addEntity(character, player)
		end)
	end

	setConnection("char_" .. player.UserId, player.CharacterAdded:Connect(onCharacter))

	setConnection("team_" .. player.UserId, player:GetPropertyChangedSignal("Team"):Connect(function()
		if not module.Enabled then
			return
		end

		task.defer(function()
			removePlayerEntry(player)

			if player.Character and not isPlayerAlly(player) then
				addEntity(player.Character, player)
			end
		end)
	end))

	if player.Character then
		onCharacter(player.Character)
	end
end

function module:Init()
	self._objects = {}
	self._connections = {}
	self._npcTimer = 0
end

function module:OnEnable()
	self.Enabled = true
	self._npcTimer = 0

	for model in pairs(self._objects) do
		destroyEntry(model)
	end
	self._objects = {}

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	setConnection("playerAdded", Players.PlayerAdded:Connect(function(player)
		setupPlayer(player)
	end))

	setConnection("playerRemoving", Players.PlayerRemoving:Connect(function(player)
		removePlayerEntry(player)

		local charKey = "char_" .. player.UserId
		local teamKey = "team_" .. player.UserId

		disconnect(module._connections[charKey])
		disconnect(module._connections[teamKey])

		module._connections[charKey] = nil
		module._connections[teamKey] = nil
	end))

	setConnection("descAdded", Workspace.DescendantAdded:Connect(function(desc)
		if not module.Enabled or not CFG.ShowNPCs then
			return
		end

		if not desc:IsA("Humanoid") then
			return
		end

		task.defer(function()
			local model = desc.Parent
			if not model or not model:IsA("Model") then
				return
			end

			if model == LocalPlayer.Character then
				return
			end

			if module._objects[model] then
				return
			end

			if isPlayerCharacter(model) then
				return
			end

			if desc.Health <= 0 then
				return
			end

			if isNPCAlly(model) then
				return
			end

			addEntity(model, nil)
		end)
	end))

	setConnection("descRemoving", Workspace.DescendantRemoving:Connect(function(desc)
		if desc:IsA("Model") and module._objects[desc] then
			destroyEntry(desc)
			return
		end

		if desc:IsA("Humanoid") and desc.Parent and module._objects[desc.Parent] then
			local entry = module._objects[desc.Parent]
			if entry.isNPC then
				destroyEntry(desc.Parent)
			end
		end
	end))

	setConnection("myTeamChanged", LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
		if not module.Enabled then
			return
		end

		task.defer(function()
			for model, entry in pairs(module._objects) do
				if entry.player and isPlayerAlly(entry.player) then
					destroyEntry(model)
				elseif entry.isNPC and isNPCAlly(model) then
					destroyEntry(model)
				end
			end

			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= LocalPlayer and player.Character and not isPlayerAlly(player) then
					if not module._objects[player.Character] then
						addEntity(player.Character, player)
					end
				end
			end

			scanNPCs()
		end)
	end))

	task.defer(scanNPCs)

	setConnection("render", RunService.RenderStepped:Connect(function(dt)
		if not module.Enabled then
			return
		end

		local removeList = {}

		for model, entry in pairs(module._objects) do
			local ok = updateEntry(entry)
			if not ok then
				table.insert(removeList, model)
			end
		end

		for _, model in ipairs(removeList) do
			destroyEntry(model)
		end

		module._npcTimer += dt
		if module._npcTimer >= CFG.NPCScanRate then
			module._npcTimer = 0
			task.defer(scanNPCs)
		end
	end))
end

function module:OnDisable()
	self.Enabled = false

	for model in pairs(self._objects) do
		destroyEntry(model)
	end
	self._objects = {}

	for key, conn in pairs(self._connections) do
		disconnect(conn)
		self._connections[key] = nil
	end
end

function module:OnTick()
end

return module
