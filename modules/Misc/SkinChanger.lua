
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local SkinChanger = {
    __settings__ = {},
    SettingsDefinitions = {
        { Name = "Цвет шляпы", Key = "HatColor", Type = "Dropdown", Options = {"Красный", "Синий", "Зелёный", "Чёрный", "Белый", "Розовый"}, Default = "Синий" },
    },
}

local colorMap = {
    ["Красный"]  = Color3.fromRGB(200, 50, 50),
    ["Синий"]    = Color3.fromRGB(50, 100, 220),
    ["Зелёный"]  = Color3.fromRGB(50, 200, 80),
    ["Чёрный"]   = Color3.fromRGB(30, 30, 30),
    ["Белый"]    = Color3.fromRGB(240, 240, 240),
    ["Розовый"]  = Color3.fromRGB(255, 120, 200),
}

local originalColors = {}
local connection = nil

local function saveColors(char)
    originalColors = {}
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("ShirtGraphic") or part:IsA("Shirt") or part:IsA("Pants") then
            originalColors[part] = part:Clone()
        end
        if part:IsA("BodyColors") then
            originalColors[part] = part:Clone()
        end
    end
end

local function applySkin(char)
    local colorKey = SkinChanger.__settings__.HatColor or "Синий"
    local color = colorMap[colorKey] or Color3.fromRGB(50, 100, 220)

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("Accessory") then
            local handle = part:FindFirstChild("Handle")
            if handle and handle:IsA("BasePart") then
                handle.Color = color
            end
        end
        if part:IsA("BodyColors") then
            part.HeadColor3 = color
            part.LeftArmColor3 = color
            part.RightArmColor3 = color
            part.TorsoColor3 = color
        end
    end
end

function SkinChanger:Init()
    self.__settings__.HatColor = self.__settings__.HatColor or "Синий"
end

function SkinChanger:OnEnable()
    print("[Xclient] SkinChanger ON")

    local char = LocalPlayer.Character
    if char then
        saveColors(char)
        applySkin(char)
    end

    connection = LocalPlayer.CharacterAdded:Connect(function(newChar)
        task.wait(0.5)
        saveColors(newChar)
        applySkin(newChar)
    end)
end

function SkinChanger:OnDisable()
    print("[Xclient] SkinChanger OFF")
    if connection then connection:Disconnect() connection = nil end

    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        for part, clone in pairs(originalColors) do
            if part and part.Parent then
                pcall(function()
                    part:Destroy()
                    clone.Parent = char
                end)
            end
        end
    end)
    originalColors = {}
end

return SkinChanger
