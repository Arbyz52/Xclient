-- modules/Movement/BunnyHopV2.lua

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local module = {
    Name = "BunnyHop RAGE",
    Category = "Movement",
    Enabled = false, -- По умолчанию выключено
}

local CONFIG = {
    HoldKey   = Enum.KeyCode.Space,
    BoostForce = 24,   -- Сила ускорения
    MinY       = 1.5,  -- Порог прыжка
}

-- Коннекты, чтобы правильно отключать
local steppedConn
local charAddedConn

-- Аккуратный геттер персонажа
local function getChar()
    local char = LocalPlayer.Character
    if not char then return nil, nil end
    local hum = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return nil, nil end
    return hum, hrp
end

-- Основная логика кадра (вызывается из RenderStepped)
local function tickFrame(self)
    -- Если модуль выключен — не делаем ничего
    if not self.Enabled then return end

    -- Прямой опрос клавиши (надёжнее, чем события)
    if not UserInputService:IsKeyDown(CONFIG.HoldKey) then return end

    local hum, hrp = getChar()
    if not hum or not hrp then return end

    -- Автопрыжок: если не воздух — инициируем прыжок
    if hum.FloorMaterial ~= Enum.Material.Air then
        hum.Jump = true
    end

    -- Буст: в воздухе и есть MoveDirection
    local v = hrp.AssemblyLinearVelocity
    local isJumping = math.abs(v.Y) > CONFIG.MinY or hum.FloorMaterial == Enum.Material.Air

    if isJumping then
        local dir = hum.MoveDirection
        if dir.Magnitude > 0 then
            local push = dir.Unit * CONFIG.BoostForce
            -- Сохраняем Y, меняем X/Z
            hrp.AssemblyLinearVelocity = Vector3.new(push.X, v.Y, push.Z)
        end
    end
end

-- Подключаем кадр и респавн-хэндлер
local function attach(self)
    -- Анти-дупликат: если уже есть — не создаём
    if steppedConn then steppedConn:Disconnect() steppedConn = nil end
    if charAddedConn then charAddedConn:Disconnect() charAddedConn = nil end

    -- Рендер-цикл
    steppedConn = RunService.RenderStepped:Connect(function()
        tickFrame(self)
    end)

    -- Чтобы после смерти логика продолжала работать (HRP/Humanoid могут быть nil мгновенно)
    charAddedConn = LocalPlayer.CharacterAdded:Connect(function()
        -- Ничего дополнительно не нужно: tickFrame всегда проверяет текущий char
        -- Но оставляем хук, чтобы при необходимости доинициализировать.
        -- print("[BunnyHop] Character reloaded")
    end)
end

function module:OnEnable()
    self.Enabled = true
    print("[Module] BHop Enabled")
    attach(self)
end

function module:OnDisable()
    self.Enabled = false
    print("[Module] BHop Disabled")

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
    -- Если лоадер требует явную инициализацию — можно оставить пусто.
    -- Здесь ничего не делаем: всё поднимается в OnEnable.
end

function module:OnTick(dt)
    -- Если твой лоадер дергает OnTick вместо RenderStepped — можно использовать общий tickFrame.
    -- Но чтобы не было двойной логики, по умолчанию ничего не делаем.
    -- Пример, если потребуется:
    -- tickFrame(self)
end

return module
