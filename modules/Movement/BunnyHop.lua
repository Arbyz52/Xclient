-- modules/Movement/BunnyHop.lua
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local module = {
    Name     = "BunnyHop",
    Category = "Movement",
    Enabled  = false,
}

local holdingSpace = false

-- ==================== Методы ====================
function module:OnEnable()
    self.Enabled = true
    -- отслеживаем пробел
    UserInputService.InputBegan:Connect(function(input,gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.Space then
            holdingSpace = true
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.Space then
            holdingSpace = false
        end
    end)
end

function module:OnDisable()
    self.Enabled = false
    holdingSpace = false
end

function module:OnTick(dt)
    if not self.Enabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    -- если держим пробел и стоим на земле
    if holdingSpace and hum.FloorMaterial ~= Enum.Material.Air then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)

        -- сохраняем горизонтальную скорость
        local vel = hrp.Velocity
        hrp.Velocity = Vector3.new(vel.X, hrp.Velocity.Y, vel.Z)
    end
end

return module
