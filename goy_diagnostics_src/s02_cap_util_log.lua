
local ENV = (type(getgenv) == "function" and getgenv()) or _G
if type(ENV.GOY_DIAG) == "table" and type(ENV.GOY_DIAG.destroy) == "function" then
    pcall(ENV.GOY_DIAG.destroy)
end

local G = {alive = true, conns = {}, internalErrors = 0, lastInternalError = "", errors = {}, VERSION = CONFIG.VERSION}
ENV.GOY_DIAG = G

local function svc(name)
    local ok, s = pcall(function() return game:GetService(name) end)
    if ok then return s end
    return nil
end

local S = {
    Players = svc("Players"), RunService = svc("RunService"), UIS = svc("UserInputService"),
    Stats = svc("Stats"), LogService = svc("LogService"), CoreGui = svc("CoreGui"),
    HttpService = svc("HttpService"), CollectionService = svc("CollectionService"),
    ReplicatedStorage = svc("ReplicatedStorage"),
}
local LP = S.Players and S.Players.LocalPlayer
if not LP then warn("[GOY DIAG] Sin LocalPlayer: este script es de cliente.") return end

-------------------------------------------------------------------------------
-- 2. CAP — funciones del ejecutor (se comprueban ANTES de usarlas)
-------------------------------------------------------------------------------
local CAP = {}
do
    local function fn(name)
        local v = ENV[name]
        if type(v) ~= "function" then v = rawget(_G, name) end
        if type(v) ~= "function" then
            local ok, r = pcall(function() return getfenv and getfenv(0)[name] end)
            if ok and type(r) == "function" then v = r end
        end
        if type(v) == "function" then return v end
        return nil
    end
    CAP.setclipboard = fn("setclipboard") or fn("toclipboard") or fn("set_clipboard")
    CAP.writefile = fn("writefile")
    CAP.readfile = fn("readfile")
    CAP.isfile = fn("isfile")
    CAP.makefolder = fn("makefolder")
    CAP.isfolder = fn("isfolder")
    CAP.gethui = fn("gethui")
    CAP.queue_on_teleport = fn("queue_on_teleport") or fn("queueonteleport")
    CAP.identifyexecutor = fn("identifyexecutor") or fn("getexecutorname")
    CAP.executor = "desconocido"
    if CAP.identifyexecutor then
        local ok, a, b = pcall(CAP.identifyexecutor)
        if ok and a then CAP.executor = tostring(a) .. (b and (" " .. tostring(b)) or "") end
    end
    CAP.touch = false
    pcall(function() CAP.touch = S.UIS.TouchEnabled end)
end

-------------------------------------------------------------------------------
-- 3. UTIL
-------------------------------------------------------------------------------
local U = {}
local unpackf = table.unpack or unpack

function U.err(where, err)
    G.internalErrors = G.internalErrors + 1
    G.lastInternalError = tostring(err)
    table.insert(G.errors, 1, {t = os.clock(), where = where or "?", msg = tostring(err)})
    if #G.errors > CONFIG.MAX_ERRORS then table.remove(G.errors) end
    if G.onInternalError then pcall(G.onInternalError, where, err) end
end

local function traceback(err)
    local tb = ""
    pcall(function() tb = debug.traceback(tostring(err), 2) end)
    return tb ~= "" and tb or tostring(err)
end

function U.try(where, fn, ...)
    local args = table.pack and table.pack(...) or {n = select("#", ...), ...}
    local ok, err = xpcall(function() return fn(unpackf(args, 1, args.n)) end, traceback)
    if not ok then U.err(where, err) end
    return ok
end

function U.conn(signal, fn, where)
    if not signal then return nil end
    where = where or "conexión"
    local ok, c = pcall(function()
        return signal:Connect(function(...)
            if not G.alive then return end
            U.try(where, fn, ...)
        end)
    end)
    if ok and c then
        G.conns[#G.conns + 1] = c
        return c
    end
    return nil
end

function U.disc(c)
    if c then pcall(function() c:Disconnect() end) end
end

function U.typeOf(v)
    local ok, t = pcall(function() return typeof(v) end)
    if ok and t then return t end
    return type(v)
end

function U.path(inst)
    local ok, p = pcall(function() return inst:GetFullName() end)
    if ok and p then return p end
    return "?"
end

-- Roblox solo garantiza os.date("*t"): la hora se arma a mano.
local function dateTable()
    local ok, t = pcall(function() return os.date("*t") end)
    if ok and type(t) == "table" then return t end
    return nil
end

function U.stamp()
    local t = dateTable()
    local ms = math.floor((os.clock() % 1) * 1000)
    if not t then return string.format("%.3f", os.clock()) end
    return string.format("%02d:%02d:%02d.%03d", t.hour, t.min, t.sec, ms)
end

function U.fullDate()
    local t = dateTable()
    if not t then return "?" end
    return string.format("%04d-%02d-%02d %02d:%02d:%02d", t.year, t.month, t.day, t.hour, t.min, t.sec)
end

function U.fileStamp()
    local t = dateTable()
    if not t then return tostring(math.floor(os.clock())) end
    return string.format("%04d%02d%02d_%02d%02d%02d", t.year, t.month, t.day, t.hour, t.min, t.sec)
end

function U.esc(s)
    s = tostring(s or "")
    s = s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub("\"", "&quot;")
    return s
end

function U.trunc(s, n)
    s = tostring(s or "")
    if #s > n then return s:sub(1, n) .. "…" end
    return s
end

function U.lower(s) return string.lower(tostring(s or "")) end

function U.oneLine(s) return (tostring(s or ""):gsub("\n", "  ·  ")) end

function U.match(q, ...)
    if q == "" then return true end
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        if v and U.lower(v):find(q, 1, true) then return true end
    end
    return false
end

-- Serializador seguro: límites de profundidad/elementos/longitud y tablas circulares.
function U.ser(v, depth, seen, budget)
    depth = depth or 0
    seen = seen or {}
    budget = budget or {n = 0}
    budget.n = budget.n + 1
    if budget.n > CONFIG.SER_BUDGET then return "…" end
    local t = U.typeOf(v)
    if t == "string" then
        return string.format("%q", U.trunc(v, CONFIG.SER_STR))
    elseif t == "number" or t == "boolean" or t == "nil" then
        return tostring(v)
    elseif t == "Instance" then
        local ok, cn = pcall(function() return v.ClassName end)
        return (ok and cn or "Instance") .. "(" .. U.trunc(U.path(v), CONFIG.SER_PATH) .. ")"
    elseif t == "table" then
        if seen[v] then return "<circular>" end
        if depth >= CONFIG.SER_DEPTH then return "{…}" end
        seen[v] = true
        local parts, count = {}, 0
        local ok = pcall(function()
            for k, val in next, v do
                count = count + 1
                if count > CONFIG.SER_ITEMS then parts[#parts + 1] = "…"; break end
                local key
                if type(k) == "string" then key = U.trunc(k, 40) else key = "[" .. U.ser(k, depth + 1, seen, budget) .. "]" end
                parts[#parts + 1] = key .. "=" .. U.ser(val, depth + 1, seen, budget)
            end
        end)
        seen[v] = nil
        if not ok then return "{tabla protegida}" end
        return "{" .. table.concat(parts, ", ") .. "}"
    elseif t == "function" then
        return "function"
    end
    local ok, s = pcall(tostring, v)
    return t .. "(" .. U.trunc(ok and s or "?", 80) .. ")"
end

-- (texto de argumentos, lista de tipos, número de argumentos)
function U.args(...)
    local n = select("#", ...)
    local pack = {...}
    local parts, types = {}, {}
    for i = 1, math.min(n, CONFIG.ARGS_MAX) do
        local t = U.typeOf(pack[i])
        types[#types + 1] = t
        parts[#parts + 1] = i .. ": " .. t .. " = " .. U.ser(pack[i])
    end
    if n > CONFIG.ARGS_MAX then parts[#parts + 1] = string.format(STR.MORE_ARGS, n - CONFIG.ARGS_MAX) end
    if n == 0 then parts[1] = STR.NO_ARGS end
    return table.concat(parts, "\n"), types, n
end

-- Valor → literal de Luau (para ver lo que llegó como código).
function U.lit(v, ind, budget)
    ind = ind or ""
    budget = budget or {n = 0}
    budget.n = budget.n + 1
    if budget.n > CONFIG.SER_BUDGET then return "nil --[[…]]" end
    local t = U.typeOf(v)
    if t == "string" then return string.format("%q", U.trunc(v, CONFIG.SER_STR * 4)) end
    if t == "number" or t == "boolean" or t == "nil" then return tostring(v) end
    if t == "Instance" then return U.pathCode(U.path(v)) end
    if t == "Vector3" or t == "Vector2" or t == "CFrame" or t == "Color3" or t == "UDim2" or t == "UDim" then
        return t .. ".new(" .. tostring(v) .. ")"
    end
    if t == "EnumItem" then return tostring(v) end
    if t == "table" then
        if #ind >= 12 then return "{ --[[…]] }" end
        local keys, parts = {}, {}
        for k in pairs(v) do keys[#keys + 1] = k end
        table.sort(keys, function(a, b)
            local ta, tb = type(a), type(b)
            if ta ~= tb then return ta < tb end
            if ta == "number" or ta == "string" then return a < b end
            return tostring(a) < tostring(b)
        end)
        local inner = ind .. "    "
        for i, k in ipairs(keys) do
            if i > CONFIG.SER_ITEMS * 2 then parts[#parts + 1] = inner .. "-- … " .. (#keys - i + 1) .. " más"; break end
            local key = (type(k) == "string" and k:match("^[%a_][%w_]*$")) and k or ("[" .. U.lit(k, inner, budget) .. "]")
            parts[#parts + 1] = inner .. key .. " = " .. U.lit(v[k], inner, budget) .. ","
        end
        if #parts == 0 then return "{}" end
        return "{\n" .. table.concat(parts, "\n") .. "\n" .. ind .. "}"
    end
    return "nil --[[" .. t .. ": " .. U.trunc(tostring(v), 60) .. "]]"
end
-- "ReplicatedStorage.Remotes.Damage" → game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Damage")
function U.pathCode(path)
    local parts = {}
    for p in tostring(path or ""):gmatch("[^%.]+") do parts[#parts + 1] = p end
    if #parts == 0 then return "nil" end
    local out
    if parts[1] == "Workspace" or parts[1] == "workspace" then out = "workspace"
    elseif parts[1] == "Players" or parts[1]:match("^[%u][%a]+$") then out = string.format('game:GetService(%q)', parts[1])
    else out = string.format("game:FindFirstChild(%q)", parts[1]) end
    for i = 2, #parts do out = out .. string.format(":WaitForChild(%q)", parts[i]) end
    return out
end
-- Código de solo lectura de una señal recibida: qué llegó y cómo se escucha.
function U.code(e, stamp, ...)
    local n = select("#", ...)
    local pack = {...}
    local lines = {
        "-- " .. STR.CODE.HEAD,
        "-- " .. string.format(STR.CODE.FROM, e.path, e.class),
        "-- " .. string.format(STR.CODE.AT, stamp, n),
        "local remote = " .. U.pathCode(e.path),
        "local args = {",
    }
    for i = 1, math.min(n, CONFIG.ARGS_MAX) do
        lines[#lines + 1] = "    [" .. i .. "] = " .. U.lit(pack[i], "    ") .. ",  -- " .. U.typeOf(pack[i])
    end
    lines[#lines + 1] = "}"
    lines[#lines + 1] = "-- " .. STR.CODE.LISTEN
    local signal = (e.class == "BindableEvent") and "Event" or "OnClientEvent"
    lines[#lines + 1] = "remote." .. signal .. ":Connect(function(...)"
    lines[#lines + 1] = "    print(\"" .. U.trunc(e.name, 40):gsub('"', "") .. "\", ...)"
    lines[#lines + 1] = "end)"
    return table.concat(lines, "\n")
end

function U.copy(text)
    if not CAP.setclipboard then return false end
    return (pcall(CAP.setclipboard, text))
end

function U.export(name, text)
    if not CAP.writefile then return false, STR.NO_WRITEFILE end
    if CAP.makefolder then
        pcall(function()
            if not (CAP.isfolder and CAP.isfolder(CONFIG.FOLDER)) then CAP.makefolder(CONFIG.FOLDER) end
        end)
    end
    local file = CONFIG.FOLDER .. "/" .. name
    local ok, err = pcall(CAP.writefile, file, text)
    if ok then return true, file end
    ok, err = pcall(CAP.writefile, name, text)
    if ok then return true, name end
    return false, tostring(err)
end

-- Exporta una lista de tablas planas a JSON (si hay HttpService) o devuelve nil.
function U.json(v)
    if not S.HttpService then return nil end
    local ok, s = pcall(function() return S.HttpService:JSONEncode(v) end)
    return ok and s or nil
end

-- 3.1 CFG — configuración persistente (GOY_Diag/config.json, si hay readfile/writefile)
local CFG = {data = {}, dirty = false, lastFlush = 0}
function CFG.load()
    if not (CAP.readfile and S.HttpService) then return end
    pcall(function()
        local file = CONFIG.FOLDER .. "/" .. CONFIG.CFG_FILE
        if CAP.isfile and not CAP.isfile(file) then return end
        local t = S.HttpService:JSONDecode(CAP.readfile(file))
        if type(t) == "table" then CFG.data = t end
    end)
end
function CFG.get(k, default)
    local v = CFG.data[k]
    if v == nil then return default end
    return v
end
function CFG.set(k, v)
    if CFG.data[k] ~= v then CFG.data[k] = v; CFG.dirty = true end
end
function CFG.flush(force)
    if not CFG.dirty or not CAP.writefile then return end
    if not force and os.clock() - CFG.lastFlush < CONFIG.CFG_FLUSH_SEC then return end
    local raw = U.json(CFG.data)
    if not raw then return end
    CFG.dirty, CFG.lastFlush = false, os.clock()
    U.export(CONFIG.CFG_FILE, raw)
end
CFG.load()

-------------------------------------------------------------------------------
-- 4. LOG — búfer circular + limitador por fuente con aviso temporizado
-------------------------------------------------------------------------------
local LOG = {max = CONFIG.LOG_MAX, buf = {}, n = 0, total = 0, paused = false, droppedPaused = 0,
    suppressed = 0, perCat = {}, version = 0, listeners = {}}
local CATS = STR.CATS

-- Campos opcionales en `meta`: alert, kind, player, userId, remote (feed del servidor).
function LOG.add(cat, name, dir, args, types, extra, meta)
    if LOG.paused then LOG.droppedPaused = LOG.droppedPaused + 1 return end
    LOG.total = LOG.total + 1
    LOG.perCat[cat] = (LOG.perCat[cat] or 0) + 1
    local e = {id = LOG.total, t = U.stamp(), clock = os.clock(), cat = cat, name = tostring(name or "?"), dir = dir or "",
        args = args or "", types = type(types) == "table" and table.concat(types, ", ") or (types or ""), extra = extra or ""}
    if meta then
        e.alert, e.kind, e.player, e.userId, e.remote, e.code = meta.alert, meta.kind, meta.player, meta.userId, meta.remote, meta.code
    end
    LOG.buf[((LOG.total - 1) % LOG.max) + 1] = e
    if LOG.n < LOG.max then LOG.n = LOG.n + 1 end
    LOG.version = LOG.version + 1
    for _, fn in ipairs(LOG.listeners) do U.try("oyente de registro", fn, e) end
    if G.onLog then G.onLog(e) end
    return e
end

-- Del más nuevo al más viejo; fn devuelve false para parar.
function LOG.iter(fn)
    for k = 0, LOG.n - 1 do
        local e = LOG.buf[((LOG.total - k - 1) % LOG.max) + 1]
        if e and fn(e) == false then return end
    end
end

function LOG.clear()
    LOG.buf, LOG.n, LOG.total, LOG.perCat = {}, 0, 0, {}
    LOG.suppressed, LOG.droppedPaused = 0, 0
    LOG.version = LOG.version + 1
end

function LOG.format(e)
    local s = "[" .. e.t .. "] [" .. e.cat .. "] " .. e.name
    if e.dir ~= "" then s = s .. "  (" .. e.dir .. ")" end
    if e.player then s = s .. "\n  jugador: " .. tostring(e.player) .. (e.userId and (" (UserId " .. tostring(e.userId) .. ")") or "") end
    if e.remote then s = s .. "\n  remoto: " .. tostring(e.remote) end
    if e.types ~= "" then s = s .. "\n  tipos: " .. e.types end
    if e.args ~= "" then s = s .. "\n  " .. e.args:gsub("\n", "\n  ") end
    if e.extra ~= "" then s = s .. "\n  " .. e.extra end
    return s
end

function LOG.toRecord(e)
    return {t = e.t, cat = e.cat, name = e.name, dir = e.dir, kind = e.kind, player = e.player, userId = e.userId,
        remote = e.remote, types = e.types, args = e.args, extra = e.extra, alert = e.alert or false}
end

-- Limitador: `limit` registros por ventana por fuente; el exceso se cuenta y se
-- avisa al cerrar la ventana, aunque no llegue otro evento (RATE.flush).
local RATE = {active = setmetatable({}, {__mode = "k"})}
local function emitSuppressed(entry)
    if (entry.winSupp or 0) <= 0 then return end
    LOG.add("Sistema", string.format(STR.LIMIT_NAME, tostring(entry.rateName or entry.name or "fuente")), "", "", nil,
        string.format(STR.LIMIT_MSG, entry.winSupp, CONFIG.RATE_WINDOW), {alert = true, kind = "Spam"})
    entry.winSupp = 0
end
function RATE.ok(entry, name, limit)
    local now = os.clock()
    if name then entry.rateName = name end
    if not entry.winStart or now - entry.winStart >= CONFIG.RATE_WINDOW then
        emitSuppressed(entry)
        entry.winStart, entry.winCount, entry.winSupp = now, 0, 0
    end
    entry.winCount = entry.winCount + 1
    if entry.winCount > (limit or CONFIG.RATE_PER_SOURCE) then
        entry.winSupp = entry.winSupp + 1
        LOG.suppressed = LOG.suppressed + 1
        RATE.active[entry] = true
        return false
    end
    return true
end
function RATE.flush()
    local now = os.clock()
    for entry in pairs(RATE.active) do
        if now - (entry.winStart or 0) >= CONFIG.RATE_WINDOW then
            emitSuppressed(entry)
            RATE.active[entry] = nil
        end
    end
end
