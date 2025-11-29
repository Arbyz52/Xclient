local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local module = {
    Name = "UI Remover",
    Category = "Visuals",
    Enabled = false, 
}

local steppedConn
local inputConn

-- Переменные для подсветки
local highlightGui
local highlightBox
local currentTarget = nil -- То, на что мы сейчас смотрим

-- Создаем рамку выделения (чтобы ты видел, что удаляешь)
local function createHighlight()
    if highlightGui then highlightGui:Destroy() end
    
    highlightGui = Instance.new("ScreenGui")
    highlightGui.Name = "RemoverHighlight"
    highlightGui.DisplayOrder = 10000 -- Поверх всего
    highlightGui.IgnoreGuiInset = true
    -- Пытаемся засунуть в CoreGui (чтобы не удалялось вместе с UI), если не выйдет - в PlayerGui
    pcall(function() highlightGui.Parent = CoreGui end)
    if not highlightGui.Parent then highlightGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    highlightBox = Instance.new("Frame")
    highlightBox.Parent = highlightGui
    highlightBox.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    highlightBox.BackgroundTransparency = 0.6
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

-- Главная логика (каждый кадр)
local function tickFrame()
    -- 1. АГРЕССИВНО РАЗБЛОКИРУЕМ КУРСОР
    -- Делаем это каждый кадр, иначе игра заберет мышку обратно
    UserInputService.MouseIconEnabled = true
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default

    -- 2. ИЩЕМ ЭЛЕМЕНТ ПОД МЫШКОЙ
    local mousePos = UserInputService:GetMouseLocation()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    
    currentTarget = nil
    
    if playerGui then
        -- Получаем список всех GUI под курсором
        local objects = playerGui:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y)
        
        for _, obj in ipairs(objects) do
            -- Фильтруем: нам нужны только видимые элементы, и это не должна быть наша подсветка
            if obj.Visible and obj.Transparency < 1 and obj.Parent ~= highlightGui then
                -- Не удаляем корневые ScreenGui, ищем кнопки, картинки, рамки
                if obj:IsA("GuiObject") then
                    currentTarget = obj
                    break -- Берем самый верхний
                end
            end
        end
    end

    -- 3. ОБНОВЛЯЕМ ПОДСВЕТКУ
    if currentTarget and highlightBox then
        highlightBox.Visible = true
        highlightBox.Size = UDim2.fromOffset(currentTarget.AbsoluteSize.X, currentTarget.AbsoluteSize.Y)
        highlightBox.Position = UDim2.fromOffset(currentTarget.AbsolutePosition.X, currentTarget.AbsolutePosition.Y)
    elseif highlightBox then
        highlightBox.Visible = false
    end
end

-- Обработка клика
local function onInput(input, gp)
    -- Если нажали ЛКМ и у нас есть цель
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if currentTarget then
            pcall(function()
                currentTarget.Visible = false
            end)
            print("[UI Remover] Deleted: " .. currentTarget.Name)
            
            -- Сразу выключаем модуль после удаления
            module:OnDisable()
        else
            -- Если кликнули в пустоту - тоже выключаем
            module:OnDisable()
        end
    end
end

function module:OnEnable()
    self.Enabled = true
    print("[UI Remover] Enabled - Click UI to delete")
    
    createHighlight()

    -- Подключаем цикл (RenderStepped)
    if steppedConn then steppedConn:Disconnect() end
    steppedConn = RunService.RenderStepped:Connect(tickFrame)

    -- Подключаем клик
    if inputConn then inputConn:Disconnect() end
    inputConn = UserInputService.InputBegan:Connect(onInput)
end

function module:OnDisable()
    self.Enabled = false
    
    -- Отключаем все
    if steppedConn then steppedConn:Disconnect() steppedConn = nil end
    if inputConn then inputConn:Disconnect() inputConn = nil end
    
    destroyHighlight()

    -- ВОЗВРАЩАЕМ КУРСОР В ИГРУ
    -- Блокируем его обратно в центр, чтобы ты мог стрелять
    UserInputService.MouseIconEnabled = false
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    
    print("[UI Remover] Disabled")
end

function module:Init() end
function module:OnTick(dt) end

return module
