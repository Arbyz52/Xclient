local module = {
    Name     = "GunSound",
    Category = "Visuals",
    Enabled  = false,
    _connections = {}
}

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer

-- ===== НАСТРОЙКИ =====
local MY_SOUND = "rbxassetid://5852470908" -- Твой ID
local VOL = 5 

-- ===== ЛОГИКА =====

-- Проверяем, принадлежит ли звук врагу
local function IsEnemySound(sound)
    -- 1. Если звук внутри Камеры - это точно НАШЕ оружие
    if sound:IsDescendantOf(Workspace.CurrentCamera) then
        return false 
    end

    -- 2. Если звук внутри НАШЕГО персонажа - это тоже мы
    if LP.Character and sound:IsDescendantOf(LP.Character) then
        return false 
    end

    -- 3. Идем вверх по родителям, ищем чужого Гуманоида
    local parent = sound.Parent
    while parent do
        if parent == game or parent == Workspace then break end

        if parent:IsA("Model") and parent:FindFirstChild("Humanoid") then
            if parent.Name ~= LP.Name then
                return true -- Это враг
            end
        end
        parent = parent.Parent
    end

    return false -- Ничей или наш
end

local function ForceSound(sound)
    -- Если модуль выключен, прекращаем менять
    if not module.Enabled then return end
    
    -- Проверка на дурака
    if sound.SoundId == MY_SOUND then return end

    -- ГЛАВНЫЙ ФИЛЬТР (Игнор врагов)
    if IsEnemySound(sound) then return end

    -- МЕНЯЕМ
    sound.SoundId = MY_SOUND
    sound.Volume = VOL
    
    -- print(">>> MY GUN CHANGED: " .. sound.Name)
end

local function Check(obj)
    -- Если модуль выключен, не проверяем
    if not module.Enabled then return end

    if obj:IsA("Sound") then
        local name = obj.Name:lower()
        
        -- Список имен выстрелов
        if name:find("fire") or name:find("shoot") or name:find("shot") or name:find("blast") or name:find("bang") or name:find("release") then
            
            -- Игнорируем хитмаркеры
            if name:find("hit") or name:find("head") or name:find("marker") then return end

            -- 1. Меняем
            ForceSound(obj)
            
            -- 2. Вечная защита (если игра пытается вернуть старый звук)
            local conn = obj:GetPropertyChangedSignal("SoundId"):Connect(function()
                if module.Enabled and obj.SoundId ~= MY_SOUND then
                    ForceSound(obj)
                end
            end)
            -- (Опционально) Можно сохранять этот conn, но для звуков это не критично
        end
    end
end

-- ===== МОДУЛЬНЫЕ МЕТОДЫ =====

function module:Init()
    self._connections = {}
end

function module:OnEnable()
    self.Enabled = true
    print("[GunSound] Enabled")

    -- 1. Сканируем игру (то, что уже есть)
    for _, v in ipairs(Workspace:GetDescendants()) do
        Check(v)
    end

    -- 2. Агрессивная глобальная слежка (то, что появляется)
    local conn = game.DescendantAdded:Connect(function(obj)
        Check(obj)
    end)
    
    -- Сохраняем подключение, чтобы отключить при выключении функции
    table.insert(module._connections, conn)
end

function module:OnDisable()
    self.Enabled = false
    print("[GunSound] Disabled")
    
    -- Отключаем глобальную слежку
    for _, conn in pairs(module._connections) do
        conn:Disconnect()
    end
    module._connections = {}
end

function module:OnTick(dt) end

return module
