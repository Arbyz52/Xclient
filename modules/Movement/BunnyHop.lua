-- modules/Movement/BunnyHop.lua

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local VERSION = "BunnyHop v3.2 (Legit Fixed)"
print("[Module] Loaded: " .. VERSION)

local module = {
    Name     = "BunnyHop Legit",
    Category = "Movement",
    Enabled  = false,
}

local CONFIG = {
    HoldKey    = Enum.KeyCode.Space,
    SpeedMulti = 1.1, -- 1.0 = обычная скорость, 1.1 = немного быстрее
}

-- Коннекты
local steppedConn, charAddedConn

local function getChar()
    local char = LocalPlayer.Character
    if not char then return nil, nil end
    local hum = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return nil, nil end
    return hum, hrp
end

-- Основная функция движения
local function processBhop(hum, hrp)
    if hum.MoveDirection.Magnitude <= 0 then return end

    -- Автопрыжок
    if hum.FloorMaterial ~= Enum.Material.Air then
        hum.Jump = true
    end

    -- Убираем трение
    local targetSpeed = hum.WalkSpeed * CONFIG.SpeedMulti
    local dir = hum.MoveDirection
    local currentY = hrp.AssemblyLinearVelocity.Y

    hrp.AssemblyLinearVelocity = Vector3.new(dir.X * targetSpeed, currentY, dir.Z * targetSpeed)
end

local function attach(self)
    -- Анти-дупликат
    if steppedConn then steppedConn:Disconnect() steppedConn = nil end
    if charAddedConn then charAddedConn:Disconnect() charAddedConn = nil end

    steppedConn = RunService.RenderStepped:Connect(function()
        if not self.Enabled then return end
        if not UserInputService:IsKeyDown(CONFIG.HoldKey) then return end

        local hum, hrp = getChar()
        if hum and hrp then
            processBhop(hum, hrp)
        end
    end)

    charAddedConn = LocalPlayer.CharacterAdded:Connect(function()
        -- tickFrame всегда проверяет актуальный char, поэтому тут ничего не нужно
        -- но оставляем хук для совместимости
        -- print("[BunnyHop Legit] Character respawned")
    end)
end

function module:OnEnable()
    self.Enabled = true
    print("[Module] BHop Legit Enabled")
    attach(self)
end

function module:OnDisable()
    self.Enabled = false
    print("[Module] BHop Legit Disabled")

    if steppedConn then steppedConn:Disconnect() steppedConn = nil end
    if charAddedConn then charAddedConn:Disconnect() charAddedConn = nil end
end

function module:Init() end
function module:OnTick(dt) end

return module
