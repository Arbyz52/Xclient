-- modules/Movement/BunnyHop.lua
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local module = {
    Name     = "BunnyHop (Space)",
    Category = "Movement",
    Enabled  = false,
}

local CONFIG = {
    HoldKey   = Enum.KeyCode.Space,
    PushForce = 28,
}

local holding = false
local stateConn, inputBeganConn, inputEndedConn

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
        hrp.Velocity = Vector3.new(push.X, hrp.Velocity.Y, push.Z)
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

    local hum, hrp = getChar()
    if hum then
        stateConn = hum.StateChanged:Connect(function(_, new)
            if self.Enabled and holding and new == Enum.HumanoidStateType.Landed then
                hop(hum, hrp)
            end
        end)
    end
end

function module:OnDisable()
    self.Enabled = false
    holding = false
    if inputBeganConn then inputBeganConn:Disconnect() inputBeganConn = nil end
    if inputEndedConn then inputEndedConn:Disconnect() inputEndedConn = nil end
    if stateConn then stateConn:Disconnect() stateConn = nil end
end

function module:Init() end
function module:OnTick(dt) end

return module
