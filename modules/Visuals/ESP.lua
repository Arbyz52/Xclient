local module = {
    Name     = "ESP",
    Category = "Visuals",
    Enabled  = false,
}

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Настройки
local Settings = {
    BoxColor       = Color3.fromRGB(255, 0, 0),
    NameColor      = Color3.fromRGB(255, 255, 255),
    HealthBarColor = Color3.fromRGB(0, 255, 0),
    MaxDistance    = 1000,
    TeamCheck      = false,
    ShowBox        = true,
    ShowName       = true,
    ShowHealth     = true,
    ShowDistance   = true
}

module._espObjects  = {}
module._connections = {}

function module:Init()
    print("[ESP] Init")
end

-- Создание ESP через Drawing API
function module:CreateESP(player)
    if player == LocalPlayer then return end
    if self._espObjects[player] then return end
    
    -- Проверяем доступность Drawing API
    if not Drawing then
        warn("[ESP] Drawing API не доступен!")
        return
    end

    local esp = {}
    
    -- Линии бокса (4 стороны)
    esp.BoxTopLine = Drawing.new("Line")
    esp.BoxTopLine.Thickness = 1
    esp.BoxTopLine.Color = Settings.BoxColor
    esp.BoxTopLine.Visible = false
    
    esp.BoxBottomLine = Drawing.new("Line")
    esp.BoxBottomLine.Thickness = 1
    esp.BoxBottomLine.Color = Settings.BoxColor
    esp.BoxBottomLine.Visible = false
    
    esp.BoxLeftLine = Drawing.new("Line")
    esp.BoxLeftLine.Thickness = 1
    esp.BoxLeftLine.Color = Settings.BoxColor
    esp.BoxLeftLine.Visible = false
    
    esp.BoxRightLine = Drawing.new("Line")
    esp.BoxRightLine.Thickness = 1
    esp.BoxRightLine.Color = Settings.BoxColor
    esp.BoxRightLine.Visible = false

    -- Имя
    esp.Name = Drawing.new("Text")
    esp.Name.Size = 14
    esp.Name.Font = 2
    esp.Name.Color = Settings.NameColor
    esp.Name.Outline = true
    esp.Name.OutlineColor = Color3.new(0, 0, 0)
    esp.Name.Center = true
    esp.Name.Visible = false
    esp.Name.Text = player.Name

    -- Дистанция
    esp.Distance = Drawing.new("Text")
    esp.Distance.Size = 12
    esp.Distance.Font = 2
    esp.Distance.Color = Settings.NameColor
    esp.Distance.Outline = true
    esp.Distance.OutlineColor = Color3.new(0, 0, 0)
    esp.Distance.Center = true
    esp.Distance.Visible = false

    -- ХП бар (фон)
    esp.HealthBarBG = Drawing.new("Line")
    esp.HealthBarBG.Thickness = 4
    esp.HealthBarBG.Color = Color3.new(0, 0, 0)
    esp.HealthBarBG.Visible = false

    -- ХП бар (заполнение)
    esp.HealthBar = Drawing.new("Line")
    esp.HealthBar.Thickness = 2
    esp.HealthBar.Color = Settings.HealthBarColor
    esp.HealthBar.Visible = false

    self._espObjects[player] = esp
    print("[ESP] Created for", player.Name)
end

-- Удаление ESP
function module:RemoveESP(player)
    local esp = self._espObjects[player]
    if esp then
        for _, drawing in pairs(esp) do
            if drawing and drawing.Remove then
                pcall(function() drawing:Remove() end)
            end
        end
        self._espObjects[player] = nil
        print("[ESP] Removed for", player.Name)
    end
end

-- Скрыть все элементы ESP
local function hideESP(esp)
    for _, drawing in pairs(esp) do
        if drawing then
            drawing.Visible = false
        end
    end
end

-- Обновление ESP
function module:UpdatePlayerESP(player)
    local esp = self._espObjects[player]
    if not esp then return end

    Camera = Workspace.CurrentCamera
    if not Camera then
        hideESP(esp)
        return
    end

    local character = player.Character
    if not character then
        hideESP(esp)
        return
    end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if not humanoidRootPart or not humanoid or humanoid.Health <= 0 then
        hideESP(esp)
        return
    end

    -- Проверка команды
    if Settings.TeamCheck then
        if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
            hideESP(esp)
            return
        end
    end

    -- Позиция на экране
    local rootPos, onScreen = Camera:WorldToViewportPoint(humanoidRootPart.Position)
    
    if not onScreen or rootPos.Z <= 0 then
        hideESP(esp)
        return
    end

    local distance = (humanoidRootPart.Position - Camera.CFrame.Position).Magnitude
    
    if distance > Settings.MaxDistance then
        hideESP(esp)
        return
    end

    -- Расчёт размеров бокса
    local topWorld = humanoidRootPart.Position + Vector3.new(0, 3, 0)
    local bottomWorld = humanoidRootPart.Position - Vector3.new(0, 3, 0)
    
    local topPos = Camera:WorldToViewportPoint(topWorld)
    local bottomPos = Camera:WorldToViewportPoint(bottomWorld)
    
    local boxHeight = math.abs(topPos.Y - bottomPos.Y)
    local boxWidth = boxHeight * 0.6
    
    local boxX = rootPos.X - boxWidth / 2
    local boxY = topPos.Y

    -- Бокс (4 линии)
    if Settings.ShowBox then
        -- Верхняя линия
        esp.BoxTopLine.From = Vector2.new(boxX, boxY)
        esp.BoxTopLine.To = Vector2.new(boxX + boxWidth, boxY)
        esp.BoxTopLine.Color = Settings.BoxColor
        esp.BoxTopLine.Visible = true
        
        -- Нижняя линия
        esp.BoxBottomLine.From = Vector2.new(boxX, boxY + boxHeight)
        esp.BoxBottomLine.To = Vector2.new(boxX + boxWidth, boxY + boxHeight)
        esp.BoxBottomLine.Color = Settings.BoxColor
        esp.BoxBottomLine.Visible = true
        
        -- Левая линия
        esp.BoxLeftLine.From = Vector2.new(boxX, boxY)
        esp.BoxLeftLine.To = Vector2.new(boxX, boxY + boxHeight)
        esp.BoxLeftLine.Color = Settings.BoxColor
        esp.BoxLeftLine.Visible = true
        
        -- Правая линия
        esp.BoxRightLine.From = Vector2.new(boxX + boxWidth, boxY)
        esp.BoxRightLine.To = Vector2.new(boxX + boxWidth, boxY + boxHeight)
        esp.BoxRightLine.Color = Settings.BoxColor
        esp.BoxRightLine.Visible = true
    else
        esp.BoxTopLine.Visible = false
        esp.BoxBottomLine.Visible = false
        esp.BoxLeftLine.Visible = false
        esp.BoxRightLine.Visible = false
    end

    -- Имя
    if Settings.ShowName then
        esp.Name.Position = Vector2.new(rootPos.X, boxY - 16)
        esp.Name.Text = player.Name
        esp.Name.Visible = true
    else
        esp.Name.Visible = false
    end

    -- Дистанция
    if Settings.ShowDistance then
        esp.Distance.Position = Vector2.new(rootPos.X, boxY + boxHeight + 2)
        esp.Distance.Text = string.format("[%d m]", math.floor(distance))
        esp.Distance.Visible = true
    else
        esp.Distance.Visible = false
    end

    -- ХП бар
    if Settings.ShowHealth then
        local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
        local barX = boxX - 6
        local barHeight = boxHeight * healthPercent
        
        -- Фон
        esp.HealthBarBG.From = Vector2.new(barX, boxY)
        esp.HealthBarBG.To = Vector2.new(barX, boxY + boxHeight)
        esp.HealthBarBG.Visible = true
        
        -- Заполнение (снизу вверх)
        esp.HealthBar.From = Vector2.new(barX, boxY + boxHeight)
        esp.HealthBar.To = Vector2.new(barX, boxY + boxHeight - barHeight)
        
        -- Цвет по здоровью
        if healthPercent > 0.66 then
            esp.HealthBar.Color = Color3.fromRGB(0, 255, 0)
        elseif healthPercent > 0.33 then
            esp.HealthBar.Color = Color3.fromRGB(255, 255, 0)
        else
            esp.HealthBar.Color = Color3.fromRGB(255, 0, 0)
        end
        esp.HealthBar.Visible = true
    else
        esp.HealthBarBG.Visible = false
        esp.HealthBar.Visible = false
    end
end

function module:OnEnable()
    print("[ESP] Enabled")
    self.Enabled = true

    -- Создаём ESP для всех игроков
    for _, player in ipairs(Players:GetPlayers()) do
        self:CreateESP(player)
    end

    -- Новые игроки
    self._connections.playerAdded = Players.PlayerAdded:Connect(function(player)
        self:CreateESP(player)
    end)

    -- Уходящие игроки
    self._connections.playerRemoving = Players.PlayerRemoving:Connect(function(player)
        self:RemoveESP(player)
    end)

    -- Обновление каждый кадр
    self._connections.render = RunService.RenderStepped:Connect(function()
        if not self.Enabled then return end
        
        for player, _ in pairs(self._espObjects) do
            if player and player.Parent then
                pcall(function()
                    self:UpdatePlayerESP(player)
                end)
            else
                self:RemoveESP(player)
            end
        end
    end)
end

function module:OnDisable()
    print("[ESP] Disabled")
    self.Enabled = false

    -- Отключаем соединения
    for _, conn in pairs(self._connections) do
        if conn then
            conn:Disconnect()
        end
    end
    self._connections = {}

    -- Удаляем все ESP
    for player, _ in pairs(self._espObjects) do
        self:RemoveESP(player)
    end
end

function module:OnTick(dt)
end

return module
