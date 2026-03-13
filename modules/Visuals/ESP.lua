local module = {
	Name     = "ESP",
	Category = "Visuals",
	Enabled  = false,
	_objects     = {},   -- model → entry
	_connections = {},
	_npcTimer    = 0,
}

--// Сервисы
local Players      = game:GetService("Players")
local LocalPlayer  = Players.LocalPlayer
local RunService   = game:GetService("RunService")

--// Проверка Drawing API (нужен эксплоит с поддержкой)
local HAS_DRAWING = pcall(function()
	local t = Drawing.new("Line"); t:Remove()
end)

-- ════════════════════════════════════════════════
--  НАСТРОЙКИ  (меняй под себя)
-- ════════════════════════════════════════════════
local CFG = {
	ShowBox       = true,        -- 2D-рамка
	ShowName      = true,        -- имя
	ShowHealthBar = true,        -- полоска HP слева
	ShowDistance   = true,        -- дистанция снизу
	ShowTracer    = false,       -- линия от низа экрана
	ShowHighlight = true,        -- 3D Highlight (через стены)
	ShowNPCs      = true,        -- показывать NPC / ботов

	TeamCheck     = false,       -- true = не показывать союзников
	MaxDistance    = 5000,        -- макс. дистанция (studs)
	NPCScanRate   = 2,           -- интервал пересканирования NPC (сек)

	TextSize      = 13,
	BoxThickness  = 1,

	HLFillAlpha   = 0.75,       -- прозрачность заливки Highlight
	HLOutAlpha    = 0,           -- прозрачность обводки Highlight

	EnemyColor    = Color3.fromRGB(255, 55, 55),
	NPCColor      = Color3.fromRGB(255, 170, 40),
}

-- ════════════════════════════════════════════════
--  УТИЛИТЫ
-- ════════════════════════════════════════════════
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
	if not CFG.TeamCheck then return false end
	if not player then return false end
	local mt, pt = LocalPlayer.Team, player.Team
	if not mt or not pt then return false end
	return mt == pt
end

-- ════════════════════════════════════════════════
--  DRAWING
-- ════════════════════════════════════════════════
local function createDrawings()
	if not HAS_DRAWING then return nil end
	local d = {}

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

	d.name = Drawing.new("Text")
	d.name.Size         = CFG.TextSize
	d.name.Font         = 2
	d.name.Center       = true
	d.name.Outline      = true
	d.name.OutlineColor = Color3.new(0, 0, 0)
	d.name.Transparency = 1
	d.name.Visible      = false

	d.dist = Drawing.new("Text")
	d.dist.Size         = CFG.TextSize - 1
	d.dist.Font         = 2
	d.dist.Center       = true
	d.dist.Outline      = true
	d.dist.OutlineColor = Color3.new(0, 0, 0)
	d.dist.Color        = Color3.fromRGB(200, 200, 200)
	d.dist.Transparency = 1
	d.dist.Visible      = false

	d.hpBg = Drawing.new("Square")
	d.hpBg.Filled       = true
	d.hpBg.Color        = Color3.new(0, 0, 0)
	d.hpBg.Transparency = 0.5
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

-- ════════════════════════════════════════════════
--  ENTRY  (создание / удаление)
-- ════════════════════════════════════════════════
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
	if player and (player == LocalPlayer or isAlly(player)) then return end

	local displayName
	if player then
		displayName = player.DisplayName or player.Name
	else
		displayName = "[NPC] " .. model.Name
	end

	local entry = {
		model = model,
		player = player,
		isNPC  = (player == nil),
		name   = displayName,
		draw   = createDrawings(),
		hl     = nil,
	}

	if CFG.ShowHighlight then
		pcall(function()
			for _, ch in ipairs(model:GetChildren()) do
				if ch:IsA("Highlight") and ch.Name == "__ESP" then
					ch:Destroy()
				end
			end
			local h = Instance.new("Highlight")
			h.Name               = "__ESP"
			h.Adornee            = model
			h.DepthMode          = Enum.HighlightDepthMode.AlwaysOnTop
			h.FillTransparency   = CFG.HLFillAlpha
			h.OutlineTransparency= CFG.HLOutAlpha
			local c = entry.isNPC and CFG.NPCColor or CFG.EnemyColor
			h.FillColor    = c
			h.OutlineColor = c
			h.Parent       = model
			entry.hl = h
		end)
	end

	module._objects[model] = entry
end

-- ════════════════════════════════════════════════
--  РЕНДЕР  (обновление каждого кадра)
-- ════════════════════════════════════════════════
local function updateEntry(entry)
	local model = entry.model
	if not model or not model.Parent then
		hideDrawings(entry.draw)
		return false
	end

	-- Если это игрок который ушёл
	if entry.player and not entry.player.Parent then
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

	-- Дистанция
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

	-- На экране?
	local _, onScreen = camera:WorldToViewportPoint(root.Position)
	if not onScreen then
		hideDrawings(entry.draw)
		return true   -- highlight остаётся видимым
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

	-- Цвета
	local entityCol = entry.isNPC and CFG.NPCColor or CFG.EnemyColor
	local hpRatio   = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
	local hpCol     = healthColor(hpRatio)

	-- ── Рисуем ──
	local d = entry.draw
	if d then
		-- Рамка
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

		-- Имя
		if CFG.ShowName then
			d.name.Text     = entry.name
			d.name.Position = Vector2.new(cx, boxY - CFG.TextSize - 3)
			d.name.Color    = entityCol
			d.name.Visible  = true
		else
			d.name.Visible = false
		end

		-- Дистанция
		if CFG.ShowDistance then
			d.dist.Text     = math.floor(distance) .. "m"
			d.dist.Position = Vector2.new(cx, boxY + boxH + 2)
			d.dist.Visible  = true
		else
			d.dist.Visible = false
		end

		-- Полоска HP
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

		-- Трейсер
		if CFG.ShowTracer then
			local vs = camera.ViewportSize
			d.tracer.From    = Vector2.new(vs.X / 2, vs.Y)
			d.tracer.To      = Vector2.new(cx, boxY + boxH)
			d.tracer.Color   = entityCol
			d.tracer.Visible = true
		else
			d.tracer.Visible = false
		end
	end

	-- Highlight
	if entry.hl then
		entry.hl.OutlineColor = entityCol
		entry.hl.FillColor    = entityCol
	end

	return true
end

-- ════════════════════════════════════════════════
--  СКАНЕР NPC
-- ════════════════════════════════════════════════
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
			then
				addEntity(m, nil)
			end
		end
	end
end

-- ════════════════════════════════════════════════
--  ТРЕКИНГ ИГРОКОВ
-- ════════════════════════════════════════════════
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

-- ════════════════════════════════════════════════
--  MODULE API
-- ════════════════════════════════════════════════
function module:Init()
	self._objects     = {}
	self._connections = {}
	self._npcTimer    = 0
end

function module:OnEnable()
	self.Enabled   = true
	self._objects  = {}
	self._npcTimer = 0

	-- Обработка существующих игроков
	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	-- Новые игроки
	storeConn("playerAdded", Players.PlayerAdded:Connect(function(player)
		setupPlayer(player)
	end))

	-- Игрок вышел
	storeConn("playerRemoving", Players.PlayerRemoving:Connect(function(player)
		removePlayerEntry(player)
		safeDC(module._connections["char_" .. player.UserId])
		safeDC(module._connections["team_" .. player.UserId])
		module._connections["char_" .. player.UserId] = nil
		module._connections["team_" .. player.UserId] = nil
	end))

	-- Автодетект NPC при добавлении в workspace
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
			if desc.Health > 0 and not module._objects[m] then
				addEntity(m, nil)
			end
		end)
	end))

	-- Удаление NPC из workspace
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

	-- Первоначальный скан NPC
	task.defer(scanNPCs)

	-- Главный цикл рендера
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

		-- Периодический рескан NPC
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
