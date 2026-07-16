
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local GrenadePredictor = {
    __settings__ = {},
    SettingsDefinitions = {
        { Name = "Длина траектории", Key = "Length", Type = "Slider", Min = 10, Max = 100, Step = 5, Default = 50, Suffix = "" },
        { Name = "Показать точки",   Key = "Dots",   Type = "Toggle", Default = true },
    },
}

local connection = nil
local dots = {}

local function clearDots()
    for _, dot in ipairs(dots) do
        pcall(function() dot:Destroy() end)
    end
    dots = {}
end

function GrenadePredictor:Init()
    self.__settings__.Length = self.__settings__.Length or 50
    self.__settings__.Dots = self.__settings__.Dots == nil and true or self.__settings__.Dots
end

function GrenadePredictor:OnEnable()
    print("[Xclient] GrenadePredictor ON")

    connection = RunService.RenderStepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        clearDots()

        local tool = char:FindFirstChildWhichIsA("Tool")
        if not tool then return end
        local handle = tool:FindFirstChild("Handle")
        if not handle then return end

        local startPos = handle.Position
        local lookDir = Workspace.CurrentCamera.CFrame.LookVector
        local velocity = lookDir * 80 + Vector3.new(0, 30, 0)
        local gravity = Vector3.new(0, -Workspace.Gravity, 0)
        local dt = 0.05
        local length = self.__settings__.Length or 50

        local pos = startPos
        local vel = velocity

        for i = 1, length do
            pos = pos + vel * dt + 0.5 * gravity * dt * dt
            vel = vel + gravity * dt

            local hit = Workspace:Raycast(pos - vel * dt, vel * dt)
            if hit then break end

            if self.__settings__.Dots then
                pcall(function()
                    local dot = Instance.new("Part")
                    dot.Size = Vector3.new(0.3, 0.3, 0.3)
                    dot.Shape = Enum.PartType.Ball
                    dot.Position = pos
                    dot.Anchored = true
                    dot.CanCollide = false
                    dot.Material = Enum.Material.Neon
                    dot.Color = Color3.fromRGB(255, 180, 50)
                    dot.Transparency = 0.3
                    dot.Parent = Workspace
                    table.insert(dots, dot)
                end)
            end
        end
    end)
end

function GrenadePredictor:OnDisable()
    print("[Xclient] GrenadePredictor OFF")
    if connection then connection:Disconnect() connection = nil end
    clearDots()
end

return GrenadePredictor
