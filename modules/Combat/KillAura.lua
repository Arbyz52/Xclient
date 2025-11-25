
local module = {
    Name = "KillAura",
    Category = "Combat", -- можно не писать, возьмётся из папки
    Enabled = false,
}

function module:Init()
    -- один раз при загрузке
end

function module:OnEnable()
    -- включили
end

function module:OnDisable()
    -- выключили
end

function module:OnTick(dt)
    if not self.Enabled then return end
    -- основной код твоей фичи
end

return module
