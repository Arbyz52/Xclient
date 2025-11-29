-- modules/Movement/BunnyHop.lua
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- ==================== Версия ====================
local VERSION = "BunnyHop v1.1.0"
print("[Module] Loaded: " .. VERSION)

local module = {
    Name     = "BunnyHop (Space)",
    Category = "Movement",
    Enabled  = false,
}

-- ==================== КОНФИГ ====================
local CONFIG = {
    HoldKey        = Enum.KeyCode.Space, -- удерживай пробел для авто-хопа
    PushForce      = 26,                 -- легитный импульс по MoveDirection после прыжка
    PreserveFactor = 1.00,               -- сколько сохранять горизонтальную скорость
    MinPreserve    = 2.5,                -- если скорость ниже — делаем мягкий толчок вместо сохранения
    LandHopDelay   = 0.00,               -- задержка перед прыжком после приземления (0 выглядит наиболее стабильным)
    Cooldown       = 0.085,              -- анти-спам между хопами
}

-- ==================== Состояния ====================
local holding = false
local lastHop = 0
local inputBeganConn, inputEndedConn, stateConn, steppedConn

-- Кэш персонажа
local function getChar()
    local char = LocalPlayer.Character
    if not char then return nil,nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return nil,nil end
    return hum, hrp
end

-- Сохранить/приподнять горизонтальную скорость безопасно
local function preserveHorizontal(hrp, hum)
    local v = hrp.AssemblyLinearVelocity
    local horiz = Vector3.new(v.X, 0, v.Z)
    local speed = horiz.Magnitude

    if speed >= CONFIG.MinPreserve then
        local dir = horiz.Unit
        local preserved = dir * (speed * CONFIG.PreserveFactor)
        hrp.AssemblyLinearVelocity = Vector3.new(preserved.X, v.Y, preserved.Z)
    else
        local moveDir = hum.MoveDirection
        if moveDir.Magnitude > 0 then
            local push = moveDir.Unit * CONFIG.PushForce
            hrp.AssemblyLinearVelocity = Vector3.new(push.X, v.Y, push.Z)
        end
    end
end

-- Выполнить прыжок + восстановить горизонталь
local function hop(hum, hrp)
    local now = tick()
    if (now - lastHop) < CONFIG.Cooldown then return end
    lastHop = now

    -- форсим прыжок
    hum:ChangeState(Enum.HumanoidStateType.Jumping)

    -- на следующем кадре корректно восстанавливаем горизонталь
    task.spawn(function()
        RunService.RenderStepped:Wait()
        if hrp and hrp.Parent then
            preserveHorizontal(hrp, hum)
        end
    end)
}

-- ==================== Методы модуля ====================
function module:OnEnable()
    self.Enabled = true

    -- ввод
    inputBeganConn = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == CONFIG.HoldKey then
            holding = true
            -- если уже стоим на земле — сразу стартовый хоп
            local hum, hrp = getChar()
            if hum and hrp and hum.FloorMaterial ~= Enum.Material.Air then
                hop(hum, hrp)
            end
        end
    end)

    inputEndedConn = UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == CONFIG.HoldKey then
            holding = false
        end
    end)

    -- приземление -> новый прыжок
    local hum, hrp = getChar()
    if hum and hrp then
        stateConn = hum.StateChanged:Connect(function(_, new)
            if not self.Enabled then return end
            if holding and new == Enum.HumanoidStateType.Landed then
                if CONFIG.LandHopDelay > 0 then
                    task.delay(CONFIG.LandHopDelay, function()
                        if self.Enabled and holding then
                            hop(hum, hrp)
                        end
                    end)
                else
                    hop(hum, hrp)
                end
            end
        end)
    end

    -- легкая корректировка скорости на каждом кадре при удержании (сглаживает стоп)
    steppedConn = RunService.RenderStepped:Connect(function()
        if not self.Enabled or not holding then return end
        local hum2, hrp2 = getChar()
        if not hum2 or not hrp2 then return end
        -- если на земле — поддерживаем горизонталь, чтобы не было резкого стопа
        if hum2.FloorMaterial ~= Enum.Material.Air then
            preserveHorizontal(hrp2, hum2)
        end
    end)
end

function module:OnDisable()
    self.Enabled = false
    holding = false
    if inputBeganConn then inputBeganConn:Disconnect() inputBeganConn = nil end
    if inputEndedConn then inputEndedConn:Disconnect() inputEndedConn = nil end
    if stateConn then stateConn:Disconnect() stateConn = nil end
    if steppedConn then steppedConn:Disconnect() steppedConn = nil end
end

function module:Init() end
function module:OnTick(dt) end

return module
