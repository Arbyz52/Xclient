
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local NameTags = {
    __settings__ = {},
    SettingsDefinitions = {
        { Name = "Размер",       Key = "Size",    Type = "Slider", Min = 10, Max = 30, Step = 1, Default = 16, Suffix = "" },
        { Name = "Показать роль", Key = "ShowRole", Type = "Toggle", Default = false },
    },
}

local billboards = {}

local function addNameTag(player)
    if player == LocalPlayer then return end

    pcall(function()
        local char = player.Character or player.CharacterAdded:Wait()
        local head = char:WaitForChild("Head", 5)
        if not head then return end

        local bb = Instance.new("BillboardGui")
        bb.Name = "XclientNameTag"
        bb.Size = UDim2.new(0, 150, 0, 30)
        bb.StudsOffset = Vector3.new(0, 2.5, 0)
        bb.AlwaysOnTop = true
        bb.Parent = head

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.TextSize = NameTags.__settings__.Size or 16
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextStrokeColor3 = Color3.fromRGB(20, 20, 20)
        label.TextStrokeTransparency = 0.3
        label.Text = player.DisplayName or player.Name
        label.Parent = bb

        billboards[player] = { gui = bb, label = label }
    end)
end

local function removeNameTag(player)
    local data = billboards[player]
    if data then
        pcall(function()
            if data.gui then data.gui:Destroy() end
        end)
        billboards[player] = nil
    end
end

function NameTags:OnEnable()
    print("[Xclient] NameTags ON")

    for _, player in ipairs(Players:GetPlayers()) do
        addNameTag(player)
    end

    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            task.wait(0.5)
            addNameTag(player)
        end)
    end)

    Players.PlayerRemoving:Connect(function(player)
        removeNameTag(player)
    end)
end

function NameTags:OnDisable()
    print("[Xclient] NameTags OFF")
    for player, _ in pairs(billboards) do
        removeNameTag(player)
    end
    billboards = {}
end

return NameTags
