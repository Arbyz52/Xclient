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
    BoxColor       = Color3.fromRGB(255, 0, 0),
    NameColor      = Color3.fromRGB(255, 255, 255),
    HealthBarColor = Color3.fromRGB(0, 255, 0),
    MaxDistance    = 1000,
    TeamCheck      = true,
    ShowBox        = true,
    ShowName       = true,
    ShowHealth     = true,
    ShowDistance   = true
}

module._gui         = nil
module._espObjects  = {}
module._connections = {}

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

-- Скрыть все ESP элементы игрока
local function hideESP(esp)
    if not esp then return end
    if esp.Box then esp.Box.Visible = false end
    if esp.Name then esp.Name.Visible = false end
    if esp.Distance then esp.Distance.Visible = false end
    if esp.HealthBar then esp.HealthBar.Visible = false end
end

-- Создание ESP элементов для игрока
function module:CreateESP(player)
    if player == LocalPlayer then return end
    if self._espObjects[player] then return end

    -- Бокс
    local box = Instance.new("Frame")
    box.Name = player.Name .. "_Box"
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false
    box.Parent = self._gui

    local boxOutline = Instance.new("UIStroke")
    boxOutline.Color = Settings.BoxColor
    boxOutline.Thickness = 2
    boxOutline.Parent = box

    -- Имя игрока
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = player.Name .. "_Name"
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Settings.NameColor
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextSize = 14
    nameLabel.Size = UDim2.new(0, 100, 0, 20)
    nameLabel.Visible = false
    nameLabel.Parent = self._gui

    -- Дистанция
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Name = player.Name .. "_Distance"
    distanceLabel.TextColor3 = Settings.NameColor
    distanceLabel.TextStrokeTransparency = 0
    distanceLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Font = Enum.Font.SourceSans
    distanceLabel.TextSize = 12
    distanceLabel.Size = UDim2.new(0, 100, 0, 20)
    distanceLabel.Visible = false
    distanceLabel.Parent = self._gui

    -- Полоска здоровья (фон)
    local healthBar = Instance.new("Frame")
    healthBar.Name = player.Name .. "_HealthBar"
    healthBar.BackgroundColor3 = Color3.new(0, 0, 0)
    healthBar.BorderSizePixel = 1
    healthBar.BorderColor3 = Color3.new(0, 0, 0)
    healthBar.Visible = false
    healthBar.Parent = self._gui

    -- Заполнение здоровья
    local healthFill = Instance.new("Frame")
    healthFill.Name = "Fill"
    healthFill.BackgroundColor3 = Settings.HealthBarColor
    healthFill.BorderSizePixel = 0
    healthFill.Size = UDim2.new(1, 0, 1, 0)
    healthFill.Position = UDim2.new(0, 0, 0, 0)
    healthFill.Parent = healthBar

    self._espObjects[player] = {
        Box        = box,
        BoxStroke  = boxOutline,
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

    -- Проверка камеры
    Camera = Workspace.CurrentCamera
    if not Camera then
        hideESP(esp)
        return
    end

    -- Проверка персонажа
    local character = player.Character
    if not character then
        hideESP(esp)
        return
    end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local head = character:FindFirstChild("Head")

    if not humanoidRootPart or not humanoid or humanoid.Health <= 0 then
        hideESP(esp)
        return
    end

    -- Проверка команды
    if Settings.TeamCheck 
       and player.Team ~= nil 
       and LocalPlayer.Team ~= nil 
       and player.Team == LocalPlayer.Team then
        hideESP(esp)
        return
    end

    -- Расчет расстояния
    local distance = (humanoidRootPart.Position - Camera.CFrame.Position).Magnitude

    if distance > Settings.MaxDistance then
        hideESP(esp)
        return
    end

    -- Позиция на экране
    local rootScreenPos, onScreen = Camera:WorldToViewportPoint(humanoidRootPart.Position)

    if not onScreen or rootScreenPos.Z <= 0 then
        hideESP(esp)
        return
    end

    -- Расчёт размеров бокса
    local topPos = Camera:WorldToViewportPoint(humanoidRootPart.Position + Vector3.new(0, 3, 0))
    local bottomPos = Camera:WorldToViewportPoint(humanoidRootPart.Position - Vector3.new(0, 3, 0))

    local boxHeight = math.abs(topPos.Y - bottomPos.Y)
    local boxWidth = boxHeight * 0.6

    local boxX = rootScreenPos.X - boxWidth / 2
    local boxY = topPos.Y

    -- Обновление бокса
    if Settings.ShowBox then
        esp.Box.Size = UDim2.new(0, boxWidth, 0, boxHeight)
        esp.Box.Position = UDim2.new(0, boxX, 0, boxY)
        esp.Box.Visible = true
    else
        esp.Box.Visible = false
    end

    -- Обновление имени
    if Settings.ShowName then
        esp.Name.Position = UDim2.new(0, rootScreenPos.X - 50, 0, boxY - 18)
        esp.Name.Visible = true
    else
        esp.Name.Visible = false
    end

    -- Обновление дистанции
    if Settings.ShowDistance then
        esp.Distance.Text = string.format("[%dm]", math.floor(distance))
        esp.Distance.Position = UDim2.new(0, rootScreenPos.X - 50, 0, boxY + boxHeight + 2)
        esp.Distance.Visible = true
    else
        esp.Distance.Visible = false
    end

    -- Обновление ХП-бара
    if Settings.ShowHealth then
        local healthPercent = humanoid.MaxHealth > 0 and (humanoid.Health / humanoid.MaxHealth) or 0
        healthPercent = math.clamp(healthPercent, 0, 1)

        esp.HealthBar.Size = UDim2.new(0, 4, 0, boxHeight)
        esp.HealthBar.Position = UDim2.new(0, boxX - 6, 0, boxY)
        esp.HealthBar.Visible = true

        esp.HealthFill.Size = UDim2.new(1, 0, healthPercent, 0)
        esp.HealthFill.Position = UDim2.new(0, 0, 1 - healthPercent, 0)

        -- Цвет в зависимости от здоровья
        if healthPercent > 0.66 then
            esp.HealthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        elseif healthPercent > 0.33 then
            esp.HealthFill.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
        else
            esp.HealthFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        end
    else
        esp.HealthBar.Visible = false
    end
end

function module:OnEnable()
    print("[Xclient][ESP] Включен")

    -- Создание GUI
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
        
        local success = pcall(function()
            screenGui.Parent = parent
        end)
        
        if not success then
            screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        end

        self._gui = screenGui
    end

    -- ESP для существующих игроков
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            safeCall("CreateESP(" .. player.Name .. ")", function()
                self:CreateESP(player)
            end)
        end
    end

    -- Подключение событий
    self._connections.playerAdded = Players.PlayerAdded:Connect(function(player)
        safeCall("PlayerAdded", function()
            self:CreateESP(player)
        end)
    end)

    self._connections.playerRemoving = Players.PlayerRemoving:Connect(function(player)
        safeCall("PlayerRemoving", function()
            self:RemoveESP(player)
        end)
    end)

    self._connections.renderStepped = RunService.RenderStepped:Connect(function()
        if not self.Enabled then return end
        for player, _ in pairs(self._espObjects) do
            if player and player.Parent then
                safeCall("UpdateESP", function()
                    self:UpdatePlayerESP(player)
                end)
            else
                -- Игрок ушёл, удаляем ESP
                self:RemoveESP(player)
            end
        end
    end)
end

function module:OnDisable()
    print("[Xclient][ESP] Выключен")

    -- Отключаем все соединения
    for _, connection in pairs(self._connections) do
        if connection then
            connection:Disconnect()
        end
    end
    self._connections = {}

    -- Скрываем/удаляем ESP
    for player, esp in pairs(self._espObjects) do
        hideESP(esp)
    end

    if self._gui then
        self._gui.Enabled = false
    end
end

function module:OnTick(dt)
    -- Не используется, обновление через RenderStepped
end

return module
