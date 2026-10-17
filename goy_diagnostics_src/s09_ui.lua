
-------------------------------------------------------------------------------
-- 9. UI — componentes del diseño "Pro" (medidas exactas en CONFIG.L)
-------------------------------------------------------------------------------
-- Versión: "pc" (diseño exacto de la foto, como panel de computadora) o "mobile" (compacta).
local LAYOUT = CFG.get("layout", CONFIG.LAYOUT_DEFAULT)
if LAYOUT ~= "pc" and LAYOUT ~= "mobile" then
    local touch, keys = false, false
    pcall(function() touch, keys = S.UIS.TouchEnabled, S.UIS.KeyboardEnabled end)
    LAYOUT = (touch and not keys) and "mobile" or "pc"
end
local IS_PC = LAYOUT == "pc"
local L = IS_PC and CONFIG.L or CONFIG.LM
local TweenService = svc("TweenService")
local TH = {
    outside = Color3.fromRGB(5, 6, 11), bg = Color3.fromRGB(9, 12, 19), bar = Color3.fromRGB(16, 18, 31),
    side = Color3.fromRGB(12, 14, 27), card = Color3.fromRGB(21, 24, 40), border = Color3.fromRGB(42, 46, 70),
    line = Color3.fromRGB(32, 36, 56), rowA = Color3.fromRGB(16, 18, 31), rowB = Color3.fromRGB(18, 21, 36),
    head = Color3.fromRGB(13, 15, 27), sel = Color3.fromRGB(27, 32, 54), chip = Color3.fromRGB(22, 27, 46),
    chipOn = Color3.fromRGB(10, 42, 54), segOn = Color3.fromRGB(18, 58, 74), track = Color3.fromRGB(9, 12, 21),
    code = Color3.fromRGB(9, 12, 19),
    cyan = Color3.fromRGB(0, 220, 255), violet = Color3.fromRGB(166, 115, 255), text = Color3.fromRGB(226, 232, 245),
    dim = Color3.fromRGB(140, 150, 175), faint = Color3.fromRGB(94, 102, 128), ok = Color3.fromRGB(70, 230, 140),
    warn = Color3.fromRGB(255, 200, 70), bad = Color3.fromRGB(255, 90, 110), blue = Color3.fromRGB(111, 168, 255),
    pink = Color3.fromRGB(255, 122, 217), dotOff = Color3.fromRGB(60, 64, 96),
    red = Color3.fromRGB(255, 95, 87), yellow = Color3.fromRGB(254, 188, 46), green = Color3.fromRGB(40, 200, 64),
    btnRed = Color3.fromRGB(46, 15, 33), btnGreen = Color3.fromRGB(14, 38, 30), btnViolet = Color3.fromRGB(30, 22, 52),
}
local HEX = {cyan = "#00DCFF", violet = "#A673FF", dim = "#8C96AF", ok = "#46E68C", warn = "#FFC846",
    bad = "#FF5A6E", text = "#E2E8F5", pink = "#FF7AD9", blue = "#6FA8FF"}
-- Insignias de categoría: color del texto y del fondo.
local CAT_STYLE = {
    Servidor = {TH.ok, Color3.fromRGB(20, 52, 38)}, Remote = {TH.cyan, Color3.fromRGB(8, 46, 60)},
    Spam = {TH.warn, Color3.fromRGB(56, 44, 16)}, Valor = {TH.blue, Color3.fromRGB(24, 38, 68)},
    Tool = {TH.warn, Color3.fromRGB(56, 44, 16)}, Consola = {TH.bad, Color3.fromRGB(58, 20, 32)},
    Cambio = {TH.pink, Color3.fromRGB(58, 24, 56)}, ["Botón"] = {TH.violet, Color3.fromRGB(40, 30, 74)},
    Bindable = {TH.ok, Color3.fromRGB(20, 52, 38)}, Instancia = {TH.dim, Color3.fromRGB(30, 34, 52)},
    Sistema = {TH.text, Color3.fromRGB(34, 38, 58)},
    RemoteEvent = {TH.cyan, Color3.fromRGB(8, 46, 60)}, UnreliableRemoteEvent = {TH.blue, Color3.fromRGB(24, 38, 68)},
    RemoteFunction = {TH.violet, Color3.fromRGB(40, 30, 74)}, BindableEvent = {TH.ok, Color3.fromRGB(20, 52, 38)},
    BindableFunction = {TH.pink, Color3.fromRGB(58, 24, 56)},
}
local BAR_COLORS = {TH.cyan, TH.ok, TH.violet, TH.blue, TH.pink}
local PLAYER_COLORS = {TH.warn, TH.ok, TH.cyan}

local UI = {layout = LAYOUT, tab = "LOGS", open = false, pages = {}, lists = {}, force = false, collapsed = false, controls = {}, sel = nil}

---------------- Fuentes: BuilderSans + RobotoMono (si existen), si no Gotham/Code
local FONT = {}
do
    local function face(family, weight)
        local ok, f = pcall(function() return Font.new("rbxasset://fonts/families/" .. family .. ".json", weight) end)
        return ok and f or nil
    end
    local W = Enum.FontWeight
    FONT.sans = {face("BuilderSans", W.Regular), Enum.Font.Gotham}
    FONT.med = {face("BuilderSans", W.Medium), Enum.Font.GothamMedium}
    FONT.semi = {face("BuilderSans", W.SemiBold), Enum.Font.GothamMedium}
    FONT.bold = {face("BuilderSans", W.Bold), Enum.Font.GothamBold}
    FONT.mono = {face("RobotoMono", W.Regular), Enum.Font.Code}
    FONT.monoMed = {face("RobotoMono", W.Medium), Enum.Font.Code}
end

local function mk(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do pcall(function() o[k] = v end) end
    if parent then o.Parent = parent end
    return o
end
local function corner(o, r) return mk("UICorner", {CornerRadius = UDim.new(0, r or 6)}, o) end
local function stroke(o, c, t) return mk("UIStroke", {Color = c or TH.border, Thickness = t or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, o) end
local function setFont(o, f)
    if f[1] then pcall(function() o.FontFace = f[1] end) else o.Font = f[2] end
end
local function rich(hex, s) return '<font color="' .. hex .. '">' .. U.esc(s) .. '</font>' end

-- Animación suave (TweenService); si no existe, asigna directo.
local function tw(o, props, t, style)
    if TweenService and t and t > 0 then
        local ok = pcall(function()
            TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Sine, Enum.EasingDirection.Out), props):Play()
        end)
        if ok then return end
    end
    for k, v in pairs(props) do pcall(function() o[k] = v end) end
end
-- Solo asigna si cambió (menos trabajo por fotograma = más FPS).
local PUT = setmetatable({}, {__mode = "k"})
local function put(o, k, v)
    local c = PUT[o]
    if not c then c = {}; PUT[o] = c end
    if c[k] == v then return end
    c[k] = v
    o[k] = v
end
-- Respuesta al tocar / pasar el ratón: capa clara encima (como en una app de PC).
local function interact(o, radius)
    local layer = Instance.new("Frame")
    layer.Name = "Hover"
    layer.Size = UDim2.new(1, 0, 1, 0)
    layer.BackgroundColor3 = Color3.new(1, 1, 1)
    layer.BackgroundTransparency = 1
    layer.BorderSizePixel = 0
    layer.ZIndex = (o.ZIndex or 1) + 1
    layer.Active = false
    if radius then local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, radius); c.Parent = layer end
    layer.Parent = o
    local hovering = false
    local function set(tr) tw(layer, {BackgroundTransparency = tr}, CONFIG.ANIM.HOVER) end
    U.conn(o.MouseEnter, function() hovering = true; set(0.94) end, "hover")
    U.conn(o.MouseLeave, function() hovering = false; set(1) end, "hover")
    U.conn(o.InputBegan, function(input)
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then set(0.86) end
    end, "pulsar")
    U.conn(o.InputEnded, function(input)
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then set(hovering and t == Enum.UserInputType.MouseButton1 and 0.94 or 1) end
    end, "soltar")
    return layer
end

-- Marco con fondo, radio y borde opcionales. Coordenadas en unidades del diseño.
local function box(parent, x, y, w, h, color, radius, border, z)
    local f = mk("Frame", {Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = color or TH.card,
        BackgroundTransparency = color and 0 or 1, BorderSizePixel = 0, ZIndex = z or 12}, parent)
    if radius then corner(f, radius) end
    if border then stroke(f, border) end
    return f
end

-- Texto: o = {x, y, w, h, text, size, font, color, align ("L","R","C"), rich, wrap, z, mono}
local function label(parent, o)
    local t = mk("TextLabel", {Position = UDim2.fromOffset(o.x or 0, o.y or 0), Size = UDim2.fromOffset(o.w or 100, o.h or 14),
        BackgroundTransparency = 1, Text = o.text or "", TextSize = o.size or 10.5, TextColor3 = o.color or TH.text,
        RichText = o.rich or false, TextWrapped = o.wrap or false, ZIndex = o.z or 13,
        TextXAlignment = (o.align == "R" and Enum.TextXAlignment.Right) or (o.align == "C" and Enum.TextXAlignment.Center) or Enum.TextXAlignment.Left,
        TextYAlignment = o.top and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
        TextTruncate = o.wrap and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd}, parent)
    setFont(t, o.font or FONT.sans)
    return t
end

-- Botón con estilo de la foto (fondo, borde, texto de color).
local function button(parent, x, y, w, h, text, fg, bg, onTap, size, font)
    local b = mk("TextButton", {Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = bg or TH.chip,
        Text = text, TextColor3 = fg or TH.text, TextSize = size or 11, AutoButtonColor = true, BorderSizePixel = 0, ZIndex = 14}, parent)
    setFont(b, font or FONT.semi)
    corner(b, 6)
    stroke(b, TH.border)
    b.AutoButtonColor = false
    interact(b, 6)
    if onTap then U.conn(b.Activated, function() onTap(b) end, "botón " .. tostring(text)) end
    return b
end

-- Insignia de categoría.
local function badge(parent, x, y, h, text, size)
    local st = CAT_STYLE[text] or CAT_STYLE.Sistema
    local f = box(parent, x, y, 10, h, st[2], 4, nil, 14)
    f.AutomaticSize = Enum.AutomaticSize.X
    mk("UIPadding", {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)}, f)
    local t = label(f, {x = 0, y = 0, w = 0, h = h, text = text, size = size or 9.5, font = FONT.med, color = st[1], z = 15})
    t.AutomaticSize = Enum.AutomaticSize.X
    t.Size = UDim2.new(0, 0, 1, 0)
    return f, t
end
local function setBadge(f, t, text)
    local st = CAT_STYLE[text] or CAT_STYLE.Sistema
    f.BackgroundColor3 = st[2]
    t.Text = text
    t.TextColor3 = st[1]
end

-- Línea entre dos puntos (para mini gráficas).
local function segment(parent, color, z)
    return mk("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = z or 14}, parent)
end
local function placeSegment(f, x1, y1, x2, y2, thick)
    local dx, dy = x2 - x1, y2 - y1
    local len = math.sqrt(dx * dx + dy * dy)
    f.Position = UDim2.fromOffset((x1 + x2) / 2, (y1 + y2) / 2)
    f.Size = UDim2.fromOffset(len + 0.6, thick or 1.4)
    f.Rotation = math.deg((math.atan2 or math.atan)(dy, dx))
end

-- Mini gráfica de línea.
function UI.spark(parent, x, y, w, h, color)
    local holder = box(parent, x, y, w, h, nil, nil, nil, 13)
    local S2 = {segs = {}, w = w, h = h}
    for i = 1, L.SPARK_POINTS - 1 do S2.segs[i] = segment(holder, color, 14) end
    function S2.set(values)
        local n = #values
        local first = math.max(1, n - L.SPARK_POINTS + 1)
        local vmin, vmax = math.huge, -math.huge
        for i = first, n do vmin = math.min(vmin, values[i]); vmax = math.max(vmax, values[i]) end
        if vmax - vmin < 1e-6 then vmin, vmax = vmin - 1, vmax + 1 end
        local pts = {}
        for i = first, n do
            local k = #pts
            pts[k + 1] = {k * (w / (L.SPARK_POINTS - 1)), h - (values[i] - vmin) / (vmax - vmin) * h}
        end
        for i, s in ipairs(S2.segs) do
            local a, b = pts[i], pts[i + 1]
            s.Visible = a ~= nil and b ~= nil
            if s.Visible then
                local dx, dy = b[1] - a[1], b[2] - a[2]
                local props = {Position = UDim2.fromOffset((a[1] + b[1]) / 2, (a[2] + b[2]) / 2),
                    Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy) + 0.6, 1.4), Rotation = math.deg((math.atan2 or math.atan)(dy, dx))}
                if S2.drawn then tw(s, props, CONFIG.ANIM.GRAPH) else for k, v in pairs(props) do s[k] = v end end
            end
        end
    end
    local set = S2.set
    function S2.set(values) set(values); S2.drawn = true end
    return S2
end

-- Barra de progreso horizontal (fondo + relleno).
local function progress(parent, x, y, w, h, color)
    local track = box(parent, x, y, w, h, TH.track, h / 2, nil, 13)
    local fill = box(track, 0, 0, 0, h, color, h / 2, nil, 14)
    return function(frac)
        frac = math.clamp(frac or 0, 0, 1)
        fill.Visible = true
        tw(fill, {Size = UDim2.fromOffset(math.max(frac > 0 and h or 0, w * frac), h)}, CONFIG.ANIM.BAR)
    end
end

-- Borde discontinuo (UIStroke no tiene guiones): segmentos cortos.
local function dashedBorder(f, w, h, color, dash, gap)
    dash, gap = dash or 4, gap or 3
    local function run(x0, y0, len, horiz)
        local p = 0
        while p < len do
            local d = math.min(dash, len - p)
            box(f, horiz and (x0 + p) or x0, horiz and y0 or (y0 + p), horiz and d or 1, horiz and 1 or d, color, nil, nil, 13)
            p = p + dash + gap
        end
    end
    run(4, 0, w - 8, true); run(4, h - 1, w - 8, true); run(0, 4, h - 8, false); run(w - 1, 4, h - 8, false)
end

---------------- Pantalla, visor desplazable y panel
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
pcall(function() screen.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets end)
REG.guiRoot = screen
screen.Parent = parentGui

local vp = Vector2.new(844, 390)
pcall(function() vp = workspace.CurrentCamera.ViewportSize end)
local function screenSize()
    local ok, s2 = pcall(function() return screen.AbsoluteSize end)
    if ok and s2 and s2.X and s2.X > 0 then return s2 end
    return vp
end

-- Si el panel escalado no cabe en la pantalla, se recorre con un dedo (visor).
local viewport = mk("ScrollingFrame", {Name = "Viewport", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 4, ScrollBarImageColor3 = TH.cyan, ScrollingDirection = Enum.ScrollingDirection.XY,
    CanvasSize = UDim2.new(0, 0, 0, 0), ElasticBehavior = Enum.ElasticBehavior.Never, Visible = false, ZIndex = 9}, screen)

local panel = mk("Frame", {Name = "Panel", Size = UDim2.fromOffset(L.PANEL_W, L.PANEL_H), Position = UDim2.fromOffset(0, 0),
    BackgroundColor3 = TH.bg, BorderSizePixel = 0, ZIndex = 10, Active = true}, viewport)
corner(panel, L.RADIUS)
stroke(panel, TH.border)
-- Escala guardada por versión (65 % o 100 %); UI.targetScale es la real (la animación de apertura no la cambia).
UI.targetScale = CFG.get("scale_" .. LAYOUT, IS_PC and CFG.get("scale", 1) or 1)
if UI.targetScale ~= CONFIG.SCALES[1] and UI.targetScale ~= CONFIG.SCALES[2] then UI.targetScale = 1 end
local uiScale = mk("UIScale", {Scale = UI.targetScale}, panel)
function UI.scale() return UI.targetScale end

---------------- Botón flotante
local fab = mk("TextButton", {Name = "Fab", Size = UDim2.fromOffset(L.FAB, L.FAB),
    Position = UDim2.fromOffset(CFG.get("fabX", vp.X - L.FAB - 16), CFG.get("fabY", math.floor(vp.Y * 0.3))),
    BackgroundColor3 = TH.bar, Text = STR.FAB, TextColor3 = TH.text, TextSize = 15, AutoButtonColor = false, ZIndex = 50}, screen)
setFont(fab, FONT.bold)
corner(fab, L.FAB / 2)
stroke(fab, TH.cyan, 2)
local fabDot = box(fab, L.FAB - 14, 2, 12, 12, TH.ok, 6, nil, 51)

---------------- Barra de título
local titleBar = mk("TextButton", {Size = UDim2.fromOffset(L.PANEL_W, L.TITLE_H), BackgroundColor3 = TH.bar, Text = "",
    AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 11}, panel)
corner(titleBar, L.RADIUS)
box(titleBar, 0, L.TITLE_H - L.RADIUS, L.PANEL_W, L.RADIUS, TH.bar, nil, nil, 11)  -- esquinas inferiores rectas
box(panel, 0, L.TITLE_H, L.PANEL_W, 1, TH.line, nil, nil, 12)
local W = {} -- widgets que se actualizan
local minBtn, closeBtn
local function layoutSeg(x, y, w, h)
    -- [Móvil | PC]: cambia de versión (se guarda y el panel se reinicia en esa versión).
    local f = box(titleBar, x, y, w, h, TH.chip, 6, TH.border, 12)
    f.ClipsDescendants = true
    W.layoutBtns = {}
    for i, id in ipairs({"mobile", "pc"}) do
        local b = mk("TextButton", {Position = UDim2.fromOffset((i - 1) * w / 2, 0), Size = UDim2.fromOffset(w / 2, h),
            BackgroundColor3 = TH.segOn, BackgroundTransparency = (id == LAYOUT) and 0 or 1, Text = STR.UI.LAYOUT[i],
            TextColor3 = (id == LAYOUT) and TH.cyan or TH.dim, TextSize = IS_PC and 10 or 11, AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 13}, f)
        setFont(b, FONT.semi)
        interact(b)
        U.conn(b.Activated, function() if UI.setLayout then UI.setLayout(id) end end, "versión " .. id)
        W.layoutBtns[id] = b
    end
end
if IS_PC then
    for i, c in ipairs({TH.red, TH.yellow, TH.green}) do box(titleBar, 14.4 + (i - 1) * 13.75, 16.7, 8, 8, c, 4, nil, 13) end
    label(titleBar, {x = 62, y = 10, w = 330, h = 22, text = string.format(STR.UI.TITLE, "1.3"), rich = true, size = 13, font = FONT.sans})
    layoutSeg(520, 10, 116, 22)
    W.pill = box(titleBar, 649.7, 10, 233.3, 22, TH.bar, 11, TH.border, 12)
    W.pillDot = box(W.pill, 12, 8, 6, 6, TH.ok, 3, nil, 14)
    W.pillText = label(W.pill, {x = 23, y = 0, w = 206, h = 22, text = "", rich = true, size = 10, color = TH.dim})
    W.scaleBtn = button(titleBar, 896, 10, 69, 22, "", TH.dim, TH.bar, nil, 10, FONT.sans)
    minBtn = button(titleBar, 970.8, 10, 24, 22, STR.UI.MIN, TH.dim, TH.bar, nil, 11, FONT.sans)
    closeBtn = button(titleBar, 1000.7, 10, 24.6, 22, STR.UI.CLOSE, TH.bad, TH.bar, nil, 11, FONT.sans)
else
    for i, c in ipairs({TH.red, TH.yellow, TH.green}) do box(titleBar, 12 + (i - 1) * 13, 14, 8, 8, c, 4, nil, 13) end
    label(titleBar, {x = 52, y = 7, w = 230, h = 22, text = string.format(STR.UI.TITLE_M, "1.3"), rich = true, size = 12, font = FONT.sans})
    W.pill = box(titleBar, 296, 6, 156, 24, TH.bar, 12, TH.border, 12)
    W.pillDot = box(W.pill, 10, 9, 6, 6, TH.ok, 3, nil, 14)
    W.pillText = label(W.pill, {x = 21, y = 0, w = 130, h = 24, text = "", rich = true, size = 10.5, color = TH.dim})
    layoutSeg(460, 5, 120, 26)
    W.scaleBtn = button(titleBar, 586, 5, 76, 26, "", TH.dim, TH.bar, nil, 10.5, FONT.sans)
    minBtn = button(titleBar, 668, 5, 32, 26, STR.UI.MIN, TH.dim, TH.bar, nil, 12, FONT.sans)
    closeBtn = button(titleBar, 706, 5, 32, 26, STR.UI.CLOSE, TH.bad, TH.bar, nil, 12, FONT.sans)
end

---------------- Estructura: lateral, columnas y barra de estado
local bodyH = L.PANEL_H - L.TITLE_H - L.STATUS_H - 1
local sidebar = box(panel, 0, L.TITLE_H + 1, L.SIDEBAR_W, bodyH, TH.side, nil, nil, 11)
box(panel, L.SIDEBAR_W, L.TITLE_H + 1, 1, bodyH, TH.line, nil, nil, 12)
local main = box(panel, L.MAIN_X, 0, L.MAIN_W, L.PANEL_H, nil, nil, nil, 11)
local right = IS_PC and box(panel, L.RIGHT_X, 0, L.RIGHT_W, L.PANEL_H, nil, nil, nil, 11) or nil
local statusBar = box(panel, 0, L.PANEL_H - L.STATUS_H, L.PANEL_W, L.STATUS_H, TH.bar, L.RADIUS, nil, 11)
box(statusBar, 0, 0, L.PANEL_W, L.RADIUS, TH.bar, nil, nil, 11)
box(panel, 0, L.PANEL_H - L.STATUS_H, L.PANEL_W, 1, TH.line, nil, nil, 12)

---------------- Aviso breve
local toast = label(panel, {x = L.MAIN_X + 40, y = L.PANEL_H - L.STATUS_H - 42, w = L.MAIN_W - 80, h = 30, text = "", size = 11, font = FONT.med, align = "C", z = 40, wrap = true})
toast.BackgroundColor3 = TH.sel
toast.BackgroundTransparency = 0
toast.Visible = false
corner(toast, 8)
stroke(toast, TH.violet)
local toastSeq = 0
function UI.toast(msg)
    toastSeq = toastSeq + 1
    local my = toastSeq
    toast.Text = msg
    toast.Visible = true
    task.delay(CONFIG.TOAST_SEC, function() if my == toastSeq then toast.Visible = false end end)
end

---------------- Tabla virtual (cabecera + filas reutilizadas)
-- cols = {{title=, x=, w=, kind="mono"|"badge"|"player"|"strong"|"text"|"dim"}}
function UI.table(parent, x, y, w, h, cols)
    local frame = box(parent, x, y, w, h, TH.rowA, 6, TH.border, 12)
    frame.ClipsDescendants = true
    local head = box(frame, 0, 0, w, L.TABLE_HEAD, TH.head, nil, nil, 13)
    box(frame, 0, L.TABLE_HEAD, w, 1, TH.line, nil, nil, 14)
    local T = {frame = frame, cols = cols, rows = {}, n = 0, get = nil, cache = {}, headLabels = {}}
    for i, c in ipairs(cols) do
        T.headLabels[i] = label(head, {x = c.x, y = 0, w = c.hw or c.w, h = L.TABLE_HEAD, text = c.title, size = L.HEAD_TEXT, color = TH.dim, font = FONT.sans})
    end
    local sf = mk("ScrollingFrame", {Position = UDim2.fromOffset(0, L.TABLE_HEAD + 1), Size = UDim2.fromOffset(w, h - L.TABLE_HEAD - 1),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = TH.cyan,
        CanvasSize = UDim2.new(0, 0, 0, 0), ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 13}, frame)
    T.sf = sf
    function T.setColumns(newCols)
        T.cols = newCols
        for i, lb in ipairs(T.headLabels) do
            local c = newCols[i]
            lb.Visible = c ~= nil
            if c then lb.Text, lb.Position, lb.Size = c.title, UDim2.fromOffset(c.x, 0), UDim2.fromOffset(c.w, L.TABLE_HEAD) end
        end
        for _, r in ipairs(T.rows) do r.btn:Destroy() end
        T.rows = {}
        T.draw()
    end
    function T.item(i)
        local it = T.cache[i]
        if it == nil and T.get then it = T.get(i); T.cache[i] = it end
        return it
    end
    local function makeRow(k)
        local row = mk("TextButton", {Size = UDim2.fromOffset(w, L.ROW_H), BackgroundColor3 = TH.rowA, Text = "", AutoButtonColor = false,
            BorderSizePixel = 0, ZIndex = 13, Visible = false}, sf)
        box(row, 0, L.ROW_H - 1, w, 1, TH.line, nil, nil, 14)
        local r = {btn = row, cells = {}, idx = 0}
        r.accent = box(row, 0, 0, 3, L.ROW_H, TH.ok, nil, nil, 15)
        interact(row)
        for ci, c in ipairs(T.cols) do
            if c.kind == "action" then
                local b = button(row, c.x, (L.ROW_H - 22) / 2, c.w, 22, "", TH.cyan, TH.chipOn, nil, L.ROW_TEXT)
                b.ZIndex = 16
                U.conn(b.Activated, function()
                    local it = T.item(r.idx)
                    if it and it.actions and it.actions[ci] then it.actions[ci]() end
                end, "acción fila")
                r.cells[ci] = {action = b}
            elseif c.kind == "badge" then
                local f, t = badge(row, c.x, (L.ROW_H - 15) / 2, 15, "", 9.5)
                r.cells[ci] = {badge = f, text = t}
            else
                local font = (c.kind == "mono" or c.kind == "dim") and FONT.mono or ((c.kind == "strong" or c.kind == "player") and FONT.med or FONT.sans)
                r.cells[ci] = {text = label(row, {x = c.x, y = 0, w = c.w, h = L.ROW_H, size = (c.kind == "mono" or c.kind == "dim") and L.MONO_TEXT or L.ROW_TEXT, font = font,
                    color = (c.kind == "mono" or c.kind == "dim") and TH.dim or (c.kind == "player" and TH.violet or TH.text), rich = c.rich})}
            end
        end
        U.conn(row.Activated, function()
            local it = T.item(r.idx)
            if it and it.onTap then it.onTap() end
            UI.force = true
        end, "fila")
        T.rows[k] = r
        return r
    end
    local function viewHeight() return h - L.TABLE_HEAD - 1 end
    function T.draw()
        local scrollY = 0
        pcall(function() scrollY = sf.CanvasPosition.Y end)
        local first = math.max(1, math.floor(scrollY / L.ROW_H) + 1)
        local need = math.ceil(viewHeight() / L.ROW_H) + L.ROW_SPARE
        for k = 1, need do
            local r = T.rows[k] or makeRow(k)
            local i = first + k - 1
            local it = i <= T.n and T.item(i) or nil
            if it then
                r.idx = i
                r.btn.Position = UDim2.fromOffset(0, (i - 1) * L.ROW_H)
                r.btn.Visible = true
                put(r.btn, "BackgroundColor3", it.selected and TH.sel or ((i % 2 == 0) and TH.rowB or TH.rowA))
                put(r.accent, "Visible", it.selected or false)
                for ci, cell in ipairs(r.cells) do
                    local v = it.cells[ci] or ""
                    if cell.action then
                        cell.action.Visible = v ~= ""
                        if cell.action.Text ~= v then cell.action.Text = v end
                    elseif cell.badge then
                        cell.badge.Visible = v ~= ""
                        if v ~= "" then setBadge(cell.badge, cell.text, v) end
                    else
                        if cell.text.Text ~= v then cell.text.Text = v end
                        local c = it.colors and it.colors[ci]
                        if c then cell.text.TextColor3 = c end
                    end
                end
            else
                r.btn.Visible = false
                r.idx = 0
            end
        end
        for k = need + 1, #T.rows do T.rows[k].btn.Visible = false; T.rows[k].idx = 0 end
    end
    function T.setLazy(n, get)
        local cap = MODE.def.maxRows
        if cap and n > cap then n = cap end
        T.n, T.get, T.cache = n, get, {}
        sf.CanvasSize = UDim2.new(0, 0, 0, n * L.ROW_H)
        T.draw()
    end
    function T.set(items) T.setLazy(#items, function(i) return items[i] end) end
    function T.all()
        local out = {}
        for i = 1, T.n do
            local it = T.item(i)
            out[#out + 1] = {title = table.concat(it.cells, " | "), sub = it.sub or "", onTap = it.onTap, item = it}
        end
        return out
    end
    U.conn(sf:GetPropertyChangedSignal("CanvasPosition"), T.draw, "scroll tabla")
    return T
end

---------------- Fila de chips
function UI.chips(parent, x, y, labels, isOn, onPick, widths)
    local C = {buttons = {}}
    local cx = x
    for i, text in ipairs(labels) do
        local w = ((widths and widths[i]) or (#text * 5.6 + 16)) * (L.CHIP_TEXT / 10.5)
        local b = mk("TextButton", {Position = UDim2.fromOffset(cx, y), Size = UDim2.fromOffset(w, L.CHIP_H), BackgroundColor3 = TH.chip,
            Text = text, TextColor3 = TH.dim, TextSize = L.CHIP_TEXT, AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 14}, parent)
        setFont(b, FONT.med)
        corner(b, L.CHIP_H / 2)
        interact(b, L.CHIP_H / 2)
        local st = stroke(b, TH.border)
        C.buttons[i] = {b = b, st = st}
        U.conn(b.Activated, function() onPick(i); C.refresh(); UI.force = true end, "chip " .. text)
        cx = cx + w + L.CHIP_GAP
    end
    C.right = cx
    function C.refresh()
        for i, it in ipairs(C.buttons) do
            local on = isOn(i)
            put(it.b, "BackgroundColor3", on and TH.chipOn or TH.chip)
            put(it.b, "TextColor3", on and TH.cyan or TH.dim)
            put(it.st, "Color", on and TH.cyan or TH.border)
        end
    end
    C.refresh()
    return C
end

---------------- Caja de búsqueda con lupa dibujada
function UI.search(parent, x, y, w, h, placeholder, onChange)
    local f = box(parent, x, y, w, h, TH.card, 6, TH.border, 12)
    local ring = box(f, 11, h / 2 - 5, 8, 8, nil, 4, TH.dim, 14)
    ring.BackgroundTransparency = 1
    placeSegment(segment(f, TH.dim, 14), 18, h / 2 + 2, 21.5, h / 2 + 5.5, 1.2)
    local tb = mk("TextBox", {Position = UDim2.fromOffset(32, 0), Size = UDim2.fromOffset(w - 40, h), BackgroundTransparency = 1, Text = "",
        PlaceholderText = placeholder, PlaceholderColor3 = TH.text, TextColor3 = TH.text, TextSize = L.ROW_TEXT + 1, ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 14}, f)
    setFont(tb, FONT.sans)
    U.conn(tb:GetPropertyChangedSignal("Text"), function() onChange(tb.Text) end, "buscar")
    return tb
end

---------------- Copiar o mostrar
function UI.copyOrShow(title, text)
    if U.copy(text) then
        UI.toast(string.format(STR.COPIED, #text))
    else
        UI.toast(STR.NO_CLIPBOARD)
        UI.detail(title, text)
    end
end
