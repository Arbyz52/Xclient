local module = {
	Name     = "ESP",
	Category = "Visuals",
	Enabled  = false,
	_objects     = {},
	_connections = {},
	_npcTimer    = 0,
}

local Players      = game:GetService("Players")
local LocalPlayer  = Players.LocalPlayer
local RunService   = game:GetService("RunService")

local HAS_DRAWING = pcall(function()
	local t = Drawing.new("Line"); t:Remove()
end)

-- ═══════════════════════════════════════
--  НАСТРОЙКИ
-- ═══════════════════════════════════════
local CFG = {
	ShowBox       = true,
	ShowName      = true,
	ShowHealthBar = true,
	ShowTracer    = false,
	ShowHighlight = true,
	ShowNPCs      = true,

	TeamCheck     = true,
	MaxDistance    = 5000,
	NPCScanRate   = 2,

	TextSize      = 15,
	BoxThickness  = 1.5,

	HLFillAlpha   = 0.75,
	HLOutAlpha    = 0,

	EnemyColor    = Color3.fromRGB(255, 50, 50),
	BotColor      = Color3.fromRGB(255, 170, 40),
}

-- ═══════════════════════════════════════
--  УТИЛИТЫ
-- ═══════════════════════════════════════
local function safeDC(c)
	if c then pcall(function() c:Disconnect() end) end
end

local function storeConn(key, conn)
	safeDC(module._connections[key])
	module._connections[key] = conn
end

local function healthColor(r)
	r = math.clamp(r, 0, 1)
	if r > 0.5 then
		return Color3.fromRGB((1 - r) * 2 * 255, 255, 0)
	end
	return Color3.fromRGB(255, r * 2 * 255, 0)
end

local function isAlly(player)
	if not player then return false end
	if player == LocalPlayer then return true end
	if not CFG.TeamCheck then return false end
	local mt, pt = LocalPlayer.Team, player.Team
	if not mt or not pt then return false end
	return mt == pt
end

-- Проверяем, является ли NPC "своим" (та же команда через TeamColor/объект Team)
local function isAllyNPC(model)
	if not CFG.TeamCheck then return false end
	if not model then return false end

	-- Проверка через атрибут Team / TeamColor на модели или Humanoid
	local myTeam = LocalPlayer.Team
	if not myTeam then return false end

	-- Некоторые игры ставят TeamColor на модель
	local tc = model:FindFirstChild("TeamColor")
	if tc and tc:IsA("ValueBase") then
		pcall(function()
			if tc.Value == myTeam.TeamColor then return true end
		end)
	end

	-- Проверяем папку — если бот лежит в папке с именем команды
	local parent = model.Parent
	if parent and parent.Name == myTeam.Name then
		return true
	end

	return false
end

-- ═══════════════════════════════════════
--  DRAWINGS  (жирный текст = 2 слоя)
-- ═══════════════════════════════════════
local function makeText(size)
	local t = Drawing.new("Text")
	t.Size         = size
	t.Font         = 2       -- Plex — самый читабельный
	t.Center       = true
	t.Outline      = true
	t.OutlineColor = Color3.new(0, 0, 0)
	t.Transparency = 1
	t.Visible      = false
	return t
end

local function createDrawings()
	if not HAS_DRAWING then return nil end
	local d = {}

	-- Рамка (двойная: чёрный контур + цветная)
	d.boxOut = Drawing.new("Square")
	d.boxOut.Thickness    = 3
	d.boxOut.Color        = Color3.new(0, 0, 0)
	d.boxOut.Transparency = 1
	d.boxOut.Filled       = false
	d.boxOut.Visible      = false

	d.box = Drawing.new("Square")
	d.box.Thickness    = CFG.BoxThickness
	d.box.Transparency = 1
	d.box.Filled       = false
	d.box.Visible      = false

	-- Жирное имя: 3 слоя текста с небольшим смещением
	d.name1 = makeText(CFG.TextSize)
	d.name2 = makeText(CFG.TextSize)
	d.name3 = makeText(CFG.TextSize)

	-- HP бар
	d.hpBg = Drawing.new("Square")
	d.hpBg.Filled       = true
	d.hpBg.Color        = Color3.fromRGB(15, 15, 15)
	d.hpBg.Transparency = 0.35
	d.hpBg.Visible      = false

	d.hpOut = Drawing.new("Square")
	d.hpOut.Filled       = false
	d.hpOut.Color        = Color3.new(0, 0, 0)
	d.hpOut.Thickness    = 1
	d.hpOut.Transparency = 1
	d.hpOut.Visible      = false

	d.hpFill = Drawing.new("Square")
	d.hpFill.Filled       = true
	d.hpFill.Transparency = 1
	d.hpFill.Visible      = false

	-- Трейсер
	d.tracer = Drawing.new("Line")
	d.tracer.Thickness    = 1
	d.tracer.Transparency = 1
	d.tracer.Visible      = false

	return d
end

local function removeDrawings(d)
	if not d then return end
	for _, o in pairs(d) do pcall(function() o:Remove() end) end
end

local function hideDrawings(d)
	if not d then return end
	for _, o in pairs(d) do pcall(function() o.Visible = false end) end
end

-- ═══════════════════════════════════════
--  ENTRY
-- ═══════════════════════════════════════
local function destroyEntry(model)
	local e = module._objects[model]
	if not e then return end
	removeDrawings(e.draw)
	if e.hl then pcall(function() e.hl:Destroy() end) end
	module._objects[model] = nil
end

local function addEntity(model, player)
	if not model then return end
	if model == LocalPlayer.Character then return end
	if module._objects[model] then return end
	if player and isAlly(player) then return end
	if not player and isAllyNPC(model) then return end

	local isNPC = (player == nil)
	local displayName
	if isNPC then
		displayName = "BOT"
	else
		displayName = player.DisplayName or player.Name
	end

	local entry = {
		model  = model,
		player = player,
		isNPC  = isNPC,
		name   = displayName,
		draw   = createDrawings(),
		hl     = nil,
	}

	-- Highlight
	if CFG.ShowHighlight then
		pcall(function()
			for _, ch in ipairs(model:GetChildren()) do
				if ch:IsA("Highlight") and ch.Name == "__ESP" then
					ch:Destroy()
				end
			end
			local h = Instance.new("Highlight")
			h.Name                = "__ESP"
			h.Adornee             = model
			h.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
			h.FillTransparency    = CFG.HLFillAlpha
			h.OutlineTransparency = CFG.HLOutAlpha
			local c = isNPC and CFG.BotColor or CFG.EnemyColor
			h.FillColor    = c
			h.OutlineColor = c
			h.Parent       = model
			entry.hl = h
		end)
	end

	module._objects[model] = entry
end

-- ═══════════════════════════════════════
--  РЕНДЕР
-- ═══════════════════════════════════════
local function updateEntry(entry)
	local model = entry.model
	if not model or not model.Parent then
		hideDrawings(entry.draw)
		return false
	end

	if entry.player and not entry.player.Parent then
		hideDrawings(entry.draw)
		return false
	end

	-- Перепроверка союзника (смена команды)
	if entry.player and isAlly(entry.player) then
		hideDrawings(entry.draw)
		return false
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		hideDrawings(entry.draw)
		return false
	end

	local root = model:FindFirstChild("HumanoidRootPart")
		or model:FindFirstChild("Torso")
		or model:FindFirstChild("UpperTorso")
		or model:FindFirstChild("Head")
	if not root then
		hideDrawings(entry.draw)
		return true
	end

	local camera = workspace.CurrentCamera
	if not camera then
		hideDrawings(entry.draw)
		return true
	end

	-- Дистанция (для отсечения)
	local myChar = LocalPlayer.Character
	local myRoot = myChar and (
		myChar:FindFirstChild("HumanoidRootPart")
		or myChar:FindFirstChild("Torso")
		or myChar:FindFirstChild("Head")
	)
	local distance = myRoot and (root.Position - myRoot.Position).Magnitude or 0

	if distance > CFG.MaxDistance then
		hideDrawings(entry.draw)
		if entry.hl then pcall(function() entry.hl.Enabled = false end) end
		return true
	else
		if entry.hl then pcall(function() entry.hl.Enabled = true end) end
	end

	local _, onScreen = camera:WorldToViewportPoint(root.Position)
	if not onScreen then
		hideDrawings(entry.draw)
		return true
	end

	-- ── Bounding box ──
	local topV, botV
	local head = model:FindFirstChild("Head")

	if head then
		local t = camera:WorldToViewportPoint((head.CFrame * CFrame.new(0, 0.8, 0)).Position)
		local b = camera:WorldToViewportPoint((root.CFrame * CFrame.new(0, -3, 0)).Position)
		if t.Z > 0 and b.Z > 0 then
			topV = Vector2.new(t.X, t.Y)
			botV = Vector2.new(b.X, b.Y)
		end
	end

	if not topV then
		local t = camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3.5, 0))
		local b = camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3.5, 0))
		if t.Z <= 0 or b.Z <= 0 then
			hideDrawings(entry.draw)
			return true
		end
		topV = Vector2.new(t.X, t.Y)
		botV = Vector2.new(b.X, b.Y)
	end

	local boxH = math.abs(botV.Y - topV.Y)
	local boxW = boxH * 0.55
	local cx   = (topV.X + botV.X) / 2
	local boxX = cx - boxW / 2
	local boxY = topV.Y

	local entityCol = entry.isNPC and CFG.BotColor or CFG.EnemyColor
	local hpRatio   = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
	local hpCol     = healthColor(hpRatio)

	local d = entry.draw
	if not d then return true end

	-- ── Рамка ──
	if CFG.ShowBox then
		d.boxOut.Position = Vector2.new(boxX, boxY)
		d.boxOut.Size     = Vector2.new(boxW, boxH)
		d.boxOut.Visible  = true

		d.box.Position = Vector2.new(boxX, boxY)
		d.box.Size     = Vector2.new(boxW, boxH)
		d.box.Color    = entityCol
		d.box.Visible  = true
	else
		d.boxOut.Visible = false
		d.box.Visible    = false
	end

	-- ── Жирное имя (3 слоя для bold-эффекта) ──
	if CFG.ShowName then
		local nameY = boxY - CFG.TextSize - 4
		local txt   = entry.name

		d.name1.Text     = txt
		d.name1.Position = Vector2.new(cx, nameY)
		d.name1.Color    = entityCol
		d.name1.Visible  = true

		d.name2.Text     = txt
		d.name2.Position = Vector2.new(cx + 1, nameY)
		d.name2.Color    = entityCol
		d.name2.Visible  = true

		d.name3.Text     = txt
		d.name3.Position = Vector2.new(cx - 1, nameY)
		d.name3.Color    = entityCol
		d.name3.Visible  = true
	else
		d.name1.Visible = false
		d.name2.Visible = false
		d.name3.Visible = false
	end

	-- ── HP бар ──
	if CFG.ShowHealthBar then
		local bw = 3
		local bx = boxX - bw - 3

		d.hpBg.Position  = Vector2.new(bx - 1, boxY - 1)
		d.hpBg.Size      = Vector2.new(bw + 2, boxH + 2)
		d.hpBg.Visible   = true

		d.hpOut.Position = Vector2.new(bx - 1, boxY - 1)
		d.hpOut.Size     = Vector2.new(bw + 2, boxH + 2)
		d.hpOut.Visible  = true

		local fillH = math.max(boxH * hpRatio, 1)
		d.hpFill.Position = Vector2.new(bx, boxY + (boxH - fillH))
		d.hpFill.Size     = Vector2.new(bw, fillH)
		d.hpFill.Color    = hpCol
		d.hpFill.Visible  = true
	else
		d.hpBg.Visible   = false
		d.hpOut.Visible  = false
		d.hpFill.Visible = false
	end

	-- ── Трейсер ──
	if CFG.ShowTracer then
		local vs = camera.ViewportSize
		d.tracer.From    = Vector2.new(vs.X / 2, vs.Y)
		d.tracer.To      = Vector2.new(cx, boxY + boxH)
		d.tracer.Color   = entityCol
		d.tracer.Visible = true
	else
		d.tracer.Visible = false
	end

	-- Highlight цвет
	if entry.hl then
		entry.hl.OutlineColor = entityCol
		entry.hl.FillColor    = entityCol
	end

	return true
end

-- ═══════════════════════════════════════
--  СКАНЕР NPC
-- ═══════════════════════════════════════
local function scanNPCs()
	if not CFG.ShowNPCs or not module.Enabled then return end

	local playerChars = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then playerChars[p.Character] = true end
	end

	for _, desc in ipairs(workspace:GetDescendants()) do
		if desc:IsA("Humanoid") and desc.Health > 0 then
			local m = desc.Parent
			if m and m:IsA("Model")
				and m ~= LocalPlayer.Character
				and not playerChars[m]
				and not module._objects[m]
				and not isAllyNPC(m)
			then
				addEntity(m, nil)
			end
		end
	end
end

-- ═══════════════════════════════════════
--  ТРЕКИНГ ИГРОКОВ
-- ═══════════════════════════════════════
local function removePlayerEntry(player)
	for model, entry in pairs(module._objects) do
		if entry.player == player then
			destroyEntry(model)
			break
		end
	end
end

local function setupPlayer(player)
	if player == LocalPlayer then return end

	local function onCharAdded(character)
		removePlayerEntry(player)
		task.defer(function()
			if not module.Enabled then return end
			if not character or not character.Parent then return end

			local hum = character:FindFirstChildOfClass("Humanoid")
			if not hum then
				hum = character:WaitForChild("Humanoid", 10)
			end
			if not hum or not module.Enabled then return end
			if isAlly(player) then return end

			addEntity(character, player)
		end)
	end

	storeConn("char_" .. player.UserId,
		player.CharacterAdded:Connect(onCharAdded))

	storeConn("team_" .. player.UserId,
		player:GetPropertyChangedSignal("Team"):Connect(function()
			if not module.Enabled then return end
			task.defer(function()
				removePlayerEntry(player)
				if player.Character then
					onCharAdded(player.Character)
				end
			end)
		end))

	if player.Character then
		onCharAdded(player.Character)
	end
end

-- ═══════════════════════════════════════
--  MODULE API
-- ═══════════════════════════════════════
function module:Init()
	self._objects     = {}
	self._connections = {}
	self._npcTimer    = 0
end

function module:OnEnable()
	self.Enabled   = true
	self._objects  = {}
	self._npcTimer = 0

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	storeConn("playerAdded", Players.PlayerAdded:Connect(function(player)
		setupPlayer(player)
	end))

	storeConn("playerRemoving", Players.PlayerRemoving:Connect(function(player)
		removePlayerEntry(player)
		safeDC(module._connections["char_" .. player.UserId])
		safeDC(module._connections["team_" .. player.UserId])
		module._connections["char_" .. player.UserId] = nil
		module._connections["team_" .. player.UserId] = nil
	end))

	storeConn("descAdded", workspace.DescendantAdded:Connect(function(desc)
		if not module.Enabled or not CFG.ShowNPCs then return end
		if not desc:IsA("Humanoid") then return end
		task.defer(function()
			if not module.Enabled then return end
			local m = desc.Parent
			if not m or not m:IsA("Model") or m == LocalPlayer.Character then return end
			for _, p in ipairs(Players:GetPlayers()) do
				if p.Character == m then return end
			end
			if isAllyNPC(m) then return end
			if desc.Health > 0 and not module._objects[m] then
				addEntity(m, nil)
			end
		end)
	end))

	storeConn("descRemoving", workspace.DescendantRemoving:Connect(function(desc)
		if desc:IsA("Model") and module._objects[desc] then
			destroyEntry(desc)
		elseif desc:IsA("Humanoid") and desc.Parent then
			local m = desc.Parent
			if module._objects[m] and module._objects[m].isNPC then
				destroyEntry(m)
			end
		end
	end))

	-- Рескан при смене своей команды
	storeConn("myTeam", LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
		if not module.Enabled then return end
		task.defer(function()
			-- Убираем тех, кто стал союзником; добавляем тех, кто стал врагом
			for model, entry in pairs(module._objects) do
				if entry.player and isAlly(entry.player) then
					destroyEntry(model)
				elseif entry.isNPC and isAllyNPC(model) then
					destroyEntry(model)
				end
			end
			-- Пересканируем
			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= LocalPlayer and not isAlly(player) and player.Character then
					if not module._objects[player.Character] then
						addEntity(player.Character, player)
					end
				end
			end
			scanNPCs()
		end)
	end))

	task.defer(scanNPCs)

	storeConn("render", RunService.RenderStepped:Connect(function(dt)
		if not module.Enabled then return end

		local toRemove = {}
		for model, entry in pairs(module._objects) do
			if not updateEntry(entry) then
				table.insert(toRemove, model)
			end
		end
		for _, model in ipairs(toRemove) do
			destroyEntry(model)
		end

		module._npcTimer = module._npcTimer + dt
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
		safeDC(conn)
	end
	self._connections = {}
end

function module:OnTick(dt)
end

return module
