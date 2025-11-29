local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

local module = {
    Name = "No Flash (Destroyer)",
    Category = "Visuals",
    Enabled = false,
}

local steppedConn

-- Список имен, которые мы БУДЕМ УДАЛЯТЬ
local BAD_GUI_NAMES = {
    ["Flashbang"] = true,
    ["Blind"] = true,
    ["Flash"] = true,
    ["WhiteScreen"] = true,
    ["Stun"] = true,
}

local function cleanLighting()
    -- Проходимся по эффектам освещения
    for _, effect in ipairs(Lighting:GetChildren()) do
        -- Если это Цветокоррекция и она делает экран белым (Яркость или Контраст выкручены)
        if effect:IsA("ColorCorrectionEffect") then
            if effect.Brightness > 0.2 or effect.Contrast > 0.5 then
                effect:Destroy() -- Удаляем эффект
            end
        end
        
        -- Если это Размытие (Blur)
        if effect:IsA("BlurEffect") then
            effect:Destroy()
        end
    end
end

local function cleanGui()
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if not gui then return end
    
    -- Мы ищем ВООБЩЕ ВЕЗДЕ (рекурсивно)
    for _, v in ipairs(gui:GetDescendants()) do
        if BAD_GUI_NAMES[v.Name] then
            v:Destroy() -- УДАЛЯЕМ БЕЗ ЖАЛОСТИ
        end
        
        -- Дополнительная проверка: Если это БЕЛЫЙ КВАДРАТ на весь экран
        if v:IsA("Frame") and v.Visible == true then
            -- Проверяем, белый ли он
            if v.BackgroundColor3.R > 0.9 and v.BackgroundColor3.G > 0.9 and v.BackgroundColor3.B > 0.9 then
                -- Проверяем, непрозрачный ли он
                if v.BackgroundTransparency < 0.5 then
                    -- Проверяем, большой ли он (больше 500 пикселей)
                    if v.AbsoluteSize.X > 800 and v.AbsoluteSize.Y > 600 then
                         -- Это точно флешка (белая стена), удаляем
                         v:Destroy()
                    end
                end
            end
        end
    end
end

function module:OnEnable()
    self.Enabled = true
    print("[NoFlash] Enabled - DESTROY MODE")
    
    -- Запускаем очистку КАЖДЫЙ КАДР
    steppedConn = RunService.RenderStepped:Connect(function()
        cleanLighting() -- Чистим свет (если белый экран от яркости)
        cleanGui()      -- Чистим интерфейс (если белый экран от картинки)
    end)
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
