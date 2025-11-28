-- modules/Visuals/GrenadePredictor.lua
local module = {
    Name     = "GrenadePredictor",
    Category = "Player",
    Enabled  = false,

    _connections = {},
    _predictors  = {}, -- хранит созданные предикторы
}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local workspace = game:GetService("Workspace")

-- ===== УТИЛИТЫ =====
local function disconnect(conn)
    if conn then pcall(function() conn:Disconnect() end) end
end

local function addConnection(key, conn)
    if key then
        if module._connections[key] then disconnect(module._connections[key]) end
        module._connections[key] = conn
    else
        table.insert(module._connections, conn)
    end
end

local function clearConnections()
    for k, v in pairs(module._connections) do
        disconnect(v)
        module._connections[k] = nil
    end
end

-- ===== ПОЛЕЗНЫЕ ФУНКЦИИ ДЛЯ ТРАЕКТОРИИ =====
local function clampVec3Magnitude(v, maxMag)
    local m = v.Magnitude
    if m > maxMag then return v.Unit * maxMag end
    return v
end

local function makeRayParams(extraIgnore)
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local ignore = {}
    local char = LocalPlayer.Character
    if char then table.insert(ignore, char) end
    if extraIgnore then
        for _, inst in ipairs(extraIgnore) do table.insert(ignore, inst) end
    end
    rp.FilterDescendantsInstances = ignore
    rp.IgnoreWater = true
    return rp
end

-- ===== ФАБРИКА ПРЕДИКТОРА =====
-- opts: table (необязательно)
--   .ThrowSpeed (number) - скорость броска
--   .ExplodeTime (number) - время до взрыва
--   .KeyOn (Enum.KeyCode) - клавиша включения (по умолчанию Four)
--   .KeyOff (table of Enum.KeyCode) - клавиши выключения (по умолчанию {One, Two, Three})
--   .MinStartDist, .StartOffsetForward - параметры смещения от камеры
-- Возвращает объект { Start = fn, Stop = fn, Destroy = fn }
function module.CreatePredictor(opts)
    opts = opts or {}
    local THROW_SPEED = opts.ThrowSpeed or 78
    local EXPLODE_TIME = opts.ExplodeTime or 4.5
    local KEY_ON = opts.KeyOn or Enum.KeyCode.Four
    local KEY_OFF = opts.KeyOff or { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three }
    local MIN_START_DIST = opts.MinStartDist or 1.2
    local START_OFFSET_FORWARD = opts.StartOffsetForward or 1.2

    -- симуляция параметры (можно расширить через opts)
    local STEPS = 260
    local DT = 1/120
    local AIR_DRAG = 0.01
    local RESTITUTION = 0.35
    local SURFACE_FRICTION = 0.2
    local ROLL_FRICTION = 0.94
    local SLIDE_ENTER_SPEED = 16
    local STOP_THRESHOLD = 0.8
    local MAX_SEGMENT = 2.5
    local MAX_BOUNCES = 12
    local RADIUS = 0.12
    local SURFACE_OFFSET = RADIUS + 0.02
    local MAX_SPEED = 120

    -- визуализация
    local SEG_RADIUS = opts.SegRadius or 0.06
    local SEG_COLOR = opts.SegColor or Color3.fromRGB(0, 255, 170)
    local SEG_MATERIAL = opts.SegMaterial or Enum.Material.Neon
    local SEG_TRANSPARENCY_HEAD = opts.SegTransparencyHead or 0.15
    local SEG_TRANSPARENCY_TAIL = opts.SegTransparencyTail or 0.6
    local FADE_START = opts.FadeStart or 0.7
    local UPDATE_RATE = opts.UpdateRate or 1/30

    -- внутренние переменные
    local predictionFolder = nil
    local segPool = {}
    local explodePart = nil
    local predConn = nil
    local predicting = false
    local lastUpdate = 0

    -- очистка старых объектов
    local function clearOldPrediction()
        local old = workspace:FindFirstChild("GrenadePrediction")
        if old then old:Destroy() end
    end

    local function ensureFolder()
        if predictionFolder and predictionFolder.Parent then return end
        clearOldPrediction()
        predictionFolder = Instance.new("Folder")
        predictionFolder.Name = "GrenadePrediction"
        predictionFolder.Parent = workspace
    end

    local function createSegment(i)
        local p = Instance.new("Part")
        p.Name = "Seg_" .. i
        p.Anchored = true
        p.CanCollide = false
        p.Material = SEG_MATERIAL
        p.Color = SEG_COLOR
        p.Shape = Enum.PartType.Cylinder
        p.TopSurface = Enum.SurfaceType.Smooth
        p.BottomSurface = Enum.SurfaceType.Smooth
        p.Parent = predictionFolder
        segPool[i] = p
        return p
    end

    local function ensureSegment(i)
        if segPool[i] and segPool[i].Parent then return segPool[i] end
        return createSegment(i)
    end

    local function ensureExplodePart()
        if explodePart and explodePart.Parent then return explodePart end
        local p = Instance.new("Part")
        p.Name = "ExplodeMarker"
        p.Shape = Enum.PartType.Ball
        p.Anchored = true
        p.CanCollide = false
        p.Material = Enum.Material.Neon
        p.Color = Color3.fromRGB(255, 80, 80)
        p.Size = Vector3.new(0.28, 0.28, 0.28)
        p.Transparency = 0
        p.Parent = predictionFolder
        p.LightEmission = 1
        explodePart = p
        return p
    end

    local function clearVisuals()
        for i, v in pairs(segPool) do
            if v then v:Destroy() segPool[i] = nil end
        end
        if explodePart then explodePart:Destroy() explodePart = nil end
    end

    -- симуляция (взята упрощённо, но полная)
    local function reflectVelocity(vel, normal)
        local vN_mag = vel:Dot(normal)
        local vN = vN_mag * normal
        local vT = vel - vN
        local newVN = -RESTITUTION * vN
        local newVT = vT * math.max(0, (1 - SURFACE_FRICTION))
        local out = newVN + newVT
        return clampVec3Magnitude(out, MAX_SPEED)
    end

    local function computeTrajectory(origin, velocity, explodeTime)
        local points = {}
        local rp = makeRayParams({predictionFolder})
        local g = Vector3.new(0, -workspace.Gravity, 0)

        local pos = origin
        local vel = clampVec3Magnitude(velocity, MAX_SPEED)
        local sliding = false
        local groundNormal = nil
        local bounceCount = 0

        local t = 0
        local explodePoint = nil

        for i = 1, STEPS do
            if vel.Magnitude < STOP_THRESHOLD then break end
            if t >= explodeTime then
                explodePoint = pos
                break
            end

            if not sliding then
                local stepVel = vel * DT
                local stepTime = DT
                if stepVel.Magnitude > MAX_SEGMENT then
                    local scale = MAX_SEGMENT / stepVel.Magnitude
                    stepVel = stepVel * scale
                    stepTime = DT * scale
                end

                local result = workspace:Raycast(pos, stepVel, rp)
                if result then
                    pos = result.Position
                    table.insert(points, pos)
                    t += stepTime

                    bounceCount += 1
                    if bounceCount > MAX_BOUNCES then break end

                    if vel.Magnitude < SLIDE_ENTER_SPEED then
                        sliding = true
                        groundNormal = result.Normal
                        pos = pos + groundNormal * SURFACE_OFFSET
                        vel = vel - vel:Dot(groundNormal) * groundNormal
                        vel = clampVec3Magnitude(vel, MAX_SPEED)
                    else
                        vel = reflectVelocity(vel, result.Normal)
                        pos = pos + result.Normal * SURFACE_OFFSET
                    end
                else
                    pos = pos + stepVel
                    table.insert(points, pos)
                    t += stepTime

                    vel = vel + g * DT
                    vel = vel * (1 - AIR_DRAG * DT)
                    vel = clampVec3Magnitude(vel, MAX_SPEED)
                end
            else
                vel = vel * ROLL_FRICTION
                if groundNormal then
                    local tangentGravity = g - groundNormal * g:Dot(groundNormal)
                    vel = vel + tangentGravity * DT
                end

                local stepVel = vel * DT
                local stepTime = DT
                if stepVel.Magnitude > MAX_SEGMENT then
                    local scale = MAX_SEGMENT / stepVel.Magnitude
                    stepVel = stepVel * scale
                    stepTime = DT * scale
                end

                local result = workspace:Raycast(pos, stepVel, rp)
                if result then
                    pos = result.Position + result.Normal * SURFACE_OFFSET
                    table.insert(points, pos)
                    t += stepTime

                    vel = vel - vel:Dot(result.Normal) * result.Normal
                    vel = vel * 0.85
                    vel = clampVec3Magnitude(vel, MAX_SPEED)

                    if vel.Magnitude < STOP_THRESHOLD then break end
                else
                    pos = pos + stepVel
                    table.insert(points, pos)
                    t += stepTime

                    if groundNormal then pos = pos + groundNormal * 0.0005 end
                    if vel.Magnitude < STOP_THRESHOLD then break end
                end
            end
        end

        if not explodePoint and #points > 0 then
            explodePoint = points[#points]
        end

        return points, explodePoint
    end

    -- рендер: используем ПОЛНУЮ траекторию, но старт рендера смещаем
    local function renderCylindricalLine(fullPoints, explodePoint)
        if not fullPoints or #fullPoints < 2 then
            clearVisuals()
            return
        end

        ensureFolder()
        local camPos = workspace.CurrentCamera.CFrame.Position
        local camLook = workspace.CurrentCamera.CFrame.LookVector

        -- найти первую точку дальше MIN_START_DIST
        local firstIndex = 1
        for i = 1, #fullPoints do
            if (fullPoints[i] - camPos).Magnitude >= MIN_START_DIST then
                firstIndex = i
                break
            end
        end

        local renderPoints = {}
        if firstIndex == 1 and (fullPoints[1] - camPos).Magnitude < MIN_START_DIST then
            table.insert(renderPoints, camPos + camLook * START_OFFSET_FORWARD)
            for i = 1, #fullPoints do table.insert(renderPoints, fullPoints[i]) end
        else
            local startPoint = camPos + camLook * MIN_START_DIST
            table.insert(renderPoints, startPoint)
            for i = firstIndex, #fullPoints do table.insert(renderPoints, fullPoints[i]) end
        end

        local segCount = math.max(0, #renderPoints - 1)
        for i = 1, segCount do
            local a = renderPoints[i]
            local b = renderPoints[i + 1]
            local dir = b - a
            local len = dir.Magnitude
            if len <= 0 then
                if segPool[i] and segPool[i].Parent then segPool[i].Parent = nil end
            else
                local seg = ensureSegment(i)
                local mid = (a + b) * 0.5
                local lookCFrame = CFrame.lookAt(mid, mid + dir.Unit)
                seg.CFrame = lookCFrame * CFrame.Angles(math.rad(90), 0, 0)
                seg.Size = Vector3.new(SEG_RADIUS * 2, len, SEG_RADIUS * 2)
                local tailStart = math.floor(segCount * FADE_START)
                seg.Transparency = (i > tailStart) and SEG_TRANSPARENCY_TAIL or SEG_TRANSPARENCY_HEAD
                seg.Parent = predictionFolder
            end
        end

        for i = segCount + 1, #segPool do
            local s = segPool[i]
            if s then s:Destroy() segPool[i] = nil end
        end

        if explodePoint then
            local m = ensureExplodePart()
            m.CFrame = CFrame.new(explodePoint)
            m.Parent = predictionFolder
        else
            if explodePart then explodePart.Parent = nil end
        end
    end

    -- получение стартовых параметров броска (HRP + камера)
    local function getThrowParams()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local startPos = hrp.Position + Vector3.new(0, 1.5, 0)
        local charVel = Vector3.zero
        local lv = hrp.AssemblyLinearVelocity
        if lv then charVel = Vector3.new(lv.X, 0, lv.Z) end
        local velocity = workspace.CurrentCamera.CFrame.LookVector.Unit * THROW_SPEED + Vector3.new(0, 5, 0) + charVel * 0.35
        return startPos, velocity
    end

    -- цикл обновления
    local function loopUpdate(dt)
        lastUpdate = lastUpdate + dt
        if lastUpdate < UPDATE_RATE then return end
        lastUpdate = 0

        if not predicting then
            clearVisuals()
            return
        end

        local startPos, vel = getThrowParams()
        if not startPos then
            clearVisuals()
            return
        end

        local points, explodePoint = computeTrajectory(startPos, vel, EXPLODE_TIME)
        renderCylindricalLine(points, explodePoint)
    end

    -- управление клавишами
    local keyConn = nil
    local function onInputBegan(input, gp)
        if gp then return end
        if input.KeyCode == KEY_ON then
            if not predicting then
                predicting = true
            end
        else
            for _, k in ipairs(KEY_OFF) do
                if input.KeyCode == k then
                    predicting = false
                    clearVisuals()
                    break
                end
            end
        end
    end

    -- публичные методы предиктора
    local predictor = {}

    function predictor:Start()
        if predConn then return end
        ensureFolder()
        predConn = RunService.RenderStepped:Connect(loopUpdate)
        keyConn = UserInputService.InputBegan:Connect(onInputBegan)
    end

    function predictor:Stop()
        predicting = false
        if predConn then disconnect(predConn) predConn = nil end
        if keyConn then disconnect(keyConn) keyConn = nil end
        clearVisuals()
        if predictionFolder and predictionFolder.Parent then
            predictionFolder:Destroy()
            predictionFolder = nil
        end
    end

    function predictor:Destroy()
        self:Stop()
    end

    return predictor
end

-- ===== МЕТОДЫ МОДУЛЯ =====
function module:Init()
    self._connections = {}
    self._predictors = {}
end

function module:OnEnable()
    self.Enabled = true
    -- создаём один предиктор по умолчанию и запускаем его
    local pred = module.CreatePredictor()
    module._predictors["default"] = pred
    pred:Start()
end

function module:OnDisable()
    self.Enabled = false
    for k, pred in pairs(self._predictors) do
        if pred and pred.Stop then
            pcall(function() pred:Stop() end)
        end
        module._predictors[k] = nil
    end
    clearConnections()
end

function module:OnTick(dt) end

return module
