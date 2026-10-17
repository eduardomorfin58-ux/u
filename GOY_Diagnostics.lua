--[[
================================================================================
 GOY DIAGNOSTICS v1.3  ·  Diagnóstico de remotos y servidor (SOLO LECTURA)
 Cliente Roblox · optimizado para iPhone + Delta
--------------------------------------------------------------------------------
 QUÉ HACE (desde el cliente, sin tocar el juego):
   · REMOTES    : RemoteEvent / UnreliableRemoteEvent / RemoteFunction /
                  BindableEvent / BindableFunction replicados; registra lo que el
                  cliente PUEDE observar: OnClientEvent y BindableEvent.Event.
   · TOOLS      : herramientas, contenedores, búsqueda e inspector de objetos.
   · BUTTONS    : botones de tu PlayerGui y sus clics (.Activated).
   · LOGS       : registro en vivo con filtros, jugadores, modos, copia y export.
   · PERFORMANCE: FPS, frame, memoria, ping, red, consola y costo del monitor.
 QUÉ NO HACE (límites reales, no se eluden):
   · No ve lo que el cliente ENVÍA (FireServer / InvokeServer): no hay hooks de
     __namecall ni se tocan metatablas.
   · No reemplaza callbacks del juego (OnClientInvoke / OnInvoke solo se listan).
   · No lee código ni eventos internos del servidor.
   · Para ver lo que llega al servidor en TU juego: MAIN → "Script Studio".
--------------------------------------------------------------------------------
 ORIGEN Y BUILD
   Este archivo se genera con build.py (repo u, goy_diagnostics_src/) a partir de s*.lua y de
   GOY_Diagnostics_Studio_Server.lua (único origen del script de servidor,
   que se incrusta en la sección 13). No edites la sección 13 a mano.
--------------------------------------------------------------------------------
 SECCIONES
   1 CONFIG (+STR) · 2 CAP · 3 UTIL · 4 LOG · 5 REG · 6 FEED · 7 MODOS ·
   8 PERF · 9 UI · 10 PESTAÑAS · 11 BUCLE (+arranque) · 12 LIMPIEZA · 13 STUDIO
--------------------------------------------------------------------------------
 CAMBIOS
 v1.3 · Dos versiones: PC (diseño exacto, como panel de computadora: arrastre,
        efecto al pasar el ratón, tecla RightControl para abrir/cerrar) y Móvil
        (744 × 360, cabe en un iPhone horizontal). Botones Móvil | PC en la
        barra de título; cada versión guarda su escala y su posición.
        Respuesta al tocar en todos los botones, gráficas y barras animadas
        (TweenService), menos asignaciones por fotograma (más FPS).
        TP a jugadores por UserId en el selector de jugadores: solo en TU juego
        con el script de Studio v1.3 (GOY_DiagTP, valida autorización y 1 TP/s).
        Revisado con luau-analyze: corregida una variable sin definir (PAGE_Y).
 v1.2 Pro · Interfaz rehecha según el diseño "GOY Diagnostics v1.2 Pro": panel
        de 1040 × 1163 con barra de título, lateral (pestañas con contadores,
        Jugadores, Modo, ejecutor), 6 tarjetas de métricas con mini gráficas,
        búsqueda, chips, tabla de eventos, remotos/jugadores más activos,
        gráfica de eventos/s, detalle del evento, feed del servidor y barra de
        estado. Escalas exactas 65 % y 100 %; si no cabe, se recorre con un dedo.
 v1.2 · Feed del servidor estructurado (tipo, remoto, jugador, userId, args,
        tipos) con límite propio de 60/s · botón JUGADORES (Todos / Solo yo /
        Elegir…) filtrado en el servidor por GOY_DiagMode y también en el
        cliente · 7 modos (Normal, Solo servidor, Alertas, Cambios, Captura,
        Ahorro, Silencioso) ampliables en CONFIG.MODES · aviso de spam emitido
        también por temporizador · escala 65–130 % con etiqueta redondeada ·
        lista virtual corregida para UIScale · giro de pantalla respeta el panel
        minimizado · recarga tras teletransporte con confirmación y URL visible ·
        CONFIG y STR únicos · secciones numeradas · build.py real.
        Servidor: presupuesto por espectador y por emisor (tus eventos nunca se
        pierden por el spam de otro), autorización resuelta en PlayerAdded sin
        cachear fallos, filtro de modo en el servidor validado (2 pet./s).
 v1.1 · Valores sin duplicados · historial de errores con traceback · cola por
        lotes · lista virtual · botones de 44 px · safe area · configuración.
 v1.0 · Primera versión.
================================================================================
]]

-------------------------------------------------------------------------------
-- 1. CONFIG — todas las constantes en un solo lugar
-------------------------------------------------------------------------------
local CONFIG = {
    VERSION = "1.3",

    -- Registro
    LOG_MAX = 700,                 -- entradas en el búfer circular
    RATE_PER_SOURCE = 12,          -- registros/s por remoto, valor, consola…
    RATE_FEED = 60,                -- registros/s del feed del servidor (GOY_DiagFeed)
    RATE_WINDOW = 1,               -- ventana del limitador (s)
    SPAM_NOTICE_CHECK = 0.5,       -- cada cuánto se emiten avisos de spam pendientes (s)
    MAX_ERRORS = 30,               -- historial de errores internos
    ARGS_MAX = 10,                 -- argumentos serializados por evento
    SER_DEPTH = 3, SER_ITEMS = 12, SER_BUDGET = 80, SER_STR = 120, SER_PATH = 90,
    PREVIEW_CHARS = 180,           -- vista previa de argumentos en una fila

    -- Escaneo y registros de objetos
    WATCH_NAMES = {"Workspace", "ReplicatedStorage", "ReplicatedFirst", "Players", "Lighting",
        "StarterGui", "StarterPack", "StarterPlayer", "SoundService", "Teams", "Chat", "TextChatService"},
    MAX_VALUES = 250,              -- ValueBase vigilados a la vez
    MAX_WATCH = 8,                 -- objetos vigilados con .Changed desde el inspector
    MAX_SEARCH = 200,              -- resultados de búsqueda de objetos
    SCAN_YIELD_EVERY = 400,        -- objetos por frame en el escaneo inicial
    SEARCH_YIELD_EVERY = 500,
    QUEUE_BUDGET_MS = 1.5,         -- ms por frame para procesar DescendantAdded
    QUEUE_CHECK_EVERY = 16,        -- cada cuántos objetos se mira el reloj

    -- Feed del servidor (solo existe en TU juego con el script de Studio)
    FEED_REMOTE = "GOY_DiagFeed",
    MODE_REMOTE = "GOY_DiagMode",
    TP_REMOTE = "GOY_DiagTP",      -- solo existe en tu juego (script de Studio v1.3)
    MODE_REQ_PER_SEC = 2,          -- peticiones de modo de jugadores por segundo
    FEED_PROTOCOL = 2,

    -- Modos
    CAPTURE_SECONDS = 30,
    PING_ALERT_MS = 200,
    FPS_ALERT = 20,
    PERF_ALERT_COOLDOWN = 10,      -- s entre alertas repetidas de ping/FPS
    MODES = {
        -- id, etiqueta, filtro de categorías, solo alertas, dibuja, multiplicador de refresco,
        -- muestreo de métricas (s), máximo de filas, gráfica, captura
        {id = "normal",  label = "Normal", desc = "Todo el registro, como siempre",        tickMul = 1, sampleEvery = 1, graph = true},
        {id = "server",  label = "Solo servidor", desc = "Solo el feed y ServerStats", cats = {Servidor = true}, tickMul = 1, sampleEvery = 1, graph = true},
        {id = "alerts",  label = "Alertas", desc = "Spam, errores, ping alto, FPS bajo",       alertsOnly = true, tickMul = 1, sampleEvery = 1, graph = true},
        {id = "changes", label = "Cambios", desc = "Valores, atributos, tools, personaje",       cats = {Valor = true, Cambio = true, Tool = true}, tickMul = 1, sampleEvery = 1, graph = true},
        {id = "capture", label = "Captura", desc = "Graba 30 s y resume",       capture = true, tickMul = 1, sampleEvery = 1, graph = true},
        {id = "saver",   label = "Ahorro", desc = "Menos refresco, menos batería",        tickMul = 3, sampleEvery = 2, maxRows = 60, graph = false},
        {id = "silent",  label = "Silencioso", desc = "No dibuja hasta que haya alerta",    silent = true, tickMul = 3, sampleEvery = 2, graph = false},
    },

    -- Interfaz: medidas exactas del diseño (unidades del diseño; UIScale aplica 65 % o 100 %)
    SCALES = {0.65, 1},
    L = {
        PANEL_W = 1040, PANEL_H = 1163, RADIUS = 10,
        TITLE_H = 41, STATUS_H = 27, SIDEBAR_W = 183,
        MAIN_X = 198, MAIN_W = 586.5, RIGHT_X = 799, RIGHT_W = 226, TOP = 56,
        METRIC_W = 137.5, METRIC_H = 88, METRIC_GAP = 11.5,
        WIDE_Y = 154.5, WIDE_W = 288, WIDE_H = 71.5,
        SEARCH_Y = 237.5, SEARCH_H = 29.5, SEARCH_W = 325, BTN_GAP = 8,
        CHIPS_Y = 279.5, CHIP_H = 22, CHIP_GAP = 5.3,
        TABLE_Y = 312.5, TABLE_H = 490, TABLE_HEAD = 28, ROW_H = 30.8, ROW_SPARE = 3,
        CARDS_Y = 814.5, CARDS_H = 174.5, CARD_W = 288.5,
        CHART_Y = 998.5, CHART_H = 122.5, CHART_BARS = 30, CHART_SECONDS = 60,
        DETAIL_H = 321.5, FEED_Y = 388.5, FEED_H = 134.5, NOTE_Y = 534.5, NOTE_H = 64.5,
        SIDE_X = 12, SIDE_W = 161, TAB_Y0 = 76, TAB_STEP = 30, TAB_H = 26,
        PLAYERS_LABEL_Y = 268, SEG_Y = 287, SEG_H = 27,
        MODE_LABEL_Y = 364, MODE_Y0 = 383, MODE_STEP = 43.6, MODE_H = 38,
        INFO_Y = 1037.3, INFO_H = 83.4, INFO_STEP = 17.3,
        FAB = 60, SPARK_POINTS = 14,
        PAGE_Y = 237.5, CHIPS_REL = 42, TABLE_REL = 75, LOGS_TABLE_H = 490,
        ROW_TEXT = 10.5, MONO_TEXT = 10, HEAD_TEXT = 9.5, CHIP_TEXT = 10.5, WRAP_VALUES = true,
    },
    -- Versión móvil: cabe en un iPhone horizontal (≈ 844 × 390 pt con márgenes seguros).
    LM = {
        PANEL_W = 744, PANEL_H = 360, RADIUS = 10,
        TITLE_H = 36, STATUS_H = 22, SIDEBAR_W = 132,
        MAIN_X = 140, MAIN_W = 596, TOP = 42,
        METRIC_H = 40, METRIC_GAP = 6,
        PAGE_Y = 42, PAGE_Y_METRICS = 88, PAGE_BOTTOM = 332,
        SEARCH_H = 30, SEARCH_W = 250, BTN_GAP = 6,
        CHIP_H = 24, CHIP_GAP = 5, CHIPS_REL = 36, TABLE_REL = 66,
        TABLE_HEAD = 24, ROW_H = 30, ROW_SPARE = 3,
        SIDE_X = 6, SIDE_W = 120, TAB_Y0 = 8, TAB_STEP = 32, TAB_H = 30,
        SEG_Y = 206, SEG_H = 28, MODE_BTN_Y = 242,
        DETAIL_SCALE = 0.92, FAB = 56, SPARK_POINTS = 12,
        CHART_BARS = 30, CHART_SECONDS = 60,
        ROW_TEXT = 11, MONO_TEXT = 10.5, HEAD_TEXT = 10, CHIP_TEXT = 11, WRAP_VALUES = false,
    },
    LAYOUT_DEFAULT = "auto",       -- "auto" (táctil sin teclado = móvil), "pc" o "mobile"
    TOGGLE_KEY = "RightControl",   -- tecla para abrir/cerrar en computadora
    ANIM = {GRAPH = 0.8, BAR = 0.35, OPEN = 0.14, HOVER = 0.08}, -- segundos de animación
    DRAG_THRESHOLD = 8,
    DETAIL_CHUNK = 2500, DETAIL_MAX = 60000,
    TOAST_SEC = 2.6,
    PERF_HISTORY = 30,             -- segundos de historial de las mini gráficas
    MAIN_RECENT = 5,               -- eventos recientes en MAIN
    FEED_VIEWER_LIMIT = 120,       -- reflejo de los límites del script de Studio (solo para mostrar)
    FEED_SENDER_LIMIT = 30,

    -- Refresco
    TICK = 0.35,                   -- periodo del bucle (s)
    REFRESH = {MAIN = 1, PERFORMANCE = 1, BUTTONS = 2, REMOTES = 1.5, TOOLS = 1.5, LOGS = 1.5},
    REFRESH_ON_CHANGE = 0.3,       -- mínimo entre redibujos cuando cambió algo
    REFRESH_SAFETY_MUL = 3,        -- redibujo de seguridad (textos con hora)

    -- Archivos y recarga
    FOLDER = "GOY_Diag",
    CFG_FILE = "config.json",
    CFG_FLUSH_SEC = 2,
    RELOAD_URL = "https://raw.githubusercontent.com/eduardomorfin58-ux/u/main/GOY_Diagnostics.lua",
}

local STUDIO_SCRIPT -- se asigna en la sección 13

-------------------------------------------------------------------------------
-- 1.1 STR — todo el texto de la interfaz
-------------------------------------------------------------------------------
local STR = {
    TITLE = '<font color="#00DCFF">GOY</font> DIAGNOSTICS <font color="#8C96AF">· solo lectura</font>',
    FAB = "GOY", CLOSE = "×", MIN = "–", GRIP = "◢",
    TABS = {"MAIN", "REMOTES", "TOOLS", "BUTTONS", "LOGS", "PERFORMANCE"},
    -- Comunes
    COPY = "Copiar", EXPORT = "Exportar", SEARCH = "Buscar", CLOSE_BTN = "Cerrar", CONFIRM = "Confirmar",
    DETAIL = "Detalle", NA = "no disponible", YES = "sí", NO = "no",
    COPIED = "Copiado al portapapeles (%d caracteres)",
    NO_CLIPBOARD = "Este ejecutor no permite copiar: se muestra el texto para seleccionarlo",
    SAVED = "Guardado: %s", EXPORT_FAIL = "No se pudo exportar: %s",
    NO_WRITEFILE = "writefile no disponible en este ejecutor",
    DETAIL_CUT = "\n… (recortado en pantalla; Copiar copia todo)",
    -- Footer
    FOOTER = '<font color="%s">%s</font> · %s · %s · remotos %d · registros %d%s · FPS %.0f',
    LIVE = "EN VIVO", PAUSED = "EN PAUSA", SPAM_SUFFIX = " (spam %d)",
    -- MAIN
    BTN_SUMMARY = "Copiar resumen", BTN_LIMITS = "Limitaciones", BTN_STUDIO = "Script Studio",
    BTN_SCALE = "Escala %d%%", BTN_OFF = "Apagar",
    BTN_TELEPORT = "Teleport: %s", TELEPORT_ON = "recargar", TELEPORT_OFF = "no",
    TELEPORT_TITLE = "Recargar tras teletransporte",
    TELEPORT_BODY = "Al teletransportarte, Delta ejecutará este código en el siguiente servidor:\n\n  loadstring(game:HttpGet(\"%s\"))()\n\nEso descarga y ejecuta lo que haya en esa URL en ese momento. Actívalo solo si la URL es tuya y confías en su contenido.\nToca «Confirmar» para activarlo.",
    TELEPORT_DONE_ON = "Se recargará tras teletransporte desde la URL confirmada",
    TELEPORT_DONE_OFF = "No se recargará tras teletransporte",
    STUDIO_TITLE = "Script de Studio (servidor, solo tu juego)",
    LIMITS_TITLE = "Qué funciona y qué no",
    SUMMARY_TITLE = "Resumen",
    MAIN_ACTIVE = "● Monitor activo", MAIN_PAUSED = "(registro en pausa)",
    MAIN_EXEC = "Ejecutor: %s · copiar %s · exportar %s · táctil %s",
    MAIN_COMM = "Objetos de comunicación: %d",
    MAIN_COMM_SUB = "RE %d · URE %d · RF %d · BE %d · BF %d · con actividad %d",
    MAIN_TOOLS = "Herramientas: %d", MAIN_BUTTONS = "Botones: %d",
    MAIN_INST = "Instancias +%d / −%d desde el inicio · revisados %d%s", SCANNING = " (escaneando…)",
    MAIN_LOGS = "Registros: %d",
    MAIN_LOGS_SUB = "guardados %d/%d · %.1f/s · spam no guardado %d · en pausa %d",
    MAIN_PERF = "FPS %.0f", MAIN_PING = "Ping %.0f ms", MAIN_PING_NA = "Ping n/d", MAIN_MEM = "Mem %.0f MB", MAIN_MEM_NA = "Mem n/d",
    MAIN_PERF_SUB = "Errores %d · advertencias %d · errores internos del monitor %d",
    MAIN_FEED = "Servidor instrumentado: %s",
    MAIN_FEED_SUB = "modo pedido %s · confirmado %s · feed %d recibidos · %d descartados por el servidor",
    MAIN_FEED_NONE = "No (este juego no tiene tu script de Studio)",
    MAIN_FEED_YES = "Sí (GOY_DiagFeed encontrado)",
    MAIN_MODE = "Modo: %s · Jugadores: %s",
    MAIN_MODE_SUB = "Toca los botones Modo y Jugadores de arriba para cambiarlos",
    MAIN_CAPTURE = "Captura: %s", MAIN_CAPTURE_SUB = "Toca para ver el resumen y exportarlo",
    MAIN_INFO = "ⓘ Qué se observa y qué requiere servidor",
    MAIN_INFO_SUB = "Toca para ver las limitaciones reales y la alternativa de Studio",
    -- Jugadores
    BTN_PLAYERS = "Jugadores: %s",
    PLAYERS_ALL = "Todos", PLAYERS_ME = "Solo yo", PLAYERS_PICK = "Elegir…", PLAYERS_ONE = "%s",
    PICK_TITLE = "Elegir jugador", PICK_SUB = "UserId %d%s", PICK_YOU = " · tú",
    PLAYERS_SENT = "Filtro de jugadores: %s (pedido al servidor)",
    PLAYERS_LOCAL = "Filtro de jugadores: %s (solo en el cliente: este juego no tiene GOY_DiagMode)",
    -- Modos
    BTN_MODE = "Modo: %s",
    MODE_SET = "Modo %s",
    CAPTURE_START = "Capturando %d s…", CAPTURE_LEFT = "captura %ds",
    CAPTURE_DONE = "Captura terminada: %d eventos en %d s",
    CAPTURE_TITLE = "Resumen de captura",
    CAPTURE_NONE = "Todavía no hay captura. Elige el modo Captura.",
    SILENT_ALERT = "Alerta: %s",
    -- REMOTES
    REMOTE_SEARCH = "Nombre, ruta, clase…",
    CLS_FILTERS = {"Todas", "RemoteEvent", "UnreliableRemoteEvent", "RemoteFunction", "BindableEvent", "BindableFunction", "Con actividad"},
    CLS_SHORT = {Todas = "Clase: todas", RemoteEvent = "RemoteEvent", UnreliableRemoteEvent = "Unreliable", RemoteFunction = "RemoteFunction",
        BindableEvent = "BindableEvent", BindableFunction = "BindableFunc", ["Con actividad"] = "Con actividad"},
    SORTS = {"Actividad", "Nombre", "Ruta"}, SORT_BTN = "Orden: %s",
    REMOTES_TITLE = "Remotos", REMOTES_COPY_HEAD = "GOY Diagnostics · remotos (%s)",
    REMOTE_ROW_SUB = "%s · %s%s · %s", REMOTE_NOT_OBS = "  (no observable)",
    REMOTE_SEE_LOGS = "Ver en LOGS", NO_RESULTS = "Sin resultados", SCANNING_T = "Escaneando…",
    NO_RESULTS_SUB = "Cambia la búsqueda o el filtro",
    DIR_RE = "Servidor → Cliente (OnClientEvent observado)", DIR_BE = "Local (BindableEvent.Event observado)",
    DIR_RF = "No observable: OnClientInvoke solo se ve reemplazando el callback (no se hace)",
    DIR_BF = "No observable: OnInvoke solo se ve reemplazando el callback (no se hace)",
    REMOTE_OBS = "Observado directamente desde el cliente.",
    REMOTE_NOOBS = "Solo listado: observarlo exigiría reemplazar el callback del juego. Para verlo, instrumenta TU servidor con el Script de Studio.",
    REMOTE_NOSEND = "Lo que el cliente envía al servidor con este objeto NO se observa (requiere instrumentación del servidor).",
    -- TOOLS
    TOOL_MODES = {"Herramientas", "Contenedores", "Buscar objetos", "Vigilados"},
    TOOL_FILTER = "Filtrar / buscar…", MIN_CHARS = "Escribe al menos 2 letras",
    FOUND = "%d objetos encontrados%s", FOUND_LIMIT = " (límite %d)",
    NO_TOOLS = "No hay herramientas visibles", NO_TOOLS_SUB = "Solo se ven las replicadas a tu cliente (tu Backpack y personajes)",
    CONT_ROW = "%d objetos", CONT_SUB = "+%d / −%d desde el inicio · toca para inspeccionar",
    SERVER_ONLY = "ServerStorage / ServerScriptService", SERVER_ONLY_SUB = "No accesibles desde el cliente (no se replican)",
    WS_LOG = "Registrar instancias nuevas de Workspace: %s", WS_LOG_SUB = "Toca para cambiar (puede generar mucho registro en juegos con proyectiles)",
    SEARCHING = "Buscando…", SEARCHING_SUB = "Por partes, sin congelar el juego",
    SEARCH_HINT = "Escribe un nombre y toca Buscar", SEARCH_HINT_SUB = "Busca en todos los contenedores accesibles (máx. %d)",
    NO_WATCH = "Nada vigilado", NO_WATCH_SUB = "Abre un objeto en el inspector y toca «Vigilar cambios»",
    WATCH_ON = "Vigilando .Changed de este objeto (máx. %d)", WATCH_OFF = "Ya no se vigila",
    WATCH_BTN = "Vigilar cambios", UNWATCH_BTN = "Dejar de vigilar", INSPECT = "Inspeccionar", INSPECTOR = "Inspector · %s",
    TOOL_STATE_EQUIPPED = "equipada",
    -- BUTTONS
    BTN_SEARCH = "Texto, nombre, ruta…", BTN_FILTERS = {"Todos", "Visibles", "Ocultos", "Con clics"},
    NO_BUTTONS = "Sin botones con este filtro", NO_BUTTONS_SUB = "Solo se exploran los botones de tu PlayerGui",
    VISIBLE = "visible", HIDDEN = "oculto",
    -- LOGS
    LOG_SEARCH = "Buscar en registros…", CAT_BTN = "Categoría: %s",
    PAUSE = "Pausa", RESUME = "Reanudar", CLEAR = "Limpiar", CLEARED = "Historial limpio",
    NO_LOGS = "Sin registros todavía", LOGS_PAUSED = "Registro en pausa",
    NO_LOGS_SUB = "Aparecen cuando el servidor te envía señales, cambian tus herramientas o valores, o tocas botones",
    MODE_EMPTY_SUB = "El modo %s oculta el resto · Jugadores: %s",
    LOGS_TITLE = "Registros", LOGS_COPY_HEAD = "GOY Diagnostics · registros (%s) · modo %s · jugadores %s",
    -- PERFORMANCE
    BTN_PERF_COPY = "Copiar métricas", BTN_PERF_NOTES = "¿Qué es aproximado?",
    PERF_TITLE = "Rendimiento", NOTES_TITLE = "Cómo se mide", ERRORS_TITLE = "Errores internos (últimos %d)",
    NO_INTERNAL = "Sin errores internos.",
    -- Categorías y textos de registro
    CATS = {"Todas", "Remote", "Bindable", "Tool", "Instancia", "Cambio", "Valor", "Botón", "Consola", "Servidor", "Sistema"},
    LIMIT_NAME = "Límite: %s",
    LIMIT_MSG = "%d eventos más en %d s no se guardaron en el registro (spam), sí se contaron",
    NO_ARGS = "(sin argumentos)", MORE_ARGS = "… +%d argumentos",
}

STR.LIMITS = [[
QUÉ FUNCIONA EN iPHONE CON DELTA (observado de verdad)
• Lista de RemoteEvent, UnreliableRemoteEvent, RemoteFunction, BindableEvent y BindableFunction replicados al cliente. Se actualiza cuando aparecen o desaparecen.
• Señales servidor → cliente: OnClientEvent (nombre, hora, argumentos, tipos, contador). Son siempre tuyas: el cliente no ve las de otros jugadores.
• BindableEvent.Event (comunicación local del cliente).
• Herramientas, valores y atributos de TU jugador/personaje, botones de tu PlayerGui y sus clics.
• Errores y advertencias de la consola del cliente (LogService).
• FPS, frame, memoria, ping, KB/s, física: lecturas aproximadas del cliente.

QUÉ NO SE PUEDE DESDE EL CLIENTE (y no se intenta)
• Lo que el cliente ENVÍA (FireServer / InvokeServer): requeriría hookear __namecall.
• RemoteFunction.OnClientInvoke y BindableFunction.OnInvoke: solo se listan (no se reemplaza el callback).
• Código y eventos internos del servidor, ServerStorage, ServerScriptService.
• La función interna de un botón: se ve el clic, no lo que hace.
• CPU/memoria del servidor, Script Profiler y MicroProfiler completos.

PARA TU PROPIO JUEGO (Roblox Studio)
• Pega el "Script Studio" (botón de MAIN) en ServerScriptService. Registra OnServerEvent y OnServerInvoke (con _G.GOYDiag.wrapInvoke) de tus remotos y los manda a este panel por GOY_DiagFeed (categoría "Servidor").
• Botón Jugadores: Todos = eventos de todos; Solo yo = lo que TÚ envías al servidor; Elegir… = un jugador. El servidor filtra antes de enviar (GOY_DiagMode), así no se gasta red ni se pierden tus eventos.
• En Studio usa también: F9 → Server, Script Profiler y MicroProfiler (Ctrl+F6).
]]

STR.PERF_NOTES = [[
CÓMO SE MIDE CADA MÉTRICA (cliente, aproximado)
• FPS: frames de RunService.RenderStepped por segundo. Real del cliente.
• Tiempo de frame: promedio y máximo del delta de RenderStepped en el último segundo.
• Memoria total: Stats:GetTotalMemoryUsageMb() del CLIENTE.
• Memoria de scripts: Stats:GetMemoryUsageMbForTag(Script) del cliente.
• Montón Lua: collectgarbage("count") del entorno de este script, no del juego entero.
• Ping: Player:GetNetworkPing() (aproximado) o Stats "Data Ping" como respaldo.
• Red: Stats.DataReceiveKbps / DataSendKbps del cliente.
• Física: workspace:GetRealPhysicsFPS() del cliente.
• En modo Ahorro se muestrea cada 2 s y no se dibuja la gráfica.

NECESITA ROBLOX STUDIO O ACCESO AL SERVIDOR
• CPU y memoria del servidor, Script Profiler, MicroProfiler y pestaña Server de la consola.
• En tu juego: Script Studio (MAIN) envía métricas del servidor (ServerStats) al panel.
]]

-- Mensajes de registro, ubicaciones, direcciones, detalle y rendimiento
STR.LOC = {PLAYER_GUI = "Tu PlayerGui", BACKPACK = "Tu Backpack", PLAYER = "Tu jugador", OUTSIDE = "fuera", IN_BACKPACK = "en Backpack", IN = "en %s"}
STR.DIR = {S2C = "Servidor → Cliente", LOCAL = "Local", REPLICATED = "Replicado", REPLICATED_VALUE = "Servidor → Cliente (replicado)",
    OBSERVED = "Observado", GUI = "Interfaz local", CONSOLE = "Consola del cliente", C2S = "Cliente → Servidor",
    SERVER_NOTICE = "Aviso del servidor", SERVER_STATS = "Métricas del servidor"}
STR.MSG = {
    NEW_REMOTE = "Nuevo %s en %s", REMOVED = "%s eliminado: %s", NEW_INST = "Nueva %s en %s", INST_RATE = "instancias nuevas en %s",
    TOOL_APPEARED = "Herramienta apareció", TOOL_MOVED = "Cambió de lugar", TOOL_EQUIPPED = "Equipada", TOOL_UNEQUIPPED = "Desequipada",
    TOOL_USED = "Activada (usada)", TOOL_GONE = "Herramienta desapareció", TOOL_INFO = "%s · dueño: %s · %s",
    BUTTON_TEXT = "texto: %s · ", BUTTON_NOTE = "%s · la función interna del botón no es visible",
    ERROR = "Error", WARNING = "Advertencia", SCAN = "Escaneo inicial",
    SCAN_DONE = "%d objetos revisados · %d remotos/bindables · %d herramientas · %d botones",
    FEED_RATE = "feed del servidor", SPAM = "Spam · %s", FEED_DROPPED = "Feed recortado por el servidor", FEED_DROPPED_N = "%s mensajes",
    SERVER_MODE = "Modo del servidor", PLAYERS = "Jugadores", MODE = "Modo", CAPTURE = "Captura",
    PING_HIGH = "Ping alto", PING_HIGH_MSG = "%.0f ms (umbral %d ms)", FPS_LOW = "FPS bajos", FPS_LOW_MSG = "%.0f FPS (umbral %d)",
    INTERNAL = "Error interno", INTERNAL_RATE = "errores internos", START = "v%s iniciado · ejecutor %s · solo lectura",
    CHAR = "Personaje", CHAR_SPAWN = "Tu personaje apareció: %s", CHAR_DIED = "Tu Humanoid murió",
    ATTR_PLAYER = "Jugador", ATTR_CHAR = "Personaje",
}
STR.CAPTURE_TXT = {
    HEAD = "GOY Diagnostics · captura de %d s · %s", STATS = "Eventos: %d · promedio %.1f/s · pico %d/s (segundo %d)",
    TOP = "Remotos / fuentes más activos:", PLAYERS = "Jugadores más activos (feed del servidor):",
    NO_PLAYERS = "  (sin datos del servidor: el juego no tiene tu script de Studio)", CATS = "Por categoría:", PER_SEC = "Eventos por segundo:",
}
STR.DET = {
    GONE = "El objeto ya no es accesible.", OBJECT = "Objeto: %s", PATH = "Ruta:   %s", ALIVE = "Sigue en el juego: %s",
    PROPS = "— Propiedades consultables (las que el cliente puede leer) —", ATTRS = "— Atributos —", TAGS = "Tags: %s",
    CHILDREN = "— Hijos directos: %d —", MORE = "… +%d", NOTE = "Nota: los scripts y su código fuente no se leen; solo propiedades replicadas.",
    R_NAME = "Nombre:     %s", R_CLASS = "Clase:      %s", R_PATH = "Ruta:       %s", R_LOC = "Ubicación:  %s", R_DIR = "Dirección:  %s",
    R_SEEN = "Detectado:  %s", R_COUNT = "Recibidos:  %d%s", R_LAST = "  (último %s)", R_ARGS = "Últimos argumentos (%s):", R_NOARGS = "(aún no recibido)",
    B_NAME = "Nombre:   %s", B_CLASS = "Clase:    %s", B_PATH = "Ruta:     %s", B_TEXT = "Texto:    %s", B_NOTEXT = "(ImageButton sin texto)",
    B_VIS = "Visible:  propio %s · en pantalla %s", B_ACTIVE = "Active:   %s · Interactable %s", B_IMAGE = "Imagen:   %s",
    B_CLICKS = "Clics observados: %d%s", B_NOTE = "Se registra Activated. La función interna del botón NO es accesible: solo se ve el clic\ny lo que llegue después (por ejemplo una señal en LOGS justo después).",
    TOOL_SUB = "%s · dueño %s · equipada ×%d · %s", BUTTONS_HEAD = "GOY Diagnostics · botones", TOOLS_HEAD = "GOY Diagnostics · %s",
    BUTTONS_TITLE = "Botones", VIS_SHORT = "vis", HID_SHORT = "ocul", YES_UP = "SÍ", NO_UP = "NO",
}
STR.PERF = {
    FPS = "FPS %.0f", FRAME = "frame %s · máx %s", GRAPH = "  (últimos %d s · cliente)", NO_GRAPH = "gráfica desactivada en este modo",
    PING = "Ping %s", PING_SRC = "%s · aproximado", PING_NA = "API no disponible en este juego/ejecutor",
    MEM = "Memoria %s", MEM_SUB = "scripts %s · montón Lua de este script %s",
    NET = "Red ↓ %s  ↑ %s", NET_SUB = "Física %s · instancias %s",
    SERVER = "Servidor", SERVER_NONE = "sin datos (requiere tu script de Studio)",
    ERR = "Errores %d", WARN = "Advertencias %d", CONSOLE_SUB = "Consola del cliente (LogService). Toca para verlos en LOGS",
    OBJECTS = "Objetos: %d remotos · %d herramientas · %d botones", OBJECTS_SUB = "Registros %d · %.1f/s · spam no guardado %d",
    MONITOR = "Monitor: %d conexiones · cola %d (pico %d)", MONITOR_SUB = "render %.2f ms · %.1f act./s · %d instancias por lotes (%.1f ms/frame) · modo %s",
    INTERNAL = "Errores internos del monitor: %d", INTERNAL_NONE = "Ninguno · toca para ver el historial con traceback",
    INFO = "ⓘ Qué es aproximado y qué necesita Studio", INFO_SUB = "Toca para ver cómo se mide cada valor",
    ERR_ROW = "#%d  [%s]  hace %.0f s",
    T_HEAD = "GOY Diagnostics · rendimiento · %s", T_FPS = "FPS: %s · frame medio %s · máx %s", T_PHYS = "Física: %s", T_PING = "Ping: %s%s",
    T_NET = "Red: recibe %s · envía %s", T_MEM = "Memoria cliente: %s · scripts %s · montón Lua %s", T_INST = "Instancias (Stats): %s",
    T_SERVER = "Servidor: %s", T_CONSOLE = "Consola: %d errores · %d advertencias",
    T_MONITOR = "Monitor: %d conexiones · render %.2f ms · %.1f actualizaciones/s · modo %s", T_LOGS = "Registros: %d · %.1f/s · errores internos %d",
}

-- Textos del diseño "Pro" (barra de título, laterales, tarjetas, tabla y barra de estado)
STR.UI = {
    TITLE = '<font color="#00DCFF"><b>GOY</b></font><b> DIAGNOSTICS</b><font color="#8C96AF"> v%s · solo lectura</font>',
    FEED_PILL = 'Feed del servidor · protocolo 2 · confirmado <b>%s</b>',
    FEED_PILL_PENDING = 'Feed del servidor · protocolo 2 · pidiendo <b>%s</b>',
    FEED_PILL_NONE = 'Sin feed del servidor (juego sin tu script)',
    SCALE = "Escala %d%%", MIN = "—", CLOSE = "✕",
    SIDE_TABS = "Pestañas", SIDE_PLAYERS = "Jugadores", SIDE_MODE = "Modo",
    SEG = {"Todos", "Solo yo", "Elegir…"},
    PLAYERS_NOTE = "El filtro se aplica en el servidor y también en el cliente.",
    INFO = {"Ejecutor", "Copiar", "Archivos", "Config guardada"},
    M_FPS = "FPS", M_PING = "Ping", M_MEM = "Memoria", M_NET = "Red", M_EPS = "Eventos por s", M_CONSOLE = "Consola",
    M_FPS_SUB = "frame %s · máx %s", M_MEM_SUB = "scripts %s · Lua %s", M_NET_SUB = "envía %s", M_EPS_SUB = "spam no guardado %d",
    M_CONSOLE_VAL = "%d err", M_CONSOLE_SUB = "%d advertencias",
    SEARCH_LOGS = "Buscar jugador, remoto o argumento", SEARCH_GENERIC = "Buscar…",
    CHIPS_LOGS = {"Todas", "Servidor", "Remote", "Spam", "Valor", "Tool", "Consola", "Cambio", "Botón"},
    COUNT = "%d de %d eventos", COUNT_ITEMS = "%d elementos",
    COLS_LOGS = {"Hora", "Categoría", "Jugador", "Evento", "Argumentos", "Tipos"},
    TOP_REMOTES = "Remotos más activos", TOP_PLAYERS = "Jugadores más activos",
    TOP_PLAYER_ROW = "%d ev · pico %d/s", FEED_LIMIT_NOTE = "Límite del feed: %d mensajes/s por emisor, %d/s en total.",
    NO_DATA = "Sin datos todavía", NO_PLAYERS = "Sin datos del servidor (requiere tu script de Studio)",
    CHART = "Eventos por segundo · últimos %d s", CHART_PEAK = "pico %d/s", AXIS = {"−60 s", "−30 s", "ahora"},
    DETAIL = "Detalle del evento", DETAIL_ITEM = "Detalle", NO_SELECTION = "Toca una fila para ver su detalle",
    D_TIME = "Hora", D_PLAYER = "Jugador", D_DIR = "Dirección", D_COUNT = "Recibidos", D_ROUTE = "Ruta", D_ARGS = "Argumentos", D_TYPES = "Tipos",
    D_COPY = "Copiar", D_WATCH = "Vigilar", D_UNWATCH = "No vigilar", D_INSPECT = "Inspeccionar", D_NO_INST = "Ese objeto no está en tu cliente",
    FEED_CARD = "Feed del servidor", FEED_BUDGET = "Presupuesto total", FEED_SENDER = "%s · por emisor", FEED_SENDER_NONE = "Por emisor",
    FEED_PER_S = "%d / %d por s", FEED_DROPPED = "Descartados (aviso)", FEED_MODE = "GOY_DiagMode",
    NOTE = "Solo lectura. El cliente no ve lo que envía con FireServer ni InvokeServer; esa parte la registra tu script de Studio en el servidor.",
    ST_LIVE = "EN VIVO", ST_PAUSED = "EN PAUSA", ST_REMOTES = "remotos %d", ST_LOGS = "registros %s", ST_SPAM = "spam no guardado %d",
    ST_QUEUE = "cola %d (pico %d)", ST_ERRORS = "errores internos %d", ST_MODE = "Modo %s", ST_FPS = "FPS %.0f", ST_PING = "ping %s", ST_VER = "v%s",
    COLS_MAIN = {"Elemento", "Valor"}, COLS_REMOTES = {"Nombre", "Clase", "Ubicación", "Recibidos", "Último", "Ruta"},
    COLS_TOOLS = {"Nombre", "Estado", "Dueño / lugar", "Detalle"}, COLS_BUTTONS = {"Texto", "Nombre", "Estado", "Clics", "Ruta"},
    COLS_PERF = {"Métrica", "Valor", "Detalle"}, COLS_LOGS_M = {"Hora", "Categoría", "Jugador", "Evento", "Argumentos"},
    BACK = "Volver", LAYOUT = {"Móvil", "PC"}, SEG_SHORT = {"Todos", "Yo", "Elegir"},
    TITLE_M = '<font color="#00DCFF"><b>GOY</b></font><b> DIAGNOSTICS</b><font color="#8C96AF"> v%s</font>',
    FEED_SHORT = "Feed · <b>%s</b>", FEED_SHORT_NONE = "Sin feed", MODE_BTN = "Modo: %s", MODE_PICK = "Elegir modo",
    PICK_TP = "Elegir jugador · TP", TP = "TP", TP_NONE = "El TP solo funciona en tu juego con el script de Studio v1.3 (GOY_DiagTP).",
    TP_SENT = "Pidiendo TP a %s…", TP_OK = "Listo: %s", TP_FAIL = "TP no hecho: %s", LAYOUT_SWITCH = "Cambiando a versión %s…", D_LOC = "Ubicación", D_TEXT = "Texto", NOT_OBS = "no observable",
}

-- Todo el monitor vive en START(): cambiar de versión (Móvil / PC) lo reinicia limpio.
local function START()

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
        e.alert, e.kind, e.player, e.userId, e.remote = meta.alert, meta.kind, meta.player, meta.userId, meta.remote
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
    LOG.add(cat, e.name, dir, a, types, e.path, {remote = e.path})
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
        return "Servidor", shortName(m.remote), STR.DIR.C2S, false
    end,
    OnServerInvoke = function(m)
        return "Servidor", shortName(m.remote), STR.DIR.C2S, false
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
    TP = function(m)
        if FEED.onTp then FEED.onTp(m.ok, tostring(m.msg or "")) end
        return "Sistema", "TP", "", not m.ok
    end,
}

function FEED.onMessage(e, ...)
    e.count = e.count + 1
    e.last = U.stamp()
    FEED.received = FEED.received + 1
    REG.remoteVersion = REG.remoteVersion + 1
    local m = FEED.parse(...)
    local handler = FEED_KINDS[m.kind]
    local isControl = m.kind == "Mode" or m.kind == "Dropped" or m.kind == "TP"
    if not isControl and not RATE.ok(e, STR.MSG.FEED_RATE, CONFIG.RATE_FEED) then return end
    if m.userId then FEED.names[m.userId] = m.player end
    if m.kind == "OnServerEvent" or m.kind == "OnServerInvoke" then FEED.count(m) end
    local cat, name, dir, alert = "Servidor", m.kind, "", false
    if handler then cat, name, dir, alert = handler(m) end
    local extra = m.msg or (m.reason and tostring(m.reason)) or (m.count and string.format(STR.MSG.FEED_DROPPED_N, tostring(m.count))) or ""
    LOG.add(cat, name, dir, m.args and tostring(m.args) or "", m.types and tostring(m.types) or "", extra,
        {kind = m.kind, player = m.player, userId = m.userId, remote = m.remote, alert = alert})
end

-- Contadores para "Remotos / Jugadores más activos" y el presupuesto por segundo.
FEED.byRemote, FEED.byPlayer, FEED.sec = {}, {}, {start = os.clock(), total = 0, bySender = {}, lastTotal = 0, lastTop = 0, lastTopName = nil}
function FEED.count(m)
    local name = shortName(m.remote)
    FEED.byRemote[name] = (FEED.byRemote[name] or 0) + 1
    local now = os.clock()
    local sec = FEED.sec
    if now - sec.start >= 1 then
        local top, topName = 0, nil
        for n, c in pairs(sec.bySender) do if c > top then top, topName = c, n end end
        sec.lastTotal, sec.lastTop, sec.lastTopName = sec.total, top, topName
        sec.start, sec.total, sec.bySender = now, 0, {}
    end
    sec.total = sec.total + 1
    if m.player then
        sec.bySender[m.player] = (sec.bySender[m.player] or 0) + 1
        local p = FEED.byPlayer[m.player] or {count = 0, peak = 0, winStart = now, win = 0}
        if now - p.winStart >= 1 then p.winStart, p.win = now, 0 end
        p.count, p.win = p.count + 1, p.win + 1
        if p.win > p.peak then p.peak = p.win end
        FEED.byPlayer[m.player] = p
    end
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

REG.specials[CONFIG.TP_REMOTE] = function(e, inst)
    FEED.tpRemote = inst
    return nil -- solo se usa para pedir TP en TU juego; no se escucha
end
-- TP por UserId: lo hace tu script de Studio (valida autorización y 1 TP/s).
function FEED.tp(userId)
    if not FEED.tpRemote then return false end
    return (pcall(function() FEED.tpRemote:FireServer({userId = userId}) end))
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
    PERF.push("pingHist", PERF.ping or 0)
    PERF.push("memHist", PERF.mem or 0)
    PERF.push("netHist", PERF.recv or 0)
    PERF.push("consoleHist", CONSOLE.errors + CONSOLE.warnings)
    checkPerfAlerts(now)
end

-- Historiales para mini gráficas y la gráfica de eventos/s.
function PERF.push(key, v)
    local h = PERF[key]
    if not h then h = {}; PERF[key] = h end
    h[#h + 1] = v
    if #h > CONFIG.PERF_HISTORY then table.remove(h, 1) end
end
PERF.eps, PERF.epsWin, PERF.epsLast, PERF.epsNow = {}, os.clock(), 0, 0
function PERF.tickEvents(now)
    if now - PERF.epsWin < 1 then return end
    local total = LOG.total + LOG.suppressed + LOG.droppedPaused
    PERF.epsNow = math.max(0, total - PERF.epsLast) / (now - PERF.epsWin)
    PERF.epsLast, PERF.epsWin = total, now
    PERF.eps[#PERF.eps + 1] = PERF.epsNow
    if #PERF.eps > CONFIG.L.CHART_SECONDS then table.remove(PERF.eps, 1) end
end

function PERF.due(now)
    return now - PERF.lastSample >= (MODE.def.sampleEvery or 1)
end

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

-------------------------------------------------------------------------------
-- 10. PESTAÑAS — lateral, tarjetas, páginas, detalle y barra de estado
-------------------------------------------------------------------------------
-- Zona de cada pestaña dentro de la columna central (en móvil, las tarjetas de
-- métricas solo se ven en MAIN y PERFORMANCE para dejar sitio a la tabla).
local function pageGeom(name)
    if IS_PC then return L.PAGE_Y, L.CHART_Y + L.CHART_H - L.PAGE_Y end
    local y = (name == "MAIN" or name == "PERFORMANCE") and L.PAGE_Y_METRICS or L.PAGE_Y
    return y, L.PAGE_BOTTOM - y
end
local PAGE_H = {}
local OV_Y = IS_PC and L.PAGE_Y or L.TOP                       -- capas (detalle largo, selector)
local OV_H = IS_PC and (L.CHART_Y + L.CHART_H - L.PAGE_Y) or (L.PAGE_BOTTOM - L.TOP)
local CHIPS_Y, TABLE_Y = L.CHIPS_REL, L.TABLE_REL
local TOOLBAR_X = L.SEARCH_W + (IS_PC and 8.6 or 6)
local fmtInt = function(n)
    local s = tostring(math.floor(n or 0))
    local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    return (out:gsub("^,", ""))
end
local function fmt(v, f, unit) if v == nil then return STR.NA end return string.format(f, v) .. (unit or "") end

---------------- Lateral: pestañas
local SIDE = {tabs = {}, seg = {}, modes = {}, info = {}}
if IS_PC then label(sidebar, {x = 17.5, y = 13, w = 150, h = 14, text = STR.UI.SIDE_TABS, size = 10, color = TH.dim}) end
for i, name in ipairs(STR.TABS) do
    local cy = IS_PC and (L.TAB_Y0 - L.TITLE_H + 13 + (i - 1) * L.TAB_STEP) or (L.TAB_Y0 + L.TAB_H / 2 + (i - 1) * L.TAB_STEP)
    local b = mk("TextButton", {Position = UDim2.fromOffset(L.SIDE_X, cy - L.TAB_H / 2), Size = UDim2.fromOffset(L.SIDE_W, L.TAB_H),
        BackgroundColor3 = TH.sel, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 13}, sidebar)
    corner(b, 6)
    local bar = box(b, 0, 0, 3, L.TAB_H, TH.cyan, 2, nil, 14)
    local name_ = label(b, {x = 7.6, y = 0, w = 100, h = L.TAB_H, text = (not IS_PC and name == "PERFORMANCE") and "PERF" or name, size = IS_PC and 11.5 or 11, color = TH.dim})
    local count = label(b, {x = L.SIDE_W - 70, y = 0, w = 63.7, h = L.TAB_H, text = "", size = 10, color = TH.dim, align = "R", font = FONT.mono})
    interact(b, 6)
    SIDE.tabs[name] = {b = b, bar = bar, name = name_, count = count}
    local py, ph = pageGeom(name)
    PAGE_H[name] = ph
    UI.pages[name] = box(main, 0, py, L.MAIN_W, ph, nil, nil, nil, 12)
    UI.pages[name].Visible = false
end

---------------- Lateral: jugadores
if IS_PC then
label(sidebar, {x = 17.5, y = L.PLAYERS_LABEL_Y - L.TITLE_H, w = 150, h = 14, text = STR.UI.SIDE_PLAYERS, size = 10, color = TH.dim})
local segFrame = box(sidebar, L.SIDE_X, L.SEG_Y - L.TITLE_H, L.SIDE_W, L.SEG_H, TH.chip, 6, TH.border, 13)
segFrame.ClipsDescendants = true
for i, text in ipairs(STR.UI.SEG) do
    local w = L.SIDE_W / 3
    local b = mk("TextButton", {Position = UDim2.fromOffset((i - 1) * w, 0), Size = UDim2.fromOffset(w, L.SEG_H), BackgroundColor3 = TH.segOn,
        BackgroundTransparency = 1, Text = text, TextColor3 = TH.dim, TextSize = 10.5, AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 14}, segFrame)
    setFont(b, FONT.med)
    interact(b)
    SIDE.seg[i] = b
end
label(sidebar, {x = 17.5, y = L.SEG_Y - L.TITLE_H + L.SEG_H + 6, w = 158, h = 30, text = STR.UI.PLAYERS_NOTE, size = 10, color = TH.dim, wrap = true, top = true})

---------------- Lateral: modos (PC: lista; móvil: botón que abre la lista)
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
    interact(b, 7)
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
else
    -- Móvil: segmentos cortos + botón de modo.
    local segFrame = box(sidebar, L.SIDE_X, L.SEG_Y, L.SIDE_W, L.SEG_H, TH.chip, 6, TH.border, 13)
    segFrame.ClipsDescendants = true
    for i, text in ipairs(STR.UI.SEG_SHORT) do
        local w = L.SIDE_W / 3
        local b = mk("TextButton", {Position = UDim2.fromOffset((i - 1) * w, 0), Size = UDim2.fromOffset(w, L.SEG_H), BackgroundColor3 = TH.segOn,
            BackgroundTransparency = 1, Text = text, TextColor3 = TH.dim, TextSize = 10.5, AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 14}, segFrame)
        setFont(b, FONT.med)
        interact(b)
        SIDE.seg[i] = b
    end
    SIDE.modeBtn = button(sidebar, L.SIDE_X, L.MODE_BTN_Y, L.SIDE_W, L.SEG_H, "", TH.text, TH.chip, function()
        local opts = {}
        for i, m in ipairs(CONFIG.MODES) do
            opts[i] = {title = m.label, sub = m.desc or "", onPick = function()
                MODE.set(i)
                if MODE.def.capture then UI.toast(string.format(STR.CAPTURE_START, CONFIG.CAPTURE_SECONDS)) end
            end}
        end
        UI.pick(STR.UI.MODE_PICK, opts)
    end, 10.5, FONT.med)
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
    local twoLines = L.WRAP_VALUES and num and #value >= 6
    put(m.value, "Text", twoLines and num or value)
    if m.value2 then
        put(m.value2, "Text", twoLines and unit or "")
        put(m.sub, "Position", UDim2.fromOffset(11.8, twoLines and 67 or m.baseSubY))
    end
    put(m.sub, "Text", sub)
    if hist and #hist >= 2 then m.spark.set(hist) end
end
if IS_PC then
    for k, def in ipairs({{"fps", STR.UI.M_FPS, TH.ok}, {"ping", STR.UI.M_PING, TH.cyan}, {"mem", STR.UI.M_MEM, TH.violet}, {"net", STR.UI.M_NET, TH.blue}}) do
        METRIC[def[1]] = metricCard(0.7 + (k - 1) * (L.METRIC_W + L.METRIC_GAP), L.TOP, L.METRIC_W, L.METRIC_H, def[2], def[3], 74.4, 28)
    end
    METRIC.eps = metricCard(0, L.WIDE_Y, L.WIDE_W, L.WIDE_H, STR.UI.M_EPS, TH.warn, 224, 27.2)
    METRIC.console = metricCard(L.WIDE_W + 10.3, L.WIDE_Y, L.WIDE_W, L.WIDE_H, STR.UI.M_CONSOLE, TH.bad, 224, 27.2)
else
    -- Móvil: 4 tarjetas compactas (solo en MAIN y PERFORMANCE).
    METRIC.group = box(main, 0, L.TOP, L.MAIN_W, L.METRIC_H, nil, nil, nil, 12)
    local w = (L.MAIN_W - 3 * L.METRIC_GAP) / 4
    for k, def in ipairs({{"fps", STR.UI.M_FPS, TH.ok}, {"ping", STR.UI.M_PING, TH.cyan}, {"mem", STR.UI.M_MEM, TH.violet}, {"eps", STR.UI.M_EPS, TH.warn}}) do
        local c = box(METRIC.group, (k - 1) * (w + L.METRIC_GAP), 0, w, L.METRIC_H, TH.card, 7, TH.border, 12)
        label(c, {x = 8, y = 3, w = w - 16, h = 13, text = def[2], size = 9.5, color = TH.dim})
        METRIC[def[1]] = {card = c, value = label(c, {x = 8, y = 17, w = 80, h = 20, text = "", size = 15, font = FONT.bold, color = def[3]}),
            sub = label(c, {x = 0, y = 0, w = 0, h = 0, text = ""}), spark = UI.spark(c, w - 52, 17, 44, 14, def[3]), baseSubY = 0}
    end
end

---------------- Columna derecha: detalle, feed y nota
local DC = {} -- tarjeta de detalle (PC: columna derecha; móvil: capa sobre la tabla)
do
    local DW, DH = 225.5, 321.5
    local c
    if IS_PC then
        c = box(right, 0.5, L.TOP + 0.5, DW, DH, TH.card, 8, TH.border, 12)
    else
        local sc = L.DETAIL_SCALE
        local holder = box(panel, L.PANEL_W - DW * sc - 8, L.TITLE_H + 6, DW, DH, nil, nil, nil, 34)
        mk("UIScale", {Scale = sc}, holder)
        holder.Visible = false
        DC.holder = holder
        c = box(holder, 0, 0, DW, DH, TH.card, 8, TH.cyan, 35)
        c.Active = true
        local x = button(c, DW - 30, 8, 22, 20, STR.UI.CLOSE, TH.bad, TH.card, function() holder.Visible = false end, 11)
        x.ZIndex = 40
    end
    DC.card = c
    DC.head = label(c, {x = 12, y = 13, w = 140, h = 15, text = STR.UI.DETAIL, size = 11.5, font = FONT.semi})
    DC.badge, DC.badgeText = badge(c, IS_PC and 170 or 140, 12.7, 14.3, "Servidor", 9.5)
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
if IS_PC then
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
if IS_PC then
    local c = box(right, 0.5, L.NOTE_Y, L.RIGHT_W - 0.5, L.NOTE_H, nil, 8, nil, 12)
    dashedBorder(c, L.RIGHT_W - 0.5, L.NOTE_H, TH.border)
    label(c, {x = 12, y = 10, w = 202, h = 46, text = STR.UI.NOTE, size = 9.5, color = TH.dim, wrap = true, top = true})
end

---------------- Barra de estado
local ST = {}
do
    local leftList = box(statusBar, IS_PC and 17.3 or 12, 0, IS_PC and 760 or 420, L.STATUS_H, nil, nil, nil, 12)
    mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 14), VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder}, leftList)
    local live = box(leftList, 0, 0, 62, L.STATUS_H, nil, nil, nil, 12)
    live.LayoutOrder = 1
    ST.dot = box(live, 0, (L.STATUS_H - 6) / 2, 6, 6, TH.ok, 3, nil, 13)
    ST.live = label(live, {x = 9.4, y = 0, w = 55, h = L.STATUS_H, text = STR.UI.ST_LIVE, size = 10, font = FONT.semi, color = TH.ok})
    local function item(parent, order, align)
        local t = label(parent, {x = 0, y = 0, w = 0, h = L.STATUS_H, text = "", size = 10, color = TH.dim, align = align})
        t.AutomaticSize = Enum.AutomaticSize.X
        t.LayoutOrder = order
        return t
    end
    ST.left = {}
    for i = 1, (IS_PC and 5 or 3) do ST.left[i] = item(leftList, i + 1) end
    local rightList = box(statusBar, L.PANEL_W - (IS_PC and 415 or 312), 0, IS_PC and 400 or 300, L.STATUS_H, nil, nil, nil, 12)
    mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 14), VerticalAlignment = Enum.VerticalAlignment.Center,
        HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder}, rightList)
    ST.right = {}
    for i = 1, (IS_PC and 4 or 3) do ST.right[i] = item(rightList, i) end
end

---------------- Detalle largo (inspector, script de Studio, limitaciones…) sobre la zona de la pestaña
local detail = box(main, 0, OV_Y, L.MAIN_W, OV_H, TH.bg, 8, TH.violet, 30)
detail.Active = true
detail.Visible = false
local DET = {chunks = {}, text = "", extraFn = nil}
DET.title = label(detail, {x = 12, y = 6, w = 300, h = 28, text = "", size = 12, font = FONT.semi, color = TH.cyan, z = 31})
DET.close = button(detail, L.MAIN_W - 72, 6, 62, 26, STR.UI.BACK, TH.bad, TH.card, function() detail.Visible = false end, 10.5)
DET.copy = button(detail, L.MAIN_W - 140, 6, 62, 26, STR.COPY, TH.cyan, TH.card, function() UI.copyOrShow(STR.DETAIL, DET.text) end, 10.5)
DET.extra = button(detail, L.MAIN_W - 238, 6, 92, 26, "", TH.violet, TH.card, function() if DET.extraFn then DET.extraFn() end end, 10.5)
for _, b in ipairs({DET.close, DET.copy, DET.extra}) do b.ZIndex = 31 end
DET.scroll = mk("ScrollingFrame", {Position = UDim2.fromOffset(8, 40), Size = UDim2.fromOffset(L.MAIN_W - 16, OV_H - 48), BackgroundColor3 = TH.card,
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
local picker = box(main, 0, OV_Y, L.MAIN_W, OV_H, TH.bg, 8, TH.cyan, 33)
picker.Active = true
picker.Visible = false
local pickerTitle = label(picker, {x = 12, y = 6, w = 300, h = 28, text = STR.PICK_TITLE, size = 12, font = FONT.semi, color = TH.cyan, z = 34})
local pickerClose = button(picker, L.MAIN_W - 72, 6, 62, 26, STR.UI.BACK, TH.bad, TH.card, function() picker.Visible = false end, 10.5)
pickerClose.ZIndex = 34
local pickerList = UI.table(picker, 8, 40, L.MAIN_W - 16, OV_H - 48, {
    {title = STR.UI.D_PLAYER, x = 14, w = IS_PC and 260 or 200, kind = "strong"}, {title = "UserId / detalle", x = IS_PC and 280 or 220, w = IS_PC and 200 or 240, kind = "mono"},
    {title = "", x = L.MAIN_W - 16 - 70, w = 56, kind = "action"}})
-- options = {{title, sub, onPick, action = {text, fn}}}
function UI.pick(title, options)
    pickerTitle.Text = title
    local items = {}
    for i, o in ipairs(options) do
        items[i] = {cells = {o.title, o.sub or "", o.action and o.action.text or ""},
            actions = o.action and {[3] = function() o.action.fn(); UI.force = true end} or nil,
            onTap = function() picker.Visible = false; o.onPick(); UI.force = true end}
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
        local name = p.Name
        opts[#opts + 1] = {title = (p.DisplayName and p.DisplayName ~= p.Name) and (p.DisplayName .. " (@" .. p.Name .. ")") or p.Name,
            sub = string.format(STR.PICK_SUB, uid, p == LP and STR.PICK_YOU or ""), onPick = function() FEED.setFilter(uid) end,
            action = p ~= LP and {text = STR.UI.TP, fn = function() UI.tp(uid, name) end} or nil}
    end
    UI.pick(STR.UI.PICK_TP, opts)
end
-- TP a un jugador por UserId: solo en tu juego (lo hace tu script de Studio, que valida todo).
function UI.tp(userId, name)
    if not FEED.tpRemote then UI.toast(STR.UI.TP_NONE) return end
    if FEED.tp(userId) then UI.toast(string.format(STR.UI.TP_SENT, tostring(name))) end
end
FEED.onTp = function(ok, msg) UI.toast(string.format(ok and STR.UI.TP_OK or STR.UI.TP_FAIL, msg)) end
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
    if DC.holder then DC.holder.Visible = true end
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
    local BW = IS_PC and {52.6, 58, 54, 64} or {56, 62, 58, 70}
    pauseBtn = toolbarRow(page, TOOLBAR_X, {
        {text = STR.PAUSE, w = BW[1], fg = TH.text, bg = TH.chip, fn = function(b)
            LOG.paused = not LOG.paused
            b.Text = LOG.paused and STR.RESUME or STR.PAUSE
            UI.force = true
        end},
        {text = STR.CLEAR, w = BW[2], fg = TH.bad, bg = TH.btnRed, fn = function() LOG.clear(); UI.sel = nil; UI.force = true; UI.toast(STR.CLEARED) end},
        {text = STR.COPY, w = BW[3], fg = TH.ok, bg = TH.btnGreen, fn = function()
            local list, t = filteredLogs(), {string.format(STR.LOGS_COPY_HEAD, U.fullDate(), MODE.def.label, FEED.label())}
            for i = #list, 1, -1 do t[#t + 1] = LOG.format(list[i]) end
            UI.copyOrShow(STR.LOGS_TITLE, table.concat(t, "\n"))
        end},
        {text = STR.EXPORT, w = BW[4], fg = TH.violet, bg = TH.btnViolet, fn = function()
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
    LOGS.count = label(page, {x = LOGS.chips.right, y = CHIPS_Y, w = L.MAIN_W - LOGS.chips.right, h = L.CHIP_H, text = "", size = 10, color = TH.dim, align = "R"})
    if IS_PC then
        local C = STR.UI.COLS_LOGS
        LOGS.table = UI.table(page, 0, TABLE_Y, L.MAIN_W, L.LOGS_TABLE_H, {
            {title = C[1], x = 14, w = 88, kind = "mono"}, {title = C[2], x = 107, w = 70, kind = "badge"},
            {title = C[3], x = 184.7, w = 80, kind = "player"}, {title = C[4], x = 269, w = 168, kind = "strong"},
            {title = C[5], x = 443, w = 46, hw = 60, kind = "mono"}, {title = C[6], x = 494, w = 88, kind = "mono"}})
    else
        local C = STR.UI.COLS_LOGS_M
        LOGS.table = UI.table(page, 0, TABLE_Y, L.MAIN_W, PAGE_H.LOGS - TABLE_Y, {
            {title = C[1], x = 10, w = 76, kind = "mono"}, {title = C[2], x = 90, w = 70, kind = "badge"},
            {title = C[3], x = 166, w = 84, kind = "player"}, {title = C[4], x = 254, w = 200, kind = "strong"},
            {title = C[5], x = 458, w = 130, kind = "mono"}})
    end
    UI.lists.LOGS = LOGS.table
    if IS_PC then
    -- Remotos / jugadores más activos
    local cardsY = L.CARDS_Y - L.PAGE_Y
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
    local ch = box(page, 0.6, L.CHART_Y - L.PAGE_Y, L.MAIN_W - 1.2, L.CHART_H, TH.card, 8, TH.border, 12)
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
    if not LOGS.remRows then return end
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
        tw(f, {Size = UDim2.fromOffset(f.Size.X.Offset, h), Position = UDim2.fromOffset(f.Position.X.Offset, 92.1 - h)}, CONFIG.ANIM.BAR)
        put(f, "BackgroundColor3", (b == peakI and peak > 0) and TH.warn or TH.cyan)
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
    if IS_PC and UI.sel == nil and list[1] then UI.sel = list[1].id; eventCard(list[1]) end
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
    UI.lists.MAIN = UI.table(page, 0, CHIPS_Y, L.MAIN_W, PAGE_H.MAIN - CHIPS_Y, {
        {title = C[1], x = IS_PC and 14 or 10, w = IS_PC and 160 or 150, kind = "strong"}, {title = C[2], x = IS_PC and 180 or 166, w = IS_PC and 396 or 420, kind = "text", rich = true}})
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
    toolbarRow(page, TOOLBAR_X, {
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
    UI.lists.REMOTES = UI.table(page, 0, TABLE_Y, L.MAIN_W, PAGE_H.REMOTES - TABLE_Y, IS_PC and {
        {title = C[1], x = 14, w = 120, kind = "strong"}, {title = C[2], x = 140, w = 90, kind = "badge"},
        {title = C[3], x = 270, w = 90, kind = "dim"}, {title = C[4], x = 362, w = 60, kind = "mono"},
        {title = C[5], x = 424, w = 80, kind = "mono"}, {title = C[6], x = 506, w = 76, kind = "mono"}} or {
        {title = C[1], x = 10, w = 140, kind = "strong"}, {title = C[2], x = 154, w = 110, kind = "badge"},
        {title = C[3], x = 300, w = 90, kind = "dim"}, {title = C[4], x = 394, w = 70, kind = "mono"},
        {title = C[5], x = 468, w = 120, kind = "mono"}})
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
    toolbarRow(page, TOOLBAR_X, {
        {text = STR.SEARCH, w = 64, fg = TH.cyan, bg = TH.chip, fn = function() toolState.mode = 3; TPAGE.chips.refresh(); runSearch(tb.Text) end},
        {text = STR.COPY, w = 54, fg = TH.ok, bg = TH.btnGreen, fn = function()
            local t = {string.format(STR.DET.TOOLS_HEAD, TOOL_MODES[toolState.mode])}
            for _, it in ipairs(UI.lists.TOOLS.all()) do t[#t + 1] = it.title end
            UI.copyOrShow(TOOL_MODES[toolState.mode], table.concat(t, "\n"))
        end},
    })
    TPAGE.chips = UI.chips(page, 0, CHIPS_Y, TOOL_MODES, function(i) return toolState.mode == i end, function(i) toolState.mode = i end)
    local C = STR.UI.COLS_TOOLS
    UI.lists.TOOLS = UI.table(page, 0, TABLE_Y, L.MAIN_W, PAGE_H.TOOLS - TABLE_Y, {
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
    toolbarRow(page, TOOLBAR_X, {
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
    UI.lists.BUTTONS = UI.table(page, 0, TABLE_Y, L.MAIN_W, PAGE_H.BUTTONS - TABLE_Y, {
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
    UI.lists.PERFORMANCE = UI.table(page, 0, CHIPS_Y, L.MAIN_W, PAGE_H.PERFORMANCE - CHIPS_Y, {
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
    put(W.pillDot, "BackgroundColor3", feedOn and TH.ok or TH.dotOff)
    if IS_PC then
        put(W.pillText, "Text", not feedOn and STR.UI.FEED_PILL_NONE or
            string.format((FEED.serverMode ~= nil and FEED.label(FEED.serverMode) == FEED.label()) and STR.UI.FEED_PILL or STR.UI.FEED_PILL_PENDING, U.esc(FEED.label())))
    else
        put(W.pillText, "Text", feedOn and string.format(STR.UI.FEED_SHORT, U.esc(FEED.label())) or STR.UI.FEED_SHORT_NONE)
    end
    put(W.scaleBtn, "Text", UI.scaleLabel())
    -- Lateral
    local counts = {REMOTES = #REG.remotes, TOOLS = #REG.tools, BUTTONS = #REG.buttons, LOGS = LOG.total}
    for name, t in pairs(SIDE.tabs) do
        local on = name == UI.tab
        put(t.b, "BackgroundTransparency", on and 0 or 1)
        put(t.bar, "Visible", on)
        put(t.name, "TextColor3", on and TH.cyan or TH.dim)
        if t.bold ~= on then t.bold = on; setFont(t.name, on and FONT.semi or FONT.sans) end
        put(t.count, "Text", counts[name] and fmtInt(counts[name]) or "")
        put(t.count, "TextColor3", on and TH.cyan or TH.dim)
    end
    local segOn = FEED.filter == "all" and 1 or (FEED.filter == "me" and 2 or 3)
    -- TP a un jugador por UserId: solo en tu juego (lo hace tu script de Studio, que valida todo).
function UI.tp(userId, name)
    if not FEED.tpRemote then UI.toast(STR.UI.TP_NONE) return end
    if FEED.tp(userId) then UI.toast(string.format(STR.UI.TP_SENT, tostring(name))) end
end
FEED.onTp = function(ok, msg) UI.toast(string.format(ok and STR.UI.TP_OK or STR.UI.TP_FAIL, msg)) end
for i, b in ipairs(SIDE.seg) do
        put(b, "BackgroundTransparency", (i == segOn) and 0 or 1)
        put(b, "TextColor3", (i == segOn) and TH.cyan or TH.dim)
        if i == 3 then put(b, "Text", (segOn == 3) and FEED.label() or (IS_PC and STR.UI.SEG[3] or STR.UI.SEG_SHORT[3])) end
    end
    for i, m in ipairs(SIDE.modes) do
        local on = i == MODE.index
        put(m.b, "BackgroundTransparency", on and 0 or 1)
        put(m.st, "Transparency", on and 0 or 1)
        put(m.dot, "BackgroundColor3", on and TH.cyan or TH.dotOff)
    end
    if SIDE.modeBtn then put(SIDE.modeBtn, "Text", string.format(STR.UI.MODE_BTN, MODE.def.label)) end
    local yn = function(b) return b and STR.YES or STR.NO end
    local vals = {CAP.executor:match("^(%S+)") or CAP.executor, yn(CAP.setclipboard), yn(CAP.writefile), yn(CAP.writefile ~= nil and CAP.readfile ~= nil)}
    for i, l in ipairs(SIDE.info) do
        put(l, "Text", vals[i])
        put(l, "TextColor3", (vals[i] == STR.YES) and TH.ok or ((vals[i] == STR.NO) and TH.bad or TH.text))
    end
    -- Tarjetas de métricas
    local U_ = STR.UI
    setMetric(METRIC.fps, fmt(PERF.fps, "%.0f"), string.format(U_.M_FPS_SUB, fmt(PERF.frameAvg * 1000, "%.1f", " ms"), fmt(PERF.lastFrameMax * 1000, "%.0f", " ms")), MODE.def.graph and PERF.hist)
    setMetric(METRIC.ping, fmt(PERF.ping, "%.0f", " ms"), PERF.pingSrc ~= "" and PERF.pingSrc or STR.PERF.PING_NA, MODE.def.graph and PERF.pingHist)
    setMetric(METRIC.mem, fmt(PERF.mem, "%.0f", " MB"), string.format(U_.M_MEM_SUB, fmt(PERF.memScript, "%.0f", " MB"), fmt(PERF.luaHeap, "%.1f", " MB")), MODE.def.graph and PERF.memHist)
    if METRIC.net then setMetric(METRIC.net, fmt(PERF.recv, "%.1f", " KB/s"), string.format(U_.M_NET_SUB, fmt(PERF.send, "%.1f", " KB/s")), MODE.def.graph and PERF.netHist) end
    setMetric(METRIC.eps, string.format("%.1f", PERF.epsNow or 0), string.format(U_.M_EPS_SUB, LOG.suppressed), MODE.def.graph and PERF.eps)
    if METRIC.console then setMetric(METRIC.console, string.format(U_.M_CONSOLE_VAL, CONSOLE.errors), string.format(U_.M_CONSOLE_SUB, CONSOLE.warnings), MODE.def.graph and PERF.consoleHist) end
    -- Feed del servidor
    local sec = FEED.sec
    if FC.v1 then
    FC.v1.Text = string.format(U_.FEED_PER_S, sec.lastTotal, CONFIG.FEED_VIEWER_LIMIT)
    FC.bar1(sec.lastTotal / CONFIG.FEED_VIEWER_LIMIT)
    FC.k2.Text = sec.lastTopName and string.format(U_.FEED_SENDER, sec.lastTopName) or U_.FEED_SENDER_NONE
    FC.v2.Text = string.format(U_.FEED_PER_S, sec.lastTop, CONFIG.FEED_SENDER_LIMIT)
    FC.bar2(sec.lastTop / CONFIG.FEED_SENDER_LIMIT)
    FC.v3.Text = tostring(FEED.droppedByServer)
    FC.v4.Text = FEED.modeRemote and FEED.label(FEED.serverMode or FEED.filter) or "—"
    end
    -- Barra de estado
    put(ST.dot, "BackgroundColor3", LOG.paused and TH.warn or TH.ok)
    put(ST.live, "Text", LOG.paused and U_.ST_PAUSED or U_.ST_LIVE)
    put(ST.live, "TextColor3", LOG.paused and TH.warn or TH.ok)
    local left = IS_PC and {string.format(U_.ST_REMOTES, #REG.remotes), string.format(U_.ST_LOGS, fmtInt(LOG.total)), string.format(U_.ST_SPAM, LOG.suppressed),
        string.format(U_.ST_QUEUE, REG.pending(), math.floor(REG.qMax)), string.format(U_.ST_ERRORS, G.internalErrors)}
        or {string.format(U_.ST_LOGS, fmtInt(LOG.total)), string.format(U_.ST_SPAM, LOG.suppressed), string.format(U_.ST_ERRORS, G.internalErrors)}
    for i, t in ipairs(ST.left) do put(t, "Text", left[i]) end
    local leftCap = MODE.captureLeft()
    local rightTxt = {string.format(U_.ST_MODE, MODE.def.label .. (leftCap and (" " .. leftCap .. "s") or "")), string.format(U_.ST_FPS, PERF.fps),
        string.format(U_.ST_PING, fmt(PERF.ping, "%.0f", " ms")), string.format(U_.ST_VER, CONFIG.VERSION)}
    for i, t in ipairs(ST.right) do put(t, "Text", rightTxt[i]) end
end

---------------- Abrir / cerrar / pestañas / escala / minimizar / arrastre
function UI.setTab(name)
    UI.tab = name
    CFG.set("tab", name)
    detail.Visible = false
    picker.Visible = false
    for n, p in pairs(UI.pages) do p.Visible = (n == name) end
    if METRIC.group then METRIC.group.Visible = (name == "MAIN" or name == "PERFORMANCE") end
    if DC.holder then DC.holder.Visible = false end
    UI.force = true
end

-- Cambiar de versión (Móvil / PC): se guarda y el panel se reinicia en esa versión.
function UI.setLayout(id)
    if id == LAYOUT then return end
    CFG.set("layout", id)
    UI.toast(string.format(STR.UI.LAYOUT_SWITCH, id == "pc" and STR.UI.LAYOUT[2] or STR.UI.LAYOUT[1]))
    task.delay(0.2, function() if G.restart then G.restart() end end)
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
    local show = not UI.collapsed
    sidebar.Visible, main.Visible, statusBar.Visible = show, show, show
    if right then right.Visible = show end
    if DC.holder and not show then DC.holder.Visible = false end
    local pw, ph = L.PANEL_W * sc, h * sc
    local margin = CONFIG.L.RADIUS
    local x, y
    if pw <= ss.X then x = math.clamp(CFG.get("x_" .. LAYOUT, (ss.X - pw) / 2), 0, ss.X - pw) else x = margin end
    if ph <= ss.Y then y = math.clamp(CFG.get("y_" .. LAYOUT, (ss.Y - ph) / 2), 0, ss.Y - ph) else y = margin end
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
    UI.targetScale = nextS
    tw(uiScale, {Scale = nextS}, CONFIG.ANIM.OPEN)
    CFG.set("scale_" .. LAYOUT, nextS)
    UI.applyLayout()
    UI.force = true
    return nextS
end
U.conn(W.scaleBtn.Activated, function() W.scaleBtn.Text = UI.scaleLabel(UI.cycleScale()) end, "escala")

function UI.toggle(state)
    if state == nil then state = not UI.open end
    UI.open = state
    viewport.Visible = state
    if state then
        UI.applyLayout()
        uiScale.Scale = UI.targetScale * 0.94
        tw(uiScale, {Scale = UI.targetScale}, CONFIG.ANIM.OPEN, Enum.EasingStyle.Quad)
        UI.force = true
    end
end
-- Tecla para abrir/cerrar (computadora o iPad con teclado). No actúa mientras escribes.
U.conn(S.UIS.InputBegan, function(input, processed)
    if processed then return end
    local ok, key = pcall(function() return Enum.KeyCode[CONFIG.TOGGLE_KEY] end)
    if ok and key and input.KeyCode == key then UI.toggle() end
end, "tecla abrir")
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
        if fitsScreen() then CFG.set("x_" .. LAYOUT, panel.Position.X.Offset); CFG.set("y_" .. LAYOUT, panel.Position.Y.Offset) end
    end)
end
draggable(fab, fab, function() return true end, function() UI.toggle() end, saveGeometry)
draggable(titleBar, panel, function() return (fitsScreen()) end, nil, saveGeometry)
U.conn(screen:GetPropertyChangedSignal("AbsoluteSize"), UI.applyLayout, "giro de pantalla")
task.defer(UI.applyLayout)

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
    return UI.open -- las tarjetas de métricas se ven en todas las pestañas
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
    PERF.tickEvents(now)
    if needsSample(now) then PERF.sample() end
    local drawing = MODE.drawAllowed()
    fabDot.BackgroundColor3 = (MODE.def.silent and MODE.alertPending) and TH.bad or (LOG.paused and TH.warn or TH.ok)
    if not drawing then return end  -- Silencioso: no se dibuja nada hasta una alerta
    UI.refreshControls(UI.controlLabels())
    if not UI.open or UI.collapsed then return end
    local tab = UI.tab
    local forced = UI.force
    if needsRender(tab, now) then renderTab(tab, now) end
    if forced or now - (LOOP.lastChrome or 0) >= CONFIG.REFRESH.MAIN * (MODE.def.tickMul or 1) then
        LOOP.lastChrome = now
        U.try("cromo", UI.renderChrome)
    end
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
UI.setTab(UI.pages[CFG.get("tab", "LOGS")] and CFG.get("tab", "LOGS") or "LOGS")
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
-- Reinicia todo el panel (lo usa el cambio de versión Móvil / PC).
function G.restart()
    G.destroy()
    task.defer(START)
end
U.conn(screen.AncestryChanged, function() if not screen.Parent then G.destroy() end end, "GUI eliminada")

end

-------------------------------------------------------------------------------
-- 13. STUDIO — generado por build.py desde GOY_Diagnostics_Studio_Server.lua (no editar aquí)
-------------------------------------------------------------------------------
STUDIO_SCRIPT = [==[
--[[
================================================================================
 GOY DIAGNOSTICS · SCRIPT DE SERVIDOR v1.3 (solo para TU propio juego)
 Dónde va: ServerScriptService → Script (no LocalScript).
--------------------------------------------------------------------------------
 QUÉ HACE
   · Escucha OnServerEvent de todos tus RemoteEvent / UnreliableRemoteEvent en
     cualquier contenedor (añade un oyente; no cambia la lógica del juego).
   · RemoteFunction: usa _G.GOYDiag.wrapInvoke(remote, tuFuncion) en lugar de
     remote.OnServerInvoke = tuFuncion y quedará registrado igual.
   · Registra jugador, userId, remoto, argumentos y tipos; avisa del spam por
     jugador y remoto (clave = instancia). Marca cada evento en el MicroProfiler
     (debug.profilebegin/profileend siempre balanceados).
   · Envía todo al panel GOY del cliente por GOY_DiagFeed, SOLO a espectadores
     autorizados, con un mensaje estructurado (protocolo 2).
   · Cada espectador elige qué ver por GOY_DiagMode: "all" (todos), "me" (solo
     sus propios eventos) o un UserId presente. El filtro se aplica AQUÍ, antes
     de enviar: no se gasta red en lo que no ve.
   · TP por GOY_DiagTP: un espectador autorizado puede ir junto a otro jugador
     de ESTE juego (por UserId). Valida autorización, 1 TP/s y personajes.
   · Presupuesto por espectador y por emisor: el spam de un jugador no puede
     gastar el cupo de los demás, y tus propios eventos tienen cupo reservado.
--------------------------------------------------------------------------------
 AUTORIZACIÓN (se resuelve en PlayerAdded, nunca mientras se envía)
   · En Roblox Studio (RunService:IsStudio()) → todos los jugadores de prueba.
   · El dueño del juego (game.CreatorId si el juego es de un usuario).
   · Juego de grupo: rango >= GROUP_MIN_RANK (si GetRankInGroup falla, se
     reintenta; los fallos no se guardan).
   · Los UserId de AUTHORIZED.
--------------------------------------------------------------------------------
 CAMBIOS v1.3: GOY_DiagTP (TP a jugadores por UserId, solo autorizados).
 CAMBIOS v1.2: presupuesto por espectador/emisor · feed estructurado (tipo,
 remoto, jugador, userId, args, tipos) · modos all/me/UserId validados en el
 servidor (máx. 2 peticiones/s) · autorización en PlayerAdded sin cachear fallos
 · aviso "Dropped" con lo descartado por espectador · ack de modo.
================================================================================
]]

local CONFIG = {
    AUTHORIZED = {},            -- UserIds extra que reciben el feed, ej. {12345678}
    GROUP_MIN_RANK = 254,       -- juegos de grupo: rango mínimo autorizado
    AUTH_RETRIES = 3,           -- reintentos si GetRankInGroup falla
    AUTH_RETRY_SEC = 10,
    PRINT = true,               -- imprime en la consola del servidor (F9 → Server)
    SPAM_PER_SECOND = 20,       -- aviso de spam por jugador y remoto
    VIEWER_PER_SECOND = 120,    -- mensajes/s máximos hacia cada espectador
    SENDER_PER_SECOND = 30,     -- mensajes/s de un mismo emisor hacia cada espectador
    MODE_REQ_PER_SECOND = 2,    -- peticiones de modo por espectador
    STATS_EVERY = 5,            -- s entre métricas del servidor
    DROPPED_EVERY = 1,          -- s entre avisos de mensajes descartados
    ARGS_MAX = 10, STR_MAX = 100, TABLE_ITEMS = 10, TABLE_DEPTH = 2,
    FEED_REMOTE = "GOY_DiagFeed",
    MODE_REMOTE = "GOY_DiagMode",
    TP_REMOTE = "GOY_DiagTP",   -- TP a otro jugador, solo para autorizados y solo en este juego
    TP_COOLDOWN = 1,            -- s entre TPs por jugador
    TP_OFFSET = 4,              -- studs detrás del jugador destino
    PROTOCOL = 2,
}

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local DataStoreService = game:GetService("DataStoreService")

local function getRemote(name)
    local r = RS:FindFirstChild(name)
    if not r then
        r = Instance.new("RemoteEvent")
        r.Name = name
        r.Parent = RS
    end
    return r
end
local feed = getRemote(CONFIG.FEED_REMOTE)
local modeRemote = getRemote(CONFIG.MODE_REMOTE)
feed.OnServerEvent:Connect(function() end) -- el cliente no puede enviar nada por el feed

---------------------------------------------------------------- AUTORIZACIÓN
local extra = {}
for _, id in ipairs(CONFIG.AUTHORIZED) do extra[id] = true end

local viewers = {} -- [player] = {mode, budget, senders, dropped, modeReq}

local function newViewer()
    return {mode = "all", winStart = 0, sent = 0, senders = {}, dropped = 0, modeWin = 0, modeCount = 0}
end

-- Devuelve true, false o nil (nil = no se pudo saber; se reintenta).
local function checkAuthorized(p)
    if RunService:IsStudio() or extra[p.UserId] then return true end
    if game.CreatorType == Enum.CreatorType.User then return p.UserId == game.CreatorId end
    if game.CreatorType == Enum.CreatorType.Group then
        local ok, rank = pcall(function() return p:GetRankInGroup(game.CreatorId) end)
        if not ok then return nil end
        return rank >= CONFIG.GROUP_MIN_RANK
    end
    return false
end

local function resolveAuth(p)
    for _ = 1, CONFIG.AUTH_RETRIES + 1 do
        if not p.Parent then return end
        local ok = checkAuthorized(p)
        if ok == true then
            viewers[p] = viewers[p] or newViewer()
            print(("[GOY DIAG] Feed autorizado para %s"):format(p.Name))
            return
        elseif ok == false then
            return
        end
        task.wait(CONFIG.AUTH_RETRY_SEC) -- fallo de red: no se guarda, se reintenta
    end
    warn(("[GOY DIAG] No se pudo comprobar el rango de %s; sin feed"):format(p.Name))
end

Players.PlayerAdded:Connect(function(p) task.spawn(resolveAuth, p) end)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(resolveAuth, p) end
Players.PlayerRemoving:Connect(function(p) viewers[p] = nil end)

local modeText = RunService:IsStudio() and "Studio (todos los jugadores de prueba)"
    or (game.CreatorType == Enum.CreatorType.Group and ("grupo, rango >= " .. CONFIG.GROUP_MIN_RANK) or "dueño del juego")
print("[GOY DIAG] Autorización del feed: " .. modeText .. (next(extra) and " + AUTHORIZED" or ""))

---------------------------------------------------------------- SERIALIZACIÓN
local function ser(v, depth)
    depth = depth or 0
    local t = typeof(v)
    if t == "string" then return string.format("%q", #v > CONFIG.STR_MAX and (v:sub(1, CONFIG.STR_MAX) .. "…") or v) end
    if t == "Instance" then return v.ClassName .. "(" .. v:GetFullName() .. ")" end
    if t == "table" then
        if depth >= CONFIG.TABLE_DEPTH then return "{…}" end
        local parts, n = {}, 0
        for k, x in pairs(v) do
            n += 1
            if n > CONFIG.TABLE_ITEMS then table.insert(parts, "…") break end
            table.insert(parts, tostring(k) .. "=" .. ser(x, depth + 1))
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    end
    return tostring(v)
end

local function describe(...)
    local n = select("#", ...)
    local args, types = {}, {}
    for i = 1, math.min(n, CONFIG.ARGS_MAX) do
        local v = select(i, ...)
        table.insert(types, typeof(v))
        table.insert(args, i .. ": " .. ser(v))
    end
    if n == 0 then args[1] = "(sin argumentos)" end
    return table.concat(args, "\n"), table.concat(types, ", ")
end

---------------------------------------------------------------- ENVÍO FILTRADO
-- ¿Quiere este espectador ver eventos de `sender`?
local function wants(v, viewerPlayer, sender)
    if sender == nil then return true end -- métricas y avisos generales
    if v.mode == "all" then return true end
    if v.mode == "me" then return sender == viewerPlayer end
    return sender.UserId == v.mode
end

-- Presupuesto: por emisor (para todos) y total por espectador; los eventos
-- del propio espectador no cuentan contra el total, así el spam ajeno no los tapa.
local function allow(v, viewerPlayer, sender)
    local now = os.clock()
    if now - v.winStart >= 1 then v.winStart, v.sent, v.senders = now, 0, {} end
    if sender then
        local key = sender.UserId
        local c = (v.senders[key] or 0) + 1
        if c > CONFIG.SENDER_PER_SECOND then return false end
        v.senders[key] = c
        if sender == viewerPlayer then return true end
    end
    if v.sent >= CONFIG.VIEWER_PER_SECOND then return false end
    v.sent += 1
    return true
end

local function deliver(msg, sender)
    msg.v = CONFIG.PROTOCOL
    for viewerPlayer, v in pairs(viewers) do
        if viewerPlayer.Parent and wants(v, viewerPlayer, sender) then
            if allow(v, viewerPlayer, sender) then
                feed:FireClient(viewerPlayer, msg)
            else
                v.dropped += 1
            end
        end
    end
end

-- Avisa a cada espectador cuántos mensajes se descartaron.
task.spawn(function()
    while true do
        task.wait(CONFIG.DROPPED_EVERY)
        for viewerPlayer, v in pairs(viewers) do
            if v.dropped > 0 and viewerPlayer.Parent then
                feed:FireClient(viewerPlayer, {v = CONFIG.PROTOCOL, kind = "Dropped", count = v.dropped})
                v.dropped = 0
            end
        end
    end
end)

---------------------------------------------------------------- MODOS (GOY_DiagMode)
local function validMode(m)
    if m == "all" or m == "me" then return m end
    local id = tonumber(m)
    if id and Players:GetPlayerByUserId(id) then return id end
    return nil
end

modeRemote.OnServerEvent:Connect(function(player, req)
    local v = viewers[player]
    if not v then return end -- no autorizado: se ignora
    local now = os.clock()
    if now - v.modeWin >= 1 then v.modeWin, v.modeCount = now, 0 end
    v.modeCount += 1
    if v.modeCount > CONFIG.MODE_REQ_PER_SECOND then return end
    local raw = type(req) == "table" and req.mode or req
    local mode = validMode(raw)
    if mode then v.mode = mode end
    feed:FireClient(player, {v = CONFIG.PROTOCOL, kind = "Mode", mode = v.mode, ok = mode ~= nil,
        reason = (not mode) and "valor no válido (usa all, me o un UserId presente)" or nil})
end)

---------------------------------------------------------------- TP (GOY_DiagTP)
-- Solo mueve al propio espectador autorizado junto a otro jugador de ESTE juego.
local tpRemote = getRemote(CONFIG.TP_REMOTE)
local lastTp = setmetatable({}, {__mode = "k"})
local function rootOf(p)
    local ch = p and p.Character
    return ch and ch:FindFirstChild("HumanoidRootPart"), ch
end
tpRemote.OnServerEvent:Connect(function(player, req)
    local function reply(ok, msg)
        feed:FireClient(player, {v = CONFIG.PROTOCOL, kind = "TP", ok = ok, msg = msg})
    end
    if not viewers[player] then return end -- no autorizado: se ignora
    local now = os.clock()
    if lastTp[player] and now - lastTp[player] < CONFIG.TP_COOLDOWN then return reply(false, "espera un segundo") end
    lastTp[player] = now
    local id = tonumber(type(req) == "table" and req.userId or req)
    local target = id and Players:GetPlayerByUserId(id)
    if not target then return reply(false, "ese jugador no está en el servidor") end
    if target == player then return reply(false, "no puedes hacer TP a ti mismo") end
    local to = rootOf(target)
    local from, ch = rootOf(player)
    if not to or not from then return reply(false, "falta el personaje de alguno de los dos") end
    ch:PivotTo(to.CFrame * CFrame.new(0, 0, CONFIG.TP_OFFSET))
    print(("[GOY DIAG] TP: %s → %s"):format(player.Name, target.Name))
    reply(true, "TP a " .. target.Name)
end)

---------------------------------------------------------------- REGISTRO DE EVENTOS
local spam = {} -- spam[player][remoteInstance] = {count, start}
local function overLimit(player, remote)
    local byRemote = spam[player]
    if not byRemote then byRemote = setmetatable({}, {__mode = "k"}); spam[player] = byRemote end
    local now = os.clock()
    local r = byRemote[remote]
    if not r or now - r.start >= 1 then r = {count = 0, start = now}; byRemote[remote] = r end
    r.count += 1
    return r.count == CONFIG.SPAM_PER_SECOND + 1
end
Players.PlayerRemoving:Connect(function(p) spam[p] = nil end)

local function record(kind, remote, player, ...)
    debug.profilebegin("GOY " .. kind .. " " .. remote.Name)
    local ok, err = pcall(function(...)
        local args, types = describe(...)
        local path = remote:GetFullName()
        if CONFIG.PRINT then
            print(("[GOY DIAG] %s %s ← %s (%d) | %s | tipos: %s"):format(kind, path, player.Name, player.UserId, args:gsub("\n", " | "), types))
        end
        deliver({kind = kind, remote = path, player = player.Name, userId = player.UserId, args = args, types = types}, player)
        if overLimit(player, remote) then
            warn(("[GOY DIAG] %s supera %d/s en %s"):format(player.Name, CONFIG.SPAM_PER_SECOND, path))
            deliver({kind = "Spam", remote = path, player = player.Name, userId = player.UserId,
                args = ">" .. CONFIG.SPAM_PER_SECOND .. "/s", types = ""}, player)
        end
    end, ...)
    debug.profileend() -- siempre se cierra, aunque falle el registro
    if not ok then warn("[GOY DIAG] error al registrar: " .. tostring(err)) end
end

local hooked = setmetatable({}, {__mode = "k"})
local function hook(obj)
    if hooked[obj] or obj == feed or obj == modeRemote or obj == tpRemote then return end
    local ok, isRemote = pcall(function() return obj:IsA("RemoteEvent") or obj:IsA("UnreliableRemoteEvent") end)
    if ok and isRemote then
        hooked[obj] = true
        obj.OnServerEvent:Connect(function(player, ...) record("OnServerEvent", obj, player, ...) end)
    end
end
for _, d in ipairs(game:GetDescendants()) do hook(d) end
game.DescendantAdded:Connect(hook)

_G.GOYDiag = {
    -- Envuelve TU función de RemoteFunction para registrarla (no toca la de nadie más).
    wrapInvoke = function(remote, handler)
        remote.OnServerInvoke = function(player, ...)
            record("OnServerInvoke", remote, player, ...)
            return handler(player, ...)
        end
    end,
}

---------------------------------------------------------------- MÉTRICAS DEL SERVIDOR
task.spawn(function()
    local frames, start = 0, os.clock()
    RunService.Heartbeat:Connect(function() frames += 1 end)
    while true do
        task.wait(CONFIG.STATS_EVERY)
        local now = os.clock()
        local hz = frames / (now - start)
        frames, start = 0, now
        local parts = {("Heartbeat %.1f Hz"):format(hz), ("memoria %.0f MB"):format(Stats:GetTotalMemoryUsageMb()),
            ("jugadores %d"):format(#Players:GetPlayers())}
        pcall(function() table.insert(parts, ("scripts %.0f MB"):format(Stats:GetMemoryUsageMbForTag(Enum.DeveloperMemoryTag.Script))) end)
        pcall(function() table.insert(parts, ("red ↓%.1f ↑%.1f KB/s"):format(Stats.DataReceiveKbps, Stats.DataSendKbps)) end)
        pcall(function()
            table.insert(parts, ("DataStore GET %d / SET %d"):format(
                DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.GetAsync),
                DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.SetIncrementAsync)))
        end)
        local msg = table.concat(parts, " · ")
        if CONFIG.PRINT then print("[GOY DIAG] " .. msg) end
        deliver({kind = "ServerStats", msg = msg}, nil)
    end
end)

print("[GOY DIAG] Instrumentación de servidor v1.2 activa.")
]==]
START()
