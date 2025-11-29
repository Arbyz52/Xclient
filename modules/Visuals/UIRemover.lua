local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local module = {
    Name = "UI Remover",
    Category = "Visuals",
    Enabled = false, 
}

-- ===== ВИЗУАЛЫ =====
local guiLayer
local highlightBox
local fakeCursor -- Наш собственный курсор
local currentTarget = nil 

-- Черный список имен, которые мы игнорируем (оверлеи)
local IGNORE_NAMES = {
    ["Flashbang"] = true,
    ["Blind"] = true,
    ["Vignette"] = true,
    ["Crosshairs"] = true, -- Если не хочешь удалять прицел случайно
    ["Container"] = true,
    ["Blood"] = true,
}

local function createVisuals()
    if guiLayer then guiLayer:Destroy() end
    
    guiLayer = Instance.new("ScreenGui")
    guiLayer.Name = "RemoverVisuals"
    guiLayer.DisplayOrder = 10000 
    guiLayer.IgnoreGuiInset = true
    guiLayer.ResetOnSpawn = false
    
    pcall(function() guiLayer.Parent = CoreGui end)
    if not guiLayer.Parent then guiLayer.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    -- 1. КРАСНАЯ РАМКА (Выделение)
    highlightBox = Instance.new("Frame")
    highlightBox.Parent = guiLayer
    highlightBox.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    highlightBox.BackgroundTransparency = 0.6
    highlightBox.BorderSizePixel = 2
    highlightBox.BorderColor3 = Color3.fromRGB(255, 255, 255)
    highlightBox.Visible = false
    highlightBox.ZIndex = 1

    -- 2. ФЕЙКОВЫЙ КУРСОР (Красная точка)
    fakeCursor = Instance.new("Frame")
    fakeCursor.Name = "FakeCursor"
    fakeCursor.Parent = guiLayer
    fakeCursor.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Зеленый, чтобы было видно
    fakeCursor.Size = UDim2.fromOffset(8, 8)
    fakeCursor.AnchorPoint = Vector2.new(0.5, 0.5)
    fakeCursor.Visible = true
    fakeCursor.ZIndex = 2
    
    -- Делаем его круглым
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = fakeCursor
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 0, 0)
    stroke.Thickness = 1
    stroke.Parent = fakeCursor
end

local function destroyVisuals()
    if guiLayer then 
        guiLayer:Destroy() 
        guiLayer = nil
        highlightBox = nil
        fakeCursor = nil
    end
end

-- ПРОВЕРКА: Важный ли это элемент или мусор (оверлей)
local function isValidTarget(obj)
    if not obj.Visible then return false end
    if obj:IsDescendantOf(guiLayer) then return false end -- Не выделять наш курсор
    
    -- Игнорируем по имени (Флешки, Кровь и т.д.)
    if IGNORE_NAMES[obj.Name] then return false end

    local viewport = Camera.ViewportSize
    local objSize = obj.AbsoluteSize
    
    -- Если объект полностью прозрачный
    if obj.BackgroundTransparency >= 0.98 then
        -- Но это картинка или текст -> БЕРЕМ (это иконка оружия)
        if obj:IsA("ImageLabel") or obj:IsA("ImageButton") or obj:IsA("TextLabel") or obj:IsA("TextButton") then
            return true
        end
        
        -- Если это просто пустой Frame -> ИГНОРИРУЕМ (скорее всего контейнер)
        return false
    end
    
    -- Если объект огромный (на весь экран) и прозрачный -> ИГНОРИРУЕМ
    if objSize.X >= viewport.X - 20 and objSize.Y >= viewport.Y - 20 then
        return false
    end
    
    return true
end

-- ===== ЛОГИКА =====
local steppedConn
local inputConn

local function tickFrame()
    -- Двигаем наш фейковый курсор за реальной мышкой
    local mousePos = UserInputService:GetMouseLocation()
    
    if fakeCursor then
        fakeCursor.Position = UDim2.fromOffset(mousePos.X, mousePos.Y)
    end

    -- Ищем элемент под курсором
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    currentTarget = nil
    
    if playerGui then
        -- Получаем ВСЕ объекты под точкой
        local objects = playerGui:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y)
        
        for _, obj in ipairs(objects) do
            if isValidTarget(obj) then
                currentTarget = obj
                break -- Нашли первый нормальный объект (не флешку)
            end
        end
    end

    -- Обновляем красную рамку
    if currentTarget and highlightBox then
        highlightBox.Visible = true
        highlightBox.Size = UDim2.fromOffset(currentTarget.AbsoluteSize.X, currentTarget.AbsoluteSize.Y)
        highlightBox.Position = UDim2.fromOffset(currentTarget.AbsolutePosition.X, currentTarget.AbsolutePosition.Y)
    elseif highlightBox then
        highlightBox.Visible = false
    end
end

local function onInput(input, gp)
    -- Клик ЛКМ
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if currentTarget then
            -- Скрываем
            pcall(function() currentTarget.Visible = false end)
            print("[UI Remover] HIDDEN: " .. currentTarget.Name)
            
            -- Выключаем скрипт
            module:OnDisable()
        else
            -- Если кликнули в пустоту
            print("[UI Remover] Clicked nothing valid")
            -- Можно раскомментировать, если хочешь выключать при промахе:
            -- module:OnDisable()
        end
    end
end

function module:OnEnable()
    self.Enabled = true
    print("[UI Remover] ON. Look for the GREEN DOT.")
    
    createVisuals()

    -- Запускаем цикл
    if steppedConn then steppedConn:Disconnect() end
    steppedConn = RunService.RenderStepped:Connect(tickFrame)

    -- Слушаем клик
    if inputConn then inputConn:Disconnect() end
    inputConn = UserInputService.InputBegan:Connect(onInput)
end

function module:OnDisable()
    self.Enabled = false
    
    if steppedConn then steppedConn:Disconnect() steppedConn = nil end
    if inputConn then inputConn:Disconnect() inputConn = nil end
    
    destroyVisuals()
    print("[UI Remover] OFF")
end

function module:Init() end
function module:OnTick(dt) end

return module
