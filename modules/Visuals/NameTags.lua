local module = {
    Name     = "NameTags",
    Category = "Visuals",
    Enabled  = false,

    _data        = {},   -- [player] = {billboard, textLabel, character, rootPart}
    _connections = {},
}

local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService  = game:GetService("RunService")

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

-- ========= СОЗДАНИЕ NAME TAG =========

local MAX_SHOW_DISTANCE = 120

local function createNameTag(player, character)
    if not character then return end

    -- ищем голову или любую деталь
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

    -- удаляем старый тег, если вдруг есть
    local old = character:FindFirstChild("NameTag")
    if old then
        pcall(function() old:Destroy() end)
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NameTag"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 150, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = MAX_SHOW_DISTANCE + 20
    billboard.ResetOnSpawn = false

    -- без фона, только текст
    local text = Instance.new("TextLabel")
    text.Name = "NameText"
    text.AnchorPoint = Vector2.new(0.5, 0.5)
    text.Position = UDim2.new(0.5, 0, 0.5, 0)
    text.Size = UDim2.new(1, -10, 1, -6)
    text.BackgroundTransparency = 1

    text.Text = player.DisplayName ~= "" and player.DisplayName or player.Name
    text.Font = Enum.Font.GothamBold
    text.TextScaled = false
    text.TextSize = 12             -- меньше шрифт
    text.TextColor3 = Color3.fromRGB(255, 255, 255)
    text.TextStrokeTransparency = 0.2
    text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

    text.Parent = billboard
    billboard.Parent = character

    local root = character:FindFirstChild("HumanoidRootPart") or head

    module._data[player] = {
        billboard = billboard,
        textLabel = text,
        character = character,
        rootPart  = root,
    }
end

-- ========= ОБНОВЛЕНИЕ ВИДИМОСТИ =========

local function updateAll()
    local lpChar = LocalPlayer.Character
    local lpRoot = lpChar and lpChar:FindFirstChild("HumanoidRootPart")

    for player, info in pairs(module._data) do
        local text = info.textLabel
        local root = info.rootPart

        if not text or not root or not lpRoot then
            if text then text.Visible = false end
        else
            local dist = (lpRoot.Position - root.Position).Magnitude
            -- резкий порог
            text.Visible = dist <= MAX_SHOW_DISTANCE
        end
    end
end

-- ========= ОБРАБОТКА ИГРОКОВ =========

local function onCharacterAdded(player, character)
    if player == LocalPlayer then return end
    destroyPlayerData(player)
    createNameTag(player, character)
end

local function onPlayerAdded(player)
    if player == LocalPlayer then return end

    if player.Character then
        onCharacterAdded(player, player.Character)
    end

    local key = "Respawn_" .. player.UserId
    addConnection(key, player.CharacterAdded:Connect(function(char)
        onCharacterAdded(player, char)
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

    for _, plr in ipairs(Players:GetPlayers()) do
        onPlayerAdded(plr)
    end

    addConnection("PlayerAdded",    Players.PlayerAdded:Connect(onPlayerAdded))
    addConnection("PlayerRemoving", Players.PlayerRemoving:Connect(onPlayerRemoving))

    addConnection("UpdateNameTags", RunService.RenderStepped:Connect(updateAll))
end

function module:OnDisable()
    self.Enabled = false

    for plr, _ in pairs(self._data) do
        destroyPlayerData(plr)
    end
    self._data = {}

    for key, conn in pairs(self._connections) do
        disconnect(conn)
        module._connections[key] = nil
    end
end

function module:OnTick(dt)
end

return module
