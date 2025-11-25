local module = {
    Name     = "ESP",
    Category = "Visuals",
    Enabled  = false,

    _esp         = {},   -- [player] = {highlight = ..., hpGui = ..., hpBar = ..., humanoid = ...}
    _connections = {},   -- ключ -> Connection
}

local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService  = game:GetService("RunService")

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

-- Отключение стандартного HP‑текста над головой (HealthDisplayDistance = 0)
local function disableDefaultHumanoidHp(humanoid)
    if not humanoid then return end
    pcall(function()
        humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
    end)
end

--=========================
-- СОЗДАНИЕ ESP
--=========================

local function createESP(player)
    if player == LocalPlayer then return end
    if module._esp[player] then return end

    local char = player.Character
    if not char then
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
        local key = "Respawn_" .. tostring(player.UserId)
        addConnection(key, player.CharacterAdded:Connect(function(newChar)
            player.Character = newChar
            createESP(player)
        end))
        return
    end

    -- выключаем стандартный HP над головой
    disableDefaultHumanoidHp(hum)

    -- Highlight
    local hl = Instance.new("Highlight")
    hl.Name = "ESP_HL"
    hl.Adornee = char
    hl.FillTransparency = 0.5
    hl.OutlineColor = Color3.fromRGB(255, 0, 0)
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = char

    -- BillboardGui
    local gui = Instance.new("BillboardGui")
    gui.Name = "ESP_HP"
    gui.Adornee = hrp
    gui.AlwaysOnTop = true
    gui.MaxDistance = 9e9

    -- Высота почти как персонаж (около 5 студов), узкая полоса по ширине
    gui.Size = UDim2.new(0.3, 0, 5, 0)

    -- Держим полосу рядом с персонажем, НЕ далеко:
    -- Слегка слева и немного вперёд, чтобы не пряталась внутрь модели
    gui.StudsOffset = Vector3.new(-3, 0, -1)

    gui.Parent = char

    -- Фон
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

    -- Вертикальный HP‑бар
    local bar = Instance.new("Frame")
    bar.Name = "HP"
    bar.AnchorPoint = Vector2.new(0, 1)
    bar.Position = UDim2.new(0, 0, 1, 0)
    bar.Size = UDim2.new(1, 0, 1, 0)
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

    -- При новом персонаже всё пересоздаём
    local key = "Respawn_" .. tostring(player.UserId)
    addConnection(key, player.CharacterAdded:Connect(function(newChar)
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
        if hum and bar and hum.MaxHealth > 0 then
            local ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)

            -- По высоте полоса повторяет рост персонажа (высоту гуя)
            bar.Size = UDim2.new(1, 0, ratio, 0)

            -- Цвет: >60% зелёный, 30–60% оранж, <30% красный
            local color
            if ratio > 0.6 then
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

--=========================
-- МОДУЛЬНЫЕ МЕТОДЫ
--=========================

function module:Init()
    if not self._esp then self._esp = {} end
    if not self._connections then self._connections = {} end
end

function module:OnEnable()
    self.Enabled = true

    -- отключаем HP‑надписи у уже существующих
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            disableDefaultHumanoidHp(hum)
        end
    end

    -- создаём ESP для уже находящихся
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            if plr.Character then
                createESP(plr)
            else
                local key = "Respawn_" .. tostring(plr.UserId)
                addConnection(key, plr.CharacterAdded:Connect(function(newChar)
                    plr.Character = newChar
                    createESP(plr)
                end))
            end
        end
    end

    -- новые игроки
    addConnection("PlayerAdded", Players.PlayerAdded:Connect(function(plr)
        -- отключаем дефолтный HP, когда появится humanoid
        addConnection("Humanoid_" .. tostring(plr.UserId), plr.CharacterAdded:Connect(function(newChar)
            plr.Character = newChar
            local hum = newChar:FindFirstChildOfClass("Humanoid")
            if hum then
                disableDefaultHumanoidHp(hum)
            end
        end))

        if plr ~= LocalPlayer then
            if plr.Character then
                createESP(plr)
            else
                local key = "Respawn_" .. tostring(plr.UserId)
                addConnection(key, plr.CharacterAdded:Connect(function(newChar)
                    plr.Character = newChar
                    createESP(plr)
                end))
            end
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
    self.Enabled = false

    -- Вернуть стандартные HP над головой для существующих humanoid
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                pcall(function()
                    hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.DisplayWhenDamaged
                end)
            end
        end
    end

    -- снять все ESP
    for plr, data in pairs(self._esp) do
        destroyEspData(data)
        self._esp[plr] = nil
    end

    -- отключить все коннекты
    if type(self._connections) == "table" then
        for key, conn in pairs(self._connections) do
            disconnect(conn)
            self._connections[key] = nil
        end
    end
end

function module:OnTick(dt)
end

return module
