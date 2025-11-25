local module = {
    Name     = "ESP",
    Category = "Visuals",
    Enabled  = false,
}

local UserInputService = game:GetService("UserInputService")
local camera = workspace.CurrentCamera

-- Горячие клавиши
local KEY_TOGGLE = Enum.KeyCode.F
local KEY_PREV   = Enum.KeyCode.Z
local KEY_NEXT   = Enum.KeyCode.X
local KEY_NEON   = Enum.KeyCode.N
local KEY_RESET  = Enum.KeyCode.T

-- Цвета 1–9
local palette = {
    [Enum.KeyCode.One]   = Color3.fromRGB(255, 70, 70),
    [Enum.KeyCode.Two]   = Color3.fromRGB(255, 150, 0),
    [Enum.KeyCode.Three] = Color3.fromRGB(255, 230, 0),
    [Enum.KeyCode.Four]  = Color3.fromRGB(0, 200, 0),
    [Enum.KeyCode.Five]  = Color3.fromRGB(0, 190, 255),
    [Enum.KeyCode.Six]   = Color3.fromRGB(85, 110, 255),
    [Enum.KeyCode.Seven] = Color3.fromRGB(170, 0, 255),
    [Enum.KeyCode.Eight] = Color3.fromRGB(255, 0, 200),
    [Enum.KeyCode.Nine]  = Color3.fromRGB(255, 255, 255),
}

-- Состояние модуля
module._tintColor = palette[Enum.KeyCode.Five]
module._useNeon = true
module._candidates = {}
module._idx = 1
module._tinted = {}
module._connection = nil

-- Слова для определения рук (исключаем)
local ARM_KEYS = {
    "arm","arms","hand","hands","glove","sleeve","finger","thumb","palm",
    "forearm","upperarm","wrist","larm","rarm","l_hand","r_hand","lh","rh"
}

-- Слова для определения оружия (выбираем)
local WEP_KEYS = {
    "gun","wep","weapon","pistol","rifle","smg","shotgun","sniper",
    "slide","barrel","mag","magazine","receiver","bolt","trigger","sight",
    "scope","muzzle","suppressor","silencer","stock","grip","glock","usp","px4","deagle","awp","ak","m4"
}

local function containsKey(name, keys)
    name = string.lower(name or "")
    for _, k in ipairs(keys) do
        if string.find(name, k, 1, true) then return true end
    end
    return false
end

local function topRootUnderCamera(inst)
    local cur, lastModel = inst, nil
    while cur and cur ~= camera do
        if cur:IsA("Model") then lastModel = cur end
        cur = cur.Parent
    end
    return lastModel or inst
end

local function collectGroups()
    local groups = {}
    local list = {}

    for _, d in ipairs(camera:GetDescendants()) do
        if d:IsA("BasePart") then
            local root = topRootUnderCamera(d)
            if not groups[root] then
                groups[root] = {root = root, parts = {}}
                table.insert(list, groups[root])
            end
            table.insert(groups[root].parts, d)
        end
    end

    local filtered = {}
    for _, g in ipairs(list) do
        if #g.parts > 0 then table.insert(filtered, g) end
    end
    return filtered
end

local function scoreGroup(g)
    local rName = g.root.Name or ""
    local armHitsRoot = containsKey(rName, ARM_KEYS) and 2 or 0
    local wepHitsRoot = containsKey(rName, WEP_KEYS) and 3 or 0

    local armHits, wepHits = 0, 0
    local meshCount = 0

    for _, p in ipairs(g.parts) do
        local n = p.Name or ""
        if containsKey(n, ARM_KEYS) then armHits = armHits + 1 end
        if containsKey(n, WEP_KEYS) then wepHits = wepHits + 1 end
        if p:IsA("MeshPart") then meshCount = meshCount + 1 end
    end

    local score = wepHitsRoot + wepHits * 1.5 + meshCount * 0.1 - (armHitsRoot + armHits * 1.2)
    score = score + #g.parts * 0.02
    return score
end

local function buildCandidates()
    local groups = collectGroups()
    table.sort(groups, function(a, b) return scoreGroup(a) > scoreGroup(b) end)

    local filtered, hasNonArm = {}, false
    for _, g in ipairs(groups) do
        local armish = containsKey(g.root.Name, ARM_KEYS)
        if not armish then hasNonArm = true end
        table.insert(filtered, g)
    end

    if hasNonArm then
        local onlyNonArm = {}
        for _, g in ipairs(filtered) do
            if not containsKey(g.root.Name, ARM_KEYS) then
                table.insert(onlyNonArm, g)
            end
        end
        if #onlyNonArm > 0 then return onlyNonArm end
    end
    return filtered
end

function module:TintRoot(root, color, neon)
    local data = self._tinted[root]
    if data then
        -- Восстановить оригинал
        for sa, parent in pairs(data.removedSA) do
            if sa then sa.Parent = parent end
        end
        for inst, info in pairs(data.removedDecals) do
            if inst and inst.Parent then
                pcall(function()
                    inst.Color3 = info.Color3
                    inst.Transparency = info.Transparency
                end)
            end
        end
        for part, texId in pairs(data.meshTex) do
            if part and part.Parent and part:IsA("MeshPart") then
                pcall(function() part.TextureID = texId end)
            end
        end
        for mesh, texId in pairs(data.specTex) do
            if mesh and mesh.Parent then
                pcall(function() mesh.TextureId = texId end)
            end
        end
        for part, orig in pairs(data.orig) do
            if part and part.Parent then
                pcall(function()
                    part.Color = orig.Color
                    part.Material = orig.Material
                end)
            end
        end
        self._tinted[root] = nil
        return
    end

    -- Включить покраску
    local parts = {}
    if root:IsA("BasePart") then table.insert(parts, root) end
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("BasePart") then table.insert(parts, d) end
    end
    if #parts == 0 then return end

    local pack = {
        parts = parts,
        orig = {},
        removedSA = {},
        removedDecals = {},
        meshTex = {},
        specTex = {},
        neon = neon
    }

    for _, p in ipairs(parts) do
        pack.orig[p] = {Color = p.Color, Material = p.Material}

        for _, ch in ipairs(p:GetChildren()) do
            if ch:IsA("SurfaceAppearance") then
                pack.removedSA[ch] = ch.Parent
                ch.Parent = nil
            elseif ch:IsA("Decal") or ch:IsA("Texture") then
                pack.removedDecals[ch] = {Color3 = ch.Color3, Transparency = ch.Transparency}
                ch.Transparency = 1
            elseif ch:IsA("SpecialMesh") then
                pack.specTex[ch] = ch.TextureId
                ch.TextureId = ""
            end
        end

        if p:IsA("MeshPart") and p.TextureID ~= "" then
            pack.meshTex[p] = p.TextureID
            p.TextureID = ""
        end

        pcall(function()
            p.Color = color
            p.Material = neon and Enum.Material.Neon or pack.orig[p].Material
        end)
    end

    self._tinted[root] = pack
end

function module:ResetAll()
    for root in pairs(self._tinted) do
        self:TintRoot(root)
    end
end

function module:RetintAll(color, neon)
    for root, data in pairs(self._tinted) do
        for _, p in ipairs(data.parts) do
            if p and p.Parent then
                pcall(function()
                    p.Color = color
                    p.Material = neon and Enum.Material.Neon or data.orig[p].Material
                end)
            end
        end
        data.neon = neon
    end
end

function module:RefreshCandidates()
    self._candidates = buildCandidates()
    if #self._candidates == 0 then
        self._idx = 1
    else
        self._idx = math.clamp(self._idx, 1, #self._candidates)
    end
end

function module:StepCandidate(dir)
    if #self._candidates == 0 then self:RefreshCandidates() end
    if #self._candidates == 0 then return end
    
    self._idx = self._idx + dir
    if self._idx < 1 then self._idx = #self._candidates end
    if self._idx > #self._candidates then self._idx = 1 end
end

function module:Init()
    print("[GunChams] Init")
end

function module:OnEnable()
    print("[GunChams] Enabled!")
    self.Enabled = true

    self._connection = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if not self.Enabled then return end

        if input.KeyCode == KEY_TOGGLE then
            self:RefreshCandidates()
            local g = self._candidates[self._idx]
            if g then self:TintRoot(g.root, self._tintColor, self._useNeon) end
            return
        end

        if input.KeyCode == KEY_PREV then
            self:RefreshCandidates()
            self:StepCandidate(-1)
            print("[GunChams] Candidate:", self._idx)
            return
        end

        if input.KeyCode == KEY_NEXT then
            self:RefreshCandidates()
            self:StepCandidate(1)
            print("[GunChams] Candidate:", self._idx)
            return
        end

        if input.KeyCode == KEY_NEON then
            self._useNeon = not self._useNeon
            self:RetintAll(self._tintColor, self._useNeon)
            print("[GunChams] Neon:", self._useNeon)
            return
        end

        if input.KeyCode == KEY_RESET then
            self:ResetAll()
            print("[GunChams] Reset all")
            return
        end

        local newColor = palette[input.KeyCode]
        if newColor then
            self._tintColor = newColor
            self:RetintAll(self._tintColor, self._useNeon)
            print("[GunChams] Color changed")
            return
        end
    end)
end

function module:OnDisable()
    print("[GunChams] Disabled!")
    self.Enabled = false

    -- Отключаем обработчик клавиш
    if self._connection then
        self._connection:Disconnect()
        self._connection = nil
    end

    -- Сбрасываем все покраски
    self:ResetAll()
end

function module:OnTick(dt)
    -- Не используется
end

return module
