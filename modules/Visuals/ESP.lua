local module = {
    Name     = "Crosshair",
    Category = "Interface",
    Enabled  = false,
}

local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

module._gui = nil

function module:Init()
    print("[Xclient][Crosshair] Init()")
end

function module:OnEnable()
    print("[Xclient][Crosshair] Включен")
    
    if self._gui then
        self._gui.Enabled = true
        return
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "Xclient_Crosshair"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    
    local parent = CoreGui
    pcall(function()
        if gethui then parent = gethui() end
    end)
    screenGui.Parent = parent
    
    -- Создаем прицел
    local center = Instance.new("Frame")
    center.Name = "Center"
    center.Size = UDim2.new(0, 4, 0, 4)
    center.Position = UDim2.new(0.5, -2, 0.5, -2)
    center.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    center.BorderSizePixel = 0
    center.Parent = screenGui
    
    -- Горизонтальная линия
    local horizontal = Instance.new("Frame")
    horizontal.Size = UDim2.new(0, 20, 0, 2)
    horizontal.Position = UDim2.new(0.5, -10, 0.5, -1)
    horizontal.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    horizontal.BorderSizePixel = 0
    horizontal.Parent = screenGui
    
    -- Вертикальная линия
    local vertical = Instance.new("Frame")
    vertical.Size = UDim2.new(0, 2, 0, 20)
    vertical.Position = UDim2.new(0.5, -1, 0.5, -10)
    vertical.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    vertical.BorderSizePixel = 0
    vertical.Parent = screenGui
    
    self._gui = screenGui
end

function module:OnDisable()
    print("[Xclient][Crosshair] Выключен")
    if self._gui then
        self._gui.Enabled = false
    end
end

function module:OnTick(dt)
    -- Не используется
end

return module
