local module = {
    Name     = "ESP",
    Category = "Visuals",
    Enabled  = false,
}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Цветовая палитра
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

-- Настройки
module._tintColor = palette[Enum.KeyCode.Five]
module._esp = {}
module._connection = nil

-- Создание ESP
local function addESP(player)
    if player == Players.LocalPlayer then return end
    if not player.Character then return end
    if module._esp[player] then return end

    local hl = Instance.new("Highlight")
    hl.Adornee = player.Character
    hl.FillTransparency = 0.5
    hl.OutlineColor = module._tintColor
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = player.Character

    module._esp[player] = hl

    player.CharacterAdded:Connect(function(char)
        hl.Adornee = char
        hl.Parent = char
    end)
end

-- Удаление ESP
local function removeESP(player)
    local hl = module._esp[player]
    if hl then
        hl:Destroy()
        module._esp[player] = nil
    end
end

-- Обновление цвета
function module:RetintAll(color)
    for _, hl in pairs(self._esp) do
        if hl and hl.Parent then
            hl.OutlineColor = color
        end
    end
end

-- Сброс ESP
function module:ResetAll()
    for _, hl in pairs(self._esp) do
        if hl then hl:Destroy() end
    end
    self._esp = {}
end

-- Инициализация
function module:Init()
    print("[ESP] Init")
end

-- Включение
function module:OnEnable()
    print("[ESP] Enabled!")
    self.Enabled = true

    for _, plr in ipairs(Players:GetPlayers()) do
        addESP(plr)
    end

    Players.PlayerAdded:Connect(function(plr)
        plr.CharacterAdded:Connect(function()
            addESP(plr)
        end)
    end)

    Players.PlayerRemoving:Connect(function(plr)
        removeESP(plr)
    end)

    self._connection = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if not self.Enabled then return end

        local newColor = palette[input.KeyCode]
        if newColor then
            self._tintColor = newColor
            self:RetintAll(newColor)
            print("[ESP] Color changed")
        elseif input.KeyCode == Enum.KeyCode.T then
            self:ResetAll()
            print("[ESP] Reset all")
        end
    end)
end

-- Выключение
function module:OnDisable()
    print("[ESP] Disabled!")
    self.Enabled = false

    if self._connection then
        self._connection:Disconnect()
        self._connection = nil
    end

    self:ResetAll()
end

-- Тик (не используется)
function module:OnTick(dt)
end

return module
