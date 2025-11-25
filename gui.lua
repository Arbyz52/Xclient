-- ===================== gui.lua ======================

local Gui = {}

function Gui.Init(ModuleManager)
    local UserInputService = game:GetService("UserInputService")
    local CoreGui          = game:GetService("CoreGui")

    ---------------------------------------------------
    -- ScreenGui и затемнение фона
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

    local overlay = Instance.new("Frame")
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.35
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BorderSizePixel = 0
    overlay.Parent = screenGui

    ---------------------------------------------------
    -- Главный контейнер
    ---------------------------------------------------
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 900, 0, 450)
    mainFrame.Position = UDim2.new(0.5, -450, 0.5, -225)
    mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = overlay

    local uiCorner = Instance.new("UICorner", mainFrame)
    uiCorner.CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", mainFrame)
    stroke.Color = Color3.fromRGB(60, 60, 80)
    stroke.Thickness = 1

    local layout = Instance.new("UIListLayout", mainFrame)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 12)

    ---------------------------------------------------
    -- Списки модулей + поиск
    ---------------------------------------------------
    local allButtons = {}  -- {button=..., mod=...}

    local function createCategoryColumn(categoryName, modules)
        table.sort(modules, function(a, b)
            return (a.Name or "") < (b.Name or "")
        end)

        local colFrame = Instance.new("Frame")
        colFrame.Name = categoryName
        colFrame.Size = UDim2.new(0, 170, 1, -50)  -- место снизу под поиск
        colFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
        colFrame.BorderSizePixel = 0
        colFrame.Parent = mainFrame

        local colCorner = Instance.new("UICorner", colFrame)
        colCorner.CornerRadius = UDim.new(0, 8)

        local colStroke = Instance.new("UIStroke", colFrame)
        colStroke.Color = Color3.fromRGB(50, 50, 70)
        colStroke.Thickness = 1

        local titleBar = Instance.new("Frame", colFrame)
        titleBar.Size = UDim2.new(1, 0, 0, 28)
        titleBar.BackgroundColor3 = Color3.fromRGB(24, 24, 36)
        titleBar.BorderSizePixel = 0

        Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)

        local title = Instance.new("TextLabel", titleBar)
        title.Name = "Title"
        title.Size = UDim2.new(1, -16, 1, 0)
        title.Position = UDim2.new(0, 8, 0, 0)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.Text = categoryName
        title.TextColor3 = Color3.fromRGB(230, 230, 240)
        title.TextSize = 18
        title.TextXAlignment = Enum.TextXAlignment.Left

        local holder = Instance.new("Frame", colFrame)
        holder.Name = "ButtonsHolder"
        holder.Size = UDim2.new(1, -8, 1, -36)
        holder.Position = UDim2.new(0, 4, 0, 32)
        holder.BackgroundTransparency = 1

        local list = Instance.new("UIListLayout", holder)
        list.FillDirection = Enum.FillDirection.Vertical
        list.Padding = UDim.new(0, 4)

        for _, mod in ipairs(modules) do
            local btn = Instance.new("TextButton")
            btn.Name = mod.Name
            btn.Size = UDim2.new(1, 0, 0, 24)
            btn.BackgroundColor3 = Color3.fromRGB(32, 32, 46)
            btn.BorderSizePixel = 0
            btn.AutoButtonColor = false
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 14
            btn.TextColor3 = Color3.fromRGB(210, 210, 220)
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Text = "  " .. mod.Name
            btn.Parent = holder

            local btnCorner = Instance.new("UICorner", btn)
            btnCorner.CornerRadius = UDim.new(0, 6)

            local rightDots = Instance.new("TextLabel", btn)
            rightDots.Size = UDim2.new(0, 20, 1, 0)
            rightDots.Position = UDim2.new(1, -22, 0, 0)
            rightDots.BackgroundTransparency = 1
            rightDots.Font = Enum.Font.GothamBold
            rightDots.Text = "···"
            rightDots.TextColor3 = Color3.fromRGB(120, 120, 140)
            rightDots.TextSize = 14

            local function updateColor()
                if mod.Enabled then
                    btn.BackgroundColor3 = Color3.fromRGB(70, 130, 200)
                    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                else
                    btn.BackgroundColor3 = Color3.fromRGB(32, 32, 46)
                    btn.TextColor3 = Color3.fromRGB(210, 210, 220)
                end
            end
            updateColor()

            btn.MouseEnter:Connect(function()
                if not mod.Enabled then
                    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
                end
            end)

            btn.MouseLeave:Connect(function()
                updateColor()
            end)

            btn.MouseButton1Click:Connect(function()
                ModuleManager:SetEnabled(mod, not mod.Enabled)
                updateColor()
            end)

            table.insert(allButtons, {button = btn, mod = mod})
        end
    end

    ---------------------------------------------------
    -- Сортировка категорий (Combat, Movement, Visuals, Player, Misc, остальные)
    ---------------------------------------------------
    local order = {"Combat", "Movement", "Visuals", "Player", "Misc"}
    local categoryNames = {}

    for name, _ in pairs(ModuleManager.Categories) do
        table.insert(categoryNames, name)
    end

    table.sort(categoryNames, function(a, b)
        local ia, ib
        for i, v in ipairs(order) do
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
    -- Поиск (снизу, по всем модулям)
    ---------------------------------------------------
    local searchFrame = Instance.new("Frame", overlay)
    searchFrame.Size = UDim2.new(0, 300, 0, 32)
    searchFrame.Position = UDim2.new(0.5, -150, 0.5, 240)
    searchFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    searchFrame.BorderSizePixel = 0

    local searchCorner = Instance.new("UICorner", searchFrame)
    searchCorner.CornerRadius = UDim.new(0, 8)

    local searchStroke = Instance.new("UIStroke", searchFrame)
    searchStroke.Color = Color3.fromRGB(60, 60, 80)
    searchStroke.Thickness = 1

    local searchBox = Instance.new("TextBox", searchFrame)
    searchBox.Size = UDim2.new(1, -16, 1, 0)
    searchBox.Position = UDim2.new(0, 8, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.Font = Enum.Font.Gotham
    searchBox.PlaceholderText = "Поиск"
    searchBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
    searchBox.Text = ""
    searchBox.TextColor3 = Color3.fromRGB(220, 220, 230)
    searchBox.TextSize = 14
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.ClearTextOnFocus = false

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
    -- Тоггл RightShift
    ---------------------------------------------------
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            screenGui.Enabled = not screenGui.Enabled
        end
    end)

    print("[Xclient] GUI инициализирован, RightShift - открыть/закрыть")
end

return Gui
