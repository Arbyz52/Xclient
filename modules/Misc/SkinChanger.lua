
local module = {
    Name     = "SkinChanger",
    Category = "Misc",
    Enabled  = false,
}

function module:OnEnable()
    self.Enabled = true

    loadstring(game:HttpGet("https://raw.githubusercontent.com/MMoonDzn/AuroraChanger/refs/heads/main/loader.lua"))()
end

function module:OnDisable()
    self.Enabled = false

end

function module:Init()

end

function module:OnTick(dt)

end

return module
