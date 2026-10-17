
-------------------------------------------------------------------------------
-- 6. FEED — datos de TU script de Studio (GOY_DiagFeed) y filtro de jugadores
--    El filtro se pide al servidor por GOY_DiagMode (remoto propio de tu juego)
--    y además se aplica en el cliente para que el cambio sea instantáneo.
-------------------------------------------------------------------------------
local FEED = {
    remote = nil, modeRemote = nil, entry = nil,
    received = 0, droppedByServer = 0, stats = nil,
    filter = CFG.get("players", "all"),   -- "all" | "me" | UserId (número)
    serverMode = nil, lastReq = -math.huge, reqScheduled = false,
    names = {},                            -- UserId → nombre visto en el feed
}
if FEED.filter ~= "all" and FEED.filter ~= "me" and type(FEED.filter) ~= "number" then FEED.filter = "all" end

local function shortName(path)
    path = tostring(path or "")
    return path:match("([^%.]+)$") or path
end

-- Acepta el protocolo 2 (una tabla con campos) y el formato antiguo (posicional).
function FEED.parse(...)
    local first = ...
    if type(first) == "table" and first.v then return first end
    local kind, remote, player, args, types = ...
    return {kind = tostring(kind or "?"), remote = remote, player = player, args = args, types = types,
        msg = (kind == "ServerStats") and tostring(remote or "") or nil}
end

local FEED_KINDS = {
    OnServerEvent = function(m)
        return "Servidor", shortName(m.remote), string.format(STR.DIR.C2S, m.kind), false
    end,
    OnServerInvoke = function(m)
        return "Servidor", shortName(m.remote), string.format(STR.DIR.C2S, m.kind), false
    end,
    Spam = function(m)
        return "Servidor", string.format(STR.MSG.SPAM, shortName(m.remote)), STR.DIR.SERVER_NOTICE, true
    end,
    ServerStats = function(m)
        FEED.stats = m.msg
        return "Servidor", "ServerStats", STR.DIR.SERVER_STATS, false
    end,
    Dropped = function(m)
        FEED.droppedByServer = FEED.droppedByServer + (tonumber(m.count) or 0)
        return "Sistema", STR.MSG.FEED_DROPPED, "", true
    end,
    Mode = function(m)
        FEED.serverMode = m.mode
        return "Sistema", STR.MSG.SERVER_MODE, "", not m.ok
    end,
}

function FEED.onMessage(e, ...)
    e.count = e.count + 1
    e.last = U.stamp()
    FEED.received = FEED.received + 1
    REG.remoteVersion = REG.remoteVersion + 1
    local m = FEED.parse(...)
    local handler = FEED_KINDS[m.kind]
    local isControl = m.kind == "Mode" or m.kind == "Dropped"
    if not isControl and not RATE.ok(e, STR.MSG.FEED_RATE, CONFIG.RATE_FEED) then return end
    if m.userId then FEED.names[m.userId] = m.player end
    local cat, name, dir, alert = "Servidor", m.kind, "", false
    if handler then cat, name, dir, alert = handler(m) end
    local extra = m.msg or (m.reason and tostring(m.reason)) or (m.count and string.format(STR.MSG.FEED_DROPPED_N, tostring(m.count))) or ""
    LOG.add(cat, name, dir, m.args and tostring(m.args) or "", m.types and tostring(m.types) or "", extra,
        {kind = m.kind, player = m.player, userId = m.userId, remote = m.remote, alert = alert})
end

REG.specials[CONFIG.FEED_REMOTE] = function(e, inst)
    FEED.remote, FEED.entry = inst, e
    return U.conn(inst.OnClientEvent, function(...) FEED.onMessage(e, ...) end, "feed del servidor")
end
REG.specials[CONFIG.MODE_REMOTE] = function(e, inst)
    FEED.modeRemote = inst
    task.defer(function() FEED.sendMode() end)
    return nil -- solo se usa para pedir el modo; no se escucha
end

function FEED.label(v)
    v = v or FEED.filter
    if v == "all" then return STR.PLAYERS_ALL end
    if v == "me" then return STR.PLAYERS_ME end
    local name = FEED.names[v]
    if not name then
        pcall(function()
            local p = S.Players:GetPlayerByUserId(v)
            if p then name = p.Name end
        end)
    end
    return string.format(STR.PLAYERS_ONE, name or tostring(v))
end

-- Pide el modo al servidor (máx. CONFIG.MODE_REQ_PER_SEC por segundo; el
-- servidor también lo limita y valida).
function FEED.sendMode()
    if not FEED.modeRemote then return false end
    local wait = (1 / CONFIG.MODE_REQ_PER_SEC) - (os.clock() - FEED.lastReq)
    if wait > 0 then
        if not FEED.reqScheduled then
            FEED.reqScheduled = true
            task.delay(wait, function()
                FEED.reqScheduled = false
                if G.alive then FEED.sendMode() end
            end)
        end
        return true
    end
    FEED.lastReq = os.clock()
    local ok = pcall(function() FEED.modeRemote:FireServer({mode = FEED.filter}) end)
    return ok
end

function FEED.setFilter(v)
    FEED.filter = v
    CFG.set("players", v)
    local sent = FEED.sendMode()
    LOG.add("Sistema", STR.MSG.PLAYERS, "", "", nil, string.format(sent and STR.PLAYERS_SENT or STR.PLAYERS_LOCAL, FEED.label(v)))
    FEED.version = (FEED.version or 0) + 1
end

-- Filtro instantáneo en el cliente. Los eventos locales (remotos que te llegan,
-- tus valores, tus botones) son tuyos; las métricas del servidor pasan siempre.
function FEED.passes(e)
    local f = FEED.filter
    if f == "all" then return true end
    local uid = e.userId
    if e.cat ~= "Servidor" then uid = LP.UserId
    elseif uid == nil then return true end
    if f == "me" then return uid == LP.UserId end
    return uid == f
end

function FEED.cycle()
    -- Todos → Solo yo → Elegir… (la elección abre una lista)
    if FEED.filter == "all" then FEED.setFilter("me") return nil end
    if FEED.filter == "me" then return "pick" end
    FEED.setFilter("all")
    return nil
end

-------------------------------------------------------------------------------
-- 7. MODOS — definidos en CONFIG.MODES (una fila por modo)
-------------------------------------------------------------------------------
local MODE = {index = 1, def = CONFIG.MODES[1], version = 0, alertPending = false, lastAlert = nil,
    capture = nil, lastCapture = nil, captureFinished = false}

function MODE.find(id)
    for i, m in ipairs(CONFIG.MODES) do if m.id == id then return i end end
    return 1
end

function MODE.set(i, silentLog)
    MODE.index = i
    MODE.def = CONFIG.MODES[i]
    MODE.alertPending = false
    MODE.version = MODE.version + 1
    CFG.set("mode", MODE.def.id)
    if MODE.def.capture then MODE.startCapture() end
    if not silentLog then LOG.add("Sistema", STR.MSG.MODE, "", "", nil, string.format(STR.MODE_SET, MODE.def.label)) end
end

function MODE.cycle()
    MODE.set(MODE.index % #CONFIG.MODES + 1)
end

function MODE.passes(e)
    local d = MODE.def
    if d.cats and not d.cats[e.cat] then return false end
    if d.alertsOnly and not e.alert then return false end
    return true
end

function MODE.drawAllowed()
    return not MODE.def.silent or MODE.alertPending
end

---------------- Captura
function MODE.startCapture()
    MODE.capture = {start = os.clock(), dur = CONFIG.CAPTURE_SECONDS, total = 0, byKey = {}, byPlayer = {}, bySecond = {}, byCat = {}}
    MODE.captureFinished = false
end

function MODE.captureAdd(e)
    local c = MODE.capture
    if not c or e.cat == "Sistema" then return end
    local sec = math.floor(e.clock - c.start) + 1
    if sec > c.dur then return end
    c.total = c.total + 1
    local key = e.remote or (e.cat .. " · " .. e.name)
    c.byKey[key] = (c.byKey[key] or 0) + 1
    if e.player then c.byPlayer[e.player] = (c.byPlayer[e.player] or 0) + 1 end
    c.bySecond[sec] = (c.bySecond[sec] or 0) + 1
    c.byCat[e.cat] = (c.byCat[e.cat] or 0) + 1
end

local function topOf(map, n)
    local list = {}
    for k, v in pairs(map) do list[#list + 1] = {k = k, v = v} end
    table.sort(list, function(a, b) if a.v ~= b.v then return a.v > b.v end return tostring(a.k) < tostring(b.k) end)
    local out = {}
    for i = 1, math.min(n, #list) do out[i] = list[i] end
    return out
end

function MODE.captureSummary(c)
    local peak, peakSec = 0, 0
    for s, v in pairs(c.bySecond) do if v > peak then peak, peakSec = v, s end end
    local t = {
        string.format(STR.CAPTURE_TXT.HEAD, c.dur, U.fullDate()),
        string.format(STR.CAPTURE_TXT.STATS, c.total, c.total / c.dur, peak, peakSec),
        "", STR.CAPTURE_TXT.TOP,
    }
    for _, it in ipairs(topOf(c.byKey, 10)) do t[#t + 1] = string.format("  ×%-5d %s", it.v, it.k) end
    t[#t + 1] = ""
    t[#t + 1] = STR.CAPTURE_TXT.PLAYERS
    local players = topOf(c.byPlayer, 10)
    if #players == 0 then t[#t + 1] = STR.CAPTURE_TXT.NO_PLAYERS end
    for _, it in ipairs(players) do t[#t + 1] = string.format("  ×%-5d %s", it.v, it.k) end
    t[#t + 1] = ""
    t[#t + 1] = STR.CAPTURE_TXT.CATS
    for _, it in ipairs(topOf(c.byCat, 20)) do t[#t + 1] = string.format("  ×%-5d %s", it.v, it.k) end
    t[#t + 1] = ""
    t[#t + 1] = STR.CAPTURE_TXT.PER_SEC
    local row = {}
    for s = 1, c.dur do row[#row + 1] = tostring(c.bySecond[s] or 0) end
    t[#t + 1] = "  " .. table.concat(row, " ")
    return table.concat(t, "\n")
end

-- Se llama desde el bucle: cierra la captura al cumplirse el tiempo.
function MODE.tickCapture()
    local c = MODE.capture
    if not c or os.clock() - c.start < c.dur then return end
    MODE.capture = nil
    MODE.lastCapture = {data = c, text = MODE.captureSummary(c)}
    MODE.captureFinished = true
    LOG.add("Sistema", STR.MSG.CAPTURE, "", "", nil, string.format(STR.CAPTURE_DONE, c.total, c.dur), {alert = false})
end

function MODE.captureLeft()
    local c = MODE.capture
    if not c then return nil end
    return math.max(0, math.ceil(c.dur - (os.clock() - c.start)))
end

LOG.listeners[#LOG.listeners + 1] = function(e)
    if e.alert then
        MODE.lastAlert = e
        if MODE.def.silent then MODE.alertPending = true end
    end
    if MODE.capture then MODE.captureAdd(e) end
end

MODE.set(MODE.find(CFG.get("mode", "normal")), true)

-------------------------------------------------------------------------------
-- 8. PERF — métricas del cliente (todas opcionales)
-------------------------------------------------------------------------------
local PERF = {fps = 0, frames = 0, frameMax = 0, frameAvg = 0, accum = 0, win = os.clock(), lastFrameMax = 0,
    hist = {}, ping = nil, pingSrc = "", mem = nil, memScript = nil, luaHeap = nil, physFps = nil,
    recv = nil, send = nil, instCount = nil, renderMs = 0, renderRate = 0, renderWin = os.clock(), renderWinCount = 0,
    logRate = 0, logWinStart = os.clock(), logWinTotal = 0, lastSample = -math.huge, lastPingAlert = -math.huge, lastFpsAlert = -math.huge}

local function onFrame(dt)
    dt = dt or 0
    PERF.frames = PERF.frames + 1
    PERF.accum = PERF.accum + dt
    if dt > PERF.frameMax then PERF.frameMax = dt end
    local now = os.clock()
    if now - PERF.win < 1 then return end
    PERF.fps = PERF.frames / (now - PERF.win)
    PERF.frameAvg = PERF.frames > 0 and (PERF.accum / PERF.frames) or 0
    PERF.lastFrameMax = PERF.frameMax
    PERF.frames, PERF.accum, PERF.frameMax, PERF.win = 0, 0, 0, now
    PERF.hist[#PERF.hist + 1] = math.floor(PERF.fps + 0.5)
    if #PERF.hist > CONFIG.PERF_HISTORY then table.remove(PERF.hist, 1) end
end
U.conn(S.RunService and (S.RunService.RenderStepped or S.RunService.Heartbeat), onFrame, "FPS")

local function readPing()
    PERF.ping, PERF.pingSrc = nil, ""
    pcall(function()
        local p = LP:GetNetworkPing()
        if type(p) == "number" then PERF.ping = p * 1000; PERF.pingSrc = "Player:GetNetworkPing()" end
    end)
    if PERF.ping then return end
    pcall(function()
        PERF.ping = S.Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        PERF.pingSrc = "Stats Data Ping"
    end)
end

local function checkPerfAlerts(now)
    if PERF.ping and PERF.ping > CONFIG.PING_ALERT_MS and now - PERF.lastPingAlert >= CONFIG.PERF_ALERT_COOLDOWN then
        PERF.lastPingAlert = now
        LOG.add("Sistema", STR.MSG.PING_HIGH, "", "", nil, string.format(STR.MSG.PING_HIGH_MSG, PERF.ping, CONFIG.PING_ALERT_MS), {alert = true, kind = "Ping"})
    end
    if PERF.fps > 0 and PERF.fps < CONFIG.FPS_ALERT and now - PERF.lastFpsAlert >= CONFIG.PERF_ALERT_COOLDOWN then
        PERF.lastFpsAlert = now
        LOG.add("Sistema", STR.MSG.FPS_LOW, "", "", nil, string.format(STR.MSG.FPS_LOW_MSG, PERF.fps, CONFIG.FPS_ALERT), {alert = true, kind = "FPS"})
    end
end

function PERF.sample()
    local now = os.clock()
    PERF.lastSample = now
    readPing()
    pcall(function() PERF.mem = S.Stats:GetTotalMemoryUsageMb() end)
    pcall(function() PERF.memScript = S.Stats:GetMemoryUsageMbForTag(Enum.DeveloperMemoryTag.Script) end)
    pcall(function() PERF.luaHeap = collectgarbage("count") / 1024 end)
    pcall(function() PERF.physFps = workspace:GetRealPhysicsFPS() end)
    pcall(function() PERF.recv = S.Stats.DataReceiveKbps end)
    pcall(function() PERF.send = S.Stats.DataSendKbps end)
    pcall(function() PERF.instCount = S.Stats.InstanceCount end)
    if now - PERF.logWinStart >= 1 then
        PERF.logRate = math.max(0, LOG.total - PERF.logWinTotal) / (now - PERF.logWinStart)
        PERF.logWinTotal, PERF.logWinStart = LOG.total, now
    end
    checkPerfAlerts(now)
end

function PERF.due(now)
    return now - PERF.lastSample >= (MODE.def.sampleEvery or 1)
end
