local module = {
    Name     = "ESP",
    Category = "Visuals",
    Enabled  = true,
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

module._espCache = {}
module._updateConnection = nil

-- Функция создания Drawing элементов (быстрее чем GUI)
local function createDrawing(type, properties)
    local drawing = Drawing.new(type)
    for prop, value in pairs(properties) do
        drawing[prop] = value
    end
    return drawing
end

function module:Init()
    print("[ESP] Инициализация")
end

function module:CreateESP(player)
    if player == LocalPlayer then return end
    
    local esp = {
        -- Линии бокса
        TopLine = createDrawing("Line", {
            Thickness = 2,
            Color = Color3.rgb(255, 255, 255),
            Transparency = 1,
            Visible = false
        }),
        BottomLine = createDrawing("Line", {
            Thickness = 2,
            Color = Color3.rgb(255, 255, 255),
            Transparency = 1,
            Visible = false
        }),
        LeftLine = createDrawing("Line", {
            Thickness = 2,
            Color = Color3.rgb(255, 255, 255),
            Transparency = 1,
            Visible = false
        }),
        RightLine = createDrawing("Line", {
            Thickness = 2,
            Color = Color3.rgb(255, 255, 255),
            Transparency = 1,
            Visible = false
        }),
        
        -- Текст имени
        NameText = createDrawing("Text", {
            Size = 18,
            Center = true,
            Outline = true,
            Color = Color3.rgb(255, 255, 255),
            Transparency = 1,
            Visible = false,
            Text = player.Name
        }),
        
        -- Текст дистанции
        DistanceText = createDrawing("Text", {
            Size = 14,
            Center = true,
            Outline = true,
            Color = Color3.rgb(200, 200, 200),
            Transparency = 1,
            Visible = false,
            Text = ""
        }),
        
        -- Бар здоровья
        HealthBarOutline = createDrawing("Square", {
            Thickness = 1,
            Filled = false,
            Color = Color3.rgb(0, 0, 0),
            Transparency = 1,
            Visible = false
        }),
        HealthBar = createDrawing("Square", {
            Thickness = 1,
            Filled = true,
            Color = Color3.rgb(0, 255, 0),
            Transparency = 1,
            Visible = false
        }),
    }
    
    self._espCache[player] = esp
end

function module:RemoveESP(player)
    local esp = self._espCache[player]
    if not esp then return end
    
    for _, drawing in pairs(esp) do
        drawing:Remove()
    end
    
    self._espCache[player] = nil
end

function module:UpdateESP(player, esp)
    local char = player.Character
    if not char then
        for _, drawing in pairs(esp) do
            drawing.Visible = false
        end
        return
    end
    
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChild("Humanoid")
    local head = char:FindFirstChild("Head")
    
    if not rootPart or not humanoid or not head or humanoid.Health <= 0 then
        for _, drawing in pairs(esp) do
            drawing.Visible = false
        end
        return
    end
    
    -- Вычисление позиций
    local rootPos = rootPart.Position
    local headPos = head.Position + Vector3.new(0, 0.5, 0)
    local legPos = rootPart.Position - Vector3.new(0, 3, 0)
    
    -- Конвертация в screen space
    local headPoint, headVisible = Camera:WorldToViewportPoint(headPos)
    local rootPoint, rootVisible = Camera:WorldToViewportPoint(rootPos)
    local legPoint, legVisible = Camera:WorldToViewportPoint(legPos)
    
    if not headVisible or headPoint.Z < 0 then
        for _, drawing in pairs(esp) do
            drawing.Visible = false
        end
        return
    end
    
    -- Вычисление размеров бокса
    local height = math.abs(headPoint.Y - legPoint.Y)
    local width = height * 0.5
    
    local boxX = headPoint.X - width / 2
    local boxY = headPoint.Y
    
    -- Дистанция
    local distance = 0
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        distance = (LocalPlayer.Character.HumanoidRootPart.Position - rootPos).Magnitude
    end
    
    -- Цвет по команде
    local color = Color3.rgb(255, 0, 0)
    if player.Team and player.Team.TeamColor then
        color = player.Team.TeamColor.Color
    end
    
    -- Обновление бокса
    esp.TopLine.From = Vector2.new(boxX, boxY)
    esp.TopLine.To = Vector2.new(boxX + width, boxY)
    esp.TopLine.Color = color
    esp.TopLine.Visible = true
    
    esp.BottomLine.From = Vector2.new(boxX, boxY + height)
    esp.BottomLine.To = Vector2.new(boxX + width, boxY + height)
    esp.BottomLine.Color = color
    esp.BottomLine.Visible = true
    
    esp.LeftLine.From = Vector2.new(boxX, boxY)
    esp.LeftLine.To = Vector2.new(boxX, boxY + height)
    esp.LeftLine.Color = color
    esp.LeftLine.Visible = true
    
    esp.RightLine.From = Vector2.new(boxX + width, boxY)
    esp.RightLine.To = Vector2.new(boxX + width, boxY + height)
    esp.RightLine.Color = color
    esp.RightLine.Visible = true
    
    -- Обновление имени
    esp.NameText.Position = Vector2.new(headPoint.X, boxY - 18)
    esp.NameText.Text = player.Name
    esp.NameText.Color = color
    esp.NameText.Visible = true
    
    -- Обновление дистанции
    esp.DistanceText.Position = Vector2.new(headPoint.X, boxY + height + 2)
    esp.DistanceText.Text = string.format("[%dm]", math.floor(distance))
    esp.DistanceText.Visible = true
    
    -- Обновление здоровья
    local healthPercent = humanoid.Health / humanoid.MaxHealth
    local healthBarWidth = 3
    local healthBarHeight = height
    
    esp.HealthBarOutline.Size = Vector2.new(healthBarWidth, healthBarHeight)
    esp.HealthBarOutline.Position = Vector2.new(boxX - healthBarWidth - 3, boxY)
    esp.HealthBarOutline.Visible = true
    
    local currentHealthHeight = healthBarHeight * healthPercent
    esp.HealthBar.Size = Vector2.new(healthBarWidth - 2, currentHealthHeight)
    esp.HealthBar.Position = Vector2.new(boxX - healthBarWidth - 2, boxY + healthBarHeight - currentHealthHeight)
    
    -- Цвет здоровья (зеленый -> желтый -> красный)
    local r = math.floor((1 - healthPercent) * 255)
    local g = math.floor(healthPercent * 255)
    esp.HealthBar.Color = Color3.rgb(r, g, 0)
    esp.HealthBar.Visible = true
end

function module:OnEnable()
    print("[ESP] Включен")
    
    -- Создаем ESP для всех игроков
    for _, player in pairs(Players:GetPlayers()) do
        self:CreateESP(player)
    end
    
    -- Подключение к событиям
    self._playerAdded = Players.PlayerAdded:Connect(function(player)
        self:CreateESP(player)
    end)
    
    self._playerRemoving = Players.PlayerRemoving:Connect(function(player)
        self:RemoveESP(player)
    end)
    
    -- Обновление каждый кадр
    self._updateConnection = RunService.RenderStepped:Connect(function()
        for player, esp in pairs(self._espCache) do
            if player and player.Parent then
                pcall(function()
                    self:UpdateESP(player, esp)
                end)
            else
                self:RemoveESP(player)
            end
        end
    end)
end

function module:OnDisable()
    print("[ESP] Выключен")
    
    -- Отключаем обновление
    if self._updateConnection then
        self._updateConnection:Disconnect()
        self._updateConnection = nil
    end
    
    if self._playerAdded then
        self._playerAdded:Disconnect()
    end
    
    if self._playerRemoving then
        self._playerRemoving:Disconnect()
    end
    
    -- Скрываем все ESP
    for player, esp in pairs(self._espCache) do
        for _, drawing in pairs(esp) do
            drawing.Visible = false
        end
    end
end

function module:OnTick(dt)
    -- RenderStepped используется для обновления
end

return module
