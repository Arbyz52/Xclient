-- ===================== gui.lua (Xclient) ======================

local Gui = {}

-- ====== ГЛОБАЛЬНЫЕ ФЛАГИ ДЛЯ ХУКА ======
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

getgenv()._xclientMenuOpen         = getgenv()._xclientMenuOpen         or false
getgenv()._xclientAllowMouseWrite  = getgenv()._xclientAllowMouseWrite  or false

-- ====== ХУК НА ИЗМЕНЕНИЕ MouseBehavior / MouseIconEnabled ======
if not getgenv()._xclientHookedMouse then
    getgenv()._xclientHookedMouse = true

    local oldNewIndex

    local function hookBody(self, key, value)
        if self == UIS and (key == "MouseBehavior" or key == "MouseIconEnabled") then
            if getgenv()._xclientMenuOpen and not getgenv()._xclientAllowMouseWrite then
                -- блокируем изменения от игры, пока меню открыто
                return
            end
        end
        return oldNewIndex(self, key, value)
    end

    if hookmetamethod then
        oldNewIndex = hookmetamethod(game, "__newindex", newcclosure(hookBody))
    else
        local mt = getrawmetatable(game)
        oldNewIndex = mt.__newindex
        setreadonly(mt, false)
        mt.__newindex = newcclosure(hookBody)
        setreadonly(mt, true)
    end
end

-- ====== ОСНОВНОЙ GUI ======
function Gui.Init(ModuleManager)
    local RunService = game:GetService("RunService")
    local localPlayer = Players.LocalPlayer

    ---------------------------------------------------
    -- ScreenGui
    ---------------------------------------------------
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "XclientMenu"
    screenGui.ResetOnSpawn = false
    screenGui.Enabled = false

    local parent = CoreGui
    pcall(function()
        if gethui then parent = gethui() end
    end)
    screenGui.Parent = parent

    ---------------------------------------------------
    -- Контейнер для колонок (без фона)
    ---------------------------------------------------
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "ColumnsHolder"
    mainFrame.Size = UDim2.new(0, 1100, 0, 420)
    mainFrame.Position = UDim2.new(0.5, -550, 0.5, -230)
    mainFrame.BackgroundTransparency = 1
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui

    local layout = Instance.new("UIListLayout", mainFrame)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 24) -- отступы между колонками

    local allButtons = {} -- {button=..., mod=...}

    ---------------------------------------------------
    -- Колонка категории
    ---------------------------------------------------
    local function createCategoryColumn(categoryName, modules)
        table.sort(modules, function(a, b)
            return (a.Name or "") < (b.Name or "")
        end)

        local colFrame = Instance.new("Frame")
        colFrame.Name = categoryName
        colFrame.Size = UDim2.new(0, 200, 1, 0) -- колонки побольше
        colFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 30)
        colFrame.BorderSizePixel = 0
        colFrame.Parent = mainFrame

        Instance.new("UICorner", colFrame).CornerRadius = UDim.new(0, 10)

        local colStroke = Instance.new("UIStroke", colFrame)
        colStroke.Color = Color3.fromRGB(60, 60, 90)
        colStroke.Thickness = 1

        local titleBar = Instance.new("Frame")
        titleBar.Size = UDim2.new(1, 0, 0, 30)
        titleBar.BackgroundColor3 = Color3.fromRGB(24, 24, 40)
        titleBar.BorderSizePixel = 0
        titleBar.Parent = colFrame

        local tbCorner = Instance.new("UICorner", titleBar)
        tbCorner.CornerRadius = UDim.new(0, 10)

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -20, 1, 0)
        title.Position = UDim2.new(0, 10, 0, 0)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.Text = categoryName
        title.TextColor3 = Color3.fromRGB(235, 235, 245)
        title.TextSize = 18
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = titleBar

        local holder = Instance.new("Frame")
        holder.Name = "ButtonsHolder"
        holder.Size = UDim2.new(1, -8, 1, -38)
        holder.Position = UDim2.new(0, 4, 0, 34)
        holder.BackgroundTransparency = 1
        holder.Parent = colFrame

        local list = Instance.new("UIListLayout", holder)
        list.FillDirection = Enum.FillDirection.Vertical
        list.Padding = UDim.new(0, 4)

        for _, mod in ipairs(modules) do
            local btn = Instance.new("TextButton")
            btn.Name = mod.Name
            btn.Size = UDim2.new(1, 0, 0, 26)
            btn.BackgroundColor3 = Color3.fromRGB(32, 32, 50)
            btn.BorderSizePixel = 0
            btn.AutoButtonColor = false
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 14
            btn.TextColor3 = Color3.fromRGB(210, 210, 220)
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Text = "      " .. mod.Name -- отступ под точку слева
            btn.Parent = holder

            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

            -- индикатор состояния (точка слева)
            local stateDot = Instance.new("Frame")
            stateDot.Size = UDim2.new(0, 8, 0, 8)
            stateDot.Position = UDim2.new(0, 8, 0.5, -4)
            stateDot.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
            stateDot.BorderSizePixel = 0
            stateDot.Parent = btn
            Instance.new("UICorner", stateDot).CornerRadius = UDim.new(1, 0)

            -- три точки справа
            local rightDots = Instance.new("TextLabel")
            rightDots.Size = UDim2.new(0, 24, 1, 0)
            rightDots.Position = UDim2.new(1, -26, 0, 0)
            rightDots.BackgroundTransparency = 1
            rightDots.Font = Enum.Font.GothamBold
            rightDots.Text = "···"
            rightDots.TextColor3 = Color3.fromRGB(130, 130, 150)
            rightDots.TextSize = 14
            rightDots.Parent = btn

            local function updateColors()
                if mod.Enabled then
                    btn.BackgroundColor3       = Color3.fromRGB(80, 140, 230)
                    btn.TextColor3            = Color3.fromRGB(255, 255, 255)
                    stateDot.BackgroundColor3 = Color3.fromRGB(130, 200, 255)
                else
                    btn.BackgroundColor3       = Color3.fromRGB(32, 32, 50)
                    btn.TextColor3            = Color3.fromRGB(210, 210, 220)
                    stateDot.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
                end
            end
            updateColors()

            btn.MouseEnter:Connect(function()
                if not mod.Enabled then
                    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
                end
            end)

            btn.MouseLeave:Connect(function()
                updateColors()
            end)

            btn.MouseButton1Click:Connect(function()
                ModuleManager:SetEnabled(mod, not mod.Enabled)
                updateColors()
            end)

            table.insert(allButtons, {button = btn, mod = mod})
        end
    end

    ---------------------------------------------------
    -- Порядок категорий
    ---------------------------------------------------
    local preferredOrder = {"Combat", "Movement", "Visuals", "Player", "Misc"}
    local categoryNames = {}
    for name, _ in pairs(ModuleManager.Categories) do
        table.insert(categoryNames, name)
    end

    table.sort(categoryNames, function(a, b)
        local ia, ib
        for i, v in ipairs(preferredOrder) do
            if v == a then ia = i end
            if v == b then ib = i end
        end
        if ia and ib then
            return ia < ib
        elseif ia then
            return true
        elseif ib then
            return false
        else
            return a < b
        end
    end)

    for _, catName in ipairs(categoryNames) do
        createCategoryColumn(catName, ModuleManager.Categories[catName])
    end

    ---------------------------------------------------
    -- Поиск снизу
    ---------------------------------------------------
    local searchFrame = Instance.new("Frame")
    searchFrame.Size = UDim2.new(0, 320, 0, 32)
    searchFrame.Position = UDim2.new(0.5, -160, 0.5, 240)
    searchFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 24)
    searchFrame.BorderSizePixel = 0
    searchFrame.Parent = screenGui

    Instance.new("UICorner", searchFrame).CornerRadius = UDim.new(0, 8)

    local searchStroke = Instance.new("UIStroke", searchFrame)
    searchStroke.Color = Color3.fromRGB(70, 70, 100)
    searchStroke.Thickness = 1

    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, -16, 1, 0)
    searchBox.Position = UDim2.new(0, 8, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.Font = Enum.Font.Gotham
    searchBox.PlaceholderText = "Поиск"
    searchBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 145)
    searchBox.Text = ""
    searchBox.TextColor3 = Color3.fromRGB(230, 230, 240)
    searchBox.TextSize = 14
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.ClearTextOnFocus = false
    searchBox.Parent = searchFrame

    local function applySearch()
        local q = searchBox.Text:lower()
        for _, info in ipairs(allButtons) do
            local name = (info.mod.Name or ""):lower()
            local visible = (q == "") or (string.find(name, q, 1, true) ~= nil)
            info.button.Visible = visible
        end
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(applySearch)

    ---------------------------------------------------
    -- Тоггл меню и управление мышью
    ---------------------------------------------------
    local menuOpen = false
    local prevMouseBehavior = UIS.MouseBehavior
    local prevMouseIcon     = UIS.MouseIconEnabled

    local function setMenuOpen(state)
        if menuOpen == state then return end
        menuOpen = state
        getgenv()._xclientMenuOpen = state

        screenGui.Enabled   = state
        searchFrame.Visible = state

        if state then
            prevMouseBehavior = UIS.MouseBehavior
            prevMouseIcon     = UIS.MouseIconEnabled

            getgenv()._xclientAllowMouseWrite = true
            UIS.MouseIconEnabled = true
            UIS.MouseBehavior    = Enum.MouseBehavior.Default
            getgenv()._xclientAllowMouseWrite = false
        else
            getgenv()._xclientAllowMouseWrite = true
            pcall(function()
                UIS.MouseBehavior    = prevMouseBehavior or Enum.MouseBehavior.LockCenter
                UIS.MouseIconEnabled = prevMouseIcon
            end)
            getgenv()._xclientAllowMouseWrite = false
        end
    end

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            setMenuOpen(not menuOpen)
        end
    end)

    print("[Xclient] GUI инициализирован, RightShift - открыть/закрыть")
end

return Gui
