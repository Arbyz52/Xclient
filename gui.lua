-- ===================== gui.lua (Xclient) ======================

local Gui = {}

function Gui.Init(ModuleManager)
    local UserInputService = game:GetService("UserInputService")
    local CoreGui          = game:GetService("CoreGui")
    local TweenService     = game:GetService("TweenService")
    local SoundService     = game:GetService("SoundService")

    ---------------------------------------------------
    -- Звук переключения
    ---------------------------------------------------
    local TOGGLE_SOUND_ID = "rbxassetid://12222005" -- можешь поменять на любой свой

    local toggleSound = Instance.new("Sound")
    toggleSound.SoundId = TOGGLE_SOUND_ID
    toggleSound.Volume = 0.4
    toggleSound.Name = "XclientToggle"
    toggleSound.Parent = SoundService

    local function playToggle()
        if not toggleSound.IsLoaded then
            -- проигрываем один и тот же объект, перезапуская
            toggleSound.TimePosition = 0
            toggleSound:Play()
        else
            toggleSound.TimePosition = 0
            toggleSound:Play()
        end
    end

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
    -- Данные для биндов и кнопок
    ---------------------------------------------------
    local ModuleBinds   = {} -- [mod] = Enum.KeyCode
    local ButtonByMod   = {} -- [mod] = info
    local InfoByButton  = {} -- [button] = info
    local bindingMod    = nil

    ---------------------------------------------------
    -- Контейнер для колонок
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
    layout.Padding = UDim.new(0, 26)

    local allButtons = {} -- список info

    ---------------------------------------------------
    -- Твин цвета
    ---------------------------------------------------
    local function tweenColor(inst, targetColor)
        TweenService:Create(
            inst,
            TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { BackgroundColor3 = targetColor }
        ):Play()
    end

    ---------------------------------------------------
    -- Колонка категории
    ---------------------------------------------------
    local function createCategoryColumn(categoryName, modules)
        table.sort(modules, function(a, b)
            return (a.Name or "") < (b.Name or "")
        end)

        local colFrame = Instance.new("Frame")
        colFrame.Name = categoryName
        colFrame.Size = UDim2.new(0, 215, 1, 0)
        colFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
        colFrame.BackgroundTransparency = 0.12
        colFrame.BorderSizePixel = 0
        colFrame.Parent = mainFrame

        Instance.new("UICorner", colFrame).CornerRadius = UDim.new(0, 14)

        local colStroke = Instance.new("UIStroke", colFrame)
        colStroke.Color = Color3.fromRGB(80, 80, 120)
        colStroke.Thickness = 1

        -- заголовок
        local titleBar = Instance.new("Frame")
        titleBar.Size = UDim2.new(1, 0, 0, 34)
        titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
        titleBar.BackgroundTransparency = 0.1
        titleBar.BorderSizePixel = 0
        titleBar.Parent = colFrame

        Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 14)

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -16, 1, 0)
        title.Position = UDim2.new(0, 8, 0, 0)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.Text = categoryName
        title.TextColor3 = Color3.fromRGB(245, 245, 255)
        title.TextSize = 18
        title.TextXAlignment = Enum.TextXAlignment.Center  -- по центру
        title.Parent = titleBar

        local holder = Instance.new("Frame")
        holder.Name = "ButtonsHolder"
        holder.Size = UDim2.new(1, -10, 1, -46)
        holder.Position = UDim2.new(0, 5, 0, 40)
        holder.BackgroundTransparency = 1
        holder.Parent = colFrame

        local list = Instance.new("UIListLayout", holder)
        list.FillDirection = Enum.FillDirection.Vertical
        list.Padding = UDim.new(0, 4)

        for _, mod in ipairs(modules) do
            local btn = Instance.new("TextButton")
            btn.Name = mod.Name
            btn.Size = UDim2.new(1, 0, 0, 26)
            btn.BackgroundColor3 = Color3.fromRGB(28, 28, 48)
            btn.BackgroundTransparency = 0.08
            btn.BorderSizePixel = 0
            btn.AutoButtonColor = false
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 14
            btn.TextColor3 = Color3.fromRGB(225, 225, 235)
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Text = "      " .. mod.Name
            btn.Parent = holder

            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

            -- точка состояния слева
            local stateDot = Instance.new("Frame")
            stateDot.Size = UDim2.new(0, 8, 0, 8)
            stateDot.Position = UDim2.new(0, 8, 0.5, -4)
            stateDot.BackgroundColor3 = Color3.fromRGB(100, 100, 140)
            stateDot.BorderSizePixel = 0
            stateDot.Parent = btn
            Instance.new("UICorner", stateDot).CornerRadius = UDim.new(1, 0)

            -- подпись бинда
            local bindLabel = Instance.new("TextLabel")
            bindLabel.Size = UDim2.new(0, 50, 1, 0)
            bindLabel.Position = UDim2.new(1, -70, 0, 0)
            bindLabel.BackgroundTransparency = 1
            bindLabel.Font = Enum.Font.Gotham
            bindLabel.TextColor3 = Color3.fromRGB(170, 170, 200)
            bindLabel.TextSize = 12
            bindLabel.TextXAlignment = Enum.TextXAlignment.Right
            bindLabel.Text = ""
            bindLabel.Parent = btn

            -- три точки справа
            local rightDots = Instance.new("TextLabel")
            rightDots.Size = UDim2.new(0, 24, 1, 0)
            rightDots.Position = UDim2.new(1, -26, 0, 0)
            rightDots.BackgroundTransparency = 1
            rightDots.Font = Enum.Font.GothamBold
            rightDots.Text = "···"
            rightDots.TextColor3 = Color3.fromRGB(160, 160, 190)
            rightDots.TextSize = 14
            rightDots.Parent = btn

            local info = {
                button    = btn,
                mod       = mod,
                bindLabel = bindLabel,
                stateDot  = stateDot,
            }

            local function updateColors()
                if mod.Enabled then
                    tweenColor(btn, Color3.fromRGB(90, 150, 240))
                    btn.TextColor3            = Color3.fromRGB(255, 255, 255)
                    stateDot.BackgroundColor3 = Color3.fromRGB(160, 210, 255)
                else
                    tweenColor(btn, Color3.fromRGB(28, 28, 48))
                    btn.TextColor3            = Color3.fromRGB(210, 210, 225)
                    stateDot.BackgroundColor3 = Color3.fromRGB(100, 100, 140)
                end
            end
            info.updateColors = updateColors
            updateColors()

            btn.MouseEnter:Connect(function()
                if not mod.Enabled then
                    tweenColor(btn, Color3.fromRGB(40, 40, 72))
                end
            end)

            btn.MouseLeave:Connect(function()
                updateColors()
            end)

            -- ЛКМ: вкл/выкл
            btn.MouseButton1Click:Connect(function()
                ModuleManager:SetEnabled(mod, not mod.Enabled)
                updateColors()
                playToggle()
            end)

            -- колесико по кнопке -> начало бинда
            if btn.MouseButton3Click then
                btn.MouseButton3Click:Connect(function()
                    bindingMod = mod
                    if bindLabel then
                        bindLabel.Text = "..."
                        bindLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
                    end
                end)
            end

            table.insert(allButtons, info)
            ButtonByMod[mod]  = info
            InfoByButton[btn] = info
        end
    end

    ---------------------------------------------------
    -- Гарантируем 5 категорий
    ---------------------------------------------------
    local preferredOrder = {"Combat", "Movement", "Visuals", "Player", "Misc"}
    for _, cat in ipairs(preferredOrder) do
        ModuleManager.Categories[cat] = ModuleManager.Categories[cat] or {}
    end

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
    searchFrame.BackgroundTransparency = 0.15
    searchFrame.BorderSizePixel = 0
    searchFrame.Parent = screenGui

    Instance.new("UICorner", searchFrame).CornerRadius = UDim.new(0, 8)

    local searchStroke = Instance.new("UIStroke", searchFrame)
    searchStroke.Color = Color3.fromRGB(80, 80, 120)
    searchStroke.Thickness = 1

    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, -16, 1, 0)
    searchBox.Position = UDim2.new(0, 8, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.Font = Enum.Font.Gotham
    searchBox.PlaceholderText = "Поиск"
    searchBox.PlaceholderColor3 = Color3.fromRGB(130, 130, 165)
    searchBox.Text = ""
    searchBox.TextColor3 = Color3.fromRGB(230, 230, 245)
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
    -- Анимация открытия/закрытия
    ---------------------------------------------------
    local menuOpen = false

    local function playOpenAnim()
        screenGui.Enabled   = true
        searchFrame.Visible = true

        mainFrame.Position   = UDim2.new(0.5, -550, 0.5, -260)
        searchFrame.Position = UDim2.new(0.5, -160, 0.5, 270)

        local info = TweenInfo.new(0.23, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(mainFrame,  info, {Position = UDim2.new(0.5, -550, 0.5, -230)}):Play()
        TweenService:Create(searchFrame, info, {Position = UDim2.new(0.5, -160, 0.5, 240)}):Play()
    end

    local function playCloseAnim()
        local info = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        local t1 = TweenService:Create(mainFrame,  info, {Position = UDim2.new(0.5, -550, 0.5, -260)})
        local t2 = TweenService:Create(searchFrame, info, {Position = UDim2.new(0.5, -160, 0.5, 270)})

        t1:Play()
        t2:Play()
        t2.Completed:Connect(function()
            if not menuOpen then
                screenGui.Enabled   = false
                searchFrame.Visible = false
            end
        end)
    end

    local function setMenuOpen(state)
        if menuOpen == state then return end
        menuOpen = state
        if state then
            playOpenAnim()
        else
            playCloseAnim()
        end
    end

    ---------------------------------------------------
    -- Бинды и ввод
    ---------------------------------------------------
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end

        local focused = UserInputService:GetFocusedTextBox()

        -- если ждём клавишу для бинда
        if bindingMod and input.UserInputType == Enum.UserInputType.Keyboard then
            local key = input.KeyCode
            local info = ButtonByMod[bindingMod]

            if key == Enum.KeyCode.Escape then
                ModuleBinds[bindingMod] = nil
                if info and info.bindLabel then
                    info.bindLabel.Text = ""
                    info.bindLabel.TextColor3 = Color3.fromRGB(170, 170, 200)
                end
            else
                ModuleBinds[bindingMod] = key
                if info and info.bindLabel then
                    local name = tostring(key):gsub("Enum.KeyCode.", "")
                    info.bindLabel.Text = name
                    info.bindLabel.TextColor3 = Color3.fromRGB(170, 170, 200)
                end
            end

            bindingMod = nil
            return
        end

        -- если печатаем в поиск и бинда не ждём — не реагируем
        if focused and focused == searchBox then
            return
        end

        -- RightShift -> открыть/закрыть меню
        if input.UserInputType == Enum.UserInputType.Keyboard
            and input.KeyCode == Enum.KeyCode.RightShift then
            setMenuOpen(not menuOpen)
            return
        end

        -- обработка биндов модулей
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local key = input.KeyCode
            for mod, bindKey in pairs(ModuleBinds) do
                if bindKey == key then
                    ModuleManager:SetEnabled(mod, not mod.Enabled)
                    local info = ButtonByMod[mod]
                    if info and info.updateColors then
                        info.updateColors()
                    end
                    playToggle()
                end
            end
        end
    end)

    print("[Xclient] GUI инициализирован, RightShift - открыть/закрыть")
end

return Gui
