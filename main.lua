
local GITHUB_USER   = "Arbyz52"
local GITHUB_REPO   = "Xclient"
local GITHUB_BRANCH = "main"

local RAW_BASE = string.format(
    "https://raw.githubusercontent.com/%s/%s/%s/",
    GITHUB_USER, GITHUB_REPO, GITHUB_BRANCH
)

local MANIFEST_URL   = RAW_BASE .. "manifest.json"
local GUI_URL        = RAW_BASE .. "gui.lua"
local AUTOCONFIG_URL = RAW_BASE .. "autoconfig.lua"

local HttpService = game:GetService("HttpService")
local RunService  = game:GetService("RunService")
local Players     = game:GetService("Players")


local function httpGet(url)

    if game and game.HttpGet then
        local ok, res = pcall(function()
            return game:HttpGet(url)
        end)
        if ok and type(res) == "string" then
            return res
        end
    end


    if syn and syn.request then
        local ok, res = pcall(syn.request, {
            Url = url,
            Method = "GET",
        })
        if ok and res and (res.Body or res.body) then
            return res.Body or res.body
        end
    end


    if http_request then
        local ok, res = pcall(http_request, {
            Url = url,
            Method = "GET",
        })
        if ok and res and (res.Body or res.body) then
            return res.Body or res.body
        end
    end

    if request then
        local ok, res = pcall(request, {
            Url = url,
            Method = "GET",
        })
        if ok and res and (res.Body or res.body) then
            return res.Body or res.body
        end
    end


    local ok, res = pcall(function()
        return HttpService:GetAsync(url)
    end)
    if ok and type(res) == "string" then
        return res
    end

    error("[Xclient] HTTP GET провалился для URL: " .. tostring(url))
end

local function getJSON(url)
    local body = httpGet(url)
    return HttpService:JSONDecode(body)
end


local ModuleManager = {
    Modules    = {},
    Categories = {},
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
                            print("[Xclient][RAW]", self.Name, "OFF (ничего не делаем)")
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


ModuleManager:ReloadFromManifest()


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

    AutoConfigLib.Load(ModulesMap)

    task.spawn(function()
        while true do
            task.wait(5)
            AutoConfigLib.Save(ModulesMap)
        end
    end)


    Players.PlayerRemoving:Connect(function()
        AutoConfigLib.Save(ModulesMap)
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
        GuiModule.Init(ModuleManager)
    else
        warn("[Xclient] gui.lua должен return'ить таблицу с Init(ModuleManager)")
    end
end

initGUI()


RunService.RenderStepped:Connect(function(dt)
    ModuleManager:Tick(dt)
end)
