-- modules/Misc/Example.lua
local module = {
    Name = "Example",
    Category = "Misc",
    Enabled = false,
}

function module:Init()
    print("[Xclient] Example Init()")
end

function module:OnEnable()
    print("[Xclient] Example включен")
end

function module:OnDisable()
    print("[Xclient] Example выключен")
end

function module:OnTick(dt)
    if not self.Enabled then return end
    self._t = (self._t or 0) + dt
    if self._t >= 1 then
        self._t = 0
        print("[Xclient] Example тик")
    end
end

return module
