local Notifications = {}

Notifications._queue = {}
Notifications._active = {}

function Notifications:Init()
    if self._initialized then return end
    self._initialized = true

    local CoreGui = game:GetService("CoreGui")
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")

    local parent = CoreGui
    pcall(function()
        if gethui then parent = gethui() end
    end)

    local container = Instance.new("Frame")
    container.Name = "XclientNotifications"
    container.Size = UDim2.new(0, 300, 1, 0)
    container.Position = UDim2.new(1, -310, 0, 10)
    container.BackgroundTransparency = 1
    container.Parent = parent

    local layout = Instance.new("UIListLayout", container)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.VerticalAlignment = Enum.VerticalAlignment.Top

    self._container = container

    RunService.RenderStepped:Connect(function()
        self:_processQueue()
    end)
end

function Notifications:_processQueue()
    if #self._queue == 0 then return end

    local entry = table.remove(self._queue, 1)
    self:_show(entry.text, entry.color, entry.duration)
end

function Notifications:_show(text, color, duration)
    local TweenService = game:GetService("TweenService")
    local container = self._container
    if not container then return end

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 36)
    frame.BackgroundColor3 = color or Color3.fromRGB(45, 45, 72)
    frame.BackgroundTransparency = 0.08
    frame.BorderSizePixel = 0
    frame.Parent = container

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = (color or Color3.fromRGB(45, 45, 72)):lerp(Color3.new(1,1,1), 0.3)
    stroke.Thickness = 1

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -16, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = Color3.fromRGB(240, 240, 255)
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.Parent = frame

    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1, -12, 0, 3)
    barBg.Position = UDim2.new(0, 6, 1, -7)
    barBg.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
    barBg.BorderSizePixel = 0
    barBg.Parent = frame
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(1, 0, 1, 0)
    barFill.BackgroundColor3 = (color or Color3.fromRGB(45, 45, 72)):lerp(Color3.new(1,1,1), 0.5)
    barFill.BorderSizePixel = 0
    barFill.Parent = barBg
    Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

    frame.BackgroundTransparency = 1
    label.TextTransparency = 1
    barBg.BackgroundTransparency = 1
    barFill.BackgroundTransparency = 1

    local fadeIn = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(frame, fadeIn, {BackgroundTransparency = 0.08}):Play()
    TweenService:Create(label, fadeIn, {TextTransparency = 0}):Play()
    TweenService:Create(barBg, fadeIn, {BackgroundTransparency = 0.5}):Play()
    TweenService:Create(barFill, fadeIn, {BackgroundTransparency = 0.1}):Play()

    local dur = duration or 3
    TweenService:Create(barFill, TweenInfo.new(dur, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 1, 0)
    }):Play()

    task.delay(dur, function()
        local fadeOut = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        TweenService:Create(frame, fadeOut, {BackgroundTransparency = 1}):Play()
        TweenService:Create(label, fadeOut, {TextTransparency = 1}):Play()
        task.wait(0.25)
        frame:Destroy()
    end)
end

function Notifications:Show(text, duration, color)
    self:Init()
    table.insert(self._queue, {
        text = text,
        duration = duration or 3,
        color = color or Color3.fromRGB(45, 45, 72)
    })
end

function Notifications:Success(text, duration)
    self:Show(text, duration or 3, Color3.fromRGB(45, 100, 65))
end

function Notifications:Error(text, duration)
    self:Show(text, duration or 4, Color3.fromRGB(120, 40, 45))
end

function Notifications:Warn(text, duration)
    self:Show(text, duration or 3, Color3.fromRGB(120, 95, 30))
end

function Notifications:Info(text, duration)
    self:Show(text, duration or 3, Color3.fromRGB(45, 70, 120))
end

return Notifications
