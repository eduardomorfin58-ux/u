
-------------------------------------------------------------------------------
-- 10. PESTAÑAS — lateral, tarjetas, páginas, detalle y barra de estado
-------------------------------------------------------------------------------
local PAGE_Y = L.SEARCH_Y
local PAGE_H = L.CHART_Y + L.CHART_H - L.SEARCH_Y
local CHIPS_Y = L.CHIPS_Y - PAGE_Y
local TABLE_Y = L.TABLE_Y - PAGE_Y
local fmtInt = function(n)
    local s = tostring(math.floor(n or 0))
    local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    return (out:gsub("^,", ""))
end
local function fmt(v, f, unit) if v == nil then return STR.NA end return string.format(f, v) .. (unit or "") end

---------------- Lateral: pestañas
local SIDE = {tabs = {}, seg = {}, modes = {}, info = {}}
label(sidebar, {x = 17.5, y = 13, w = 150, h = 14, text = STR.UI.SIDE_TABS, size = 10, color = TH.dim})
for i, name in ipairs(STR.TABS) do
    local cy = L.TAB_Y0 - L.TITLE_H + 13 + (i - 1) * L.TAB_STEP
    local b = mk("TextButton", {Position = UDim2.fromOffset(L.SIDE_X, cy - L.TAB_H / 2), Size = UDim2.fromOffset(L.SIDE_W, L.TAB_H),
        BackgroundColor3 = TH.sel, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 13}, sidebar)
    corner(b, 6)
    local bar = box(b, 0, 0, 3, L.TAB_H, TH.cyan, 2, nil, 14)
    local name_ = label(b, {x = 7.6, y = 0, w = 100, h = L.TAB_H, text = name, size = 11.5, color = TH.dim})
    local count = label(b, {x = 90, y = 0, w = 63.7, h = L.TAB_H, text = "", size = 10, color = TH.dim, align = "R", font = FONT.mono})
    SIDE.tabs[name] = {b = b, bar = bar, name = name_, count = count}
    UI.pages[name] = box(main, 0, PAGE_Y, L.MAIN_W, PAGE_H, nil, nil, nil, 12)
    UI.pages[name].Visible = false
end

---------------- Lateral: jugadores
label(sidebar, {x = 17.5, y = L.PLAYERS_LABEL_Y - L.TITLE_H, w = 150, h = 14, text = STR.UI.SIDE_PLAYERS, size = 10, color = TH.dim})
local segFrame = box(sidebar, L.SIDE_X, L.SEG_Y - L.TITLE_H, L.SIDE_W, L.SEG_H, TH.chip, 6, TH.border, 13)
segFrame.ClipsDescendants = true
for i, text in ipairs(STR.UI.SEG) do
    local w = L.SIDE_W / 3
    local b = mk("TextButton", {Position = UDim2.fromOffset((i - 1) * w, 0), Size = UDim2.fromOffset(w, L.SEG_H), BackgroundColor3 = TH.segOn,
        BackgroundTransparency = 1, Text = text, TextColor3 = TH.dim, TextSize = 10.5, AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 14}, segFrame)
    setFont(b, FONT.med)
    SIDE.seg[i] = b
end
label(sidebar, {x = 17.5, y = L.SEG_Y - L.TITLE_H + L.SEG_H + 6, w = 158, h = 30, text = STR.UI.PLAYERS_NOTE, size = 10, color = TH.dim, wrap = true, top = true})

---------------- Lateral: modos
label(sidebar, {x = 17.5, y = L.MODE_LABEL_Y - L.TITLE_H, w = 150, h = 14, text = STR.UI.SIDE_MODE, size = 10, color = TH.dim})
for i, m in ipairs(CONFIG.MODES) do
    local y = L.MODE_Y0 - L.TITLE_H + (i - 1) * L.MODE_STEP
    local b = mk("TextButton", {Position = UDim2.fromOffset(L.SIDE_X, y), Size = UDim2.fromOffset(L.SIDE_W, L.MODE_H), BackgroundColor3 = TH.sel,
        BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 13}, sidebar)
    corner(b, 7)
    local st = stroke(b, TH.cyan)
    local dot = box(b, 8.4, 10.7, 5, 5, TH.dotOff, 3, nil, 14)
    label(b, {x = 21.7, y = 5, w = 136, h = 16, text = m.label, size = 12, font = FONT.semi})
    label(b, {x = 21.7, y = 19.5, w = 138, h = 14, text = m.desc or "", size = 10, color = TH.dim})
    SIDE.modes[i] = {b = b, st = st, dot = dot}
    U.conn(b.Activated, function()
        MODE.set(i)
        if MODE.def.capture then UI.toast(string.format(STR.CAPTURE_START, CONFIG.CAPTURE_SECONDS)) end
        UI.force = true
    end, "modo " .. m.id)
end

---------------- Lateral: información del ejecutor
do
    local card = box(sidebar, L.SIDE_X, L.INFO_Y - L.TITLE_H, L.SIDE_W, L.INFO_H, TH.side, 7, TH.border, 13)
    for i, k in ipairs(STR.UI.INFO) do
        local cy = 16 + (i - 1) * L.INFO_STEP
        label(card, {x = 9.3, y = cy - 7, w = 100, h = 14, text = k, size = 10, color = TH.dim})
        SIDE.info[i] = label(card, {x = 70, y = cy - 7, w = 81, h = 14, text = "", size = 10, align = "R"})
    end
end

---------------- Tarjetas de métricas
local METRIC = {}
local function metricCard(x, y, w, h, title, color, sparkX, sparkY)
    local c = box(main, x, y, w, h, TH.card, 8, TH.border, 12)
    label(c, {x = 11.8, y = 9.7, w = w - 20, h = 14, text = title, size = 11, color = TH.dim})
    local value = label(c, {x = 11.8, y = 26, w = 80, h = 24, text = "", size = 19, font = FONT.bold, color = color})
    local value2 = label(c, {x = 11.8, y = 44.7, w = 80, h = 24, text = "", size = 19, font = FONT.bold, color = color})
    local sub = label(c, {x = 11.8, y = 50, w = w - 20, h = 14, text = "", size = 10, color = TH.dim})
    local spark = UI.spark(c, sparkX, sparkY, 53, 17, color)
    return {card = c, value = value, value2 = value2, sub = sub, spark = spark, baseSubY = 50}
end
-- Valor en una o dos líneas (como en el diseño: "412 / MB" cuando no cabe).
local function setMetric(m, value, sub, hist)
    local num, unit = value:match("^(%S+)%s+(%S+)$")
    local twoLines = num and #value >= 6
    m.value.Text = twoLines and num or value
    m.value2.Text = twoLines and unit or ""
    m.sub.Position = UDim2.fromOffset(11.8, twoLines and 67 or m.baseSubY)
    m.sub.Text = sub
    if hist and #hist >= 2 then m.spark.set(hist) end
end
for k, def in ipairs({{"fps", STR.UI.M_FPS, TH.ok}, {"ping", STR.UI.M_PING, TH.cyan}, {"mem", STR.UI.M_MEM, TH.violet}, {"net", STR.UI.M_NET, TH.blue}}) do
    METRIC[def[1]] = metricCard(0.7 + (k - 1) * (L.METRIC_W + L.METRIC_GAP), L.TOP, L.METRIC_W, L.METRIC_H, def[2], def[3], 74.4, 28)
end
METRIC.eps = metricCard(0, L.WIDE_Y, L.WIDE_W, L.WIDE_H, STR.UI.M_EPS, TH.warn, 224, 27.2)
METRIC.console = metricCard(L.WIDE_W + 10.3, L.WIDE_Y, L.WIDE_W, L.WIDE_H, STR.UI.M_CONSOLE, TH.bad, 224, 27.2)

---------------- Columna derecha: detalle, feed y nota
local DC = {} -- tarjeta de detalle
do
    local c = box(right, 0.5, L.TOP + 0.5, L.RIGHT_W - 0.5, L.DETAIL_H, TH.card, 8, TH.border, 12)
    DC.card = c
    DC.head = label(c, {x = 12, y = 13, w = 140, h = 15, text = STR.UI.DETAIL, size = 11.5, font = FONT.semi})
    DC.badge, DC.badgeText = badge(c, 170, 12.7, 14.3, "Servidor", 9.5)
    DC.title = label(c, {x = 12, y = 35, w = 202, h = 18, text = STR.UI.NO_SELECTION, size = 13, font = FONT.semi})
    DC.keys, DC.vals = {}, {}
    for i = 1, 4 do
        local cy = 66.7 + (i - 1) * 18.1
        DC.keys[i] = label(c, {x = 12, y = cy - 7, w = 90, h = 14, text = "", size = 10.5, color = TH.dim})
        DC.vals[i] = label(c, {x = 70, y = cy - 7, w = 144, h = 14, text = "", size = 10.5, align = "R"})
    end
    label(c, {x = 12, y = 134.5, w = 100, h = 14, text = STR.UI.D_ROUTE, size = 10, color = TH.dim})
    DC.route = label(c, {x = 12, y = 156, w = 202, h = 14, text = "", size = 10, color = TH.cyan, font = FONT.mono})
    label(c, {x = 12, y = 178.5, w = 100, h = 14, text = STR.UI.D_ARGS, size = 10, color = TH.dim})
    local code = box(c, 12, 200.5, 202, 44.4, TH.code, 6, TH.border, 13)
    code.ClipsDescendants = true
    DC.args = label(code, {x = 9.6, y = 7, w = 186, h = 31, text = "", size = 10, font = FONT.mono, wrap = true, top = true, z = 14})
    label(c, {x = 12, y = 255.5, w = 40, h = 14, text = STR.UI.D_TYPES, size = 10, color = TH.dim})
    DC.typeChips = {}
    for i = 1, 3 do
        local f = box(c, 39 + (i - 1) * 46, 254.5, 42.5, 16, TH.code, 4, TH.border, 13)
        DC.typeChips[i] = {f = f, t = label(f, {x = 0, y = 0, w = 42.5, h = 16, text = "", size = 9.5, font = FONT.mono, align = "C", z = 14})}
    end
    DC.copy = button(c, 12.2, 280.3, 62, 28, STR.UI.D_COPY, TH.ok, TH.card, nil, 10.5)
    DC.watch = button(c, 81, 280.3, 61.3, 28, STR.UI.D_WATCH, TH.violet, TH.card, nil, 10.5)
    DC.inspect = button(c, 149.2, 280.3, 64.3, 28, STR.UI.D_INSPECT, TH.text, TH.card, nil, 10.5)
end
local FC = {}
do
    local c = box(right, 0.5, L.FEED_Y, L.RIGHT_W - 0.5, L.FEED_H, TH.card, 8, TH.border, 12)
    label(c, {x = 12, y = 11, w = 200, h = 15, text = STR.UI.FEED_CARD, size = 11.5, font = FONT.semi})
    FC.k1 = label(c, {x = 12, y = 32.5, w = 120, h = 14, text = STR.UI.FEED_BUDGET, size = 10, color = TH.dim})
    FC.v1 = label(c, {x = 110, y = 32.5, w = 104, h = 14, text = "", size = 10, font = FONT.mono, align = "R"})
    FC.bar1 = progress(c, 12, 51.5, 202, 4, TH.ok)
    FC.k2 = label(c, {x = 12, y = 62.5, w = 130, h = 14, text = "", size = 10, color = TH.dim})
    FC.v2 = label(c, {x = 110, y = 62.5, w = 104, h = 14, text = "", size = 10, font = FONT.mono, align = "R", color = TH.warn})
    FC.bar2 = progress(c, 12, 80.5, 202, 4, TH.warn)
    label(c, {x = 12, y = 91.5, w = 130, h = 14, text = STR.UI.FEED_DROPPED, size = 10, color = TH.dim})
    FC.v3 = label(c, {x = 110, y = 91.5, w = 104, h = 14, text = "", size = 10, align = "R", font = FONT.mono})
    label(c, {x = 12, y = 108.5, w = 130, h = 14, text = STR.UI.FEED_MODE, size = 10, color = TH.dim})
    FC.v4 = label(c, {x = 110, y = 108.5, w = 104, h = 14, text = "", size = 10, align = "R", color = TH.ok})
end
do
    local c = box(right, 0.5, L.NOTE_Y, L.RIGHT_W - 0.5, L.NOTE_H, nil, 8, nil, 12)
    dashedBorder(c, L.RIGHT_W - 0.5, L.NOTE_H, TH.border)
    label(c, {x = 12, y = 10, w = 202, h = 46, text = STR.UI.NOTE, size = 9.5, color = TH.dim, wrap = true, top = true})
end

---------------- Barra de estado
local ST = {}
do
    local leftList = box(statusBar, 17.3, 0, 760, L.STATUS_H, nil, nil, nil, 12)
    mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 14), VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder}, leftList)
    local live = box(leftList, 0, 0, 62, L.STATUS_H, nil, nil, nil, 12)
    live.LayoutOrder = 1
    ST.dot = box(live, 0, 10.5, 6, 6, TH.ok, 3, nil, 13)
    ST.live = label(live, {x = 9.4, y = 0, w = 55, h = L.STATUS_H, text = STR.UI.ST_LIVE, size = 10, font = FONT.semi, color = TH.ok})
    local function item(parent, order, align)
        local t = label(parent, {x = 0, y = 0, w = 0, h = L.STATUS_H, text = "", size = 10, color = TH.dim, align = align})
        t.AutomaticSize = Enum.AutomaticSize.X
        t.LayoutOrder = order
        return t
    end
    ST.left = {}
    for i = 1, 5 do ST.left[i] = item(leftList, i + 1) end
    local rightList = box(statusBar, 625, 0, 400, L.STATUS_H, nil, nil, nil, 12)
    mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 14), VerticalAlignment = Enum.VerticalAlignment.Center,
        HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder}, rightList)
    ST.right = {}
    for i = 1, 4 do ST.right[i] = item(rightList, i) end
end

---------------- Detalle largo (inspector, script de Studio, limitaciones…) sobre la zona de la pestaña
local detail = box(main, 0, PAGE_Y, L.MAIN_W, PAGE_H, TH.bg, 8, TH.violet, 30)
detail.Active = true
detail.Visible = false
local DET = {chunks = {}, text = "", extraFn = nil}
DET.title = label(detail, {x = 12, y = 6, w = 300, h = 28, text = "", size = 12, font = FONT.semi, color = TH.cyan, z = 31})
DET.close = button(detail, L.MAIN_W - 72, 6, 62, 26, STR.UI.BACK, TH.bad, TH.card, function() detail.Visible = false end, 10.5)
DET.copy = button(detail, L.MAIN_W - 140, 6, 62, 26, STR.COPY, TH.cyan, TH.card, function() UI.copyOrShow(STR.DETAIL, DET.text) end, 10.5)
DET.extra = button(detail, L.MAIN_W - 238, 6, 92, 26, "", TH.violet, TH.card, function() if DET.extraFn then DET.extraFn() end end, 10.5)
for _, b in ipairs({DET.close, DET.copy, DET.extra}) do b.ZIndex = 31 end
DET.scroll = mk("ScrollingFrame", {Position = UDim2.fromOffset(8, 40), Size = UDim2.fromOffset(L.MAIN_W - 16, PAGE_H - 48), BackgroundColor3 = TH.card,
    BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = TH.violet, AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(0, 0, 0, 0), ZIndex = 31}, detail)
corner(DET.scroll, 6)
mk("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8)}, DET.scroll)
mk("UIListLayout", {Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder}, DET.scroll)

local function chunkText(s)
    local parts, pos = {}, 1
    while pos <= #s do
        local stop = math.min(#s, pos + CONFIG.DETAIL_CHUNK - 1)
        if stop < #s then
            local nl = s:find("\n", stop, true)
            if nl and nl - stop < 400 then stop = nl end
        end
        parts[#parts + 1] = s:sub(pos, stop)
        pos = stop + 1
    end
    return parts
end

function UI.detail(title, text, extraLabel, extraFn)
    DET.text = tostring(text or "")
    DET.extraFn = extraFn
    DET.title.Text = title or STR.DETAIL
    DET.extra.Visible = extraLabel ~= nil
    DET.extra.Text = extraLabel or ""
    local shown = DET.text
    if #shown > CONFIG.DETAIL_MAX then shown = shown:sub(1, CONFIG.DETAIL_MAX) .. STR.DETAIL_CUT end
    local parts = chunkText(shown)
    for idx, part in ipairs(parts) do
        local tb = DET.chunks[idx]
        if not tb then
            tb = mk("TextBox", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, TextColor3 = TH.text,
                TextSize = 10.5, TextWrapped = true, MultiLine = true, ClearTextOnFocus = false, TextEditable = false,
                TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = idx, ZIndex = 32}, DET.scroll)
            setFont(tb, FONT.mono)
            DET.chunks[idx] = tb
        end
        tb.Text = part
        tb.Visible = true
    end
    for i = #parts + 1, #DET.chunks do DET.chunks[i].Visible = false; DET.chunks[i].Text = "" end
    DET.scroll.CanvasPosition = Vector2.new(0, 0)
    detail.Visible = true
end

---------------- Selector de jugador (misma zona)
local picker = box(main, 0, PAGE_Y, L.MAIN_W, PAGE_H, TH.bg, 8, TH.cyan, 33)
picker.Active = true
picker.Visible = false
local pickerTitle = label(picker, {x = 12, y = 6, w = 300, h = 28, text = STR.PICK_TITLE, size = 12, font = FONT.semi, color = TH.cyan, z = 34})
local pickerClose = button(picker, L.MAIN_W - 72, 6, 62, 26, STR.UI.BACK, TH.bad, TH.card, function() picker.Visible = false end, 10.5)
pickerClose.ZIndex = 34
local pickerList = UI.table(picker, 8, 40, L.MAIN_W - 16, PAGE_H - 48, {
    {title = STR.UI.D_PLAYER, x = 14, w = 300, kind = "strong"}, {title = "UserId", x = 330, w = 230, kind = "mono"}})
function UI.pick(title, options)
    pickerTitle.Text = title
    local items = {}
    for i, o in ipairs(options) do
        items[i] = {cells = {o.title, o.sub or ""}, onTap = function() picker.Visible = false; o.onPick(); UI.force = true end}
    end
    picker.Visible = true
    pickerList.set(items)
end

---------------- Controles compartidos
function UI.controlLabels()
    local modeTxt = MODE.def.label
    local left = MODE.captureLeft()
    if left then modeTxt = modeTxt .. " " .. left .. "s" end
    return {mode = string.format(STR.BTN_MODE, modeTxt), players = string.format(STR.BTN_PLAYERS, FEED.label())}
end
function UI.addControl(kind, b) UI.controls[#UI.controls + 1] = {kind = kind, b = b} end
function UI.refreshControls(labels)
    for _, c in ipairs(UI.controls) do
        local t = labels[c.kind]
        if t and c.b.Text ~= t then c.b.Text = t end
    end
end

function UI.pickPlayer()
    local opts = {
        {title = STR.PLAYERS_ALL, sub = "", onPick = function() FEED.setFilter("all") end},
        {title = STR.PLAYERS_ME, sub = "", onPick = function() FEED.setFilter("me") end},
    }
    local ok, players = pcall(function() return S.Players:GetPlayers() end)
    for _, p in ipairs(ok and players or {}) do
        local uid = p.UserId
        opts[#opts + 1] = {title = (p.DisplayName and p.DisplayName ~= p.Name) and (p.DisplayName .. " (@" .. p.Name .. ")") or p.Name,
            sub = string.format(STR.PICK_SUB, uid, p == LP and STR.PICK_YOU or ""), onPick = function() FEED.setFilter(uid) end}
    end
    UI.pick(STR.PICK_TITLE, opts)
end
for i, b in ipairs(SIDE.seg) do
    U.conn(b.Activated, function()
        if i == 1 then FEED.setFilter("all") elseif i == 2 then FEED.setFilter("me") else UI.pickPlayer() end
        UI.force = true
    end, "segmento jugadores")
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
        UI.detail(string.format(STR.INSPECTOR, tostring(inst.Name)), inspect(inst), WATCH.has(inst) and STR.UNWATCH_BTN or STR.WATCH_BTN, function()
            local on = WATCH.toggle(inst)
            UI.toast(on and string.format(STR.WATCH_ON, CONFIG.MAX_WATCH) or STR.WATCH_OFF)
            show()
        end)
    end
    show()
end

local function remoteByPath(path)
    if not path then return nil end
    for _, e in ipairs(REG.remotes) do if e.path == path then return e end end
    return nil
end

---------------- Tarjeta de detalle (columna derecha)
-- spec = {badge, title, rows = {{k, v, color}}, route, args, types = {...}, copyText, inst}
function UI.showCard(spec)
    DC.spec = spec
    DC.badge.Visible = spec.badge ~= nil
    if spec.badge then setBadge(DC.badge, DC.badgeText, spec.badge) end
    DC.title.Text = spec.title or ""
    for i = 1, 4 do
        local r = spec.rows and spec.rows[i]
        DC.keys[i].Text = r and r[1] or ""
        DC.vals[i].Text = r and tostring(r[2]) or ""
        DC.vals[i].TextColor3 = (r and r[3]) or TH.text
        setFont(DC.vals[i], (r and r[4]) and FONT.mono or FONT.sans)
    end
    DC.route.Text = spec.route or "—"
    DC.args.Text = spec.args or ""
    for i, chip in ipairs(DC.typeChips) do
        local t = spec.types and spec.types[i]
        chip.f.Visible = t ~= nil
        chip.t.Text = t or ""
    end
    DC.watch.Text = (spec.inst and WATCH.has(spec.inst)) and STR.UI.D_UNWATCH or STR.UI.D_WATCH
end
U.conn(DC.copy.Activated, function() if DC.spec then UI.copyOrShow(STR.DETAIL, DC.spec.copyText or DC.args.Text) end end, "detalle copiar")
U.conn(DC.watch.Activated, function()
    local inst = DC.spec and DC.spec.inst
    if not inst then UI.toast(STR.UI.D_NO_INST) return end
    UI.toast(WATCH.toggle(inst) and string.format(STR.WATCH_ON, CONFIG.MAX_WATCH) or STR.WATCH_OFF)
    UI.showCard(DC.spec)
end, "detalle vigilar")
U.conn(DC.inspect.Activated, function()
    local spec = DC.spec
    if spec and spec.inspect then spec.inspect() return end
    if spec and spec.inst then openInspector(spec.inst) else UI.toast(STR.UI.D_NO_INST) end
end, "detalle inspeccionar")

local function eventCard(e)
    local types = {}
    for t in tostring(e.types or ""):gmatch("[^,%s]+") do types[#types + 1] = t end
    local rem = remoteByPath(e.remote)
    local who = e.player and ("@" .. tostring(e.player) .. (e.userId and (" · " .. tostring(e.userId)) or "")) or "—"
    UI.showCard({
        badge = (e.kind == "Spam") and "Spam" or e.cat,
        title = (e.cat == "Servidor" and e.kind and e.kind ~= "Spam" and e.kind ~= e.name) and (e.kind .. " · " .. e.name) or e.name,
        rows = {{STR.UI.D_TIME, e.t, TH.text, true}, {STR.UI.D_PLAYER, who, e.player and TH.violet or TH.dim},
            {STR.UI.D_DIR, e.dir ~= "" and e.dir or "—"}, {STR.UI.D_COUNT, (rem and ("×" .. rem.count)) or (FEED.byRemote[e.name] and ("×" .. FEED.byRemote[e.name])) or "—", TH.text, true}},
        route = e.remote or (e.extra ~= "" and e.extra) or "—", args = e.args ~= "" and e.args or e.extra, types = types,
        copyText = LOG.format(e), inst = rem and rem.inst or nil,
    })
end

---------------- Filtros de registros: chips + búsqueda + modo + jugadores
local CHIPS = STR.UI.CHIPS_LOGS
local logState = {q = "", chip = CFG.get("logChip", 1), box = nil}
if not CHIPS[logState.chip] then logState.chip = 1 end
local function chipPasses(e)
    local c = CHIPS[logState.chip]
    if c == "Todas" then return true end
    if c == "Spam" then return e.kind == "Spam" end
    return e.cat == c
end
local function logVisible(e, q)
    if not chipPasses(e) or not MODE.passes(e) or not FEED.passes(e) then return false end
    return U.match(q, e.name, e.args, e.extra, e.cat, e.types, e.player, e.remote, e.kind)
end
local function filteredLogs(limit)
    local q, out = U.lower(logState.q), {}
    LOG.iter(function(e)
        if logVisible(e, q) then out[#out + 1] = e end
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
    local preview = e.args ~= "" and e.args or e.extra
    return {
        id = e.id, selected = (UI.sel == e.id),
        cells = {e.t, (e.kind == "Spam") and "Spam" or e.cat, e.player and ("@" .. tostring(e.player)) or "—",
            (e.cat == "Servidor" and e.kind and e.kind ~= "Spam" and e.kind ~= e.name and e.kind ~= "ServerStats") and (e.kind .. " · " .. e.name) or e.name,
            U.oneLine(preview), e.types ~= "" and e.types or "—"},
        colors = {nil, nil, e.player and TH.violet or TH.dim},
        onTap = function() UI.sel = e.id; eventCard(e) end,
    }
end

---------------- Textos para copiar
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

local function teleportArmed()
    return CFG.get("reloadOnTeleport", false) and CFG.get("reloadUrl", "") == CONFIG.RELOAD_URL
end
local function confirmTeleportReload(b)
    if CFG.get("reloadOnTeleport", false) then
        CFG.set("reloadOnTeleport", false)
        b.Text = string.format(STR.BTN_TELEPORT, STR.TELEPORT_OFF)
        UI.toast(STR.TELEPORT_DONE_OFF)
        return
    end
    UI.detail(STR.TELEPORT_TITLE, string.format(STR.TELEPORT_BODY, CONFIG.RELOAD_URL), STR.CONFIRM, function()
        CFG.set("reloadOnTeleport", true)
        CFG.set("reloadUrl", CONFIG.RELOAD_URL)
        b.Text = string.format(STR.BTN_TELEPORT, STR.TELEPORT_ON)
        detail.Visible = false
        UI.toast(STR.TELEPORT_DONE_ON)
    end)
end

-- Fila de botones al estilo de la foto, de izquierda a derecha.
local function toolbarRow(page, x, defs)
    local out = {}
    for _, d in ipairs(defs) do
        out[#out + 1] = button(page, x, 0, d.w, L.SEARCH_H, d.text, d.fg, d.bg, d.fn, 11)
        x = x + d.w + L.BTN_GAP
    end
    return out
end

---------------- LOGS (la vista de la foto)
local LOGS = {}
do
    local page = UI.pages.LOGS
    logState.box = UI.search(page, 0, 0, L.SEARCH_W, L.SEARCH_H, STR.UI.SEARCH_LOGS, function(t) logState.q = t; UI.force = true end)
    local pauseBtn
    pauseBtn = toolbarRow(page, 333.6, {
        {text = STR.PAUSE, w = 52.6, fg = TH.text, bg = TH.chip, fn = function(b)
            LOG.paused = not LOG.paused
            b.Text = LOG.paused and STR.RESUME or STR.PAUSE
            UI.force = true
        end},
        {text = STR.CLEAR, w = 58, fg = TH.bad, bg = TH.btnRed, fn = function() LOG.clear(); UI.sel = nil; UI.force = true; UI.toast(STR.CLEARED) end},
        {text = STR.COPY, w = 54, fg = TH.ok, bg = TH.btnGreen, fn = function()
            local list, t = filteredLogs(), {string.format(STR.LOGS_COPY_HEAD, U.fullDate(), MODE.def.label, FEED.label())}
            for i = #list, 1, -1 do t[#t + 1] = LOG.format(list[i]) end
            UI.copyOrShow(STR.LOGS_TITLE, table.concat(t, "\n"))
        end},
        {text = STR.EXPORT, w = 64, fg = TH.violet, bg = TH.btnViolet, fn = function()
            local list = filteredLogs()
            local base, t, records = "logs_" .. U.fileStamp(), {string.format(STR.LOGS_COPY_HEAD, U.fullDate(), MODE.def.label, FEED.label())}, {}
            for i = #list, 1, -1 do t[#t + 1] = LOG.format(list[i]); records[#records + 1] = LOG.toRecord(list[i]) end
            local ok, where = U.export(base .. ".txt", table.concat(t, "\n"))
            local json = U.json({version = CONFIG.VERSION, placeId = game.PlaceId, mode = MODE.def.id, players = FEED.filter, logs = records})
            if ok and json then U.export(base .. ".json", json) end
            UI.toast(ok and string.format(STR.SAVED, where) or string.format(STR.EXPORT_FAIL, tostring(where)))
        end},
    })
    LOGS.pause = pauseBtn[1]
    LOGS.chips = UI.chips(page, 0, CHIPS_Y, CHIPS, function(i) return logState.chip == i end,
        function(i) logState.chip = i; CFG.set("logChip", i) end, {44, 53, 50, 43, 40, 36, 52, 50, 44})
    LOGS.count = label(page, {x = 386.5, y = CHIPS_Y, w = 200, h = L.CHIP_H, text = "", size = 10, color = TH.dim, align = "R"})
    local C = STR.UI.COLS_LOGS
    LOGS.table = UI.table(page, 0, TABLE_Y, L.MAIN_W, L.TABLE_H, {
        {title = C[1], x = 14, w = 88, kind = "mono"}, {title = C[2], x = 107, w = 70, kind = "badge"},
        {title = C[3], x = 184.7, w = 80, kind = "player"}, {title = C[4], x = 269, w = 168, kind = "strong"},
        {title = C[5], x = 443, w = 46, hw = 60, kind = "mono"}, {title = C[6], x = 494, w = 88, kind = "mono"}})
    UI.lists.LOGS = LOGS.table
    -- Remotos / jugadores más activos
    local cardsY = L.CARDS_Y - PAGE_Y
    local function topCard(x, title)
        local c = box(page, x, cardsY, L.CARD_W, L.CARDS_H, TH.card, 8, TH.border, 12)
        label(c, {x = 12.8, y = 10.7, w = 260, h = 15, text = title, size = 11.5, font = FONT.semi})
        local rows = {}
        for i = 1, 5 do
            local cy = 38.7 + (i - 1) * 27.75
            rows[i] = {
                name = label(c, {x = 12.8, y = cy - 7, w = 150, h = 14, text = "", size = 10.5, font = FONT.med}),
                val = label(c, {x = 120, y = cy - 7, w = 156.8, h = 14, text = "", size = 10, align = "R", color = TH.dim, font = FONT.mono}),
                bar = progress(c, 12.8, cy + 5.5, 264, 4, BAR_COLORS[i]),
            }
        end
        return c, rows
    end
    LOGS.remCard, LOGS.remRows = topCard(0.6, STR.UI.TOP_REMOTES)
    LOGS.plCard, LOGS.plRows = topCard(299, STR.UI.TOP_PLAYERS)
    LOGS.plNote = label(LOGS.plCard, {x = 12.8, y = 114.4, w = 264, h = 14, text = string.format(STR.UI.FEED_LIMIT_NOTE, CONFIG.FEED_SENDER_LIMIT, CONFIG.FEED_VIEWER_LIMIT), size = 9.5, color = TH.dim})
    -- Gráfica de eventos por segundo
    local ch = box(page, 0.6, L.CHART_Y - PAGE_Y, L.MAIN_W - 1.2, L.CHART_H, TH.card, 8, TH.border, 12)
    label(ch, {x = 12.2, y = 11, w = 300, h = 15, text = string.format(STR.UI.CHART, L.CHART_SECONDS), size = 11.5, font = FONT.semi})
    LOGS.peak = label(ch, {x = 400, y = 11, w = 174, h = 15, text = "", size = 9.5, color = TH.dim, align = "R"})
    LOGS.bars = {}
    local pitch = (574 - 12.2) / L.CHART_BARS
    for i = 1, L.CHART_BARS do LOGS.bars[i] = box(ch, 12.2 + (i - 1) * pitch, 92.1, pitch - 2.6, 0, TH.cyan, 2, nil, 13) end
    local ax = STR.UI.AXIS
    label(ch, {x = 12.2, y = 99, w = 80, h = 14, text = ax[1], size = 9.5, color = TH.dim})
    label(ch, {x = 253, y = 99, w = 80, h = 14, text = ax[2], size = 9.5, color = TH.dim, align = "C"})
    label(ch, {x = 494, y = 99, w = 80, h = 14, text = ax[3], size = 9.5, color = TH.dim, align = "R"})
end

local function topList(map, n)
    local list = {}
    for k, v in pairs(map) do list[#list + 1] = {k = k, v = v} end
    table.sort(list, function(a, b) local av, bv = type(a.v) == "table" and a.v.count or a.v, type(b.v) == "table" and b.v.count or b.v
        if av ~= bv then return av > bv end return tostring(a.k) < tostring(b.k) end)
    local out = {}
    for i = 1, math.min(n, #list) do out[i] = list[i] end
    return out
end

local function renderLogsCharts()
    -- Remotos más activos: lo que te llega (OnClientEvent) + lo que registra tu servidor.
    local merged = {}
    for _, e in ipairs(REG.remotes) do if e.count > 0 and e.name ~= CONFIG.FEED_REMOTE then merged[e.name] = (merged[e.name] or 0) + e.count end end
    for name, c in pairs(FEED.byRemote) do merged[name] = (merged[name] or 0) + c end
    local top = topList(merged, 5)
    local maxv = top[1] and top[1].v or 1
    for i, r in ipairs(LOGS.remRows) do
        local it = top[i]
        r.name.Text = it and tostring(it.k) or (i == 1 and STR.UI.NO_DATA or "")
        r.val.Text = it and ("×" .. it.v) or ""
        r.bar(it and it.v / maxv or 0)
    end
    local players = topList(FEED.byPlayer, 3)
    local pmax = players[1] and players[1].v.count or 1
    for i, r in ipairs(LOGS.plRows) do
        local it = i <= 3 and players[i] or nil
        r.name.Text = it and ("@" .. tostring(it.k)) or ((i == 1 and #players == 0) and STR.UI.NO_PLAYERS or "")
        r.name.TextColor3 = it and TH.violet or TH.dim
        r.val.Text = it and string.format(STR.UI.TOP_PLAYER_ROW, it.v.count, it.v.peak) or ""
        r.bar(it and it.v.count / pmax or 0)
    end
    for i = 4, 5 do LOGS.plRows[i].name.Text = ""; LOGS.plRows[i].val.Text = ""; LOGS.plRows[i].bar(0) end
    -- Gráfica: cada barra = media de 2 s
    local per = L.CHART_SECONDS / L.CHART_BARS
    local vals, peak, peakI = {}, 0, 0
    local n = #PERF.eps
    for b = 1, L.CHART_BARS do
        local sum, cnt = 0, 0
        for s = 1, per do
            local idx = n - (L.CHART_BARS - b) * per - (per - s)
            if idx >= 1 and PERF.eps[idx] then sum, cnt = sum + PERF.eps[idx], cnt + 1 end
        end
        vals[b] = cnt > 0 and sum / cnt or 0
        if vals[b] > peak then peak, peakI = vals[b], b end
    end
    local maxH = 57.6
    for b, f in ipairs(LOGS.bars) do
        local h = peak > 0 and math.max(2, vals[b] / peak * maxH) or 2
        f.Size = UDim2.fromOffset(f.Size.X.Offset, h)
        f.Position = UDim2.fromOffset(f.Position.X.Offset, 92.1 - h)
        f.BackgroundColor3 = (b == peakI and peak > 0) and TH.warn or TH.cyan
    end
    local maxSec = 0
    for _, v in ipairs(PERF.eps) do if v > maxSec then maxSec = v end end
    LOGS.peak.Text = string.format(STR.UI.CHART_PEAK, math.floor(maxSec + 0.5))
end

local function renderLogs()
    local list = filteredLogs()
    LOGS.count.Text = string.format(STR.UI.COUNT, #list, LOG.n)
    LOGS.chips.refresh()
    LOGS.pause.Text = LOG.paused and STR.RESUME or STR.PAUSE
    if UI.sel == nil and list[1] then UI.sel = list[1].id; eventCard(list[1]) end
    if #list == 0 then
        local filtered = MODE.def.id ~= "normal" or FEED.filter ~= "all"
        LOGS.table.set({{cells = {"", "", "", LOG.paused and STR.LOGS_PAUSED or STR.NO_LOGS,
            filtered and string.format(STR.MODE_EMPTY_SUB, MODE.def.label, FEED.label()) or STR.NO_LOGS_SUB, ""}}})
    else
        LOGS.table.setLazy(#list, function(i) return logRow(list[i]) end)
    end
    renderLogsCharts()
end

---------------- MAIN
local MAINP = {}
do
    local page = UI.pages.MAIN
    MAINP.buttons = toolbarRow(page, 0, {
        {text = STR.BTN_SUMMARY, w = 110, fg = TH.cyan, bg = TH.chip, fn = function() UI.copyOrShow(STR.SUMMARY_TITLE, UI.summaryText()) end},
        {text = STR.BTN_LIMITS, w = 92, fg = TH.text, bg = TH.chip, fn = function() UI.detail(STR.LIMITS_TITLE, STR.LIMITS) end},
        {text = STR.BTN_STUDIO, w = 96, fg = TH.violet, bg = TH.btnViolet, fn = function() UI.detail(STR.STUDIO_TITLE, STUDIO_SCRIPT) end},
        {text = string.format(STR.BTN_TELEPORT, teleportArmed() and STR.TELEPORT_ON or STR.TELEPORT_OFF), w = 128, fg = TH.violet, bg = TH.chip,
            fn = function(b) if CAP.queue_on_teleport then confirmTeleportReload(b) else UI.toast(STR.NO_WRITEFILE) end end},
        {text = STR.BTN_OFF, w = 62, fg = TH.bad, bg = TH.btnRed, fn = function() G.destroy() end},
    })
    MAINP.buttons[4].Visible = CAP.queue_on_teleport ~= nil
    local C = STR.UI.COLS_MAIN
    UI.lists.MAIN = UI.table(page, 0, CHIPS_Y, L.MAIN_W, PAGE_H - CHIPS_Y, {
        {title = C[1], x = 14, w = 160, kind = "strong"}, {title = C[2], x = 180, w = 396, kind = "text", rich = true}})
end

local function renderMain()
    local items = {}
    local function row(k, v, tap) items[#items + 1] = {cells = {k, v}, onTap = tap} end
    local counts, active = {}, 0
    for _, e in ipairs(REG.remotes) do
        counts[e.class] = (counts[e.class] or 0) + 1
        if e.count > 0 then active = active + 1 end
    end
    local yn = function(b) return b and STR.YES or STR.NO end
    row(STR.MAIN_ACTIVE, U.esc(string.format(STR.MAIN_EXEC, CAP.executor, yn(CAP.setclipboard), yn(CAP.writefile), yn(CAP.touch))))
    row(STR.MSG.MODE, U.esc(string.format(STR.MAIN_MODE, MODE.def.label, FEED.label())))
    row(STR.UI.FEED_CARD, U.esc(string.format(STR.MAIN_FEED, FEED.remote and STR.MAIN_FEED_YES or STR.MAIN_FEED_NONE)))
    if MODE.capture or MODE.lastCapture then
        local status = MODE.capture and string.format(STR.CAPTURE_LEFT, MODE.captureLeft()) or
            string.format(STR.CAPTURE_DONE, MODE.lastCapture.data.total, MODE.lastCapture.data.dur)
        row(STR.MSG.CAPTURE, U.esc(status), showCapture)
    end
    row(string.format(STR.MAIN_COMM, #REG.remotes), string.format(STR.MAIN_COMM_SUB, counts.RemoteEvent or 0, counts.UnreliableRemoteEvent or 0,
        counts.RemoteFunction or 0, counts.BindableEvent or 0, counts.BindableFunction or 0, active), function() UI.setTab("REMOTES") end)
    row(string.format(STR.MAIN_TOOLS, #REG.tools) .. " · " .. string.format(STR.MAIN_BUTTONS, #REG.buttons),
        string.format(STR.MAIN_INST, REG.instAdded, REG.instRemoved, REG.scanned, REG.scanDone and "" or STR.SCANNING), function() UI.setTab("TOOLS") end)
    row(string.format(STR.MAIN_LOGS, LOG.total), string.format(STR.MAIN_LOGS_SUB, LOG.n, LOG.max, PERF.logRate, LOG.suppressed, LOG.droppedPaused),
        function() UI.setTab("LOGS") end)
    row(string.format(STR.MAIN_PERF, PERF.fps), string.format(STR.MAIN_PERF_SUB, CONSOLE.errors, CONSOLE.warnings, G.internalErrors),
        function() UI.setTab("PERFORMANCE") end)
    for _, e in ipairs(filteredLogs(CONFIG.MAIN_RECENT)) do
        row(e.t .. "  " .. e.cat, U.esc(e.name .. "  " .. U.trunc(U.oneLine(e.args ~= "" and e.args or e.extra), 80)), function() UI.sel = e.id; eventCard(e) end)
    end
    row(STR.MAIN_INFO, STR.MAIN_INFO_SUB, function() UI.detail(STR.LIMITS_TITLE, STR.LIMITS) end)
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
local function remoteCard(e)
    local types = {}
    for t in tostring(e.lastTypes or ""):gmatch("[^,%s]+") do types[#types + 1] = t end
    UI.showCard({badge = e.class, title = e.name,
        rows = {{STR.UI.D_TIME, e.last or "—", TH.text, true}, {STR.UI.D_LOC, e.loc, TH.text},
            {STR.UI.D_DIR, e.observable and STR.DIR.S2C or STR.UI.NOT_OBS}, {STR.UI.D_COUNT, "×" .. e.count, TH.text, true}},
        route = e.path, args = e.lastArgs ~= "" and e.lastArgs or STR.DET.R_NOARGS, types = types, copyText = remoteText(e), inst = e.inst,
        inspect = function() UI.detail(e.class .. " · " .. e.name, remoteText(e), STR.REMOTE_SEE_LOGS, function() UI.logSearch(e.name) end) end})
end
local RPAGE = {}
do
    local page = UI.pages.REMOTES
    UI.search(page, 0, 0, L.SEARCH_W, L.SEARCH_H, STR.REMOTE_SEARCH, function(t) remoteState.q = t; UI.force = true end)
    toolbarRow(page, 333.6, {
        {text = string.format(STR.SORT_BTN, SORTS[remoteState.sort]), w = 120, fg = TH.text, bg = TH.chip, fn = function(b)
            remoteState.sort = remoteState.sort % #SORTS + 1
            b.Text = string.format(STR.SORT_BTN, SORTS[remoteState.sort])
            CFG.set("remoteSort", remoteState.sort)
            UI.force = true
        end},
        {text = STR.COPY, w = 54, fg = TH.ok, bg = TH.btnGreen, fn = function()
            local t = {string.format(STR.REMOTES_COPY_HEAD, U.fullDate())}
            for _, e in ipairs(filteredRemotes()) do t[#t + 1] = string.format("%-22s ×%-5d %-24s %s", e.class, e.count, e.loc, e.path) end
            UI.copyOrShow(STR.REMOTES_TITLE, table.concat(t, "\n"))
        end},
    })
    local labels = {}
    for i, f in ipairs(CLS_FILTERS) do labels[i] = CLS_SHORT[f] end
    RPAGE.chips = UI.chips(page, 0, CHIPS_Y, labels, function(i) return remoteState.cls == i end,
        function(i) remoteState.cls = i; CFG.set("remoteCls", i) end)
    local C = STR.UI.COLS_REMOTES
    UI.lists.REMOTES = UI.table(page, 0, TABLE_Y, L.MAIN_W, PAGE_H - TABLE_Y, {
        {title = C[1], x = 14, w = 120, kind = "strong"}, {title = C[2], x = 140, w = 90, kind = "badge"},
        {title = C[3], x = 270, w = 90, kind = "dim"}, {title = C[4], x = 362, w = 60, kind = "mono"},
        {title = C[5], x = 424, w = 80, kind = "mono"}, {title = C[6], x = 506, w = 76, kind = "mono"}})
end
local function renderRemotes()
    local list = filteredRemotes()
    if #list == 0 then
        UI.lists.REMOTES.set({{cells = {REG.scanDone and STR.NO_RESULTS or STR.SCANNING_T, "", STR.NO_RESULTS_SUB, "", "", ""}}})
        return
    end
    UI.lists.REMOTES.setLazy(#list, function(i)
        local e = list[i]
        return {cells = {e.name, e.class, e.loc, e.observable and ("×" .. e.count) or STR.REMOTE_NOT_OBS, e.last or "—", e.path},
            selected = UI.sel == e, onTap = function() UI.sel = e; remoteCard(e) end}
    end)
end

---------------- TOOLS
local TOOL_MODES = STR.TOOL_MODES
local toolState = {mode = 1, q = "", results = {}, searching = false}
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
local TPAGE = {}
do
    local page = UI.pages.TOOLS
    local tb = UI.search(page, 0, 0, L.SEARCH_W, L.SEARCH_H, STR.TOOL_FILTER, function(t) toolState.q = t; UI.force = true end)
    U.conn(tb.FocusLost, function(enter) if enter and toolState.mode == 3 then runSearch(tb.Text) end end, "buscar enter")
    toolbarRow(page, 333.6, {
        {text = STR.SEARCH, w = 64, fg = TH.cyan, bg = TH.chip, fn = function() toolState.mode = 3; TPAGE.chips.refresh(); runSearch(tb.Text) end},
        {text = STR.COPY, w = 54, fg = TH.ok, bg = TH.btnGreen, fn = function()
            local t = {string.format(STR.DET.TOOLS_HEAD, TOOL_MODES[toolState.mode])}
            for _, it in ipairs(UI.lists.TOOLS.all()) do t[#t + 1] = it.title end
            UI.copyOrShow(TOOL_MODES[toolState.mode], table.concat(t, "\n"))
        end},
    })
    TPAGE.chips = UI.chips(page, 0, CHIPS_Y, TOOL_MODES, function(i) return toolState.mode == i end, function(i) toolState.mode = i end)
    local C = STR.UI.COLS_TOOLS
    UI.lists.TOOLS = UI.table(page, 0, TABLE_Y, L.MAIN_W, PAGE_H - TABLE_Y, {
        {title = C[1], x = 14, w = 150, kind = "strong"}, {title = C[2], x = 170, w = 90, kind = "text"},
        {title = C[3], x = 262, w = 120, kind = "dim"}, {title = C[4], x = 384, w = 198, kind = "mono"}})
end
local function objectCard(inst, title, rows)
    UI.showCard({badge = "Instancia", title = title, rows = rows, route = U.path(inst), args = "", types = {}, copyText = U.path(inst), inst = inst})
end
local TOOL_RENDER = {}
TOOL_RENDER[1] = function(items, q)
    for _, e in ipairs(REG.tools) do
        if U.match(q, e.name, e.owner, e.path) then
            items[#items + 1] = {cells = {e.name, tostring(e.state), tostring(e.owner), string.format("×%d · %s", e.equips, e.path)},
                colors = {nil, (e.state == STR.TOOL_STATE_EQUIPPED) and TH.ok or TH.warn},
                onTap = function() objectCard(e.inst, e.name, {{STR.UI.D_PLAYER, tostring(e.owner)}, {STR.UI.D_DIR, tostring(e.state)}}) end}
        end
    end
    if #items == 0 then items[1] = {cells = {STR.NO_TOOLS, "", "", STR.NO_TOOLS_SUB}} end
end
TOOL_RENDER[2] = function(items)
    for _, c in ipairs(REG.containers) do
        items[#items + 1] = {cells = {c.name, string.format(STR.CONT_ROW, c.count), "", string.format(STR.CONT_SUB, c.added, c.removed)},
            onTap = function() openInspector(c.inst) end}
    end
    items[#items + 1] = {cells = {STR.SERVER_ONLY, "", "", STR.SERVER_ONLY_SUB}}
    items[#items + 1] = {cells = {string.format(STR.WS_LOG, REG.logWorkspaceInstances and STR.DET.YES_UP or STR.DET.NO_UP), "", "", STR.WS_LOG_SUB},
        onTap = function() REG.logWorkspaceInstances = not REG.logWorkspaceInstances; UI.force = true end}
end
TOOL_RENDER[3] = function(items)
    if toolState.searching then items[1] = {cells = {STR.SEARCHING, "", "", STR.SEARCHING_SUB}} end
    for _, r in ipairs(toolState.results) do
        local ok, cls, nm = pcall(function() return r.inst.ClassName, r.inst.Name end)
        if ok then items[#items + 1] = {cells = {nm, cls, r.loc, U.path(r.inst)}, onTap = function() openInspector(r.inst) end} end
    end
    if #items == 0 then items[1] = {cells = {STR.SEARCH_HINT, "", "", string.format(STR.SEARCH_HINT_SUB, CONFIG.MAX_SEARCH)}} end
end
TOOL_RENDER[4] = function(items)
    for _, w in ipairs(WATCH.list) do items[#items + 1] = {cells = {w.name, "", "", U.path(w.inst)}, onTap = function() openInspector(w.inst) end} end
    if #items == 0 then items[1] = {cells = {STR.NO_WATCH, "", "", STR.NO_WATCH_SUB}} end
end
local function renderTools()
    local items = {}
    TOOL_RENDER[toolState.mode](items, U.lower(toolState.q))
    TPAGE.chips.refresh()
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
local BPAGE = {}
do
    local page = UI.pages.BUTTONS
    UI.search(page, 0, 0, L.SEARCH_W, L.SEARCH_H, STR.BTN_SEARCH, function(t) btnState.q = t; UI.force = true end)
    toolbarRow(page, 333.6, {
        {text = STR.COPY, w = 54, fg = TH.ok, bg = TH.btnGreen, fn = function()
            local t = {STR.DET.BUTTONS_HEAD}
            for _, e in ipairs(REG.buttons) do
                local okt, tx = pcall(function() return e.inst.Text end)
                t[#t + 1] = string.format("%-12s %-5s ×%-4d %s  \"%s\"", e.class, effVisible(e.inst) and STR.DET.VIS_SHORT or STR.DET.HID_SHORT, e.clicks, U.path(e.inst), okt and U.trunc(tx or "", 40) or "")
            end
            UI.copyOrShow(STR.DET.BUTTONS_TITLE, table.concat(t, "\n"))
        end},
    })
    BPAGE.chips = UI.chips(page, 0, CHIPS_Y, BTN_FILTERS, function(i) return btnState.f == i end, function(i) btnState.f = i end)
    local C = STR.UI.COLS_BUTTONS
    UI.lists.BUTTONS = UI.table(page, 0, TABLE_Y, L.MAIN_W, PAGE_H - TABLE_Y, {
        {title = C[1], x = 14, w = 150, kind = "strong"}, {title = C[2], x = 170, w = 110, kind = "dim"},
        {title = C[3], x = 282, w = 70, kind = "text"}, {title = C[4], x = 354, w = 50, kind = "mono"}, {title = C[5], x = 406, w = 176, kind = "mono"}})
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
    BPAGE.chips.refresh()
    if #list == 0 then UI.lists.BUTTONS.set({{cells = {STR.NO_BUTTONS, "", "", "", STR.NO_BUTTONS_SUB}}}) return end
    UI.lists.BUTTONS.setLazy(#list, function(i)
        local it, e = list[i], list[i].e
        return {cells = {it.tx ~= "" and U.trunc(it.tx, 40) or e.name, e.name, it.vis and STR.VISIBLE or STR.HIDDEN, "×" .. e.clicks, e.path},
            colors = {it.vis and TH.text or TH.dim, nil, it.vis and TH.ok or TH.dim},
            onTap = function()
                UI.showCard({badge = "Botón", title = e.name, rows = {{STR.UI.D_COUNT, "×" .. e.clicks, TH.text, true}, {STR.UI.D_TEXT, it.tx}},
                    route = e.path, args = "", types = {}, copyText = buttonText(e), inst = e.inst,
                    inspect = function() UI.detail(e.class .. " · " .. e.name, buttonText(e), STR.INSPECT, function() openInspector(e.inst) end) end})
            end}
    end)
end

---------------- PERFORMANCE
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
    toolbarRow(page, 0, {
        {text = STR.BTN_PERF_COPY, w = 118, fg = TH.cyan, bg = TH.chip, fn = function() UI.copyOrShow(STR.PERF_TITLE, UI.perfText()) end},
        {text = STR.BTN_PERF_NOTES, w = 140, fg = TH.violet, bg = TH.btnViolet, fn = function() UI.detail(STR.NOTES_TITLE, STR.PERF_NOTES) end},
    })
    local C = STR.UI.COLS_PERF
    UI.lists.PERFORMANCE = UI.table(page, 0, CHIPS_Y, L.MAIN_W, PAGE_H - CHIPS_Y, {
        {title = C[1], x = 14, w = 130, kind = "strong"}, {title = C[2], x = 150, w = 120, kind = "mono"}, {title = C[3], x = 276, w = 306, kind = "dim"}})
end
local function renderPerf()
    local P = STR.PERF
    local items = {}
    local function row(k, v, d, tap, color) items[#items + 1] = {cells = {k, v, d}, onTap = tap, colors = {nil, color}} end
    row(STR.UI.M_FPS, fmt(PERF.fps, "%.0f"), string.format(P.FRAME, fmt(PERF.frameAvg * 1000, "%.1f", " ms"), fmt(PERF.lastFrameMax * 1000, "%.0f", " ms")), nil,
        PERF.fps >= 50 and TH.ok or (PERF.fps >= 30 and TH.warn or TH.bad))
    row(STR.UI.M_PING, fmt(PERF.ping, "%.0f", " ms"), PERF.pingSrc ~= "" and string.format(P.PING_SRC, PERF.pingSrc) or P.PING_NA, nil,
        (PERF.ping and PERF.ping > CONFIG.PING_ALERT_MS) and TH.bad or TH.cyan)
    row(STR.UI.M_MEM, fmt(PERF.mem, "%.0f", " MB"), string.format(P.MEM_SUB, fmt(PERF.memScript, "%.0f", " MB"), fmt(PERF.luaHeap, "%.1f", " MB")), nil, TH.violet)
    row(STR.UI.M_NET, fmt(PERF.recv, "%.1f", " KB/s"), string.format(P.NET_SUB, fmt(PERF.physFps, "%.0f", " FPS"), fmt(PERF.instCount, "%.0f")), nil, TH.blue)
    row(P.SERVER, FEED.stats and "ok" or "—", FEED.stats or P.SERVER_NONE)
    row(STR.UI.M_CONSOLE, string.format(P.ERR, CONSOLE.errors), string.format(P.WARN, CONSOLE.warnings) .. " · " .. P.CONSOLE_SUB, function()
        for i, c in ipairs(CHIPS) do if c == "Consola" then logState.chip = i end end
        UI.logSearch("")
    end, CONSOLE.errors > 0 and TH.bad or TH.ok)
    row(STR.TABS[2], tostring(#REG.remotes), string.format(P.OBJECTS, #REG.remotes, #REG.tools, #REG.buttons))
    row(STR.MSG.MODE, MODE.def.label, string.format(P.MONITOR, #G.conns, REG.pending(), math.floor(REG.qMax)) .. " · " ..
        string.format("%.2f ms", PERF.renderMs))
    row(STR.MSG.INTERNAL, tostring(G.internalErrors), G.internalErrors > 0 and U.trunc(U.oneLine(G.lastInternalError), 150) or P.INTERNAL_NONE,
        function() UI.detail(string.format(STR.ERRORS_TITLE, CONFIG.MAX_ERRORS), UI.errorsText()) end, G.internalErrors > 0 and TH.bad or TH.ok)
    row(P.INFO, "", P.INFO_SUB, function() UI.detail(STR.NOTES_TITLE, STR.PERF_NOTES) end)
    UI.lists.PERFORMANCE.set(items)
end

---------------- Cromo común (barra de título, lateral, tarjetas, feed, estado): se refresca siempre que se dibuja
function UI.renderChrome()
    -- Barra de título
    local feedOn = FEED.remote ~= nil
    W.pillDot.BackgroundColor3 = feedOn and TH.ok or TH.dotOff
    W.pillText.Text = not feedOn and STR.UI.FEED_PILL_NONE or
        string.format((FEED.serverMode ~= nil and FEED.label(FEED.serverMode) == FEED.label()) and STR.UI.FEED_PILL or STR.UI.FEED_PILL_PENDING, U.esc(FEED.label()))
    W.scaleBtn.Text = UI.scaleLabel()
    -- Lateral
    local counts = {REMOTES = #REG.remotes, TOOLS = #REG.tools, BUTTONS = #REG.buttons, LOGS = LOG.total}
    for name, t in pairs(SIDE.tabs) do
        local on = name == UI.tab
        t.b.BackgroundTransparency = on and 0 or 1
        t.bar.Visible = on
        t.name.TextColor3 = on and TH.cyan or TH.dim
        setFont(t.name, on and FONT.semi or FONT.sans)
        t.count.Text = counts[name] and fmtInt(counts[name]) or ""
        t.count.TextColor3 = on and TH.cyan or TH.dim
    end
    local segOn = FEED.filter == "all" and 1 or (FEED.filter == "me" and 2 or 3)
    for i, b in ipairs(SIDE.seg) do
        b.BackgroundTransparency = (i == segOn) and 0 or 1
        b.TextColor3 = (i == segOn) and TH.cyan or TH.dim
        if i == 3 then b.Text = (segOn == 3) and FEED.label() or STR.UI.SEG[3] end
    end
    for i, m in ipairs(SIDE.modes) do
        local on = i == MODE.index
        m.b.BackgroundTransparency = on and 0 or 1
        m.st.Transparency = on and 0 or 1
        m.dot.BackgroundColor3 = on and TH.cyan or TH.dotOff
    end
    local yn = function(b) return b and STR.YES or STR.NO end
    local vals = {CAP.executor:match("^(%S+)") or CAP.executor, yn(CAP.setclipboard), yn(CAP.writefile), yn(CAP.writefile ~= nil and CAP.readfile ~= nil)}
    for i, l in ipairs(SIDE.info) do
        l.Text = vals[i]
        l.TextColor3 = (vals[i] == STR.YES) and TH.ok or ((vals[i] == STR.NO) and TH.bad or TH.text)
    end
    -- Tarjetas de métricas
    local U_ = STR.UI
    setMetric(METRIC.fps, fmt(PERF.fps, "%.0f"), string.format(U_.M_FPS_SUB, fmt(PERF.frameAvg * 1000, "%.1f", " ms"), fmt(PERF.lastFrameMax * 1000, "%.0f", " ms")), MODE.def.graph and PERF.hist)
    setMetric(METRIC.ping, fmt(PERF.ping, "%.0f", " ms"), PERF.pingSrc ~= "" and PERF.pingSrc or STR.PERF.PING_NA, MODE.def.graph and PERF.pingHist)
    setMetric(METRIC.mem, fmt(PERF.mem, "%.0f", " MB"), string.format(U_.M_MEM_SUB, fmt(PERF.memScript, "%.0f", " MB"), fmt(PERF.luaHeap, "%.1f", " MB")), MODE.def.graph and PERF.memHist)
    setMetric(METRIC.net, fmt(PERF.recv, "%.1f", " KB/s"), string.format(U_.M_NET_SUB, fmt(PERF.send, "%.1f", " KB/s")), MODE.def.graph and PERF.netHist)
    setMetric(METRIC.eps, string.format("%.1f", PERF.epsNow or 0), string.format(U_.M_EPS_SUB, LOG.suppressed), MODE.def.graph and PERF.eps)
    setMetric(METRIC.console, string.format(U_.M_CONSOLE_VAL, CONSOLE.errors), string.format(U_.M_CONSOLE_SUB, CONSOLE.warnings), MODE.def.graph and PERF.consoleHist)
    -- Feed del servidor
    local sec = FEED.sec
    FC.v1.Text = string.format(U_.FEED_PER_S, sec.lastTotal, CONFIG.FEED_VIEWER_LIMIT)
    FC.bar1(sec.lastTotal / CONFIG.FEED_VIEWER_LIMIT)
    FC.k2.Text = sec.lastTopName and string.format(U_.FEED_SENDER, sec.lastTopName) or U_.FEED_SENDER_NONE
    FC.v2.Text = string.format(U_.FEED_PER_S, sec.lastTop, CONFIG.FEED_SENDER_LIMIT)
    FC.bar2(sec.lastTop / CONFIG.FEED_SENDER_LIMIT)
    FC.v3.Text = tostring(FEED.droppedByServer)
    FC.v4.Text = FEED.modeRemote and FEED.label(FEED.serverMode or FEED.filter) or "—"
    -- Barra de estado
    ST.dot.BackgroundColor3 = LOG.paused and TH.warn or TH.ok
    ST.live.Text = LOG.paused and U_.ST_PAUSED or U_.ST_LIVE
    ST.live.TextColor3 = LOG.paused and TH.warn or TH.ok
    local left = {string.format(U_.ST_REMOTES, #REG.remotes), string.format(U_.ST_LOGS, fmtInt(LOG.total)), string.format(U_.ST_SPAM, LOG.suppressed),
        string.format(U_.ST_QUEUE, REG.pending(), math.floor(REG.qMax)), string.format(U_.ST_ERRORS, G.internalErrors)}
    for i, t in ipairs(ST.left) do t.Text = left[i] end
    local leftCap = MODE.captureLeft()
    local rightTxt = {string.format(U_.ST_MODE, MODE.def.label .. (leftCap and (" " .. leftCap .. "s") or "")), string.format(U_.ST_FPS, PERF.fps),
        string.format(U_.ST_PING, fmt(PERF.ping, "%.0f", " ms")), string.format(U_.ST_VER, "1.2")}
    for i, t in ipairs(ST.right) do t.Text = rightTxt[i] end
end

---------------- Abrir / cerrar / pestañas / escala / minimizar / arrastre
function UI.setTab(name)
    UI.tab = name
    CFG.set("tab", name)
    detail.Visible = false
    picker.Visible = false
    for n, p in pairs(UI.pages) do p.Visible = (n == name) end
    UI.force = true
end
for name, t in pairs(SIDE.tabs) do U.conn(t.b.Activated, function() UI.setTab(name) end, "pestaña " .. name) end

function UI.scaleLabel(sc) return string.format(STR.UI.SCALE, math.floor((sc or UI.scale()) * 100 + 0.5)) end

local function fitsScreen()
    local ss, sc = screenSize(), UI.scale()
    local h = UI.collapsed and L.TITLE_H or L.PANEL_H
    return L.PANEL_W * sc <= ss.X and h * sc <= ss.Y, ss, sc, h
end

-- Coloca el panel: si cabe, se arrastra y queda dentro de la pantalla; si no,
-- el visor permite recorrerlo con un dedo (tamaño exacto, sin recortes).
function UI.applyLayout()
    local fits, ss, sc, h = fitsScreen()
    panel.Size = UDim2.fromOffset(L.PANEL_W, h)
    sidebar.Visible, main.Visible, right.Visible, statusBar.Visible = not UI.collapsed, not UI.collapsed, not UI.collapsed, not UI.collapsed
    local pw, ph = L.PANEL_W * sc, h * sc
    local margin = CONFIG.L.RADIUS
    local x, y
    if pw <= ss.X then x = math.clamp(CFG.get("x", (ss.X - pw) / 2), 0, ss.X - pw) else x = margin end
    if ph <= ss.Y then y = math.clamp(CFG.get("y", (ss.Y - ph) / 2), 0, ss.Y - ph) else y = margin end
    panel.Position = UDim2.fromOffset(math.floor(x), math.floor(y))
    viewport.CanvasSize = UDim2.fromOffset(pw > ss.X and (pw + 2 * margin) or 0, ph > ss.Y and (ph + 2 * margin) or 0)
    viewport.ScrollingEnabled = not fits
    viewport.Active = not fits
    panel.Active = fits -- si no cabe, el arrastre sobre el panel desplaza el visor
    pcall(function()
        local f = fab
        local fs = f.AbsoluteSize
        f.Position = UDim2.fromOffset(math.clamp(f.Position.X.Offset, 0, math.max(0, ss.X - fs.X)), math.clamp(f.Position.Y.Offset, 0, math.max(0, ss.Y - fs.Y)))
    end)
end

function UI.cycleScale()
    local cur, nextS = UI.scale(), CONFIG.SCALES[1]
    for i, v in ipairs(CONFIG.SCALES) do if math.abs(v - cur) < 0.01 then nextS = CONFIG.SCALES[i % #CONFIG.SCALES + 1] end end
    uiScale.Scale = nextS
    CFG.set("scale", nextS)
    UI.applyLayout()
    UI.force = true
    return nextS
end
U.conn(W.scaleBtn.Activated, function() W.scaleBtn.Text = UI.scaleLabel(UI.cycleScale()) end, "escala")

function UI.toggle(state)
    if state == nil then state = not UI.open end
    UI.open = state
    viewport.Visible = state
    if state then UI.applyLayout(); UI.force = true end
end
U.conn(closeBtn.Activated, function() UI.toggle(false) end, "cerrar")
U.conn(minBtn.Activated, function() UI.collapsed = not UI.collapsed; UI.applyLayout() end, "minimizar")

local function isPress(input)
    local t = input.UserInputType
    return t == Enum.UserInputType.Touch or t == Enum.UserInputType.MouseButton1
end
local function isMove(input)
    local t = input.UserInputType
    return t == Enum.UserInputType.Touch or t == Enum.UserInputType.MouseMovement
end
local function draggable(handle, target, canDrag, onTap, onEnd)
    local dragging, startPos, startUD, moved = false, nil, nil, false
    U.conn(handle.InputBegan, function(input)
        if not isPress(input) or not canDrag() then return end
        dragging, moved, startPos, startUD = true, false, input.Position, target.Position
        local c
        c = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                if c then c:Disconnect() end
                dragging = false
                if moved and onEnd then onEnd() end
            end
        end)
    end, "arrastre")
    U.conn(S.UIS.InputChanged, function(input)
        if not dragging or not isMove(input) then return end
        local d = input.Position - startPos
        if math.abs(d.X) + math.abs(d.Y) > CONFIG.DRAG_THRESHOLD then moved = true end
        if not moved then return end
        local ss, fs = screenSize(), target.AbsoluteSize
        target.Position = UDim2.fromOffset(math.clamp(startUD.X.Offset + d.X, 0, math.max(0, ss.X - fs.X)),
            math.clamp(startUD.Y.Offset + d.Y, 0, math.max(0, ss.Y - fs.Y)))
    end, "arrastre mover")
    if onTap then U.conn(handle.Activated, function() if not moved then onTap() end moved = false end, "toque") end
end
local function saveGeometry()
    pcall(function()
        CFG.set("fabX", fab.Position.X.Offset); CFG.set("fabY", fab.Position.Y.Offset)
        if fitsScreen() then CFG.set("x", panel.Position.X.Offset); CFG.set("y", panel.Position.Y.Offset) end
    end)
end
draggable(fab, fab, function() return true end, function() UI.toggle() end, saveGeometry)
draggable(titleBar, panel, function() return (fitsScreen()) end, nil, saveGeometry)
U.conn(screen:GetPropertyChangedSignal("AbsoluteSize"), UI.applyLayout, "giro de pantalla")
task.defer(UI.applyLayout)
