-- modules/Visuals/AntiFlash.lua

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local module = {
    Name = "AntiFlash",
    Category = "Visuals",
    Enabled = false,
}

local conn

local function disableFlash()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        for _, gui in pairs(playerGui:GetDescendants()) do
            if gui:IsA("Frame") then
                -- Проверка на белый экран
                if gui.BackgroundColor3 == Color3.new(1, 1, 1) then
                    gui.Visible = false
                    gui.BackgroundTransparency = 1
                end
            elseif gui:IsA("ImageLabel") then
                if gui.ImageColor3 == Color3.new(1, 1, 1) then
                    gui.Visible = false
                    gui.ImageTransparency = 1
                end
            end
        end
    end

    -- Убираем пост-эффекты
    for _, eff in pairs(Lighting:GetChildren()) do
        if eff:IsA("ColorCorrectionEffect") or eff:IsA("BlurEffect") then
            eff.Enabled = false
        end
    end
end

function module:OnEnable()
    self.Enabled = true
    print("[Module] AntiFlash Enabled")

    conn = RunService.RenderStepped:Connect(function()
        if not self.Enabled then return end
        disableFlash()
    end)
end

function module:OnDisable()
    self.Enabled = false
    print("[Module] AntiFlash Disabled")
    if conn then conn:Disconnect() conn = nil end
end

function module:Init() end
function module:OnTick(dt) end

return module
