-- modules/Movement/BunnyHopBoost.lua
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local VERSION = "BunnyHop v2.1 (Fixed Force)"
print("[Module] Loaded: " .. VERSION)

local module = {
    Name     = "BunnyHop RAGE",
    Category = "Movement",
    Enabled  = false,
}

-- Настройки из твоего скрипта
local CONFIG = {
    HoldKey    = Enum.KeyCode.Space,
    BoostForce = 24,  -- Сила ускорения (как было 24)
    MinY       = 1.5, -- Порог для определения прыжка
}

local holding = false
local inputBeganConn, inputEndedConn, steppedConn

-- Получение персонажа
local function getChar()
    local char = LocalPlayer.Character
    if not char then return nil, nil end
    local hum = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return nil, nil end
    return hum, hrp
end

-- Основная логика (из твоего RenderStepped)
local function processLogic(hum, hrp)
    -- 1. АВТОПРЫЖОК
    -- Если мы на земле и держим кнопку -> прыгаем
    if hum.FloorMaterial ~= Enum.Material.Air then
        hum.Jump = true
    end

    -- 2. УСКОРЕНИЕ (Velocity Boost)
    local v = hrp.AssemblyLinearVelocity
    
    -- Проверяем, в воздухе ли мы (по скорости Y или материалу)
    local isJumping = math.abs(v.Y) > CONFIG.MinY or hum.FloorMaterial == Enum.Material.Air

    if isJumping then
        local dir = hum.MoveDirection
        -- Применяем ускорение только если игрок нажимает WASD
        if dir.Magnitude > 0 then
            local push = dir.Unit * CONFIG.BoostForce
            -- Сохраняем Y (вертикальную скорость), меняем X и Z на фиксированную силу 24
            hrp.AssemblyLinearVelocity = Vector3.new(push.X, v.Y, push.Z)
        end
    end
end

function module:OnEnable()
    self.Enabled = true
    
    -- Слушаем нажатие клавиши
    inputBeganConn = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == CONFIG.HoldKey then holding = true end
    end)
    
    -- Слушаем отпускание клавиши
    inputEndedConn = UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == CONFIG.HoldKey then holding = false end
    end)

    -- Цикл каждый кадр
    steppedConn = RunService.RenderStepped:Connect(function()
        -- Выполняем код только если модуль включен И кнопка зажата
        if not self.Enabled or not holding then return end
        
        local hum, hrp = getChar()
        if hum and hrp then
            processLogic(hum, hrp)
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
