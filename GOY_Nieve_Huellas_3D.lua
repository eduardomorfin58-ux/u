--[[
  GOY | Entorno Invernal + Huellas 3D  (100% LOCAL, solo tu pantalla)
  - Vuelve a ejecutar el script, pulsa F6 o toca el botón ❄ para quitar/poner la nieve.
  - No toca el servidor, ni otros jugadores, ni GUIs, ni líneas verdes de parcelas.
]]

local Players      = game:GetService("Players")
local Lighting     = game:GetService("Lighting")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local Debris       = game:GetService("Debris")

local LP     = Players.LocalPlayer
local ENV    = (getgenv and getgenv()) or _G

-- Volver a ejecutar = apagar todo y salir
if ENV.GOY_SNOW and ENV.GOY_SNOW.destroy then
	pcall(ENV.GOY_SNOW.destroy)
	ENV.GOY_SNOW = nil
	return
end

---------------------------------------------------------------------
-- AJUSTES
---------------------------------------------------------------------
local CFG = {
	SNOW_COLOR      = Color3.fromRGB(238, 243, 249),
	ROCK_TINT       = 0.78,          -- cuánto se blanquean paredes/rocas (0-1)
	PRINT_COLOR     = Color3.fromHex and Color3.fromHex("#9BB9D7") or Color3.fromRGB(155, 185, 215),
	PRINT_DEEP      = Color3.fromRGB(128, 160, 196),
	RIM_COLOR       = Color3.fromRGB(250, 252, 255),
	STRIDE          = 2.3,           -- distancia entre pasos (studs)
	PRINT_LIFE      = 7,             -- segundos visibles antes de desvanecer
	PRINT_FADE      = 4,
	PRINT_ROT       = 0,             -- si la huella sale al revés pon 180
	GROUND_TILE     = 14,            -- tamaño de la textura de nieve (studs)             -- segundos de desvanecido
	MAX_PRINTS      = 70,
	MOUNDS          = 46,
	MOUND_RADIUS    = 230,
	BATCH           = 250,           -- piezas por frame al convertir
	FLAKE_RATE      = 320,
	BOKEH_RATE      = 5,
}
local SOFT = "rbxasset://textures/particles/smoke_main.dds"
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"

-- Texturas realistas (huella con relieve horneado, nieve del suelo, copo, bokeh)
-- se descargan una vez del repo y se cargan con getcustomasset. Si el executor no
-- lo soporta, se usa la versión de piezas 3D.
local RAW = "https://raw.githubusercontent.com/eduardomorfin58-ux/u/main/goy_snow/"
local ASSET = {}
local function loadAsset(name)
	if ASSET[name] ~= nil then return ASSET[name] or nil end
	local ok, id = pcall(function()
		local gca = getcustomasset or getsynasset
		if not (gca and writefile and isfile) then return nil end
		if makefolder and isfolder and not isfolder("GOY_Snow") then makefolder("GOY_Snow") end
		local path = "GOY_Snow/" .. name
		if not isfile(path) then writefile(path, game:HttpGet(RAW .. name)) end
		return gca(path)
	end)
	ASSET[name] = (ok and id) or false
	return ASSET[name] or nil
end

---------------------------------------------------------------------
-- ESTADO
---------------------------------------------------------------------
local S = {
	on = false,
	conns = {},          -- conexiones mientras está encendido
	made = {},           -- instancias creadas
	parts = {},          -- [part] = {Material, Color}
	removed = {},        -- hijos de Lighting/Terrain quitados {inst, parent}
	light = {},          -- propiedades originales de Lighting
	terrainColors = {},
	prints = {},
	queue = {}, qhead = 1,
	plotParts = {},
	floorSet = setmetatable({}, {__mode = "k"}),
}
local fx                 -- carpeta local de efectos (workspace)

local function track(c) S.conns[#S.conns + 1] = c; return c end
local function made(i) S.made[#S.made + 1] = i; return i end

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end

---------------------------------------------------------------------
-- PROTECCIÓN: qué NO se toca
---------------------------------------------------------------------
local BAD_NAMES = { "plot", "build", "zone", "border", "line", "grid", "area", "parcel", "region", "boundary" }

local function isPlotLine(p)
	if p.Material == Enum.Material.Neon or p.Material == Enum.Material.ForceField then return true end
	local c = p.Color
	if c.G > 0.55 and c.G > c.R + 0.22 and c.G > c.B + 0.12 then return true end -- verde neón
	local n = string.lower(p.Name)
	for _, w in ipairs(BAD_NAMES) do
		if string.find(n, w, 1, true) then return true end
	end
	local par = p.Parent
	if par and par ~= workspace then
		local pn = string.lower(par.Name)
		for _, w in ipairs(BAD_NAMES) do
			if string.find(pn, w, 1, true) then return true end
		end
	end
	return false
end

local function underCharacterOrToy(inst)
	local a = inst.Parent
	while a and a ~= workspace and a ~= game do
		if a:IsA("Model") and a:FindFirstChildOfClass("Humanoid") then return true end
		if Players:GetPlayerFromCharacter(a) then return true end
		local n = a.Name
		if string.find(n, "SpawnedInToys", 1, true) then return true end
		if a == fx or a:IsA("Camera") then return true end
		a = a.Parent
	end
	return false
end

local function eligible(p)
	if not p:IsA("BasePart") or p:IsA("Terrain") then return false end
	if not p.Anchored then return false end           -- juguetes/objetos que se mueven
	if p.Transparency >= 0.9 then return false end
	if p.Size.Magnitude < 2 then return false end
	if isPlotLine(p) then S.plotParts[p] = true return false end
	if underCharacterOrToy(p) then return false end
	return true
end

local function isFloor(p)
	local up = p.CFrame.UpVector
	local s = p.Size
	local flatY = s.Y <= math.min(s.X, s.Z) * 0.6
	return (math.abs(up.Y) > 0.92 and flatY) or (s.X > 30 and s.Z > 30)
end

---------------------------------------------------------------------
-- CONVERSIÓN DEL MAPA
---------------------------------------------------------------------
local function lerpColor(a, b, t) return a:Lerp(b, t) end

local function convert(p)
	if not S.on or S.parts[p] or not p.Parent then return end
	if not eligible(p) then return end
	S.parts[p] = { p.Material, p.Color }
	if isFloor(p) then
		S.floorSet[p] = true
		p.Material = Enum.Material.Snow
		p.Color = CFG.SNOW_COLOR
		if S.groundTex and p.Size.X * p.Size.Z > 30 then
			made(new("Texture", {
				Name = "GOY_SnowTex", Texture = S.groundTex,
				Face = (p.CFrame.UpVector.Y >= 0) and Enum.NormalId.Top or Enum.NormalId.Bottom,
				StudsPerTileU = CFG.GROUND_TILE, StudsPerTileV = CFG.GROUND_TILE,
				Transparency = 0.2,
			}, p))
		end
	else
		local m = p.Material
		if m ~= Enum.Material.Glass and m ~= Enum.Material.Metal and m ~= Enum.Material.DiamondPlate then
			p.Material = Enum.Material.Snow
		end
		p.Color = lerpColor(p.Color, Color3.fromRGB(232, 236, 242), CFG.ROCK_TINT)
	end
end

local function processQueue()
	local n = 0
	while S.qhead <= #S.queue and n < CFG.BATCH do
		local p = S.queue[S.qhead]
		S.queue[S.qhead] = nil
		S.qhead = S.qhead + 1
		if p and p.Parent then pcall(convert, p) end
		n = n + 1
	end
	if S.qhead > #S.queue then S.queue = {}; S.qhead = 1 end
end

local TERRAIN_MATS = { "Grass", "LeafyGrass", "Ground", "Mud", "Sand", "Rock", "Slate", "Sandstone", "Pavement", "Asphalt", "Concrete", "Snow", "Glacier", "Basalt" }

local function convertTerrain()
	local T = workspace.Terrain
	for _, name in ipairs(TERRAIN_MATS) do
		local mat = Enum.Material[name]
		local ok, col = pcall(function() return T:GetMaterialColor(mat) end)
		if ok then
			S.terrainColors[mat] = col
			pcall(function() T:SetMaterialColor(mat, CFG.SNOW_COLOR) end)
		end
	end
end

---------------------------------------------------------------------
-- CIELO, LUZ Y ATMÓSFERA
---------------------------------------------------------------------
local LIGHT_PROPS = {
	Ambient = Color3.fromRGB(150, 165, 185),
	OutdoorAmbient = Color3.fromRGB(175, 190, 210),
	Brightness = 3.1,
	ClockTime = 13.2,
	GeographicLatitude = 35,
	ExposureCompensation = 0.18,
	EnvironmentDiffuseScale = 1,
	EnvironmentSpecularScale = 0.55,
	ColorShift_Top = Color3.fromRGB(255, 250, 240),
	ColorShift_Bottom = Color3.fromRGB(190, 210, 235),
	FogEnd = 100000,
	GlobalShadows = true,
}

local function setupSky()
	for k, v in pairs(LIGHT_PROPS) do
		local ok, old = pcall(function() return Lighting[k] end)
		if ok then
			S.light[k] = old
			pcall(function() Lighting[k] = v end)
		end
	end
	-- quitar efectos actuales (se restauran luego)
	for _, c in ipairs(Lighting:GetChildren()) do
		if c:IsA("Sky") or c:IsA("Atmosphere") or c:IsA("PostEffect") then
			S.removed[#S.removed + 1] = { c, c.Parent }
			c.Parent = nil
		end
	end
	local oldClouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
	if oldClouds then
		S.removed[#S.removed + 1] = { oldClouds, oldClouds.Parent }
		oldClouds.Parent = nil
	end

	local sky = made(new("Sky", {
		Name = "GOY_Sky",
		SkyboxBk = "rbxasset://textures/sky/sky512_bk.tex",
		SkyboxDn = "rbxasset://textures/sky/sky512_dn.tex",
		SkyboxFt = "rbxasset://textures/sky/sky512_ft.tex",
		SkyboxLf = "rbxasset://textures/sky/sky512_lf.tex",
		SkyboxRt = "rbxasset://textures/sky/sky512_rt.tex",
		SkyboxUp = "rbxasset://textures/sky/sky512_up.tex",
		SunAngularSize = 14, MoonAngularSize = 9, StarCount = 0,
		CelestialBodiesShown = true,
	}))
	sky.Parent = Lighting

	made(new("Atmosphere", {
		Name = "GOY_Atmosphere",
		Density = 0.33, Offset = 0.12,
		Color = Color3.fromRGB(205, 220, 238),
		Decay = Color3.fromRGB(150, 178, 210),
		Glare = 0.25, Haze = 1.7,
	}, Lighting))

	pcall(function()
		made(new("Clouds", {
			Name = "GOY_Clouds", Cover = 0.58, Density = 0.78,
			Color = Color3.fromRGB(255, 255, 255),
		}, workspace.Terrain))
	end)

	made(new("ColorCorrectionEffect", {
		Name = "GOY_CC", Brightness = 0.03, Contrast = 0.09, Saturation = -0.08,
		TintColor = Color3.fromRGB(241, 247, 255),
	}, Lighting))
	made(new("BloomEffect", { Name = "GOY_Bloom", Intensity = 0.55, Size = 28, Threshold = 1.55 }, Lighting))
	made(new("SunRaysEffect", { Name = "GOY_Rays", Intensity = 0.04, Spread = 0.6 }, Lighting))
end

---------------------------------------------------------------------
-- RAYCAST
---------------------------------------------------------------------
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function refreshFilter()
	local list = { fx }
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl.Character then list[#list + 1] = pl.Character end
	end
	rayParams.FilterDescendantsInstances = list
end

local function snowSurface(hit)
	if not hit then return false end
	local i = hit.Instance
	if i:IsA("Terrain") then return true end
	if S.plotParts[i] then return false end
	return S.floorSet[i] == true or (S.parts[i] ~= nil)
end

---------------------------------------------------------------------
-- MONTÍCULOS / DUNAS
---------------------------------------------------------------------
local function blob(cf, size, parent)
	local p = new("Part", {
		Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
		CastShadow = true, Material = Enum.Material.Snow, Color = CFG.SNOW_COLOR,
		Size = Vector3.new(1, 1, 1), CFrame = cf, TopSurface = 0, BottomSurface = 0,
	})
	new("SpecialMesh", { MeshType = Enum.MeshType.Sphere, Scale = size }, p)
	p.Parent = parent
	return p
end

local function makeMounds()
	local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
	local center = root and root.Position or (workspace.CurrentCamera.CFrame.Position)
	local folder = new("Folder", { Name = "Montículos" }, fx)
	local rng = Random.new(os.time())
	local placed, tries = 0, 0
	while placed < CFG.MOUNDS and tries < CFG.MOUNDS * 10 do
		tries = tries + 1
		local ang = rng:NextNumber(0, math.pi * 2)
		local dist = rng:NextNumber(25, CFG.MOUND_RADIUS)
		local pos = center + Vector3.new(math.cos(ang) * dist, 300, math.sin(ang) * dist)
		local hit = workspace:Raycast(pos, Vector3.new(0, -700, 0), rayParams)
		if hit and snowSurface(hit) and hit.Normal.Y > 0.9 then
			-- lejos de líneas de parcela
			local nearPlot = false
			for pp in pairs(S.plotParts) do
				if pp.Parent and (pp.Position - hit.Position).Magnitude < math.max(pp.Size.X, pp.Size.Z) * 0.5 + 10 then
					nearPlot = true break
				end
			end
			if not nearPlot then
				placed = placed + 1
				local big = rng:NextNumber(6, 20)
				local yaw = CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
				local base = CFrame.new(hit.Position) * yaw
				for k = 1, rng:NextInteger(2, 5) do
					local w = big * rng:NextNumber(0.55, 1.1)
					local l = big * rng:NextNumber(0.7, 1.6)
					local h = big * rng:NextNumber(0.14, 0.3)
					local off = Vector3.new(rng:NextNumber(-big, big) * 0.6, -h * 0.38, rng:NextNumber(-big, big) * 0.6)
					blob(base * CFrame.new(off) * CFrame.Angles(0, rng:NextNumber(-0.6, 0.6), 0), Vector3.new(w, h, l), folder)
				end
			end
		end
	end
end

---------------------------------------------------------------------
-- PARTÍCULAS (viento rasante + bokeh frente a la cámara)
---------------------------------------------------------------------
local flakePart, bokehPart, flakes2

local function makeParticles()
	local FLAKE = loadAsset("flake.png") or SOFT
	local BOKEH = loadAsset("bokeh.png") or SOFT
	flakePart = new("Part", {
		Name = "GOY_SnowEmitter", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
		Transparency = 1, Size = Vector3.new(160, 1, 160),
	}, fx)
	new("ParticleEmitter", {
		Texture = FLAKE, Rate = CFG.FLAKE_RATE,
		Lifetime = NumberRange.new(6, 10),
		Speed = NumberRange.new(4, 8),
		EmissionDirection = Enum.NormalId.Bottom,
		Acceleration = Vector3.new(3.2, -1.2, 1.6),
		Drag = 0.4,
		SpreadAngle = Vector2.new(25, 25),
		RotSpeed = NumberRange.new(-60, 60),
		Rotation = NumberRange.new(0, 360),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.18), NumberSequenceKeypoint.new(1, 0.12) }),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.1, 0.15),
			NumberSequenceKeypoint.new(0.85, 0.2), NumberSequenceKeypoint.new(1, 1) }),
		Color = ColorSequence.new(Color3.new(1, 1, 1)),
		LightInfluence = 0.6, LightEmission = 0.15,
	}, flakePart)
	-- copos chispeantes pequeños (brillo)
	flakes2 = new("ParticleEmitter", {
		Texture = SPARK, Rate = 60,
		Lifetime = NumberRange.new(5, 8), Speed = NumberRange.new(3, 6),
		EmissionDirection = Enum.NormalId.Bottom,
		Acceleration = Vector3.new(2.5, -0.8, 1.2),
		Size = NumberSequence.new(0.22),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.3), NumberSequenceKeypoint.new(1, 1) }),
		LightEmission = 0.5,
	}, flakePart)

	-- viento rasante a ras del piso
	local drift = new("ParticleEmitter", {
		Texture = SOFT, Rate = 18,
		Lifetime = NumberRange.new(2.5, 4), Speed = NumberRange.new(9, 14),
		EmissionDirection = Enum.NormalId.Right,
		SpreadAngle = Vector2.new(8, 4),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 4) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.86), NumberSequenceKeypoint.new(1, 1) }),
		Color = ColorSequence.new(Color3.fromRGB(245, 249, 255)),
		LightInfluence = 0.8,
	})
	S.drift = new("Part", {
		Name = "GOY_Drift", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
		Transparency = 1, Size = Vector3.new(1, 0.5, 70),
	}, fx)
	drift.Parent = S.drift

	-- bokeh: copos grandes y borrosos pegados al lente
	bokehPart = new("Part", {
		Name = "GOY_Bokeh", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
		Transparency = 1, Size = Vector3.new(9, 5, 0.2),
	}, fx)
	new("ParticleEmitter", {
		Texture = BOKEH, Rate = CFG.BOKEH_RATE, LockedToPart = true,
		Lifetime = NumberRange.new(1.6, 2.6), Speed = NumberRange.new(0.4, 1),
		EmissionDirection = Enum.NormalId.Bottom,
		SpreadAngle = Vector2.new(40, 40),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0.75) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.55), NumberSequenceKeypoint.new(0.75, 0.6), NumberSequenceKeypoint.new(1, 1) }),
		LightEmission = 0.35, LightInfluence = 0.3,
		Color = ColorSequence.new(Color3.fromRGB(250, 252, 255)),
	}, bokehPart)
end

local function updateParticles()
	local cam = workspace.CurrentCamera
	if not cam then return end
	local cf = cam.CFrame
	if flakePart then
		flakePart.CFrame = CFrame.new(cf.Position + Vector3.new(-10, 40, -6))
		-- ráfagas de viento suaves
		local t = os.clock()
		local g = 1 + 0.6 * math.sin(t * 0.35) + 0.3 * math.sin(t * 1.3)
		local em = flakePart:FindFirstChildOfClass("ParticleEmitter")
		if em then em.Acceleration = Vector3.new(3.2 * g, -1.2, 1.6 * g) end
	end
	if bokehPart then
		bokehPart.CFrame = cf * CFrame.new(0, 0.6, -3.2)
	end
	if S.drift then
		local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		if root then
			local hit = workspace:Raycast(root.Position, Vector3.new(0, -12, 0), rayParams)
			local y = hit and hit.Position.Y or (root.Position.Y - 3)
			S.drift.CFrame = CFrame.new(root.Position.X - 30, y + 0.4, root.Position.Z)
			S.drift.ParticleEmitter.Enabled = hit ~= nil and snowSurface(hit)
		end
	end
end

---------------------------------------------------------------------
-- HUELLAS 3D
---------------------------------------------------------------------
-- forma de suela (pie izquierdo; -Z = hacia delante, +X = hacia fuera)
local SOLE = {
	{ x = 0.00, z = 0.58, w = 0.56, l = 0.72 },  -- talón
	{ x = -0.07, z = 0.08, w = 0.40, l = 0.62 }, -- arco (más estrecho, hacia dentro)
	{ x = 0.02, z = -0.38, w = 0.72, l = 0.86 }, -- planta
	{ x = 0.05, z = -0.84, w = 0.58, l = 0.40 }, -- punta
}

local function piece(cf, size, color, mtype, transp, parent)
	local p = new("Part", {
		Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false,
		Material = Enum.Material.Snow, Color = color, Transparency = transp,
		Size = Vector3.new(0.2, 0.2, 0.2), CFrame = cf, TopSurface = 0, BottomSurface = 0,
	})
	new("SpecialMesh", { MeshType = mtype, Scale = size * 5 }, p)
	p.Parent = parent
	return p
end

local function puff(pos)
	local a = new("Attachment", { WorldPosition = pos }, workspace.Terrain)
	local e = new("ParticleEmitter", {
		Texture = SOFT, Enabled = false,
		Lifetime = NumberRange.new(0.5, 0.9), Speed = NumberRange.new(1.5, 3.2),
		SpreadAngle = Vector2.new(70, 70), Acceleration = Vector3.new(0, -4, 0), Drag = 3,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0.9) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) }),
		Color = ColorSequence.new(Color3.new(1, 1, 1)), LightInfluence = 0.9,
	}, a)
	e:Emit(12)
	Debris:AddItem(a, 1.5)
end

local function fadePrint(model)
	local info = TweenInfo.new(CFG.PRINT_FADE, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("Decal") then
			TweenService:Create(p, info, { Transparency = 1 }):Play()
		elseif p:IsA("BasePart") and p.Transparency < 1 then
			TweenService:Create(p, info, { Transparency = 1 }):Play()
			local m = p:FindFirstChildOfClass("SpecialMesh")
			if m then TweenService:Create(m, info, { Scale = m.Scale * Vector3.new(1.05, 0.3, 1.05) }):Play() end
		end
	end
	Debris:AddItem(model, CFG.PRINT_FADE + 0.2)
end

local function makePrint(pos, normal, forward, left, scale)
	-- marco alineado a la superficie
	local up = normal.Unit
	local fwd = (forward - up * forward:Dot(up))
	if fwd.Magnitude < 1e-3 then return end
	fwd = fwd.Unit
	local right = fwd:Cross(up).Unit
	local base = CFrame.fromMatrix(pos, right, up, -fwd)
	local mirror = left and 1 or -1
	local model = new("Model", { Name = left and "HuellaIzq" or "HuellaDer" })
	local s = scale
	local texId = left and S.printL or S.printR

	if texId then
		-- huella realista: textura con relieve, sombra azul y borde rebotado horneados
		local holder = new("Part", {
			Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false,
			Transparency = 1, Size = Vector3.new(1.2 * s, 0.05, 2.4 * s),
			CFrame = base * CFrame.Angles(0, math.rad(CFG.PRINT_ROT), 0) * CFrame.new(0, 0.03, 0),
		})
		new("Decal", { Texture = texId, Face = Enum.NormalId.Top, Transparency = 0.02 }, holder)
		holder.Parent = model
		-- terrones de nieve que salen despedidos alrededor
		local rng = Random.new()
		for k = 1, rng:NextInteger(3, 6) do
			local a = rng:NextNumber(0, math.pi * 2)
			local rx, rz = math.cos(a) * 0.62 * s, math.sin(a) * 1.15 * s
			local d = rng:NextNumber(0.1, 0.22) * s
			piece(base * CFrame.new(rx, d * 0.15, rz), Vector3.new(d, d * 0.7, d), CFG.RIM_COLOR, Enum.MeshType.Sphere, 0, model)
		end
	end

	for _, seg in ipairs(texId and {} or SOLE) do
		local c = base * CFrame.new(seg.x * mirror * s, 0, seg.z * s)
		-- borde rebotado (nieve desplazada, un poco elevada)
		piece(c * CFrame.new(0, -0.02, 0), Vector3.new(seg.w * 1.55, 0.2, seg.l * 1.38) * s, CFG.RIM_COLOR, Enum.MeshType.Sphere, 0, model)
		-- sombra de oclusión en la pared interna
		piece(c * CFrame.new(0, 0.032, 0), Vector3.new(seg.w * 1.08, 0.012, seg.l * 1.06) * s, CFG.PRINT_DEEP, Enum.MeshType.Cylinder, 0.35, model)
		-- fondo hundido azul helado
		piece(c * CFrame.new(0, 0.04, 0), Vector3.new(seg.w, 0.012, seg.l) * s, CFG.PRINT_COLOR, Enum.MeshType.Cylinder, 0.05, model)
	end
	-- marcas de la suela (dibujo) en planta y talón
	for k = 0, (texId and -1 or 3) do
		local z = (-0.62 + k * 0.17) * s
		piece(base * CFrame.new(0.02 * mirror * s, 0.047, z), Vector3.new(0.5 * s, 0.01, 0.045 * s), CFG.PRINT_DEEP, Enum.MeshType.Brick, 0.25, model)
	end
	for k = 0, (texId and -1 or 1) do
		piece(base * CFrame.new(0, 0.047, (0.5 + k * 0.17) * s), Vector3.new(0.36 * s, 0.01, 0.04 * s), CFG.PRINT_DEEP, Enum.MeshType.Brick, 0.3, model)
	end
	-- Cylinder mesh queda acostado sobre X; lo ponemos de pie
	for _, p in ipairs(model:GetChildren()) do
		local m = p:FindFirstChildOfClass("SpecialMesh")
		if m and m.MeshType == Enum.MeshType.Cylinder then
			local sc = m.Scale
			m.Scale = Vector3.new(sc.Y, sc.X, sc.Z)
			p.CFrame = p.CFrame * CFrame.Angles(0, 0, math.rad(90))
		end
	end
	model.Parent = fx
	puff(pos + up * 0.2)

	S.prints[#S.prints + 1] = model
	if #S.prints > CFG.MAX_PRINTS then
		local old = table.remove(S.prints, 1)
		if old and old.Parent then old:Destroy() end
	end
	task.delay(CFG.PRINT_LIFE, function()
		if model.Parent then fadePrint(model) end
	end)
end

local step = { last = nil, left = true }

local function updateFootprints()
	local char = LP.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not (hum and root) or hum.Sit then step.last = nil return end
	if hum.FloorMaterial == Enum.Material.Air then return end
	local p = root.Position
	local flat = Vector3.new(p.X, 0, p.Z)
	if not step.last then step.last = flat return end
	local moved = (flat - step.last).Magnitude
	local scale = math.clamp(root.Size.Y / 2, 0.6, 2.5)
	if moved < CFG.STRIDE * scale then return end
	local dir = (flat - step.last).Unit
	step.last = flat
	local side = Vector3.new(-dir.Z, 0, dir.X) -- derecha
	local off = (step.left and -1 or 1) * 0.42 * scale
	local origin = p + side * off + dir * 0.3
	local hit = workspace:Raycast(origin, Vector3.new(0, -(hum.HipHeight + root.Size.Y) * 1.6 - 2, 0), rayParams)
	if hit and snowSurface(hit) then
		makePrint(hit.Position, hit.Normal, dir, step.left, scale)
	end
	step.left = not step.left
end

---------------------------------------------------------------------
-- ENCENDER / APAGAR
---------------------------------------------------------------------
local function enable()
	if S.on then return end
	S.on = true
	fx = new("Folder", { Name = "GOY_SnowFX" }, workspace)
	made(fx)
	refreshFilter()
	S.groundTex = loadAsset("snow_ground.png")
	S.printL = loadAsset("footprint_L.png")
	S.printR = loadAsset("footprint_R.png")
	setupSky()
	convertTerrain()
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("BasePart") then S.queue[#S.queue + 1] = d end
	end
	-- convertir lo inicial antes de poner montículos
	while S.qhead <= #S.queue do
		processQueue()
		task.wait()
		if not S.on then return end
	end
	track(workspace.DescendantAdded:Connect(function(d)
		if d:IsA("BasePart") then S.queue[#S.queue + 1] = d end
	end))
	track(Players.PlayerAdded:Connect(function(pl) pl.CharacterAdded:Connect(refreshFilter) end))
	for _, pl in ipairs(Players:GetPlayers()) do
		track(pl.CharacterAdded:Connect(function() task.wait(0.5) refreshFilter() end))
	end
	makeParticles()
	pcall(makeMounds)
	track(RunService.Heartbeat:Connect(function()
		processQueue()
		local ok = pcall(updateFootprints)
		if not ok then step.last = nil end
	end))
	track(RunService.RenderStepped:Connect(function() pcall(updateParticles) end))
end

local function disable()
	if not S.on then return end
	S.on = false
	for _, c in ipairs(S.conns) do pcall(function() c:Disconnect() end) end
	S.conns = {}
	-- mapa original exacto
	for p, orig in pairs(S.parts) do
		if p.Parent then
			pcall(function() p.Material = orig[1]; p.Color = orig[2] end)
		end
	end
	S.parts = {}
	S.floorSet = setmetatable({}, { __mode = "k" })
	S.plotParts = {}
	S.queue = {}; S.qhead = 1
	for mat, col in pairs(S.terrainColors) do
		pcall(function() workspace.Terrain:SetMaterialColor(mat, col) end)
	end
	S.terrainColors = {}
	-- iluminación original exacta
	for i = #S.made, 1, -1 do pcall(function() S.made[i]:Destroy() end) end
	S.made = {}
	for k, v in pairs(S.light) do pcall(function() Lighting[k] = v end) end
	S.light = {}
	for _, r in ipairs(S.removed) do pcall(function() r[1].Parent = r[2] end) end
	S.removed = {}
	S.prints = {}
	flakePart, bokehPart, flakes2, S.drift = nil, nil, nil, nil
	step.last = nil
end

local function toggle()
	if S.on then disable() else task.spawn(enable) end
end

---------------------------------------------------------------------
-- BOTÓN ❄ (iPhone) + TECLA F6
---------------------------------------------------------------------
local guiParent = (gethui and gethui()) or game:GetService("CoreGui")
local gui = new("ScreenGui", { Name = "GOY_SnowToggle", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 50 })
if not pcall(function() gui.Parent = guiParent end) then gui.Parent = LP:WaitForChild("PlayerGui") end

local btn = new("TextButton", {
	Size = UDim2.fromOffset(46, 46), Position = UDim2.new(1, -60, 0.32, 0),
	BackgroundColor3 = Color3.fromRGB(20, 28, 40), BackgroundTransparency = 0.2,
	Text = "❄", TextSize = 26, Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(170, 225, 255),
	AutoButtonColor = true,
}, gui)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, btn)
local stroke = new("UIStroke", { Color = Color3.fromRGB(120, 200, 255), Thickness = 2 }, btn)

local function paint()
	stroke.Color = S.on and Color3.fromRGB(120, 200, 255) or Color3.fromRGB(90, 90, 100)
	btn.TextColor3 = S.on and Color3.fromRGB(170, 225, 255) or Color3.fromRGB(130, 130, 140)
end

-- arrastrable
do
	local dragging, startPos, startIn, movedFar
	btn.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging, startPos, startIn, movedFar = true, btn.Position, i.Position, false
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
			local d = i.Position - startIn
			if d.Magnitude > 8 then movedFar = true end
			btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	btn.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
			if not movedFar then toggle(); task.delay(0.1, paint) end
		end
	end)
end

local keyConn = UIS.InputBegan:Connect(function(i, gpe)
	if gpe then return end
	if i.KeyCode == Enum.KeyCode.F6 then toggle(); task.delay(0.1, paint) end
end)

ENV.GOY_SNOW = {
	enable = enable, disable = disable, toggle = toggle, state = S, config = CFG,
	destroy = function()
		disable()
		pcall(function() keyConn:Disconnect() end)
		pcall(function() gui:Destroy() end)
	end,
}

task.spawn(enable)
task.delay(0.2, paint)
