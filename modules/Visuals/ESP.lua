local module = {
    Name     = "ESP",
    Category = "Visuals",
    Enabled  = false,
    _esp = {},
    _connections = {},
}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- Удалить стандартный HP‑бар
local function disableDefaultHealthBar(humanoid)
    if humanoid then
        humanoid.HealthDisplayDistance = 0
        humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
    end
end

-- Удалить ESP для игрока
local function removeESP(player)
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

-- Создать ESP для игрока
local function createESP(player)
    if player == LocalPlayer then return end
    if module._esp[player] then return end

    local char = player.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    disableDefaultHealthBar(hum)

    -- Highlight
    local hl = Instance.new("Highlight")
    hl.Adornee = char
    hl.FillTransparency = 0.5
    hl.OutlineColor = Color3.fromRGB(255, 0, 0)
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = char

    -- BillboardGui сбоку слева
    local gui = Instance.new("BillboardGui")
    gui.Name = "HPBar"
    gui.Adornee = hrp
    gui.Size = UDim2.new(0.3, 0, 3, 0)
    gui.StudsOffset = Vector3.new(-2.5, 0, 0)
    gui.AlwaysOnTop = true
    gui.Parent = char

    -- Фон
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    bg.BackgroundTransparency = 0.4
    bg.BorderSizePixel = 0
    bg.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = bg

    -- HP‑полоса
    local bar = Instance.new("Frame")
    bar.Name = "HP"
    bar.Size = UDim2.new(1, 0, 1, 0)
    bar.Position = UDim2.new(0, 0, 0, 0)
    bar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    bar.BorderSizePixel = 0
    bar.ZIndex = 2
    bar.Parent = bg

    local corner2 = Instance.new("UICorner")
    corner2.CornerRadius = UDim.new(0, 4)
    corner2.Parent = bar

    module._esp[player] = {
        highlight = hl,
        hpGui = gui,
        hpBar = bar,
        humanoid = hum,
    }

    -- Перепривязка при респавне
    module._connections[player] = player.CharacterAdded:Connect(function(newChar)
        removeESP(player)
        createESP(player)
    end)
end

-- Обновление HP‑баров
local function updateBars()
    for _, data in pairs(module._esp) do
        local hum = data.humanoid
        local bar = data.hpBar
        if hum and bar then
            local ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            bar.Size = UDim2.new(1, 0, ratio, 0)
            if ratio > 0.6 then
                bar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            elseif ratio > 0.3 then
                bar.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
            else
                bar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            end
        end
    end
end

-- Включение
function module:OnEnable()
    self.Enabled = true

    for _, player in ipairs(Players:GetPlayers()) do
        createESP(player)
    end

    module._connections["PlayerAdded"] = Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            createESP(player)
        end)
        if player.Character then
            createESP(player)
        end
    end)

    module._connections["PlayerRemoving"] = Players.PlayerRemoving:Connect(function(player)
        removeESP(player)
    end)

    module._connections["Render"] = RunService.RenderStepped:Connect(updateBars)
end

-- Выключение
function module:OnDisable()
    self.Enabled = false

    for _, data in pairs(module._esp) do
        if data.highlight then data.highlight:Destroy() end
        if data.hpGui then data.hpGui:Destroy() end
    end
    module._esp = {}

    for _, conn in pairs(module._connections) do
        if conn then conn:Disconnect() end
    end
    module._connections = {}
end

-- Инициализация
function module:Init()
    print("[ESP] Init")
end

function module:OnTick(dt)
end

return module
