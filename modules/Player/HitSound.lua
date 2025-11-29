local module = {
    Name     = "HitSound",
    Category = "Player",
    Enabled  = false,

    _connections = {},
}

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer


local HEAD_ID = "rbxassetid://7567750067" 
local BODY_ID = "rbxassetid://109817519733426" 
local VOL = 3


local SoundFolder = nil
local HeadSound = nil
local BodySound = nil
local lastShootTime = 0


local function disconnect(conn)
    if conn then
        pcall(function() conn:Disconnect() end)
    end
end

local function addConnection(key, conn)
    if not key then return end
    if module._connections[key] then disconnect(module._connections[key]) end
    module._connections[key] = conn
end

local function clearConnections()
    for k, v in pairs(module._connections) do
        disconnect(v)
        module._connections[k] = nil
    end
end


local function IsGunSound(name)
    name = name:lower()
    if name:find("fire") or name:find("shoot") or name:find("reload") or name:find("draw") or name:find("mag") or name:find("bolt") or name:find("pump") then
        return true
    end
    return false
end

local function IsHitSound(name)
    name = name:lower()
    if name:find("head") or name:find("ding") or name:find("hit") or name:find("crit") or name:find("marker") or name:find("helmet") or name:find("impact") then
        return true
    end
    return false
end

local function MuteLogic(obj)

    if not module.Enabled then return end

    if obj:IsA("Sound") then

        if obj.SoundId == HEAD_ID or obj.SoundId == BODY_ID then
            return 
        end


        if obj.Parent and obj.Parent.Name == "HPSounds_Module" then
            return 
        end

        if IsHitSound(obj.Name) and not IsGunSound(obj.Name) then
            obj.Volume = 0
            obj.MaxDistance = 0
            
            if obj.IsPlaying then obj:Stop() end

            local conn = obj:GetPropertyChangedSignal("Volume"):Connect(function()
                if obj.Volume > 0 then obj.Volume = 0 end
            end)

        end
    end
end

local function ScanAndMute()

    for _, v in ipairs(workspace:GetDescendants()) do MuteLogic(v) end
    for _, v in ipairs(SoundService:GetDescendants()) do MuteLogic(v) end
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do MuteLogic(v) end
end


local function SetupSounds()
    if SoundFolder then SoundFolder:Destroy() end
    
    SoundFolder = Instance.new("Folder")
    SoundFolder.Name = "HPSounds_Module"
    SoundFolder.Parent = CoreGui

    HeadSound = Instance.new("Sound")
    HeadSound.SoundId = HEAD_ID
    HeadSound.Volume = VOL
    HeadSound.Parent = SoundFolder

    BodySound = Instance.new("Sound")
    BodySound.SoundId = BODY_ID
    BodySound.Volume = VOL
    BodySound.Parent = SoundFolder
end

local function PlayCustomSound(dmg)
    if not module.Enabled then return end
    
    if dmg > 40 then 
        HeadSound:Play()
        HeadSound.PlaybackSpeed = 1 + (math.random(-5, 5)/100)
    else
        BodySound:Play()
        BodySound.PlaybackSpeed = 1 + (math.random(-5, 5)/100)
    end
end

local function MonitorPlayer(plr)
    if plr == LocalPlayer then return end
    
    local function CharacterAdded(char)
        local hum = char:WaitForChild("Humanoid", 10)
        if not hum then return end
        
        local oldHp = hum.Health
        

        local hpConn = hum.HealthChanged:Connect(function(newHp)
            if not module.Enabled then return end 
            
            if newHp < oldHp then
                local dmg = oldHp - newHp
                
                -- Тайминг 0.5 сек
                if (tick() - lastShootTime) < 0.5 then
                    -- Проверка на врага
                    if LocalPlayer.Team == nil or plr.Team ~= LocalPlayer.Team then
                         PlayCustomSound(dmg)
                    end
                end
            end
            oldHp = newHp
        end)

    end
    
    if plr.Character then CharacterAdded(plr.Character) end

    local respawnConn = plr.CharacterAdded:Connect(CharacterAdded)
    addConnection("Respawn_"..plr.Name, respawnConn)
end



function module:Init()
    self._connections = {}
end

function module:OnEnable()
    self.Enabled = true
    

    SetupSounds()
    

    local inputConn = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            lastShootTime = tick()
        end
    end)
    addConnection("Input", inputConn)
    

    local muteConn = game.DescendantAdded:Connect(MuteLogic)
    addConnection("Muter", muteConn)

    ScanAndMute()

    local playerAddedConn = Players.PlayerAdded:Connect(function(p)
        MonitorPlayer(p)
    end)
    addConnection("PlayerAdded", playerAddedConn)
    
    for _, p in ipairs(Players:GetPlayers()) do
        MonitorPlayer(p)
    end
    
    print("[HitSound] Module Enabled")
end

function module:OnDisable()
    self.Enabled = false
    

    if SoundFolder then 
        SoundFolder:Destroy() 
        SoundFolder = nil
    end
    

    clearConnections()
    
    print("[HitSound] Module Disabled")
end

function module:OnTick(dt) end

return module
