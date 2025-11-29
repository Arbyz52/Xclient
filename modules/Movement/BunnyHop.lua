-- modules/Movement/BunnyHopLegit.lua
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local module = {
    Name = "BunnyHop Legit",
    Category = "Movement",
    Enabled = false,
}

local CONFIG = {
    HoldKey    = Enum.KeyCode.Space,
    SpeedMulti = 1.0, -- 1.0 = обычная скорость персонажа (WalkSpeed), 1.1 = чуть быстрее
}

local steppedConn

-- Получение персонажа
local function getChar()
    local char = LocalPlayer.Character
    if not char then return nil, nil end
    local hum = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return nil, nil end
    return hum, hrp
end

-- Основная логика
local function tickFrame(self)
    -- Если модуль выключен — выход
    if not self.Enabled then return end

    -- ИСПОЛЬЗУЕМ IsKeyDown (как в рабочей версии), это намного надежнее
    if not UserInputService:IsKeyDown(CONFIG.HoldKey) then return end

    local hum, hrp = getChar()
    if not hum or not hrp then return end

    -- Если мы не пытаемся идти (WASD не нажаты) — не трогаем физику
    if hum.MoveDirection.Magnitude <= 0 then return end

    -- 1. АВТОПРЫЖОК
    if hum.FloorMaterial ~= Enum.Material.Air then
        hum.Jump = true
    end

    -- 2. УБИРАЕМ ТРЕНИЕ (Legit Logic)
    -- Вместо силы 24, берем твою WalkSpeed
    local targetSpeed = hum.WalkSpeed * CONFIG.SpeedMulti
    local dir = hum.MoveDirection
    local currentY = hrp.AssemblyLinearVelocity.Y

    -- Обновляем скорость X и Z каждый кадр, чтобы не было торможения при приземлении
    hrp.AssemblyLinearVelocity = Vector3.new(dir.X * targetSpeed, currentY, dir.Z * targetSpeed)
end

function module:OnEnable()
    self.Enabled = true
    print("[Module] BHop Legit Enabled")
    
    -- Очистка старых коннектов на всякий случай
    if steppedConn then steppedConn:Disconnect() end
    
    -- Запускаем цикл
    steppedConn = RunService.RenderStepped:Connect(function()
        tickFrame(self)
    end)
end

function module:OnDisable()
    self.Enabled = false
    print("[Module] BHop Legit Disabled")
    
    if steppedConn then
        steppedConn:Disconnect()
        steppedConn = nil
    end
end

function module:Init() end
function module:OnTick(dt) end

return module
