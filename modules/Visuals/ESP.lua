local module = {
    Name     = "ESP",
    Category = "Visuals",
    Enabled  = false,
}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

module._esp = {}          -- [player] = {highlight = ..., hpGui = ..., hpBar = ..., humanoid = ...}
module._connections = {}  -- [player] = connection

-- Создание ESP для игрока
local function createESP(player)
    if player == LocalPlayer then return end
    if module._esp[player] then return end
    if not player.Character then return end

    local char = player.Character
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    -- Highlight
    local hl = Instance.new("Highlight")
    hl.Adornee = char
    hl.FillTransparency = 0.5
    hl.OutlineColor = Color3.fromRGB(255, 0, 0)
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = char

    -- BillboardGui для HP
    local gui = Instance.new("BillboardGui")
    gui.Name = "HPBar"
    gui.Adornee = hrp
    gui.Size = UDim2.new(4, 0, 0.5, 0)
    gui.StudsOffset = Vector3.new(0, 3, 0)
    gui.AlwaysOnTop = true
    gui.Parent = char

    -- Фон
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    bg.BackgroundTransparency = 0.3
    bg.BorderSizePixel = 0
    bg.Parent = gui

    -- Скругление фона
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = bg

    -- HP-полоса
    local bar = Instance.new("Frame")
    bar.Name = "HP"
    bar.Size = UDim2.new(1, 0, 1, 0)
    bar.Position = UDim2.new(0, 0, 0, 0)
    bar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    bar.BorderSizePixel = 0
    bar.ZIndex = 2
    bar.Parent = bg

    -- Скругление полосы
    local corner2 = Instance.new("UICorner")
    corner2.CornerRadius = UDim.new(0, 6)
    corner2.Parent = bar

    module._esp[player] = {
        highlight = hl,
        hpGui = gui,
        hpBar = bar,
        humanoid = hum
    }

    -- Обновление при респавне
    local conn = player.CharacterAdded:Connect(function()
        removeESP(player)
        createESP(player)
    end)
    module._connections[player] = conn
end

-- Удаление ESP
function removeESP(player)
    local data = module._esp[player]
    if data then
        if data.highlight then data.highlight:Destroy() end
        if data.hpGui then data.hpGui:Destroy() end
        module._esp[player] = nil
    end
    if module._connections[player] then
        module._connections[player]:Disconnect()
        module._connections[player] = nil
    end
end

-- Сброс всех ESP
function module:ResetAll()
    for player in pairs(module._esp) do
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

    module._connections["Render"] = RunService.RenderStepped:Connect(function()
        for _, data in pairs(module._esp) do
            local hum = data.humanoid
            local bar = data.hpBar
            if hum and bar then
                local ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                bar.Size = UDim2.new(ratio, 0, 1, 0)
                bar.BackgroundColor3 = Color3.fromRGB(255 - ratio * 255, ratio * 255, 0)
            end
        end
    end)
end

-- Выключение
function module:OnDisable()
    print("[ESP] Disabled")
    self.Enabled = false
    self:ResetAll()

    for _, conn in pairs(module._connections) do
        if conn then conn:Disconnect() end
    end
    module._connections = {}
end

-- Не используется
function module:OnTick(dt)
end

return module
