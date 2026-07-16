
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local AntiAFK = {
    __settings__ = {},
    SettingsDefinitions = {
        { Name = "Интервал (сек)", Key = "Interval", Type = "Slider", Min = 10, Max = 120, Step = 5, Default = 30, Suffix = "с" },
        { Name = "Прыжок",          Key = "Jump",     Type = "Toggle", Default = true },
    },
}

local connection = nil
local lastAction = 0

function AntiAFK:Init()
    self.__settings__.Interval = self.__settings__.Interval or 30
    self.__settings__.Jump = self.__settings__.Jump == nil and true or self.__settings__.Jump
end

function AntiAFK:OnEnable()
    print("[Xclient] AntiAFK ON")

    -- Override Idle event
    pcall(function()
        LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end)

    lastAction = tick()

    connection = RunService.Heartbeat:Connect(function()
        local now = tick()
        local interval = self.__settings__.Interval or 30

        if now - lastAction >= interval then
            lastAction = now

            -- Small movement
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)

            -- Optional jump
            if self.__settings__.Jump then
                pcall(function()
                    local char = LocalPlayer.Character
                    if char then
                        local humanoid = char:FindFirstChild("Humanoid")
                        if humanoid then
                            humanoid.Jump = true
                        end
                    end
                end)
            end
        end
    end)
end

function AntiAFK:OnDisable()
    print("[Xclient] AntiAFK OFF")
    if connection then connection:Disconnect() connection = nil end
end

return AntiAFK
