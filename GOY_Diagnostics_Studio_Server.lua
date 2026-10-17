--[[
 GOY DIAGNOSTICS · SCRIPT DE SERVIDOR v1.1 (solo para TU propio juego en Roblox Studio)
 Dónde va: ServerScriptService → Script (no LocalScript).
 Qué hace:
   · Escucha OnServerEvent de todos tus RemoteEvent / UnreliableRemoteEvent, en
     cualquier contenedor (agrega un oyente extra, no cambia la lógica del juego).
   · Registra jugador, remoto, argumentos, tipos y frecuencia por jugador y por
     remoto (clave = la instancia, no el nombre); avisa si se supera MAX_PER_SECOND.
   · Marca cada evento con debug.profilebegin/profileend (siempre balanceados):
     aparece con nombre propio en el MicroProfiler (Ctrl+F6) y en el Script Profiler.
   · RemoteFunction: usa _G.GOYDiag.wrapInvoke(remote, tuFuncion) en lugar de
     remote.OnServerInvoke = tuFuncion, y quedará registrado igual.
   · Envía lo registrado al panel GOY del cliente por "GOY_DiagFeed" solo a
     jugadores autorizados (ver AUTORIZACIÓN). A nadie más.
 AUTORIZACIÓN (cualquiera de estas):
   · En Roblox Studio (RunService:IsStudio()) → todos los jugadores de la prueba.
   · El dueño del juego (game.CreatorId si el juego es de un usuario).
   · Si el juego es de un grupo: rango >= GROUP_MIN_RANK en ese grupo.
   · Los UserId que pongas en AUTHORIZED.
 Cambios v1.1: profileend garantizado, limitador por instancia, engancha todo el
 juego, autorización por Studio/dueño/grupo con aviso, métricas extra.
]]

local CONFIG = {
    AUTHORIZED = {},          -- ej. {12345678}: UserIds extra que reciben el feed
    GROUP_MIN_RANK = 254,     -- si el juego es de un grupo: rango mínimo autorizado
    PRINT = true,             -- imprime en la consola del servidor (F9 → Server)
    MAX_PER_SECOND = 20,      -- aviso de spam por jugador y remoto
    FEED_PER_SECOND = 20,     -- máximo de mensajes por segundo hacia el panel
    STATS_EVERY = 5,          -- segundos entre envíos de métricas del servidor
}

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local DataStoreService = game:GetService("DataStoreService")

local extra = {}
for _, id in ipairs(CONFIG.AUTHORIZED) do extra[id] = true end

local authCache = {}
local function isAuthorized(p)
    if authCache[p] ~= nil then return authCache[p] end
    local ok = false
    if RunService:IsStudio() or extra[p.UserId] then
        ok = true
    elseif game.CreatorType == Enum.CreatorType.User and p.UserId == game.CreatorId then
        ok = true
    elseif game.CreatorType == Enum.CreatorType.Group then
        local s, rank = pcall(function() return p:GetRankInGroup(game.CreatorId) end)
        ok = s and rank >= CONFIG.GROUP_MIN_RANK
    end
    authCache[p] = ok
    if ok then print(("[GOY DIAG] Feed autorizado para %s"):format(p.Name)) end
    return ok
end
Players.PlayerRemoving:Connect(function(p) authCache[p] = nil end)

local mode = RunService:IsStudio() and "Studio (todos los jugadores de prueba)"
    or (game.CreatorType == Enum.CreatorType.Group and ("grupo, rango >= " .. CONFIG.GROUP_MIN_RANK) or "dueño del juego")
print("[GOY DIAG] Autorización del feed: " .. mode .. (next(extra) and " + AUTHORIZED" or ""))

local feed = RS:FindFirstChild("GOY_DiagFeed")
if not feed then
    feed = Instance.new("RemoteEvent")
    feed.Name = "GOY_DiagFeed"
    feed.Parent = RS
end
-- El cliente nunca puede usar el feed para enviar nada.
feed.OnServerEvent:Connect(function() end)

local function ser(v, depth)
    depth = depth or 0
    local t = typeof(v)
    if t == "string" then return string.format("%q", #v > 100 and (v:sub(1, 100) .. "…") or v) end
    if t == "Instance" then return v.ClassName .. "(" .. v:GetFullName() .. ")" end
    if t == "table" then
        if depth >= 2 then return "{…}" end
        local parts, n = {}, 0
        for k, x in pairs(v) do
            n += 1
            if n > 10 then table.insert(parts, "…") break end
            table.insert(parts, tostring(k) .. "=" .. ser(x, depth + 1))
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    end
    return tostring(v)
end

local function describe(...)
    local n = select("#", ...)
    local args, types = {}, {}
    for i = 1, math.min(n, 10) do
        local v = select(i, ...)
        table.insert(types, typeof(v))
        table.insert(args, i .. ": " .. ser(v))
    end
    return table.concat(args, " | "), table.concat(types, ", ")
end

local sentThisSecond, secondStart = 0, os.clock()
local function sendFeed(...)
    local now = os.clock()
    if now - secondStart >= 1 then sentThisSecond, secondStart = 0, now end
    if sentThisSecond >= CONFIG.FEED_PER_SECOND then return end
    sentThisSecond += 1
    for _, p in ipairs(Players:GetPlayers()) do
        if isAuthorized(p) then feed:FireClient(p, ...) end
    end
end

local rate = {} -- rate[player][remoteInstance] = {count, start}
local function overLimit(player, remote)
    local byRemote = rate[player]
    if not byRemote then byRemote = setmetatable({}, {__mode = "k"}); rate[player] = byRemote end
    local r = byRemote[remote]
    local now = os.clock()
    if not r or now - r.start >= 1 then r = {count = 0, start = now}; byRemote[remote] = r end
    r.count += 1
    return r.count == CONFIG.MAX_PER_SECOND + 1
end
Players.PlayerRemoving:Connect(function(p) rate[p] = nil end)

local function record(kind, remote, player, ...)
    debug.profilebegin("GOY " .. kind .. " " .. remote.Name)
    local ok, err = pcall(function(...)
        local args, types = describe(...)
        if CONFIG.PRINT then
            print(("[GOY DIAG] %s %s ← %s | %s | tipos: %s"):format(kind, remote:GetFullName(), player.Name, args, types))
        end
        sendFeed(kind, remote:GetFullName(), player.Name, args, types)
        if overLimit(player, remote) then
            warn(("[GOY DIAG] %s supera %d/s en %s"):format(player.Name, CONFIG.MAX_PER_SECOND, remote:GetFullName()))
            sendFeed("Spam", remote:GetFullName(), player.Name, ">" .. CONFIG.MAX_PER_SECOND .. "/s", "")
        end
    end, ...)
    debug.profileend() -- siempre se cierra, aunque describe falle
    if not ok then warn("[GOY DIAG] error al registrar: " .. tostring(err)) end
end

local hooked = setmetatable({}, {__mode = "k"})
local function hook(obj)
    if hooked[obj] or obj == feed then return end
    local ok, isRemote = pcall(function() return obj:IsA("RemoteEvent") or obj:IsA("UnreliableRemoteEvent") end)
    if ok and isRemote then
        hooked[obj] = true
        obj.OnServerEvent:Connect(function(player, ...) record("OnServerEvent", obj, player, ...) end)
    end
end
-- Todo el juego: cualquier contenedor donde tengas remotos.
for _, d in ipairs(game:GetDescendants()) do hook(d) end
game.DescendantAdded:Connect(hook)

-- RemoteFunction: envuelve TU función para registrarla.
_G.GOYDiag = {
    wrapInvoke = function(remote, handler)
        remote.OnServerInvoke = function(player, ...)
            record("OnServerInvoke", remote, player, ...)
            return handler(player, ...)
        end
    end,
}

-- Métricas del servidor (consola del servidor + feed autorizado).
task.spawn(function()
    local frames, start = 0, os.clock()
    RunService.Heartbeat:Connect(function() frames += 1 end)
    while true do
        task.wait(CONFIG.STATS_EVERY)
        local now = os.clock()
        local hz = frames / (now - start)
        frames, start = 0, now
        local mem = Stats:GetTotalMemoryUsageMb()
        local parts = {("Heartbeat %.1f Hz"):format(hz), ("memoria %.0f MB"):format(mem), ("jugadores %d"):format(#Players:GetPlayers())}
        pcall(function() table.insert(parts, ("scripts %.0f MB"):format(Stats:GetMemoryUsageMbForTag(Enum.DeveloperMemoryTag.Script))) end)
        pcall(function() table.insert(parts, ("red ↓%.1f ↑%.1f KB/s"):format(Stats.DataReceiveKbps, Stats.DataSendKbps)) end)
        pcall(function()
            table.insert(parts, ("DataStore GET %d / SET %d"):format(
                DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.GetAsync),
                DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.SetIncrementAsync)))
        end)
        local msg = table.concat(parts, " · ")
        if CONFIG.PRINT then print("[GOY DIAG] " .. msg) end
        sendFeed("ServerStats", msg)
    end
end)

print("[GOY DIAG] Instrumentación de servidor v1.1 activa.")
