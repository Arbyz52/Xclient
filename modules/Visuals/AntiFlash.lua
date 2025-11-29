-- modules/Visual/AntiFlash.lua
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local module = {
    Name = "AntiFlash",
    Category = "Visual",
    Enabled = false,
}

local conn

local function disableFlash()
    -- Проверяем все GUI у игрока
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        for _, gui in pairs(playerGui:GetDescendants()) do
            if gui:IsA("Frame") or gui:IsA("ImageLabel") then
                if gui.BackgroundColor3 == Color3.new(1,1,1) or gui.ImageColor3 == Color3.new(1,1,1) then
                    gui.Visible = false
                    gui.BackgroundTransparency = 1
                end
            end
        end
    end

    -- Проверяем эффекты в Lighting
    local lighting = game:GetService("Lighting")
    for _, eff in pairs(lighting:GetChildren()) do
        if eff:IsA("ColorCorrectionEffect") or eff:IsA("BlurEffect") then
            eff.Enabled = false
        end
    end
end

function module:OnEnable()
    self.Enabled = true
    print("[Module] AntiFlash Enabled")

    -- Цикл проверки каждые кадры
    conn = game:GetService("RunService").RenderStepped:Connect(function()
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
