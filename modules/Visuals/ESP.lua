local module = {
    Name     = "ESP",
    Category = "Visuals",
    Enabled  = true,
}

local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")

module._gui = nil
module._connection = nil
module._frameCount = 0
module._lastUpdate = 0

function module:Init()
    print("[Xclient][FPS Monitor] Init()")
end

function module:OnEnable()
    print("[Xclient][FPS Monitor] Включен")
    
    if self._gui then
        self._gui.Enabled = true
        return
    end
    
    -- Создаем GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "Xclient_FPSMonitor"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 150, 0, 80)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Name = "FPS"
    fpsLabel.Size = UDim2.new(1, 0, 0.5, 0)
    fpsLabel.Position = UDim2.new(0, 0, 0, 0)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Font = Enum.Font.SourceSansBold
    fpsLabel.Text = "FPS: 0"
    fpsLabel.TextColor3 = Color3.new(1, 1, 1)
    fpsLabel.TextSize = 16
    fpsLabel.Parent = frame
    
    local pingLabel = Instance.new("TextLabel")
    pingLabel.Name = "Ping"
    pingLabel.Size = UDim2.new(1, 0, 0.5, 0)
    pingLabel.Position = UDim2.new(0, 0, 0.5, 0)
    pingLabel.BackgroundTransparency = 1
    pingLabel.Font = Enum.Font.SourceSansBold
    pingLabel.Text = "Ping: 0ms"
    pingLabel.TextColor3 = Color3.new(1, 1, 1)
    pingLabel.TextSize = 16
    pingLabel.Parent = frame
    
    local parent = CoreGui
    pcall(function()
        if gethui then parent = gethui() end
    end)
    screenGui.Parent = parent
    
    self._gui = screenGui
    self._fpsLabel = fpsLabel
    self._pingLabel = pingLabel
    
    -- Запускаем обновление
    self._lastUpdate = tick()
    self._frameCount = 0
    
    self._connection = RunService.RenderStepped:Connect(function()
        self._frameCount = self._frameCount + 1
        
        local currentTime = tick()
        if currentTime - self._lastUpdate >= 1 then
            local fps = self._frameCount
            self._frameCount = 0
            self._lastUpdate = currentTime
            
            self._fpsLabel.Text = string.format("FPS: %d", fps)
            
            -- Цвет FPS в зависимости от значения
            if fps >= 50 then
                self._fpsLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            elseif fps >= 30 then
                self._fpsLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
            else
                self._fpsLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
            end
            
            -- Пинг
            local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
            self._pingLabel.Text = string.format("Ping: %dms", math.floor(ping))
            
            -- Цвет пинга
            if ping <= 50 then
                self._pingLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            elseif ping <= 100 then
                self._pingLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
            else
                self._pingLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
            end
        end
    end)
end

function module:OnDisable()
    print("[Xclient][FPS Monitor] Выключен")
    
    if self._gui then
        self._gui.Enabled = false
    end
    
    if self._connection then
        self._connection:Disconnect()
        self._connection = nil
    end
end

function module:OnTick(dt)
    -- Не используется
end

return module
