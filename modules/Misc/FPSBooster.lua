
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Terrain = Workspace.Terrain

local FPSBooster = {
    __settings__ = {},
    SettingsDefinitions = {
        { Name = "Убрать тени",     Key = "Shadows",  Type = "Toggle", Default = true },
        { Name = "Убрать частицы",  Key = "Particles", Type = "Toggle", Default = true },
        { Name = "Убрать воду",     Key = "Water",    Type = "Toggle", Default = false },
    },
}

local connection = nil
local savedQuality = nil

function FPSBooster:Init()
    self.__settings__.Shadows = self.__settings__.Shadows == nil and true or self.__settings__.Shadows
    self.__settings__.Particles = self.__settings__.Particles == nil and true or self.__settings__.Particles
    self.__settings__.Water = self.__settings__.Water or false
end

local function applyOptimizations()
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)

    if FPSBooster.__settings__.Shadows then
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1000000
    end

    -- Remove post effects
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("PostEffect") or v:IsA("Atmosphere") then
            v.Enabled = false
        end
    end

    -- Remove particles and effects from workspace
    if FPSBooster.__settings__.Particles then
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("Explosion") then
                v.Enabled = false
            end
        end
    end

    -- Water
    if FPSBooster.__settings__.Water then
        pcall(function()
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 0
        end)
    end
end

function FPSBooster:OnEnable()
    print("[Xclient] FPSBooster ON")
    pcall(function() savedQuality = settings().Rendering.QualityLevel end)
    applyOptimizations()
end

function FPSBooster:OnDisable()
    print("[Xclient] FPSBooster OFF")
    pcall(function()
        if savedQuality then settings().Rendering.QualityLevel = savedQuality end
    end)
end

return FPSBooster
