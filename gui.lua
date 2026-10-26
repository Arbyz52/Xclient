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

    -- ========== LUCIDE VECTOR ICON ASSETS (SHARP & NATIVE) ==========
    local Icons = {
        Swords      = "rbxassetid://10734975692", -- Combat
        Wind        = "rbxassetid://10747382750", -- Movement
        Eye         = "rbxassetid://10723346959", -- Visuals
        Target      = "rbxassetid://10734977012", -- Player
        Sliders     = "rbxassetid://10734963400", -- Misc
        Star        = "rbxassetid://10734966248", -- Favorites / All
        Settings    = "rbxassetid://10734950309", -- Menu Settings
        Search      = "rbxassetid://10734943674", -- Search Bar
        Refresh     = "rbxassetid://10734940654", -- Reload Manifest
        Close       = "rbxassetid://10747384394", -- Close Window
        ChevronDown = "rbxassetid://10709790948", -- Dropdown Arrow
        Zap         = "rbxassetid://10723376114", -- Logo
    }

    -- ========== THICK MODERN FONTS ==========
    local BoldFont     = Enum.Font.Montserrat
    local HeavyFont    = Enum.Font.GothamBold
    local SemiBoldFont = Enum.Font.GothamBold

    -- ========== MENU SETTINGS & THEME STATE ==========
    local MenuConfig = {
        LiquidGlass    = true,
        MenuGlow       = true,
        WindowOpacity  = 0.95,
        AnimationSpeed = 1.0,
        AccentColor    = Color3.fromRGB(120, 100, 255), -- Фирменный Rich Purple/Indigo
    }

    local AccentPresets = {
        { Name = "Фиолетовый", Color = Color3.fromRGB(120, 100, 255) },
        { Name = "Электро-циан", Color = Color3.fromRGB(56, 189, 248) },
        { Name = "Изумруд",    Color = Color3.fromRGB(34, 197, 94) },
        { Name = "Рубин",      Color = Color3.fromRGB(239, 68, 68) },
        { Name = "Янтарь",     Color = Color3.fromRGB(245, 158, 11) },
        { Name = "Неон-розовый", Color = Color3.fromRGB(236, 72, 153) },
        { Name = "Синий",      Color = Color3.fromRGB(59, 130, 246) },
    }

    local Theme = {
        WindowBg      = Color3.fromRGB(13, 15, 22),
        PanelBg       = Color3.fromRGB(18, 21, 32),
        PanelHeader   = Color3.fromRGB(24, 28, 44),
        CardBg        = Color3.fromRGB(23, 27, 40),
        CardHover     = Color3.fromRGB(30, 36, 54),
        CardSelected  = Color3.fromRGB(34, 40, 62),
        StrokeDim     = Color3.fromRGB(38, 43, 62),
        StrokeGlass   = Color3.fromRGB(255, 255, 255),
        TextPrimary   = Color3.fromRGB(250, 252, 255),
        TextSecondary = Color3.fromRGB(165, 175, 195),
        TextMuted     = Color3.fromRGB(105, 115, 138),
        Success       = Color3.fromRGB(34, 197, 94),
        Danger        = Color3.fromRGB(239, 68, 68),
        SwitchOff     = Color3.fromRGB(36, 42, 60),
    }

    local Categories = {
        { Id = "ALL",      Name = "Все модули",     Icon = Icons.Star },
        { Id = "Combat",   Name = "Combat",         Icon = Icons.Swords },
        { Id = "Movement", Name = "Movement",       Icon = Icons.Wind },
        { Id = "Visuals",  Name = "Visuals",        Icon = Icons.Eye },
        { Id = "Player",   Name = "Player",         Icon = Icons.Target },
        { Id = "Misc",     Name = "Misc",           Icon = Icons.Sliders },
        { Id = "SETTINGS", Name = "Настройки меню", Icon = Icons.Settings, IsSpecial = true },
    }

    -- ========== STATE ==========
    local menuOpen             = false
    local selectedCategory     = "Combat"
    local selectedModule       = nil
    local keybindListening     = false
    local keybindCallback      = nil
    local searchQuery          = ""

    local currentWidth         = 850
    local currentHeight        = 520
    local MIN_WIDTH            = 720
    local MIN_HEIGHT           = 450

    local moduleCardItems      = {}
    local categoryButtons      = {}
    local accentColorObjects   = {}

    -- ========== SCREEN GUI ==========
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "XclientMenu"
    screenGui.ResetOnSpawn = false
    screenGui.Enabled = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = parent

    -- ========== MAIN WINDOW (RICH-MODERN SHELL) ==========
    local mainWindow = Instance.new("Frame")
    mainWindow.Name = "RichModernWindow"
    mainWindow.Size = UDim2.new(0, currentWidth, 0, currentHeight)
    mainWindow.Position = UDim2.new(0.5, -currentWidth / 2, 0.5, -currentHeight / 2)
    mainWindow.BackgroundColor3 = Theme.WindowBg
    mainWindow.BackgroundTransparency = 1 - MenuConfig.WindowOpacity
    mainWindow.BorderSizePixel = 0
    mainWindow.ClipsDescendants = false
    mainWindow.Parent = screenGui
    Instance.new("UICorner", mainWindow).CornerRadius = UDim.new(0, 16)

    -- Liquid Glass Specular Gradient Stroke
    local mainStroke = Instance.new("UIStroke", mainWindow)
    mainStroke.Color = Theme.StrokeGlass
    mainStroke.Thickness = 1.4
    mainStroke.Transparency = 0.82

    local strokeGradient = Instance.new("UIGradient", mainStroke)
    strokeGradient.Rotation = 45
    strokeGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.3, MenuConfig.AccentColor),
        ColorSequenceKeypoint.new(0.7, Color3.fromRGB(60, 65, 90)),
        ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 255, 255)),
    })
    strokeGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0.0, 0.2),
        NumberSequenceKeypoint.new(0.4, 0.6),
        NumberSequenceKeypoint.new(1.0, 0.9),
    })

    -- Specular Glass Highlight Line (Top Sheen)
    local topSheen = Instance.new("Frame")
    topSheen.Name = "TopGlassSheen"
    topSheen.Size = UDim2.new(1, -32, 0, 1)
    topSheen.Position = UDim2.new(0, 16, 0, 1)
    topSheen.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    topSheen.BorderSizePixel = 0
    topSheen.Parent = mainWindow

    local sheenGrad = Instance.new("UIGradient", topSheen)
    sheenGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0.0, 1.0),
        NumberSequenceKeypoint.new(0.5, 0.5),
        NumberSequenceKeypoint.new(1.0, 1.0),
    })

    -- ========== HELPERS ==========
    local function notify(text, dur, color)
        if Notifications and Notifications.Show then
            Notifications:Show(text, dur, color)
        end
    end

    local function tween(inst, props, dur)
        dur = (dur or 0.16) / math.max(0.2, MenuConfig.AnimationSpeed)
        TweenService:Create(
            inst,
            TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            props
        ):Play()
    end

    local function registerAccent(inst, property)
        table.insert(accentColorObjects, { inst = inst, prop = property })
    end

    local function applyAccentColor(newColor)
        MenuConfig.AccentColor = newColor
        for _, obj in ipairs(accentColorObjects) do
            if obj.inst and obj.inst.Parent then
                obj.inst[obj.prop] = newColor
            end
        end
        strokeGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.3, newColor),
            ColorSequenceKeypoint.new(0.7, Color3.fromRGB(60, 65, 90)),
            ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 255, 255)),
        })
    end

    -- ========== LEFT SIDEBAR ==========
    local SIDEBAR_WIDTH = 180
    local PADDING = 10

    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, SIDEBAR_WIDTH, 1, -PADDING * 2)
    sidebar.Position = UDim2.new(0, PADDING, 0, PADDING)
    sidebar.BackgroundColor3 = Theme.PanelBg
    sidebar.BackgroundTransparency = 0.2
    sidebar.BorderSizePixel = 0
    sidebar.Parent = mainWindow
    Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 12)

    local sidebarStroke = Instance.new("UIStroke", sidebar)
    sidebarStroke.Color = Theme.StrokeDim
    sidebarStroke.Thickness = 1

    -- Brand Card (Top of Sidebar)
    local brandCard = Instance.new("Frame")
    brandCard.Name = "BrandCard"
    brandCard.Size = UDim2.new(1, -16, 0, 50)
    brandCard.Position = UDim2.new(0, 8, 0, 8)
    brandCard.BackgroundColor3 = Theme.PanelHeader
    brandCard.BorderSizePixel = 0
    brandCard.Parent = sidebar
    Instance.new("UICorner", brandCard).CornerRadius = UDim.new(0, 10)

    local brandStroke = Instance.new("UIStroke", brandCard)
    brandStroke.Color = Theme.StrokeDim
    brandStroke.Thickness = 1

    local logoImg = Instance.new("ImageLabel")
    logoImg.Name = "LogoIcon"
    logoImg.Size = UDim2.new(0, 24, 0, 24)
    logoImg.Position = UDim2.new(0, 10, 0.5, -12)
    logoImg.BackgroundTransparency = 1
    logoImg.Image = Icons.Zap
    logoImg.ImageColor3 = MenuConfig.AccentColor
    logoImg.Parent = brandCard
    registerAccent(logoImg, "ImageColor3")

    local brandTitle = Instance.new("TextLabel")
    brandTitle.Size = UDim2.new(1, -44, 0, 20)
    brandTitle.Position = UDim2.new(0, 38, 0, 6)
    brandTitle.BackgroundTransparency = 1
    brandTitle.Font = BoldFont
    brandTitle.Text = "XCLIENT"
    brandTitle.TextColor3 = Theme.TextPrimary
    brandTitle.TextSize = 16
    brandTitle.TextXAlignment = Enum.TextXAlignment.Left
    brandTitle.Parent = brandCard

    local brandSub = Instance.new("TextLabel")
    brandSub.Size = UDim2.new(1, -44, 0, 14)
    brandSub.Position = UDim2.new(0, 38, 0, 26)
    brandSub.BackgroundTransparency = 1
    brandSub.Font = HeavyFont
    brandSub.Text = "v2.0 • Modern"
    brandSub.TextColor3 = Color3.fromRGB(56, 189, 248)
    brandSub.TextSize = 11
    brandSub.TextXAlignment = Enum.TextXAlignment.Left
    brandSub.Parent = brandCard

    -- Categories Buttons Container
    local catContainer = Instance.new("Frame")
    catContainer.Name = "CategoryList"
    catContainer.Size = UDim2.new(1, -16, 1, -132)
    catContainer.Position = UDim2.new(0, 8, 0, 68)
    catContainer.BackgroundTransparency = 1
    catContainer.Parent = sidebar

    local catLayout = Instance.new("UIListLayout", catContainer)
    catLayout.FillDirection = Enum.FillDirection.Vertical
    catLayout.Padding = UDim.new(0, 5)
    catLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- Profile Card (Bottom of Sidebar)
    local profileCard = Instance.new("Frame")
    profileCard.Name = "ProfileCard"
    profileCard.Size = UDim2.new(1, -16, 0, 48)
    profileCard.Position = UDim2.new(0, 8, 1, -56)
    profileCard.BackgroundColor3 = Theme.PanelHeader
    profileCard.BorderSizePixel = 0
    profileCard.Parent = sidebar
    Instance.new("UICorner", profileCard).CornerRadius = UDim.new(0, 10)

    local profileStroke = Instance.new("UIStroke", profileCard)
    profileStroke.Color = Theme.StrokeDim
    profileStroke.Thickness = 1

    local avatarImg = Instance.new("ImageLabel")
    avatarImg.Name = "Avatar"
    avatarImg.Size = UDim2.new(0, 32, 0, 32)
    avatarImg.Position = UDim2.new(0, 8, 0.5, -16)
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
    profileName.Size = UDim2.new(1, -48, 0, 18)
    profileName.Position = UDim2.new(0, 46, 0, 7)
    profileName.BackgroundTransparency = 1
    profileName.Font = HeavyFont
    profileName.Text = (LocalPlayer and LocalPlayer.DisplayName) or "Player"
    profileName.TextColor3 = Theme.TextPrimary
    profileName.TextSize = 13
    profileName.TextXAlignment = Enum.TextXAlignment.Left
    profileName.TextTruncate = Enum.TextTruncate.AtEnd
    profileName.Parent = profileCard

    local profileStatus = Instance.new("TextLabel")
    profileStatus.Size = UDim2.new(1, -48, 0, 14)
    profileStatus.Position = UDim2.new(0, 46, 0, 25)
    profileStatus.BackgroundTransparency = 1
    profileStatus.Font = HeavyFont
    profileStatus.Text = "Активен"
    profileStatus.TextColor3 = Theme.Success
    profileStatus.TextSize = 11
    profileStatus.TextXAlignment = Enum.TextXAlignment.Left
    profileStatus.Parent = profileCard

    -- ========== RIGHT WORKSPACE AREA ==========
    local rightContainer = Instance.new("Frame")
    rightContainer.Name = "RightWorkspace"
    rightContainer.Size = UDim2.new(1, -SIDEBAR_WIDTH - PADDING * 3, 1, -PADDING * 2)
    rightContainer.Position = UDim2.new(0, SIDEBAR_WIDTH + PADDING * 2, 0, PADDING)
    rightContainer.BackgroundTransparency = 1
    rightContainer.Parent = mainWindow

    -- 1. Top Header Card
    local HEADER_HEIGHT = 46
    local headerCard = Instance.new("Frame")
    headerCard.Name = "HeaderCard"
    headerCard.Size = UDim2.new(1, 0, 0, HEADER_HEIGHT)
    headerCard.Position = UDim2.new(0, 0, 0, 0)
    headerCard.BackgroundColor3 = Theme.PanelBg
    headerCard.BackgroundTransparency = 0.2
    headerCard.BorderSizePixel = 0
    headerCard.Parent = rightContainer
    Instance.new("UICorner", headerCard).CornerRadius = UDim.new(0, 12)

    local headerStroke = Instance.new("UIStroke", headerCard)
    headerStroke.Color = Theme.StrokeDim
    headerStroke.Thickness = 1

    local categoryHeaderTitle = Instance.new("TextLabel")
    categoryHeaderTitle.Name = "CategoryTitle"
    categoryHeaderTitle.Size = UDim2.new(0, 220, 1, 0)
    categoryHeaderTitle.Position = UDim2.new(0, 16, 0, 0)
    categoryHeaderTitle.BackgroundTransparency = 1
    categoryHeaderTitle.Font = BoldFont
    categoryHeaderTitle.Text = "Combat"
    categoryHeaderTitle.TextColor3 = Theme.TextPrimary
    categoryHeaderTitle.TextSize = 18
    categoryHeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
    categoryHeaderTitle.Parent = headerCard

    -- Action Buttons (Reload & Close) with Lucide Icons
    local closeBtn = Instance.new("ImageButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -38, 0.5, -15)
    closeBtn.BackgroundColor3 = Theme.PanelHeader
    closeBtn.BorderSizePixel = 0
    closeBtn.Image = Icons.Close
    closeBtn.ImageColor3 = Theme.TextSecondary
    closeBtn.ScaleType = Enum.ScaleType.Fit
    closeBtn.Parent = headerCard
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
    local closeStroke = Instance.new("UIStroke", closeBtn)
    closeStroke.Color = Theme.StrokeDim
    closeStroke.Thickness = 1

    local reloadBtn = Instance.new("ImageButton")
    reloadBtn.Name = "ReloadButton"
    reloadBtn.Size = UDim2.new(0, 30, 0, 30)
    reloadBtn.Position = UDim2.new(1, -74, 0.5, -15)
    reloadBtn.BackgroundColor3 = Theme.PanelHeader
    reloadBtn.BorderSizePixel = 0
    reloadBtn.Image = Icons.Refresh
    reloadBtn.ImageColor3 = Theme.TextSecondary
    reloadBtn.ScaleType = Enum.ScaleType.Fit
    reloadBtn.Parent = headerCard
    Instance.new("UICorner", reloadBtn).CornerRadius = UDim.new(0, 8)
    local reloadStroke = Instance.new("UIStroke", reloadBtn)
    reloadStroke.Color = Theme.StrokeDim
    reloadStroke.Thickness = 1

    -- Search Box with Lucide Search Icon
    local searchContainer = Instance.new("Frame")
    searchContainer.Name = "SearchBox"
    searchContainer.Size = UDim2.new(0, 220, 0, 30)
    searchContainer.Position = UDim2.new(1, -304, 0.5, -15)
    searchContainer.BackgroundColor3 = Theme.PanelHeader
    searchContainer.BorderSizePixel = 0
    searchContainer.Parent = headerCard
    Instance.new("UICorner", searchContainer).CornerRadius = UDim.new(0, 8)

    local searchStroke = Instance.new("UIStroke", searchContainer)
    searchStroke.Color = Theme.StrokeDim
    searchStroke.Thickness = 1

    local searchIconImg = Instance.new("ImageLabel")
    searchIconImg.Size = UDim2.new(0, 16, 0, 16)
    searchIconImg.Position = UDim2.new(0, 8, 0.5, -8)
    searchIconImg.BackgroundTransparency = 1
    searchIconImg.Image = Icons.Search
    searchIconImg.ImageColor3 = Theme.TextMuted
    searchIconImg.Parent = searchContainer

    local searchInput = Instance.new("TextBox")
    searchInput.Size = UDim2.new(1, -36, 1, 0)
    searchInput.Position = UDim2.new(0, 30, 0, 0)
    searchInput.BackgroundTransparency = 1
    searchInput.Font = HeavyFont
    searchInput.PlaceholderText = "Поиск функций..."
    searchInput.PlaceholderColor3 = Theme.TextMuted
    searchInput.Text = ""
    searchInput.TextColor3 = Theme.TextPrimary
    searchInput.TextSize = 13
    searchInput.TextXAlignment = Enum.TextXAlignment.Left
    searchInput.ClearTextOnFocus = false
    searchInput.Parent = searchContainer

    -- 2. Content Card
    local contentCard = Instance.new("Frame")
    contentCard.Name = "ContentCard"
    contentCard.Size = UDim2.new(1, 0, 1, -HEADER_HEIGHT - 8)
    contentCard.Position = UDim2.new(0, 0, 0, HEADER_HEIGHT + 8)
    contentCard.BackgroundColor3 = Theme.PanelBg
    contentCard.BackgroundTransparency = 0.2
    contentCard.BorderSizePixel = 0
    contentCard.Parent = rightContainer
    Instance.new("UICorner", contentCard).CornerRadius = UDim.new(0, 12)

    local contentStroke = Instance.new("UIStroke", contentCard)
    contentStroke.Color = Theme.StrokeDim
    contentStroke.Thickness = 1

    -- Left Pane: Module List (Wider: 250px so text never clips!)
    local MODULE_LIST_WIDTH = 250

    local moduleListFrame = Instance.new("ScrollingFrame")
    moduleListFrame.Name = "ModuleList"
    moduleListFrame.Size = UDim2.new(0, MODULE_LIST_WIDTH, 1, -16)
    moduleListFrame.Position = UDim2.new(0, 10, 0, 8)
    moduleListFrame.BackgroundTransparency = 1
    moduleListFrame.BorderSizePixel = 0
    moduleListFrame.ScrollBarThickness = 3
    moduleListFrame.ScrollBarImageColor3 = Theme.StrokeDim
    moduleListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    moduleListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    moduleListFrame.Parent = contentCard

    local moduleListLayout = Instance.new("UIListLayout", moduleListFrame)
    moduleListLayout.Padding = UDim.new(0, 6)
    moduleListLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- Vertical Divider
    local divider = Instance.new("Frame")
    divider.Name = "Divider"
    divider.Size = UDim2.new(0, 1, 1, -16)
    divider.Position = UDim2.new(0, MODULE_LIST_WIDTH + 20, 0, 8)
    divider.BackgroundColor3 = Theme.StrokeDim
    divider.BorderSizePixel = 0
    divider.Parent = contentCard

    -- Right Pane: Inspector / Settings Panel
    local INSPECTOR_X = MODULE_LIST_WIDTH + 30
    local inspectorFrame = Instance.new("Frame")
    inspectorFrame.Name = "Inspector"
    inspectorFrame.Size = UDim2.new(1, -INSPECTOR_X - 10, 1, -16)
    inspectorFrame.Position = UDim2.new(0, INSPECTOR_X, 0, 8)
    inspectorFrame.BackgroundTransparency = 1
    inspectorFrame.Parent = contentCard

    local inspectorScroll = Instance.new("ScrollingFrame")
    inspectorScroll.Name = "InspectorScroll"
    inspectorScroll.Size = UDim2.new(1, 0, 1, 0)
    inspectorScroll.BackgroundTransparency = 1
    inspectorScroll.BorderSizePixel = 0
    inspectorScroll.ScrollBarThickness = 3
    inspectorScroll.ScrollBarImageColor3 = MenuConfig.AccentColor
    registerAccent(inspectorScroll, "ScrollBarImageColor3")
    inspectorScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    inspectorScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    inspectorScroll.Parent = inspectorFrame

    local inspectorLayout = Instance.new("UIListLayout", inspectorScroll)
    inspectorLayout.Padding = UDim.new(0, 10)
    inspectorLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- ========== RICH-MODERN RESIZE GRIP (3 DOTS BOTTOM-RIGHT) ==========
    local resizeGrip = Instance.new("TextButton")
    resizeGrip.Name = "ResizeGrip"
    resizeGrip.Size = UDim2.new(0, 20, 0, 20)
    resizeGrip.Position = UDim2.new(1, -22, 1, -22)
    resizeGrip.BackgroundTransparency = 1
    resizeGrip.Text = ""
    resizeGrip.Parent = mainWindow

    local function makeDot(offsetX, offsetY)
        local d = Instance.new("Frame")
        d.Size = UDim2.new(0, 4, 0, 4)
        d.Position = UDim2.new(1, offsetX, 1, offsetY)
        d.BackgroundColor3 = Theme.TextMuted
        d.BorderSizePixel = 0
        d.Parent = resizeGrip
        Instance.new("UICorner", d).CornerRadius = UDim.new(1, 0)
        return d
    end

    local dot1 = makeDot(-6, -6)
    local dot2 = makeDot(-12, -6)
    local dot3 = makeDot(-6, -12)

    local resizingWindow = false
    local resizeStartMouse = nil
    local resizeStartSize = nil

    resizeGrip.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizingWindow = true
            resizeStartMouse = input.Position
            resizeStartSize = Vector2.new(mainWindow.AbsoluteSize.X, mainWindow.AbsoluteSize.Y)
            dot1.BackgroundColor3 = MenuConfig.AccentColor
            dot2.BackgroundColor3 = MenuConfig.AccentColor
            dot3.BackgroundColor3 = MenuConfig.AccentColor
        end
    end)

    resizeGrip.MouseEnter:Connect(function()
        dot1.BackgroundColor3 = Theme.TextPrimary
        dot2.BackgroundColor3 = Theme.TextPrimary
        dot3.BackgroundColor3 = Theme.TextPrimary
    end)
    resizeGrip.MouseLeave:Connect(function()
        if not resizingWindow then
            dot1.BackgroundColor3 = Theme.TextMuted
            dot2.BackgroundColor3 = Theme.TextMuted
            dot3.BackgroundColor3 = Theme.TextMuted
        end
    end)

    -- ========== FORWARD DECLARATIONS ==========
    local renderInspector = nil
    local renderModuleList = nil
    local renderCategories = nil
    local renderMenuSettingsPanel = nil

    -- ========== MENU SETTINGS PANEL RENDERING ==========
    renderMenuSettingsPanel = function()
        for _, child in ipairs(inspectorScroll:GetChildren()) do
            if child:IsA("GuiObject") then child:Destroy() end
        end

        -- Header Card
        local headerCardMod = Instance.new("Frame")
        headerCardMod.Size = UDim2.new(1, -4, 0, 56)
        headerCardMod.BackgroundColor3 = Theme.CardBg
        headerCardMod.BorderSizePixel = 0
        headerCardMod.LayoutOrder = 1
        headerCardMod.Parent = inspectorScroll
        Instance.new("UICorner", headerCardMod).CornerRadius = UDim.new(0, 10)

        local hmStroke = Instance.new("UIStroke", headerCardMod)
        hmStroke.Color = Theme.StrokeDim
        hmStroke.Thickness = 1

        local titleLbl = Instance.new("TextLabel")
        titleLbl.Size = UDim2.new(1, -24, 0, 24)
        titleLbl.Position = UDim2.new(0, 14, 0, 8)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Font = BoldFont
        titleLbl.Text = "Настройки интерфейса (ClickGUI)"
        titleLbl.TextColor3 = Theme.TextPrimary
        titleLbl.TextSize = 16
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.Parent = headerCardMod

        local subLbl = Instance.new("TextLabel")
        subLbl.Size = UDim2.new(1, -24, 0, 16)
        subLbl.Position = UDim2.new(0, 14, 0, 32)
        subLbl.BackgroundTransparency = 1
        subLbl.Font = HeavyFont
        subLbl.Text = "Кастомизация визуала, цветов, Liquid Glass и размытия"
        subLbl.TextColor3 = MenuConfig.AccentColor
        registerAccent(subLbl, "TextColor3")
        subLbl.TextSize = 11
        subLbl.TextXAlignment = Enum.TextXAlignment.Left
        subLbl.Parent = headerCardMod

        local function makeToggleRow(name, desc, state, onToggle, order)
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, -4, 0, 50)
            row.BackgroundColor3 = Theme.CardBg
            row.BorderSizePixel = 0
            row.LayoutOrder = order
            row.Parent = inspectorScroll
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

            local rStroke = Instance.new("UIStroke", row)
            rStroke.Color = Theme.StrokeDim
            rStroke.Thickness = 1

            local nl = Instance.new("TextLabel")
            nl.Size = UDim2.new(1, -70, 0, 20)
            nl.Position = UDim2.new(0, 14, 0, 6)
            nl.BackgroundTransparency = 1
            nl.Font = HeavyFont
            nl.Text = name
            nl.TextColor3 = Theme.TextPrimary
            nl.TextSize = 13
            nl.TextXAlignment = Enum.TextXAlignment.Left
            nl.Parent = row

            local dl = Instance.new("TextLabel")
            dl.Size = UDim2.new(1, -70, 0, 16)
            dl.Position = UDim2.new(0, 14, 0, 26)
            dl.BackgroundTransparency = 1
            dl.Font = HeavyFont
            dl.Text = desc
            dl.TextColor3 = Theme.TextMuted
            dl.TextSize = 11
            dl.TextXAlignment = Enum.TextXAlignment.Left
            dl.Parent = row

            local sw = Instance.new("TextButton")
            sw.Size = UDim2.new(0, 44, 0, 22)
            sw.Position = UDim2.new(1, -56, 0.5, -11)
            sw.BackgroundColor3 = state and MenuConfig.AccentColor or Theme.SwitchOff
            registerAccent(sw, "BackgroundColor3")
            sw.BorderSizePixel = 0
            sw.AutoButtonColor = false
            sw.Text = ""
            sw.Parent = row
            Instance.new("UICorner", sw).CornerRadius = UDim.new(1, 0)

            local th = Instance.new("Frame")
            th.Size = UDim2.new(0, 16, 0, 16)
            th.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
            th.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            th.BorderSizePixel = 0
            th.Parent = sw
            Instance.new("UICorner", th).CornerRadius = UDim.new(1, 0)

            sw.MouseButton1Click:Connect(function()
                state = not state
                onToggle(state)
                tween(sw, { BackgroundColor3 = state and MenuConfig.AccentColor or Theme.SwitchOff })
                tween(th, { Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8) })
            end)
        end

        -- Row 2: Liquid Glass
        makeToggleRow(
            "Liquid Glass (Жидкое стекло)",
            "Эффект глянцевого стекла и преломления света",
            MenuConfig.LiquidGlass,
            function(v)
                MenuConfig.LiquidGlass = v
                topSheen.Visible = v
                strokeGradient.Enabled = v
                notify("Liquid Glass: " .. (v and "ВКЛ" or "ВЫКЛ"), 1.5, Theme.Success)
            end,
            2
        )

        -- Row 3: Menu Glow (Свечение элементов)
        makeToggleRow(
            "Свечение меню (Menu Glow)",
            "Неоновое свечение активных модулей и текста",
            MenuConfig.MenuGlow,
            function(v)
                MenuConfig.MenuGlow = v
                notify("Menu Glow: " .. (v and "ВКЛ" or "ВЫКЛ"), 1.5, Theme.Success)
            end,
            3
        )

        -- Row 4: Цвет акцента (Presets)
        local colorCard = Instance.new("Frame")
        colorCard.Size = UDim2.new(1, -4, 0, 74)
        colorCard.BackgroundColor3 = Theme.CardBg
        colorCard.BorderSizePixel = 0
        colorCard.LayoutOrder = 4
        colorCard.Parent = inspectorScroll
        Instance.new("UICorner", colorCard).CornerRadius = UDim.new(0, 8)

        local ccStroke = Instance.new("UIStroke", colorCard)
        ccStroke.Color = Theme.StrokeDim
        ccStroke.Thickness = 1

        local ccTitle = Instance.new("TextLabel")
        ccTitle.Size = UDim2.new(1, -24, 0, 20)
        ccTitle.Position = UDim2.new(0, 14, 0, 8)
        ccTitle.BackgroundTransparency = 1
        ccTitle.Font = HeavyFont
        ccTitle.Text = "Цвет интерфейса (Accent Color)"
        ccTitle.TextColor3 = Theme.TextPrimary
        ccTitle.TextSize = 13
        ccTitle.TextXAlignment = Enum.TextXAlignment.Left
        ccTitle.Parent = colorCard

        local colorsHolder = Instance.new("Frame")
        colorsHolder.Size = UDim2.new(1, -28, 0, 32)
        colorsHolder.Position = UDim2.new(0, 14, 0, 34)
        colorsHolder.BackgroundTransparency = 1
        colorsHolder.Parent = colorCard

        local colorLayout = Instance.new("UIListLayout", colorsHolder)
        colorLayout.FillDirection = Enum.FillDirection.Horizontal
        colorLayout.Padding = UDim.new(0, 10)
        colorLayout.SortOrder = Enum.SortOrder.LayoutOrder

        for _, preset in ipairs(AccentPresets) do
            local dotBtn = Instance.new("TextButton")
            dotBtn.Size = UDim2.new(0, 28, 0, 28)
            dotBtn.BackgroundColor3 = preset.Color
            dotBtn.BorderSizePixel = 0
            dotBtn.AutoButtonColor = false
            dotBtn.Text = ""
            dotBtn.Parent = colorsHolder
            Instance.new("UICorner", dotBtn).CornerRadius = UDim.new(1, 0)

            local dStroke = Instance.new("UIStroke", dotBtn)
            dStroke.Color = Color3.fromRGB(255, 255, 255)
            dStroke.Thickness = 2
            dStroke.Transparency = (MenuConfig.AccentColor == preset.Color) and 0 or 1

            dotBtn.MouseButton1Click:Connect(function()
                applyAccentColor(preset.Color)
                renderMenuSettingsPanel()
                renderCategories()
                notify("Выбран цвет: " .. preset.Name, 1.5, preset.Color)
            end)
        end

        -- Row 5: Прозрачность окна
        local opCard = Instance.new("Frame")
        opCard.Size = UDim2.new(1, -4, 0, 56)
        opCard.BackgroundColor3 = Theme.CardBg
        opCard.BorderSizePixel = 0
        opCard.LayoutOrder = 5
        opCard.Parent = inspectorScroll
        Instance.new("UICorner", opCard).CornerRadius = UDim.new(0, 8)

        local opStroke = Instance.new("UIStroke", opCard)
        opStroke.Color = Theme.StrokeDim
        opStroke.Thickness = 1

        local opLbl = Instance.new("TextLabel")
        opLbl.Size = UDim2.new(0.65, 0, 0, 20)
        opLbl.Position = UDim2.new(0, 14, 0, 6)
        opLbl.BackgroundTransparency = 1
        opLbl.Font = HeavyFont
        opLbl.Text = "Прозрачность окна"
        opLbl.TextColor3 = Theme.TextPrimary
        opLbl.TextSize = 13
        opLbl.TextXAlignment = Enum.TextXAlignment.Left
        opLbl.Parent = opCard

        local opValLbl = Instance.new("TextLabel")
        opValLbl.Size = UDim2.new(0.3, 0, 0, 20)
        opValLbl.Position = UDim2.new(0.7, -14, 0, 6)
        opValLbl.BackgroundTransparency = 1
        opValLbl.Font = HeavyFont
        opValLbl.Text = string.format("%.0f%%", MenuConfig.WindowOpacity * 100)
        opValLbl.TextColor3 = MenuConfig.AccentColor
        registerAccent(opValLbl, "TextColor3")
        opValLbl.TextSize = 13
        opValLbl.TextXAlignment = Enum.TextXAlignment.Right
        opValLbl.Parent = opCard

        local barBg = Instance.new("Frame")
        barBg.Size = UDim2.new(1, -28, 0, 8)
        barBg.Position = UDim2.new(0, 14, 0, 36)
        barBg.BackgroundColor3 = Color3.fromRGB(36, 41, 60)
        barBg.BorderSizePixel = 0
        barBg.Parent = opCard
        Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

        local barFill = Instance.new("Frame")
        barFill.Size = UDim2.new(MenuConfig.WindowOpacity, 0, 1, 0)
        barFill.BackgroundColor3 = MenuConfig.AccentColor
        registerAccent(barFill, "BackgroundColor3")
        barFill.BorderSizePixel = 0
        barFill.Parent = barBg
        Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

        local draggingOp = false
        barBg.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                draggingOp = true
                local absPos = barBg.AbsolutePosition.X
                local absSize = barBg.AbsoluteSize.X
                local p = math.clamp((input.Position.X - absPos) / absSize, 0.3, 1)
                MenuConfig.WindowOpacity = p
                mainWindow.BackgroundTransparency = 1 - p
                barFill.Size = UDim2.new(p, 0, 1, 0)
                opValLbl.Text = string.format("%.0f%%", p * 100)
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if draggingOp and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local absPos = barBg.AbsolutePosition.X
                local absSize = barBg.AbsoluteSize.X
                local p = math.clamp((input.Position.X - absPos) / absSize, 0.3, 1)
                MenuConfig.WindowOpacity = p
                mainWindow.BackgroundTransparency = 1 - p
                barFill.Size = UDim2.new(p, 0, 1, 0)
                opValLbl.Text = string.format("%.0f%%", p * 100)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                draggingOp = false
            end
        end)
    end

    -- ========== MODULE INSPECTOR RENDERING ==========
    renderInspector = function(mod)
        for _, child in ipairs(inspectorScroll:GetChildren()) do
            if child:IsA("GuiObject") then child:Destroy() end
        end

        if not mod then
            local empty = Instance.new("Frame")
            empty.Size = UDim2.new(1, 0, 1, 0)
            empty.BackgroundTransparency = 1
            empty.Parent = inspectorScroll

            local icon = Instance.new("ImageLabel")
            icon.Size = UDim2.new(0, 48, 0, 48)
            icon.Position = UDim2.new(0.5, -24, 0.35, 0)
            icon.BackgroundTransparency = 1
            icon.Image = Icons.Sliders
            icon.ImageColor3 = Theme.TextMuted
            icon.Parent = empty

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 0, 24)
            lbl.Position = UDim2.new(0, 0, 0.35, 56)
            lbl.BackgroundTransparency = 1
            lbl.Font = HeavyFont
            lbl.Text = "Выберите модуль для настройки"
            lbl.TextColor3 = Theme.TextMuted
            lbl.TextSize = 14
            lbl.Parent = empty
            return
        end

        -- Header Card in Inspector
        local headerCardMod = Instance.new("Frame")
        headerCardMod.Name = "ModHeader"
        headerCardMod.Size = UDim2.new(1, -4, 0, 60)
        headerCardMod.BackgroundColor3 = Theme.CardBg
        headerCardMod.BorderSizePixel = 0
        headerCardMod.LayoutOrder = 1
        headerCardMod.Parent = inspectorScroll
        Instance.new("UICorner", headerCardMod).CornerRadius = UDim.new(0, 10)

        local hmStroke = Instance.new("UIStroke", headerCardMod)
        hmStroke.Color = Theme.StrokeDim
        hmStroke.Thickness = 1

        local modNameLbl = Instance.new("TextLabel")
        modNameLbl.Size = UDim2.new(0.65, 0, 0, 24)
        modNameLbl.Position = UDim2.new(0, 14, 0, 8)
        modNameLbl.BackgroundTransparency = 1
        modNameLbl.Font = BoldFont
        modNameLbl.Text = mod.Name or "Unknown"
        modNameLbl.TextColor3 = Theme.TextPrimary
        modNameLbl.TextSize = 17
        modNameLbl.TextXAlignment = Enum.TextXAlignment.Left
        modNameLbl.Parent = headerCardMod

        local catTag = Instance.new("TextLabel")
        catTag.Size = UDim2.new(0.65, 0, 0, 16)
        catTag.Position = UDim2.new(0, 14, 0, 34)
        catTag.BackgroundTransparency = 1
        catTag.Font = HeavyFont
        catTag.Text = "Категория: " .. (mod.Category or "Misc")
        catTag.TextColor3 = MenuConfig.AccentColor
        registerAccent(catTag, "TextColor3")
        catTag.TextSize = 12
        catTag.TextXAlignment = Enum.TextXAlignment.Left
        catTag.Parent = headerCardMod

        -- Master Switch in Inspector Header
        local masterSwitch = Instance.new("TextButton")
        masterSwitch.Size = UDim2.new(0, 48, 0, 24)
        masterSwitch.Position = UDim2.new(1, -62, 0.5, -12)
        masterSwitch.BackgroundColor3 = mod.Enabled and MenuConfig.AccentColor or Theme.SwitchOff
        masterSwitch.BorderSizePixel = 0
        masterSwitch.AutoButtonColor = false
        masterSwitch.Text = ""
        masterSwitch.Parent = headerCardMod
        Instance.new("UICorner", masterSwitch).CornerRadius = UDim.new(1, 0)

        local masterThumb = Instance.new("Frame")
        masterThumb.Size = UDim2.new(0, 18, 0, 18)
        masterThumb.Position = mod.Enabled and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        masterThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        masterThumb.BorderSizePixel = 0
        masterThumb.Parent = masterSwitch
        Instance.new("UICorner", masterThumb).CornerRadius = UDim.new(1, 0)

        masterSwitch.MouseButton1Click:Connect(function()
            ModuleManager:SetEnabled(mod, not mod.Enabled)
            local state = mod.Enabled
            tween(masterSwitch, { BackgroundColor3 = state and MenuConfig.AccentColor or Theme.SwitchOff })
            tween(masterThumb, { Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9) })

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
        kbRow.Size = UDim2.new(1, -4, 0, 42)
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
        kbLabel.Position = UDim2.new(0, 14, 0, 0)
        kbLabel.BackgroundTransparency = 1
        kbLabel.Font = HeavyFont
        kbLabel.Text = "Горячая клавиша"
        kbLabel.TextColor3 = Theme.TextSecondary
        kbLabel.TextSize = 13
        kbLabel.TextXAlignment = Enum.TextXAlignment.Left
        kbLabel.Parent = kbRow

        local kbBtn = Instance.new("TextButton")
        kbBtn.Size = UDim2.new(0.42, 0, 0, 26)
        kbBtn.Position = UDim2.new(0.56, 0, 0.5, -13)
        kbBtn.BackgroundColor3 = Theme.PanelHeader
        kbBtn.BorderSizePixel = 0
        kbBtn.AutoButtonColor = false
        kbBtn.Font = HeavyFont
        kbBtn.TextSize = 12
        kbBtn.TextColor3 = Color3.fromRGB(56, 189, 248)
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
            kbBtn.TextColor3 = MenuConfig.AccentColor

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
                    kbBtn.TextColor3 = Color3.fromRGB(56, 189, 248)
                    for _, item in ipairs(moduleCardItems) do
                        if item.mod == mod and item.kbTag then
                            item.kbTag.Text = "[" .. keyName:sub(1, 4) .. "]"
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
                    card.Size = UDim2.new(1, -4, 0, 56)
                    card.BackgroundColor3 = Theme.CardBg
                    card.BorderSizePixel = 0
                    card.LayoutOrder = orderCounter
                    card.Parent = inspectorScroll
                    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

                    local sStroke = Instance.new("UIStroke", card)
                    sStroke.Color = Theme.StrokeDim
                    sStroke.Thickness = 1

                    local lbl = Instance.new("TextLabel")
                    lbl.Size = UDim2.new(0.65, 0, 0, 22)
                    lbl.Position = UDim2.new(0, 14, 0, 6)
                    lbl.BackgroundTransparency = 1
                    lbl.Font = HeavyFont
                    lbl.Text = sName
                    lbl.TextColor3 = Theme.TextSecondary
                    lbl.TextSize = 13
                    lbl.TextXAlignment = Enum.TextXAlignment.Left
                    lbl.Parent = card

                    local valLbl = Instance.new("TextLabel")
                    valLbl.Size = UDim2.new(0.3, 0, 0, 22)
                    valLbl.Position = UDim2.new(0.7, -14, 0, 6)
                    valLbl.BackgroundTransparency = 1
                    valLbl.Font = HeavyFont
                    valLbl.Text = tostring(currentVal) .. sSuffix
                    valLbl.TextColor3 = MenuConfig.AccentColor
                    registerAccent(valLbl, "TextColor3")
                    valLbl.TextSize = 13
                    valLbl.TextXAlignment = Enum.TextXAlignment.Right
                    valLbl.Parent = card

                    local barBg = Instance.new("Frame")
                    barBg.Size = UDim2.new(1, -28, 0, 8)
                    barBg.Position = UDim2.new(0, 14, 0, 36)
                    barBg.BackgroundColor3 = Color3.fromRGB(36, 41, 60)
                    barBg.BorderSizePixel = 0
                    barBg.Parent = card
                    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

                    local barFill = Instance.new("Frame")
                    local pct = math.clamp((currentVal - sMin) / (sMax - sMin), 0, 1)
                    barFill.Size = UDim2.new(pct, 0, 1, 0)
                    barFill.BackgroundColor3 = MenuConfig.AccentColor
                    registerAccent(barFill, "BackgroundColor3")
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
                            local p = math.clamp((input.Position.X - absPos) / absSize, 0, 1)
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
                            local p = math.clamp((input.Position.X - absPos) / absSize, 0, 1)
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
                    row.Size = UDim2.new(1, -4, 0, 42)
                    row.BackgroundColor3 = Theme.CardBg
                    row.BorderSizePixel = 0
                    row.LayoutOrder = orderCounter
                    row.Parent = inspectorScroll
                    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

                    local tStroke = Instance.new("UIStroke", row)
                    tStroke.Color = Theme.StrokeDim
                    tStroke.Thickness = 1

                    local lbl = Instance.new("TextLabel")
                    lbl.Size = UDim2.new(1, -66, 1, 0)
                    lbl.Position = UDim2.new(0, 14, 0, 0)
                    lbl.BackgroundTransparency = 1
                    lbl.Font = HeavyFont
                    lbl.Text = sName
                    lbl.TextColor3 = Theme.TextSecondary
                    lbl.TextSize = 13
                    lbl.TextXAlignment = Enum.TextXAlignment.Left
                    lbl.Parent = row

                    local sw = Instance.new("TextButton")
                    sw.Size = UDim2.new(0, 44, 0, 22)
                    sw.Position = UDim2.new(1, -56, 0.5, -11)
                    sw.BackgroundColor3 = currentVal and MenuConfig.AccentColor or Theme.SwitchOff
                    registerAccent(sw, "BackgroundColor3")
                    sw.BorderSizePixel = 0
                    sw.AutoButtonColor = false
                    sw.Text = ""
                    sw.Parent = row
                    Instance.new("UICorner", sw).CornerRadius = UDim.new(1, 0)

                    local th = Instance.new("Frame")
                    th.Size = UDim2.new(0, 16, 0, 16)
                    th.Position = currentVal and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
                    th.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    th.BorderSizePixel = 0
                    th.Parent = sw
                    Instance.new("UICorner", th).CornerRadius = UDim.new(1, 0)

                    sw.MouseButton1Click:Connect(function()
                        currentVal = not currentVal
                        if not mod.__settings__ then mod.__settings__ = {} end
                        mod.__settings__[sKey] = currentVal
                        tween(sw, { BackgroundColor3 = currentVal and MenuConfig.AccentColor or Theme.SwitchOff })
                        tween(th, { Position = currentVal and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8) })
                    end)

                elseif sType == "Dropdown" then
                    local sOptions = def.Options or {}
                    local currentVal = sDefault or sOptions[1] or ""
                    if mod.__settings__ and mod.__settings__[sKey] ~= nil then
                        currentVal = mod.__settings__[sKey]
                    end

                    local row = Instance.new("Frame")
                    row.Size = UDim2.new(1, -4, 0, 42)
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
                    lbl.Position = UDim2.new(0, 14, 0, 0)
                    lbl.BackgroundTransparency = 1
                    lbl.Font = HeavyFont
                    lbl.Text = sName
                    lbl.TextColor3 = Theme.TextSecondary
                    lbl.TextSize = 13
                    lbl.TextXAlignment = Enum.TextXAlignment.Left
                    lbl.Parent = row

                    local dropBtn = Instance.new("TextButton")
                    dropBtn.Size = UDim2.new(0.44, 0, 0, 26)
                    dropBtn.Position = UDim2.new(0.54, 0, 0.5, -13)
                    dropBtn.BackgroundColor3 = Theme.PanelHeader
                    dropBtn.BorderSizePixel = 0
                    dropBtn.AutoButtonColor = false
                    dropBtn.Font = HeavyFont
                    dropBtn.Text = tostring(currentVal) .. "  "
                    dropBtn.TextColor3 = Theme.TextPrimary
                    dropBtn.TextSize = 12
                    dropBtn.Parent = row
                    Instance.new("UICorner", dropBtn).CornerRadius = UDim.new(0, 6)

                    local arrowImg = Instance.new("ImageLabel")
                    arrowImg.Size = UDim2.new(0, 14, 0, 14)
                    arrowImg.Position = UDim2.new(1, -20, 0.5, -7)
                    arrowImg.BackgroundTransparency = 1
                    arrowImg.Image = Icons.ChevronDown
                    arrowImg.ImageColor3 = Theme.TextMuted
                    arrowImg.Parent = dropBtn

                    local curIdx = 1
                    for idx, opt in ipairs(sOptions) do
                        if opt == currentVal then curIdx = idx break end
                    end

                    dropBtn.MouseButton1Click:Connect(function()
                        curIdx = curIdx + 1
                        if curIdx > #sOptions then curIdx = 1 end
                        currentVal = sOptions[curIdx]
                        dropBtn.Text = tostring(currentVal) .. "  "
                        if not mod.__settings__ then mod.__settings__ = {} end
                        mod.__settings__[sKey] = currentVal
                    end)
                end
            end
        else
            -- Empty Settings Row
            local emptyRow = Instance.new("Frame")
            emptyRow.Size = UDim2.new(1, -4, 0, 60)
            emptyRow.BackgroundColor3 = Theme.CardBg
            emptyRow.BorderSizePixel = 0
            emptyRow.LayoutOrder = 3
            emptyRow.Parent = inspectorScroll
            Instance.new("UICorner", emptyRow).CornerRadius = UDim.new(0, 8)

            local noSettingsLbl = Instance.new("TextLabel")
            noSettingsLbl.Size = UDim2.new(1, 0, 1, 0)
            noSettingsLbl.BackgroundTransparency = 1
            noSettingsLbl.Font = HeavyFont
            noSettingsLbl.Text = "У данной функции нет дополнительных параметров"
            noSettingsLbl.TextColor3 = Theme.TextMuted
            noSettingsLbl.TextSize = 12
            noSettingsLbl.Parent = emptyRow
        end
    end

    -- ========== MODULE LIST RENDERING ==========
    renderModuleList = function()
        for _, child in ipairs(moduleListFrame:GetChildren()) do
            if child:IsA("GuiObject") then child:Destroy() end
        end
        moduleCardItems = {}

        if selectedCategory == "SETTINGS" then
            moduleListFrame.Visible = false
            divider.Visible = false
            inspectorFrame.Position = UDim2.new(0, 10, 0, 8)
            inspectorFrame.Size = UDim2.new(1, -20, 1, -16)
            renderMenuSettingsPanel()
            return
        else
            moduleListFrame.Visible = true
            divider.Visible = true
            inspectorFrame.Position = UDim2.new(0, MODULE_LIST_WIDTH + 30, 0, 8)
            inspectorFrame.Size = UDim2.new(1, -MODULE_LIST_WIDTH - 40, 1, -16)
        end

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
            emptyCard.Size = UDim2.new(1, 0, 0, 60)
            emptyCard.BackgroundTransparency = 1
            emptyCard.Parent = moduleListFrame

            local emptyLbl = Instance.new("TextLabel")
            emptyLbl.Size = UDim2.new(1, 0, 1, 0)
            emptyLbl.BackgroundTransparency = 1
            emptyLbl.Font = HeavyFont
            emptyLbl.Text = "Ничего не найдено"
            emptyLbl.TextColor3 = Theme.TextMuted
            emptyLbl.TextSize = 13
            emptyLbl.Parent = emptyCard
            renderInspector(nil)
            return
        end

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
            card.Size = UDim2.new(1, -6, 0, 44) -- Высота 44px (удобно, просторно, ничего не обрезается!)
            card.BackgroundColor3 = (selectedModule == mod) and Theme.CardSelected or Theme.CardBg
            card.BorderSizePixel = 0
            card.Parent = moduleListFrame
            Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

            local cardStroke = Instance.new("UIStroke", card)
            cardStroke.Color = (selectedModule == mod) and MenuConfig.AccentColor or Theme.StrokeDim
            cardStroke.Thickness = 1.2

            -- Module Name (Bold font 14px, wide enough)
            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size = UDim2.new(1, -86, 1, 0)
            nameLbl.Position = UDim2.new(0, 12, 0, 0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Font = BoldFont
            nameLbl.Text = mod.Name or ""
            nameLbl.TextColor3 = mod.Enabled and Theme.TextPrimary or Theme.TextSecondary
            nameLbl.TextSize = 14
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
            nameLbl.Parent = card

            -- Keybind indicator tag
            local kbTag = Instance.new("TextLabel")
            kbTag.Size = UDim2.new(0, 30, 0, 16)
            kbTag.Position = UDim2.new(1, -82, 0.5, -8)
            kbTag.BackgroundTransparency = 1
            kbTag.Font = HeavyFont
            kbTag.Text = ModuleManager.Keybinds[mod.Name] and ("[" .. ModuleManager.Keybinds[mod.Name]:sub(1, 4) .. "]") or ""
            kbTag.TextColor3 = Theme.TextMuted
            kbTag.TextSize = 10
            kbTag.TextXAlignment = Enum.TextXAlignment.Right
            kbTag.Parent = card

            -- Modern Toggle Switch on Card
            local sw = Instance.new("TextButton")
            sw.Size = UDim2.new(0, 38, 0, 20)
            sw.Position = UDim2.new(1, -48, 0.5, -10)
            sw.BackgroundColor3 = mod.Enabled and MenuConfig.AccentColor or Theme.SwitchOff
            sw.BorderSizePixel = 0
            sw.AutoButtonColor = false
            sw.Text = ""
            sw.Parent = card
            Instance.new("UICorner", sw).CornerRadius = UDim.new(1, 0)

            local th = Instance.new("Frame")
            th.Size = UDim2.new(0, 14, 0, 14)
            th.Position = mod.Enabled and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
            th.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            th.BorderSizePixel = 0
            th.Parent = sw
            Instance.new("UICorner", th).CornerRadius = UDim.new(1, 0)

            -- Invisible button over card body to select module
            local selectBtn = Instance.new("TextButton")
            selectBtn.Size = UDim2.new(1, -52, 1, 0)
            selectBtn.Position = UDim2.new(0, 0, 0, 0)
            selectBtn.BackgroundTransparency = 1
            selectBtn.Text = ""
            selectBtn.Parent = card

            local function updateCardVisuals()
                local isSel = (selectedModule == mod)
                card.BackgroundColor3 = isSel and Theme.CardSelected or Theme.CardBg
                cardStroke.Color = isSel and MenuConfig.AccentColor or Theme.StrokeDim
                nameLbl.TextColor3 = mod.Enabled and Theme.TextPrimary or (isSel and Theme.TextPrimary or Theme.TextSecondary)
                tween(sw, { BackgroundColor3 = mod.Enabled and MenuConfig.AccentColor or Theme.SwitchOff })
                tween(th, { Position = mod.Enabled and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7) })
            end

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

            selectBtn.MouseButton1Click:Connect(function()
                selectedModule = mod
                for _, item in ipairs(moduleCardItems) do
                    if item.updateVisuals then item.updateVisuals() end
                end
                renderInspector(mod)
            end)

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
    renderCategories = function()
        for _, btn in ipairs(categoryButtons) do
            btn:Destroy()
        end
        categoryButtons = {}

        for _, cat in ipairs(Categories) do
            local isSelected = (selectedCategory == cat.Id)

            local btn = Instance.new("TextButton")
            btn.Name = "Cat_" .. cat.Id
            btn.Size = UDim2.new(1, 0, 0, 36)
            btn.BackgroundColor3 = isSelected and Theme.PanelHeader or Color3.fromRGB(20, 23, 34)
            btn.BackgroundTransparency = isSelected and 0 or 1
            btn.BorderSizePixel = 0
            btn.AutoButtonColor = false
            btn.Text = ""
            btn.Parent = catContainer
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

            local btnStroke = Instance.new("UIStroke", btn)
            btnStroke.Color = isSelected and MenuConfig.AccentColor or Theme.StrokeDim
            btnStroke.Thickness = 1
            btnStroke.Transparency = isSelected and 0 or 1

            local iconImg = Instance.new("ImageLabel")
            iconImg.Size = UDim2.new(0, 18, 0, 18)
            iconImg.Position = UDim2.new(0, 10, 0.5, -9)
            iconImg.BackgroundTransparency = 1
            iconImg.Image = cat.Icon
            iconImg.ImageColor3 = isSelected and MenuConfig.AccentColor or Theme.TextMuted
            iconImg.Parent = btn

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size = UDim2.new(1, -38, 1, 0)
            nameLbl.Position = UDim2.new(0, 36, 0, 0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Font = BoldFont
            nameLbl.Text = cat.Name
            nameLbl.TextColor3 = isSelected and Theme.TextPrimary or Theme.TextSecondary
            nameLbl.TextSize = 13
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
            for _, c in ipairs(Categories) do
                if c.Id == selectedCategory then
                    categoryHeaderTitle.Text = c.Name
                    break
                end
            end
        end
        renderModuleList()
    end)

    -- ========== RELOAD BUTTON EVENT ==========
    reloadBtn.MouseEnter:Connect(function()
        tween(reloadBtn, { BackgroundColor3 = Theme.CardHover, ImageColor3 = Theme.TextPrimary })
    end)
    reloadBtn.MouseLeave:Connect(function()
        tween(reloadBtn, { BackgroundColor3 = Theme.PanelHeader, ImageColor3 = Theme.TextSecondary })
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

    -- ========== CLOSE BUTTON EVENT ==========
    closeBtn.MouseEnter:Connect(function()
        tween(closeBtn, { BackgroundColor3 = Theme.Danger, ImageColor3 = Color3.fromRGB(255, 255, 255) })
    end)
    closeBtn.MouseLeave:Connect(function()
        tween(closeBtn, { BackgroundColor3 = Theme.PanelHeader, ImageColor3 = Theme.TextSecondary })
    end)

    closeBtn.MouseButton1Click:Connect(function()
        screenGui.Enabled = false
        menuOpen = false
    end)

    -- ========== DRAGGING & LIVE RESIZING LOGIC ==========
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

        if resizingWindow and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - resizeStartMouse
            local newW = math.clamp(resizeStartSize.X + delta.X, MIN_WIDTH, 1400)
            local newH = math.clamp(resizeStartSize.Y + delta.Y, MIN_HEIGHT, 900)
            currentWidth = newW
            currentHeight = newH
            mainWindow.Size = UDim2.new(0, newW, 0, newH)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingWindow = false
            resizingWindow = false
            dot1.BackgroundColor3 = Theme.TextMuted
            dot2.BackgroundColor3 = Theme.TextMuted
            dot3.BackgroundColor3 = Theme.TextMuted
        end
    end)

    -- ========== OPEN / CLOSE ANIMATIONS ==========
    local function playOpenAnim()
        screenGui.Enabled = true
        mainWindow.Position = UDim2.new(0.5, -currentWidth / 2, 0.5, -currentHeight / 2 - 24)
        TweenService:Create(
            mainWindow,
            TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { Position = UDim2.new(0.5, -currentWidth / 2, 0.5, -currentHeight / 2) }
        ):Play()
    end

    local function playCloseAnim()
        local t = TweenService:Create(
            mainWindow,
            TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { Position = UDim2.new(0.5, -currentWidth / 2, 0.5, -currentHeight / 2 - 24) }
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
                        if selectedModule == mod and selectedCategory ~= "SETTINGS" then
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
                            if selectedModule == mod and selectedCategory ~= "SETTINGS" then
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
