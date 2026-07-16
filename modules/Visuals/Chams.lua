
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Chams = {
    __settings__ = {},
    SettingsDefinitions = {
        { Name = "Цвет", Key = "Color", Type = "Dropdown", Options = {"Красный", "Синий", "Зелёный", "Фиолетовый", "Белый"}, Default = "Красный" },
        { Name = "Прозрачность", Key = "Transparency", Type = "Slider", Min = 0, Max = 100, Step = 5, Default = 50, Suffix = "%" },
        { Name = "Только враги", Key = "Enemies", Type = "Toggle", Default = true },
    },
}

local highlights = {}

local colorMap = {
    ["Красный"]     = Color3.fromRGB(255, 60, 60),
    ["Синий"]       = Color3.fromRGB(60, 130, 255),
    ["Зелёный"]     = Color3.fromRGB(60, 255, 120),
    ["Фиолетовый"]  = Color3.fromRGB(180, 60, 255),
    ["Белый"]       = Color3.fromRGB(255, 255, 255),
}

local function isEnemy(player)
    if not Chams.__settings__.Enemies then return true end
    if player.Team and LocalPlayer.Team then
        return player.Team ~= LocalPlayer.Team
    end
    return true
end

local function applyChams(player)
    if player == LocalPlayer then return end
    if not isEnemy(player) then return end

    local char = player.Character
    if not char then return end

    if highlights[player] then
        pcall(function() highlights[player]:Destroy() end)
    end

    local colorKey = Chams.__settings__.Color or "Красный"
    local transp = (Chams.__settings__.Transparency or 50) / 100

    local highlight = Instance.new("Highlight")
    highlight.Name = "XclientChams"
    highlight.FillColor = colorMap[colorKey] or Color3.fromRGB(255, 60, 60)
    highlight.FillTransparency = transp
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0.7
    highlight.Adornee = char
    highlight.Parent = char

    highlights[player] = highlight
end

local function removeChams(player)
    local h = highlights[player]
    if h then
        pcall(function() h:Destroy() end)
        highlights[player] = nil
    end
end

local connection = nil

function Chams:OnEnable()
    print("[Xclient] Chams ON")

    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then applyChams(player) end
        player.CharacterAdded:Connect(function()
            task.wait(0.3)
            applyChams(player)
        end)
    end

    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            task.wait(0.3)
            applyChams(player)
        end)
    end)

    Players.PlayerRemoving:Connect(function(player)
        removeChams(player)
    end)

    connection = RunService.Heartbeat:Connect(function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local h = highlights[player]
                if isEnemy(player) then
                    if not h or not h.Parent then
                        applyChams(player)
                    else
                        local colorKey = Chams.__settings__.Color or "Красный"
                        h.FillColor = colorMap[colorKey] or Color3.fromRGB(255, 60, 60)
                        h.FillTransparency = (Chams.__settings__.Transparency or 50) / 100
                    end
                else
                    if h then removeChams(player) end
                end
            end
        end
    end)
end

function Chams:OnDisable()
    print("[Xclient] Chams OFF")
    if connection then connection:Disconnect() connection = nil end
    for player, _ in pairs(highlights) do
        removeChams(player)
    end
    highlights = {}
end

return Chams
