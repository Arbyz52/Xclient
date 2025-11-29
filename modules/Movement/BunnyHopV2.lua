local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local module = {
    Name = "BunnyHop RAGE",
    Category = "Movement",
    Enabled = false,
}

local CONFIG = {
    HoldKey   = Enum.KeyCode.Space,
    BoostForce = 24,
    MinY       = 1.5,
}


local steppedConn
local charAddedConn


local function getChar()
    local char = LocalPlayer.Character
    if not char then return nil, nil end
    local hum = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return nil, nil end
    return hum, hrp
end


local function tickFrame(self)

    if not self.Enabled then return end


    if not UserInputService:IsKeyDown(CONFIG.HoldKey) then return end

    local hum, hrp = getChar()
    if not hum or not hrp then return end

    if hum.FloorMaterial ~= Enum.Material.Air then
        hum.Jump = true
    end

    local v = hrp.AssemblyLinearVelocity
    local isJumping = math.abs(v.Y) > CONFIG.MinY or hum.FloorMaterial == Enum.Material.Air

    if isJumping then
        local dir = hum.MoveDirection
        if dir.Magnitude > 0 then
            local push = dir.Unit * CONFIG.BoostForce
            hrp.AssemblyLinearVelocity = Vector3.new(push.X, v.Y, push.Z)
        end
    end
end

local function attach(self)
    if steppedConn then steppedConn:Disconnect() steppedConn = nil end
    if charAddedConn then charAddedConn:Disconnect() charAddedConn = nil end

    steppedConn = RunService.RenderStepped:Connect(function()
        tickFrame(self)
    end)
    
    charAddedConn = LocalPlayer.CharacterAdded:Connect(function()
    end)
end

function module:OnEnable()
    self.Enabled = true
    attach(self)
end

function module:OnDisable()
    self.Enabled = false

    if steppedConn then
        steppedConn:Disconnect()
        steppedConn = nil
    end
    if charAddedConn then
        charAddedConn:Disconnect()
        charAddedConn = nil
    end
end

function module:Init()

end

function module:OnTick(dt)

end

return module
