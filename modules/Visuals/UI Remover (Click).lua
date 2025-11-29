-- modules/Visuals/UIRemover.lua
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local module = {
    Name = "UI Remover (Click)",
    Category = "Visuals",
    Enabled = false,
}

local clickConnection

-- Функция для "удаления" (скрытия) элемента
local function hideElement(guiObject)
    if not guiObject then return end
    
    -- Мы используем Visible = false, это безопаснее, чем Destroy()
    -- Если использовать Destroy(), игровой скрипт может выдать ошибку, если попытается обновить патроны/хп
    pcall(function()
        guiObject.Visible = false
    end)
    print("[UI Remover] Hidden: " .. guiObject.Name)
end

function module:OnEnable()
    self.Enabled = true
    
    -- 1. ПОКАЗЫВАЕМ КУРСОР
    -- Чтобы ты мог выбрать элемент, нужно разблокировать мышку
    UserInputService.MouseIconEnabled = true
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    
    print("[UI Remover] Select a UI element to remove...")

    -- 2. СЛУШАЕМ ОДИН КЛИК
    -- Если уже было подключение - убираем (на всякий случай)
    if clickConnection then clickConnection:Disconnect() end
    
    clickConnection = UserInputService.InputBegan:Connect(function(input)
        -- Нам нужен только левый клик мыши
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            
            -- Получаем позицию мышки
            local mousePos = UserInputService:GetMouseLocation()
            
            -- Ищем все GUI элементы под мышкой (в PlayerGui)
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                -- GetGuiObjectsAtPosition возвращает список. Первый элемент [1] - это самый верхний (тот, что ты видишь)
                local objects = playerGui:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y)
                
                if objects and #objects > 0 then
                    local target = objects[1]
                    
                    -- Небольшая защита, чтобы случайно не удалить весь экран (ScreenGui), удаляем только рамки/текст/картинки
                    if target:IsA("Frame") or target:IsA("ImageLabel") or target:IsA("TextLabel") or target:IsA("ImageButton") or target:IsA("TextButton") then
                        hideElement(target)
                    else
                        -- Если кликнули по чему-то странному, пробуем скрыть всё равно
                        hideElement(target)
                    end
                end
            end

            -- 3. ВЫКЛЮЧАЕМ ФУНКЦИЮ ПОСЛЕ КЛИКА
            -- Вызываем OnDisable вручную, чтобы вернуть игру в норму
            module:OnDisable()
        end
    end)
end

function module:OnDisable()
    self.Enabled = false
    
    -- Отключаем прослушивание кликов
    if clickConnection then
        clickConnection:Disconnect()
        clickConnection = nil
    end

    -- 4. ВОЗВРАЩАЕМ УПРАВЛЕНИЕ
    -- Скрываем курсор и блокируем его обратно в центр экрана (для шутеров)
    UserInputService.MouseIconEnabled = false
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    
    print("[UI Remover] Disabled")
end

function module:Init() end
function module:OnTick(dt) end

return module
