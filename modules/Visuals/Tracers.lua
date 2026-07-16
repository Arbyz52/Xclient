
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Tracers = {
    __settings__ = {},
    SettingsDefinitions = {
        { Name = "Толщина", Key = "Thickness", Type = "Slider", Min = 1, Max = 4, Step = 1, Default = 1, Suffix = "" },
        { Name = "Только враги", Key = "Enemies", Type = "Toggle", Default = false },
    },
}

local lines = {}
local connection = nil

local function isEnemy(player)
    if not Tracers.__settings__.Enemies then return true end
    if player.Team and LocalPlayer.Team then
        return player.Team ~= LocalPlayer.Team
    end
    return true
end

local function createLine(player)
    if player == LocalPlayer then return end
    pcall(function()
        local line = Drawing.new("Line")
        line.Visible = false
        line.Color = Color3.fromRGB(255, 80, 80)
        line.Thickness = Tracers.__settings__.Thickness or 1
        line.Transparency = 0.7
        lines[player] = line
    end)
end

local function removeLine(player)
    local line = lines[player]
    if line then
        pcall(function() line:Remove() end)
        lines[player] = nil
    end
end

function Tracers:OnEnable()
    print("[Xclient] Tracers ON")

    for _, player in ipairs(Players:GetPlayers()) do
        createLine(player)
    end

    Players.PlayerAdded:Connect(function(player)
        createLine(player)
    end)
    Players.PlayerRemoving:Connect(function(player)
        removeLine(player)
    end)

    local viewportSize = Camera.ViewportSize
    local bottomCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y)

    connection = RunService.RenderStepped:Connect(function()
        viewportSize = Camera.ViewportSize
        bottomCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y)

        for player, line in pairs(lines) do
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local humanoid = char and char:FindFirstChild("Humanoid")

            if root and humanoid and humanoid.Health > 0 and isEnemy(player) then
                local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    line.From = bottomCenter
                    line.To = Vector2.new(pos.X, pos.Y)
                    line.Thickness = self.__settings__.Thickness or 1
                    line.Visible = true
                else
                    line.Visible = false
                end
            else
                line.Visible = false
            end
        end
    end)
end

function Tracers:OnDisable()
    print("[Xclient] Tracers OFF")
    if connection then connection:Disconnect() connection = nil end
    for player, _ in pairs(lines) do
        removeLine(player)
    end
    lines = {}
end

return Tracers
