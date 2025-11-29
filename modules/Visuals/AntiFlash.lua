-- modules/Visuals/AntiFlash.lua

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local module = {
    Name = "AntiFlash",
    Category = "Visuals",
    Enabled = false,
}

local conn
local hooked = {}

local function hardBlock(gui)
    if gui:IsA("Frame") or gui:IsA("ImageLabel") then
        -- Принудительно убираем белый экран
        gui.Visible = false
        if gui:IsA("Frame") then
            gui.BackgroundTransparency = 1
        elseif gui:IsA("ImageLabel") then
            gui.ImageTransparency = 1
        end

        -- Перехватываем изменения
        if not hooked[gui] then
            hooked[gui] = true
            gui:GetPropertyChangedSignal("Visible"):Connect(function()
                gui.Visible = false
            end)
            gui:GetPropertyChangedSignal("BackgroundTransparency"):Connect(function()
                gui.BackgroundTransparency = 1
            end)
            gui:GetPropertyChangedSignal("ImageTransparency"):Connect(function()
                gui.ImageTransparency = 1
            end)
        end
    end
end

local function disableFlash()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        for _, gui in pairs(playerGui:GetDescendants()) do
            if gui:IsA("Frame") and gui.BackgroundColor3 == Color3.new(1,1,1) then
                hardBlock(gui)
            elseif gui:IsA("ImageLabel") and gui.ImageColor3 == Color3.new(1,1,1) then
                hardBlock(gui)
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

-- Блокируем TweenService:Create чтобы флеш не мог плавно появиться
local oldCreate = TweenService.Create
local function fakeTween(self, target, info, props)
    if props and (props.BackgroundTransparency == 0 or props.ImageTransparency == 0 or props.Visible == true) then
        props.BackgroundTransparency = 1
        props.ImageTransparency = 1
        props.Visible = false
    end
    return oldCreate(self, target, info, props)
end

function module:OnEnable()
    self.Enabled = true
    print("[Module] AntiFlash v2 Enabled")

    -- Hook TweenService
    TweenService.Create = fakeTween

    conn = RunService.RenderStepped:Connect(function()
        if not self.Enabled then return end
        disableFlash()
    end)
end

function module:OnDisable()
    self.Enabled = false
    print("[Module] AntiFlash v2 Disabled")

    TweenService.Create = oldCreate

    if conn then conn:Disconnect() conn = nil end
    hooked = {}
end

function module:Init() end
function module:OnTick(dt) end

return module
