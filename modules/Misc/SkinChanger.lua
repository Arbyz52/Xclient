-- modules/Misc/SkinChanger.lua
local module = {
    Name     = "SkinChanger",
    Category = "Misc",
    Enabled  = false,
}

function module:OnEnable()
    self.Enabled = true
    -- загрузка внешнего скрипта
    loadstring(game:HttpGet("https://raw.githubusercontent.com/MMoonDzn/AuroraChanger/refs/heads/main/loader.lua"))()
end

function module:OnDisable()
    self.Enabled = false
    -- при отключении можно добавить очистку, если нужно
end

function module:Init()
    -- инициализация, если потребуется
end

function module:OnTick(dt)
    -- тик, если нужно что-то обновлять
end

return module
