local module = {
    Name = "ESP",
    Category = "Visuals",
    Enabled = false,
    _data = {},
    _connections = {},
}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

local USE_TEAMS = true


local function disconnect(conn)
    if conn then
        pcall(function() conn:Disconnect() end)
    end
end

local function addConnection(key, conn)
    if key then
        if module._connections[key] then
            disconnect(module._connections[key])
        end
        module._connections[key] = conn
    else
        table.insert(module._connections, conn)
    end
end

local function disableDefaultHp(humanoid)
    if not humanoid then return end
    pcall(function()
        humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
    end)
end

local function restoreDefaultHp(humanoid)
    if not humanoid then return end
    pcall(function()
        humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.DisplayWhenDamaged
    end)
end

local function destroyPlayerData(player)
    local info = module._data[player]
    if not info then return end

    if info.highlight then
        pcall(function() info.highlight:Destroy() end)
    end

    module._data[player] = nil
end


local function isEnemy(player)
    if player == LocalPlayer then
        return false
    end

    if not USE_TEAMS then

        return true
    end


    local myTeam = LocalPlayer.Team
    local theirTeam = player.Team

    if myTeam == nil or theirTeam == nil then
        return false
    end

    return theirTeam ~= myTeam
end

local function getHealthColor(ratio)
    ratio = math.clamp(ratio, 0, 1)
    if ratio >= 0.5 then
 
        local t = (ratio - 0.5) / 0.5
        local r = 255 * (1 - t)
        local g = 255
        local b = 0
        return Color3.fromRGB(r, g, b)
    else

        local t = ratio / 0.5
        local r = 255
        local g = 255 * t
        local b = 0
        return Color3.fromRGB(r, g, b)
    end
end



local function setupCharacter(player, character)
    if not character then return end


    if not isEnemy(player) then
        destroyPlayerData(player)
        return
    end

    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum then

        local key = "HumWait_" .. player.UserId
        addConnection(key, character.ChildAdded:Connect(function(child)
            if child:IsA("Humanoid") then
                disconnect(module._connections[key])
                module._connections[key] = nil

                task.defer(function()
                    if not module.Enabled then return end
                    setupCharacter(player, character)
                end)
            end
        end))
        return
    end

    disableDefaultHp(hum)


    destroyPlayerData(player)

    local hl = Instance.new("Highlight")
    hl.Name = "ESP_Highlight"
    hl.Adornee = character
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency = 1
    hl.OutlineTransparency = 0

    local ratio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
    local col = getHealthColor(ratio)
    hl.OutlineColor = col
    hl.Parent = character

    module._data[player] = {
        humanoid = hum,
        character = character,
        highlight = hl,
        lastColor = col,
    }
end



local function trackTeamChange(player)
    local key = "TeamChanged_" .. player.UserId
    addConnection(key, player:GetPropertyChangedSignal("Team"):Connect(function()
        task.defer(function()
            if not module.Enabled then return end

            if not isEnemy(player) then
                destroyPlayerData(player)
                return
            end


            local character = player.Character
            if character then
                setupCharacter(player, character)
            end
        end)
    end))
end



local function onCharacterAdded(player, character)

    destroyPlayerData(player)

    task.defer(function()
        if not module.Enabled then return end


        if isEnemy(player) then
            setupCharacter(player, character)
        else
            destroyPlayerData(player)
        end
    end)
end

local function onPlayerAdded(player)
    if player == LocalPlayer then return end

    trackTeamChange(player)


    if player.Character then
        onCharacterAdded(player, player.Character)
    end

    local key = "Respawn_" .. player.UserId
    addConnection(key, player.CharacterAdded:Connect(function(newChar)
        onCharacterAdded(player, newChar)
    end))
end

local function onPlayerRemoving(player)
    destroyPlayerData(player)
end



local LERP_SPEED = 10

local function updateAll(dt)
    for player, info in pairs(module._data) do
        local hum = info.humanoid
        local hl = info.highlight


        if not isEnemy(player) then
            destroyPlayerData(player)
        elseif hum and hl and hum.Parent and hum.MaxHealth > 0 then
            local ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            local targetColor = getHealthColor(ratio)
            local current = info.lastColor or targetColor
            local alpha = math.clamp(LERP_SPEED * dt, 0, 1)
            local newColor = current:Lerp(targetColor, alpha)
            hl.OutlineColor = newColor
            info.lastColor = newColor
        else

            destroyPlayerData(player)
        end
    end
end



function module:Init()
    if not self._data then self._data = {} end
    if not self._connections then self._connections = {} end
end

function module:OnEnable()
    self.Enabled = true


    for _, plr in ipairs(Players:GetPlayers()) do
        onPlayerAdded(plr)
    end

    addConnection("PlayerAdded", Players.PlayerAdded:Connect(onPlayerAdded))
    addConnection("PlayerRemoving", Players.PlayerRemoving:Connect(onPlayerRemoving))
    addConnection("RenderUpdate", RunService.RenderStepped:Connect(function(dt)
        if not module.Enabled then return end
        updateAll(dt)
    end))
end

function module:OnDisable()
    self.Enabled = false

    for plr, info in pairs(self._data) do
        if info.humanoid then
            restoreDefaultHp(info.humanoid)
        end
        if info.highlight then
            pcall(function() info.highlight:Destroy() end)
        end
    end
    self._data = {}

    for key, conn in pairs(self._connections) do
        disconnect(conn)
        self._connections[key] = nil
    end
end

function module:OnTick(dt)

end

return module
