local module = {
    Name     = "ESP",
    Category = "Visuals",
    Enabled  = false,

    -- [player] = {
    --     highlight, humanoid, char,
    --     origDisplayType, currentColor, targetColor
    -- }
    _esp         = {},
    _connections = {},

    _localHumanoid        = nil,
    _localOrigDisplayType = nil,
}

local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService  = game:GetService("RunService")
local StarterGui  = game:GetService("StarterGui")

----------------- утилиты -----------------

local function addConnection(conn)
    table.insert(module._connections, conn)
    return conn
end

local function disconnectAll()
    for i, conn in ipairs(module._connections) do
        if conn then pcall(function() conn:Disconnect() end) end
        module._connections[i] = nil
    end
end

local function clearCharHighlights(char, keep)
    if not char or not char.Parent then return end
    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("Highlight") and obj ~= keep then
            pcall(function() obj:Destroy() end)
        end
    end
end

local function destroyEspData(player, restoreDisplay)
    local data = module._esp[player]
    if not data then return end
    module._esp[player] = nil

    if restoreDisplay and data.humanoid and data.origDisplayType then
        pcall(function()
            data.humanoid.HealthDisplayType = data.origDisplayType
        end)
    end

    if data.highlight then
        pcall(function() data.highlight:Destroy() end)
    end
end

----------------- цвет по хп -----------------
-- 0   -> красный
-- 0.5 -> жёлтый
-- 1   -> зелёный
local function getColorForRatio(r)
    r = math.clamp(r or 0, 0, 1)
    if r < 0.5 then
        local t = r / 0.5              -- 0..1 (красный -> жёлтый)
        return Color3.fromRGB(255, math.floor(255 * t), 0)
    else
        local t = (r - 0.5) / 0.5      -- 0..1 (жёлтый -> зелёный)
        return Color3.fromRGB(math.floor(255 * (1 - t)), 255, 0)
    end
end

----------------- настройка персонажа -----------------

local function setupCharacter(player, char)
    if not char then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then
        local ok, res = pcall(function()
            return char:WaitForChild("Humanoid", 5)
        end)
        if not ok then return end
        hum = res
        if not hum then return end
    end

    -- убрать старый ESP (без возврата полоски, мы её снова выключим)
    destroyEspData(player, false)

    -- выключаем полоску HP над головой
    local origDisplay = hum.HealthDisplayType
    hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff

    -- чистим ВСЕ чужие хайлайты с этого персонажа
    clearCharHighlights(char, nil)

    -- локального игрока не подсвечиваем, только убираем HP‑бар
    if player == LocalPlayer then
        module._localHumanoid        = hum
        module._localOrigDisplayType = origDisplay
        return
    end

    local ratio = 0
    if hum.MaxHealth > 0 then
        ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
    end
    local startColor = getColorForRatio(ratio)

    -- наш единственный Highlight
    local hl = Instance.new("Highlight")
    hl.Name = "ESP_Highlight"
    hl.Adornee = char
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency = 1           -- только контур
    hl.FillColor        = startColor  -- на всякий
    hl.OutlineTransparency = 0
    hl.OutlineColor        = startColor
    hl.Parent = char

    module._esp[player] = {
        highlight       = hl,
        humanoid        = hum,
        char            = char,
        origDisplayType = origDisplay,
        currentColor    = startColor,
        targetColor     = startColor,
    }
end

local function trackPlayer(player)
    addConnection(player.CharacterAdded:Connect(function(char)
        setupCharacter(player, char)
    end))

    if player.Character then
        setupCharacter(player, player.Character)
    end
end

----------------- плавное обновление -----------------

local function updateAll(dt)
    local speed = 6
    local alpha = 1 - math.exp(-speed * dt)

    for player, data in pairs(module._esp) do
        local hum  = data.humanoid
        local hl   = data.highlight
        local char = data.char

        if hum and hum.Parent and hl and hl.Parent and char and char.Parent then
            -- ещё раз подчистим все чужие хайлайты, оставив только наш
            clearCharHighlights(char, hl)

            local ratio = 0
            if hum.MaxHealth > 0 then
                ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            end

            local target = getColorForRatio(ratio)
            data.targetColor = target

            local cur = data.currentColor or target
            data.currentColor = cur:Lerp(target, alpha)

            -- ЖЁСТКО каждый кадр прописываем настройки,
            -- чтобы никакие другие скрипты не могли оставить синий.
            hl.FillTransparency  = 1
            hl.FillColor         = data.currentColor
            hl.OutlineTransparency = 0
            hl.OutlineColor        = data.currentColor
        end
    end
end

----------------- публичные методы -----------------

function module:Init()
    self._esp = {}
    self._connections = {}
    self._localHumanoid = nil
    self._localOrigDisplayType = nil
end

function module:OnEnable()
    self.Enabled = true

    -- убираем GUI‑хп в углу экрана
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
    end)

    -- уже присутствующие игроки
    for _, plr in ipairs(Players:GetPlayers()) do
        trackPlayer(plr)
    end

    -- новые игроки
    addConnection(Players.PlayerAdded:Connect(trackPlayer))

    -- выход игроков
    addConnection(Players.PlayerRemoving:Connect(function(plr)
        destroyEspData(plr, true)
        if plr == LocalPlayer then
            module._localHumanoid        = nil
            module._localOrigDisplayType = nil
        end
    end))

    -- апдейт
    addConnection(RunService.RenderStepped:Connect(updateAll))
end

function module:OnDisable()
    self.Enabled = false

    -- вернуть GUI‑хп
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, true)
    end)

    -- вернуть полоски над головой и убрать ESP
    for plr, _ in pairs(self._esp) do
        destroyEspData(plr, true)
    end

    if self._localHumanoid and self._localOrigDisplayType then
        pcall(function()
            self._localHumanoid.HealthDisplayType = self._localOrigDisplayType
        end)
    end
    self._localHumanoid        = nil
    self._localOrigDisplayType = nil

    disconnectAll()
end

function module:OnTick(dt)
    -- не используется
end

return module
