
local HttpService = game:GetService("HttpService")
local ConfigSystem = {}

local FILENAME = "XClient_Config.json"

function ConfigSystem.Save(modules, keybinds)
    local data = { modules = {}, keybinds = {} }

    for name, mod in pairs(modules) do
        local entry = {
            Enabled = mod.Enabled or false
        }

        if mod.__settings__ then
            entry.Settings = {}
            for k, v in pairs(mod.__settings__) do
                entry.Settings[k] = v
            end
        end

        data.modules[name] = entry
    end

    if keybinds then
        for name, key in pairs(keybinds) do
            data.keybinds[name] = key
        end
    end

    pcall(function()
        writefile(FILENAME, HttpService:JSONEncode(data))
    end)
end

function ConfigSystem.Load(modules, keybinds)
    if not isfile(FILENAME) then return end

    local success, result = pcall(function() return readfile(FILENAME) end)
    if not success or not result then return end

    local ok2, data = pcall(HttpService.JSONDecode, HttpService, result)
    if not ok2 or type(data) ~= "table" then return end

    if data.modules then
        for name, saved in pairs(data.modules) do
            local mod = modules[name]
            if mod and type(saved) == "table" then
                if saved.Settings and type(saved.Settings) == "table" then
                    if not mod.__settings__ then mod.__settings__ = {} end
                    for k, v in pairs(saved.Settings) do
                        mod.__settings__[k] = v
                    end
                end
                if saved.Enabled and not mod.Enabled then
                    mod.Enabled = true
                    if type(mod.OnEnable) == "function" then
                        pcall(function() mod:OnEnable() end)
                    end
                end
            end
        end
    end

    if data.keybinds and keybinds then
        for name, key in pairs(data.keybinds) do
            if type(key) == "string" then
                keybinds[name] = key
            end
        end
    end
end

return ConfigSystem
