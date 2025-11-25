local module = {
    Name     = "ESP",
    Category = "Visuals",
    Enabled  = false,
}

-- вызывать один раз при загрузке, тут можно подготовить объекты/таблицы
function module:Init()
    print("[Xclient][ESP] Init()")
    -- сюда потом добавишь свои переменные / кэш
end

function module:OnEnable()
    print("[Xclient][ESP] Включен")
    -- включение твоего ESP
end

function module:OnDisable()
    print("[Xclient][ESP] Выключен")
    -- выключение / очистка ESP
end

function module:OnTick(dt)
    if not self.Enabled then return end
    -- здесь будет твоя логика ESP, которая выполняется каждый кадр
end

return module
