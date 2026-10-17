--[[
 GOY DIAGNOSTICS · SCRIPT DE SERVIDOR (solo para TU propio juego en Roblox Studio)
 Dónde va: ServerScriptService → Script (no LocalScript).
 Qué hace:
   · Escucha OnServerEvent de todos tus RemoteEvent / UnreliableRemoteEvent
     (agrega un oyente extra, no cambia la lógica de tu juego).
   · Registra jugador, remoto, argumentos, tipos y frecuencia por jugador;
     avisa si alguien supera MAX_PER_SECOND.
   · Marca cada evento con debug.profilebegin/profileend: aparece con nombre
     propio en el MicroProfiler (Ctrl+F6) y en el Script Profiler.
   · Para RemoteFunction: usa _G.GOYDiag.wrapInvoke(remote, tuFuncion) en lugar
     de remote.OnServerInvoke = tuFuncion, y quedará registrado igual.
   · Si pones tu UserId en AUTHORIZED, envía lo registrado al panel GOY del
     cliente por el remoto "GOY_DiagFeed" (categoría "Servidor"). A nadie más.
]]

local CONFIG = {
    AUTHORIZED = {},          -- ej. {12345678}: solo estos jugadores reciben el feed
    PRINT = true,             -- imprime en la consola del servidor (F9 → Server)
    MAX_PER_SECOND = 20,      -- aviso de spam por jugador y remoto
    FEED_PER_SECOND = 20,     -- máximo de mensajes por segundo hacia el panel
    STATS_EVERY = 5,          -- segundos entre envíos de métricas del servidor
    ROOTS = {"ReplicatedStorage", "Workspace", "ReplicatedFirst"},
}

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local authorized = {}
for _, id in ipairs(CONFIG.AUTHORIZED) do authorized[id] = true end

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
        if authorized[p.UserId] then feed:FireClient(p, ...) end
    end
end

local rate = {} -- rate[player][remoteName] = {count, start}
local function overLimit(player, name)
    rate[player] = rate[player] or {}
    local r = rate[player][name]
    local now = os.clock()
    if not r or now - r.start >= 1 then r = {count = 0, start = now}; rate[player][name] = r end
    r.count += 1
    return r.count == CONFIG.MAX_PER_SECOND + 1
end
Players.PlayerRemoving:Connect(function(p) rate[p] = nil end)

local function record(kind, remote, player, ...)
    debug.profilebegin("GOY " .. kind .. " " .. remote.Name)
    local args, types = describe(...)
    if CONFIG.PRINT then
        print(("[GOY DIAG] %s %s ← %s | %s | tipos: %s"):format(kind, remote:GetFullName(), player.Name, args, types))
    end
    sendFeed(kind, remote:GetFullName(), player.Name, args, types)
    if overLimit(player, remote.Name) then
        warn(("[GOY DIAG] %s supera %d/s en %s"):format(player.Name, CONFIG.MAX_PER_SECOND, remote:GetFullName()))
        sendFeed("Spam", remote:GetFullName(), player.Name, ">" .. CONFIG.MAX_PER_SECOND .. "/s", "")
    end
    debug.profileend()
end

local hooked = setmetatable({}, {__mode = "k"})
local function hook(obj)
    if hooked[obj] or obj == feed then return end
    if obj:IsA("RemoteEvent") or obj:IsA("UnreliableRemoteEvent") then
        hooked[obj] = true
        obj.OnServerEvent:Connect(function(player, ...) record("OnServerEvent", obj, player, ...) end)
    end
end
for _, rootName in ipairs(CONFIG.ROOTS) do
    local root = game:GetService(rootName)
    for _, d in ipairs(root:GetDescendants()) do hook(d) end
    root.DescendantAdded:Connect(hook)
end

-- RemoteFunction: envuelve TU función para registrarla.
_G.GOYDiag = {
    wrapInvoke = function(remote, handler)
        remote.OnServerInvoke = function(player, ...)
            record("OnServerInvoke", remote, player, ...)
            return handler(player, ...)
        end
    end,
}

-- Métricas del servidor (solo visibles en el servidor / feed autorizado).
task.spawn(function()
    local frames, start = 0, os.clock()
    RunService.Heartbeat:Connect(function() frames += 1 end)
    while true do
        task.wait(CONFIG.STATS_EVERY)
        local now = os.clock()
        local hz = frames / (now - start)
        frames, start = 0, now
        local mem = Stats:GetTotalMemoryUsageMb()
        local msg = ("Heartbeat %.1f Hz · memoria servidor %.0f MB · jugadores %d"):format(hz, mem, #Players:GetPlayers())
        if CONFIG.PRINT then print("[GOY DIAG] " .. msg) end
        sendFeed("ServerStats", msg)
    end
end)

print("[GOY DIAG] Instrumentación de servidor activa.")
