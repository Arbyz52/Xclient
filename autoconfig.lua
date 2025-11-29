
local HttpService = game:GetService("HttpService")
local ConfigSystem = {}

local FILENAME = "XClient_Config.json"

function ConfigSystem.Save(modules)
    local data = {}

    for name, mod in pairs(modules) do

        data[name] = {
            Enabled = mod.Enabled
        }
    end

    writefile(FILENAME, HttpService:JSONEncode(data))

end

function ConfigSystem.Load(modules)
    if not isfile(FILENAME) then return end

    local success, result = pcall(function() return readfile(FILENAME) end)
    if not success then return end

    local data = HttpService:JSONDecode(result)

    for name, savedData in pairs(data) do
        local mod = modules[name]
        if mod then

            if savedData.Enabled and not mod.Enabled then
                if mod.OnEnable then
                    mod:OnEnable()
                end
                mod.Enabled = true
            end
        end
    end

end

return ConfigSystem
