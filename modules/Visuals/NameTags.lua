local module = {
    Name     = "NameTags",
    Category = "Visuals",
    Enabled  = false,

    _data        = {},   -- [player] = {humanoid, character, highlight, lastColor}
    _connections = {},

    -- настройки NameTags
    NameTagsEnabled = false,
    _nameTags       = {}, -- [player] = BillboardGui
}

local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService  = game:GetService("RunService")

-- ========= УТИЛИТЫ =========

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

local function destroyNameTag(player)
    local gui = module._nameTags[player]
    if gui then
        pcall(function() gui:Destroy() end)
    end
    module._nameTags[player] = nil
end

local function destroyPlayerData(player)
    local info = module._data[player]
    if info and info.highlight then
        pcall(function() info.highlight:Destroy() end)
    end
    module._data[player] = nil
    destroyNameTag(player)
end

-- ========= ЛОГИКА КОМАНД =========
-- Подсвечиваем только врагов, себя НЕ трогаем

local function isEnemy(player)
    if player == LocalPlayer then
        return false
    end

    -- если у игры нет команд, то все, кроме LocalPlayer, считаются врагами
    if not LocalPlayer.Team or not player.Team then
        return player ~= LocalPlayer
    end

    return player.Team ~= LocalPlayer.Team
end

-- Цвет по HP: 1 = зелёный, 0.5 = жёлтый, 0 = красный
local function getHealthColor(ratio)
    ratio = math.clamp(ratio, 0, 1)

    if ratio >= 0.5 then
        -- жёлтый -> зелёный
        local t = (ratio - 0.5) / 0.5
        local r = 255 * (1 - t)
        local g = 255
        local b = 0
        return Color3.fromRGB(r, g, b)
    else
        -- красный -> жёлтый
        local t = ratio / 0.5
        local r = 255
        local g = 255 * t
        local b = 0
        return Color3.fromRGB(r, g, b)
    end
end

-- ========= NAME TAGS =========

local function createOrUpdateNameTag(player, info)
    if not module.NameTagsEnabled then return end
    if player == LocalPlayer then return end             -- СЕБЯ НЕ ТРОГАЕМ
    if not isEnemy(player) then                          -- только враги
        destroyNameTag(player)
        return
    end
    if not info or not info.character or not info.humanoid then return end

    local char = info.character
    local head = char:FindFirstChild("Head")
    if not head then return end

    local nameTag = module._nameTags[player]
    if not nameTag then
        nameTag = Instance.new("BillboardGui")
        nameTag.Name = "ESP_NameTag"
        nameTag.AlwaysOnTop = true
        nameTag.Size = UDim2.new(0, 200, 0, 50)
        nameTag.StudsOffset = Vector3.new(0, 3, 0)
        nameTag.MaxDistance = 300
        nameTag.Adornee = head

        local frame = Instance.new("Frame")
        frame.Name = "Main"
        frame.BackgroundTransparency = 1
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.Parent = nameTag

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "NameLabel"
        nameLabel.BackgroundTransparency = 1
        nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
        nameLabel.Position = UDim2.new(0, 0, 0, 0)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextScaled = true
        nameLabel.TextColor3 = Color3.new(1, 1, 1)
        nameLabel.TextStrokeTransparency = 0
        nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        nameLabel.Parent = frame

        local hpBack = Instance.new("Frame")
        hpBack.Name = "HpBack"
        hpBack.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        hpBack.BorderSizePixel = 0
        hpBack.Size = UDim2.new(1, 0, 0.25, 0)
        hpBack.Position = UDim2.new(0, 0, 0.7, 0)
        hpBack.Parent = frame

        local hpFill = Instance.new("Frame")
        hpFill.Name = "HpFill"
        hpFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        hpFill.BorderSizePixel = 0
        hpFill.Size = UDim2.new(1, 0, 1, 0)
        hpFill.Parent = hpBack

        nameTag.Parent = char
        module._nameTags[player] = nameTag
    end

    local hum   = info.humanoid
    local ratio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
    local col   = getHealthColor(ratio)

    local frame   = nameTag:FindFirstChild("Main")
    if not frame then return end
    local nameLbl = frame:FindFirstChild("NameLabel")
    local hpBack  = frame:FindFirstChild("HpBack")
    local hpFill  = hpBack and hpBack:FindFirstChild("HpFill")

    if nameLbl then
        nameLbl.Text = player.Name
        nameLbl.TextColor3 = col
    end
    if hpFill then
        hpFill.Size = UDim2.new(ratio, 0, 1, 0)
        hpFill.BackgroundColor3 = col
    end
end

-- ========= НАСТРОЙКА ЧАРА =========

local function setupCharacter(player, character)
    if not character then return end

    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum then
        -- ждём Humanoid, если его ещё нет
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

    -- создаём Highlight
    local hl = Instance.new("Highlight")
    hl.Name = "ESP_Highlight"
    hl.Adornee = character
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    hl.FillTransparency = 1
    hl.OutlineTransparency = 0

    local ratio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
    local col = getHealthColor(ratio)
    hl.OutlineColor = col

    hl.Parent = character

    module._data[player] = {
        humanoid  = hum,
        character = character,
        highlight = hl,
        lastColor = col,
    }

    -- создаём/обновляем NameTag для врага
    createOrUpdateNameTag(player, module._data[player])
end

-- слежение за сменой команды
local function trackTeamChange(player)
    local key = "TeamChanged_" .. player.UserId
    addConnection(key, player:GetPropertyChangedSignal("Team"):Connect(function()
        -- если стал тиммейтом – убираем ESP и NameTag
        if not isEnemy(player) then
            destroyPlayerData(player)
            return
        end

        -- если стал врагом – вешаем ESP, если есть персонаж
        if player.Character then
            destroyPlayerData(player)
            setupCharacter(player, player.Character)
        end
    end))
end

local function onPlayerAdded(player)
    -- не трогаем локального игрока вообще
    if player == LocalPlayer then
        return
    end

    trackTeamChange(player)

    if not isEnemy(player) then
        return
    end

    if player.Character then
        setupCharacter(player, player.Character)
    end

    local key = "Respawn_" .. player.UserId
    addConnection(key, player.CharacterAdded:Connect(function(newChar)
        destroyPlayerData(player)
        if isEnemy(player) then
            setupCharacter(player, newChar)
        end
    end))
end

local function onPlayerRemoving(player)
    destroyPlayerData(player)
end

-- ========= ОБНОВЛЕНИЕ ЦВЕТА =========

local LERP_SPEED = 10

local function updateAll(dt)
    for player, info in pairs(module._data) do
        local hum = info.humanoid
        local hl  = info.highlight
        if hum and hl and hum.MaxHealth > 0 then
            local ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            local targetColor = getHealthColor(ratio)

            local current = info.lastColor or targetColor
            local alpha   = math.clamp(LERP_SPEED * dt, 0, 1)
            local newColor = current:Lerp(targetColor, alpha)

            hl.OutlineColor = newColor
            info.lastColor  = newColor

            -- обновляем NameTag
            createOrUpdateNameTag(player, info)
        end
    end
end

-- ========= МОДУЛЬНЫЕ МЕТОДЫ =========

function module:Init()
    if not self._data then self._data = {} end
    if not self._connections then self._connections = {} end
    if not self._nameTags then self._nameTags = {} end
end

function module:OnEnable()
    self.Enabled = true

    for _, plr in ipairs(Players:GetPlayers()) do
        onPlayerAdded(plr)
    end

    addConnection("PlayerAdded",    Players.PlayerAdded:Connect(onPlayerAdded))
    addConnection("PlayerRemoving", Players.PlayerRemoving:Connect(onPlayerRemoving))

    addConnection("RenderUpdate", RunService.RenderStepped:Connect(function(dt)
        updateAll(dt)
    end))
end

function module:OnDisable()
    self.Enabled = false

    for plr, info in pairs(self._data) do
        if info.humanoid then
            restoreDefaultHp(info.humanoid)
        end
        if info.highlight then
            pcall(function() info.highlight:Destroy() end)
        end
        destroyNameTag(plr)
    end
    self._data = {}
    self._nameTags = {}

    for key, conn in pairs(self._connections) do
        disconnect(conn)
        self._connections[key] = nil
    end
end

function module:OnTick(dt)
end

-- ========= ПУБЛИЧНАЯ ФУНКЦИЯ ДЛЯ ВКЛ/ВЫКЛ NAMETAGS =========
-- пример вызова снаружи: module:NameTags(true) или module:NameTags(false)

function module:NameTags(state)
    self.NameTagsEnabled = state and true or false

    -- если отключили – сразу убрать все BillboardGui
    if not self.NameTagsEnabled then
        for plr, _ in pairs(self._nameTags) do
            destroyNameTag(plr)
        end
    else
        -- если включили – создать NameTag для уже отслеживаемых врагов
        for plr, info in pairs(self._data) do
            createOrUpdateNameTag(plr, info)
        end
    end
end

return module
