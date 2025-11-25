local module = {
    Name     = "ESP",   -- как будет называться в колонке Visuals
    Category = "Visuals",
    Enabled  = false,
}

local RunService = game:GetService("RunService")
local CoreGui    = game:GetService("CoreGui")

module._gui   = nil
module._frame = nil
module._conn  = nil

function module:Init()
    print("[Xclient][TestOverlay] Init()")
end

function module:OnEnable()
    print("[Xclient][TestOverlay] Включен")

    -- Создаём GUI один раз
    if not self._gui then
        local gui = Instance.new("ScreenGui")
        gui.Name = "Xclient_TestOverlay"
        gui.ResetOnSpawn = false

        local parent = CoreGui
        pcall(function()
            if gethui then parent = gethui() end
        end)
        gui.Parent = parent

        self._gui = gui

        -- центральный прямоугольник
        local frame = Instance.new("Frame")
        frame.Name = "PulseBox"
        frame.Size = UDim2.new(0, 200, 0, 100)
        frame.Position = UDim2.new(0.5, -100, 0.5, -50)
        frame.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
        frame.BackgroundTransparency = 0.2
        frame.BorderSizePixel = 0
        frame.Parent = gui

        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

        self._frame = frame
    end

    self._gui.Enabled = true
    self._frame.Visible = true

    -- Анимация через RenderStepped (пульс по размеру/прозрачности)
    local t = 0
    self._conn = RunService.RenderStepped:Connect(function(dt)
        if not self.Enabled then return end
        t += dt * 3

        local scale = 1 + 0.1 * math.sin(t)
        local alpha = 0.2 + 0.1 * (1 - math.cos(t))

        local baseW, baseH = 200, 100
        local w = baseW * scale
        local h = baseH * scale

        if self._frame then
            self._frame.Size = UDim2.new(0, w, 0, h)
            self._frame.Position = UDim2.new(0.5, -w/2, 0.5, -h/2)
            self._frame.BackgroundTransparency = alpha
        end
    end)
end

function module:OnDisable()
    print("[Xclient][TestOverlay] Выключен")

    if self._conn then
        self._conn:Disconnect()
        self._conn = nil
    end

    if self._frame then
        self._frame.Visible = false
    end

    if self._gui then
        self._gui.Enabled = false
    end
end

function module:OnTick(dt)
    -- ничего, всё делаем в RenderStepped
end

return module
