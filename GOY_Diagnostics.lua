--[[
================================================================================
 GOY DIAGNOSTICS v1.0  ·  Advanced Remote & Server Diagnostics (solo lectura)
 Cliente Roblox · optimizado para iPhone + Delta
--------------------------------------------------------------------------------
 QUÉ HACE (todo desde el cliente, sin tocar el juego):
   · REMOTES  : encuentra RemoteEvent / UnreliableRemoteEvent / RemoteFunction /
                BindableEvent / BindableFunction en los contenedores replicados y
                registra lo que el cliente PUEDE observar: OnClientEvent (servidor
                → cliente) y BindableEvent.Event (local).
   · TOOLS    : herramientas que aparecen/desaparecen, equipadas/desequipadas,
                contenedores, búsqueda de objetos e inspector de propiedades.
   · BUTTONS  : TextButton / ImageButton de tu PlayerGui (texto, ruta, visible,
                clics observados con .Activated).
   · LOGS     : registro en tiempo real con hora, categoría, argumentos y tipos,
                búsqueda, filtros, pausa, limpieza, copiar y exportar.
   · PERFORMANCE: FPS, tiempo de frame, memoria, ping, red, errores de consola,
                y el costo del propio monitor.
 QUÉ NO HACE (límites reales, no se intentan eludir):
   · No ve lo que el cliente ENVÍA (FireServer / InvokeServer): no se hookea
     __namecall ni se modifican metatablas.
   · No ve RemoteFunction.OnClientInvoke ni BindableFunction.OnInvoke sin
     REEMPLAZAR el callback del juego, así que solo se listan.
   · No lee código del servidor ni eventos internos del servidor.
   · Para eso: script de Studio (pestaña MAIN → "Copiar script de Studio"),
     solo para TU propio juego.
================================================================================
]]

local ENV = (type(getgenv) == "function" and getgenv()) or _G
if type(ENV.GOY_DIAG) == "table" and type(ENV.GOY_DIAG.destroy) == "function" then
    pcall(ENV.GOY_DIAG.destroy)
end

local G = {alive = true, conns = {}, internalErrors = 0, lastInternalError = ""}
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
}
local LP = S.Players and S.Players.LocalPlayer
if not LP then warn("[GOY DIAG] Sin LocalPlayer: este script es de cliente.") return end

-- Contenedores que se exploran (solo los que existan y sean accesibles).
local WATCH_NAMES = {"Workspace", "ReplicatedStorage", "ReplicatedFirst", "Players", "Lighting",
    "StarterGui", "StarterPack", "StarterPlayer", "SoundService", "Teams", "Chat", "TextChatService"}

---------------------------------------------------------------- CAPACIDADES
-- Se comprueba cada función del ejecutor ANTES de usarla.
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
    CAP.makefolder = fn("makefolder")
    CAP.isfolder = fn("isfolder")
    CAP.gethui = fn("gethui")
    CAP.identifyexecutor = fn("identifyexecutor") or fn("getexecutorname")
    CAP.executor = "desconocido"
    if CAP.identifyexecutor then
        local ok, a, b = pcall(CAP.identifyexecutor)
        if ok and a then CAP.executor = tostring(a) .. (b and (" " .. tostring(b)) or "") end
    end
    CAP.touch = false
    pcall(function() CAP.touch = S.UIS.TouchEnabled end)
end

---------------------------------------------------------------- UTILIDADES
local U = {}
local unpackf = table.unpack or unpack

function U.conn(signal, fn)
    if not signal then return nil end
    local ok, c = pcall(function()
        return signal:Connect(function(...)
            if not G.alive then return end
            local ok2, err = pcall(fn, ...)
            if not ok2 then
                G.internalErrors = G.internalErrors + 1
                G.lastInternalError = tostring(err)
            end
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

function U.clock() return os.clock() end

-- Roblox solo garantiza os.date("*t"), así que se arma la hora a mano.
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

-- Serializador seguro: límite de profundidad, de elementos y de longitud;
-- detecta referencias circulares. Nunca llama metamétodos del juego sin pcall.
function U.ser(v, depth, seen, budget)
    depth = depth or 0
    seen = seen or {}
    budget = budget or {n = 0}
    budget.n = budget.n + 1
    if budget.n > 80 then return "…" end
    local t = U.typeOf(v)
    if t == "string" then
        return string.format("%q", U.trunc(v, 120))
    elseif t == "number" or t == "boolean" or t == "nil" then
        return tostring(v)
    elseif t == "Instance" then
        local ok, cn = pcall(function() return v.ClassName end)
        return (ok and cn or "Instance") .. "(" .. U.trunc(U.path(v), 90) .. ")"
    elseif t == "table" then
        if seen[v] then return "<circular>" end
        if depth >= 3 then return "{…}" end
        seen[v] = true
        local parts, count = {}, 0
        local ok = pcall(function()
            for k, val in next, v do
                count = count + 1
                if count > 12 then parts[#parts + 1] = "…"; break end
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
    else
        local ok, s = pcall(tostring, v)
        return t .. "(" .. U.trunc(ok and s or "?", 80) .. ")"
    end
end

-- Devuelve (texto de argumentos, lista de tipos, número de argumentos)
function U.args(...)
    local n = select("#", ...)
    local pack = {...}
    local parts, types = {}, {}
    for i = 1, math.min(n, 10) do
        local t = U.typeOf(pack[i])
        types[#types + 1] = t
        parts[#parts + 1] = i .. ": " .. t .. " = " .. U.ser(pack[i])
    end
    if n > 10 then parts[#parts + 1] = "… +" .. (n - 10) .. " argumentos" end
    if n == 0 then parts[1] = "(sin argumentos)" end
    return table.concat(parts, "\n"), types, n
end

function U.copy(text)
    if CAP.setclipboard then
        local ok = pcall(CAP.setclipboard, text)
        if ok then return true end
    end
    return false
end

function U.export(name, text)
    if not CAP.writefile then return false, "writefile no disponible en este ejecutor" end
    local folder = "GOY_Diag"
    if CAP.makefolder then
        pcall(function()
            if not (CAP.isfolder and CAP.isfolder(folder)) then CAP.makefolder(folder) end
        end)
    end
    local file = folder .. "/" .. name
    local ok, err = pcall(CAP.writefile, file, text)
    if ok then return true, file end
    -- sin carpeta
    ok, err = pcall(CAP.writefile, name, text)
    if ok then return true, name end
    return false, tostring(err)
end

---------------------------------------------------------------- REGISTRO (LOG)
-- Búfer circular: nunca crece más de MAX entradas.
local LOG = {max = 700, buf = {}, n = 0, total = 0, paused = false, droppedPaused = 0,
    suppressed = 0, perCat = {}, version = 0}
local CATS = {"Todas", "Remote", "Bindable", "Tool", "Instancia", "Cambio", "Valor", "Botón", "Consola", "Servidor", "Sistema"}

function LOG.add(cat, name, dir, args, types, extra)
    if LOG.paused then LOG.droppedPaused = LOG.droppedPaused + 1 return end
    LOG.total = LOG.total + 1
    LOG.perCat[cat] = (LOG.perCat[cat] or 0) + 1
    local e = {id = LOG.total, t = U.stamp(), cat = cat, name = tostring(name or "?"), dir = dir or "",
        args = args or "", types = types and table.concat(types, ", ") or "", extra = extra or ""}
    local idx = ((LOG.total - 1) % LOG.max) + 1
    LOG.buf[idx] = e
    if LOG.n < LOG.max then LOG.n = LOG.n + 1 end
    LOG.version = LOG.version + 1
    if G.onLog then G.onLog(e) end
end

-- Recorre del más nuevo al más viejo.
function LOG.iter(fn)
    for k = 0, LOG.n - 1 do
        local id = LOG.total - k
        local e = LOG.buf[((id - 1) % LOG.max) + 1]
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
    if e.types ~= "" then s = s .. "\n  tipos: " .. e.types end
    if e.args ~= "" then s = s .. "\n  " .. e.args:gsub("\n", "\n  ") end
    if e.extra ~= "" then s = s .. "\n  " .. e.extra end
    return s
end

-- Limitador por fuente: máximo 12 registros/s por objeto; el resto solo se cuenta.
function U.rateOk(entry)
    local now = os.clock()
    if not entry.winStart or now - entry.winStart >= 1 then
        if entry.winSupp and entry.winSupp > 0 then
            LOG.add("Sistema", entry.name or "?", "", "", nil,
                entry.winSupp .. " eventos más en 1 s no se guardaron en el registro (spam), sí se contaron")
        end
        entry.winStart, entry.winCount, entry.winSupp = now, 0, 0
    end
    entry.winCount = entry.winCount + 1
    if entry.winCount > 12 then
        entry.winSupp = entry.winSupp + 1
        LOG.suppressed = LOG.suppressed + 1
        return false
    end
    return true
end

---------------------------------------------------------------- REGISTROS DE OBJETOS
local REG = {
    remotes = {}, remoteByInst = setmetatable({}, {__mode = "k"}), remoteVersion = 0,
    tools = {}, toolByInst = setmetatable({}, {__mode = "k"}), toolVersion = 0,
    buttons = {}, buttonByInst = setmetatable({}, {__mode = "k"}), buttonVersion = 0,
    containers = {}, watched = {}, scanDone = false, scanned = 0,
    valueConns = 0, instAdded = 0, instRemoved = 0, logWorkspaceInstances = false,
}
local REMOTE_CLASSES = {RemoteEvent = true, UnreliableRemoteEvent = true, RemoteFunction = true,
    BindableEvent = true, BindableFunction = true}
local GUI_ROOT -- se asigna al crear la interfaz (para ignorar nuestra propia GUI)

local function isOwnGui(inst)
    if not GUI_ROOT then return false end
    local ok, r = pcall(function() return inst == GUI_ROOT or inst:IsDescendantOf(GUI_ROOT) end)
    return ok and r
end

local function locationOf(inst, rootName)
    if rootName == "Players" then
        local ok, r = pcall(function()
            if inst:IsDescendantOf(LP) then
                local pg = LP:FindFirstChildOfClass("PlayerGui")
                if pg and inst:IsDescendantOf(pg) then return "Tu PlayerGui" end
                local bp = LP:FindFirstChildOfClass("Backpack")
                if bp and inst:IsDescendantOf(bp) then return "Tu Backpack" end
                return "Tu jugador"
            end
            return "Players"
        end)
        return ok and r or "Players"
    end
    return rootName
end

local function remoteDirection(class)
    if class == "RemoteEvent" or class == "UnreliableRemoteEvent" then
        return "Servidor → Cliente (OnClientEvent observado)"
    elseif class == "BindableEvent" then
        return "Local (BindableEvent.Event observado)"
    elseif class == "RemoteFunction" then
        return "No observable: OnClientInvoke solo se ve reemplazando el callback (no se hace)"
    else
        return "No observable: OnInvoke solo se ve reemplazando el callback (no se hace)"
    end
end

local function addRemote(inst, rootName, class)
    if REG.remoteByInst[inst] then return end
    local e = {inst = inst, name = inst.Name, class = class, path = U.path(inst), loc = locationOf(inst, rootName),
        count = 0, last = nil, lastArgs = "", lastTypes = "", observable = false, removed = false,
        addedAt = U.stamp(), dir = remoteDirection(class)}
    if class == "RemoteEvent" or class == "UnreliableRemoteEvent" then
        e.observable = true
        e.conn = U.conn(inst.OnClientEvent, function(...)
            e.count = e.count + 1
            e.last = U.stamp()
            REG.remoteVersion = REG.remoteVersion + 1
            if not U.rateOk(e) then return end
            local a, types = U.args(...)
            e.lastArgs, e.lastTypes = a, table.concat(types, ", ")
            if e.name == "GOY_DiagFeed" then
                -- Canal de tu script de Studio (solo existe en TU juego instrumentado).
                LOG.add("Servidor", "Instrumentación", "Servidor (instrumentado)", a, types, e.path)
            else
                LOG.add("Remote", e.name, "Servidor → Cliente", a, types, e.path)
            end
        end)
    elseif class == "BindableEvent" then
        e.observable = true
        e.conn = U.conn(inst.Event, function(...)
            e.count = e.count + 1
            e.last = U.stamp()
            REG.remoteVersion = REG.remoteVersion + 1
            if not U.rateOk(e) then return end
            local a, types = U.args(...)
            e.lastArgs, e.lastTypes = a, table.concat(types, ", ")
            LOG.add("Bindable", e.name, "Local", a, types, e.path)
        end)
    end
    e.nameConn = U.conn(inst:GetPropertyChangedSignal("Name"), function()
        e.name = inst.Name
        e.path = U.path(inst)
        REG.remoteVersion = REG.remoteVersion + 1
    end)
    REG.remoteByInst[inst] = e
    REG.remotes[#REG.remotes + 1] = e
    REG.remoteVersion = REG.remoteVersion + 1
    if REG.scanDone then
        LOG.add("Instancia", e.name, "", "", nil, "Nuevo " .. class .. " en " .. e.path)
    end
end

local function removeRemote(inst)
    local e = REG.remoteByInst[inst]
    if not e then return end
    U.disc(e.conn); U.disc(e.nameConn)
    e.removed = true
    REG.remoteByInst[inst] = nil
    for i = #REG.remotes, 1, -1 do
        if REG.remotes[i] == e then table.remove(REG.remotes, i) break end
    end
    REG.remoteVersion = REG.remoteVersion + 1
    LOG.add("Instancia", e.name, "", "", nil, e.class .. " eliminado: " .. e.path)
end

local function toolOwner(tool)
    local ok, r, st = pcall(function()
        local p = tool.Parent
        if not p then return "—", "fuera" end
        if p:IsA("Backpack") then
            local pl = p.Parent
            return (pl and pl.Name or "?"), "en Backpack"
        end
        local pl = S.Players:GetPlayerFromCharacter(p)
        if pl then return pl.Name, "equipada" end
        return "—", "en " .. p.Name
    end)
    if ok then return r, st end
    return "?", "?"
end

local function addTool(inst, rootName)
    if REG.toolByInst[inst] then return end
    local e = {inst = inst, name = inst.Name, class = inst.ClassName, loc = rootName, equips = 0, removed = false}
    e.path = U.path(inst)
    local function upd(reason)
        local ok, owner, state = pcall(toolOwner, inst)
        e.owner = ok and owner or "?"
        e.state = ok and state or "?"
        e.path = U.path(inst)
        REG.toolVersion = REG.toolVersion + 1
        if reason then LOG.add("Tool", e.name, "", "", nil, reason .. " · dueño: " .. tostring(e.owner) .. " · " .. tostring(e.state)) end
    end
    upd(REG.scanDone and "Herramienta apareció" or nil)
    e.anc = U.conn(inst.AncestryChanged, function() if inst.Parent then upd("Cambió de lugar") end end)
    pcall(function()
        e.eq = U.conn(inst.Equipped, function() e.equips = e.equips + 1 upd("Equipada") end)
        e.uneq = U.conn(inst.Unequipped, function() upd("Desequipada") end)
        e.act = U.conn(inst.Activated, function() LOG.add("Tool", e.name, "", "", nil, "Activada (usada)") end)
    end)
    REG.toolByInst[inst] = e
    REG.tools[#REG.tools + 1] = e
end

local function removeTool(inst)
    local e = REG.toolByInst[inst]
    if not e then return end
    -- Si solo cambió de lugar (Backpack ↔ Character) sigue en el árbol: no se elimina.
    task.defer(function()
        local ok, still = pcall(function() return inst:IsDescendantOf(game) end)
        if ok and still then return end
        U.disc(e.anc); U.disc(e.eq); U.disc(e.uneq); U.disc(e.act)
        REG.toolByInst[inst] = nil
        for i = #REG.tools, 1, -1 do
            if REG.tools[i] == e then table.remove(REG.tools, i) break end
        end
        REG.toolVersion = REG.toolVersion + 1
        LOG.add("Tool", e.name, "", "", nil, "Herramienta desapareció")
    end)
end

-- Botones de interfaz (solo tu PlayerGui: es lo que el cliente puede ver).
local function addButton(inst)
    if REG.buttonByInst[inst] or isOwnGui(inst) then return end
    local e = {inst = inst, name = inst.Name, class = inst.ClassName, clicks = 0, lastClick = nil}
    e.path = U.path(inst)
    e.conn = U.conn(inst.Activated, function()
        e.clicks = e.clicks + 1
        e.lastClick = U.stamp()
        REG.buttonVersion = REG.buttonVersion + 1
        local txt = ""
        pcall(function() txt = inst.Text or "" end)
        LOG.add("Botón", e.name, "Interfaz local", "", nil,
            (txt ~= "" and ("texto: " .. U.trunc(txt, 60) .. " · ") or "") .. e.path ..
            " · la función interna del botón no es visible")
    end)
    REG.buttonByInst[inst] = e
    REG.buttons[#REG.buttons + 1] = e
    REG.buttonVersion = REG.buttonVersion + 1
end

local function removeButton(inst)
    local e = REG.buttonByInst[inst]
    if not e then return end
    U.disc(e.conn)
    REG.buttonByInst[inst] = nil
    for i = #REG.buttons, 1, -1 do
        if REG.buttons[i] == e then table.remove(REG.buttons, i) break end
    end
    REG.buttonVersion = REG.buttonVersion + 1
end

-- Valores de TU jugador (leaderstats, etc.): cambios visibles.
local function addValue(inst)
    if REG.valueConns >= 250 then return end
    REG.valueConns = REG.valueConns + 1
    local last = nil
    pcall(function() last = inst.Value end)
    local entry = {name = inst.Name}
    U.conn(inst.Changed, function()
        if not U.rateOk(entry) then return end
        local newv = nil
        pcall(function() newv = inst.Value end)
        local before = U.ser(last)
        last = newv
        LOG.add("Valor", inst.Name, "Servidor → Cliente (replicado)", before .. "  →  " .. U.ser(newv),
            {U.typeOf(newv)}, U.path(inst))
    end)
end

local function classify(inst, rootName, initial)
    local ok, cls = pcall(function() return inst.ClassName end)
    if not ok then return end
    if REMOTE_CLASSES[cls] then
        addRemote(inst, rootName, cls)
    elseif cls == "Tool" or cls == "HopperBin" then
        addTool(inst, rootName)
    elseif cls == "TextButton" or cls == "ImageButton" then
        if rootName == "Players" then addButton(inst) end
    elseif rootName == "Players" then
        local okv, isv = pcall(function() return inst:IsA("ValueBase") and inst:IsDescendantOf(LP) end)
        if okv and isv then
            local inGui = false
            pcall(function() inGui = inst:FindFirstAncestorOfClass("PlayerGui") ~= nil end)
            if not inGui then addValue(inst) end
        end
    end
end

local function watchContainer(root, rootName)
    local c = {name = rootName, inst = root, count = 0, added = 0, removed = 0}
    REG.containers[#REG.containers + 1] = c
    REG.watched[root] = c
    U.conn(root.DescendantAdded, function(inst)
        c.count = c.count + 1
        c.added = c.added + 1
        REG.instAdded = REG.instAdded + 1
        if isOwnGui(inst) then return end
        classify(inst, rootName, false)
        if REG.scanDone and (rootName ~= "Workspace" or REG.logWorkspaceInstances) and rootName ~= "Players" then
            if U.rateOk(c) then
                local okc, cls = pcall(function() return inst.ClassName end)
                LOG.add("Instancia", inst.Name, "", "", nil, "Nueva " .. tostring(okc and cls or "?") .. " en " .. U.path(inst))
            end
        end
    end)
    U.conn(root.DescendantRemoving, function(inst)
        c.count = math.max(0, c.count - 1)
        c.removed = c.removed + 1
        REG.instRemoved = REG.instRemoved + 1
        if REG.remoteByInst[inst] then removeRemote(inst) end
        if REG.toolByInst[inst] then removeTool(inst) end
        if REG.buttonByInst[inst] then removeButton(inst) end
    end)
end

-- Escaneo inicial por partes (no congela el juego).
local function initialScan()
    local roots = {}
    for _, name in ipairs(WATCH_NAMES) do
        local s = svc(name)
        if s then
            roots[#roots + 1] = {s, name}
            watchContainer(s, name)
        end
    end
    for _, r in ipairs(roots) do
        local ok, list = pcall(function() return r[1]:GetDescendants() end)
        if ok and list then
            local c = REG.watched[r[1]]
            c.count = #list
            for i, inst in ipairs(list) do
                if not G.alive then return end
                classify(inst, r[2], true)
                REG.scanned = REG.scanned + 1
                if i % 400 == 0 then task.wait() end
            end
        end
    end
    REG.scanDone = true
    LOG.add("Sistema", "Escaneo inicial", "", "", nil,
        REG.scanned .. " objetos revisados · " .. #REG.remotes .. " remotos/bindables · " ..
        #REG.tools .. " herramientas · " .. #REG.buttons .. " botones")
end

-- Atributos de tu jugador y personaje.
local function watchAttributes(inst, label)
    U.conn(inst.AttributeChanged, function(attr)
        local v = nil
        pcall(function() v = inst:GetAttribute(attr) end)
        LOG.add("Cambio", label .. "@" .. tostring(attr), "Replicado", U.ser(v), {U.typeOf(v)}, U.path(inst))
    end)
end

-- Objetos vigilados manualmente desde el inspector (.Changed).
local WATCH = {list = {}, max = 8}
function WATCH.toggle(inst)
    for i, w in ipairs(WATCH.list) do
        if w.inst == inst then
            U.disc(w.conn)
            table.remove(WATCH.list, i)
            return false
        end
    end
    if #WATCH.list >= WATCH.max then
        local old = table.remove(WATCH.list, 1)
        U.disc(old.conn)
    end
    local w = {inst = inst, name = inst.Name}
    w.conn = U.conn(inst.Changed, function(prop)
        if not U.rateOk(w) then return end
        local v = nil
        pcall(function() v = inst[prop] end)
        LOG.add("Cambio", w.name .. "." .. tostring(prop), "Observado", U.ser(v), {U.typeOf(v)}, U.path(inst))
    end)
    WATCH.list[#WATCH.list + 1] = w
    return true
end
function WATCH.has(inst)
    for _, w in ipairs(WATCH.list) do if w.inst == inst then return true end end
    return false
end

---------------------------------------------------------------- CONSOLA (LogService)
local CONSOLE = {errors = 0, warnings = 0, infos = 0, last = {}}
do
    if S.LogService then
        U.conn(S.LogService.MessageOut, function(msg, mtype)
            local t = tostring(mtype)
            if t:find("Error") then
                CONSOLE.errors = CONSOLE.errors + 1
            elseif t:find("Warning") then
                CONSOLE.warnings = CONSOLE.warnings + 1
            else
                CONSOLE.infos = CONSOLE.infos + 1
                return
            end
            local m = tostring(msg)
            if m:find("GOY DIAG", 1, true) then return end
            if U.rateOk(CONSOLE) then
                LOG.add("Consola", t:find("Error") and "Error" or "Advertencia", "Consola del cliente", U.trunc(m, 400), nil, "")
            end
        end)
    end
end

---------------------------------------------------------------- RENDIMIENTO
local PERF = {fps = 0, frames = 0, frameMax = 0, frameAvg = 0, accum = 0, win = os.clock(),
    hist = {}, ping = nil, pingSrc = "", mem = nil, memScript = nil, luaHeap = nil, physFps = nil,
    recv = nil, send = nil, instCount = nil, renderMs = 0, renders = 0, renderRate = 0,
    renderWin = os.clock(), renderWinCount = 0, logRate = 0, logWinStart = os.clock(), logWinTotal = 0}

do
    local sig = S.RunService and (S.RunService.RenderStepped or S.RunService.Heartbeat)
    U.conn(sig, function(dt)
        PERF.frames = PERF.frames + 1
        PERF.accum = PERF.accum + (dt or 0)
        if (dt or 0) > PERF.frameMax then PERF.frameMax = dt end
        local now = os.clock()
        if now - PERF.win >= 1 then
            PERF.fps = PERF.frames / (now - PERF.win)
            PERF.frameAvg = PERF.frames > 0 and (PERF.accum / PERF.frames) or 0
            PERF.lastFrameMax = PERF.frameMax
            PERF.frames, PERF.accum, PERF.frameMax, PERF.win = 0, 0, 0, now
            PERF.hist[#PERF.hist + 1] = math.floor(PERF.fps + 0.5)
            if #PERF.hist > 30 then table.remove(PERF.hist, 1) end
        end
    end)
end

function PERF.sample()
    -- Cada métrica es opcional: si la API no existe o falla, queda "no disponible".
    PERF.ping, PERF.pingSrc = nil, ""
    pcall(function()
        local p = LP:GetNetworkPing()
        if type(p) == "number" then PERF.ping = p * 1000; PERF.pingSrc = "Player:GetNetworkPing()" end
    end)
    if not PERF.ping then
        pcall(function()
            local item = S.Stats.Network.ServerStatsItem["Data Ping"]
            PERF.ping = item:GetValue()
            PERF.pingSrc = "Stats Data Ping"
        end)
    end
    pcall(function() PERF.mem = S.Stats:GetTotalMemoryUsageMb() end)
    pcall(function() PERF.memScript = S.Stats:GetMemoryUsageMbForTag(Enum.DeveloperMemoryTag.Script) end)
    pcall(function() PERF.luaHeap = collectgarbage("count") / 1024 end)
    pcall(function() PERF.physFps = workspace:GetRealPhysicsFPS() end)
    pcall(function() PERF.recv = S.Stats.DataReceiveKbps end)
    pcall(function() PERF.send = S.Stats.DataSendKbps end)
    pcall(function() PERF.instCount = S.Stats.InstanceCount end)
    local now = os.clock()
    if now - PERF.logWinStart >= 1 then
        PERF.logRate = math.max(0, LOG.total - PERF.logWinTotal) / (now - PERF.logWinStart)
        PERF.logWinTotal, PERF.logWinStart = LOG.total, now
    end
end

---------------------------------------------------------------- INTERFAZ
local TH = {
    bg = Color3.fromRGB(10, 12, 20), panel = Color3.fromRGB(16, 18, 30), card = Color3.fromRGB(22, 25, 42),
    card2 = Color3.fromRGB(28, 31, 52), line = Color3.fromRGB(45, 50, 80),
    cyan = Color3.fromRGB(0, 220, 255), violet = Color3.fromRGB(150, 90, 255),
    text = Color3.fromRGB(226, 232, 245), dim = Color3.fromRGB(140, 150, 175),
    ok = Color3.fromRGB(70, 230, 140), warn = Color3.fromRGB(255, 200, 70), bad = Color3.fromRGB(255, 90, 110),
}
local HEX = {cyan = "#00DCFF", violet = "#A673FF", dim = "#8C96AF", ok = "#46E68C", warn = "#FFC846",
    bad = "#FF5A6E", text = "#E2E8F5", pink = "#FF7AD9", blue = "#6FA8FF"}
local CLASS_HEX = {RemoteEvent = HEX.cyan, UnreliableRemoteEvent = HEX.blue, RemoteFunction = HEX.violet,
    BindableEvent = HEX.ok, BindableFunction = HEX.pink}
local CAT_HEX = {Remote = HEX.cyan, Bindable = HEX.ok, Tool = HEX.warn, Instancia = HEX.dim, Cambio = HEX.pink,
    Valor = HEX.blue, ["Botón"] = HEX.violet, Consola = HEX.bad, Servidor = HEX.ok, Sistema = HEX.text}

local UI = {tab = "MAIN", open = false, pages = {}, lists = {}, seen = {}, filters = {}, mode = {}}

local function mk(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do
        pcall(function() o[k] = v end)
    end
    if parent then o.Parent = parent end
    return o
end
local function corner(o, r) return mk("UICorner", {CornerRadius = UDim.new(0, r or 8)}, o) end
local function stroke(o, c, t, tr) return mk("UIStroke", {Color = c or TH.line, Thickness = t or 1, Transparency = tr or 0}, o) end
local function pad(o, p) return mk("UIPadding", {PaddingLeft = UDim.new(0, p), PaddingRight = UDim.new(0, p), PaddingTop = UDim.new(0, p), PaddingBottom = UDim.new(0, p)}, o) end

-- Padre de la GUI: gethui (si existe) → CoreGui → PlayerGui.
local function guiParent()
    if CAP.gethui then
        local ok, h = pcall(CAP.gethui)
        if ok and h then return h end
    end
    local ok = pcall(function()
        local probe = Instance.new("Folder")
        probe.Parent = S.CoreGui
        probe:Destroy()
    end)
    if ok and S.CoreGui then return S.CoreGui end
    return LP:WaitForChild("PlayerGui")
end

local parentGui = guiParent()
pcall(function()
    local old = parentGui:FindFirstChild("GOY_Diagnostics")
    if old then old:Destroy() end
end)
local screen = mk("ScreenGui", {Name = "GOY_Diagnostics", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999})
GUI_ROOT = screen
screen.Parent = parentGui

local vp = Vector2.new(844, 390)
pcall(function() vp = workspace.CurrentCamera.ViewportSize end)
local PW = math.floor(math.clamp(vp.X * 0.92, 320, 620))
local PH = math.floor(math.clamp(vp.Y * 0.86, 260, 430))

---------------- Arrastre táctil (sin APIs de escritorio)
local function draggable(handle, target, onTap)
    local dragging, startPos, startUD, moved = false, nil, nil, false
    U.conn(handle.InputBegan, function(input)
        local t = input.UserInputType
        if t == Enum.UserInputType.Touch or t == Enum.UserInputType.MouseButton1 then
            dragging, moved = true, false
            startPos, startUD = input.Position, target.Position
            local c
            c = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if c then c:Disconnect() end
                end
            end)
        end
    end)
    U.conn(S.UIS.InputChanged, function(input)
        if not dragging then return end
        local t = input.UserInputType
        if t == Enum.UserInputType.Touch or t == Enum.UserInputType.MouseMovement then
            local d = input.Position - startPos
            if math.abs(d.X) + math.abs(d.Y) > 8 then moved = true end
            if moved then
                target.Position = UDim2.new(startUD.X.Scale, startUD.X.Offset + d.X, startUD.Y.Scale, startUD.Y.Offset + d.Y)
            end
        end
    end)
    if onTap then
        U.conn(handle.Activated, function()
            if not moved then onTap() end
            moved = false
        end)
    end
end

---------------- Botón flotante
local fab = mk("TextButton", {Name = "Fab", Size = UDim2.fromOffset(58, 58), Position = UDim2.new(1, -74, 0.3, 0),
    BackgroundColor3 = TH.panel, Text = "GOY", TextColor3 = TH.text, Font = Enum.Font.GothamBlack, TextSize = 15,
    AutoButtonColor = false, ZIndex = 50}, screen)
corner(fab, 29)
stroke(fab, TH.cyan, 2)
mk("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(0, 120, 160), Color3.fromRGB(90, 40, 170)), Rotation = 45}, fab)
local fabDot = mk("Frame", {Size = UDim2.fromOffset(12, 12), Position = UDim2.new(1, -14, 0, 2), BackgroundColor3 = TH.ok, ZIndex = 51}, fab)
corner(fabDot, 6)

---------------- Panel
local panel = mk("Frame", {Name = "Panel", Size = UDim2.fromOffset(PW, PH), Position = UDim2.new(0.5, -PW / 2, 0.5, -PH / 2),
    BackgroundColor3 = TH.bg, Visible = false, ZIndex = 10, Active = true}, screen)
corner(panel, 14)
stroke(panel, TH.cyan, 1.5, 0.2)
mk("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(205, 200, 255)), Rotation = 90}, panel)

local header = mk("TextButton", {Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = TH.panel, Text = "", AutoButtonColor = false, ZIndex = 11}, panel)
corner(header, 14)
mk("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(0, 70, 95), Color3.fromRGB(55, 25, 105)), Rotation = 0}, header)
local statusDot = mk("Frame", {Size = UDim2.fromOffset(10, 10), Position = UDim2.new(0, 12, 0.5, -5), BackgroundColor3 = TH.ok, ZIndex = 12}, header)
corner(statusDot, 5)
mk("TextLabel", {Size = UDim2.new(1, -150, 1, 0), Position = UDim2.fromOffset(30, 0), BackgroundTransparency = 1,
    RichText = true, Text = '<font color="' .. HEX.cyan .. '">GOY</font> DIAGNOSTICS <font color="' .. HEX.dim .. '">· solo lectura</font>',
    TextColor3 = TH.text, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12}, header)
local function headBtn(txt, x, color)
    local b = mk("TextButton", {Size = UDim2.fromOffset(40, 30), Position = UDim2.new(1, x, 0.5, -15), BackgroundColor3 = TH.card2,
        Text = txt, TextColor3 = color or TH.text, Font = Enum.Font.GothamBold, TextSize = 16, ZIndex = 12, AutoButtonColor = true}, header)
    corner(b, 8)
    return b
end
local closeBtn = headBtn("×", -46, TH.bad)
local minBtn = headBtn("–", -92)

local tabBar = mk("ScrollingFrame", {Size = UDim2.new(1, -16, 0, 40), Position = UDim2.fromOffset(8, 42), BackgroundTransparency = 1,
    ScrollBarThickness = 0, ScrollingDirection = Enum.ScrollingDirection.X, AutomaticCanvasSize = Enum.AutomaticSize.X,
    CanvasSize = UDim2.new(0, 0, 0, 0), ZIndex = 11}, panel)
mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, tabBar)

local body = mk("Frame", {Size = UDim2.new(1, -16, 1, -112), Position = UDim2.fromOffset(8, 86), BackgroundTransparency = 1,
    ClipsDescendants = true, ZIndex = 11}, panel)
local footer = mk("TextLabel", {Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 10, 1, -24), BackgroundTransparency = 1,
    Text = "", RichText = true, TextColor3 = TH.dim, Font = Enum.Font.Gotham, TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 11}, panel)

local toastLbl = mk("TextLabel", {Size = UDim2.new(1, -40, 0, 30), Position = UDim2.new(0, 20, 1, -64), BackgroundColor3 = TH.card2,
    TextColor3 = TH.text, Font = Enum.Font.GothamMedium, TextSize = 13, Visible = false, ZIndex = 40, TextWrapped = true}, panel)
corner(toastLbl, 8)
stroke(toastLbl, TH.violet, 1)
local toastSeq = 0
function UI.toast(msg)
    toastSeq = toastSeq + 1
    local my = toastSeq
    toastLbl.Text = msg
    toastLbl.Visible = true
    task.delay(2.6, function() if my == toastSeq then toastLbl.Visible = false end end)
end

function UI.copyOrShow(title, text)
    if U.copy(text) then
        UI.toast("Copiado al portapapeles (" .. #text .. " caracteres)")
    else
        UI.toast("Este ejecutor no permite copiar: se muestra el texto para seleccionarlo")
        UI.detail(title, text)
    end
end

---------------- Pestañas
local TABS = {"MAIN", "REMOTES", "TOOLS", "BUTTONS", "LOGS", "PERFORMANCE"}
local tabButtons = {}
for i, name in ipairs(TABS) do
    local b = mk("TextButton", {Size = UDim2.fromOffset(name == "PERFORMANCE" and 118 or 92, 34), BackgroundColor3 = TH.card,
        Text = name, TextColor3 = TH.dim, Font = Enum.Font.GothamBold, TextSize = 12, LayoutOrder = i, ZIndex = 12, AutoButtonColor = false}, tabBar)
    corner(b, 9)
    b:SetAttribute("tab", name)
    tabButtons[name] = b
    local page = mk("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, ZIndex = 11}, body)
    UI.pages[name] = page
end

---------------- Barra de herramientas y lista reutilizable
function UI.toolbar(page)
    local bar = mk("ScrollingFrame", {Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.X, AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new(0, 0, 0, 0), ZIndex = 12}, page)
    mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center}, bar)
    local tb = {bar = bar, n = 0}
    function tb.search(placeholder, w)
        tb.n = tb.n + 1
        local box = mk("TextBox", {Size = UDim2.fromOffset(w or 150, 34), BackgroundColor3 = TH.card, Text = "", PlaceholderText = placeholder or "Buscar…",
            PlaceholderColor3 = TH.dim, TextColor3 = TH.text, Font = Enum.Font.Gotham, TextSize = 13, ClearTextOnFocus = false,
            TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = tb.n, ZIndex = 12}, bar)
        corner(box, 8); stroke(box, TH.cyan, 1, 0.55); pad(box, 8)
        return box
    end
    function tb.button(text, fn, color, w)
        tb.n = tb.n + 1
        local b = mk("TextButton", {Size = UDim2.fromOffset(w or 78, 34), BackgroundColor3 = TH.card2, Text = text,
            TextColor3 = color or TH.text, Font = Enum.Font.GothamBold, TextSize = 12, LayoutOrder = tb.n, ZIndex = 12}, bar)
        corner(b, 8); stroke(b, TH.violet, 1, 0.6)
        if fn then U.conn(b.Activated, function() fn(b) end) end
        return b
    end
    return tb
end

-- Lista con filas reutilizadas (máx. MAX_ROWS visibles para no cargar la GUI).
local MAX_ROWS = 150
function UI.list(page, top)
    local sf = mk("ScrollingFrame", {Size = UDim2.new(1, 0, 1, -(top or 44)), Position = UDim2.fromOffset(0, top or 44),
        BackgroundColor3 = TH.panel, BackgroundTransparency = 0.15, ScrollBarThickness = 5, ScrollBarImageColor3 = TH.cyan,
        AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0, 0, 0, 0), ScrollingDirection = Enum.ScrollingDirection.Y,
        ElasticBehavior = Enum.ElasticBehavior.Always, ZIndex = 11}, page)
    corner(sf, 10)
    pad(sf, 6)
    mk("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}, sf)
    local L = {sf = sf, rows = {}, items = {}}
    function L.set(items)
        L.items = items
        for i = 1, math.min(#items, MAX_ROWS + 1) do
            local row = L.rows[i]
            if not row then
                row = mk("TextButton", {Size = UDim2.new(1, -4, 0, 48), BackgroundColor3 = TH.card, Text = "", AutoButtonColor = true,
                    LayoutOrder = i, ZIndex = 12}, sf)
                corner(row, 8)
                local bar = mk("Frame", {Size = UDim2.new(0, 3, 1, -12), Position = UDim2.fromOffset(4, 6), BackgroundColor3 = TH.cyan, BorderSizePixel = 0, ZIndex = 13}, row)
                local t1 = mk("TextLabel", {Size = UDim2.new(1, -20, 0, 20), Position = UDim2.fromOffset(14, 4), BackgroundTransparency = 1, RichText = true,
                    TextColor3 = TH.text, Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 13}, row)
                local t2 = mk("TextLabel", {Size = UDim2.new(1, -20, 0, 18), Position = UDim2.fromOffset(14, 25), BackgroundTransparency = 1, RichText = true,
                    TextColor3 = TH.dim, Font = Enum.Font.Code, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 13}, row)
                row:SetAttribute("i", i)
                U.conn(row.Activated, function()
                    local it = L.items[i]
                    if it and it.onTap then it.onTap() end
                end)
                L.rows[i] = {btn = row, bar = bar, t1 = t1, t2 = t2}
                row = L.rows[i]
            end
            local it = items[i]
            if i > MAX_ROWS then
                it = {title = '<font color="' .. HEX.dim .. '">Mostrando ' .. MAX_ROWS .. ' de ' .. #items .. '</font>', sub = "Usa la búsqueda o los filtros para acotar"}
                L.items[i] = it
            end
            row.btn.Visible = true
            if row.t1.Text ~= it.title then row.t1.Text = it.title end
            if row.t2.Text ~= (it.sub or "") then row.t2.Text = it.sub or "" end
            row.bar.BackgroundColor3 = it.color or TH.cyan
        end
        for i = math.min(#items, MAX_ROWS + 1) + 1, #L.rows do
            L.rows[i].btn.Visible = false
        end
    end
    return L
end

---------------- Detalle (texto largo, seleccionable, en bloques)
local detail = mk("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = TH.bg, Visible = false, ZIndex = 30, Active = true}, body)
corner(detail, 10); stroke(detail, TH.violet, 1.2)
local detailTitle = mk("TextLabel", {Size = UDim2.new(1, -250, 0, 36), Position = UDim2.fromOffset(10, 2), BackgroundTransparency = 1, RichText = true,
    TextColor3 = TH.cyan, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 31}, detail)
local function dBtn(txt, x, w, color)
    local b = mk("TextButton", {Size = UDim2.fromOffset(w, 32), Position = UDim2.new(1, x, 0, 4), BackgroundColor3 = TH.card2, Text = txt,
        TextColor3 = color or TH.text, Font = Enum.Font.GothamBold, TextSize = 12, ZIndex = 31}, detail)
    corner(b, 8)
    return b
end
local dClose = dBtn("Cerrar", -74, 68, TH.bad)
local dCopy = dBtn("Copiar", -148, 68, TH.cyan)
local dExtra = dBtn("", -240, 86, TH.violet)
local dScroll = mk("ScrollingFrame", {Size = UDim2.new(1, -12, 1, -46), Position = UDim2.fromOffset(6, 42), BackgroundColor3 = TH.panel,
    ScrollBarThickness = 5, ScrollBarImageColor3 = TH.violet, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0, 0, 0, 0),
    ZIndex = 31}, detail)
corner(dScroll, 8); pad(dScroll, 8)
mk("UIListLayout", {Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder}, dScroll)
local dChunks, dText, dExtraFn = {}, "", nil
local CHUNK = 2500
function UI.detail(title, text, extraLabel, extraFn)
    dText = tostring(text or "")
    detailTitle.Text = U.esc(title or "Detalle")
    dExtraFn = extraFn
    dExtra.Visible = extraLabel ~= nil
    dExtra.Text = extraLabel or ""
    local shown = dText
    if #shown > 60000 then shown = shown:sub(1, 60000) .. "\n… (recortado en pantalla; Copiar copia todo)" end
    local idx = 0
    local pos = 1
    while pos <= #shown do
        idx = idx + 1
        local stop = math.min(#shown, pos + CHUNK - 1)
        if stop < #shown then
            local nl = shown:find("\n", stop, true)
            if nl and nl - stop < 400 then stop = nl end
        end
        local part = shown:sub(pos, stop)
        pos = stop + 1
        local box = dChunks[idx]
        if not box then
            box = mk("TextBox", {Size = UDim2.new(1, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
                TextColor3 = TH.text, Font = Enum.Font.Code, TextSize = 12, TextWrapped = true, MultiLine = true, ClearTextOnFocus = false,
                TextEditable = false, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
                LayoutOrder = idx, ZIndex = 32}, dScroll)
            dChunks[idx] = box
        end
        box.Text = part
        box.Visible = true
    end
    for i = idx + 1, #dChunks do dChunks[i].Visible = false; dChunks[i].Text = "" end
    dScroll.CanvasPosition = Vector2.new(0, 0)
    detail.Visible = true
end
U.conn(dClose.Activated, function() detail.Visible = false end)
U.conn(dCopy.Activated, function() UI.copyOrShow("Copia", dText) end)
U.conn(dExtra.Activated, function() if dExtraFn then dExtraFn() end end)

---------------- Abrir / cerrar / cambiar pestaña
function UI.setTab(name)
    UI.tab = name
    detail.Visible = false
    for n, p in pairs(UI.pages) do p.Visible = (n == name) end
    for n, b in pairs(tabButtons) do
        local on = (n == name)
        b.BackgroundColor3 = on and TH.card2 or TH.card
        b.TextColor3 = on and TH.cyan or TH.dim
        local st = b:FindFirstChildOfClass("UIStroke") or stroke(b, TH.cyan, 1.4)
        st.Transparency = on and 0 or 1
    end
    UI.force = true
end
for name, b in pairs(tabButtons) do
    U.conn(b.Activated, function() UI.setTab(name) end)
end

function UI.toggle(state)
    if state == nil then state = not UI.open end
    UI.open = state
    panel.Visible = state
    if state then UI.force = true end
end
draggable(fab, fab, function() UI.toggle() end)
draggable(header, panel, nil)
U.conn(closeBtn.Activated, function() UI.toggle(false) end)

---------------------------------------------------------------- INSPECTOR DE OBJETOS
local PROPS = {"Name", "ClassName", "Parent", "Archivable", "Enabled", "Disabled", "Visible", "Active", "Text", "Value",
    "Position", "Size", "Orientation", "Transparency", "Anchored", "CanCollide", "CanTouch", "Massless", "Material", "Color",
    "BrickColor", "Locked", "PrimaryPart", "Health", "MaxHealth", "WalkSpeed", "JumpPower", "JumpHeight", "ToolTip",
    "RequiresHandle", "CanBeDropped", "ManualActivationOnly", "Image", "AutoButtonColor", "Selectable", "ZIndex", "LayoutOrder",
    "AbsolutePosition", "AbsoluteSize", "SoundId", "Volume", "Playing", "Looped", "AnimationId", "MeshId", "TextureID", "Texture"}

local function inspect(inst)
    local lines = {}
    local function add(s) lines[#lines + 1] = s end
    local okN, name = pcall(function() return inst.Name end)
    if not okN then return "El objeto ya no es accesible." end
    add("Objeto: " .. tostring(name))
    add("Ruta:   " .. U.path(inst))
    local okA, alive = pcall(function() return inst:IsDescendantOf(game) end)
    add("Sigue en el juego: " .. tostring(okA and alive))
    add("")
    add("— Propiedades consultables (las que el cliente puede leer) —")
    for _, p in ipairs(PROPS) do
        local ok, v = pcall(function() return inst[p] end)
        if ok and v ~= nil and p ~= "Name" then
            add(string.format("%-18s %s", p, U.ser(v)))
        end
    end
    local okAt, attrs = pcall(function() return inst:GetAttributes() end)
    if okAt and attrs and next(attrs) then
        add("")
        add("— Atributos —")
        for k, v in pairs(attrs) do add(string.format("%-18s %s", tostring(k), U.ser(v))) end
    end
    if S.CollectionService then
        local okT, tags = pcall(function() return S.CollectionService:GetTags(inst) end)
        if okT and tags and #tags > 0 then add(""); add("Tags: " .. table.concat(tags, ", ")) end
    end
    local okC, kids = pcall(function() return inst:GetChildren() end)
    if okC and kids then
        add("")
        add("— Hijos directos: " .. #kids .. " —")
        for i, k in ipairs(kids) do
            if i > 60 then add("… +" .. (#kids - 60)) break end
            local okk, s = pcall(function() return k.ClassName .. "  " .. k.Name end)
            add("  " .. (okk and s or "?"))
        end
    end
    add("")
    add("Nota: los scripts y su código fuente no se leen; solo propiedades replicadas.")
    return table.concat(lines, "\n")
end

local function openInspector(inst)
    local function show()
        local watching = WATCH.has(inst)
        UI.detail("Inspector · " .. tostring(inst.Name), inspect(inst), watching and "Dejar de vigilar" or "Vigilar cambios", function()
            local on = WATCH.toggle(inst)
            UI.toast(on and "Vigilando .Changed de este objeto (máx. 8)" or "Ya no se vigila")
            show()
        end)
    end
    show()
end

local function match(q, ...)
    if q == "" then return true end
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        if v and U.lower(v):find(q, 1, true) then return true end
    end
    return false
end

local function rich(hex, s) return '<font color="' .. hex .. '">' .. U.esc(s) .. '</font>' end

---------------------------------------------------------------- MAIN
local STUDIO_SCRIPT -- se define al final
local LIMITS = [[
QUÉ FUNCIONA EN iPHONE CON DELTA (observado de verdad)
• Lista de RemoteEvent, UnreliableRemoteEvent, RemoteFunction, BindableEvent y BindableFunction replicados al cliente (Workspace, ReplicatedStorage, ReplicatedFirst, Players, Lighting, StarterGui, StarterPack, StarterPlayer, SoundService, Teams, Chat, TextChatService). Se actualiza cuando aparecen o desaparecen.
• Señales servidor → cliente: OnClientEvent (nombre, hora, argumentos, tipos, contador).
• BindableEvent.Event (comunicación local del cliente).
• Herramientas: aparecer/desaparecer, mover, equipar, desequipar, activar.
• Valores (ValueBase) y atributos de TU jugador y personaje que cambian.
• Botones de tu PlayerGui y sus clics (.Activated).
• Errores y advertencias de la consola del cliente (LogService).
• FPS, tiempo de frame, memoria, ping, KB/s de red, física: lecturas aproximadas del cliente.

QUÉ NO SE PUEDE DESDE EL CLIENTE (y no se intenta)
• Lo que el cliente ENVÍA (FireServer / InvokeServer): requeriría hookear __namecall; este monitor no modifica funciones globales.
• RemoteFunction.OnClientInvoke y BindableFunction.OnInvoke: solo se ven reemplazando el callback del juego, así que solo se listan.
• Código fuente de scripts del servidor, eventos internos del servidor, ServerStorage y ServerScriptService: no se replican al cliente.
• La función interna de un botón: se ve el clic, no lo que hace.
• Memoria y CPU del servidor, Script Profiler y MicroProfiler completos: herramientas de Roblox Studio / consola de desarrollador con permisos.

PARA TU PROPIO JUEGO (Roblox Studio)
• Pega el "Script de Studio" en ServerScriptService. Registra OnServerEvent/OnServerInvoke de tus remotos (jugador, argumentos, tipos, frecuencia) en la consola del servidor y, si agregas tu UserId, lo envía a este panel por el remoto GOY_DiagFeed (categoría "Servidor").
• En Studio usa también: Developer Console (F9) → Server, Script Profiler y MicroProfiler (Ctrl+F6).
]]

do
    local page = UI.pages.MAIN
    local tb = UI.toolbar(page)
    tb.button("Copiar resumen", function() UI.copyOrShow("Resumen", UI.summaryText()) end, TH.cyan, 120)
    tb.button("Limitaciones", function() UI.detail("Qué funciona y qué no", LIMITS) end, nil, 104)
    tb.button("Script Studio", function()
        UI.detail("Script de Studio (servidor, solo tu juego)", STUDIO_SCRIPT)
    end, TH.violet, 108)
    tb.button("Apagar", function() G.destroy() end, TH.bad, 76)
    UI.lists.MAIN = UI.list(page, 44)
end

function UI.summaryText()
    local t = {}
    t[#t + 1] = "GOY Diagnostics · " .. U.fullDate()
    t[#t + 1] = "Juego PlaceId " .. tostring(game.PlaceId) .. " · jugador " .. LP.Name
    t[#t + 1] = "Ejecutor: " .. CAP.executor .. " · copiar: " .. (CAP.setclipboard and "sí" or "no") .. " · archivos: " .. (CAP.writefile and "sí" or "no")
    t[#t + 1] = "Objetos revisados: " .. REG.scanned .. (REG.scanDone and "" or " (escaneando…)")
    local counts = {}
    for _, e in ipairs(REG.remotes) do counts[e.class] = (counts[e.class] or 0) + 1 end
    for _, c in ipairs({"RemoteEvent", "UnreliableRemoteEvent", "RemoteFunction", "BindableEvent", "BindableFunction"}) do
        t[#t + 1] = "  " .. c .. ": " .. (counts[c] or 0)
    end
    t[#t + 1] = "Herramientas: " .. #REG.tools .. " · Botones: " .. #REG.buttons
    t[#t + 1] = "Registros: " .. LOG.total .. " (guardados " .. LOG.n .. "/" .. LOG.max .. ", spam no guardado " .. LOG.suppressed .. ")"
    t[#t + 1] = string.format("FPS %.0f · Ping %s · Memoria %s", PERF.fps, PERF.ping and string.format("%.0f ms", PERF.ping) or "n/d",
        PERF.mem and string.format("%.0f MB", PERF.mem) or "n/d")
    t[#t + 1] = "Consola: " .. CONSOLE.errors .. " errores, " .. CONSOLE.warnings .. " advertencias"
    t[#t + 1] = ""
    t[#t + 1] = "Más activos (servidor → cliente):"
    local top = {}
    for _, e in ipairs(REG.remotes) do if e.count > 0 then top[#top + 1] = e end end
    table.sort(top, function(a, b) return a.count > b.count end)
    for i = 1, math.min(10, #top) do t[#t + 1] = "  ×" .. top[i].count .. "  " .. top[i].path end
    return table.concat(t, "\n")
end

local function renderMain()
    local items = {}
    local function row(title, sub, color, tap) items[#items + 1] = {title = title, sub = sub, color = color, onTap = tap} end
    local counts, active = {}, 0
    for _, e in ipairs(REG.remotes) do
        counts[e.class] = (counts[e.class] or 0) + 1
        if e.count > 0 then active = active + 1 end
    end
    row(rich(HEX.ok, "● Monitor activo") .. "  " .. rich(HEX.dim, LOG.paused and "(registro en pausa)" or ""),
        "Ejecutor: " .. U.esc(CAP.executor) .. " · copiar " .. (CAP.setclipboard and "sí" or "no") .. " · exportar " .. (CAP.writefile and "sí" or "no") ..
        " · táctil " .. (CAP.touch and "sí" or "no"), TH.ok)
    row(rich(HEX.cyan, "Objetos de comunicación: " .. #REG.remotes),
        "RE " .. (counts.RemoteEvent or 0) .. " · URE " .. (counts.UnreliableRemoteEvent or 0) .. " · RF " .. (counts.RemoteFunction or 0) ..
        " · BE " .. (counts.BindableEvent or 0) .. " · BF " .. (counts.BindableFunction or 0) .. " · con actividad " .. active,
        TH.cyan, function() UI.setTab("REMOTES") end)
    row(rich(HEX.warn, "Herramientas: " .. #REG.tools) .. "   " .. rich(HEX.violet, "Botones: " .. #REG.buttons),
        "Instancias +" .. REG.instAdded .. " / −" .. REG.instRemoved .. " desde el inicio · revisados " .. REG.scanned .. (REG.scanDone and "" or " (escaneando…)"),
        TH.warn, function() UI.setTab("TOOLS") end)
    row(rich(HEX.text, "Registros: " .. LOG.total),
        string.format("guardados %d/%d · %.1f/s · spam no guardado %d · en pausa %d", LOG.n, LOG.max, PERF.logRate, LOG.suppressed, LOG.droppedPaused),
        TH.violet, function() UI.setTab("LOGS") end)
    row(rich(HEX.ok, string.format("FPS %.0f", PERF.fps)) .. "  " .. rich(HEX.cyan, PERF.ping and string.format("Ping %.0f ms", PERF.ping) or "Ping n/d") ..
        "  " .. rich(HEX.violet, PERF.mem and string.format("Mem %.0f MB", PERF.mem) or "Mem n/d"),
        "Errores " .. CONSOLE.errors .. " · advertencias " .. CONSOLE.warnings .. " · errores internos del monitor " .. G.internalErrors,
        TH.ok, function() UI.setTab("PERFORMANCE") end)
    -- últimos 5 eventos
    local n = 0
    LOG.iter(function(e)
        n = n + 1
        row(rich(CAT_HEX[e.cat] or HEX.text, e.cat) .. "  " .. U.esc(e.name), U.esc(e.t .. "  " .. U.trunc((e.args ~= "" and e.args or e.extra):gsub("\n", " · "), 140)),
            TH.line, function() UI.detail(e.cat .. " · " .. e.name, LOG.format(e)) end)
        return n < 5
    end)
    row(rich(HEX.dim, "ⓘ Qué se observa y qué requiere servidor"), "Toca para ver las limitaciones reales y la alternativa de Studio", TH.line,
        function() UI.detail("Qué funciona y qué no", LIMITS) end)
    UI.lists.MAIN.set(items)
end

---------------------------------------------------------------- REMOTES
local remoteState = {q = "", cls = 1, sort = 1}
local CLS_FILTERS = {"Todas", "RemoteEvent", "UnreliableRemoteEvent", "RemoteFunction", "BindableEvent", "BindableFunction", "Con actividad"}
local CLS_SHORT = {Todas = "Clase: todas", RemoteEvent = "RemoteEvent", UnreliableRemoteEvent = "Unreliable", RemoteFunction = "RemoteFunction",
    BindableEvent = "BindableEvent", BindableFunction = "BindableFunc", ["Con actividad"] = "Con actividad"}
local SORTS = {"Actividad", "Nombre", "Ruta"}
local function filteredRemotes()
    local q = U.lower(remoteState.q)
    local f = CLS_FILTERS[remoteState.cls]
    local out = {}
    for _, e in ipairs(REG.remotes) do
        local okc = (f == "Todas") or (f == "Con actividad" and e.count > 0) or (e.class == f)
        if okc and match(q, e.name, e.path, e.class, e.loc) then out[#out + 1] = e end
    end
    local s = SORTS[remoteState.sort]
    table.sort(out, function(a, b)
        if s == "Actividad" then
            if a.count ~= b.count then return a.count > b.count end
            return a.name < b.name
        elseif s == "Nombre" then
            return U.lower(a.name) < U.lower(b.name)
        end
        return a.path < b.path
    end)
    return out
end
local function remoteText(e)
    return table.concat({
        "Nombre:     " .. e.name, "Clase:      " .. e.class, "Ruta:       " .. U.path(e.inst), "Ubicación:  " .. e.loc,
        "Dirección:  " .. e.dir, "Detectado:  " .. e.addedAt, "Recibidos:  " .. e.count .. (e.last and ("  (último " .. e.last .. ")") or ""),
        "", "Últimos argumentos (" .. (e.lastTypes ~= "" and e.lastTypes or "—") .. "):", e.lastArgs ~= "" and e.lastArgs or "(aún no recibido)",
        "", e.observable and "Observado directamente desde el cliente." or
            "Solo listado: observarlo exigiría reemplazar el callback del juego. Para verlo, instrumenta TU servidor con el Script de Studio.",
        "Lo que el cliente envía al servidor con este objeto NO se observa (requiere instrumentación del servidor).",
    }, "\n")
end
do
    local page = UI.pages.REMOTES
    local tb = UI.toolbar(page)
    local box = tb.search("Nombre, ruta, clase…", 150)
    U.conn(box:GetPropertyChangedSignal("Text"), function() remoteState.q = box.Text; UI.force = true end)
    tb.button(CLS_SHORT.Todas, function(b)
        remoteState.cls = remoteState.cls % #CLS_FILTERS + 1
        b.Text = CLS_SHORT[CLS_FILTERS[remoteState.cls]]
        UI.force = true
    end, TH.cyan, 116)
    tb.button("Orden: Actividad", function(b)
        remoteState.sort = remoteState.sort % #SORTS + 1
        b.Text = "Orden: " .. SORTS[remoteState.sort]
        UI.force = true
    end, nil, 124)
    tb.button("Copiar", function()
        local t = {"GOY Diagnostics · remotos (" .. U.fullDate() .. ")"}
        for _, e in ipairs(filteredRemotes()) do
            t[#t + 1] = string.format("%-22s ×%-5d %-24s %s", e.class, e.count, e.loc, e.path)
        end
        UI.copyOrShow("Remotos", table.concat(t, "\n"))
    end, TH.ok, 72)
    UI.lists.REMOTES = UI.list(page, 44)
end
local function renderRemotes()
    local items = {}
    for _, e in ipairs(filteredRemotes()) do
        local hex = CLASS_HEX[e.class] or HEX.text
        local cnt = e.observable and (e.count > 0 and rich(HEX.warn, "  ×" .. e.count) or rich(HEX.dim, "  ×0")) or rich(HEX.dim, "  (no observable)")
        items[#items + 1] = {
            title = rich(hex, e.name) .. cnt,
            sub = U.esc(e.class .. " · " .. e.loc .. (e.last and (" · " .. e.last) or "") .. " · " .. e.path),
            color = Color3.fromHex and Color3.fromHex(hex) or TH.cyan,
            onTap = function()
                UI.detail(e.class .. " · " .. e.name, remoteText(e), "Ver en LOGS", function()
                    UI.logSearch(e.name)
                end)
            end,
        }
    end
    if #items == 0 then
        items[1] = {title = rich(HEX.dim, REG.scanDone and "Sin resultados" or "Escaneando…"), sub = "Cambia la búsqueda o el filtro"}
    end
    UI.lists.REMOTES.set(items)
end

---------------------------------------------------------------- TOOLS
local toolState = {mode = 1, q = "", results = {}, searching = false}
local TOOL_MODES = {"Herramientas", "Contenedores", "Buscar objetos", "Vigilados"}
local function runSearch(q)
    if toolState.searching then return end
    q = U.lower(q)
    if #q < 2 then UI.toast("Escribe al menos 2 letras") return end
    toolState.searching, toolState.results = true, {}
    UI.force = true
    task.spawn(function()
        local n = 0
        for _, c in ipairs(REG.containers) do
            local ok, list = pcall(function() return c.inst:GetDescendants() end)
            if ok then
                for i, inst in ipairs(list) do
                    if not G.alive or #toolState.results >= 200 then break end
                    local okn, nm = pcall(function() return inst.Name end)
                    if okn and U.lower(nm):find(q, 1, true) and not isOwnGui(inst) then
                        toolState.results[#toolState.results + 1] = {inst = inst, loc = c.name}
                    end
                    n = n + 1
                    if n % 500 == 0 then task.wait() end
                end
            end
        end
        toolState.searching = false
        UI.force = true
        UI.toast(#toolState.results .. " objetos encontrados" .. (#toolState.results >= 200 and " (límite 200)" or ""))
    end)
end
do
    local page = UI.pages.TOOLS
    local tb = UI.toolbar(page)
    tb.button("Herramientas", function(b)
        toolState.mode = toolState.mode % #TOOL_MODES + 1
        b.Text = TOOL_MODES[toolState.mode]
        UI.force = true
    end, TH.warn, 116)
    local box = tb.search("Filtrar / buscar…", 140)
    U.conn(box:GetPropertyChangedSignal("Text"), function() toolState.q = box.Text; UI.force = true end)
    U.conn(box.FocusLost, function(enter) if enter and TOOL_MODES[toolState.mode] == "Buscar objetos" then runSearch(box.Text) end end)
    tb.button("Buscar", function()
        if TOOL_MODES[toolState.mode] ~= "Buscar objetos" then
            toolState.mode = 3
            for _, ch in ipairs(tb.bar:GetChildren()) do
                if ch:IsA("TextButton") and ch.LayoutOrder == 1 then ch.Text = TOOL_MODES[3] end
            end
        end
        runSearch(box.Text)
    end, TH.cyan, 72)
    tb.button("Copiar", function()
        local t = {"GOY Diagnostics · " .. TOOL_MODES[toolState.mode]}
        for _, it in ipairs(UI.lists.TOOLS.items) do
            t[#t + 1] = (it.copy or ((it.title or ""):gsub("<[^>]->", "") .. " · " .. (it.sub or ""):gsub("<[^>]->", "")))
        end
        UI.copyOrShow("Herramientas", table.concat(t, "\n"))
    end, TH.ok, 72)
    UI.lists.TOOLS = UI.list(page, 44)
end
local function renderTools()
    local items, q = {}, U.lower(toolState.q)
    local mode = TOOL_MODES[toolState.mode]
    if mode == "Herramientas" then
        for _, e in ipairs(REG.tools) do
            if match(q, e.name, e.owner, e.path) then
                local stHex = (e.state == "equipada") and HEX.ok or HEX.warn
                items[#items + 1] = {title = rich(HEX.warn, e.name) .. "  " .. rich(stHex, tostring(e.state)),
                    sub = U.esc(e.class .. " · dueño " .. tostring(e.owner) .. " · equipada ×" .. e.equips .. " · " .. e.path),
                    color = TH.warn, onTap = function() openInspector(e.inst) end}
            end
        end
        if #items == 0 then items[1] = {title = rich(HEX.dim, "No hay herramientas visibles"), sub = "Solo se ven las replicadas a tu cliente (tu Backpack y personajes)"} end
    elseif mode == "Contenedores" then
        for _, c in ipairs(REG.containers) do
            items[#items + 1] = {title = rich(HEX.cyan, c.name) .. "  " .. rich(HEX.text, tostring(c.count) .. " objetos"),
                sub = "+" .. c.added .. " / −" .. c.removed .. " desde el inicio · toca para inspeccionar", color = TH.cyan,
                onTap = function() openInspector(c.inst) end}
        end
        items[#items + 1] = {title = rich(HEX.dim, "ServerStorage / ServerScriptService"), sub = "No accesibles desde el cliente (no se replican)", color = TH.line}
        items[#items + 1] = {title = rich(REG.logWorkspaceInstances and HEX.ok or HEX.dim,
            "Registrar instancias nuevas de Workspace: " .. (REG.logWorkspaceInstances and "SÍ" or "NO")),
            sub = "Toca para cambiar (puede generar mucho registro en juegos con proyectiles)", color = TH.violet,
            onTap = function() REG.logWorkspaceInstances = not REG.logWorkspaceInstances; UI.force = true end}
    elseif mode == "Buscar objetos" then
        if toolState.searching then items[1] = {title = rich(HEX.cyan, "Buscando…"), sub = "Por partes, sin congelar el juego"} end
        for _, r in ipairs(toolState.results) do
            local ok, cls, nm = pcall(function() return r.inst.ClassName, r.inst.Name end)
            if ok then
                items[#items + 1] = {title = rich(HEX.text, nm) .. "  " .. rich(HEX.dim, cls), sub = U.esc(r.loc .. " · " .. U.path(r.inst)),
                    color = TH.violet, onTap = function() openInspector(r.inst) end}
            end
        end
        if #items == 0 then items[1] = {title = rich(HEX.dim, "Escribe un nombre y toca Buscar"), sub = "Busca en todos los contenedores accesibles (máx. 200)"} end
    else
        for _, w in ipairs(WATCH.list) do
            items[#items + 1] = {title = rich(HEX.pink, w.name), sub = U.esc(U.path(w.inst) .. " · toca para inspeccionar"), color = TH.violet,
                onTap = function() openInspector(w.inst) end}
        end
        if #items == 0 then items[1] = {title = rich(HEX.dim, "Nada vigilado"), sub = "Abre un objeto en el inspector y toca «Vigilar cambios»"} end
    end
    UI.lists.TOOLS.set(items)
end

---------------------------------------------------------------- BUTTONS
local btnState = {q = "", f = 1}
local BTN_FILTERS = {"Todos", "Visibles", "Ocultos", "Con clics"}
local function effVisible(inst)
    local ok, r = pcall(function()
        local p = inst
        local depth = 0
        while p and depth < 40 do
            if p:IsA("PlayerGui") then return true end
            if p:IsA("GuiObject") and not p.Visible then return false end
            if p:IsA("LayerCollector") and not p.Enabled then return false end
            p = p.Parent
            depth = depth + 1
        end
        return p ~= nil
    end)
    return ok and r
end
local function buttonText(e)
    local inst = e.inst
    local function g(p) local ok, v = pcall(function() return inst[p] end) return ok and v or nil end
    return table.concat({
        "Nombre:   " .. e.name, "Clase:    " .. e.class, "Ruta:     " .. U.path(inst),
        "Texto:    " .. tostring(g("Text") or "(ImageButton sin texto)"), "Visible:  propio " .. tostring(g("Visible")) .. " · en pantalla " .. tostring(effVisible(inst)),
        "Active:   " .. tostring(g("Active")) .. " · Interactable " .. tostring(g("Interactable")),
        "Imagen:   " .. tostring(g("Image") or "—"),
        "Clics observados: " .. e.clicks .. (e.lastClick and ("  (último " .. e.lastClick .. ")") or ""),
        "", "Eventos de interfaz observables: Activated, MouseButton1Click, InputBegan (se registra Activated).",
        "La función interna del botón NO es accesible: solo se puede ver el clic y lo que llegue después",
        "(por ejemplo una señal en LOGS justo después del clic).",
    }, "\n")
end
do
    local page = UI.pages.BUTTONS
    local tb = UI.toolbar(page)
    local box = tb.search("Texto, nombre, ruta…", 150)
    U.conn(box:GetPropertyChangedSignal("Text"), function() btnState.q = box.Text; UI.force = true end)
    tb.button("Todos", function(b)
        btnState.f = btnState.f % #BTN_FILTERS + 1
        b.Text = BTN_FILTERS[btnState.f]
        UI.force = true
    end, TH.violet, 90)
    tb.button("Copiar", function()
        local t = {"GOY Diagnostics · botones"}
        for _, e in ipairs(REG.buttons) do
            local okt, tx = pcall(function() return e.inst.Text end)
            t[#t + 1] = string.format("%-12s %-5s ×%-4d %s  \"%s\"", e.class, effVisible(e.inst) and "vis" or "ocul", e.clicks, U.path(e.inst), okt and U.trunc(tx or "", 40) or "")
        end
        UI.copyOrShow("Botones", table.concat(t, "\n"))
    end, TH.ok, 72)
    UI.lists.BUTTONS = UI.list(page, 44)
end
local function renderButtons()
    local items, q, f = {}, U.lower(btnState.q), BTN_FILTERS[btnState.f]
    local list = {}
    for _, e in ipairs(REG.buttons) do
        local okt, tx = pcall(function() return e.inst.Text end)
        tx = okt and tx or ""
        if match(q, e.name, tx, e.path) then
            local vis = effVisible(e.inst)
            local okf = (f == "Todos") or (f == "Visibles" and vis) or (f == "Ocultos" and not vis) or (f == "Con clics" and e.clicks > 0)
            if okf then list[#list + 1] = {e = e, tx = tx, vis = vis} end
        end
    end
    table.sort(list, function(a, b)
        if a.e.clicks ~= b.e.clicks then return a.e.clicks > b.e.clicks end
        if a.vis ~= b.vis then return a.vis end
        return a.e.path < b.e.path
    end)
    for _, it in ipairs(list) do
        local e = it.e
        items[#items + 1] = {
            title = rich(it.vis and HEX.violet or HEX.dim, (it.tx ~= "" and U.trunc(it.tx, 40) or e.name)) ..
                (it.tx ~= "" and ("  " .. rich(HEX.dim, e.name)) or "") .. (e.clicks > 0 and rich(HEX.warn, "  ×" .. e.clicks) or ""),
            sub = U.esc(e.class .. " · " .. (it.vis and "visible" or "oculto") .. " · " .. e.path),
            color = it.vis and TH.violet or TH.line,
            onTap = function() UI.detail(e.class .. " · " .. e.name, buttonText(e), "Inspeccionar", function() openInspector(e.inst) end) end,
        }
    end
    if #items == 0 then items[1] = {title = rich(HEX.dim, "Sin botones con este filtro"), sub = "Solo se exploran los botones de tu PlayerGui"} end
    UI.lists.BUTTONS.set(items)
end

---------------------------------------------------------------- LOGS
local logState = {q = "", cat = 1, box = nil}
local function filteredLogs(limit)
    local q, cat = U.lower(logState.q), CATS[logState.cat]
    local out = {}
    LOG.iter(function(e)
        if (cat == "Todas" or e.cat == cat) and match(q, e.name, e.args, e.extra, e.cat, e.types) then
            out[#out + 1] = e
        end
        return not limit or #out < limit
    end)
    return out
end
function UI.logSearch(text)
    logState.q = text
    if logState.box then logState.box.Text = text end
    UI.setTab("LOGS")
end
do
    local page = UI.pages.LOGS
    local tb = UI.toolbar(page)
    local box = tb.search("Buscar en registros…", 140)
    logState.box = box
    U.conn(box:GetPropertyChangedSignal("Text"), function() logState.q = box.Text; UI.force = true end)
    logState.catBtn = tb.button("Categoría: Todas", function(b)
        logState.cat = logState.cat % #CATS + 1
        b.Text = "Categoría: " .. CATS[logState.cat]
        UI.force = true
    end, TH.cyan, 132)
    tb.button("Pausa", function(b)
        LOG.paused = not LOG.paused
        b.Text = LOG.paused and "Reanudar" or "Pausa"
        b.TextColor3 = LOG.paused and TH.warn or TH.text
        statusDot.BackgroundColor3 = LOG.paused and TH.warn or TH.ok
        fabDot.BackgroundColor3 = LOG.paused and TH.warn or TH.ok
        UI.force = true
    end, nil, 84)
    tb.button("Limpiar", function() LOG.clear(); UI.force = true; UI.toast("Historial limpio") end, TH.bad, 76)
    tb.button("Copiar", function()
        local t = {"GOY Diagnostics · registros (" .. U.fullDate() .. ")"}
        local list = filteredLogs()
        for i = #list, 1, -1 do t[#t + 1] = LOG.format(list[i]) end
        UI.copyOrShow("Registros", table.concat(t, "\n"))
    end, TH.ok, 72)
    tb.button("Exportar", function()
        local t = {"GOY Diagnostics · registros · " .. U.fullDate(), "PlaceId " .. tostring(game.PlaceId), ""}
        local list = filteredLogs()
        for i = #list, 1, -1 do t[#t + 1] = LOG.format(list[i]) end
        local name = "logs_" .. (tostring(os.time and os.time() or math.floor(os.clock()))) .. ".txt"
        local ok, where = U.export(name, table.concat(t, "\n"))
        UI.toast(ok and ("Guardado: " .. where) or ("No se pudo exportar: " .. tostring(where)))
    end, TH.violet, 84)
    UI.lists.LOGS = UI.list(page, 44)
end
local function renderLogs()
    local items = {}
    local list = filteredLogs(MAX_ROWS + 1)
    for _, e in ipairs(list) do
        local hex = CAT_HEX[e.cat] or HEX.text
        local preview = e.args ~= "" and e.args or e.extra
        items[#items + 1] = {
            title = rich(HEX.dim, e.t) .. "  " .. rich(hex, e.cat) .. "  " .. U.esc(e.name) .. (e.dir ~= "" and ("  " .. rich(HEX.dim, "· " .. e.dir)) or ""),
            sub = U.esc(U.trunc(preview:gsub("\n", "  ·  "), 180)),
            color = Color3.fromHex and Color3.fromHex(hex) or TH.cyan,
            onTap = function() UI.detail(e.cat .. " · " .. e.name, LOG.format(e)) end,
        }
    end
    if #items == 0 then
        items[1] = {title = rich(HEX.dim, LOG.paused and "Registro en pausa" or "Sin registros todavía"),
            sub = "Aparecen cuando el servidor te envía señales, cambian tus herramientas o valores, o tocas botones"}
    elseif #list > MAX_ROWS then
        items[#items] = nil
        items[#items + 1] = {title = rich(HEX.dim, "Mostrando los " .. MAX_ROWS .. " más recientes de " .. LOG.n .. " guardados"), sub = "Copiar/Exportar incluyen todos los que coinciden"}
    end
    UI.lists.LOGS.set(items)
end

---------------------------------------------------------------- PERFORMANCE
local PERF_NOTES = [[
CÓMO SE MIDE CADA MÉTRICA (cliente, aproximado)
• FPS: frames contados con RunService.RenderStepped cada segundo. Real del cliente.
• Tiempo de frame: promedio y máximo del delta de RenderStepped en el último segundo.
• Memoria total: Stats:GetTotalMemoryUsageMb() del CLIENTE (si el ejecutor/juego lo permite).
• Memoria de scripts: Stats:GetMemoryUsageMbForTag(Script) del cliente.
• Montón Lua: collectgarbage("count") del entorno donde corre este script, no del juego entero.
• Ping: Player:GetNetworkPing() (latencia aislada, aproximada) o Stats "Data Ping" como respaldo.
• Red: Stats.DataReceiveKbps / DataSendKbps del cliente.
• Física: workspace:GetRealPhysicsFPS() del cliente.
• Errores/advertencias: LogService.MessageOut (solo los del cliente).

NECESITA ROBLOX STUDIO O ACCESO AL SERVIDOR
• CPU y memoria del servidor, scripts del servidor, Script Profiler y MicroProfiler completos,
  pestaña Server de la Developer Console (requiere permisos de desarrollador del juego).
• En tu juego: Script de Studio (MAIN) + F9 → Server + Script Profiler + Ctrl+F6 (MicroProfiler).
]]
do
    local page = UI.pages.PERFORMANCE
    local tb = UI.toolbar(page)
    tb.button("Copiar métricas", function() UI.copyOrShow("Rendimiento", UI.perfText()) end, TH.cyan, 124)
    tb.button("¿Qué es aproximado?", function() UI.detail("Cómo se mide", PERF_NOTES) end, TH.violet, 150)
    UI.lists.PERFORMANCE = UI.list(page, 44)
end
local BARS = {"▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"}
local function spark(hist)
    local maxv = 1
    for _, v in ipairs(hist) do if v > maxv then maxv = v end end
    local t = {}
    for _, v in ipairs(hist) do t[#t + 1] = BARS[math.clamp(math.floor(v / maxv * 7) + 1, 1, 8)] end
    return table.concat(t)
end
local function fmt(v, f, unit) if v == nil then return "no disponible" end return string.format(f, v) .. (unit or "") end
function UI.perfText()
    return table.concat({
        "GOY Diagnostics · rendimiento · " .. U.fullDate(),
        "FPS: " .. fmt(PERF.fps, "%.1f") .. " · frame medio " .. fmt(PERF.frameAvg * 1000, "%.1f", " ms") .. " · máx " .. fmt((PERF.lastFrameMax or 0) * 1000, "%.1f", " ms"),
        "Física: " .. fmt(PERF.physFps, "%.1f", " FPS"),
        "Ping: " .. fmt(PERF.ping, "%.0f", " ms") .. (PERF.pingSrc ~= "" and (" (" .. PERF.pingSrc .. ")") or ""),
        "Red: recibe " .. fmt(PERF.recv, "%.1f", " KB/s") .. " · envía " .. fmt(PERF.send, "%.1f", " KB/s"),
        "Memoria cliente: " .. fmt(PERF.mem, "%.0f", " MB") .. " · scripts " .. fmt(PERF.memScript, "%.0f", " MB") .. " · montón Lua " .. fmt(PERF.luaHeap, "%.1f", " MB"),
        "Instancias (Stats): " .. fmt(PERF.instCount, "%.0f"),
        "Consola: " .. CONSOLE.errors .. " errores · " .. CONSOLE.warnings .. " advertencias",
        "Monitor: " .. #G.conns .. " conexiones · render " .. string.format("%.2f", PERF.renderMs) .. " ms · " .. string.format("%.1f", PERF.renderRate) .. " actualizaciones/s",
        "Registros: " .. LOG.total .. " · " .. string.format("%.1f", PERF.logRate) .. "/s · errores internos " .. G.internalErrors,
    }, "\n")
end
local function renderPerf()
    local items = {}
    local function row(t, s, c) items[#items + 1] = {title = t, sub = s, color = c} end
    local fpsHex = PERF.fps >= 50 and HEX.ok or (PERF.fps >= 30 and HEX.warn or HEX.bad)
    row(rich(fpsHex, string.format("FPS %.0f", PERF.fps)) .. "  " .. rich(HEX.dim, "frame " .. fmt(PERF.frameAvg * 1000, "%.1f", " ms") .. " · máx " .. fmt((PERF.lastFrameMax or 0) * 1000, "%.0f", " ms")),
        spark(PERF.hist) .. "  (últimos 30 s · cliente)", Color3.fromHex and Color3.fromHex(fpsHex) or TH.ok)
    row(rich(HEX.cyan, "Ping " .. fmt(PERF.ping, "%.0f", " ms")), U.esc(PERF.pingSrc ~= "" and (PERF.pingSrc .. " · aproximado") or "API no disponible en este juego/ejecutor"), TH.cyan)
    row(rich(HEX.violet, "Memoria " .. fmt(PERF.mem, "%.0f", " MB")), "scripts " .. fmt(PERF.memScript, "%.0f", " MB") .. " · montón Lua de este script " .. fmt(PERF.luaHeap, "%.1f", " MB"), TH.violet)
    row(rich(HEX.blue, "Red ↓ " .. fmt(PERF.recv, "%.1f", " KB/s") .. "  ↑ " .. fmt(PERF.send, "%.1f", " KB/s")), "Física " .. fmt(PERF.physFps, "%.0f", " FPS") .. " · instancias " .. fmt(PERF.instCount, "%.0f"), TH.line)
    row(rich(CONSOLE.errors > 0 and HEX.bad or HEX.ok, "Errores " .. CONSOLE.errors) .. "  " .. rich(HEX.warn, "Advertencias " .. CONSOLE.warnings),
        "Consola del cliente (LogService). Toca para verlos en LOGS", TH.bad)
    items[#items].onTap = function()
        for i, c in ipairs(CATS) do if c == "Consola" then logState.cat = i end end
        if logState.catBtn then logState.catBtn.Text = "Categoría: Consola" end
        UI.logSearch("")
    end
    row(rich(HEX.text, "Objetos: " .. #REG.remotes .. " remotos · " .. #REG.tools .. " herramientas · " .. #REG.buttons .. " botones"),
        "Registros " .. LOG.total .. " · " .. string.format("%.1f/s", PERF.logRate) .. " · spam no guardado " .. LOG.suppressed, TH.line)
    row(rich(HEX.dim, "Monitor: " .. #G.conns .. " conexiones"), string.format("render %.2f ms · %.1f actualizaciones/s · errores internos %d", PERF.renderMs, PERF.renderRate, G.internalErrors), TH.line)
    row(rich(HEX.dim, "ⓘ Qué es aproximado y qué necesita Studio"), "Toca para ver cómo se mide cada valor", TH.line)
    items[#items].onTap = function() UI.detail("Cómo se mide", PERF_NOTES) end
    UI.lists.PERFORMANCE.set(items)
end

---------------------------------------------------------------- BUCLE DE REFRESCO
-- Un solo bucle, solo con el panel abierto, y solo re-dibuja lo que cambió.
local RENDER = {MAIN = renderMain, REMOTES = renderRemotes, TOOLS = renderTools, BUTTONS = renderButtons, LOGS = renderLogs, PERFORMANCE = renderPerf}
local lastSig, lastTime = {}, {}
local function signature(tab)
    if tab == "REMOTES" then return REG.remoteVersion
    elseif tab == "TOOLS" then return REG.toolVersion .. ":" .. #toolState.results .. ":" .. #WATCH.list
    elseif tab == "BUTTONS" then return REG.buttonVersion
    elseif tab == "LOGS" then return LOG.version end
    return nil
end
task.spawn(function()
    while G.alive do
        task.wait(0.35)
        if not G.alive then break end
        local now = os.clock()
        PERF.renderWinCount = PERF.renderWinCount or 0
        if now - PERF.renderWin >= 2 then
            PERF.renderRate = PERF.renderWinCount / (now - PERF.renderWin)
            PERF.renderWin, PERF.renderWinCount = now, 0
        end
        footer.Text = string.format('<font color="%s">%s</font> · remotos %d · registros %d%s · FPS %.0f',
            LOG.paused and HEX.warn or HEX.ok, LOG.paused and "EN PAUSA" or "EN VIVO", #REG.remotes, LOG.total,
            LOG.suppressed > 0 and (" (spam " .. LOG.suppressed .. ")") or "", PERF.fps)
        if UI.open then
            PERF.sample()
            local tab = UI.tab
            local sig = signature(tab)
            local periodic = (tab == "MAIN" or tab == "PERFORMANCE") and 1 or ((tab == "BUTTONS") and 2 or 1.5)
            if UI.force or sig == nil and (now - (lastTime[tab] or 0) >= periodic) or (sig ~= nil and sig ~= lastSig[tab]) or (now - (lastTime[tab] or 0) >= periodic * 3) then
                UI.force = false
                local t0 = os.clock()
                local ok, err = pcall(RENDER[tab])
                if not ok then
                    G.internalErrors = G.internalErrors + 1
                    G.lastInternalError = tostring(err)
                end
                PERF.renderMs = (os.clock() - t0) * 1000
                PERF.renderWinCount = PERF.renderWinCount + 1
                lastSig[tab], lastTime[tab] = sig, now
            end
        end
    end
end)

---------------------------------------------------------------- LIMPIEZA
function G.destroy()
    if not G.alive then return end
    G.alive = false
    for _, c in ipairs(G.conns) do pcall(function() c:Disconnect() end) end
    G.conns = {}
    pcall(function() screen:Destroy() end)
    if ENV.GOY_DIAG == G then ENV.GOY_DIAG = nil end
end
U.conn(screen.AncestryChanged, function() if not screen.Parent then G.destroy() end end)

---------------------------------------------------------------- MINIMIZAR
do
    local collapsed = false
    U.conn(minBtn.Activated, function()
        collapsed = not collapsed
        tabBar.Visible, body.Visible, footer.Visible = not collapsed, not collapsed, not collapsed
        panel.Size = collapsed and UDim2.fromOffset(PW, 38) or UDim2.fromOffset(PW, PH)
    end)
end

---------------------------------------------------------------- SCRIPT DE STUDIO (texto para copiar)
STUDIO_SCRIPT = [==[
--[[
 GOY DIAGNOSTICS · SCRIPT DE SERVIDOR (solo para TU propio juego en Roblox Studio)
 Dónde va: ServerScriptService → Script (no LocalScript).
 Qué hace:
   · Escucha OnServerEvent de todos tus RemoteEvent / UnreliableRemoteEvent
     (agrega un oyente extra, no cambia la lógica de tu juego).
   · Registra jugador, remoto, argumentos, tipos y frecuencia por jugador;
     avisa si alguien supera MAX_PER_SECOND.
   · Marca cada evento con debug.profilebegin/profileend: aparece con nombre
     propio en el MicroProfiler (Ctrl+F6) y en el Script Profiler.
   · Para RemoteFunction: usa _G.GOYDiag.wrapInvoke(remote, tuFuncion) en lugar
     de remote.OnServerInvoke = tuFuncion, y quedará registrado igual.
   · Si pones tu UserId en AUTHORIZED, envía lo registrado al panel GOY del
     cliente por el remoto "GOY_DiagFeed" (categoría "Servidor"). A nadie más.
]]

local CONFIG = {
    AUTHORIZED = {},          -- ej. {12345678}: solo estos jugadores reciben el feed
    PRINT = true,             -- imprime en la consola del servidor (F9 → Server)
    MAX_PER_SECOND = 20,      -- aviso de spam por jugador y remoto
    FEED_PER_SECOND = 20,     -- máximo de mensajes por segundo hacia el panel
    STATS_EVERY = 5,          -- segundos entre envíos de métricas del servidor
    ROOTS = {"ReplicatedStorage", "Workspace", "ReplicatedFirst"},
}

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local authorized = {}
for _, id in ipairs(CONFIG.AUTHORIZED) do authorized[id] = true end

local feed = RS:FindFirstChild("GOY_DiagFeed")
if not feed then
    feed = Instance.new("RemoteEvent")
    feed.Name = "GOY_DiagFeed"
    feed.Parent = RS
end
-- El cliente nunca puede usar el feed para enviar nada.
feed.OnServerEvent:Connect(function() end)

local function ser(v, depth)
    depth = depth or 0
    local t = typeof(v)
    if t == "string" then return string.format("%q", #v > 100 and (v:sub(1, 100) .. "…") or v) end
    if t == "Instance" then return v.ClassName .. "(" .. v:GetFullName() .. ")" end
    if t == "table" then
        if depth >= 2 then return "{…}" end
        local parts, n = {}, 0
        for k, x in pairs(v) do
            n += 1
            if n > 10 then table.insert(parts, "…") break end
            table.insert(parts, tostring(k) .. "=" .. ser(x, depth + 1))
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    end
    return tostring(v)
end

local function describe(...)
    local n = select("#", ...)
    local args, types = {}, {}
    for i = 1, math.min(n, 10) do
        local v = select(i, ...)
        table.insert(types, typeof(v))
        table.insert(args, i .. ": " .. ser(v))
    end
    return table.concat(args, " | "), table.concat(types, ", ")
end

local sentThisSecond, secondStart = 0, os.clock()
local function sendFeed(...)
    local now = os.clock()
    if now - secondStart >= 1 then sentThisSecond, secondStart = 0, now end
    if sentThisSecond >= CONFIG.FEED_PER_SECOND then return end
    sentThisSecond += 1
    for _, p in ipairs(Players:GetPlayers()) do
        if authorized[p.UserId] then feed:FireClient(p, ...) end
    end
end

local rate = {} -- rate[player][remoteName] = {count, start}
local function overLimit(player, name)
    rate[player] = rate[player] or {}
    local r = rate[player][name]
    local now = os.clock()
    if not r or now - r.start >= 1 then r = {count = 0, start = now}; rate[player][name] = r end
    r.count += 1
    return r.count == CONFIG.MAX_PER_SECOND + 1
end
Players.PlayerRemoving:Connect(function(p) rate[p] = nil end)

local function record(kind, remote, player, ...)
    debug.profilebegin("GOY " .. kind .. " " .. remote.Name)
    local args, types = describe(...)
    if CONFIG.PRINT then
        print(("[GOY DIAG] %s %s ← %s | %s | tipos: %s"):format(kind, remote:GetFullName(), player.Name, args, types))
    end
    sendFeed(kind, remote:GetFullName(), player.Name, args, types)
    if overLimit(player, remote.Name) then
        warn(("[GOY DIAG] %s supera %d/s en %s"):format(player.Name, CONFIG.MAX_PER_SECOND, remote:GetFullName()))
        sendFeed("Spam", remote:GetFullName(), player.Name, ">" .. CONFIG.MAX_PER_SECOND .. "/s", "")
    end
    debug.profileend()
end

local hooked = setmetatable({}, {__mode = "k"})
local function hook(obj)
    if hooked[obj] or obj == feed then return end
    if obj:IsA("RemoteEvent") or obj:IsA("UnreliableRemoteEvent") then
        hooked[obj] = true
        obj.OnServerEvent:Connect(function(player, ...) record("OnServerEvent", obj, player, ...) end)
    end
end
for _, rootName in ipairs(CONFIG.ROOTS) do
    local root = game:GetService(rootName)
    for _, d in ipairs(root:GetDescendants()) do hook(d) end
    root.DescendantAdded:Connect(hook)
end

-- RemoteFunction: envuelve TU función para registrarla.
_G.GOYDiag = {
    wrapInvoke = function(remote, handler)
        remote.OnServerInvoke = function(player, ...)
            record("OnServerInvoke", remote, player, ...)
            return handler(player, ...)
        end
    end,
}

-- Métricas del servidor (solo visibles en el servidor / feed autorizado).
task.spawn(function()
    local frames, start = 0, os.clock()
    RunService.Heartbeat:Connect(function() frames += 1 end)
    while true do
        task.wait(CONFIG.STATS_EVERY)
        local now = os.clock()
        local hz = frames / (now - start)
        frames, start = 0, now
        local mem = Stats:GetTotalMemoryUsageMb()
        local msg = ("Heartbeat %.1f Hz · memoria servidor %.0f MB · jugadores %d"):format(hz, mem, #Players:GetPlayers())
        if CONFIG.PRINT then print("[GOY DIAG] " .. msg) end
        sendFeed("ServerStats", msg)
    end
end)

print("[GOY DIAG] Instrumentación de servidor activa.")
]==]

---------------------------------------------------------------- ARRANQUE
watchAttributes(LP, "Jugador")
local function onCharacter(char)
    if not char then return end
    LOG.add("Cambio", "Personaje", "Replicado", "", nil, "Tu personaje apareció: " .. U.path(char))
    watchAttributes(char, "Personaje")
    task.spawn(function()
        local hum = char:WaitForChild("Humanoid", 10)
        if hum and G.alive then
            U.conn(hum.Died, function() LOG.add("Cambio", "Personaje", "Replicado", "", nil, "Tu Humanoid murió") end)
        end
    end)
end
onCharacter(LP.Character)
U.conn(LP.CharacterAdded, onCharacter)
G.UI, G.REG, G.LOG, G.PERF, G.CAP = UI, REG, LOG, PERF, CAP -- acceso de solo lectura para depurar
UI.setTab("MAIN")
LOG.add("Sistema", "GOY Diagnostics", "", "", nil, "Iniciado · ejecutor " .. CAP.executor .. " · solo lectura")
task.spawn(initialScan)
