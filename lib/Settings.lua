local Settings = {}

Settings.Defaults = {}

function Settings.MakeSetting(mod, name, defaultValue)
    local key = "__settings__"
    if not mod[key] then mod[key] = {} end
    if mod[key][name] == nil then
        mod[key][name] = defaultValue
    end
    return mod[key][name]
end

function Settings.Get(mod, name, default)
    if not mod then return default end
    local key = "__settings__"
    if not mod[key] then mod[key] = {} end
    if mod[key][name] ~= nil then
        return mod[key][name]
    end
    if default ~= nil then
        mod[key][name] = default
    end
    return default
end

function Settings.Set(mod, name, value)
    if not mod then return end
    local key = "__settings__"
    if not mod[key] then mod[key] = {} end
    mod[key][name] = value
end

function Settings.Clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

function Settings.Round(value, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(value * mult + 0.5) / mult
end

function Settings.Save(filename, modulesMap, keybinds)
    local HttpService = game:GetService("HttpService")
    local data = { modules = {}, keybinds = {} }

    for name, mod in pairs(modulesMap) do
        local entry = { Enabled = mod.Enabled or false }
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
        writefile(filename, HttpService:JSONEncode(data))
    end)
end

function Settings.Load(filename, modulesMap, keybinds)
    if not isfile(filename) then return end

    local HttpService = game:GetService("HttpService")
    local ok, raw = pcall(readfile, filename)
    if not ok or not raw then return end

    local ok2, data = pcall(HttpService.JSONDecode, HttpService, raw)
    if not ok2 or type(data) ~= "table" then return end

    if data.modules then
        for name, saved in pairs(data.modules) do
            local mod = modulesMap[name]
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

return Settings
