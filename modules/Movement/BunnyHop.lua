-- modules/Movement/BunnyHop.lua
local Players            = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")

local LocalPlayer        = Players.LocalPlayer

local module = {
    Name     = "BunnyHop",
    Category = "Movement",
    Enabled  = false,
}

-- Конфиг (легит: удерживаешь Space — подпрыгиваешь без стопа скорости)
local CONFIG = {
    HoldKey           = Enum.KeyCode.Space, -- удерживай пробел
    PreserveFactor    = 1.00,               -- 1.00 = сохраняем скорость как есть (легит)
    MinSpeedToPreserve= 2.0,                -- не трогаем скорость, если почти стоим
    Cooldown          = 0.08,               -- минимальный интервал между прыжками (сек), чтобы не спамить
}

local holding = false
local lastHop = 0
local inputBeganConn, inputEndedConn

local function getChar()
    local char = LocalPlayer and LocalPlayer.Character
    if not char then return nil,nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return nil,nil end
    return hum, hrp
end

-- Аккуратный прыжок без стопа горизонтальной скорости
local function doBhop(hum, hrp)
    -- Проверяем землю
    if hum.FloorMaterial == Enum.Material.Air then return end

    -- Небольшой анти-спам
    local now = tick()
    if (now - lastHop) < CONFIG.Cooldown then return end
    lastHop = now

    -- Сохраняем направление
    local moveDir = hum.MoveDirection
    -- Форсим прыжок легально
    hum:ChangeState(Enum.HumanoidStateType.Jumping)

    -- Через следующий кадр корректно восстановим горизонтальную скорость
    -- чтобы не бороться с внутренним апдейтом Humanoid
    task.spawn(function()
        RunService.RenderStepped:Wait()
        if not hrp.Parent then return end

        local v = hrp.Velocity
        local horizSpeed = Vector3.new(v.X, 0, v.Z).Magnitude
        if horizSpeed >= CONFIG.MinSpeedToPreserve then
            local horizDir = Vector3.new(v.X, 0, v.Z).Unit
            local preserved = horizDir * (horizSpeed * CONFIG.PreserveFactor)
            -- Сохраняем Y из текущей вертикали, горизонталь переписываем
            hrp.Velocity = Vector3.new(preserved.X, hrp.Velocity.Y, preserved.Z)
        else
            -- Если стоим, толкнём лёгкий импульс по MoveDirection, выглядит легитно
            if moveDir.Magnitude > 0 then
                local push = (moveDir.Unit * 10)
                hrp.Velocity = Vector3.new(push.X, hrp.Velocity.Y, push.Z)
            end
        end
    end)
end

function module:OnEnable()
    self.Enabled = true

    -- Подписки на ввод с безопасным снятием при Disable
    inputBeganConn = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == CONFIG.HoldKey then
            holding = true
        end
    end)
    inputEndedConn = UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == CONFIG.HoldKey then
            holding = false
        end
    end)
end

function module:OnDisable()
    self.Enabled = false
    holding = false
    if inputBeganConn then inputBeganConn:Disconnect() inputBeganConn = nil end
    if inputEndedConn then inputEndedConn:Disconnect() inputEndedConn = nil end
end

function module:Init()
    -- Ничего критичного, но можем подготовить имя с подсказкой:
    -- self.Name = "BunnyHop (Space)"
end

function module:OnTick(dt)
    if not self.Enabled or not holding then return end
    local hum, hrp = getChar()
    if not hum or not hrp then return end
    doBhop(hum, hrp)
end

return module
