local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

local module = {
    Name = "No Flash",
    Category = "Visuals",
    Enabled = false,
}

-- Список названий, которые используются для эффекта слепоты
local FLASH_NAMES = {
    ["Flashbang"] = true,  -- То, что было у тебя в логах
    ["Blind"] = true,
    ["Flash"] = true,
    ["WhiteScreen"] = true,
    ["StunEffect"] = true,
}

local connections = {}
local monitoredObjects = {} -- Объекты, за которыми мы следим

-- Функция отключения конкретного объекта
local function disableObject(obj)
    if not obj then return end
    
    -- Если это GUI (картинка/рамка)
    if obj:IsA("GuiObject") or obj:IsA("ScreenGui") then
        obj.Visible = false
        obj.Transparency = 1 -- На случай, если игра принудительно включает Visible
        
    -- Если это эффект в Lighting (ColorCorrection, Blur)
    elseif obj:IsA("PostEffect") then
        obj.Enabled = false
    end
end

-- Проверка объекта: является ли он флешкой?
local function checkObject(obj)
    if FLASH_NAMES[obj.Name] then
        -- Отключаем сейчас
        disableObject(obj)
        
        -- И подписываемся на изменения, чтобы игра не включила его обратно
        if not monitoredObjects[obj] then
            monitoredObjects[obj] = obj:GetPropertyChangedSignal("Visible"):Connect(function()
                if module.Enabled then 
                    obj.Visible = false 
                end
            end)
            
            -- Дополнительная страховка для Lighting
            if obj:IsA("PostEffect") then
                monitoredObjects[obj] = obj:GetPropertyChangedSignal("Enabled"):Connect(function()
                    if module.Enabled then obj.Enabled = false end
                end)
            end
            
            print("[NoFlash] Disabled effect: " .. obj.Name)
        end
    end
end

-- Сканирование всего интерфейса (запускается один раз при включении)
local function scanAll()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        -- Используем GetDescendants, чтобы найти флешку, даже если она глубоко в папках
        for _, v in ipairs(playerGui:GetDescendants()) do
            checkObject(v)
        end
    end
    
    -- Сканируем Lighting
    for _, v in ipairs(Lighting:GetChildren()) do
        checkObject(v)
    end
end

function module:OnEnable()
    self.Enabled = true
    print("[NoFlash] Enabled")
    
    -- 1. Сканируем то, что уже есть
    scanAll()
    
    -- 2. Слушаем новые объекты в PlayerGui (на случай, если флешка создается при взрыве)
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    table.insert(connections, playerGui.DescendantAdded:Connect(checkObject))
    
    -- 3. Слушаем новые эффекты в Lighting
    table.insert(connections, Lighting.ChildAdded:Connect(checkObject))
    
    -- 4. ЖЕСТКИЙ ЦИКЛ (Страховка)
    -- Каждую секунду проверяем, не появилось ли чего, если ивенты не сработали
    table.insert(connections, RunService.RenderStepped:Connect(function()
        if math.random() > 0.95 then -- Не каждый кадр, чтобы не лагало, но часто
            local gui = LocalPlayer:FindFirstChild("PlayerGui")
            if gui then
                -- Проверяем самые частые места
                local flash = gui:FindFirstChild("Flashbang", true) -- Рекурсивный поиск
                if flash then disableObject(flash) end
            end
        end
    end))
end

function module:OnDisable()
    self.Enabled = false
    print("[NoFlash] Disabled")
    
    -- Отключаем все следилки
    for _, conn in ipairs(connections) do
        conn:Disconnect()
    end
    connections = {}
    
    for _, conn in pairs(monitoredObjects) do
        conn:Disconnect()
    end
    monitoredObjects = {}
end

function module:Init() end
function module:OnTick(dt) end

return module
