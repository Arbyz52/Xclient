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

local steppedConn
local inputConn

-- Подсветка
local highlightGui
local highlightBox
local currentTarget = nil 

-- Создание красной рамки
local function createHighlight()
    if highlightGui then highlightGui:Destroy() end
    
    highlightGui = Instance.new("ScreenGui")
    highlightGui.Name = "RemoverHighlight"
    highlightGui.DisplayOrder = 10000 
    highlightGui.IgnoreGuiInset = true
    highlightGui.ResetOnSpawn = false
    
    -- Пытаемся засунуть в CoreGui (чтобы рамка была поверх всего), если нет прав - в PlayerGui
    pcall(function() highlightGui.Parent = CoreGui end)
    if not highlightGui.Parent then highlightGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    highlightBox = Instance.new("Frame")
    highlightBox.Parent = highlightGui
    highlightBox.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    highlightBox.BackgroundTransparency = 0.7
    highlightBox.BorderSizePixel = 2
    highlightBox.BorderColor3 = Color3.fromRGB(255, 255, 255)
    highlightBox.Visible = false
end

local function destroyHighlight()
    if highlightGui then 
        highlightGui:Destroy() 
        highlightGui = nil
        highlightBox = nil
    end
end

-- ФИЛЬТР: Проверяем, стоит ли удалять этот объект
local function isValidTarget(obj)
    if not obj.Visible then return false end
    if obj.Parent == highlightGui then return false end -- Не удалять саму подсветку
    
    -- Получаем размеры экрана
    local viewport = Camera.ViewportSize
    local objSize = obj.AbsoluteSize
    
    -- 1. Если объект прозрачный И занимает почти весь экран -> это мусорный контейнер, пропускаем
    if obj.BackgroundTransparency >= 0.95 then
        -- Если это Текст или Картинка - берем (даже если фон прозрачный)
        if obj:IsA("TextLabel") or obj:IsA("ImageLabel") or obj:IsA("ImageButton") or obj:IsA("TextButton") then
            return true
        end
        
        -- Если это просто Frame размером с экран - игнорируем
        if objSize.X >= viewport.X - 50 and objSize.Y >= viewport.Y - 50 then
            return false
        end
    end
    
    return true
end

-- Главный цикл
local function tickFrame()
    -- 1. СПАМ КУРСОРОМ (Чтобы игра не скрывала его)
    UserInputService.MouseIconEnabled = true
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default

    -- 2. ПОИСК ЭЛЕМЕНТА
    local mousePos = UserInputService:GetMouseLocation()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    
    currentTarget = nil
    
    if playerGui then
        local objects = playerGui:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y)
        
        for _, obj in ipairs(objects) do
            if isValidTarget(obj) then
                currentTarget = obj
                break -- Нашли верхний подходящий объект
            end
        end
    end

    -- 3. ОТРИСОВКА РАМКИ
    if currentTarget and highlightBox then
        highlightBox.Visible = true
        highlightBox.Size = UDim2.fromOffset(currentTarget.AbsoluteSize.X, currentTarget.AbsoluteSize.Y)
        highlightBox.Position = UDim2.fromOffset(currentTarget.AbsolutePosition.X, currentTarget.AbsolutePosition.Y)
    elseif highlightBox then
        highlightBox.Visible = false
    end
end

local function onInput(input, gp)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if currentTarget then
            -- Скрываем объект
            pcall(function() currentTarget.Visible = false end)
            print("[UI Remover] Hidden: " .. currentTarget.Name)
            
            -- Выключаем модуль
            module:OnDisable()
        else
            -- Если кликнули в пустоту, тоже выключаем, чтобы не застрять
            -- (Закомментируй строчку ниже, если хочешь кликать пока не попадешь)
            -- module:OnDisable() 
        end
    end
end

function module:OnEnable()
    self.Enabled = true
    print("[UI Remover] ON. Click RED highlighted UI to remove.")
    createHighlight()

    if steppedConn then steppedConn:Disconnect() end
    steppedConn = RunService.RenderStepped:Connect(tickFrame)

    if inputConn then inputConn:Disconnect() end
    inputConn = UserInputService.InputBegan:Connect(onInput)
end

function module:OnDisable()
    self.Enabled = false
    
    if steppedConn then steppedConn:Disconnect() steppedConn = nil end
    if inputConn then inputConn:Disconnect() inputConn = nil end
    
    destroyHighlight()

    -- Возвращаем управление игрой
    UserInputService.MouseIconEnabled = false
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    
    print("[UI Remover] OFF")
end

function module:Init() end
function module:OnTick(dt) end

return module
