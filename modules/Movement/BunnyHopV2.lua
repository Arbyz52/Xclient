-- modules/Movement/BunnyHopBoost.lua
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local module = {
    Name     = "BunnyHop RAGE",
    Category = "Movement",
    Enabled  = false, -- По умолчанию выключено
}

local CONFIG = {
    HoldKey    = Enum.KeyCode.Space,
    BoostForce = 24,  -- Твоя сила ускорения
    MinY       = 1.5, -- Порог прыжка
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

function module:OnEnable()
    self.Enabled = true
    print("[Module] BHop Enabled")

    -- Запускаем цикл, который работает каждый кадр
    steppedConn = RunService.RenderStepped:Connect(function()
        -- 1. Если модуль выключен - останавливаем работу
        if not self.Enabled then return end

        -- 2. ПРЯМАЯ ПРОВЕРКА: Зажат ли пробел прямо сейчас?
        -- Это надежнее, чем ловить события нажатия/отжатия
        if not UserInputService:IsKeyDown(CONFIG.HoldKey) then 
            return -- Если пробел не нажат, выходим и ничего не делаем
        end

        local hum, hrp = getChar()
        if not hum or not hrp then return end

        -- === ТВОЯ ЛОГИКА ===
        
        -- АВТОПРЫЖОК: Если на земле -> прыжок
        if hum.FloorMaterial ~= Enum.Material.Air then
            hum.Jump = true
        end

        -- БУСТ: Если в воздухе и двигаемся -> даем скорость 24
        local v = hrp.AssemblyLinearVelocity
        local isJumping = math.abs(v.Y) > CONFIG.MinY or hum.FloorMaterial == Enum.Material.Air

        if isJumping then
            local dir = hum.MoveDirection
            if dir.Magnitude > 0 then
                local push = dir.Unit * CONFIG.BoostForce
                -- Сохраняем Y, меняем X и Z
                hrp.AssemblyLinearVelocity = Vector3.new(push.X, v.Y, push.Z)
            end
        end
    end)
end

function module:OnDisable()
    self.Enabled = false
    print("[Module] BHop Disabled")
    
    -- Отключаем цикл, чтобы не грузить игру
    if steppedConn then 
        steppedConn:Disconnect() 
        steppedConn = nil 
    end
end

function module:Init() 
    -- Функция инициализации (если нужна загрузчику)
end

function module:OnTick(dt) 
    -- Если твой загрузчик вызывает OnTick вместо RenderStepped, можно перенести логику сюда
end

return module
