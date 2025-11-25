local module = {
    Name     = "ESP",
    Category = "Visuals",
    Enabled  = false,

    -- состояние и соединения сразу инициализируем
    _esp         = {},   -- [player] = {highlight = ..., hpGui = ..., hpBar = ..., humanoid = ..., origHealthDisplayType = ...}
    _connections = {},   -- список/карта соединений для отключения

    _localHumanoid          = nil,
    _localOrigDisplayType   = nil,
}

local Players      = game:GetService("Players")
local LocalPlayer  = Players.LocalPlayer
local RunService   = game:GetService("RunService")
local StarterGui   = game:GetService("StarterGui")

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
        -- вернуть стандартный вид полоски хп над головой
        if data.humanoid and data.origHealthDisplayType then
            data.humanoid.HealthDisplayType = data.origHealthDisplayType
        end

        if data.highlight then data.highlight:Destroy() end
        if data.hpGui     then data.hpGui:Destroy()     end
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

-- создание ESP (highlight + вертикальный HP‑бар слева) для игрока
local function createESP(player)
    if player == LocalPlayer then return end
    if module._esp[player] then return end

    local char = player.Character
    if not char then
        -- если персонажа нет — дождёмся появления и тогда создадим
        local key = "Respawn_" .. tostring(player.UserId)
        addConnection(key, player.CharacterAdded:Connect(function(newChar)
            player.Character = newChar
            createESP(player)
        end))
        return
    end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")

    if not hum or not hrp then
        -- попробуем дождаться нужных частей этого же персонажа
        local ok = pcall(function()
            hum = hum or char:WaitForChild("Humanoid", 5)
            hrp = hrp or char:WaitForChild("HumanoidRootPart", 5)
        end)

        if not ok or not hum or not hrp then
            -- если всё ещё нет — ждём следующий респавн
            local key = "Respawn_" .. tostring(player.UserId)
            addConnection(key, player.CharacterAdded:Connect(function(newChar)
                player.Character = newChar
                createESP(player)
            end))
            return
        end
    end

    -- запомним и отключим стандартную полоску хп над головой
    local origDisplayType = hum.HealthDisplayType
    hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff

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
    gui.Size = UDim2.new(0.2, 0, 3, 0)          -- тонкая (0.2) и высокая (3 студии)
    gui.StudsOffset = Vector3.new(-2, 1.5, 0)   -- слева от персонажа
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
    cornerBG.CornerRadius = UDim.new(0, 4)
    cornerBG.Parent = bg

    -- вертикальная полоса HP (заполняется снизу вверх)
    local bar = Instance.new("Frame")
    bar.Name = "HP"
    bar.AnchorPoint = Vector2.new(0, 1)             -- привязка к низу
    bar.Position = UDim2.new(0, 0, 1, 0)            -- внизу фона
    bar.Size = UDim2.new(1, 0, 1, 0)                -- высота будет меняться по ScaleY
    bar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    bar.BorderSizePixel = 0
    bar.ZIndex = 2
    bar.Parent = bg

    local cornerBar = Instance.new("UICorner")
    cornerBar.CornerRadius = UDim.new(0, 4)
    cornerBar.Parent = bar

    -- сохраним ссылки
    module._esp[player] = {
        highlight             = hl,
        hpGui                 = gui,
        hpBar                 = bar,
        humanoid              = hum,
        char                  = char,
        origHealthDisplayType = origDisplayType,
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
        if hum and bar and hum.MaxHealth > 0 then
            local ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)

            -- вертикальное заполнение (снизу вверх)
            bar.Size = UDim2.new(1, 0, ratio, 0)

            -- цвет по уровню хп:
            -- >70%  -> зелёный
            -- 30-70 -> оранжевый
            -- <30%  -> красный
            local color
            if ratio > 0.7 then
                color = Color3.fromRGB(0, 255, 0)
            elseif ratio > 0.3 then
                color = Color3.fromRGB(255, 165, 0)
            else
                color = Color3.fromRGB(255, 0, 0)
            end
            bar.BackgroundColor3 = color
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

    -- выключаем стандартный GUI‑хп (нижний/левый верхний угол)
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
    end)

    -- спрячем стандартный хп‑бар над головой локального игрока
    local function hideLocalHeadBar(char)
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            module._localHumanoid = hum
            module._localOrigDisplayType = hum.HealthDisplayType
            hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
        end
    end

    if LocalPlayer.Character then
        hideLocalHeadBar(LocalPlayer.Character)
    end
    addConnection("LocalRespawn", LocalPlayer.CharacterAdded:Connect(hideLocalHeadBar))

    -- создать для уже присутствующих игроков
    for _, plr in ipairs(Players:GetPlayers()) do
        createESP(plr)
    end

    -- новые игроки
    addConnection("PlayerAdded", Players.PlayerAdded:Connect(function(plr)
        createESP(plr)
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

    -- вернуть стандартный GUI‑хп
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, true)
    end)

    -- вернуть полоску хп над головой локального игрока
    if self._localHumanoid and self._localOrigDisplayType then
        pcall(function()
            self._localHumanoid.HealthDisplayType = self._localOrigDisplayType
        end)
    end
    self._localHumanoid = nil
    self._localOrigDisplayType = nil

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
