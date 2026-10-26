local Gui = {}

function Gui.Init(ModuleManager, Notifications)
    local UserInputService = game:GetService("UserInputService")
    local CoreGui          = game:GetService("CoreGui")
    local TweenService     = game:GetService("TweenService")
    local RunService       = game:GetService("RunService")
    local Players          = game:GetService("Players")

    local LocalPlayer = Players.LocalPlayer

    local parent = CoreGui
    pcall(function()
        if gethui then parent = gethui() end
    end)

    -- ========== RICH-MODERN THEME PALETTE ==========
    local Theme = {
        WindowBg       = Color3.fromRGB(15, 17, 24),        -- Главный фон окна (Obsidian)
        PanelBg        = Color3.fromRGB(20, 23, 34),        -- Фон внутренних карточек
        PanelHeader    = Color3.fromRGB(25, 29, 44),        -- Фон шапок карточек
        CardBg         = Color3.fromRGB(24, 28, 42),        -- Фон элементов/модулей
        CardHover      = Color3.fromRGB(32, 38, 58),        -- При наведении
        CardSelected   = Color3.fromRGB(36, 42, 66),        -- Выбранный модуль
        Accent         = Color3.fromRGB(120, 100, 255),     -- Фирменный Rich-акцент (Electric Purple/Indigo)
        AccentGlow     = Color3.fromRGB(168, 130, 255),     -- Неоновое свечение
        AccentCyan     = Color3.fromRGB(56, 189, 248),      -- Циан акцент
        StrokeDim      = Color3.fromRGB(36, 41, 60),        -- Тонкая рамка (неактивная)
        StrokeHover    = Color3.fromRGB(60, 68, 100),       -- Рамка при наведении
        StrokeActive   = Color3.fromRGB(120, 100, 255),     -- Рамка активная
        TextPrimary    = Color3.fromRGB(245, 247, 250),     -- Яркий белый
        TextSecondary  = Color3.fromRGB(156, 163, 175),     -- Светло-серый
        TextMuted      = Color3.fromRGB(100, 108, 128),     -- Приглушенный
        Success        = Color3.fromRGB(34, 197, 94),       -- Зеленый
        Danger         = Color3.fromRGB(239, 68, 68),       -- Красный
        SwitchOff      = Color3.fromRGB(36, 41, 58),        -- Выключенный свитч
        SwitchOn       = Color3.fromRGB(120, 100, 255),     -- Включенный свитч
    }

    local CategoryData = {
        { Id = "ALL",      Name = "Все модули",  Icon = "★" },
        { Id = "Combat",   Name = "Combat",      Icon = "⚔" },
        { Id = "Movement", Name = "Movement",    Icon = "⚡" },
        { Id = "Visuals",  Name = "Visuals",     Icon = "👁" },
        { Id = "Player",   Name = "Player",      Icon = "🎯" },
        { Id = "Misc",     Name = "Misc",        Icon = "⚙" },
    }

    -- ========== STATE ==========
    local menuOpen             = false
    local selectedCategory     = "Combat"
    local selectedModule       = nil
    local keybindListening     = false
    local keybindCallback      = nil
    local searchQuery          = ""

    local moduleCardItems      = {}  -- Карточки модулей в списке
    local categoryButtons      = {}  -- Кнопки в сайдбаре

    -- ========== SCREEN GUI ==========
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "XclientMenu"
    screenGui.ResetOnSpawn = false
    screenGui.Enabled = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = parent

    -- ========== MAIN WINDOW (RICH-MODERN FRAME) ==========
    local WIN_WIDTH  = 780
    local WIN_HEIGHT = 490

    local mainWindow = Instance.new("Frame")
    mainWindow.Name = "RichModernWindow"
    mainWindow.Size = UDim2.new(0, WIN_WIDTH, 0, WIN_HEIGHT)
    mainWindow.Position = UDim2.new(0.5, -WIN_WIDTH / 2, 0.5, -WIN_HEIGHT / 2)
    mainWindow.BackgroundColor3 = Theme.WindowBg
    mainWindow.BorderSizePixel = 0
    mainWindow.ClipsDescendants = false
    mainWindow.Parent = screenGui
    Instance.new("UICorner", mainWindow).CornerRadius = UDim.new(0, 16)

    local mainStroke = Instance.new("UIStroke", mainWindow)
    mainStroke.Color = Theme.StrokeDim
    mainStroke.Thickness = 1.2

    -- ========== LEFT SIDEBAR ==========
    local SIDEBAR_WIDTH = 175
    local PADDING = 10

    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, SIDEBAR_WIDTH, 1, -PADDING * 2)
    sidebar.Position = UDim2.new(0, PADDING, 0, PADDING)
    sidebar.BackgroundColor3 = Theme.PanelBg
    sidebar.BorderSizePixel = 0
    sidebar.Parent = mainWindow
    Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 12)

    local sidebarStroke = Instance.new("UIStroke", sidebar)
    sidebarStroke.Color = Theme.StrokeDim
    sidebarStroke.Thickness = 1

    -- Brand Card (Top of Sidebar)
    local brandCard = Instance.new("Frame")
    brandCard.Name = "BrandCard"
    brandCard.Size = UDim2.new(1, -16, 0, 46)
    brandCard.Position = UDim2.new(0, 8, 0, 8)
    brandCard.BackgroundColor3 = Theme.PanelHeader
    brandCard.BorderSizePixel = 0
    brandCard.Parent = sidebar
    Instance.new("UICorner", brandCard).CornerRadius = UDim.new(0, 10)

    local brandStroke = Instance.new("UIStroke", brandCard)
    brandStroke.Color = Theme.StrokeDim
    brandStroke.Thickness = 1

    local brandLogo = Instance.new("TextLabel")
    brandLogo.Size = UDim2.new(0, 24, 0, 24)
    brandLogo.Position = UDim2.new(0, 10, 0.5, -12)
    brandLogo.BackgroundTransparency = 1
    brandLogo.Font = Enum.Font.GothamBold
    brandLogo.Text = "⚡"
    brandLogo.TextColor3 = Theme.AccentGlow
    brandLogo.TextSize = 18
    brandLogo.Parent = brandCard

    local brandTitle = Instance.new("TextLabel")
    brandTitle.Size = UDim2.new(1, -44, 0, 18)
    brandTitle.Position = UDim2.new(0, 36, 0, 7)
    brandTitle.BackgroundTransparency = 1
    brandTitle.Font = Enum.Font.GothamBold
    brandTitle.Text = "XCLIENT"
    brandTitle.TextColor3 = Theme.TextPrimary
    brandTitle.TextSize = 13
    brandTitle.TextXAlignment = Enum.TextXAlignment.Left
    brandTitle.Parent = brandCard

    local brandSub = Instance.new("TextLabel")
    brandSub.Size = UDim2.new(1, -44, 0, 14)
    brandSub.Position = UDim2.new(0, 36, 0, 24)
    brandSub.BackgroundTransparency = 1
    brandSub.Font = Enum.Font.Gotham
    brandSub.Text = "v2.0 • Modern"
    brandSub.TextColor3 = Theme.AccentCyan
    brandSub.TextSize = 10
    brandSub.TextXAlignment = Enum.TextXAlignment.Left
    brandSub.Parent = brandCard

    -- Categories Buttons Container
    local catContainer = Instance.new("Frame")
    catContainer.Name = "CategoryList"
    catContainer.Size = UDim2.new(1, -16, 1, -118)
    catContainer.Position = UDim2.new(0, 8, 0, 62)
    catContainer.BackgroundTransparency = 1
    catContainer.Parent = sidebar

    local catLayout = Instance.new("UIListLayout", catContainer)
    catLayout.FillDirection = Enum.FillDirection.Vertical
    catLayout.Padding = UDim.new(0, 4)
    catLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- Profile Card (Bottom of Sidebar)
    local profileCard = Instance.new("Frame")
    profileCard.Name = "ProfileCard"
    profileCard.Size = UDim2.new(1, -16, 0, 42)
    profileCard.Position = UDim2.new(0, 8, 1, -50)
    profileCard.BackgroundColor3 = Theme.PanelHeader
    profileCard.BorderSizePixel = 0
    profileCard.Parent = sidebar
    Instance.new("UICorner", profileCard).CornerRadius = UDim.new(0, 10)

    local profileStroke = Instance.new("UIStroke", profileCard)
    profileStroke.Color = Theme.StrokeDim
    profileStroke.Thickness = 1

    local avatarImg = Instance.new("ImageLabel")
    avatarImg.Name = "Avatar"
    avatarImg.Size = UDim2.new(0, 28, 0, 28)
    avatarImg.Position = UDim2.new(0, 7, 0.5, -14)
    avatarImg.BackgroundColor3 = Color3.fromRGB(30, 35, 52)
    avatarImg.BorderSizePixel = 0
    pcall(function()
        if LocalPlayer and LocalPlayer.UserId then
            avatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=48&h=48"
        end
    end)
    avatarImg.Parent = profileCard
    Instance.new("UICorner", avatarImg).CornerRadius = UDim.new(1, 0)

    local profileName = Instance.new("TextLabel")
    profileName.Size = UDim2.new(1, -44, 0, 16)
    profileName.Position = UDim2.new(0, 42, 0, 6)
    profileName.BackgroundTransparency = 1
    profileName.Font = Enum.Font.GothamBold
    profileName.Text = (LocalPlayer and LocalPlayer.DisplayName) or "Player"
    profileName.TextColor3 = Theme.TextPrimary
    profileName.TextSize = 11
    profileName.TextXAlignment = Enum.TextXAlignment.Left
    profileName.TextTruncate = Enum.TextTruncate.AtEnd
    profileName.Parent = profileCard

    local profileStatus = Instance.new("TextLabel")
    profileStatus.Size = UDim2.new(1, -44, 0, 14)
    profileStatus.Position = UDim2.new(0, 42, 0, 22)
    profileStatus.BackgroundTransparency = 1
    profileStatus.Font = Enum.Font.Gotham
    profileStatus.Text = "Активен"
    profileStatus.TextColor3 = Theme.Success
    profileStatus.TextSize = 10
    profileStatus.TextXAlignment = Enum.TextXAlignment.Left
    profileStatus.Parent = profileCard

    -- ========== RIGHT WORKSPACE AREA ==========
    local RIGHT_X = SIDEBAR_WIDTH + PADDING * 2
    local RIGHT_WIDTH = WIN_WIDTH - RIGHT_X - PADDING

    -- 1. Top Header Card
    local HEADER_HEIGHT = 44
    local headerCard = Instance.new("Frame")
    headerCard.Name = "HeaderCard"
    headerCard.Size = UDim2.new(0, RIGHT_WIDTH, 0, HEADER_HEIGHT)
    headerCard.Position = UDim2.new(0, RIGHT_X, 0, PADDING)
    headerCard.BackgroundColor3 = Theme.PanelBg
    headerCard.BorderSizePixel = 0
    headerCard.Parent = mainWindow
    Instance.new("UICorner", headerCard).CornerRadius = UDim.new(0, 12)

    local headerStroke = Instance.new("UIStroke", headerCard)
    headerStroke.Color = Theme.StrokeDim
    headerStroke.Thickness = 1

    local categoryHeaderTitle = Instance.new("TextLabel")
    categoryHeaderTitle.Name = "CategoryTitle"
    categoryHeaderTitle.Size = UDim2.new(0, 160, 1, 0)
    categoryHeaderTitle.Position = UDim2.new(0, 16, 0, 0)
    categoryHeaderTitle.BackgroundTransparency = 1
    categoryHeaderTitle.Font = Enum.Font.GothamBold
    categoryHeaderTitle.Text = "Combat"
    categoryHeaderTitle.TextColor3 = Theme.TextPrimary
    categoryHeaderTitle.TextSize = 15
    categoryHeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
    categoryHeaderTitle.Parent = headerCard

    -- Search Box
    local searchContainer = Instance.new("Frame")
    searchContainer.Name = "SearchBox"
    searchContainer.Size = UDim2.new(0, 200, 0, 28)
    searchContainer.Position = UDim2.new(1, -196, 0.5, -14)
    searchContainer.BackgroundColor3 = Theme.PanelHeader
    searchContainer.BorderSizePixel = 0
    searchContainer.Parent = headerCard
    Instance.new("UICorner", searchContainer).CornerRadius = UDim.new(0, 8)

    local searchStroke = Instance.new("UIStroke", searchContainer)
    searchStroke.Color = Theme.StrokeDim
    searchStroke.Thickness = 1

    local searchIcon = Instance.new("TextLabel")
    searchIcon.Size = UDim2.new(0, 24, 1, 0)
    searchIcon.Position = UDim2.new(0, 6, 0, 0)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Font = Enum.Font.Gotham
    searchIcon.Text = "🔍"
    searchIcon.TextSize = 11
    searchIcon.TextColor3 = Theme.TextMuted
    searchIcon.Parent = searchContainer

    local searchInput = Instance.new("TextBox")
    searchInput.Size = UDim2.new(1, -34, 1, 0)
    searchInput.Position = UDim2.new(0, 28, 0, 0)
    searchInput.BackgroundTransparency = 1
    searchInput.Font = Enum.Font.Gotham
    searchInput.PlaceholderText = "Поиск функций..."
    searchInput.PlaceholderColor3 = Theme.TextMuted
    searchInput.Text = ""
    searchInput.TextColor3 = Theme.TextPrimary
    searchInput.TextSize = 11
    searchInput.TextXAlignment = Enum.TextXAlignment.Left
    searchInput.ClearTextOnFocus = false
    searchInput.Parent = searchContainer

    -- Reload & Close Buttons
    local reloadBtn = Instance.new("TextButton")
    reloadBtn.Size = UDim2.new(0, 28, 0, 28)
    reloadBtn.Position = UDim2.new(1, -66, 0.5, -14)
    reloadBtn.BackgroundColor3 = Theme.PanelHeader
    reloadBtn.BorderSizePixel = 0
    reloadBtn.AutoButtonColor = false
    reloadBtn.Font = Enum.Font.GothamBold
    reloadBtn.Text = "⟳"
    reloadBtn.TextColor3 = Theme.TextSecondary
    reloadBtn.TextSize = 13
    reloadBtn.Parent = headerCard
    Instance.new("UICorner", reloadBtn).CornerRadius = UDim.new(0, 8)
    local reloadStroke = Instance.new("UIStroke", reloadBtn)
    reloadStroke.Color = Theme.StrokeDim
    reloadStroke.Thickness = 1

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -34, 0.5, -14)
    closeBtn.BackgroundColor3 = Theme.PanelHeader
    closeBtn.BorderSizePixel = 0
    closeBtn.AutoButtonColor = false
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Theme.TextSecondary
    closeBtn.TextSize = 12
    closeBtn.Parent = headerCard
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
    local closeStroke = Instance.new("UIStroke", closeBtn)
    closeStroke.Color = Theme.StrokeDim
    closeStroke.Thickness = 1

    -- Adjust search box position with reload & close present
    searchContainer.Position = UDim2.new(1, -274, 0.5, -14)

    -- 2. Content Card (Modules List on Left + Inspector on Right)
    local CONTENT_Y = PADDING + HEADER_HEIGHT + 8
    local CONTENT_HEIGHT = WIN_HEIGHT - CONTENT_Y - PADDING

    local contentCard = Instance.new("Frame")
    contentCard.Name = "ContentCard"
    contentCard.Size = UDim2.new(0, RIGHT_WIDTH, 0, CONTENT_HEIGHT)
    contentCard.Position = UDim2.new(0, RIGHT_X, 0, CONTENT_Y)
    contentCard.BackgroundColor3 = Theme.PanelBg
    contentCard.BorderSizePixel = 0
    contentCard.Parent = mainWindow
    Instance.new("UICorner", contentCard).CornerRadius = UDim.new(0, 12)

    local contentStroke = Instance.new("UIStroke", contentCard)
    contentStroke.Color = Theme.StrokeDim
    contentStroke.Thickness = 1

    -- Left Pane: Module List
    local MODULE_LIST_WIDTH = 215

    local moduleListFrame = Instance.new("ScrollingFrame")
    moduleListFrame.Name = "ModuleList"
    moduleListFrame.Size = UDim2.new(0, MODULE_LIST_WIDTH, 1, -16)
    moduleListFrame.Position = UDim2.new(0, 10, 0, 8)
    moduleListFrame.BackgroundTransparency = 1
    moduleListFrame.BorderSizePixel = 0
    moduleListFrame.ScrollBarThickness = 2
    moduleListFrame.ScrollBarImageColor3 = Theme.StrokeDim
    moduleListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    moduleListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    moduleListFrame.Parent = contentCard

    local moduleListLayout = Instance.new("UIListLayout", moduleListFrame)
    moduleListLayout.Padding = UDim.new(0, 5)
    moduleListLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- Vertical Divider
    local divider = Instance.new("Frame")
    divider.Name = "Divider"
    divider.Size = UDim2.new(0, 1, 1, -16)
    divider.Position = UDim2.new(0, MODULE_LIST_WIDTH + 18, 0, 8)
    divider.BackgroundColor3 = Theme.StrokeDim
    divider.BorderSizePixel = 0
    divider.Parent = contentCard

    -- Right Pane: Inspector / Settings Panel
    local INSPECTOR_X = MODULE_LIST_WIDTH + 26
    local INSPECTOR_WIDTH = RIGHT_WIDTH - INSPECTOR_X - 10

    local inspectorFrame = Instance.new("Frame")
    inspectorFrame.Name = "Inspector"
    inspectorFrame.Size = UDim2.new(0, INSPECTOR_WIDTH, 1, -16)
    inspectorFrame.Position = UDim2.new(0, INSPECTOR_X, 0, 8)
    inspectorFrame.BackgroundTransparency = 1
    inspectorFrame.Parent = contentCard

    local inspectorScroll = Instance.new("ScrollingFrame")
    inspectorScroll.Name = "InspectorScroll"
    inspectorScroll.Size = UDim2.new(1, 0, 1, 0)
    inspectorScroll.BackgroundTransparency = 1
    inspectorScroll.BorderSizePixel = 0
    inspectorScroll.ScrollBarThickness = 3
    inspectorScroll.ScrollBarImageColor3 = Theme.Accent
    inspectorScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    inspectorScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    inspectorScroll.Parent = inspectorFrame

    local inspectorLayout = Instance.new("UIListLayout", inspectorScroll)
    inspectorLayout.Padding = UDim.new(0, 8)
    inspectorLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- ========== HELPERS ==========
    local function notify(text, dur, color)
        if Notifications and Notifications.Show then
            Notifications:Show(text, dur, color)
        end
    end

    local function tween(inst, props, dur)
        TweenService:Create(
            inst,
            TweenInfo.new(dur or 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            props
        ):Play()
    end

    -- ========== INSPECTOR RENDERING ==========
    local function renderInspector(mod)
        for _, child in ipairs(inspectorScroll:GetChildren()) do
            if child:IsA("GuiObject") then child:Destroy() end
        end

        if not mod then
            -- Empty state
            local empty = Instance.new("Frame")
            empty.Size = UDim2.new(1, 0, 1, 0)
            empty.BackgroundTransparency = 1
            empty.Parent = inspectorScroll

            local icon = Instance.new("TextLabel")
            icon.Size = UDim2.new(1, 0, 0, 36)
            icon.Position = UDim2.new(0, 0, 0.35, 0)
            icon.BackgroundTransparency = 1
            icon.Font = Enum.Font.Gotham
            icon.Text = "⚡"
            icon.TextColor3 = Theme.TextMuted
            icon.TextSize = 28
            icon.Parent = empty

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 0, 20)
            lbl.Position = UDim2.new(0, 0, 0.35, 38)
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.GothamMedium
            lbl.Text = "Выберите модуль для настройки"
            lbl.TextColor3 = Theme.TextMuted
            lbl.TextSize = 12
            lbl.Parent = empty
            return
        end

        -- Header Card in Inspector
        local headerCardMod = Instance.new("Frame")
        headerCardMod.Name = "ModHeader"
        headerCardMod.Size = UDim2.new(1, -4, 0, 52)
        headerCardMod.BackgroundColor3 = Theme.CardBg
        headerCardMod.BorderSizePixel = 0
        headerCardMod.LayoutOrder = 1
        headerCardMod.Parent = inspectorScroll
        Instance.new("UICorner", headerCardMod).CornerRadius = UDim.new(0, 10)

        local hmStroke = Instance.new("UIStroke", headerCardMod)
        hmStroke.Color = Theme.StrokeDim
        hmStroke.Thickness = 1

        local modNameLbl = Instance.new("TextLabel")
        modNameLbl.Size = UDim2.new(0.65, 0, 0, 20)
        modNameLbl.Position = UDim2.new(0, 12, 0, 8)
        modNameLbl.BackgroundTransparency = 1
        modNameLbl.Font = Enum.Font.GothamBold
        modNameLbl.Text = mod.Name or "Unknown"
        modNameLbl.TextColor3 = Theme.TextPrimary
        modNameLbl.TextSize = 14
        modNameLbl.TextXAlignment = Enum.TextXAlignment.Left
        modNameLbl.Parent = headerCardMod

        local catTag = Instance.new("TextLabel")
        catTag.Size = UDim2.new(0.65, 0, 0, 14)
        catTag.Position = UDim2.new(0, 12, 0, 30)
        catTag.BackgroundTransparency = 1
        catTag.Font = Enum.Font.Gotham
        catTag.Text = "Категория: " .. (mod.Category or "Misc")
        catTag.TextColor3 = Theme.AccentGlow
        catTag.TextSize = 10
        catTag.TextXAlignment = Enum.TextXAlignment.Left
        catTag.Parent = headerCardMod

        -- Master Switch in Inspector Header
        local masterSwitch = Instance.new("TextButton")
        masterSwitch.Size = UDim2.new(0, 44, 0, 22)
        masterSwitch.Position = UDim2.new(1, -54, 0.5, -11)
        masterSwitch.BackgroundColor3 = mod.Enabled and Theme.SwitchOn or Theme.SwitchOff
        masterSwitch.BorderSizePixel = 0
        masterSwitch.AutoButtonColor = false
        masterSwitch.Text = ""
        masterSwitch.Parent = headerCardMod
        Instance.new("UICorner", masterSwitch).CornerRadius = UDim.new(1, 0)

        local masterThumb = Instance.new("Frame")
        masterThumb.Size = UDim2.new(0, 16, 0, 16)
        masterThumb.Position = mod.Enabled and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        masterThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        masterThumb.BorderSizePixel = 0
        masterThumb.Parent = masterSwitch
        Instance.new("UICorner", masterThumb).CornerRadius = UDim.new(1, 0)

        masterSwitch.MouseButton1Click:Connect(function()
            ModuleManager:SetEnabled(mod, not mod.Enabled)
            local state = mod.Enabled
            tween(masterSwitch, { BackgroundColor3 = state and Theme.SwitchOn or Theme.SwitchOff })
            tween(masterThumb, { Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8) })

            -- Refresh list item switch
            for _, item in ipairs(moduleCardItems) do
                if item.mod == mod and item.updateState then
                    item.updateState()
                end
            end

            if state then
                notify(mod.Name .. " включён", 2, Theme.Success)
            else
                notify(mod.Name .. " выключен", 2, Theme.Danger)
            end
        end)

        -- Keybind Row
        local kbRow = Instance.new("Frame")
        kbRow.Size = UDim2.new(1, -4, 0, 36)
        kbRow.BackgroundColor3 = Theme.CardBg
        kbRow.BorderSizePixel = 0
        kbRow.LayoutOrder = 2
        kbRow.Parent = inspectorScroll
        Instance.new("UICorner", kbRow).CornerRadius = UDim.new(0, 8)

        local kbStroke = Instance.new("UIStroke", kbRow)
        kbStroke.Color = Theme.StrokeDim
        kbStroke.Thickness = 1

        local kbLabel = Instance.new("TextLabel")
        kbLabel.Size = UDim2.new(0.5, 0, 1, 0)
        kbLabel.Position = UDim2.new(0, 12, 0, 0)
        kbLabel.BackgroundTransparency = 1
        kbLabel.Font = Enum.Font.GothamMedium
        kbLabel.Text = "Горячая клавиша"
        kbLabel.TextColor3 = Theme.TextSecondary
        kbLabel.TextSize = 11
        kbLabel.TextXAlignment = Enum.TextXAlignment.Left
        kbLabel.Parent = kbRow

        local kbBtn = Instance.new("TextButton")
        kbBtn.Size = UDim2.new(0.42, 0, 0, 24)
        kbBtn.Position = UDim2.new(0.56, 0, 0.5, -12)
        kbBtn.BackgroundColor3 = Theme.PanelHeader
        kbBtn.BorderSizePixel = 0
        kbBtn.AutoButtonColor = false
        kbBtn.Font = Enum.Font.GothamBold
        kbBtn.TextSize = 11
        kbBtn.TextColor3 = Theme.AccentCyan
        kbBtn.Text = ModuleManager.Keybinds[mod.Name] and ("[" .. ModuleManager.Keybinds[mod.Name] .. "]") or "[ Нет ]"
        kbBtn.Parent = kbRow
        Instance.new("UICorner", kbBtn).CornerRadius = UDim.new(0, 6)

        local kbBtnStroke = Instance.new("UIStroke", kbBtn)
        kbBtnStroke.Color = Theme.StrokeDim
        kbBtnStroke.Thickness = 1

        kbBtn.MouseButton1Click:Connect(function()
            if keybindListening then return end
            keybindListening = true
            kbBtn.Text = "[ Нажмите... ]"
            kbBtn.TextColor3 = Theme.AccentGlow

            keybindCallback = function(input)
                keybindListening = false
                keybindCallback = nil

                local keyName = nil
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    if input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Escape then
                        ModuleManager.Keybinds[mod.Name] = nil
                        kbBtn.Text = "[ Нет ]"
                        kbBtn.TextColor3 = Theme.TextSecondary
                        for _, item in ipairs(moduleCardItems) do
                            if item.mod == mod and item.kbTag then item.kbTag.Text = "" end
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
                    kbBtn.TextColor3 = Theme.AccentCyan
                    for _, item in ipairs(moduleCardItems) do
                        if item.mod == mod and item.kbTag then
                            item.kbTag.Text = "[" .. keyName:sub(1, 4) .. "]"
                        end
                    end
                end
            end
        end)

        -- Settings definitions rendering
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
                    card.Size = UDim2.new(1, -4, 0, 50)
                    card.BackgroundColor3 = Theme.CardBg
                    card.BorderSizePixel = 0
                    card.LayoutOrder = orderCounter
                    card.Parent = inspectorScroll
                    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

                    local sStroke = Instance.new("UIStroke", card)
                    sStroke.Color = Theme.StrokeDim
                    sStroke.Thickness = 1

                    local lbl = Instance.new("TextLabel")
                    lbl.Size = UDim2.new(0.65, 0, 0, 20)
                    lbl.Position = UDim2.new(0, 12, 0, 5)
                    lbl.BackgroundTransparency = 1
                    lbl.Font = Enum.Font.GothamMedium
                    lbl.Text = sName
                    lbl.TextColor3 = Theme.TextSecondary
                    lbl.TextSize = 11
                    lbl.TextXAlignment = Enum.TextXAlignment.Left
                    lbl.Parent = card

                    local valLbl = Instance.new("TextLabel")
                    valLbl.Size = UDim2.new(0.3, 0, 0, 20)
                    valLbl.Position = UDim2.new(0.7, -12, 0, 5)
                    valLbl.BackgroundTransparency = 1
                    valLbl.Font = Enum.Font.GothamBold
                    valLbl.Text = tostring(currentVal) .. sSuffix
                    valLbl.TextColor3 = Theme.AccentGlow
                    valLbl.TextSize = 11
                    valLbl.TextXAlignment = Enum.TextXAlignment.Right
                    valLbl.Parent = card

                    local barBg = Instance.new("Frame")
                    barBg.Size = UDim2.new(1, -24, 0, 8)
                    barBg.Position = UDim2.new(0, 12, 0, 30)
                    barBg.BackgroundColor3 = Color3.fromRGB(36, 41, 60)
                    barBg.BorderSizePixel = 0
                    barBg.Parent = card
                    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

                    local barFill = Instance.new("Frame")
                    local pct = math.clamp((currentVal - sMin) / (sMax - sMin), 0, 1)
                    barFill.Size = UDim2.new(pct, 0, 1, 0)
                    barFill.BackgroundColor3 = Theme.Accent
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
                    row.Size = UDim2.new(1, -4, 0, 36)
                    row.BackgroundColor3 = Theme.CardBg
                    row.BorderSizePixel = 0
                    row.LayoutOrder = orderCounter
                    row.Parent = inspectorScroll
                    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

                    local tStroke = Instance.new("UIStroke", row)
                    tStroke.Color = Theme.StrokeDim
                    tStroke.Thickness = 1

                    local lbl = Instance.new("TextLabel")
                    lbl.Size = UDim2.new(1, -60, 1, 0)
                    lbl.Position = UDim2.new(0, 12, 0, 0)
                    lbl.BackgroundTransparency = 1
                    lbl.Font = Enum.Font.GothamMedium
                    lbl.Text = sName
                    lbl.TextColor3 = Theme.TextSecondary
                    lbl.TextSize = 11
                    lbl.TextXAlignment = Enum.TextXAlignment.Left
                    lbl.Parent = row

                    local sw = Instance.new("TextButton")
                    sw.Size = UDim2.new(0, 40, 0, 20)
                    sw.Position = UDim2.new(1, -50, 0.5, -10)
                    sw.BackgroundColor3 = currentVal and Theme.SwitchOn or Theme.SwitchOff
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
                        tween(sw, { BackgroundColor3 = currentVal and Theme.SwitchOn or Theme.SwitchOff })
                        tween(th, { Position = currentVal and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7) })
                    end)

                elseif sType == "Dropdown" then
                    local sOptions = def.Options or {}
                    local currentVal = sDefault or sOptions[1] or ""
                    if mod.__settings__ and mod.__settings__[sKey] ~= nil then
                        currentVal = mod.__settings__[sKey]
                    end

                    local row = Instance.new("Frame")
                    row.Size = UDim2.new(1, -4, 0, 36)
                    row.BackgroundColor3 = Theme.CardBg
                    row.BorderSizePixel = 0
                    row.LayoutOrder = orderCounter
                    row.Parent = inspectorScroll
                    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

                    local dStroke = Instance.new("UIStroke", row)
                    dStroke.Color = Theme.StrokeDim
                    dStroke.Thickness = 1

                    local lbl = Instance.new("TextLabel")
                    lbl.Size = UDim2.new(0.5, 0, 1, 0)
                    lbl.Position = UDim2.new(0, 12, 0, 0)
                    lbl.BackgroundTransparency = 1
                    lbl.Font = Enum.Font.GothamMedium
                    lbl.Text = sName
                    lbl.TextColor3 = Theme.TextSecondary
                    lbl.TextSize = 11
                    lbl.TextXAlignment = Enum.TextXAlignment.Left
                    lbl.Parent = row

                    local dropBtn = Instance.new("TextButton")
                    dropBtn.Size = UDim2.new(0.44, 0, 0, 24)
                    dropBtn.Position = UDim2.new(0.54, 0, 0.5, -12)
                    dropBtn.BackgroundColor3 = Theme.PanelHeader
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
        else
            -- No parameters row
            local emptyRow = Instance.new("Frame")
            emptyRow.Size = UDim2.new(1, -4, 0, 50)
            emptyRow.BackgroundColor3 = Theme.CardBg
            emptyRow.BorderSizePixel = 0
            emptyRow.LayoutOrder = 3
            emptyRow.Parent = inspectorScroll
            Instance.new("UICorner", emptyRow).CornerRadius = UDim.new(0, 8)

            local noSettingsLbl = Instance.new("TextLabel")
            noSettingsLbl.Size = UDim2.new(1, 0, 1, 0)
            noSettingsLbl.BackgroundTransparency = 1
            noSettingsLbl.Font = Enum.Font.Gotham
            noSettingsLbl.Text = "У данной функции нет дополнительных параметров"
            noSettingsLbl.TextColor3 = Theme.TextMuted
            noSettingsLbl.TextSize = 11
            noSettingsLbl.Parent = emptyRow
        end
    end

    -- ========== MODULE LIST RENDERING ==========
    local function renderModuleList()
        for _, child in ipairs(moduleListFrame:GetChildren()) do
            if child:IsA("GuiObject") then child:Destroy() end
        end
        moduleCardItems = {}

        local listToDisplay = {}
        local q = searchQuery:lower()

        for _, mod in ipairs(ModuleManager.Modules) do
            local matchesCat = (selectedCategory == "ALL") or (mod.Category == selectedCategory)
            local matchesSearch = (q == "") or (string.find((mod.Name or ""):lower(), q, 1, true) ~= nil)
            if matchesCat and matchesSearch then
                table.insert(listToDisplay, mod)
            end
        end

        if #listToDisplay == 0 then
            local emptyCard = Instance.new("Frame")
            emptyCard.Size = UDim2.new(1, 0, 0, 50)
            emptyCard.BackgroundTransparency = 1
            emptyCard.Parent = moduleListFrame

            local emptyLbl = Instance.new("TextLabel")
            emptyLbl.Size = UDim2.new(1, 0, 1, 0)
            emptyLbl.BackgroundTransparency = 1
            emptyLbl.Font = Enum.Font.Gotham
            emptyLbl.Text = "Ничего не найдено"
            emptyLbl.TextColor3 = Theme.TextMuted
            emptyLbl.TextSize = 11
            emptyLbl.Parent = emptyCard
            return
        end

        -- If current selected module is not in list, auto-select first
        local hasCurrent = false
        for _, m in ipairs(listToDisplay) do
            if m == selectedModule then hasCurrent = true break end
        end
        if not hasCurrent and #listToDisplay > 0 then
            selectedModule = listToDisplay[1]
        end
        renderInspector(selectedModule)

        for _, mod in ipairs(listToDisplay) do
            local card = Instance.new("Frame")
            card.Name = mod.Name
            card.Size = UDim2.new(1, -6, 0, 36)
            card.BackgroundColor3 = (selectedModule == mod) and Theme.CardSelected or Theme.CardBg
            card.BorderSizePixel = 0
            card.Parent = moduleListFrame
            Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

            local cardStroke = Instance.new("UIStroke", card)
            cardStroke.Color = (selectedModule == mod) and Theme.StrokeActive or Theme.StrokeDim
            cardStroke.Thickness = 1

            -- Module Name
            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size = UDim2.new(1, -78, 1, 0)
            nameLbl.Position = UDim2.new(0, 10, 0, 0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Font = Enum.Font.GothamMedium
            nameLbl.Text = mod.Name or ""
            nameLbl.TextColor3 = mod.Enabled and Theme.TextPrimary or Theme.TextSecondary
            nameLbl.TextSize = 11
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
            nameLbl.Parent = card

            -- Keybind indicator tag
            local kbTag = Instance.new("TextLabel")
            kbTag.Size = UDim2.new(0, 26, 0, 14)
            kbTag.Position = UDim2.new(1, -72, 0.5, -7)
            kbTag.BackgroundTransparency = 1
            kbTag.Font = Enum.Font.GothamBold
            kbTag.Text = ModuleManager.Keybinds[mod.Name] and ("[" .. ModuleManager.Keybinds[mod.Name]:sub(1, 3) .. "]") or ""
            kbTag.TextColor3 = Theme.TextMuted
            kbTag.TextSize = 9
            kbTag.TextXAlignment = Enum.TextXAlignment.Right
            kbTag.Parent = card

            -- Modern Toggle Switch on Card
            local sw = Instance.new("TextButton")
            sw.Size = UDim2.new(0, 34, 0, 18)
            sw.Position = UDim2.new(1, -42, 0.5, -9)
            sw.BackgroundColor3 = mod.Enabled and Theme.SwitchOn or Theme.SwitchOff
            sw.BorderSizePixel = 0
            sw.AutoButtonColor = false
            sw.Text = ""
            sw.Parent = card
            Instance.new("UICorner", sw).CornerRadius = UDim.new(1, 0)

            local th = Instance.new("Frame")
            th.Size = UDim2.new(0, 12, 0, 12)
            th.Position = mod.Enabled and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
            th.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            th.BorderSizePixel = 0
            th.Parent = sw
            Instance.new("UICorner", th).CornerRadius = UDim.new(1, 0)

            -- Invisible button over card body to select module
            local selectBtn = Instance.new("TextButton")
            selectBtn.Size = UDim2.new(1, -44, 1, 0)
            selectBtn.Position = UDim2.new(0, 0, 0, 0)
            selectBtn.BackgroundTransparency = 1
            selectBtn.Text = ""
            selectBtn.Parent = card

            local function updateCardVisuals()
                local isSel = (selectedModule == mod)
                card.BackgroundColor3 = isSel and Theme.CardSelected or Theme.CardBg
                cardStroke.Color = isSel and Theme.StrokeActive or Theme.StrokeDim
                nameLbl.TextColor3 = mod.Enabled and Theme.TextPrimary or (isSel and Theme.TextPrimary or Theme.TextSecondary)
                tween(sw, { BackgroundColor3 = mod.Enabled and Theme.SwitchOn or Theme.SwitchOff })
                tween(th, { Position = mod.Enabled and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6) })
            end

            -- Click switch -> Toggle on/off
            sw.MouseButton1Click:Connect(function()
                ModuleManager:SetEnabled(mod, not mod.Enabled)
                updateCardVisuals()
                if selectedModule == mod then
                    renderInspector(mod)
                end
                if mod.Enabled then
                    notify(mod.Name .. " включён", 2, Theme.Success)
                else
                    notify(mod.Name .. " выключен", 2, Theme.Danger)
                end
            end)

            -- Click card -> Select and inspect
            selectBtn.MouseButton1Click:Connect(function()
                selectedModule = mod
                for _, item in ipairs(moduleCardItems) do
                    if item.updateVisuals then item.updateVisuals() end
                end
                renderInspector(mod)
            end)

            -- Hover effect
            selectBtn.MouseEnter:Connect(function()
                if selectedModule ~= mod then
                    tween(card, { BackgroundColor3 = Theme.CardHover })
                end
            end)
            selectBtn.MouseLeave:Connect(function()
                updateCardVisuals()
            end)

            table.insert(moduleCardItems, {
                mod           = mod,
                card          = card,
                kbTag         = kbTag,
                updateState   = updateCardVisuals,
                updateVisuals = updateCardVisuals,
            })
        end
    end

    -- ========== SIDEBAR CATEGORY BUTTONS ==========
    local function renderCategories()
        for _, btn in ipairs(categoryButtons) do
            btn:Destroy()
        end
        categoryButtons = {}

        for _, cat in ipairs(CategoryData) do
            local isSelected = (selectedCategory == cat.Id)

            local btn = Instance.new("TextButton")
            btn.Name = "Cat_" .. cat.Id
            btn.Size = UDim2.new(1, 0, 0, 32)
            btn.BackgroundColor3 = isSelected and Theme.PanelHeader or Color3.fromRGB(20, 23, 34)
            btn.BackgroundTransparency = isSelected and 0 or 1
            btn.BorderSizePixel = 0
            btn.AutoButtonColor = false
            btn.Text = ""
            btn.Parent = catContainer
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

            local btnStroke = Instance.new("UIStroke", btn)
            btnStroke.Color = isSelected and Theme.StrokeActive or Theme.StrokeDim
            btnStroke.Thickness = 1
            btnStroke.Transparency = isSelected and 0 or 1

            local iconLbl = Instance.new("TextLabel")
            iconLbl.Size = UDim2.new(0, 20, 1, 0)
            iconLbl.Position = UDim2.new(0, 10, 0, 0)
            iconLbl.BackgroundTransparency = 1
            iconLbl.Font = Enum.Font.GothamBold
            iconLbl.Text = cat.Icon
            iconLbl.TextColor3 = isSelected and Theme.AccentGlow or Theme.TextMuted
            iconLbl.TextSize = 13
            iconLbl.Parent = btn

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size = UDim2.new(1, -38, 1, 0)
            nameLbl.Position = UDim2.new(0, 34, 0, 0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Font = Enum.Font.GothamMedium
            nameLbl.Text = cat.Name
            nameLbl.TextColor3 = isSelected and Theme.TextPrimary or Theme.TextSecondary
            nameLbl.TextSize = 11
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.Parent = btn

            btn.MouseButton1Click:Connect(function()
                if selectedCategory == cat.Id then return end
                selectedCategory = cat.Id
                categoryHeaderTitle.Text = cat.Name
                renderCategories()
                renderModuleList()
            end)

            btn.MouseEnter:Connect(function()
                if selectedCategory ~= cat.Id then
                    tween(btn, { BackgroundTransparency = 0.5 })
                end
            end)
            btn.MouseLeave:Connect(function()
                if selectedCategory ~= cat.Id then
                    tween(btn, { BackgroundTransparency = 1 })
                end
            end)

            table.insert(categoryButtons, btn)
        end
    end

    renderCategories()
    renderModuleList()

    -- ========== SEARCH FILTER ==========
    searchInput:GetPropertyChangedSignal("Text"):Connect(function()
        searchQuery = searchInput.Text
        if searchQuery ~= "" then
            categoryHeaderTitle.Text = "Результаты поиска"
        else
            for _, c in ipairs(CategoryData) do
                if c.Id == selectedCategory then
                    categoryHeaderTitle.Text = c.Name
                    break
                end
            end
        end
        renderModuleList()
    end)

    -- ========== RELOAD BUTTON ==========
    reloadBtn.MouseEnter:Connect(function()
        tween(reloadBtn, { BackgroundColor3 = Theme.CardHover })
        reloadBtn.TextColor3 = Theme.TextPrimary
    end)
    reloadBtn.MouseLeave:Connect(function()
        tween(reloadBtn, { BackgroundColor3 = Theme.PanelHeader })
        reloadBtn.TextColor3 = Theme.TextSecondary
    end)

    reloadBtn.MouseButton1Click:Connect(function()
        if ModuleManager.ReloadFromManifest then
            local ok, err = pcall(function() ModuleManager:ReloadFromManifest() end)
            if ok then
                renderModuleList()
                notify("Модули обновлены!", 2, Theme.Success)
            else
                notify("Ошибка обновления: " .. tostring(err), 4, Theme.Danger)
            end
        end
    end)

    -- ========== CLOSE BUTTON ==========
    closeBtn.MouseEnter:Connect(function()
        tween(closeBtn, { BackgroundColor3 = Theme.Danger })
        closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    closeBtn.MouseLeave:Connect(function()
        tween(closeBtn, { BackgroundColor3 = Theme.PanelHeader })
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

    local function setupDragOn(inst)
        inst.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                draggingWindow = true
                dragStartPos = input.Position
                frameStartPos = mainWindow.Position
            end
        end)
    end

    setupDragOn(headerCard)
    setupDragOn(brandCard)

    UserInputService.InputChanged:Connect(function(input)
        if draggingWindow and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStartPos
            mainWindow.Position = UDim2.new(
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

    -- ========== OPEN / CLOSE ANIMATION ==========
    local function playOpenAnim()
        screenGui.Enabled = true
        mainWindow.Position = UDim2.new(0.5, -WIN_WIDTH / 2, 0.5, -WIN_HEIGHT / 2 - 20)
        TweenService:Create(
            mainWindow,
            TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Position = UDim2.new(0.5, -WIN_WIDTH / 2, 0.5, -WIN_HEIGHT / 2) }
        ):Play()
    end

    local function playCloseAnim()
        local t = TweenService:Create(
            mainWindow,
            TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { Position = UDim2.new(0.5, -WIN_WIDTH / 2, 0.5, -WIN_HEIGHT / 2 - 20) }
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
                        for _, item in ipairs(moduleCardItems) do
                            if item.mod == mod and item.updateState then
                                item.updateState()
                            end
                        end
                        if selectedModule == mod then
                            renderInspector(mod)
                        end
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
                            for _, item in ipairs(moduleCardItems) do
                                if item.mod == mod and item.updateState then
                                    item.updateState()
                                end
                            end
                            if selectedModule == mod then
                                renderInspector(mod)
                            end
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
