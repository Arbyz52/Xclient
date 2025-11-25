local module = {
    Name     = "ESP",
    Category = "Visuals",
    Enabled  = false,

    _data        = {},   -- [player] = {humanoid = ..., character = ..., highlight = ..., lastColor = Color3}
    _connections = {},   -- ключ -> Connection
}

local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService  = game:GetService("RunService")

--=========================
-- УТИЛИТЫ
--=========================

local function disconnect(conn)
    if conn then
        pcall(function() conn:Disconnect() end)
    end
end

local function addConnection(key, conn)
    if key then
        if module._connections[key] then
            disconnect(module._connections[key])
        end
        module._connections[key] = conn
    else
        table.insert(module._connections, conn)
    end
end

local function disableDefaultHp(humanoid)
    if not humanoid then return end
    pcall(function()
        humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
    end)
end

local function restoreDefaultHp(humanoid)
    if not humanoid then return end
    pcall(function()
        humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.DisplayWhenDamaged
    end)
end

local function destroyPlayerData(player)
    local info = module._data[player]
    if not info then return end
    if info.highlight then
        pcall(function() info.highlight:Destroy() end)
    end
    module._data[player] = nil
end

-- цвет по хп: зелёный → жёлтый → красный
local function getHealthColor(ratio)
    ratio = math.clamp(ratio, 0, 1)

    -- 1.0 -> зелёный (0,255,0)
    -- 0.5 -> жёлтый (255,255,0)
    -- 0.0 -> красный (255,0,0)

    if ratio >= 0.5 then
        -- от 0.5 до 1: жёлтый -> зелёный
        local t = (ratio - 0.5) / 0.5  -- 0..1
        local r = 255 * (1 - t)       -- 255 -> 0
        local g = 255                 -- постоянный
        local b = 0
        return Color3.fromRGB(r, g, b)
    else
        -- от 0 до 0.5: красный -> жёлтый
        local t = ratio / 0.5         -- 0..1
        local r = 255
        local g = 255 * t             -- 0 -> 255
        local b = 0
        return Color3.fromRGB(r, g, b)
    end
end

--=========================
-- НАСТРОЙКА ИГРОКА
--=========================

local function setupCharacter(player, character)
    if player == LocalPlayer then return end
    if not character then return end

    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum then
        -- дождёмся появления Humanoid
        local key = "HumWait_" .. tostring(player.UserId)
        addConnection(key, character.ChildAdded:Connect(function(child)
            if child:IsA("Humanoid") then
                disconnect(module._connections[key])
                module._connections[key] = nil
                setupCharacter(player, character)
            end
        end))
        return
    end

    disableDefaultHp(hum)

    -- создаём Highlight
    local hl = Instance.new("Highlight")
    hl.Name = "ESP_Highlight"
    hl.Adornee = character
    hl.FillTransparency = 0.7
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = character

    -- начальный цвет по текущему хп
    local maxHp = math.max(hum.MaxHealth, 1)
    local ratio = hum.Health / maxHp
    local col   = getHealthColor(ratio)
    hl.OutlineColor = col
    hl.FillColor    = col

    module._data[player] = {
        humanoid  = hum,
        character = character,
        highlight = hl,
        lastColor = col,
    }
end

local function onPlayerAdded(player)
    if player ~= LocalPlayer then
        if player.Character then
            setupCharacter(player, player.Character)
        end

        local key = "Respawn_" .. tostring(player.UserId)
        addConnection(key, player.CharacterAdded:Connect(function(newChar)
            destroyPlayerData(player)
            setupCharacter(player, newChar)
        end))
    else
        -- даже локальному выключим надпись хп, если хочешь без неё
        if player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            disableDefaultHp(hum)
        end
        local key = "LocalRespawn"
        addConnection(key, player.CharacterAdded:Connect(function(newChar)
            local hum = newChar:FindFirstChildOfClass("Humanoid")
            disableDefaultHp(hum)
        end))
    end
end

local function onPlayerRemoving(player)
    destroyPlayerData(player)
end

--=========================
-- ОБНОВЛЕНИЕ ЦВЕТА (АНИМАЦИЯ)
--=========================

local LERP_SPEED = 10 -- скорость плавного перехода

local function updateAll(dt)
    for player, info in pairs(module._data) do
        local hum = info.humanoid
        local hl  = info.highlight
        local char = info.character

        if hum and hl and char and hum.MaxHealth > 0 then
            local ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            local targetColor = getHealthColor(ratio)

            local current = info.lastColor or targetColor
            local alpha   = math.clamp(LERP_SPEED * dt, 0, 1)
            local newColor = current:Lerp(targetColor, alpha)

            hl.OutlineColor = newColor
            hl.FillColor    = newColor
            info.lastColor  = newColor
        end
    end
end

--=========================
-- МЕТОДЫ МОДУЛЯ
--=========================

function module:Init()
    if not self._data then self._data = {} end
    if not self._connections then self._connections = {} end
end

function module:OnEnable()
    self.Enabled = true

    -- уже находящиеся игроки
    for _, plr in ipairs(Players:GetPlayers()) do
        onPlayerAdded(plr)
    end

    addConnection("PlayerAdded",   Players.PlayerAdded:Connect(onPlayerAdded))
    addConnection("PlayerRemoving",Players.PlayerRemoving:Connect(onPlayerRemoving))

    addConnection("RenderUpdate", RunService.RenderStepped:Connect(function(dt)
        updateAll(dt)
    end))
end

function module:OnDisable()
    self.Enabled = false

    -- вернуть стандартные hp‑надписи
    for plr, info in pairs(self._data) do
        if info.humanoid then
            restoreDefaultHp(info.humanoid)
        end
        if info.highlight then
            pcall(function() info.highlight:Destroy() end)
        end
    end
    self._data = {}

    for key, conn in pairs(self._connections) do
        disconnect(conn)
        self._connections[key] = nil
    end
end

function module:OnTick(dt)
end

return module
