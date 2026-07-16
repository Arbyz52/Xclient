
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local ESP = {
    __settings__ = {},
    SettingsDefinitions = {
        { Name = "Показать имена",  Key = "ShowNames",  Type = "Toggle", Default = true },
        { Name = "Показать HP",     Key = "ShowHP",     Type = "Toggle", Default = true },
        { Name = "Показать дист.",  Key = "ShowDist",   Type = "Toggle", Default = true },
        { Name = "Только враги",    Key = "Enemies",    Type = "Toggle", Default = false },
        { Name = "Цвет",            Key = "Color",      Type = "Dropdown", Options = {"Белый", "Красный", "Зелёный", "Жёлтый"}, Default = "Белый" },
    },
}

local drawings = {}
local connection = nil

local colorMap = {
    ["Белый"]  = Color3.new(1, 1, 1),
    ["Красный"] = Color3.fromRGB(255, 70, 70),
    ["Зелёный"] = Color3.fromRGB(70, 255, 120),
    ["Жёлтый"]  = Color3.fromRGB(255, 255, 80),
}

local function isEnemy(player)
    if not ESP.__settings__.Enemies then return true end
    if player.Team and LocalPlayer.Team then
        return player.Team ~= LocalPlayer.Team
    end
    return true
end

local function createESPForPlayer(player)
    if player == LocalPlayer then return end

    local espGroup = {}

    pcall(function()
        -- Box
        espGroup.box = Drawing.new("Square")
        espGroup.box.Visible = false
        espGroup.box.Color = Color3.new(1, 1, 1)
        espGroup.box.Thickness = 1
        espGroup.box.Filled = false
        espGroup.box.Transparency = 1

        -- Name
        espGroup.name = Drawing.new("Text")
        espGroup.name.Visible = false
        espGroup.name.Center = true
        espGroup.name.Outline = true
        espGroup.name.Font = 2
        espGroup.name.Size = 13
        espGroup.name.Color = Color3.new(1, 1, 1)

        -- HP bar background
        espGroup.hpBg = Drawing.new("Square")
        espGroup.hpBg.Visible = false
        espGroup.hpBg.Color = Color3.fromRGB(30, 30, 30)
        espGroup.hpBg.Thickness = 1
        espGroup.hpBg.Filled = true
        espGroup.hpBg.Transparency = 0.8

        -- HP bar fill
        espGroup.hpFill = Drawing.new("Square")
        espGroup.hpFill.Visible = false
        espGroup.hpFill.Color = Color3.fromRGB(0, 255, 0)
        espGroup.hpFill.Thickness = 1
        espGroup.hpFill.Filled = true
        espGroup.hpFill.Transparency = 1

        -- Distance
        espGroup.dist = Drawing.new("Text")
        espGroup.dist.Visible = false
        espGroup.dist.Center = true
        espGroup.dist.Outline = true
        espGroup.dist.Font = 2
        espGroup.dist.Size = 11
        espGroup.dist.Color = Color3.fromRGB(180, 180, 180)
    end)

    drawings[player] = espGroup
end

local function removeESPForPlayer(player)
    local espGroup = drawings[player]
    if espGroup then
        pcall(function()
            if espGroup.box then espGroup.box:Remove() end
            if espGroup.name then espGroup.name:Remove() end
            if espGroup.hpBg then espGroup.hpBg:Remove() end
            if espGroup.hpFill then espGroup.hpFill:Remove() end
            if espGroup.dist then espGroup.dist:Remove() end
        end)
        drawings[player] = nil
    end
end

function ESP:OnEnable()
    print("[Xclient] ESP ON")

    for _, player in ipairs(Players:GetPlayers()) do
        createESPForPlayer(player)
    end

    Players.PlayerAdded:Connect(function(player)
        createESPForPlayer(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        removeESPForPlayer(player)
    end)

    connection = RunService.RenderStepped:Connect(function()
        local colorKey = self.__settings__.Color or "Белый"
        local boxColor = colorMap[colorKey] or Color3.new(1, 1, 1)
        local localChar = LocalPlayer.Character
        local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")

        for player, espGroup in pairs(drawings) do
            local char = player.Character
            local humanoid = char and char:FindFirstChild("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if char and humanoid and humanoid.Health > 0 and root and isEnemy(player) then
                local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    local scale = 1000 / (Camera.CFrame.Position - root.Position).Magnitude
                    local w, h = scale * 1.6, scale * 3.5
                    local x, y = pos.X - w / 2, pos.Y - h / 2

                    -- Box
                    espGroup.box.Position = Vector2.new(x, y)
                    espGroup.box.Size = Vector2.new(w, h)
                    espGroup.box.Color = boxColor
                    espGroup.box.Visible = true

                    -- Name
                    if self.__settings__.ShowNames then
                        espGroup.name.Text = player.DisplayName or player.Name
                        espGroup.name.Position = Vector2.new(pos.X, y - 16)
                        espGroup.name.Visible = true
                    else
                        espGroup.name.Visible = false
                    end

                    -- HP bar
                    if self.__settings__.ShowHP then
                        local hpPct = humanoid.Health / humanoid.MaxHealth
                        local barW = 3
                        local barH = h

                        espGroup.hpBg.Position = Vector2.new(x - barW - 3, y)
                        espGroup.hpBg.Size = Vector2.new(barW, barH)
                        espGroup.hpBg.Visible = true

                        espGroup.hpFill.Position = Vector2.new(x - barW - 3, y + barH * (1 - hpPct))
                        espGroup.hpFill.Size = Vector2.new(barW, barH * hpPct)

                        if hpPct > 0.5 then
                            espGroup.hpFill.Color = Color3.fromRGB(0, 255, 0)
                        elseif hpPct > 0.25 then
                            espGroup.hpFill.Color = Color3.fromRGB(255, 255, 0)
                        else
                            espGroup.hpFill.Color = Color3.fromRGB(255, 0, 0)
                        end
                        espGroup.hpFill.Visible = true
                    else
                        espGroup.hpBg.Visible = false
                        espGroup.hpFill.Visible = false
                    end

                    -- Distance
                    if self.__settings__.ShowDist and localRoot then
                        local dist = math.floor((localRoot.Position - root.Position).Magnitude)
                        espGroup.dist.Text = tostring(dist) .. "m"
                        espGroup.dist.Position = Vector2.new(pos.X, y + h + 3)
                        espGroup.dist.Visible = true
                    else
                        espGroup.dist.Visible = false
                    end
                else
                    espGroup.box.Visible = false
                    espGroup.name.Visible = false
                    espGroup.hpBg.Visible = false
                    espGroup.hpFill.Visible = false
                    espGroup.dist.Visible = false
                end
            else
                espGroup.box.Visible = false
                espGroup.name.Visible = false
                espGroup.hpBg.Visible = false
                espGroup.hpFill.Visible = false
                espGroup.dist.Visible = false
            end
        end
    end)
end

function ESP:OnDisable()
    print("[Xclient] ESP OFF")
    if connection then connection:Disconnect() connection = nil end

    for player, _ in pairs(drawings) do
        removeESPForPlayer(player)
    end
    drawings = {}
end

return ESP
