
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local BunnyHopV2 = {
    __settings__ = {},
    SettingsDefinitions = {
        { Name = "Усиление прыжка", Key = "BoostPower", Type = "Slider", Min = 10, Max = 100, Step = 5, Default = 40, Suffix = "" },
        { Name = "Задержка (мс)",   Key = "Delay",      Type = "Slider", Min = 0,  Max = 50,  Step = 5, Default = 0,  Suffix = "мс" },
    },
}

local connection = nil

function BunnyHopV2:Init()
    self.__settings__.BoostPower = self.__settings__.BoostPower or 40
    self.__settings__.Delay = self.__settings__.Delay or 0
end

function BunnyHopV2:OnEnable()
    print("[Xclient] BunnyHop RAGE ON")

    connection = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChild("Humanoid")
        if not root or not humanoid then return end

        local boost = self.__settings__.BoostPower or 40
        local delay = self.__settings__.Delay or 0

        if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                local vel = root.AssemblyLinearVelocity
                root.AssemblyLinearVelocity = Vector3.new(vel.X, boost, vel.Z)
            end
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            humanoid.Jump = true
        end

        if delay > 0 then
            task.wait(delay / 1000)
        end
    end)
end

function BunnyHopV2:OnDisable()
    print("[Xclient] BunnyHop RAGE OFF")
    if connection then connection:Disconnect() connection = nil end
end

return BunnyHopV2
