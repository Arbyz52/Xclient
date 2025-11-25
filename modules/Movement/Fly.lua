local module = {
    Name     = "Fly",
    Category = "Visuals",
    Enabled  = false,
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Character, HRP
local Velocity
local FlyConnection
local InputConnection

local SPEED = 50
local Direction = Vector3.zero

-- Обновление направления
local function updateDirection()
    Direction = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then Direction += Vector3.new(0, 0, -1) end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then Direction += Vector3.new(0, 0, 1) end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then Direction += Vector3.new(-1, 0, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then Direction += Vector3.new(1, 0, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then Direction += Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then Direction += Vector3.new(0, -1, 0) end
end

-- Включение флая
function module:OnEnable()
    self.Enabled = true
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    HRP = Character:WaitForChild("HumanoidRootPart")

    -- Удалим гравитацию
    Velocity = Instance.new("BodyVelocity")
    Velocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    Velocity.Velocity = Vector3.zero
    Velocity.Parent = HRP

    -- Обновление направления
    InputConnection = UserInputService.InputBegan:Connect(updateDirection)
    addConnection = UserInputService.InputEnded:Connect(updateDirection)

    FlyConnection = RunService.RenderStepped:Connect(function()
        updateDirection()
        local camCF = workspace.CurrentCamera.CFrame
        local move = (camCF:VectorToWorldSpace(Direction)).Unit * SPEED
        if move.Magnitude ~= move.Magnitude then move = Vector3.zero end
        Velocity.Velocity = move
    end)
end

-- Выключение флая
function module:OnDisable()
    self.Enabled = false
    if Velocity then Velocity:Destroy() Velocity = nil end
    if FlyConnection then FlyConnection:Disconnect() FlyConnection = nil end
    if InputConnection then InputConnection:Disconnect() InputConnection = nil end
    if addConnection then addConnection:Disconnect() addConnection = nil end
end

function module:Init()
    print("[Fly] Init")
end

function module:OnTick(dt)
end

return module
