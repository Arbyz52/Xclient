-- ===================== main.lua (GitHub) ======================
-- Запуск:
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/Arbyz52/Xclient/main/main.lua"))()

local GITHUB_USER   = "Arbyz52"
local GITHUB_REPO   = "Xclient"
local GITHUB_BRANCH = "main"

local API_BASE = string.format(
    "https://api.github.com/repos/%s/%s/contents/modules",
    GITHUB_USER, GITHUB_REPO
)

local GUI_RAW_URL = string.format(
    "https://raw.githubusercontent.com/%s/%s/%s/gui.lua",
    GITHUB_USER, GITHUB_REPO, GITHUB_BRANCH
)

local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")

---------------------------------------------------------
-- HTTP GET (стабильный, без лишних хедеров)
---------------------------------------------------------

local function httpGet(url)
    -- пробуем сначала Roblox HttpGet
    if game and game.HttpGet then
        local ok, res = pcall(game.HttpGet, game, url)
        if ok then return res end
    end

    -- далее экзекьюторные функции (без заголовков)
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

    -- HttpService как крайний случай
    local ok, res = pcall(function()
        return HttpService:GetAsync(url)
    end)
    if ok then return res end

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
-- ЗАГРУЗКА МОДУЛЕЙ ЧЕРЕЗ GitHub API (без manifest.json)
---------------------------------------------------------

local function loadModulesFromGitHub()
    print("[Xclient] Загружаю модули из GitHub (API)...")

    local categories
    local ok, err = pcall(function()
        categories = getJSON(API_BASE .. "?ref=" .. GITHUB_BRANCH)
    end)

    if not ok then
        warn("[Xclient] Не удалось получить список категорий:", err)
        return
    end

    local loaded = 0

    for _, cat in ipairs(categories) do
        if cat.type == "dir" then
            local categoryName = cat.name

            local files
            local ok2, err2 = pcall(function()
                files = getJSON(cat.url .. "?ref=" .. GITHUB_BRANCH)
            end)

            if not ok2 then
                warn("[Xclient] Ошибка списка файлов для", categoryName, ":", err2)
            else
                for _, f in ipairs(files) do
                    if f.type == "file" and f.name:sub(-4):lower() == ".lua" then
                        local codeOK, code = pcall(httpGet, f.download_url)
                        if not codeOK then
                            warn("[Xclient] Не удалось скачать модуль", f.path, ":", code)
                        else
                            local chunk, lerr = loadstring(code, "@" .. f.path)
                            if not chunk then
                                warn("[Xclient] loadstring ошибка", f.path, ":", lerr)
                            else
                                local ok3, mod = pcall(chunk)
                                if not ok3 then
                                    warn("[Xclient] runtime ошибка", f.path, ":", mod)
                                elseif type(mod) == "table" then
                                    mod.Category = mod.Category or categoryName
                                    ModuleManager:RegisterModule(mod)
                                    loaded += 1
                                    print("[Xclient] Модуль загружен:", categoryName .. "/" .. (mod.Name or f.name))
                                else
                                    warn("[Xclient] Модуль", f.path, "не вернул таблицу")
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    print("[Xclient] Загрузка модулей завершена, всего:", loaded)
end

---------------------------------------------------------
-- ЗАГРУЗКА GUI
---------------------------------------------------------

local function initGUI()
    local code = httpGet(GUI_RAW_URL)
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

loadModulesFromGitHub()
initGUI()

RunService.RenderStepped:Connect(function(dt)
    ModuleManager:Tick(dt)
end)
