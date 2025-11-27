local module = {
    Name     = "NameTags",
    Category = "Visuals",
    Enabled  = false,

    _data        = {},   -- [player] = {humanoid, character, nameTagGui, nameTagLabel, lastColor}
    _connections = {},
}

local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService  = game:GetService("RunService")
local CoreGui     = game:GetService("CoreGui")

-- ========= УТИЛИТЫ =========

local function disconnect(conn)
    if conn then pcall(function() conn:Disconnect() end) end
end

local function addConnection(key, conn)
    if key then
        if module._connections[key] then disconnect(module._connections[key]) end
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

    if info.nameTagGui then pcall(function() info.nameTagGui:Destroy() end) end
    module._data[player] = nil
end

-- ========= ЛОГИКА КОМАНД =========

local function isEnemy(player)
    if player == LocalPlayer then return false end
    local lt = LocalPlayer.Team
    local pt = player.Team
    if lt == nil or pt == nil then
        return player ~= LocalPlayer
    end
    return lt ~= pt
end

-- Цвет по HP: 1 = зелёный, 0.5 = жёлтый, 0 = красный
local function getHealthColor(ratio)
    ratio = math.clamp(ratio, 0, 1)
    if ratio >= 0.5 then
        local t = (ratio - 0.5) / 0.5
        local r = 255 * (1 - t)
        return Color3.fromRGB(r, 255, 0)
    else
        local t = ratio / 0.5
        local g = 255 * t
        return Color3.fromRGB(255, g, 0)
    end
end

-- ========= ФУНКЦИЯ СОЗДАНИЯ НЕЙМТАГА =========

local function createNameTag(player, character, humanoid, startColor)
    if not character then return end

    local head = character:FindFirstChild("Head")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
        or character:FindFirstChildWhichIsA("BasePart")

    if not head then return end

    local tagGui = Instance.new("BillboardGui")
    tagGui.Name = "ESP_NameTag"
    tagGui.Adornee = head
    tagGui.AlwaysOnTop = true
    tagGui.Size = UDim2.new(0, 150, 0, 25)
    tagGui.StudsOffset = Vector3.new(0, 2.5, 0)
    tagGui.MaxDistance = 0 -- без ограничения дистанции

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.TextColor3 = startColor or Color3.new(1, 1, 1)
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center

    local hp  = humanoid and math.floor(humanoid.Health + 0.5) or 0
    local max = humanoid and math.floor(humanoid.MaxHealth + 0.5) or 0
    label.Text = string.format("%s [%d/%d]", player.Name, hp, max)

    label.Parent = tagGui
    tagGui.Parent = CoreGui -- ключевой фикс: BillboardGui должен быть в GUI-сервисе

    return tagGui, label
end

-- ========= НАСТРОЙКА ЧАРА =========

local function setupCharacter(player, character)
    if not character then return end

    -- фильтр врагов
    if not isEnemy(player) then
        destroyPlayerData(player)
        return
    end

    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum then
        local key = "HumWait_" .. player.UserId
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

    local ratio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
    local col = getHealthColor(ratio)

    local tagGui, tagLabel = createNameTag(player, character, hum, col)
    if not tagGui or not tagLabel then return end

    module._data[player] = {
        humanoid     = hum,
        character    = character,
        nameTagGui   = tagGui,
        nameTagLabel = tagLabel,
        lastColor    = col,
    }

    -- Автоочистка при смерти, чтобы не висели теги
    local diedKey = "Died_" .. player.UserId
    addConnection(diedKey, hum.Died:Connect(function()
        destroyPlayerData(player)
    end))
end

-- слежение за сменой команды
local function trackTeamChange(player)
    local key = "TeamChanged_" .. player.UserId
    addConnection(key, player:GetPropertyChangedSignal("Team"):Connect(function()
        destroyPlayerData(player)
        if isEnemy(player) and player.Character then
            setupCharacter(player, player.Character)
        end
    end))
end

local function onPlayerAdded(player)
    if player == LocalPlayer then return end

    trackTeamChange(player)

    if player.Character then
        setupCharacter(player, player.Character)
    end

    local key = "Respawn_" .. player.UserId
    addConnection(key, player.CharacterAdded:Connect(function(newChar)
        destroyPlayerData(player)
        setupCharacter(player, newChar)
    end))
end

local function onPlayerRemoving(player)
    destroyPlayerData(player)
end

-- ========= ОБНОВЛЕНИЕ ЦВЕТА И ТЕКСТА =========

local LERP_SPEED = 10

local function updateAll(dt)
    for player, info in pairs(module._data) do
        local hum = info.humanoid
        local label = info.nameTagLabel
        if hum and label and hum.MaxHealth > 0 then
            local ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            local targetColor = getHealthColor(ratio)

            local current = info.lastColor or targetColor
            local alpha   = math.clamp(LERP_SPEED * dt, 0, 1)
            local newColor = current:Lerp(targetColor, alpha)

            info.lastColor = newColor
            label.TextColor3 = newColor

            local hp  = math.floor(hum.Health + 0.5)
            local max = math.floor(hum.MaxHealth + 0.5)
            label.Text = string.format("%s [%d/%d]", player.Name, hp, max)
        end
    end
end

-- ========= МОДУЛЬНЫЕ МЕТОДЫ =========

function module:Init()
    self._data = {}
    self._connections = {}
end

function module:OnEnable()
    self.Enabled = true

    for _, plr in ipairs(Players:GetPlayers()) do
        onPlayerAdded(plr)
    end

    addConnection("PlayerAdded",    Players.PlayerAdded:Connect(onPlayerAdded))
    addConnection("PlayerRemoving", Players.PlayerRemoving:Connect(onPlayerRemoving))
    addConnection("RenderUpdate",   RunService.RenderStepped:Connect(updateAll))
end

function module:OnDisable()
    self.Enabled = false

    for _, info in pairs(self._data) do
        if info.humanoid then restoreDefaultHp(info.humanoid) end
        if info.nameTagGui then pcall(function() info.nameTagGui:Destroy() end) end
    end
    self._data = {}

    for key, conn in pairs(self._connections) do
        disconnect(conn)
        self._connections[key] = nil
    end
end

function module:OnTick(dt) end

return module
