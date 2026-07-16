
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local SpeedHack = {
    __settings__ = {},
    SettingsDefinitions = {
        { Name = "Скорость", Key = "Speed", Type = "Slider", Min = 16, Max = 120, Step = 2, Default = 32, Suffix = "" },
    },
}

local connection = nil
local originalWalkSpeed = nil

function SpeedHack:Init()
    self.__settings__.Speed = self.__settings__.Speed or 32
end

function SpeedHack:OnEnable()
    print("[Xclient] SpeedHack ON")

    connection = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        local humanoid = char:FindFirstChild("Humanoid")
        if not humanoid then return end

        local speed = self.__settings__.Speed or 32
        if humanoid.WalkSpeed ~= speed then
            humanoid.WalkSpeed = speed
        end
    end)
end

function SpeedHack:OnDisable()
    print("[Xclient] SpeedHack OFF")
    if connection then connection:Disconnect() connection = nil end

    pcall(function()
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = 16
            end
        end
    end)
end

return SpeedHack
