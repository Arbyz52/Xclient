-- modules/Movement/BunnyHop.lua
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local VERSION = "BunnyHop v3.1 (No Friction)"
print("[Module] Loaded: " .. VERSION)

local module = {
    Name     = "BunnyHop (Space)",
    Category = "Movement",
    Enabled  = false,
}

local CONFIG = {
    HoldKey    = Enum.KeyCode.Space,
    SpeedMulti = 1.0, -- 1.0 = обычная скорость, 1.1 = немного быстрее
}

local holding = false
local inputBeganConn, inputEndedConn, steppedConn

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
    -- Если мы не пытаемся двигаться (WASD), ничего не делаем
    if hum.MoveDirection.Magnitude <= 0 then return end

    -- 1. АВТОПРЫЖОК: Если касаемся земли - прыгаем
    if hum.FloorMaterial ~= Enum.Material.Air then
        hum.Jump = true
    end

    -- 2. УБИРАЕМ ТОРМОЖЕНИЕ:
    -- Берем текущую скорость ходьбы (WalkSpeed)
    local targetSpeed = hum.WalkSpeed * CONFIG.SpeedMulti
    local dir = hum.MoveDirection
    
    -- Сохраняем текущую вертикальную скорость (Y), чтобы гравитация работала нормально
    local currentY = hrp.AssemblyLinearVelocity.Y
    
    -- Принудительно устанавливаем скорость по горизонтали.
    -- Это выполняется каждый кадр, поэтому трение земли не успевает остановить персонажа.
    hrp.AssemblyLinearVelocity = Vector3.new(dir.X * targetSpeed, currentY, dir.Z * targetSpeed)
end

function module:OnEnable()
    self.Enabled = true
    
    -- Отслеживаем нажатие клавиши (через ивенты, как в твоем примере)
    inputBeganConn = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == CONFIG.HoldKey then holding = true end
    end)
    
    inputEndedConn = UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == CONFIG.HoldKey then holding = false end
    end)

    -- Главный цикл
    steppedConn = RunService.RenderStepped:Connect(function()
        -- Работаем только если модуль включен и кнопка зажата
        if not self.Enabled or not holding then return end
        
        local hum, hrp = getChar()
        if hum and hrp then
            processBhop(hum, hrp)
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
