local module = {
    Name = "KillAura",
    Category = "Combat",
    Enabled = false,
}

function module:OnEnable()
    print("[Xclient] KillAura ON")
end

function module:OnDisable()
    print("[Xclient] KillAura OFF")
end

function module:OnTick(dt)
    if not self.Enabled then return end
    -- твой код
end

return module
