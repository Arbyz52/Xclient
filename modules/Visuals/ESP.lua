local module = {
    Name     = "ESP",
    Category = "Visuals",
    Enabled  = false,

    _data        = {},   -- [player] = {humanoid = ..., character = ..., lastColor = Color3}
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

local function setCharacterColor(char, color)
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("MeshPart") then
            if part.Name ~= "HumanoidRootPart" then
                pcall(function()
                    part.Color = color
                end)
            end
        end
    end
end

local function getHealthColor(ratio)
    ratio = math.clamp(ratio, 0, 1)

    -- 1.0 -> зелёный (0,255,0)
    -- 0.5 -> жёлтый (255,255,0)
    -- 0.0 -> красный (255,0,0)

    if ratio >= 0.5 then
        -- от 0.5 до 1: жёлтый -> зелёный
        local t = (ratio - 0.5) / 0.5  -- 0..1
        -- от (255,255,0) к (0,255,0)
        local r = 255 * (1 - t)
        local g = 255
        local b = 0
        return Color3.fromRGB(r, g, b)
    else
        -- от 0 до 0.5: красный -> жёлтый
        local t = ratio / 0.5  -- 0..1
        -- от (255,0,0) к (255,255,0)
        local r = 255
        local g = 255 * t
        local b = 0
        return Color3.fromRGB(r, g, b)
    end
end

local function destroyPlayerData(player)
    local info = module._data[player]
    if not info then return end
    module._data[player] = nil
end

--=========================
-- СОЗДАНИЕ / НАСТРОЙКА ИГРОКА
--=========================

local function setupCharacter(player, character)
    if player == LocalPlayer then return end
    if not character then return end

    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum then
        -- дождёмся появления Humanoid
        local key = "HumanoidWait_" .. tostring(player.UserId)
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

    -- начальный цвет по текущему ХП
    local maxHp = math.max(hum.MaxHealth, 1)
    local ratio = hum.Health / maxHp
    local targetColor = getHealthColor(ratio)

    setCharacterColor(character, targetColor)

    module._data[player] = {
        humanoid   = hum,
        character  = character,
        lastColor  = targetColor,
    }
end

local function onPlayerAdded(player)
    if player == LocalPlayer then return end

    -- если персонаж уже есть
    if player.Character then
        setupCharacter(player, player.Character)
    end

    -- отслеживаем новые персонажи
    local key = "Respawn_" .. tostring(player.UserId)
    addConnection(key, player.CharacterAdded:Connect(function(newChar)
        destroyPlayerData(player)
        setupCharacter(player, newChar)
    end))
end

local function onPlayerRemoving(player)
    destroyPlayerData(player)
end

--=========================
-- ОБНОВЛЕНИЕ ЦВЕТА
--=========================

local LERP_SPEED = 8 -- скорость плавного перехода (чем больше, тем быстрее)

local function updateAll()
    local dt = RunService.Heartbeat:Wait()  -- берём dt для плавности

    for player, info in pairs(module._data) do
        local hum = info.humanoid
        local char = info.character
        if hum and char and hum.MaxHealth > 0 then
            local ratio = hum.Health / hum.MaxHealth
            ratio = math.clamp(ratio, 0, 1)
            local targetColor = getHealthColor(ratio)

            -- плавный переход от lastColor к targetColor
            local current = info.lastColor or targetColor
            local alpha = math.clamp(LERP_SPEED * dt, 0, 1)
            local newColor = current:Lerp(targetColor, alpha)

            setCharacterColor(char, newColor)
            info.lastColor = newColor
        end
    end
end

--=========================
-- МОДУЛЬНЫЕ МЕТОДЫ
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

    addConnection("PlayerAdded", Players.PlayerAdded:Connect(onPlayerAdded))
    addConnection("PlayerRemoving", Players.PlayerRemoving:Connect(onPlayerRemoving))

    -- обновление (анимация цвета)
    addConnection("Update", RunService.RenderStepped:Connect(function()
        updateAll()
    end))
end

function module:OnDisable()
    self.Enabled = false

    -- вернуть дефолтное поведение HP и сбросить данные
    for plr, info in pairs(self._data) do
        if info.humanoid then
            restoreDefaultHp(info.humanoid)
        end
        -- Цвет персонажа я не трогаю обратно, чтобы не ломать скины.
        -- Если хочешь вернуть исходный цвет – нужен кэш исходных цветов.
    end

    self._data = {}

    -- отключить все коннекты
    for key, conn in pairs(self._connections) do
        disconnect(conn)
        self._connections[key] = nil
    end
end

function module:OnTick(dt)
end

return module
