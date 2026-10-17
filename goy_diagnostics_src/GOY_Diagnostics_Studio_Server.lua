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
