--[[
================================================================================
 GOY DIAGNOSTICS v1.2  ·  Diagnóstico de remotos y servidor (SOLO LECTURA)
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
    VERSION = "1.2",

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
        {id = "normal",  label = "Normal",        tickMul = 1, sampleEvery = 1, graph = true},
        {id = "server",  label = "Solo servidor", cats = {Servidor = true}, tickMul = 1, sampleEvery = 1, graph = true},
        {id = "alerts",  label = "Alertas",       alertsOnly = true, tickMul = 1, sampleEvery = 1, graph = true},
        {id = "changes", label = "Cambios",       cats = {Valor = true, Cambio = true, Tool = true}, tickMul = 1, sampleEvery = 1, graph = true},
        {id = "capture", label = "Captura",       capture = true, tickMul = 1, sampleEvery = 1, graph = true},
        {id = "saver",   label = "Ahorro",        tickMul = 3, sampleEvery = 2, maxRows = 60, graph = false},
        {id = "silent",  label = "Silencioso",    silent = true, tickMul = 3, sampleEvery = 2, graph = false},
    },

    -- Interfaz
    TOUCH = 44,                    -- alto mínimo táctil (px)
    HEADER_H = 52, TAB_BAR_H = 46, TOOLBAR_H = 48, FOOTER_H = 20, GAP = 4, MARGIN = 8,
    TAB_W = 96, TAB_W_WIDE = 122,
    ROW_H = 56, ROW_GAP = 5, ROW_SPARE = 3,
    FAB_SIZE = 60,
    PANEL_MIN_W = 300, PANEL_MIN_H = 240, PANEL_VP_W = 0.92, PANEL_VP_H = 0.86, SCREEN_PAD = 8,
    DRAG_THRESHOLD = 8,
    SCALES = {0.65, 0.85, 1, 1.15, 1.3},
    DETAIL_CHUNK = 2500, DETAIL_MAX = 60000,
    TOAST_SEC = 2.6,
    PERF_HISTORY = 30,             -- segundos de la gráfica de FPS
    MAIN_RECENT = 5,               -- eventos recientes en MAIN

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
    OBSERVED = "Observado", GUI = "Interfaz local", CONSOLE = "Consola del cliente", C2S = "Cliente → Servidor (%s)",
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

-------------------------------------------------------------------------------
-- 13. STUDIO — generado por build.py desde GOY_Diagnostics_Studio_Server.lua (no editar aquí)
-------------------------------------------------------------------------------
STUDIO_SCRIPT = [==[
--[[
================================================================================
 GOY DIAGNOSTICS · SCRIPT DE SERVIDOR v1.2 (solo para TU propio juego)
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
        reason = mode and nil or "valor no válido (usa all, me o un UserId presente)"})
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
    if hooked[obj] or obj == feed or obj == modeRemote then return end
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
