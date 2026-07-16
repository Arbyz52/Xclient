
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Fly = {
    __settings__ = {},
    SettingsDefinitions = {
        { Name = "Скорость", Key = "Speed", Type = "Slider", Min = 10, Max = 300, Step = 10, Default = 80, Suffix = "" },
    },
}

local connection = nil
local bodyVelocity = nil
local bodyGyro = nil

function Fly:Init()
    self.__settings__.Speed = self.__settings__.Speed or 80
end

function Fly:OnEnable()
    print("[Xclient] Fly ON")

    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end

    humanoid.PlatformStand = true

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Velocity = Vector3.zero
    bodyVelocity.Parent = root

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyGyro.D = 200
    bodyGyro.P = 20000
    bodyGyro.Parent = root

    connection = RunService.RenderStepped:Connect(function()
        if not root or not root.Parent then return end

        local speed = self.__settings__.Speed or 80
        local moveVec = Vector3.zero

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveVec = moveVec + Camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveVec = moveVec - Camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveVec = moveVec - Camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveVec = moveVec + Camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveVec = moveVec + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            moveVec = moveVec - Vector3.new(0, 1, 0)
        end

        if moveVec.Magnitude > 0 then
            moveVec = moveVec.Unit
        end

        bodyVelocity.Velocity = moveVec * speed
        bodyGyro.CFrame = Camera.CFrame
    end)
end

function Fly:OnDisable()
    print("[Xclient] Fly OFF")
    if connection then connection:Disconnect() connection = nil end

    pcall(function()
        if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
        if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
    end)

    pcall(function()
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChild("Humanoid")
            if humanoid then humanoid.PlatformStand = false end
        end
    end)
end

return Fly
