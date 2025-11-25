local module = {
    Name     = "ESP",
    Category = "Visuals",
    Enabled  = false,
}

local CoreGui = game:GetService("CoreGui")

-- сюда положим наш ScreenGui
module._gui = nil

function module:Init()
    print("[Xclient][ESP] Init()")
end

function module:OnEnable()
    print("[Xclient][ESP] Включен")

    if self._gui then
        self._gui.Enabled = true
        return
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "Xclient_ESP_Test"
    screenGui.ResetOnSpawn = false

    local parent = CoreGui
    pcall(function()
        if gethui then parent = gethui() end
    end)
    screenGui.Parent = parent

    -- просто делаем рамочки по краям экрана для наглядности
    local function makeBox(name, pos, size, color)
        local f = Instance.new("Frame")
        f.Name = name
        f.Size = size
        f.Position = pos
        f.BackgroundColor3 = color
        f.BackgroundTransparency = 0.4
        f.BorderSizePixel = 0
        f.Parent = screenGui
        return f
    end

    -- 4 рамки по краям
    makeBox("TopBar",    UDim2.new(0, 0, 0, 0),             UDim2.new(1, 0, 0, 3),  Color3.fromRGB(0, 255, 0))
    makeBox("BottomBar", UDim2.new(0, 0, 1, -3),            UDim2.new(1, 0, 0, 3),  Color3.fromRGB(0, 255, 0))
    makeBox("LeftBar",   UDim2.new(0, 0, 0, 0),             UDim2.new(0, 3, 1, 0),  Color3.fromRGB(0, 255, 0))
    makeBox("RightBar",  UDim2.new(1, -3, 0, 0),            UDim2.new(0, 3, 1, 0),  Color3.fromRGB(0, 255, 0))

    -- и надпись вверху по центру
    local label = Instance.new("TextLabel")
    label.Name = "ESPLabel"
    label.Size = UDim2.new(0, 200, 0, 24)
    label.Position = UDim2.new(0.5, -100, 0, 10)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.Text = "ESP TEST ACTIVE"
    label.TextColor3 = Color3.fromRGB(0, 255, 0)
    label.TextSize = 18
    label.Parent = screenGui

    self._gui = screenGui
end

function module:OnDisable()
    print("[Xclient][ESP] Выключен")
    if self._gui then
        self._gui.Enabled = false
    end
end

function module:OnTick(dt)
    if not self.Enabled then return end
    -- сюда потом можешь добавить реальную логику ESP,
    -- пока ничего не делаем, только рамки и надпись
end

return module
