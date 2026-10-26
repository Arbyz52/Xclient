local Gui = {}

function Gui.Init(ModuleManager, Notifications)
    local UserInputService = game:GetService("UserInputService")
    local CoreGui          = game:GetService("CoreGui")
    local TweenService     = game:GetService("TweenService")
    local RunService       = game:GetService("RunService")

    local parent = CoreGui
    pcall(function()
        if gethui then parent = gethui() end
    end)

    -- ========== THEME PALETTE ==========
    local Theme = {
        BgBase        = Color3.fromRGB(13, 14, 22),       -- Глубокий темный
        CardBg        = Color3.fromRGB(18, 20, 32),       -- Фон колонок
        CardHeader    = Color3.fromRGB(24, 26, 42),       -- Заголовок колонок
        ItemBg        = Color3.fromRGB(25, 27, 44),       -- Модуль выключен
        ItemHover     = Color3.fromRGB(34, 38, 62),       -- Модуль hover
        ItemActive    = Color3.fromRGB(99, 102, 241),      -- Модуль включен (Индиго/Неон)
        ItemActiveDot = Color3.fromRGB(56, 189, 248),      -- Светящаяся точка (Циан)
        StrokeNormal  = Color3.fromRGB(36, 39, 60),       -- Обводка обычная
        StrokeAccent  = Color3.fromRGB(99, 102, 241),      -- Обводка активная
        TextPrimary   = Color3.fromRGB(241, 245, 249),     -- Белый текст
        TextSecondary = Color3.fromRGB(148, 163, 184),     -- Серый текст
        TextMuted     = Color3.fromRGB(90, 100, 125),      -- Приглушенный текст
        Success       = Color3.fromRGB(16, 185, 129),      -- Зеленый
        Danger        = Color3.fromRGB(239, 68, 68),       -- Красный
        AccentGrad    = Color3.fromRGB(139, 92, 246),      -- Пурпур
    }

    -- Цвета плашек категорий
    local CategoryColors = {
        ["Combat"]   = Color3.fromRGB(239, 68, 68),   -- Красный
        ["Movement"] = Color3.fromRGB(56, 189, 248),  -- Голубой
        ["Visuals"]  = Color3.fromRGB(168, 85, 247),  -- Фиолетовый
        ["Player"]   = Color3.fromRGB(34, 197, 94),   -- Зеленый
        ["Misc"]     = Color3.fromRGB(245, 158, 11),  -- Янтарный
    }

    local CategoryIcons = {
        ["Combat"]   = "⚔",
        ["Movement"] = "⚡",
        ["Visuals"]  = "👁",
        ["Player"]   = "🎯",
        ["Misc"]     = "⚙",
    }

    -- ========== STATE ==========
    local allButtons       = {}
    local settingsOpen     = false
    local settingsModName  = nil
    local menuOpen         = false
    local keybindListening = false
    local keybindCallback  = nil
    local activeModulesCountLabel = nil

    -- ========== SCREEN GUI ==========
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "XclientMenu"
    screenGui.ResetOnSpawn = false
    screenGui.Enabled = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = parent

    -- ========== DRAG ROOT FRAME ==========
    local totalWidth = 1040
    local totalHeight = 490

    local dragFrame = Instance.new("Frame")
    dragFrame.Name = "DragRoot"
    dragFrame.Size = UDim2.new(0, totalWidth, 0, totalHeight)
    dragFrame.Position = UDim2.new(0.5, -totalWidth / 2, 0.5, -totalHeight / 2)
    dragFrame.BackgroundTransparency = 1
    dragFrame.Parent = screenGui

    -- ========== TOP HEADER BAR ==========
    local headerBar = Instance.new("Frame")
    headerBar.Name = "HeaderBar"
    headerBar.Size = UDim2.new(1, 0, 0, 46)
    headerBar.Position = UDim2.new(0, 0, 0, 0)
    headerBar.BackgroundColor3 = Theme.CardBg
    headerBar.BorderSizePixel = 0
    headerBar.Parent = dragFrame

    local headerCorner = Instance.new("UICorner", headerBar)
    headerCorner.CornerRadius = UDim.new(0, 12)

    local headerStroke = Instance.new("UIStroke", headerBar)
    headerStroke.Color = Theme.StrokeNormal
    headerStroke.Thickness = 1

    -- Logo
    local logoLabel = Instance.new("TextLabel")
    logoLabel.Name = "Logo"
    logoLabel.Size = UDim2.new(0, 130, 1, 0)
    logoLabel.Position = UDim2.new(0, 16, 0, 0)
    logoLabel.BackgroundTransparency = 1
    logoLabel.Font = Enum.Font.GothamBold
    logoLabel.Text = "⚡ XCLIENT"
    logoLabel.TextColor3 = Theme.ItemActive
    logoLabel.TextSize = 18
    logoLabel.TextXAlignment = Enum.TextXAlignment.Left
    logoLabel.Parent = headerBar

    -- Version Badge
    local verBadge = Instance.new("Frame")
    verBadge.Name = "VersionBadge"
    verBadge.Size = UDim2.new(0, 50, 0, 20)
    verBadge.Position = UDim2.new(0, 138, 0.5, -10)
    verBadge.BackgroundColor3 = Color3.fromRGB(30, 33, 54)
    verBadge.BorderSizePixel = 0
    verBadge.Parent = headerBar
    Instance.new("UICorner", verBadge).CornerRadius = UDim.new(0, 6)

    local verText = Instance.new("TextLabel")
    verText.Size = UDim2.new(1, 0, 1, 0)
    verText.BackgroundTransparency = 1
    verText.Font = Enum.Font.GothamBold
    verText.Text = "v2.0"
    verText.TextColor3 = Theme.ItemActiveDot
    verText.TextSize = 11
    verText.Parent = verBadge

    -- Active Count Badge
    activeModulesCountLabel = Instance.new("TextLabel")
    activeModulesCountLabel.Name = "ActiveCount"
    activeModulesCountLabel.Size = UDim2.new(0, 110, 1, 0)
    activeModulesCountLabel.Position = UDim2.new(0, 200, 0, 0)
    activeModulesCountLabel.BackgroundTransparency = 1
    activeModulesCountLabel.Font = Enum.Font.Gotham
    activeModulesCountLabel.Text = "Активно: 0"
    activeModulesCountLabel.TextColor3 = Theme.TextSecondary
    activeModulesCountLabel.TextSize = 12
    activeModulesCountLabel.TextXAlignment = Enum.TextXAlignment.Left
    activeModulesCountLabel.Parent = headerBar

    -- Search Box Container
    local searchContainer = Instance.new("Frame")
    searchContainer.Name = "SearchContainer"
    searchContainer.Size = UDim2.new(0, 260, 0, 30)
    searchContainer.Position = UDim2.new(0.5, -130, 0.5, -15)
    searchContainer.BackgroundColor3 = Color3.fromRGB(12, 13, 20)
    searchContainer.BorderSizePixel = 0
    searchContainer.Parent = headerBar
    Instance.new("UICorner", searchContainer).CornerRadius = UDim.new(0, 8)

    local searchStroke = Instance.new("UIStroke", searchContainer)
    searchStroke.Color = Theme.StrokeNormal
    searchStroke.Thickness = 1

    local searchIcon = Instance.new("TextLabel")
    searchIcon.Size = UDim2.new(0, 26, 1, 0)
    searchIcon.Position = UDim2.new(0, 6, 0, 0)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Font = Enum.Font.Gotham
    searchIcon.Text = "🔍"
    searchIcon.TextSize = 12
    searchIcon.TextColor3 = Theme.TextMuted
    searchIcon.Parent = searchContainer

    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, -38, 1, 0)
    searchBox.Position = UDim2.new(0, 32, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.Font = Enum.Font.Gotham
    searchBox.PlaceholderText = "Поиск по модулям..."
    searchBox.PlaceholderColor3 = Theme.TextMuted
    searchBox.Text = ""
    searchBox.TextColor3 = Theme.TextPrimary
    searchBox.TextSize = 12
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.ClearTextOnFocus = false
    searchBox.Parent = searchContainer

    -- Reload Button (Right side)
    local reloadBtn = Instance.new("TextButton")
    reloadBtn.Name = "ReloadBtn"
    reloadBtn.Size = UDim2.new(0, 110, 0, 28)
    reloadBtn.Position = UDim2.new(1, -156, 0.5, -14)
    reloadBtn.BackgroundColor3 = Color3.fromRGB(24, 27, 44)
    reloadBtn.BorderSizePixel = 0
    reloadBtn.AutoButtonColor = false
    reloadBtn.Font = Enum.Font.GothamBold
    reloadBtn.Text = "⟳ Обновить"
    reloadBtn.TextColor3 = Theme.TextSecondary
    reloadBtn.TextSize = 11
    reloadBtn.Parent = headerBar
    Instance.new("UICorner", reloadBtn).CornerRadius = UDim.new(0, 8)

    local reloadStroke = Instance.new("UIStroke", reloadBtn)
    reloadStroke.Color = Theme.StrokeNormal
    reloadStroke.Thickness = 1

    -- Close Button (Right side)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -38, 0.5, -14)
    closeBtn.BackgroundColor3 = Color3.fromRGB(24, 27, 44)
    closeBtn.BorderSizePixel = 0
    closeBtn.AutoButtonColor = false
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Theme.TextSecondary
    closeBtn.TextSize = 13
    closeBtn.Parent = headerBar
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

    -- ========== COLUMNS HOLDER ==========
    local columnsHolder = Instance.new("Frame")
    columnsHolder.Name = "ColumnsHolder"
    columnsHolder.Size = UDim2.new(1, 0, 1, -56)
    columnsHolder.Position = UDim2.new(0, 0, 0, 56)
    columnsHolder.BackgroundTransparency = 1
    columnsHolder.Parent = dragFrame

    local columnsLayout = Instance.new("UIListLayout", columnsHolder)
    columnsLayout.FillDirection = Enum.FillDirection.Horizontal
    columnsLayout.Padding = UDim.new(0, 10)
    columnsLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- ========== SETTINGS DRAWER (SIDE PANEL) ==========
    local settingsPanel = Instance.new("Frame")
    settingsPanel.Name = "SettingsPanel"
    settingsPanel.Size = UDim2.new(0, 290, 1, -56)
    settingsPanel.Position = UDim2.new(1, 14, 0, 56)
    settingsPanel.BackgroundColor3 = Theme.CardBg
    settingsPanel.BorderSizePixel = 0
    settingsPanel.Visible = false
    settingsPanel.Parent = dragFrame
    Instance.new("UICorner", settingsPanel).CornerRadius = UDim.new(0, 12)

    local settingsStroke = Instance.new("UIStroke", settingsPanel)
    settingsStroke.Color = Theme.StrokeNormal
    settingsStroke.Thickness = 1

    local settingsHeader = Instance.new("Frame")
    settingsHeader.Size = UDim2.new(1, 0, 0, 42)
    settingsHeader.BackgroundColor3 = Theme.CardHeader
    settingsHeader.BorderSizePixel = 0
    settingsHeader.Parent = settingsPanel
    Instance.new("UICorner", settingsHeader).CornerRadius = UDim.new(0, 12)

    local settingsTitle = Instance.new("TextLabel")
    settingsTitle.Size = UDim2.new(1, -70, 1, 0)
    settingsTitle.Position = UDim2.new(0, 14, 0, 0)
    settingsTitle.BackgroundTransparency = 1
    settingsTitle.Font = Enum.Font.GothamBold
    settingsTitle.Text = "Настройки"
    settingsTitle.TextColor3 = Theme.TextPrimary
    settingsTitle.TextSize = 14
    settingsTitle.TextXAlignment = Enum.TextXAlignment.Left
    settingsTitle.Parent = settingsHeader

    local settingsCloseBtn = Instance.new("TextButton")
    settingsCloseBtn.Size = UDim2.new(0, 26, 0, 26)
    settingsCloseBtn.Position = UDim2.new(1, -34, 0.5, -13)
    settingsCloseBtn.BackgroundColor3 = Color3.fromRGB(30, 33, 50)
    settingsCloseBtn.BorderSizePixel = 0
    settingsCloseBtn.AutoButtonColor = false
    settingsCloseBtn.Font = Enum.Font.GothamBold
    settingsCloseBtn.Text = "✕"
    settingsCloseBtn.TextColor3 = Theme.TextSecondary
    settingsCloseBtn.TextSize = 12
    settingsCloseBtn.Parent = settingsHeader
    Instance.new("UICorner", settingsCloseBtn).CornerRadius = UDim.new(0, 6)

    local settingsScroll = Instance.new("ScrollingFrame")
    settingsScroll.Name = "SettingsScroll"
    settingsScroll.Size = UDim2.new(1, -16, 1, -54)
    settingsScroll.Position = UDim2.new(0, 8, 0, 48)
    settingsScroll.BackgroundTransparency = 1
    settingsScroll.BorderSizePixel = 0
    settingsScroll.ScrollBarThickness = 3
    settingsScroll.ScrollBarImageColor3 = Theme.StrokeAccent
    settingsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    settingsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    settingsScroll.Parent = settingsPanel

    local settingsLayout = Instance.new("UIListLayout", settingsScroll)
    settingsLayout.Padding = UDim.new(0, 8)
    settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- ========== HELPERS ==========
    local function tweenColor(inst, targetColor, dur)
        TweenService:Create(
            inst,
            TweenInfo.new(dur or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { BackgroundColor3 = targetColor }
        ):Play()
    end

    local function notify(text, dur, color)
        if Notifications and Notifications.Show then
            Notifications:Show(text, dur, color)
        end
    end

    local function updateActiveCounter()
        if not activeModulesCountLabel then return end
        local count = 0
        for _, mod in ipairs(ModuleManager.Modules) do
            if mod.Enabled then count = count + 1 end
        end
        activeModulesCountLabel.Text = "Активно: " .. count
    end

    -- ========== SETTINGS PANEL RENDERING ==========
    local function clearSettingsPanel()
        for _, child in ipairs(settingsScroll:GetChildren()) do
            if child:IsA("GuiObject") then child:Destroy() end
        end
    end

    local function renderSettingsPanel(mod)
        clearSettingsPanel()
        if not mod then
            settingsPanel.Visible = false
            settingsOpen = false
            settingsModName = nil
            for _, b in ipairs(allButtons) do
                if b.updateColors then b.updateColors() end
            end
            return
        end

        settingsTitle.Text = mod.Name or "Настройки"
        settingsModName = mod.Name
        settingsOpen = true
        settingsPanel.Visible = true

        -- Quick Toggle Switch in Settings
        local toggleRow = Instance.new("Frame")
        toggleRow.Size = UDim2.new(1, 0, 0, 36)
        toggleRow.BackgroundColor3 = Color3.fromRGB(24, 27, 44)
        toggleRow.BorderSizePixel = 0
        toggleRow.LayoutOrder = 1
        toggleRow.Parent = settingsScroll
        Instance.new("UICorner", toggleRow).CornerRadius = UDim.new(0, 8)

        local toggleLabel = Instance.new("TextLabel")
        toggleLabel.Size = UDim2.new(1, -70, 1, 0)
        toggleLabel.Position = UDim2.new(0, 12, 0, 0)
        toggleLabel.BackgroundTransparency = 1
        toggleLabel.Font = Enum.Font.GothamBold
        toggleLabel.Text = "Включить модуль"
        toggleLabel.TextColor3 = Theme.TextPrimary
        toggleLabel.TextSize = 12
        toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
        toggleLabel.Parent = toggleRow

        local toggleSwitch = Instance.new("TextButton")
        toggleSwitch.Size = UDim2.new(0, 44, 0, 22)
        toggleSwitch.Position = UDim2.new(1, -54, 0.5, -11)
        toggleSwitch.BackgroundColor3 = mod.Enabled and Theme.ItemActive or Color3.fromRGB(36, 40, 62)
        toggleSwitch.BorderSizePixel = 0
        toggleSwitch.AutoButtonColor = false
        toggleSwitch.Text = ""
        toggleSwitch.Parent = toggleRow
        Instance.new("UICorner", toggleSwitch).CornerRadius = UDim.new(1, 0)

        local toggleThumb = Instance.new("Frame")
        toggleThumb.Size = UDim2.new(0, 16, 0, 16)
        toggleThumb.Position = mod.Enabled and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        toggleThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        toggleThumb.BorderSizePixel = 0
        toggleThumb.Parent = toggleSwitch
        Instance.new("UICorner", toggleThumb).CornerRadius = UDim.new(1, 0)

        toggleSwitch.MouseButton1Click:Connect(function()
            ModuleManager:SetEnabled(mod, not mod.Enabled)
            local enabled = mod.Enabled
            TweenService:Create(toggleSwitch, TweenInfo.new(0.18), {
                BackgroundColor3 = enabled and Theme.ItemActive or Color3.fromRGB(36, 40, 62)
            }):Play()
            TweenService:Create(toggleThumb, TweenInfo.new(0.18), {
                Position = enabled and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
            }):Play()
            for _, b in ipairs(allButtons) do
                if b.updateColors then b.updateColors() end
            end
            updateActiveCounter()
        end)

        -- Keybind Assignment Button
        local kbRow = Instance.new("Frame")
        kbRow.Size = UDim2.new(1, 0, 0, 36)
        kbRow.BackgroundColor3 = Color3.fromRGB(24, 27, 44)
        kbRow.BorderSizePixel = 0
        kbRow.LayoutOrder = 2
        kbRow.Parent = settingsScroll
        Instance.new("UICorner", kbRow).CornerRadius = UDim.new(0, 8)

        local kbTitle = Instance.new("TextLabel")
        kbTitle.Size = UDim2.new(0.45, 0, 1, 0)
        kbTitle.Position = UDim2.new(0, 12, 0, 0)
        kbTitle.BackgroundTransparency = 1
        kbTitle.Font = Enum.Font.Gotham
        kbTitle.Text = "Горячая клавиша:"
        kbTitle.TextColor3 = Theme.TextSecondary
        kbTitle.TextSize = 11
        kbTitle.TextXAlignment = Enum.TextXAlignment.Left
        kbTitle.Parent = kbRow

        local kbBtn = Instance.new("TextButton")
        kbBtn.Size = UDim2.new(0.48, 0, 0, 24)
        kbBtn.Position = UDim2.new(0.5, 0, 0.5, -12)
        kbBtn.BackgroundColor3 = Color3.fromRGB(32, 35, 56)
        kbBtn.BorderSizePixel = 0
        kbBtn.AutoButtonColor = false
        kbBtn.Font = Enum.Font.GothamBold
        kbBtn.TextSize = 11
        kbBtn.TextColor3 = Theme.ItemActiveDot
        kbBtn.Text = ModuleManager.Keybinds[mod.Name] and ("[" .. ModuleManager.Keybinds[mod.Name] .. "]") or "[ Нет ]"
        kbBtn.Parent = kbRow
        Instance.new("UICorner", kbBtn).CornerRadius = UDim.new(0, 6)

        kbBtn.MouseButton1Click:Connect(function()
            if keybindListening then return end
            keybindListening = true
            kbBtn.Text = "[ Нажмите... ]"
            kbBtn.TextColor3 = Theme.AccentGrad

            keybindCallback = function(input)
                keybindListening = false
                keybindCallback = nil

                local keyName = nil
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    if input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Escape then
                        ModuleManager.Keybinds[mod.Name] = nil
                        kbBtn.Text = "[ Нет ]"
                        kbBtn.TextColor3 = Theme.TextSecondary
                        for _, b in ipairs(allButtons) do
                            if b.mod == mod and b.kbLabel then b.kbLabel.Text = "" end
                        end
                        return
                    else
                        keyName = input.KeyCode.Name
                    end
                elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                    keyName = "Mouse1"
                elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                    keyName = "Mouse2"
                end

                if keyName then
                    ModuleManager.Keybinds[mod.Name] = keyName
                    kbBtn.Text = "[" .. keyName .. "]"
                    kbBtn.TextColor3 = Theme.ItemActiveDot
                    for _, b in ipairs(allButtons) do
                        if b.mod == mod and b.kbLabel then
                            b.kbLabel.Text = "[" .. keyName:sub(1, 5) .. "]"
                        end
                    end
                end
            end
        end)

        -- Dynamic Settings Definitions
        if mod.SettingsDefinitions and #mod.SettingsDefinitions > 0 then
            local orderCounter = 3

            for _, def in ipairs(mod.SettingsDefinitions) do
                local sName    = def.Name    or "Параметр"
                local sKey     = def.Key     or sName
                local sType    = def.Type    or "Slider"
                local sDefault = def.Default
                orderCounter = orderCounter + 1

                if sType == "Slider" then
                    local sMin    = def.Min    or 0
                    local sMax    = def.Max    or 100
                    local sStep   = def.Step   or 1
                    local sSuffix = def.Suffix or ""

                    local currentVal = sDefault or sMin
                    if mod.__settings__ and mod.__settings__[sKey] ~= nil then
                        currentVal = mod.__settings__[sKey]
                    end

                    local card = Instance.new("Frame")
                    card.Size = UDim2.new(1, 0, 0, 48)
                    card.BackgroundColor3 = Color3.fromRGB(24, 27, 44)
                    card.BorderSizePixel = 0
                    card.LayoutOrder = orderCounter
                    card.Parent = settingsScroll
                    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

                    local lbl = Instance.new("TextLabel")
                    lbl.Size = UDim2.new(0.65, 0, 0, 20)
                    lbl.Position = UDim2.new(0, 10, 0, 4)
                    lbl.BackgroundTransparency = 1
                    lbl.Font = Enum.Font.Gotham
                    lbl.Text = sName
                    lbl.TextColor3 = Theme.TextSecondary
                    lbl.TextSize = 11
                    lbl.TextXAlignment = Enum.TextXAlignment.Left
                    lbl.Parent = card

                    local valLbl = Instance.new("TextLabel")
                    valLbl.Size = UDim2.new(0.3, 0, 0, 20)
                    valLbl.Position = UDim2.new(0.7, -10, 0, 4)
                    valLbl.BackgroundTransparency = 1
                    valLbl.Font = Enum.Font.GothamBold
                    valLbl.Text = tostring(currentVal) .. sSuffix
                    valLbl.TextColor3 = Theme.ItemActiveDot
                    valLbl.TextSize = 11
                    valLbl.TextXAlignment = Enum.TextXAlignment.Right
                    valLbl.Parent = card

                    local barBg = Instance.new("Frame")
                    barBg.Size = UDim2.new(1, -20, 0, 8)
                    barBg.Position = UDim2.new(0, 10, 0, 28)
                    barBg.BackgroundColor3 = Color3.fromRGB(36, 40, 62)
                    barBg.BorderSizePixel = 0
                    barBg.Parent = card
                    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

                    local barFill = Instance.new("Frame")
                    local pct = math.clamp((currentVal - sMin) / (sMax - sMin), 0, 1)
                    barFill.Size = UDim2.new(pct, 0, 1, 0)
                    barFill.BackgroundColor3 = Theme.ItemActive
                    barFill.BorderSizePixel = 0
                    barFill.Parent = barBg
                    Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

                    local function updateBar()
                        local p = math.clamp((currentVal - sMin) / (sMax - sMin), 0, 1)
                        barFill.Size = UDim2.new(p, 0, 1, 0)
                        valLbl.Text = tostring(currentVal) .. sSuffix
                    end

                    local dragging = false
                    barBg.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            dragging = true
                            local absPos = barBg.AbsolutePosition.X
                            local absSize = barBg.AbsoluteSize.X
                            local mouseX = input.Position.X
                            local p = math.clamp((mouseX - absPos) / absSize, 0, 1)
                            local raw = sMin + p * (sMax - sMin)
                            currentVal = math.floor(raw / sStep + 0.5) * sStep
                            currentVal = math.clamp(currentVal, sMin, sMax)
                            if not mod.__settings__ then mod.__settings__ = {} end
                            mod.__settings__[sKey] = currentVal
                            updateBar()
                        end
                    end)

                    UserInputService.InputChanged:Connect(function(input)
                        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                            local absPos = barBg.AbsolutePosition.X
                            local absSize = barBg.AbsoluteSize.X
                            local mouseX = input.Position.X
                            local p = math.clamp((mouseX - absPos) / absSize, 0, 1)
                            local raw = sMin + p * (sMax - sMin)
                            currentVal = math.floor(raw / sStep + 0.5) * sStep
                            currentVal = math.clamp(currentVal, sMin, sMax)
                            if not mod.__settings__ then mod.__settings__ = {} end
                            mod.__settings__[sKey] = currentVal
                            updateBar()
                        end
                    end)

                    UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            dragging = false
                        end
                    end)

                elseif sType == "Toggle" then
                    local currentVal = sDefault or false
                    if mod.__settings__ and mod.__settings__[sKey] ~= nil then
                        currentVal = mod.__settings__[sKey]
                    end

                    local row = Instance.new("Frame")
                    row.Size = UDim2.new(1, 0, 0, 36)
                    row.BackgroundColor3 = Color3.fromRGB(24, 27, 44)
                    row.BorderSizePixel = 0
                    row.LayoutOrder = orderCounter
                    row.Parent = settingsScroll
                    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

                    local lbl = Instance.new("TextLabel")
                    lbl.Size = UDim2.new(1, -60, 1, 0)
                    lbl.Position = UDim2.new(0, 12, 0, 0)
                    lbl.BackgroundTransparency = 1
                    lbl.Font = Enum.Font.Gotham
                    lbl.Text = sName
                    lbl.TextColor3 = Theme.TextSecondary
                    lbl.TextSize = 11
                    lbl.TextXAlignment = Enum.TextXAlignment.Left
                    lbl.Parent = row

                    local sw = Instance.new("TextButton")
                    sw.Size = UDim2.new(0, 40, 0, 20)
                    sw.Position = UDim2.new(1, -50, 0.5, -10)
                    sw.BackgroundColor3 = currentVal and Theme.ItemActive or Color3.fromRGB(36, 40, 62)
                    sw.BorderSizePixel = 0
                    sw.AutoButtonColor = false
                    sw.Text = ""
                    sw.Parent = row
                    Instance.new("UICorner", sw).CornerRadius = UDim.new(1, 0)

                    local th = Instance.new("Frame")
                    th.Size = UDim2.new(0, 14, 0, 14)
                    th.Position = currentVal and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
                    th.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    th.BorderSizePixel = 0
                    th.Parent = sw
                    Instance.new("UICorner", th).CornerRadius = UDim.new(1, 0)

                    sw.MouseButton1Click:Connect(function()
                        currentVal = not currentVal
                        if not mod.__settings__ then mod.__settings__ = {} end
                        mod.__settings__[sKey] = currentVal
                        TweenService:Create(sw, TweenInfo.new(0.15), {
                            BackgroundColor3 = currentVal and Theme.ItemActive or Color3.fromRGB(36, 40, 62)
                        }):Play()
                        TweenService:Create(th, TweenInfo.new(0.15), {
                            Position = currentVal and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
                        }):Play()
                    end)

                elseif sType == "Dropdown" then
                    local sOptions = def.Options or {}
                    local currentVal = sDefault or sOptions[1] or ""
                    if mod.__settings__ and mod.__settings__[sKey] ~= nil then
                        currentVal = mod.__settings__[sKey]
                    end

                    local row = Instance.new("Frame")
                    row.Size = UDim2.new(1, 0, 0, 34)
                    row.BackgroundColor3 = Color3.fromRGB(24, 27, 44)
                    row.BorderSizePixel = 0
                    row.LayoutOrder = orderCounter
                    row.Parent = settingsScroll
                    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

                    local lbl = Instance.new("TextLabel")
                    lbl.Size = UDim2.new(0.5, 0, 1, 0)
                    lbl.Position = UDim2.new(0, 12, 0, 0)
                    lbl.BackgroundTransparency = 1
                    lbl.Font = Enum.Font.Gotham
                    lbl.Text = sName
                    lbl.TextColor3 = Theme.TextSecondary
                    lbl.TextSize = 11
                    lbl.TextXAlignment = Enum.TextXAlignment.Left
                    lbl.Parent = row

                    local dropBtn = Instance.new("TextButton")
                    dropBtn.Size = UDim2.new(0.44, 0, 0, 24)
                    dropBtn.Position = UDim2.new(0.52, 0, 0.5, -12)
                    dropBtn.BackgroundColor3 = Color3.fromRGB(32, 35, 56)
                    dropBtn.BorderSizePixel = 0
                    dropBtn.AutoButtonColor = false
                    dropBtn.Font = Enum.Font.GothamBold
                    dropBtn.Text = tostring(currentVal) .. " ▾"
                    dropBtn.TextColor3 = Theme.TextPrimary
                    dropBtn.TextSize = 11
                    dropBtn.Parent = row
                    Instance.new("UICorner", dropBtn).CornerRadius = UDim.new(0, 6)

                    local curIdx = 1
                    for idx, opt in ipairs(sOptions) do
                        if opt == currentVal then curIdx = idx break end
                    end

                    dropBtn.MouseButton1Click:Connect(function()
                        curIdx = curIdx + 1
                        if curIdx > #sOptions then curIdx = 1 end
                        currentVal = sOptions[curIdx]
                        dropBtn.Text = tostring(currentVal) .. " ▾"
                        if not mod.__settings__ then mod.__settings__ = {} end
                        mod.__settings__[sKey] = currentVal
                    end)
                end
            end
        end
    end

    settingsCloseBtn.MouseButton1Click:Connect(function()
        renderSettingsPanel(nil)
    end)

    -- ========== CATEGORY COLUMN BUILDER ==========
    local function createCategoryColumn(categoryName, modules, order)
        local colFrame = Instance.new("Frame")
        colFrame.Name = "Col_" .. categoryName
        colFrame.Size = UDim2.new(0.2, -8, 1, 0)
        colFrame.BackgroundColor3 = Theme.CardBg
        colFrame.BorderSizePixel = 0
        colFrame.LayoutOrder = order
        colFrame.Parent = columnsHolder
        Instance.new("UICorner", colFrame).CornerRadius = UDim.new(0, 12)

        local colStroke = Instance.new("UIStroke", colFrame)
        colStroke.Color = Theme.StrokeNormal
        colStroke.Thickness = 1

        -- Header Accent Strip
        local accentColor = CategoryColors[categoryName] or Theme.ItemActive
        local accentStrip = Instance.new("Frame")
        accentStrip.Size = UDim2.new(1, -24, 0, 3)
        accentStrip.Position = UDim2.new(0, 12, 0, 1)
        accentStrip.BackgroundColor3 = accentColor
        accentStrip.BorderSizePixel = 0
        accentStrip.Parent = colFrame
        Instance.new("UICorner", accentStrip).CornerRadius = UDim.new(1, 0)

        -- Title Bar
        local titleBar = Instance.new("Frame")
        titleBar.Name = "TitleBar"
        titleBar.Size = UDim2.new(1, 0, 0, 38)
        titleBar.Position = UDim2.new(0, 0, 0, 4)
        titleBar.BackgroundTransparency = 1
        titleBar.Parent = colFrame

        local catIcon = CategoryIcons[categoryName] or "•"
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -16, 1, 0)
        title.Position = UDim2.new(0, 12, 0, 0)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.Text = catIcon .. "  " .. categoryName
        title.TextColor3 = Theme.TextPrimary
        title.TextSize = 13
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = titleBar

        -- Scrollable Module List
        local scrollHolder = Instance.new("ScrollingFrame")
        scrollHolder.Name = "ScrollHolder"
        scrollHolder.Size = UDim2.new(1, -10, 1, -48)
        scrollHolder.Position = UDim2.new(0, 5, 0, 44)
        scrollHolder.BackgroundTransparency = 1
        scrollHolder.BorderSizePixel = 0
        scrollHolder.ScrollBarThickness = 2
        scrollHolder.ScrollBarImageColor3 = Theme.StrokeNormal
        scrollHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
        scrollHolder.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scrollHolder.Parent = colFrame

        local list = Instance.new("UIListLayout", scrollHolder)
        list.FillDirection = Enum.FillDirection.Vertical
        list.Padding = UDim.new(0, 5)
        list.SortOrder = Enum.SortOrder.LayoutOrder

        for _, mod in ipairs(modules) do
            local card = Instance.new("Frame")
            card.Name = mod.Name
            card.Size = UDim2.new(1, -4, 0, 34)
            card.BackgroundColor3 = Theme.ItemBg
            card.BorderSizePixel = 0
            card.Parent = scrollHolder
            Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

            local cardStroke = Instance.new("UIStroke", card)
            cardStroke.Color = Theme.StrokeNormal
            cardStroke.Thickness = 1
            cardStroke.Transparency = 1

            -- Glowing State Indicator Dot
            local dot = Instance.new("Frame")
            dot.Size = UDim2.new(0, 7, 0, 7)
            dot.Position = UDim2.new(0, 10, 0.5, -3.5)
            dot.BackgroundColor3 = Color3.fromRGB(60, 65, 95)
            dot.BorderSizePixel = 0
            dot.Parent = card
            Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

            -- Module Name Label
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -66, 1, 0)
            nameLabel.Position = UDim2.new(0, 24, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Font = Enum.Font.GothamMedium
            nameLabel.TextSize = 11
            nameLabel.TextColor3 = Theme.TextSecondary
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Text = mod.Name or ""
            nameLabel.Parent = card

            -- Keybind Badge
            local kbLabel = Instance.new("TextLabel")
            kbLabel.Size = UDim2.new(0, 24, 0, 16)
            kbLabel.Position = UDim2.new(1, -46, 0.5, -8)
            kbLabel.BackgroundTransparency = 1
            kbLabel.Font = Enum.Font.GothamBold
            kbLabel.TextSize = 9
            kbLabel.TextColor3 = Theme.TextMuted
            kbLabel.TextXAlignment = Enum.TextXAlignment.Right
            kbLabel.Text = ModuleManager.Keybinds[mod.Name] and ("[" .. ModuleManager.Keybinds[mod.Name]:sub(1, 4) .. "]") or ""
            kbLabel.Parent = card

            -- Gear / Settings Icon Button
            local gearBtn = Instance.new("TextButton")
            gearBtn.Size = UDim2.new(0, 20, 0, 20)
            gearBtn.Position = UDim2.new(1, -22, 0.5, -10)
            gearBtn.BackgroundTransparency = 1
            gearBtn.Font = Enum.Font.GothamBold
            gearBtn.Text = "⚙"
            gearBtn.TextSize = 11
            gearBtn.TextColor3 = Theme.TextMuted
            gearBtn.Parent = card

            -- Full Card Invisible Button for Left / Right Click
            local triggerBtn = Instance.new("TextButton")
            triggerBtn.Size = UDim2.new(1, -24, 1, 0)
            triggerBtn.Position = UDim2.new(0, 0, 0, 0)
            triggerBtn.BackgroundTransparency = 1
            triggerBtn.Text = ""
            triggerBtn.Parent = card

            local info = {
                card      = card,
                mod       = mod,
                dot       = dot,
                nameLabel = nameLabel,
                kbLabel   = kbLabel,
                stroke    = cardStroke,
            }

            local function updateColors()
                local isSelected = (settingsOpen and settingsModName == mod.Name)
                if mod.Enabled then
                    tweenColor(card, Color3.fromRGB(38, 42, 75))
                    nameLabel.TextColor3 = Theme.TextPrimary
                    dot.BackgroundColor3 = Theme.ItemActiveDot
                    cardStroke.Color = Theme.ItemActive
                    cardStroke.Transparency = isSelected and 0 or 0.3
                else
                    tweenColor(card, isSelected and Color3.fromRGB(30, 33, 52) or Theme.ItemBg)
                    nameLabel.TextColor3 = isSelected and Theme.TextPrimary or Theme.TextSecondary
                    dot.BackgroundColor3 = Color3.fromRGB(60, 65, 95)
                    cardStroke.Color = Theme.StrokeAccent
                    cardStroke.Transparency = isSelected and 0.4 or 1
                end
            end
            info.updateColors = updateColors
            updateColors()

            -- SINGLE CLICK ON CARD = TOGGLE MODULE
            triggerBtn.MouseButton1Click:Connect(function()
                ModuleManager:SetEnabled(mod, not mod.Enabled)
                updateColors()
                updateActiveCounter()
                if mod.Enabled then
                    notify(mod.Name .. " включён", 2, Theme.Success)
                else
                    notify(mod.Name .. " выключен", 2, Theme.Danger)
                end
            end)

            -- RIGHT CLICK ON CARD = OPEN SETTINGS
            triggerBtn.MouseButton2Click:Connect(function()
                if settingsOpen and settingsModName == mod.Name then
                    renderSettingsPanel(nil)
                else
                    renderSettingsPanel(mod)
                end
            end)

            -- GEAR ICON = OPEN SETTINGS
            gearBtn.MouseButton1Click:Connect(function()
                if settingsOpen and settingsModName == mod.Name then
                    renderSettingsPanel(nil)
                else
                    renderSettingsPanel(mod)
                end
            end)

            gearBtn.MouseEnter:Connect(function()
                gearBtn.TextColor3 = Theme.TextPrimary
            end)
            gearBtn.MouseLeave:Connect(function()
                gearBtn.TextColor3 = Theme.TextMuted
            end)

            -- Hover Effect on Card
            triggerBtn.MouseEnter:Connect(function()
                if not mod.Enabled and not (settingsOpen and settingsModName == mod.Name) then
                    tweenColor(card, Theme.ItemHover)
                end
            end)

            triggerBtn.MouseLeave:Connect(function()
                updateColors()
            end)

            table.insert(allButtons, info)
        end
    end

    -- ========== REBUILD COLUMNS ==========
    local preferredOrder = {"Combat", "Movement", "Visuals", "Player", "Misc"}

    local function rebuildColumns()
        allButtons = {}
        for _, child in ipairs(columnsHolder:GetChildren()) do
            if child:IsA("GuiObject") and child.Name ~= "UIListLayout" then
                child:Destroy()
            end
        end

        local categoryNames = {}
        for catName, _ in pairs(ModuleManager.Categories) do
            table.insert(categoryNames, catName)
        end

        table.sort(categoryNames, function(a, b)
            local ia, ib
            for i, v in ipairs(preferredOrder) do
                if v == a then ia = i end
                if v == b then ib = i end
            end
            if ia and ib then return ia < ib
            elseif ia then return true
            elseif ib then return false
            else return a < b end
        end)

        local idx = 1
        for _, catName in ipairs(categoryNames) do
            if #ModuleManager.Categories[catName] > 0 then
                createCategoryColumn(catName, ModuleManager.Categories[catName], idx)
                idx = idx + 1
            end
        end

        updateActiveCounter()
    end

    rebuildColumns()

    -- ========== SEARCH FILTER ==========
    local function applySearch()
        local q = searchBox.Text:lower()
        for _, info in ipairs(allButtons) do
            local name = (info.mod.Name or ""):lower()
            local cat  = (info.mod.Category or ""):lower()
            local visible = (q == "") or (string.find(name, q, 1, true) ~= nil) or (string.find(cat, q, 1, true) ~= nil)
            info.card.Visible = visible
        end
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(applySearch)

    -- ========== RELOAD BUTTON EVENT ==========
    reloadBtn.MouseEnter:Connect(function()
        tweenColor(reloadBtn, Color3.fromRGB(36, 40, 64))
        reloadBtn.TextColor3 = Theme.TextPrimary
    end)
    reloadBtn.MouseLeave:Connect(function()
        tweenColor(reloadBtn, Color3.fromRGB(24, 27, 44))
        reloadBtn.TextColor3 = Theme.TextSecondary
    end)

    reloadBtn.MouseButton1Click:Connect(function()
        if ModuleManager.ReloadFromManifest then
            local ok, err = pcall(function() ModuleManager:ReloadFromManifest() end)
            if ok then
                rebuildColumns()
                applySearch()
                if settingsOpen and settingsModName then
                    local m = ModuleManager:GetModuleByName(settingsModName)
                    if m then renderSettingsPanel(m) else renderSettingsPanel(nil) end
                end
                notify("Модули обновлены!", 2, Theme.Success)
            else
                notify("Ошибка обновления: " .. tostring(err), 4, Theme.Danger)
            end
        end
    end)

    -- ========== CLOSE BUTTON EVENT ==========
    closeBtn.MouseEnter:Connect(function()
        tweenColor(closeBtn, Theme.Danger)
        closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    closeBtn.MouseLeave:Connect(function()
        tweenColor(closeBtn, Color3.fromRGB(24, 27, 44))
        closeBtn.TextColor3 = Theme.TextSecondary
    end)

    closeBtn.MouseButton1Click:Connect(function()
        screenGui.Enabled = false
        menuOpen = false
    end)

    -- ========== DRAGGING LOGIC ==========
    local draggingWindow = false
    local dragStartPos = nil
    local frameStartPos = nil

    headerBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingWindow = true
            dragStartPos = input.Position
            frameStartPos = dragFrame.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if draggingWindow and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStartPos
            dragFrame.Position = UDim2.new(
                frameStartPos.X.Scale, frameStartPos.X.Offset + delta.X,
                frameStartPos.Y.Scale, frameStartPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingWindow = false
        end
    end)

    -- ========== OPEN / CLOSE ANIMATIONS ==========
    local function playOpenAnim()
        screenGui.Enabled = true
        dragFrame.Position = UDim2.new(0.5, -totalWidth / 2, 0.5, -totalHeight / 2 - 25)
        TweenService:Create(
            dragFrame,
            TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Position = UDim2.new(0.5, -totalWidth / 2, 0.5, -totalHeight / 2) }
        ):Play()
    end

    local function playCloseAnim()
        local t = TweenService:Create(
            dragFrame,
            TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { Position = UDim2.new(0.5, -totalWidth / 2, 0.5, -totalHeight / 2 - 25) }
        )
        t:Play()
        t.Completed:Connect(function()
            if not menuOpen then
                screenGui.Enabled = false
            end
        end)
    end

    local function setMenuOpen(state)
        if menuOpen == state then return end
        menuOpen = state
        if state then playOpenAnim() else playCloseAnim() end
    end

    -- ========== GLOBAL KEYBIND HANDLER ==========
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        -- Keybind Capture Mode
        if keybindListening and keybindCallback then
            keybindCallback(input)
            return
        end

        -- Toggle Menu (RightShift or Insert)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == Enum.KeyCode.Insert then
                setMenuOpen(not menuOpen)
                return
            end

            -- Trigger Module Keybind
            if menuOpen then return end
            local keyName = input.KeyCode.Name
            for modName, boundKey in pairs(ModuleManager.Keybinds) do
                if boundKey == keyName then
                    local mod = ModuleManager:GetModuleByName(modName)
                    if mod then
                        ModuleManager:SetEnabled(mod, not mod.Enabled)
                        for _, b in ipairs(allButtons) do
                            if b.updateColors then b.updateColors() end
                        end
                        updateActiveCounter()
                        if mod.Enabled then
                            notify(mod.Name .. " включён", 2, Theme.Success)
                        else
                            notify(mod.Name .. " выключен", 2, Theme.Danger)
                        end
                    end
                    break
                end
            end
        end

        -- Mouse Keybinds
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
            if not menuOpen and not keybindListening then
                local keyName = input.UserInputType == Enum.UserInputType.MouseButton1 and "Mouse1" or "Mouse2"
                for modName, boundKey in pairs(ModuleManager.Keybinds) do
                    if boundKey == keyName then
                        local mod = ModuleManager:GetModuleByName(modName)
                        if mod then
                            ModuleManager:SetEnabled(mod, not mod.Enabled)
                            for _, b in ipairs(allButtons) do
                                if b.updateColors then b.updateColors() end
                            end
                            updateActiveCounter()
                            if mod.Enabled then
                                notify(mod.Name .. " включён", 2, Theme.Success)
                            else
                                notify(mod.Name .. " выключен", 2, Theme.Danger)
                            end
                        end
                        break
                    end
                end
            end
        end
    end)
end

return Gui
