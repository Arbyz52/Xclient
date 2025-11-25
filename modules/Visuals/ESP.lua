local module = {
    Name     = "ESP",
    Category = "Visuals",
    Enabled  = false,

    _esp         = {},   -- [player] = {highlight, humanoid, origDisplayType, currentColor, targetColor}
    _connections = {},

    _localHumanoid        = nil,
    _localOrigDisplayType = nil,
}

local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService  = game:GetService("RunService")
local StarterGui  = game:GetService("StarterGui")

-- ==== утилиты ====

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

-- ==== цвет по хп ====
-- 0  -> красный
-- 0.5-> жёлтый
-- 1  -> зелёный
local function getColorForRatio(r)
    r = math.clamp(r or 0, 0, 1)
    if r < 0.5 then
        local t = r / 0.5            -- 0..1 (красный -> жёлтый)
        return Color3.fromRGB(255, math.floor(255 * t), 0)
    else
        local t = (r - 0.5) / 0.5    -- 0..1 (жёлтый -> зелёный)
        return Color3.fromRGB(math.floor(255 * (1 - t)), 255, 0)
    end
end

-- ==== настройка персонажа ====

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

    -- локального игрока не подсвечиваем, только прячем HP‑бар
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

    local hl = Instance.new("Highlight")
    hl.Name = "ESP_Highlight"
    hl.Adornee = char
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency = 1                -- нет заливки, только контур
    hl.FillColor = startColor             -- всё равно задаём, на всякий случай
    hl.OutlineTransparency = 0
    hl.OutlineColor = startColor
    hl.Parent = char

    module._esp[player] = {
        highlight       = hl,
        humanoid        = hum,
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

-- ==== плавное обновление цвета ====

local function updateAll(dt)
    -- экспоненциальное сглаживание (быстрая, но плавная анимация)
    local speed = 6
    local alpha = 1 - math.exp(-speed * dt)

    for player, data in pairs(module._esp) do
        local hum = data.humanoid
        local hl  = data.highlight
        if hum and hum.Parent and hl and hl.Parent then
            local ratio = 0
            if hum.MaxHealth > 0 then
                ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            end

            local target = getColorForRatio(ratio)
            data.targetColor = target

            local cur = data.currentColor or target
            data.currentColor = cur:Lerp(target, alpha)

            -- ЖЁСТКО каждый кадр задаём цвет и прозрачность, чтобы
            -- никакие другие скрипты и дефолтный синий не вмешивались
            hl.FillTransparency = 1
            hl.FillColor        = data.currentColor
            hl.OutlineColor     = data.currentColor
        end
    end
end

-- ==== публичные методы ====

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

    for _, plr in ipairs(Players:GetPlayers()) do
        trackPlayer(plr)
    end

    addConnection(Players.PlayerAdded:Connect(trackPlayer))

    addConnection(Players.PlayerRemoving:Connect(function(plr)
        destroyEspData(plr, true)
        if plr == LocalPlayer then
            module._localHumanoid        = nil
            module._localOrigDisplayType = nil
        end
    end))

    addConnection(RunService.RenderStepped:Connect(updateAll))
end

function module:OnDisable()
    self.Enabled = false

    -- вернуть GUI‑хп
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, true)
    end)

    -- вернуть полоски над головами и удалить хайлайты
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
