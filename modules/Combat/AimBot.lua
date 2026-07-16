
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local AimBot = {
    __settings__ = {},
    SettingsDefinitions = {
        { Name = "Плавность",      Key = "Smoothness", Type = "Slider",   Min = 1,  Max = 20, Step = 1,  Default = 5,  Suffix = "" },
        { Name = "FOV",            Key = "FOV",        Type = "Slider",   Min = 10, Max = 500, Step = 10, Default = 200, Suffix = "" },
        { Name = "Зона",           Key = "TargetPart", Type = "Dropdown", Options = {"Head", "HumanoidRootPart", "UpperTorso"}, Default = "Head" },
        { Name = "Только видимые", Key = "VisCheck",   Type = "Toggle",   Default = true },
        { Name = "Показать FOV",   Key = "ShowFOV",    Type = "Toggle",   Default = false },
    },
}

local connection = nil

function AimBot:Init()
    self.__settings__.Smoothness = self.__settings__.Smoothness or 5
    self.__settings__.FOV = self.__settings__.FOV or 200
    self.__settings__.TargetPart = self.__settings__.TargetPart or "Head"
    self.__settings__.VisCheck = self.__settings__.VisCheck == nil and true or self.__settings__.VisCheck
    self.__settings__.ShowFOV = self.__settings__.ShowFOV or false
end

local function getClosestPlayer()
    local closest = nil
    local minDist = math.huge
    local smoothness = AimBot.__settings__.Smoothness or 5
    local fov = AimBot.__settings__.FOV or 200
    local targetPart = AimBot.__settings__.TargetPart or "Head"
    local visCheck = AimBot.__settings__.VisCheck

    local localChar = LocalPlayer.Character
    if not localChar then return nil end
    local localRoot = localChar:FindFirstChild("HumanoidRootPart")
    if not localRoot then return nil end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local humanoid = char:FindFirstChild("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            local part = char:FindFirstChild(targetPart) or root

            if humanoid and humanoid.Health > 0 and root then
                if visCheck then
                    local rayParams = RaycastParams.new()
                    rayParams.FilterDescendantsInstances = {localChar, char}
                    rayParams.FilterType = Enum.RaycastFilterType.Exclude

                    local origin = Camera.CFrame.Position
                    local direction = (part.Position - origin)
                    local result = Workspace:Raycast(origin, direction, rayParams)
                    if result then continue end
                end

                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local mousePos = UserInputService:GetMouseLocation()
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < fov and dist < minDist then
                        minDist = dist
                        closest = part
                    end
                end
            end
        end
    end

    return closest
end

function AimBot:OnEnable()
    print("[Xclient] AimBot ON")
    connection = RunService.RenderStepped:Connect(function()
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local target = getClosestPlayer()
            if target then
                local smoothness = self.__settings__.Smoothness or 5
                local currentCF = Camera.CFrame
                local targetCF = CFrame.new(currentCF.Position, target.Position)
                Camera.CFrame = currentCF:Lerp(targetCF, 1 / math.max(smoothness, 1))
            end
        end
    end)
end

function AimBot:OnDisable()
    print("[Xclient] AimBot OFF")
    if connection then connection:Disconnect() connection = nil end
end

return AimBot
