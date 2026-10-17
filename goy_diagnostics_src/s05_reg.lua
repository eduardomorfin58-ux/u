
-------------------------------------------------------------------------------
-- 5. REG — objetos detectados (remotos, herramientas, botones, valores),
--    escaneo por lotes, atributos, vigilancia y consola
-------------------------------------------------------------------------------
local REG = {
    remotes = {}, remoteByInst = setmetatable({}, {__mode = "k"}), remoteVersion = 0,
    tools = {}, toolByInst = setmetatable({}, {__mode = "k"}), toolVersion = 0,
    buttons = {}, buttonByInst = setmetatable({}, {__mode = "k"}), buttonVersion = 0,
    values = 0, valueByInst = setmetatable({}, {__mode = "k"}),
    containers = {}, watched = {}, scanDone = false, scanned = 0,
    queue = {}, qHead = 1, qTail = 0, qMax = 0, qProcessed = 0,
    instAdded = 0, instRemoved = 0, logWorkspaceInstances = false,
    specials = {},   -- nombre de remoto → manejador propio (lo llena FEED)
    guiRoot = nil,   -- nuestra GUI (se ignora)
}
local REMOTE_CLASSES = {RemoteEvent = true, UnreliableRemoteEvent = true, RemoteFunction = true,
    BindableEvent = true, BindableFunction = true}
local REMOTE_DIR = {RemoteEvent = STR.DIR_RE, UnreliableRemoteEvent = STR.DIR_RE, BindableEvent = STR.DIR_BE,
    RemoteFunction = STR.DIR_RF, BindableFunction = STR.DIR_BF}

function REG.isOwnGui(inst)
    local root = REG.guiRoot
    if not root then return false end
    local ok, r = pcall(function() return inst == root or inst:IsDescendantOf(root) end)
    return ok and r
end

local function locationOf(inst, rootName)
    if rootName ~= "Players" then return rootName end
    local ok, r = pcall(function()
        if not inst:IsDescendantOf(LP) then return "Players" end
        local pg = LP:FindFirstChildOfClass("PlayerGui")
        if pg and inst:IsDescendantOf(pg) then return STR.LOC.PLAYER_GUI end
        local bp = LP:FindFirstChildOfClass("Backpack")
        if bp and inst:IsDescendantOf(bp) then return STR.LOC.BACKPACK end
        return STR.LOC.PLAYER
    end)
    return ok and r or "Players"
end

---------------- Remotos
local function onRemoteSignal(e, cat, dir, ...)
    e.count = e.count + 1
    e.last = U.stamp()
    REG.remoteVersion = REG.remoteVersion + 1
    if not RATE.ok(e, e.name) then return end
    local a, types = U.args(...)
    e.lastArgs, e.lastTypes = a, table.concat(types, ", ")
    LOG.add(cat, e.name, dir, a, types, e.path, {remote = e.path, code = U.code(e, U.stamp(), ...)})
end

function REG.addRemote(inst, rootName, class)
    if REG.remoteByInst[inst] then return end
    local e = {inst = inst, name = inst.Name, class = class, path = U.path(inst), loc = locationOf(inst, rootName),
        count = 0, last = nil, lastArgs = "", lastTypes = "", observable = false, addedAt = U.stamp(), dir = REMOTE_DIR[class]}
    local special = REG.specials[e.name]
    if class == "RemoteEvent" or class == "UnreliableRemoteEvent" then
        e.observable = true
        if special then
            e.conn = special(e, inst)
        else
            e.conn = U.conn(inst.OnClientEvent, function(...) onRemoteSignal(e, "Remote", STR.DIR.S2C, ...) end, "OnClientEvent")
        end
    elseif class == "BindableEvent" then
        e.observable = true
        e.conn = U.conn(inst.Event, function(...) onRemoteSignal(e, "Bindable", STR.DIR.LOCAL, ...) end, "BindableEvent")
    end
    e.nameConn = U.conn(inst:GetPropertyChangedSignal("Name"), function()
        e.name, e.path = inst.Name, U.path(inst)
        REG.remoteVersion = REG.remoteVersion + 1
    end, "nombre remoto")
    REG.remoteByInst[inst] = e
    REG.remotes[#REG.remotes + 1] = e
    REG.remoteVersion = REG.remoteVersion + 1
    if REG.scanDone then LOG.add("Instancia", e.name, "", "", nil, string.format(STR.MSG.NEW_REMOTE, class, e.path)) end
end

local function removeFrom(list, item)
    for i = #list, 1, -1 do
        if list[i] == item then table.remove(list, i) return end
    end
end

function REG.removeRemote(inst)
    local e = REG.remoteByInst[inst]
    if not e then return end
    U.disc(e.conn); U.disc(e.nameConn)
    REG.remoteByInst[inst] = nil
    removeFrom(REG.remotes, e)
    REG.remoteVersion = REG.remoteVersion + 1
    LOG.add("Instancia", e.name, "", "", nil, string.format(STR.MSG.REMOVED, e.class, e.path))
end

---------------- Herramientas
local function toolOwner(tool)
    local ok, owner, state = pcall(function()
        local p = tool.Parent
        if not p then return "—", STR.LOC.OUTSIDE end
        if p:IsA("Backpack") then return (p.Parent and p.Parent.Name or "?"), STR.LOC.IN_BACKPACK end
        local pl = S.Players:GetPlayerFromCharacter(p)
        if pl then return pl.Name, STR.TOOL_STATE_EQUIPPED end
        return "—", string.format(STR.LOC.IN, p.Name)
    end)
    if ok then return owner, state end
    return "?", "?"
end

function REG.addTool(inst, rootName)
    if REG.toolByInst[inst] then return end
    local e = {inst = inst, name = inst.Name, class = inst.ClassName, loc = rootName, equips = 0, path = U.path(inst)}
    local function update(reason)
        e.owner, e.state = toolOwner(inst)
        e.path = U.path(inst)
        REG.toolVersion = REG.toolVersion + 1
        if reason then LOG.add("Tool", e.name, "", "", nil, string.format(STR.MSG.TOOL_INFO, reason, tostring(e.owner), tostring(e.state))) end
    end
    update(REG.scanDone and STR.MSG.TOOL_APPEARED or nil)
    e.anc = U.conn(inst.AncestryChanged, function() if inst.Parent then update(STR.MSG.TOOL_MOVED) end end, "tool lugar")
    pcall(function()
        e.eq = U.conn(inst.Equipped, function() e.equips = e.equips + 1; update(STR.MSG.TOOL_EQUIPPED) end, "tool equipada")
        e.uneq = U.conn(inst.Unequipped, function() update(STR.MSG.TOOL_UNEQUIPPED) end, "tool desequipada")
        e.act = U.conn(inst.Activated, function() LOG.add("Tool", e.name, "", "", nil, STR.MSG.TOOL_USED) end, "tool activada")
    end)
    REG.toolByInst[inst] = e
    REG.tools[#REG.tools + 1] = e
end

function REG.removeTool(inst)
    local e = REG.toolByInst[inst]
    if not e then return end
    -- Backpack ↔ Character dispara DescendantRemoving pero sigue en el juego.
    task.defer(function()
        local ok, still = pcall(function() return inst:IsDescendantOf(game) end)
        if ok and still then return end
        U.disc(e.anc); U.disc(e.eq); U.disc(e.uneq); U.disc(e.act)
        REG.toolByInst[inst] = nil
        removeFrom(REG.tools, e)
        REG.toolVersion = REG.toolVersion + 1
        LOG.add("Tool", e.name, "", "", nil, STR.MSG.TOOL_GONE)
    end)
end

---------------- Botones (solo tu PlayerGui)
function REG.addButton(inst)
    if REG.buttonByInst[inst] or REG.isOwnGui(inst) then return end
    local e = {inst = inst, name = inst.Name, class = inst.ClassName, clicks = 0, lastClick = nil, path = U.path(inst)}
    e.conn = U.conn(inst.Activated, function()
        e.clicks = e.clicks + 1
        e.lastClick = U.stamp()
        REG.buttonVersion = REG.buttonVersion + 1
        local txt = ""
        pcall(function() txt = inst.Text or "" end)
        LOG.add("Botón", e.name, STR.DIR.GUI, "", nil,
            (txt ~= "" and string.format(STR.MSG.BUTTON_TEXT, U.trunc(txt, 60)) or "") .. string.format(STR.MSG.BUTTON_NOTE, e.path))
    end, "botón")
    REG.buttonByInst[inst] = e
    REG.buttons[#REG.buttons + 1] = e
    REG.buttonVersion = REG.buttonVersion + 1
end

function REG.removeButton(inst)
    local e = REG.buttonByInst[inst]
    if not e then return end
    U.disc(e.conn)
    REG.buttonByInst[inst] = nil
    removeFrom(REG.buttons, e)
    REG.buttonVersion = REG.buttonVersion + 1
end

---------------- Valores de tu jugador (sin duplicados; se descuentan al eliminarse)
function REG.addValue(inst)
    if REG.valueByInst[inst] or REG.values >= CONFIG.MAX_VALUES then return end
    local last = nil
    pcall(function() last = inst.Value end)
    local e = {name = inst.Name}
    REG.valueByInst[inst] = e
    REG.values = REG.values + 1
    e.conn = U.conn(inst.Changed, function()
        if not RATE.ok(e, e.name) then return end
        local newv = nil
        pcall(function() newv = inst.Value end)
        local before = U.ser(last)
        last = newv
        LOG.add("Valor", inst.Name, STR.DIR.REPLICATED_VALUE, before .. "  →  " .. U.ser(newv), {U.typeOf(newv)}, U.path(inst))
    end, "valor")
end

function REG.removeValue(inst)
    local e = REG.valueByInst[inst]
    if not e then return end
    U.disc(e.conn)
    REG.valueByInst[inst] = nil
    REG.values = math.max(0, REG.values - 1)
end

---------------- Clasificación y escaneo
local function isOwnValue(inst)
    local ok, r = pcall(function()
        return inst:IsA("ValueBase") and inst:IsDescendantOf(LP) and inst:FindFirstAncestorOfClass("PlayerGui") == nil
    end)
    return ok and r
end

function REG.classify(inst, rootName)
    local ok, cls = pcall(function() return inst.ClassName end)
    if not ok then return end
    if REMOTE_CLASSES[cls] then
        REG.addRemote(inst, rootName, cls)
    elseif cls == "Tool" or cls == "HopperBin" then
        REG.addTool(inst, rootName)
    elseif cls == "TextButton" or cls == "ImageButton" then
        if rootName == "Players" then REG.addButton(inst) end
    elseif rootName == "Players" and isOwnValue(inst) then
        REG.addValue(inst)
    end
end

local function enqueue(inst, c)
    local q, t = REG.queue, REG.qTail
    q[t + 1], q[t + 2] = inst, c
    REG.qTail = t + 2
    local pending = (REG.qTail - REG.qHead + 1) / 2
    if pending > REG.qMax then REG.qMax = pending end
end

function REG.pending()
    return math.floor((REG.qTail - REG.qHead + 1) / 2)
end

local function onDescendantRemoving(c, inst)
    c.count = math.max(0, c.count - 1)
    c.removed = c.removed + 1
    REG.instRemoved = REG.instRemoved + 1
    if REG.remoteByInst[inst] then REG.removeRemote(inst) end
    if REG.toolByInst[inst] then REG.removeTool(inst) end
    if REG.buttonByInst[inst] then REG.removeButton(inst) end
    if REG.valueByInst[inst] then REG.removeValue(inst) end
end

function REG.watchContainer(root, rootName)
    local c = {name = rootName, inst = root, count = 0, added = 0, removed = 0}
    REG.containers[#REG.containers + 1] = c
    REG.watched[root] = c
    -- El evento solo encola (O(1)); se procesa por lotes en Heartbeat.
    U.conn(root.DescendantAdded, function(inst)
        c.count = c.count + 1
        c.added = c.added + 1
        REG.instAdded = REG.instAdded + 1
        enqueue(inst, c)
    end, "DescendantAdded " .. rootName)
    U.conn(root.DescendantRemoving, function(inst) onDescendantRemoving(c, inst) end, "DescendantRemoving " .. rootName)
end

local function processAdded(inst, c)
    local okA, alive = pcall(function() return inst:IsDescendantOf(game) end)
    if not (okA and alive) or REG.isOwnGui(inst) then return end
    REG.classify(inst, c.name)
    local logIt = REG.scanDone and c.name ~= "Players" and (c.name ~= "Workspace" or REG.logWorkspaceInstances)
    if logIt and RATE.ok(c, string.format(STR.MSG.INST_RATE, c.name)) then
        local okc, cls = pcall(function() return inst.ClassName end)
        LOG.add("Instancia", inst.Name, "", "", nil, string.format(STR.MSG.NEW_INST, tostring(okc and cls or "?"), U.path(inst)))
    end
end

function REG.processQueue()
    if REG.qHead > REG.qTail then return end
    local q = REG.queue
    local deadline = os.clock() + CONFIG.QUEUE_BUDGET_MS / 1000
    local n = 0
    while REG.qHead <= REG.qTail do
        local inst, c = q[REG.qHead], q[REG.qHead + 1]
        q[REG.qHead], q[REG.qHead + 1] = nil, nil
        REG.qHead = REG.qHead + 2
        U.try("cola de instancias", processAdded, inst, c)
        REG.qProcessed = REG.qProcessed + 1
        n = n + 1
        if n % CONFIG.QUEUE_CHECK_EVERY == 0 and os.clock() > deadline then break end
    end
    if REG.qHead > REG.qTail then REG.queue, REG.qHead, REG.qTail = {}, 1, 0 end
end
U.conn(S.RunService and S.RunService.Heartbeat, REG.processQueue, "cola Heartbeat")

function REG.initialScan()
    local roots = {}
    for _, name in ipairs(CONFIG.WATCH_NAMES) do
        local s = svc(name)
        if s then
            roots[#roots + 1] = {s, name}
            REG.watchContainer(s, name)
        end
    end
    for _, r in ipairs(roots) do
        local ok, list = pcall(function() return r[1]:GetDescendants() end)
        if ok and list then
            REG.watched[r[1]].count = #list
            for i, inst in ipairs(list) do
                if not G.alive then return end
                REG.classify(inst, r[2])
                REG.scanned = REG.scanned + 1
                if i % CONFIG.SCAN_YIELD_EVERY == 0 then task.wait() end
            end
        end
    end
    REG.scanDone = true
    LOG.add("Sistema", STR.MSG.SCAN, "", "", nil, string.format(STR.MSG.SCAN_DONE,
        REG.scanned, #REG.remotes, #REG.tools, #REG.buttons))
end

---------------- Atributos de tu jugador y personaje
function REG.watchAttributes(inst, label)
    U.conn(inst.AttributeChanged, function(attr)
        local v = nil
        pcall(function() v = inst:GetAttribute(attr) end)
        LOG.add("Cambio", label .. "@" .. tostring(attr), STR.DIR.REPLICATED, U.ser(v), {U.typeOf(v)}, U.path(inst))
    end, "atributo")
end

---------------- Vigilancia manual (.Changed) desde el inspector
local WATCH = {list = {}}
function WATCH.has(inst)
    for _, w in ipairs(WATCH.list) do if w.inst == inst then return true end end
    return false
end
function WATCH.toggle(inst)
    for i, w in ipairs(WATCH.list) do
        if w.inst == inst then
            U.disc(w.conn)
            table.remove(WATCH.list, i)
            return false
        end
    end
    if #WATCH.list >= CONFIG.MAX_WATCH then U.disc(table.remove(WATCH.list, 1).conn) end
    local w = {inst = inst, name = inst.Name}
    w.conn = U.conn(inst.Changed, function(prop)
        if not RATE.ok(w, w.name) then return end
        local v = nil
        pcall(function() v = inst[prop] end)
        LOG.add("Cambio", w.name .. "." .. tostring(prop), STR.DIR.OBSERVED, U.ser(v), {U.typeOf(v)}, U.path(inst))
    end, "vigilado")
    WATCH.list[#WATCH.list + 1] = w
    return true
end

---------------- Consola del cliente (LogService)
local CONSOLE = {errors = 0, warnings = 0, infos = 0, rateName = "consola del cliente"}
U.conn(S.LogService and S.LogService.MessageOut, function(msg, mtype)
    local t = tostring(mtype)
    local isError, isWarn = t:find("Error") ~= nil, t:find("Warning") ~= nil
    if isError then CONSOLE.errors = CONSOLE.errors + 1
    elseif isWarn then CONSOLE.warnings = CONSOLE.warnings + 1
    else CONSOLE.infos = CONSOLE.infos + 1 return end
    local m = tostring(msg)
    if m:find("GOY DIAG", 1, true) then return end
    if RATE.ok(CONSOLE) then
        LOG.add("Consola", isError and STR.MSG.ERROR or STR.MSG.WARNING, STR.DIR.CONSOLE, U.trunc(m, 400), nil, "", {alert = isError})
    end
end, "consola")
