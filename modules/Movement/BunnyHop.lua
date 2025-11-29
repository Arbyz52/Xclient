local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local VERSION = "BunnyHop v3.2 (No Friction - Fixed)"

local module = {
    Name     = "BunnyHop Legit",
    Category = "Movement",
    Enabled  = false,
}

local CONFIG = {
    HoldKey    = Enum.KeyCode.Space,
    SpeedMulti = 1.2,
}

local steppedConn

local function getChar()
    local char = LocalPlayer.Character
    if not char then return nil, nil end
    local hum = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return nil, nil end
    return hum, hrp
end


local function tickFrame(self)

    if not self.Enabled or not UserInputService:IsKeyDown(CONFIG.HoldKey) then
        return
    end

    local hum, hrp = getChar()
    if not hum or not hrp then return end


    local dir = hum.MoveDirection
    if dir.Magnitude <= 0 then return end

    if hum.FloorMaterial ~= Enum.Material.Air then
        hum.Jump = true
    end


    local targetSpeed = hum.WalkSpeed * CONFIG.SpeedMulti
    local currentVelocity = hrp.AssemblyLinearVelocity


    hrp.AssemblyLinearVelocity = Vector3.new(
        dir.X * targetSpeed,
        currentVelocity.Y,
        dir.Z * targetSpeed
    )
end

function module:OnEnable()
    self.Enabled = true


    if steppedConn then steppedConn:Disconnect() end
    steppedConn = RunService.RenderStepped:Connect(function()
        tickFrame(self)
    end)
end

function module:OnDisable()
    self.Enabled = false

    if steppedConn then
        steppedConn:Disconnect()
        steppedConn = nil
    end
end


function module:Init() end
function module:OnTick(dt) end

return module
