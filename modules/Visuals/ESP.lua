local module = {
    Name     = "ESP",
    Category = "Visuals",
    Enabled  = false,

    -- [player] = {
    --     highlight = Highlight,
    --     humanoid  = Humanoid,
    --     origHealthDisplayType = Enum.HumanoidHealthDisplayType,
    --     currentColor = Color3,
    --     targetColor  = Color3,
    -- }
    _esp           = {},
    _connections   = {},

    _localHumanoid        = nil,
    _localOrigDisplayType = nil,
}

local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService  = game:GetService("RunService")
local StarterGui  = game:GetService("StarterGui")

-- ================== Утилиты ==================

local function addConnection(conn)
    table.insert(module._connections, conn)
    return conn
end

local function disconnectAll()
    for i, conn in ipairs(module._connections) do
        if conn then
            pcall(function() conn:Disconnect() end)
        end
        module._connections[i] = nil
    end
end

local function destroyEspData(player, restoreHealthDisplay)
    local data = module._esp[player]
    if not data then return end
    module._esp[player] = nil

    pcall(function()
        if restoreHealthDisplay and data.humanoid and data.origHealthDisplayType then
            data.humanoid.HealthDisplayType = data.origHealthDisplayType
        end
        if data.highlight then
            data.highlight:Destroy()
        end
    end)
end

-- ================== Цвет по ХП ==================

local function getColorForRatio(ratio)
    -- 1 -> зелёный, 0 -> красный
    local r = math.floor(255 * (1 - ratio))
    local g = math.floor(255 * ratio)
    return Color3.fromRGB(r, g, 0)
end

-- ================== Создание ESP для персонажа ==================

local function setupCharacterForPlayer(player, char)
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

    -- убрать старый ESP с этого игрока (если был), НО не возвращать полоску (мы её сразу снова выключим)
    destroyEspData(player, false)

    local origDisplayType = hum.HealthDisplayType
    hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff -- убираем здоровье над головой

    -- Для локального игрока: полоску над головой выключаем, но чамс НЕ рисуем
    if player == LocalPlayer then
        module._localHumanoid        = hum
        module._localOrigDisplayType = origDisplayType
        return
    end

    -- начальный цвет по хп
    local ratio = 0
    if hum.MaxHealth > 0 then
        ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
    end
    local startColor = getColorForRatio(ratio)

    -- Highlight (чамс) ТОЛЬКО обводка, без заливки частей тела
    local hl = Instance.new("Highlight")
    hl.Name = "ESP_Highlight"
    hl.Adornee = char
    hl.FillTransparency = 1                    -- НЕТ заливки, только контур
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- видно сквозь стены
    hl.OutlineColor = startColor
    hl.Parent = char

    module._esp[player] = {
        highlight             = hl,
        humanoid              = hum,
        origHealthDisplayType = origDisplayType,
        currentColor          = startColor,
        targetColor           = startColor,
    }
end

local function trackPlayer(player)
    -- следим за сменой персонажа
    addConnection(player.CharacterAdded:Connect(function(char)
        setupCharacterForPlayer(player, char)
    end))

    -- если персонаж уже есть
    if player.Character then
        setupCharacterForPlayer(player, player.Character)
    end
end

-- ================== Плавное обновление цвета ==================

local function updateAllColors(dt)
    local speed = 5                          -- чем больше, тем быстрее анимация
    local alpha = math.clamp(dt * speed, 0, 1)

    for player, data in pairs(module._esp) do
        local hum = data.humanoid
        local hl  = data.highlight
        if hum and hl and hum.Parent and hum.MaxHealth > 0 then
            local ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            local target = getColorForRatio(ratio)

            data.targetColor = target

            if not data.currentColor then
                data.currentColor = target
            else
                data.currentColor = data.currentColor:Lerp(target, alpha)
            end

            hl.OutlineColor = data.currentColor
        end
    end
end

-- ================== Публичные методы ==================

function module:Init()
    if not self._esp then self._esp = {} end
    if not self._connections then self._connections = {} end
end

function module:OnEnable()
    self.Enabled = true

    -- отключаем стандартный GUI-хп (в углу экрана)
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
    end)

    -- подписываемся на уже существующих игроков
    for _, plr in ipairs(Players:GetPlayers()) do
        trackPlayer(plr)
    end

    -- новые игроки
    addConnection(Players.PlayerAdded:Connect(function(plr)
        trackPlayer(plr)
    end))

    -- когда игрок выходит — удаляем его ESP и возвращаем полоску над головой
    addConnection(Players.PlayerRemoving:Connect(function(plr)
        destroyEspData(plr, true)
        if plr == LocalPlayer then
            module._localHumanoid        = nil
            module._localOrigDisplayType = nil
        end
    end))

    -- плавное обновление цветов
    addConnection(RunService.RenderStepped:Connect(updateAllColors))
end

function module:OnDisable()
    self.Enabled = false

    -- вернуть стандартный GUI-хп
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, true)
    end)

    -- вернуть полоски хп над головой всем игрокам, убрать чамсы
    for plr, _ in pairs(self._esp) do
        destroyEspData(plr, true)
    end

    -- вернуть полоску над головой локального игрока
    if self._localHumanoid and self._localOrigDisplayType then
        pcall(function()
            self._localHumanoid.HealthDisplayType = self._localOrigDisplayType
        end)
    end
    self._localHumanoid        = nil
    self._localOrigDisplayType = nil

    -- отключить все коннекты
    disconnectAll()
end

function module:OnTick(dt)
    -- не используется
end

return module
