
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local TriggerBot = {
    __settings__ = {},
    SettingsDefinitions = {
        { Name = "Задержка (мс)", Key = "Delay",    Type = "Slider", Min = 0, Max = 200, Step = 10, Default = 50,  Suffix = "мс" },
        { Name = "FOV",           Key = "FOV",      Type = "Slider", Min = 1, Max = 100, Step = 1,  Default = 20,  Suffix = "" },
        { Name = "Только враги",  Key = "Enemies",  Type = "Toggle", Default = true },
    },
}

local connection = nil
local lastShot = 0

function TriggerBot:Init()
    self.__settings__.Delay = self.__settings__.Delay or 50
    self.__settings__.FOV = self.__settings__.FOV or 20
    self.__settings__.Enemies = self.__settings__.Enemies == nil and true or self.__settings__.Enemies
end

local function isEnemy(player)
    if not TriggerBot.__settings__.Enemies then return true end
    if player.Team and LocalPlayer.Team then
        return player.Team ~= LocalPlayer.Team
    end
    return true
end

function TriggerBot:OnEnable()
    print("[Xclient] TriggerBot ON")
    local mouse = LocalPlayer:GetMouse()

    connection = RunService.RenderStepped:Connect(function()
        local now = tick() * 1000
        local delay = self.__settings__.Delay or 50
        if now - lastShot < delay then return end

        local target = mouse.Target
        if target then
            local char = target:FindFirstAncestorOfClass("Model")
            if char then
                local player = Players:GetPlayerFromCharacter(char)
                if player and player ~= LocalPlayer and isEnemy(player) then
                    local humanoid = char:FindFirstChild("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        -- Simulate click
                        mouse1press()
                        task.wait(0.01)
                        mouse1release()
                        lastShot = now
                    end
                end
            end
        end
    end)
end

function TriggerBot:OnDisable()
    print("[Xclient] TriggerBot OFF")
    if connection then connection:Disconnect() connection = nil end
end

return TriggerBot
