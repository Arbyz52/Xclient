local module = {
    Name     = "ESP",
    Category = "Visuals",
    Enabled  = false,
}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Настройки ESP
local ESP_COLOR = Color3.fromRGB(255, 0, 0)
local FILL_TRANSPARENCY = 0.5
local OUTLINE_TRANSPARENCY = 0
local DEPTH_MODE = Enum.HighlightDepthMode.AlwaysOnTop

-- Хранилище ESP-объектов
module._esp = {}
module._connections = {}

-- Создание ESP для игрока
local function createESP(player)
    if player == LocalPlayer then return end
    if module._esp[player] then return end
    if not player.Character then return end

    local hl = Instance.new("Highlight")
    hl.Adornee = player.Character
    hl.FillColor = ESP_COLOR
    hl.OutlineColor = ESP_COLOR
    hl.FillTransparency = FILL_TRANSPARENCY
    hl.OutlineTransparency = OUTLINE_TRANSPARENCY
    hl.DepthMode = DEPTH_MODE
    hl.Parent = player.Character

    module._esp[player] = hl

    -- Перепривязка при респавне
    local conn = player.CharacterAdded:Connect(function(char)
        hl.Adornee = char
        hl.Parent = char
    end)
    module._connections[player] = conn
end

-- Удаление ESP
local function removeESP(player)
    if module._esp[player] then
        module._esp[player]:Destroy()
        module._esp[player] = nil
    end
    if module._connections[player] then
        module._connections[player]:Disconnect()
        module._connections[player] = nil
    end
end

-- Сброс всех ESP
function module:ResetAll()
    for player, _ in pairs(module._esp) do
        removeESP(player)
    end
end

-- Инициализация
function module:Init()
    print("[ESP] Init")
end

-- Включение
function module:OnEnable()
    print("[ESP] Enabled")
    self.Enabled = true

    for _, player in ipairs(Players:GetPlayers()) do
        createESP(player)
    end

    module._connections["PlayerAdded"] = Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            createESP(player)
        end)
    end)

    module._connections["PlayerRemoving"] = Players.PlayerRemoving:Connect(function(player)
        removeESP(player)
    end)
end

-- Выключение
function module:OnDisable()
    print("[ESP] Disabled")
    self.Enabled = false
    self:ResetAll()

    if module._connections["PlayerAdded"] then
        module._connections["PlayerAdded"]:Disconnect()
        module._connections["PlayerAdded"] = nil
    end
    if module._connections["PlayerRemoving"] then
        module._connections["PlayerRemoving"]:Disconnect()
        module._connections["PlayerRemoving"] = nil
    end
end

-- Не используется
function module:OnTick(dt)
end

return module
