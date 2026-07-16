
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

    -- ========== STATE ==========
    local allButtons       = {}
    local selectedModName  = nil
    local settingsOpen     = false
    local settingsModName  = nil
    local menuOpen         = false
    local keybindListening = false
    local keybindCallback  = nil
    local keybindBtnRef    = nil

    -- ========== SCREEN GUI ==========
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "XclientMenu"
    screenGui.ResetOnSpawn = false
    screenGui.Enabled = false
    screenGui.Parent = parent

    -- ========== MAIN FRAME (DRAGGABLE) ==========
    local dragFrame = Instance.new("Frame")
    dragFrame.Name = "DragFrame"
    dragFrame.Size = UDim2.new(0, 1100, 0, 480)
    dragFrame.Position = UDim2.new(0.5, -550, 0.5, -260)
    dragFrame.BackgroundTransparency = 1
    dragFrame.Parent = screenGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "ColumnsHolder"
    mainFrame.Size = UDim2.new(1, 0, 1, -50)
    mainFrame.Position = UDim2.new(0, 0, 0, 0)
    mainFrame.BackgroundTransparency = 1
    mainFrame.ClipsDescendants = false
    mainFrame.Parent = dragFrame

    local layout = Instance.new("UIListLayout", mainFrame)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 14)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    -- ========== SETTINGS PANEL ==========
    local settingsPanel = Instance.new("Frame")
    settingsPanel.Name = "SettingsPanel"
    settingsPanel.Size = UDim2.new(0, 260, 0, 380)
    settingsPanel.Position = UDim2.new(0, 1120, 0, 20)
    settingsPanel.BackgroundColor3 = Color3.fromRGB(14, 14, 24)
    settingsPanel.BackgroundTransparency = 0.05
    settingsPanel.BorderSizePixel = 0
    settingsPanel.Visible = false
    settingsPanel.Parent = dragFrame
    Instance.new("UICorner", settingsPanel).CornerRadius = UDim.new(0, 14)

    local settingsStroke = Instance.new("UIStroke", settingsPanel)
    settingsStroke.Color = Color3.fromRGB(70, 70, 115)
    settingsStroke.Thickness = 1

    local settingsTitle = Instance.new("TextLabel")
    settingsTitle.Size = UDim2.new(1, -16, 0, 32)
    settingsTitle.Position = UDim2.new(0, 8, 0, 6)
    settingsTitle.BackgroundTransparency = 1
    settingsTitle.Font = Enum.Font.GothamBold
    settingsTitle.Text = "Настройки"
    settingsTitle.TextColor3 = Color3.fromRGB(220, 220, 255)
    settingsTitle.TextSize = 15
    settingsTitle.TextXAlignment = Enum.TextXAlignment.Center
    settingsTitle.Parent = settingsPanel

    local settingsScroll = Instance.new("ScrollingFrame")
    settingsScroll.Name = "SettingsScroll"
    settingsScroll.Size = UDim2.new(1, -12, 1, -48)
    settingsScroll.Position = UDim2.new(0, 6, 0, 42)
    settingsScroll.BackgroundTransparency = 1
    settingsScroll.BorderSizePixel = 0
    settingsScroll.ScrollBarThickness = 4
    settingsScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 160)
    settingsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    settingsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    settingsScroll.Parent = settingsPanel

    local settingsLayout = Instance.new("UIListLayout", settingsScroll)
    settingsLayout.Padding = UDim.new(0, 6)
    settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- ========== HELPERS ==========
    local function tweenColor(inst, targetColor, dur)
        TweenService:Create(
            inst,
            TweenInfo.new(dur or 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { BackgroundColor3 = targetColor }
        ):Play()
    end

    local function tweenTransp(inst, prop, target, dur)
        local t = {}
        t[prop] = target
        TweenService:Create(
            inst,
            TweenInfo.new(dur or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            t
        ):Play()
    end

    local function notify(text, dur, color)
        if Notifications and Notifications.Show then
            Notifications:Show(text, dur, color)
        end
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
            return
        end

        settingsTitle.Text = mod.Name or "Настройки"
        settingsModName = mod.Name
        settingsOpen = true
        settingsPanel.Visible = true

        -- Toggle row
        local toggleFrame = Instance.new("Frame")
        toggleFrame.Size = UDim2.new(1, 0, 0, 30)
        toggleFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 58)
        toggleFrame.BackgroundTransparency = 0.1
        toggleFrame.BorderSizePixel = 0
        toggleFrame.LayoutOrder = 0
        toggleFrame.Parent = settingsScroll
        Instance.new("UICorner", toggleFrame).CornerRadius = UDim.new(0, 8)

        local toggleLabel = Instance.new("TextLabel")
        toggleLabel.Size = UDim2.new(1, -56, 1, 0)
        toggleLabel.Position = UDim2.new(0, 10, 0, 0)
        toggleLabel.BackgroundTransparency = 1
        toggleLabel.Font = Enum.Font.Gotham
        toggleLabel.Text = "Включить"
        toggleLabel.TextColor3 = Color3.fromRGB(200, 200, 225)
        toggleLabel.TextSize = 13
        toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
        toggleLabel.Parent = toggleFrame

        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(0, 36, 0, 20)
        toggleBtn.Position = UDim2.new(1, -46, 0.5, -10)
        toggleBtn.BorderSizePixel = 0
        toggleBtn.AutoButtonColor = false
        toggleBtn.Font = Enum.Font.GothamBold
        toggleBtn.Text = ""
        toggleBtn.Parent = toggleFrame
        Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)

        local function updateToggle()
            if mod.Enabled then
                tweenColor(toggleBtn, Color3.fromRGB(80, 160, 255))
                toggleBtn.Text = "✓"
                toggleBtn.TextColor3 = Color3.new(1,1,1)
            else
                tweenColor(toggleBtn, Color3.fromRGB(55, 55, 80))
                toggleBtn.Text = ""
            end
        end
        updateToggle()

        toggleBtn.MouseButton1Click:Connect(function()
            ModuleManager:SetEnabled(mod, not mod.Enabled)
            updateToggle()
            for _, info in ipairs(allButtons) do
                if info.mod == mod and info.updateColors then
                    info.updateColors()
                end
            end
            if mod.Enabled then
                notify(mod.Name .. " включён", 2, Color3.fromRGB(45, 100, 65))
            else
                notify(mod.Name .. " выключен", 2, Color3.fromRGB(120, 60, 40))
            end
        end)

        -- Keybind row
        local kbFrame = Instance.new("Frame")
        kbFrame.Size = UDim2.new(1, 0, 0, 30)
        kbFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 58)
        kbFrame.BackgroundTransparency = 0.1
        kbFrame.BorderSizePixel = 0
        kbFrame.LayoutOrder = 1
        kbFrame.Parent = settingsScroll
        Instance.new("UICorner", kbFrame).CornerRadius = UDim.new(0, 8)

        local kbLabel = Instance.new("TextLabel")
        kbLabel.Size = UDim2.new(1, -70, 1, 0)
        kbLabel.Position = UDim2.new(0, 10, 0, 0)
        kbLabel.BackgroundTransparency = 1
        kbLabel.Font = Enum.Font.Gotham
        kbLabel.Text = "Клавиша"
        kbLabel.TextColor3 = Color3.fromRGB(200, 200, 225)
        kbLabel.TextSize = 13
        kbLabel.TextXAlignment = Enum.TextXAlignment.Left
        kbLabel.Parent = kbFrame

        local kbBtn = Instance.new("TextButton")
        kbBtn.Size = UDim2.new(0, 56, 0, 22)
        kbBtn.Position = UDim2.new(1, -64, 0.5, -11)
        kbBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 72)
        kbBtn.BorderSizePixel = 0
        kbBtn.AutoButtonColor = false
        kbBtn.Font = Enum.Font.Gotham
        kbBtn.TextSize = 12
        kbBtn.TextColor3 = Color3.fromRGB(180, 180, 210)
        kbBtn.Parent = kbFrame
        Instance.new("UICorner", kbBtn).CornerRadius = UDim.new(0, 6)

        local currentBind = ModuleManager.Keybinds[mod.Name]
        kbBtn.Text = currentBind and currentBind:sub(1,8) or "None"

        kbBtn.MouseButton1Click:Connect(function()
            if keybindListening then
                if keybindBtnRef then
                    keybindBtnRef.Text = keybindBtnRef._prevText or "None"
                end
            end
            kbBtn._prevText = kbBtn.Text
            kbBtn.Text = "..."
            tweenColor(kbBtn, Color3.fromRGB(80, 100, 160))
            keybindListening = true
            keybindBtnRef = kbBtn

            keybindCallback = function(input)
                keybindListening = false
                keybindCallback = nil
                keybindBtnRef = nil

                local keyName = nil
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    keyName = input.KeyCode.Name
                elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                    keyName = "Mouse1"
                elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                    keyName = "Mouse2"
                end

                if keyName then
                    ModuleManager.Keybinds[mod.Name] = keyName
                    kbBtn.Text = keyName:sub(1,8)
                    tweenColor(kbBtn, Color3.fromRGB(45, 45, 72))
                    notify(mod.Name .. " → " .. keyName, 2, Color3.fromRGB(45, 70, 120))
                else
                    kbBtn.Text = kbBtn._prevText or "None"
                    tweenColor(kbBtn, Color3.fromRGB(45, 45, 72))
                end
            end
        end)

        -- Separator
        if mod.__settings__ and next(mod.__settings__) then
            local sep = Instance.new("Frame")
            sep.Size = UDim2.new(1, -10, 0, 1)
            sep.Position = UDim2.new(0, 5, 0, 0)
            sep.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
            sep.BackgroundTransparency = 0.5
            sep.BorderSizePixel = 0
            sep.LayoutOrder = 2
            sep.Parent = settingsScroll
        end

        -- Module-specific settings
        local orderCounter = 10
        if mod.SettingsDefinitions then
            for _, def in ipairs(mod.SettingsDefinitions) do
                orderCounter = orderCounter + 1
                local sType = def.Type or "Toggle"
                local sName = def.Name or "?"
                local sKey  = def.Key or sName
                local sDefault = def.Default

                if sType == "Toggle" then
                    local row = Instance.new("Frame")
                    row.Size = UDim2.new(1, 0, 0, 28)
                    row.BackgroundColor3 = Color3.fromRGB(32, 32, 54)
                    row.BackgroundTransparency = 0.15
                    row.BorderSizePixel = 0
                    row.LayoutOrder = orderCounter
                    row.Parent = settingsScroll
                    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

                    local lbl = Instance.new("TextLabel")
                    lbl.Size = UDim2.new(1, -50, 1, 0)
                    lbl.Position = UDim2.new(0, 10, 0, 0)
                    lbl.BackgroundTransparency = 1
                    lbl.Font = Enum.Font.Gotham
                    lbl.Text = sName
                    lbl.TextColor3 = Color3.fromRGB(190, 190, 215)
                    lbl.TextSize = 12
                    lbl.TextXAlignment = Enum.TextXAlignment.Left
                    lbl.Parent = row

                    local btn = Instance.new("TextButton")
                    btn.Size = UDim2.new(0, 30, 0, 18)
                    btn.Position = UDim2.new(1, -40, 0.5, -9)
                    btn.BorderSizePixel = 0
                    btn.AutoButtonColor = false
                    btn.Font = Enum.Font.GothamBold
                    btn.TextSize = 14
                    btn.Text = ""
                    btn.Parent = row
                    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

                    local currentVal = false
                    if mod.__settings__ and mod.__settings__[sKey] ~= nil then
                        currentVal = mod.__settings__[sKey]
                    elseif sDefault ~= nil then
                        currentVal = sDefault
                    end

                    local function updateBtn()
                        if currentVal then
                            tweenColor(btn, Color3.fromRGB(80, 160, 255))
                            btn.Text = "✓"
                            btn.TextColor3 = Color3.new(1,1,1)
                        else
                            tweenColor(btn, Color3.fromRGB(50, 50, 75))
                            btn.Text = ""
                        end
                    end
                    updateBtn()

                    btn.MouseButton1Click:Connect(function()
                        currentVal = not currentVal
                        if not mod.__settings__ then mod.__settings__ = {} end
                        mod.__settings__[sKey] = currentVal
                        updateBtn()
                    end)

                elseif sType == "Slider" then
                    local sMin = def.Min or 0
                    local sMax = def.Max or 100
                    local sStep = def.Step or 1
                    local sSuffix = def.Suffix or ""

                    local currentVal = sDefault or sMin
                    if mod.__settings__ and mod.__settings__[sKey] ~= nil then
                        currentVal = mod.__settings__[sKey]
                    end

                    local row = Instance.new("Frame")
                    row.Size = UDim2.new(1, 0, 0, 44)
                    row.BackgroundColor3 = Color3.fromRGB(32, 32, 54)
                    row.BackgroundTransparency = 0.15
                    row.BorderSizePixel = 0
                    row.LayoutOrder = orderCounter
                    row.Parent = settingsScroll
                    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

                    local lbl = Instance.new("TextLabel")
                    lbl.Size = UDim2.new(1, -10, 0, 16)
                    lbl.Position = UDim2.new(0, 10, 0, 3)
                    lbl.BackgroundTransparency = 1
                    lbl.Font = Enum.Font.Gotham
                    lbl.Text = sName
                    lbl.TextColor3 = Color3.fromRGB(190, 190, 215)
                    lbl.TextSize = 12
                    lbl.TextXAlignment = Enum.TextXAlignment.Left
                    lbl.Parent = row

                    local valLabel = Instance.new("TextLabel")
                    valLabel.Size = UDim2.new(0, 60, 0, 16)
                    valLabel.Position = UDim2.new(1, -70, 0, 3)
                    valLabel.BackgroundTransparency = 1
                    valLabel.Font = Enum.Font.Gotham
                    valLabel.Text = tostring(currentVal) .. sSuffix
                    valLabel.TextColor3 = Color3.fromRGB(160, 160, 200)
                    valLabel.TextSize = 11
                    valLabel.TextXAlignment = Enum.TextXAlignment.Right
                    valLabel.Parent = row

                    local barBg = Instance.new("TextButton")
                    barBg.Size = UDim2.new(1, -20, 0, 12)
                    barBg.Position = UDim2.new(0, 10, 0, 26)
                    barBg.BackgroundColor3 = Color3.fromRGB(25, 25, 42)
                    barBg.BorderSizePixel = 0
                    barBg.AutoButtonColor = false
                    barBg.Text = ""
                    barBg.Parent = row
                    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

                    local barFill = Instance.new("Frame")
                    barFill.BackgroundColor3 = Color3.fromRGB(75, 130, 230)
                    barFill.BorderSizePixel = 0
                    barFill.Parent = barBg
                    Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

                    local function updateBar()
                        local pct = (currentVal - sMin) / math.max(sMax - sMin, 1)
                        pct = math.clamp(pct, 0, 1)
                        barFill.Size = UDim2.new(pct, 0, 1, 0)
                        local displayVal = currentVal
                        if sStep >= 1 then
                            displayVal = math.floor(currentVal + 0.5)
                        else
                            local dec = 0
                            local s = tostring(sStep)
                            local dot = s:find("%.")
                            if dot then dec = #s - dot end
                            displayVal = math.floor(currentVal * 10^dec + 0.5) / 10^dec
                        end
                        valLabel.Text = tostring(displayVal) .. sSuffix
                    end
                    updateBar()

                    local dragging = false

                    barBg.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                            dragging = true
                            local absPos = barBg.AbsolutePosition.X
                            local absSize = barBg.AbsoluteSize.X
                            local mouseX = input.Position.X
                            local pct = math.clamp((mouseX - absPos) / absSize, 0, 1)
                            local raw = sMin + pct * (sMax - sMin)
                            currentVal = math.floor(raw / sStep + 0.5) * sStep
                            currentVal = math.clamp(currentVal, sMin, sMax)
                            if not mod.__settings__ then mod.__settings__ = {} end
                            mod.__settings__[sKey] = currentVal
                            updateBar()
                        end
                    end)

                    UserInputService.InputChanged:Connect(function(input)
                        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                        or input.UserInputType == Enum.UserInputType.Touch) then
                            local absPos = barBg.AbsolutePosition.X
                            local absSize = barBg.AbsoluteSize.X
                            local mouseX = input.Position.X
                            local pct = math.clamp((mouseX - absPos) / absSize, 0, 1)
                            local raw = sMin + pct * (sMax - sMin)
                            currentVal = math.floor(raw / sStep + 0.5) * sStep
                            currentVal = math.clamp(currentVal, sMin, sMax)
                            if not mod.__settings__ then mod.__settings__ = {} end
                            mod.__settings__[sKey] = currentVal
                            updateBar()
                        end
                    end)

                    UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                            dragging = false
                        end
                    end)

                elseif sType == "Dropdown" then
                    local sOptions = def.Options or {}
                    local currentVal = sDefault or sOptions[1] or ""
                    if mod.__settings__ and mod.__settings__[sKey] ~= nil then
                        currentVal = mod.__settings__[sKey]
                    end

                    local row = Instance.new("Frame")
                    row.Size = UDim2.new(1, 0, 0, 30)
                    row.BackgroundColor3 = Color3.fromRGB(32, 32, 54)
                    row.BackgroundTransparency = 0.15
                    row.BorderSizePixel = 0
                    row.LayoutOrder = orderCounter
                    row.ZIndex = 10
                    row.Parent = settingsScroll
                    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

                    local lbl = Instance.new("TextLabel")
                    lbl.Size = UDim2.new(0.45, 0, 1, 0)
                    lbl.Position = UDim2.new(0, 10, 0, 0)
                    lbl.BackgroundTransparency = 1
                    lbl.Font = Enum.Font.Gotham
                    lbl.Text = sName
                    lbl.TextColor3 = Color3.fromRGB(190, 190, 215)
                    lbl.TextSize = 12
                    lbl.TextXAlignment = Enum.TextXAlignment.Left
                    lbl.ZIndex = 10
                    lbl.Parent = row

                    local ddBtn = Instance.new("TextButton")
                    ddBtn.Size = UDim2.new(0.5, -16, 0, 20)
                    ddBtn.Position = UDim2.new(0.5, 2, 0.5, -10)
                    ddBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
                    ddBtn.BorderSizePixel = 0
                    ddBtn.AutoButtonColor = false
                    ddBtn.Font = Enum.Font.Gotham
                    ddBtn.TextSize = 11
                    ddBtn.TextColor3 = Color3.fromRGB(170, 170, 210)
                    ddBtn.Text = "  " .. tostring(currentVal) .. " ▾"
                    ddBtn.TextXAlignment = Enum.TextXAlignment.Left
                    ddBtn.ZIndex = 11
                    ddBtn.Parent = row
                    Instance.new("UICorner", ddBtn).CornerRadius = UDim.new(0, 6)

                    local ddOpen = false
                    local optionsFrame = Instance.new("Frame")
                    optionsFrame.Size = UDim2.new(1, 0, 0, #sOptions * 22)
                    optionsFrame.Position = UDim2.new(0, 0, 1, 2)
                    optionsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 52)
                    optionsFrame.BorderSizePixel = 0
                    optionsFrame.Visible = false
                    optionsFrame.ZIndex = 15
                    optionsFrame.Parent = row
                    Instance.new("UICorner", optionsFrame).CornerRadius = UDim.new(0, 6)

                    local optLayout = Instance.new("UIListLayout", optionsFrame)
                    optLayout.Padding = UDim.new(0, 0)
                    optLayout.SortOrder = Enum.SortOrder.LayoutOrder

                    for i, opt in ipairs(sOptions) do
                        local optBtn = Instance.new("TextButton")
                        optBtn.Size = UDim2.new(1, 0, 0, 22)
                        optBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 52)
                        optBtn.BackgroundTransparency = 0.3
                        optBtn.BorderSizePixel = 0
                        optBtn.AutoButtonColor = false
                        optBtn.Font = Enum.Font.Gotham
                        optBtn.TextSize = 11
                        optBtn.TextColor3 = Color3.fromRGB(170, 170, 210)
                        optBtn.Text = "  " .. tostring(opt)
                        optBtn.TextXAlignment = Enum.TextXAlignment.Left
                        optBtn.ZIndex = 16
                        optBtn.LayoutOrder = i
                        optBtn.Parent = optionsFrame
                        Instance.new("UICorner", optBtn).CornerRadius = UDim.new(0, 4)

                        optBtn.MouseEnter:Connect(function()
                            tweenColor(optBtn, Color3.fromRGB(60, 60, 100))
                        end)
                        optBtn.MouseLeave:Connect(function()
                            tweenColor(optBtn, Color3.fromRGB(30, 30, 52))
                        end)

                        optBtn.MouseButton1Click:Connect(function()
                            currentVal = opt
                            if not mod.__settings__ then mod.__settings__ = {} end
                            mod.__settings__[sKey] = currentVal
                            ddBtn.Text = "  " .. tostring(currentVal) .. " ▾"
                            optionsFrame.Visible = false
                            ddOpen = false
                        end)
                    end

                    ddBtn.MouseButton1Click:Connect(function()
                        ddOpen = not ddOpen
                        optionsFrame.Visible = ddOpen
                    end)
                end
            end
        end
    end

    -- ========== CREATE CATEGORY COLUMN ==========
    local preferredOrder = {"Combat", "Movement", "Visuals", "Player", "Misc"}

    local function createCategoryColumn(categoryName, modules, orderIndex)
        table.sort(modules, function(a, b) return (a.Name or "") < (b.Name or "") end)

        local colFrame = Instance.new("ScrollingFrame")
        colFrame.Name = categoryName
        colFrame.Size = UDim2.new(0, 205, 1, 0)
        colFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 22)
        colFrame.BackgroundTransparency = 0.12
        colFrame.BorderSizePixel = 0
        colFrame.ScrollBarThickness = 3
        colFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 130)
        colFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        colFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        colFrame.LayoutOrder = orderIndex
        colFrame.Parent = mainFrame

        Instance.new("UICorner", colFrame).CornerRadius = UDim.new(0, 14)
        local colStroke = Instance.new("UIStroke", colFrame)
        colStroke.Color = Color3.fromRGB(50, 50, 90)
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
        title.TextColor3 = Color3.fromRGB(210, 210, 240)
        title.TextSize = 16
        title.TextXAlignment = Enum.TextXAlignment.Center
        title.Parent = titleBar

        local holder = Instance.new("Frame")
        holder.Name = "ButtonsHolder"
        holder.Size = UDim2.new(1, -8, 0, 0)
        holder.Position = UDim2.new(0, 4, 0, 38)
        holder.AutomaticSize = Enum.AutomaticSize.Y
        holder.BackgroundTransparency = 1
        holder.Parent = colFrame

        local list = Instance.new("UIListLayout", holder)
        list.FillDirection = Enum.FillDirection.Vertical
        list.Padding = UDim.new(0, 4)
        list.SortOrder = Enum.SortOrder.LayoutOrder

        for _, mod in ipairs(modules) do
            local btn = Instance.new("TextButton")
            btn.Name = mod.Name
            btn.Size = UDim2.new(1, 0, 0, 30)
            btn.BackgroundColor3 = Color3.fromRGB(28, 28, 52)
            btn.BackgroundTransparency = 0.08
            btn.BorderSizePixel = 0
            btn.AutoButtonColor = false
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 12
            btn.TextColor3 = Color3.fromRGB(200, 200, 225)
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Text = "    " .. (mod.Name or "")
            btn.Parent = holder

            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

            -- state indicator dot
            local stateDot = Instance.new("Frame")
            stateDot.Size = UDim2.new(0, 8, 0, 8)
            stateDot.Position = UDim2.new(0, 8, 0.5, -4)
            stateDot.BackgroundColor3 = Color3.fromRGB(80, 80, 120)
            stateDot.BorderSizePixel = 0
            stateDot.Parent = btn
            Instance.new("UICorner", stateDot).CornerRadius = UDim.new(1, 0)

            -- keybind label
            local kbLabel = Instance.new("TextLabel")
            kbLabel.Size = UDim2.new(0, 40, 0, 14)
            kbLabel.Position = UDim2.new(1, -46, 0.5, -7)
            kbLabel.BackgroundTransparency = 1
            kbLabel.Font = Enum.Font.Gotham
            kbLabel.TextSize = 10
            kbLabel.TextColor3 = Color3.fromRGB(110, 110, 150)
            kbLabel.TextXAlignment = Enum.TextXAlignment.Right
            kbLabel.Text = ModuleManager.Keybinds[mod.Name] and ("[" .. ModuleManager.Keybinds[mod.Name]:sub(1,5) .. "]") or ""
            kbLabel.Parent = btn

            -- selection highlight
            local selStroke = Instance.new("UIStroke", btn)
            selStroke.Color = Color3.fromRGB(80, 130, 255)
            selStroke.Thickness = 1.5
            selStroke.Transparency = 1

            local info = {
                button     = btn,
                mod        = mod,
                dot        = stateDot,
                kbLabel    = kbLabel,
                selStroke  = selStroke,
            }

            local function updateColors()
                local isSelected = (settingsOpen and settingsModName == mod.Name)
                if mod.Enabled then
                    tweenColor(btn, Color3.fromRGB(75, 135, 220))
                    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                    stateDot.BackgroundColor3 = Color3.fromRGB(150, 210, 255)
                    selStroke.Transparency = isSelected and 0 or 1
                else
                    tweenColor(btn, Color3.fromRGB(28, 28, 52))
                    btn.TextColor3 = Color3.fromRGB(195, 195, 220)
                    stateDot.BackgroundColor3 = Color3.fromRGB(80, 80, 120)
                    selStroke.Transparency = isSelected and 0.3 or 1
                end
            end
            info.updateColors = updateColors
            updateColors()

            -- click handlers
            local lastClick = 0
            btn.MouseButton1Click:Connect(function()
                local now = tick()
                local dt = now - lastClick
                lastClick = now

                if dt < 0.35 then
                    -- DOUBLE CLICK: toggle module
                    ModuleManager:SetEnabled(mod, not mod.Enabled)
                    if mod.Enabled then
                        notify(mod.Name .. " включён", 2, Color3.fromRGB(45, 100, 65))
                    else
                        notify(mod.Name .. " выключен", 2, Color3.fromRGB(120, 60, 40))
                    end
                else
                    -- SINGLE CLICK: open/close settings
                    if settingsOpen and settingsModName == mod.Name then
                        renderSettingsPanel(nil)
                    else
                        renderSettingsPanel(mod)
                    end
                end

                -- refresh all button visuals
                for _, b in ipairs(allButtons) do
                    if b.updateColors then b.updateColors() end
                end
            end)

            btn.MouseEnter:Connect(function()
                if not mod.Enabled and not (settingsOpen and settingsModName == mod.Name) then
                    tweenColor(btn, Color3.fromRGB(40, 40, 68))
                end
            end)

            btn.MouseLeave:Connect(function()
                updateColors()
            end)

            table.insert(allButtons, info)
        end
    end

    -- ========== REBUILD COLUMNS ==========
    local function rebuildColumns()
        allButtons = {}

        for _, child in ipairs(mainFrame:GetChildren()) do
            if child:IsA("GuiObject") and child.Name ~= "UIListLayout" then
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
    end

    rebuildColumns()

    -- ========== SEARCH BAR ==========
    local searchFrame = Instance.new("Frame")
    searchFrame.Size = UDim2.new(0, 280, 0, 30)
    searchFrame.Position = UDim2.new(0.5, -140, 1, -42)
    searchFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
    searchFrame.BackgroundTransparency = 0.15
    searchFrame.BorderSizePixel = 0
    searchFrame.Parent = dragFrame
    Instance.new("UICorner", searchFrame).CornerRadius = UDim.new(0, 8)
    local searchStroke = Instance.new("UIStroke", searchFrame)
    searchStroke.Color = Color3.fromRGB(60, 60, 100)
    searchStroke.Thickness = 1

    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, -16, 1, 0)
    searchBox.Position = UDim2.new(0, 8, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.Font = Enum.Font.Gotham
    searchBox.PlaceholderText = "Поиск..."
    searchBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 160)
    searchBox.Text = ""
    searchBox.TextColor3 = Color3.fromRGB(220, 220, 240)
    searchBox.TextSize = 13
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.ClearTextOnFocus = false
    searchBox.Parent = searchFrame

    local function applySearch()
        local q = searchBox.Text:lower()
        for _, info in ipairs(allButtons) do
            local name = (info.mod.Name or ""):lower()
            local cat  = (info.mod.Category or ""):lower()
            local visible = (q == "") or (string.find(name, q, 1, true) ~= nil) or (string.find(cat, q, 1, true) ~= nil)
            info.button.Visible = visible
        end
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(applySearch)

    -- ========== REFRESH BUTTON ==========
    local refreshButton = Instance.new("TextButton")
    refreshButton.Name = "RefreshButton"
    refreshButton.Size = UDim2.new(0, 100, 0, 28)
    refreshButton.Position = UDim2.new(0, 10, 1, -42)
    refreshButton.BackgroundColor3 = Color3.fromRGB(18, 18, 30)
    refreshButton.BackgroundTransparency = 0.1
    refreshButton.BorderSizePixel = 0
    refreshButton.AutoButtonColor = false
    refreshButton.Font = Enum.Font.Gotham
    refreshButton.TextSize = 13
    refreshButton.TextColor3 = Color3.fromRGB(200, 200, 230)
    refreshButton.Text = "⟳ Обновить"
    refreshButton.Parent = dragFrame
    Instance.new("UICorner", refreshButton).CornerRadius = UDim.new(0, 8)
    local refreshStroke = Instance.new("UIStroke", refreshButton)
    refreshStroke.Color = Color3.fromRGB(60, 60, 100)
    refreshStroke.Thickness = 1

    refreshButton.MouseEnter:Connect(function() tweenColor(refreshButton, Color3.fromRGB(30, 30, 52)) end)
    refreshButton.MouseLeave:Connect(function() tweenColor(refreshButton, Color3.fromRGB(18, 18, 30)) end)

    refreshButton.MouseButton1Click:Connect(function()
        if ModuleManager.ReloadFromManifest then
            local ok, err = pcall(function() ModuleManager:ReloadFromManifest() end)
            if ok then
                rebuildColumns()
                applySearch()
                if settingsOpen and settingsModName then
                    local m = ModuleManager:GetModuleByName(settingsModName)
                    if m then renderSettingsPanel(m) else renderSettingsPanel(nil) end
                end
                notify("Модули обновлены!", 2, Color3.fromRGB(45, 100, 65))
            else
                notify("Ошибка обновления: " .. tostring(err), 4, Color3.fromRGB(120, 40, 45))
            end
        end
    end)

    -- ========== DRAGGING ==========
    local draggingWindow = false
    local dragStartPos = nil
    local frameStartPos = nil

    dragFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            draggingWindow = true
            dragStartPos = input.Position
            frameStartPos = dragFrame.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if draggingWindow and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStartPos
            dragFrame.Position = UDim2.new(
                frameStartPos.X.Scale, frameStartPos.X.Offset + delta.X,
                frameStartPos.Y.Scale, frameStartPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            draggingWindow = false
        end
    end)

    -- ========== MENU OPEN/CLOSE ==========
    local function playOpenAnim()
        screenGui.Enabled = true
        dragFrame.Position = UDim2.new(0.5, -550, 0.5, -290)
        local info = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(dragFrame, info, {Position = UDim2.new(0.5, -550, 0.5, -260)}):Play()
    end

    local function playCloseAnim()
        local info = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        local t = TweenService:Create(dragFrame, info, {Position = UDim2.new(0.5, -550, 0.5, -290)})
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

        -- Keybind capture mode
        if keybindListening and keybindCallback then
            keybindCallback(input)
            return
        end

        -- Menu toggle
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == Enum.KeyCode.RightShift then
                setMenuOpen(not menuOpen)
                return
            end

            -- Check module keybinds
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
                        if mod.Enabled then
                            notify(mod.Name .. " включён", 2, Color3.fromRGB(45, 100, 65))
                        else
                            notify(mod.Name .. " выключен", 2, Color3.fromRGB(120, 60, 40))
                        end
                    end
                    break
                end
            end
        end

        -- Mouse keybinds
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
                            if mod.Enabled then
                                notify(mod.Name .. " включён", 2, Color3.fromRGB(45, 100, 65))
                            else
                                notify(mod.Name .. " выключен", 2, Color3.fromRGB(120, 60, 40))
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
