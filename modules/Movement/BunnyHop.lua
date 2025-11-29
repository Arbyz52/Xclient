-- modules/Movement/BunnyHop.lua
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local module = {
    Name     = "BunnyHop (Space)",
    Category = "Movement",
    Enabled  = false,
}

-- ==================== КОНФИГ ====================
local CONFIG = {
    HoldKey    = Enum.KeyCode.Space, -- удерживай пробел
    Cooldown   = 0.08,               -- минимальный интервал между прыжками
    PushForce  = 28,                 -- сила толчка по MoveDirection
}

local holding = false
local lastHop = 0
local inputBeganConn, inputEndedConn

-- ==================== Вспомогательные ====================
local function getChar()
    local char = LocalPlayer.Character
    if not char then return nil,nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return nil,nil end
    return hum, hrp
end

local function doBhop(hum, hrp)
    if hum.FloorMaterial == Enum.Material.Air then return end
    local now = tick()
    if (now - lastHop) < CONFIG.Cooldown then return end
    lastHop = now

    hum:ChangeState(Enum.HumanoidStateType.Jumping)

    task.spawn(function()
        RunService.RenderStepped:Wait()
        if not hrp.Parent then return end
        local moveDir = hum.MoveDirection
        if moveDir.Magnitude > 0 then
            local push = moveDir.Unit * CONFIG.PushForce
            hrp.Velocity = Vector3.new(push.X, hrp.Velocity.Y, push.Z)
        end
    end)
end

-- ==================== Методы модуля ====================
function module:OnEnable()
    self.Enabled = true
    inputBeganConn = UserInputService.InputBegan:Connect(function(input,gp)
        if gp then return end
        if input.KeyCode == CONFIG.HoldKey then holding = true end
    end)
    inputEndedConn = UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == CONFIG.HoldKey then holding = false end
    end)
end

function module:OnDisable()
    self.Enabled = false
    holding = false
    if inputBeganConn then inputBeganConn:Disconnect() inputBeganConn = nil end
    if inputEndedConn then inputEndedConn:Disconnect() inputEndedConn = nil end
end

function module:Init()
    -- можно добавить логи или авто‑подсказку
end

function module:OnTick(dt)
    if not self.Enabled or not holding then return end
    local hum, hrp = getChar()
    if hum and hrp then
        doBhop(hum, hrp)
    end
end

return module
