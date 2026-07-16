
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local BunnyHop = {
    __settings__ = {},
    SettingsDefinitions = {
        { Name = "Интенсивность", Key = "Intensity", Type = "Slider", Min = 1, Max = 10, Step = 1, Default = 3, Suffix = "" },
    },
}

local connection = nil

function BunnyHop:OnEnable()
    print("[Xclient] BunnyHop Legit ON")

    connection = RunService.RenderStepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        local humanoid = char:FindFirstChild("Humanoid")
        if not humanoid then return end

        if humanoid:GetState() == Enum.HumanoidStateType.Freefall
        or humanoid:GetState() == Enum.HumanoidStateType.Running then
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                humanoid.Jump = true
            end
        end
    end)
end

function BunnyHop:OnDisable()
    print("[Xclient] BunnyHop Legit OFF")
    if connection then connection:Disconnect() connection = nil end
end

return BunnyHop
