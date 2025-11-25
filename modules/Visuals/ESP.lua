local module = {
    Name     = "ESP",
    Category = "Visuals",
    Enabled  = false,
}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Цвета 1–9
local palette = {
    [Enum.KeyCode.One]   = Color3.fromRGB(255, 70, 70),
    [Enum.KeyCode.Two]   = Color3.fromRGB(255, 150, 0),
    [Enum.KeyCode.Three] = Color3.fromRGB(255, 230, 0),
    [Enum.KeyCode.Four]  = Color3.fromRGB(0, 200, 0),
    [Enum.KeyCode.Five]  = Color3.fromRGB(0, 190, 255),
    [Enum.KeyCode.Six]   = Color3.fromRGB(85, 110, 255),
    [Enum.KeyCode.Seven] = Color3.fromRGB(170, 0, 255),
    [Enum.KeyCode.Eight] = Color3.fromRGB(255, 0, 200),
    [Enum.KeyCode.Nine]  = Color3.fromRGB(255, 255, 255),
}

-- Состояние
module._tintColor = palette[Enum.KeyCode.Five]
module._esp = {}
module._connection = nil

-- Создать ESP для игрока
local function addESP(player, color)
    if player == Players.LocalPlayer then return end
    if not player.Character then return end
    if module._esp[player] then return end

    local hl = Instance.new("Highlight")
    hl.Adornee = player.Character
    hl.FillTransparency = 0.7
    hl.OutlineColor = color
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = player.Character

    module._esp[player] = hl

    -- При респавне перепривязываем
    player.CharacterAdded:Connect(function(char)
        hl.Adornee = char
        hl.Parent = char
    end)
end

-- Удалить ESP
local function removeESP(player)
    local hl = module._esp[player]
    if hl then
        hl:Destroy()
        module._esp[player] = nil
    end
end

-- Перекрасить все ESP
function module:RetintAll(color)
    for _, hl in pairs(self._esp) do
        if hl and hl.Parent then
            hl.OutlineColor = color
        end
    end
end

-- Сбросить все ESP
function module:ResetAll()
    for plr, hl in pairs(self._esp) do
        if hl then hl:Destroy() end
    end
    self._esp = {}
end

function module:Init()
    print("[ESP] Init")
end

function module:OnEnable()
    print("[ESP] Enabled!")
    self.Enabled = true

    -- Создать ESP для всех игроков
    for _, plr in ipairs(Players:GetPlayers()) do
        addESP(plr, self._tintColor)
    end

    -- Новые игроки
    Players.PlayerAdded:Connect(function(plr)
        addESP(plr, self._tintColor)
    end)

    -- Обработка клавиш
    self._connection = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if not self.Enabled then return end

        local newColor = palette[input.KeyCode]
        if newColor then
            self._tintColor = newColor
            self:RetintAll(newColor)
            print("[ESP] Color changed")
            return
        end

        if input.KeyCode == Enum.KeyCode.T then
            self:ResetAll()
            print("[ESP] Reset all")
            return
        end
    end)
end

function module:OnDisable()
    print("[ESP] Disabled!")
    self.Enabled = false

    if self._connection then
        self._connection:Disconnect()
        self._connection = nil
    end

    self:ResetAll()
end

function module:OnTick(dt)
    -- Не используется
end

return module
