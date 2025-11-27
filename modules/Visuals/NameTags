local module = {
    Name     = "NameTags",
    Category = "Visuals",
    Enabled  = false,

    _data        = {},   -- [player] = {billboard, textLabel}
    _connections = {},
}

local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ========= УТИЛИТЫ =========

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

local function destroyPlayerData(player)
    local info = module._data[player]
    if not info then return end

    if info.billboard then
        pcall(function() info.billboard:Destroy() end)
    end

    module._data[player] = nil
end

-- ========= ЛОГИКА КОМАНД (как в ESP, только враги; если нужно для всех — убери isEnemy) =========

local function isEnemy(player)
    if player == LocalPlayer then
        return false
    end

    -- если у игры нет команд, то все, кроме LocalPlayer, считаются врагами
    if not LocalPlayer.Team or not player.Team then
        return player ~= LocalPlayer
    end

    return player.Team ~= LocalPlayer.Team
end

-- ========= СОЗДАНИЕ NAME TAG =========

local function createNameTag(player, character)
    if not character then return end

    -- ищем голову
    local head = character:FindFirstChild("Head") or character:FindFirstChildWhichIsA("BasePart")
    if not head then
        local key = "HeadWait_" .. player.UserId
        addConnection(key, character.ChildAdded:Connect(function(child)
            if child.Name == "Head" or child:IsA("BasePart") then
                disconnect(module._connections[key])
                module._connections[key] = nil
                createNameTag(player, character)
            end
        end))
        return
    end

    -- удаляем старый тег, если есть
    local old = character:FindFirstChild("NameTag")
    if old then
        pcall(function() old:Destroy() end)
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NameTag"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 200
    billboard.ResetOnSpawn = false

    local bg = Instance.new("Frame")
    bg.Name = "Background"
    bg.BackgroundTransparency = 0.2
    bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BorderSizePixel = 0
    bg.Parent = billboard

    local text = Instance.new("TextLabel")
    text.Name = "NameText"
    text.AnchorPoint = Vector2.new(0.5, 0.5)
    text.Position = UDim2.new(0.5, 0, 0.5, 0)
    text.Size = UDim2.new(1, -10, 1, -10)
    text.BackgroundTransparency = 1

    text.Text = player.DisplayName ~= "" and player.DisplayName or player.Name
    text.Font = Enum.Font.GothamBold      -- можно сменить на любой
    text.TextScaled = true
    text.TextColor3 = Color3.fromRGB(255, 255, 255)
    text.TextStrokeTransparency = 0.2
    text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

    text.Parent = bg
    billboard.Parent = character

    module._data[player] = {
        billboard = billboard,
        textLabel = text,
    }
end

-- ========= НАСТРОЙКА ЧАРА / КОМАНД =========

local function setupCharacter(player, character)
    if not isEnemy(player) then
        destroyPlayerData(player)
        return
    end

    destroyPlayerData(player)
    createNameTag(player, character)
end

local function trackTeamChange(player)
    local key = "TeamChanged_" .. player.UserId
    addConnection(key, player:GetPropertyChangedSignal("Team"):Connect(function()
        if not isEnemy(player) then
            destroyPlayerData(player)
            return
        end

        if player.Character then
            setupCharacter(player, player.Character)
        end
    end))
end

local function onPlayerAdded(player)
    -- не трогаем локального игрока
    if player == LocalPlayer then
        return
    end

    trackTeamChange(player)

    if not isEnemy(player) then
        return
    end

    if player.Character then
        setupCharacter(player, player.Character)
    end

    local key = "Respawn_" .. player.UserId
    addConnection(key, player.CharacterAdded:Connect(function(newChar)
        setupCharacter(player, newChar)
    end))
end

local function onPlayerRemoving(player)
    destroyPlayerData(player)
end

-- ========= МОДУЛЬНЫЕ МЕТОДЫ =========

function module:Init()
    if not self._data then self._data = {} end
    if not self._connections then self._connections = {} end
end

function module:OnEnable()
    self.Enabled = true

    -- уже находящиеся игроки
    for _, plr in ipairs(Players:GetPlayers()) do
        onPlayerAdded(plr)
    end

    addConnection("PlayerAdded",    Players.PlayerAdded:Connect(onPlayerAdded))
    addConnection("PlayerRemoving", Players.PlayerRemoving:Connect(onPlayerRemoving))
end

function module:OnDisable()
    self.Enabled = false

    for plr, _ in pairs(self._data) do
        destroyPlayerData(plr)
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
