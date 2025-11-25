local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui    = game:GetService("CoreGui")
local Workspace  = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

local module = {
    Name     = "ESP",
    Category = "Visuals",
    Enabled  = false,
}

local Settings = {
    BoxColor       = Color3.fromRGB(255, 0, 0),
    NameColor      = Color3.fromRGB(255, 255, 255),
    MaxDistance    = 1000,
    TeamCheck      = true,
    ShowBox        = true,
    ShowName       = true,
    ShowHealth     = true,
    ShowDistance   = true,
}

module._gui         = nil        -- ScreenGui
module._container   = nil        -- Folder под все ESP объекты
module._espObjects  = {}         -- [player] = {...}
module._connections = {}         -- список коннектов

function module:Init()
    print("[Xclient][ESP] Init()")
end

---------------------------------------------------------------------
-- Вспомогательные
---------------------------------------------------------------------
local function hideAll(esp)
    for _, obj in pairs(esp) do
        if typeof(obj) == "Instance" and obj:IsA("GuiObject") then
            obj.Visible = false
        end
    end
end

---------------------------------------------------------------------
-- Создание ESP элементов для игрока
---------------------------------------------------------------------
function module:CreateESP(player)
    if player == LocalPlayer then return end

    -- защита от дубликатов
    self:RemoveESP(player)

    if not self._container then return end

    local espHolder = Instance.new("Folder")
    espHolder.Name = player.Name .. "_ESP"
    espHolder.Parent = self._container

    -- Бокс
    local box = Instance.new("Frame")
    box.Name = "Box"
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false

    local boxStroke = Instance.new("UIStroke")
    boxStroke.Color = Settings.BoxColor
    boxStroke.Thickness = 2
    boxStroke.Parent = box

    -- Имя
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
    nameLabel.Visible = false

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
    distanceLabel.Visible = false

    -- Здоровье (полоска слева)
    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.BackgroundColor3 = Color3.new(0, 0, 0)
    healthBar.BorderSizePixel = 0
    healthBar.Visible = false

    local healthFill = Instance.new("Frame")
    healthFill.Name = "Fill"
    healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthFill.BorderSizePixel = 0
    healthFill.Parent = healthBar

    box.Parent          = espHolder
    nameLabel.Parent    = espHolder
    distanceLabel.Parent= espHolder
    healthBar.Parent    = espHolder

    self._espObjects[player] = {
        Holder     = espHolder,
        Box        = box,
        Name       = nameLabel,
        Distance   = distanceLabel,
        HealthBar  = healthBar,
        HealthFill = healthFill
    }
end

---------------------------------------------------------------------
-- Удаление ESP игрока
---------------------------------------------------------------------
function module:RemoveESP(player)
    local esp = self._espObjects[player]
    if esp then
        if esp.Holder and esp.Holder.Parent then
            esp.Holder:Destroy()
        else
            for _, obj in pairs(esp) do
                if typeof(obj) == "Instance" and obj.Parent then
                    obj:Destroy()
                end
            end
        end
        self._espObjects[player] = nil
    end
end

---------------------------------------------------------------------
-- Обновление ESP для конкретного игрока (каждый кадр)
---------------------------------------------------------------------
function module:UpdatePlayerESP(player)
    local esp = self._espObjects[player]
    if not esp then return end

    local character = player.Character
    if not character then
        hideAll(esp)
        return
    end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid or humanoid.Health <= 0 then
        hideAll(esp)
        return
    end

    -- TeamCheck
    if Settings.TeamCheck and player.Team ~= nil and LocalPlayer.Team ~= nil
        and player.Team == LocalPlayer.Team then
        hideAll(esp)
        return
    end

    -- расстояние
    if not Camera then
        Camera = Workspace.CurrentCamera
        if not Camera then
            hideAll(esp)
            return
        end
    end

    local distance = (hrp.Position - Camera.CFrame.Position).Magnitude
    if distance > Settings.MaxDistance then
        hideAll(esp)
        return
    end

    -- 3D -> 2D
    local rootPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
    if not onScreen then
        hideAll(esp)
        return
    end

    local head = character:FindFirstChild("Head")
    local headPos = head and Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0)) or rootPos
    local legPos  = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))

    local boxHeight = math.abs(headPos.Y - legPos.Y)
    if boxHeight < 5 then
        hideAll(esp)
        return
    end
    local boxWidth = boxHeight * 0.5

    -- Бокс
    if Settings.ShowBox then
        esp.Box.Size = UDim2.new(0, boxWidth, 0, boxHeight)
        esp.Box.Position = UDim2.new(0, rootPos.X - boxWidth / 
