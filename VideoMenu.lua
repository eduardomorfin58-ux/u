--[[
    VIDEO MENU v2  -  menú que reproduce un video con sonido al abrirse
    ------------------------------------------------------------------
    * Al abrir el menú: el video empieza desde el principio CON audio.
    * Al cerrar el menú: el video se pausa.
    * Abrir/cerrar: RightShift (PC) o el botón flotante (celular).

    DETECCIÓN AUTOMÁTICA
    El script consulta tu repo de GitHub, encuentra los archivos de video
    (.webm / .mp4 / .mov), los prueba uno por uno (los más livianos y con
    "menu" en el nombre primero) y se queda con el primero que cargue.
    Si ningún video carga, busca un audio (.ogg / .mp3) para que al menos
    se escuche la música.

    NOTA: Roblox no reproduce links de GitHub directamente. Por eso el script
    descarga el archivo, lo guarda con writefile y lo carga con
    getcustomasset (necesita un ejecutor con esas funciones). Si subiste el
    video a Roblox, pon su ID en ROBLOX_ASSET_ID y no necesitas nada más.
]]

-- ================= CONFIGURACIÓN =================
local CONFIG = {
    REPO_OWNER = "eduardomorfin58-ux",
    REPO_NAME = "u",
    REPO_BRANCH = "main",

    -- Opcional: "rbxassetid://TU_ID" si subiste el video a Roblox
    ROBLOX_ASSET_ID = nil,

    MAX_FILE_MB = 40,           -- ignora archivos más pesados que esto
    USE_SEPARATE_AUDIO = false, -- true = video en mute + audio aparte (si el video no suena)

    TOGGLE_KEY = Enum.KeyCode.RightShift,
    START_VOLUME = 0.8,
    LOOPED = true,
    TITLE = "MENU",
}
-- ================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

local function getGuiParent()
    local ok, hui = pcall(function()
        return gethui and gethui()
    end)
    if ok and hui then return hui end
    local ok2 = pcall(function() return CoreGui.Name end)
    if ok2 then return CoreGui end
    return player:WaitForChild("PlayerGui")
end

local guiParent = getGuiParent()
local old = guiParent:FindFirstChild("VideoMenuGui")
if old then old:Destroy() end

-- ================= RED / GITHUB =================
local function httpGet(url)
    local ok, res = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and type(res) == "string" and #res > 0 then return res end

    local req = (syn and syn.request) or http_request or request or (http and http.request)
    if req then
        local ok2, r = pcall(req, { Url = url, Method = "GET" })
        if ok2 and r and (r.StatusCode == 200 or r.Success) and r.Body and #r.Body > 0 then
            return r.Body
        end
    end
    return nil
end

local function extOf(name)
    local e = name:match("%.([%w]+)$")
    return e and e:lower() or ""
end

local function encodePath(name)
    return (name:gsub("[^%w%-%._~]", function(c)
        return string.format("%%%02X", string.byte(c))
    end))
end

local function rawUrl(name)
    return ("https://raw.githubusercontent.com/%s/%s/%s/%s"):format(
        CONFIG.REPO_OWNER, CONFIG.REPO_NAME, CONFIG.REPO_BRANCH, encodePath(name)
    )
end

-- Lista los archivos del repo (API de GitHub). Devuelve nil si falla.
local function listRepoFiles()
    local api = ("https://api.github.com/repos/%s/%s/contents/?ref=%s"):format(
        CONFIG.REPO_OWNER, CONFIG.REPO_NAME, CONFIG.REPO_BRANCH
    )
    local body = httpGet(api)
    if not body then return nil end
    local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
    if not ok or type(data) ~= "table" then return nil end
    local files = {}
    for _, item in ipairs(data) do
        if type(item) == "table" and item.type == "file" and item.name then
            table.insert(files, {
                name = item.name,
                size = item.size or 0,
                url = item.download_url or rawUrl(item.name),
            })
        end
    end
    return files
end

local VIDEO_RANK = { webm = 1, mp4 = 2, mov = 3 }
local AUDIO_RANK = { ogg = 1, mp3 = 2 }

-- Ordena candidatos: con "menu" en el nombre primero, luego mejor formato, luego más liviano.
local function pickCandidates(files, rankTable)
    local list = {}
    local maxBytes = CONFIG.MAX_FILE_MB * 1024 * 1024
    for _, f in ipairs(files) do
        local rank = rankTable[extOf(f.name)]
        if rank and (f.size == 0 or f.size <= maxBytes) then
            f.score = rank + (f.name:lower():find("menu") and -10 or 0)
            table.insert(list, f)
        end
    end
    table.sort(list, function(a, b)
        if a.score ~= b.score then return a.score < b.score end
        return a.size < b.size
    end)
    return list
end

-- Si la API de GitHub falla, prueba nombres comunes directamente.
local function fallbackCandidates(kind)
    local names = kind == "video"
        and { "menu_video.webm", "menu_video.mp4", "menu_video_1.webm", "menu_video_2.webm" }
        or { "menu_audio.ogg", "menu_audio.mp3" }
    local list = {}
    for _, n in ipairs(names) do
        table.insert(list, { name = n, size = 0, url = rawUrl(n) })
    end
    return list
end

-- Descarga un candidato y devuelve el asset local listo para Roblox.
local function fetchAsset(c)
    if not (writefile and getcustomasset) then
        return nil, "tu ejecutor no tiene writefile/getcustomasset"
    end
    local data = httpGet(c.url)
    if not data or #data < 1000 then
        return nil, "no se pudo descargar " .. c.name
    end
    local cache = "vm_" .. c.name:gsub("[^%w%._%-]", "_")
    local okW, errW = pcall(writefile, cache, data)
    if not okW then return nil, "no se pudo guardar: " .. tostring(errW) end
    local okA, asset = pcall(getcustomasset, cache)
    if not okA or not asset then return nil, "getcustomasset falló con " .. c.name end
    return asset
end

-- ================= UI =================
local gui = Instance.new("ScreenGui")
gui.Name = "VideoMenuGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = guiParent

local function corner(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = obj
    return c
end

local openBtn = Instance.new("TextButton")
openBtn.Name = "OpenButton"
openBtn.Size = UDim2.fromOffset(110, 36)
openBtn.Position = UDim2.new(0, 14, 0.5, -18)
openBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
openBtn.TextColor3 = Color3.new(1, 1, 1)
openBtn.Font = Enum.Font.GothamBold
openBtn.TextSize = 14
openBtn.Text = CONFIG.TITLE
openBtn.Visible = false
openBtn.Parent = gui
corner(openBtn, 10)

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(560, 340)
main.Position = UDim2.new(0.5, -280, 0.5, -170)
main.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Visible = false
main.Parent = gui
corner(main, 14)

local video = Instance.new("VideoFrame")
video.Name = "Video"
video.Size = UDim2.fromScale(1, 1)
video.BackgroundTransparency = 1
video.Looped = CONFIG.LOOPED
video.Volume = CONFIG.START_VOLUME
video.ZIndex = 1
video.Parent = main

local shade = Instance.new("Frame")
shade.Size = UDim2.fromScale(1, 1)
shade.BackgroundColor3 = Color3.new(0, 0, 0)
shade.BackgroundTransparency = 0.6
shade.BorderSizePixel = 0
shade.ZIndex = 2
shade.Parent = main

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundTransparency = 1
titleBar.ZIndex = 3
titleBar.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 1, 0)
title.Position = UDim2.fromOffset(16, 0)
title.BackgroundTransparency = 1
title.Text = CONFIG.TITLE
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBlack
title.TextSize = 18
title.ZIndex = 4
title.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(30, 30)
closeBtn.Position = UDim2.new(1, -38, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 60)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.ZIndex = 5
closeBtn.Parent = titleBar
corner(closeBtn, 8)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -32, 0, 40)
status.Position = UDim2.new(0, 16, 0, 44)
status.BackgroundTransparency = 1
status.Text = ""
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.TextColor3 = Color3.fromRGB(255, 220, 120)
status.Font = Enum.Font.Gotham
status.TextSize = 13
status.ZIndex = 4
status.Parent = main

local controls = Instance.new("Frame")
controls.Size = UDim2.new(1, -32, 0, 44)
controls.Position = UDim2.new(0, 16, 1, -60)
controls.BackgroundColor3 = Color3.new(0, 0, 0)
controls.BackgroundTransparency = 0.35
controls.ZIndex = 4
controls.Parent = main
corner(controls, 10)

local function makeButton(text, x, w)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(w, 30)
    b.Position = UDim2.fromOffset(x, 7)
    b.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.Text = text
    b.ZIndex = 5
    b.Parent = controls
    corner(b, 8)
    return b
end

local playBtn = makeButton("Pausar", 8, 90)
local muteBtn = makeButton("Sonido", 106, 90)
local restartBtn = makeButton("Reiniciar", 204, 96)

local sliderBack = Instance.new("Frame")
sliderBack.Size = UDim2.fromOffset(150, 8)
sliderBack.Position = UDim2.new(1, -164, 0.5, -4)
sliderBack.BackgroundColor3 = Color3.fromRGB(70, 70, 85)
sliderBack.ZIndex = 5
sliderBack.Parent = controls
corner(sliderBack, 4)

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.fromScale(CONFIG.START_VOLUME, 1)
sliderFill.BackgroundColor3 = Color3.fromRGB(90, 170, 255)
sliderFill.ZIndex = 6
sliderFill.Parent = sliderBack
corner(sliderFill, 4)

local knob = Instance.new("Frame")
knob.Size = UDim2.fromOffset(16, 16)
knob.AnchorPoint = Vector2.new(0.5, 0.5)
knob.Position = UDim2.new(CONFIG.START_VOLUME, 0, 0.5, 0)
knob.BackgroundColor3 = Color3.new(1, 1, 1)
knob.ZIndex = 7
knob.Parent = sliderBack
corner(knob, 8)

-- ================= MEDIA =================
local videoReady = false
local sound = nil            -- Sound de respaldo / audio aparte
local soundMode = "video"    -- "video" | "separate" | "audioonly"
local volume = CONFIG.START_VOLUME
local lastVolume = CONFIG.START_VOLUME
local muted = false
local isOpen = false
local loading = false
local loadedOnce = false

local function applyVolume()
    if soundMode == "video" then
        video.Volume = volume
    elseif soundMode == "separate" then
        video.Volume = 0
    end
    if sound then sound.Volume = volume end
end

local function setVolume(v)
    volume = math.clamp(v, 0, 1)
    sliderFill.Size = UDim2.fromScale(volume, 1)
    knob.Position = UDim2.new(volume, 0, 0.5, 0)
    if volume > 0 then
        lastVolume = volume
        muted = false
        muteBtn.Text = "Sonido"
    else
        muted = true
        muteBtn.Text = "Mute"
    end
    applyVolume()
end

local function mediaPlay(fromStart)
    if videoReady then
        if fromStart then video.TimePosition = 0 end
        video:Play()
    end
    if sound and soundMode ~= "video" then
        if fromStart then sound.TimePosition = 0 end
        sound:Play()
    end
    playBtn.Text = "Pausar"
end

local function mediaPause()
    if videoReady then video:Pause() end
    if sound then sound:Pause() end
    playBtn.Text = "Reanudar"
end

local function isPlaying()
    if videoReady then return video.Playing end
    if sound then return sound.Playing end
    return false
end

-- Busca y prueba los candidatos hasta que uno cargue.
local function tryLoadVideo()
    if CONFIG.ROBLOX_ASSET_ID then
        video.Video = CONFIG.ROBLOX_ASSET_ID
        local t0 = os.clock()
        while not video.IsLoaded and os.clock() - t0 < 20 do task.wait(0.1) end
        return video.IsLoaded
    end

    status.Text = "Buscando video en GitHub..."
    local files = listRepoFiles()
    local candidates = files and pickCandidates(files, VIDEO_RANK) or {}
    if #candidates == 0 then candidates = fallbackCandidates("video") end

    local lastErr = "no se encontró ningún video"
    for _, c in ipairs(candidates) do
        status.Text = "Probando " .. c.name .. "..."
        local asset, err = fetchAsset(c)
        if asset then
            video.Video = asset
            local t0 = os.clock()
            while not video.IsLoaded and os.clock() - t0 < 15 do task.wait(0.1) end
            if video.IsLoaded then
                status.Text = ""
                return true
            end
            lastErr = c.name .. " no se pudo reproducir (formato no soportado)"
        else
            lastErr = err
        end
    end
    status.Text = "No cargó el video: " .. tostring(lastErr)
    return false
end

local function tryLoadAudio()
    status.Text = "Buscando audio..."
    local files = listRepoFiles()
    local candidates = files and pickCandidates(files, AUDIO_RANK) or {}
    if #candidates == 0 then candidates = fallbackCandidates("audio") end

    for _, c in ipairs(candidates) do
        local asset = fetchAsset(c)
        if asset then
            local s = Instance.new("Sound")
            s.Name = "MenuAudio"
            s.SoundId = asset
            s.Looped = CONFIG.LOOPED
            s.Volume = volume
            s.Parent = gui
            local t0 = os.clock()
            while not s.IsLoaded and os.clock() - t0 < 10 do task.wait(0.1) end
            if s.IsLoaded then
                sound = s
                return true
            end
            s:Destroy()
        end
    end
    return false
end

local function loadMedia()
    local okVideo = tryLoadVideo()
    videoReady = okVideo

    if okVideo then
        soundMode = "video"
        if CONFIG.USE_SEPARATE_AUDIO and tryLoadAudio() then
            soundMode = "separate"
            -- mantiene el audio alineado cuando el video da la vuelta
            video.DidLoop:Connect(function()
                if sound and isOpen then sound.TimePosition = 0 end
            end)
        end
        if soundMode == "video" then status.Text = "" end
    else
        -- Plan B: al menos que suene la música
        if tryLoadAudio() then
            soundMode = "audioonly"
            status.Text = "El video no cargó, pero la música sí suena."
        end
    end
    applyVolume()
    loadedOnce = true
end

-- ================= ABRIR / CERRAR =================
local function openMenu()
    if isOpen then return end
    isOpen = true
    main.Visible = true
    openBtn.Visible = false

    if loadedOnce then
        mediaPlay(true)
    elseif not loading then
        loading = true
        task.spawn(function()
            loadMedia()
            loading = false
            if isOpen then mediaPlay(true) end
        end)
    end
end

local function closeMenu()
    if not isOpen then return end
    isOpen = false
    main.Visible = false
    openBtn.Visible = true
    if loadedOnce then mediaPause() end
end

openBtn.MouseButton1Click:Connect(openMenu)
closeBtn.MouseButton1Click:Connect(closeMenu)

playBtn.MouseButton1Click:Connect(function()
    if not loadedOnce then return end
    if isPlaying() then mediaPause() else mediaPlay(false) end
end)

restartBtn.MouseButton1Click:Connect(function()
    if not loadedOnce then return end
    mediaPlay(true)
end)

muteBtn.MouseButton1Click:Connect(function()
    if muted then
        setVolume(lastVolume > 0 and lastVolume or 0.8)
    else
        local keep = volume
        setVolume(0)
        lastVolume = keep
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == CONFIG.TOGGLE_KEY then
        if isOpen then closeMenu() else openMenu() end
    end
end)

-- Slider (mouse y touch)
local draggingSlider = false
local function updateSlider(x)
    setVolume((x - sliderBack.AbsolutePosition.X) / sliderBack.AbsoluteSize.X)
end
sliderBack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        draggingSlider = true
        updateSlider(input.Position.X)
    end
end)

-- Mover ventana desde la barra de título
local draggingWindow, dragStart, startPos = false, nil, nil
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        draggingWindow = true
        dragStart = input.Position
        startPos = main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end
    if draggingSlider then
        updateSlider(input.Position.X)
    elseif draggingWindow then
        local d = input.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        draggingSlider = false
        draggingWindow = false
    end
end)

openMenu()
