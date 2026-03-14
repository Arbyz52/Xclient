local module = {
	Name = "ESP",
	Category = "Visuals",
	Enabled = false,

	_objects = {},
	_connections = {},
	_npcTimer = 0,
	_updateTimer = 0,
	_playerCharacters = {},
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
	ShowHighlight = false,
	ShowNPCs = true,

	TeamCheck = true,
	MaxDistance = 1500,
	NPCScanRate = 5,
	UpdateRate = 1 / 30,

	TextSize = 13,
	BoxThickness = 1,

	HLFillAlpha = 0.8,
	HLOutAlpha = 1,

	EnemyColor = Color3.fromRGB(255, 80, 80),
	BotColor = Color3.fromRGB(255, 170, 70),
	TextColor = Color3.fromRGB(255, 255, 255),
}

local function disconnect(conn)
	if conn then
		pcall(function()
			conn:Disconnect()
		end)
	end
end

local function bind(key, conn)
	disconnect(module._connections[key])
	module._connections[key] = conn
end

local function getHumanoid(model)
	return model and model:FindFirstChildOfClass("Humanoid")
end

local function getRoot(model)
	return model and (
		model:FindFirstChild("HumanoidRootPart")
		or model:FindFirstChild("UpperTorso")
		or model:FindFirstChild("Torso")
		or model:FindFirstChild("Head")
	)
end

local function getLocalRoot()
	local char = LocalPlayer.Character
	if not char then
		return nil
	end
	return getRoot(char)
end

local function healthColor(r)
	r = math.clamp(r, 0, 1)
	if r > 0.5 then
		return Color3.fromRGB((1 - r) * 2 * 255, 255, 0)
	end
	return Color3.fromRGB(255, r * 2 * 255, 0)
end

local function isAlly(player)
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

local function isAllyNPC(model)
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
	if teamColor and teamColor:IsA("BrickColorValue") and teamColor.Value == myTeam.TeamColor then
		return true
	end

	local parent = model.Parent
	if parent and parent.Name == myTeam.Name then
		return true
	end

	return false
end

local function hideDraw(draw)
	if not draw then
		return
	end

	for _, obj in pairs(draw) do
		pcall(function()
			obj.Visible = false
		end)
	end
end

local function removeDraw(draw)
	if not draw then
		return
	end

	for _, obj in pairs(draw) do
		pcall(function()
			obj:Remove()
		end)
	end
end

local function createDraw()
	if not HAS_DRAWING then
		return nil
	end

	local d = {}

	d.box = Drawing.new("Square")
	d.box.Filled = false
	d.box.Thickness = CFG.BoxThickness
	d.box.Transparency = 1
	d.box.Visible = false

	d.name = Drawing.new("Text")
	d.name.Size = CFG.TextSize
	d.name.Font = 2
	d.name.Center = true
	d.name.Outline = true
	d.name.OutlineColor = Color3.new(0, 0, 0)
	d.name.Transparency = 1
	d.name.Visible = false

	d.hpBg = Drawing.new("Square")
	d.hpBg.Filled = true
	d.hpBg.Color = Color3.fromRGB(20, 20, 20)
	d.hpBg.Transparency = 0.35
	d.hpBg.Visible = false

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

local function createHighlight(model, color)
	if not CFG.ShowHighlight then
		return nil
	end

	local ok, hl = pcall(function()
		local old = model:FindFirstChild("__ESP_HL")
		if old then
			old:Destroy()
		end

		local h = Instance.new("Highlight")
		h.Name = "__ESP_HL"
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

local function destroyEntry(model)
	local entry = module._objects[model]
	if not entry then
		return
	end

	hideDraw(entry.draw)
	removeDraw(entry.draw)

	if entry.highlight then
		pcall(function()
			entry.highlight:Destroy()
		end)
	end

	module._objects[model] = nil
end

local function addEntity(model, player)
	if not model or module._objects[model] then
		return
	end

	if model == LocalPlayer.Character then
		return
	end

	if player then
		if isAlly(player) then
			return
		end
	else
		if isAllyNPC(model) then
			return
		end
	end

	local isNPC = player == nil
	local color = isNPC and CFG.BotColor or CFG.EnemyColor

	module._objects[model] = {
		model = model,
		player = player,
		isNPC = isNPC,
		name = isNPC and model.Name or (player.DisplayName or player.Name),
		color = color,
		draw = createDraw(),
		highlight = createHighlight(model, color),
	}
end

local function hideEntry(entry)
	hideDraw(entry.draw)
	if entry.highlight then
		entry.highlight.Enabled = false
	end
end

local function getBox(root, model, camera)
	local head = model:FindFirstChild("Head")

	local top2d, bot2d

	if head then
		local top = camera:WorldToViewportPoint((head.CFrame * CFrame.new(0, 0.8, 0)).Position)
		local bot = camera:WorldToViewportPoint((root.CFrame * CFrame.new(0, -3, 0)).Position)

		if top.Z > 0 and bot.Z > 0 then
			top2d = Vector2.new(top.X, top.Y)
			bot2d = Vector2.new(bot.X, bot.Y)
		end
	end

	if not top2d then
		local top = camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3, 0))
		local bot = camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))

		if top.Z <= 0 or bot.Z <= 0 then
			return nil
		end

		top2d = Vector2.new(top.X, top.Y)
		bot2d = Vector2.new(bot.X, bot.Y)
	end

	local h = math.abs(bot2d.Y - top2d.Y)
	local w = h * 0.55
	local cx = (top2d.X + bot2d.X) * 0.5

	return {
		x = cx - w * 0.5,
		y = top2d.Y,
		w = w,
		h = h,
		cx = cx,
	}
end

local function updateEntry(entry, camera, localRoot)
	local model = entry.model
	if not model or not model.Parent then
		return false
	end

	if entry.player and not entry.player.Parent then
		return false
	end

	if entry.player and isAlly(entry.player) then
		hideEntry(entry)
		return true
	end

	if entry.isNPC and isAllyNPC(model) then
		hideEntry(entry)
		return true
	end

	local humanoid = getHumanoid(model)
	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	local root = getRoot(model)
	if not root then
		hideEntry(entry)
		return true
	end

	local distance = localRoot and (root.Position - localRoot.Position).Magnitude or math.huge
	if distance > CFG.MaxDistance then
		hideEntry(entry)
		return true
	end

	local pos, onScreen = camera:WorldToViewportPoint(root.Position)
	if not onScreen or pos.Z <= 0 then
		hideEntry(entry)
		return true
	end

	local box = getBox(root, model, camera)
	if not box then
		hideEntry(entry)
		return true
	end

	local draw = entry.draw
	local color = entry.color
	local hpRatio = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)

	if CFG.ShowBox then
		draw.box.Position = Vector2.new(box.x, box.y)
		draw.box.Size = Vector2.new(box.w, box.h)
		draw.box.Color = color
		draw.box.Visible = true
	else
		draw.box.Visible = false
	end

	if CFG.ShowName then
		draw.name.Text = entry.name
		draw.name.Position = Vector2.new(box.cx, box.y - 15)
		draw.name.Color = CFG.TextColor
		draw.name.Visible = true
	else
		draw.name.Visible = false
	end

	if CFG.ShowHealthBar then
		local bw = 3
		local bx = box.x - 5
		local fillH = math.max(1, box.h * hpRatio)

		draw.hpBg.Position = Vector2.new(bx, box.y)
		draw.hpBg.Size = Vector2.new(bw, box.h)
		draw.hpBg.Visible = true

		draw.hpFill.Position = Vector2.new(bx, box.y + (box.h - fillH))
		draw.hpFill.Size = Vector2.new(bw, fillH)
		draw.hpFill.Color = healthColor(hpRatio)
		draw.hpFill.Visible = true
	else
		draw.hpBg.Visible = false
		draw.hpFill.Visible = false
	end

	if CFG.ShowTracer then
		local vs = camera.ViewportSize
		draw.tracer.From = Vector2.new(vs.X * 0.5, vs.Y)
		draw.tracer.To = Vector2.new(box.cx, box.y + box.h)
		draw.tracer.Color = color
		draw.tracer.Visible = true
	else
		draw.tracer.Visible = false
	end

	if entry.highlight then
		entry.highlight.Enabled = true
	end

	return true
end

local function rebuildPlayerCharacters()
	table.clear(module._playerCharacters)
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			module._playerCharacters[p.Character] = true
		end
	end
end

local function scanNPCs()
	if not module.Enabled or not CFG.ShowNPCs then
		return
	end

	rebuildPlayerCharacters()

	for _, obj in ipairs(Workspace:GetChildren()) do
		if obj:IsA("Model")
			and obj ~= LocalPlayer.Character
			and not module._playerCharacters[obj]
			and not module._objects[obj]
		then
			local hum = getHumanoid(obj)
			if hum and hum.Health > 0 and not isAllyNPC(obj) then
				addEntity(obj, nil)
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

	local function onCharacterAdded(character)
		module._playerCharacters[character] = true
		removePlayerEntry(player)

		task.defer(function()
			if not module.Enabled then
				return
			end

			if not character or not character.Parent then
				return
			end

			local hum = getHumanoid(character) or character:WaitForChild("Humanoid", 3)
			if not hum or hum.Health <= 0 then
				return
			end

			if isAlly(player) then
				return
			end

			addEntity(character, player)
		end)
	end

	bind("char_" .. player.UserId, player.CharacterAdded:Connect(onCharacterAdded))

	bind("team_" .. player.UserId, player:GetPropertyChangedSignal("Team"):Connect(function()
		task.defer(function()
			if not module.Enabled then
				return
			end

			removePlayerEntry(player)
			if player.Character and not isAlly(player) then
				addEntity(player.Character, player)
			end
		end)
	end))

	if player.Character then
		onCharacterAdded(player.Character)
	end
end

function module:Init()
	self._objects = {}
	self._connections = {}
	self._npcTimer = 0
	self._updateTimer = 0
	self._playerCharacters = {}
end

function module:OnEnable()
	self.Enabled = true
	self._npcTimer = 0
	self._updateTimer = 0

	for model in pairs(self._objects) do
		destroyEntry(model)
	end
	self._objects = {}

	rebuildPlayerCharacters()

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	bind("playerAdded", Players.PlayerAdded:Connect(function(player)
		setupPlayer(player)
	end))

	bind("playerRemoving", Players.PlayerRemoving:Connect(function(player)
		removePlayerEntry(player)

		local cKey = "char_" .. player.UserId
		local tKey = "team_" .. player.UserId

		disconnect(module._connections[cKey])
		disconnect(module._connections[tKey])

		module._connections[cKey] = nil
		module._connections[tKey] = nil

		rebuildPlayerCharacters()
	end))

	bind("descAdded", Workspace.DescendantAdded:Connect(function(desc)
		if not module.Enabled or not CFG.ShowNPCs then
			return
		end

		if not desc:IsA("Humanoid") then
			return
		end

		local model = desc.Parent
		if not model or not model:IsA("Model") then
			return
		end

		task.defer(function()
			if not module.Enabled then
				return
			end

			if model == LocalPlayer.Character then
				return
			end

			if module._playerCharacters[model] then
				return
			end

			if module._objects[model] then
				return
			end

			if desc.Health <= 0 then
				return
			end

			if isAllyNPC(model) then
				return
			end

			addEntity(model, nil)
		end)
	end))

	bind("descRemoving", Workspace.DescendantRemoving:Connect(function(desc)
		if desc:IsA("Model") and module._objects[desc] then
			destroyEntry(desc)
		end
	end))

	bind("myTeamChanged", LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
		task.defer(function()
			if not module.Enabled then
				return
			end

			for model, entry in pairs(module._objects) do
				if entry.player and isAlly(entry.player) then
					destroyEntry(model)
				elseif entry.isNPC and isAllyNPC(model) then
					destroyEntry(model)
				end
			end

			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= LocalPlayer and player.Character and not isAlly(player) then
					if not module._objects[player.Character] then
						addEntity(player.Character, player)
					end
				end
			end

			scanNPCs()
		end)
	end))

	task.defer(scanNPCs)

	bind("render", RunService.RenderStepped:Connect(function(dt)
		if not module.Enabled then
			return
		end

		module._updateTimer += dt
		module._npcTimer += dt

		if module._npcTimer >= CFG.NPCScanRate then
			module._npcTimer = 0
			task.defer(scanNPCs)
		end

		if module._updateTimer < CFG.UpdateRate then
			return
		end
		module._updateTimer = 0

		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end

		local localRoot = getLocalRoot()
		local removeList = {}

		for model, entry in pairs(module._objects) do
			if not updateEntry(entry, camera, localRoot) then
				removeList[#removeList + 1] = model
			end
		end

		for i = 1, #removeList do
			destroyEntry(removeList[i])
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

	table.clear(self._playerCharacters)
end

function module:OnTick()
end

return module
