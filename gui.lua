local Gui = {}

function Gui.Init(ModuleManager, Notifications)
    local UserInputService = game:GetService("UserInputService")
    local CoreGui          = game:GetService("CoreGui")
    local TweenService     = game:GetService("TweenService")
    local RunService       = game:GetService("RunService")
    local Players          = game:GetService("Players")
    local SoundService     = game:GetService("SoundService")

    local LocalPlayer = Players.LocalPlayer

    local parent = CoreGui
    pcall(function()
        if gethui then parent = gethui() end
    end)

    -- Удаляем старое меню, чтобы при повторном запуске скрипта ничего не дублировалось
    pcall(function()
        local old = parent:FindFirstChild("XclientMenu")
        if old then old:Destroy() end
    end)

    -- ========== LUCIDE VECTOR ICON ASSETS ==========
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
        Zap         = "rbxassetid://10723376114", -- Logo Zap
        GlowShadow  = "rbxassetid://5028857472",  -- 9-slice True Glow Texture
    }

    -- ========== RICH UI SOUND EFFECTS ==========
    local Sounds = {
        ToggleOn    = "rbxassetid://6895079853", -- Современный чёткий щелчок включения
        ToggleOff   = "rbxassetid://4590662766", -- Мягкий щелчок выключения
        TabClick    = "rbxassetid://6542983700", -- Клик по категориям
        ButtonClick = "rbxassetid://6895079853", -- Клик по кнопкам интерфейса
        SliderTick  = "rbxassetid://9069609268", -- Щелчок ползунка
        MenuOpen    = "rbxassetid://10029801832", -- Плавный звук открытия меню
        MenuClose   = "rbxassetid://10029801832", -- Звук закрытия меню
    }

    local function playSound(soundId, vol, pitch)
        pcall(function()
            local s = Instance.new("Sound")
            s.SoundId = soundId
            s.Volume = vol or 0.45
            s.Pitch = pitch or 1.0
            s.PlayOnRemove = true
            s.Parent = SoundService
            s:Destroy()
        end)
    end

    -- ========== БЕЗУПРЕЧНЫЙ ПЛОТНЫЙ ШРИФТ БЕЗ РАЗРЫВОВ КИРИЛЛИЦЫ ==========
    -- Используем BuilderSansBold (новый шрифт Roblox 2024 с идеальной кириллицей)
    -- с надёжным фоллбеком на SourceSansBold, в котором нет бага с буквой 'л'
    local MainFont = Enum.Font.SourceSansBold
    pcall(function()
        if Enum.Font.BuilderSansBold then
            MainFont = Enum.Font.BuilderSansBold
        end
    end)

    -- ========== MENU CONFIG & RICH THEME ==========
    local MenuConfig = {
        LiquidGlass    = true,
        MenuGlow       = true,
        WindowOpacity  = 0.92,
        AnimationSpeed = 1.0,
        MenuScale      = 1.0,
        AccentColor    = Color3.fromRGB(120, 100, 255), -- Фирменный Rich Purple
    }

    local AccentPresets = {
        { Name = "Фиолетовый",   Color = Color3.fromRGB(120, 100, 255) },
        { Name = "Электро-циан", Color = Color3.fromRGB(56, 189, 248) },
        { Name = "Изумруд",      Color = Color3.fromRGB(34, 197, 94) },
        { Name = "Рубин",        Color = Color3.fromRGB(239, 68, 68) },
        { Name = "Янтарь",       Color = Color3.fromRGB(245, 158, 11) },
        { Name = "Неон-розовый", Color = Color3.fromRGB(236, 72, 153) },
        { Name = "Синий",        Color = Color3.fromRGB(59, 130, 246) },
    }

    local Theme = {
        WindowBg      = Color3.fromRGB(14, 16, 25),
        PanelBg       = Color3.fromRGB(19, 22, 34),
        PanelHeader   = Color3.fromRGB(25, 29, 45),
        CardBg        = Color3.fromRGB(24, 28, 43),
        CardHover     = Color3.fromRGB(32, 38, 58),
        CardSelected  = Color3.fromRGB(36, 42, 65),
        StrokeDim     = Color3.fromRGB(40, 45, 66),
        TextPrimary   = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(180, 190, 215),
        TextMuted     = Color3.fromRGB(115, 125, 148),
        Success       = Color3.fromRGB(34, 197, 94),
        Danger        = Color3.fromRGB(239, 68, 68),
        SwitchOff     = Color3.fromRGB(38, 43, 62),
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

    local BASE_WIDTH           = 850
    local BASE_HEIGHT          = 520

    local moduleCardItems      = {}
    local categoryButtons      = {}
    local accentColorObjects   = {}
    local currentDraggingSlider= nil

    -- ========== SCREEN GUI ==========
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "XclientMenu"
    screenGui.ResetOnSpawn = false
    screenGui.Enabled = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = parent

    -- ========== TRUE NEON GLOW BLOOM (9-SLICE PNG) ==========
    local glowShadow = Instance.new("ImageLabel")
    glowShadow.Name = "NeonGlowBloom"
    glowShadow.AnchorPoint = Vector2.new(0.5, 0.5)
    glowShadow.Size = UDim2.new(0, BASE_WIDTH + 60, 0, BASE_HEIGHT + 60)
    glowShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    glowShadow.BackgroundTransparency = 1
    glowShadow.Image = Icons.GlowShadow
    glowShadow.ImageColor3 = MenuConfig.AccentColor
    glowShadow.ImageTransparency = MenuConfig.MenuGlow and 0.55 or 1
    glowShadow.ScaleType = Enum.ScaleType.Slice
    glowShadow.SliceCenter = Rect.new(24, 24, 276, 276)
    glowShadow.ZIndex = 1
    glowShadow.Parent = screenGui

    local glowScale = Instance.new("UIScale", glowShadow)
    glowScale.Name = "GlowScale"
    glowScale.Scale = MenuConfig.MenuScale

    -- ========== MAIN WINDOW (RICH-MODERN SHELL) ==========
    local mainWindow = Instance.new("Frame")
    mainWindow.Name = "RichModernWindow"
    mainWindow.AnchorPoint = Vector2.new(0.5, 0.5)
    mainWindow.Size = UDim2.new(0, BASE_WIDTH, 0, BASE_HEIGHT)
    mainWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainWindow.BackgroundColor3 = Theme.WindowBg
    mainWindow.BackgroundTransparency = 1 - MenuConfig.WindowOpacity
    mainWindow.BorderSizePixel = 0
    mainWindow.ClipsDescendants = false
    mainWindow.ZIndex = 2
    mainWindow.Parent = screenGui
    Instance.new("UICorner", mainWindow).CornerRadius = UDim.new(0, 16)

    -- ДИНАМИЧЕСКИЙ МАСШТАБ ВСЕХ ЭЛЕМЕНТОВ (ШРИФТЫ, ИКОНКИ, КАРТОЧКИ, ОТСТУПЫ)
    local menuScale = Instance.new("UIScale", mainWindow)
    menuScale.Name = "MenuScale"
    menuScale.Scale = MenuConfig.MenuScale

    -- Liquid Glass Specular Gradient Stroke
    local mainStroke = Instance.new("UIStroke", mainWindow)
    mainStroke.Color = Color3.fromRGB(255, 255, 255)
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
        NumberSequenceKeypoint.new(0.0, 0.25),
        NumberSequenceKeypoint.new(0.4, 0.65),
        NumberSequenceKeypoint.new(1.0, 0.92),
    })

    -- Specular Glass Highlight Line (Top Sheen)
    local topSheen = Instance.new("Frame")
    topSheen.Name = "TopGlassSheen"
    topSheen.Size = UDim2.new(1, -32, 0, 1.5)
    topSheen.Position = UDim2.new(0, 16, 0, 1)
    topSheen.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    topSheen.BorderSizePixel = 0
    topSheen.ZIndex = 3
    topSheen.Parent = mainWindow

    local sheenGrad = Instance.new("UIGradient", topSheen)
    sheenGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0.0, 1.0),
        NumberSequenceKeypoint.new(0.5, 0.4),
        NumberSequenceKeypoint.new(1.0, 1.0),
    })

    -- ========== HELPERS ==========
    local function notify(text, dur, color)
        if Notifications and Notifications.Show then
            Notifications:Show(text, dur, color)
        end
    end

    local function tween(inst, props, dur, easingStyle, easingDir)
        dur = (dur or 0.16) / math.max(0.2, MenuConfig.AnimationSpeed)
        TweenService:Create(
            inst,
            TweenInfo.new(dur, easingStyle or Enum.EasingStyle.Cubic, easingDir or Enum.EasingDirection.Out),
            props
        ):Play()
    end

    local function registerAccent(inst, property)
        table.insert(accentColorObjects, { inst = inst, prop = property })
    end

    local function applyAccentColor(newColor)
        MenuConfig.AccentColor = newColor
        glowShadow.ImageColor3 = newColor
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

    local function setGuiScale(newScale)
        newScale = math.clamp(newScale, 0.70, 1.45)
        MenuConfig.MenuScale = newScale
        menuScale.Scale = newScale
        glowScale.Scale = newScale
    end

    -- ========== LEFT SIDEBAR ==========
    local SIDEBAR_WIDTH = 180
    local PADDING = 10

    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, SIDEBAR_WIDTH, 1, -PADDING * 2)
    sidebar.Position = UDim2.new(0, PADDING, 0, PADDING)
    sidebar.BackgroundColor3 = Theme.PanelBg
    sidebar.BackgroundTransparency = 0.25
    sidebar.BorderSizePixel = 0
    sidebar.ZIndex = 2
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
    brandCard.ZIndex = 3
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
    logoImg.ScaleType = Enum.ScaleType.Fit
    logoImg.ImageColor3 = MenuConfig.AccentColor
    logoImg.ZIndex = 4
    logoImg.Parent = brandCard
    registerAccent(logoImg, "ImageColor3")

    local brandTitle = Instance.new("TextLabel")
    brandTitle.Size = UDim2.new(1, -44, 0, 20)
    brandTitle.Position = UDim2.new(0, 38, 0, 6)
    brandTitle.BackgroundTransparency = 1
    brandTitle.Font = MainFont
    brandTitle.Text = "XCLIENT"
    brandTitle.TextColor3 = Theme.TextPrimary
    brandTitle.TextSize = 16
    brandTitle.TextXAlignment = Enum.TextXAlignment.Left
    brandTitle.ZIndex = 4
    brandTitle.Parent = brandCard

    local brandSub = Instance.new("TextLabel")
    brandSub.Size = UDim2.new(1, -44, 0, 14)
    brandSub.Position = UDim2.new(0, 38, 0, 26)
    brandSub.BackgroundTransparency = 1
    brandSub.Font = MainFont
    brandSub.Text = "v2.0 • Modern"
    brandSub.TextColor3 = Color3.fromRGB(56, 189, 248)
    brandSub.TextSize = 11
    brandSub.TextXAlignment = Enum.TextXAlignment.Left
    brandSub.ZIndex = 4
    brandSub.Parent = brandCard

    -- Categories Buttons Container
    local catContainer = Instance.new("ScrollingFrame")
    catContainer.Name = "CategoryList"
    catContainer.Size = UDim2.new(1, -16, 1, -132)
    catContainer.Position = UDim2.new(0, 8, 0, 68)
    catContainer.BackgroundTransparency = 1
    catContainer.BorderSizePixel = 0
    catContainer.ScrollBarThickness = 0
    catContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    catContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    catContainer.ZIndex = 3
    catContainer.Parent = sidebar

    local catPad = Instance.new("UIPadding", catContainer)
    catPad.PaddingTop = UDim.new(0, 2)
    catPad.PaddingBottom = UDim.new(0, 2)
    catPad.PaddingLeft = UDim.new(0, 2)
    catPad.PaddingRight = UDim.new(0, 2)

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
    profileCard.ZIndex = 3
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
    avatarImg.ZIndex = 4
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
    profileName.Font = MainFont
    profileName.Text = (LocalPlayer and LocalPlayer.DisplayName) or "Player"
    profileName.TextColor3 = Theme.TextPrimary
    profileName.TextSize = 13
    profileName.TextXAlignment = Enum.TextXAlignment.Left
    profileName.TextTruncate = Enum.TextTruncate.AtEnd
    profileName.ZIndex = 4
    profileName.Parent = profileCard

    local profileStatus = Instance.new("TextLabel")
    profileStatus.Size = UDim2.new(1, -48, 0, 14)
    profileStatus.Position = UDim2.new(0, 46, 0, 25)
    profileStatus.BackgroundTransparency = 1
    profileStatus.Font = MainFont
    profileStatus.Text = "Активен"
    profileStatus.TextColor3 = Theme.Success
    profileStatus.TextSize = 11
    profileStatus.TextXAlignment = Enum.TextXAlignment.Left
    profileStatus.ZIndex = 4
    profileStatus.Parent = profileCard

    -- ========== RIGHT WORKSPACE AREA ==========
    local rightContainer = Instance.new("Frame")
    rightContainer.Name = "RightWorkspace"
    rightContainer.Size = UDim2.new(1, -SIDEBAR_WIDTH - PADDING * 3, 1, -PADDING * 2)
    rightContainer.Position = UDim2.new(0, SIDEBAR_WIDTH + PADDING * 2, 0, PADDING)
    rightContainer.BackgroundTransparency = 1
    rightContainer.ZIndex = 2
    rightContainer.Parent = mainWindow

    -- 1. Top Header Card
    local HEADER_HEIGHT = 46
    local headerCard = Instance.new("Frame")
    headerCard.Name = "HeaderCard"
    headerCard.Size = UDim2.new(1, 0, 0, HEADER_HEIGHT)
    headerCard.Position = UDim2.new(0, 0, 0, 0)
    headerCard.BackgroundColor3 = Theme.PanelBg
    headerCard.BackgroundTransparency = 0.25
    headerCard.BorderSizePixel = 0
    headerCard.ZIndex = 2
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
    categoryHeaderTitle.Font = MainFont
    categoryHeaderTitle.Text = "Combat"
    categoryHeaderTitle.TextColor3 = Theme.TextPrimary
    categoryHeaderTitle.TextSize = 18
    categoryHeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
    categoryHeaderTitle.ZIndex = 3
    categoryHeaderTitle.Parent = headerCard

    -- Action Buttons (Reload & Close) - Frameless, sleek, rounded
    local closeBtn = Instance.new("ImageButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 32, 0, 32)
    closeBtn.Position = UDim2.new(1, -40, 0.5, -16)
    closeBtn.BackgroundColor3 = Color3.fromRGB(26, 30, 46)
    closeBtn.BorderSizePixel = 0
    closeBtn.AutoButtonColor = false
    closeBtn.Image = Icons.Close
    closeBtn.ImageColor3 = Theme.TextSecondary
    closeBtn.ScaleType = Enum.ScaleType.Fit
    closeBtn.ZIndex = 4
    closeBtn.Parent = headerCard
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)

    local reloadBtn = Instance.new("ImageButton")
    reloadBtn.Name = "ReloadButton"
    reloadBtn.Size = UDim2.new(0, 32, 0, 32)
    reloadBtn.Position = UDim2.new(1, -78, 0.5, -16)
    reloadBtn.BackgroundColor3 = Color3.fromRGB(26, 30, 46)
    reloadBtn.BorderSizePixel = 0
    reloadBtn.AutoButtonColor = false
    reloadBtn.Image = Icons.Refresh
    reloadBtn.ImageColor3 = Theme.TextSecondary
    reloadBtn.ScaleType = Enum.ScaleType.Fit
    reloadBtn.ZIndex = 4
    reloadBtn.Parent = headerCard
    Instance.new("UICorner", reloadBtn).CornerRadius = UDim.new(1, 0)

    -- Search Box with Lucide Search Icon
    local searchContainer = Instance.new("Frame")
    searchContainer.Name = "SearchBox"
    searchContainer.Size = UDim2.new(0, 220, 0, 32)
    searchContainer.Position = UDim2.new(1, -310, 0.5, -16)
    searchContainer.BackgroundColor3 = Theme.PanelHeader
    searchContainer.BorderSizePixel = 0
    searchContainer.ZIndex = 3
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
    searchIconImg.ScaleType = Enum.ScaleType.Fit
    searchIconImg.ZIndex = 4
    searchIconImg.Parent = searchContainer

    local searchInput = Instance.new("TextBox")
    searchInput.Size = UDim2.new(1, -36, 1, 0)
    searchInput.Position = UDim2.new(0, 30, 0, 0)
    searchInput.BackgroundTransparency = 1
    searchInput.Font = MainFont
    searchInput.PlaceholderText = "Поиск функций..."
    searchInput.PlaceholderColor3 = Theme.TextMuted
    searchInput.Text = ""
    searchInput.TextColor3 = Theme.TextPrimary
    searchInput.TextSize = 13
    searchInput.TextXAlignment = Enum.TextXAlignment.Left
    searchInput.ClearTextOnFocus = false
    searchInput.ZIndex = 4
    searchInput.Parent = searchContainer

    -- 2. Content Card
    local contentCard = Instance.new("Frame")
    contentCard.Name = "ContentCard"
    contentCard.Size = UDim2.new(1, 0, 1, -HEADER_HEIGHT - 8)
    contentCard.Position = UDim2.new(0, 0, 0, HEADER_HEIGHT + 8)
    contentCard.BackgroundColor3 = Theme.PanelBg
    contentCard.BackgroundTransparency = 0.25
    contentCard.BorderSizePixel = 0
    contentCard.ZIndex = 2
    contentCard.Parent = rightContainer
    Instance.new("UICorner", contentCard).CornerRadius = UDim.new(0, 12)

    local contentStroke = Instance.new("UIStroke", contentCard)
    contentStroke.Color = Theme.StrokeDim
    contentStroke.Thickness = 1

    -- Left Pane: Module List Frame
    local MODULE_LIST_WIDTH = 250

    local moduleListFrame = Instance.new("ScrollingFrame")
    moduleListFrame.Name = "ModuleList"
    moduleListFrame.Size = UDim2.new(0, MODULE_LIST_WIDTH, 1, -16)
    moduleListFrame.Position = UDim2.new(0, 8, 0, 8)
    moduleListFrame.BackgroundTransparency = 1
    moduleListFrame.BorderSizePixel = 0
    moduleListFrame.ScrollBarThickness = 3
    moduleListFrame.ScrollBarImageColor3 = Theme.StrokeDim
    moduleListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    moduleListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    moduleListFrame.ZIndex = 3
    moduleListFrame.Parent = contentCard

    -- ВАЖНО: Отступы UIPadding исключают срезание обводки карточек движком!
    local listPad = Instance.new("UIPadding", moduleListFrame)
    listPad.PaddingTop = UDim.new(0, 6)
    listPad.PaddingBottom = UDim.new(0, 8)
    listPad.PaddingLeft = UDim.new(0, 6)
    listPad.PaddingRight = UDim.new(0, 12)

    local moduleListLayout = Instance.new("UIListLayout", moduleListFrame)
    moduleListLayout.Padding = UDim.new(0, 6)
    moduleListLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- Vertical Divider
    local divider = Instance.new("Frame")
    divider.Name = "Divider"
    divider.Size = UDim2.new(0, 1, 1, -16)
    divider.Position = UDim2.new(0, MODULE_LIST_WIDTH + 16, 0, 8)
    divider.BackgroundColor3 = Theme.StrokeDim
    divider.BorderSizePixel = 0
    divider.ZIndex = 3
    divider.Parent = contentCard

    -- Right Pane: Inspector / Settings Panel
    local INSPECTOR_X = MODULE_LIST_WIDTH + 24
    local inspectorFrame = Instance.new("Frame")
    inspectorFrame.Name = "Inspector"
    inspectorFrame.Size = UDim2.new(1, -INSPECTOR_X - 8, 1, -16)
    inspectorFrame.Position = UDim2.new(0, INSPECTOR_X, 0, 8)
    inspectorFrame.BackgroundTransparency = 1
    inspectorFrame.ZIndex = 3
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
    inspectorScroll.ZIndex = 3
    inspectorScroll.Parent = inspectorFrame

    -- ВАЖНО: Отступы UIPadding для инспектора, чтобы карточки не резались!
    local inspPad = Instance.new("UIPadding", inspectorScroll)
    inspPad.PaddingTop = UDim.new(0, 6)
    inspPad.PaddingBottom = UDim.new(0, 12)
    inspPad.PaddingLeft = UDim.new(0, 6)
    inspPad.PaddingRight = UDim.new(0, 12)

    local inspectorLayout = Instance.new("UIListLayout", inspectorScroll)
    inspectorLayout.Padding = UDim.new(0, 8)
    inspectorLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- ========== RICH-MODERN RESIZE GRIP (3 DOTS BOTTOM-RIGHT) ==========
    local resizeGrip = Instance.new("TextButton")
    resizeGrip.Name = "ResizeGrip"
    resizeGrip.Size = UDim2.new(0, 24, 0, 24)
    resizeGrip.Position = UDim2.new(1, -26, 1, -26)
    resizeGrip.BackgroundTransparency = 1
    resizeGrip.Text = ""
    resizeGrip.ZIndex = 10
    resizeGrip.Parent = mainWindow

    local function makeDot(offsetX, offsetY)
        local d = Instance.new("Frame")
        d.Size = UDim2.new(0, 4, 0, 4)
        d.Position = UDim2.new(1, offsetX, 1, offsetY)
        d.BackgroundColor3 = Theme.TextMuted
        d.BorderSizePixel = 0
        d.ZIndex = 10
        d.Parent = resizeGrip
        Instance.new("UICorner", d).CornerRadius = UDim.new(1, 0)
        return d
    end

    local dot1 = makeDot(-6, -6)
    local dot2 = makeDot(-13, -6)
    local dot3 = makeDot(-6, -13)

    local resizingWindow = false
    local resizeStartMouse = nil
    local resizeStartScale = 1.0

    resizeGrip.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizingWindow = true
            resizeStartMouse = input.Position
            resizeStartScale = menuScale.Scale
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
    local renderModuleList = nil
    local renderInspector  = nil
    local renderMenuSettingsPanel = nil

    -- ========== MENU SETTINGS PANEL RENDERING ==========
    renderMenuSettingsPanel = function()
        for _, child in ipairs(inspectorScroll:GetChildren()) do
            if child:IsA("GuiObject") then child:Destroy() end
        end

        local headerCardMod = Instance.new("Frame")
        headerCardMod.Name = "SettingsHeader"
        headerCardMod.Size = UDim2.new(1, 0, 0, 56)
        headerCardMod.BackgroundColor3 = Theme.CardBg
        headerCardMod.BorderSizePixel = 0
        headerCardMod.LayoutOrder = 1
        headerCardMod.ZIndex = 4
        headerCardMod.Parent = inspectorScroll
        Instance.new("UICorner", headerCardMod).CornerRadius = UDim.new(0, 10)

        local hmStroke = Instance.new("UIStroke", headerCardMod)
        hmStroke.Color = Theme.StrokeDim
        hmStroke.Thickness = 1

        local titleLbl = Instance.new("TextLabel")
        titleLbl.Size = UDim2.new(1, -24, 0, 24)
        titleLbl.Position = UDim2.new(0, 14, 0, 8)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Font = MainFont
        titleLbl.Text = "Настройки интерфейса"
        titleLbl.TextColor3 = Theme.TextPrimary
        titleLbl.TextSize = 16
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.ZIndex = 5
        titleLbl.Parent = headerCardMod

        local subLbl = Instance.new("TextLabel")
        subLbl.Size = UDim2.new(1, -24, 0, 16)
        subLbl.Position = UDim2.new(0, 14, 0, 32)
        subLbl.BackgroundTransparency = 1
        subLbl.Font = MainFont
        subLbl.Text = "Liquid Glass, свечение меню, масштабирование и акценты"
        subLbl.TextColor3 = MenuConfig.AccentColor
        registerAccent(subLbl, "TextColor3")
        subLbl.TextSize = 12
        subLbl.TextXAlignment = Enum.TextXAlignment.Left
        subLbl.ZIndex = 5
        subLbl.Parent = headerCardMod

        local function makeToggleRow(name, desc, state, onToggle, order)
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 50)
            row.BackgroundColor3 = Theme.CardBg
            row.BorderSizePixel = 0
            row.LayoutOrder = order
            row.ZIndex = 4
            row.Parent = inspectorScroll
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

            local rStroke = Instance.new("UIStroke", row)
            rStroke.Color = Theme.StrokeDim
            rStroke.Thickness = 1

            local nl = Instance.new("TextLabel")
            nl.Size = UDim2.new(1, -70, 0, 20)
            nl.Position = UDim2.new(0, 14, 0, 6)
            nl.BackgroundTransparency = 1
            nl.Font = MainFont
            nl.Text = name
            nl.TextColor3 = Theme.TextPrimary
            nl.TextSize = 13
            nl.TextXAlignment = Enum.TextXAlignment.Left
            nl.ZIndex = 5
            nl.Parent = row

            local dl = Instance.new("TextLabel")
            dl.Size = UDim2.new(1, -70, 0, 16)
            dl.Position = UDim2.new(0, 14, 0, 26)
            dl.BackgroundTransparency = 1
            dl.Font = MainFont
            dl.Text = desc
            dl.TextColor3 = Theme.TextMuted
            dl.TextSize = 11
            dl.TextXAlignment = Enum.TextXAlignment.Left
            dl.ZIndex = 5
            dl.Parent = row

            local sw = Instance.new("TextButton")
            sw.Size = UDim2.new(0, 44, 0, 22)
            sw.Position = UDim2.new(1, -56, 0.5, -11)
            sw.BackgroundColor3 = state and MenuConfig.AccentColor or Theme.SwitchOff
            registerAccent(sw, "BackgroundColor3")
            sw.BorderSizePixel = 0
            sw.AutoButtonColor = false
            sw.Text = ""
            sw.ZIndex = 5
            sw.Parent = row
            Instance.new("UICorner", sw).CornerRadius = UDim.new(1, 0)

            local th = Instance.new("Frame")
            th.Size = UDim2.new(0, 16, 0, 16)
            th.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
            th.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            th.BorderSizePixel = 0
            th.ZIndex = 6
            th.Parent = sw
            Instance.new("UICorner", th).CornerRadius = UDim.new(1, 0)

            sw.MouseButton1Click:Connect(function()
                state = not state
                onToggle(state)
                playSound(state and Sounds.ToggleOn or Sounds.ToggleOff, 0.45, state and 1.1 or 0.95)
                tween(sw, { BackgroundColor3 = state and MenuConfig.AccentColor or Theme.SwitchOff }, 0.18, Enum.EasingStyle.Cubic)
                tween(th, { Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8) }, 0.18, Enum.EasingStyle.Cubic)
            end)
        end

        -- Row 2: Liquid Glass
        makeToggleRow(
            "Liquid Glass (Жидкое стекло)",
            "Эффект преломления света и стеклянных граней",
            MenuConfig.LiquidGlass,
            function(v)
                MenuConfig.LiquidGlass = v
                topSheen.Visible = v
                strokeGradient.Enabled = v
                notify("Liquid Glass: " .. (v and "ВКЛ" or "ВЫКЛ"), 1.5, Theme.Success)
            end,
            2
        )

        -- Row 3: Menu Glow (Свечение меню)
        makeToggleRow(
            "Свечение меню (Menu Glow)",
            "Атмосферный неоновый блум вокруг окна",
            MenuConfig.MenuGlow,
            function(v)
                MenuConfig.MenuGlow = v
                glowShadow.ImageTransparency = v and 0.55 or 1
                notify("Свечение: " .. (v and "ВКЛ" or "ВЫКЛ"), 1.5, Theme.Success)
            end,
            3
        )

        -- Row 4: Цвет акцента (Presets)
        local colorCard = Instance.new("Frame")
        colorCard.Size = UDim2.new(1, 0, 0, 76)
        colorCard.BackgroundColor3 = Theme.CardBg
        colorCard.BorderSizePixel = 0
        colorCard.LayoutOrder = 4
        colorCard.ZIndex = 4
        colorCard.Parent = inspectorScroll
        Instance.new("UICorner", colorCard).CornerRadius = UDim.new(0, 8)

        local ccStroke = Instance.new("UIStroke", colorCard)
        ccStroke.Color = Theme.StrokeDim
        ccStroke.Thickness = 1

        local ccTitle = Instance.new("TextLabel")
        ccTitle.Size = UDim2.new(1, -24, 0, 20)
        ccTitle.Position = UDim2.new(0, 14, 0, 8)
        ccTitle.BackgroundTransparency = 1
        ccTitle.Font = MainFont
        ccTitle.Text = "Цвет интерфейса (Accent Color)"
        ccTitle.TextColor3 = Theme.TextPrimary
        ccTitle.TextSize = 13
        ccTitle.TextXAlignment = Enum.TextXAlignment.Left
        ccTitle.ZIndex = 5
        ccTitle.Parent = colorCard

        local colorsScroll = Instance.new("ScrollingFrame")
        colorsScroll.Size = UDim2.new(1, -24, 0, 34)
        colorsScroll.Position = UDim2.new(0, 14, 0, 32)
        colorsScroll.BackgroundTransparency = 1
        colorsScroll.BorderSizePixel = 0
        colorsScroll.ScrollBarThickness = 0
        colorsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        colorsScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
        colorsScroll.ZIndex = 5
        colorsScroll.Parent = colorCard

        local cList = Instance.new("UIListLayout", colorsScroll)
        cList.FillDirection = Enum.FillDirection.Horizontal
        cList.Padding = UDim.new(0, 8)

        for _, preset in ipairs(AccentPresets) do
            local dot = Instance.new("TextButton")
            dot.Size = UDim2.new(0, 26, 0, 26)
            dot.BackgroundColor3 = preset.Color
            dot.BorderSizePixel = 0
            dot.Text = ""
            dot.AutoButtonColor = false
            dot.ZIndex = 6
            dot.Parent = colorsScroll
            Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

            local dStroke = Instance.new("UIStroke", dot)
            dStroke.Color = (preset.Color == MenuConfig.AccentColor) and Color3.fromRGB(255, 255, 255) or Theme.StrokeDim
            dStroke.Thickness = 2

            dot.MouseButton1Click:Connect(function()
                applyAccentColor(preset.Color)
                playSound(Sounds.ButtonClick, 0.45, 1.1)
                notify("Акцент: " .. preset.Name, 1.5, preset.Color)
                renderMenuSettingsPanel()
            end)
        end

        -- Row 5: Прозрачность окна (Slider)
        local opCard = Instance.new("Frame")
        opCard.Size = UDim2.new(1, 0, 0, 58)
        opCard.BackgroundColor3 = Theme.CardBg
        opCard.BorderSizePixel = 0
        opCard.LayoutOrder = 5
        opCard.ZIndex = 4
        opCard.Parent = inspectorScroll
        Instance.new("UICorner", opCard).CornerRadius = UDim.new(0, 8)

        local opStroke = Instance.new("UIStroke", opCard)
        opStroke.Color = Theme.StrokeDim
        opStroke.Thickness = 1

        local opTitle = Instance.new("TextLabel")
        opTitle.Size = UDim2.new(0.6, 0, 0, 20)
        opTitle.Position = UDim2.new(0, 14, 0, 8)
        opTitle.BackgroundTransparency = 1
        opTitle.Font = MainFont
        opTitle.Text = "Прозрачность окна"
        opTitle.TextColor3 = Theme.TextPrimary
        opTitle.TextSize = 13
        opTitle.TextXAlignment = Enum.TextXAlignment.Left
        opTitle.ZIndex = 5
        opTitle.Parent = opCard

        local opValLbl = Instance.new("TextLabel")
        opValLbl.Size = UDim2.new(0, 60, 0, 20)
        opValLbl.Position = UDim2.new(1, -74, 0, 8)
        opValLbl.BackgroundTransparency = 1
        opValLbl.Font = MainFont
        opValLbl.Text = string.format("%.0f%%", MenuConfig.WindowOpacity * 100)
        opValLbl.TextColor3 = MenuConfig.AccentColor
        registerAccent(opValLbl, "TextColor3")
        opValLbl.TextSize = 13
        opValLbl.TextXAlignment = Enum.TextXAlignment.Right
        opValLbl.ZIndex = 5
        opValLbl.Parent = opCard

        local opBarBg = Instance.new("Frame")
        opBarBg.Size = UDim2.new(1, -28, 0, 5)
        opBarBg.Position = UDim2.new(0, 14, 0, 36)
        opBarBg.BackgroundColor3 = Color3.fromRGB(34, 39, 58)
        opBarBg.BorderSizePixel = 0
        opBarBg.ZIndex = 5
        opBarBg.Parent = opCard
        Instance.new("UICorner", opBarBg).CornerRadius = UDim.new(1, 0)

        local opBarFill = Instance.new("Frame")
        opBarFill.Size = UDim2.new(MenuConfig.WindowOpacity, 0, 1, 0)
        opBarFill.BackgroundColor3 = MenuConfig.AccentColor
        registerAccent(opBarFill, "BackgroundColor3")
        opBarFill.BorderSizePixel = 0
        opBarFill.ZIndex = 6
        opBarFill.Parent = opBarBg
        Instance.new("UICorner", opBarFill).CornerRadius = UDim.new(1, 0)

        local opThumb = Instance.new("Frame")
        opThumb.Size = UDim2.new(0, 14, 0, 14)
        opThumb.Position = UDim2.new(MenuConfig.WindowOpacity, -7, 0.5, -7)
        opThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        opThumb.BorderSizePixel = 0
        opThumb.ZIndex = 8
        opThumb.Parent = opBarBg
        Instance.new("UICorner", opThumb).CornerRadius = UDim.new(1, 0)

        local opThStroke = Instance.new("UIStroke", opThumb)
        opThStroke.Color = MenuConfig.AccentColor
        registerAccent(opThStroke, "Color")
        opThStroke.Thickness = 2

        local opHit = Instance.new("TextButton")
        opHit.Size = UDim2.new(1, 0, 0, 26)
        opHit.Position = UDim2.new(0, 0, 0, 24)
        opHit.BackgroundTransparency = 1
        opHit.Text = ""
        opHit.ZIndex = 9
        opHit.Parent = opCard

        local function updateOp(inputX)
            local absPos = opBarBg.AbsolutePosition.X
            local absSize = opBarBg.AbsoluteSize.X
            if absSize <= 0 then return end
            local p = math.clamp((inputX - absPos) / absSize, 0.35, 1.0)
            MenuConfig.WindowOpacity = p
            mainWindow.BackgroundTransparency = 1 - p
            opBarFill.Size = UDim2.new(p, 0, 1, 0)
            opThumb.Position = UDim2.new(p, -7, 0.5, -7)
            opValLbl.Text = string.format("%.0f%%", p * 100)
        end

        opHit.MouseButton1Down:Connect(function()
            inspectorScroll.ScrollingEnabled = false
            currentDraggingSlider = {
                update = updateOp,
                finish = function() inspectorScroll.ScrollingEnabled = true end
            }
            local mouseLoc = UserInputService:GetMouseLocation()
            updateOp(mouseLoc.X)
        end)

        -- Row 6: Масштаб меню GUI Scale (Slider)
        local scaleCard = Instance.new("Frame")
        scaleCard.Size = UDim2.new(1, 0, 0, 58)
        scaleCard.BackgroundColor3 = Theme.CardBg
        scaleCard.BorderSizePixel = 0
        scaleCard.LayoutOrder = 6
        scaleCard.ZIndex = 4
        scaleCard.Parent = inspectorScroll
        Instance.new("UICorner", scaleCard).CornerRadius = UDim.new(0, 8)

        local scStroke = Instance.new("UIStroke", scaleCard)
        scStroke.Color = Theme.StrokeDim
        scStroke.Thickness = 1

        local scTitle = Instance.new("TextLabel")
        scTitle.Size = UDim2.new(0.6, 0, 0, 20)
        scTitle.Position = UDim2.new(0, 14, 0, 8)
        scTitle.BackgroundTransparency = 1
        scTitle.Font = MainFont
        scTitle.Text = "Масштаб интерфейса (GUI Scale)"
        scTitle.TextColor3 = Theme.TextPrimary
        scTitle.TextSize = 13
        scTitle.TextXAlignment = Enum.TextXAlignment.Left
        scTitle.ZIndex = 5
        scTitle.Parent = scaleCard

        local scValLbl = Instance.new("TextLabel")
        scValLbl.Size = UDim2.new(0, 60, 0, 20)
        scValLbl.Position = UDim2.new(1, -74, 0, 8)
        scValLbl.BackgroundTransparency = 1
        scValLbl.Font = MainFont
        scValLbl.Text = string.format("%.0f%%", menuScale.Scale * 100)
        scValLbl.TextColor3 = MenuConfig.AccentColor
        registerAccent(scValLbl, "TextColor3")
        scValLbl.TextSize = 13
        scValLbl.TextXAlignment = Enum.TextXAlignment.Right
        scValLbl.ZIndex = 5
        scValLbl.Parent = scaleCard

        local scBarBg = Instance.new("Frame")
        scBarBg.Size = UDim2.new(1, -28, 0, 5)
        scBarBg.Position = UDim2.new(0, 14, 0, 36)
        scBarBg.BackgroundColor3 = Color3.fromRGB(34, 39, 58)
        scBarBg.BorderSizePixel = 0
        scBarBg.ZIndex = 5
        scBarBg.Parent = scaleCard
        Instance.new("UICorner", scBarBg).CornerRadius = UDim.new(1, 0)

        local scNorm = math.clamp((menuScale.Scale - 0.75) / (1.40 - 0.75), 0, 1)

        local scBarFill = Instance.new("Frame")
        scBarFill.Size = UDim2.new(scNorm, 0, 1, 0)
        scBarFill.BackgroundColor3 = MenuConfig.AccentColor
        registerAccent(scBarFill, "BackgroundColor3")
        scBarFill.BorderSizePixel = 0
        scBarFill.ZIndex = 6
        scBarFill.Parent = scBarBg
        Instance.new("UICorner", scBarFill).CornerRadius = UDim.new(1, 0)

        local scThumb = Instance.new("Frame")
        scThumb.Size = UDim2.new(0, 14, 0, 14)
        scThumb.Position = UDim2.new(scNorm, -7, 0.5, -7)
        scThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        scThumb.BorderSizePixel = 0
        scThumb.ZIndex = 8
        scThumb.Parent = scBarBg
        Instance.new("UICorner", scThumb).CornerRadius = UDim.new(1, 0)

        local scThStroke = Instance.new("UIStroke", scThumb)
        scThStroke.Color = MenuConfig.AccentColor
        registerAccent(scThStroke, "Color")
        scThStroke.Thickness = 2

        local scHit = Instance.new("TextButton")
        scHit.Size = UDim2.new(1, 0, 0, 26)
        scHit.Position = UDim2.new(0, 0, 0, 24)
        scHit.BackgroundTransparency = 1
        scHit.Text = ""
        scHit.ZIndex = 9
        scHit.Parent = scaleCard

        local function updateScale(inputX)
            local absPos = scBarBg.AbsolutePosition.X
            local absSize = scBarBg.AbsoluteSize.X
            if absSize <= 0 then return end
            local p = math.clamp((inputX - absPos) / absSize, 0, 1)
            local targetScale = 0.75 + p * (1.40 - 0.75)
            targetScale = math.floor(targetScale * 100 + 0.5) / 100
            setGuiScale(targetScale)
            scBarFill.Size = UDim2.new(p, 0, 1, 0)
            scThumb.Position = UDim2.new(p, -7, 0.5, -7)
            scValLbl.Text = string.format("%.0f%%", targetScale * 100)
        end

        scHit.MouseButton1Down:Connect(function()
            inspectorScroll.ScrollingEnabled = false
            currentDraggingSlider = {
                update = updateScale,
                finish = function() inspectorScroll.ScrollingEnabled = true end
            }
            local mouseLoc = UserInputService:GetMouseLocation()
            updateScale(mouseLoc.X)
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
            icon.ScaleType = Enum.ScaleType.Fit
            icon.ZIndex = 4
            icon.Parent = empty

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 0, 24)
            lbl.Position = UDim2.new(0, 0, 0.35, 56)
            lbl.BackgroundTransparency = 1
            lbl.Font = MainFont
            lbl.Text = "Выберите модуль для настройки"
            lbl.TextColor3 = Theme.TextMuted
            lbl.TextSize = 14
            lbl.ZIndex = 4
            lbl.Parent = empty
            return
        end

        -- Header Card in Inspector
        local headerCardMod = Instance.new("Frame")
        headerCardMod.Name = "ModHeader"
        headerCardMod.Size = UDim2.new(1, 0, 0, 60)
        headerCardMod.BackgroundColor3 = Theme.CardBg
        headerCardMod.BorderSizePixel = 0
        headerCardMod.LayoutOrder = 1
        headerCardMod.ZIndex = 4
        headerCardMod.Parent = inspectorScroll
        Instance.new("UICorner", headerCardMod).CornerRadius = UDim.new(0, 10)

        local hmStroke = Instance.new("UIStroke", headerCardMod)
        hmStroke.Color = Theme.StrokeDim
        hmStroke.Thickness = 1

        local modNameLbl = Instance.new("TextLabel")
        modNameLbl.Size = UDim2.new(0.65, 0, 0, 24)
        modNameLbl.Position = UDim2.new(0, 14, 0, 8)
        modNameLbl.BackgroundTransparency = 1
        modNameLbl.Font = MainFont
        modNameLbl.Text = mod.Name or "Unknown"
        modNameLbl.TextColor3 = Theme.TextPrimary
        modNameLbl.TextSize = 17
        modNameLbl.TextXAlignment = Enum.TextXAlignment.Left
        modNameLbl.ZIndex = 5
        modNameLbl.Parent = headerCardMod

        local catTag = Instance.new("TextLabel")
        catTag.Size = UDim2.new(0.65, 0, 0, 16)
        catTag.Position = UDim2.new(0, 14, 0, 34)
        catTag.BackgroundTransparency = 1
        catTag.Font = MainFont
        catTag.Text = "Категория: " .. (mod.Category or "Misc")
        catTag.TextColor3 = MenuConfig.AccentColor
        registerAccent(catTag, "TextColor3")
        catTag.TextSize = 12
        catTag.TextXAlignment = Enum.TextXAlignment.Left
        catTag.ZIndex = 5
        catTag.Parent = headerCardMod

        -- Master Switch in Inspector Header
        local masterSwitch = Instance.new("TextButton")
        masterSwitch.Size = UDim2.new(0, 48, 0, 24)
        masterSwitch.Position = UDim2.new(1, -62, 0.5, -12)
        masterSwitch.BackgroundColor3 = mod.Enabled and MenuConfig.AccentColor or Theme.SwitchOff
        masterSwitch.BorderSizePixel = 0
        masterSwitch.AutoButtonColor = false
        masterSwitch.Text = ""
        masterSwitch.ZIndex = 5
        masterSwitch.Parent = headerCardMod
        Instance.new("UICorner", masterSwitch).CornerRadius = UDim.new(1, 0)

        local masterThumb = Instance.new("Frame")
        masterThumb.Size = UDim2.new(0, 18, 0, 18)
        masterThumb.Position = mod.Enabled and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        masterThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        masterThumb.BorderSizePixel = 0
        masterThumb.ZIndex = 6
        masterThumb.Parent = masterSwitch
        Instance.new("UICorner", masterThumb).CornerRadius = UDim.new(1, 0)

        masterSwitch.MouseButton1Click:Connect(function()
            ModuleManager:SetEnabled(mod, not mod.Enabled)
            local state = mod.Enabled
            playSound(state and Sounds.ToggleOn or Sounds.ToggleOff, 0.45, state and 1.1 or 0.95)
            tween(masterSwitch, { BackgroundColor3 = state and MenuConfig.AccentColor or Theme.SwitchOff }, 0.18, Enum.EasingStyle.Cubic)
            tween(masterThumb, { Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9) }, 0.18, Enum.EasingStyle.Cubic)

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

        -- Keybind Row (Элегантный бейдж справа как в Rich ModernBindWidget)
        local kbRow = Instance.new("Frame")
        kbRow.Size = UDim2.new(1, 0, 0, 42)
        kbRow.BackgroundColor3 = Theme.CardBg
        kbRow.BorderSizePixel = 0
        kbRow.LayoutOrder = 2
        kbRow.ZIndex = 4
        kbRow.Parent = inspectorScroll
        Instance.new("UICorner", kbRow).CornerRadius = UDim.new(0, 8)

        local kbStroke = Instance.new("UIStroke", kbRow)
        kbStroke.Color = Theme.StrokeDim
        kbStroke.Thickness = 1

        local kbLabel = Instance.new("TextLabel")
        kbLabel.Size = UDim2.new(0.6, 0, 1, 0)
        kbLabel.Position = UDim2.new(0, 14, 0, 0)
        kbLabel.BackgroundTransparency = 1
        kbLabel.Font = MainFont
        kbLabel.Text = "Горячая клавиша"
        kbLabel.TextColor3 = Theme.TextSecondary
        kbLabel.TextSize = 13
        kbLabel.TextXAlignment = Enum.TextXAlignment.Left
        kbLabel.ZIndex = 5
        kbLabel.Parent = kbRow

        local boundKey = ModuleManager.Keybinds[mod.Name]
        local kbBtn = Instance.new("TextButton")
        kbBtn.AnchorPoint = Vector2.new(1, 0.5)
        kbBtn.Size = UDim2.new(0, 84, 0, 24)
        kbBtn.Position = UDim2.new(1, -12, 0.5, 0)
        kbBtn.BackgroundColor3 = Color3.fromRGB(28, 33, 50)
        kbBtn.BorderSizePixel = 0
        kbBtn.AutoButtonColor = false
        kbBtn.Font = MainFont
        kbBtn.TextSize = 12
        kbBtn.TextColor3 = boundKey and MenuConfig.AccentColor or Theme.TextMuted
        kbBtn.Text = boundKey and ("[" .. boundKey .. "]") or "[ Нет ]"
        kbBtn.ZIndex = 5
        kbBtn.Parent = kbRow
        Instance.new("UICorner", kbBtn).CornerRadius = UDim.new(0, 6)

        local kbBtnStroke = Instance.new("UIStroke", kbBtn)
        kbBtnStroke.Color = boundKey and MenuConfig.AccentColor or Theme.StrokeDim
        kbBtnStroke.Thickness = 1.2

        kbBtn.MouseButton1Click:Connect(function()
            if keybindListening then return end
            keybindListening = true
            playSound(Sounds.ButtonClick, 0.5, 1.2)
            kbBtn.Text = "[ Нажмите... ]"
            kbBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            kbBtn.BackgroundColor3 = MenuConfig.AccentColor
            kbBtnStroke.Color = Color3.fromRGB(255, 255, 255)

            keybindCallback = function(input)
                keybindListening = false
                keybindCallback = nil
                kbBtn.BackgroundColor3 = Color3.fromRGB(28, 33, 50)

                local keyName = nil
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    if input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Escape then
                        ModuleManager.Keybinds[mod.Name] = nil
                        kbBtn.Text = "[ Нет ]"
                        kbBtn.TextColor3 = Theme.TextMuted
                        kbBtnStroke.Color = Theme.StrokeDim
                        playSound(Sounds.ToggleOff, 0.4, 0.9)
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
                    kbBtn.TextColor3 = MenuConfig.AccentColor
                    kbBtnStroke.Color = MenuConfig.AccentColor
                    playSound(Sounds.ButtonClick, 0.5, 1.1)
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
                local sName    = def.Name    or "Setting"
                local sKey     = def.Key     or sName
                local sDefault = def.Default
                local sType    = def.Type    or "Slider"

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
                    card.Size = UDim2.new(1, 0, 0, 58)
                    card.BackgroundColor3 = Theme.CardBg
                    card.BorderSizePixel = 0
                    card.LayoutOrder = orderCounter
                    card.ZIndex = 4
                    card.Parent = inspectorScroll
                    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

                    local sStroke = Instance.new("UIStroke", card)
                    sStroke.Color = Theme.StrokeDim
                    sStroke.Thickness = 1

                    local lbl = Instance.new("TextLabel")
                    lbl.Size = UDim2.new(0.65, 0, 0, 22)
                    lbl.Position = UDim2.new(0, 14, 0, 6)
                    lbl.BackgroundTransparency = 1
                    lbl.Font = MainFont
                    lbl.Text = sName
                    lbl.TextColor3 = Theme.TextSecondary
                    lbl.TextSize = 13
                    lbl.TextXAlignment = Enum.TextXAlignment.Left
                    lbl.ZIndex = 5
                    lbl.Parent = card

                    -- Value Badge
                    local valBadge = Instance.new("Frame")
                    valBadge.Size = UDim2.new(0, 52, 0, 20)
                    valBadge.Position = UDim2.new(1, -66, 0, 6)
                    valBadge.BackgroundColor3 = Theme.PanelHeader
                    valBadge.BorderSizePixel = 0
                    valBadge.ZIndex = 5
                    valBadge.Parent = card
                    Instance.new("UICorner", valBadge).CornerRadius = UDim.new(0, 6)

                    local vbStroke = Instance.new("UIStroke", valBadge)
                    vbStroke.Color = MenuConfig.AccentColor
                    registerAccent(vbStroke, "Color")
                    vbStroke.Thickness = 1

                    local valLbl = Instance.new("TextLabel")
                    valLbl.Size = UDim2.new(1, 0, 1, 0)
                    valLbl.BackgroundTransparency = 1
                    valLbl.Font = MainFont
                    valLbl.Text = tostring(currentVal) .. sSuffix
                    valLbl.TextColor3 = MenuConfig.AccentColor
                    registerAccent(valLbl, "TextColor3")
                    valLbl.TextSize = 12
                    valLbl.ZIndex = 6
                    valLbl.Parent = valBadge

                    -- Track Bar (Clean, Solid Luminous Bar WITHOUT ugly white stripe!)
                    local barBg = Instance.new("Frame")
                    barBg.Size = UDim2.new(1, -28, 0, 5)
                    barBg.Position = UDim2.new(0, 14, 0, 36)
                    barBg.BackgroundColor3 = Color3.fromRGB(34, 39, 58)
                    barBg.BorderSizePixel = 0
                    barBg.ZIndex = 5
                    barBg.Parent = card
                    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

                    local pct = math.clamp((currentVal - sMin) / (sMax - sMin), 0, 1)

                    local barFill = Instance.new("Frame")
                    barFill.Size = UDim2.new(pct, 0, 1, 0)
                    barFill.BackgroundColor3 = MenuConfig.AccentColor
                    registerAccent(barFill, "BackgroundColor3")
                    barFill.BorderSizePixel = 0
                    barFill.ZIndex = 6
                    barFill.Parent = barBg
                    Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

                    -- REAL VISIBLE DRAGGABLE THUMB KNOB (14x14)
                    local thumb = Instance.new("Frame")
                    thumb.Name = "SliderThumb"
                    thumb.Size = UDim2.new(0, 14, 0, 14)
                    thumb.Position = UDim2.new(pct, -7, 0.5, -7)
                    thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    thumb.BorderSizePixel = 0
                    thumb.ZIndex = 8
                    thumb.Parent = barBg
                    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)

                    local thStroke = Instance.new("UIStroke", thumb)
                    thStroke.Color = MenuConfig.AccentColor
                    registerAccent(thStroke, "Color")
                    thStroke.Thickness = 2

                    -- ШИРОКАЯ ЗОНА ЗАХВАТА: исключает срыв при быстром движении!
                    local hitArea = Instance.new("TextButton")
                    hitArea.Size = UDim2.new(1, 0, 0, 26)
                    hitArea.Position = UDim2.new(0, 0, 0, 24)
                    hitArea.BackgroundTransparency = 1
                    hitArea.Text = ""
                    hitArea.ZIndex = 9
                    hitArea.Parent = card

                    local function updateSlider(inputX)
                        local absPos = barBg.AbsolutePosition.X
                        local absSize = barBg.AbsoluteSize.X
                        if absSize <= 0 then return end
                        local p = math.clamp((inputX - absPos) / absSize, 0, 1)
                        local raw = sMin + p * (sMax - sMin)
                        local stepped = math.floor(raw / sStep + 0.5) * sStep
                        stepped = math.clamp(stepped, sMin, sMax)
                        if stepped ~= currentVal then
                            currentVal = stepped
                            if not mod.__settings__ then mod.__settings__ = {} end
                            mod.__settings__[sKey] = currentVal
                            playSound(Sounds.SliderTick, 0.2, 1.25)
                        end

                        local newP = math.clamp((currentVal - sMin) / (sMax - sMin), 0, 1)
                        barFill.Size = UDim2.new(newP, 0, 1, 0)
                        thumb.Position = UDim2.new(newP, -7, 0.5, -7)
                        valLbl.Text = tostring(currentVal) .. sSuffix
                    end

                    hitArea.MouseButton1Down:Connect(function()
                        inspectorScroll.ScrollingEnabled = false
                        currentDraggingSlider = {
                            update = updateSlider,
                            finish = function() inspectorScroll.ScrollingEnabled = true end
                        }
                        local mouseLoc = UserInputService:GetMouseLocation()
                        updateSlider(mouseLoc.X)
                    end)

                elseif sType == "Toggle" then
                    local currentVal = sDefault or false
                    if mod.__settings__ and mod.__settings__[sKey] ~= nil then
                        currentVal = mod.__settings__[sKey]
                    end

                    local row = Instance.new("Frame")
                    row.Size = UDim2.new(1, 0, 0, 42)
                    row.BackgroundColor3 = Theme.CardBg
                    row.BorderSizePixel = 0
                    row.LayoutOrder = orderCounter
                    row.ZIndex = 4
                    row.Parent = inspectorScroll
                    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

                    local tStroke = Instance.new("UIStroke", row)
                    tStroke.Color = Theme.StrokeDim
                    tStroke.Thickness = 1

                    local lbl = Instance.new("TextLabel")
                    lbl.Size = UDim2.new(1, -66, 1, 0)
                    lbl.Position = UDim2.new(0, 14, 0, 0)
                    lbl.BackgroundTransparency = 1
                    lbl.Font = MainFont
                    lbl.Text = sName
                    lbl.TextColor3 = Theme.TextSecondary
                    lbl.TextSize = 13
                    lbl.TextXAlignment = Enum.TextXAlignment.Left
                    lbl.ZIndex = 5
                    lbl.Parent = row

                    local sw = Instance.new("TextButton")
                    sw.Size = UDim2.new(0, 44, 0, 22)
                    sw.Position = UDim2.new(1, -56, 0.5, -11)
                    sw.BackgroundColor3 = currentVal and MenuConfig.AccentColor or Theme.SwitchOff
                    registerAccent(sw, "BackgroundColor3")
                    sw.BorderSizePixel = 0
                    sw.AutoButtonColor = false
                    sw.Text = ""
                    sw.ZIndex = 5
                    sw.Parent = row
                    Instance.new("UICorner", sw).CornerRadius = UDim.new(1, 0)

                    local th = Instance.new("Frame")
                    th.Size = UDim2.new(0, 16, 0, 16)
                    th.Position = currentVal and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
                    th.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    th.BorderSizePixel = 0
                    th.ZIndex = 6
                    th.Parent = sw
                    Instance.new("UICorner", th).CornerRadius = UDim.new(1, 0)

                    sw.MouseButton1Click:Connect(function()
                        currentVal = not currentVal
                        if not mod.__settings__ then mod.__settings__ = {} end
                        mod.__settings__[sKey] = currentVal
                        playSound(currentVal and Sounds.ToggleOn or Sounds.ToggleOff, 0.45, currentVal and 1.1 or 0.95)
                        tween(sw, { BackgroundColor3 = currentVal and MenuConfig.AccentColor or Theme.SwitchOff }, 0.18, Enum.EasingStyle.Cubic)
                        tween(th, { Position = currentVal and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8) }, 0.18, Enum.EasingStyle.Cubic)
                    end)

                elseif sType == "Dropdown" then
                    local sOptions = def.Options or {}
                    local currentVal = sDefault or sOptions[1] or ""
                    if mod.__settings__ and mod.__settings__[sKey] ~= nil then
                        currentVal = mod.__settings__[sKey]
                    end

                    local row = Instance.new("Frame")
                    row.Size = UDim2.new(1, 0, 0, 42)
                    row.BackgroundColor3 = Theme.CardBg
                    row.BorderSizePixel = 0
                    row.LayoutOrder = orderCounter
                    row.ZIndex = 4
                    row.Parent = inspectorScroll
                    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

                    local dStroke = Instance.new("UIStroke", row)
                    dStroke.Color = Theme.StrokeDim
                    dStroke.Thickness = 1

                    local lbl = Instance.new("TextLabel")
                    lbl.Size = UDim2.new(0.5, 0, 1, 0)
                    lbl.Position = UDim2.new(0, 14, 0, 0)
                    lbl.BackgroundTransparency = 1
                    lbl.Font = MainFont
                    lbl.Text = sName
                    lbl.TextColor3 = Theme.TextSecondary
                    lbl.TextSize = 13
                    lbl.TextXAlignment = Enum.TextXAlignment.Left
                    lbl.ZIndex = 5
                    lbl.Parent = row

                    local dropBtn = Instance.new("TextButton")
                    dropBtn.Size = UDim2.new(0.44, 0, 0, 26)
                    dropBtn.Position = UDim2.new(0.54, 0, 0.5, -13)
                    dropBtn.BackgroundColor3 = Theme.PanelHeader
                    dropBtn.BorderSizePixel = 0
                    dropBtn.AutoButtonColor = false
                    dropBtn.Font = MainFont
                    dropBtn.Text = tostring(currentVal) .. "  "
                    dropBtn.TextColor3 = Theme.TextPrimary
                    dropBtn.TextSize = 12
                    dropBtn.ZIndex = 5
                    dropBtn.Parent = row
                    Instance.new("UICorner", dropBtn).CornerRadius = UDim.new(0, 6)

                    local arrowImg = Instance.new("ImageLabel")
                    arrowImg.Size = UDim2.new(0, 14, 0, 14)
                    arrowImg.Position = UDim2.new(1, -20, 0.5, -7)
                    arrowImg.BackgroundTransparency = 1
                    arrowImg.Image = Icons.ChevronDown
                    arrowImg.ImageColor3 = Theme.TextMuted
                    arrowImg.ScaleType = Enum.ScaleType.Fit
                    arrowImg.ZIndex = 6
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
                        playSound(Sounds.ButtonClick, 0.45, 1.05)
                        if not mod.__settings__ then mod.__settings__ = {} end
                        mod.__settings__[sKey] = currentVal
                    end)
                end
            end
        else
            local emptyRow = Instance.new("Frame")
            emptyRow.Size = UDim2.new(1, 0, 0, 60)
            emptyRow.BackgroundColor3 = Theme.CardBg
            emptyRow.BorderSizePixel = 0
            emptyRow.LayoutOrder = 3
            emptyRow.ZIndex = 4
            emptyRow.Parent = inspectorScroll
            Instance.new("UICorner", emptyRow).CornerRadius = UDim.new(0, 8)

            local noSettingsLbl = Instance.new("TextLabel")
            noSettingsLbl.Size = UDim2.new(1, 0, 1, 0)
            noSettingsLbl.BackgroundTransparency = 1
            noSettingsLbl.Font = MainFont
            noSettingsLbl.Text = "У данной функции нет дополнительных параметров"
            noSettingsLbl.TextColor3 = Theme.TextMuted
            noSettingsLbl.TextSize = 12
            noSettingsLbl.ZIndex = 5
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
            inspectorFrame.Position = UDim2.new(0, 8, 0, 8)
            inspectorFrame.Size = UDim2.new(1, -16, 1, -16)
            renderMenuSettingsPanel()
            return
        else
            moduleListFrame.Visible = true
            divider.Visible = true
            inspectorFrame.Position = UDim2.new(0, MODULE_LIST_WIDTH + 24, 0, 8)
            inspectorFrame.Size = UDim2.new(1, -MODULE_LIST_WIDTH - 32, 1, -16)
        end

        local listToDisplay = {}
        local seenNames = {}
        local q = searchQuery:lower()

        for _, mod in ipairs(ModuleManager.Modules) do
            if not seenNames[mod.Name] then
                seenNames[mod.Name] = true
                local matchesCat = (selectedCategory == "ALL") or (mod.Category == selectedCategory)
                local matchesSearch = (q == "") or (string.find((mod.Name or ""):lower(), q, 1, true) ~= nil)
                if matchesCat and matchesSearch then
                    table.insert(listToDisplay, mod)
                end
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
            emptyLbl.Font = MainFont
            emptyLbl.Text = "Ничего не найдено"
            emptyLbl.TextColor3 = Theme.TextMuted
            emptyLbl.TextSize = 13
            emptyLbl.ZIndex = 4
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
            card.Size = UDim2.new(1, 0, 0, 44)
            card.BackgroundColor3 = (selectedModule == mod) and Theme.CardSelected or Theme.CardBg
            card.BorderSizePixel = 0
            card.ZIndex = 4
            card.Parent = moduleListFrame
            Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

            local cardStroke = Instance.new("UIStroke", card)
            cardStroke.Color = (selectedModule == mod) and MenuConfig.AccentColor or Theme.StrokeDim
            cardStroke.Thickness = 1.2

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size = UDim2.new(1, -95, 1, 0)
            nameLbl.Position = UDim2.new(0, 12, 0, 0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Font = MainFont
            nameLbl.Text = mod.Name or ""
            nameLbl.TextColor3 = mod.Enabled and Theme.TextPrimary or Theme.TextSecondary
            nameLbl.TextSize = 14
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
            nameLbl.ZIndex = 5
            nameLbl.Parent = card

            local kbTag = Instance.new("TextLabel")
            kbTag.Size = UDim2.new(0, 32, 0, 16)
            kbTag.Position = UDim2.new(1, -88, 0.5, -8)
            kbTag.BackgroundTransparency = 1
            kbTag.Font = MainFont
            kbTag.Text = ModuleManager.Keybinds[mod.Name] and ("[" .. ModuleManager.Keybinds[mod.Name]:sub(1, 4) .. "]") or ""
            kbTag.TextColor3 = Theme.TextMuted
            kbTag.TextSize = 10
            kbTag.TextXAlignment = Enum.TextXAlignment.Right
            kbTag.ZIndex = 5
            kbTag.Parent = card

            local sw = Instance.new("TextButton")
            sw.Size = UDim2.new(0, 40, 0, 20)
            sw.Position = UDim2.new(1, -50, 0.5, -10)
            sw.BackgroundColor3 = mod.Enabled and MenuConfig.AccentColor or Theme.SwitchOff
            sw.BorderSizePixel = 0
            sw.AutoButtonColor = false
            sw.Text = ""
            sw.ZIndex = 5
            sw.Parent = card
            Instance.new("UICorner", sw).CornerRadius = UDim.new(1, 0)

            local th = Instance.new("Frame")
            th.Size = UDim2.new(0, 14, 0, 14)
            th.Position = mod.Enabled and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
            th.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            th.BorderSizePixel = 0
            th.ZIndex = 6
            th.Parent = sw
            Instance.new("UICorner", th).CornerRadius = UDim.new(1, 0)

            local selectBtn = Instance.new("TextButton")
            selectBtn.Size = UDim2.new(1, -54, 1, 0)
            selectBtn.Position = UDim2.new(0, 0, 0, 0)
            selectBtn.BackgroundTransparency = 1
            selectBtn.Text = ""
            selectBtn.ZIndex = 5
            selectBtn.Parent = card

            local function updateCardVisuals()
                local isSel = (selectedModule == mod)
                card.BackgroundColor3 = isSel and Theme.CardSelected or Theme.CardBg
                cardStroke.Color = isSel and MenuConfig.AccentColor or Theme.StrokeDim
                nameLbl.TextColor3 = mod.Enabled and Theme.TextPrimary or (isSel and Theme.TextPrimary or Theme.TextSecondary)
                tween(sw, { BackgroundColor3 = mod.Enabled and MenuConfig.AccentColor or Theme.SwitchOff }, 0.18, Enum.EasingStyle.Cubic)
                tween(th, { Position = mod.Enabled and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7) }, 0.18, Enum.EasingStyle.Cubic)
            end

            -- ПЛАВНЫЕ АНИМАЦИИ НАВЕДЕНИЯ НА КАРТОЧКУ
            selectBtn.MouseEnter:Connect(function()
                if selectedModule ~= mod then
                    tween(card, { BackgroundColor3 = Theme.CardHover }, 0.12)
                end
            end)
            selectBtn.MouseLeave:Connect(function()
                if selectedModule ~= mod then
                    tween(card, { BackgroundColor3 = Theme.CardBg }, 0.12)
                end
            end)

            sw.MouseButton1Click:Connect(function()
                ModuleManager:SetEnabled(mod, not mod.Enabled)
                playSound(mod.Enabled and Sounds.ToggleOn or Sounds.ToggleOff, 0.45, mod.Enabled and 1.1 or 0.95)
                updateCardVisuals()
                if selectedModule == mod then
                    renderInspector(mod)
                end
            end)

            selectBtn.MouseButton1Click:Connect(function()
                if selectedModule ~= mod then
                    selectedModule = mod
                    playSound(Sounds.TabClick, 0.35, 1.1)
                    for _, item in ipairs(moduleCardItems) do
                        if item.updateState then item.updateState() end
                    end
                    renderInspector(mod)
                end
            end)

            table.insert(moduleCardItems, {
                mod = mod,
                card = card,
                updateState = updateCardVisuals,
                kbTag = kbTag,
            })
        end
    end

    -- ========== SIDEBAR CATEGORY BUTTONS ==========
    for idx, cat in ipairs(Categories) do
        local btn = Instance.new("TextButton")
        btn.Name = cat.Id
        btn.Size = UDim2.new(1, 0, 0, 36)
        btn.LayoutOrder = idx
        btn.BackgroundColor3 = (selectedCategory == cat.Id) and Theme.CardSelected or Color3.fromRGB(0, 0, 0)
        btn.BackgroundTransparency = (selectedCategory == cat.Id) and 0 or 1
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Text = ""
        btn.ZIndex = 4
        btn.Parent = catContainer
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

        local btnStroke = Instance.new("UIStroke", btn)
        btnStroke.Color = (selectedCategory == cat.Id) and MenuConfig.AccentColor or Color3.fromRGB(0, 0, 0)
        btnStroke.Transparency = (selectedCategory == cat.Id) and 0 or 1
        btnStroke.Thickness = 1

        local iconImg = Instance.new("ImageLabel")
        iconImg.Size = UDim2.new(0, 20, 0, 20)
        iconImg.Position = UDim2.new(0, 10, 0.5, -10)
        iconImg.BackgroundTransparency = 1
        iconImg.Image = cat.Icon
        iconImg.ScaleType = Enum.ScaleType.Fit
        iconImg.ImageColor3 = (selectedCategory == cat.Id) and MenuConfig.AccentColor or Theme.TextSecondary
        iconImg.ZIndex = 5
        iconImg.Parent = btn

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -38, 1, 0)
        label.Position = UDim2.new(0, 36, 0, 0)
        label.BackgroundTransparency = 1
        label.Font = MainFont
        label.Text = cat.Name
        label.TextColor3 = (selectedCategory == cat.Id) and Theme.TextPrimary or Theme.TextSecondary
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 5
        label.Parent = btn

        local function updateBtnVisuals(isSelected)
            tween(btn, {
                BackgroundTransparency = isSelected and 0 or 1,
                BackgroundColor3 = isSelected and Theme.CardSelected or Color3.fromRGB(0, 0, 0),
            }, 0.14)
            btnStroke.Transparency = isSelected and 0 or 1
            btnStroke.Color = isSelected and MenuConfig.AccentColor or Color3.fromRGB(0, 0, 0)
            iconImg.ImageColor3 = isSelected and MenuConfig.AccentColor or Theme.TextSecondary
            label.TextColor3 = isSelected and Theme.TextPrimary or Theme.TextSecondary
        end

        btn.MouseEnter:Connect(function()
            if selectedCategory ~= cat.Id then
                tween(btn, { BackgroundTransparency = 0.5, BackgroundColor3 = Theme.CardHover }, 0.12)
                iconImg.ImageColor3 = Color3.fromRGB(230, 235, 255)
                label.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
        end)

        btn.MouseLeave:Connect(function()
            if selectedCategory ~= cat.Id then
                tween(btn, { BackgroundTransparency = 1 }, 0.12)
                iconImg.ImageColor3 = Theme.TextSecondary
                label.TextColor3 = Theme.TextSecondary
            end
        end)

        btn.MouseButton1Click:Connect(function()
            if selectedCategory ~= cat.Id then
                selectedCategory = cat.Id
                playSound(Sounds.TabClick, 0.45, 1.0)
                categoryHeaderTitle.Text = cat.Name
                for cId, bData in pairs(categoryButtons) do
                    bData.update(cId == selectedCategory)
                end
                renderModuleList()
            end
        end)

        categoryButtons[cat.Id] = {
            btn = btn,
            update = updateBtnVisuals,
        }
    end

    -- ========== SEARCH FILTER ==========
    searchInput:GetPropertyChangedSignal("Text"):Connect(function()
        searchQuery = searchInput.Text
        renderModuleList()
    end)

    -- ========== RELOAD BUTTON EVENT ==========
    reloadBtn.MouseEnter:Connect(function()
        tween(reloadBtn, { BackgroundColor3 = Theme.CardHover, ImageColor3 = Color3.fromRGB(255, 255, 255) }, 0.12)
    end)
    reloadBtn.MouseLeave:Connect(function()
        tween(reloadBtn, { BackgroundColor3 = Color3.fromRGB(26, 30, 46), ImageColor3 = Theme.TextSecondary }, 0.12)
    end)

    reloadBtn.MouseButton1Click:Connect(function()
        playSound(Sounds.ButtonClick, 0.5, 1.0)
        notify("Перезагрузка манифеста...", 1.5, Color3.fromRGB(56, 189, 248))
        if ModuleManager.ReloadManifest then
            pcall(function() ModuleManager:ReloadManifest() end)
        end
        renderModuleList()
        notify("Манифест успешно обновлен", 2, Theme.Success)
    end)

    -- ========== CLOSE BUTTON EVENT ==========
    closeBtn.MouseEnter:Connect(function()
        tween(closeBtn, { BackgroundColor3 = Theme.Danger, ImageColor3 = Color3.fromRGB(255, 255, 255) }, 0.12)
    end)
    closeBtn.MouseLeave:Connect(function()
        tween(closeBtn, { BackgroundColor3 = Color3.fromRGB(26, 30, 46), ImageColor3 = Theme.TextSecondary }, 0.12)
    end)

    closeBtn.MouseButton1Click:Connect(function()
        playSound(Sounds.MenuClose, 0.4, 0.95)
        setMenuOpen(false)
    end)

    -- ========== DRAGGING & LIVE RESIZING LOGIC ==========
    local draggingWindow = false
    local dragStartMouse = nil
    local frameStartPos  = nil

    local function setupDragOn(inst)
        inst.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                draggingWindow = true
                dragStartMouse = input.Position
                frameStartPos  = mainWindow.Position
            end
        end)
    end

    setupDragOn(headerCard)
    setupDragOn(brandCard)

    UserInputService.InputChanged:Connect(function(input)
        -- 1. Перемещение окна
        if draggingWindow and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStartMouse
            local newPos = UDim2.new(
                frameStartPos.X.Scale, frameStartPos.X.Offset + delta.X,
                frameStartPos.Y.Scale, frameStartPos.Y.Offset + delta.Y
            )
            mainWindow.Position = newPos
            glowShadow.Position = newPos
        end

        -- 2. Динамическое масштабирование через 3 точки (UIScale)
        if resizingWindow and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - resizeStartMouse
            local scaleDelta = (delta.X / BASE_WIDTH + delta.Y / BASE_HEIGHT) / 2
            local newScale = math.clamp(resizeStartScale + scaleDelta, 0.70, 1.45)
            setGuiScale(newScale)
        end

        -- 3. Плавное перетаскивание ползунков (Никогда не срывается!)
        if currentDraggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            currentDraggingSlider.update(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingWindow = false

            if resizingWindow then
                resizingWindow = false
                dot1.BackgroundColor3 = Theme.TextMuted
                dot2.BackgroundColor3 = Theme.TextMuted
                dot3.BackgroundColor3 = Theme.TextMuted
            end

            if currentDraggingSlider then
                if currentDraggingSlider.finish then currentDraggingSlider.finish() end
                currentDraggingSlider = nil
            end
        end
    end)

    -- ========== OPEN / CLOSE ANIMATIONS (SMOOTH POP-IN SCALE) ==========
    local function playOpenAnim()
        screenGui.Enabled = true
        playSound(Sounds.MenuOpen, 0.45, 1.0)
        local targetScale = MenuConfig.MenuScale

        menuScale.Scale = targetScale * 0.88
        glowScale.Scale = targetScale * 0.88
        mainWindow.BackgroundTransparency = 1
        glowShadow.ImageTransparency = 1

        TweenService:Create(
            menuScale,
            TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            { Scale = targetScale }
        ):Play()

        TweenService:Create(
            glowScale,
            TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            { Scale = targetScale }
        ):Play()

        TweenService:Create(
            mainWindow,
            TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { BackgroundTransparency = 1 - MenuConfig.WindowOpacity }
        ):Play()

        if MenuConfig.MenuGlow then
            TweenService:Create(
                glowShadow,
                TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { ImageTransparency = 0.55 }
            ):Play()
        end
    end

    local function playCloseAnim()
        local targetScale = MenuConfig.MenuScale
        playSound(Sounds.MenuClose, 0.4, 0.95)

        local t = TweenService:Create(
            menuScale,
            TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
            { Scale = targetScale * 0.90 }
        )
        t:Play()

        TweenService:Create(
            glowScale,
            TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
            { Scale = targetScale * 0.90 }
        ):Play()

        TweenService:Create(
            mainWindow,
            TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { BackgroundTransparency = 1 }
        ):Play()

        TweenService:Create(
            glowShadow,
            TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { ImageTransparency = 1 }
        ):Play()

        t.Completed:Connect(function()
            if not menuOpen then
                screenGui.Enabled = false
                menuScale.Scale = targetScale
                glowScale.Scale = targetScale
            end
        end)
    end

    function setMenuOpen(state)
        menuOpen = state
        if state then playOpenAnim() else playCloseAnim() end
    end

    -- ========== GLOBAL KEYBIND HANDLER ==========
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        -- 1. Режим назначения бинда перехватывает клавишу в первую очередь!
        if keybindListening and keybindCallback then
            keybindCallback(input)
            return
        end

        -- 2. Если игрок печатает в чате или поиске, не триггерим читы
        if UserInputService:GetFocusedTextBox() ~= nil then
            return
        end

        -- 3. Открытие/закрытие меню (RightShift или Insert)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == Enum.KeyCode.Insert then
                setMenuOpen(not menuOpen)
                return
            end

            -- 4. Срабатывание биндов модулей в игре
            if not menuOpen then
                local keyName = input.KeyCode.Name
                for modName, boundKey in pairs(ModuleManager.Keybinds) do
                    if boundKey == keyName then
                        local mod = ModuleManager:GetModuleByName(modName)
                        if mod then
                            ModuleManager:SetEnabled(mod, not mod.Enabled)
                            playSound(mod.Enabled and Sounds.ToggleOn or Sounds.ToggleOff, 0.45, mod.Enabled and 1.1 or 0.95)
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

        -- 5. Бинды на кнопки мыши (Mouse1, Mouse2)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
            if not menuOpen and not keybindListening then
                local keyName = input.UserInputType == Enum.UserInputType.MouseButton1 and "Mouse1" or "Mouse2"
                for modName, boundKey in pairs(ModuleManager.Keybinds) do
                    if boundKey == keyName then
                        local mod = ModuleManager:GetModuleByName(modName)
                        if mod then
                            ModuleManager:SetEnabled(mod, not mod.Enabled)
                            playSound(mod.Enabled and Sounds.ToggleOn or Sounds.ToggleOff, 0.45, mod.Enabled and 1.1 or 0.95)
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

    renderModuleList()
    return screenGui
end

return Gui
