
-------------------------------------------------------------------------------
-- 10. PESTAÑAS
-------------------------------------------------------------------------------
local LIST_TOP = CONFIG.TOOLBAR_H + CONFIG.GAP

---------------- Controles compartidos (MAIN y LOGS): Modo y Jugadores
function UI.controlLabels()
    local modeTxt = MODE.def.label
    local left = MODE.captureLeft()
    if left then modeTxt = modeTxt .. " " .. left .. "s" end
    return {mode = string.format(STR.BTN_MODE, modeTxt), players = string.format(STR.BTN_PLAYERS, FEED.label())}
end

function UI.pickPlayer()
    local opts = {
        {title = STR.PLAYERS_ALL, sub = "", onPick = function() FEED.setFilter("all") end},
        {title = STR.PLAYERS_ME, sub = "", onPick = function() FEED.setFilter("me") end},
    }
    local ok, players = pcall(function() return S.Players:GetPlayers() end)
    for _, p in ipairs(ok and players or {}) do
        local uid = p.UserId
        opts[#opts + 1] = {title = U.esc(p.DisplayName ~= p.Name and (p.DisplayName .. " (@" .. p.Name .. ")") or p.Name),
            sub = string.format(STR.PICK_SUB, uid, p == LP and STR.PICK_YOU or ""), onPick = function() FEED.setFilter(uid) end}
    end
    UI.pick(STR.PICK_TITLE, opts)
end

local function addSharedControls(tb)
    local labels = UI.controlLabels()
    UI.addControl("mode", tb.button(labels.mode, function()
        MODE.cycle()
        if MODE.def.capture then UI.toast(string.format(STR.CAPTURE_START, CONFIG.CAPTURE_SECONDS)) end
        UI.refreshControls(UI.controlLabels())
        UI.force = true
    end, TH.warn, 150))
    UI.addControl("players", tb.button(labels.players, function()
        if FEED.cycle() == "pick" then UI.pickPlayer() end
        UI.refreshControls(UI.controlLabels())
        UI.force = true
    end, TH.ok, 150))
end

---------------- Inspector de objetos
local PROPS = {"Name", "ClassName", "Parent", "Archivable", "Enabled", "Disabled", "Visible", "Active", "Text", "Value",
    "Position", "Size", "Orientation", "Transparency", "Anchored", "CanCollide", "CanTouch", "Massless", "Material", "Color",
    "BrickColor", "Locked", "PrimaryPart", "Health", "MaxHealth", "WalkSpeed", "JumpPower", "JumpHeight", "ToolTip",
    "RequiresHandle", "CanBeDropped", "ManualActivationOnly", "Image", "AutoButtonColor", "Selectable", "ZIndex", "LayoutOrder",
    "AbsolutePosition", "AbsoluteSize", "SoundId", "Volume", "Playing", "Looped", "AnimationId", "MeshId", "TextureID", "Texture"}
local INSPECT_MAX_CHILDREN = 60

local function inspect(inst)
    local D = STR.DET
    local lines = {}
    local function add(s) lines[#lines + 1] = s end
    local okN, name = pcall(function() return inst.Name end)
    if not okN then return D.GONE end
    add(string.format(D.OBJECT, tostring(name)))
    add(string.format(D.PATH, U.path(inst)))
    local okA, alive = pcall(function() return inst:IsDescendantOf(game) end)
    add(string.format(D.ALIVE, tostring(okA and alive)))
    add("")
    add(D.PROPS)
    for _, p in ipairs(PROPS) do
        local ok, v = pcall(function() return inst[p] end)
        if ok and v ~= nil and p ~= "Name" then add(string.format("%-18s %s", p, U.ser(v))) end
    end
    local okAt, attrs = pcall(function() return inst:GetAttributes() end)
    if okAt and attrs and next(attrs) then
        add("")
        add(D.ATTRS)
        for k, v in pairs(attrs) do add(string.format("%-18s %s", tostring(k), U.ser(v))) end
    end
    if S.CollectionService then
        local okT, tags = pcall(function() return S.CollectionService:GetTags(inst) end)
        if okT and tags and #tags > 0 then add(""); add(string.format(D.TAGS, table.concat(tags, ", "))) end
    end
    local okC, kids = pcall(function() return inst:GetChildren() end)
    if okC and kids then
        add("")
        add(string.format(D.CHILDREN, #kids))
        for i, k in ipairs(kids) do
            if i > INSPECT_MAX_CHILDREN then add(string.format(D.MORE, #kids - INSPECT_MAX_CHILDREN)) break end
            local okk, s = pcall(function() return k.ClassName .. "  " .. k.Name end)
            add("  " .. (okk and s or "?"))
        end
    end
    add("")
    add(D.NOTE)
    return table.concat(lines, "\n")
end

local function openInspector(inst)
    local function show()
        local watching = WATCH.has(inst)
        UI.detail(string.format(STR.INSPECTOR, tostring(inst.Name)), inspect(inst), watching and STR.UNWATCH_BTN or STR.WATCH_BTN, function()
            local on = WATCH.toggle(inst)
            UI.toast(on and string.format(STR.WATCH_ON, CONFIG.MAX_WATCH) or STR.WATCH_OFF)
            show()
        end)
    end
    show()
end

---------------- Filtro de registros (categoría + búsqueda + modo + jugadores)
local logState = {q = "", cat = CFG.get("logCat", 1), box = nil, catBtn = nil}
if not CATS[logState.cat] then logState.cat = 1 end

local function logVisible(e, q, cat)
    if cat ~= "Todas" and e.cat ~= cat then return false end
    if not MODE.passes(e) or not FEED.passes(e) then return false end
    return U.match(q, e.name, e.args, e.extra, e.cat, e.types, e.player, e.remote, e.kind)
end

local function filteredLogs(limit)
    local q, cat = U.lower(logState.q), CATS[logState.cat]
    local out = {}
    LOG.iter(function(e)
        if logVisible(e, q, cat) then out[#out + 1] = e end
        return not limit or #out < limit
    end)
    return out
end

function UI.logSearch(text)
    logState.q = text
    if logState.box then logState.box.Text = text end
    UI.setTab("LOGS")
end

local function logRow(e)
    local hex = CAT_HEX[e.cat] or HEX.text
    local who = e.player and ("  " .. rich(HEX.warn, "@" .. tostring(e.player))) or ""
    local preview = e.args ~= "" and e.args or e.extra
    return {
        title = rich(HEX.dim, e.t) .. "  " .. rich(hex, e.cat) .. "  " .. U.esc(e.name) .. who .. (e.dir ~= "" and ("  " .. rich(HEX.dim, "· " .. e.dir)) or ""),
        sub = U.esc(U.trunc(U.oneLine(preview), CONFIG.PREVIEW_CHARS)),
        color = e.alert and TH.bad or hexColor(hex),
        onTap = function() UI.detail(e.cat .. " · " .. e.name, LOG.format(e)) end,
    }
end

---------------- Resumen y textos para copiar
function UI.summaryText()
    local t = {
        "GOY Diagnostics v" .. CONFIG.VERSION .. " · " .. U.fullDate(),
        "Juego PlaceId " .. tostring(game.PlaceId) .. " · jugador " .. LP.Name .. " (" .. tostring(LP.UserId) .. ")",
        "Ejecutor: " .. CAP.executor .. " · copiar: " .. (CAP.setclipboard and STR.YES or STR.NO) .. " · archivos: " .. (CAP.writefile and STR.YES or STR.NO),
        "Modo: " .. MODE.def.label .. " · Jugadores: " .. FEED.label(),
        "Objetos revisados: " .. REG.scanned .. (REG.scanDone and "" or STR.SCANNING),
    }
    local counts = {}
    for _, e in ipairs(REG.remotes) do counts[e.class] = (counts[e.class] or 0) + 1 end
    for _, c in ipairs({"RemoteEvent", "UnreliableRemoteEvent", "RemoteFunction", "BindableEvent", "BindableFunction"}) do
        t[#t + 1] = "  " .. c .. ": " .. (counts[c] or 0)
    end
    t[#t + 1] = "Herramientas: " .. #REG.tools .. " · Botones: " .. #REG.buttons
    t[#t + 1] = string.format("Registros: %d (guardados %d/%d, spam no guardado %d)", LOG.total, LOG.n, LOG.max, LOG.suppressed)
    t[#t + 1] = "Servidor instrumentado: " .. (FEED.remote and STR.YES or STR.NO) .. " · feed " .. FEED.received .. " · descartados por el servidor " .. FEED.droppedByServer
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

local function exportCapture()
    local cap = MODE.lastCapture
    if not cap then UI.toast(STR.CAPTURE_NONE) return end
    local base = "captura_" .. U.fileStamp()
    local ok, where = U.export(base .. ".txt", cap.text)
    local json = U.json(cap.data)
    if ok and json then U.export(base .. ".json", json) end
    UI.toast(ok and string.format(STR.SAVED, where) or string.format(STR.EXPORT_FAIL, tostring(where)))
end

local function showCapture()
    if not MODE.lastCapture then UI.toast(STR.CAPTURE_NONE) return end
    UI.detail(STR.CAPTURE_TITLE, MODE.lastCapture.text, STR.EXPORT, exportCapture)
end

---------------- MAIN
local function confirmTeleportReload(button)
    if CFG.get("reloadOnTeleport", false) then
        CFG.set("reloadOnTeleport", false)
        button.Text = string.format(STR.BTN_TELEPORT, STR.TELEPORT_OFF)
        UI.toast(STR.TELEPORT_DONE_OFF)
        return
    end
    UI.detail(STR.TELEPORT_TITLE, string.format(STR.TELEPORT_BODY, CONFIG.RELOAD_URL), STR.CONFIRM, function()
        CFG.set("reloadOnTeleport", true)
        CFG.set("reloadUrl", CONFIG.RELOAD_URL) -- si la URL de CONFIG cambia, hay que volver a confirmar
        button.Text = string.format(STR.BTN_TELEPORT, STR.TELEPORT_ON)
        detail.Visible = false
        UI.toast(STR.TELEPORT_DONE_ON)
    end)
end

local function teleportArmed()
    return CFG.get("reloadOnTeleport", false) and CFG.get("reloadUrl", "") == CONFIG.RELOAD_URL
end

do
    local page = UI.pages.MAIN
    local tb = UI.toolbar(page)
    addSharedControls(tb)
    tb.button(STR.BTN_SUMMARY, function() UI.copyOrShow(STR.SUMMARY_TITLE, UI.summaryText()) end, TH.cyan, 120)
    tb.button(STR.BTN_LIMITS, function() UI.detail(STR.LIMITS_TITLE, STR.LIMITS) end, nil, 104)
    tb.button(STR.BTN_STUDIO, function() UI.detail(STR.STUDIO_TITLE, STUDIO_SCRIPT) end, TH.violet, 108)
    tb.button(UI.scaleLabel(), function(b) b.Text = UI.scaleLabel(UI.cycleScale()) end, nil, 104)
    if CAP.queue_on_teleport then
        tb.button(string.format(STR.BTN_TELEPORT, teleportArmed() and STR.TELEPORT_ON or STR.TELEPORT_OFF), confirmTeleportReload, TH.violet, 140)
    end
    tb.button(STR.BTN_OFF, function() G.destroy() end, TH.bad, 76)
    UI.lists.MAIN = UI.list(page, LIST_TOP)
end

local function renderMain()
    local items = {}
    local function row(title, sub, color, tap) items[#items + 1] = {title = title, sub = sub, color = color, onTap = tap} end
    local counts, active = {}, 0
    for _, e in ipairs(REG.remotes) do
        counts[e.class] = (counts[e.class] or 0) + 1
        if e.count > 0 then active = active + 1 end
    end
    local yn = function(b) return b and STR.YES or STR.NO end
    row(rich(HEX.ok, STR.MAIN_ACTIVE) .. "  " .. rich(HEX.dim, LOG.paused and STR.MAIN_PAUSED or ""),
        U.esc(string.format(STR.MAIN_EXEC, CAP.executor, yn(CAP.setclipboard), yn(CAP.writefile), yn(CAP.touch))), TH.ok)
    row(rich(HEX.warn, string.format(STR.MAIN_MODE, MODE.def.label, FEED.label())), STR.MAIN_MODE_SUB, TH.warn)
    row(rich(FEED.remote and HEX.ok or HEX.dim, string.format(STR.MAIN_FEED, FEED.remote and STR.MAIN_FEED_YES or STR.MAIN_FEED_NONE)),
        string.format(STR.MAIN_FEED_SUB, FEED.label(), FEED.serverMode and FEED.label(FEED.serverMode) or "—", FEED.received, FEED.droppedByServer), TH.ok)
    if MODE.capture or MODE.lastCapture then
        local status = MODE.capture and string.format(STR.CAPTURE_LEFT, MODE.captureLeft()) or
            string.format(STR.CAPTURE_DONE, MODE.lastCapture.data.total, MODE.lastCapture.data.dur)
        row(rich(HEX.violet, string.format(STR.MAIN_CAPTURE, status)), STR.MAIN_CAPTURE_SUB, TH.violet, showCapture)
    end
    row(rich(HEX.cyan, string.format(STR.MAIN_COMM, #REG.remotes)),
        string.format(STR.MAIN_COMM_SUB, counts.RemoteEvent or 0, counts.UnreliableRemoteEvent or 0, counts.RemoteFunction or 0,
            counts.BindableEvent or 0, counts.BindableFunction or 0, active), TH.cyan, function() UI.setTab("REMOTES") end)
    row(rich(HEX.warn, string.format(STR.MAIN_TOOLS, #REG.tools)) .. "   " .. rich(HEX.violet, string.format(STR.MAIN_BUTTONS, #REG.buttons)),
        string.format(STR.MAIN_INST, REG.instAdded, REG.instRemoved, REG.scanned, REG.scanDone and "" or STR.SCANNING), TH.warn, function() UI.setTab("TOOLS") end)
    row(rich(HEX.text, string.format(STR.MAIN_LOGS, LOG.total)),
        string.format(STR.MAIN_LOGS_SUB, LOG.n, LOG.max, PERF.logRate, LOG.suppressed, LOG.droppedPaused), TH.violet, function() UI.setTab("LOGS") end)
    row(rich(HEX.ok, string.format(STR.MAIN_PERF, PERF.fps)) .. "  " .. rich(HEX.cyan, PERF.ping and string.format(STR.MAIN_PING, PERF.ping) or STR.MAIN_PING_NA) ..
        "  " .. rich(HEX.violet, PERF.mem and string.format(STR.MAIN_MEM, PERF.mem) or STR.MAIN_MEM_NA),
        string.format(STR.MAIN_PERF_SUB, CONSOLE.errors, CONSOLE.warnings, G.internalErrors), TH.ok, function() UI.setTab("PERFORMANCE") end)
    for _, e in ipairs(filteredLogs(CONFIG.MAIN_RECENT)) do items[#items + 1] = logRow(e) end
    row(rich(HEX.dim, STR.MAIN_INFO), STR.MAIN_INFO_SUB, TH.line, function() UI.detail(STR.LIMITS_TITLE, STR.LIMITS) end)
    UI.lists.MAIN.set(items)
end

---------------- REMOTES
local CLS_FILTERS, CLS_SHORT, SORTS = STR.CLS_FILTERS, STR.CLS_SHORT, STR.SORTS
local remoteState = {q = "", cls = CFG.get("remoteCls", 1), sort = CFG.get("remoteSort", 1)}
if not CLS_FILTERS[remoteState.cls] then remoteState.cls = 1 end
if not SORTS[remoteState.sort] then remoteState.sort = 1 end

local REMOTE_SORT = {
    Actividad = function(a, b) if a.count ~= b.count then return a.count > b.count end return a.name < b.name end,
    Nombre = function(a, b) return U.lower(a.name) < U.lower(b.name) end,
    Ruta = function(a, b) return a.path < b.path end,
}

local function filteredRemotes()
    local q, f = U.lower(remoteState.q), CLS_FILTERS[remoteState.cls]
    local out = {}
    for _, e in ipairs(REG.remotes) do
        local okc = (f == "Todas") or (f == "Con actividad" and e.count > 0) or (e.class == f)
        if okc and U.match(q, e.name, e.path, e.class, e.loc) then out[#out + 1] = e end
    end
    table.sort(out, REMOTE_SORT[SORTS[remoteState.sort]])
    return out
end

local function remoteText(e)
    local D = STR.DET
    return table.concat({
        string.format(D.R_NAME, e.name), string.format(D.R_CLASS, e.class), string.format(D.R_PATH, U.path(e.inst)),
        string.format(D.R_LOC, e.loc), string.format(D.R_DIR, e.dir), string.format(D.R_SEEN, e.addedAt),
        string.format(D.R_COUNT, e.count, e.last and string.format(D.R_LAST, e.last) or ""),
        "", string.format(D.R_ARGS, e.lastTypes ~= "" and e.lastTypes or "—"), e.lastArgs ~= "" and e.lastArgs or D.R_NOARGS,
        "", e.observable and STR.REMOTE_OBS or STR.REMOTE_NOOBS, STR.REMOTE_NOSEND,
    }, "\n")
end

do
    local page = UI.pages.REMOTES
    local tb = UI.toolbar(page)
    local box = tb.search(STR.REMOTE_SEARCH, 150)
    U.conn(box:GetPropertyChangedSignal("Text"), function() remoteState.q = box.Text; UI.force = true end, "buscar remotos")
    tb.button(CLS_SHORT[CLS_FILTERS[remoteState.cls]], function(b)
        remoteState.cls = remoteState.cls % #CLS_FILTERS + 1
        b.Text = CLS_SHORT[CLS_FILTERS[remoteState.cls]]
        CFG.set("remoteCls", remoteState.cls)
        UI.force = true
    end, TH.cyan, 116)
    tb.button(string.format(STR.SORT_BTN, SORTS[remoteState.sort]), function(b)
        remoteState.sort = remoteState.sort % #SORTS + 1
        b.Text = string.format(STR.SORT_BTN, SORTS[remoteState.sort])
        CFG.set("remoteSort", remoteState.sort)
        UI.force = true
    end, nil, 124)
    tb.button(STR.COPY, function()
        local t = {string.format(STR.REMOTES_COPY_HEAD, U.fullDate())}
        for _, e in ipairs(filteredRemotes()) do t[#t + 1] = string.format("%-22s ×%-5d %-24s %s", e.class, e.count, e.loc, e.path) end
        UI.copyOrShow(STR.REMOTES_TITLE, table.concat(t, "\n"))
    end, TH.ok, 72)
    UI.lists.REMOTES = UI.list(page, LIST_TOP)
end

local function renderRemotes()
    local list = filteredRemotes()
    if #list == 0 then
        UI.lists.REMOTES.set({{title = rich(HEX.dim, REG.scanDone and STR.NO_RESULTS or STR.SCANNING_T), sub = STR.NO_RESULTS_SUB}})
        return
    end
    UI.lists.REMOTES.setLazy(#list, function(i)
        local e = list[i]
        local hex = CLASS_HEX[e.class] or HEX.text
        local cnt = e.observable and rich(e.count > 0 and HEX.warn or HEX.dim, "  ×" .. e.count) or rich(HEX.dim, STR.REMOTE_NOT_OBS)
        return {
            title = rich(hex, e.name) .. cnt,
            sub = U.esc(string.format(STR.REMOTE_ROW_SUB, e.class, e.loc, e.last and (" · " .. e.last) or "", e.path)),
            color = hexColor(hex),
            onTap = function() UI.detail(e.class .. " · " .. e.name, remoteText(e), STR.REMOTE_SEE_LOGS, function() UI.logSearch(e.name) end) end,
        }
    end)
end

---------------- TOOLS
local TOOL_MODES = STR.TOOL_MODES
local toolState = {mode = 1, q = "", results = {}, searching = false, modeBtn = nil}

local function runSearch(q)
    if toolState.searching then return end
    q = U.lower(q)
    if #q < 2 then UI.toast(STR.MIN_CHARS) return end
    toolState.searching, toolState.results = true, {}
    UI.force = true
    task.spawn(function()
        local n = 0
        for _, c in ipairs(REG.containers) do
            local ok, list = pcall(function() return c.inst:GetDescendants() end)
            if ok then
                for _, inst in ipairs(list) do
                    if not G.alive or #toolState.results >= CONFIG.MAX_SEARCH then break end
                    local okn, nm = pcall(function() return inst.Name end)
                    if okn and U.lower(nm):find(q, 1, true) and not REG.isOwnGui(inst) then
                        toolState.results[#toolState.results + 1] = {inst = inst, loc = c.name}
                    end
                    n = n + 1
                    if n % CONFIG.SEARCH_YIELD_EVERY == 0 then task.wait() end
                end
            end
        end
        toolState.searching = false
        UI.force = true
        UI.toast(string.format(STR.FOUND, #toolState.results, #toolState.results >= CONFIG.MAX_SEARCH and string.format(STR.FOUND_LIMIT, CONFIG.MAX_SEARCH) or ""))
    end)
end

local function setToolMode(i)
    toolState.mode = i
    if toolState.modeBtn then toolState.modeBtn.Text = TOOL_MODES[i] end
    UI.force = true
end

do
    local page = UI.pages.TOOLS
    local tb = UI.toolbar(page)
    toolState.modeBtn = tb.button(TOOL_MODES[1], function() setToolMode(toolState.mode % #TOOL_MODES + 1) end, TH.warn, 116)
    local box = tb.search(STR.TOOL_FILTER, 140)
    U.conn(box:GetPropertyChangedSignal("Text"), function() toolState.q = box.Text; UI.force = true end, "filtrar tools")
    U.conn(box.FocusLost, function(enter) if enter and toolState.mode == 3 then runSearch(box.Text) end end, "buscar enter")
    tb.button(STR.SEARCH, function()
        if toolState.mode ~= 3 then setToolMode(3) end
        runSearch(box.Text)
    end, TH.cyan, 72)
    tb.button(STR.COPY, function()
        local t = {string.format(STR.DET.TOOLS_HEAD, TOOL_MODES[toolState.mode])}
        for _, it in ipairs(UI.lists.TOOLS.all()) do
            t[#t + 1] = ((it.title or ""):gsub("<[^>]->", "")) .. " · " .. ((it.sub or ""):gsub("<[^>]->", ""))
        end
        UI.copyOrShow(TOOL_MODES[toolState.mode], table.concat(t, "\n"))
    end, TH.ok, 72)
    UI.lists.TOOLS = UI.list(page, LIST_TOP)
end

local TOOL_RENDER = {}
TOOL_RENDER[1] = function(items, q)
    for _, e in ipairs(REG.tools) do
        if U.match(q, e.name, e.owner, e.path) then
            local stHex = (e.state == STR.TOOL_STATE_EQUIPPED) and HEX.ok or HEX.warn
            items[#items + 1] = {title = rich(HEX.warn, e.name) .. "  " .. rich(stHex, tostring(e.state)),
                sub = U.esc(string.format(STR.DET.TOOL_SUB, e.class, tostring(e.owner), e.equips, e.path)),
                color = TH.warn, onTap = function() openInspector(e.inst) end}
        end
    end
    if #items == 0 then items[1] = {title = rich(HEX.dim, STR.NO_TOOLS), sub = STR.NO_TOOLS_SUB} end
end
TOOL_RENDER[2] = function(items)
    for _, c in ipairs(REG.containers) do
        items[#items + 1] = {title = rich(HEX.cyan, c.name) .. "  " .. rich(HEX.text, string.format(STR.CONT_ROW, c.count)),
            sub = string.format(STR.CONT_SUB, c.added, c.removed), color = TH.cyan, onTap = function() openInspector(c.inst) end}
    end
    items[#items + 1] = {title = rich(HEX.dim, STR.SERVER_ONLY), sub = STR.SERVER_ONLY_SUB, color = TH.line}
    items[#items + 1] = {title = rich(REG.logWorkspaceInstances and HEX.ok or HEX.dim, string.format(STR.WS_LOG, REG.logWorkspaceInstances and STR.DET.YES_UP or STR.DET.NO_UP)),
        sub = STR.WS_LOG_SUB, color = TH.violet, onTap = function() REG.logWorkspaceInstances = not REG.logWorkspaceInstances; UI.force = true end}
end
TOOL_RENDER[3] = function(items)
    if toolState.searching then items[1] = {title = rich(HEX.cyan, STR.SEARCHING), sub = STR.SEARCHING_SUB} end
    for _, r in ipairs(toolState.results) do
        local ok, cls, nm = pcall(function() return r.inst.ClassName, r.inst.Name end)
        if ok then
            items[#items + 1] = {title = rich(HEX.text, nm) .. "  " .. rich(HEX.dim, cls), sub = U.esc(r.loc .. " · " .. U.path(r.inst)),
                color = TH.violet, onTap = function() openInspector(r.inst) end}
        end
    end
    if #items == 0 then items[1] = {title = rich(HEX.dim, STR.SEARCH_HINT), sub = string.format(STR.SEARCH_HINT_SUB, CONFIG.MAX_SEARCH)} end
end
TOOL_RENDER[4] = function(items)
    for _, w in ipairs(WATCH.list) do
        items[#items + 1] = {title = rich(HEX.pink, w.name), sub = U.esc(U.path(w.inst)), color = TH.violet, onTap = function() openInspector(w.inst) end}
    end
    if #items == 0 then items[1] = {title = rich(HEX.dim, STR.NO_WATCH), sub = STR.NO_WATCH_SUB} end
end

local function renderTools()
    local items = {}
    TOOL_RENDER[toolState.mode](items, U.lower(toolState.q))
    UI.lists.TOOLS.set(items)
end

---------------- BUTTONS
local BTN_FILTERS = STR.BTN_FILTERS
local btnState = {q = "", f = 1}
local MAX_GUI_DEPTH = 40

local function effVisible(inst)
    local ok, r = pcall(function()
        local p, depth = inst, 0
        while p and depth < MAX_GUI_DEPTH do
            if p:IsA("PlayerGui") then return true end
            if p:IsA("GuiObject") and not p.Visible then return false end
            if p:IsA("LayerCollector") and not p.Enabled then return false end
            p, depth = p.Parent, depth + 1
        end
        return p ~= nil
    end)
    return ok and r
end

local function buttonText(e)
    local D, inst = STR.DET, e.inst
    local function g(p) local ok, v = pcall(function() return inst[p] end) return ok and v or nil end
    return table.concat({
        string.format(D.B_NAME, e.name), string.format(D.B_CLASS, e.class), string.format(D.B_PATH, U.path(inst)),
        string.format(D.B_TEXT, tostring(g("Text") or D.B_NOTEXT)),
        string.format(D.B_VIS, tostring(g("Visible")), tostring(effVisible(inst))),
        string.format(D.B_ACTIVE, tostring(g("Active")), tostring(g("Interactable"))),
        string.format(D.B_IMAGE, tostring(g("Image") or "—")),
        string.format(D.B_CLICKS, e.clicks, e.lastClick and string.format(D.R_LAST, e.lastClick) or ""),
        "", D.B_NOTE,
    }, "\n")
end

do
    local page = UI.pages.BUTTONS
    local tb = UI.toolbar(page)
    local box = tb.search(STR.BTN_SEARCH, 150)
    U.conn(box:GetPropertyChangedSignal("Text"), function() btnState.q = box.Text; UI.force = true end, "buscar botones")
    tb.button(BTN_FILTERS[1], function(b)
        btnState.f = btnState.f % #BTN_FILTERS + 1
        b.Text = BTN_FILTERS[btnState.f]
        UI.force = true
    end, TH.violet, 90)
    tb.button(STR.COPY, function()
        local t = {STR.DET.BUTTONS_HEAD}
        for _, e in ipairs(REG.buttons) do
            local okt, tx = pcall(function() return e.inst.Text end)
            t[#t + 1] = string.format("%-12s %-5s ×%-4d %s  \"%s\"", e.class, effVisible(e.inst) and STR.DET.VIS_SHORT or STR.DET.HID_SHORT, e.clicks, U.path(e.inst), okt and U.trunc(tx or "", 40) or "")
        end
        UI.copyOrShow(STR.DET.BUTTONS_TITLE, table.concat(t, "\n"))
    end, TH.ok, 72)
    UI.lists.BUTTONS = UI.list(page, LIST_TOP)
end

local function renderButtons()
    local q, f = U.lower(btnState.q), BTN_FILTERS[btnState.f]
    local list = {}
    for _, e in ipairs(REG.buttons) do
        local okt, tx = pcall(function() return e.inst.Text end)
        tx = okt and tx or ""
        if U.match(q, e.name, tx, e.path) then
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
    if #list == 0 then
        UI.lists.BUTTONS.set({{title = rich(HEX.dim, STR.NO_BUTTONS), sub = STR.NO_BUTTONS_SUB}})
        return
    end
    UI.lists.BUTTONS.setLazy(#list, function(i)
        local it, e = list[i], list[i].e
        return {
            title = rich(it.vis and HEX.violet or HEX.dim, (it.tx ~= "" and U.trunc(it.tx, 40) or e.name)) ..
                (it.tx ~= "" and ("  " .. rich(HEX.dim, e.name)) or "") .. (e.clicks > 0 and rich(HEX.warn, "  ×" .. e.clicks) or ""),
            sub = U.esc(e.class .. " · " .. (it.vis and STR.VISIBLE or STR.HIDDEN) .. " · " .. e.path),
            color = it.vis and TH.violet or TH.line,
            onTap = function() UI.detail(e.class .. " · " .. e.name, buttonText(e), STR.INSPECT, function() openInspector(e.inst) end) end,
        }
    end)
end

---------------- LOGS
local function logsAsText(list)
    local t = {string.format(STR.LOGS_COPY_HEAD, U.fullDate(), MODE.def.label, FEED.label())}
    for i = #list, 1, -1 do t[#t + 1] = LOG.format(list[i]) end
    return table.concat(t, "\n")
end

local function exportLogs()
    local list = filteredLogs()
    local base = "logs_" .. U.fileStamp()
    local ok, where = U.export(base .. ".txt", "PlaceId " .. tostring(game.PlaceId) .. "\n" .. logsAsText(list))
    local records = {}
    for i = #list, 1, -1 do records[#records + 1] = LOG.toRecord(list[i]) end
    local json = U.json({version = CONFIG.VERSION, placeId = game.PlaceId, mode = MODE.def.id, players = FEED.filter, logs = records})
    if ok and json then U.export(base .. ".json", json) end
    UI.toast(ok and string.format(STR.SAVED, where) or string.format(STR.EXPORT_FAIL, tostring(where)))
end

local function setPaused(paused, b)
    LOG.paused = paused
    b.Text = paused and STR.RESUME or STR.PAUSE
    b.TextColor3 = paused and TH.warn or TH.text
    statusDot.BackgroundColor3 = paused and TH.warn or TH.ok
    fabDot.BackgroundColor3 = paused and TH.warn or TH.ok
    UI.force = true
end

do
    local page = UI.pages.LOGS
    local tb = UI.toolbar(page)
    local box = tb.search(STR.LOG_SEARCH, 140)
    logState.box = box
    U.conn(box:GetPropertyChangedSignal("Text"), function() logState.q = box.Text; UI.force = true end, "buscar logs")
    addSharedControls(tb)
    logState.catBtn = tb.button(string.format(STR.CAT_BTN, CATS[logState.cat]), function(b)
        logState.cat = logState.cat % #CATS + 1
        b.Text = string.format(STR.CAT_BTN, CATS[logState.cat])
        CFG.set("logCat", logState.cat)
        UI.force = true
    end, TH.cyan, 132)
    tb.button(STR.PAUSE, function(b) setPaused(not LOG.paused, b) end, nil, 84)
    tb.button(STR.CLEAR, function() LOG.clear(); UI.force = true; UI.toast(STR.CLEARED) end, TH.bad, 76)
    tb.button(STR.COPY, function() UI.copyOrShow(STR.LOGS_TITLE, logsAsText(filteredLogs())) end, TH.ok, 72)
    tb.button(STR.EXPORT, exportLogs, TH.violet, 84)
    UI.lists.LOGS = UI.list(page, LIST_TOP)
end

local function renderLogs()
    local list = filteredLogs()
    if #list == 0 then
        local filtered = MODE.def.id ~= "normal" or FEED.filter ~= "all"
        UI.lists.LOGS.set({{title = rich(HEX.dim, LOG.paused and STR.LOGS_PAUSED or STR.NO_LOGS),
            sub = filtered and string.format(STR.MODE_EMPTY_SUB, MODE.def.label, FEED.label()) or STR.NO_LOGS_SUB}})
        return
    end
    UI.lists.LOGS.setLazy(#list, function(i) return logRow(list[i]) end)
end

---------------- PERFORMANCE
local BARS = {"▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"}
local function spark(hist)
    local maxv = 1
    for _, v in ipairs(hist) do if v > maxv then maxv = v end end
    local t = {}
    for _, v in ipairs(hist) do t[#t + 1] = BARS[math.clamp(math.floor(v / maxv * (#BARS - 1)) + 1, 1, #BARS)] end
    return table.concat(t)
end
local function fmt(v, f, unit) if v == nil then return STR.NA end return string.format(f, v) .. (unit or "") end

function UI.errorsText()
    if #G.errors == 0 then return STR.NO_INTERNAL end
    local t = {}
    for i, e in ipairs(G.errors) do
        t[#t + 1] = string.format(STR.PERF.ERR_ROW, i, e.where, os.clock() - e.t)
        t[#t + 1] = e.msg
        t[#t + 1] = ""
    end
    return table.concat(t, "\n")
end

do
    local limiter = {}
    G.onInternalError = function(where, err)
        if RATE.ok(limiter, STR.MSG.INTERNAL_RATE) then
            LOG.add("Sistema", STR.MSG.INTERNAL, "", "", nil, tostring(where) .. ": " .. U.trunc(tostring(err):match("^[^\n]*") or "", 200), {alert = true})
        end
    end
end

function UI.perfText()
    local P = STR.PERF
    return table.concat({
        string.format(P.T_HEAD, U.fullDate()),
        string.format(P.T_FPS, fmt(PERF.fps, "%.1f"), fmt(PERF.frameAvg * 1000, "%.1f", " ms"), fmt(PERF.lastFrameMax * 1000, "%.1f", " ms")),
        string.format(P.T_PHYS, fmt(PERF.physFps, "%.1f", " FPS")),
        string.format(P.T_PING, fmt(PERF.ping, "%.0f", " ms"), PERF.pingSrc ~= "" and (" (" .. PERF.pingSrc .. ")") or ""),
        string.format(P.T_NET, fmt(PERF.recv, "%.1f", " KB/s"), fmt(PERF.send, "%.1f", " KB/s")),
        string.format(P.T_MEM, fmt(PERF.mem, "%.0f", " MB"), fmt(PERF.memScript, "%.0f", " MB"), fmt(PERF.luaHeap, "%.1f", " MB")),
        string.format(P.T_INST, fmt(PERF.instCount, "%.0f")),
        string.format(P.T_SERVER, FEED.stats or P.SERVER_NONE),
        string.format(P.T_CONSOLE, CONSOLE.errors, CONSOLE.warnings),
        string.format(P.T_MONITOR, #G.conns, PERF.renderMs, PERF.renderRate, MODE.def.label),
        string.format(P.T_LOGS, LOG.total, PERF.logRate, G.internalErrors),
    }, "\n")
end

do
    local page = UI.pages.PERFORMANCE
    local tb = UI.toolbar(page)
    tb.button(STR.BTN_PERF_COPY, function() UI.copyOrShow(STR.PERF_TITLE, UI.perfText()) end, TH.cyan, 124)
    tb.button(STR.BTN_PERF_NOTES, function() UI.detail(STR.NOTES_TITLE, STR.PERF_NOTES) end, TH.violet, 150)
    UI.lists.PERFORMANCE = UI.list(page, LIST_TOP)
end

local function renderPerf()
    local P = STR.PERF
    local items = {}
    local function row(t, s, c, tap) items[#items + 1] = {title = t, sub = s, color = c, onTap = tap} end
    local fpsHex = PERF.fps >= 50 and HEX.ok or (PERF.fps >= 30 and HEX.warn or HEX.bad)
    local graph = MODE.def.graph and (spark(PERF.hist) .. string.format(P.GRAPH, CONFIG.PERF_HISTORY)) or P.NO_GRAPH
    row(rich(fpsHex, string.format(P.FPS, PERF.fps)) .. "  " .. rich(HEX.dim, string.format(P.FRAME, fmt(PERF.frameAvg * 1000, "%.1f", " ms"), fmt(PERF.lastFrameMax * 1000, "%.0f", " ms"))),
        graph, hexColor(fpsHex, TH.ok))
    local pingHex = (PERF.ping and PERF.ping > CONFIG.PING_ALERT_MS) and HEX.bad or HEX.cyan
    row(rich(pingHex, string.format(P.PING, fmt(PERF.ping, "%.0f", " ms"))), U.esc(PERF.pingSrc ~= "" and string.format(P.PING_SRC, PERF.pingSrc) or P.PING_NA), TH.cyan)
    row(rich(HEX.violet, string.format(P.MEM, fmt(PERF.mem, "%.0f", " MB"))), string.format(P.MEM_SUB, fmt(PERF.memScript, "%.0f", " MB"), fmt(PERF.luaHeap, "%.1f", " MB")), TH.violet)
    row(rich(HEX.blue, string.format(P.NET, fmt(PERF.recv, "%.1f", " KB/s"), fmt(PERF.send, "%.1f", " KB/s"))),
        string.format(P.NET_SUB, fmt(PERF.physFps, "%.0f", " FPS"), fmt(PERF.instCount, "%.0f")), TH.line)
    row(rich(FEED.stats and HEX.ok or HEX.dim, P.SERVER), U.esc(FEED.stats or P.SERVER_NONE), TH.ok)
    row(rich(CONSOLE.errors > 0 and HEX.bad or HEX.ok, string.format(P.ERR, CONSOLE.errors)) .. "  " .. rich(HEX.warn, string.format(P.WARN, CONSOLE.warnings)),
        P.CONSOLE_SUB, TH.bad, function()
            for i, c in ipairs(CATS) do if c == "Consola" then logState.cat = i end end
            if logState.catBtn then logState.catBtn.Text = string.format(STR.CAT_BTN, "Consola") end
            UI.logSearch("")
        end)
    row(rich(HEX.text, string.format(P.OBJECTS, #REG.remotes, #REG.tools, #REG.buttons)),
        string.format(P.OBJECTS_SUB, LOG.total, PERF.logRate, LOG.suppressed), TH.line)
    row(rich(HEX.dim, string.format(P.MONITOR, #G.conns, REG.pending(), math.floor(REG.qMax))),
        string.format(P.MONITOR_SUB, PERF.renderMs, PERF.renderRate, REG.qProcessed, CONFIG.QUEUE_BUDGET_MS, MODE.def.label), TH.line)
    row(rich(G.internalErrors > 0 and HEX.bad or HEX.ok, string.format(P.INTERNAL, G.internalErrors)),
        G.internalErrors > 0 and U.esc(U.trunc(U.oneLine(G.lastInternalError), 150)) or P.INTERNAL_NONE, TH.line,
        function() UI.detail(string.format(STR.ERRORS_TITLE, CONFIG.MAX_ERRORS), UI.errorsText()) end)
    row(rich(HEX.dim, P.INFO), P.INFO_SUB, TH.line, function() UI.detail(STR.NOTES_TITLE, STR.PERF_NOTES) end)
    UI.lists.PERFORMANCE.set(items)
end
