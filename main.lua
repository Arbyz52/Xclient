-- ===================== main.lua (GitHub) ======================
-- ВСЁ на GitHub, запуск из игры:
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/Arbyz52/Xclient/main/main.lua"))()

local GITHUB_USER   = "Arbyz52"
local GITHUB_REPO   = "Xclient"
local GITHUB_BRANCH = "main"

local RAW_BASE = string.format(
    "https://raw.githubusercontent.com/%s/%s/%s/",
    GITHUB_USER, GITHUB_REPO, GITHUB_BRANCH
)

local MANIFEST_URL = RAW_BASE .. "manifest.json"
local GUI_URL      = RAW_BASE .. "gui.lua"

local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")

---------------------------------------------------------
-- HTTP GET
---------------------------------------------------------

local function httpGet(url)
    if syn and syn.request then
        local res = syn.request({ Url = url, Method = "GET" })
        return res.Body or res.body
    end

    if http_request then
        local res = http_request({ Url = url, Method = "GET" })
        return res.Body or res.body
    end

    if request then
        local res = request({ Url = url, Method = "GET" })
        return res.Body or res.body
    end

    if game and game.HttpGet then
        return game:HttpGet(url)
    end

    local ok, res = pcall(function()
        return HttpService:GetAsync(url)
    end)
    if ok then
        return res
    end

    error("[Xclient] Нет доступного способа HTTP GET")
end

local function getJSON(url)
    local body = httpGet(url)
    return HttpService:JSONDecode(body)
end

---------------------------------------------------------
-- ModuleManager
---------------------------------------------------------

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

---------------------------------------------------------
-- ЗАГРУЗКА МОДУЛЕЙ ПО manifest.json
---------------------------------------------------------

local function loadModulesFromManifest()
    print("[Xclient] Загружаю manifest.json...")

    local manifest
    local ok, err = pcall(function()
        manifest = getJSON(MANIFEST_URL)
    end)

    if not ok then
        warn("[Xclient] Не удалось загрузить manifest.json:", err)
        return
    end

    if type(manifest) ~= "table" or type(manifest.modules) ~= "table" then
        warn("[Xclient] Неверный формат manifest.json")
        return
    end

    local count = 0

    for _, entry in ipairs(manifest.modules) do
        if type(entry.path) == "string" then
            local path     = entry.path
            local category = entry.category or "Misc"
            local name     = entry.name     or path

            local url = RAW_BASE .. path
            local codeOK, code = pcall(httpGet, url)

            if not codeOK then
                warn("[Xclient] Не удалось скачать модуль", path, ":", code)
            else
                local chunk, lerr = loadstring(code, "@" .. path)
                if not chunk then
                    warn("[Xclient] Ошибка loadstring в модуле", path, ":", lerr)
                else
                    local ok2, mod = pcall(chunk)
                    if not ok2 then
                        warn("[Xclient] Ошибка при выполнении модуля", path, ":", mod)
                    elseif type(mod) == "table" then
                        mod.Category = mod.Category or category
                        mod.Name     = mod.Name     or name
                        ModuleManager:RegisterModule(mod)
                        count += 1
                        print("[Xclient] Модуль загружен:", category .. "/" .. (mod.Name or path))
                    else
                        warn("[Xclient] Модуль", path, "не вернул таблицу")
                    end
                end
            end
        end
    end

    print("[Xclient] Загрузка модулей завершена, всего:", count)
end

---------------------------------------------------------
-- ЗАГРУЗКА GUI С GITHUB
---------------------------------------------------------

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

---------------------------------------------------------
-- СТАРТ
---------------------------------------------------------

loadModulesFromManifest()
initGUI()

RunService.RenderStepped:Connect(function(dt)
    ModuleManager:Tick(dt)
end)
