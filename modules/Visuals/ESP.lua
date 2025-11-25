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

module._gui = nil
module._espObjects = {}

function module:Init()
    print("[Xclient][ESP] Init()")
    
    -- События игроков
    Players.PlayerAdded:Connect(function(player)
        if self.Enabled and self._gui then
            task.wait(1)
            self:CreateESPForPlayer(player)
        end
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:RemoveESPForPlayer(player)
    end)
end

function module:CreateESPForPlayer(player)
    if player == LocalPlayer then return end
    if self._espObjects[player] then return end
    
    -- Контейнер для ESP элементов
    local container = Instance.new("Frame")
    container.Name = "ESP_" .. player.Name
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(0, 100, 0, 100)
    container.Position = UDim2.new(0, 0, 0, 0)
    container.Visible = false
    container.Parent = self._gui
    
    -- Функция создания линии бокса
    local function makeLine()
        local line = Instance.new("Frame")
        line.BorderSizePixel = 0
        line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        line.Parent = container
        return line
    end
    
    -- 4 линии бокса
    local topLine = makeLine()
    topLine.Name = "Top"
    
    local bottomLine = makeLine()
    bottomLine.Name = "Bottom"
    
    local leftLine = makeLine()
    leftLine.Name = "Left"
    
    local rightLine = makeLine()
    rightLine.Name = "Right"
    
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
    nameLabel.Parent = container
    
    -- Дистанция
    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "DistLabel"
    distLabel.Size = UDim2.new(1, 0, 0, 18)
    distLabel.Position = UDim2.new(0, 0, 1, 2)
    distLabel.BackgroundTransparency = 1
    distLabel.Font = Enum.Font.Gotham
    distLabel.Text = "0m"
    distLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    distLabel.TextSize = 12
    distLabel.TextStrokeTransparency = 0.5
    distLabel.Parent = container
    
    -- Здоровье фон
    local healthBg = Instance.new("Frame")
    healthBg.Name = "HealthBg"
    healthBg.Size = UDim2.new(0, 3, 1, 0)
    healthBg.Position = UDim2.new(0, -6, 0, 0)
    healthBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    healthBg.BorderSizePixel = 1
    healthBg.BorderColor3 = Color3.fromRGB(255, 255, 255)
    healthBg.Parent = container
    
    -- Здоровье бар
    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.Position = UDim2.new(0, 0, 1, 0)
    healthBar.AnchorPoint = Vector2.new(0, 1)
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthBar.BorderSizePixel = 0
    healthBar.Parent = healthBg
    
    -- Сохраняем ссылки
    self._espObjects[player] = {
        container = container,
        topLine = topLine,
        bottomLine = bottomLine,
        leftLine = leftLine,
        rightLine = rightLine,
        nameLabel = nameLabel,
        distLabel = distLabel,
        healthBar = healthBar,
        healthBg = healthBg,
    }
end

function module:RemoveESPForPlayer(player)
    local esp = self._espObjects[player]
    if esp and esp.container then
        esp.container:Destroy()
    end
    self._espObjects[player] = nil
end

function module:UpdateESPForPlayer(player, esp)
    local camera = Workspace.CurrentCamera
    if not camera then
        esp.container.Visible = false
        return
    end
    
    local character = player.Character
    if not character then
        esp.container.Visible = false
        return
    end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    local head = character:FindFirstChild("Head")
    
    if not rootPart or not humanoid or not head then
        esp.container.Visible = false
        return
    end
    
    if humanoid.Health <= 0 then
        esp.container.Visible = false
        return
    end
    
    -- Позиции
    local rootPos = rootPart.Position
    local headPos = head.Position + Vector3.new(0, 0.5, 0)
    local legPos = rootPart.Position - Vector3.new(0, 3, 0)
    
    -- Конвертация в экранные координаты
    local headPoint, headOnScreen = camera:WorldToViewportPoint(headPos)
    local legPoint, legOnScreen = camera:WorldToViewportPoint(legPos)
    
    if not headOnScreen or headPoint.Z < 0 then
        esp.container.Visible = false
        return
    end
    
    -- Размеры бокса
    local height = math.abs(headPoint.Y - legPoint.Y)
    local width = height * 0.5
    
    local x = headPoint.X - width / 2
    local y = headPoint.Y
    
    -- Обновляем позицию и размер контейнера
    esp.container.Position = UDim2.new(0, x, 0, y)
    esp.container.Size = UDim2.new(0, width, 0, height)
    esp.container.Visible = true
    
    -- Обновляем линии бокса
    esp.topLine.Size = UDim2.new(1, 0, 0, 2)
    esp.topLine.Position = UDim2.new(0, 0, 0, 0)
    
    esp.bottomLine.Size = UDim2.new(1, 0, 0, 2)
    esp.bottomLine.Position = UDim2.new(0, 0, 1, -2)
    
    esp.leftLine.Size = UDim2.new(0, 2, 1, 0)
    esp.leftLine.Position = UDim2.new(0, 0, 0, 0)
    
    esp.rightLine.Size = UDim2.new(0, 2, 1, 0)
    esp.rightLine.Position = UDim2.new(1, -2, 0, 0)
    
    -- Цвет по команде
    local color = Color3.fromRGB(255, 0, 0)
    if player.Team and player.Team.TeamColor then
        color = player.Team.TeamColor.Color
    end
    
    esp.topLine.BackgroundColor3 = color
    esp.bottomLine.BackgroundColor3 = color
    esp.leftLine.BackgroundColor3 = color
    esp.rightLine.BackgroundColor3 = color
    esp.nameLabel.TextColor3 = color
    esp.healthBg.BorderColor3 = color
    
    -- Обновляем здоровье
    local healthPercent = humanoid.Health / humanoid.MaxHealth
    esp.healthBar.Size = UDim2.new(1, 0, healthPercent, 0)
    
    local r = math.floor((1 - healthPercent) * 255)
    local g = math.floor(healthPercent * 255)
    esp.healthBar.BackgroundColor3 = Color3.fromRGB(r, g, 0)
    
    -- Обновляем дистанцию
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local distance = (LocalPlayer.Character.HumanoidRootPart.Position - rootPos).Magnitude
        esp.distLabel.Text = string.format("%dm", math.floor(distance))
    end
end

function module:OnEnable()
    print("[Xclient][ESP] Включен")

    if self._gui then
        self._gui.Enabled = true
        -- Пересоздаем ESP для всех игроков
        for _, player in pairs(Players:GetPlayers()) do
            if not self._espObjects[player] then
                self:CreateESPForPlayer(player)
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
    
    -- Создаем ESP для всех текущих игроков
    for _, player in pairs(Players:GetPlayers()) do
        self:CreateESPForPlayer(player)
    end
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
    
    -- Обновляем ESP для каждого игрока
    for player, esp in pairs(self._espObjects) do
        if player and player.Parent then
            local success = pcall(function()
                self:UpdateESPForPlayer(player, esp)
            end)
            if not success then
                esp.container.Visible = false
            end
        else
            self:RemoveESPForPlayer(player)
        end
    end
end

return module
