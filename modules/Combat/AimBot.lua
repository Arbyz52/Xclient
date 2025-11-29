-- modules/Misc/AimAssist.lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local module = {
    Name     = "AimBot",
    Category = "Combat",
    Enabled  = false,
}

-- ==================== КОНФИГ ====================
local CONFIG = {
    FOV            = 180,
    AimSmoothSpeed = 12,
    HoldKey        = Enum.KeyCode.LeftAlt, -- теперь Alt
    IgnoreTeammates = true,
}

local aimHolding = false

-- ==================== Вспомогательные функции ====================
local function isEnemy(plr)
    if plr == LocalPlayer then return false end
    if not CONFIG.IgnoreTeammates then return true end
    if not LocalPlayer.Team or not plr.Team then return true end
    return plr.Team ~= LocalPlayer.Team
end

local function getHead(char)
    return char and char:FindFirstChild("Head")
end

local function getBestTarget()
    local vp = Camera.ViewportSize
    local center = Vector2.new(vp.X/2, vp.Y/2)
    local bestHead, bestDist
    for _, plr in ipairs(Players:GetPlayers()) do
        if isEnemy(plr) and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local head = getHead(plr.Character)
                if head then
                    local sp = Camera:WorldToViewportPoint(head.Position)
                    if sp.Z > 0 then
                        local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if dist <= CONFIG.FOV and (not bestDist or dist < bestDist) then
                            bestHead, bestDist = head, dist
                        end
                    end
                end
            end
        end
    end
    return bestHead
end

local function aimAt(head, dt)
    if not head then return end
    local desired = CFrame.new(Camera.CFrame.Position, head.Position)
    local t = 1 - math.exp(-CONFIG.AimSmoothSpeed * dt)
    Camera.CFrame = Camera.CFrame:Lerp(desired, math.clamp(t,0,1))
end

-- ==================== Методы модуля ====================
function module:OnEnable()
    self.Enabled = true
    -- бинды
    UserInputService.InputBegan:Connect(function(input,gp)
        if gp then return end
        if input.KeyCode == CONFIG.HoldKey then aimHolding = true end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == CONFIG.HoldKey then aimHolding = false end
    end)
end

function module:OnDisable()
    self.Enabled = false
    aimHolding = false
end

function module:Init()
    -- если нужно что-то подготовить
end

function module:OnTick(dt)
    if not self.Enabled then return end
    if aimHolding then
        local head = getBestTarget()
        aimAt(head, dt)
    end
end

return module
