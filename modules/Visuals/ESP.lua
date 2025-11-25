local module = {
    Name     = "ESP",
    Category = "Visuals",
    Enabled  = false,

    _esp         = {},   -- [player] = {highlight = ..., hpGui = ..., hpBar = ..., humanoid = ...}
    _connections = {},   -- ключ -> Connection
}

local Players      = game:GetService("Players")
local LocalPlayer  = Players.LocalPlayer
local RunService   = game:GetService("RunService")
local StarterGui   = game:GetService("StarterGui")

--=========================
-- УТИЛИТЫ
--=========================

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

local function destroyEspData(data)
    if not data then return end
    pcall(function()
        if data.highlight then data.highlight:Destroy() end
        if data.hpGui     then data.hpGui:Destroy() end
    end)
end

local function removeESP(player)
    local data = module._esp[player]
    if data then
        destroyEspData(data)
        module._esp[player] = nil
    end
    local key = "Respawn_" .. tostring(player.UserId)
    if module._connections[key] then
        disconnect(module._connections[key])
        module._connections[key] = nil
    end
end

--=========================
-- СОЗДАНИЕ ESP
--=========================

local function createESP(player)
    if player == LocalPlayer then return end
    if module._esp[player] then return end

    local char = player.Character
    if not char then
        -- дождёмся появления персонажа
        local key = "Respawn_" .. tostring(player.UserId)
        addConnection(key, player.CharacterAdded:Connect(function(newChar)
            player.Character = newChar
            createESP(player)
        end))
        return
    end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then
        -- если Humanoid / HRP ещё не прогрузились — повторим при следующем Character
        local key = "Respawn_" .. tostring(player.UserId)
        addConnection(key, player.CharacterAdded:Connect(function(newChar)
            player.Character = newChar
            createESP(player)
        end))
        return
    end

    -- Highlight (сквозь стены)
    local hl = Instance.new("Highlight")
    hl.Name = "ESP_HL"
    hl.Adornee = char
    hl.FillTransparency = 0.5
    hl.OutlineColor = Color3.fromRGB(255, 0, 0)
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = char

    -- BillboardGui (вертикальная HP‑полоска слева от персонажа)
    local gui = Instance.new("BillboardGui")
    gui.Name = "ESP_HP"
    gui.Adornee = hrp
    -- узкая и высокая полоска: ширина ~0.2, высота ~3
    gui.Size = UDim2.new(0.2, 0, 3, 0)
    -- слева от персонажа
    gui.StudsOffset = Vector3.new(-3, 0, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 1e6
    gui.Parent = char

    -- Фон (вертикальная полоска)
    local bg = Instance.new("Frame")
    bg.Name = "BG"
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.Position = UDim2.new(0, 0, 0, 0)
    bg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    bg.BackgroundTransparency = 0.3
    bg.BorderSizePixel = 0
    bg.ZIndex = 1
    bg.Parent = gui

    local cornerBG = Instance.new("UICorner")
    cornerBG.CornerRadius = UDim.new(0, 4)
    cornerBG.Parent = bg

    -- HP‑бар: растёт/убывает ВВЕРХ/ВНИЗ
    local bar = Instance.new("Frame")
    bar.Name = "HP"
    -- изначально фулл полоска
    bar.Size = UDim2.new(1, 0, 1, 0)
    -- снизу вверх: AnchorPoint + Position
    bar.AnchorPoint = Vector2.new(0, 1)
    bar.Position = UDim2.new(0, 0, 1, 0)
    bar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    bar.BorderSizePixel = 0
    bar.ZIndex = 2
    bar.Parent = bg

    local cornerBar = Instance.new("UICorner")
    cornerBar.CornerRadius = UDim.new(0, 4)
    cornerBar.Parent = bar

    module._esp[player] = {
        highlight = hl,
        hpGui     = gui,
        hpBar     = bar,
        humanoid  = hum,
        char      = char,
    }

    -- При новом Character перепривязываем ESP
    local key = "Respawn_" .. tostring(player.UserId)
    addConnection(key, player.CharacterAdded:Connect(function(newChar)
        -- полностью очищаем старое
        removeESP(player)
        player.Character = newChar
        createESP(player)
    end))
end

--=========================
-- ОБНОВЛЕНИЕ ПОЛОСОК
--=========================

local function updateAllBars()
    for player, data in pairs(module._esp) do
        local hum = data and data.humanoid
        local bar = data and data.hpBar
        if hum and bar and hum.Health and hum.MaxHealth and hum.MaxHealth > 0 then
            local ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)

            -- изменяем ВЫСОТУ (вертикальная полоска снизу вверх)
            bar.Size = UDim2.new(1, 0, ratio, 0)

            -- Цвет в зависимости от процента:
            -- > 60%   -> зелёный
            -- 30-60%  -> оранжевый
            -- < 30%   -> красный
            local color
            if ratio > 0.6 then
                color = Color3.fromRGB(0, 255, 0)           -- зелёный
            elseif ratio > 0.3 then
                color = Color3.fromRGB(255, 165, 0)         -- оранжевый
            else
                color = Color3.fromRGB(255, 0, 0)           -- красный
            end
            bar.BackgroundColor3 = color
        end
    end
end

--=========================
-- ВКЛ / ВЫКЛ МОДУЛЯ
--=========================

function module:Init()
    if not self._esp then self._esp = {} end
    if not self._connections then self._connections = {} end
end

function module:OnEnable()
    self.Enabled = true

    -- выключаем стандартный Roblox HP бар
    pcall(function()
        StarterGui:SetCore("HealthBarVisible", false)
    end)

    -- ESP для уже присутствующих
    for _, plr in ipairs(Players:GetPlayers()) do
        -- если персонаж уже есть, создаём сразу
        if plr.Character then
            createESP(plr)
        else
            -- иначе ждём его появления
            local key = "Respawn_" .. tostring(plr.UserId)
            addConnection(key, plr.CharacterAdded:Connect(function(newChar)
                plr.Character = newChar
                createESP(plr)
            end))
        end
    end

    -- новые игроки
    addConnection("PlayerAdded", Players.PlayerAdded:Connect(function(plr)
        if plr.Character then
            createESP(plr)
        else
            local key = "Respawn_" .. tostring(plr.UserId)
            addConnection(key, plr.CharacterAdded:Connect(function(newChar)
                plr.Character = newChar
                createESP(plr)
            end))
        end
    end))

    -- удаление при выходе игрока
    addConnection("PlayerRemoving", Players.PlayerRemoving:Connect(function(plr)
        removeESP(plr)
    end))

    -- апдейт HP‑баров
    addConnection("Render", RunService.RenderStepped:Connect(updateAllBars))
end

function module:OnDisable()
    self.Enabled = false

    -- вернуть стандартный HP бар
    pcall(function()
        StarterGui:SetCore("HealthBarVisible", true)
    end)

    -- снять все ESP
    for plr, data in pairs(self._esp) do
        destroyEspData(data)
        self._esp[plr] = nil
    end

    -- отключить все соединения
    if type(self._connections) == "table" then
        for key, conn in pairs(self._connections) do
            disconnect(conn)
            self._connections[key] = nil
        end
    end
end

function module:OnTick(dt)
    -- не используется
end

return module
