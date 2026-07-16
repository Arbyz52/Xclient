
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local GunSound = {
    __settings__ = {},
    SettingsDefinitions = {
        { Name = "Громкость", Key = "Volume", Type = "Slider", Min = 0.1, Max = 3, Step = 0.1, Default = 1.5, Suffix = "x" },
        { Name = "ID звука",  Key = "SoundId", Type = "Dropdown", Options = {
            "rbxassetid://138081500",
            "rbxassetid://138081500",
            "rbxassetid://2927688157",
            "rbxassetid://148880905",
        }, Default = "rbxassetid://138081500" },
    },
}

local connection = nil

function GunSound:Init()
    self.__settings__.Volume = self.__settings__.Volume or 1.5
    self.__settings__.SoundId = self.__settings__.SoundId or "rbxassetid://138081500"
end

function GunSound:OnEnable()
    print("[Xclient] GunSound ON")

    local function hookCharacter(char)
        local humanoid = char:WaitForChild("Humanoid", 10)
        if not humanoid then return end

        -- Find tools in character
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                for _, child in ipairs(tool:GetDescendants()) do
                    if child:IsA("Sound") then
                        child.SoundId = self.__settings__.SoundId or "rbxassetid://138081500"
                        child.Volume = self.__settings__.Volume or 1.5
                    end
                end
            end
        end

        char.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                task.wait(0.1)
                for _, desc in ipairs(child:GetDescendants()) do
                    if desc:IsA("Sound") then
                        desc.SoundId = self.__settings__.SoundId or "rbxassetid://138081500"
                        desc.Volume = self.__settings__.Volume or 1.5
                    end
                end
            end
        end)
    end

    if LocalPlayer.Character then hookCharacter(LocalPlayer.Character) end
    connection = LocalPlayer.CharacterAdded:Connect(hookCharacter)
end

function GunSound:OnDisable()
    print("[Xclient] GunSound OFF")
    if connection then connection:Disconnect() connection = nil end
end

return GunSound
