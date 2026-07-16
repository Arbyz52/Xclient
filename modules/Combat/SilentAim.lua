
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local SilentAim = {
    __settings__ = {},
    SettingsDefinitions = {
        { Name = "FOV",          Key = "FOV",        Type = "Slider",   Min = 10, Max = 600, Step = 10, Default = 300, Suffix = "" },
        { Name = "Зона",         Key = "TargetPart", Type = "Dropdown", Options = {"Head", "HumanoidRootPart", "UpperTorso"}, Default = "Head" },
        { Name = "Только видимые", Key = "VisCheck", Type = "Toggle",   Default = true },
        { Name = "Показать FOV", Key = "ShowFOV",    Type = "Toggle",   Default = false },
    },
}

local _hooked = false
local _originalIndex = nil
local _fovCircle = nil
local _fovConnection = nil

function SilentAim:Init()
    self.__settings__.FOV = self.__settings__.FOV or 300
    self.__settings__.TargetPart = self.__settings__.TargetPart or "Head"
    self.__settings__.VisCheck = self.__settings__.VisCheck == nil and true or self.__settings__.VisCheck
    self.__settings__.ShowFOV = self.__settings__.ShowFOV or false
end

local function getClosestPart()
    local closest = nil
    local minDist = math.huge
    local fov = SilentAim.__settings__.FOV or 300
    local targetPartName = SilentAim.__settings__.TargetPart or "Head"
    local visCheck = SilentAim.__settings__.VisCheck

    local localChar = LocalPlayer.Character
    if not localChar then return nil end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local humanoid = char:FindFirstChild("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            local part = char:FindFirstChild(targetPartName) or root

            if humanoid and humanoid.Health > 0 and root then
                if visCheck then
                    local rayParams = RaycastParams.new()
                    rayParams.FilterDescendantsInstances = {localChar}
                    rayParams.FilterType = Enum.RaycastFilterType.Exclude
                    local origin = Camera.CFrame.Position
                    local result = Workspace:Raycast(origin, (part.Position - origin), rayParams)
                    if result then continue end
                end

                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local mousePos = game:GetService("UserInputService"):GetMouseLocation()
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

function SilentAim:OnEnable()
    print("[Xclient] SilentAim ON")

    -- FOV circle
    if self.__settings__.ShowFOV then
        pcall(function()
            local gui = Instance.new("ScreenGui")
            gui.Name = "SilentAimFOV"
            gui.ResetOnSpawn = false
            local parent = game:GetService("CoreGui")
            pcall(function() if gethui then parent = gethui() end end)
            gui.Parent = parent

            local circle = Instance.new("Frame")
            circle.Size = UDim2.new(0, self.__settings__.FOV * 2, 0, self.__settings__.FOV * 2)
            circle.AnchorPoint = Vector2.new(0.5, 0.5)
            circle.BackgroundTransparency = 1
            circle.Parent = gui

            local stroke = Instance.new("UIStroke", circle)
            stroke.Color = Color3.fromRGB(255, 80, 80)
            stroke.Thickness = 1.5
            stroke.Transparency = 0.4

            local corner = Instance.new("UICorner", circle)
            corner.CornerRadius = UDim.new(1, 0)

            _fovCircle = { gui = gui, circle = circle }

            if _fovConnection then _fovConnection:Disconnect() end
            _fovConnection = RunService.RenderStepped:Connect(function()
                if _fovCircle and _fovCircle.circle then
                    local mousePos = game:GetService("UserInputService"):GetMouseLocation()
                    _fovCircle.circle.Position = UDim2.new(0, mousePos.X - self.__settings__.FOV, 0, mousePos.Y - self.__settings__.FOV)
                    _fovCircle.circle.Size = UDim2.new(0, self.__settings__.FOV * 2, 0, self.__settings__.FOV * 2)
                end
            end)
        end)
    end

    -- Hook namecall for silent aim
    if not _hooked and hookmetamethod and getnamecallmethod then
        pcall(function()
            _originalIndex = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                local method = getnamecallmethod()
                if method == "FindPartOnRayWithWhitelist" or method == "FindPartOnRayWithIgnoreList" or method == "Raycast" then
                    local target = getClosestPart()
                    if target and method == "Raycast" then
                        local args = {...}
                        if #args >= 2 then
                            args[2] = (target.Position - args[1]).Unit * 1000
                            return _originalIndex(self, unpack(args))
                        end
                    end
                end
                return _originalIndex(self, ...)
            end))
            _hooked = true
        end)
    end
end

function SilentAim:OnDisable()
    print("[Xclient] SilentAim OFF")
    if _fovConnection then _fovConnection:Disconnect() _fovConnection = nil end
    if _fovCircle and _fovCircle.gui then
        pcall(function() _fovCircle.gui:Destroy() end)
        _fovCircle = nil
    end
end

return SilentAim
