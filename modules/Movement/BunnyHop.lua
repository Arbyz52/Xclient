-- modules/Movement/BunnyHop.lua
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local VERSION = "BunnyHop v1.2.0"
print("[Module] Loaded: " .. VERSION)

local module = {
    Name     = "BunnyHop (Space)",
    Category = "Movement",
    Enabled  = false,
}

local CONFIG = {
    HoldKey   = Enum.KeyCode.Space,
    PushForce = 26,
}

local holding = false
local inputBeganConn, inputEndedConn, steppedConn

local function getChar()
    local char = LocalPlayer.Character
    if not char then return nil,nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return nil,nil end
    return hum, hrp
end

local function hop(hum, hrp)
    hum:ChangeState(Enum.HumanoidStateType.Jumping)
    local moveDir = hum.MoveDirection
    if moveDir.Magnitude > 0 then
        local push = moveDir.Unit * CONFIG.PushForce
        hrp.AssemblyLinearVelocity = Vector3.new(push.X, hrp.AssemblyLinearVelocity.Y, push.Z)
    end
end

function module:OnEnable()
    self.Enabled = true
    inputBeganConn = UserInputService.InputBegan:Connect(function(input,gp)
        if gp then return end
        if input.KeyCode == CONFIG.HoldKey then holding = true end
    end)
    inputEndedConn = UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == CONFIG.HoldKey then holding = false end
    end)

    -- главный цикл: проверяем каждый кадр
    steppedConn = RunService.RenderStepped:Connect(function()
        if not self.Enabled or not holding then return end
        local hum, hrp = getChar()
        if hum and hrp and hum.FloorMaterial ~= Enum.Material.Air then
            hop(hum, hrp)
        end
    end)
end

function module:OnDisable()
    self.Enabled = false
    holding = false
    if inputBeganConn then inputBeganConn:Disconnect() inputBeganConn = nil end
    if inputEndedConn then inputEndedConn:Disconnect() inputEndedConn = nil end
    if steppedConn then steppedConn:Disconnect() steppedConn = nil end
end

function module:Init() end
function module:OnTick(dt) end

return module
