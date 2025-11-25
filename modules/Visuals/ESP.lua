-- Красим только пистолет из вид-модели (CurrentCamera).
-- Без прицеливания: авто-поиск "оружейной" модели, руки игнорируем.
-- F: вкл/выкл, Z/X: переключить кандидата, 1–9: цвет, N: Neon, T: сброс.
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
local tintColor = palette[Enum.KeyCode.Five]
local useNeon = true

-- Слова, по которым считаем, что это РУКИ (исключаем)
local ARM_KEYS = {
    "arm","arms","hand","hands","glove","sleeve","finger","thumb","palm",
    "forearm","upperarm","wrist","larm","rarm","l_hand","r_hand","lh","rh"
}
-- Слова, по которым считаем, что это ОРУЖИЕ (выбираем)
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

-- Находим "корень" (верхнюю Model под камерой) для части
local function topRootUnderCamera(inst)
    local cur, lastModel = inst, nil
    while cur and cur ~= camera do
        if cur:IsA("Model") then lastModel = cur end
        cur = cur.Parent
    end
    return lastModel or inst
end

-- Группируем все BasePart внутри камеры по корневым моделям
local function collectGroups()
    local groups = {}         -- { root1 = {parts = {...}}, root2 = {...} }
    local list = {}           -- массив для упорядоченного обхода
    local seen = {}

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

    -- Уберём бессодержательные (вдруг попадутся пустышки)
    local filtered = {}
    for _, g in ipairs(list) do
        if #g.parts > 0 then table.insert(filtered, g) end
    end
    return filtered
end

-- Оценка группы: пытаемся угадать оружие, а не руки
local function scoreGroup(g)
    local rName = g.root.Name or ""
    local armHitsRoot  = containsKey(rName, ARM_KEYS) and 2 or 0
    local wepHitsRoot  = containsKey(rName, WEP_KEYS) and 3 or 0

    local armHits, wepHits = 0, 0
    local meshCount = 0

    for _, p in ipairs(g.parts) do
        local n = p.Name or ""
        if containsKey(n, ARM_KEYS) then armHits += 1 end
        if containsKey(n, WEP_KEYS) then wepHits += 1 end
        if p:IsA("MeshPart") then meshCount += 1 end
    end

    -- Простая формула: плюс за оружие, минус за руки, небольшой плюс за детали
    local score = wepHitsRoot + wepHits*1.5 + meshCount*0.1 - (armHitsRoot + armHits*1.2)
    -- Крохотный бонус большим моделям
    score += #g.parts * 0.02
    return score
end

-- Выбираем кандидатов и сортируем по оценке (сначала самые "похожи" на оружие)
local function buildCandidates()
    local groups = collectGroups()
    table.sort(groups, function(a,b) return scoreGroup(a) > scoreGroup(b) end)

    -- Отфильтровываем явные руки сверху списка (если есть явный не-руки)
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

-- Хранилище покраски
local tinted = {}  -- [root] = {parts, orig = {}, removedSA = {}, removedDecals = {}, meshTex = {}, specTex = {}, neon = bool}

local function tintRoot(root, color, neon)
    local data = tinted[root]
    if data then
        -- восстановить
        for sa, parent in pairs(data.removedSA) do if sa then sa.Parent = parent end end
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
        tinted[root] = nil
        return
    end

    -- включить
    local parts = {}
    if root:IsA("BasePart") then table.insert(parts, root) end
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("BasePart") then table.insert(parts, d) end
    end
    if #parts == 0 then return end

    local pack = {parts = parts, orig = {}, removedSA = {}, removedDecals = {}, meshTex = {}, specTex = {}, neon = neon}
    for _, p in ipairs(parts) do
        pack.orig[p] = {Color = p.Color, Material = p.Material}

        -- SurfaceAppearance скрываем
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
    tinted[root] = pack
end

local function resetAll()
    for root in pairs(tinted) do
        tintRoot(root) -- повторный вызов вернет всё назад
    end
end

local function retintAll(color, neon)
    for root, data in pairs(tinted) do
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

-- Кандидаты под камерой и выбранный индекс
local candidates, idx = {}, 1
local function refreshCandidates()
    candidates = buildCandidates()
    if #candidates == 0 then idx = 1 else idx = math.clamp(idx, 1, #candidates) end
end

-- Выбор следующего/предыдущего кандидата
local function stepCandidate(dir)
    if #candidates == 0 then refreshCandidates() end
    if #candidates == 0 then return end
    idx += dir
    if idx < 1 then idx = #candidates end
    if idx > #candidates then idx = 1 end
end

-- Управление
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end

    if input.KeyCode == KEY_TOGGLE then
        refreshCandidates()
        local g = candidates[idx]
        if g then tintRoot(g.root, tintColor, useNeon) end
        return
    end

    if input.KeyCode == KEY_PREV then
        refreshCandidates()
        stepCandidate(-1)
        return
    end

    if input.KeyCode == KEY_NEXT then
        refreshCandidates()
        stepCandidate(1)
        return
    end

    if input.KeyCode == KEY_NEON then
        useNeon = not useNeon
        retintAll(tintColor, useNeon)
        return
    end

    if input.KeyCode == KEY_RESET then
        resetAll()
        return
    end

    local newColor = palette[input.KeyCode]
    if newColor then
        tintColor = newColor
        retintAll(tintColor, useNeon)
        return
    end
end)
