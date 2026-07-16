
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local NoFog = {
    __settings__ = {},
    SettingsDefinitions = {},
}

local connection = nil
local savedFog = {}

local function saveFog()
    savedFog.FogStart = Lighting.FogStart
    savedFog.FogEnd = Lighting.FogEnd
    savedFog.FogColor = Lighting.FogColor
end

local function restoreFog()
    for k, v in pairs(savedFog) do
        pcall(function() Lighting[k] = v end)
    end
end

function NoFog:OnEnable()
    print("[Xclient] NoFog ON")
    saveFog()

    connection = RunService.Heartbeat:Connect(function()
        Lighting.FogStart = 0
        Lighting.FogEnd = 1000000
        Lighting.FogColor = Color3.new(1, 1, 1)

        -- Disable Atmosphere
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("Atmosphere") then
                v.Density = 0
                v.Haze = 0
            end
        end
    end)
end

function NoFog:OnDisable()
    print("[Xclient] NoFog OFF")
    if connection then connection:Disconnect() connection = nil end
    restoreFog()
end

return NoFog
