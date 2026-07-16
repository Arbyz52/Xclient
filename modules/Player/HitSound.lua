
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local HitSound = {
    __settings__ = {},
    SettingsDefinitions = {
        { Name = "Громкость", Key = "Volume", Type = "Slider", Min = 0.1, Max = 5, Step = 0.1, Default = 2, Suffix = "x" },
        { Name = "Звук", Key = "SoundId", Type = "Dropdown", Options = {
            "rbxassetid://4817809188",
            "rbxassetid://5911718247",
            "rbxassetid://3432457897",
        }, Default = "rbxassetid://4817809188" },
    },
}

local function playHitSound()
    pcall(function()
        local sound = Instance.new("Sound")
        sound.SoundId = HitSound.__settings__.SoundId or "rbxassetid://4817809188"
        sound.Volume = HitSound.__settings__.Volume or 2
        sound.PlayOnRemove = false
        local parent = workspace.CurrentCamera or workspace
        sound.Parent = parent
        sound:Play()
        game:GetService("Debris"):AddItem(sound, 3)
    end)
end

local _hooked = false
local _original = nil

function HitSound:Init()
    self.__settings__.Volume = self.__settings__.Volume or 2
    self.__settings__.SoundId = self.__settings__.SoundId or "rbxassetid://4817809188"
end

function HitSound:OnEnable()
    print("[Xclient] HitSound ON")

    if not _hooked and hookmetamethod and getnamecallmethod then
        pcall(function()
            _original = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                local method = getnamecallmethod()
                if method == "FireServer" then
                    local args = {...}
                    for _, arg in ipairs(args) do
                        if type(arg) == "string" and (arg:lower():find("hit") or arg:lower():find("damage")) then
                            playHitSound()
                            break
                        end
                    end
                end
                return _original(self, ...)
            end))
            _hooked = true
        end)
    end
end

function HitSound:OnDisable()
    print("[Xclient] HitSound OFF")
end

return HitSound
