
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local FullBright = {
    __settings__ = {},
    SettingsDefinitions = {
        { Name = "Яркость", Key = "Brightness", Type = "Slider", Min = 1, Max = 10, Step = 1, Default = 3, Suffix = "" },
    },
}

local connection = nil
local savedSettings = {}

local function saveLighting()
    savedSettings.Brightness = Lighting.Brightness
    savedSettings.Ambient = Lighting.Ambient
    savedSettings.OutdoorAmbient = Lighting.OutdoorAmbient
    savedSettings.FogEnd = Lighting.FogEnd
    savedSettings.GlobalShadows = Lighting.GlobalShadows
    pcall(function() savedSettings.ClockTime = Lighting.ClockTime end)
end

local function restoreLighting()
    for k, v in pairs(savedSettings) do
        pcall(function() Lighting[k] = v end)
    end
end

function FullBright:Init()
    self.__settings__.Brightness = self.__settings__.Brightness or 3
end

function FullBright:OnEnable()
    print("[Xclient] FullBright ON")
    saveLighting()

    connection = RunService.Heartbeat:Connect(function()
        local br = self.__settings__.Brightness or 3
        Lighting.Brightness = br
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        pcall(function() Lighting.ClockTime = 14 end)

        -- Remove atmosphere and bloom
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("Atmosphere") or v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") then
                v.Enabled = false
            end
        end
    end)
end

function FullBright:OnDisable()
    print("[Xclient] FullBright OFF")
    if connection then connection:Disconnect() connection = nil end
    restoreLighting()
end

return FullBright
