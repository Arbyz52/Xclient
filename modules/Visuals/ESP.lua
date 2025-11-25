local module = {
    Name     = "ESP",
    Category = "Visuals",
    Enabled  = false,

    -- [player] = {
    --     highlight = Highlight,
    --     humanoid  = Humanoid,
    --     char      = Model,
    --     origHealthDisplayType = Enum.HumanoidHealthDisplayType,
    --     currentColor = Color3,
    --     targetColor  = Color3,
    -- }
    _esp         = {},
    _connections = {},
}

local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService  = game:GetService("RunService")
local StarterGui  = game:GetService("StarterGui")

-- ================== Утилиты ==================

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

local function destroyEspData(data, restoreHealthDisplay)
    if not data then return end
    pcall(function()
        if restoreHealthDisplay and data.humanoid and data.origHealthDisplayType then
            data.humanoid.HealthDisplayType = data.origHealthDisplayType
        end
        if data.highlight then
            data.highlight:Destroy()
        end
    end)
end

local function removeESP(player, restoreHealthDisplay)
    local data = module._esp[player]
    if data then
        destroyEspData(data, restoreHealthDisplay)
        module._esp[player] = nil
    end

    local key = "Char_" .. tostring(player.UserId)
    if module._connections[key] then
        disconnect(module._connections[key])
        module._connections[key] = nil
    end
end

-- ================== Цвет по ХП ==================

local function getColorForRatio(ratio)
    -- ratio 0..1
    -- 1  -> зелёный
    -- 0  -> красный
    local r = 255 * (1 - ratio)
    local g = 255 * ratio
    return Color3.fromRGB(r, g, 0)
end

-- ================== Создание ESP для персонажа ==================

local function createESPForCharacter(player, char, hum)
    if player == LocalPlayer then
        -- Себя не подсвечиваем, но можно скрыть стандартный HP бар, если нужно — отдельно
        return
    end

    -- Сохраним и выключим стандартную полоску хп над головой
    local origDisplayType = hum.HealthDisplayType
    hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff

    -- Стартовый цвет по текущему хп
    local ratio = 0
    if hum.MaxHealth > 0 then
        ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
    end
    local startColor = getColorForRatio(ratio)

    -- Highlight
    local hl = Instance.new("Highlight")
    hl.Name = "ESP_HL"
    hl.Adornee = char
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillColor = startColor
    hl.OutlineColor = startColor
    hl.Parent = char

    module._esp[player] = {
        highlight             = hl,
        humanoid              = hum,
        char                  = char,
        origHealthDisplayType = origDisplayType,
        currentColor          = startColor,
        targetColor           = startColor,
    }
end

local function onCharacterAdded(player, char)
    if player == LocalPlayer then
        -- Свой персонаж тут можно дополнительно настраивать, если нужно
        return
    end

    -- убираем старый ESP, но НЕ возвращаем полоску ХП (модуль включён)
    removeESP(player, false)

    local hum
    local ok = pcall(function()
        hum = char:WaitForChild("Humanoid", 5)
    end)

    if not ok or not hum then
        return
    end

    createESPForCharacter(player, char, hum)
end

local function watchPlayer(player)
    if player == LocalPlayer then
        return
    end

    local key = "Char_" .. tostring(player.UserId)
    addConnection(key, player.CharacterAdded:Connect(function(char)
        onCharacterAdded(player, char)
    end))

    -- Если персонаж уже есть — сразу обработаем
    if player.Character then
        onCharacterAdded(player, player.Character)
    end
end

-- ================== Обновление цвета (плавная анимация) ==================

local function updateAllColors(dt)
    -- скорость сглаживания (чем больше, тем быстрее анимация)
    local speed = 5  -- 5 = примерно 0.2 сек до нового цвета
    local alpha = math.clamp(dt * speed, 0, 1)

    for player, data in pairs(module._esp) do
        local hum = data.humanoid
        local hl  = data.highlight

        if hum and hl and hum.MaxHealth > 0 then
            local ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            local target = getColorForRatio(ratio)

            data.targetColor = target

            if not data.currentColor then
                data.currentColor = target
            else
                data.currentColor = data.currentColor:Lerp(target, alpha)
            end

            hl.FillColor    = data.currentColor
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

    -- Убираем стандартный HP GUI (левый верхний угол) у тебя на клиенте
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
    end)

    -- Подключаемся к уже существующим игрокам
    for _, plr in ipairs(Players:GetPlayers()) do
        watchPlayer(plr)
    end

    -- Новые игроки
    addConnection("PlayerAdded", Players.PlayerAdded:Connect(function(plr)
        watchPlayer(plr)
    end))

    -- Удаление при выходе игрока
    addConnection("PlayerRemoving", Players.PlayerRemoving:Connect(function(plr)
        removeESP(plr, false)
    end))

    -- Плавное обновление цвета по хп
    addConnection("Render", RunService.RenderStepped:Connect(updateAllColors))
end

function module:OnDisable()
    self.Enabled = false

    -- Вернуть стандартный HP GUI
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, true)
    end)

    -- Снять ESP со всех и ВЕРНУТЬ полоски хп над головой
    for plr, _ in pairs(self._esp) do
        removeESP(plr, true)
    end

    -- Отключить все соединения
    if type(self._connections) == "table" then
        for key, conn in pairs(self._connections) do
            disconnect(conn)
            self._connections[key] = nil
        end
    end
end

function module:OnTick(dt)
    -- не используется
end

return module
