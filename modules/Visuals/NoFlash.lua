local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

local module = {
    Name = "No Flash (Brute Force)",
    Category = "Visuals",
    Enabled = false,
}

-- Имена, по которым ищем гадость
local BAD_NAMES = {
    ["Flashbang"] = true,
    ["Blind"] = true,
    ["Flash"] = true,
    ["WhiteScreen"] = true,
    ["StunEffect"] = true,
    ["Blur"] = true,        -- Размытие
    ["ColorCorrection"] = true -- Цветокоррекция (иногда делает экран белым)
}

local steppedConn

-- Функция, которая УНИЧТОЖАЕТ видимость объекта, не удаляя его (чтобы игра не крашнулась)
local function nukeObject(obj)
    -- 1. GUI Элементы (Квадраты, Картинки)
    if obj:IsA("GuiObject") or obj:IsA("ScreenGui") then
        obj.Visible = false
        
        -- Если игра принудительно ставит Visible = true, эти параметры спасут:
        if obj:IsA("GuiObject") then
            obj.BackgroundTransparency = 1
            if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
                obj.ImageTransparency = 1
            end
            -- Убираем за пределы экрана и сжимаем
            obj.Position = UDim2.new(10, 0, 10, 0)
            obj.Size = UDim2.new(0, 0, 0, 0)
        end

    -- 2. Эффекты освещения (Lighting)
    elseif obj:IsA("PostEffect") then
        obj.Enabled = false
    end
end

local function loop()
    -- 1. Ищем в Lighting (Освещение)
    -- Некоторые игры делают экран белым через ColorCorrection
    for _, v in ipairs(Lighting:GetChildren()) do
        if BAD_NAMES[v.Name] or (v:IsA("ColorCorrectionEffect") and v.Brightness > 0.5) then
            nukeObject(v)
        end
    end

    -- 2. Ищем в PlayerGui (Интерфейс)
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if not gui then return end

    -- Пытаемся найти объект "Flashbang" рекурсивно.
    -- FindFirstChild(name, true) ищет во всех вложенных папках.
    local flash = gui:FindFirstChild("Flashbang", true)
    if flash then
        nukeObject(flash)
    end

    -- Проверяем другие имена, если Flashbang не найден
    local blind = gui:FindFirstChild("Blind", true)
    if blind then nukeObject(blind) end
    
    local white = gui:FindFirstChild("WhiteScreen", true)
    if white then nukeObject(white) end
end

function module:OnEnable()
    self.Enabled = true
    print("[NoFlash] Enabled (Loop Mode)")
    
    -- Запускаем проверку КАЖДЫЙ КАДР.
    -- Это перебивает скрипты игры. Даже если игра включит флешку, мы в том же кадре её выключим.
    steppedConn = RunService.RenderStepped:Connect(loop)
end

function module:OnDisable()
    self.Enabled = false
    print("[NoFlash] Disabled")
    
    if steppedConn then
        steppedConn:Disconnect()
        steppedConn = nil
    end
end

function module:Init() end
function module:OnTick(dt) end

return module
