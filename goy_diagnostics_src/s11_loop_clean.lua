
-------------------------------------------------------------------------------
-- 11. BUCLE (un solo bucle de refresco) + ARRANQUE
-------------------------------------------------------------------------------
local RENDER = {MAIN = renderMain, REMOTES = renderRemotes, TOOLS = renderTools, BUTTONS = renderButtons, LOGS = renderLogs, PERFORMANCE = renderPerf}
local LOOP = {lastSig = {}, lastTime = {}, renders = 0}

local function signature(tab)
    local common = MODE.version .. ":" .. (FEED.version or 0)
    if tab == "REMOTES" then return REG.remoteVersion .. ":" .. common
    elseif tab == "TOOLS" then return REG.toolVersion .. ":" .. #toolState.results .. ":" .. #WATCH.list .. ":" .. common
    elseif tab == "BUTTONS" then return REG.buttonVersion .. ":" .. common
    elseif tab == "LOGS" then return LOG.version .. ":" .. common end
    return nil -- MAIN y PERFORMANCE se refrescan por tiempo
end

-- ¿Hay que redibujar la pestaña?
local function needsRender(tab, now)
    if UI.force then return true end
    local age = now - (LOOP.lastTime[tab] or 0)
    local period = (CONFIG.REFRESH[tab] or 1.5) * (MODE.def.tickMul or 1)
    local sig = signature(tab)
    if sig == nil then return age >= period end
    if sig ~= LOOP.lastSig[tab] then return age >= CONFIG.REFRESH_ON_CHANGE * (MODE.def.tickMul or 1) end
    return age >= period * CONFIG.REFRESH_SAFETY_MUL
end

-- ¿Hay que medir? Donde se muestra, o siempre si el modo vigila alertas.
local function needsSample(now)
    if not PERF.due(now) then return false end
    if MODE.def.alertsOnly or MODE.def.silent then return true end
    return UI.open and (UI.tab == "MAIN" or UI.tab == "PERFORMANCE")
end

local function updateFooter()
    local left = MODE.captureLeft()
    local modeTxt = MODE.def.label .. (left and (" " .. string.format(STR.CAPTURE_LEFT, left)) or "")
    footer.Text = string.format(STR.FOOTER, LOG.paused and HEX.warn or HEX.ok, LOG.paused and STR.PAUSED or STR.LIVE,
        modeTxt, FEED.label(), #REG.remotes, LOG.total, LOG.suppressed > 0 and string.format(STR.SPAM_SUFFIX, LOG.suppressed) or "", PERF.fps)
end

local function renderTab(tab, now)
    UI.force = false
    local t0 = os.clock()
    U.try("render " .. tab, RENDER[tab])
    PERF.renderMs = (os.clock() - t0) * 1000
    PERF.renderWinCount = PERF.renderWinCount + 1
    LOOP.renders = LOOP.renders + 1
    LOOP.lastSig[tab], LOOP.lastTime[tab] = signature(tab), now
end

local function tick()
    local now = os.clock()
    RATE.flush()                 -- avisos de spam aunque el spam haya parado
    MODE.tickCapture()
    CFG.flush(false)
    if MODE.captureFinished then
        MODE.captureFinished = false
        if UI.open then UI.toast(string.format(STR.CAPTURE_DONE, MODE.lastCapture.data.total, MODE.lastCapture.data.dur)) end
        UI.force = true
    end
    if now - PERF.renderWin >= 2 then
        PERF.renderRate = PERF.renderWinCount / (now - PERF.renderWin)
        PERF.renderWin, PERF.renderWinCount = now, 0
    end
    if needsSample(now) then PERF.sample() end
    local drawing = MODE.drawAllowed()
    fabDot.BackgroundColor3 = (MODE.def.silent and MODE.alertPending) and TH.bad or (LOG.paused and TH.warn or TH.ok)
    if not drawing then return end  -- Silencioso: no se dibuja nada hasta una alerta
    UI.refreshControls(UI.controlLabels())
    if not UI.open or UI.collapsed then return end
    updateFooter()
    local tab = UI.tab
    if needsRender(tab, now) then renderTab(tab, now) end
end

---------------- Arranque
local function onCharacter(char)
    if not char then return end
    LOG.add("Cambio", STR.MSG.CHAR, STR.DIR.REPLICATED, "", nil, string.format(STR.MSG.CHAR_SPAWN, U.path(char)))
    REG.watchAttributes(char, STR.MSG.ATTR_CHAR)
    task.spawn(function()
        local hum = char:WaitForChild("Humanoid", 10)
        if hum and G.alive then
            U.conn(hum.Died, function() LOG.add("Cambio", STR.MSG.CHAR, STR.DIR.REPLICATED, "", nil, STR.MSG.CHAR_DIED) end, "murió")
        end
    end)
end

-- Recarga tras teletransporte: solo si se confirmó ESTA URL (ver MAIN).
if CAP.queue_on_teleport then
    U.conn(LP.OnTeleport, function(state)
        if teleportArmed() and tostring(state):find("Started") then
            CFG.flush(true)
            pcall(CAP.queue_on_teleport, 'loadstring(game:HttpGet("' .. CONFIG.RELOAD_URL .. '"))()')
        end
    end, "teleport")
end

REG.watchAttributes(LP, STR.MSG.ATTR_PLAYER)
onCharacter(LP.Character)
U.conn(LP.CharacterAdded, onCharacter, "personaje")
G.UI, G.REG, G.LOG, G.PERF, G.CAP, G.FEED, G.MODE, G.CFG, G.CONFIG, G.STR = UI, REG, LOG, PERF, CAP, FEED, MODE, CFG, CONFIG, STR
UI.setTab(UI.pages[CFG.get("tab", "MAIN")] and CFG.get("tab", "MAIN") or "MAIN")
LOG.add("Sistema", "GOY Diagnostics", "", "", nil, string.format(STR.MSG.START, CONFIG.VERSION, CAP.executor))
task.spawn(REG.initialScan)
task.spawn(function()
    while G.alive do
        task.wait(CONFIG.TICK)
        if G.alive then U.try("bucle", tick) end
    end
end)

-------------------------------------------------------------------------------
-- 12. LIMPIEZA
-------------------------------------------------------------------------------
function G.destroy()
    if not G.alive then return end
    G.alive = false
    for _, c in ipairs(G.conns) do pcall(function() c:Disconnect() end) end
    G.conns = {}
    CFG.flush(true)
    pcall(function() screen:Destroy() end)
    if ENV.GOY_DIAG == G then ENV.GOY_DIAG = nil end
end
U.conn(screen.AncestryChanged, function() if not screen.Parent then G.destroy() end end, "GUI eliminada")
