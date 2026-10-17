
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
STR.CODE = {HEAD = "Lo que te envió el servidor (solo lectura; este código no envía nada)",
    FROM = "Remoto: %s  (%s · Servidor → Cliente)", AT = "Hora: %s · %d argumento(s)",
    LISTEN = "Así lo escucha un LocalScript de tu juego:", TITLE = "Código recibido · %s",
    FEED_HEAD = "Lo que registró tu script de Studio (OnServerEvent en TU juego)"}
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
    D_COPY = "Copiar", D_WATCH = "Vigilar", D_UNWATCH = "No vigilar", D_INSPECT = "Inspeccionar", D_CODE = "Código", D_NO_INST = "Ese objeto no está en tu cliente",
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
