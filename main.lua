
local GITHUB_USER   = "Arbyz52"
local GITHUB_REPO   = "Xclient"
local GITHUB_BRANCH = "main"
local VERSION        = "2.0.0"

local RAW_BASE = string.format(
    "https://raw.githubusercontent.com/%s/%s/%s/",
    GITHUB_USER, GITHUB_REPO, GITHUB_BRANCH
)

local MANIFEST_URL   = RAW_BASE .. "manifest.json"
local GUI_URL        = RAW_BASE .. "gui.lua"
local AUTOCONFIG_URL = RAW_BASE .. "autoconfig.lua"
local NOTIF_URL      = RAW_BASE .. "lib/Notifications.lua"

local HttpService = game:GetService("HttpService")
local RunService  = game:GetService("RunService")
local Players     = game:GetService("Players")

local CACHE_DIR    = "XclientCache/"
local MAX_RETRIES  = 2
local RETRY_DELAY  = 0.5

local function ensureCacheDir()
    pcall(function()
        if not isfolder(CACHE_DIR) then
            makefolder(CACHE_DIR)
        end
    end)
end

local function httpGet(url, retries)
    retries = retries or MAX_RETRIES

    local function tryRequest(reqFunc)
        for attempt = 1, retries do
            local ok, res = pcall(reqFunc)
            if ok and res then
                local body = type(res) == "string" and res or (res.Body or res.body)
                if type(body) == "string" and #body > 0 then
                    return body
                end
            end
            if attempt < retries then
                task.wait(RETRY_DELAY)
            end
        end
        return nil
    end

    local result = nil

    if game and game.HttpGet then
        result = tryRequest(function() return game:HttpGet(url) end)
    end

    if not result and syn and syn.request then
        result = tryRequest(function()
            local r = syn.request({ Url = url, Method = "GET" })
            return r
        end)
    end

    if not result and http_request then
        result = tryRequest(function()
            local r = http_request({ Url = url, Method = "GET" })
            return r
        end)
    end

    if not result and request then
        result = tryRequest(function()
            local r = request({ Url = url, Method = "GET" })
            return r
        end)
    end

    if not result then
        result = tryRequest(function()
            return HttpService:GetAsync(url)
        end)
    end

    if result then
        ensureCacheDir()
        local cacheKey = url:gsub("[^%w]", "_")
        pcall(function() writefile(CACHE_DIR .. cacheKey, result) end)
        return result
    end

    local cacheKey = url:gsub("[^%w]", "_")
    if isfile(CACHE_DIR .. cacheKey) then
        local ok, cached = pcall(readfile, CACHE_DIR .. cacheKey)
        if ok and cached and #cached > 0 then
            warn("[Xclient] Использую кеш для:", url)
            return cached
        end
    end

    error("[Xclient] HTTP GET failed for: " .. tostring(url))
end

local function getJSON(url)
    local body = httpGet(url)
    return HttpService:JSONDecode(body)
end


local ModuleManager = {
    Modules    = {},
    Categories = {},
    Keybinds   = {},
    Version    = VERSION,
}

function ModuleManager:RegisterModule(mod)
    if type(mod) ~= "table" then return end

    mod.Name     = mod.Name or "Unnamed"
    mod.Enabled  = mod.Enabled or false
    mod.Category = mod.Category or "Misc"

    self.Categories[mod.Category] = self.Categories[mod.Category] or {}
    table.insert(self.Modules, mod)
    table.insert(self.Categories[mod.Category], mod)

    if type(mod.Init) == "function" then
        pcall(function() mod:Init() end)
    end
end

function ModuleManager:SetEnabled(mod, state)
    if not mod or mod.Enabled == state then return end
    mod.Enabled = state

    if state then
        if type(mod.OnEnable) == "function" then
            pcall(function() mod:OnEnable() end)
        end
    else
        if type(mod.OnDisable) == "function" then
            pcall(function() mod:OnDisable() end)
        end
    end
end

function ModuleManager:Tick(dt)
    for _, mod in ipairs(self.Modules) do
        if mod.Enabled and type(mod.OnTick) == "function" then
            pcall(function() mod:OnTick(dt) end)
        end
    end
end

function ModuleManager:GetModuleByName(name)
    for _, mod in ipairs(self.Modules) do
        if mod.Name == name then return mod end
    end
    return nil
end

function ModuleManager:ReloadFromManifest()
    print("[Xclient] Загружаю manifest.json...")

    for _, mod in ipairs(self.Modules) do
        if mod.Enabled and type(mod.OnDisable) == "function" then
            pcall(function() mod:OnDisable() end)
        end
    end

    self.Modules    = {}
    self.Categories = {}

    local manifest
    local ok, err = pcall(function()
        manifest = getJSON(MANIFEST_URL)
    end)

    if not ok then
        warn("[Xclient] Не удалось загрузить manifest.json:", err)
        return false
    end

    if type(manifest) ~= "table" or type(manifest.modules) ~= "table" then
        warn("[Xclient] Неверный формат manifest.json")
        return false
    end

    local count = 0

    for _, entry in ipairs(manifest.modules) do
        if type(entry.path) == "string" then
            local path     = entry.path
            local category = entry.category or "Misc"
            local name     = entry.name     or path
            local mtype    = (entry.type or entry.kind or "module"):lower()

            local url = RAW_BASE .. path

            local codeOK, code = pcall(httpGet, url)
            if not codeOK then
                warn("[Xclient] Не удалось скачать", path, ":", code)
            else
                if mtype == "raw" then
                    local chunk, lerr = loadstring(code, "@" .. path)
                    if not chunk then
                        warn("[Xclient] loadstring error (raw)", path, ":", lerr)
                    else
                        local wrapper = {
                            Name     = name,
                            Category = category,
                            Enabled  = false,
                            _chunk   = chunk,
                        }

                        function wrapper:OnEnable()
                            print("[Xclient][RAW]", self.Name, "ON")
                            local ok2, err2 = pcall(self._chunk)
                            if not ok2 then
                                warn("[Xclient][RAW]", self.Name, "error:", err2)
                            end
                        end

                        function wrapper:OnDisable()
                            print("[Xclient][RAW]", self.Name, "OFF")
                        end

                        self:RegisterModule(wrapper)
                        count += 1
                        print("[Xclient] RAW-скрипт загружен:", category .. "/" .. name)
                    end
                else
                    local chunk, lerr = loadstring(code, "@" .. path)
                    if not chunk then
                        warn("[Xclient] loadstring error (module)", path, ":", lerr)
                    else
                        local ok2, mod = pcall(chunk)
                        if not ok2 then
                            warn("[Xclient] runtime error (module)", path, ":", mod)
                        elseif type(mod) == "table" then
                            mod.Category = category
                            mod.Name     = name
                            self:RegisterModule(mod)
                            count += 1
                            print("[Xclient] Модуль загружен:", category .. "/" .. name)
                        else
                            warn("[Xclient] Модуль", path, "не вернул таблицу")
                        end
                    end
                end
            end
        end
    end

    print("[Xclient] Загрузка модулей завершена, всего:", count)
    return true
end


local Notifications

local function loadLibraries()
    local ok1, lib1 = pcall(httpGet, NOTIF_URL)
    if ok1 and lib1 then
        local chunk, err = loadstring(lib1, "@Notifications.lua")
        if chunk then
            local ok2, result = pcall(chunk)
            if ok2 and type(result) == "table" then
                Notifications = result
                Notifications:Init()
            end
        end
    end
end

loadLibraries()

ModuleManager:ReloadFromManifest()

local function notify(text, duration, color)
    if Notifications then
        Notifications:Show(text, duration, color)
    end
    print("[Xclient]", text)
end

local function initAutoConfig()
    local ModulesMap = {}
    for _, mod in ipairs(ModuleManager.Modules) do
        if mod.Name then
            ModulesMap[mod.Name] = mod
        end
    end

    local codeOK, code = pcall(httpGet, AUTOCONFIG_URL)
    if not codeOK then
        warn("[Xclient] Не удалось скачать autoconfig.lua")
        return
    end

    local chunk, err = loadstring(code, "@autoconfig.lua")
    if not chunk then
        warn("[Xclient] Ошибка loadstring autoconfig.lua:", err)
        return
    end

    local ok, AutoConfigLib = pcall(chunk)
    if not ok or type(AutoConfigLib) ~= "table" then
        warn("[Xclient] Ошибка выполнения autoconfig.lua или неверный return")
        return
    end

    AutoConfigLib.Load(ModulesMap, ModuleManager.Keybinds)

    task.spawn(function()
        while true do
            task.wait(5)
            AutoConfigLib.Save(ModulesMap, ModuleManager.Keybinds)
        end
    end)

    Players.PlayerRemoving:Connect(function()
        AutoConfigLib.Save(ModulesMap, ModuleManager.Keybinds)
    end)
end

initAutoConfig()


local function initGUI()
    local code = httpGet(GUI_URL)
    local chunk, err = loadstring(code, "@gui.lua")
    if not chunk then
        warn("[Xclient] Ошибка loadstring gui.lua:", err)
        return
    end

    local ok, GuiModule = pcall(chunk)
    if not ok then
        warn("[Xclient] Ошибка выполнения gui.lua:", GuiModule)
        return
    end

    if type(GuiModule) == "table" and type(GuiModule.Init) == "function" then
        GuiModule.Init(ModuleManager, Notifications)
    else
        warn("[Xclient] gui.lua должен return'ить таблицу с Init(ModuleManager)")
    end
end

initGUI()

notify("Xclient v" .. VERSION .. " загружен!", 4, Color3.fromRGB(45, 100, 65))

RunService.RenderStepped:Connect(function(dt)
    ModuleManager:Tick(dt)
end)
