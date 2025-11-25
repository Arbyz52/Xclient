local module = {
    Name     = "ESP",
    Category = "Visuals",
    Enabled  = false,
}

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

module._espObjects  = {}
module._connections = {}

-- Настройки
local Settings = {
    BoxColor     = Color3.fromRGB(255, 0, 0),
    NameColor    = Color3.fromRGB(255, 255, 255),
    MaxDistance  = 1000,
    TeamCheck    = false,
}

function module:Init()
    print("[ESP] Init")
end

function module:CreateESP(player)
    if player == LocalPlayer then return end
    if self._espObjects[player] then return end

    local esp = {}

    -- Квадрат (Square)
    esp.Box = Drawing.new("Square")
    esp.Box.Thickness = 1
    esp.Box.Color = Settings.BoxColor
    esp.Box.Filled = false
    esp.Box.Visible = false

    -- Имя
    esp.Name = Drawing.new("Text")
    esp.Name.Size = 14
    esp.Name.Color = Settings.NameColor
    esp.Name.Outline = true
    esp.Name.OutlineColor = Color3.new(0, 0, 0)
    esp.Name.Center = true
    esp.Name.Visible = false
    esp.Name.Text = player.Name

    -- Дистанция
    esp.Distance = Drawing.new("Text")
    esp.Distance.Size = 12
    esp.Distance.Color = Color3.fromRGB(200, 200, 200)
    esp.Distance.Outline = true
    esp.Distance.OutlineColor = Color3.new(0, 0, 0)
    esp.Distance.Center = true
    esp.Distance.Visible = false

    -- ХП бар фон
    esp.HealthBG = Drawing.new("Square")
    esp.HealthBG.Thickness = 1
    esp.HealthBG.Color = Color3.new(0, 0, 0)
    esp.HealthBG.Filled = true
    esp.HealthBG.Visible = false

    -- ХП бар
    esp.Health = Drawing.new("Square")
    esp.Health.Thickness = 1
    esp.Health.Color = Color3.fromRGB(0, 255, 0)
    esp.Health.Filled = true
    esp.Health.Visible = false

    self._espObjects[player] = esp
    print("[ESP] Created:", player.Name)
end

function module:RemoveESP(player)
    local esp = self._espObjects[player]
    if esp then
        for _, obj in pairs(esp) do
            pcall(function()
                obj:Remove()
            end)
        end
        self._espObjects[player] = nil
        print("[ESP] Removed:", player.Name)
    end
end

function module:UpdateESP(player)
    local esp = self._espObjects[player]
    if not esp then return end

    local camera = Workspace.CurrentCamera
    if not camera then
        for _, obj in pairs(esp) do obj.Visible = false end
        return
    end

    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if not hrp or not humanoid or humanoid.Health <= 0 then
        for _, obj in pairs(esp) do obj.Visible = false end
        return
    end

    -- Команды
    if Settings.TeamCheck and player.Team and LocalPlayer.Team then
        if player.Team == LocalPlayer.Team then
            for _, obj in pairs(esp) do obj.Visible = false end
            return
        end
    end

    -- Позиция на экране
    local pos, onScreen = camera:WorldToViewportPoint(hrp.Position)

    if not onScreen or pos.Z <= 0 then
        for _, obj in pairs(esp) do obj.Visible = false end
        return
    end

    local distance = (hrp.Position - camera.CFrame.Position).Magnitude

    if distance > Settings.MaxDistance then
        for _, obj in pairs(esp) do obj.Visible = false end
        return
    end

    -- Размеры бокса
    local topPos = camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))
    local bottomPos = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))

    local height = math.abs(topPos.Y - bottomPos.Y)
    local width = height * 0.6

    local boxX = pos.X - width / 2
    local boxY = topPos.Y

    -- Бокс
    esp.Box.Size = Vector2.new(width, height)
    esp.Box.Position = Vector2.new(boxX, boxY)
    esp.Box.Color = Settings.BoxColor
    esp.Box.Visible = true

    -- Имя
    esp.Name.Position = Vector2.new(pos.X, boxY - 16)
    esp.Name.Text = player.Name
    esp.Name.Visible = true

    -- Дистанция
    esp.Distance.Position = Vector2.new(pos.X, boxY + height + 2)
    esp.Distance.Text = string.format("[%dm]", math.floor(distance))
    esp.Distance.Visible = true

    -- ХП бар
    local hp = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
    local barWidth = 4
    local barHeight = height

    -- Фон ХП
    esp.HealthBG.Size = Vector2.new(barWidth, barHeight)
    esp.HealthBG.Position = Vector2.new(boxX - barWidth - 2, boxY)
    esp.HealthBG.Visible = true

    -- ХП заполнение
    local fillHeight = barHeight * hp
    esp.Health.Size = Vector2.new(barWidth - 2, fillHeight)
    esp.Health.Position = Vector2.new(boxX - barWidth - 1, boxY + barHeight - fillHeight)
    
    -- Цвет по HP
    if hp > 0.66 then
        esp.Health.Color = Color3.fromRGB(0, 255, 0)
    elseif hp > 0.33 then
        esp.Health.Color = Color3.fromRGB(255, 255, 0)
    else
        esp.Health.Color = Color3.fromRGB(255, 0, 0)
    end
    esp.Health.Visible = true
end

function module:OnEnable()
    print("[ESP] Enabled!")
    self.Enabled = true

    -- Создаём для всех
    for _, player in pairs(Players:GetPlayers()) do
        self:CreateESP(player)
    end

    -- Новые игроки
    self._connections.added = Players.PlayerAdded:Connect(function(p)
        self:CreateESP(p)
    end)

    -- Ушедшие игроки
    self._connections.removing = Players.PlayerRemoving:Connect(function(p)
        self:RemoveESP(p)
    end)

    -- Рендер
    self._connections.render = RunService.RenderStepped:Connect(function()
        for player, _ in pairs(self._espObjects) do
            if player and player.Parent then
                self:UpdateESP(player)
            else
                self:RemoveESP(player)
            end
        end
    end)
end

function module:OnDisable()
    print("[ESP] Disabled!")
    self.Enabled = false

    for _, c in pairs(self._connections) do
        if c then c:Disconnect() end
    end
    self._connections = {}

    for player in pairs(self._espObjects) do
        self:RemoveESP(player)
    end
end

function module:OnTick(dt)
end

return module
