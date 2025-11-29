
local Gui = {}

function Gui.Init(ModuleManager)
    local UserInputService = game:GetService("UserInputService")
    local CoreGui          = game:GetService("CoreGui")
    local TweenService     = game:GetService("TweenService")

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "XclientMenu"
    screenGui.ResetOnSpawn = false
    screenGui.Enabled = false

    local parent = CoreGui
    pcall(function()
        if gethui then parent = gethui() end
    end)
    screenGui.Parent = parent


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

    local allButtons = {}
    local preferredOrder = {"Combat", "Movement", "Visuals", "Player", "Misc"}


    local function tweenColor(inst, targetColor)
        TweenService:Create(
            inst,
            TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { BackgroundColor3 = targetColor }
        ):Play()
    end


    local function createCategoryColumn(categoryName, modules)
        table.sort(modules, function(a, b)
            return (a.Name or "") < (b.Name or "")
        end)

        local colFrame = Instance.new("Frame")
        colFrame.Name = categoryName
        colFrame.Size = UDim2.new(0, 215, 1, 0)
        colFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 22)
        colFrame.BackgroundTransparency = 0.12
        colFrame.BorderSizePixel = 0
        colFrame.Parent = mainFrame

        Instance.new("UICorner", colFrame).CornerRadius = UDim.new(0, 14)

        local colStroke = Instance.new("UIStroke", colFrame)
        colStroke.Color = Color3.fromRGB(90, 90, 135)
        colStroke.Thickness = 1

        local titleBar = Instance.new("Frame")
        titleBar.Size = UDim2.new(1, 0, 0, 34)
        titleBar.BackgroundColor3 = Color3.fromRGB(28, 28, 48)
        titleBar.BackgroundTransparency = 0.05
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
        title.TextXAlignment = Enum.TextXAlignment.Center
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
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 56)
            btn.BackgroundTransparency = 0.08
            btn.BorderSizePixel = 0
            btn.AutoButtonColor = false
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 14
            btn.TextColor3 = Color3.fromRGB(225, 225, 238)
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Text = "      " .. mod.Name
            btn.Parent = holder

            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

            local stateDot = Instance.new("Frame")
            stateDot.Size = UDim2.new(0, 8, 0, 8)
            stateDot.Position = UDim2.new(0, 8, 0.5, -4)
            stateDot.BackgroundColor3 = Color3.fromRGB(110, 110, 155)
            stateDot.BorderSizePixel = 0
            stateDot.Parent = btn
            Instance.new("UICorner", stateDot).CornerRadius = UDim.new(1, 0)

            local info = {
                button = btn,
                mod    = mod,
                dot    = stateDot,
            }

            local function updateColors()
                if mod.Enabled then
                    tweenColor(btn, Color3.fromRGB(95, 155, 245))
                    btn.TextColor3            = Color3.fromRGB(255, 255, 255)
                    stateDot.BackgroundColor3 = Color3.fromRGB(170, 215, 255)
                else
                    tweenColor(btn, Color3.fromRGB(30, 30, 56))
                    btn.TextColor3            = Color3.fromRGB(215, 215, 232)
                    stateDot.BackgroundColor3 = Color3.fromRGB(110, 110, 155)
                end
            end
            info.updateColors = updateColors
            updateColors()

            btn.MouseEnter:Connect(function()
                if not mod.Enabled then
                    tweenColor(btn, Color3.fromRGB(42, 42, 74))
                end
            end)

            btn.MouseLeave:Connect(function()
                updateColors()
            end)

            btn.MouseButton1Click:Connect(function()
                ModuleManager:SetEnabled(mod, not mod.Enabled)
                updateColors()
            end)

            table.insert(allButtons, info)
        end
    end


    local function rebuildColumns()
        allButtons = {}

        for _, child in ipairs(mainFrame:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end

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
    end

    rebuildColumns() 


    local searchFrame = Instance.new("Frame")
    searchFrame.Size = UDim2.new(0, 320, 0, 32)
    searchFrame.Position = UDim2.new(0.5, -160, 0.5, 240)
    searchFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 24)
    searchFrame.BackgroundTransparency = 0.18
    searchFrame.BorderSizePixel = 0
    searchFrame.Parent = screenGui

    Instance.new("UICorner", searchFrame).CornerRadius = UDim.new(0, 8)

    local searchStroke = Instance.new("UIStroke", searchFrame)
    searchStroke.Color = Color3.fromRGB(80, 80, 130)
    searchStroke.Thickness = 1

    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, -16, 1, 0)
    searchBox.Position = UDim2.new(0, 8, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.Font = Enum.Font.Gotham
    searchBox.PlaceholderText = "Поиск"
    searchBox.PlaceholderColor3 = Color3.fromRGB(135, 135, 170)
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


    local refreshButton = Instance.new("TextButton")
    refreshButton.Name = "RefreshButton"
    refreshButton.Size = UDim2.new(0, 110, 0, 30)
    refreshButton.Position = UDim2.new(0, 20, 0, 20) 
    refreshButton.BackgroundColor3 = Color3.fromRGB(20, 20, 32)
    refreshButton.BackgroundTransparency = 0.12
    refreshButton.BorderSizePixel = 0
    refreshButton.AutoButtonColor = false
    refreshButton.Font = Enum.Font.Gotham
    refreshButton.TextSize = 14
    refreshButton.TextColor3 = Color3.fromRGB(230, 230, 245)
    refreshButton.Text = "Обновить"
    refreshButton.Parent = screenGui

    Instance.new("UICorner", refreshButton).CornerRadius = UDim.new(0, 8)

    local refreshStroke = Instance.new("UIStroke", refreshButton)
    refreshStroke.Color = Color3.fromRGB(80, 80, 130)
    refreshStroke.Thickness = 1

    refreshButton.MouseEnter:Connect(function()
        tweenColor(refreshButton, Color3.fromRGB(30, 30, 52))
    end)

    refreshButton.MouseLeave:Connect(function()
        tweenColor(refreshButton, Color3.fromRGB(20, 20, 32))
    end)

    refreshButton.MouseButton1Click:Connect(function()
        if ModuleManager.ReloadFromManifest then
            local ok, err = pcall(function()
                ModuleManager:ReloadFromManifest()
            end)
            if ok then
                rebuildColumns()
                applySearch()
            else
                warn("[Xclient] ReloadFromManifest error:", err)
            end
        else
            warn("[Xclient] ReloadFromManifest не реализован в main.lua")
        end
    end)


    local menuOpen = false

    local function playOpenAnim()
        screenGui.Enabled     = true
        searchFrame.Visible   = true
        refreshButton.Visible = true

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
                screenGui.Enabled     = false
                searchFrame.Visible   = false
                refreshButton.Visible = false
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


    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end

        local focused = UserInputService:GetFocusedTextBox()
        if focused and focused == searchBox then
            return
        end

        if input.UserInputType == Enum.UserInputType.Keyboard
           and input.KeyCode == Enum.KeyCode.RightShift then
            setMenuOpen(not menuOpen)
            return
        end
    end)

end

return Gui
