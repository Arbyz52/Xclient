local module = {
    Name     = "ESP",
    Category = "Visuals",
    Enabled  = false,

    -- состояние и соединения сразу инициализируем
    _esp         = {},   -- [player] = {highlight = ..., hpGui = ..., hpBar = ..., humanoid = ...}
    _connections = {},   -- список/карта соединений для отключения
}

local Players    = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- локальные утилиты

local function disconnect(conn)
    if conn then
        pcall(function() conn:Disconnect() end)
    end
end

local function addConnection(key, conn)
    -- храним по ключу или пушим в список
    if key then
        -- если был старый — выключим
        if module._connections[key] then disconnect(module._connections[key]) end
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

-- удаление ESP для игрока
local function removeESP(player)
    local data = module._esp[player]
    if data then
        destroyEspData(data)
        module._esp[player] = nil
    end
    -- отключим персональные коннекты респавна, если есть
    local key = "Respawn_" .. tostring(player.UserId)
    if module._connections[key] then
        disconnect(module._connections[key])
        module._connections[key] = nil
    end
end

-- создание ESP (highlight + HP‑бар) для игрока
local function createESP(player)
    if player == LocalPlayer then return end
    if module._esp[player] then return end

    local char = player.Character
    if not char then
        -- если персонажа нет — дождёмся появления и тогда создадим
        local key = "Respawn_" .. tostring(player.UserId)
        addConnection(key, player.CharacterAdded:Connect(function(newChar)
            -- подстрахуемся: если к этому моменту ESP уже создан, не дублируем
            if not module._esp[player] then
                player.Character = newChar
                createESP(player)
            end
        end))
        return
    end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then
        -- иногда части приходят чуть позже; привяжем перехват на респавн
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

    -- BillboardGui (HP‑полоска над головой)
    local gui = Instance.new("BillboardGui")
    gui.Name = "ESP_HP"
    gui.Adornee = hrp
    gui.Size = UDim2.new(4, 0, 0.5, 0)
    gui.StudsOffset = Vector3.new(0, 3, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 1e6
    gui.Parent = char

    -- фон
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
    cornerBG.CornerRadius = UDim.new(0, 6)
    cornerBG.Parent = bg

    -- полоса HP
    local bar = Instance.new("Frame")
    bar.Name = "HP"
    bar.Size = UDim2.new(1, 0, 1, 0)  -- будет динамически изменяться по ширине
    bar.Position = UDim2.new(0, 0, 0, 0)
    bar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    bar.BorderSizePixel = 0
    bar.ZIndex = 2
    bar.Parent = bg

    local cornerBar = Instance.new("UICorner")
    cornerBar.CornerRadius = UDim.new(0, 6)
    cornerBar.Parent = bar

    -- сохраним ссылки
    module._esp[player] = {
        highlight = hl,
        hpGui     = gui,
        hpBar     = bar,
        humanoid  = hum,
        char      = char,
    }

    -- при каждом новом Character перепривязываем всё
    local key = "Respawn_" .. tostring(player.UserId)
    addConnection(key, player.CharacterAdded:Connect(function(newChar)
        -- очистим старое и создадим заново на новой модели
        removeESP(player)
        player.Character = newChar
        createESP(player)
    end))
end

-- обновление всех HP‑баров (раз в кадр)
local function updateAllBars()
    for player, data in pairs(module._esp) do
        local hum = data and data.humanoid
        local bar = data and data.hpBar
        if hum and bar then
            local max = math.max(hum.MaxHealth, 1)
            local ratio = math.clamp(hum.Health / max, 0, 1)
            bar.Size = UDim2.new(ratio, 0, 1, 0)
            -- градиент от красного к зелёному
            bar.BackgroundColor3 = Color3.fromRGB(255 * (1 - ratio), 255 * ratio, 0)
        end
    end
end

-- публичные методы модуля

function module:Init()
    print("[ESP] Init")
    -- гарантируем начальное состояние
    if not self._esp then self._esp = {} end
    if not self._connections then self._connections = {} end
end

function module:OnEnable()
    print("[ESP] Enabled")
    self.Enabled = true

    -- создать для уже присутствующих
    for _, plr in ipairs(Players:GetPlayers()) do
        createESP(plr)
    end

    -- новые игроки
    addConnection("PlayerAdded", Players.PlayerAdded:Connect(function(plr)
        -- ждём персонаж и создаём ESP
        addConnection("Respawn_" .. tostring(plr.UserId), plr.CharacterAdded:Connect(function(newChar)
            plr.Character = newChar
            createESP(plr)
        end))
        -- если персонаж уже есть (бывает), создадим сразу
        if plr.Character then
            createESP(plr)
        end
    end))

    -- удаление при выходе
    addConnection("PlayerRemoving", Players.PlayerRemoving:Connect(function(plr)
        removeESP(plr)
    end))

    -- апдейт HP‑баров
    addConnection("Render", RunService.RenderStepped:Connect(updateAllBars))
end

function module:OnDisable()
    print("[ESP] Disabled")
    self.Enabled = false

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
