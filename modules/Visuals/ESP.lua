local module = {
    Name     = "ESP",
    Category = "Visuals",
    Enabled  = false,

    _data        = {},   -- [player] = {humanoid, character, highlight, lastColor}
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
    if info.highlight then pcall(function() info.highlight:Destroy() end) end
    module._data[player] = nil
end

-- ========= ЛОГИКА КОМАНД =========

local function isEnemy(player)
    if player == LocalPlayer then return false end
    if not LocalPlayer.Team or not player.Team then
        return player ~= LocalPlayer
    end
    return player.Team ~= LocalPlayer.Team
end

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

-- ========= НАСТРОЙКА ЧАРА =========

local function setupCharacter(player, character)
    if not character then return end
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

    local hl = Instance.new("Highlight")
    hl.Name = "ESP_Highlight"
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency = 1
    hl.OutlineTransparency = 0

    -- выбираем корректный Adornee
    local adornee = character.PrimaryPart
        or character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("Torso")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChildWhichIsA("BasePart")

    if adornee then
        hl.Adornee = adornee
    end

    local ratio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
    local col = getHealthColor(ratio)
    hl.OutlineColor = col

    hl.Parent = CoreGui -- фикс: не в character

    module._data[player] = {
        humanoid  = hum,
        character = character,
        highlight = hl,
        lastColor = col,
    }

    hum.Died:Connect(function()
        destroyPlayerData(player)
    end)
end

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
    if isEnemy(player) and player.Character then
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
        if info.highlight then pcall(function() info.highlight:Destroy() end) end
    end
    self._data = {}
    for key, conn in pairs(self._connections) do
        disconnect(conn)
        self._connections[key] = nil
    end
end

function module:OnTick(dt) end

return module
