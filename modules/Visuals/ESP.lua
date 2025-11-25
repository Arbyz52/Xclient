local module = {
    Name     = "ESP",
    Category = "Visuals",
    Enabled  = false,
}

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui    = game:GetService("CoreGui")
local Workspace  = game:GetService("Workspace")

local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Настройки ESP
local Settings = {
    BoxColor      = Color3.fromRGB(255, 0, 0),
    NameColor     = Color3.fromRGB(255, 255, 255),
    HealthBarColor= Color3.fromRGB(0, 255, 0),
    MaxDistance   = 1000,
    TeamCheck     = true,
    ShowBox       = true,
    ShowName      = true,
    ShowHealth    = true,
    ShowDistance  = true
}

module._gui        = nil
module._espObjects = {}
module._connections = {}

-- NEW: helper для логирования ошибок
local function safeCall(tag, fn, ...)
    local ok, res = pcall(fn, ...)
    if not ok then
        warn(string.format("[Xclient][ESP] ERROR in %s: %s", tag, tostring(res)))
    end
    return ok, res
end

function module:Init()
    print("[Xclient][ESP] Init()")
end

-- Создание ESP элементов для игрока
function module:CreateESP(player)
    if player == LocalPlayer then return end

    -- на всякий случай, если уже есть
    if self._espObjects[player] then
        return
    end

    local espHolder = Instance.new("Folder")
    espHolder.Name = player.Name .. "_ESP"

    -- Бокс вокруг игрока
    local box = Instance.new("Frame")
    box.Name = "Box"
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0

    local boxOutline = Instance.new("UIStroke")
    boxOutline.Color = Settings.BoxColor
    boxOutline.Thickness = 2
    boxOutline.Parent = box

    -- Имя игрока
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Settings.NameColor
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextSize = 14
    nameLabel.Size = UDim2.new(0, 100, 0, 20)

    -- Дистанция
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Name = "Distance"
    distanceLabel.TextColor3 = Settings.NameColor
    distanceLabel.TextStrokeTransparency = 0
    distanceLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Font = Enum.Font.SourceSans
    distanceLabel.TextSize = 12
    distanceLabel.Size = UDim2.new(0, 100, 0, 20)

    -- Полоска здоровья
    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.BackgroundColor3 = Color3.new(0, 0, 0)
    healthBar.BorderSizePixel = 0
    healthBar.Size = UDim2.new(0, 4, 1, 0)

    local healthFill = Instance.new("Frame")
    healthFill.Name = "Fill"
    healthFill.BackgroundColor3 = Settings.HealthBarColor
    healthFill.BorderSizePixel = 0
    healthFill.Parent = healthBar

    -- Добавляем все элементы
    box.Parent         = self._gui
    nameLabel.Parent   = self._gui
    distanceLabel.Parent = self._gui
    healthBar.Parent   = self._gui

    self._espObjects[player] = {
        Box        = box,
        Name       = nameLabel,
        Distance   = distanceLabel,
        HealthBar  = healthBar,
        HealthFill = healthFill
    }

    print("[Xclient][ESP] CreateESP for", player.Name)
end

-- Удаление ESP элементов игрока
function module:RemoveESP(player)
    local esp = self._espObjects[player]
    if esp then
        for _, obj in pairs(esp) do
            if typeof(obj) == "Instance" and obj.Parent then
                obj:Destroy()
            end
        end
        self._espObjects[player] = nil
        print("[Xclient][ESP] RemoveESP for", player.Name)
    end
end

-- Обновление ESP для конкретного игрока
function module:UpdatePlayerESP(player)
    local esp = self._espObjects[player]
    if not esp then return end

    -- обновляем камеру, если её не было
    if not Workspace.CurrentCamera then
        for _, obj in pairs(esp) do
            if obj.Visible ~= nil then
                obj.Visible = false
            end
        end
        return
    end
    Camera = Workspace.CurrentCamera

    local character = player.Character
    if not character then
        for _, obj in pairs(esp) do
            if obj.Visible ~= nil then
                obj.Visible = false
            end
        end
        return
    end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid          = character:FindFirstChild("Humanoid")

    if not humanoidRootPart or not humanoid then
        for _, obj in pairs(esp) do
            if obj.Visible ~= nil then
                obj.Visible = false
            end
        end
        return
    end

    -- Проверка команды (аккуратнее, чтобы не скрывать всех)
    if Settings.TeamCheck
       and player.Team ~= nil
       and LocalPlayer.Team ~= nil
       and player.Team == LocalPlayer.Team then
        for _, obj in pairs(esp) do
            if obj.Visible ~= nil then
                obj.Visible = false
            end
        end
        return
    end

    -- Расчет расстояния
    local distance = (humanoidRootPart.Position - Camera.CFrame.Position).Magnitude

    if distance > Settings.MaxDistance then
        for _, obj in pairs(esp) do
            if obj.Visible ~= nil then
                obj.Visible = false
            end
        end
        return
    end

    -- Позиция на экране
    local screenPos, onScreen = Camera:WorldToViewportPoint(humanoidRootPart.Position)

    if not onScreen then
        for _, obj in pairs(esp) do
            if obj.Visible ~= nil then
                obj.Visible = false
            end
        end
        return
    end

    -- Размер бокса
    local head = character:FindFirstChild("Head")
    local rootPos = Camera:WorldToViewportPoint(humanoidRootPart.Position)
    local headPos = head and Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0)) or rootPos
    local legPos  = Camera:WorldToViewportPoint(humanoidRootPart.Position - Vector3.new(0, 3, 0))

    local boxHeight = math.abs(headPos.Y - legPos.Y)
    local boxWidth  = boxHeight * 0.5

    -- Бокс
    esp.Box.Size     = UDim2.new(0, boxWidth, 0, boxHeight)
    esp.Box.Position = UDim2.new(0, screenPos.X - boxWidth / 2, 0, headPos.Y)
    esp.Box.Visible  = Settings.ShowBox

    -- Имя
    esp.Name.Position = UDim2.new(0, screenPos.X - 50, 0, headPos.Y - 25)
    esp.Name.Visible  = Settings.ShowName

    -- Дистанция
    esp.Distance.Text     = string.format("%dm", math.floor(distance))
    esp.Distance.Position = UDim2.new(0, screenPos.X - 50, 0, legPos.Y + 5)
    esp.Distance.Visible  = Settings.ShowDistance

    -- ХП‑бар
    local healthPercent = humanoid.MaxHealth > 0 and (humanoid.Health / humanoid.MaxHealth) or 0
    healthPercent = math.clamp(healthPercent, 0, 1)

    esp.HealthBar.Position = UDim2.new(0, screenPos.X - boxWidth / 2 - 8, 0, headPos.Y)
    esp.HealthBar.Size     = UDim2.new(0, 4, 0, boxHeight)
    esp.HealthFill.Size    = UDim2.new(1, 0, healthPercent, 0)
    esp.HealthFill.Position= UDim2.new(0, 0, 1 - healthPercent, 0)

    if healthPercent > 0.66 then
        esp.HealthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    elseif healthPercent > 0.33 then
        esp.HealthFill.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
    else
        esp.HealthFill.BackgroundColor3 = Color3.fromRGB(255,   0, 0)
    end

    esp.HealthBar.Visible = Settings.ShowHealth
end

function module:OnEnable()
    print("[Xclient][ESP] Включен")

    if self._gui then
        self._gui.Enabled = true
    else
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "Xclient_ESP"
        screenGui.ResetOnSpawn = false
        screenGui.IgnoreGuiInset = true

        local parent = CoreGui
        pcall(function()
            if gethui then parent = gethui() end
        end)
        screenGui.Parent = parent

        self._gui = screenGui
    end

    -- ESP для уже существующих игроков
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            safeCall("CreateESP(" .. player.Name .. ")", function()
                self:CreateESP(player)
            end)
        end
    end

    -- события
    self._connections.playerAdded = Players.PlayerAdded:Connect(function(player)
        safeCall("PlayerAdded/CreateESP(" .. player.Name .. ")", function()
            self:CreateESP(player)
        end)
    end)

    self._connections.playerRemoving = Players.PlayerRemoving:Connect(function(player)
        safeCall("PlayerRemoving/RemoveESP(" .. player.Name .. ")", function()
            self:RemoveESP(player)
        end)
    end)

    self._connections.renderStepped = RunService.RenderStepped:Connect(function()
        for player, _ in pairs(self._espObjects) do
            safeCall("UpdatePlayerESP(" .. player.Name .. ")", function()
                self:UpdatePlayerESP(player)
            end)
        end
    end)
end

function module:OnDisable()
    print("[Xclient][ESP] Выключен")

    if self._gui then
        self._gui.Enabled = false
    end

    for _, connection in pairs(self._connections) do
        if connection then
            connection:Disconnect()
        end
    end
    self._connections = {}

    for player, _ in pairs(self._espObjects) do
        self:RemoveESP(player)
    end
end

function module:OnTick(dt)
    -- не нужен, обновление идёт через RenderStepped
end

return module
