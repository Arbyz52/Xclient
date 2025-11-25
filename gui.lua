-- ===================== gui.lua (GitHub) ======================

local Gui = {}

function Gui.Init(ModuleManager)
    local UserInputService = game:GetService("UserInputService")
    local CoreGui          = game:GetService("CoreGui")

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
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 800, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -400, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui

    local uiCorner = Instance.new("UICorner", mainFrame)
    uiCorner.CornerRadius = UDim.new(0, 8)

    local layout = Instance.new("UIListLayout", mainFrame)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 10)

    local function createCategoryColumn(categoryName, modules)
        table.sort(modules, function(a, b)
            return (a.Name or "") < (b.Name or "")
        end)

        local colFrame = Instance.new("Frame")
        colFrame.Name = categoryName
        colFrame.Size = UDim2.new(0, 150, 1, -20)
        colFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        colFrame.BorderSizePixel = 0
        colFrame.Parent = mainFrame

        local colCorner = Instance.new("UICorner", colFrame)
        colCorner.CornerRadius = UDim.new(0, 6)

        local title = Instance.new("TextLabel", colFrame)
        title.Name = "Title"
        title.Size = UDim2.new(1, -10, 0, 24)
        title.Position = UDim2.new(0, 5, 0, 5)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.SourceSansBold
        title.Text = categoryName
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextSize = 18
        title.TextXAlignment = Enum.TextXAlignment.Left

        local holder = Instance.new("Frame", colFrame)
        holder.Name = "ButtonsHolder"
        holder.Size = UDim2.new(1, -10, 1, -34)
        holder.Position = UDim2.new(0, 5, 0, 30)
        holder.BackgroundTransparency = 1

        local list = Instance.new("UIListLayout", holder)
        list.FillDirection = Enum.FillDirection.Vertical
        list.Padding = UDim.new(0, 4)

        for _, mod in ipairs(modules) do
            local btn = Instance.new("TextButton")
            btn.Name = mod.Name
            btn.Size = UDim2.new(1, 0, 0, 22)
            btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            btn.BorderSizePixel = 0
            btn.AutoButtonColor = false
            btn.Font = Enum.Font.SourceSans
            btn.TextSize = 16
            btn.TextColor3 = Color3.fromRGB(200, 200, 200)
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Text = mod.Name
            btn.Parent = holder

            local btnCorner = Instance.new("UICorner", btn)
            btnCorner.CornerRadius = UDim.new(0, 4)

            local function updateColor()
                if mod.Enabled then
                    btn.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
                    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                else
                    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
                    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
                end
            end
            updateColor()

            btn.MouseButton1Click:Connect(function()
                ModuleManager:SetEnabled(mod, not mod.Enabled)
                updateColor()
            end)
        end
    end

    local categoryNames = {}
    for name, _ in pairs(ModuleManager.Categories) do
        table.insert(categoryNames, name)
    end
    table.sort(categoryNames)

    for _, catName in ipairs(categoryNames) do
        createCategoryColumn(catName, ModuleManager.Categories[catName])
    end

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            screenGui.Enabled = not screenGui.Enabled
        end
    end)

    print("[Xclient] GUI инициализирован, RightShift - открыть/закрыть")
end

return Gui
