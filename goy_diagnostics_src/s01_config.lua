--[[
================================================================================
 GOY DIAGNOSTICS v1.2 Pro  ·  Diagnóstico de remotos y servidor (SOLO LECTURA)
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
    VERSION = "1.2 Pro",

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
    },
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
