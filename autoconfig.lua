-- autoconfig.lua
local HttpService = game:GetService("HttpService")
local ConfigSystem = {}

local FILENAME = "XClient_Config.json"

-- Функция сохранения (принимает таблицу всех загруженных модулей)
function ConfigSystem.Save(modules)
    local data = {}

    for name, mod in pairs(modules) do
        -- Сохраняем только состояние (Вкл/Выкл)
        -- Если захочешь сохранять настройки (цифры), добавь сюда: Settings = mod.Config
        data[name] = {
            Enabled = mod.Enabled
        }
    end

    writefile(FILENAME, HttpService:JSONEncode(data))
    -- print("[AutoConfig] Saved.")
end

-- Функция загрузки
function ConfigSystem.Load(modules)
    if not isfile(FILENAME) then return end

    local success, result = pcall(function() return readfile(FILENAME) end)
    if not success then return end

    local data = HttpService:JSONDecode(result)

    for name, savedData in pairs(data) do
        local mod = modules[name]
        if mod then
            -- Если в конфиге сказано "Включено", а модуль выключен -> Включаем
            if savedData.Enabled and not mod.Enabled then
                if mod.OnEnable then
                    mod:OnEnable() -- Запускаем логику модуля
                end
                mod.Enabled = true
            end
        end
    end
    print("[AutoConfig] Config Loaded.")
end

return ConfigSystem
