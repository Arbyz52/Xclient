-- modules/Movement/BunnyHop.lua
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local VERSION = "BunnyHop v3.2 (No Friction - Fixed)"
print("[Module] Loaded: " .. VERSION)

local module = {
    Name     = "BunnyHop Legit",
    Category = "Movement",
    Enabled  = false,
}

local CONFIG = {
    HoldKey    = Enum.KeyCode.Space,
    SpeedMulti = 1.05, -- 1.0 = скорость бега, 1.05 = чуть быстрее для плавности
}

local steppedConn

-- Аккуратный геттер персонажа
local function getChar()
    local char = LocalPlayer.Character
    if not char then return nil, nil end
    local hum = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return nil, nil end
    return hum, hrp
end

-- Основная логика, вызывается каждый кадр
local function tickFrame(self)
    -- Если модуль выключен или кнопка не зажата, ничего не делаем
    if not self.Enabled or not UserInputService:IsKeyDown(CONFIG.HoldKey) then
        return
    end

    local hum, hrp = getChar()
    if not hum or not hrp then return end

    -- Работаем только если игрок пытается двигаться
    local dir = hum.MoveDirection
    if dir.Magnitude <= 0 then return end

    -- 1. АВТОПРЫЖОК: Если на земле - прыгаем
    if hum.FloorMaterial ~= Enum.Material.Air then
        hum.Jump = true
    end

    -- 2. УБИРАЕМ ТРЕНИЕ (Сохранение скорости)
    -- Эта часть теперь выполняется КАЖДЫЙ КАДР, пока зажат пробел,
    -- как на земле, так и в воздухе, что и создает эффект "отсутствия трения".
    local targetSpeed = hum.WalkSpeed * CONFIG.SpeedMulti
    local currentVelocity = hrp.AssemblyLinearVelocity

    -- Принудительно устанавливаем горизонтальную скорость, но СОХРАНЯЕМ текущую вертикальную.
    -- Это и есть ключ к исправлению: мы не мешаем прыжку и гравитации.
    hrp.AssemblyLinearVelocity = Vector3.new(
        dir.X * targetSpeed,
        currentVelocity.Y, -- <-- Сохраняем Y!
        dir.Z * targetSpeed
    )
end

function module:OnEnable()
    self.Enabled = true
    print("[Module] Legit BHop Enabled")

    -- Просто подключаем основной цикл к RenderStepped
    if steppedConn then steppedConn:Disconnect() end
    steppedConn = RunService.RenderStepped:Connect(function()
        tickFrame(self)
    end)
end

function module:OnDisable()
    self.Enabled = false
    print("[Module] Legit BHop Disabled")

    if steppedConn then
        steppedConn:Disconnect()
        steppedConn = nil
    end
end

-- Пустые функции для совместимости с лоадером
function module:Init() end
function module:OnTick(dt) end

return module
