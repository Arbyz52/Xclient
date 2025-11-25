local module = {
    Name     = "ESP",
    Category = "Visuals",
    Enabled  = false,
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Настройки ESP
module.Settings = {
    ShowBox = true,
    ShowName = true,
    ShowDistance = true,
    ShowHealth = true,
    ShowTracers = false,
    TeamCheck = false,
    MaxDistance = 1000,
    BoxColor = Color3.fromRGB(255, 255, 255),
    TeamColor = true,
}

module._gui = nil
module._espObjects = {}

function module:Init()
    print("[Xclient][ESP] Init()")
end

function module:CreateESP(player)
    if player == LocalPlayer then return end
    
    -- Контейнер для бокса
    local boxFrame = Instance.new("Frame")
    boxFrame.Name = "BoxFrame_" .. player.Name
    boxFrame.BackgroundTransparency = 1
    boxFrame.Size = UDim2.new(0, 100, 0, 100)
    boxFrame.Position = UDim2.new(0, 0, 0, 0)
    boxFrame.Parent = self._gui
    
    -- Создание линий бокса
    local function createLine(name, position, size)
        local line = Instance.new("Frame")
        line.Name = name
        line.Size = size
        line.Position = position
        line.BorderSizePixel = 0
        line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        line.Parent = boxFrame
        return line
    end
    
    -- 4 линии (верх, низ, лево, право)
    local topLine = createLine("Top", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 2))
    local bottomLine = createLine("Bottom", UDim2.new(0, 0, 1, -2), UDim2.new(1, 0, 0, 2))
    local leftLine = createLine("Left", UDim2.new(0, 0, 0, 0), UDim2.new(0, 2, 1, 0))
    local rightLine = createLine("Right", UDim2.new(1, -2, 0, 0), UDim2.new(0, 2, 1, 0))
    
    -- Имя игрока
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.Position = UDim2.new(0, 0, 0, -22)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 14
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Parent = boxFrame
    
    -- Расстояние
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Name = "DistanceLabel"
    distanceLabel.Size = UDim2.new(1, 0, 0, 18)
    distanceLabel.Position = UDim2.new(0, 0, 1, 2)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Font = Enum.Font.Gotham
    distanceLabel.Text = "0m"
    distanceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    distanceLabel.TextSize = 12
    distanceLabel.TextStrokeTransparency = 0.5
    distanceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    distanceLabel.Parent = boxFrame
    
    -- Здоровье бар
    local healthBarBg = Instance.new("Frame")
    healthBarBg.Name = "HealthBarBg"
    healthBarBg.Size = UDim2.new(0, 3, 1, 0)
    healthBarBg.Position = UDim2.new(0, -6, 0, 0)
    healthBarBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    healthBarBg.BorderSizePixel = 1
    healthBarBg.BorderColor3 = Color3.fromRGB(255, 255, 255)
    healthBarBg.Parent = boxFrame
    
    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.Position = UDim2.new(0, 0, 0, 0)
    healthBar.AnchorPoint = Vector2.new(0, 1)
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthBar.BorderSizePixel = 0
    healthBar.Parent = healthBarBg
    
    -- Трейсер
    local tracer = Instance.new("Frame")
    tracer.Name = "Tracer_" .. player.Name
    tracer.Size = UDim2.new(0, 2, 0, 100)
    tracer.AnchorPoint = Vector2.new(0.5, 0)
    tracer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    tracer.BorderSizePixel = 0
    tracer.Visible = false
    tracer.Parent = self._gui
    
    self._espObjects[player] = {
        player = player,
        boxFrame = boxFrame,
        nameLabel = nameLabel,
        distanceLabel = distanceLabel,
        healthBar = healthBar,
        healthBarBg = healthBarBg,
        tracer = tracer,
        lines = {topLine, bottomLine, leftLine, rightLine},
    }
end

function module:RemoveESP(player)
    local espObj = self._espObjects[player]
    if espObj then
        if espObj.boxFrame then espObj.boxFrame:Destroy() end
        if espObj.tracer then espObj.tracer:Destroy() end
        self._espObjects[player] = nil
    end
end

function module:UpdateESP(espObj)
    local player = espObj.player
    local character = player.Character
    
    if not character then
        espObj.boxFrame.Visible = false
        espObj.tracer.Visible = false
        return
    end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    
    if not rootPart or not humanoid or humanoid.Health <= 0 then
        espObj.boxFrame.Visible = false
        espObj.tracer.Visible = false
        return
    end
    
    -- Проверка команды
    if self.Settings.TeamCheck and player.Team == LocalPlayer.Team then
        espObj.boxFrame.Visible = false
        espObj.tracer.Visible = false
        return
    end
    
    -- Проверка расстояния
    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot then return end
    
    local distance = (localRoot.Position - rootPart.Position).Magnitude
    if distance > self.Settings.MaxDistance then
        espObj.boxFrame.Visible = false
        espObj.tracer.Visible = false
        return
    end
    
    -- Конвертация 3D в 2D
    local vector, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
    
    if not onScreen then
        espObj.boxFrame.Visible = false
        espObj.tracer.Visible = false
        return
    end
    
    -- Вычисление размера бокса
    local head = character:FindFirstChild("Head")
    if not head then return end
    
    local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
    local legPos = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))
    
    local height = math.abs(headPos.Y - legPos.Y)
    local width = height / 2
    
    -- Обновление бокса
    espObj.boxFrame.Position = UDim2.new(0, vector.X - width/2, 0, headPos.Y)
    espObj.boxFrame.Size = UDim2.new(0, width, 0, height)
    espObj.boxFrame.Visible = self.Settings.ShowBox
    
    -- Цвет
    local color = self.Settings.BoxColor
    if self.Settings.TeamColor and player.Team then
        color = player.Team.TeamColor.Color
    end
    
    for _, line in pairs(espObj.lines) do
        line.BackgroundColor3 = color
    end
    
    -- Имя
    espObj.nameLabel.Visible = self.Settings.ShowName
    espObj.nameLabel.TextColor3 = color
    
    -- Расстояние
    if self.Settings.ShowDistance then
        espObj.distanceLabel.Visible = true
        espObj.distanceLabel.Text = string.format("%dm", math.floor(distance))
    else
        espObj.distanceLabel.Visible = false
    end
    
    -- Здоровье
    if self.Settings.ShowHealth then
        local healthPercent = humanoid.Health / humanoid.MaxHealth
        espObj.healthBar.Size = UDim2.new(1, 0, healthPercent, 0)
        espObj.healthBar.Position = UDim2.new(0, 0, 1, 0)
        
        local r = math.floor((1 - healthPercent) * 255)
        local g = math.floor(healthPercent * 255)
        espObj.healthBar.BackgroundColor3 = Color3.fromRGB(r, g, 0)
        espObj.healthBarBg.Visible = true
    else
        espObj.healthBarBg.Visible = false
    end
    
    -- Трейсер
    if self.Settings.ShowTracers then
        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        local playerPos = Vector2.new(vector.X, vector.Y)
        
        local distance2D = (playerPos - screenCenter).Magnitude
        local angle = math.atan2(playerPos.Y - screenCenter.Y, playerPos.X - screenCenter.X)
        
        espObj.tracer.Position = UDim2.new(0, screenCenter.X, 0, screenCenter.Y)
        espObj.tracer.Size = UDim2.new(0, 2, 0, distance2D)
        espObj.tracer.Rotation = math.deg(angle) + 90
        espObj.tracer.BackgroundColor3 = color
        espObj.tracer.Visible = true
    else
        espObj.tracer.Visible = false
    end
end

function module:OnEnable()
    print("[Xclient][ESP] Включен")

    if self._gui then
        self._gui.Enabled = true
        for _, player in pairs(Players:GetPlayers()) do
            if not self._espObjects[player] then
                self:CreateESP(player)
            end
        end
        return
    end

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
    
    -- Создаем ESP для всех игроков
    for _, player in pairs(Players:GetPlayers()) do
        self:CreateESP(player)
    end
    
    -- События
    Players.PlayerAdded:Connect(function(player)
        if self.Enabled then
            task.wait(0.5)
            self:CreateESP(player)
        end
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:RemoveESP(player)
    end)
end

function module:OnDisable()
    print("[Xclient][ESP] Выключен")
    if self._gui then
        self._gui.Enabled = false
    end
end

function module:OnTick(dt)
    if not self.Enabled then return end
    if not self._gui then return end
    
    for player, espObj in pairs(self._espObjects) do
        if player and player.Parent then
            self:UpdateESP(espObj)
        else
            self:RemoveESP(player)
        end
    end
end

return module
