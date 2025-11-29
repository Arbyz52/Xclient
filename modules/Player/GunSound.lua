local module = {
    Name     = "GunSound",
    Category = "Visuals",
    Enabled  = false,
    _connections = {}
}

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer

local MY_SOUND = "rbxassetid://5852470908"
local VOL = 5 


local function IsEnemySound(sound)

    if sound:IsDescendantOf(Workspace.CurrentCamera) then
        return false 
    end


    if LP.Character and sound:IsDescendantOf(LP.Character) then
        return false 
    end


    local parent = sound.Parent
    while parent do
        if parent == game or parent == Workspace then break end

        if parent:IsA("Model") and parent:FindFirstChild("Humanoid") then
            if parent.Name ~= LP.Name then
                return true 
            end
        end
        parent = parent.Parent
    end

    return false 
end

local function ForceSound(sound)

    if not module.Enabled then return end
    

    if sound.SoundId == MY_SOUND then return end


    if IsEnemySound(sound) then return end


    sound.SoundId = MY_SOUND
    sound.Volume = VOL
    

end

local function Check(obj)

    if not module.Enabled then return end

    if obj:IsA("Sound") then
        local name = obj.Name:lower()
        

        if name:find("fire") or name:find("shoot") or name:find("shot") or name:find("blast") or name:find("bang") or name:find("release") then
            
  
            if name:find("hit") or name:find("head") or name:find("marker") then return end


            ForceSound(obj)
            

            local conn = obj:GetPropertyChangedSignal("SoundId"):Connect(function()
                if module.Enabled and obj.SoundId ~= MY_SOUND then
                    ForceSound(obj)
                end
            end)

        end
    end
end


function module:Init()
    self._connections = {}
end

function module:OnEnable()
    self.Enabled = true


    for _, v in ipairs(Workspace:GetDescendants()) do
        Check(v)
    end


    local conn = game.DescendantAdded:Connect(function(obj)
        Check(obj)
    end)
    

    table.insert(module._connections, conn)
end

function module:OnDisable()
    self.Enabled = false

    

    for _, conn in pairs(module._connections) do
        conn:Disconnect()
    end
    module._connections = {}
end

function module:OnTick(dt) end

return module
