
-------------------------------------------------------------------------------
-- 9. UI — componentes (tema, panel, arrastre, lista virtual, detalle, selector)
-------------------------------------------------------------------------------
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

local UI = {tab = "MAIN", open = false, pages = {}, lists = {}, force = false, collapsed = false, controls = {}}

local function mk(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do pcall(function() o[k] = v end) end
    if parent then o.Parent = parent end
    return o
end
local function corner(o, r) return mk("UICorner", {CornerRadius = UDim.new(0, r or 8)}, o) end
local function stroke(o, c, t, tr) return mk("UIStroke", {Color = c or TH.line, Thickness = t or 1, Transparency = tr or 0}, o) end
local function pad(o, p) return mk("UIPadding", {PaddingLeft = UDim.new(0, p), PaddingRight = UDim.new(0, p), PaddingTop = UDim.new(0, p), PaddingBottom = UDim.new(0, p)}, o) end
local function rich(hex, s) return '<font color="' .. hex .. '">' .. U.esc(s) .. '</font>' end
local function hexColor(hex, fallback) return (Color3.fromHex and Color3.fromHex(hex)) or fallback or TH.cyan end
local function isPress(input)
    local t = input.UserInputType
    return t == Enum.UserInputType.Touch or t == Enum.UserInputType.MouseButton1
end
local function isMove(input)
    local t = input.UserInputType
    return t == Enum.UserInputType.Touch or t == Enum.UserInputType.MouseMovement
end
local function onRelease(input, fn)
    local c
    c = input.Changed:Connect(function()
        if input.UserInputState == Enum.UserInputState.End then
            if c then c:Disconnect() end
            fn()
        end
    end)
end

---------------- Padre de la GUI: gethui → CoreGui → PlayerGui
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
pcall(function() screen.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets end) -- notch y barra inferior
REG.guiRoot = screen
screen.Parent = parentGui

local vp = Vector2.new(844, 390)
pcall(function() vp = workspace.CurrentCamera.ViewportSize end)
local function screenSize()
    local ok, s2 = pcall(function() return screen.AbsoluteSize end)
    if ok and s2 and s2.X and s2.X > 0 then return s2 end
    return vp
end

---------------- Geometría del panel (tamaño sin escala; la escala la aplica UIScale)
local GEOM = {}
GEOM.w = math.floor(math.clamp(CFG.get("w", vp.X * CONFIG.PANEL_VP_W), CONFIG.PANEL_MIN_W, math.max(CONFIG.PANEL_MIN_W, vp.X - CONFIG.SCREEN_PAD)))
GEOM.h = math.floor(math.clamp(CFG.get("h", vp.Y * CONFIG.PANEL_VP_H), CONFIG.PANEL_MIN_H, math.max(CONFIG.PANEL_MIN_H, vp.Y - CONFIG.SCREEN_PAD)))
GEOM.bodyTop = CONFIG.HEADER_H + CONFIG.GAP + CONFIG.TAB_BAR_H + CONFIG.GAP
GEOM.bodyBottom = CONFIG.FOOTER_H + CONFIG.MARGIN

-- Mantiene un marco dentro de la pantalla (posición en píxeles).
local function clampFrame(f)
    pcall(function()
        local ss, fs, p = screenSize(), f.AbsoluteSize, f.Position
        local x = math.clamp(p.X.Offset + p.X.Scale * ss.X, 0, math.max(0, ss.X - fs.X))
        local y = math.clamp(p.Y.Offset + p.Y.Scale * ss.Y, 0, math.max(0, ss.Y - fs.Y))
        f.Position = UDim2.fromOffset(math.floor(x), math.floor(y))
    end)
end

---------------- Arrastre táctil
local function draggable(handle, target, onTap, onEnd)
    local dragging, startPos, startUD, moved = false, nil, nil, false
    U.conn(handle.InputBegan, function(input)
        if not isPress(input) then return end
        dragging, moved = true, false
        startPos, startUD = input.Position, target.Position
        onRelease(input, function()
            dragging = false
            clampFrame(target)
            if moved and onEnd then onEnd() end
        end)
    end, "arrastre inicio")
    U.conn(S.UIS.InputChanged, function(input)
        if not dragging or not isMove(input) then return end
        local d = input.Position - startPos
        if math.abs(d.X) + math.abs(d.Y) > CONFIG.DRAG_THRESHOLD then moved = true end
        if moved then
            target.Position = UDim2.new(startUD.X.Scale, startUD.X.Offset + d.X, startUD.Y.Scale, startUD.Y.Offset + d.Y)
            clampFrame(target)
        end
    end, "arrastre")
    if onTap then
        U.conn(handle.Activated, function()
            if not moved then onTap() end
            moved = false
        end, "toque")
    end
end

---------------- Botón flotante
local fab = mk("TextButton", {Name = "Fab", Size = UDim2.fromOffset(CONFIG.FAB_SIZE, CONFIG.FAB_SIZE),
    Position = UDim2.fromOffset(CFG.get("fabX", vp.X - CONFIG.FAB_SIZE - 16), CFG.get("fabY", math.floor(vp.Y * 0.3))),
    BackgroundColor3 = TH.panel, Text = STR.FAB, TextColor3 = TH.text, Font = Enum.Font.GothamBlack, TextSize = 15,
    AutoButtonColor = false, ZIndex = 50}, screen)
corner(fab, CONFIG.FAB_SIZE / 2)
stroke(fab, TH.cyan, 2)
mk("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(0, 120, 160), Color3.fromRGB(90, 40, 170)), Rotation = 45}, fab)
local fabDot = mk("Frame", {Size = UDim2.fromOffset(12, 12), Position = UDim2.new(1, -14, 0, 2), BackgroundColor3 = TH.ok, ZIndex = 51}, fab)
corner(fabDot, 6)

---------------- Panel
local panel = mk("Frame", {Name = "Panel", Size = UDim2.fromOffset(GEOM.w, GEOM.h),
    Position = UDim2.fromOffset(CFG.get("x", math.floor((vp.X - GEOM.w) / 2)), CFG.get("y", math.floor((vp.Y - GEOM.h) / 2))),
    BackgroundColor3 = TH.bg, Visible = false, ZIndex = 10, Active = true}, screen)
corner(panel, 14)
stroke(panel, TH.cyan, 1.5, 0.2)
mk("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(205, 200, 255)), Rotation = 90}, panel)
local uiScale = mk("UIScale", {Scale = CFG.get("scale", 1)}, panel)
function UI.scale() return (uiScale.Scale and uiScale.Scale > 0) and uiScale.Scale or 1 end

local header = mk("TextButton", {Size = UDim2.new(1, 0, 0, CONFIG.HEADER_H), BackgroundColor3 = TH.panel, Text = "", AutoButtonColor = false, ZIndex = 11}, panel)
corner(header, 14)
mk("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(0, 70, 95), Color3.fromRGB(55, 25, 105)), Rotation = 0}, header)
local statusDot = mk("Frame", {Size = UDim2.fromOffset(10, 10), Position = UDim2.new(0, 12, 0.5, -5), BackgroundColor3 = TH.ok, ZIndex = 12}, header)
corner(statusDot, 5)
mk("TextLabel", {Size = UDim2.new(1, -(2 * CONFIG.TOUCH + 52), 1, 0), Position = UDim2.fromOffset(30, 0), BackgroundTransparency = 1,
    RichText = true, Text = STR.TITLE, TextColor3 = TH.text, Font = Enum.Font.GothamBold, TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 12}, header)
local function headBtn(txt, slot, color)
    local w = CONFIG.TOUCH + 2
    local b = mk("TextButton", {Size = UDim2.fromOffset(w, CONFIG.TOUCH), Position = UDim2.new(1, -(w + 6) * slot, 0.5, -CONFIG.TOUCH / 2),
        BackgroundColor3 = TH.card2, Text = txt, TextColor3 = color or TH.text, Font = Enum.Font.GothamBold, TextSize = 16, ZIndex = 12}, header)
    corner(b, 8)
    return b
end
local closeBtn = headBtn(STR.CLOSE, 1, TH.bad)
local minBtn = headBtn(STR.MIN, 2)

local tabBar = mk("ScrollingFrame", {Size = UDim2.new(1, -2 * CONFIG.MARGIN, 0, CONFIG.TAB_BAR_H),
    Position = UDim2.fromOffset(CONFIG.MARGIN, CONFIG.HEADER_H + CONFIG.GAP), BackgroundTransparency = 1,
    ScrollBarThickness = 0, ScrollingDirection = Enum.ScrollingDirection.X, AutomaticCanvasSize = Enum.AutomaticSize.X,
    CanvasSize = UDim2.new(0, 0, 0, 0), ZIndex = 11}, panel)
mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, tabBar)

local body = mk("Frame", {Size = UDim2.new(1, -2 * CONFIG.MARGIN, 1, -(GEOM.bodyTop + GEOM.bodyBottom)), Position = UDim2.fromOffset(CONFIG.MARGIN, GEOM.bodyTop),
    BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 11}, panel)
local footer = mk("TextLabel", {Size = UDim2.new(1, -(CONFIG.TOUCH + 16), 0, CONFIG.FOOTER_H), Position = UDim2.new(0, 10, 1, -(CONFIG.FOOTER_H + 4)),
    BackgroundTransparency = 1, Text = "", RichText = true, TextColor3 = TH.dim, Font = Enum.Font.Gotham, TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 11}, panel)

---------------- Aviso breve
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
    task.delay(CONFIG.TOAST_SEC, function() if my == toastSeq then toastLbl.Visible = false end end)
end

---------------- Pestañas (marcos)
local tabButtons = {}
for i, name in ipairs(STR.TABS) do
    local b = mk("TextButton", {Size = UDim2.fromOffset(name == "PERFORMANCE" and CONFIG.TAB_W_WIDE or CONFIG.TAB_W, CONFIG.TOUCH),
        BackgroundColor3 = TH.card, Text = name, TextColor3 = TH.dim, Font = Enum.Font.GothamBold, TextSize = 12, LayoutOrder = i,
        ZIndex = 12, AutoButtonColor = false}, tabBar)
    corner(b, 9)
    tabButtons[name] = b
    UI.pages[name] = mk("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, ZIndex = 11}, body)
end

---------------- Barra de herramientas
function UI.toolbar(page)
    local bar = mk("ScrollingFrame", {Size = UDim2.new(1, 0, 0, CONFIG.TOOLBAR_H), BackgroundTransparency = 1, ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.X, AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new(0, 0, 0, 0), ZIndex = 12}, page)
    mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center}, bar)
    local tb = {bar = bar, n = 0}
    function tb.search(placeholder, w)
        tb.n = tb.n + 1
        local box = mk("TextBox", {Size = UDim2.fromOffset(w or 150, CONFIG.TOUCH), BackgroundColor3 = TH.card, Text = "", PlaceholderText = placeholder,
            PlaceholderColor3 = TH.dim, TextColor3 = TH.text, Font = Enum.Font.Gotham, TextSize = 13, ClearTextOnFocus = false,
            TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = tb.n, ZIndex = 12}, bar)
        corner(box, 8); stroke(box, TH.cyan, 1, 0.55); pad(box, 8)
        return box
    end
    function tb.button(text, fn, color, w)
        tb.n = tb.n + 1
        local b = mk("TextButton", {Size = UDim2.fromOffset(w or 78, CONFIG.TOUCH), BackgroundColor3 = TH.card2, Text = text,
            TextColor3 = color or TH.text, Font = Enum.Font.GothamBold, TextSize = 12, LayoutOrder = tb.n, ZIndex = 12}, bar)
        corner(b, 8); stroke(b, TH.violet, 1, 0.6)
        if fn then U.conn(b.Activated, function() fn(b) end, "botón " .. text) end
        return b
    end
    return tb
end

-- Botones que aparecen en varias pestañas (Modo, Jugadores): se re-etiquetan juntos.
function UI.addControl(kind, button) UI.controls[#UI.controls + 1] = {kind = kind, b = button} end
function UI.refreshControls(labels)
    for _, c in ipairs(UI.controls) do
        local txt = labels[c.kind]
        if txt and c.b.Text ~= txt then c.b.Text = txt end
    end
end

---------------- Lista VIRTUAL: solo existen las filas visibles (+CONFIG.ROW_SPARE)
function UI.list(parent, top)
    local sf = mk("ScrollingFrame", {Size = UDim2.new(1, 0, 1, -top), Position = UDim2.fromOffset(0, top),
        BackgroundColor3 = TH.panel, BackgroundTransparency = 0.15, ScrollBarThickness = 6, ScrollBarImageColor3 = TH.cyan,
        AutomaticCanvasSize = Enum.AutomaticSize.None, CanvasSize = UDim2.new(0, 0, 0, 0), ScrollingDirection = Enum.ScrollingDirection.Y,
        ElasticBehavior = Enum.ElasticBehavior.Always, ZIndex = 11}, parent)
    corner(sf, 10)
    local L = {sf = sf, rows = {}, n = 0, get = nil, cache = {}}
    function L.item(i)
        local it = L.cache[i]
        if it == nil and L.get then
            it = L.get(i)
            L.cache[i] = it
        end
        return it
    end
    local function makeRow(k)
        local row = mk("TextButton", {Size = UDim2.new(1, -14, 0, CONFIG.ROW_H - CONFIG.ROW_GAP), BackgroundColor3 = TH.card, Text = "",
            AutoButtonColor = true, ZIndex = 12, Visible = false}, sf)
        corner(row, 8)
        local bar = mk("Frame", {Size = UDim2.new(0, 3, 1, -14), Position = UDim2.fromOffset(5, 7), BackgroundColor3 = TH.cyan, BorderSizePixel = 0, ZIndex = 13}, row)
        local t1 = mk("TextLabel", {Size = UDim2.new(1, -22, 0, 22), Position = UDim2.fromOffset(15, 5), BackgroundTransparency = 1, RichText = true,
            TextColor3 = TH.text, Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 13}, row)
        local t2 = mk("TextLabel", {Size = UDim2.new(1, -22, 0, 18), Position = UDim2.fromOffset(15, 28), BackgroundTransparency = 1, RichText = true,
            TextColor3 = TH.dim, Font = Enum.Font.Code, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 13}, row)
        local r = {btn = row, bar = bar, t1 = t1, t2 = t2, idx = 0}
        U.conn(row.Activated, function()
            local it = L.item(r.idx)
            if it and it.onTap then it.onTap() end
        end, "fila")
        L.rows[k] = r
        return r
    end
    local function viewHeight()
        -- AbsoluteWindowSize está en píxeles de pantalla (ya escalados): se pasa a unidades de la lista.
        local h = nil
        pcall(function() h = sf.AbsoluteWindowSize.Y end)
        if not h or h <= 0 then h = GEOM.h end
        return h / UI.scale()
    end
    function L.draw()
        local scrollY = 0
        pcall(function() scrollY = sf.CanvasPosition.Y end)
        local first = math.max(1, math.floor(scrollY / CONFIG.ROW_H) + 1)
        local need = math.ceil(viewHeight() / CONFIG.ROW_H) + CONFIG.ROW_SPARE
        for k = 1, need do
            local r = L.rows[k] or makeRow(k)
            local i = first + k - 1
            if i <= L.n then
                local it = L.item(i)
                r.idx = i
                r.btn.Position = UDim2.fromOffset(6, (i - 1) * CONFIG.ROW_H + 6)
                r.btn.Visible = true
                if r.t1.Text ~= it.title then r.t1.Text = it.title end
                local sub = it.sub or ""
                if r.t2.Text ~= sub then r.t2.Text = sub end
                r.bar.BackgroundColor3 = it.color or TH.cyan
            else
                r.btn.Visible = false
                r.idx = 0
            end
        end
        for k = need + 1, #L.rows do L.rows[k].btn.Visible = false; L.rows[k].idx = 0 end
    end
    function L.setLazy(n, get)
        local cap = MODE.def.maxRows
        if cap and n > cap then n = cap end
        L.n, L.get, L.cache = n, get, {}
        sf.CanvasSize = UDim2.new(0, 0, 0, n * CONFIG.ROW_H + 12)
        L.draw()
    end
    function L.set(items) L.setLazy(#items, function(i) return items[i] end) end
    function L.all()
        local out = {}
        for i = 1, L.n do out[#out + 1] = L.item(i) end
        return out
    end
    U.conn(sf:GetPropertyChangedSignal("CanvasPosition"), L.draw, "scroll lista")
    U.conn(sf:GetPropertyChangedSignal("AbsoluteWindowSize"), L.draw, "tamaño lista")
    return L
end

---------------- Detalle (texto largo seleccionable, en bloques)
local detail = mk("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = TH.bg, Visible = false, ZIndex = 30, Active = true}, body)
corner(detail, 10); stroke(detail, TH.violet, 1.2)
local detailTitle = mk("TextLabel", {Size = UDim2.new(1, -262, 0, CONFIG.TOUCH), Position = UDim2.fromOffset(10, 3), BackgroundTransparency = 1, RichText = true,
    TextColor3 = TH.cyan, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 31}, detail)
local function dBtn(txt, right, w, color)
    local b = mk("TextButton", {Size = UDim2.fromOffset(w, CONFIG.TOUCH), Position = UDim2.new(1, -right, 0, 3), BackgroundColor3 = TH.card2, Text = txt,
        TextColor3 = color or TH.text, Font = Enum.Font.GothamBold, TextSize = 12, ZIndex = 31}, detail)
    corner(b, 8)
    return b
end
local dClose = dBtn(STR.CLOSE_BTN, 76, 70, TH.bad)
local dCopy = dBtn(STR.COPY, 152, 70, TH.cyan)
local dExtra = dBtn("", 250, 92, TH.violet)
local dScroll = mk("ScrollingFrame", {Size = UDim2.new(1, -12, 1, -(CONFIG.TOUCH + 12)), Position = UDim2.fromOffset(6, CONFIG.TOUCH + 6), BackgroundColor3 = TH.panel,
    ScrollBarThickness = 5, ScrollBarImageColor3 = TH.violet, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0, 0, 0, 0),
    ZIndex = 31}, detail)
corner(dScroll, 8); pad(dScroll, 8)
mk("UIListLayout", {Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder}, dScroll)
local DET = {chunks = {}, text = "", extraFn = nil}

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
    detailTitle.Text = U.esc(title or STR.DETAIL)
    dExtra.Visible = extraLabel ~= nil
    dExtra.Text = extraLabel or ""
    local shown = DET.text
    if #shown > CONFIG.DETAIL_MAX then shown = shown:sub(1, CONFIG.DETAIL_MAX) .. STR.DETAIL_CUT end
    local parts = chunkText(shown)
    for idx, part in ipairs(parts) do
        local box = DET.chunks[idx]
        if not box then
            box = mk("TextBox", {Size = UDim2.new(1, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
                TextColor3 = TH.text, Font = Enum.Font.Code, TextSize = 12, TextWrapped = true, MultiLine = true, ClearTextOnFocus = false,
                TextEditable = false, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
                LayoutOrder = idx, ZIndex = 32}, dScroll)
            DET.chunks[idx] = box
        end
        box.Text = part
        box.Visible = true
    end
    for i = #parts + 1, #DET.chunks do DET.chunks[i].Visible = false; DET.chunks[i].Text = "" end
    dScroll.CanvasPosition = Vector2.new(0, 0)
    detail.Visible = true
end
U.conn(dClose.Activated, function() detail.Visible = false end, "cerrar detalle")
U.conn(dCopy.Activated, function() UI.copyOrShow(STR.DETAIL, DET.text) end, "copiar detalle")
U.conn(dExtra.Activated, function() if DET.extraFn then DET.extraFn() end end, "acción detalle")

function UI.copyOrShow(title, text)
    if U.copy(text) then
        UI.toast(string.format(STR.COPIED, #text))
    else
        UI.toast(STR.NO_CLIPBOARD)
        UI.detail(title, text)
    end
end

---------------- Selector (lista de opciones a pantalla completa del cuerpo)
local picker = mk("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = TH.bg, Visible = false, ZIndex = 34, Active = true}, body)
corner(picker, 10); stroke(picker, TH.cyan, 1.2)
local pickerTitle = mk("TextLabel", {Size = UDim2.new(1, -100, 0, CONFIG.TOUCH), Position = UDim2.fromOffset(10, 3), BackgroundTransparency = 1,
    TextColor3 = TH.cyan, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 35}, picker)
local pickerClose = mk("TextButton", {Size = UDim2.fromOffset(70, CONFIG.TOUCH), Position = UDim2.new(1, -76, 0, 3), BackgroundColor3 = TH.card2,
    Text = STR.CLOSE_BTN, TextColor3 = TH.bad, Font = Enum.Font.GothamBold, TextSize = 12, ZIndex = 35}, picker)
corner(pickerClose, 8)
local pickerList = UI.list(picker, CONFIG.TOUCH + 8)
pickerList.sf.ZIndex = 35
U.conn(pickerClose.Activated, function() picker.Visible = false end, "cerrar selector")
-- options = {{title=, sub=, onPick=fn}, ...}
function UI.pick(title, options)
    pickerTitle.Text = title
    local items = {}
    for i, o in ipairs(options) do
        items[i] = {title = o.title, sub = o.sub, color = TH.cyan, onTap = function()
            picker.Visible = false
            o.onPick()
            UI.force = true
        end}
    end
    picker.Visible = true
    pickerList.set(items)
end

---------------- Abrir / cerrar / pestañas
function UI.setTab(name)
    UI.tab = name
    CFG.set("tab", name)
    detail.Visible = false
    picker.Visible = false
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
    U.conn(b.Activated, function() UI.setTab(name) end, "pestaña " .. name)
end

function UI.toggle(state)
    if state == nil then state = not UI.open end
    UI.open = state
    panel.Visible = state
    if state then UI.force = true end
end

local function saveGeometry()
    pcall(function()
        CFG.set("fabX", fab.Position.X.Offset); CFG.set("fabY", fab.Position.Y.Offset)
        CFG.set("x", panel.Position.X.Offset); CFG.set("y", panel.Position.Y.Offset)
        CFG.set("w", GEOM.w); CFG.set("h", GEOM.h)
    end)
end
draggable(fab, fab, function() UI.toggle() end, saveGeometry)
draggable(header, panel, nil, saveGeometry)
U.conn(closeBtn.Activated, function() UI.toggle(false) end, "cerrar panel")

---------------- Tamaño: minimizado, giro de pantalla y esquina de redimensionar
local grip = mk("TextButton", {Size = UDim2.fromOffset(CONFIG.TOUCH, CONFIG.TOUCH), Position = UDim2.new(1, -CONFIG.TOUCH, 1, -CONFIG.TOUCH),
    BackgroundTransparency = 1, Text = STR.GRIP, TextColor3 = TH.cyan, TextTransparency = 0.3, Font = Enum.Font.GothamBold, TextSize = 18,
    ZIndex = 25, TextXAlignment = Enum.TextXAlignment.Right, TextYAlignment = Enum.TextYAlignment.Bottom}, panel)

-- Ajusta GEOM a la pantalla actual y aplica el tamaño respetando "minimizado".
function UI.applySize()
    local ss, sc = screenSize(), UI.scale()
    GEOM.w = math.floor(math.clamp(GEOM.w, CONFIG.PANEL_MIN_W, math.max(CONFIG.PANEL_MIN_W, ss.X / sc - CONFIG.SCREEN_PAD)))
    GEOM.h = math.floor(math.clamp(GEOM.h, CONFIG.PANEL_MIN_H, math.max(CONFIG.PANEL_MIN_H, ss.Y / sc - CONFIG.SCREEN_PAD)))
    local h = UI.collapsed and CONFIG.HEADER_H or GEOM.h
    panel.Size = UDim2.fromOffset(GEOM.w, h)
    tabBar.Visible, body.Visible, footer.Visible, grip.Visible = not UI.collapsed, not UI.collapsed, not UI.collapsed, not UI.collapsed
    clampFrame(panel)
    clampFrame(fab)
end

U.conn(minBtn.Activated, function()
    UI.collapsed = not UI.collapsed
    UI.applySize()
end, "minimizar")

do
    local resizing, startPos, startW, startH = false, nil, 0, 0
    U.conn(grip.InputBegan, function(input)
        if not isPress(input) then return end
        resizing, startPos, startW, startH = true, input.Position, GEOM.w, GEOM.h
        onRelease(input, function()
            resizing = false
            saveGeometry()
        end)
    end, "redimensionar inicio")
    U.conn(S.UIS.InputChanged, function(input)
        if not resizing or not isMove(input) then return end
        local d = input.Position - startPos
        local ss, sc = screenSize(), UI.scale()
        local maxW = (ss.X - panel.Position.X.Offset) / sc
        local maxH = (ss.Y - panel.Position.Y.Offset) / sc
        GEOM.w = math.floor(math.clamp(startW + d.X / sc, CONFIG.PANEL_MIN_W, math.max(CONFIG.PANEL_MIN_W, maxW)))
        GEOM.h = math.floor(math.clamp(startH + d.Y / sc, CONFIG.PANEL_MIN_H, math.max(CONFIG.PANEL_MIN_H, maxH)))
        panel.Size = UDim2.fromOffset(GEOM.w, GEOM.h)
    end, "redimensionar")
end

function UI.scaleLabel(sc) return string.format(STR.BTN_SCALE, math.floor((sc or UI.scale()) * 100 + 0.5)) end

function UI.cycleScale()
    local cur, nextS = UI.scale(), CONFIG.SCALES[1]
    for i, v in ipairs(CONFIG.SCALES) do
        if math.abs(v - cur) < 0.01 then nextS = CONFIG.SCALES[i % #CONFIG.SCALES + 1] end
    end
    uiScale.Scale = nextS
    CFG.set("scale", nextS)
    UI.applySize()
    for _, L in pairs(UI.lists) do pcall(L.draw) end
    return nextS
end

U.conn(screen:GetPropertyChangedSignal("AbsoluteSize"), UI.applySize, "giro de pantalla")
task.defer(UI.applySize)
