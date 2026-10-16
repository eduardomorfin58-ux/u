local _Players = game:GetService('Players')
local u3 = loadstring(game:HttpGet('http://you.whimper.xyz/sources/blitz/orionx'))()
local _Debris = game:GetService('Debris')
local _Workspace = game:GetService('Workspace')
local _Lighting = game:GetService('Lighting')
local _TweenService = game:GetService('TweenService')
local _UserInputService = game:GetService('UserInputService')
local _ReplicatedStorage = game:GetService('ReplicatedStorage')
local _ReplicatedFirst = game:GetService('ReplicatedFirst')
local _ContextActionService = game:GetService('ContextActionService')
local _RunService = game:GetService('RunService')
local _VirtualUser = game:GetService('VirtualUser')
local _CharacterEvents = _ReplicatedStorage:WaitForChild('CharacterEvents')
local _LocalPlayer = _Players.LocalPlayer
local _PlayerGui = _LocalPlayer:WaitForChild('PlayerGui')
_LocalPlayer:GetMouse()

local u17 = _Workspace:WaitForChild(_LocalPlayer.Name .. 'SpawnedInToys')
local _InPlot = _LocalPlayer:WaitForChild('InPlot')
local _ToysLimitCap = _LocalPlayer:WaitForChild('ToysLimitCap')

SpawnToyRF = _ReplicatedStorage:WaitForChild('MenuToys'):WaitForChild('SpawnToyRemoteFunction')
DeleteToyRE = _ReplicatedStorage:WaitForChild('MenuToys'):WaitForChild('DestroyToy')
BuyToy = _ReplicatedStorage:WaitForChild('MenuToys'):WaitForChild('BuyToyRemoteFunction')
BombEvents = _ReplicatedStorage:WaitForChild('BombEvents')
typeAnimation = _ReplicatedFirst.Typing.Type
flailAnimation = _ReplicatedFirst.ThrowPlayers.Flail

local _CreateGrabLine = _ReplicatedStorage:WaitForChild('GrabEvents'):WaitForChild('CreateGrabLine')
local _DestroyGrabLine = _ReplicatedStorage:WaitForChild('GrabEvents'):WaitForChild('DestroyGrabLine')
local _SetNetworkOwner = _ReplicatedStorage:WaitForChild('GrabEvents'):WaitForChild('SetNetworkOwner')

_ReplicatedStorage:WaitForChild('GrabEvents'):WaitForChild('ExtendGrabLine')

local _RagdollRemote = _CharacterEvents:WaitForChild('RagdollRemote')

ChatTypingBoard = _CharacterEvents:WaitForChild('ChatTyping')

local u24

if _ReplicatedStorage:FindFirstChild('DefaultChatSystemChatEvents') and _ReplicatedStorage.DefaultChatSystemChatEvents:FindFirstChild('SayMessageRequest') then
	u24 = _ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest
else
	u24 = nil
end

local _UpdateLineColorsEvent = _ReplicatedStorage:WaitForChild('DataEvents'):WaitForChild('UpdateLineColorsEvent')
local _IsHeld = _LocalPlayer:WaitForChild('IsHeld')
local _PlayerScripts = _LocalPlayer:WaitForChild('PlayerScripts')
local u28 = nil
local _Struggle = _CharacterEvents:WaitForChild('Struggle')

anticreatelinelocalscript = _PlayerScripts:WaitForChild('CharacterAndBeamMove')

_LocalPlayer.Changed:Connect(function(p30)
	if p30 == 'userId' or p30 == 'UserId' then
		while true do end
	else
		return
	end
end)

function Type(p31)
	u24:FireServer(p31, 'All')
end

local function u33(p32)
	u3:MakeNotification({
		Name = 'GOY FREE',
		Content = p32,
		Image = 'rbxassetid://16570630989',
		Time = 5,
	})
end

function IsSolara()
	if getexecutorname then
		local v34 = getexecutorname()

		if v34 and string.find(v34, 'Solara') then
			return true
		end
	end
end
function IsMobile()
	if _LocalPlayer.PlayerGui:FindFirstChild('ContextActionGui') then
		return true
	end
end

IsUsingSolara = IsSolara()

if IsUsingSolara then
	print('new proximity promp created!')

	getgenv().fireproximityprompt = function(p35)
		if p35.Name ~= 'ProximityPrompt' then
			error('retard: ' .. Obj.Name)
		else
			local _HoldDuration = p35.HoldDuration
			local _MaxActivationDistance = p35.MaxActivationDistance

			p35.MaxActivationDistance = math.huge
			p35.HoldDuration = 0

			p35:InputHoldBegin()
			p35:InputHoldEnd()

			p35.HoldDuration = _HoldDuration
			p35.MaxActivationDistance = _MaxActivationDistance
		end
	end
end

local u38 = {}

function checkadminData(p39)
	if table.find(u38, p39) then
		return true
	end
end

spawnToyThread = coroutine.create(function()
	while true do
		repeat
			local v40 = coroutine.yield()
		until typeof(v40) == 'table'

		SpawnToyRF:InvokeServer(unpack(v40))
	end
end)

function SpawnToy(p41)
	coroutine.resume(spawnToyThread, p41)
end

local function u49(p42, p43)
	if typeof(p42) == 'Instance' and p42.Parent then
		local _LastTimeRankUpdate = p42:GetAttribute('LastTimeRankUpdate')

		if not _LastTimeRankUpdate or _LastTimeRankUpdate and 300 <= os.clock() - _LastTimeRankUpdate then
			local v45, v46 = pcall(function()
				return p42:GetRankInGroup(p43)
			end)
			local _, v47 = pcall(function()
				return p42:GetRoleInGroup(p43)
			end)
			local v48 = not v45 and 'Common' or v46

			if v48 == 255 then
				p42:SetAttribute('Rank', 'Leader')
			elseif v48 == 4 then
				if v47 == 'High Rank Admin' then
					p42:SetAttribute('Rank', 'High Rank Admin')
				end
			elseif v48 == 3 then
				p42:SetAttribute('Rank', 'Low Rank Admin')
			elseif v48 == 2 then
				p42:SetAttribute('Rank', 'Goon')
			elseif v48 == 0 or v48 == 1 then
				p42:SetAttribute('Rank', 'Common')
			end

			p42:SetAttribute('LastTimeRankUpdate', os.clock())
		end

		local _ = p42.GetAttribute
	end
end
local function u54(p50)
	if typeof(p50) ~= 'Instance' then
		p50 = nil
	elseif p50:IsA('Model') and p50:FindFirstChildOfClass('Humanoid') and _Players:GetPlayerFromCharacter(p50) then
		p50 = _Players:GetPlayerFromCharacter(p50)
	elseif not p50:IsA('Player') then
		return
	end

	local v51 = false

	if p50 then
		local v52 = u49(p50, 16168861)
		local v53 = (v52 == 'Leader' or v52 == 'High Rank Admin') and true or ((v52 == 'Low Rank Admin' or v52 == 'Goon') and true or v51)

		if checkadminData(p50.Name) and not u38[p50.Name].Protection then
			v53 = false
		end

		return v53
	end
end

function IsHoldingAdminPlayer()
	local _GrabParts = _Workspace:FindFirstChild('GrabParts')

	if _GrabParts and _GrabParts:FindFirstChild('GrabPart') and _GrabParts.GrabPart:FindFirstChild('WeldConstraint') then
		local _Part1 = _GrabParts.GrabPart.WeldConstraint.Part1

		if _Part1 and u54(_Part1.Parent) then
			return true
		end
	end
end
function WhatIsHolding(p57)
	if p57 and p57:FindFirstChild('GrabPart') and p57.GrabPart:FindFirstChild('WeldConstraint') then
		local _Part12 = p57.GrabPart.WeldConstraint.Part1

		if _Part12 and _Part12.Parent and _Part12.Parent:IsA('Model') then
			local _Parent = _Part12.Parent

			return _Players:GetPlayerFromCharacter(_Part12.Parent) and 'Player' or (_Parent:FindFirstChild('Pet') and 'Follow NPC' or 'Object')
		end
	end
end
function tableAlphabeticOrder(p60, p61)
	return p60:lower() < p61:lower()
end

local function u69(p62)
	local v63 = _Players
	local v64, v65, v66 = pairs(v63:GetPlayers())
	local v67 = {}

	while true do
		local v68

		v66, v68 = v64(v65, v66)

		if v66 == nil then
			break
		end
		if v68.UserId ~= _LocalPlayer.UserId then
			table.insert(v67, v68.Name .. ' ' .. '(' .. v68.DisplayName .. ')')
		end
	end

	table.sort(v67, tableAlphabeticOrder)
	p62:Refresh(v67, true)
end

local u70 = {}
local u71 = {}

local function u79(p72, p73)
	local v74, v75, v76 = pairs(p73)
	local v77 = {}

	while true do
		local v78

		v76, v78 = v74(v75, v76)

		if v76 == nil then
			break
		end
		if typeof(v78) == 'string' then
			table.insert(v77, v78)
		end
	end

	p72:Refresh(v77, true)
end
local function u87(p80)
	local v81 = _Players
	local v82, v83, v84 = pairs(v81:GetPlayers())
	local v85 = {}

	while true do
		local v86

		v84, v86 = v82(v83, v84)

		if v84 == nil then
			break
		end
		if v86.UserId ~= _LocalPlayer.UserId then
			table.insert(v85, v86.Name .. ' ' .. '(' .. v86.DisplayName .. ')')
		end
	end

	table.sort(v85, tableAlphabeticOrder)
	table.insert(v85, 1, _LocalPlayer.Name .. ' ' .. '(' .. _LocalPlayer.DisplayName .. ')')
	p80:Refresh(v85, true)
end

function lookAt(p88, p89)
	local _Unit = (p89 - p88).Unit
	local v91 = _Unit:Cross((Vector3.new(0, 1, 0)))
	local v92 = v91:Cross(_Unit)

	return CFrame.fromMatrix(p88, v91, v92)
end

local function u96(p93, p94, _)
	if p93 == 'Spawn Toy (TAB)' and p94 == Enum.UserInputState.Begin then
		local v95 = {
			_G.SelectedToy,
			_LocalPlayer.Character.CamPart.CFrame,
			Vector3.new(0, _LocalPlayer.Character.CamPart.Orientation.Y, 0),
		}

		SpawnToyRF:InvokeServer(unpack(v95))
	end
end

function teleportfunc()
	local v97 = _G.ControllingCreature or _LocalPlayer.Character
	local v98 = _G.ControllingCreature and 'Head' or (_LocalPlayer.Character and 'CamPart' or nil)
	local v99, v100 = _Workspace:FindPartOnRayWithIgnoreList(Ray.new(v97[v98].Position, _LocalPlayer.Character.CamPart.CFrame.lookVector * 5000), {v97})

	if v99 then
		v97.HumanoidRootPart.CFrame = CFrame.new(v100.X, v100.Y + 5, v100.Z)
	end
end

local function u103(p101, p102, _)
	if p101 == 'Teleport(Z)' and p102 == Enum.UserInputState.Begin then
		teleportfunc()
	end
end
local function u105(p104)
	if table.find(u71, p104) then
		return true
	end
end

local u106 = nil
local u107 = nil

Noclip2 = nil
Clip2 = nil

local function u113()
	if not u106 then
		u107 = false

		local function v112()
			if u107 == false and game.Players.LocalPlayer.Character ~= nil then
				local v108, v109, v110 = pairs(game.Players.LocalPlayer.Character:GetChildren())

				while true do
					local v111

					v110, v111 = v108(v109, v110)

					if v110 == nil then
						break
					end
					if v111:IsA('BasePart') and v111.CanCollide and v111.Name ~= floatName then
						v111.CanCollide = false
					end
				end
			end

			wait(0.21)
		end

		u106 = _RunService.Stepped:Connect(v112)
	end
end
local function u114()
	if not _G.NoclipToggle then
		if u106 then
			u106:Disconnect()

			u106 = nil
		end

		u107 = true
	end
end

function countToys(p115)
	local v116 = u17
	local v117, v118, v119 = pairs(v116:GetChildren())
	local v120 = 0

	while true do
		local v121

		v119, v121 = v117(v118, v119)

		if v119 == nil then
			break
		end
		if v121.Name == p115 then
			v120 = v120 + 1
		end
	end

	return v120
end
function CheckNetworkOwnerShipOnPlayer(p122, p123)
	if typeof(p122) == 'Instance' and (p122:IsA('Player') and p122.Character) and (p122.Character:FindFirstChild('Head') and (p122.Character.Head:FindFirstChild('PartOwner') and p122.Character.Head.PartOwner.Value == _LocalPlayer.Name)) then
		return not p123 and true or p122.Character.Head.PartOwner
	end
end
function CheckNetworkOwnerShipPermanentOnPlayer(p124, p125)
	if typeof(p124) == 'Instance' and (p124:IsA('Player') and p124.Character) and (p124.Character:FindFirstChild('HumanoidRootPart') and p124.Character.HumanoidRootPart:FindFirstChild('FirePlayerPart')) and (p124.Character.HumanoidRootPart.FirePlayerPart:FindFirstChild('PartOwner') and p124.Character.HumanoidRootPart.FirePlayerPart.PartOwner.Value == _LocalPlayer.Name) then
		return not p125 and true or p124.Character.HumanoidRootPart.FirePlayerPart.PartOwner
	end
end
function CheckNetworkOwnerShipOnPart(p126, p127)
	if typeof(p126) == 'Instance' and (p126:FindFirstChild('PartOwner') and p126.PartOwner.Value == _LocalPlayer.Name) then
		return not p127 and true or p126.PartOwner
	end
end
function SNOWship(p128)
	if p128 and typeof(p128) == 'Instance' then
		local v129 = _LocalPlayer:DistanceFromCharacter(p128.Position)

		if _LocalPlayer.Character and (_LocalPlayer.Character:FindFirstChild('HumanoidRootPart') and v129 <= 30) then
			_SetNetworkOwner:FireServer(p128, lookAt(_LocalPlayer.Character.HumanoidRootPart.Position, p128.Position))
		end
	end
end
function IsPlayerInsideSafeZone(p130)
	if typeof(p130) == 'Instance' and (p130:IsA('Player') and p130:FindFirstChild('InPlot')) and p130.InPlot.Value then
		return true
	end
end
function IsPlayerFloating(p131)
	if typeof(p131) == 'Instance' and (p131:IsA('Player') and p131.Character) and (p131.Character:FindFirstChildOfClass('Humanoid') and p131.Character:FindFirstChildOfClass('Humanoid').FloorMaterial == Enum.Material.Air) then
		return true
	end
end
function CheckPlayerVelocity(p132)
	if typeof(p132) == 'Instance' and (p132:IsA('Player') and p132.Character) and p132.Character:FindFirstChild('HumanoidRootPart') then
		return p132.Character.HumanoidRootPart.Velocity.Magnitude
	end
end
function SNOWshipOnce(p133)
	local v134 = _LocalPlayer:DistanceFromCharacter(p133.Position)

	if _LocalPlayer.Character and _LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
		if CheckNetworkOwnerShipOnPart(p133) then
			return true
		end
		if v134 <= 30 then
			_SetNetworkOwner:FireServer(p133, lookAt(_LocalPlayer.Character.HumanoidRootPart.Position, p133.Position))
		end
	end
end
function SNOWshipTrack(p135)
	if p135.Parent and p135.Parent:IsA('Model') then
		local _Parent2 = p135.Parent
		local _OwnershipTrackConnected = _Parent2:GetAttribute('OwnershipTrackConnected')
		local _CreatedConnected2 = _Parent2:GetAttribute('CreatedConnected2')

		if _LocalPlayer.Character and _LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
			local v139 = _LocalPlayer:DistanceFromCharacter(p135.Position)

			if _CreatedConnected2 then
				if _OwnershipTrackConnected then
					return true
				end
				if v139 <= 30 then
					_SetNetworkOwner:FireServer(p135, lookAt(_LocalPlayer.Character.HumanoidRootPart.Position, p135.Position))
				end
			else
				_Parent2:SetAttribute('CreatedConnected2', true)
				print('Create Connection 2')
				_Parent2.DescendantAdded:Connect(function(p140)
					if p140.Name ~= 'PartOwner' or p140.Value ~= _LocalPlayer.Name then
						if p140.Name == 'PartOwner' and p140.Value ~= _LocalPlayer.Name then
							_Parent2:SetAttribute('OwnershipTrackConnected', false)
						end
					else
						_Parent2:SetAttribute('OwnershipTrackConnected', true)
					end
				end)
			end
		end
	end
end
function SNOWshipOnceAndDelete(p141)
	local v142 = _LocalPlayer:DistanceFromCharacter(p141.Position)
	local _Connected = p141:GetAttribute('Connected')
	local _CreatedConnected = p141:GetAttribute('CreatedConnected')

	if _LocalPlayer.Character and _LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
		if CheckNetworkOwnerShipOnPart(p141) then
			p141:SetAttribute('Connected', true)
			_DestroyGrabLine:FireServer(p141)

			if not _CreatedConnected then
				p141:SetAttribute('CreatedConnected', true)
				print('Create Connection')
				p141.ChildAdded:Connect(function(p145)
					if p145.Name == 'PartOwner' and p145.Value ~= _LocalPlayer.Name then
						p141:SetAttribute('Connected', false)
					end
				end)
			end
		elseif v142 <= 30 and not _Connected then
			_SetNetworkOwner:FireServer(p141, lookAt(_LocalPlayer.Character.HumanoidRootPart.Position, p141.Position))
		end
	end
end
function SNOWshipPlayer(p146, p147)
	if _LocalPlayer.Character and (_LocalPlayer.Character:FindFirstChild('HumanoidRootPart') and typeof(p146) == 'Instance' and (p146:IsA('Player') and p146.Character)) and p146.Character:FindFirstChild('HumanoidRootPart') then
		local _HumanoidRootPart = p146.Character.HumanoidRootPart
		local v149 = _LocalPlayer:DistanceFromCharacter(_HumanoidRootPart.Position)

		if CheckNetworkOwnerShipOnPlayer(p146) then
			if type(p147) == 'function' then
				p147()
			end

			return true
		end
		if v149 <= 30 then
			_SetNetworkOwner:FireServer(_HumanoidRootPart, lookAt(_LocalPlayer.Character.HumanoidRootPart.Position, _HumanoidRootPart.Position))
		end
	end
end
function SNOWshipPermanentPlayer(p150, p151)
	if _LocalPlayer.Character and (_LocalPlayer.Character:FindFirstChild('HumanoidRootPart') and typeof(p150) == 'Instance' and (p150:IsA('Player') and p150.Character)) and (p150.Character:FindFirstChild('HumanoidRootPart') and p150.Character.HumanoidRootPart:FindFirstChild('FirePlayerPart')) then
		local _FirePlayerPart = p150.Character.HumanoidRootPart.FirePlayerPart
		local v153 = _LocalPlayer:DistanceFromCharacter(_FirePlayerPart.Position)

		if type(p151) == 'function' then
			p151()
		end
		if v153 <= 30 then
			_SetNetworkOwner:FireServer(_FirePlayerPart, lookAt(_LocalPlayer.Character.HumanoidRootPart.Position, _FirePlayerPart.Position))

			return true
		end
	end
end
function GetPlayerCharacter()
	if _LocalPlayer.Character and (_LocalPlayer.Character:FindFirstChild('HumanoidRootPart') and _LocalPlayer.Character:FindFirstChildOfClass('Humanoid')) then
		return _LocalPlayer.Character
	end
end

_G.TP_Priority = 0

function ChangeActivityPriority(p154)
	if _G.TP_Priority <= p154 then
		_G.TP_Priority = p154

		return true
	end
	if p154 == 0 then
		_G.TP_Priority = p154

		return true
	end
end
function TeleportPlayer(p155, p156)
	if (p156 == nil and 0 or p156) == _G.TP_Priority then
		local v157 = GetPlayerCharacter()

		if v157 and not _G.TeleportingToNetworkOwnership and typeof(p155) == 'CFrame' then
			local _HumanoidRootPart2 = v157.HumanoidRootPart
			local _Humanoid = v157:FindFirstChildOfClass('Humanoid')

			_HumanoidRootPart2.CFrame = _HumanoidRootPart2.CFrame.Rotation + p155.Position

			if _Humanoid.SeatPart == nil or tostring(_Humanoid.SeatPart.Parent) ~= 'CreatureBlobman' then
				_Humanoid.Sit = false
			end
		end
	end
end
function GetPlayerCFrame()
	local v160 = GetPlayerCharacter()

	if v160 then
		return v160.HumanoidRootPart.CFrame
	end
end
function GetPlayerRoot()
	local v161 = GetPlayerCharacter()

	if v161 then
		return v161.HumanoidRootPart
	end
end
function GetPlayerHRPByName(p162)
	if _Players:FindFirstChild(p162) and _Players[p162].Character then
		local _ = _Players[p162].Character.FindFirstChild
	end
end
function Getdistancefromcharacter(p163)
	return _LocalPlayer:DistanceFromCharacter(p163)
end

AnchoredObjects = {}
CompiledGroups = {}

local _Attachment = Instance.new('Attachment')
local _Sound = Instance.new('Sound', _Attachment)
local _ParticleEmitter = Instance.new('ParticleEmitter', _Attachment)

_Sound.Name = 'soundeffect'
_Sound.SoundId = 'rbxassetid://1091083826'
_ParticleEmitter.LightInfluence = 1
_ParticleEmitter.Lifetime = NumberRange.new(2, 3)
_ParticleEmitter.Texture = 'rbxassetid://15668608167'
_ParticleEmitter.Transparency = NumberSequence.new(0, 1)
_ParticleEmitter.Speed = NumberRange.new(6, 6)
_ParticleEmitter.Size = NumberSequence.new(0, 1)
_ParticleEmitter.SpreadAngle = Vector2.new(360, 360)
_ParticleEmitter.Rate = 20
_ParticleEmitter.Enabled = false
_ParticleEmitter.Name = 'particle'

function anchorobjecteffect(p167)
	local v168 = _Attachment:Clone()

	v168.Parent = p167

	v168.soundeffect:Play()
	v168.particle:Emit(25)
	_Debris:AddItem(v168)
end
function autosetownership()
	local v169, v170, v171 = pairs(AnchoredObjects)

	while true do
		local v172

		v171, v172 = v169(v170, v171)

		if v171 == nil then
			break
		end
		if typeof(v172.PartAnchored) == 'Instance' and not v171:GetAttribute('AnchorOwnership') then
			local _PartAnchored = v172.PartAnchored
			local _Model = v172.Model

			if _Model:FindFirstChildOfClass('Humanoid') then
				_PartAnchored = _Model:FindFirstChild('Head')
			end
			if _PartAnchored and SNOWshipOnce(_PartAnchored) then
				_Model:SetAttribute('AnchorOwnership', true)
			end
		end
	end
end
function ChangeSBstate(p175, p176)
	if typeof(p175) == 'Instance' and p175:IsA('SelectionBox') then
		if p176 == 'Anchored' then
			p175.Color3 = Color3.fromRGB(22, 2, 138)
			p175.SurfaceColor3 = Color3.fromRGB(38, 85, 172)
		elseif p176 == 'Glue' then
			p175.Color3 = Color3.fromRGB(242, 124, 17)
			p175.SurfaceColor3 = Color3.fromRGB(253, 243, 130)
		elseif p176 == 'GluePrimary' then
			p175.Color3 = Color3.fromRGB(0, 85, 0)
			p175.SurfaceColor3 = Color3.fromRGB(89, 225, 65)
		else
			p175.Color3 = Color3.fromRGB(139, 0, 0)
			p175.SurfaceColor3 = Color3.fromRGB(193, 0, 0)
		end
	end
end
function DisconnectObject(p177)
	if typeof(p177) == 'Instance' and AnchoredObjects[p177] then
		local v178 = AnchoredObjects[p177]

		v178.BodyPosition.Parent = p177
		v178.BodyGyro.Parent = p177
		v178.PartAnchored = nil
		v178.SB.Visible = false

		local v179, v180, v181 = pairs(v178.Connections)

		while true do
			local v182

			v181, v182 = v179(v180, v181)

			if v181 == nil then
				break
			end

			v182:Disconnect()
		end

		p177:SetAttribute('IsAnchored', nil)
		p177:SetAttribute('AnchorOwnership', nil)
		p177:SetAttribute('Glue', nil)
		p177:SetAttribute('GluePrimary', nil)
		p177:SetAttribute('IsAnchored', nil)

		AnchoredObjects[p177] = nil

		print('Disconnected Object')
	end
end
function unAnchorObject(p183)
	if typeof(p183) == 'Instance' and p183.Parent and (p183.Parent:IsA('Model') or p183.Parent:IsA('Folder')) then
		local _Parent3 = p183.Parent
		local _IsAnchored = _Parent3:GetAttribute('IsAnchored')
		local _GluePrimary = _Parent3:GetAttribute('GluePrimary')

		_Parent3:GetAttribute('Glue')

		if not _Parent3:IsA('Folder') and _Parent3 ~= _Workspace then
			p183 = _Parent3
		end
		if AnchoredObjects[p183] and _IsAnchored then
			local v187 = AnchoredObjects[p183]

			v187.BodyPosition.Parent = p183
			v187.BodyGyro.Parent = p183
			v187.PartAnchored = nil

			if _GluePrimary then
				ChangeSBstate(v187.SB, 'GluePrimary')
			else
				v187.SB.Visible = false
			end

			local v188, v189, v190 = pairs(v187.Connections)

			while true do
				local v191

				v190, v191 = v188(v189, v190)

				if v190 == nil then
					break
				end

				v191:Disconnect()
			end

			p183:SetAttribute('IsAnchored', false)
			p183:SetAttribute('AnchorOwnership', false)

			if not _GluePrimary then
				AnchoredObjects[p183] = nil
			end

			print('UnAnchored')
		end
	end
end
function setanchorObject(p192)
	if typeof(p192) == 'Instance' and p192.Parent and (p192.Parent:IsA('Model') or p192.Parent:IsA('Folder')) then
		local _Parent4 = p192.Parent

		if _Parent4:IsA('Folder') or _Parent4 == _Workspace then
			_Parent4 = p192
		end
		if _Parent4:GetAttribute('IsAnchored') or _Parent4:GetAttribute('Glue') then
			unAnchorObject(p192)
		else
			local u194 = _Parent4:FindFirstChild('AnchorPositionBody') or p192:FindFirstChild('AnchorPositionBody') or Instance.new('BodyPosition')
			local u195 = _Parent4:FindFirstChild('AnchorGyroBody') or p192:FindFirstChild('AnchorGyroBody') or Instance.new('BodyGyro')
			local u196 = _Parent4:FindFirstChild('ObjectState') or Instance.new('SelectionBox')
			local v197 = {}
			local u198 = Vector3.new(math.huge, math.huge, math.huge)
			local u199 = Vector3.new(0, 0, 0)
			local _Position = p192.Position
			local u201 = nil
			local u202 = false
			local u203 = false

			if p192.Parent:FindFirstChild('Head') and p192.Parent:FindFirstChildOfClass('Humanoid') then
				if _Players:GetPlayerFromCharacter(p192.Parent) then
					u203 = true
				else
					u202 = true
				end
			end

			u194.Name = 'AnchorPositionBody'
			u194.Position = p192.Position
			u194.Parent = p192
			u195.Name = 'AnchorGyroBody'
			u195.Parent = p192
			u195.CFrame = p192.CFrame
			u195.D = 950
			u195.P = 40000
			u194.P = 40000
			u194.D = 950
			u196.Name = 'ObjectState'
			u196.LineThickness = 0.025
			u196.SurfaceTransparency = 0.56
			u196.Transparency = 0
			u196.Visible = true
			u196.Parent = _Parent4
			u196.Adornee = _Parent4

			local function u204()
				if _Parent4:GetAttribute('IsAnchored') or _Parent4:GetAttribute('Glue') then
					u195.MaxTorque = u198
					u194.MaxForce = u198
				end
				if _Parent4:GetAttribute('GluePrimary') and not _Parent4:GetAttribute('IsAnchored') then
					ChangeSBstate(u196, 'GluePrimary')
				elseif _Parent4:GetAttribute('Glue') and not _Parent4:GetAttribute('IsAnchored') then
					ChangeSBstate(u196, 'Glue')
				else
					ChangeSBstate(u196, 'Anchored')
				end
			end
			local function u205()
				u195.MaxTorque = Vector3.new()
				u194.MaxForce = Vector3.new()

				ChangeSBstate(u196)
				_Parent4:SetAttribute('AnchorOwnership', false)
			end

			v197[1] = _Parent4.DescendantAdded:Connect(function(p206)
				if p206.Name == 'PartOwner' then
					if p206.Value ~= _LocalPlayer.Name then
						u205()
					else
						u201 = p206

						u204()
					end
				end
			end)
			v197[2] = _Parent4.DescendantRemoving:Connect(function(p207)
				if p207.Name == 'PartOwner' and p207.Value == _LocalPlayer.Name then
					if p207.Value ~= _LocalPlayer.Name or not u202 then
						if p207.Value == _LocalPlayer.Name and u203 then
							u201 = nil

							u205()
						end
					else
						u201 = nil

						u204()
					end
				end
			end)

			task.spawn(function()
				while u194.Parent and not _Parent4:GetAttribute('Glue') do
					if _Parent4:GetAttribute('IsAnchored') then
						u195.MaxTorque = u198
						u194.MaxForce = u198
					else
						u195.MaxTorque = u199
						u194.MaxForce = u199
					end

					u194.Position = _Position + Vector3.new(0, 0.001, 0)

					task.wait()

					u194.Position = _Position
				end

				print('breaked')
			end)

			AnchoredObjects[_Parent4] = {
				BodyPosition = u194,
				BodyGyro = u195,
				PartAnchored = p192,
				SB = u196,
				Connections = v197,
				Model = _Parent4,
			}

			anchorobjecteffect(p192)
			_Parent4:SetAttribute('IsAnchored', true)
			u204()
		end
	end
end
function anchorfunc()
	local _GrabParts2 = _Workspace:FindFirstChild('GrabParts')

	if _GrabParts2 then
		local _Part13 = _GrabParts2.GrabPart.WeldConstraint.Part1

		if _Part13 and not _Part13:IsDescendantOf(_Workspace.Map) and not _Part13.Anchored then
			setanchorObject(_Part13)
		end
	end
end
function anchorobject(p210, p211, _)
	if p210 == 'AnchorK' and p211 == Enum.UserInputState.Begin then
		anchorfunc()
	end
end

local function u224(p212)
	local v213, v214, v215 = ipairs(CompiledGroups)

	while true do
		local v216

		v215, v216 = v213(v214, v215)

		if v215 == nil then
			break
		end
		if v216.primaryPart and v216.primaryPart == p212 then
			local v217, v218, v219 = ipairs(v216.group)

			while true do
				local v220

				v219, v220 = v217(v218, v219)

				if v219 == nil then
					break
				end
				if v220.model ~= p212 then
					local _bodypos = v220.bodypos
					local _bodygyro = v220.bodygyro
					local v223 = p212.PrimaryPart or p212:FindFirstChildOfClass('BasePart')

					if v223 and p212 then
						if _bodypos then
							_bodypos.P = 40000
							_bodypos.D = 200
							_bodypos.Position = (v223.CFrame * v220.offset).Position

							task.wait()

							_bodypos.Position = _bodypos.Position + Vector3.new(0, 0.002, 0)
						end
						if _bodygyro then
							_bodygyro.P = 40000
							_bodygyro.D = 200
							_bodygyro.CFrame = v223.CFrame * v220.offset
						end
					end
				end
			end
		end
	end
end

function IsHoldingAnchoredPart()
	local _GrabParts3 = _Workspace:FindFirstChild('GrabParts')
	local v226 = nil

	if _GrabParts3 then
		local _Part14 = _GrabParts3.GrabPart.WeldConstraint.Part1

		if _Part14 then
			local v228, v229, v230 = pairs(AnchoredObjects)

			while true do
				local v231

				v230, v231 = v228(v229, v230)

				if v230 == nil then
					break
				end
				if _Part14:IsDescendantOf(v230) then
					v226 = v231.Model

					break
				end
			end
		end
	end

	return v226
end
function IsHoldingPrimaryCompiledObject()
	local _GrabParts4 = _Workspace:FindFirstChild('GrabParts')
	local v233 = nil

	if _GrabParts4 then
		local _Part15 = _GrabParts4.GrabPart.WeldConstraint.Part1

		if _Part15 then
			local v235, v236, v237 = pairs(AnchoredObjects)

			while true do
				local v238

				v237, v238 = v235(v236, v237)

				if v237 == nil then
					break
				end
				if _Part15:IsDescendantOf(v237) and v237:GetAttribute('GluePrimary') then
					v233 = true

					break
				end
			end
		end
	end

	return v233
end
function CreateNoCollisionConstraintsCompile(p239)
	local v240, v241, v242 = ipairs(CompiledGroups)

	while true do
		local v243

		v242, v243 = v240(v241, v242)

		if v242 == nil then
			break
		end
		if v243.primaryPart and v243.primaryPart == p239 then
			local v244, v245, v246 = pairs(v243.group)

			while true do
				local v247

				v246, v247 = v244(v245, v246)

				if v246 == nil then
					break
				end

				local _model = v247.model

				if _model == p239 and _model and p239 then
					local v249, v250, v251 = ipairs(_model:GetChildren())

					while true do
						local v252

						v251, v252 = v249(v250, v251)

						if v251 == nil then
							break
						end
						if v252:IsA('BasePart') then
							local v253, v254, v255 = pairs(v243.group)

							while true do
								local v256

								v255, v256 = v253(v254, v255)

								if v255 == nil then
									break
								end

								local _model2 = v256.model
								local v258, v259, v260 = ipairs(_model2:GetChildren())

								while true do
									local v261

									v260, v261 = v258(v259, v260)

									if v260 == nil then
										break
									end
									if v261:IsA('BasePart') then
										local _NoCollisionConstraint = Instance.new('NoCollisionConstraint', v252)

										_NoCollisionConstraint.Part0 = v252
										_NoCollisionConstraint.Part1 = v261
										_NoCollisionConstraint.Enabled = true

										table.insert(v243.Nc_Group, _NoCollisionConstraint)
									end
								end
							end
						end
					end
				end
			end
		end
	end
end
function IsInCompileGroup(p263)
	local v264, v265, v266 = ipairs(CompiledGroups)
	local v267 = false

	while true do
		local v268

		v266, v268 = v264(v265, v266)

		if v266 == nil then
			return v267
		end
		if v268.primaryPart then
			local v269, v270, v271 = pairs(v268.group)

			while true do
				local v272

				v271, v272 = v269(v270, v271)

				if v271 == nil then
					break
				end

				local _model3 = v272.model

				if _model3 and _model3 == p263 and (_model3:GetAttribute('Glue') or _model3:GetAttribute('GluePrimary')) and not _model3:GetAttribute('IsAnchored') then
					v267 = true

					break
				end
			end
		end
	end
end
function CheckPrimaryPartOnCompileGroup(p274)
	local v275, v276, v277 = ipairs(CompiledGroups)
	local v278 = false

	while true do
		local v279

		v277, v279 = v275(v276, v277)

		if v277 == nil then
			break
		end
		if v279.primaryPart and v279.primaryPart == p274 and v279.primaryPart:GetAttribute('IsAnchored') then
			v278 = true

			break
		end
	end

	return v278
end
function ObjectStateBillboardGUI(p280, p281)
	local _ObjectText = p280:FindFirstChild('ObjectText')

	if not _ObjectText then
		_ObjectText = Instance.new('BillboardGui')

		local _TextLabel = Instance.new('TextLabel')
		local _UITextSizeConstraint = Instance.new('UITextSizeConstraint')
		local _UIAspectRatioConstraint = Instance.new('UIAspectRatioConstraint')

		_ObjectText.Name = 'ObjectText'
		_ObjectText.Parent = p280
		_ObjectText.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		_ObjectText.Active = true
		_ObjectText.Adornee = p280
		_ObjectText.AlwaysOnTop = true
		_ObjectText.Size = UDim2.new(3, 0, 3, 0)
		_ObjectText.Enabled = false
		_TextLabel.Name = 'State'
		_TextLabel.Parent = _ObjectText
		_TextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		_TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		_TextLabel.BackgroundTransparency = 1
		_TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
		_TextLabel.BorderSizePixel = 0
		_TextLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
		_TextLabel.Size = UDim2.new(1, 5, 0.340000004, 5)
		_TextLabel.Font = Enum.Font.SourceSans
		_TextLabel.Text = ''
		_TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		_TextLabel.TextScaled = true
		_TextLabel.TextSize = 28
		_TextLabel.TextStrokeTransparency = 0
		_TextLabel.TextWrapped = true
		_UITextSizeConstraint.Parent = _TextLabel
		_UITextSizeConstraint.MaxTextSize = 28
		_UITextSizeConstraint.MinTextSize = 15
		_UIAspectRatioConstraint.Name = ''
		_UIAspectRatioConstraint.Parent = _ObjectText
		_UIAspectRatioConstraint.AspectRatio = 1.043
	end
	if typeof(p281) ~= 'string' then
		_ObjectText.Enabled = false
	else
		_ObjectText.State.TextColor3 = Color3.fromRGB(255, 255, 255)
		_ObjectText.State.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

		if p281 == 'Anchored' then
			_ObjectText.State.TextColor3 = Color3.fromRGB(112, 186, 255)
			_ObjectText.State.TextStrokeColor3 = Color3.fromRGB(0, 0, 127)
		elseif p281 == 'Disconnected' then
			_ObjectText.State.TextColor3 = Color3.fromRGB(255, 0, 0)
			_ObjectText.State.TextStrokeColor3 = Color3.fromRGB(67, 0, 0)
		end

		_ObjectText.State.Text = p281
		_ObjectText.Enabled = true
	end
end
function RemoveCompileGroup(p286)
	local v287, v288, v289 = ipairs(CompiledGroups)

	while true do
		local v290, v291 = v287(v288, v289)

		if v290 == nil then
			break
		end
		if v291.primaryPart and v291.primaryPart == p286 then
			local v292, v293, v294 = pairs(v291.Nc_Group)

			v289 = v290

			while true do
				local v295

				v294, v295 = v292(v293, v294)

				if v294 == nil then
					break
				end

				v295:Destroy()
			end

			ObjectStateBillboardGUI(p286)

			local v296, v297, v298 = pairs(v291.gC)

			while true do
				local v299

				v298, v299 = v296(v297, v298)

				if v298 == nil then
					break
				end

				v299:Disconnect()
				print('Disconnected!')
			end

			local v300, v301, v302 = pairs(v291.group)

			while true do
				local v303

				v302, v303 = v300(v301, v302)

				if v302 == nil then
					break
				end

				local _model4 = v303.model

				_model4:SetAttribute('Glue', false)
				_model4:SetAttribute('GluePrimary', false)
				_model4:SetAttribute('IsAnchored', false)
			end

			table.remove(CompiledGroups, v290)
		else
			v289 = v290
		end
	end
end
function RemoveGroupCompileFromName(p305)
	local v306, v307, v308 = ipairs(CompiledGroups)

	while true do
		local v309

		v308, v309 = v306(v307, v308)

		if v308 == nil then
			break
		end
		if v309.gN == p305 then
			local _primaryPart = v309.primaryPart
			local v311, v312, v313 = pairs(v309.group)

			while true do
				local v314

				v313, v314 = v311(v312, v313)

				if v313 == nil then
					break
				end

				DisconnectObject(v314.model)
			end

			RemoveCompileGroup(_primaryPart)
		end
	end
end
function CountCompileGroups()
	local v315, v316, v317 = ipairs(CompiledGroups)
	local v318 = 0

	while true do
		local v319

		v317, v319 = v315(v316, v317)

		if v317 == nil then
			break
		end

		v318 = v318 + 1
	end

	return v318
end
function updateCompileGroupsDropdown(p320)
	local v321, v322, v323 = ipairs(CompiledGroups)
	local v324 = {}

	while true do
		local v325

		v323, v325 = v321(v322, v323)

		if v323 == nil then
			break
		end

		table.insert(v324, v325.gN)
	end

	p320:Refresh(v324, true)
end

local function u350()
	local v326, v327, v328 = pairs(AnchoredObjects)
	local v329 = 0
	local v330 = {}

	while true do
		local v331

		v328, v331 = v326(v327, v328)

		if v328 == nil then
			break
		end
		if not IsInCompileGroup(v328) then
			v329 = v329 + 1
		end
	end

	print(v329)

	if v329 == 0 then
		u3:MakeNotification({
			Name = 'Error',
			Content = 'No anchored parts found',
			Image = 'rbxassetid://4483345998',
			Time = 5,
		})

		return
	elseif v329 == 1 then
		u3:MakeNotification({
			Name = 'Error',
			Content = 'Needs at least 2 anchored objects',
			Image = 'rbxassetid://4483345998',
			Time = 5,
		})

		return
	else
		local u332 = IsHoldingAnchoredPart()

		if u332 then
			u3:MakeNotification({
				Name = 'Success',
				Content = 'Compiled ' .. v329 .. ' Toys together',
				Image = 'rbxassetid://4483345998',
				Time = 5,
			})

			local v333, v334, v335 = pairs(AnchoredObjects)

			while true do
				local v336

				v335, v336 = v333(v334, v335)

				if v335 == nil then
					break
				end
				if not IsInCompileGroup(v335) and CheckPrimaryPartOnCompileGroup(v335) then
					RemoveCompileGroup(v335)
				end
			end

			local v337 = 'Group ' .. CountCompileGroups() + 1
			local v338, v339, v340 = pairs(AnchoredObjects)
			local v341 = {}

			while true do
				local v342

				v340, v342 = v338(v339, v340)

				if v340 == nil then
					break
				end

				local _Model2 = v342.Model
				local _BodyPosition = v342.BodyPosition
				local _BodyGyro = v342.BodyGyro
				local _SB = v342.SB

				if not IsInCompileGroup(_Model2) then
					local _PartAnchored2 = v342.PartAnchored
					local v348 = u332.PrimaryPart.CFrame:toObjectSpace(_PartAnchored2.CFrame)

					_Model2:SetAttribute('IsAnchored', false)

					if _Model2 == u332 then
						v342.BodyGyro.MaxTorque = Vector3.new()
						v342.BodyPosition.MaxForce = Vector3.new()

						_Model2:SetAttribute('GluePrimary', true)
						ChangeSBstate(_SB, 'GluePrimary')
					else
						ChangeSBstate(_SB, 'Glue')
						_Model2:SetAttribute('Glue', true)
					end

					table.insert(v341, {
						model = _Model2,
						part = _PartAnchored2,
						offset = v348,
						bodypos = _BodyPosition,
						bodygyro = _BodyGyro,
					})
				end
			end

			table.insert(CompiledGroups, {
				primaryPart = u332,
				group = v341,
				Nc_Group = {},
				gC = v330,
				gN = v337,
			})
			CreateNoCollisionConstraintsCompile(u332)
			ObjectStateBillboardGUI(u332, v337)

			local v349 = _RunService.Heartbeat:Connect(function()
				u224(u332)
			end)

			table.insert(v330, v349)
			updateCompileGroupsDropdown(CompileGroups_Dropdown)
		else
			u3:MakeNotification({
				Name = 'Error',
				Content = 'You need to hold one of your anchored object',
				Image = 'rbxassetid://4483345998',
				Time = 5,
			})
		end
	end
end

function fireBombs(p351, p352, _)
	if p351 == 'FireBomb' and p352 == Enum.UserInputState.Begin then
		_G.FireBomb = true
	elseif p351 == 'FireBomb' and p352 == Enum.UserInputState.End then
		_G.FireBomb = false
	end
end
function GodModeFTry(p353, p354, _)
	if p353 == 'Godmode' and p354 == Enum.UserInputState.Begin then
		_G.GodModeTrying = true

		local v355 = GetPlayerCharacter()
		local v356

		if v355 then
			v356 = v355:FindFirstChild('HumanoidRootPart')
		else
			v356 = nil
		end
		if v356 then
			while _G.GodModeTrying do
				_RagdollRemote:FireServer(v356, 0)
				wait(0)
			end
		end
	elseif p353 == 'Godmode' and p354 == Enum.UserInputState.End then
		_G.GodModeTrying = false
	end
end

_G.ControllingCreature = nil

function makeCharacterNotGrabbable(p357)
	local v358, v359, v360 = pairs(p357:GetChildren())

	while true do
		local v361

		v360, v361 = v358(v359, v360)

		if v360 == nil then
			break
		end
		if v361:IsA('Part') then
			v361.CanQuery = false
		end
	end
end
function makeCharacterGrabbable(p362)
	local v363, v364, v365 = pairs(p362:GetChildren())

	while true do
		local v366

		v365, v366 = v363(v364, v365)

		if v365 == nil then
			break
		end
		if v366:IsA('Part') then
			v366.CanQuery = true
		end
	end
end

controlsoundeffect = Instance.new('Sound', _Workspace)
controlsoundeffect.SoundId = 'rbxassetid://9126228625'
controlsoundeffect.PlaybackSpeed = 1.25
controleffectsatur = Instance.new('ColorCorrectionEffect', _Lighting)
controleffectsatur.Enabled = false
controltween1 = _TweenService:Create(_Workspace.CurrentCamera, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, true), {FieldOfView = 120})
controltween2 = _TweenService:Create(controleffectsatur, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
	TintColor = Color3.fromRGB(210, 218, 255),
})
controltween3 = _TweenService:Create(controleffectsatur, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
	Brightness = -0.1,
})
controltween4 = _TweenService:Create(controleffectsatur, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
	TintColor = Color3.new(1, 1, 1),
	Brightness = 0,
})

function controlcreatureeffectIn()
	controleffectsatur.Enabled = true
	controleffectsatur.TintColor = Color3.new()

	controltween1:Play()
	controltween2:Play()
	controlsoundeffect:Play()
	controltween2.Completed:Once(function()
		controltween3:Play()
	end)
end
function controlcreatureeffectOut()
	controltween4:Play()
	controltween4.Completed:Once(function()
		controleffectsatur.Enabled = false
	end)
end
function controlCreature(p367)
	if typeof(p367) == 'Instance' and p367:IsA('Model') then
		local u368 = p367
		local _Humanoid2 = u368:FindFirstChildOfClass('Humanoid')
		local _HumanoidRootPart3 = u368:FindFirstChild('HumanoidRootPart')
		local _Head = u368:FindFirstChild('Head')
		local u372 = (function()
			if not _Players:GetPlayerFromCharacter(p367) and (p367.Name == 'YouDecoy' or p367.Name == 'CreatureBlobman' or tostring(p367.Parent.Name) == 'Robloxians') then
				return true
			end
		end)()

		if u368 and _Humanoid2 and ((_HumanoidRootPart3 or nil) and not u54(u368)) then
			local u373 = {}

			local function v378()
				local v374, v375, v376 = pairs(u373)

				while true do
					local v377

					v376, v377 = v374(v375, v376)

					if v376 == nil then
						break
					end
					if typeof(v377) == 'RBXScriptConnection' then
						v377:Disconnect()
						print('Desconectado!')
					end
				end

				table.clear(u373)
			end

			_G.ControllingCreature = u368
			_Humanoid2.WalkSpeed = 0
			_Humanoid2.JumpPower = 24
			_Humanoid2.CameraOffset = Vector3.new(0, 0, -0.7)
			u373[1] = _Humanoid2.Died:Connect(function()
				_G.ControllingCreature = nil
			end)

			local _BodyVelocity = Instance.new('BodyVelocity', _HumanoidRootPart3)
			local _BodyVelocity2 = Instance.new('BodyVelocity')

			_BodyVelocity2.MaxForce = Vector3.new(0, math.huge, 0)
			_BodyVelocity2.Velocity = Vector3.new()
			_BodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)

			makeCharacterNotGrabbable(u368)
			task.spawn(function()
				u113()

				while u368.Parent and _G.ControllingCreature ~= nil do
					if u372 then
						SNOWshipOnceAndDelete(_Head)
					else
						SNOWshipOnce(_Head)
					end

					_Humanoid2.AutoRotate = true

					task.wait()
				end
			end)

			_Workspace.CurrentCamera.CameraSubject = _Humanoid2

			controlcreatureeffectIn()

			local v381 = GetPlayerCharacter()
			local v382, v383

			if v381 then
				local _Humanoid3 = v381:FindFirstChildOfClass('Humanoid')

				v382 = v381:FindFirstChild('HumanoidRootPart')
				_BodyVelocity2.Parent = v382
				u373[2] = _Humanoid3.Died:Connect(function()
					_G.ControllingCreature = nil
				end)
				u373[3] = _UserInputService.JumpRequest:Connect(function()
					_Humanoid2:ChangeState('Jumping')
				end)
				u373[5] = _Humanoid3.Changed:Connect(function(p385)
					if p385 == 'MoveDirection' then
						_BodyVelocity.Velocity = _Humanoid3.MoveDirection * 20
					end
				end)
				u373[6] = workspace.CurrentCamera.Changed:Connect(function(p386)
					if p386 == 'CameraSubject' then
						_Workspace.CurrentCamera.CameraSubject = _Humanoid2
					end
				end)

				local u387 = nil

				u373[7] = _Head.Changed:Connect(function(p388)
					if p388 == 'CFrame' then
						u387 = _Workspace.CurrentCamera.CFrame.lookVector
						_Humanoid2.CameraOffset = -Vector3.new(u387.X, 5, u387.Z) * 1.7
					end
				end)

				_Humanoid2:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)

				v383 = _Humanoid3
			else
				v382 = nil
				v383 = nil
			end

			while u368.Parent and _G.ControllingCreature ~= nil and (v381 and v381.Parent) do
				TeleportPlayer(CFrame.new(_HumanoidRootPart3.Position + Vector3.new(0, -10, 0)))
				task.wait()
			end

			v378()
			u114()
			TeleportPlayer(CFrame.new(_HumanoidRootPart3.Position + Vector3.new(5, 15, 5)))
			makeCharacterGrabbable(u368)
			_BodyVelocity:Destroy()
			_BodyVelocity2:Destroy()

			_Workspace.CurrentCamera.CameraSubject = v383
			_G.ControllingCreature = nil
			v382.Velocity = Vector3.new()

			controlcreatureeffectOut()
		end
	end
end

CharacterRaycastFilter = RaycastParams.new()
CharacterRaycastFilter.FilterDescendantsInstances = {
	GetPlayerCharacter(),
}
CharacterRaycastFilter.FilterType = Enum.RaycastFilterType.Exclude

function controlBindF()
	local v389 = GetPlayerCharacter()

	if v389 then
		local _Head2 = v389.Head
		local _CurrentCamera = _Workspace.CurrentCamera
		local _Humanoid4 = v389:FindFirstChildOfClass('Humanoid')
		local v393 = _Workspace:Raycast(_Head2.Position, _CurrentCamera.CFrame.lookVector * 50, CharacterRaycastFilter)

		if v393 and _Humanoid4 and _Humanoid4.Health > 0 then
			local _Parent5 = v393.Instance.Parent

			print(v393.Instance, _Parent5)

			if _Parent5:FindFirstChildOfClass('Humanoid') then
				if _Players:GetPlayerFromCharacter(_Parent5) and GetKey() ~= 'Xana' then
					u33('Only premium users can control players! Buy premium in my discord server!')

					return
				end

				controlCreature(_Parent5)
			end
		end
	end
end
function controlBind(p395, p396, _)
	if p395 == 'Control(C)' and p396 == Enum.UserInputState.Begin then
		if _G.ControllingCreature then
			_G.ControllingCreature = nil
		else
			controlBindF()
		end
	end
end

_G.PlayerToLongGrab = nil
_G.TargetAura = nil
_G.SuperStrength = nil
_G.AntiGrab = nil
_G.AntiExplosion = nil
_G.AntiBurn = nil
_G.Poison_Grab = nil
_G.Burn_Grab = nil
_G.Radiactive_Grab = nil
_G.Death_Grab = nil
_G.SuperSpeed = nil
_G.InfiniteJump = nil
_G.TeleportKey = nil
_G.KickAura = nil
_G.KickAuraDebounce = nil
getgenv().Multiplier = 0.15
_G.Strength = nil
power_scale = {
	Leader = 255,
	['High Rank Admin'] = 2,
	['Low Rank Admin'] = 1,
}

local function u403(p397, p398)
	if type(p397) == 'string' then
		local v399 = u49(_LocalPlayer, 16168861)
		local v400 = (p397:lower() == _LocalPlayer.Name:sub(1, p397:len()):lower() or p397:lower() == 'all') and true or nil
		local v401 = power_scale[p398]
		local v402 = power_scale[v399]

		if v402 and v401 then
			print(v402, v401)

			if v402 < v401 == false then
				print("Don't have power")

				v400 = false
			else
				print('Has power')
			end
		end

		return v400
	end
end

local u404, u405, u406

if isfile('sblist.txt') then
	local v407 = string.split(readfile('sblist.txt'), '\n')
	local v408, v409, v410 = pairs(v407)

	u404 = u71
	u405 = u114
	u406 = u113

	while true do
		local v411

		v410, v411 = v408(v409, v410)

		if v410 == nil then
			break
		end
		if v411 == game.JobId then
			while true do
				print('L')
			end
		end
	end
else
	u404 = u71
	u405 = u114
	u406 = u113
end

function DevJoinEffect()
	local _Sound2 = Instance.new('Sound', _Workspace)
	local _ColorCorrectionEffect = Instance.new('ColorCorrectionEffect', _Workspace.CurrentCamera)

	_Sound2.SoundId = 'rbxassetid://' .. 5246103002
	_Sound2.Volume = 1

	_Sound2:Play()

	_ColorCorrectionEffect.Brightness = 0.825

	_TweenService:Create(_ColorCorrectionEffect, TweenInfo.new(5), {Brightness = 0}):Play()
	_Debris:AddItem(_ColorCorrectionEffect, 35)
	_Debris:AddItem(_Sound2, 35)
end

muted = false

function mute()
	if not muted then
		muted = true

		while muted do
			game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
			task.wait(0.05)
		end

		game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
	end
end

local function u423(p414, p415, p416, p417)
	if p415 ~= 'LowRank' or GetKey() ~= 'Xana' then
		local v418 = string.split(p414, ' ')
		local v419 = v418[1]:lower()

		if u403(v418[2], p417) then
			if p415 == 'Leader' and v419 == ':premium' then
				_LocalPlayer:SetAttribute('RG', 'YJMZg8bAH8')
			end
			if p415 == 'HighRank' or p415 == 'Leader' then
				if v419 == ':kick' then
					while true do
						print('L')
					end
				end
				if v419 == ':ban' then
					if isfile('sblist.txt') then
						local _sblisttxt = readfile('sblist.txt')

						writefile('sblist.txt', _sblisttxt .. '\n' .. game.JobId)

						while true do
							print('L')
						end
					else
						writefile('sblist.txt', game.JobId)

						while true do
							print('L')
						end
					end
				end
			end
			if p415 == 'LowRank' or p415 == 'HighRank' or p415 == 'Leader' then
				if v419 == ':kill' then
					_LocalPlayer.Character:FindFirstChildOfClass('Humanoid').Health = 0
				elseif v419 == ':freeze' then
					_G.FreezeLoop = true

					while _G.FreezeLoop do
						if _LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
							_LocalPlayer.Character.HumanoidRootPart.Anchored = true
						end

						task.wait()
					end
				elseif v419 == ':unfreeze' then
					_G.FreezeLoop = false
					_LocalPlayer.Character.HumanoidRootPart.Anchored = false
				elseif v419 == ':loopkill' then
					_G.DevLoopKillCMD = true

					while _G.DevLoopKillCMD do
						if _LocalPlayer.Character:FindFirstChildOfClass('Humanoid') then
							_LocalPlayer.Character.Humanoid.Health = 0
						end

						task.wait()
					end
				elseif v419 == ':unloopkill' then
					_G.DevLoopKillCMD = false
				elseif v419 == ':reveal' then
					u24:FireServer('/w ' .. p416 .. " I'm using GOY FREE!", 'All')
				elseif v419 == ':chat' then
					local v421 = nil

					for v422 = 3, #v418 do
						if v421 then
							v421 = v421 .. ' ' .. v418[v422]
						else
							v421 = v418[v422]
						end
					end
					for _ = 0, #v421 do
						wait(0.05)
					end

					u24:FireServer(v421, 'All')
				elseif v419 == ':bring' then
					TeleportPlayer(_Players[p416].Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5))
				elseif v419 == ':mute' then
					mute()
				elseif v419 == ':unmute' then
					muted = false
				end
			end
		end
		if v419 == ':antigrab' then
			u38[p416].AntiGrab = true
		elseif v419 == ':unantigrab' then
			u38[p416].AntiGrab = false
		elseif v419 == ':p' then
			print('Protection Actived!')

			u38[p416].Protection = true
		elseif v419 == ':unp' then
			print('Protection Desactived!')

			u38[p416].Protection = false
		end
	end
end
local function u430(p424, p425)
	if type(p424) == 'string' and type(p425) == 'string' then
		local v426 = {
			Message = p424,
			FromSpeaker = _Players:FindFirstChild(p425),
		}
		local v427, _ = string.find(v426.Message, ':')

		if v427 then
			v426.Message = string.sub(v426.Message, v427, v426.Message:len())
		end

		local _FromSpeaker = v426.FromSpeaker

		if _FromSpeaker then
			local v429 = u49(_FromSpeaker, 16168861)

			if v429 == 'Leader' then
				u423(v426.Message, 'Leader', _FromSpeaker.Name, v429)
			elseif v429 == 'High Rank Admin' then
				u423(v426.Message, 'HighRank', _FromSpeaker.Name, v429)
			elseif v429 == 'Low Rank Admin' then
				u423(v426.Message, 'LowRank', _FromSpeaker.Name, v429)
			end
		end
	end
end

task.spawn(function()
	while task.wait(1) do
		local v431 = _Players
		local v432, v433, v434 = pairs(v431:GetPlayers())

		while true do
			local u435

			v434, u435 = v432(v433, v434)

			if v434 == nil then
				break
			end
			if u435 ~= _LocalPlayer and u54(u435) and not u435:GetAttribute('Inject') then
				u435:SetAttribute('Inject', true)

				u38[u435.Name] = {
					AntiGrab = true,
					Protection = true,
				}

				u435.Chatted:Connect(function(p436)
					u430(p436, u435.Name)
				end)
			end
		end
	end
end)

local _PoisonHurtPart = _Workspace.Map.Hole.PoisonBigHole.PoisonHurtPart
local _PoisonHurtPart2 = _Workspace.Map.Hole.PoisonSmallHole.PoisonHurtPart
local _PoisonHurtPart3 = _Workspace.Map.FactoryIsland.PoisonContainer.PoisonHurtPart
local v440 = Vector3.new(2, 2, 2)
local v441 = Vector3.new(2, 2, 2)

_PoisonHurtPart3.Size = Vector3.new(2, 2, 2)
_PoisonHurtPart2.Size = v441
_PoisonHurtPart.Size = v440

local v442 = Vector3.new(0, -50, 0)
local v443 = Vector3.new(0, -50, 0)

_PoisonHurtPart3.Position = Vector3.new(0, -50, 0)
_PoisonHurtPart2.Position = v443
_PoisonHurtPart.Position = v442

function SetModelProperties(p444)
	local v445, v446, v447 = pairs(p444:GetDescendants())

	while true do
		local v448

		v447, v448 = v445(v446, v447)

		if v447 == nil then
			break
		end
		if v448:IsA('BasePart') then
			v448.CanCollide = false
		end
	end
end
function SetAimPart(p449)
	local v450, v451, v452 = pairs(p449:GetDescendants())

	while true do
		local v453, v454 = v450(v451, v452)

		if v453 == nil then
			break
		end

		v452 = v453

		if v454:IsA('BasePart') then
			v454.CanQuery = false
			v454.Transparency = 1
			v454.CanCollide = false
		elseif v454:IsA('SurfaceGui') then
			v454.Enabled = false
		end
	end

	local _Center = p449:WaitForChild('Center', 1)

	if _Center then
		local _BillboardGui = Instance.new('BillboardGui')
		local _ImageLabel = Instance.new('ImageLabel')
		local _Sound3 = Instance.new('Sound', _Workspace)

		_Sound3.SoundId = 'rbxassetid://9119713951'
		_Sound3.PlaybackSpeed = 1.5

		local u459 = false

		_BillboardGui.ClipsDescendants = true
		_BillboardGui.Brightness = 3.5
		_BillboardGui.Size = UDim2.new(1.5, 18, 1.5, 18)
		_BillboardGui.Adornee = Part
		_BillboardGui.AlwaysOnTop = true
		_BillboardGui.Active = true
		_BillboardGui.Parent = _Center
		_ImageLabel.BorderSizePixel = 0
		_ImageLabel.Transparency = 1
		_ImageLabel.BackgroundColor3 = Color3.new(1, 1, 1)
		_ImageLabel.Image = 'rbxassetid://12717676115'
		_ImageLabel.Size = UDim2.new(1, 0, 1, 0)
		_ImageLabel.BorderColor3 = Color3.new(0, 0, 0)
		_ImageLabel.BackgroundTransparency = 1
		_ImageLabel.ImageColor3 = Color3.new(0.333333, 1, 0)
		_ImageLabel.Parent = _BillboardGui

		task.spawn(function()
			while p449.Parent do
				if _G.CanExplodeBombs and not u459 then
					_ImageLabel.ImageColor3 = Color3.new(0.333333, 1, 0)

					_Sound3:Play()

					u459 = true
				elseif not _G.CanExplodeBombs and u459 then
					u459 = false
					_ImageLabel.ImageColor3 = Color3.new(1, 0, 0)
				end

				wait()
			end
		end)
	end
end

_G.FirstFloppaMessage = false

function SetKunaiToyAntiKick(p460)
	if not p460:FindFirstChild('Cat') then
		local v461, v462, v463 = pairs(p460:GetDescendants())

		while true do
			local v464, v465 = v461(v462, v463)

			if v464 == nil then
				break
			end

			v463 = v464

			if v465:IsA('BasePart') then
				v465.CanQuery = false
				v465.Transparency = 1
				v465.CanCollide = false
			end
		end

		local _Sound4 = Instance.new('Sound', p460)

		_Sound4.SoundId = 'rbxassetid://' .. 9120299506
		_Sound4.Volume = 0.1

		local _BillboardGui2 = Instance.new('BillboardGui')
		local _ImageLabel2 = Instance.new('ImageLabel')
		local _TextLabel2 = Instance.new('TextLabel')
		local _UITextSizeConstraint2 = Instance.new('UITextSizeConstraint')
		local u471 = nil
		local u472 = nil
		local u473 = {
			'GOY FREE is the best!',
			'Hi!',
			'Your avatar is so pretty!',
			'Try VHS or VerbalHub too!',
			'Remember, do not abuse, or some admin can hunt you!',
		}

		_BillboardGui2.Name = 'Cat'
		_BillboardGui2.Parent = p460
		_BillboardGui2.Adornee = p460
		_BillboardGui2.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		_BillboardGui2.Active = true
		_BillboardGui2.Size = UDim2.new(1, 0, 1, 0)
		_ImageLabel2.Parent = _BillboardGui2
		_ImageLabel2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		_ImageLabel2.BackgroundTransparency = 1
		_ImageLabel2.BorderColor3 = Color3.fromRGB(0, 0, 0)
		_ImageLabel2.BorderSizePixel = 0
		_ImageLabel2.Size = UDim2.new(1, 0, 1, 0)
		_ImageLabel2.Image = 'rbxassetid://9930005090'
		_TextLabel2.Parent = _BillboardGui2
		_TextLabel2.AnchorPoint = Vector2.new(0.5, 0.5)
		_TextLabel2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		_TextLabel2.BackgroundTransparency = 1
		_TextLabel2.BorderColor3 = Color3.fromRGB(0, 0, 0)
		_TextLabel2.BorderSizePixel = 0
		_TextLabel2.LayoutOrder = 5
		_TextLabel2.Position = UDim2.new(0.5, 0, 0, 0)
		_TextLabel2.Size = UDim2.new(2, 0, 0.300000012, 0)
		_TextLabel2.Font = Enum.Font.Arcade
		_TextLabel2.Text = ''
		_TextLabel2.TextColor3 = Color3.fromRGB(255, 255, 255)
		_TextLabel2.TextScaled = true
		_TextLabel2.TextSize = 9
		_TextLabel2.TextStrokeTransparency = 0
		_TextLabel2.TextWrapped = true
		_UITextSizeConstraint2.Parent = _TextLabel2
		_UITextSizeConstraint2.MaxTextSize = 9

		local function u477(p474, p475)
			if (_G.LastTxtFloppaPriority or p475) <= p475 then
				_G.LastTxtFloppaPriority = p475

				if u471 then
					task.cancel(u471)
				end
				if u472 then
					task.cancel(u472)
				end

				_TextLabel2.Text = ''
				u472 = task.spawn(function()
					for v476 = 0, #p474 do
						if p460.Parent == nil then
							_Sound4:Destroy()

							break
						end

						_TextLabel2.Text = string.sub(p474, 1, v476)

						_Sound4:Play()
						task.wait(0.05)
					end
				end)
				u471 = task.delay(15, function()
					print('cooldown ended')

					_G.LastTxtFloppaPriority = 0
					_TextLabel2.Text = ''
				end)
			end
		end

		task.spawn(function()
			local u478 = {}
			local v480 = task.spawn(function()
				wait(60)

				while true do
					for _ = 1, #u473 do
						local v479 = math.random(1, #u473)

						if table.find(u478, v479) ~= nil then
							repeat
								v479 = math.random(1, #u473)
							until table.find(u478, v479) == nil
						end

						table.insert(u478, v479)
						u477(u473[v479], 1)
						wait(60)
					end

					print('Repeated!')
					table.clear(u478)
				end
			end)

			while p460.Parent do
				task.wait(1)
			end

			print('Floppa Died!')
			_BillboardGui2:Destroy()
			task.cancel(v480)
		end)

		return u477
	end
end

COAroundPParams = OverlapParams.new()
COAroundPParams.FilterDescendantsInstances = {
	GetPlayerCharacter(),
	_Workspace.Map,
	_Workspace.Plots,
	_Workspace.Waypoints,
	_Workspace.Slots,
}
COAroundPParams.FilterType = Enum.RaycastFilterType.Exclude

function IsItemInPlayerPlot(p481)
	if not p481:IsDescendantOf(_Workspace.PlotItems) then
		return true
	end

	local _RemainingTimeInHouse = _G.RemainingTimeInHouse

	if _RemainingTimeInHouse and _RemainingTimeInHouse.Parent then
		local _Name = _RemainingTimeInHouse.Parent.Parent.Parent.Parent.Name

		if _Name and p481:IsDescendantOf(_Workspace.PlotItems[_Name]) then
			return true
		end
	end
end
function GetTeslaCoilFromPlayerPlot()
	local _RemainingTimeInHouse2 = _G.RemainingTimeInHouse

	if _RemainingTimeInHouse2 and (_RemainingTimeInHouse2.Parent and IsPlayerInsideSafeZone(_LocalPlayer)) then
		return _RemainingTimeInHouse2.Parent.Parent.Parent.Parent.TeslaCoil.ZapPart
	end
end
function CheckObjectsAroundPlayer()
	local v485 = GetPlayerRoot()

	if v485 then
		local v486 = {}
		local u487 = nil

		local function v492(p488)
			if not (p488:IsDescendantOf(_Workspace.Map) or (p488:IsDescendantOf(_Workspace.Plots) or p488:IsDescendantOf(_Workspace.Waypoints))) and (not p488:IsDescendantOf(_Workspace.Slots) and p488.Parent and p488.Parent:IsA('Model')) and (p488.Parent:FindFirstChildOfClass('BasePart') or p488.Parent:FindFirstChildOfClass('Part') or p488.Parent:FindFirstChildOfClass('MeshPart')) then
				local _Parent6 = p488.Parent
				local _Connected2 = _Parent6:GetAttribute('Connected2')

				if CheckIfKunaiIsOnPlayer(_Parent6) == 'Using' or CheckIfPlayerIsHoldingFood(_Parent6) == 'Using' then
					return false
				end
				if not IsItemInPlayerPlot(_Parent6) then
					return false
				end

				u487 = GetTeslaCoilFromPlayerPlot()

				local v491

				if _Parent6:FindFirstChildOfClass('Humanoid') then
					v491 = _Players:GetPlayerFromCharacter(_Parent6)
				else
					v491 = nil
				end
				if not (v491 or _Connected2) then
					return true
				end
			end
		end

		local v493 = _Workspace:GetPartBoundsInRadius(v485.Position, 28, COAroundPParams)
		local v494, v495, v496 = pairs(v493)
		local v497 = u487

		while true do
			local v498

			v496, v498 = v494(v495, v496)

			if v496 == nil then
				break
			end
			if v492(v498) then
				local _Parent7 = v498.Parent

				if not table.find(v486, _Parent7) then
					table.insert(v486, _Parent7)
				end
			end
		end

		return v486, v497
	end
end

local u500 = nil

local function u514()
	local v501 = GetPlayerCFrame()
	local v502 = u17
	local v503, v504, v505 = pairs(v502:GetChildren())
	local u506 = nil

	while true do
		local v507, v508 = v503(v504, v505)

		if v507 == nil then
			break
		end

		v505 = v507

		if v508.Name == 'SprayCanWD' and (v508:FindFirstChild('StickyRemoverPart') and v508.PrimaryPart) and Getdistancefromcharacter(v508.PrimaryPart.Position) < 30 then
			if v508.StickyRemoverPart:FindFirstChildOfClass('TouchTransmitter') then
				u506 = v508
			else
				DeleteToyRE:FireServer(v508)
			end
		end
	end

	if not u506 then
		if v501 then
			local v509 = {
				'SprayCanWD',
				CFrame.new(v501.Position.X, v501.Position.Y, v501.Position.Z, -0.133750245, -0.471861839, 0.871468484, -3.7252903e-9, 0.879369617, 0.476139903, -0.991015136, 0.0636838302, -0.117615893),
				Vector3.new(0, 97.69000244140625, 0),
			}

			SpawnToy(v509)
		end

		BuyToy:InvokeServer('SprayCanWD')
	end
	if u506 and not u506:GetAttribute('Connected2') then
		local u511 = u506.DescendantAdded:Connect(function(p510)
			if p510.Name == 'PartOwner' and p510.Value ~= _LocalPlayer.Name then
				u506:SetAttribute('AlreadySetOwnerShip', false)
			end
		end)
		local _Hitbox = u506:FindFirstChild('Hitbox')
		local _StickyRemoverPart = u506:FindFirstChild('StickyRemoverPart')

		task.spawn(function()
			while u506.Parent do
				if not _StickyRemoverPart:FindFirstChildOfClass('TouchTransmitter') then
					DeleteToyRE:FireServer(u506)
				end

				task.wait(5)
			end
		end)
		task.spawn(function()
			while u506.Parent do
				if not u506:GetAttribute('AlreadySetOwnerShip') then
					if SNOWshipOnce(_Hitbox) then
						u506:SetAttribute('AlreadySetOwnerShip', true)
					elseif Getdistancefromcharacter(_Hitbox.Position) > 30 then
						DeleteToyRE:FireServer(u506)
					end
				end

				task.wait(0.1)
			end

			u500 = nil

			u511:Disconnect()
		end)
		u506:SetAttribute('Connected2', true)
	end

	u500 = u506
end
local function u515()
	if u500 then
		return u500
	end

	u514()
end
local function u522(p516)
	local u517 = u515()
	local v518 = nil
	local _Character = _LocalPlayer.Character

	if _Character then
		_Character = _Character:FindFirstChild('Head')
	end
	if u517 then
		v518 = u517.PrimaryPart
	end
	if u517 and _Character and v518 then
		local _StickyRemoverPart2 = u517:FindFirstChild('StickyRemoverPart')

		if not v518:FindFirstChild('SprayPosRemove') and u517:GetAttribute('AlreadySetOwnerShip') then
			SetModelProperties(u517)

			local _BodyPosition2 = Instance.new('BodyPosition', v518)

			_BodyPosition2.Name = 'SprayPosRemove'
			_BodyPosition2.MaxForce = Vector3.new(math.huge, math.huge, math.huge)

			Vector3.new(-453, math.random(50, 100), 1081)
			task.spawn(function()
				while u517.Parent do
					_BodyPosition2.Position = _Character.Position + Vector3.new(10, 500, 0)

					task.wait()
				end
			end)
		end
		if _StickyRemoverPart2 and u517:GetAttribute('AlreadySetOwnerShip') then
			_StickyRemoverPart2.Position = p516.Position

			task.wait()

			_StickyRemoverPart2.Position = v518.Position
		end
	end
end

KunaiFound = nil

function CheckIfKunaiIsOnPlayer(p523)
	if typeof(p523) == 'Instance' and (p523:IsA('Model') and p523.Parent) then
		local _StickyPart = p523:FindFirstChild('StickyPart')
		local v525 = GetPlayerCharacter()
		local v526 = _StickyPart and _StickyPart:FindFirstChild('StickyWeld')

		if v526 then
			local _Part16 = v526.Part1

			return v526.Enabled ~= false and (_Part16 and (_Part16:IsDescendantOf(v525) and 'Using' or 'Used') or 'No use!') or 'Useless'
		end
	end
end
function CheckIfPlayerIsHoldingFood(p528)
	if typeof(p528) == 'Instance' and (p528:IsA('Model') and p528.Parent) then
		local _HoldPart = p528:FindFirstChild('HoldPart')
		local v530 = GetPlayerCharacter()
		local v531 = _HoldPart and _HoldPart:FindFirstChild('RigidConstraint')

		if v531 then
			local _Attachment1 = v531.Attachment1

			return v531.Enabled ~= false and (_Attachment1 and (_Attachment1:IsDescendantOf(v530) and 'Using' or 'Used') or 'No use!') or 'Useless'
		end
	end
end
function CheckKunai()
	if not KunaiFound then
		local v533 = GetPlayerCFrame()
		local v534 = u17
		local v535, v536, v537 = pairs(v534:GetChildren())
		local u538 = nil

		while true do
			local v539, v540 = v535(v536, v537)

			if v539 == nil then
				break
			end

			v537 = v539

			if v540.Name == 'NinjaKunai' and (v540.PrimaryPart and v540.Parent) then
				if CheckIfKunaiIsOnPlayer(v540) ~= 'No use!' or 30 >= Getdistancefromcharacter(v540.PrimaryPart.Position) then
					if CheckIfKunaiIsOnPlayer(v540) ~= 'Useless' then
						u538 = v540
					else
						DeleteToyRE:FireServer(v540)
					end
				else
					DeleteToyRE:FireServer(v540)
					print('Destroy1')
				end
			end
		end

		if not u538 then
			if v533 then
				local v541 = {
					'NinjaKunai',
					CFrame.new(v533.Position.X, v533.Position.Y, v533.Position.Z, -0.133750245, -0.471861839, 0.871468484, -3.7252903e-9, 0.879369617, 0.476139903, -0.991015136, 0.0636838302, -0.117615893),
					Vector3.new(0, 97.69000244140625, 0),
				}

				SpawnToy(v541)
			end

			BuyToy:InvokeServer('NinjaKunai')
		end
		if u538 and not u538:GetAttribute('Connected2') and u538:FindFirstChild('StickyPart') and (u538.StickyPart:FindFirstChild('StickyWeld') and u538.Parent) then
			local _StickyPart2 = u538.StickyPart
			local _ = _StickyPart2.StickyWeld
			local u543 = SetKunaiToyAntiKick(u538)
			local u544 = {
				_StickyPart2,
				_LocalPlayer.Character:FindFirstChild('Left Leg'),
				CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
			}
			local u546 = u538.DescendantAdded:Connect(function(p545)
				if p545.Name == 'PartOwner' and p545.Value ~= _LocalPlayer.Name then
					u538:SetAttribute('AlreadySetOwnerShip', false)
				end
			end)

			task.spawn(function()
				while u538.Parent do
					if CheckIfKunaiIsOnPlayer(u538) == 'Useless' then
						DeleteToyRE:FireServer(u538)
					end
					if CheckIfKunaiIsOnPlayer(u538) ~= 'Used' then
						if CheckIfKunaiIsOnPlayer(u538) == 'No use!' then
							if Getdistancefromcharacter(_StickyPart2.Position) >= 30 then
								DeleteToyRE:FireServer(u538)
							elseif SNOWshipOnce(_StickyPart2) then
								_ReplicatedStorage:WaitForChild('PlayerEvents'):WaitForChild('StickyPartEvent'):FireServer(unpack(u544))
							end
						end
					elseif Getdistancefromcharacter(_StickyPart2.Position) >= 30 then
						DeleteToyRE:FireServer(u538)
					else
						SNOWship(_StickyPart2)
					end

					task.wait()
				end

				print('Pew!')
			end)
			task.spawn(function()
				while u538.Parent do
					if not u538:GetAttribute('AlreadySetOwnerShip') then
						if SNOWshipOnce(_StickyPart2) then
							if CheckIfKunaiIsOnPlayer(u538) ~= 'Using' then
								_ReplicatedStorage:WaitForChild('PlayerEvents'):WaitForChild('StickyPartEvent'):FireServer(unpack(u544))

								if not _G.FirstFloppaMessage then
									u543("Don't worry my buddy, you won't get kicked", 3)

									_G.FirstFloppaMessage = true
								end
							else
								u538:SetAttribute('AlreadySetOwnerShip', true)
							end
						elseif Getdistancefromcharacter(_StickyPart2.Position) > 30 then
							DeleteToyRE:FireServer(u538)
						end
					end

					task.wait()
				end

				_StickyPart2 = nil
				KunaiFound = nil
				ShurikenEquipped = false

				u546:Disconnect()
				print('Pew!')
			end)
			u538:SetAttribute('Connected2', true)
		end

		KunaiFound = u538
	end
end
function GetKunai()
	if not KunaiFound then
		CheckKunai()
	end
end

local u547 = nil
local u548 = nil

local function u552(p549)
	if p549 then
		local _EdiblePart = p549:FindFirstChild('EdiblePart')
		local _HoldPart2 = p549:FindFirstChild('HoldPart')

		if _HoldPart2 then
			_HoldPart2 = _HoldPart2.RigidConstraint.Attachment1
		end
		if not (_EdiblePart or _HoldPart2) then
			return true
		end
	end
end
local function u570()
	local v553 = GetPlayerCFrame()
	local v554 = u17
	local v555, v556, v557 = pairs(v554:GetChildren())
	local u558 = nil

	while true do
		local v559

		v557, v559 = v555(v556, v557)

		if v557 == nil then
			break
		end
		if v559.Name == 'FoodBanana' and v559:GetAttribute('RagdollToy') then
			if u552(v559) then
				u558 = v559
			end
		end
	end

	if not u558 then
		local _FoodBanana = u17:FindFirstChild('FoodBanana')

		if _FoodBanana then
			if u552(_FoodBanana) then
				_FoodBanana:SetAttribute('RagdollToy', true)
			else
				local _EdiblePart2 = _FoodBanana:FindFirstChild('EdiblePart')
				local _HoldPart3 = _FoodBanana.HoldPart
				local _RigidConstraint = _HoldPart3.RigidConstraint

				if _EdiblePart2 and not _RigidConstraint.Attachment1 then
					local v564 = {
						_FoodBanana,
						_LocalPlayer.Character,
					}

					_HoldPart3.HoldItemRemoteFunction:InvokeServer(unpack(v564))
				elseif _EdiblePart2 and _RigidConstraint.Attachment1 and (_RigidConstraint.Attachment1:IsDescendantOf(_LocalPlayer.Character) and not _HoldPart3.EatingSound.IsPlaying) then
					_ReplicatedStorage.HoldEvents.Use:FireServer(_FoodBanana)
					task.wait(0.5)
				elseif not _EdiblePart2 and _RigidConstraint.Attachment1 and _RigidConstraint.Attachment1:IsDescendantOf(_LocalPlayer.Character) then
					local v565 = {
						_FoodBanana,
						CFrame.new(v553.Position.X, v553.Position.Y, v553.Position.Z, -0.133750245, -0.471861839, 0.871468484, -3.7252903e-9, 0.879369617, 0.476139903, -0.991015136, 0.0636838302, -0.117615893),
						Vector3.new(0, 97.69000244140625, 0),
					}

					_HoldPart3.DropItemRemoteFunction:InvokeServer(unpack(v565))
				end
			end
		else
			local v566 = {
				'FoodBanana',
				CFrame.new(508.073517, 67.2614441, -261.901917, -0.133750245, -0.471861839, 0.871468484, -3.7252903e-9, 0.879369617, 0.476139903, -0.991015136, 0.0636838302, -0.117615893),
				Vector3.new(0, 97.69000244140625, 0),
			}

			SpawnToy(v566)
			BuyToy:InvokeServer('FoodBanana')
		end
	end
	if u558 and u558:FindFirstChild('HoldPart') and (u558.HoldPart:FindFirstChild('RigidConstraint') and not u558:GetAttribute('Connected2')) then
		local u568 = u558.DescendantAdded:Connect(function(p567)
			if p567.Name == 'PartOwner' and p567.Value ~= _LocalPlayer.Name then
				u558:SetAttribute('AlreadySetOwnerShip', nil)
			end
		end)
		local _HitboxPart = u558:FindFirstChild('HitboxPart')

		task.spawn(function()
			while u558.Parent do
				if not u558:GetAttribute('AlreadySetOwnerShip') then
					if SNOWshipOnce(_HitboxPart) then
						for _ = 1, 15 do
							_DestroyGrabLine:FireServer(_HitboxPart)
							task.wait()
						end

						u558:SetAttribute('AlreadySetOwnerShip', true)
					elseif Getdistancefromcharacter(_HitboxPart.Position) > 30 then
						DeleteToyRE:FireServer(u558)
					end
				end

				task.wait(0.1)
			end

			u568:Disconnect()

			u547 = nil
			u548 = nil
			_HitboxPart = nil
		end)
		u558:SetAttribute('Connected2', true)
	end

	u547 = u558
end
local function u571()
	if u547 and u547.Parent ~= nil then
		return u547
	end

	u570()
end
local function u582(p572)
	local u573 = u571()
	local v574 = nil
	local _Character2 = _LocalPlayer.Character

	if _Character2 then
		_Character2 = _Character2:FindFirstChild('Head')
	end
	if u573 then
		v574 = u573.PrimaryPart
	end
	if u573 and _Character2 and v574 then
		if not u548 then
			local v576, v577, v578 = pairs(u573:GetChildren())

			while true do
				local v579

				v578, v579 = v576(v577, v578)

				if v578 == nil then
					break
				end
				if v579.Name == 'BananaPeel' and v579:FindFirstChildOfClass('TouchTransmitter') then
					u548 = v579
				end
			end

			print('Done!')
		end

		local v580 = u548

		v580.Size = Vector3.new(2, 2, 2)
		v580.Transparency = 1

		if not v574:FindFirstChild('FoodBananaPosRemove') and u573:GetAttribute('AlreadySetOwnerShip') then
			SetModelProperties(u573)

			local _BodyPosition3 = Instance.new('BodyPosition', u573.PrimaryPart)

			_BodyPosition3.Name = 'FoodBananaPosRemove'
			_BodyPosition3.MaxForce = Vector3.new(12500, 12500, 12500)

			task.spawn(function()
				while u573.Parent do
					_BodyPosition3.Position = _Character2.Position + Vector3.new(0, 500, 0)

					task.wait()
				end
			end)
		end
		if v580 and p572 and u573:GetAttribute('AlreadySetOwnerShip') then
			v580.Position = p572.Position

			task.wait()

			v580.Position = v574.Position
		end
	end
end

local u583 = nil

holdfirePartFound = nil

function checkHoldFirePart()
	local v584 = u17
	local v585, v586, v587 = pairs(v584:GetChildren())
	local v588 = nil

	while true do
		local v589

		v587, v589 = v585(v586, v587)

		if v587 == nil then
			break
		end
		if v589.Name == 'Campfire' and not v589:GetAttribute('FirePlayerPart') then
			if v589.FirePlayerPart.CanBurn.Value then
				v588 = v589
			end
		end
	end

	if not v588 then
		local v590 = {
			'Campfire',
			CFrame.new(508.073517, 67.2614441, -261.901917, -0.133750245, -0.471861839, 0.871468484, -3.7252903e-9, 0.879369617, 0.476139903, -0.991015136, 0.0636838302, -0.117615893),
			Vector3.new(0, 97.69000244140625, 0),
		}

		SpawnToy(v590)
		BuyToy:InvokeServer('Campfire')
	end

	holdfirePartFound = v588
end

local function u591()
	if holdfirePartFound and holdfirePartFound.Parent ~= nil then
		return holdfirePartFound
	end

	checkHoldFirePart()
end
local function u604()
	local v592 = GetPlayerCFrame()
	local v593 = u17
	local v594, v595, v596 = pairs(v593:GetChildren())
	local u597 = nil
	local u598 = nil

	while true do
		local v599

		v596, v599 = v594(v595, v596)

		if v596 == nil then
			break
		end
		if v599.Name == 'Campfire' and v599.PrimaryPart then
			if Getdistancefromcharacter(v599.PrimaryPart.Position) < 30 and v599.FirePlayerPart.CanBurn.Value then
				u597 = v599
			end
		end
	end

	if not u597 then
		if v592 then
			local v600 = {
				'Campfire',
				CFrame.new(v592.Position.X, v592.Position.Y, v592.Position.Z, -0.133750245, -0.471861839, 0.871468484, -3.7252903e-9, 0.879369617, 0.476139903, -0.991015136, 0.0636838302, -0.117615893),
				Vector3.new(0, 97.69000244140625, 0),
			}

			SpawnToy(v600)
		end

		BuyToy:InvokeServer('Campfire')
	end
	if u597 and u597:FindFirstChild('FirePlayerPart') and (u597.FirePlayerPart:FindFirstChild('CanBurn') and not u597:GetAttribute('Connected2')) then
		local u602 = u597.DescendantAdded:Connect(function(p601)
			if p601.Name == 'PartOwner' and p601.Value ~= _LocalPlayer.Name then
				u597:SetAttribute('AlreadySetOwnerShip', false)
			end
		end)

		task.spawn(function()
			lastpos = GetPlayerCFrame()
			u598 = u597.FirePlayerPart

			while u597.Parent do
				local v603 = not u597.FirePlayerPart.CanBurn.Value and u591()

				if v603 then
					u598.Position = v603.FirePlayerPart.Position
				end
				if not u597:GetAttribute('AlreadySetOwnerShip') then
					if SNOWshipOnce(u598) then
						u597:SetAttribute('AlreadySetOwnerShip', true)
					elseif Getdistancefromcharacter(u598.Position) > 30 then
						DeleteToyRE:FireServer(u597)
					end
				end

				task.wait(0.1)
			end

			u602:Disconnect()
			print('Pew!')
		end)
		u597:SetAttribute('Connected2', true)
	end

	u583 = u597
end
local function u605()
	if u583 and u583.Parent ~= nil then
		return u583
	end

	u604()
end
local function u613(p606)
	local u607 = u605()
	local v608 = nil
	local _Character3 = _LocalPlayer.Character

	if _Character3 then
		_Character3 = _Character3:FindFirstChild('Head')
	end
	if u607 then
		v608 = u607.PrimaryPart
	end
	if u607 and _Character3 and v608 then
		local _FirePlayerPart2 = u607:FindFirstChild('FirePlayerPart')
		local _CampfirePosRemove = v608:FindFirstChild('CampfirePosRemove')

		_FirePlayerPart2.Size = Vector3.new(2, 2, 2)

		if not _CampfirePosRemove and u607:GetAttribute('AlreadySetOwnerShip') then
			SetModelProperties(u607)

			local _BodyPosition4 = Instance.new('BodyPosition', u607.PrimaryPart)

			_BodyPosition4.Name = 'CampfirePosRemove'
			_BodyPosition4.MaxForce = Vector3.new(12500, 12500, 12500)

			Vector3.new(-453, math.random(50, 100), 1081)
			task.spawn(function()
				while u607.Parent do
					_BodyPosition4.Position = _Character3.Position + Vector3.new(5, 500, 0)

					task.wait()
				end
			end)
		end
		if _FirePlayerPart2 and p606 and (u607:GetAttribute('AlreadySetOwnerShip') and v608) then
			_FirePlayerPart2.Position = p606.Position

			task.wait()

			_FirePlayerPart2.Position = v608.Position
		end
	end
end

smalldiceToyFound = nil

function CheckFakeAim()
	local v614 = GetPlayerCFrame()
	local v615 = u17
	local v616, v617, v618 = pairs(v615:GetChildren())
	local u619 = nil

	while true do
		local v620

		v618, v620 = v616(v617, v618)

		if v618 == nil then
			break
		end
		if v620.Name == 'DiceSmall' and v620:FindFirstChild('Center') then
			if v620.PrimaryPart and Getdistancefromcharacter(v620.PrimaryPart.Position) < 30 then
				u619 = v620
			end
		end
	end

	if not u619 then
		if v614 then
			local v621 = {
				'DiceSmall',
				CFrame.new(v614.Position.X, v614.Position.Y, v614.Position.Z, -0.133750245, -0.471861839, 0.871468484, -3.7252903e-9, 0.879369617, 0.476139903, -0.991015136, 0.0636838302, -0.117615893),
				Vector3.new(0, 97.69000244140625, 0),
			}

			SpawnToy(v621)
		end

		BuyToy:InvokeServer('DiceSmall')
	end
	if u619 and u619:FindFirstChild('Center') and not u619:GetAttribute('Connected2') then
		local u623 = u619.DescendantAdded:Connect(function(p622)
			if p622.Name == 'PartOwner' and p622.Value ~= _LocalPlayer.Name then
				u619:SetAttribute('AlreadySetOwnerShip', false)
			end
		end)
		local _SoundPart = u619:FindFirstChild('SoundPart')

		task.spawn(function()
			while u619.Parent do
				if not u619:GetAttribute('AlreadySetOwnerShip') then
					if SNOWshipOnce(_SoundPart) then
						u619:SetAttribute('AlreadySetOwnerShip', true)
					elseif Getdistancefromcharacter(_SoundPart.Position) > 30 then
						DeleteToyRE:FireServer(u619)
					end
				end
				if not _G.FireworkEffectSpam then
					DeleteToyRE:FireServer(u619)
				end

				task.wait(0.1)
			end

			_SoundPart = nil
			smalldiceToyFound = nil
			u619 = nil

			u623:Disconnect()
			print('Pew!')
		end)
		u619:SetAttribute('Connected2', true)
	end

	smalldiceToyFound = u619
end
function GetFakeAim()
	if smalldiceToyFound and smalldiceToyFound.Parent ~= nil then
		return smalldiceToyFound
	end

	CheckFakeAim()
end
function GetFakeAim2()
	local u625 = GetFakeAim()
	local _Character4 = _LocalPlayer.Character
	local v627

	if u625 then
		v627 = u625.PrimaryPart
	else
		v627 = nil
	end
	if u625 and _Character4 and v627 then
		hitpart = u625:FindFirstChild('StickyRemoverPart')

		if not v627:FindFirstChild('AimPosRemove') and u625:GetAttribute('AlreadySetOwnerShip') then
			SetAimPart(u625)

			local _BodyPosition5 = Instance.new('BodyPosition', v627)

			_BodyPosition5.Name = 'AimPosRemove'
			_BodyPosition5.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
			_BodyPosition5.P = 40000
			_BodyPosition5.D = 950

			local u629 = nil
			local u630 = nil
			local u631 = nil

			task.spawn(function()
				while u625.Parent do
					if _LocalPlayer.Character and _LocalPlayer.Character:FindFirstChild('CamPart') then
						u629 = Ray.new(_LocalPlayer.Character.CamPart.Position, _LocalPlayer.Character.CamPart.CFrame.lookVector * 5000)

						local v632, v633 = _Workspace:FindPartOnRayWithIgnoreList(u629, {
							_LocalPlayer.Character,
							u17,
						})

						u631 = v633
						u630 = v632

						if u630 and u631 then
							_BodyPosition5.Position = u631
						end
					end

					task.wait()
				end
			end)
		end

		return v627
	end
end

local u634 = nil

local function u643()
	local v635 = GetPlayerCharacter()
	local v636 = u17
	local v637, v638, v639 = pairs(v636:GetChildren())
	local v640 = nil

	while true do
		local v641

		v639, v641 = v637(v638, v639)

		if v639 == nil then
			break
		end
		if v641.Name == 'CreatureBlobman' then
			v640 = v641
		end
	end

	if not v640 then
		if u17:FindFirstChild('CreatureBlobman') then
			v640 = u17.CreatureBlobman
		else
			local v642 = {
				'CreatureBlobman',
				CFrame.new(v635.Head.Position),
				Vector3.new(0, 97.69000244140625, 0),
			}

			SpawnToy(v642)
			BuyToy:InvokeServer('CreatureBlobman')
		end
	end

	u634 = v640
end
local function u644()
	if u634 and u634.Parent then
		return u634
	end

	u643()
end

local v645 = u3
local v646 = u3.MakeWindow(v645, {
	Name = 'Fling Things and People',
	HidePremium = true,
	SaveConfig = true,
	ConfigFolder = 'FTAPConfig',
	IntroEnabled = false,
	KeyToOpenWindow = 'M',
	FreeMouse = true,
})
local v647 = v646:MakeTab({
	Name = 'Combat',
	Icon = 'rbxassetid://7485051715',
	PremiumOnly = false,
})

LongReachGrab_Player = v646:MakeTab({
	Name = 'Blobman Grab',
	Icon = 'rbxassetid://7734058599',
	PremiumOnly = false,
})

local v648 = v646:MakeTab({
	Name = 'Invincibility',
	Icon = 'rbxassetid://7734056608',
	PremiumOnly = false,
})
local v649 = v646:MakeTab({
	Name = 'Player',
	Icon = 'rbxassetid://7743871002',
	PremiumOnly = false,
})

Esp_Tab = v646:MakeTab({
	Name = 'ESP',
	Icon = 'rbxassetid://7733774602',
	PremiumOnly = false,
})

local v650 = v646:MakeTab({
	Name = 'Explosions',
	Icon = 'rbxassetid://17837704089',
	PremiumOnly = false,
})
local v651 = v646:MakeTab({
	Name = 'Teleport',
	Icon = 'rbxassetid://7733992829',
	PremiumOnly = false,
})
local v652 = v646:MakeTab({
	Name = 'Custom Line',
	Icon = 'rbxassetid://7734022107',
	PremiumOnly = false,
})
local v653 = v646:MakeTab({
	Name = 'Grab Auras',
	Icon = 'rbxassetid://7733955740',
	PremiumOnly = false,
})
local v654 = v646:MakeTab({
	Name = 'Keybinds',
	Icon = 'rbxassetid://11710306232',
	PremiumOnly = false,
})
local v655 = v646:MakeTab({
	Name = 'Loop Players',
	Icon = 'rbxassetid://7733964640',
	PremiumOnly = false,
})
local v656 = v646:MakeTab({
	Name = 'Auto',
	Icon = 'rbxassetid://7733916988',
	PremiumOnly = false,
})
local v657 = v646:MakeTab({
	Name = 'Misc',
	Icon = 'rbxassetid://7733917120',
	PremiumOnly = false,
})
local u658 = v646:MakeTab({
	Name = 'Discord Server',
	Icon = 'rbxassetid://7733960981',
	PremiumOnly = false,
})
local v659 = v646:MakeTab({
	Name = 'Config',
	Icon = 'rbxassetid://7734053495',
	PremiumOnly = false,
})

local PremiumInfo_Tab = v646:MakeTab({
	Name = 'Premium Info',
	Icon = 'rbxassetid://7734053495',
	PremiumOnly = false,
})

local v660 = v646:MakeTab({
	Name = 'Credits',
	Icon = 'rbxassetid://7733687281',
	PremiumOnly = false,
})
local u661 = nil

task.spawn(function()
	local v664 = u658:AddSection({
		Name = 'Discord Server',
	})
	local discordProfile = 'https://discord.com/users/1545842149382422632/profile/'
	local discordInvite = 'https://discord.gg/25ms'
	v664:AddLabel('Discord Profile')
	v664:AddLabel(discordProfile)
	v664:AddButton({
		Name = 'Open Discord Profile',
		Callback = function()
			local opened = false
			for _, openerName in ipairs({'openurl', 'open_url', 'OpenURL'}) do
				local opener = getgenv and getgenv()[openerName] or nil
				if type(opener) == 'function' then
					local ok = pcall(opener, discordProfile)
					if ok then opened = true; break end
				end
			end
			if not opened then
				if type(setclipboard) == 'function' then
					pcall(setclipboard, discordProfile)
					u33('GOY FREE\nDiscord profile link copied. Paste it in your browser or Discord.')
				else
					u33(discordProfile)
				end
			end
		end,
	})
	v664:AddButton({
		Name = 'Copy Discord Server Link',
		Callback = function()
			if type(setclipboard) == 'function' then
				setclipboard(discordInvite)
				u33('Discord server invite copied')
			else
				u33(discordInvite)
			end
		end,
	})
	v664:AddLabel('Join my discord server to see updates!')
end)

local v665 = v660:AddSection({
	Name = '1# Medal credits',
})
local v666 = v660:AddSection({
	Name = '2# Medal credits',
})
local v667 = v660:AddSection({
	Name = '3# Medal credits',
})
local _UserService = game:GetService('UserService')
local u669 = {
	90063030,
	2298910483,
	1030559478,
	1762306425,
	542649826,
	237152138,
	1390422876,
	3089724826,
	882860613,
	7280113503,
	3485279105,
}
local v670 = {}
local v671, v672 = pcall(function()
	return _UserService:GetUserInfosByUserIdsAsync(u669)
end)

if v671 and v672 then
	local v673, v674, v675 = pairs(u669)
	local v676 = u669

	while true do
		local v677

		v675, v677 = v673(v674, v675)

		if v675 == nil then
			break
		end

		local v678, v679, v680 = pairs(v672)

		while true do
			local v681

			v680, v681 = v678(v679, v680)

			if v680 == nil then
				break
			end
			if v681.Id == v677 then
				table.insert(v670, v681)
			end
		end
	end

	local v682, v683, v684 = pairs(v676)
	local v685 = v670

	while true do
		local v686, _ = v682(v683, v684)

		if v686 == nil then
			break
		end

		v684 = v686

		if not v670[v686] then
			v685[v686] = {
				DisplayName = 'deleted',
				Username = 'deleted',
			}
		end
	end

	v665:AddParagraph(v670[1].DisplayName .. ' (' .. v670[1].Username .. ')', 'I made the whole GUI (Combat, Player, Auras and more) XD!')
	v665:AddParagraph(v670[2].DisplayName .. ' (' .. v670[2].Username .. ')', 'Thanks for giving me inspiration to create the blobman functions, Massless Grab and Line color changer script!')
	v665:AddParagraph(v670[3].DisplayName .. ' (' .. v670[3].Username .. ') ' .. 'and ' .. v670[6].DisplayName .. ' (' .. v670[6].Username .. ')', 'Thanks for sharing the Attraction Aura, Silent Aim, Further Extend scripts for me!')
	v665:AddParagraph(v670[7].DisplayName .. ' (' .. v670[7].Username .. ')', 'Thanks for helping me to fix kick stuff and my anti-blobman')
	v665:AddParagraph(v670[8].DisplayName .. ' (' .. v670[8].Username .. ')', 'Thanks for explosion stuff, fireproximityprompt fix and script updater')
	v665:AddParagraph(v670[9].DisplayName .. ' (' .. v670[9].Username .. ')', 'Thanks for laggy stuff!')
	v665:AddParagraph(v670[10].DisplayName .. ' (' .. v670[10].Username .. ')', 'Thanks for Anchor Objects Glue/Compile')
	v665:AddParagraph(v670[11].DisplayName .. ' (' .. v670[11].Username .. ')', 'Thanks for Tornado Shape')
	v666:AddParagraph(v670[4].DisplayName .. ' (' .. v670[4].Username .. ')', 'Thanks for releasing my script!')
	v667:AddParagraph(v670[5].DisplayName .. ' (' .. v670[5].Username .. ')', 'Thanks for testing my scripts')
end

PerspectiveEffect = Instance.new('ScreenGui')
ImageLabel = Instance.new('ImageLabel')
PerspectiveSaturation = Instance.new('ColorCorrectionEffect', _Lighting)
PerspectiveEffect.Name = 'PerspectiveEffect'
PerspectiveEffect.DisplayOrder = -5
PerspectiveEffect.Enabled = true
PerspectiveEffect.IgnoreGuiInset = true
PerspectiveEffect.ResetOnSpawn = false
PerspectiveEffect.Parent = _LocalPlayer.PlayerGui
ImageLabel.Parent = PerspectiveEffect
ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ImageLabel.BackgroundTransparency = 1
ImageLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
ImageLabel.BorderSizePixel = 0
ImageLabel.Size = UDim2.new(1, 0, 1, 0)
ImageLabel.Image = 'rbxassetid://8586979842'
ImageLabel.ImageTransparency = 1
PerspectiveSaturation.Enabled = true
PerspectiveSaturation.Saturation = 0
imagestransparencyeffect = 0.65
saturationvalue = -0.3
t1p = TweenInfo.new(0.6, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0)
t2p = TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0)

local v687 = _TweenService

perspectiveON_effect1 = _TweenService.Create(v687, ImageLabel, t1p, {ImageTransparency = imagestransparencyeffect})

local v688 = _TweenService

perspectiveON_effect2 = _TweenService.Create(v688, PerspectiveSaturation, t1p, {Saturation = saturationvalue})

local v689 = _TweenService

perspectiveOff_effect1 = _TweenService.Create(v689, ImageLabel, t2p, {ImageTransparency = 1})

local v690 = _TweenService

perspectiveOff_effect2 = _TweenService.Create(v690, PerspectiveSaturation, t2p, {Saturation = 0})

function PerspectiveOnEffect()
	perspectiveON_effect1:Play()
	perspectiveON_effect2:Play()
end
function PerspectiveOffEffect()
	perspectiveOff_effect1:Play()
	perspectiveOff_effect2:Play()
end

local function u692(p691)
	if p691 and _G.PerspectiveEffectsAllow then
		PerspectiveOnEffect()
	else
		PerspectiveOffEffect()
	end
end

gui = Instance.new('ScreenGui')
gui.ResetOnSpawn = false
CAG = _LocalPlayer.PlayerGui:FindFirstChild('ContextActionGui')

function IsMobile()
	if _LocalPlayer.PlayerGui:FindFirstChild('ContextActionGui') then
		return true
	end
end

if IsMobile() then
	gui.Parent = _LocalPlayer.PlayerGui
end

scriptToGetSenv = nil
senv = nil
minDistance = 3
pcDistance = 0
imageButton = Instance.new('ImageButton')
imageButton.Size = UDim2.new(0, 45, 0, 45)
imageButton.Position = UDim2.new(1, -70, 1, -259)
imageButton.Image = 'rbxassetid://97166444'
imageButton.BackgroundTransparency = 1
imageButton.ImageTransparency = 0.2
imageButton.Visible = false
imageButton.ImageColor3 = Color3.fromRGB(142, 142, 142)
imageButton.Parent = gui
imageLabel = Instance.new('ImageLabel')
imageLabel.Size = UDim2.new(1, 0, 1, 0)
imageLabel.Image = 'rbxassetid://9603831913'
imageLabel.BackgroundTransparency = 1
imageLabel.Parent = imageButton
imageButtonDe = Instance.new('ImageButton')
imageButtonDe.Size = UDim2.new(0, 45, 0, 45)
imageButtonDe.Position = UDim2.new(1, -70, 1, -211)
imageButtonDe.Image = 'rbxassetid://97166444'
imageButtonDe.BackgroundTransparency = 1
imageButtonDe.ImageTransparency = 0.2
imageButtonDe.Visible = false
imageButtonDe.ImageColor3 = Color3.fromRGB(142, 142, 142)
imageButtonDe.Parent = gui
imageLabelDe = Instance.new('ImageLabel')
imageLabelDe.Size = UDim2.new(1, 0, 1, 0)
imageLabelDe.Image = 'rbxassetid://9603826756'
imageLabelDe.BackgroundTransparency = 1
imageLabelDe.Parent = imageButtonDe
IncreaseLineExtend = 0

function buttonClicked()
	if senv and (senv.distance and _G.FutherExtend) then
		senv.distance = (senv.distance or 0) + IncreaseLineExtend

		if senv.distance < minDistance then
			senv.distance = minDistance
		end
	end
end
function buttonClickedDE()
	if senv and (senv.distance and _G.FutherExtend) then
		senv.distance = (senv.distance or 0) - IncreaseLineExtend

		if senv.distance < minDistance then
			senv.distance = minDistance
		end
	end
end
function toggleButtonState(p693)
	if p693 and _G.FutherExtend then
		imageButton.Visible = true
		imageButton.Active = true
		imageButtonDe.Visible = true
		imageButtonDe.Active = true
	else
		imageButton.Visible = false
		imageButton.Active = false
		imageButtonDe.Visible = false
		imageButtonDe.Active = false
	end
end
function toggleDefaultExtendButtons(p694)
	if CAG then
		local v695, v696, v697 = pairs(CAG:GetDescendants())

		while true do
			local v698

			v697, v698 = v695(v696, v697)

			if v697 == nil then
				break
			end
			if v698:IsA('ImageLabel') and (v698.Image == 'rbxassetid://9603826756' or v698.Image == 'rbxassetid://9603831913') then
				v698.Parent.Visible = p694
			end
		end
	end
end

_Workspace.ChildAdded:Connect(function(p699)
	if p699.Name == 'GrabParts' and (p699:IsA('Model') and not IsHoldingAdminPlayer()) then
		if _G.FutherExtend and _UserInputService.MouseEnabled and not IsMobile() then
			local u700 = p699

			GetPlayerCharacter()

			local v701 = u700

			u700.WaitForChild(v701, 'GrabPart')

			local v702 = u700

			u700.WaitForChild(v702, 'DragPart')

			local u703 = u700.DragPart:Clone()

			u703.Name = 'DragPart1'
			u703.AlignPosition.Attachment1 = u703.DragAttach
			u703.Parent = u700
			pcDistance = (u703.Position - _Workspace.CurrentCamera.CFrame.Position).Magnitude
			u703.AlignOrientation.Enabled = false
			u700.DragPart.AlignPosition.Enabled = false

			task.spawn(function()
				while u700.Parent do
					u703.Position = _Workspace.Camera.CFrame.Position + _Workspace.Camera.CFrame.LookVector * pcDistance

					task.wait()
				end

				pcDistance = 0
			end)
		end
		if _G.FutherExtend and IsMobile() then
			toggleDefaultExtendButtons(false)
			toggleButtonState(true)
		end
	end
end)

local u704 = nil

workspace.ChildRemoved:Connect(function(p705)
	if p705.Name == 'GrabParts' and p705:IsA('Model') then
		toggleButtonState(false)
		toggleDefaultExtendButtons(true)

		_G.HoldingObjectGrabPart = nil

		local v706 = WhatIsHolding(p705)
		local _Part17 = p705.GrabPart.WeldConstraint.Part1
		local v708

		if _Part17.Parent and _Part17.Parent:IsA('Model') then
			v708 = _Part17.Parent:GetAttribute('IsAnchored')
		else
			v708 = nil
		end

		_DestroyGrabLine.Parent = _ReplicatedStorage.GrabEvents

		if u704 then
			task.cancel(u704)
		end
		if v706 == 'Player' or v706 == 'Follow NPC' then
			p705:GetAttribute('IsAnchored')

			if _G.TornadoAura and _G.TornadoMode == 'Click' or v708 then
				_DestroyGrabLine.Parent = nil
				u704 = task.delay(0.2, function()
					_DestroyGrabLine.Parent = _ReplicatedStorage.GrabEvents
				end)
			end
		end

		_CreateGrabLine:FireServer()
	end
end)

local u709 = false

local function u710()
	while u709 do
		buttonClicked()
		wait(0.1)
	end
end
local function u711()
	while u709 do
		buttonClickedDE()
		wait(0.1)
	end
end

local u712 = _UserInputService

imageButton.InputBegan:Connect(function(p713, p714)
	if not p714 and (u712.TouchEnabled and p713.UserInputType == Enum.UserInputType.Touch) then
		u709 = true

		u710()
	end
end)
imageButton.InputEnded:Connect(function(p715)
	if u712.TouchEnabled and p715.UserInputType == Enum.UserInputType.Touch then
		u709 = false
	end
end)
imageButtonDe.InputBegan:Connect(function(p716, p717)
	if not p717 and (u712.TouchEnabled and p716.UserInputType == Enum.UserInputType.Touch) then
		u709 = true

		u711()
	end
end)
imageButtonDe.InputEnded:Connect(function(p718)
	if u712.TouchEnabled and p718.UserInputType == Enum.UserInputType.Touch then
		u709 = false
	end
end)
_UserInputService.InputChanged:Connect(function(p719)
	if p719.UserInputType == Enum.UserInputType.MouseWheel then
		if pcDistance < 11 then
			pcDistance = 11
		end
		if p719.Position.Z <= 0 then
			if p719.Position.Z < 0 then
				pcDistance = pcDistance - IncreaseLineExtend
			end
		else
			pcDistance = pcDistance + IncreaseLineExtend
		end
	end
end)

getgenv().Settings = {
	Fov = 150,
	Hitbox = {
		'Head',
		'Torso',
		'Left Leg',
		'Right Leg',
	},
	FovCircle = false,
}

local u720 = _Players
local u721 = _LocalPlayer
local _CurrentCamera2 = _Workspace.CurrentCamera
local v723 = u721

u721.GetMouse(v723)

local u724 = nil

local function u736(_)
	local _huge = math.huge
	local v726 = u720
	local v727, v728, v729 = pairs(v726:GetPlayers())
	local v730 = nil

	while true do
		local v731

		v729, v731 = v727(v728, v729)

		if v729 == nil then
			break
		end
		if v731.Name ~= u721.Name and v731.Character and (u721 and u721.Character) and u721.Character:FindFirstChild('HumanoidRootPart') then
			local _HumanoidRootPart4 = v731.Character:FindFirstChild('HumanoidRootPart')

			if _HumanoidRootPart4 then
				local _Position2 = u721.Character.HumanoidRootPart.Position
				local _, v734 = _CurrentCamera2:WorldToScreenPoint(_HumanoidRootPart4.Position)

				if v734 then
					local _magnitude = (_Position2 - _HumanoidRootPart4.Position).magnitude

					if _magnitude < _huge then
						v730 = v731
						_huge = _magnitude
					end
				end
			end
		end
	end

	return v730
end

local u737 = nil
local u738 = nil
local u739 = nil
local u740 = nil
local _Circle = Drawing.new('Circle')
local _Circle2 = Drawing.new('Circle')

_RunService.RenderStepped:Connect(function()
	if _Circle then
		_Circle.Radius = getgenv().Settings.Fov
		_Circle.Thickness = 2
		_Circle.Position = Vector2.new(_CurrentCamera2.ViewportSize.X / 2, _CurrentCamera2.ViewportSize.Y / 2 + 36)
		_Circle.Transparency = 1
		_Circle.Filled = false
		_Circle.Color = Color3.fromRGB(255, 255, 255)
		_Circle.Visible = getgenv().Settings.FovCircle
		_Circle.ZIndex = 2
	end
	if _Circle2 then
		_Circle2.Radius = getgenv().Settings.Fov
		_Circle2.Thickness = 4
		_Circle2.Position = Vector2.new(_CurrentCamera2.ViewportSize.X / 2, _CurrentCamera2.ViewportSize.Y / 2 + 36)
		_Circle2.Transparency = 1
		_Circle2.Filled = false
		_Circle2.Color = Color3.new()
		_Circle2.Visible = getgenv().Settings.FovCircle
		_Circle2.ZIndex = 1
	end

	u737 = u736(getgenv().Settings.Fov)
end)

local function u746(p743, p744, p745)
	return (p744 - p743).Unit * p745
end

if hookmetamethod then
	local u747 = nil

	u747 = hookmetamethod(game, '__namecall', function(...)
		local v748 = {...}
		local v749 = v748[1]
		local v750 = getnamecallmethod()

		if v749 == workspace and (not checkcaller() and v750 == 'Raycast') and (u737 and u737.Character and (u737.Character.HumanoidRootPart and u721.Character.HumanoidRootPart)) and (u737.Character.Humanoid and 0 < u737.Character.Humanoid.Health and (not u737.InPlot.Value and _G.SilentAim)) then
			local _magnitude2 = (u721.Character.HumanoidRootPart.Position - u737.Character.HumanoidRootPart.Position).magnitude

			u738 = math.random(1, #getgenv().Settings.Hitbox)
			u739 = getgenv().Settings.Hitbox[u738]
			u740 = u737.Character[u739]

			if _magnitude2 <= u724 and u740 then
				v748[3] = u746(v748[2], u737.Character[u739].Position, 1000)
				v748[4] = RaycastParams.new()
				v748[4].FilterDescendantsInstances = {
					u737.Character,
				}
				v748[4].FilterType = Enum.RaycastFilterType.Include
				u738 = nil
				u739 = nil
				u740 = nil
			end
		end

		return u747(unpack(v748))
	end)
end

local function u757()
	local v752, v753, v754 = pairs(_Workspace.Slots:GetChildren())
	local v755 = nil

	while true do
		local v756

		v754, v756 = v752(v753, v754)

		if v754 == nil then
			break
		end
		if v756.SlotHandle.LightBall.Material ~= Enum.Material.Neon then
			v755 = false

			break
		end

		v755 = true
	end

	return v755
end
local function u760(p758)
	local v759

	if _LocalPlayer.Character and _LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
		v759 = _LocalPlayer.Character.HumanoidRootPart
	else
		v759 = nil
	end
	if p758 == 'Spin' then
		if v759 then
			_G.SavedPositionInSpin = v759.CFrame
		end
	elseif p758 == 'House' and v759 then
		_G.SavedPositionOutHouse = v759.CFrame
	end
end
local function u763(p761)
	local v762

	if _LocalPlayer.Character and _LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
		v762 = _LocalPlayer.Character.HumanoidRootPart
	else
		v762 = nil
	end
	if p761 == 'Spin' then
		if v762 then
			v762.CFrame = _G.SavedPositionInSpin
		end
	elseif p761 == 'House' and v762 then
		v762.CFrame = _G.SavedPositionOutHouse
	end
end

local v764 = v656:AddSection({
	Name = 'Auto Get Coins',
})
local v765 = v656:AddSection({
	Name = 'Auto Time-Reset',
})
local v766 = v656:AddSection({
	Name = 'Auto Claim-Plot',
})

timelefttextlabelingame = _Workspace.Slots.Slots.Screen.SlotGui.TimeLeftFrame.TimeText

v764:AddToggle({
	Name = 'Auto-Spin',
	Default = false,
	Callback = function(p767)
		_G.AutoFarmCoins = p767

		if p767 then
			while _G.AutoFarmCoins do
				if u757() and ChangeActivityPriority(5) then
					u760('Spin')

					local u768 = nil
					local v769 = task.spawn(function()
						while true do
							if u768 then
								TeleportPlayer(u768.CFrame + Vector3.new(0, 5, 0), 5)
								task.wait(0.2)
								SNOWship(u768)
							end

							task.wait()
						end
					end)
					local v770, v771, v772 = pairs(_Workspace.Slots:GetChildren())

					while true do
						local v773

						v772, v773 = v770(v771, v772)

						if v772 == nil then
							break
						end

						u768 = v773.SlotHandle.Handle
						u768.CanCollide = false

						local v774 = u768

						for _ = 1, 5 do
							task.wait(0.2)
						end

						v774.CanCollide = true

						if not u757() then
							break
						end
					end

					task.cancel(v769)

					newtask = nil

					ChangeActivityPriority(0)
					u763('Spin')
				end

				task.wait(5)
			end
		end
	end,
	Save = true,
	Flag = 'autofarmcoins_toggle',
})

TimeRemainingLabel = v764:AddLabel('Time Remaining: 0:00')
CoinsWonLabel = v764:AddLabel('Coins Won: 0')

timelefttextlabelingame.Changed:Connect(function(p775)
	if p775 == 'Text' then
		TimeRemainingLabel:Set('Time Remaining: ' .. timelefttextlabelingame.Text)
	end
end)
task.spawn(function()
	local v776, v777, v778 = pairs(_Workspace.Slots:GetDescendants())

	while true do
		local u779

		v778, u779 = v776(v777, v778)

		if v778 == nil then
			break
		end
		if u779.Name == 'CoinAmount' and tostring(u779.Parent) == 'CoinsFrame' then
			u779.Changed:Connect(function(p780)
				local _PlayerName = u779.Parent.Parent.SpinningFrame.PlayerName

				if p780 == 'Text' and (_PlayerName.Text == _LocalPlayer.DisplayName and CoinsWonLabel) then
					CoinsWonLabel:Set(u779.Text)
				end
			end)
		end
	end

	_Workspace.Plots.DescendantAdded:Connect(function(p782)
		if p782.Name == 'Value' and (tostring(p782.Parent) == 'ThisPlotsOwners' and p782.Value == _LocalPlayer.Name) then
			RTime = p782:WaitForChild('TimeRemainingNum', 1)

			if RTime then
				RTime.Changed:Connect(function(p783)
					TimeInHouseLabel:Set('Time: ' .. p783)
				end)
			end
		end
	end)
end)

local function v789()
	local v784, v785, v786 = pairs(_Workspace.Plots:GetDescendants())

	while true do
		local v787

		v786, v787 = v784(v785, v786)

		if v786 == nil then
			break
		end
		if v787.Name == 'TimeRemainingNum' and v787.Parent.Value == _LocalPlayer.Name then
			_G.RemainingTimeInHouse = v787

			v787.Changed:Connect(function(p788)
				TimeInHouseLabel:Set('Time: ' .. p788)
			end)
		end
	end
end

task.spawn(v789)

local u790 = nil

u790 = v765:AddToggle({
	Name = 'Preserve Time',
	Default = false,
	Callback = function(p791)
		_G.AutoSaveHouseTime = p791

		if p791 then
			while _G.AutoSaveHouseTime do
				if _LocalPlayer.InfiniteHouseTime.Value then
					u790:Set(false)
					u3:MakeNotification({
						Name = 'Stop being greedy!',
						Content = 'You already own infinity house gamepass!',
						Image = 'rbxassetid://4483345998',
						Time = 5,
					})

					break
				end

				local _RemainingTimeInHouse3 = _G.RemainingTimeInHouse

				if typeof(_RemainingTimeInHouse3) == 'Instance' and _RemainingTimeInHouse3:IsDescendantOf(_Workspace) and _RemainingTimeInHouse3:IsA('IntValue') then
					local _PlotArea = _G.RemainingTimeInHouse.Parent.Parent.Parent.Parent:FindFirstChild('PlotArea')

					if _RemainingTimeInHouse3.Value < 20 and ChangeActivityPriority(4) then
						u760('House')
						task.wait()

						repeat
							TeleportPlayer(CFrame.new(_PlotArea.Position), 4)
							task.wait(1)
						until _RemainingTimeInHouse3.Parent ~= nil or (not _G.AutoSaveHouseTime or 15 < _RemainingTimeInHouse3.Value)

						u763('House')
						ChangeActivityPriority(0)
					end
				end

				task.wait(2)
			end
		end
	end,
	Save = true,
	Flag = 'autosavehousetimeremaining_toggle',
})
TimeInHouseLabel = v765:AddLabel('Plot Time: 0')

local _IntValue = Instance.new('IntValue')

PlotWorkspace = _Workspace.Plots:GetDescendants()

function GetPlotModel(_)
	local _Plots = _Workspace.Plots
	local _PlotName = _G.PlotName

	if _PlotName == 'Witch House' then
		_Plots = _Plots:FindFirstChild('Plot3')
	elseif _PlotName == 'Lumber House' then
		_Plots = _Plots:FindFirstChild('Plot2')
	elseif _PlotName == 'Common House' then
		_Plots = _Plots:FindFirstChild('Plot1')
	elseif _PlotName == 'American House' then
		_Plots = _Plots:FindFirstChild('Plot4')
	elseif _PlotName == 'Chinese House' then
		_Plots = _Plots:FindFirstChild('Plot5')
	end

	return _Plots
end
function ClaimPlot()
	local v797 = not IsThereOwnerOnPlot() and GetPlotModel(_G.PlotName)

	if v797 then
		local _PlotSign = v797.PlotSign

		local function v804()
			local v799, v800, v801 = pairs(_PlotSign.ThisPlotsOwners:GetChildren())
			local v802 = false

			while true do
				local v803

				v801, v803 = v799(v800, v801)

				if v801 == nil then
					break
				end
				if v803.Value == _LocalPlayer.Name then
					v802 = true
				end
			end

			return v802
		end

		local v805 = _PlotSign
		local v806, v807, v808 = pairs(_PlotSign.GetChildren(v805))

		while true do
			local v809

			v808, v809 = v806(v807, v808)

			if v808 == nil or v804() then
				break
			end
			if v809.Name == 'Sign' and ChangeActivityPriority(3) then
				local _PlusGrabPart = v809.Plus.PlusGrabPart

				TeleportPlayer(_PlusGrabPart.CFrame * CFrame.new(-5, 0, -5), 3)

				for _ = 0, 15 do
					SNOWship(_PlusGrabPart)
					wait()
				end

				ChangeActivityPriority(0)
			end
		end
	end
end
function UpdatePlotOwner()
	local v811 = PlotWorkspace
	local v812, v813, v814 = pairs(v811)

	while true do
		local v815

		v814, v815 = v812(v813, v814)

		if v814 == nil then
			break
		end
		if v815.Name == 'PlayerRole' then
			local _PlayerDisplayName = v815.Parent.PlayerDisplayName
			local u817 = v815
			local _Parent8 = v815.Parent
			local u819 = nil
			local u820 = false

			local function u826()
				u820 = false
				u819 = GetPlotModel(_G.PlotName)

				if u819 and (u817:IsDescendantOf(u819) and u817.Text == 'Owner' and _Parent8.Visible) then
					wait()

					local v821 = _Players
					local v822, v823, v824 = pairs(v821:GetPlayers())

					while true do
						local v825

						v824, v825 = v822(v823, v824)

						if v824 == nil then
							break
						end
						if v825.DisplayName == _PlayerDisplayName.Text then
							u820 = true
						end
					end

					if PlotOwner and u820 then
						PlotOwner:Set('Plot Owner: ' .. _PlayerDisplayName.Text)
					else
						PlotOwner:Set('Plot Available!')
					end
				end
			end

			u817.Changed:Connect(function(p827)
				if p827 == 'Text' then
					u826()
				end
			end)
			_IntValue.Changed:Connect(function(_)
				u826()
			end)
			u826()
		end
	end
end
function IsThereOwnerOnPlot()
	local v828 = GetPlotModel()

	if v828 and v828.PlotSign.ThisPlotsOwners:FindFirstChild('Value') then
		return true
	end
end
function UpdatePeopleInPlot()
	local v829 = PlotWorkspace
	local v830, v831, v832 = pairs(v829)

	while true do
		local u833

		v832, u833 = v830(v831, v832)

		if v832 == nil then
			break
		end
		if u833.Name == 'ThisPlotsOwners' then
			local function u838()
				local v834 = u833
				local v835 = GetPlotModel(_G.PlotName)
				local v836 = v834:GetChildren()

				if v835 and u833:IsDescendantOf(v835) then
					local v837 = table.getn(v836)

					if PlayersInPlot then
						PlayersInPlot:Set('Players in Plot: ' .. v837)
					end
					if v837 == 0 and PlotOwner then
						PlotOwner:Set('Plot Available!')
					end
				end
			end

			_IntValue.Changed:Connect(function(_)
				u838()
			end)
			u833.ChildAdded:Connect(u838)
			u833.ChildRemoved:Connect(u838)
			u838()
		end
	end
end

v766:AddDropdown({
	Name = 'Plot',
	Default = 'Witch House',
	Options = {
		'Witch House',
		'Lumber House',
		'Common House',
		'American House',
		'Chinese House',
	},
	Callback = function(p839)
		_G.PlotName = p839
		_IntValue.Value = _IntValue.Value + 1
	end,
})
task.spawn(function()
	UpdatePlotOwner()
	task.wait()
	UpdatePeopleInPlot()
end)

PlotOwner = v766:AddLabel('Plot Owner:')
PlayersInPlot = v766:AddLabel('Players in Plot: 0')

v766:AddButton({
	Name = 'Claim Plot!',
	Callback = function()
		ClaimPlot()
	end,
})

function ExplodeSb(p840)
	local v841 = {
		{
			Radius = 17.5,
			TimeLength = 0.1,
			Hitbox = p840:FindFirstChild('SoundPart'),
			ExplodesByFire = true,
			MaxForcePerStudSquared = -100,
			DestroysModel = true,
			Model = p840,
			ExplodesByPointy = false,
			ImpactSpeed = 100,
			PositionPart = _LocalPlayer.Character.HumanoidRootPart,
		},
		_LocalPlayer.Character.HumanoidRootPart.Position,
	}

	BombEvents.BombExplode:FireServer(unpack(v841))
end

getgenv().MaxSize = 15

local u842 = {}
local u843 = 0
local u844 = v766:AddLabel("25ms was here")
snowballEffectConnection = nil
snowballMaxAmmount = 20

if _ToysLimitCap.Value == 200 then
	snowballMaxAmmount = 40
end

function checkSize(p845)
	while _G.SnowbalEffectSpam do
		if p845 and p845:IsDescendantOf(_Workspace) and p845:FindFirstChild('SoundPart') then
			local _SoundPart2 = p845:FindFirstChild('SoundPart')
			local _Size = _SoundPart2.Size

			if _Size.X >= MaxSize and _Size.Y >= MaxSize and (_Size.Z >= MaxSize and not u842[_SoundPart2]) then
				u842[_SoundPart2] = true

				break
			end
		end

		task.wait()
	end
end
function checkSnowBall(p848)
	if p848 and p848:FindFirstChild('SoundPart') then
		local _SoundPart3 = p848.SoundPart
		local v850 = RaycastParams.new()

		v850.FilterDescendantsInstances = {p848}
		v850.FilterType = Enum.RaycastFilterType.Exclude

		local v851 = _Workspace:Raycast(_SoundPart3.Position, Vector3.new(0, -100, 0), v850)

		if v851 and v851.Material == Enum.Material.Sand then
			return true
		end
	end
end

lastpossb = nil

function holdOwnership()
	if not _G.SnowbalEffectSpam then
		return
	end

	local v852 = u17
	local v853, v854, v855 = pairs(v852:GetChildren())

	if v857 and v857.Name == 'BallSnowball' and v857:FindFirstChild('SoundPart') then
		local _SoundPart4 = v857:FindFirstChild('SoundPart')

		if not CheckNetworkOwnerShipOnPart(_SoundPart4) then
			if not lastpossb then
				lastpossb = GetPlayerCFrame()
			end

			for _ = 1, 10 do
				if SNOWshipOnce(_SoundPart4) then
					_SoundPart4.CanTouch = false
					_SoundPart4.CanCollide = false

					break
				end

				TeleportPlayer(CFrame.new(_SoundPart4.Position + Vector3.new(0, -10, 0)))
				task.wait(0.1)
			end

			TeleportPlayer(lastpossb)

			lastpossb = nil
		end
	end

	local v857

	v855, v857 = v853(v854, v855)

	if v855 ~= nil and _G.SnowbalEffectSpam then
	else
	end

	task.wait()
end
function CountGrownSnowsballs()
	local v858, v859, v860 = pairs(u842)
	local v861 = 0

	while true do
		local v862

		v860, v862 = v858(v859, v860)

		if v860 == nil then
			break
		end
		if v860:IsDescendantOf(_Workspace) then
			v861 = v861 + 1
		else
			u842[v860] = nil
		end
	end

	u844:Set('Grown Snowballs: ' .. v861)

	return v861
end
function modify(p863)
	local v864 = CFrame.new(-410, 228.394, 510, -0.246182978, 3.22764193e-9, -0.96922338, 1.2914926e-8, 1, 4.97377278e-11, 0.96922338, -1.2505204e-8, -0.246182978)

	while _G.SnowbalEffectSpam and p863 do
		if p863:FindFirstChild('SoundPart') then
			local _SoundPart5 = p863.SoundPart
			local _FarmSnowball = _SoundPart5:FindFirstChild('FarmSnowball')

			if CheckNetworkOwnerShipOnPart(_SoundPart5) then
				if _FarmSnowball then
					if u842[_SoundPart5] then
						_FarmSnowball.Position = Vector3.new(math.random(-10000, 10000), 10000, math.random(-10000, 10000))
					else
						_FarmSnowball.Position = v864.Position + Vector3.new(25, 0, 0) + Vector3.new(0, _SoundPart5.Size.X / 2 - 0.65, 0)

						wait(0.5)

						_FarmSnowball.Position = v864.Position + Vector3.new(-25, 0, 0) + Vector3.new(0, _SoundPart5.Size.X / 2 - 0.65, 0)

						wait(0.5)

						_FarmSnowball.Position = v864.Position + Vector3.new(0, _SoundPart5.Size.X / 2 - 0.65, 0)
					end
				else
					local _BodyPosition6 = Instance.new('BodyPosition', _SoundPart5)

					_BodyPosition6.MaxForce = Vector3.new(12500, 12500, 12500)
					_BodyPosition6.Name = 'FarmSnowball'
					_BodyPosition6.Position = _SoundPart5.Position
				end
			end
		end

		wait()
	end
end
function newSnowball(p868)
	if p868.Name == 'BallSnowball' and _G.SnowbalEffectSpam then
		task.spawn(function()
			checkSize(p868)
		end)
		task.spawn(function()
			modify(p868)
		end)
	end
end

task.spawn(function()
	while task.wait() do
		CountGrownSnowsballs()
	end
end)

local v869 = v650:AddSection({
	Name = 'Snowball',
})

v869:AddSlider({
	Name = 'Ammount',
	Min = 5,
	Max = snowballMaxAmmount,
	Default = 5,
	Color = Color3.fromRGB(255, 255, 255),
	Increment = 1,
	ValueName = 'Snowballs you want to make to explode them!',
	Callback = function(p870)
		u843 = p870
	end,
	Save = true,
	Flag = 'ammountsnowballtomake_slider',
})

automakesnowballtoggle = nil
automakesnowballtoggle = v869:AddToggle({
	Name = 'Auto Make Snowball',
	Default = false,
	Callback = function(p871)
		_G.SnowbalEffectSpam = p871

		if p871 then
			snowballEffectConnection = u17.ChildAdded:Connect(newSnowball)

			task.spawn(function()
				while _G.SnowbalEffectSpam do
					if u843 > countToys('BallSnowball') then
						SpawnToy({
							'BallSnowball',
							CFrame.new(-389, 228, 550, -0.3092496991157532, 0.2610282301902771, -0.9144555330276489, 0, 0.9615919589996338, 0.2744831442832947, 0.9509809017181396, 0.08488383144140244, -0.2973720133304596),
							Vector3.new(0, 97.69000244140625, 0),
						})
						task.wait(0.1)
					end
					if u843 <= CountGrownSnowsballs() then
						automakesnowballtoggle:Set(false)
					end

					task.wait()
				end
			end)
			task.spawn(function()
				holdOwnership()
			end)

			local v872 = u17
			local v873, v874, v875 = ipairs(v872:GetChildren())

			while true do
				local v876

				v875, v876 = v873(v874, v875)

				if v875 == nil then
					break
				end

				newSnowball(v876)
			end
		elseif snowballEffectConnection then
			snowballEffectConnection:Disconnect()
		end
	end,
	Save = true,
	Flag = 'autofarmsnowball_toggle',
})

local _ = v869:AddLabel('Grown Snowballs:')

v869:AddButton({
	Name = 'Explode Snowballs',
	Callback = function()
		local v877, v878, v879 = pairs(u842)

		while true do
			local v880

			v879, v880 = v877(v878, v879)

			if v879 == nil then
				break
			end
			if v879:IsDescendantOf(_Workspace) then
				ExplodeSb(v879.Parent)
			end
		end
	end,
})

spamexplosiontype = nil
spamexplosiontarget = 0
bombsammountoexplode = 1
reachedrightammount = false
explosionInterval = nil
canExplode = false
maxBombstoexplode = 8

if _ToysLimitCap.Value == 200 then
	maxBombstoexplode = 18
end

_ContextActionService:BindAction('FireBomb', fireBombs, false, Enum.KeyCode.F)

function ExplodeFw()
	local v881 = u17
	local v882, v883, v884 = pairs(v881:GetChildren())

	while true do
		local v885

		v884, v885 = v882(v883, v884)

		if v884 == nil then
			break
		end
		if v885.Name == spamexplosiontype then
			local v886 = {
				{
					Radius = 17.5,
					TimeLength = 0.5,
					Hitbox = v885:FindFirstChild('PartHitDetector'),
					ExplodesByFire = true,
					MaxForcePerStudSquared = 225,
					DestroysModel = true,
					Model = v885,
					ExplodesByPointy = false,
					ImpactSpeed = 20,
					PositionPart = workspace.SpawnLocation,
				},
				Vector3.new(0, -10, 0),
			}

			if spamexplosiontype ~= 'BombBalloon' then
				if spamexplosiontype == 'PresentBig' or spamexplosiontype == 'PresentSmall' then
					v886[1].Hitbox = v885.Box
				end
			else
				v886[1].Hitbox = v885.Balloon
			end
			if spamexplosiontarget ~= 0 then
				if spamexplosiontarget ~= 1 then
					local v887 = spamexplosiontarget == 2 and GetFakeAim2()

					if v887 then
						v886[1].PositionPart = v887
						v886[2] = v887.Position
					end
				else
					local v888

					if _G.TargetToBombPlayer then
						v888 = _Players:FindFirstChild(_G.TargetToBombPlayer)
					else
						v888 = nil
					end
					if v888 and not IsPlayerInsideSafeZone(v888) and v888.Character and (v888.Character:FindFirstChild('HumanoidRootPart') and not u54(v888)) then
						local _HumanoidRootPart5 = v888.Character.HumanoidRootPart

						v886[1].PositionPart = _HumanoidRootPart5
						v886[2] = _HumanoidRootPart5.Position
					end
				end
			else
				v886[1].PositionPart = workspace.SpawnLocation
				v886[2] = Vector3.new(math.random(-10, 10), math.random(-10, 10), math.random(-10, 10))
			end

			BombEvents.BombExplode:FireServer(unpack(v886))
		end
		if explosionInterval > 0 then
			task.wait(explosionInterval)
		end
	end
end

firework_section = v650:AddSection({
	Name = 'Explosions Spam',
})
explosionexplanation = v650:AddSection({
	Name = 'FAQ about (Explosions Spam)',
})

firework_section:AddToggle({
	Name = 'Explode',
	Default = false,
	Callback = function(p890)
		_G.FireworkEffectSpam = p890

		if p890 then
			task.spawn(function()
				while _G.FireworkEffectSpam do
					local v891 = GetPlayerCFrame()

					if countToys(spamexplosiontype) < bombsammountoexplode and not reachedrightammount and (spamexplosiontarget ~= 2 or GetFakeAim()) and v891 then
						SpawnToy({
							spamexplosiontype,
							CFrame.new(v891.Position.X, v891.Position.Y, v891.Position.Z, -0.3092496991157532, 0.2610282301902771, -0.9144555330276489, 0, 0.9615919589996338, 0.2744831442832947, 0.9509809017181396, 0.08488383144140244, -0.2973720133304596),
							Vector3.new(0, 97.69000244140625, 0),
						})
					end

					task.wait()
				end
			end)
			task.spawn(function()
				while _G.FireworkEffectSpam do
					local v892 = u17
					local v893, v894, v895 = pairs(v892:GetChildren())

					while true do
						local v896

						v895, v896 = v893(v894, v895)

						if v895 == nil then
							break
						end
						if v896.Name == spamexplosiontype then
							local v897 = nil

							if spamexplosiontype ~= 'BombDarkMatter' then
								if spamexplosiontype ~= 'BombMissile' then
									if spamexplosiontype ~= 'BombBalloon' then
										if spamexplosiontype ~= 'FireworkMissile' then
											if spamexplosiontype == 'PresentBig' or spamexplosiontype == 'PresentSmall' then
												v897 = v896:FindFirstChild('Box')
											end
										else
											v897 = v896:FindFirstChild('Hitbox')
										end
									else
										v897 = v896:FindFirstChild('Balloon')
									end
								else
									v897 = v896:FindFirstChild('Body')
								end
							else
								v897 = v896:FindFirstChild('Pyramid')
							end
							if v897 and not SNOWshipOnce(v897) and _LocalPlayer:DistanceFromCharacter(v897.Position) > 30 then
								DeleteToyRE:FireServer(v896)
								print('Deletado!')
							elseif v897 and CheckNetworkOwnerShipOnPart(v897) and not v896:GetAttribute('MissileTeleported') then
								wait()

								if v896.PrimaryPart then
									local _BodyVelocity3 = Instance.new('BodyVelocity', v896.PrimaryPart)

									_BodyVelocity3.Velocity = Vector3.new(0, 0, 0)
									_BodyVelocity3.MaxForce = Vector3.new(1, 1, 1) * math.huge

									v896:SetPrimaryPartCFrame(CFrame.new(math.random(-1000, 1000), 10000, math.random(-1000, 1000)))
									v896:SetAttribute('MissileTeleported', true)
								end

								print('ownershipped!')
							end
						end
					end

					task.wait(0.1)
				end
			end)
			task.spawn(function()
				while _G.FireworkEffectSpam do
					if countToys(spamexplosiontype) < bombsammountoexplode then
						_G.CanExplodeBombs = false
					else
						if spamexplosiontarget ~= 2 or not _G.FireBomb then
							if spamexplosiontarget ~= 2 then
								canExplode = true
							end
						else
							canExplode = true
						end

						_G.CanExplodeBombs = true

						if canExplode then
							ExplodeFw()

							reachedrightammount = false
							canExplode = false
						end
					end

					task.wait()
				end
			end)
			task.spawn(function()
				while _G.FireworkEffectSpam do
					if spamexplosiontarget == 2 then
						GetFakeAim2()
					end

					wait(0.1)
				end
			end)
		end
	end,
})
firework_section:AddDropdown({
	Name = 'Explosion Type',
	Default = 'Firework',
	Options = {
		'Firework',
		'Missile',
		'Void',
		'Ballon',
		'Small Present',
		'Big Present',
	},
	Callback = function(p899)
		if p899 == 'Firework' then
			spamexplosiontype = 'FireworkMissile'
		elseif p899 == 'Missile' then
			spamexplosiontype = 'BombMissile'
		elseif p899 == 'Void' then
			spamexplosiontype = 'BombDarkMatter'
		elseif p899 == 'Ballon' then
			spamexplosiontype = 'BombBalloon'
		elseif p899 == 'Small Present' then
			spamexplosiontype = 'PresentSmall'
		elseif p899 == 'Big Present' then
			spamexplosiontype = 'PresentBig'
		end
	end,
})
firework_section:AddSlider({
	Name = 'Ammount to Explode',
	Min = 1,
	Max = maxBombstoexplode,
	Default = 1,
	Color = Color3.fromRGB(255, 255, 255),
	Increment = 1,
	ValueName = 'to explode the player brutally',
	Callback = function(p900)
		bombsammountoexplode = p900
	end,
})
firework_section:AddSlider({
	Name = 'Delay',
	Min = 0,
	Max = 1,
	Default = 0,
	Color = Color3.fromRGB(255, 255, 255),
	Increment = 0.1,
	ValueName = 'interval between every explosion',
	Callback = function(p901)
		explosionInterval = p901
	end,
})
firework_section:AddDropdown({
	Name = 'Target',
	Default = 'Spawn',
	Options = {
		'Spawn',
		'Player',
		'Mouse',
	},
	Callback = function(p902)
		if p902 == 'Spawn' then
			spamexplosiontarget = 0
		elseif p902 == 'Player' then
			spamexplosiontarget = 1
		elseif p902 == 'Mouse' then
			spamexplosiontarget = 2
		end
	end,
})

PlayerToTarget = firework_section:AddDropdown({
	Name = 'Select Player',
	Default = 'Macaco (negro)',
	Options = {
		'',
	},
	Callback = function(p903)
		local v904 = string.split(p903, ' ')

		_G.TargetToBombPlayer = v904[1]
	end,
})

explosionexplanation:AddParagraph('How to use target mouse?', 'Press/Hold the keybind (F) and then BOOM!')
explosionexplanation:AddParagraph('How to target player?', 'Select Target to Player and then select the player you want to target')
explosionexplanation:AddParagraph('How to change the explosive', 'Click on Explosive Type and select any type')
_LocalPlayer.Idled:connect(function()
	_VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
	wait(1)
	_VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)

SilentAim_Section = v657:AddSection({
	Name = 'Silent-Aim',
})

SilentAim_Section:AddToggle({
	Name = 'Silent Aim',
	Default = false,
	Callback = function(p905)
		_G.SilentAim = p905
	end,
	Save = true,
	Flag = 'SilentAim_toggle',
})
SilentAim_Section:AddSlider({
	Name = 'Silent-Aim Range',
	Min = 0,
	Max = 50,
	Default = 50,
	Color = Color3.fromRGB(255, 255, 255),
	Increment = 1,
	ValueName = '',
	Callback = function(p906)
		u724 = p906
	end,
	Save = true,
	Flag = 'silentaimrange_slider',
})

FurtherLineExtend_Section = v652:AddSection({
	Name = 'Line Extender',
})

FurtherLineExtend_Section:AddToggle({
	Name = 'Further Extend',
	Default = false,
	Callback = function(p907)
		_G.FutherExtend = p907
	end,
	Save = true,
	Flag = 'FurtherLineExtend_toggle',
})

MaxExtendLine = 0
MinExtendLine = 0

if _UserInputService.TouchEnabled then
	MinExtendLine = 3
	MaxExtendLine = 25
elseif _UserInputService.MouseEnabled then
	MinExtendLine = 3
	MaxExtendLine = 25
end

FurtherLineExtend_Section:AddSlider({
	Name = 'Increase Extend',
	Min = MinExtendLine,
	Max = MaxExtendLine,
	Default = 3,
	Color = Color3.fromRGB(255, 255, 255),
	Increment = 1,
	ValueName = 'Ammount',
	Callback = function(p908)
		IncreaseLineExtend = p908
	end,
	Save = true,
	Flag = 'FurtherLineExtend_slider',
})

local v909 = v653:AddSection({
	Name = 'Normal Auras',
})
local v910 = v653:AddSection({
	Name = 'Fling Aura',
})
local v911 = v653:AddSection({
	Name = 'Telekinesis Aura',
})
local v912 = v653:AddSection({
	Name = 'Anchor Aura',
})
local v913 = v653:AddSection({
	Name = 'Kick Aura',
})
local v914 = v653:AddSection({
	Name = 'Auras Whitelist',
})

local function u917()
	local _Character5 = _LocalPlayer.Character
	local v916

	if _Character5 then
		v916 = _Character5:FindFirstChildOfClass('Humanoid')
	else
		v916 = nil
	end
	if not (_Character5 and v916) or (not v916.Sit or v916.SeatPart == nil) or tostring(v916.SeatPart.Parent) ~= 'CreatureBlobman' then
		return false
	end

	_G.LastBlobmanWasSeat = v916.SeatPart.Parent

	return true
end

function IsPlayerKickingWithBlobman()
	if u917() and _G.LoopKick then
		return true
	end
end

local function u924(p918)
	local v919 = false

	_Players:FindFirstChild(p918)

	if u917() and _G.LoopKick then
		local v920, v921, v922 = pairs(u70)

		while true do
			local v923

			v922, v923 = v920(v921, v922)

			if v922 == nil then
				break
			end
			if p918 == v923 then
				v919 = true
			end
		end
	end

	return v919
end

function CheckPlayer(p925)
	if typeof(p925) == 'Instance' and (p925 ~= _LocalPlayer and not u54(p925)) and (p925.Character and p925.Character:IsDescendantOf(_Workspace)) and (p925.Character:FindFirstChild('HumanoidRootPart') and (p925.Character:FindFirstChildOfClass('Humanoid') and 0 < p925.Character.Humanoid.Health)) then
		return true
	end
end
function CheckPlayerForLoopKill(p926)
	if CheckPlayer(p926) and not IsPlayerInsideSafeZone(p926) then
		return true
	end
end
function CheckPlayerAuras(p927)
	if CheckPlayer(p927) and not (u105(p927.Name) and _G.WhitelistFriends) and not (u924(p927.Name) or (p927.Character:GetAttribute('Kicking') or _G.KickAura)) then
		return true
	end
end
function CheckPlayerAurasKick(p928)
	if CheckPlayer(p928) and not (u105(p928.Name) and _G.WhitelistFriends) and not (u924(p928.Name) or p928.Character:GetAttribute('Kicking')) then
		return true
	end
end
function CheckPlayerAnnoyAll(p929)
	if CheckPlayer(p929) and not (u105(p929.Name) and _G.WhitelistFriends3) and not (u924(p929.Name) or p929.Character:GetAttribute('Kicking')) then
		return true
	end
end
function CheckPlayerKill(p930)
	if CheckPlayer(p930) and not (u105(p930.Name) and _G.WhitelistFriends3) and not IsPlayerInsideSafeZone(p930) then
		return true
	end
end
function CheckPlayerKick(p931)
	if CheckPlayer(p931) and not (u105(p931.Name) and _G.WhitelistFriends3) and not (IsPlayerInsideSafeZone(p931) or IsPlayerFloating(p931)) then
		return true
	end
end
function CheckPlayerBring(p932, _)
	if CheckPlayer(p932) and not (u105(p932.Name) and _G.WhitelistFriends3) and (not IsPlayerInsideSafeZone(p932) and CheckPlayerVelocity(p932) < 20) then
		return true
	end
end
function CreateSkyVelocity(p933)
	if not p933:FindFirstChild('SkyVelocity') then
		local _BodyVelocity4 = Instance.new('BodyVelocity', p933)

		_BodyVelocity4.Name = 'SkyVelocity'
		_BodyVelocity4.Velocity = Vector3.new(0, 100000000000000, 0)
		_BodyVelocity4.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	end
end
function CreateBringBody(p935, p936)
	if p935:FindFirstChild('BringBody') then
		p935:FindFirstChild('BringBody').Position = p936.Position
	else
		local _BodyPosition7 = Instance.new('BodyPosition', p935)

		_BodyPosition7.Name = 'BringBody'
		_BodyPosition7.Position = p936.Position
		_BodyPosition7.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		_BodyPosition7.D = 5000
		_BodyPosition7.P = 1500000
	end
end

local _OuterUFO = _Workspace.Map.AlwaysHereTweenedObjects:FindFirstChild('OuterUFO')

if _OuterUFO and _OuterUFO:FindFirstChild('Object') and _OuterUFO.Object:FindFirstChild('ObjectModel') then
	_OuterUFO = _OuterUFO.Object.ObjectModel.PaintPlayerPart
	_OuterUFO:WaitForChild('WeldConstraint').Enabled = false
	_OuterUFO.Anchored = true
	_OuterUFO.Shape = Enum.PartType.Block
	_OuterUFO.Transparency = 1
	_OuterUFO.Size = Vector3.new(0.5, 0.5, 0.5)
	_OuterUFO.Position = Vector3.new(0, -50, 0)
end

v909:AddToggle({
	Name = 'Poison Aura',
	Default = false,
	Callback = function(p939)
		_G.Poison_Aura = p939

		if p939 then
			while _G.Poison_Aura do
				local v940 = _Players
				local v941, v942, v943 = pairs(v940:GetPlayers())

				while true do
					local v944

					v943, v944 = v941(v942, v943)

					if v943 == nil then
						break
					end
					if CheckPlayerAuras(v944) then
						local _Head3 = v944.Character:FindFirstChild('Head')

						if _Head3 and SNOWshipPlayer(v944) then
							_PoisonHurtPart.CFrame = _Head3.CFrame
							_PoisonHurtPart2.CFrame = _Head3.CFrame
							_PoisonHurtPart3.CFrame = _Head3.CFrame

							task.wait()

							_PoisonHurtPart3.Position = Vector3.new(0, -50, 0)
							_PoisonHurtPart2.Position = Vector3.new(0, -50, 0)
							_PoisonHurtPart.Position = Vector3.new(0, -50, 0)
						end
					end
				end

				task.wait()
			end
		end
	end,
	Save = true,
	Flag = 'poisonaura_toggle',
})
v909:AddToggle({
	Name = 'Death Aura',
	Default = false,
	Callback = function(p946)
		_G.DeathAura = p946

		if p946 then
			while _G.DeathAura do
				local v947 = _Players
				local v948, v949, v950 = pairs(v947:GetPlayers())

				while true do
					local v951

					v950, v951 = v948(v949, v950)

					if v950 == nil then
						break
					end
					if CheckPlayerAuras(v951) then
						local _Character6 = v951.Character
						local _HumanoidRootPart6 = _Character6:FindFirstChild('HumanoidRootPart')
						local _Humanoid5 = _Character6:FindFirstChildOfClass('Humanoid')

						if _HumanoidRootPart6 and _Humanoid5 and SNOWshipPlayer(v951) then
							_DestroyGrabLine:FireServer(_HumanoidRootPart6)
							CreateSkyVelocity(_HumanoidRootPart6)

							_Humanoid5.BreakJointsOnDeath = false

							_Humanoid5:ChangeState(Enum.HumanoidStateType.Dead)

							_Humanoid5.Jump = true
							_Humanoid5.Sit = false

							if _Humanoid5:GetStateEnabled(Enum.HumanoidStateType.Dead) then
								_DestroyGrabLine:FireServer(_HumanoidRootPart6)
							end
						end
					end
				end

				task.wait()
			end
		end
	end,
	Save = true,
	Flag = 'deathaura_toggle',
})

if _OuterUFO then
	v909:AddToggle({
		Name = 'Radioactive Aura',
		Default = false,
		Callback = function(p955)
			_G.RadioactiveAura = p955

			if p955 then
				while _G.RadioactiveAura do
					local v956 = _Players
					local v957, v958, v959 = pairs(v956:GetPlayers())

					while true do
						local v960

						v959, v960 = v957(v958, v959)

						if v959 == nil then
							break
						end
						if CheckPlayerAuras(v960) then
							local _HumanoidRootPart7 = v960.Character:FindFirstChild('HumanoidRootPart')

							if _HumanoidRootPart7 and SNOWshipPlayer(v960) then
								_OuterUFO.Position = _HumanoidRootPart7.Position

								task.wait()

								_OuterUFO.Position = Vector3.new(0, -50, 0)
							end
						end
					end

					task.wait()
				end
			end
		end,
		Save = true,
		Flag = 'radioaura_toggle',
	})
end

v909:AddToggle({
	Name = 'Burn Aura',
	Default = false,
	Callback = function(p962)
		_G.BurnAura = p962

		if p962 then
			while _G.BurnAura do
				local v963 = _Players
				local v964, v965, v966 = pairs(v963:GetPlayers())

				while true do
					local v967

					v966, v967 = v964(v965, v966)

					if v966 == nil then
						break
					end
					if CheckPlayerAuras(v967) then
						local _HumanoidRootPart8 = v967.Character:FindFirstChild('HumanoidRootPart')

						if _HumanoidRootPart8 and _LocalPlayer:DistanceFromCharacter(_HumanoidRootPart8.Position) < 30 then
							u613(_HumanoidRootPart8)
						end
					end
				end

				task.wait()
			end
		end
	end,
	Save = true,
	Flag = 'burnaura_toggle',
})
v910:AddToggle({
	Name = 'Fling Aura',
	Default = false,
	Callback = function(p969)
		_G.FlingAura = p969

		if p969 then
			while _G.FlingAura do
				if _G.FlingTarget == 2 or _G.FlingTarget == 3 then
					local v970, v971 = CheckObjectsAroundPlayer()

					if v970 then
						local v972, v973, v974 = pairs(v970)

						while true do
							local v975

							v974, v975 = v972(v973, v974)

							if v974 == nil then
								break
							end

							local v976 = 0

							if v975 then
								local _Head4 = v975:FindFirstChild('Head')
								local v978, v979, v980 = pairs(v975:GetChildren())

								while true do
									local v981

									v980, v981 = v978(v979, v980)

									if v980 == nil then
										break
									end
									if v981:IsA('BasePart') and v981.CanQuery then
										local v982 = SNOWshipTrack(v981)
										local v983 = GetPlayerRoot()

										if not v982 and _Head4 then
											v982 = CheckNetworkOwnerShipOnPart(_Head4)
										end
										if v982 and v983 then
											if v971 then
												local _Position3 = v971.Position

												v971.Position = v981.Position

												task.wait()

												v971.Position = _Position3
											elseif not v981:FindFirstChild('FlingAuraVelocity') then
												local v985 = lookAt(v983.Position, v981.Position)
												local _BodyVelocity5 = Instance.new('BodyVelocity', v981)

												_BodyVelocity5.Name = 'FlingAuraVelocity'
												_BodyVelocity5.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
												_BodyVelocity5.Velocity = Vector3.new(v985.lookVector.X, 0.5, v985.lookVector.Z) * math.clamp(_G.FlingStrength, 400, 600)

												_Debris:AddItem(_BodyVelocity5)
											end

											v976 = v976 + 1
										end
										if v976 >= 3 then
											break
										end
									end
								end
							end
						end
					end
				end
				if _G.FlingTarget == 1 or _G.FlingTarget == 3 then
					local v987 = _Players
					local v988, v989, v990 = pairs(v987:GetPlayers())

					while true do
						local v991

						v990, v991 = v988(v989, v990)

						if v990 == nil then
							break
						end
						if CheckPlayerAuras(v991) then
							local _HumanoidRootPart9 = v991.Character:FindFirstChild('HumanoidRootPart')
							local v993 = SNOWshipPlayer(v991)
							local v994 = GetPlayerCharacter()

							if _HumanoidRootPart9 and v993 and (v994 and not _HumanoidRootPart9:FindFirstChild('FlingAuraVelocity')) then
								local v995 = lookAt(v994.HumanoidRootPart.Position, _HumanoidRootPart9.Position)
								local _BodyVelocity6 = Instance.new('BodyVelocity', _HumanoidRootPart9)

								_BodyVelocity6.Name = 'FlingAuraVelocity'
								_BodyVelocity6.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
								_BodyVelocity6.Velocity = Vector3.new(v995.lookVector.X, 0.5, v995.lookVector.Z) * _G.FlingStrength

								_Debris:AddItem(_BodyVelocity6)
							end
						end
					end
				end

				task.wait(0.1)
			end
		end
	end,
	Save = true,
	Flag = 'flingaura_toggle',
})
v910:AddSlider({
	Name = 'Strength',
	Min = 400,
	Max = 10000,
	Default = 400,
	Color = Color3.fromRGB(255, 255, 255),
	Increment = 100,
	ValueName = '',
	Callback = function(p997)
		_G.FlingStrength = p997
	end,
	Save = true,
	Flag = 'flingstrengthvalue_toggle',
})
v910:AddDropdown({
	Name = 'Target',
	Default = 'Players',
	Options = {
		'Players',
		'Objects',
		'Players and Objects',
	},
	Callback = function(p998)
		if p998 == 'Players' then
			_G.FlingTarget = 1
		elseif p998 == 'Objects' then
			_G.FlingTarget = 2
		elseif p998 == 'Players and Objects' then
			_G.FlingTarget = 3
		end
	end,
	Save = true,
	Flag = 'flingtarget_dropdown',
})
v912:AddToggle({
	Name = 'Anchor Aura',
	Default = false,
	Callback = function(p999)
		_G.AnchorAura = p999

		if p999 then
			while _G.AnchorAura do
				if _G.AnchorTarget == 2 or _G.AnchorTarget == 3 then
					local v1000, _ = CheckObjectsAroundPlayer()

					if v1000 then
						local v1001, v1002, v1003 = pairs(v1000)

						while true do
							local v1004

							v1003, v1004 = v1001(v1002, v1003)

							if v1003 == nil then
								break
							end

							local v1005 = 0

							if v1004 and not v1004:GetAttribute('IsAnchored') then
								local v1006, v1007, v1008 = pairs(v1004:GetChildren())

								while true do
									local v1009

									v1008, v1009 = v1006(v1007, v1008)

									if v1008 == nil then
										break
									end
									if v1009:IsA('BasePart') and v1009.CanQuery then
										if SNOWshipTrack(v1009) or CheckNetworkOwnerShipOnPart(head) then
											setanchorObject(v1009)

											v1005 = v1005 + 1
										end
										if v1005 >= 3 then
											break
										end
									end
								end
							end
						end
					end
				end
				if _G.AnchorTarget == 1 or _G.AnchorTarget == 3 then
					local v1010 = _Players
					local v1011, v1012, v1013 = pairs(v1010:GetPlayers())

					while true do
						local v1014

						v1013, v1014 = v1011(v1012, v1013)

						if v1013 == nil then
							break
						end
						if CheckPlayerAuras(v1014) then
							local _Character7 = v1014.Character
							local _HumanoidRootPart10 = _Character7:FindFirstChild('HumanoidRootPart')

							if SNOWshipPlayer(v1014) and _HumanoidRootPart10 and not _Character7:GetAttribute('IsAnchored') then
								setanchorObject(_HumanoidRootPart10)
							end
						end
					end
				end

				task.wait(0.1)
			end
		end
	end,
	Save = true,
	Flag = 'anchoraura_toggle',
})
v912:AddDropdown({
	Name = 'Target',
	Default = 'Players',
	Options = {
		'Players',
		'Objects',
		'Players and Objects',
	},
	Callback = function(p1017)
		if p1017 == 'Players' then
			_G.AnchorTarget = 1
		elseif p1017 == 'Objects' then
			_G.AnchorTarget = 2
		elseif p1017 == 'Players and Objects' then
			_G.AnchorTarget = 3
		end
	end,
	Save = true,
	Flag = 'anchortarget_dropdown',
})

GroupCollisionData = {}

function SetCollisionObjectOff(p1018)
	if typeof(p1018) == 'Instance' and (p1018:IsA('Model') and not p1018:GetAttribute('ObjectCollisions')) then
		p1018:SetAttribute('ObjectCollisions', true)

		local v1019 = p1018:GetDescendants()
		local v1020, v1021, v1022 = pairs(v1019)
		local v1023 = {}

		while true do
			local v1024

			v1022, v1024 = v1020(v1021, v1022)

			if v1022 == nil then
				break
			end
			if v1024:IsA('BasePart') or v1024:IsA('Part') or v1024:IsA('MeshPart') then
				v1023[v1024] = v1024.CanCollide
			end
		end

		table.insert(GroupCollisionData, {
			Model = p1018,
			OldValues = v1023,
		})

		local v1025, v1026, v1027 = pairs(v1019)

		while true do
			local v1028

			v1027, v1028 = v1025(v1026, v1027)

			if v1027 == nil then
				break
			end
			if v1028:IsA('BasePart') or v1028:IsA('Part') or v1028:IsA('MeshPart') then
				v1028.CanCollide = false
			end
		end
	end
end
function SetCollisionObjectOn(p1029)
	if typeof(p1029) == 'Instance' and (p1029:IsA('Model') and p1029:GetAttribute('ObjectCollisions')) then
		local v1030, v1031, v1032 = pairs(GroupCollisionData)

		while true do
			local v1033

			v1032, v1033 = v1030(v1031, v1032)

			if v1032 == nil then
				break
			end

			local v1034, v1035, v1036 = pairs(v1033)
			local v1037 = v1032

			while true do
				local v1038

				v1036, v1038 = v1034(v1035, v1036)

				if v1036 == nil then
					break
				end
				if v1036 == 'Model' and v1038 == p1029 then
					local v1039, v1040, v1041 = pairs(p1029:GetDescendants())

					while true do
						local v1042

						v1041, v1042 = v1039(v1040, v1041)

						if v1041 == nil then
							break
						end
						if v1042:IsA('BasePart') or v1042:IsA('Part') or v1042:IsA('MeshPart') then
							v1042.CanCollide = v1033.OldValues[v1042]
						end
					end

					p1029:SetAttribute('ObjectCollisions', false)
					table.remove(GroupCollisionData, v1037)
				end
			end
		end
	end
end

TornadoOffset = 0
TornadoHeight = 0

function SpiralFormulaCalculation(p1043, p1044, p1045, p1046)
	if _G.TornadoShape == 'Tornado' then
		return Vector3.new(p1043.X + 15 * p1046 * math.sin(p1044), p1043.Y + 20 + p1046 * 2 + math.sin(p1044 * 0.5) * 40 + math.random(-20, 20), p1043.Z + 15 * p1046 * math.cos(p1044))
	end
	if _G.TornadoShape == 'Blackhole' then
		local _ = Vector3.new
		local _ = p1043.X + p1045 * math.sin(p1044)
		local _ = p1043.Y + TornadoHeight
		local _ = p1043.Z + p1045 * math.cos(p1044)
	end
end

_G.LastPartToGet = nil
_G.LastTheta = 0
TelekinesisBodiesPosition = {}

v911:AddToggle({
	Name = 'Telekinesis Aura',
	Default = false,
	Callback = function(p1047)
		_G.TornadoAura = p1047

		if p1047 then
			local u1048 = {}
			local u1049 = 0

			local function v1063(p1050, p1051)
				if not p1050:GetAttribute('TornadoSetup') then
					p1050:SetAttribute('TornadoSetup', true)

					if u1049 <= 1 then
						u1049 = u1049 + 0.1
					else
						u1049 = 0.1
					end

					_G.LastPartToGet = p1050

					local u1052 = 40 * u1049

					table.insert(u1048, p1050)

					local u1053 = table.find(u1048, p1050)
					local _BodyPosition8 = Instance.new('BodyPosition', p1051)

					_BodyPosition8.Name = 'TornadoAuraVelocity'
					_BodyPosition8.MaxForce = Vector3.new(math.huge, math.huge, math.huge)

					table.insert(TelekinesisBodiesPosition, _BodyPosition8)

					local u1055 = #TelekinesisBodiesPosition

					task.spawn(function()
						local _LastTheta = _G.LastTheta
						local v1057 = Vector3.new(0, 0, 0)
						local v1058 = Vector3.new(1250000, 1250000, 1250000)
						local v1059 = nil

						while p1050.Parent and _BodyPosition8.Parent do
							local v1060

							if _G.TornadoAura then
								if _G.LastPartToGet == p1050 then
									_G.LastTheta = _LastTheta + 0.5
								end

								_LastTheta = _LastTheta + TornadoSpeed

								local v1061 = TornadoOffset

								if _G.TornadoFollowType ~= 'Mouse' or not _LocalPlayer.Character or not _LocalPlayer.Character:FindFirstChild('CamPart') then
									v1060 = v1059
								else
									local v1062

									v1062, v1060 = _Workspace:FindPartOnRayWithIgnoreList(Ray.new(_LocalPlayer.Character.CamPart.Position, _LocalPlayer.Character.CamPart.CFrame.lookVector * 5000), {
										_LocalPlayer.Character,
										table.unpack(u1048),
									})

									if v1062 and v1060 then
										v1059 = v1060
									else
										v1060 = v1059
									end
									if v1059 then
										_BodyPosition8.Position = SpiralFormulaCalculation(v1059, _LastTheta, v1061, u1052)
									end
								end
								if _G.TornadoFollowType == 'Player' then
									MainPart = GetPlayerHRPByName(_G.TornadoFollowPlayer)

									if MainPart then
										_BodyPosition8.Position = SpiralFormulaCalculation(MainPart.Position, _LastTheta, v1061, u1052)
									end
								end
							else
								v1060 = v1059
							end
							if _G.TornadoAura then
								_BodyPosition8.MaxForce = v1058

								SetCollisionObjectOff(p1050)
							else
								SetCollisionObjectOn(p1050)

								_BodyPosition8.MaxForce = v1057
							end

							wait()

							v1059 = v1060
						end

						table.remove(u1048, u1053)
						table.remove(TelekinesisBodiesPosition, u1055)
						SetCollisionObjectOn(p1050)
						_BodyPosition8:Destroy()
						p1050:SetAttribute('TornadoSetup', false)
					end)
				end
			end

			while _G.TornadoAura do
				if _G.TornadoMode ~= 'Aura' then
					if _G.TornadoMode == 'Click' and _G.HoldingObjectGrabPart then
						local _HoldingObjectGrabPart = _G.HoldingObjectGrabPart

						if _HoldingObjectGrabPart.Parent and _HoldingObjectGrabPart.Parent:IsA('Model') then
							local _Parent9 = _HoldingObjectGrabPart.Parent
							local v1066 = _Players:GetPlayerFromCharacter(_Parent9)
							local _Head5 = _Parent9:FindFirstChild('Head')

							if v1066 then
								if CheckNetworkOwnerShipOnPlayer(v1066) then
									v1063(_Parent9, _HoldingObjectGrabPart)
								end
							elseif not v1066 and CheckNetworkOwnerShipOnPart(_Head5 or _HoldingObjectGrabPart) then
								v1063(_Parent9, _Head5 or _HoldingObjectGrabPart)
							end
						end
					end
				else
					if _G.TornadoTarget == 2 or _G.TornadoTarget == 3 then
						local v1068 = CheckObjectsAroundPlayer()

						if v1068 then
							local v1069, v1070, v1071 = pairs(v1068)

							while true do
								local v1072

								v1071, v1072 = v1069(v1070, v1071)

								if v1071 == nil then
									break
								end

								local v1073 = 0

								if v1072 then
									local _Head6 = v1072:FindFirstChild('Head')
									local v1075, v1076, v1077 = pairs(v1072:GetChildren())

									while true do
										local v1078

										v1077, v1078 = v1075(v1076, v1077)

										if v1077 == nil then
											break
										end
										if v1078:IsA('BasePart') and v1078.CanQuery then
											local v1079 = SNOWshipTrack(v1078)
											local v1080 = GetPlayerRoot()

											if not v1079 and _Head6 then
												v1079 = CheckNetworkOwnerShipOnPart(_Head6)
											end
											if v1079 and v1080 then
												v1063(v1072, v1078)

												v1073 = v1073 + 1
											end
											if v1073 >= 3 then
												break
											end
										end
									end
								end
							end
						end
					end
					if _G.TornadoTarget == 1 or _G.TornadoTarget == 3 then
						local v1081 = _Players
						local v1082, v1083, v1084 = pairs(v1081:GetPlayers())

						while true do
							local v1085

							v1084, v1085 = v1082(v1083, v1084)

							if v1084 == nil then
								break
							end
							if CheckPlayerAuras(v1085) then
								local _Character8 = v1085.Character
								local _HumanoidRootPart11 = _Character8:FindFirstChild('HumanoidRootPart')

								if _HumanoidRootPart11 and SNOWshipPlayer(v1085) and GetPlayerCharacter() then
									v1063(_Character8, _HumanoidRootPart11)
								end
							end
						end
					end

					task.wait(0.1)
				end

				task.wait()
			end
		end
	end,
	Save = true,
	Flag = 'tornadoaura_toggle',
})
v911:AddDropdown({
	Name = 'Select Mode',
	Default = 'Aura',
	Options = {
		'Click',
		'Aura',
	},
	Callback = function(p1088)
		if p1088 then
			_G.TornadoMode = p1088
		end
	end,
})

telekenesisshapedropdown = nil
telekenesisshapedropdown = v911:AddDropdown({
	Name = 'Shape',
	Default = 'Blackhole',
	Options = {
		'Blackhole',
		'Tornado',
	},
	Callback = function(p1089)
		if p1089 then
			if p1089 == 'Tornado' then
				telekenesissliderspeed:Set(0.495)
			end

			_G.TornadoShape = p1089
		end
	end,
})

v911:AddDropdown({
	Name = 'Follow Type:',
	Default = 'Player',
	Options = {
		'Player',
		'Mouse',
	},
	Callback = function(p1090)
		if p1090 then
			_G.TornadoFollowType = p1090
		end
	end,
})

RotationAuraList = v911:AddDropdown({
	Name = 'Follow Player:',
	Default = '',
	Options = {
		'',
	},
	Callback = function(p1091)
		if p1091 then
			_G.TornadoFollowPlayer = string.split(p1091, ' ')[1]
		end
	end,
})
_G.TornadoFollowPlayer = _LocalPlayer.Name

v911:AddDropdown({
	Name = 'Target',
	Default = 'Players',
	Options = {
		'Players',
		'Objects',
		'Players and Objects',
	},
	Callback = function(p1092)
		if p1092 == 'Players' then
			_G.TornadoTarget = 1
		elseif p1092 == 'Objects' then
			_G.TornadoTarget = 2
		elseif p1092 == 'Players and Objects' then
			_G.TornadoTarget = 3
		end
	end,
	Save = true,
	Flag = 'tornadotarget_dropdown',
})
v911:AddSlider({
	Name = 'Distance',
	Min = 5,
	Max = 1000,
	Default = 10,
	Color = Color3.fromRGB(255, 255, 255),
	Increment = 5,
	ValueName = 'Offset',
	Callback = function(p1093)
		TornadoOffset = p1093
	end,
	Save = true,
	Flag = 'tornadodistance_toggle',
})
v911:AddSlider({
	Name = 'Height',
	Min = 5,
	Max = 1000,
	Default = 10,
	Color = Color3.fromRGB(255, 255, 255),
	Increment = 5,
	ValueName = 'Offset',
	Callback = function(p1094)
		TornadoHeight = p1094
	end,
	Save = true,
	Flag = 'tornadoheight_toggle',
})

telekenesissliderspeed = nil
telekenesissliderspeed = v911:AddSlider({
	Name = 'Speed',
	Min = 0.01,
	Max = 0.5,
	Default = 0.01,
	Color = Color3.fromRGB(255, 255, 255),
	Increment = 0.015,
	ValueName = 'Rotation Speed',
	Callback = function(p1095)
		TornadoSpeed = p1095
	end,
	Save = true,
	Flag = 'tornadospeed_toggle',
})

v911:AddButton({
	Name = 'Disconnect All',
	Callback = function()
		local v1096, v1097, v1098 = pairs(TelekinesisBodiesPosition)

		while true do
			local v1099

			v1098, v1099 = v1096(v1097, v1098)

			if v1098 == nil then
				break
			end

			v1099:Destroy()
		end
	end,
})
v909:AddToggle({
	Name = 'Attraction Aura',
	Default = false,
	Callback = function(p1100)
		_G.AttractionAura = p1100

		if p1100 then
			while _G.AttractionAura do
				local v1101 = _Players
				local v1102, v1103, v1104 = pairs(v1101:GetPlayers())

				while true do
					local v1105

					v1104, v1105 = v1102(v1103, v1104)

					if v1104 == nil then
						break
					end
					if CheckPlayerAuras(v1105) then
						local _Character9 = v1105.Character
						local _HumanoidRootPart12 = _Character9:FindFirstChild('HumanoidRootPart')
						local _Humanoid6 = _Character9:FindFirstChildOfClass('Humanoid')
						local v1109 = GetPlayerCharacter()

						if _Humanoid6 and _HumanoidRootPart12 and v1109 then
							SNOWship(_HumanoidRootPart12)

							_Humanoid6.Sit = false
							_Humanoid6.WalkSpeed = 25

							_Humanoid6:MoveTo(v1109.HumanoidRootPart.Position)
						end
					end
				end

				task.wait()
			end
		end
	end,
	Save = true,
	Flag = 'attractaura_toggle',
})

kickauratoggle = nil
KickTypesList = {
	'Silent',
	'Float',
	'Sky Anchor',
}

function CreateKickPhysical(p1110, p1111, p1112)
	if p1111:FindFirstChild('KickAuraP') then
		p1111.KickAuraP:SetAttribute('TypeFunction', p1112)
	else
		local _BodyPosition9 = Instance.new('BodyPosition', p1111)

		_BodyPosition9.Name = 'KickAuraP'

		local v1114 = _BodyPosition9

		_BodyPosition9.SetAttribute(v1114, 'TypeFunction', p1112)

		local _BodyVelocity7 = Instance.new('BodyVelocity', p1111)

		_BodyVelocity7.Name = 'KickAuraP1'
		_BodyVelocity7.Velocity = Vector3.new(0, 400, 0)

		task.spawn(function()
			local u1116 = nil
			local u1117 = nil
			local u1118 = Vector3.new(0, -100, 0)
			local u1119 = Vector3.new(0, 0, 0)
			local u1120 = Vector3.new(0, 12500, 0)
			local u1121 = Vector3.new(4000, 4000, 4000)
			local u1122 = Vector3.new(math.random(50, 250), 250, math.random(50, 250))
			local u1123 = RaycastParams.new()

			u1123.FilterDescendantsInstances = {p1110}
			u1123.FilterType = Enum.RaycastFilterType.Exclude

			local function v1125(p1124)
				if p1124 == 'Silent' then
					_BodyPosition9.MaxForce = u1120
					_BodyVelocity7.MaxForce = u1119
					u1116 = p1111.Position
					u1117 = _Workspace:Raycast(u1116, u1118, u1123)

					if u1117 then
						_BodyPosition9.Position = u1117.Position + Vector3.new(0, 5, 0)
					end
				elseif p1124 == 'Float' then
					_BodyVelocity7.MaxForce = u1121
					_BodyPosition9.MaxForce = u1119
				elseif p1124 == 'Sky Anchor' then
					_BodyPosition9.MaxForce = u1121
					_BodyPosition9.Position = u1122
					_BodyVelocity7.MaxForce = u1119
				end
			end

			while _BodyPosition9.Parent and p1110.Parent do
				p1112 = _BodyPosition9:GetAttribute('TypeFunction')

				if p1112 == 'Aura' or not p1112 then
					if not _G.KickAura then
						break
					end

					v1125(_G.KickAuraType)
				elseif p1112 ~= 'Counter' then
					if p1112 ~= 'Kick_All' then
						if p1112 == 'LoopKick' then
							if not _G.LoopKickOwnership then
								break
							end

							v1125(_G.LoopKickOwnerType)
						end
					else
						if not _G.KickAll then
							break
						end

						v1125(_G.KickAllType)
					end
				else
					if not _G.AutoAttacker then
						break
					end

					v1125(_G.KickCounterType)
				end

				task.wait()
			end

			_BodyPosition9:Destroy()
			_BodyVelocity7:Destroy()
		end)
	end
end

kickauratoggle = v913:AddToggle({
	Name = 'Kick Aura',
	Default = false,
	Callback = function(p1126)
		_G.KickAura = p1126

		if p1126 then
			while _G.KickAura do
				if GetKey() ~= 'Xana' then
					kickauratoggle:Set(false)
					u33('Only for premium users! Buy premium in my discord server!')

					break
				end

				local v1127 = _Players
				local v1128, v1129, v1130 = pairs(v1127:GetPlayers())

				while true do
					local v1131

					v1130, v1131 = v1128(v1129, v1130)

					if v1130 == nil then
						break
					end
					if CheckPlayerAurasKick(v1131) then
						local _Character10 = v1131.Character
						local _HumanoidRootPart13 = _Character10:FindFirstChild('HumanoidRootPart')

						if _HumanoidRootPart13 and _Character10:FindFirstChildOfClass('Humanoid') and (_HumanoidRootPart13:FindFirstChild('FirePlayerPart') and SNOWshipPlayer(v1131)) then
							CreateSkyVelocity(_HumanoidRootPart13)
							_DestroyGrabLine:FireServer(_HumanoidRootPart13)
						end
					end
				end

				task.wait()
			end
		end
	end,
})

v913:AddDropdown({
	Name = 'Kick Type',
	Default = 'Go to the heaven!',
	Options = {
		'Go to the heaven!',
	},
	Callback = function(p1134)
		_G.KickAuraType = p1134
	end,
	Save = true,
	Flag = 'kickauratype_dropdown',
})
v914:AddToggle({
	Name = 'Whitelist Friends',
	Default = false,
	Callback = function(p1135)
		_G.WhitelistFriends = p1135
	end,
	Save = true,
	Flag = 'whitelistaura_toggle',
})

local v1136 = v647:AddSection({
	Name = 'Strength',
})
local v1137 = v647:AddSection({
	Name = 'Others',
})
local v1138 = v647:AddSection({
	Name = 'Perspective',
})

v1136:AddToggle({
	Name = 'Super Strength',
	Default = false,
	Callback = function(p1139)
		_G.SuperStrength = p1139
	end,
	Save = true,
	Flag = 'superstrengthgrab_toggle',
})
v1136:AddSlider({
	Name = 'Strength',
	Min = 400,
	Max = 10000,
	Default = 400,
	Color = Color3.fromRGB(255, 255, 255),
	Increment = 100,
	ValueName = '',
	Callback = function(p1140)
		_G.Strength = p1140
	end,
	Save = true,
	Flag = 'superstrengthvalue_toggle',
})
v1137:AddToggle({
	Name = 'Poison Grab',
	Default = false,
	Callback = function(p1141)
		_G.Poison_Grab = p1141
	end,
	Save = true,
	Flag = 'poisongrab_toggle',
})
v1137:AddToggle({
	Name = 'Burn Grab',
	Default = false,
	Callback = function(p1142)
		_G.Burn_Grab = p1142
	end,
	Save = true,
	Flag = 'burngrab_toggle',
})
v1137:AddToggle({
	Name = 'Death Grab',
	Default = false,
	Callback = function(p1143)
		_G.Death_Grab = p1143
	end,
	Save = true,
	Flag = 'deathgrab_toggle',
})
v1137:AddToggle({
	Name = 'Massless Grab',
	Default = false,
	Callback = function(p1144)
		_G.MasslessGrab = p1144
	end,
	Save = true,
	Flag = 'masslessgrab_toggle',
})

if _OuterUFO then
	v1137:AddToggle({
		Name = 'Radiactive Grab',
		Default = false,
		Callback = function(p1145)
			_G.Radiactive_Grab = p1145
		end,
		Save = true,
		Flag = 'radiactivegrab_toggle',
	})
end

v1137:AddToggle({
	Name = 'Noclip Grab',
	Default = false,
	Callback = function(p1146)
		_G.NoclipGrab = p1146
	end,
	Save = true,
	Flag = 'noclipgrab_toggle',
})

local u1147 = nil
local u1148 = 50

kickgrabtoggle = nil

v1138:AddToggle({
	Name = 'Perspective Grab',
	Default = false,
	Callback = function(p1149)
		_G.PerspectiveGrab = p1149
	end,
	Save = true,
	Flag = 'perspectivegrab_toggle',
})
v1138:AddSlider({
	Name = 'Speed',
	Min = 50,
	Max = 150,
	Default = 50,
	Color = Color3.fromRGB(255, 255, 255),
	Increment = 1,
	ValueName = '',
	Callback = function(p1150)
		u1148 = p1150
	end,
	Save = true,
	Flag = 'perspectivespeedvalue_toggle',
})

local v1151 = v657:AddSection({
	Name = 'Annoy Players',
})
local v1152 = v657:AddSection({
	Name = 'Kick All',
})
local v1153 = v657:AddSection({
	Name = 'Bring All',
})
local v1154 = v657:AddSection({
	Name = 'Whitelist',
})

freezecampart = Instance.new('Part', _Workspace)
freezecampart.Anchored = true
freezecampart.CanCollide = false
freezecampart.Transparency = 1
freezecampart.CanQuery = false
freezecampart.Size = Vector3.new()

function FreezeCam(p1155)
	freezecampart.CFrame = p1155
	workspace.CurrentCamera.CameraType = Enum.CameraType.Follow
	workspace.CurrentCamera.CameraSubject = freezecampart
end
function unFreezeCam()
	workspace.CurrentCamera.CameraSubject = _LocalPlayer.Character:FindFirstChildOfClass('Humanoid')
	workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
end

local u1156 = nil

u1156 = v1151:AddToggle({
	Name = 'Fire All',
	Default = false,
	Callback = function(p1157)
		_G.FireAllPlayers = p1157

		if p1157 then
			while _G.FireAllPlayers do
				if GetKey() ~= 'Xana' then
					u1156:Set(false)
					u33('Only for premium users! Buy premium in my discord server!')

					break
				end

				local v1158 = _Players
				local v1159, v1160, v1161 = pairs(v1158:GetPlayers())

				while true do
					local v1162

					v1161, v1162 = v1159(v1160, v1161)

					if v1161 == nil then
						break
					end
					if CheckPlayerAnnoyAll(v1162) then
						local _ = v1162.Character
						local _HumanoidRootPart14 = v1162.Character:FindFirstChild('HumanoidRootPart')
						local v1164

						if _HumanoidRootPart14:FindFirstChild('FirePlayerPart') and _HumanoidRootPart14.FirePlayerPart:FindFirstChild('CanBurn') then
							v1164 = _HumanoidRootPart14.FirePlayerPart.CanBurn.Value
						else
							v1164 = nil
						end
						if _HumanoidRootPart14 and v1162 and not (IsPlayerInsideSafeZone(v1162) or v1164) then
							u613(_HumanoidRootPart14)
							task.wait(0.015)
						end
					end
				end

				task.wait()
			end
		end
	end,
})
annoyalltoggle = v1151:AddToggle({
	Name = 'Ragdoll All',
	Default = false,
	Callback = function(p1165)
		_G.AnnoyAllPlayers = p1165

		if p1165 then
			while _G.AnnoyAllPlayers do
				if GetKey() ~= 'Xana' then
					annoyalltoggle:Set(false)
					u33('Only for premium users! Buy premium in my discord server!')

					break
				end

				local v1166 = _Players
				local v1167, v1168, v1169 = pairs(v1166:GetPlayers())

				while true do
					local v1170

					v1169, v1170 = v1167(v1168, v1169)

					if v1169 == nil then
						break
					end
					if CheckPlayerAnnoyAll(v1170) then
						local _Character11 = v1170.Character
						local _HumanoidRootPart15 = v1170.Character:FindFirstChild('HumanoidRootPart')
						local _Ragdolled = _Character11:FindFirstChildOfClass('Humanoid'):FindFirstChild('Ragdolled')

						if _HumanoidRootPart15 and _Ragdolled and not _Ragdolled.Value then
							u582(_HumanoidRootPart15)
							task.wait(0.015)
						end
					end
				end

				task.wait()
			end
		end
	end,
})
killalltoggle = v1151:AddToggle({
	Name = 'Kill All',
	Default = false,
	Callback = function(p1174)
		_G.KillAll = p1174

		if p1174 then
			if GetKey() ~= 'Xana' then
				_G.KillAll = false

				killalltoggle:Set(false)
				u33('Only for premium users! Buy premium in my discord server!')

				return
			end

			while _G.KillAll do
				ipos = GetPlayerCFrame()

				local v1175 = _Players
				local v1176, v1177, v1178 = pairs(v1175:GetPlayers())

				while true do
					local v1179

					v1178, v1179 = v1176(v1177, v1178)

					if v1178 == nil then
						break
					end
					if CheckPlayerKill(v1179) then
						local _HumanoidRootPart16 = v1179.Character:FindFirstChild('HumanoidRootPart')
						local _Humanoid7 = v1179.Character:FindFirstChild('Humanoid')

						if v1179 and _HumanoidRootPart16 and _Humanoid7 then
							for _ = 0, 50 do
								u406()
								SNOWship(_HumanoidRootPart16)

								if not (CheckPlayerKill(v1179) and _G.KillAll) or (CheckNetworkOwnerShipOnPlayer(v1179) or 500 < _HumanoidRootPart16.AssemblyLinearVelocity.Magnitude) then
									CreateSkyVelocity(_HumanoidRootPart16)
									_DestroyGrabLine:FireServer(_HumanoidRootPart16)

									break
								end

								task.wait()

								if _HumanoidRootPart16.Position.Y <= -12 then
									TeleportPlayer(CFrame.new(_HumanoidRootPart16.Position + Vector3.new(0, 5, -15)))
								else
									TeleportPlayer(CFrame.new(_HumanoidRootPart16.Position + Vector3.new(0, -10, -10)))
								end

								_Humanoid7.BreakJointsOnDeath = false

								_Humanoid7:ChangeState(Enum.HumanoidStateType.Dead)

								_Humanoid7.Jump = true
								_Humanoid7.Sit = false
							end
						end
					end
				end

				TeleportPlayer(ipos)
				task.wait(0.2)
			end

			u405()
			TeleportPlayer(ipos)
		end
	end,
})
kickalltoggle = v1152:AddToggle({
	Name = 'Kick All',
	Default = false,
	Callback = function(p1182)
		_G.KickAll = p1182

		if p1182 then
			if GetKey() ~= 'Xana' then
				_G.KickAll = false

				kickalltoggle:Set(false)
				u33('Only for premium users! Buy premium in my discord server!')

				return
			end

			while _G.KickAll do
				ipos = GetPlayerCFrame()

				local v1183 = _Players
				local v1184, v1185, v1186 = pairs(v1183:GetPlayers())

				while true do
					local v1187

					v1186, v1187 = v1184(v1185, v1186)

					if v1186 == nil then
						break
					end
					if CheckPlayerKick(v1187) then
						local _HumanoidRootPart17 = v1187.Character:FindFirstChild('HumanoidRootPart')

						if v1187 and _HumanoidRootPart17 then
							for _ = 0, 50 do
								u406()
								SNOWship(_HumanoidRootPart17)

								if not (CheckPlayerKick(v1187) and _G.KickAll) or (CheckNetworkOwnerShipOnPlayer(v1187) or 500 < _HumanoidRootPart17.AssemblyLinearVelocity.Magnitude) then
									CreateSkyVelocity(_HumanoidRootPart17)
									_DestroyGrabLine:FireServer(_HumanoidRootPart17)

									break
								end

								task.wait()

								if _HumanoidRootPart17.Position.Y <= -12 then
									TeleportPlayer(CFrame.new(_HumanoidRootPart17.Position + Vector3.new(0, 5, -15)))
								else
									TeleportPlayer(CFrame.new(_HumanoidRootPart17.Position + Vector3.new(0, -10, -10)))
								end
							end
						end
					end
				end

				TeleportPlayer(ipos)
				task.wait(0.2)
			end

			u405()
			TeleportPlayer(ipos)
		end
	end,
})
bringalltoggle = v1153:AddToggle({
	Name = 'Bring All',
	Default = false,
	Callback = function(p1189)
		_G.BringAll = p1189

		if p1189 then
			if GetKey() ~= 'Xana' then
				_G.BringAll = false

				bringalltoggle:Set(false)
				u33('Only for premium users! Buy premium in my discord server!')

				return
			end

			local v1190 = GetPlayerCFrame()
			local v1191 = CFrame.lookAt(_Workspace.CurrentCamera.CFrame.Position + Vector3.new(-15, 15, 0), v1190.Position)

			workspace.CurrentCamera.CFrame = v1191

			while _G.BringAll do
				FreezeCam(v1191)

				local v1192 = _Players
				local v1193, v1194, v1195 = pairs(v1192:GetPlayers())

				while true do
					local v1196

					v1195, v1196 = v1193(v1194, v1195)

					if v1195 == nil then
						break
					end
					if CheckPlayerBring(v1196) then
						local _HumanoidRootPart18 = v1196.Character:FindFirstChild('HumanoidRootPart')
						local _Humanoid8 = v1196.Character:FindFirstChildOfClass('Humanoid')
						local v1199

						if _Humanoid8 and _Humanoid8:FindFirstChild('Ragdolled') then
							v1199 = _Humanoid8.Ragdolled
						else
							v1199 = nil
						end
						if v1196 and _HumanoidRootPart18 and (_Humanoid8 and v1199) then
							for _ = 0, 50 do
								if not _G.BringAll then
									break
								end

								u406()
								SNOWshipOnce(_HumanoidRootPart18)

								if CheckNetworkOwnerShipOnPlayer(v1196) then
									if not v1199.Value and 10 < v1196:DistanceFromCharacter(v1190.Position) then
										_HumanoidRootPart18.CFrame = v1190
									end

									CreateBringBody(_HumanoidRootPart18, v1190)

									break
								end

								task.wait()

								if _HumanoidRootPart18.Position.Y <= -12 then
									TeleportPlayer(CFrame.new(_HumanoidRootPart18.Position + Vector3.new(0, 5, -15)))
								else
									TeleportPlayer(CFrame.new(_HumanoidRootPart18.Position + Vector3.new(0, -10, -10)))
								end
							end
						end
					end
				end

				TeleportPlayer(CFrame.new(527, 123, -376))
				task.wait()
			end

			unFreezeCam()
			u405()
			TeleportPlayer(v1190)
		end
	end,
})

v1152:AddDropdown({
	Name = 'Kick Type',
	Default = 'Go to the heaven!',
	Options = {
		'Go to the heaven!',
	},
	Callback = function(p1200)
		_G.KickAllType = p1200
	end,
	Save = true,
	Flag = 'kickalltype_dropdown',
})
v1154:AddToggle({
	Name = 'Whitelist Friends',
	Default = false,
	Callback = function(p1201)
		_G.WhitelistFriends3 = p1201
	end,
	Save = true,
	Flag = 'whitelistfriends3_toggle',
})

local v1202 = v648:AddSection({
	Name = 'Invulnerability',
})
local v1203 = v648:AddSection({
	Name = 'Counter-Attack',
})

v1202:AddToggle({
	Name = 'Anti-Grab',
	Default = false,
	Callback = function(p1204)
		_G.AntiGrab = p1204

		if p1204 and not u54(u28) then
			_Struggle:FireServer(_LocalPlayer)
		end
	end,
	Save = true,
	Flag = 'antigrab_toggle',
})
v1202:AddToggle({
	Name = 'Anti-Burn',
	Default = false,
	Callback = function(p1205)
		_G.AntiBurn = p1205
	end,
	Save = true,
	Flag = 'antiburn_toggle',
})
v1202:AddToggle({
	Name = 'Anti-Explosion',
	Default = false,
	Callback = function(p1206)
		_G.AntiExplosion = p1206
	end,
	Save = true,
	Flag = 'antiexplosion_toggle',
})
v1203:AddToggle({
	Name = 'Auto-Attacker',
	Default = false,
	Callback = function(p1207)
		_G.AutoAttacker = p1207
	end,
	Save = true,
	Flag = 'rinnegan_toggle',
})

counterdropdownselection = nil
counterdropdownselection = v1203:AddDropdown({
	Name = 'Counter Mode',
	Default = 'Repulsion',
	Options = {
		'Repulsion',
		'Freeze',
		'Death',
		'Kick',
	},
	Callback = function(p1208)
		if p1208 == 'Kick' and GetKey() ~= 'Xana' then
			counterdropdownselection:Set('Repulsion')
			u33('Only for premium users! Buy premium in my discord server!')
		else
			_G.CounterMode = p1208
		end
	end,
})
floppadialogo = Instance.new('ScreenGui')
Floppa = Instance.new('ImageLabel')
Bubble_chat = Instance.new('ImageLabel')
BubbleTextchat = Instance.new('TextLabel')
typingsoundeffect = Instance.new('Sound', _Workspace)
typingsoundeffect2 = Instance.new('Sound', _Workspace)
typingsoundeffect.SoundId = 'rbxassetid://' .. 9120299506
typingsoundeffect.Volume = 0.345
typingsoundeffect2.SoundId = 'rbxassetid://' .. 9118870964
typingsoundeffect2.Volume = 1
typingsoundeffect2.PlaybackSpeed = 1.5
floppadialogo.IgnoreGuiInset = true
floppadialogo.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
floppadialogo.Name = 'floppadialogo'
floppadialogo.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
floppadialogo.Parent = _PlayerGui
floppadialogo.DisplayOrder = 10
floppadialogo.Enabled = false
floppadialogo.ResetOnSpawn = false
Floppa.ZIndex = 0
Floppa.BorderSizePixel = 0
Floppa.BackgroundColor3 = Color3.new(1, 1, 1)
Floppa.Image = 'rbxassetid://15668608167'
Floppa.Size = UDim2.new(0.195372716, 0, 0.305668026, 0)
Floppa.BorderColor3 = Color3.new(0, 0, 0)
Floppa.Position = UDim2.new(0.0185752641, 0, 0.661330521, 0)
Floppa.Name = 'Floppa'
Floppa.Parent = floppadialogo
Bubble_chat.BorderSizePixel = 0
Bubble_chat.Transparency = 1
Bubble_chatBackgroundColor3 = Color3.new(1, 1, 1)
Bubble_chat.Image = 'rbxassetid://1395860348'
Bubble_chat.Size = UDim2.new(1.03356743, 0, 0.79455024, 0)
Bubble_chat.BorderColor3 = Color3.new(0, 0, 0)
Bubble_chat.BackgroundTransparency = 1
Bubble_chat.Position = UDim2.new(0.678329766, 0, -0.292054504, 0)
Bubble_chat.Name = 'Bubble chat'
Bubble_chat.Parent = Floppa
BubbleTextchat.TextWrapped = true
BubbleTextchat.BorderSizePixel = 0
BubbleTextchat.Transparency = 1
BubbleTextchat.TextScaled = true
BubbleTextchat.BackgroundColor3 = Color3.new(1, 1, 1)
BubbleTextchat.TextSize = 14
BubbleTextchat.Size = UDim2.new(0.634431362, 0, 0.268763244, 0)
BubbleTextchat.TextColor3 = Color3.new(0, 0, 0)
BubbleTextchat.BorderColor3 = Color3.new(0, 0, 0)
BubbleTextchat.Text = 'I saved you from falling on the void, my son!'
BubbleTextchat.Font = Enum.Font.SourceSans
BubbleTextchat.Position = UDim2.new(0.18163082, 0, 0.365639389, 0)
BubbleTextchat.BackgroundTransparency = 1
BubbleTextchat.TextTransparency = 0
BubbleTextchat.Parent = Bubble_chat
floppatweeninfo1 = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0)

local v1209 = _TweenService

floppatween = _TweenService.Create(v1209, Floppa, floppatweeninfo1, {
	Position = UDim2.new(0.0185752641, 0, 0.661330521, 0),
})
floppamessageoncooldown = false

function antivoidmesssage()
	if not floppamessageoncooldown then
		Floppa.Position = UDim2.new(0.0185752641, 0, 2, 0)
		floppadialogo.Enabled = true
		Floppa.Visible = true
		Bubble_chat.Visible = false
		BubbleTextchat.Visible = false
		floppamessageoncooldown = true

		floppatween:Play()
		floppatween.Completed:Connect(function(p1210)
			if p1210 == Enum.PlaybackState.Completed then
				Bubble_chat.Visible = true
				BubbleTextchat.Visible = true
				BubbleTextchat.Text = ''

				local v1211 = 'I saved you from falling on the void, my son!'

				for v1212 = 0, #v1211 do
					BubbleTextchat.Text = string.sub(v1211, 1, v1212)

					typingsoundeffect:Play()
					task.wait(0.05)
				end

				task.wait(1)
				typingsoundeffect2:Play()

				floppadialogo.Enabled = false
				floppamessageoncooldown = false
			end
		end)
	end
end

v1202:AddToggle({
	Name = 'Anti-Void',
	Default = false,
	Callback = function(p1213)
		_G.AntiVoid = p1213

		if p1213 then
			_Workspace.FallenPartsDestroyHeight = -1000

			while _G.AntiVoid do
				local v1214 = GetPlayerCharacter()

				if v1214 and v1214.HumanoidRootPart.Position.Y < -800 then
					v1214:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
					antivoidmesssage()
				end

				wait(0.1)
			end
		else
			_Workspace.FallenPartsDestroyHeight = -100
		end
	end,
	Save = true,
	Flag = 'antivoid_toggle',
})
v1202:AddToggle({
	Name = 'Anti-Lag',
	Default = false,
	Callback = function(p1215)
		anticreatelinelocalscript.Disabled = p1215
	end,
	Save = true,
	Flag = 'antilag_toggle',
})

antikicktoggle = v1202:AddToggle({
	Name = 'Anti-Kick',
	Default = false,
	Callback = function(p1216)
		_G.AntiKick = p1216

		if p1216 then
			while _G.AntiKick do
				GetKunai()
				task.wait()
			end
		end
	end,
	Save = true,
	Flag = 'antikick_toggle',
})
playersCharFolder = Instance.new('Model', _Workspace)
playersCharFolder.Name = 'Characters'
highlightesp = Instance.new('Highlight')
highlightesp.Enabled = true
ESP_Section1 = Esp_Tab:AddSection({
	Name = 'ESP Highlight',
})
ESP_Section2 = Esp_Tab:AddSection({
	Name = 'ESP Billboard',
})

ESP_Section1:AddToggle({
	Name = 'ESP (Highlight)',
	Default = false,
	Callback = function(p1217)
		_G.ESP_Hightlight = p1217

		if p1217 then
			highlightesp.Parent = playersCharFolder

			local function u1220(p1218)
				local v1219 = p1218 ~= _LocalPlayer and p1218.Character

				if v1219 then
					v1219.Parent = playersCharFolder
				end
			end
			local function v1226()
				local v1221 = _Players
				local v1222, v1223, v1224 = pairs(v1221:GetPlayers())

				while true do
					local v1225

					v1224, v1225 = v1222(v1223, v1224)

					if v1224 == nil then
						break
					end

					u1220(v1225)
				end
			end

			v1226()

			while _G.ESP_Hightlight do
				v1226()
				wait(2)
			end

			highlightesp.Parent = nil
		end
	end,
})
ESP_Section1:AddColorpicker({
	Name = 'Fill Color',
	Default = Color3.fromRGB(255, 0, 0),
	Callback = function(p1227)
		highlightesp.FillColor = p1227
	end,
	Save = true,
	Flag = 'espHighlightFillcolor_picker',
})
ESP_Section1:AddSlider({
	Name = 'Fill Transparency',
	Min = 0,
	Max = 1,
	Default = 0.5,
	Color = Color3.fromRGB(255, 255, 255),
	Increment = 0.1,
	ValueName = 'Fill color transparency:',
	Callback = function(p1228)
		highlightesp.FillTransparency = p1228
	end,
	Save = true,
	Flag = 'espHighlightFillTransparency_slider',
})
ESP_Section1:AddColorpicker({
	Name = 'Outline Color',
	Default = Color3.fromRGB(255, 0, 0),
	Callback = function(p1229)
		highlightesp.OutlineColor = p1229
	end,
	Save = true,
	Flag = 'espHighlightOutlinecolor_picker',
})
ESP_Section1:AddSlider({
	Name = 'Outline Transparency',
	Min = 0,
	Max = 1,
	Default = 0.5,
	Color = Color3.fromRGB(255, 255, 255),
	Increment = 0.1,
	ValueName = 'Outline color transparency:',
	Callback = function(p1230)
		highlightesp.OutlineTransparency = p1230
	end,
	Save = true,
	Flag = 'espHighlightOutlineTransparency_slider',
})
ESP_Section1:AddDropdown({
	Name = 'Highlight Mode',
	Default = 'AlwaysOnTop',
	Options = {
		'AlwaysOnTop',
		'Occluded',
	},
	Callback = function(p1231)
		highlightesp.DepthMode = Enum.HighlightDepthMode[p1231]
	end,
	Save = true,
	Flag = 'espHighlightMode_dropdown',
})

function ESPIconCreation()
	local _BillboardGui3 = Instance.new('BillboardGui')
	local _ImageButton = Instance.new('ImageButton')
	local _UICorner = Instance.new('UICorner')
	local _TextLabel3 = Instance.new('TextLabel')
	local _UITextSizeConstraint3 = Instance.new('UITextSizeConstraint')
	local _UIAspectRatioConstraint2 = Instance.new('UIAspectRatioConstraint')

	_BillboardGui3.Name = 'ESP'
	_BillboardGui3.Parent = nil
	_BillboardGui3.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	_BillboardGui3.Active = true
	_BillboardGui3.Adornee = nil
	_BillboardGui3.AlwaysOnTop = true
	_BillboardGui3.ExtentsOffset = Vector3.new(0, 10, 0)
	_BillboardGui3.Size = UDim2.new(3, 50, 3, 45)
	_ImageButton.Name = 'UserImage'
	_ImageButton.Parent = _BillboardGui3
	_ImageButton.AnchorPoint = Vector2.new(0.5, 0.5)
	_ImageButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	_ImageButton.BackgroundTransparency = 1
	_ImageButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	_ImageButton.BorderSizePixel = 0
	_ImageButton.Position = UDim2.new(0.5, 0, 0.300000012, 0)
	_ImageButton.Size = UDim2.new(0.5, 5, 0.5, 5)
	_ImageButton.Image = ''
	_UICorner.CornerRadius = UDim.new(2, 0)
	_UICorner.Parent = _ImageButton
	_TextLabel3.Name = 'Username'
	_TextLabel3.Parent = _BillboardGui3
	_TextLabel3.AnchorPoint = Vector2.new(0.5, 0.5)
	_TextLabel3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	_TextLabel3.BackgroundTransparency = 1
	_TextLabel3.BorderColor3 = Color3.fromRGB(0, 0, 0)
	_TextLabel3.BorderSizePixel = 0
	_TextLabel3.Position = UDim2.new(0.5, 0, 0.75999999, 0)
	_TextLabel3.Size = UDim2.new(1, 5, 0.340000004, 5)
	_TextLabel3.Font = Enum.Font.SourceSans
	_TextLabel3.Text = ''
	_TextLabel3.TextColor3 = Color3.fromRGB(255, 255, 255)
	_TextLabel3.TextScaled = true
	_TextLabel3.TextSize = 35
	_TextLabel3.TextStrokeTransparency = 0
	_TextLabel3.TextWrapped = true
	_UITextSizeConstraint3.Parent = _TextLabel3
	_UITextSizeConstraint3.MaxTextSize = 35
	_UITextSizeConstraint3.MinTextSize = 15
	_UIAspectRatioConstraint2.Parent = _BillboardGui3
	_UIAspectRatioConstraint2.AspectRatio = 1.043

	return _BillboardGui3
end

ESPIconCreation = ESPIconCreation()

function CreateIconOnPlayer(p1238)
	if p1238.Character then
		local _Character12 = p1238.Character
		local _Head7 = _Character12:WaitForChild('Head', 1)

		if not _Character12:FindFirstChild('ESP') and _Head7 then
			local u1241 = ESPIconCreation:Clone()

			u1241.Parent = _Character12
			u1241.Adornee = _Head7
			u1241.Username.Text = p1238.Name
			u1241.UserImage.Image = 'https://www.roblox.com/headshot-thumbnail/image?userId=' .. p1238.UserId .. '&width=420&height=420&format=png'

			task.spawn(function()
				while _Character12.Parent and _G.ESP_Icon do
					task.wait(0.25)
				end

				u1241:Destroy()
			end)
		end
	end
end

ESP_Section2:AddToggle({
	Name = 'ESP (Icon)',
	Default = false,
	Callback = function(p1242)
		_G.ESP_Icon = p1242

		if p1242 then
			local u1243 = {}

			local function v1248()
				local v1244, v1245, v1246 = pairs(u1243)

				while true do
					local v1247

					v1246, v1247 = v1244(v1245, v1246)

					if v1246 == nil then
						break
					end
					if typeof(v1247) == 'RBXScriptConnection' then
						v1247:Disconnect()
						print('Desconectado!')
					end
				end

				table.clear(u1243)
			end
			local function u1250(p1249)
				if p1249 ~= _LocalPlayer and (p1249.Character or p1249.CharacterAdded:Wait()) then
					CreateIconOnPlayer(p1249)

					u1243[#u1243 + 1] = p1249.CharacterAdded:Connect(function(_)
						CreateIconOnPlayer(p1249)
					end)
				end
			end
			local function v1256()
				local v1251 = _Players
				local v1252, v1253, v1254 = pairs(v1251:GetPlayers())

				while true do
					local v1255

					v1254, v1255 = v1252(v1253, v1254)

					if v1254 == nil then
						break
					end

					u1250(v1255)
				end
			end

			local v1258 = _Players.PlayerAdded:Connect(function(p1257)
				u1250(p1257)
			end)

			v1256()

			while _G.ESP_Icon do
				wait(0.1)
			end

			v1258:Disconnect()
			v1248()
		end
	end,
})

MapTeleport_Section = v651:AddSection({
	Name = 'Place TP',
})
PlayerTeleport_Section = v651:AddSection({
	Name = 'Player TP',
})
placeLocations = {
	['Green House'] = CFrame.new(-352, 99, 354),
	['Green Safe-House'] = CFrame.new(-584, -6, 93),
	['Chinese Safe-House'] = CFrame.new(579, 124, -94),
	['Farm House'] = CFrame.new(-234, 83, -324),
	Spawn = CFrame.new(4, -7, -3),
	['Blue Safe-House'] = CFrame.new(538, 96, -372),
	['Secret Big Cave'] = CFrame.new(17, -7, 539),
	['Secret Train Cave'] = CFrame.new(500, 62, -307),
	['Mine Cave'] = CFrame.new(-254, -7, 518),
	['Witch Safe-House'] = CFrame.new(296, -4, 494),
	['Red Safe-House'] = CFrame.new(-516, -6, -162),
}

MapTeleport_Section:AddDropdown({
	Name = 'Place to Teleport',
	Default = 'Green House',
	Options = {
		'Green House',
		'Chinese Safe-House',
		'Spawn',
		'Blue Safe-House',
		'Secret Big Cave',
		'Secret Train Cave',
		'Mine Cave',
		'Farm House',
		'Witch Safe-House',
		'Green Safe-House',
		'Red Safe-House',
	},
	Callback = function(p1259)
		_G.PlaceToTeleport = p1259
	end,
})
MapTeleport_Section:AddButton({
	Name = 'Teleport',
	Callback = function()
		TeleportPlayer(placeLocations[_G.PlaceToTeleport])
	end,
})

PlayerToTeleport = PlayerTeleport_Section:AddDropdown({
	Name = 'Select Player',
	Default = '',
	Options = {
		'',
	},
	Callback = function(p1260)
		local v1261 = string.split(p1260, ' ')

		_G.PlayerToTeleport = v1261[1]
	end,
})

function teleportplayerfunctionoffset(p1262, p1263, p1264, p1265)
	local v1266 = nil

	if _G.PlayerToTeleportDirection ~= 'Behind' then
		if _G.PlayerToTeleportDirection ~= 'Front' then
			if _G.PlayerToTeleportDirection ~= 'Right' then
				if _G.PlayerToTeleportDirection ~= 'Left' then
					if _G.PlayerToTeleportDirection == 'Rotate' and (p1263 and p1264) then
						local v1267 = 0

						while _G.PlayerToTeleportDirection == 'Rotate' and _G.LoopPlayerTP and (p1264:IsDescendantOf(_Workspace) and p1265 == _G.PlayerToTeleport) do
							v1267 = v1267 + 0.1
							v1266 = CFrame.new(p1263.Position + Vector3.new(math.clamp(math.cos(v1267), -1, 1), 0, math.clamp(math.sin(v1267), -1, 1)) * (TeleportPlayerOffset + 1), p1263.Position)

							TeleportPlayer(v1266)
							task.wait()
						end
					end
				else
					v1266 = CFrame.new(p1262.Position - p1262.rightVector * (TeleportPlayerOffset + 1))
				end
			else
				v1266 = CFrame.new(p1262.Position + p1262.rightVector * (TeleportPlayerOffset + 1))
			end
		else
			v1266 = CFrame.new(p1262.Position + p1262.lookVector * (TeleportPlayerOffset + 1))
		end
	else
		v1266 = CFrame.new(p1262.Position - p1262.lookVector * (TeleportPlayerOffset + 1))
	end
	if _G.PlayerToTeleportDirection ~= 'Rotate' then
		TeleportPlayer(v1266)
	end
end

PlayerTeleport_Section:AddButton({
	Name = 'Teleport',
	Callback = function()
		local v1268 = _Players:FindFirstChild(_G.PlayerToTeleport)
		local v1269 = GetPlayerRoot()
		local v1270 = v1268 and (v1268.Character and v1269) and v1268.Character:FindFirstChild('HumanoidRootPart')

		if v1270 then
			teleportplayerfunctionoffset(v1270.CFrame, v1269)
		end
	end,
})

PlayerLoopTeleport = PlayerTeleport_Section:AddToggle({
	Name = 'Loop Teleport',
	Default = false,
	Callback = function(p1271)
		_G.LoopPlayerTP = p1271

		if p1271 then
			while _G.LoopPlayerTP do
				local v1272 = _Players:FindFirstChild(_G.PlayerToTeleport)

				if v1272 and v1272.Character and not IsPlayerKickingWithBlobman() then
					local _Character13 = v1272.Character
					local _HumanoidRootPart19 = _Character13:FindFirstChild('HumanoidRootPart')

					if _HumanoidRootPart19 then
						teleportplayerfunctionoffset(_HumanoidRootPart19.CFrame, _HumanoidRootPart19, _Character13, v1272.Name)
					end
				elseif not v1272 then
					if PlayerLoopTeleport then
						PlayerLoopTeleport:Set(false)
					end

					_G.LoopPlayerTP = false
				end

				task.wait()
			end
		end
	end,
})
PlayerLockCamera = PlayerTeleport_Section:AddToggle({
	Name = 'Lock Camera',
	Default = false,
	Callback = function(p1275)
		_G.LockCameraOnPlayer = p1275

		if p1275 then
			local u1276 = nil
			local u1277 = nil
			local u1278 = nil
			local u1279 = nil
			local u1280 = nil

			u1280 = _RunService.RenderStepped:Connect(function()
				u1276 = _Players:FindFirstChild(_G.PlayerToTeleport)
				u1279 = _Workspace.CurrentCamera

				if not _G.LockCameraOnPlayer then
					u1280:Disconnect()
				end
				if u1276 and u1276.Character and u1279 then
					u1278 = u1276.Character
					u1277 = u1278:FindFirstChild('HumanoidRootPart')

					if u1277 then
						u1279.CFrame = CFrame.lookAt(u1279.CFrame.Position, u1277.CFrame.Position + Vector3.new(0, 1, 0))
					end
				elseif not u1276 then
					if PlayerLockCamera then
						PlayerLockCamera:Set(false)
					end

					_G.LockCameraOnPlayer = false
				end

				task.wait()
			end)
		end
	end,
})
PlayerViewCamera = PlayerTeleport_Section:AddToggle({
	Name = 'View',
	Default = false,
	Callback = function(p1281)
		_G.ViewCameraOnPlayer = p1281

		if p1281 then
			local _CurrentCamera3 = _Workspace.CurrentCamera
			local _CameraSubject = _CurrentCamera3.CameraSubject

			while _G.ViewCameraOnPlayer do
				local v1284 = _Players:FindFirstChild(_G.PlayerToTeleport)

				if v1284 and v1284.Character and _CurrentCamera3 then
					local _Humanoid9 = v1284.Character:FindFirstChildOfClass('Humanoid')

					if _Humanoid9 then
						_CurrentCamera3.CameraSubject = _Humanoid9
					end
				elseif not v1284 then
					if PlayerViewCamera then
						PlayerViewCamera:Set(false)
					end

					_G.ViewCameraOnPlayer = false
				end

				wait()
			end

			_CurrentCamera3.CameraSubject = _CameraSubject
		end
	end,
})

PlayerTeleport_Section:AddSlider({
	Name = 'Offset',
	Min = 1,
	Max = 20,
	Default = 1,
	Color = Color3.fromRGB(255, 255, 255),
	Increment = 1,
	ValueName = 'Teleport Offset',
	Callback = function(p1286)
		TeleportPlayerOffset = p1286
	end,
	Save = true,
	Flag = 'speed_slider',
})
PlayerTeleport_Section:AddDropdown({
	Name = 'Behavior',
	Default = 'Behind',
	Options = {
		'Behind',
		'Left',
		'Right',
		'Front',
		'Rotate',
	},
	Callback = function(p1287)
		_G.PlayerToTeleportDirection = p1287
	end,
})

WS_Section = v649:AddSection({
	Name = 'Walkspeed',
})
JP_Section = v649:AddSection({
	Name = 'Infinite Power Jump',
})
NC_Section = v649:AddSection({
	Name = 'Noclip',
})

WS_Section:AddToggle({
	Name = 'Walkspeed',
	Default = false,
	Callback = function(p1288)
		_G.SuperSpeed = p1288
	end,
	Save = true,
	Flag = 'walkspeed_toggle',
})
WS_Section:AddSlider({
	Name = 'Speed',
	Min = 0.1,
	Max = 5,
	Default = 0.1,
	Color = Color3.fromRGB(255, 255, 255),
	Increment = 0.01,
	ValueName = '',
	Callback = function(p1289)
		Multiplier = p1289
	end,
	Save = true,
	Flag = 'speed_slider',
})
JP_Section:AddToggle({
	Name = 'Infinite Jump',
	Default = false,
	Callback = function(p1290)
		_G.InfiniteJump = p1290
	end,
	Save = true,
	Flag = 'infinitejump_toggle',
})
JP_Section:AddSlider({
	Name = 'Jump Power',
	Min = 24,
	Max = 1000,
	Default = 24,
	Color = Color3.fromRGB(255, 255, 255),
	Increment = 10,
	ValueName = '',
	Callback = function(p1291)
		_G.InfiniteJumpPower = p1291
		_LocalPlayer.Character:FindFirstChildOfClass('Humanoid').JumpPower = p1291
	end,
	Save = true,
	Flag = 'jumppower_slider',
})
NC_Section:AddToggle({
	Name = 'Noclip',
	Default = false,
	Callback = function(p1292)
		_G.NoclipToggle = p1292

		if p1292 then
			u406()
		else
			u405()
		end
	end,
	Save = true,
	Flag = 'noclip_toggle',
})

local u1293 = {
	Color3.new(1, 0, 0),
	Color3.new(1, 0, 0),
	Color3.new(1, 0, 0),
	Color3.new(1, 0, 0),
	Color3.new(1, 0, 0),
	Color3.new(1, 0, 0),
	Color3.new(1, 0, 0),
	Color3.new(1, 0, 0),
	Color3.new(1, 0, 0),
	Color3.new(1, 0, 0),
}
local v1294 = v652:AddSection({
	Name = 'Change your entire line color',
})
local v1295 = v652:AddSection({
	Name = 'Line Effects',
})
local v1296 = v652:AddSection({
	Name = 'Stress Server',
})

LagServerToggle = nil
LagServerToggle = v1296:AddToggle({
	Name = 'Lag Server',
	Default = false,
	Callback = function(p1297)
		laggg = p1297

		while laggg do
			if GetKey() ~= 'Xana' then
				LagServerToggle:Set(false)
				u33('Only for premium users! Buy premium in my discord server!')

				break
			end

			for _ = 0, Lag_Intensity do
				local v1298, v1299, v1300 = ipairs(game:GetService('Players'):GetPlayers())

				while true do
					local v1301

					v1300, v1301 = v1298(v1299, v1300)

					if v1300 == nil then
						break
					end
					if v1301.Character.Torso ~= nil then
						_CreateGrabLine:FireServer(v1301.Character.Torso, v1301.Character.Torso.CFrame)
					end
				end
			end

			wait(1)
		end
	end,
})

v1296:AddSlider({
	Name = 'Lag Intensity',
	Min = 1,
	Max = 400,
	Default = 150,
	Color = Color3.fromRGB(255, 255, 255),
	Increment = 1,
	ValueName = 'This can have you kicked or kick someone in the server!',
	Save = true,
	Flag = 'Lag-Intensity',
	Callback = function(p1302)
		Lag_Intensity = p1302
	end,
})
v1294:AddColorpicker({
	Name = 'Choose the color',
	Default = Color3.fromRGB(255, 0, 0),
	Callback = function(p1303)
		_G.LineColorChangeValue = p1303
	end,
	Save = true,
	Flag = 'changelinecolor_picker',
})
v1294:AddButton({
	Name = 'Apply Colors',
	Callback = function()
		local v1304, v1305, v1306 = pairs(u1293)

		while true do
			local v1307

			v1306, v1307 = v1304(v1305, v1306)

			if v1306 == nil then
				break
			end
			if v1306 == 1 then
				u1293[v1306] = ColorSequence.new(_G.LineColorChangeValue, 1)
			else
				u1293[v1306] = Color3.new(_G.LineColorChangeValue.R / 255, _G.LineColorChangeValue.G / 255, _G.LineColorChangeValue.B / 255)
			end
		end

		_UpdateLineColorsEvent:FireServer(unpack(u1293))
	end,
})
v1295:AddToggle({
	Name = 'Crazy Line (Soft Lag)',
	Default = false,
	Callback = function(p1308)
		if p1308 then
			_G.CrazyLine = p1308

			while _G.CrazyLine do
				local v1309 = _Players
				local v1310, v1311, v1312 = pairs(v1309:GetPlayers())

				while true do
					local v1313

					v1312, v1313 = v1310(v1311, v1312)

					if v1312 == nil then
						break
					end
					if v1313 and v1313 ~= _LocalPlayer and v1313.Character and v1313.Character:FindFirstChild('Torso') then
						_CreateGrabLine:FireServer(v1313.Character:FindFirstChild('Torso'), CFrame.new(0.12640380859375, 0.9606337547302246, -0.5000009536743164, 0.9985212683677673, 0, -0.05436277016997337, -6.4805472099749295e-9, 1, -1.1903301100346653e-7, 0.05436277016997337, 5.9604644775390625e-8, 0.9985212683677673))
					end

					task.wait()
				end
			end
		else
			_G.CrazyLine = p1308
		end
	end,
	Save = true,
	Flag = 'softlagline_toggle',
})
v1295:AddToggle({
	Name = 'Invisible Line',
	Default = false,
	Callback = function(p1314)
		if p1314 then
			_G.InvisibleLine = p1314
		else
			_G.InvisibleLine = p1314
		end
	end,
	Save = true,
	Flag = 'invisLine_toggle',
})
_ContextActionService:BindAction('Godmode', GodModeFTry, false, Enum.KeyCode.T)
v1295:AddParagraph('Note!', "You can't see the effects line, but others player can see it. And Invisible Line won't work if Crazy Line is Enabled")

gui2 = Instance.new('ScreenGui')
gui2.ResetOnSpawn = false
gui2.Name = 'CAG2'

if _UserInputService.TouchEnabled then
	gui2.Parent = _LocalPlayer.PlayerGui
end

imageButtonTeleport = Instance.new('ImageButton')
imageButtonTeleport.Size = UDim2.new(0, 70, 0, 70)
imageButtonTeleport.Position = UDim2.new(1, -267, 1, -90)
imageButtonTeleport.Image = 'rbxassetid://97166444'
imageButtonTeleport.BackgroundTransparency = 1
imageButtonTeleport.ImageTransparency = 0.2
imageButtonTeleport.ImageColor3 = Color3.fromRGB(142, 142, 142)
imageButtonTeleport.Parent = gui2
imageTLabel = Instance.new('ImageLabel')
imageTLabel.Size = UDim2.new(1, 0, 1, 0)
imageTLabel.Image = 'rbxassetid://6723742952'
imageTLabel.BackgroundTransparency = 1
imageTLabel.Parent = imageButtonTeleport
imageButtonControl = Instance.new('ImageButton')
imageButtonControl.Size = UDim2.new(0, 50, 0, 50)
imageButtonControl.Position = UDim2.new(1, -378, 1, -80)
imageButtonControl.Image = 'rbxassetid://97166444'
imageButtonControl.BackgroundTransparency = 1
imageButtonControl.ImageTransparency = 0.2
imageButtonControl.ImageColor3 = Color3.fromRGB(142, 142, 142)
imageButtonControl.Parent = gui2
imageCLabel = Instance.new('ImageLabel')
imageCLabel.Size = UDim2.new(1, 0, 1, 0)
imageCLabel.Image = 'rbxassetid://14436167187'
imageCLabel.BackgroundTransparency = 1
imageCLabel.Parent = imageButtonControl
imageButtonAnchor = Instance.new('ImageButton')
imageButtonAnchor.Size = UDim2.new(0, 50, 0, 50)
imageButtonAnchor.Position = UDim2.new(1, -325, 1, -80)
imageButtonAnchor.Image = 'rbxassetid://97166444'
imageButtonAnchor.BackgroundTransparency = 1
imageButtonAnchor.ImageTransparency = 0.2
imageButtonAnchor.ImageColor3 = Color3.fromRGB(142, 142, 142)
imageButtonAnchor.Parent = gui2
imageKLabelDe = Instance.new('ImageLabel')
imageKLabelDe.Size = UDim2.new(1, 0, 1, 0)
imageKLabelDe.Image = 'rbxassetid://3040311268'
imageKLabelDe.BackgroundTransparency = 1
imageKLabelDe.Parent = imageButtonAnchor

imageButtonAnchor.InputBegan:Connect(function(p1315, p1316)
	if not p1316 and (u712.TouchEnabled and p1315.UserInputType == Enum.UserInputType.Touch) then
		anchorfunc()
	end
end)
imageButtonTeleport.InputBegan:Connect(function(p1317, p1318)
	if not p1318 and (u712.TouchEnabled and p1317.UserInputType == Enum.UserInputType.Touch) then
		teleportfunc()
	end
end)
imageButtonControl.InputBegan:Connect(function(p1319, p1320)
	if not p1320 and (u712.TouchEnabled and p1319.UserInputType == Enum.UserInputType.Touch) then
		controlBind('Control(C)', Enum.UserInputState.Begin)
	end
end)

local v1321 = v654:AddSection({
	Name = 'Teleport',
})
local v1322 = v654:AddSection({
	Name = 'Spawn Toy',
})
local v1323 = v654:AddSection({
	Name = 'Anchor Objects',
})
local v1324 = v654:AddSection({
	Name = 'Compile Objects',
})
local v1325 = v654:AddSection({
	Name = 'Control Player/NPC',
})

v1323:AddToggle({
	Name = 'Anchor (K)',
	Default = false,
	Callback = function(p1326)
		imageButtonAnchor.Visible = p1326
		imageButtonAnchor.Active = p1326

		if p1326 then
			_ContextActionService:BindAction('AnchorK', anchorobject, false, Enum.KeyCode.K)
		else
			_ContextActionService:UnbindAction('AnchorK')
		end
	end,
	Save = true,
	Flag = 'anchorbind_toggle',
})
v1323:AddButton({
	Name = 'Unanchor All',
	Callback = function(_)
		local v1327, v1328, v1329 = pairs(AnchoredObjects)

		while true do
			local v1330

			v1329, v1330 = v1327(v1328, v1329)

			if v1329 == nil then
				break
			end
			if typeof(v1330.PartAnchored) == 'Instance' then
				unAnchorObject(v1330.PartAnchored)
			end
		end
	end,
})
v1324:AddButton({
	Name = 'Compile New Group',
	Callback = function()
		u350()
	end,
})

CompileGroups_Dropdown = v1324:AddDropdown({
	Name = 'Groups',
	Default = '',
	Options = {
		'',
	},
	Callback = function(p1331)
		_G.CompileGroupSelected = p1331
	end,
})

v1324:AddButton({
	Name = 'Delete Group',
	Callback = function()
		RemoveGroupCompileFromName(_G.CompileGroupSelected)
		updateCompileGroupsDropdown(CompileGroups_Dropdown)
	end,
})
v1321:AddToggle({
	Name = 'Teleport (Z)',
	Default = false,
	Callback = function(p1332)
		imageButtonTeleport.Visible = p1332
		imageButtonTeleport.Active = p1332

		if p1332 then
			_ContextActionService:BindAction('Teleport(Z)', u103, false, Enum.KeyCode.Z)
		else
			_ContextActionService:UnbindAction('Teleport(Z)')
		end
	end,
	Save = true,
	Flag = 'teleportbind_toggle',
})
v1325:AddToggle({
	Name = 'Control (C)',
	Default = false,
	Callback = function(p1333)
		imageButtonControl.Visible = p1333
		imageButtonControl.Active = p1333

		if p1333 then
			_ContextActionService:BindAction('Control(C)', controlBind, false, Enum.KeyCode.C)
		else
			_ContextActionService:UnbindAction('Control(C)')
		end
	end,
	Save = true,
	Flag = 'controlbind_toggle',
})
v1322:AddDropdown({
	Name = 'Select Toy',
	Default = 'Pallet',
	Options = {
		'Pallet',
		'BombMissile',
	},
	Callback = function(p1334)
		if p1334 == 'Pallet' then
			_G.SelectedToy = 'PalletLightBrown'
		else
			_G.SelectedToy = p1334
		end
	end,
	Save = true,
	Flag = 'selecttoy_dropdown',
})
v1322:AddToggle({
	Name = 'Spawn Toy (TAB)',
	Default = false,
	Callback = function(p1335)
		if p1335 then
			_ContextActionService:BindAction('Spawn Toy (TAB)', u96, false, Enum.KeyCode.Tab)
			_ContextActionService:SetImage('Spawn Toy (TAB)', 'rbxassetid://6723742952')
			_ContextActionService:SetPosition('Spawn Toy (TAB)', UDim2.new(1, -367, 1, -90))

			local _SpawnToyTAB = _ContextActionService:GetButton('Spawn Toy (TAB)')

			if _SpawnToyTAB then
				_SpawnToyTAB.Size = UDim2.new(0, 70, 0, 70)
			end
		else
			_ContextActionService:UnbindAction('Spawn Toy (TAB)')
		end
	end,
	Save = true,
	Flag = 'spawntoy_toggle',
})

local v1337 = v659:AddSection({
	Name = 'Whitelist',
})
local u1339 = v1337:AddDropdown({
	Name = 'Select Player',
	Default = '',
	Options = {
		'',
	},
	Callback = function(p1338)
		if p1338 then
			_G.PlayerToAddWhitelist = string.split(p1338, ' ')[1]
		end
	end,
})
local u1340 = nil

v1337:AddButton({
	Name = 'Add',
	Callback = function()
		if not u105(_G.PlayerToAddWhitelist) then
			table.insert(u404, _G.PlayerToAddWhitelist)
			u79(u1340, u404)
		end
	end,
})

u1340 = v1337:AddDropdown({
	Name = 'Players in Whitelist',
	Default = '',
	Options = {
		'',
	},
	Callback = function(p1341)
		_G.PlayerToRemoveWhitelist = p1341
	end,
})

v1337:AddButton({
	Name = 'Remove',
	Callback = function()
		local v1342, v1343, v1344 = pairs(u404)

		while true do
			local v1345

			v1344, v1345 = v1342(v1343, v1344)

			if v1344 == nil then
				break
			end
			if v1345 == _G.PlayerToRemoveWhitelist then
				u404[v1344] = nil
			end
		end

		u79(u1340, u404)
	end,
})

local v1346 = v659:AddSection({
	Name = 'Blobman Loopkick',
})
local v1347 = v659:AddSection({
	Name = 'Perspective',
})

v659:AddSection({
	Name = 'Anchor Objects/Compiled Groups',
}):AddToggle({
	Name = 'Auto Ownership',
	Default = false,
	Callback = function(p1348)
		_G.AutoOwnershipAnchor = p1348

		if p1348 then
			while _G.AutoOwnershipAnchor do
				autosetownership()
				task.wait(0.1)
			end
		end
	end,
	Save = true,
	Flag = 'autoownershipanchorconfig_toggle',
})
v1346:AddToggle({
	Name = 'Heavy Blobman',
	Default = false,
	Callback = function(p1349)
		_G.RockBlobman = p1349
	end,
	Save = true,
	Flag = 'heavyblobmanconfig_toggle',
})

_G.PerspectiveEffectsAllow = true

v1347:AddToggle({
	Name = 'Teleport to Camera Position',
	Default = true,
	Callback = function(p1350)
		_G.PerspectiveTeleportToCameraPos = p1350
	end,
	Save = true,
	Flag = 'perspectiveconfig1_toggle',
})
v1347:AddDropdown({
	Name = 'Camera Effect',
	Default = 'Default',
	Options = {
		'Default',
		'Old TV',
	},
	Callback = function(p1351)
		if p1351 == 'Default' then
			ImageLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
			ImageLabel.BorderSizePixel = 0
			ImageLabel.Size = UDim2.new(1, 0, 1, 0)
			ImageLabel.Image = 'rbxassetid://5945121255'
			ImageLabel.ImageColor3 = Color3.new(0, 0, 0)
			imagestransparencyeffect = 0.45
			saturationvalue = -0.6
			perspectiveON_effect1 = _TweenService:Create(ImageLabel, t1p, {ImageTransparency = imagestransparencyeffect})
			perspectiveON_effect2 = _TweenService:Create(PerspectiveSaturation, t1p, {Saturation = saturationvalue})
		elseif p1351 == 'Old TV' then
			ImageLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
			ImageLabel.BorderSizePixel = 0
			ImageLabel.Size = UDim2.new(1, 0, 1, 0)
			ImageLabel.Image = 'rbxassetid://8586979842'
			ImageLabel.ImageColor3 = Color3.fromRGB(255, 255, 255)
			imagestransparencyeffect = 0.7
			saturationvalue = -0.3
			perspectiveON_effect1 = _TweenService:Create(ImageLabel, t1p, {ImageTransparency = imagestransparencyeffect})
			perspectiveON_effect2 = _TweenService:Create(PerspectiveSaturation, t1p, {Saturation = saturationvalue})
		end
	end,
	Save = true,
	Flag = 'perspectivevisualeffect_dropdown',
})

local v1352 = v655:AddSection({
	Name = 'Loop Players',
})
local v1353 = v655:AddSection({
	Name = 'Players in Loop',
})
local v1354 = v655:AddSection({
	Name = 'Loop Kill Functions',
})
local v1355 = v655:AddSection({
	Name = 'Loop Kick (Blobman)',
})
local u1357 = v1352:AddDropdown({
	Name = 'Select Player',
	Default = '',
	Options = {
		'',
	},
	Callback = function(p1356)
		if p1356 then
			_G.PlayerToAdd = string.split(p1356, ' ')[1]
		end
	end,
})
local u1358 = nil
local u1359 = 3

v1352:AddButton({
	Name = 'Add',
	Callback = function()
		if not table.find(u70, _G.PlayerToAdd) then
			if u1359 <= #u70 then
				u33('You reached the max ammount of players in loop, buy premium to unlock more space!')
			else
				table.insert(u70, _G.PlayerToAdd)
				u79(u1358, u70)
			end
		end
	end,
})

local u1361 = v1353:AddDropdown({
	Name = 'Players in Loop',
	Default = '',
	Options = {
		'',
	},
	Callback = function(p1360)
		_G.PlayerToRemove = p1360
	end,
})

v1353:AddButton({
	Name = 'Remove',
	Callback = function()
		local v1362, v1363, v1364 = pairs(u70)

		while true do
			local v1365

			v1364, v1365 = v1362(v1363, v1364)

			if v1364 == nil then
				break
			end
			if v1365 == _G.PlayerToRemove then
				u70[v1364] = nil
			end
		end

		u79(u1361, u70)
	end,
})

local function u1372()
	if typeof(_G.LastBlobmanWasSeat) ~= 'Instance' or not _G.LastBlobmanWasSeat.Parent then
		_G.LastBlobmanWasSeat = u644()
	else
		local v1366 = GetPlayerCharacter()
		local _VehicleSeat = _G.LastBlobmanWasSeat:FindFirstChild('VehicleSeat')

		if not (_VehicleSeat and _VehicleSeat:FindFirstChild('ProximityPrompt')) then
			DeleteToyRE:FireServer(_G.LastBlobmanWasSeat)

			return
		end

		local _ProximityPrompt = _VehicleSeat.ProximityPrompt
		local _Weld = _VehicleSeat:FindFirstChildOfClass('Weld')

		if _LocalPlayer:DistanceFromCharacter(_VehicleSeat.Position) >= 150 then
			DeleteToyRE:FireServer(_G.LastBlobmanWasSeat)

			return
		end
		if v1366 and _Weld and _Weld.Part1 and not _Weld.Part1:IsDescendantOf(v1366) then
			local _Part18 = _Weld.Part1
			local v1371 = _Players

			SNOWshipPlayer(v1371:GetPlayerFromCharacter(_Part18.Parent))
		end
		if _ProximityPrompt and _VehicleSeat then
			for _ = 0, 15 do
				if u917() or not _G.LoopKick then
					break
				end

				fireproximityprompt(_ProximityPrompt)
				TeleportPlayer(_VehicleSeat.CFrame + Vector3.new(0, 3.5, 0), 1.5)
				task.wait(0.1)
			end
		end
	end
end

function CountRealNumberPlayersInLoop()
	local v1373, v1374, v1375 = pairs(u70)
	local v1376 = 0

	while true do
		local v1377

		v1375, v1377 = v1373(v1374, v1375)

		if v1375 == nil then
			break
		end
		if _Players:FindFirstChild(v1377) then
			v1376 = v1376 + 1
		end
	end

	return v1376
end
function IsThereAnyPlayersInLoopAlive()
	local v1378, v1379, v1380 = pairs(u70)
	local v1381 = false

	while true do
		local v1382

		v1380, v1382 = v1378(v1379, v1380)

		if v1380 == nil then
			break
		end
		if _Players:FindFirstChild(v1382) and v1382.Character then
			if v1382.Character:FindFirstChildOfClass('Humanoid') and 0 < v1382.Character.Humanoid.Health then
				v1381 = true
			end
		end
	end

	return v1381
end
function ResetCharacterStats()
	local v1383, v1384, v1385 = pairs(u70)

	while true do
		local v1386

		v1385, v1386 = v1383(v1384, v1385)

		if v1385 == nil then
			break
		end

		local v1387 = _Players:FindFirstChild(v1386)

		if v1387 and v1387.Character and v1387.Character:FindFirstChild('HumanoidRootPart') then
			local _HumanoidRootPart20 = v1387.Character.HumanoidRootPart

			v1387.Character:SetAttribute('Kick', 0)
			v1387.Character:SetAttribute('Kicking', nil)
			v1387.Character:SetAttribute('Kicking2', nil)

			if _HumanoidRootPart20:FindFirstChild('KickAuraVelocity') then
				_HumanoidRootPart20.KickAuraVelocity:Destroy()
			end
		end
	end
end
function verifyPlayerinBlobmanHand()
	local _Humanoid10 = _LocalPlayer.Character:FindFirstChildOfClass('Humanoid')

	if u917() then
		local _Attachment0 = _Humanoid10.SeatPart.Parent:WaitForChild('LeftDetector'):WaitForChild('LeftWeld').Attachment0
		local v1391 = _Attachment0 and _Attachment0.Parent and _Players:GetPlayerFromCharacter(_Attachment0.Parent.Parent)

		if v1391 then
			return v1391
		end
	end
end

local u1392 = nil

v1354:AddToggle({
	Name = 'Loop Kill',
	Default = false,
	Callback = function(p1393)
		_G.LoopKill = p1393

		if p1393 then
			while _G.LoopKill do
				u1392 = GetPlayerCFrame()

				local v1394, v1395, v1396 = pairs(u70)

				while true do
					local v1397

					v1396, v1397 = v1394(v1395, v1396)

					if v1396 == nil then
						break
					end

					local v1398 = _Players:FindFirstChild(v1397)

					if CheckPlayerForLoopKill(v1398) and ChangeActivityPriority(2) then
						local _HumanoidRootPart21 = v1398.Character:FindFirstChild('HumanoidRootPart')
						local _Head8 = v1398.Character:FindFirstChild('Head')
						local _Humanoid11 = v1398.Character:FindFirstChild('Humanoid')

						if v1398 and _HumanoidRootPart21 and _Head8 then
							for _ = 0, 50 do
								u406()
								SNOWship(_HumanoidRootPart21)

								if not (CheckPlayerForLoopKill(v1398) and _G.LoopKill) or (CheckNetworkOwnerShipOnPlayer(v1398) or 500 < _HumanoidRootPart21.AssemblyLinearVelocity.Magnitude) then
									_DestroyGrabLine:FireServer(_HumanoidRootPart21)
									CreateSkyVelocity(_HumanoidRootPart21)

									break
								end

								task.wait()

								if _HumanoidRootPart21.Position.Y <= -12 then
									TeleportPlayer(CFrame.new(_HumanoidRootPart21.Position + Vector3.new(0, 5, -15)), 2)
								else
									TeleportPlayer(CFrame.new(_HumanoidRootPart21.Position + Vector3.new(0, -10, -10)), 2)
								end

								_Humanoid11.BreakJointsOnDeath = false

								_Humanoid11:ChangeState(Enum.HumanoidStateType.Dead)

								_Humanoid11.Jump = true
								_Humanoid11.Sit = false
							end
						end

						ChangeActivityPriority(0)
					end
				end

				TeleportPlayer(u1392)
				task.wait(0.2)
			end

			u405()
			TeleportPlayer(u1392)
			print('End LoopKill')
		end
	end,
	Save = true,
	Flag = 'lk_toggle',
})

local v1402 = v655:AddSection({
	Name = 'Loop Kick (Ownership)',
})

loopkickownertoggle = v1402:AddToggle({
	Name = 'Loop Kick',
	Default = false,
	Callback = function(p1403)
		_G.LoopKickOwnership = p1403

		if p1403 then
			while _G.LoopKickOwnership do
				if GetKey() ~= 'Xana' then
					_G.LoopKickOwnership = false

					u33('Only for premium users! Buy premium in my discord server!')
					loopkickownertoggle:Set(false)
				end

				u1392 = GetPlayerCFrame()

				local v1404, v1405, v1406 = pairs(u70)

				while true do
					local v1407

					v1406, v1407 = v1404(v1405, v1406)

					if v1406 == nil then
						break
					end

					local v1408 = _Players:FindFirstChild(v1407)

					if CheckPlayerForLoopKill(v1408) and ChangeActivityPriority(2) then
						local _HumanoidRootPart22 = v1408.Character:FindFirstChild('HumanoidRootPart')
						local _Head9 = v1408.Character:FindFirstChild('Head')

						v1408.Character:FindFirstChild('Humanoid')

						if v1408 and _HumanoidRootPart22 and _Head9 then
							for _ = 0, 50 do
								u406()
								SNOWship(_HumanoidRootPart22)

								if not (CheckPlayerForLoopKill(v1408) and _G.LoopKickOwnership) or (CheckNetworkOwnerShipOnPlayer(v1408) or 500 < _HumanoidRootPart22.AssemblyLinearVelocity.Magnitude) then
									_DestroyGrabLine:FireServer(_HumanoidRootPart22)
									wait()
									CreateSkyVelocity(_HumanoidRootPart22)

									break
								end

								task.wait()

								if _HumanoidRootPart22.Position.Y <= -12 then
									TeleportPlayer(CFrame.new(_HumanoidRootPart22.Position + Vector3.new(0, 5, -15)), 2)
								else
									TeleportPlayer(CFrame.new(_HumanoidRootPart22.Position + Vector3.new(0, -10, -10)), 2)
								end
							end
						end

						ChangeActivityPriority(0)
					end
				end

				TeleportPlayer(u1392)
				task.wait(0.2)
			end

			u405()
			TeleportPlayer(u1392)
		end
	end,
	Save = true,
	Flag = 'lkickowner_toggle',
})

v1402:AddDropdown({
	Name = 'Kick Type',
	Default = 'Go to the heaven!',
	Options = {
		'Go to the heaven!',
	},
	Callback = function(p1411)
		_G.LoopKickOwnerType = p1411
	end,
	Save = true,
	Flag = 'loopkickownershiptype_dropdown',
})

loopRagdoll = v1354:AddToggle({
	Name = 'Loop Ragdoll',
	Default = false,
	Callback = function(p1412)
		_G.LoopRagdoll = p1412

		if p1412 then
			while _G.LoopRagdoll do
				if GetKey() ~= 'Xana' then
					loopRagdoll:Set(false)

					_G.LoopRagdoll = false

					u33('Only for premium users! Buy premium in my discord server!')

					break
				end

				local v1413, v1414, v1415 = pairs(u70)

				while true do
					local v1416

					v1415, v1416 = v1413(v1414, v1415)

					if v1415 == nil then
						break
					end

					local v1417 = _Players:FindFirstChild(v1416)

					if CheckPlayerAnnoyAll(v1417) then
						local _Character14 = v1417.Character
						local _HumanoidRootPart23 = v1417.Character:FindFirstChild('HumanoidRootPart')
						local _Ragdolled2 = _Character14:FindFirstChildOfClass('Humanoid'):FindFirstChild('Ragdolled')

						if _HumanoidRootPart23 and _Ragdolled2 and not _Ragdolled2.Value then
							u582(_HumanoidRootPart23)
							task.wait(0.015)
						end
					end
				end

				task.wait()
			end
		end
	end,
})
loopFire = v1354:AddToggle({
	Name = 'Loop Fire',
	Default = false,
	Callback = function(p1421)
		_G.LoopFire = p1421

		if p1421 then
			while _G.LoopFire do
				if GetKey() ~= 'Xana' then
					loopFire:Set(false)

					_G.LoopFire = false

					u33('Only for premium users! Buy premium in my discord server!')

					break
				end

				local v1422, v1423, v1424 = pairs(u70)

				while true do
					local v1425

					v1424, v1425 = v1422(v1423, v1424)

					if v1424 == nil then
						break
					end

					local v1426 = _Players:FindFirstChild(v1425)

					if CheckPlayerAnnoyAll(v1426) then
						local _ = v1426.Character
						local _HumanoidRootPart24 = v1426.Character:FindFirstChild('HumanoidRootPart')
						local v1428

						if _HumanoidRootPart24:FindFirstChild('FirePlayerPart') and _HumanoidRootPart24.FirePlayerPart:FindFirstChild('CanBurn') then
							v1428 = _HumanoidRootPart24.FirePlayerPart.CanBurn.Value
						else
							v1428 = nil
						end
						if _HumanoidRootPart24 and v1426 and not (IsPlayerInsideSafeZone(v1426) or v1428) then
							u613(_HumanoidRootPart24)
							task.wait(0.015)
						end
					end
				end

				task.wait()
			end
		end
	end,
})

local function u1443(p1429, p1430)
	local _Humanoid12 = _LocalPlayer.Character:FindFirstChildOfClass('Humanoid')

	if u917() then
		local _Parent10 = _Humanoid12.SeatPart.Parent
		local v1433 = _Players:FindFirstChild(p1429)

		if v1433 and v1433.Character and (v1433.Character:FindFirstChild('HumanoidRootPart') and _Parent10) and not u54(v1433) then
			local v1434 = {
				_Parent10.LeftDetector,
				v1433.Character.HumanoidRootPart,
				_Parent10.LeftDetector.LeftWeld,
			}
			local v1435 = {
				_Parent10.LeftDetector.LeftWeld,
				v1433.Character.HumanoidRootPart,
			}

			CreatureGrab = _Parent10.BlobmanSeatAndOwnerScript.CreatureGrab

			local _CreatureDrop = _Parent10.BlobmanSeatAndOwnerScript.CreatureDrop

			if _Parent10 then
				if p1430 == 1 then
					if _Parent10.Parent ~= u17 then
						u3:MakeNotification({
							Name = 'You need to be seated on Blobman',
							Content = 'The Blobman needs to be your own toy',
							Image = 'rbxassetid://4483345998',
							Time = 5,
						})
					else
						task.wait(0.2)
						DeleteToyRE:FireServer(_Parent10)
					end
				elseif p1430 == 2 then
					CreatureGrab:FireServer(unpack(v1434))
					task.wait(0.155)

					_Humanoid12.Sit = false
				elseif p1430 == 3 and not v1433.Character:GetAttribute('Kicking') and not v1433.Character:GetAttribute('Kicking2') then
					local v1437 = _Players:FindFirstChild(p1429)
					local _Character15 = v1437.Character
					local _HumanoidRootPart25 = _Character15.HumanoidRootPart
					local _ = _Character15.Head
					local _Humanoid13 = _Character15:FindFirstChildOfClass('Humanoid')
					local v1441 = nil

					_Character15:SetAttribute('Kicking', true)

					if _HumanoidRootPart25:FindFirstChild('FlingAuraVelocity') then
						_HumanoidRootPart25.FlingAuraVelocity:Destroy()
					end

					print('Kick')

					for _ = 0, 50 do
						if not u917() or CheckNetworkOwnerShipOnPlayer(v1437) then
							break
						end
						if verifyPlayerinBlobmanHand() == v1437 then
							_CreatureDrop:FireServer(unpack(v1435))

							break
						end

						CreatureGrab:FireServer(unpack(v1434))
						task.wait()
					end

					print('End Loop Here!')

					for _ = 0, 25 do
						if SNOWshipPlayer(v1437) then
							if not _HumanoidRootPart25:FindFirstChild('KickAuraVelocity') then
								v1441 = Instance.new('BodyVelocity', _HumanoidRootPart25)
								v1441.Name = 'KickAuraVelocity'
								v1441.MaxForce = Vector3.new(0, 12500, 0)
								v1441.Velocity = Vector3.new(0, 100, 0)
							end

							local v1442 = 0

							while u917() and v1442 < 100 do
								if _Humanoid13.FloorMaterial == Enum.Material.Air and _LocalPlayer:DistanceFromCharacter(_HumanoidRootPart25.Position) > 100 then
									_Character15:SetAttribute('Kicking2', true)
									_DestroyGrabLine:FireServer(_HumanoidRootPart25)
									CreatureGrab:FireServer(unpack(v1434))
									print('Destroyed!')

									break
								end

								SNOWshipPlayer(v1437)

								v1442 = v1442 + 1

								task.wait()
							end

							break
						end
						if not u917() then
							break
						end

						task.wait()
					end

					if v1441 then
						v1441:Destroy()
					end

					_Character15:SetAttribute('Kicking', nil)
				elseif not p1430 then
					CreatureGrab:FireServer(unpack(v1434))
				end
			end
		end
	else
		u3:MakeNotification({
			Name = 'You need to be seated on Blobman',
			Content = 'Please, sit on any Blobman',
			Image = 'rbxassetid://4483345998',
			Time = 5,
		})
	end
end

v1355:AddToggle({
	Name = 'Loop Kick (Blobman)',
	Default = false,
	Callback = function(p1444)
		if p1444 then
			_G.LoopKick = p1444

			while _G.LoopKick do
				local v1445, v1446, v1447 = pairs(u70)

				while true do
					local v1448

					v1447, v1448 = v1445(v1446, v1447)

					if v1447 == nil then
						break
					end
					if _Players:FindFirstChild(v1448) and ChangeActivityPriority(1.5) then
						if u917() then
							u1443(v1448, 3)
						else
							u1372()
						end

						ChangeActivityPriority(0)
					end
				end

				task.wait()
			end
		else
			_G.LoopKick = p1444
		end
	end,
	Save = true,
	Flag = 'lkick_toggle',
})

function blobmangraball()
	local v1449 = _Players
	local v1450, v1451, v1452 = pairs(v1449:GetPlayers())

	while true do
		local v1453

		v1452, v1453 = v1450(v1451, v1452)

		if v1452 == nil then
			break
		end
		if not u54(v1453) and v1453 ~= _LocalPlayer and v1453.Character and (v1453.Character:FindFirstChild('HumanoidRootPart') and not (u105(v1453.Name) and _G.WhitelistFriends2)) and (_LocalPlayer.Character and _LocalPlayer.Character:FindFirstChildOfClass('Humanoid')) then
			local _Parent11 = _LocalPlayer.Character:FindFirstChildOfClass('Humanoid').SeatPart.Parent
			local v1455 = {
				_Parent11:WaitForChild('LeftDetector'),
				v1453.Character:FindFirstChild('HumanoidRootPart'),
				_Parent11:WaitForChild('LeftDetector'):WaitForChild('LeftWeld'),
			}

			_Parent11:WaitForChild('BlobmanSeatAndOwnerScript'):WaitForChild('CreatureGrab'):FireServer(unpack(v1455))
		end

		task.wait()
	end
end

PlayerToSelect = LongReachGrab_Player:AddDropdown({
	Name = 'Select Player',
	Default = '',
	Options = {
		'',
	},
	Callback = function(p1456)
		local v1457 = string.split(p1456, ' ')

		_G.PlayerToLongGrab = v1457[1]
	end,
})

LongReachGrab_Player:AddButton({
	Name = 'Lock',
	Callback = function()
		u1443(_G.PlayerToLongGrab, 2)
	end,
})
LongReachGrab_Player:AddButton({
	Name = 'Bring',
	Callback = function()
		u1443(_G.PlayerToLongGrab)
	end,
})
LongReachGrab_Player:AddButton({
	Name = 'Kick',
	Callback = function()
		u1443(_G.PlayerToLongGrab, 3)
	end,
})

local v1458 = LongReachGrab_Player:AddSection({
	Name = 'Destroy Everything',
})
local u1459 = nil

u1459 = v1458:AddToggle({
	Name = 'Destroy Server',
	Default = false,
	Callback = function(p1460)
		if p1460 then
			_G.BringAllLongReach = true

			if GetKey() ~= 'Xana' and _InPlot.Value then
				u1459:Set(false)
				u33("You can't use destroy server inside a house!, buy premium to be able to do that!")

				return
			end
			if u917() then
				while _G.BringAllLongReach do
					if u917() then
						blobmangraball()
					else
						task.wait(1)
					end
				end
			else
				u1459:Set(false)
				u3:MakeNotification({
					Name = 'You need to be seated on Blobman',
					Content = 'Please, sit on any Blobman',
					Image = 'rbxassetid://4483345998',
					Time = 5,
				})
			end
		else
			_G.BringAllLongReach = false
		end
	end,
	Save = true,
	Flag = 'BringAllLongReach_toggle',
})
u1459 = v1458:AddToggle({
	Name = 'Whitelist Friends',
	Default = false,
	Callback = function(p1461)
		_G.WhitelistFriends2 = p1461
	end,
	Save = true,
	Flag = 'Whitelistfreinds2_toggle',
})
apagarfogo = _Workspace.Map.Hole.PoisonBigHole.ExtinguishPart
apagarfogo.Size = Vector3.new(0.5, 0.5, 0.5)
apagarfogo.Transparency = 1
apagarfogo.Tex.Transparency = 1

_Workspace.ChildAdded:Connect(function(p1462)
	if p1462.Name == 'GrabParts' then
		local _Part19 = p1462.GrabPart.WeldConstraint.Part1
		local u1464 = nil

		if _Part19 then
			if u54(_Part19.Parent) then
				return
			end
			if _G.InvisibleLine then
				_CreateGrabLine:FireServer()
			end
			if _G.SuperStrength then
				u1464 = Instance.new('BodyVelocity', _Part19)
				u1464.MaxForce = Vector3.new(0, 0, 0)
				u1464.Velocity = Vector3.new()
				u1464.Name = 'SuperStrength'
			end

			_G.HoldingObjectGrabPart = _Part19

			if _G.MasslessGrab then
				task.spawn(function()
					local _AlignOrientation = p1462.DragPart.AlignOrientation
					local _AlignPosition = p1462.DragPart.AlignPosition

					while _G.MasslessGrab do
						_AlignOrientation.MaxTorque = 1e46
						_AlignOrientation.Responsiveness = 20099
						_AlignPosition.MaxForce = 1e51
						_AlignPosition.Responsiveness = 20099

						task.wait(0.245)
					end

					_AlignOrientation.MaxTorque = 600000
					_AlignOrientation.Responsiveness = 30
					_AlignPosition.MaxForce = 60000
					_AlignPosition.Responsiveness = 40
				end)
			end
			if _G.NoclipGrab and not _Part19.Anchored then
				task.spawn(function()
					if _Part19.Parent and _Part19.Parent:IsA('Model') then
						local v1467 = _Part19.Parent:GetDescendants()
						local _Humanoid14 = _Part19.Parent:FindFirstChildOfClass('Humanoid')
						local v1469, v1470, v1471 = pairs(v1467)
						local v1472 = {}

						while true do
							local v1473

							v1471, v1473 = v1469(v1470, v1471)

							if v1471 == nil then
								break
							end
							if v1473:IsA('BasePart') or v1473:IsA('Part') or v1473:IsA('MeshPart') then
								v1472[v1473] = v1473.CanCollide
							end
						end
						while p1462.Parent do
							local v1474, v1475, v1476 = pairs(v1467)

							while true do
								local v1477

								v1476, v1477 = v1474(v1475, v1476)

								if v1476 == nil then
									break
								end
								if v1477:IsA('BasePart') or v1477:IsA('Part') or v1477:IsA('MeshPart') then
									v1477.CanCollide = false
								end
							end

							wait(0.214)
						end

						if _Humanoid14 then
							task.wait(0.5)
						end

						local v1478, v1479, v1480 = pairs(v1467)

						while true do
							local v1481

							v1480, v1481 = v1478(v1479, v1480)

							if v1480 == nil then
								break
							end
							if v1481:IsA('BasePart') or v1481:IsA('Part') or v1481:IsA('MeshPart') then
								v1481.CanCollide = v1472[v1481]
							end
						end
					end
				end)
			end
			if _G.PerspectiveGrab and not _Part19.Anchored then
				task.spawn(function()
					local v1482 = GetPlayerCharacter()

					_CreateGrabLine:FireServer()

					local u1483, u1484

					if v1482 then
						u1483 = v1482:FindFirstChildOfClass('Humanoid')
						u1484 = v1482:FindFirstChild('HumanoidRootPart')
					else
						u1483 = nil
						u1484 = nil
					end

					local _Part = Instance.new('Part', _Workspace)

					_Part.Anchored = true
					_Part.CanCollide = false
					_Part.Transparency = 1
					_Part.CanQuery = false
					_Part.Size = Vector3.new()
					_Part.CFrame = workspace.CurrentCamera.CFrame
					workspace.CurrentCamera.CameraType = Enum.CameraType.Follow
					workspace.CurrentCamera.CameraSubject = _Part

					if u1147 then
						u1147:Disconnect()
					end
					if u1483 and u1484 then
						local v1486 = GetPlayerCFrame()

						u692(true)

						local u1487 = nil
						local u1488 = nil
						local u1489 = nil
						local u1490 = nil
						local u1491 = nil
						local u1492 = nil
						local u1493 = nil

						u1147 = _RunService.Heartbeat:Connect(function(p1494)
							u1487 = u1483.MoveDirection * (u1148 * p1494)
							u1488 = _Part.CFrame
							u1489 = workspace.CurrentCamera.CFrame
							u1490 = u1488:ToObjectSpace(u1489).Position
							u1489 = u1489 * CFrame.new(-u1490.X, -u1490.Y, -u1490.Z + 1)
							u1491 = u1489.Position
							u1492 = u1488.Position
							u1493 = CFrame.new(u1491, Vector3.new(u1492.X, u1491.Y, u1492.Z)):VectorToObjectSpace(u1487)
							_Part.CFrame = CFrame.new(u1492) * (u1489 - u1491) * CFrame.new(u1493)
							u1484.CFrame = CFrame.new(527, 123, -376)
						end)

						while p1462.Parent do
							task.wait()
						end

						local _CFrame = workspace.CurrentCamera.CFrame

						u692(false)

						workspace.CurrentCamera.CameraSubject = _LocalPlayer.Character:FindFirstChildOfClass('Humanoid')
						workspace.CurrentCamera.CameraType = Enum.CameraType.Custom

						if u1147 then
							u1147:Disconnect()
						end
						if _G.PerspectiveTeleportToCameraPos then
							u1484.CFrame = _CFrame
						else
							u1484.CFrame = v1486
						end
					end
				end)
			end

			task.spawn(function()
				if u1464 then
					if not _LocalPlayer.PlayerGui:FindFirstChild('ContextActionGui') then
						return
					end

					local v1496 = nil
					local u1497 = nil
					local u1498 = nil

					while v1496 == nil and p1462.Parent do
						local v1499, v1500, v1501 = pairs(game.Players.LocalPlayer.PlayerGui.ContextActionGui:GetDescendants())

						while true do
							local v1502

							v1501, v1502 = v1499(v1500, v1501)

							if v1501 == nil then
								break
							end
							if v1502:IsA('ImageLabel') and v1502.Image == 'http://www.roblox.com/asset/?id=9603678090' then
								v1496 = v1502.Parent
							end
						end

						task.wait()
					end

					v1496.Active = true

					if v1496 then
						u1497 = v1496.MouseButton1Down:Connect(function()
							print('Launched Mobile!')

							pressedStrength = true
							u1464.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
							u1464.Velocity = workspace.CurrentCamera.CFrame.lookVector * _G.Strength
						end)
					end

					local _ = p1462:GetPropertyChangedSignal('Parent'):Connect(function()
						if not p1462.Parent then
							_Debris:AddItem(u1464, 1)

							if u1497 then
								u1497:Disconnect()
							end

							u1498:Disconnect()
						end
					end)
				end
			end)
			task.spawn(function()
				if u1464 then
					local u1503 = nil

					u1503 = p1462:GetPropertyChangedSignal('Parent'):Connect(function()
						if not p1462.Parent then
							if _UserInputService:GetLastInputType() ~= Enum.UserInputType.MouseButton2 or not _G.SuperStrength then
								if _UserInputService:GetLastInputType() == Enum.UserInputType.MouseButton1 then
									u1464:Destroy()
								end
							else
								print('Launched!')

								pressedStrength = true
								u1464.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
								u1464.Velocity = workspace.CurrentCamera.CFrame.lookVector * _G.Strength

								_Debris:AddItem(u1464, 1)
							end

							u1503:Disconnect()
						end
					end)
				end
			end)

			if _G.Poison_Grab then
				task.spawn(function()
					if _Part19.Parent:FindFirstChildOfClass('Humanoid') then
						local _Head10 = _Part19.Parent.Head

						while p1462.Parent and _G.Poison_Grab do
							_PoisonHurtPart.CFrame = _Head10.CFrame
							_PoisonHurtPart2.CFrame = _Head10.CFrame
							_PoisonHurtPart3.CFrame = _Head10.CFrame

							task.wait()

							_PoisonHurtPart3.Position = Vector3.new(0, -50, 0)
							_PoisonHurtPart2.Position = Vector3.new(0, -50, 0)
							_PoisonHurtPart.Position = Vector3.new(0, -50, 0)
						end
					end
				end)
			end
			if _G.Burn_Grab then
				task.spawn(function()
					while p1462.Parent and _G.Burn_Grab do
						if _Part19.Parent:FindFirstChildOfClass('Humanoid') then
							u613(_Part19.Parent.HumanoidRootPart)
						elseif _Part19.Parent:FindFirstChild('FireDetector') then
							u613(_Part19.Parent.FireDetector)
						else
							u613(_Part19)
						end

						task.wait()
					end
				end)
			end
			if _G.Radiactive_Grab then
				task.spawn(function()
					if _Part19.Parent:FindFirstChildOfClass('Humanoid') then
						while p1462.Parent and _G.Radiactive_Grab do
							_OuterUFO.Position = _Part19.Position

							task.wait()
						end

						_OuterUFO.Position = Vector3.new(0, -50, 0)
					end
				end)
			end
			if _G.Death_Grab then
				task.spawn(function()
					if _Part19.Parent:FindFirstChildOfClass('Humanoid') then
						local _Humanoid15 = _Part19.Parent:FindFirstChildOfClass('Humanoid')
						local _ = _Part19.Parent.HumanoidRootPart

						while _Part19.Parent do
							local v1506 = _Players

							if CheckNetworkOwnerShipOnPlayer(v1506:GetPlayerFromCharacter(_Part19.Parent)) then
								_Humanoid15.BreakJointsOnDeath = false

								_Humanoid15:ChangeState(Enum.HumanoidStateType.Dead)

								_Humanoid15.Jump = true
								_Humanoid15.Sit = false

								if _Humanoid15:GetStateEnabled(Enum.HumanoidStateType.Dead) then
									_DestroyGrabLine:FireServer(_Part19)
								end
							end

							task.wait()
						end
					end
				end)
			end
		end
	end
end)
workspace.DescendantAdded:Connect(function(p1507)
	if p1507.Name == 'PartOwner' and p1507.Parent.Name == 'Head' then
		local _HumanoidRootPart26 = p1507.Parent.Parent:FindFirstChild('HumanoidRootPart')

		if _HumanoidRootPart26:FindFirstChild('KickAuraP') then
			_HumanoidRootPart26.KickAuraP:Destroy()
		end
		if _HumanoidRootPart26:FindFirstChild('KickAuraP1') then
			_HumanoidRootPart26.KickAuraP1:Destroy()
		end
		if _HumanoidRootPart26:FindFirstChild('SkyVelocity') then
			_HumanoidRootPart26.SkyVelocity:Destroy()
		end
		if _HumanoidRootPart26:FindFirstChild('BringBody') then
			_HumanoidRootPart26.BringBody:Destroy()
		end
	end
	if p1507.Name == 'TimeRemainingNum' and p1507.Parent.Value == _LocalPlayer.Name then
		_G.RemainingTimeInHouse = p1507
	end
end)
_IsHeld.Changed:Connect(function(p1509)
	if p1509 == true and (not u54(_Players:FindFirstChild(u28)) and _G.AntiGrab) then
		local _HumanoidRootPart27 = (_LocalPlayer.Character or _LocalPlayer.CharacterAdded:Wait()):WaitForChild('HumanoidRootPart')

		if _IsHeld.Value then
			local u1511 = nil

			u1511 = _RunService.Heartbeat:Connect(function()
				if _IsHeld.Value then
					_HumanoidRootPart27.Velocity = Vector3.new()
					_HumanoidRootPart27.Anchored = true

					_Struggle:FireServer(_LocalPlayer)
					_RagdollRemote:FireServer(_HumanoidRootPart27, 0)
				else
					_HumanoidRootPart27.Velocity = Vector3.new()
					_HumanoidRootPart27.Anchored = false

					u1511:Disconnect()
				end
			end)
		end
	end
end)

function IsReallyBeingHeld()
	if _IsHeld.Value and not _G.AntiGrab then
		return true
	end
	if _IsHeld.Value and u54(_Players:FindFirstChild(u28)) then
		return true
	end
end
function setMasslessFalse(p1512)
	local v1513, v1514, v1515 = ipairs(p1512:GetDescendants())

	while true do
		local v1516

		v1515, v1516 = v1513(v1514, v1515)

		if v1515 == nil then
			break
		end
		if v1516:IsA('BasePart') then
			v1516.Massless = false
		end
	end
end
function enforceMasslessFalse(p1517)
	p1517.DescendantAdded:Connect(function(p1518)
		if p1518:IsA('BasePart') then
			p1518:GetPropertyChangedSignal('Massless'):Connect(function()
				if p1518.Massless then
					p1518.Massless = false
				end
			end)
		end
	end)

	local v1519, v1520, v1521 = ipairs(p1517:GetDescendants())

	while true do
		local u1522

		v1521, u1522 = v1519(v1520, v1521)

		if v1521 == nil then
			break
		end
		if u1522:IsA('BasePart') then
			u1522:GetPropertyChangedSignal('Massless'):Connect(function()
				if u1522.Massless then
					u1522.Massless = false
				end
			end)
		end
	end
end
local function reconnect()
	local v1523 = _LocalPlayer.Character or _LocalPlayer.CharacterAdded:Wait()
	local u1524 = v1523:FindFirstChildWhichIsA('Humanoid') or v1523:WaitForChild('Humanoid')
	local _HumanoidRootPart28 = v1523:WaitForChild('HumanoidRootPart')

	v1523:WaitForChild('Head')

	CharacterRaycastFilter.FilterDescendantsInstances[1] = v1523
	COAroundPParams.FilterDescendantsInstances[1] = v1523
	_G.UniversalPlayerRoot = _HumanoidRootPart28
	scriptToGetSenv = v1523:WaitForChild('GrabbingScript')

	if scriptToGetSenv and getsenv then
		senv = getsenv(scriptToGetSenv)
	end

	local _CanBurn = _HumanoidRootPart28:WaitForChild('FirePlayerPart'):WaitForChild('CanBurn')
	local _Ragdolled3 = u1524:WaitForChild('Ragdolled')

	if true then
		local u1528 = _HumanoidRootPart28 and _HumanoidRootPart28:FindFirstChild('RootAttachment')

		if u1528 then
			task.delay(1, function()
				u1528:Destroy()
			end)
		end

		setMasslessFalse(v1523)
		enforceMasslessFalse(v1523)
	end

	local _BodyPosition10 = Instance.new('BodyPosition', _HumanoidRootPart28)

	_BodyPosition10.MaxForce = Vector3.new(0, 0, 0)
	u1524.JumpPower = _G.InfiniteJumpPower

	if _G.NoclipToggle then
		u406()
	end

	v1523.DescendantAdded:Connect(function(p1530)
		if p1530.Name == 'PartOwner' then
			u28 = tostring(p1530.Value)

			if _G.AutoAttacker then
				local u1531 = _Players:FindFirstChild(u28)
				local u1532 = nil
				local u1533 = nil

				if u1531 and u1531.Character then
					local _Character16 = u1531.Character

					if _Character16 then
						u1532 = _Character16:FindFirstChildOfClass('Humanoid')
						u1533 = _Character16:FindFirstChild('HumanoidRootPart')
					end
				end
				if u1531 and u54(u1531) == false and u1531 ~= _LocalPlayer then
					local v1535 = nil
					local u1536 = nil
					local v1537 = false
					local v1538

					if _G.CounterMode == 'Repulsion' or not _G.CounterMode then
						v1538 = function()
							u1536 = lookAt(_LocalPlayer.Character.HumanoidRootPart.Position, u1533.Position)

							local _BodyVelocity8 = Instance.new('BodyVelocity', u1531.Character.HumanoidRootPart)

							_BodyVelocity8.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
							_BodyVelocity8.Velocity = Vector3.new(u1536.lookVector.X, 0.5, u1536.lookVector.Z) * 100

							wait()
							_BodyVelocity8:Destroy()
							_DestroyGrabLine:FireServer(u1533)
						end
					elseif _G.CounterMode ~= 'Freeze' then
						if _G.CounterMode ~= 'Kick' then
							v1538 = _G.CounterMode == 'Death' and function()
								local v1540 = u1532

								if v1540 then
									CreateSkyVelocity(u1533)

									for _ = 0, 20 do
										v1540.BreakJointsOnDeath = false

										v1540:ChangeState(Enum.HumanoidStateType.Dead)

										v1540.Jump = true
										v1540.Sit = true
									end

									task.wait()
									_DestroyGrabLine:FireServer(u1533)
								end
							end or v1535
						else
							v1538 = function()
								CreateSkyVelocity(u1533)
								wait(1)
								_DestroyGrabLine:FireServer(u1533)
							end
						end
					else
						v1538 = function()
							local v1541 = u1532

							if v1541 then
								v1541.WalkSpeed = 0
								v1541.Sit = false
								v1541.JumpPower = 0
							end
						end
					end
					if v1537 then
						for _ = 1, 50 do
							SNOWshipPermanentPlayer(u1531, v1538)
							task.wait()
						end
					else
						for _ = 1, 50 do
							if SNOWshipPlayer(u1531, v1538) then
								break
							end

							task.wait()
						end
					end
				end
			end
		end
	end)
	_CanBurn.Changed:Connect(function(p1542)
		if p1542 and _G.AntiBurn then
			while _CanBurn.Value do
				if firetouchinterest then
					firetouchinterest(_HumanoidRootPart28.FirePlayerPart, apagarfogo, 0)
					task.wait()
					firetouchinterest(_HumanoidRootPart28.FirePlayerPart, apagarfogo, 1)
				else
					apagarfogo.CFrame = _HumanoidRootPart28.FirePlayerPart.CFrame * CFrame.new(math.random(-1, 1), math.random(-1, 1), math.random(-1, 1))

					task.wait()

					apagarfogo.Position = Vector3.new(0, -100, 0)
				end
			end
		end
	end)
	_Ragdolled3.Changed:Connect(function(p1543)
		if p1543 and _G.AntiExplosion then
			while _Ragdolled3.Value do
				if IsReallyBeingHeld() then
					_HumanoidRootPart28.Anchored = false
				else
					_HumanoidRootPart28.Anchored = true
					_HumanoidRootPart28.Velocity = Vector3.new()
				end

				task.wait()
			end

			_HumanoidRootPart28.Velocity = Vector3.new()
			_HumanoidRootPart28.Anchored = false
		end
	end)
	u1524.Changed:Connect(function(p1544)
		if p1544 == 'Sit' and u1524.Sit == true then
			if u1524.SeatPart == nil or tostring(u1524.SeatPart.Parent) ~= 'CreatureBlobman' then
				if u1524.SeatPart == nil and _G.AntiGrab then
					u1524:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)

					u1524.Sit = false
				end
			elseif _G.RockBlobman then
				_BodyPosition10.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
				_BodyPosition10.Position = _HumanoidRootPart28.Position
			end
		end
		if p1544 == 'SeatPart' and u1524.SeatPart == nil then
			ResetCharacterStats()

			if _HumanoidRootPart28:FindFirstChild('BodyPositionFloat') then
				_HumanoidRootPart28.BodyPositionFloat:Destroy()
			end

			_BodyPosition10.MaxForce = Vector3.new(0, 0, 0)
		end
		if p1544 == 'MoveDirection' and _G.RockBlobman and u917() then
			_BodyPosition10.Position = _HumanoidRootPart28.Position

			if u1524.MoveDirection.Magnitude <= 0 then
				_BodyPosition10.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
			else
				_BodyPosition10.MaxForce = Vector3.new(0, 0, 0)
			end
		end
	end)

	local v1545 = u1524 and u1524:WaitForChild('Animator', 1)

	if v1545 then
		TypeAnimation = v1545:LoadAnimation(typeAnimation)
		FlailAnimation = v1545:LoadAnimation(flailAnimation)
	end
end

_UserInputService.JumpRequest:Connect(function()
	if _G.InfiniteJump then
		_LocalPlayer.Character:FindFirstChildOfClass('Humanoid'):ChangeState('Jumping')
	end
end)
_RunService.Heartbeat:Connect(function()
	if _G.SuperSpeed then
		_LocalPlayer.Character.HumanoidRootPart.CFrame = _LocalPlayer.Character.HumanoidRootPart.CFrame + _LocalPlayer.Character:FindFirstChildOfClass('Humanoid').MoveDirection * Multiplier
	end
end)

function CanRemoveStickyPart(_, p1546, _)
	return p1546:GetAttribute('Kicking2') and true or nil
end

task.spawn(function()
	while task.wait() do
		local v1547 = _Players
		local v1548, v1549, v1550 = pairs(v1547:GetPlayers())

		while true do
			local v1551

			v1550, v1551 = v1548(v1549, v1550)

			if v1550 == nil then
				break
			end
			if CheckPlayer(v1551) then
				local _Character17 = v1551.Character
				local _HumanoidRootPart29 = v1551.Character:FindFirstChild('HumanoidRootPart')

				if v1551 and _Character17 and (_HumanoidRootPart29 and CanRemoveStickyPart(v1551, _Character17, _HumanoidRootPart29)) then
					u522(_HumanoidRootPart29)
				end
			end
		end
	end
end)

function PlayerRemoving_Added(_)
	u69(PlayerToSelect)
	u69(u1357)
	u69(u1339)
	u69(PlayerToTeleport)
	u87(RotationAuraList)
	u87(PlayerToTarget)
end

local _ = PlayerRemoving_Added

_Players.PlayerAdded:Connect(PlayerRemoving_Added)
_Players.PlayerRemoving:Connect(PlayerRemoving_Added)
task.spawn(PlayerRemoving_Added)
task.spawn(reconnect)
_Players.PlayerAdded:Connect(function(p1554)
	local v1555, v1556 = pcall(function()
		return p1554:IsFriendsWith(_LocalPlayer.UserId)
	end)

	if v1555 then
		if v1556 and not u105(p1554.Name) then
			table.insert(u404, p1554.Name)
		end

		u79(u1340, u404)
	end
end)
task.spawn(function()
	local v1557 = _Players
	local v1558, v1559, v1560 = pairs(v1557:GetPlayers())

	while true do
		local v1561

		v1560, v1561 = v1558(v1559, v1560)

		if v1560 == nil then
			break
		end
		if v1561:IsFriendsWith(_LocalPlayer.UserId) then
			table.insert(u404, v1561.Name)
		end
	end

	u79(u1340, u404)
end)
_LocalPlayer.CharacterAdded:Connect(reconnect)
u3:Init()
-- ================================================================
-- VISUAL PATCH v4: 16:9 anime image clipped to menu bounds
-- Visual-only changes: preserves original tabs, callbacks and features.
-- ================================================================
task.spawn(function()
    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local player = Players.LocalPlayer
    if not player then return end

    local C = {
        panel = Color3.fromRGB(17, 39, 59),
        panel2 = Color3.fromRGB(24, 52, 75),
        button = Color3.fromRGB(40, 72, 96),
        selected = Color3.fromRGB(63, 112, 151),
        border = Color3.fromRGB(106, 176, 220),
        white = Color3.fromRGB(244, 249, 255),
        muted = Color3.fromRGB(191, 211, 228),
    }
    local IMAGE_URL = "https://raw.githubusercontent.com/eduardomorfin58-ux/delta-password-menu/main/IMG_5934.jpeg"
    local IMAGE_FILE = "IMG_5934.jpeg"
    local imageAsset = nil
    pcall(function()
        if type(isfile) == "function" and type(writefile) == "function" and type(getcustomasset) == "function" then
            if not isfile(IMAGE_FILE) then writefile(IMAGE_FILE, game:HttpGet(IMAGE_URL)) end
            imageAsset = getcustomasset(IMAGE_FILE)
        end
    end)

    local function corner(obj, radius)
        if not obj:IsA("GuiObject") then return end
        local x = obj:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
        x.CornerRadius = UDim.new(0, radius)
        x.Parent = obj
    end
    local function stroke(obj, transparency, thickness)
        if not obj:IsA("GuiObject") then return end
        local x = obj:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
        x.Color = C.border; x.Transparency = transparency or 0.48; x.Thickness = thickness or 1
        x.Parent = obj
    end
    local function findWindow(screen)
        if not screen then return nil end
        local title
        for _, d in ipairs(screen:GetDescendants()) do
            if (d:IsA("TextLabel") or d:IsA("TextButton")) and string.find(string.lower(d.Text or ""), "fling things and people", 1, true) then title = d; break end
        end
        if not title then return nil end
        local node, best = title.Parent, nil
        while node and node ~= screen do
            if node:IsA("Frame") then
                local size = node.AbsoluteSize
                if size.X >= 300 and size.Y >= 200 then best = node end
            end
            node = node.Parent
        end
        return best
    end
    local function style(screen)
        if not screen or not screen:IsA("ScreenGui") then return end
        local root = findWindow(screen)
        if not root or root:GetAttribute("GOY_ReferenceStyleV3") then return end
        root:SetAttribute("GOY_ReferenceStyleV3", true)

        -- Match the reference: wide dark-blue glass panel, thin blue outline.
        root.BackgroundColor3 = C.panel
        root.BackgroundTransparency = 0.22
        root.BorderSizePixel = 0
        corner(root, 8); stroke(root, 0.22, 1)
        root.ClipsDescendants = true
        -- Keep the anime background strictly inside the menu window.

        -- Insert the anime image at the back of the actual window, not full-screen.
        if type(imageAsset) == "string" and imageAsset ~= "" then
            local bg = Instance.new("ImageLabel")
            bg.Name = "GOY_AnimeGlassBackground"
            bg.BackgroundTransparency = 1
            bg.BorderSizePixel = 0
            bg.Size = UDim2.fromScale(1, 1)
            bg.AnchorPoint = Vector2.new(0, 0)
            bg.Position = UDim2.fromScale(0, 0)
            bg.Image = imageAsset
            bg.ImageTransparency = 0.12
            bg.ScaleType = Enum.ScaleType.Crop
            -- Fill the full menu area (landscape 16:9 presentation) without spilling outside it.
            bg.ZIndex = 0
            bg.Parent = root
            for _, d in ipairs(root:GetDescendants()) do
                if d ~= bg and d:IsA("GuiObject") and d.ZIndex < 2 then d.ZIndex = 2 end
            end
        else
            warn("[GOY UI] La imagen anime no cargó. El estilo azul sí puede aplicarse; revisa que IMG_5934.jpeg sea público en GitHub.")
        end

        for _, d in ipairs(root:GetDescendants()) do
            if d.Name == "GOY_AnimeGlassBackground" then
                -- Leave the image untouched.
            elseif d:IsA("ScrollingFrame") then
                d.BackgroundColor3 = C.panel
                d.BackgroundTransparency = math.max(d.BackgroundTransparency, 0.24)
                d.BorderSizePixel = 0
                corner(d, 6)
            elseif d:IsA("Frame") then
                d.BorderSizePixel = 0
                if d.BackgroundTransparency < 1 then
                    d.BackgroundColor3 = C.panel2
                    d.BackgroundTransparency = math.max(d.BackgroundTransparency, 0.34)
                    corner(d, 7)
                end
            elseif d:IsA("TextButton") or d:IsA("ImageButton") then
                d.BorderSizePixel = 0
                d.BackgroundColor3 = C.button
                if d.BackgroundTransparency < 1 then d.BackgroundTransparency = math.min(d.BackgroundTransparency, 0.18) end
                corner(d, 7); stroke(d, 0.52, 1)
                if d:IsA("TextButton") then d.TextColor3 = C.white; d.Font = Enum.Font.GothamSemibold end
                if not d:GetAttribute("GOY_HoverV3") then
                    d:SetAttribute("GOY_HoverV3", true)
                    local normal = C.button
                    d.MouseEnter:Connect(function() if d.Parent then TweenService:Create(d, TweenInfo.new(0.12), {BackgroundColor3=C.selected}):Play() end end)
                    d.MouseLeave:Connect(function() if d.Parent then TweenService:Create(d, TweenInfo.new(0.12), {BackgroundColor3=normal}):Play() end end)
                end
            elseif d:IsA("TextBox") then
                d.BackgroundColor3 = C.panel; d.BackgroundTransparency = 0.12
                d.TextColor3 = C.white; d.BorderSizePixel = 0; corner(d, 6); stroke(d, 0.55, 1)
            elseif d:IsA("TextLabel") then
                d.TextColor3 = C.white
                if d.TextSize > 0 and d.TextSize <= 13 then d.TextColor3 = C.muted end
            end
        end
    end

    -- Search all descendants, not just immediate children. Orion/Delta can parent UI differently.
    for _ = 1, 120 do
        pcall(function()
            local pg = player:FindFirstChildOfClass("PlayerGui")
            if pg then
                for _, d in ipairs(pg:GetDescendants()) do
                    if d:IsA("ScreenGui") then style(d) end
                end
            end
            local ok, cg = pcall(function() return game:GetService("CoreGui") end)
            if ok and cg then
                for _, d in ipairs(cg:GetDescendants()) do
                    if d:IsA("ScreenGui") then style(d) end
                end
            end
            -- Some Delta builds place executor interfaces inside gethui().
            if type(gethui) == "function" then
                local okH, hui = pcall(gethui)
                if okH and hui then
                    for _, d in ipairs(hui:GetDescendants()) do
                        if d:IsA("ScreenGui") then style(d) end
                    end
                end
            end
        end)
        task.wait(0.35)
    end
end)


-- GOY FREE v1.5.2: solo indicador compacto de FPS y ping. No modifica los gráficos.
pcall(function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Stats = game:GetService("Stats")
    local player = Players.LocalPlayer
    if not player then return end

    local parent
    pcall(function()
        if type(gethui) == "function" then parent = gethui() end
    end)
    if not parent then pcall(function() parent = game:GetService("CoreGui") end) end
    if not parent then
        pcall(function() parent = player:WaitForChild("PlayerGui", 5) end)
    end
    if not parent then return end

    -- Remove only older GOY performance widgets, not the main menu.
    for _, name in ipairs({"GOY_FREE_GRAPHICS_V15", "GOY_FREE_GRAPHICS_V14", "GOY_FREE_PerformanceStats", "GOY_FREE_MINI_STATS"}) do
        local old = parent:FindFirstChild(name)
        if old then pcall(function() old:Destroy() end) end
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "GOY_FREE_MINI_STATS"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false
    gui.DisplayOrder = 20
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = parent

    local pill = Instance.new("Frame")
    pill.Name = "StatsPill"
    pill.AnchorPoint = Vector2.new(0, 0)
    pill.Position = UDim2.new(0, 8, 0, 8)
    pill.Size = UDim2.new(0, 112, 0, 23)
    pill.BackgroundColor3 = Color3.fromRGB(15, 18, 27)
    pill.BackgroundTransparency = 0.28
    pill.BorderSizePixel = 0
    pill.Parent = gui
    Instance.new("UICorner", pill).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(112, 119, 153)
    stroke.Transparency = 0.55
    stroke.Thickness = 1
    stroke.Parent = pill

    local label = Instance.new("TextLabel")
    label.Name = "StatsText"
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 5, 0, 0)
    label.Size = UDim2.new(1, -10, 1, 0)
    label.Font = Enum.Font.GothamSemibold
    label.Text = "FPS --  ·  PING --"
    label.TextColor3 = Color3.fromRGB(235, 239, 255)
    label.TextSize = 10
    label.TextScaled = false
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.Parent = pill

    task.spawn(function()
        local last = os.clock()
        local frames = 0
        while gui.Parent do
            local ok = pcall(function() RunService.RenderStepped:Wait() end)
            if not ok then break end
            frames += 1
            local now = os.clock()
            if now - last >= 1 then
                local fps = math.floor(frames / math.max(now - last, 0.001) + 0.5)
                frames = 0
                last = now
                local ping = "--"
                pcall(function()
                    local network = Stats:FindFirstChild("Network")
                    local serverStats = network and network:FindFirstChild("ServerStatsItem")
                    local pingItem = serverStats and serverStats:FindFirstChild("Data Ping")
                    if pingItem then ping = tostring(math.floor(pingItem:GetValue() + 0.5)) end
                end)
                if label.Parent then
                    label.Text = string.format("FPS %d  ·  PING %s", fps, ping == "--" and "--" or ping .. "ms")
                    label.TextColor3 = fps >= 55 and Color3.fromRGB(220, 244, 232) or Color3.fromRGB(255, 218, 172)
                end
            end
        end
    end)
end)


-- ================================================================
-- GOY FREE v1.5.3: Player TP avatar thumbnail + live 3D preview.
-- Lightweight: only the selected player's character is mirrored, and
-- only while the preview panel is open (15 updates/second).
-- ================================================================
task.spawn(function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local CoreGui = game:GetService("CoreGui")
    local localPlayer = Players.LocalPlayer
    if not localPlayer then return end

    local function getUIParent()
        local parent
        pcall(function()
            if type(gethui) == "function" then parent = gethui() end
        end)
        if parent then return parent end
        local ok, core = pcall(function() return CoreGui end)
        if ok and core then return core end
        return localPlayer:FindFirstChildOfClass("PlayerGui")
    end

    local function normalize(text)
        return string.lower((tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")))
    end

    local function visibleThroughTree(obj)
        local node = obj
        while node do
            if node:IsA("GuiObject") and not node.Visible then return false end
            if node:IsA("ScreenGui") and not node.Enabled then return false end
            node = node.Parent
        end
        return true
    end

    local function collectScreens()
        local screens, seen = {}, {}
        local roots = {getUIParent(), localPlayer:FindFirstChildOfClass("PlayerGui"), CoreGui}
        local ok, hui = pcall(function()
            if type(gethui) == "function" then return gethui() end
        end)
        if ok and hui then table.insert(roots, hui) end
        for _, root in ipairs(roots) do
            if root then
                if root:IsA("ScreenGui") and not seen[root] then
                    seen[root] = true; table.insert(screens, root)
                end
                pcall(function()
                    for _, child in ipairs(root:GetDescendants()) do
                        if child:IsA("ScreenGui") and not seen[child] then
                            seen[child] = true; table.insert(screens, child)
                        end
                    end
                end)
            end
        end
        return screens
    end

    local function getText(obj)
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            -- Use the original (pre-translation) text so detection keeps working in every language.
            return normalize(obj:GetAttribute("GOY_Orig") or obj.Text)
        end
        return ""
    end

    local function findPlayerTPSelectorIn(screenList)
        local bestHeader, bestSelector, bestScreen, bestGap
        for _, screen in ipairs(screenList) do
            local labels = {}
            pcall(function()
                for _, item in ipairs(screen:GetDescendants()) do
                    if (item:IsA("TextLabel") or item:IsA("TextButton")) and visibleThroughTree(item) then
                        table.insert(labels, item)
                    end
                end
            end)
            for _, header in ipairs(labels) do
                if getText(header) == "player tp" then
                    for _, selector in ipairs(labels) do
                        if getText(selector) == "select player" then
                            local dy = selector.AbsolutePosition.Y - (header.AbsolutePosition.Y + header.AbsoluteSize.Y)
                            if dy >= -4 and dy <= 220 and (not bestGap or dy < bestGap) then
                                bestHeader, bestSelector, bestScreen, bestGap = header, selector, screen, dy
                            end
                        end
                    end
                end
            end
        end
        if not bestSelector then return nil end

        -- Find the compact row that owns the Select Player label.
        local row = nil
        local node = bestSelector.Parent
        while node and node ~= bestScreen do
            if node:IsA("Frame") and node.AbsoluteSize.X >= 170 and node.AbsoluteSize.Y >= 30 and node.AbsoluteSize.Y <= 100 then
                row = node
                break
            end
            node = node.Parent
        end
        if not row then row = bestSelector.Parent end

        -- Most Orion-style dropdowns use a TextButton beneath the row label.
        local field, fieldScore = nil, -math.huge
        if row then
            pcall(function()
                for _, item in ipairs(row:GetDescendants()) do
                    if item:IsA("TextButton") and item ~= bestSelector and visibleThroughTree(item) then
                        local size = item.AbsoluteSize
                        local dy = item.AbsolutePosition.Y - bestSelector.AbsolutePosition.Y
                        if size.X >= 100 and size.Y >= 16 and size.Y <= 50 and dy >= -6 and dy <= 50 then
                            local score = size.X - math.abs(dy) * 2
                            if score > fieldScore then field, fieldScore = item, score end
                        end
                    end
                end
            end)
        end
        return bestHeader, bestSelector, bestScreen, row, field
    end

    local function findPlayerTPSelector()
        -- Fast path: scan only the Orion window instead of every ScreenGui in CoreGui.
        local quick = {}
        local roots = {getUIParent(), localPlayer:FindFirstChildOfClass("PlayerGui"), CoreGui}
        for _, root in ipairs(roots) do
            local orion = root and root:FindFirstChild("Orion")
            if orion and orion:IsA("ScreenGui") then table.insert(quick, orion) end
        end
        if #quick > 0 then return findPlayerTPSelectorIn(quick) end
        return findPlayerTPSelectorIn(collectScreens())
    end

    local function selectedPlayer()
        local wanted = tostring(_G.PlayerToTeleport or "")
        if wanted == "" then return nil end
        local direct = Players:FindFirstChild(wanted)
        if direct then return direct end
        local first = string.match(wanted, "^(%S+)")
        if first then
            direct = Players:FindFirstChild(first)
            if direct then return direct end
        end
        for _, p in ipairs(Players:GetPlayers()) do
            if p.DisplayName == wanted or (first and p.DisplayName == first) then return p end
        end
        return nil
    end

    local uiParent = getUIParent()
    if not uiParent then return end

    -- Never keep two copies of the preview (re-execution): destroying the old overlay also stops its loops.
    do
        local oldOverlay = uiParent:FindFirstChild("GOY_FREE_PLAYER_AVATAR_PREVIEW")
        if oldOverlay then pcall(function() oldOverlay:Destroy() end) end
    end

    local PT_STRINGS = {
        es = {
            title = "VISTA PREVIA DEL JUGADOR",
            selectPlayer = "Selecciona un jugador",
            noPlayer = "No hay jugador seleccionado",
            waiting = "Esperando a que aparezca su personaje...",
            cloneFail = "No se pudo crear la vista 3D",
            pickFirst = "Elige primero un jugador en «Seleccionar jugador»",
            measuring = "EN VIVO · midiendo...",
            live = "EN VIVO · %d act/s (objetivo: %d Hz)",
        },
        en = {
            title = "PLAYER PREVIEW",
            selectPlayer = "Select a player",
            noPlayer = "No player selected",
            waiting = "Waiting for their character to load...",
            cloneFail = "Could not create the 3D view",
            pickFirst = "Pick a player in “Select Player” first",
            measuring = "LIVE · measuring...",
            live = "LIVE · %d upd/s (target: %d Hz)",
        },
        ja = {
            title = "プレイヤープレビュー",
            selectPlayer = "プレイヤーを選択",
            noPlayer = "プレイヤーが選択されていません",
            waiting = "キャラクターの読み込みを待っています...",
            cloneFail = "3Dビューを作成できませんでした",
            pickFirst = "先に「プレイヤー選択」でプレイヤーを選んでください",
            measuring = "ライブ · 計測中...",
            live = "ライブ · %d 回/秒（目標: %d Hz）",
        },
    }
    local function PT(key, ...)
        local set = PT_STRINGS[_G.GOY_LANG] or PT_STRINGS.es
        local text = set[key] or PT_STRINGS.es[key] or key
        if select("#", ...) > 0 then
            local ok, formatted = pcall(string.format, text, ...)
            if ok then return formatted end
        end
        return text
    end
    local overlay = Instance.new("ScreenGui")
    overlay.Name = "GOY_FREE_PLAYER_AVATAR_PREVIEW"
    overlay.ResetOnSpawn = false
    overlay.IgnoreGuiInset = false
    overlay.DisplayOrder = 10000
    overlay.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    overlay.Parent = uiParent

    local avatarButton = Instance.new("ImageButton")
    avatarButton.Name = "SelectedPlayerAvatar"
    avatarButton.Size = UDim2.fromOffset(32, 32)
    avatarButton.BackgroundColor3 = Color3.fromRGB(17, 25, 39)
    avatarButton.BackgroundTransparency = 0.05
    avatarButton.BorderSizePixel = 0
    avatarButton.Image = ""
    avatarButton.ScaleType = Enum.ScaleType.Crop
    avatarButton.AutoButtonColor = false
    avatarButton.Visible = false
    avatarButton.ZIndex = 10002
    avatarButton.Parent = overlay
    Instance.new("UICorner", avatarButton).CornerRadius = UDim.new(0, 8)
    local avatarStroke = Instance.new("UIStroke")
    avatarStroke.Color = Color3.fromRGB(105, 177, 255)
    avatarStroke.Thickness = 1.2
    avatarStroke.Transparency = 0.12
    avatarStroke.Parent = avatarButton

    local panel = Instance.new("Frame")
    panel.Name = "Live3DPlayerPreview"
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.Size = UDim2.new(0.9, 0, 0, 420)
    panel.BackgroundColor3 = Color3.fromRGB(12, 17, 29)
    panel.BackgroundTransparency = 0.04
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.ZIndex = 10010
    panel.Parent = overlay
    local panelConstraint = Instance.new("UISizeConstraint")
    panelConstraint.MinSize = Vector2.new(270, 360)
    panelConstraint.MaxSize = Vector2.new(420, 460)
    panelConstraint.Parent = panel
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 16)
    local panelStroke = Instance.new("UIStroke")
    panelStroke.Color = Color3.fromRGB(75, 135, 210)
    panelStroke.Thickness = 1
    panelStroke.Transparency = 0.18
    panelStroke.Parent = panel

    local topLine = Instance.new("Frame")
    topLine.BackgroundColor3 = Color3.fromRGB(44, 117, 201)
    topLine.BorderSizePixel = 0
    topLine.Size = UDim2.new(1, -28, 0, 2)
    topLine.Position = UDim2.new(0, 14, 0, 54)
    topLine.ZIndex = 10011
    topLine.Parent = panel
    Instance.new("UICorner", topLine).CornerRadius = UDim.new(1, 0)

    local panelTitle = Instance.new("TextLabel")
    panelTitle.BackgroundTransparency = 1
    panelTitle.Position = UDim2.new(0, 16, 0, 9)
    panelTitle.Size = UDim2.new(1, -70, 0, 24)
    panelTitle.Font = Enum.Font.GothamBold
    panelTitle.Text = PT("title")
    panelTitle.TextSize = 14
    panelTitle.TextColor3 = Color3.fromRGB(241, 247, 255)
    panelTitle.TextXAlignment = Enum.TextXAlignment.Left
    panelTitle.ZIndex = 10012
    panelTitle.Parent = panel

    local playerNameLabel = Instance.new("TextLabel")
    playerNameLabel.BackgroundTransparency = 1
    playerNameLabel.Position = UDim2.new(0, 16, 0, 31)
    playerNameLabel.Size = UDim2.new(1, -72, 0, 16)
    playerNameLabel.Font = Enum.Font.Gotham
    playerNameLabel.Text = PT("selectPlayer")
    playerNameLabel.TextSize = 11
    playerNameLabel.TextColor3 = Color3.fromRGB(156, 181, 211)
    playerNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    playerNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    playerNameLabel.ZIndex = 10012
    playerNameLabel.Parent = panel

    local closeButton = Instance.new("TextButton")
    closeButton.Name = "ClosePreview"
    closeButton.AnchorPoint = Vector2.new(1, 0)
    closeButton.Position = UDim2.new(1, -10, 0, 10)
    closeButton.Size = UDim2.fromOffset(28, 28)
    closeButton.BackgroundColor3 = Color3.fromRGB(33, 43, 62)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "×"
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 20
    closeButton.TextColor3 = Color3.fromRGB(234, 243, 255)
    closeButton.ZIndex = 10013
    closeButton.Parent = panel
    Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0, 8)

    local viewport = Instance.new("ViewportFrame")
    viewport.Name = "CharacterViewport"
    viewport.Position = UDim2.new(0, 12, 0, 64)
    viewport.Size = UDim2.new(1, -24, 1, -108)
    viewport.BackgroundColor3 = Color3.fromRGB(18, 27, 43)
    viewport.BackgroundTransparency = 0.05
    viewport.BorderSizePixel = 0
    viewport.Ambient = Color3.fromRGB(190, 202, 225)
    viewport.LightColor = Color3.fromRGB(255, 255, 255)
    viewport.LightDirection = Vector3.new(-1, -1, -1)
    viewport.ZIndex = 10011
    viewport.Parent = panel
    Instance.new("UICorner", viewport).CornerRadius = UDim.new(0, 12)

    local camera = Instance.new("Camera")
    camera.FieldOfView = 38
    camera.Parent = viewport
    viewport.CurrentCamera = camera

    local status = Instance.new("TextLabel")
    status.BackgroundTransparency = 1
    status.Position = UDim2.new(0, 14, 1, -32)
    status.Size = UDim2.new(1, -28, 0, 20)
    status.Font = Enum.Font.GothamMedium
    status.Text = PT("measuring")
    status.TextSize = 10
    status.TextColor3 = Color3.fromRGB(133, 181, 232)
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.ZIndex = 10012
    status.Parent = panel

    -- Localized status line: remembers its key so a language change can re-render it.
    local statusKey, statusArgs = "measuring", {}
    local nameLabelKey = "selectPlayer"
    local function setStatus(key, ...)
        statusKey, statusArgs = key, {...}
        status.Text = PT(key, ...)
    end
    _G.GOY_RefreshPreviewText = function()
        panelTitle.Text = PT("title")
        if nameLabelKey then playerNameLabel.Text = PT(nameLabelKey) end
        status.Text = PT(statusKey, table.unpack(statusArgs))
    end

    local thumbnailCache = {}
    local thumbnailRequested = {}
    local currentSelectedId = nil
    local oldButtonSizes = setmetatable({}, {__mode = "k"})
    local previewTarget, previewCharacter, previewModel, previewWorld
    local partPairs, jointPairs = {}, {}

    local function clearPreviewModel()
        if previewWorld then pcall(function() previewWorld:Destroy() end) end
        previewWorld = nil
        previewModel = nil
        previewTarget = nil
        previewCharacter = nil
        partPairs = {}
        jointPairs = {}
    end

    local function pairHierarchy(source, clone, pairsParts, pairsJoints)
        if source:IsA("BasePart") and clone:IsA("BasePart") then
            table.insert(pairsParts, {source, clone})
        elseif source:IsA("Motor6D") and clone:IsA("Motor6D") then
            table.insert(pairsJoints, {source, clone})
        end
        local sourceChildren = source:GetChildren()
        local cloneChildren = clone:GetChildren()
        local used = {}
        for _, sourceChild in ipairs(sourceChildren) do
            local match, matchIndex
            for index, cloneChild in ipairs(cloneChildren) do
                if not used[index] and cloneChild.Name == sourceChild.Name and cloneChild.ClassName == sourceChild.ClassName then
                    match, matchIndex = cloneChild, index
                    break
                end
            end
            if match then
                used[matchIndex] = true
                pairHierarchy(sourceChild, match, pairsParts, pairsJoints)
            end
        end
    end

    local function preparePreview(target)
        clearPreviewModel()
        previewTarget = target
        previewCharacter = target and target.Character or nil
        if not target then
            nameLabelKey = "selectPlayer"
            playerNameLabel.Text = PT(nameLabelKey)
            setStatus("noPlayer")
            return
        end
        nameLabelKey = nil -- player names come from the game and are never translated
        playerNameLabel.Text = target.DisplayName .. "  ·  @" .. target.Name
        if not previewCharacter or not previewCharacter.Parent then
            setStatus("waiting")
            return
        end

        local originalArchivable = previewCharacter.Archivable
        local clone
        local okClone = pcall(function()
            previewCharacter.Archivable = true
            clone = previewCharacter:Clone()
            previewCharacter.Archivable = originalArchivable
        end)
        pcall(function() previewCharacter.Archivable = originalArchivable end)
        if not okClone or not clone then
            setStatus("cloneFail")
            return
        end

        local nextParts, nextJoints = {}, {}
        pcall(function() pairHierarchy(previewCharacter, clone, nextParts, nextJoints) end)
        -- Remove executable content from the visual clone only.
        for _, descendant in ipairs(clone:GetDescendants()) do
            if descendant:IsA("BaseScript") or descendant:IsA("ModuleScript") then
                pcall(function() descendant:Destroy() end)
            end
        end
        for _, item in ipairs(clone:GetDescendants()) do
            if item:IsA("BasePart") then
                item.Anchored = true
                item.CanCollide = false
                item.CanTouch = false
                item.CanQuery = false
                item.CastShadow = false
            elseif item:IsA("Humanoid") then
                pcall(function()
                    item.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                    item.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
                    item.NameDisplayDistance = 0
                    item.HealthDisplayDistance = 0
                end)
            end
        end

        previewWorld = Instance.new("WorldModel")
        previewWorld.Name = "SelectedCharacterWorld"
        previewWorld.Parent = viewport
        clone.Name = "SelectedCharacterClone"
        clone.Parent = previewWorld
        previewModel = clone
        partPairs = nextParts
        jointPairs = nextJoints
        setStatus("measuring")
    end

    local function updateCamera(target)
        local character = target and target.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local focus = root.Position + Vector3.new(0, 1.25, 0)
        local cameraPosition = root.Position + root.CFrame.LookVector * 8 + Vector3.new(0, 2.1, 0)
        camera.CFrame = CFrame.lookAt(cameraPosition, focus)
    end

    local function setThumbnail(target)
        if not target then
            currentSelectedId = nil
            avatarButton.Image = ""
            avatarButton.Visible = false
            return
        end
        currentSelectedId = target.UserId
        avatarButton.Visible = true
        avatarButton.Image = thumbnailCache[target.UserId] or ("rbxthumb://type=AvatarHeadShot&id=" .. tostring(target.UserId) .. "&w=150&h=150")
        if thumbnailCache[target.UserId] or thumbnailRequested[target.UserId] then return end
        thumbnailRequested[target.UserId] = true
        task.spawn(function()
            local ok, imageUrl = pcall(function()
                local url = Players:GetUserThumbnailAsync(target.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
                return url
            end)
            if ok and type(imageUrl) == "string" and imageUrl ~= "" then
                thumbnailCache[target.UserId] = imageUrl
                if currentSelectedId == target.UserId and avatarButton.Parent then avatarButton.Image = imageUrl end
            end
        end)
    end

    -- Preview loop: connected ONLY while the panel is open. It is driven by RenderStepped with an
    -- accumulator, so the refresh rate is min(menu FPS setting, real frame rate) and costs nothing when closed.
    local previewConn
    local previewAccum, previewCount, previewReportAt, previewTargetCheckAt = 0, 0, 0, 0
    local activeTarget

    local function stopPreviewLoop()
        if previewConn then
            previewConn:Disconnect()
            previewConn = nil
        end
    end

    local function mirrorCharacter()
        for _, pair in ipairs(partPairs) do
            local sourcePart, clonePart = pair[1], pair[2]
            if sourcePart.Parent and clonePart.Parent then
                clonePart.CFrame = sourcePart.CFrame
            end
        end
        for _, pair in ipairs(jointPairs) do
            local sourceJoint, cloneJoint = pair[1], pair[2]
            if sourceJoint.Parent and cloneJoint.Parent then
                cloneJoint.Transform = sourceJoint.Transform
            end
        end
    end

    local function startPreviewLoop()
        if previewConn then return end
        previewAccum, previewCount = 0, 0
        previewReportAt = os.clock()
        previewTargetCheckAt = 0
        previewConn = RunService.RenderStepped:Connect(function(dt)
            if not overlay.Parent or not panel.Visible then
                stopPreviewLoop()
                return
            end
            local now = os.clock()
            -- Re-evaluate the selected player a few times per second, not every frame.
            if now >= previewTargetCheckAt then
                previewTargetCheckAt = now + 0.25
                activeTarget = selectedPlayer()
                if activeTarget ~= previewTarget or (activeTarget and activeTarget.Character ~= previewCharacter) then
                    preparePreview(activeTarget)
                end
            end
            local hz = math.max(1, tonumber(_G.GOY_MENU_UPDATES) or 120)
            previewAccum = previewAccum + dt
            if previewAccum < 1 / hz then return end
            previewAccum = 0
            if activeTarget and previewCharacter and previewModel and previewCharacter.Parent then
                pcall(mirrorCharacter)
                updateCamera(activeTarget)
                if previewCount == 0 then previewReportAt = now end
                previewCount = previewCount + 1
                if now - previewReportAt >= 1 then
                    -- Real measured preview updates per second (not an assumed value).
                    setStatus("live", math.floor(previewCount / (now - previewReportAt) + 0.5), hz)
                    previewCount = 0
                    previewReportAt = now
                end
            elseif activeTarget and statusKey ~= "waiting" then
                setStatus("waiting")
            end
        end)
    end

    avatarButton.Activated:Connect(function()
        local target = selectedPlayer()
        if not target then
            setStatus("pickFirst")
            panel.Visible = true
            startPreviewLoop()
            return
        end
        panel.Visible = not panel.Visible
        if panel.Visible then
            preparePreview(target)
            updateCamera(target)
            startPreviewLoop()
        else
            stopPreviewLoop()
            clearPreviewModel()
        end
    end)
    closeButton.Activated:Connect(function()
        panel.Visible = false
        stopPreviewLoop()
        clearPreviewModel()
    end)

    -- Position the thumbnail directly beside the real Select Player dropdown.
    -- The dropdown is narrowed only enough to reserve a 32px avatar square.
    task.spawn(function()
        local cachedHeader, cachedSelector, cachedScreen, cachedRow, cachedField
        local nextRescan = 0
        while overlay.Parent do
            local target = selectedPlayer()
            if target then
                if currentSelectedId ~= target.UserId then setThumbnail(target) end
            elseif currentSelectedId ~= nil then
                setThumbnail(nil)
            end

            if os.clock() >= nextRescan or not cachedSelector or not cachedSelector.Parent then
                cachedHeader, cachedSelector, cachedScreen, cachedRow, cachedField = findPlayerTPSelector()
                nextRescan = os.clock() + ((cachedSelector and cachedSelector.Parent) and 5 or 2)
            end
            local header, selector, sourceScreen, row, field = cachedHeader, cachedSelector, cachedScreen, cachedRow, cachedField
            if selector and sourceScreen and target then
                if sourceScreen.Parent and overlay.Parent ~= sourceScreen.Parent then
                    pcall(function() overlay.Parent = sourceScreen.Parent end)
                end
                overlay.IgnoreGuiInset = sourceScreen.IgnoreGuiInset
                if field then
                    if not oldButtonSizes[field] then
                        oldButtonSizes[field] = field.Size
                        field.Size = UDim2.new(field.Size.X.Scale, field.Size.X.Offset - 38, field.Size.Y.Scale, field.Size.Y.Offset)
                    end
                    avatarButton.Position = UDim2.fromOffset(
                        math.floor(field.AbsolutePosition.X + field.AbsoluteSize.X + 4),
                        math.floor(field.AbsolutePosition.Y + (field.AbsoluteSize.Y - avatarButton.AbsoluteSize.Y) / 2)
                    )
                elseif row then
                    avatarButton.Position = UDim2.fromOffset(
                        math.floor(row.AbsolutePosition.X + row.AbsoluteSize.X - avatarButton.AbsoluteSize.X - 3),
                        math.floor(row.AbsolutePosition.Y + (row.AbsoluteSize.Y - avatarButton.AbsoluteSize.Y) / 2)
                    )
                else
                    avatarButton.Position = UDim2.fromOffset(
                        math.floor(selector.AbsolutePosition.X + selector.AbsoluteSize.X + 4),
                        math.floor(selector.AbsolutePosition.Y + (selector.AbsoluteSize.Y - avatarButton.AbsoluteSize.Y) / 2)
                    )
                end
                local cameraObject = workspace.CurrentCamera
                if cameraObject then
                    local v = cameraObject.ViewportSize
                    if avatarButton.AbsolutePosition.X > v.X - 36 then
                        avatarButton.Position = UDim2.fromOffset(math.max(4, v.X - 36), math.max(4, avatarButton.AbsolutePosition.Y))
                    end
                end
                avatarButton.Visible = visibleThroughTree(selector)
            else
                avatarButton.Visible = false
            end
            task.wait(avatarButton.Visible and 0.2 or 0.5)
        end
    end)
end)

-- ================================================================
-- GOY FREE v1.5.6: language system (ES / EN / JA), Premium Info controls and Roblox FPS.
--  * One translator walks the Orion window once, remembers each element's ORIGINAL English text
--    (attribute GOY_Orig) and re-applies the chosen language in place. The menu is never rebuilt.
--  * Callbacks/flags keep using the original English values; only the displayed text changes.
--  * Player names / usernames / in-game data are not in the dictionary, so they are never translated.
-- ================================================================
task.spawn(function()
    -- Remove the previous copy of this system if the script is executed again (no duplicates).
    if _G.GOY_I18N_CLEANUP then pcall(_G.GOY_I18N_CLEANUP) end

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local HttpService = game:GetService("HttpService")
    local CoreGui = game:GetService("CoreGui")
    local player = Players.LocalPlayer
    if not player then return end

    ----------------------------------------------------------------
    -- Saved settings (language + menu FPS). Needs executor file functions; otherwise session-only.
    ----------------------------------------------------------------
    local SETTINGS_FILE = "GOY_FREE_settings.json"
    local settings = {lang = "es", menuFps = 120}
    pcall(function()
        if type(isfile) == "function" and type(readfile) == "function" and isfile(SETTINGS_FILE) then
            local data = HttpService:JSONDecode(readfile(SETTINGS_FILE))
            if type(data) == "table" then
                if data.lang == "es" or data.lang == "en" or data.lang == "ja" then settings.lang = data.lang end
                if data.menuFps == 240 or data.menuFps == 144 or data.menuFps == 120 then settings.menuFps = data.menuFps end
            end
        end
    end)
    local function saveSettings()
        return (pcall(function()
            if type(writefile) ~= "function" then error("writefile unavailable") end
            writefile(SETTINGS_FILE, HttpService:JSONEncode(settings))
        end))
    end
    -- Set early: other GOY blocks (3D preview) read these.
    _G.GOY_LANG = settings.lang
    _G.GOY_MENU_UPDATES = settings.menuFps

    task.wait(0.15)
    if not PremiumInfo_Tab then return end

    ----------------------------------------------------------------
    -- Dictionary. Key = original English text exactly as written in the script.
    ----------------------------------------------------------------
    local D = {}
    local function E(en, es, ja) D[en] = {es = es, ja = ja} end

    -- Tabs
    E("Combat", "Combate", "戦闘")
    E("Blobman Grab", "Agarre Blobman", "ブロブマン掴み")
    E("Invincibility", "Invencibilidad", "無敵")
    E("Player", "Jugador", "プレイヤー")
    E("Explosions", "Explosiones", "爆発")
    E("Teleport", "Teletransportar", "テレポート")
    E("Custom Line", "Línea personalizada", "カスタムライン")
    E("Grab Auras", "Auras de agarre", "グラブオーラ")
    E("Keybinds", "Atajos", "キーバインド")
    E("Loop Players", "Jugadores en bucle", "ループ対象")
    E("Auto", "Automático", "オート")
    E("Misc", "Varios", "その他")
    E("Discord Server", "Servidor de Discord", "Discordサーバー")
    E("Config", "Configuración", "設定")
    E("Premium Info", "Info Premium", "プレミアム情報")
    E("Credits", "Créditos", "クレジット")

    -- Sections
    E("1# Medal credits", "Créditos Medal n.º 1", "Medalクレジット #1")
    E("2# Medal credits", "Créditos Medal n.º 2", "Medalクレジット #2")
    E("3# Medal credits", "Créditos Medal n.º 3", "Medalクレジット #3")
    E("Auto Get Coins", "Obtener monedas automáticamente", "コイン自動取得")
    E("Auto Time-Reset", "Reinicio de tiempo automático", "タイム自動リセット")
    E("Auto Claim-Plot", "Reclamar parcela automáticamente", "区画自動取得")
    E("Snowball", "Bola de nieve", "雪玉")
    E("Explosions Spam", "Spam de explosiones", "爆発スパム")
    E("FAQ about (Explosions Spam)", "Preguntas sobre (Spam de explosiones)", "よくある質問（爆発スパム）")
    E("Silent-Aim", "Apuntado silencioso", "サイレントエイム")
    E("Line Extender", "Extensor de línea", "ライン延長")
    E("Normal Auras", "Auras normales", "通常オーラ")
    E("Fling Aura", "Aura de lanzamiento", "フリングオーラ")
    E("Telekinesis Aura", "Aura de telequinesis", "念力オーラ")
    E("Anchor Aura", "Aura de anclaje", "アンカーオーラ")
    E("Kick Aura", "Aura de expulsión", "キックオーラ")
    E("Auras Whitelist", "Lista blanca de auras", "オーラのホワイトリスト")
    E("Strength", "Fuerza", "力")
    E("Others", "Otros", "その他")
    E("Perspective", "Perspectiva", "パースペクティブ")
    E("Annoy Players", "Molestar jugadores", "プレイヤーを妨害")
    E("Kick All", "Expulsar a todos", "全員キック")
    E("Bring All", "Traer a todos", "全員を呼ぶ")
    E("Whitelist", "Lista blanca", "ホワイトリスト")
    E("Invulnerability", "Invulnerabilidad", "不死身")
    E("Counter-Attack", "Contraataque", "カウンター攻撃")
    E("ESP Highlight", "ESP resaltado", "ESPハイライト")
    E("ESP Billboard", "ESP cartel", "ESPビルボード")
    E("Place TP", "TP a lugares", "場所テレポート")
    E("Player TP", "TP a jugador", "プレイヤーTP")
    E("Walkspeed", "Velocidad de caminata", "歩行速度")
    E("Infinite Power Jump", "Salto potente infinito", "無限パワージャンプ")
    E("Change your entire line color", "Cambia el color de toda tu línea", "ライン全体の色を変更")
    E("Line Effects", "Efectos de línea", "ラインエフェクト")
    E("Stress Server", "Estresar servidor", "サーバー負荷")
    E("Spawn Toy", "Generar juguete", "おもちゃ召喚")
    E("Anchor Objects", "Anclar objetos", "オブジェクト固定")
    E("Compile Objects", "Compilar objetos", "オブジェクト結合")
    E("Control Player/NPC", "Controlar jugador/NPC", "プレイヤー/NPC操作")
    E("Blobman Loopkick", "Expulsión en bucle con Blobman", "ブロブマンのループキック")
    E("Anchor Objects/Compiled Groups", "Objetos anclados/Grupos compilados", "固定オブジェクト／結合グループ")
    E("Players in Loop", "Jugadores en el bucle", "ループ中のプレイヤー")
    E("Loop Kill Functions", "Funciones de eliminación en bucle", "ループキル機能")
    E("Loop Kick (Blobman)", "Expulsión en bucle (Blobman)", "ループキック（ブロブマン）")
    E("Loop Kick (Ownership)", "Expulsión en bucle (propiedad)", "ループキック（所有権）")
    E("Destroy Everything", "Destruir todo", "すべて破壊")

    -- Discord tab
    E("Discord Profile", "Perfil de Discord", "Discordプロフィール")
    E("Open Discord Profile", "Abrir perfil de Discord", "Discordプロフィールを開く")
    E("Copy Discord Server Link", "Copiar enlace del servidor de Discord", "Discordサーバーのリンクをコピー")
    E("Join my discord server to see updates!", "¡Únete a mi servidor de Discord para ver las actualizaciones!", "Discordサーバーに参加してアップデートを確認しよう！")

    -- Credits
    E("I made the whole GUI (Combat, Player, Auras and more) XD!", "¡Hice toda la interfaz (Combate, Jugador, Auras y más) XD!", "GUI全体（戦闘、プレイヤー、オーラなど）を作りました XD！")
    E("Thanks for giving me inspiration to create the blobman functions, Massless Grab and Line color changer script!", "¡Gracias por inspirarme a crear las funciones de Blobman, el Agarre sin masa y el script para cambiar el color de la línea!", "ブロブマン機能、マスレスグラブ、ライン色変更スクリプトを作るきっかけをくれてありがとう！")
    E("Thanks for sharing the Attraction Aura, Silent Aim, Further Extend scripts for me!", "¡Gracias por compartir conmigo los scripts de Aura de atracción, Apuntado silencioso y Extensión de línea!", "引き寄せオーラ、サイレントエイム、ライン延長のスクリプトを共有してくれてありがとう！")
    E("Thanks for helping me to fix kick stuff and my anti-blobman", "Gracias por ayudarme a corregir lo de las expulsiones y mi anti-Blobman", "キック関連と私のアンチブロブマンの修正を手伝ってくれてありがとう")
    E("Thanks for explosion stuff, fireproximityprompt fix and script updater", "Gracias por lo de las explosiones, la corrección de fireproximityprompt y el actualizador de scripts", "爆発関連、fireproximityprompt の修正、スクリプトアップデーターをありがとう")
    E("Thanks for laggy stuff!", "¡Gracias por lo del lag!", "ラグ関連をありがとう！")
    E("Thanks for Anchor Objects Glue/Compile", "Gracias por Anclar objetos, Pegar/Compilar", "オブジェクト固定のグルー／結合機能をありがとう")
    E("Thanks for Tornado Shape", "Gracias por la forma de tornado", "竜巻の形状をありがとう")
    E("Thanks for releasing my script!", "¡Gracias por publicar mi script!", "私のスクリプトを公開してくれてありがとう！")
    E("Thanks for testing my scripts", "Gracias por probar mis scripts", "私のスクリプトをテストしてくれてありがとう")

    -- Auto tab
    E("Auto-Spin", "Giro automático", "オートスピン")
    E("Preserve Time", "Conservar tiempo", "時間を維持")
    E("Plot", "Parcela", "区画")
    E("Witch House", "Casa de la bruja", "魔女の家")
    E("Lumber House", "Casa del leñador", "木こりの家")
    E("Common House", "Casa común", "普通の家")
    E("American House", "Casa americana", "アメリカの家")
    E("Chinese House", "Casa china", "中華風の家")
    E("Plot Owner:", "Dueño de la parcela:", "区画の所有者:")
    E("Plot Available!", "¡Parcela disponible!", "区画は空いています！")
    E("Grown Snowballs:", "Bolas de nieve crecidas:", "成長した雪玉:")
    E("Claim Plot!", "¡Reclamar parcela!", "区画を取得！")

    -- Explosions tab
    E("Ammount", "Cantidad", "数量")
    E("Snowballs you want to make to explode them!", "Bolas de nieve que quieres crear para explotarlas", "爆発させるために作る雪玉の数")
    E("Auto Make Snowball", "Crear bolas de nieve automáticamente", "雪玉を自動作成")
    E("Explode Snowballs", "Explotar bolas de nieve", "雪玉を爆発")
    E("Explode", "Explotar", "爆発")
    E("Explosion Type", "Tipo de explosión", "爆発の種類")
    E("Firework", "Fuegos artificiales", "花火")
    E("Missile", "Misil", "ミサイル")
    E("Void", "Vacío", "ヴォイド")
    E("Ballon", "Globo", "風船")
    E("Small Present", "Regalo pequeño", "小さなプレゼント")
    E("Big Present", "Regalo grande", "大きなプレゼント")
    E("Ammount to Explode", "Cantidad a explotar", "爆発させる数")
    E("to explode the player brutally", "para explotar al jugador brutalmente", "プレイヤーを激しく爆破する")
    E("Delay", "Retardo", "遅延")
    E("interval between every explosion", "intervalo entre cada explosión", "爆発ごとの間隔")
    E("Target", "Objetivo", "ターゲット")
    E("Spawn", "Aparición", "スポーン")
    E("Mouse", "Ratón", "マウス")
    E("Select Player", "Seleccionar jugador", "プレイヤー選択")
    E("How to use target mouse?", "¿Cómo usar el objetivo ratón?", "マウスターゲットの使い方は？")
    E("Press/Hold the keybind (F) and then BOOM!", "Pulsa o mantén la tecla (F) y ¡BOOM!", "キー（F）を押す／押し続けると、ドカン！")
    E("How to target player?", "¿Cómo apuntar a un jugador?", "プレイヤーを狙うには？")
    E("Select Target to Player and then select the player you want to target", "Elige Objetivo: Jugador y luego selecciona al jugador al que quieras apuntar", "ターゲットを「プレイヤー」にして、狙いたいプレイヤーを選択します")
    E("How to change the explosive", "¿Cómo cambiar el explosivo?", "爆発物の変更方法は？")
    E("Click on Explosive Type and select any type", "Pulsa Tipo de explosión y elige cualquier tipo", "「爆発の種類」を押して好きな種類を選びます")

    -- Misc tab
    E("Silent Aim", "Apuntado silencioso", "サイレントエイム")
    E("Silent-Aim Range", "Alcance del apuntado silencioso", "サイレントエイムの範囲")
    E("Further Extend", "Extensión adicional", "さらに延長")
    E("Increase Extend", "Aumento de extensión", "延長量")

    -- Auras
    E("Poison Aura", "Aura de veneno", "毒オーラ")
    E("Death Aura", "Aura de muerte", "死のオーラ")
    E("Radioactive Aura", "Aura radiactiva", "放射能オーラ")
    E("Burn Aura", "Aura de fuego", "燃焼オーラ")
    E("Players", "Jugadores", "プレイヤー")
    E("Objects", "Objetos", "オブジェクト")
    E("Players and Objects", "Jugadores y objetos", "プレイヤーとオブジェクト")
    E("Select Mode", "Seleccionar modo", "モード選択")
    E("Click", "Clic", "クリック")
    E("Aura", "Aura", "オーラ")
    E("Shape", "Forma", "形状")
    E("Blackhole", "Agujero negro", "ブラックホール")
    E("Tornado", "Tornado", "竜巻")
    E("Follow Type:", "Tipo de seguimiento:", "追従タイプ:")
    E("Follow Player:", "Seguir jugador:", "追従プレイヤー:")
    E("Distance", "Distancia", "距離")
    E("Height", "Altura", "高さ")
    E("Speed", "Velocidad", "速度")
    E("Rotation Speed", "Velocidad de rotación", "回転速度")
    E("Offset", "Desplazamiento", "オフセット")
    E("Disconnect All", "Desconectar todo", "すべて切断")
    E("Attraction Aura", "Aura de atracción", "引き寄せオーラ")
    E("Kick Type", "Tipo de expulsión", "キックの種類")
    E("Go to the heaven!", "¡Ve al cielo!", "天国へ行け！")
    E("Whitelist Friends", "Lista blanca de amigos", "フレンドをホワイトリストに")

    -- Combat tab
    E("Super Strength", "Superfuerza", "超パワー")
    E("Poison Grab", "Agarre venenoso", "毒グラブ")
    E("Burn Grab", "Agarre ardiente", "燃焼グラブ")
    E("Death Grab", "Agarre mortal", "デスグラブ")
    E("Massless Grab", "Agarre sin masa", "マスレスグラブ")
    E("Radiactive Grab", "Agarre radiactivo", "放射能グラブ")
    E("Noclip Grab", "Agarre Noclip", "ノークリップグラブ")
    E("Perspective Grab", "Agarre en perspectiva", "パースペクティブグラブ")
    E("Fire All", "Prender fuego a todos", "全員を燃やす")
    E("Ragdoll All", "Ragdoll a todos", "全員をラグドール化")
    E("Kill All", "Eliminar a todos", "全員キル")

    -- Invincibility tab
    E("Anti-Grab", "Anti-agarre", "アンチグラブ")
    E("Anti-Burn", "Anti-fuego", "アンチバーン")
    E("Anti-Explosion", "Anti-explosión", "アンチ爆発")
    E("Auto-Attacker", "Atacante automático", "自動攻撃")
    E("Counter Mode", "Modo de contraataque", "カウンターモード")
    E("Repulsion", "Repulsión", "反発")
    E("Freeze", "Congelar", "凍結")
    E("Death", "Muerte", "死")
    E("Kick", "Expulsar", "キック")
    E("Anti-Void", "Anti-vacío", "アンチボイド")
    E("Anti-Lag", "Anti-lag", "アンチラグ")
    E("Anti-Kick", "Anti-expulsión", "アンチキック")

    -- ESP tab
    E("ESP (Highlight)", "ESP (resaltado)", "ESP（ハイライト）")
    E("Fill Color", "Color de relleno", "塗りつぶしの色")
    E("Fill Transparency", "Transparencia del relleno", "塗りつぶしの透明度")
    E("Outline Color", "Color del contorno", "輪郭の色")
    E("Outline Transparency", "Transparencia del contorno", "輪郭の透明度")
    E("Fill color transparency:", "Transparencia del color de relleno:", "塗りつぶしの透明度:")
    E("Outline color transparency:", "Transparencia del color del contorno:", "輪郭の透明度:")
    E("Highlight Mode", "Modo de resaltado", "ハイライトモード")
    E("AlwaysOnTop", "Siempre visible", "常に手前")
    E("Occluded", "Ocultado por objetos", "遮蔽あり")
    E("ESP (Icon)", "ESP (icono)", "ESP（アイコン）")

    -- Teleport tab
    E("Place to Teleport", "Lugar de destino", "テレポート先")
    E("Green House", "Casa verde", "緑の家")
    E("Chinese Safe-House", "Refugio chino", "中華の隠れ家")
    E("Blue Safe-House", "Refugio azul", "青い隠れ家")
    E("Secret Big Cave", "Cueva grande secreta", "秘密の大洞窟")
    E("Secret Train Cave", "Cueva secreta del tren", "秘密の列車洞窟")
    E("Mine Cave", "Cueva de la mina", "鉱山の洞窟")
    E("Farm House", "Casa de campo", "農家")
    E("Witch Safe-House", "Refugio de la bruja", "魔女の隠れ家")
    E("Green Safe-House", "Refugio verde", "緑の隠れ家")
    E("Red Safe-House", "Refugio rojo", "赤い隠れ家")
    E("Loop Teleport", "Teletransporte en bucle", "ループテレポート")
    E("Lock Camera", "Fijar cámara", "カメラ固定")
    E("View", "Ver", "視点")
    E("Teleport Offset", "Desplazamiento del teletransporte", "テレポートのオフセット")
    E("Behavior", "Comportamiento", "動作")
    E("Behind", "Detrás", "後ろ")
    E("Left", "Izquierda", "左")
    E("Right", "Derecha", "右")
    E("Front", "Frente", "前")
    E("Rotate", "Girar", "回転")

    -- Player tab
    E("Infinite Jump", "Salto infinito", "無限ジャンプ")
    E("Jump Power", "Potencia de salto", "ジャンプ力")

    -- Custom Line tab
    E("Lag Server", "Laguear servidor", "サーバーをラグらせる")
    E("Lag Intensity", "Intensidad del lag", "ラグの強さ")
    E("This can have you kicked or kick someone in the server!", "¡Esto puede hacer que te expulsen a ti o a alguien del servidor!", "あなた自身、またはサーバー内の誰かがキックされる可能性があります！")
    E("Choose the color", "Elige el color", "色を選択")
    E("Apply Colors", "Aplicar colores", "色を適用")
    E("Crazy Line (Soft Lag)", "Línea loca (lag leve)", "クレイジーライン（軽いラグ）")
    E("Invisible Line", "Línea invisible", "透明ライン")
    E("Note!", "¡Nota!", "注意！")
    E("You can't see the effects line, but others player can see it. And Invisible Line won't work if Crazy Line is Enabled", "No puedes ver la línea de efectos, pero otros jugadores sí. Y la Línea invisible no funcionará si la Línea loca está activada.", "エフェクトラインはあなたには見えませんが、他のプレイヤーには見えます。また、クレイジーラインが有効な場合、透明ラインは機能しません。")

    -- Keybinds tab
    E("Anchor (K)", "Anclar (K)", "固定 (K)")
    E("Unanchor All", "Desanclar todo", "すべて固定解除")
    E("Compile New Group", "Compilar nuevo grupo", "新しいグループを結合")
    E("Groups", "Grupos", "グループ")
    E("Delete Group", "Eliminar grupo", "グループを削除")
    E("Teleport (Z)", "Teletransporte (Z)", "テレポート (Z)")
    E("Control (C)", "Control (C)", "操作 (C)")
    E("Select Toy", "Seleccionar juguete", "おもちゃを選択")
    E("Pallet", "Palé", "パレット")
    E("Spawn Toy (TAB)", "Generar juguete (TAB)", "おもちゃ召喚 (TAB)")

    -- Config tab
    E("Add", "Añadir", "追加")
    E("Remove", "Quitar", "削除")
    E("Players in Whitelist", "Jugadores en la lista blanca", "ホワイトリストのプレイヤー")
    E("Auto Ownership", "Propiedad automática", "自動オーナーシップ")
    E("Heavy Blobman", "Blobman pesado", "重いブロブマン")
    E("Teleport to Camera Position", "Teletransportar a la posición de la cámara", "カメラ位置へテレポート")
    E("Camera Effect", "Efecto de cámara", "カメラエフェクト")
    E("Default", "Predeterminado", "デフォルト")
    E("Old TV", "TV antigua", "古いテレビ")

    -- Loop Players / Blobman tabs
    E("Loop Kill", "Eliminar en bucle", "ループキル")
    E("Loop Kick", "Expulsar en bucle", "ループキック")
    E("Loop Ragdoll", "Ragdoll en bucle", "ループラグドール")
    E("Loop Fire", "Fuego en bucle", "ループファイア")
    E("Lock", "Bloquear", "ロック")
    E("Bring", "Traer", "呼ぶ")
    E("Destroy Server", "Destruir servidor", "サーバー破壊")

    -- Notifications / popups
    E("Only premium users can control players! Buy premium in my discord server!", "¡Solo los usuarios premium pueden controlar jugadores! ¡Compra premium en mi servidor de Discord!", "プレイヤーを操作できるのはプレミアムユーザーだけです！私のDiscordサーバーでプレミアムを購入してください！")
    E("Only for premium users! Buy premium in my discord server!", "¡Solo para usuarios premium! ¡Compra premium en mi servidor de Discord!", "プレミアムユーザー限定です！私のDiscordサーバーでプレミアムを購入してください！")
    E("You reached the max ammount of players in loop, buy premium to unlock more space!", "¡Alcanzaste el máximo de jugadores en el bucle! ¡Compra premium para desbloquear más espacio!", "ループ内のプレイヤー数の上限に達しました！プレミアムを購入すると枠が増えます！")
    E("You can't use destroy server inside a house!, buy premium to be able to do that!", "¡No puedes usar Destruir servidor dentro de una casa! ¡Compra premium para poder hacerlo!", "家の中ではサーバー破壊を使えません！プレミアムを購入すると使えます！")
    E("Error", "Error", "エラー")
    E("Success", "Éxito", "成功")
    E("No anchored parts found", "No se encontraron piezas ancladas", "固定されたパーツが見つかりません")
    E("Needs at least 2 anchored objects", "Se necesitan al menos 2 objetos anclados", "固定オブジェクトが最低2つ必要です")
    E("You need to hold one of your anchored object", "Debes sostener uno de tus objetos anclados", "固定したオブジェクトのどれかを掴んでいる必要があります")
    E("Stop being greedy!", "¡No seas codicioso!", "欲張らないで！")
    E("You already own infinity house gamepass!", "¡Ya tienes el pase de casa infinita!", "無限ハウスのゲームパスをすでに持っています！")
    E("You need to be seated on Blobman", "Debes estar sentado en un Blobman", "ブロブマンに座る必要があります")
    E("The Blobman needs to be your own toy", "El Blobman debe ser tu propio juguete", "ブロブマンは自分のおもちゃである必要があります")
    E("Please, sit on any Blobman", "Siéntate en cualquier Blobman, por favor", "どれかのブロブマンに座ってください")
    E("Discord server invite copied", "Invitación al servidor de Discord copiada", "Discordサーバーの招待リンクをコピーしました")
    E("Discord profile link copied. Paste it in your browser or Discord.", "Enlace del perfil de Discord copiado. Pégalo en tu navegador o en Discord.", "Discordプロフィールのリンクをコピーしました。ブラウザまたはDiscordに貼り付けてください。")

    -- Premium Info tab (this block's own static text)
    E("Profile", "Perfil", "プロフィール")
    E("Avatar preview", "Vista del avatar", "アバタープレビュー")
    E("Open Player TP and tap a player's thumbnail to see their live 3D view.", "Abre TP a jugador y toca la miniatura de un jugador para ver su vista 3D en vivo.", "プレイヤーTPを開き、プレイヤーのサムネイルをタップするとライブ3Dビューが表示されます。")
    E("Language", "Idioma", "言語")
    E("Menu language", "Idioma del menú", "メニューの言語")
    E("The whole menu changes instantly. You can also use the 🌐 button next to your name. Player names and game data are never translated.", "Todo el menú cambia al instante. También puedes usar el botón 🌐 junto a tu nombre. Los nombres de jugadores y los datos del juego nunca se traducen.", "メニュー全体が即座に切り替わります。名前の横の🌐ボタンでも変更できます。プレイヤー名やゲームのデータは翻訳されません。")
    E("Roblox FPS", "FPS de Roblox", "Roblox FPS")
    E("Game frame-rate cap", "Límite de FPS del juego", "ゲームのフレームレート上限")
    E("Asks your executor to change Roblox's own FPS cap (setfpscap). This affects the game, not the menu. GOY then measures the real FPS; your device may not reach the cap.", "Pide a tu executor que cambie el límite de FPS propio de Roblox (setfpscap). Afecta al juego, no al menú. Después GOY mide los FPS reales; tu dispositivo puede no alcanzar el límite.", "executorにRobloxのFPS上限（setfpscap）の変更を依頼します。対象はゲームで、メニューではありません。その後GOYが実際のFPSを計測します。端末が上限に届かない場合があります。")
    E("Menu FPS (3D previews)", "FPS del menú (vistas 3D)", "メニューFPS（3Dプレビュー）")
    E("Menu update rate", "Frecuencia de actualización del menú", "メニューの更新頻度")
    E("Sets how often GOY's own 3D player previews refresh. It does not change the game's FPS and never exceeds your real frame rate.", "Define cada cuánto se actualizan las vistas 3D de jugadores de GOY. No cambia los FPS del juego y nunca supera tu frecuencia de cuadros real.", "GOY独自の3Dプレイヤープレビューの更新頻度を設定します。ゲームのFPSは変わらず、実際のフレームレートを超えることもありません。")
    E("Optimization", "Optimización", "最適化")
    E("Automatic savings", "Ahorros automáticos", "自動で行われる節約")
    E("3D previews update only while their panel is open and stop when it closes. Thumbnails load once per player, the Player TP search runs rarely, and nothing is duplicated when you change language.", "Las vistas 3D solo se actualizan mientras su panel está abierto y se detienen al cerrarlo. Las miniaturas se cargan una vez por jugador, la búsqueda de TP a jugador se ejecuta pocas veces y no se duplica nada al cambiar de idioma.", "3Dプレビューはパネルが開いている間だけ更新され、閉じると停止します。サムネイルはプレイヤーごとに1回だけ読み込まれ、プレイヤーTPの検索はまれにしか実行されず、言語を変えても何も重複しません。")

    ----------------------------------------------------------------
    -- Prefix and pattern translations for text that carries live values.
    ----------------------------------------------------------------
    local PREFIXES = {
        {en = "Time Remaining: ", es = "Tiempo restante: ", ja = "残り時間: "},
        {en = "Coins Won: ", es = "Monedas ganadas: ", ja = "獲得コイン: "},
        {en = "Plot Time: ", es = "Tiempo de la parcela: ", ja = "区画の時間: "},
        {en = "Time: ", es = "Tiempo: ", ja = "時間: "},
        {en = "Plot Owner: ", es = "Dueño de la parcela: ", ja = "区画の所有者: "},
        {en = "Players in Plot: ", es = "Jugadores en la parcela: ", ja = "区画内のプレイヤー: "},
        {en = "Grown Snowballs: ", es = "Bolas de nieve crecidas: ", ja = "成長した雪玉: "},
    }
    local PATTERNS = {
        {pat = "^Compiled (%d+) Toys together$", es = "Se compilaron %s juguetes juntos", ja = "%s個のおもちゃを結合しました"},
    }

    local function translateLine(text, lang)
        if lang == "en" or text == "" then return text end
        local entry = D[text]
        if entry then return entry[lang] or text end
        for _, p in ipairs(PATTERNS) do
            local caps = {string.match(text, p.pat)}
            if caps[1] ~= nil then
                local ok, out = pcall(string.format, p[lang], table.unpack(caps))
                if ok then return out end
            end
        end
        for _, p in ipairs(PREFIXES) do
            if string.sub(text, 1, #p.en) == p.en then
                return p[lang] .. string.sub(text, #p.en + 1)
            end
        end
        -- Sliders show "<value> <ValueName>".
        local num, rest = string.match(text, "^(%-?%d[%d%.]*) (.+)$")
        if num and D[rest] then return num .. " " .. (D[rest][lang] or rest) end
        return text
    end
    local function translate(text, lang)
        if string.find(text, "\n", 1, true) then
            local out = {}
            for line in string.gmatch(text .. "\n", "(.-)\n") do
                out[#out + 1] = translateLine(line, lang)
            end
            return table.concat(out, "\n")
        end
        return translateLine(text, lang)
    end

    ----------------------------------------------------------------
    -- Runtime strings (dynamic labels, notifications) in the three languages.
    ----------------------------------------------------------------
    local LANG_NAMES = {es = "Español", en = "English", ja = "日本語"}
    local STR = {
        es = {
            profile = "Tu personaje: %s (@%s)",
            langStatus = "Idioma actual: %s",
            langChanged = "Idioma cambiado a %s.",
            langNotSaved = " (No se pudo guardar: tu executor no permite escribir archivos; solo vale para esta sesión.)",
            rfpsNone = "Límite de FPS de Roblox: sin cambios en esta sesión.",
            rfpsMeasuring = "Límite solicitado: %s · midiendo FPS reales...",
            rfpsMeasured = "Límite solicitado: %s · FPS medidos: %d (aprox.)",
            rfpsUnsupported = "Tu executor no ofrece setfpscap: el límite de FPS de Roblox NO se cambió.",
            rfpsFailed = "El executor rechazó el cambio (setfpscap falló): el límite NO se cambió.",
            fmtFps = "%d FPS",
            fmtDefault = "predeterminado (%d)",
            notifyUnsupported = "Tu executor no admite setfpscap, así que el límite de FPS de Roblox NO se cambió.",
            notifyFailed = "Delta rechazó el cambio de límite de FPS (setfpscap falló). No se cambió nada.",
            notifyRequested = "Se solicitó el límite %s a Delta. La medición real aparece en Premium Info.",
            notifyDefaultAssumed = "No se pudo leer el límite original (getfpscap no disponible); se pidió 60, el valor habitual.",
            menuStatus = "Vistas 3D del menú: objetivo %d Hz (nunca supera tus FPS reales).",
            menuSet = "FPS del menú: %d Hz (solo afecta a las vistas 3D del menú, no al juego).",
        },
        en = {
            profile = "Your character: %s (@%s)",
            langStatus = "Current language: %s",
            langChanged = "Language changed to %s.",
            langNotSaved = " (Not saved: your executor cannot write files; this only lasts for this session.)",
            rfpsNone = "Roblox FPS cap: unchanged in this session.",
            rfpsMeasuring = "Requested cap: %s · measuring real FPS...",
            rfpsMeasured = "Requested cap: %s · measured FPS: %d (approx.)",
            rfpsUnsupported = "Your executor has no setfpscap: Roblox's FPS cap was NOT changed.",
            rfpsFailed = "The executor rejected the change (setfpscap failed): the cap was NOT changed.",
            fmtFps = "%d FPS",
            fmtDefault = "default (%d)",
            notifyUnsupported = "Your executor does not support setfpscap, so Roblox's FPS cap was NOT changed.",
            notifyFailed = "Delta rejected the FPS cap change (setfpscap failed). Nothing was changed.",
            notifyRequested = "Requested the %s cap from Delta. The real measurement shows in Premium Info.",
            notifyDefaultAssumed = "Could not read the original cap (getfpscap unavailable); requested 60, the usual value.",
            menuStatus = "Menu 3D previews: target %d Hz (never exceeds your real FPS).",
            menuSet = "Menu FPS: %d Hz (only affects the menu's 3D previews, not the game).",
        },
        ja = {
            profile = "あなたのキャラクター：%s（@%s）",
            langStatus = "現在の言語：%s",
            langChanged = "言語を%sに変更しました。",
            langNotSaved = "（保存できませんでした：executorがファイル書き込みに対応していないため、このセッションのみ有効です。）",
            rfpsNone = "RobloxのFPS上限：このセッションでは変更なし。",
            rfpsMeasuring = "要求した上限：%s · 実際のFPSを計測中...",
            rfpsMeasured = "要求した上限：%s · 計測FPS：%d（概算）",
            rfpsUnsupported = "executorがsetfpscapに対応していないため、RobloxのFPS上限は変更されていません。",
            rfpsFailed = "executorが変更を拒否しました（setfpscap失敗）。上限は変更されていません。",
            fmtFps = "%d FPS",
            fmtDefault = "デフォルト（%d）",
            notifyUnsupported = "executorがsetfpscapに対応していないため、RobloxのFPS上限は変更されていません。",
            notifyFailed = "DeltaがFPS上限の変更を拒否しました（setfpscap失敗）。何も変更されていません。",
            notifyRequested = "Deltaに%sの上限を要求しました。実測値はプレミアム情報に表示されます。",
            notifyDefaultAssumed = "元の上限を取得できなかったため（getfpscapなし）、通常値の60を要求しました。",
            menuStatus = "メニューの3Dプレビュー：目標 %d Hz（実際のFPSを超えません）。",
            menuSet = "メニューFPS：%d Hz（メニューの3Dプレビューのみ。ゲームには影響しません）。",
        },
    }
    local function L() return STR[_G.GOY_LANG] or STR.es end

    local function notify(content)
        pcall(function()
            u3:MakeNotification({
                Name = "GOY FREE",
                Content = content,
                Image = "rbxassetid://16570630989",
                Time = 6,
            })
        end)
    end

    ----------------------------------------------------------------
    -- Translator: tracks text elements of the Orion window; never rebuilds anything.
    ----------------------------------------------------------------
    local tracked = setmetatable({}, {__mode = "k"})
    local protectedNames = {[player.Name] = true, [player.DisplayName] = true}

    local applyTo, onChanged

    applyTo = function(obj)
        local state = tracked[obj]
        if not state or protectedNames[state.orig] then return end
        local nextText = translate(state.orig, _G.GOY_LANG)
        if obj.Text ~= nextText then
            state.applied = nextText
            obj.Text = nextText
        end
    end

    onChanged = function(obj)
        local state = tracked[obj]
        if not state or obj.Text == state.applied then return end
        -- The menu itself set new text (e.g. a live counter): that is the new original.
        state.orig = obj.Text
        obj:SetAttribute("GOY_Orig", obj.Text)
        applyTo(obj)
    end

    local function track(obj)
        if tracked[obj] or obj:GetAttribute("GOY_NoTranslate") then return end
        local text = obj.Text
        tracked[obj] = {orig = text}
        obj:SetAttribute("GOY_Orig", text)
        obj:GetPropertyChangedSignal("Text"):Connect(function() onChanged(obj) end)
        applyTo(obj)
    end

    local function applyAll()
        for obj in pairs(tracked) do
            if obj.Parent then applyTo(obj) end
        end
    end

    ----------------------------------------------------------------
    -- Dynamic labels + controls in Premium Info (built once; text refreshed in place).
    ----------------------------------------------------------------
    local fpsState = {status = "none", value = 0, isDefault = false, measured = 0}
    local origCap
    pcall(function()
        if type(getfpscap) == "function" then
            local current = getfpscap()
            if type(current) == "number" and current > 0 then origCap = current end
        end
    end)

    local profileSection = PremiumInfo_Tab:AddSection({Name = "Profile"})
    local profileLabel = profileSection:AddLabel("")
    profileSection:AddParagraph("Avatar preview", "Open Player TP and tap a player's thumbnail to see their live 3D view.")

    local languageSection = PremiumInfo_Tab:AddSection({Name = "Language"})
    local languageStatus = languageSection:AddLabel("")
    local syncingDropdown = false
    local setLanguage
    local languageDropdown = languageSection:AddDropdown({
        Name = "Menu language",
        Default = LANG_NAMES[_G.GOY_LANG],
        Options = {"Español", "English", "日本語"},
        Callback = function(value)
            if syncingDropdown then return end
            for code, name in pairs(LANG_NAMES) do
                if name == value and setLanguage then setLanguage(code) end
            end
        end,
    })
    languageSection:AddParagraph("Language", "The whole menu changes instantly. You can also use the 🌐 button next to your name. Player names and game data are never translated.")

    local gameSection = PremiumInfo_Tab:AddSection({Name = "Roblox FPS"})
    gameSection:AddParagraph("Game frame-rate cap", "Asks your executor to change Roblox's own FPS cap (setfpscap). This affects the game, not the menu. GOY then measures the real FPS; your device may not reach the cap.")
    local gameStatus = gameSection:AddLabel("")

    local menuSection = PremiumInfo_Tab:AddSection({Name = "Menu FPS (3D previews)"})
    menuSection:AddParagraph("Menu update rate", "Sets how often GOY's own 3D player previews refresh. It does not change the game's FPS and never exceeds your real frame rate.")
    local menuStatus = menuSection:AddLabel("")

    local optimizationSection = PremiumInfo_Tab:AddSection({Name = "Optimization"})
    optimizationSection:AddParagraph("Automatic savings", "3D previews update only while their panel is open and stop when it closes. Thumbnails load once per player, the Player TP search runs rarely, and nothing is duplicated when you change language.")

    local function safeSet(label, text)
        if label then pcall(function() label:Set(text) end) end
    end
    local function fpsStatusText()
        local s = L()
        if fpsState.status == "unsupported" then return s.rfpsUnsupported end
        if fpsState.status == "failed" then return s.rfpsFailed end
        if fpsState.status == "none" then return s.rfpsNone end
        local requested = fpsState.isDefault and string.format(s.fmtDefault, fpsState.value) or string.format(s.fmtFps, fpsState.value)
        if fpsState.status == "measuring" then return string.format(s.rfpsMeasuring, requested) end
        return string.format(s.rfpsMeasured, requested, fpsState.measured)
    end
    local function refreshDynamic()
        local s = L()
        safeSet(profileLabel, string.format(s.profile, player.DisplayName or player.Name, player.Name))
        safeSet(languageStatus, string.format(s.langStatus, LANG_NAMES[_G.GOY_LANG]))
        safeSet(gameStatus, fpsStatusText())
        safeSet(menuStatus, string.format(s.menuStatus, tonumber(_G.GOY_MENU_UPDATES) or 120))
    end

    -- Roblox (game) FPS: real call to setfpscap if the executor has it; measured afterwards.
    local measureToken = 0
    local function measureFps(duration, onDone)
        local frames, startedAt = 0, os.clock()
        local conn
        conn = RunService.RenderStepped:Connect(function()
            frames = frames + 1
            local elapsed = os.clock() - startedAt
            if elapsed >= duration then
                conn:Disconnect()
                onDone(frames / elapsed)
            end
        end)
    end

    local function applyRobloxFps(choice)
        local s = L()
        local setCap = (type(setfpscap) == "function") and setfpscap or nil
        if not setCap then
            fpsState.status = "unsupported"
            refreshDynamic()
            notify(s.notifyUnsupported)
            return
        end
        local isDefault = (choice == "default")
        local value = isDefault and (origCap or 60) or choice
        local ok = pcall(setCap, value)
        if not ok then
            fpsState.status = "failed"
            refreshDynamic()
            notify(s.notifyFailed)
            return
        end
        fpsState.status, fpsState.value, fpsState.isDefault = "measuring", value, isDefault
        refreshDynamic()
        local shown = isDefault and string.format(s.fmtDefault, value) or string.format(s.fmtFps, value)
        notify(string.format(s.notifyRequested, shown))
        if isDefault and not origCap then notify(s.notifyDefaultAssumed) end
        measureToken = measureToken + 1
        local myToken = measureToken
        task.delay(0.75, function()
            if myToken ~= measureToken then return end
            measureFps(2, function(fps)
                if myToken ~= measureToken then return end
                fpsState.status, fpsState.measured = "measured", math.floor(fps + 0.5)
                refreshDynamic()
            end)
        end)
    end

    for _, fps in ipairs({240, 144, 120, 60, 30}) do
        gameSection:AddButton({Name = fps .. " FPS", Callback = function() applyRobloxFps(fps) end})
    end
    gameSection:AddButton({Name = "Default", Callback = function() applyRobloxFps("default") end})

    -- Menu FPS: update budget for GOY's own 3D previews (read by the preview loop every frame).
    local function setMenuFps(hz)
        _G.GOY_MENU_UPDATES = hz
        settings.menuFps = hz
        saveSettings()
        refreshDynamic()
        notify(string.format(L().menuSet, hz))
    end
    for _, hz in ipairs({240, 144, 120}) do
        menuSection:AddButton({Name = hz .. " FPS", Callback = function() setMenuFps(hz) end})
    end

    ----------------------------------------------------------------
    -- Locate the Orion window, translate it, and build the 🌐 selector next to the avatar/name.
    ----------------------------------------------------------------
    local TITLE_TEXT = "fling things and people"
    local function screenHasTitle(screen)
        for _, d in ipairs(screen:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextButton") then
                if string.lower(d.Text or "") == TITLE_TEXT then return d end
            end
        end
        return nil
    end
    local function findOrionScreen(deep)
        local roots = {}
        pcall(function() if type(gethui) == "function" then roots[#roots + 1] = gethui() end end)
        roots[#roots + 1] = CoreGui
        roots[#roots + 1] = player:FindFirstChildOfClass("PlayerGui")
        for _, root in ipairs(roots) do
            if root then
                for _, child in ipairs(root:GetChildren()) do
                    if child:IsA("ScreenGui") and not string.find(child.Name, "^GOY_") and (child.Name == "Orion" or (deep and child.Name ~= "RobloxGui")) then
                        local title = screenHasTitle(child)
                        if title then return child, title end
                    end
                end
            end
        end
        return nil
    end
    local function windowRootFrom(screen, title)
        local node, best = title.Parent, nil
        while node and node ~= screen do
            if node:IsA("Frame") and node.AbsoluteSize.X >= 300 and node.AbsoluteSize.Y >= 200 then best = node end
            node = node.Parent
        end
        return best
    end

    local screenConn, langButton, langPanel, shrunkLabel, shrunkLabelSize
    _G.GOY_I18N_CLEANUP = function()
        if screenConn then screenConn:Disconnect() screenConn = nil end
        if langButton then pcall(function() langButton:Destroy() end) end
        if langPanel then pcall(function() langPanel:Destroy() end) end
        if shrunkLabel and shrunkLabelSize then pcall(function() shrunkLabel.Size = shrunkLabelSize end) end
    end

    local C = {
        panel = Color3.fromRGB(17, 39, 59),
        button = Color3.fromRGB(40, 72, 96),
        selected = Color3.fromRGB(63, 112, 151),
        border = Color3.fromRGB(106, 176, 220),
        white = Color3.fromRGB(244, 249, 255),
    }
    local LANG_OPTIONS = {
        {code = "es", text = "🇪🇸 Español"},
        {code = "en", text = "🇺🇸 English"},
        {code = "ja", text = "🇯🇵 日本語"},
    }
    local optionButtons = {}

    local function styleBox(obj, radius, transparency)
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, radius)
        corner.Parent = obj
        local stroke = Instance.new("UIStroke")
        stroke.Color = C.border
        stroke.Transparency = transparency
        stroke.Thickness = 1
        stroke.Parent = obj
    end
    local function refreshOptionHighlight()
        for code, btn in pairs(optionButtons) do
            btn.BackgroundColor3 = (code == _G.GOY_LANG) and C.selected or C.button
        end
    end

    local function buildSelector(screen, root)
        -- Find the row that shows the player's avatar + name (match by ORIGINAL text).
        local nameLabel, fallbackLabel
        for _, d in ipairs(screen:GetDescendants()) do
            if d:IsA("TextLabel") then
                local text = d:GetAttribute("GOY_Orig") or d.Text
                if (text == player.DisplayName or text == player.Name) and d.Parent and d.Parent:IsA("GuiObject") then
                    local hasImage = false
                    for _, sibling in ipairs(d.Parent:GetDescendants()) do
                        if sibling:IsA("ImageLabel") or sibling:IsA("ImageButton") then hasImage = true break end
                    end
                    if hasImage then nameLabel = d break end
                    fallbackLabel = fallbackLabel or d
                end
            end
        end
        nameLabel = nameLabel or fallbackLabel

        local button = Instance.new("TextButton")
        button.Name = "GOY_LanguageButton"
        button.Text = "🌐"
        button.Font = Enum.Font.GothamBold
        button.TextSize = 16
        button.TextColor3 = C.white
        button.BackgroundColor3 = C.button
        button.BackgroundTransparency = 0.12
        button.AutoButtonColor = true
        button.Size = UDim2.fromOffset(30, 30)
        button.ZIndex = 60
        button:SetAttribute("GOY_NoTranslate", true)
        styleBox(button, 8, 0.45)

        if nameLabel then
            -- Sits at the right end of the avatar/name row; the name is narrowed a little so they don't overlap.
            button.AnchorPoint = Vector2.new(1, 0.5)
            button.Position = UDim2.new(1, -4, 0.5, 0)
            button.Parent = nameLabel.Parent
            shrunkLabel, shrunkLabelSize = nameLabel, nameLabel.Size
            pcall(function()
                nameLabel.Size = UDim2.new(nameLabel.Size.X.Scale, nameLabel.Size.X.Offset - 34, nameLabel.Size.Y.Scale, nameLabel.Size.Y.Offset)
                nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
            end)
        else
            -- The avatar/name row could not be detected: put the button in the window's bottom-right corner.
            warn("[GOY FREE] No se encontró la fila de avatar/nombre; el botón 🌐 se colocó en la esquina inferior derecha del menú.")
            button.AnchorPoint = Vector2.new(1, 1)
            button.Position = UDim2.new(1, -8, 1, -8)
            button.Parent = root
        end
        langButton = button

        local panelWidth, panelHeight = 170, 3 * 36 + 14
        local panel = Instance.new("Frame")
        panel.Name = "GOY_LanguagePanel"
        panel.Size = UDim2.fromOffset(panelWidth, panelHeight)
        panel.AnchorPoint = Vector2.new(0, 1)
        panel.BackgroundColor3 = C.panel
        panel.BackgroundTransparency = 0.06
        panel.BorderSizePixel = 0
        panel.Visible = false
        panel.ZIndex = 80
        panel.Parent = root
        styleBox(panel, 10, 0.25)
        langPanel = panel

        for index, option in ipairs(LANG_OPTIONS) do
            local optionButton = Instance.new("TextButton")
            optionButton.Name = "Option_" .. option.code
            optionButton.Text = option.text
            optionButton.Font = Enum.Font.GothamSemibold
            optionButton.TextSize = 14
            optionButton.TextColor3 = C.white
            optionButton.BackgroundColor3 = C.button
            optionButton.BackgroundTransparency = 0.1
            optionButton.AutoButtonColor = true
            optionButton.Size = UDim2.new(1, -12, 0, 32)
            optionButton.Position = UDim2.fromOffset(6, 7 + (index - 1) * 36)
            optionButton.ZIndex = 81
            optionButton:SetAttribute("GOY_NoTranslate", true)
            optionButton.Parent = panel
            styleBox(optionButton, 8, 0.55)
            optionButtons[option.code] = optionButton
            optionButton.Activated:Connect(function()
                panel.Visible = false
                setLanguage(option.code)
            end)
        end
        refreshOptionHighlight()

        button.Activated:Connect(function()
            if panel.Visible then
                panel.Visible = false
                return
            end
            -- Place the panel just above the button, inside the menu bounds.
            local relative = button.AbsolutePosition - root.AbsolutePosition
            local x = math.clamp(relative.X, 6, math.max(6, root.AbsoluteSize.X - panelWidth - 6))
            local y = math.max(relative.Y - 4, panelHeight + 6)
            panel.Position = UDim2.fromOffset(x, y)
            refreshOptionHighlight()
            panel.Visible = true
        end)
        root:GetPropertyChangedSignal("Visible"):Connect(function()
            if not root.Visible then panel.Visible = false end
        end)
    end

    ----------------------------------------------------------------
    -- Language switch: re-translates in place, syncs every control, updates the preview. No rebuild.
    ----------------------------------------------------------------
    setLanguage = function(code)
        if not LANG_NAMES[code] or code == _G.GOY_LANG then return end
        _G.GOY_LANG = code
        settings.lang = code
        local saved = saveSettings()
        applyAll()
        refreshDynamic()
        refreshOptionHighlight()
        syncingDropdown = true
        pcall(function() languageDropdown:Set(LANG_NAMES[code]) end)
        syncingDropdown = false
        if _G.GOY_RefreshPreviewText then pcall(_G.GOY_RefreshPreviewText) end
        local s = L()
        notify(string.format(s.langChanged, LANG_NAMES[code]) .. (saved and "" or s.langNotSaved))
    end

    refreshDynamic()

    -- Wait for the Orion window (it is created by u3:Init() right before this block).
    local screen, title
    for attempt = 1, 60 do
        screen, title = findOrionScreen(attempt > 10)
        if screen then break end
        task.wait(0.5)
    end
    if not screen then
        warn("[GOY FREE] No se encontró la ventana del menú: el idioma no se pudo aplicar al menú (los textos siguen en inglés).")
        return
    end
    local root = windowRootFrom(screen, title) or screen

    -- Initial pass (yielding every 200 elements so the game never hitches), then follow new elements.
    local descendants = screen:GetDescendants()
    for index, d in ipairs(descendants) do
        if d:IsA("TextLabel") or d:IsA("TextButton") then track(d) end
        if index % 200 == 0 then task.wait() end
    end
    screenConn = screen.DescendantAdded:Connect(function(d)
        if d:IsA("TextLabel") or d:IsA("TextButton") then
            task.defer(function()
                if d.Parent then track(d) end
            end)
        end
    end)
    buildSelector(screen, root)
    refreshDynamic()
end)

-- =====================================================================
-- =====================================================================
-- GOY | REMOTE SPY v1.5.7 (solo lectura) + REGISTRO POR BOTÓN + SERVIDOR + IA
-- v1.5.7.9: respuestas y códigos largos (hasta 10,000 líneas, por partes), botón Leer script, más contexto para la IA.
-- v1.5.7.8: analizador/corrector del servidor con registro del proceso y más arreglos; la IA responde Proceso/Fallos/Código/Cambios.
-- Se abre desde la pestaña "Premium Info" del menú. NO toca botones, funciones
-- ni animaciones del menú: solo agrega su propia ventana.
--
-- Escucha SOLO señales entrantes (RemoteEvent/UnreliableRemoteEvent.OnClientEvent).
-- No envía, no repite, no bloquea ni manipula remotos de nadie.
--
-- Config de la IA: se lee de un archivo de config (GitHub o local). Ninguna clave
-- va escrita en el script; la clave vive en tu worker, detrás de la URL.
-- =====================================================================
task.spawn(function()
    if not PremiumInfo_Tab then return end
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local me = Players.LocalPlayer
    if not me then return end

    local ENV = (type(getgenv) == "function" and getgenv()) or _G
    ENV.GOY_SIGNAL_VIEWER_TOKEN = (ENV.GOY_SIGNAL_VIEWER_TOKEN or 0) + 1
    local MY_TOKEN = ENV.GOY_SIGNAL_VIEWER_TOKEN
    local function alive() return ENV.GOY_SIGNAL_VIEWER_TOKEN == MY_TOKEN end
    -- Zona compartida con tus demás paneles (zona privada): aquí quedan la señal
    -- seleccionada, el registro por botón y un gancho para abrir la IA.
    ENV.GOY = ENV.GOY or {}
    local SHARED = ENV.GOY

    ---------------- AJUSTES ----------------
    local MAX_GROUPS = 400
    local MAX_ALERTS = 120
    local MAX_ARG_TEXT = 500
    local MAX_DETAIL_PER_SEC = 60
    local UI_REFRESH = 0.4
    local ROWS_SHOWN = 80
    local ALERT_COOLDOWN = 3
    local ALERT_RATE = 8            -- más de N por segundo = marcado como alerta (amarillo)
    local BUTTON_WINDOW = 1.2       -- s: señales del servidor tras pulsar un botón se le atribuyen
    -- Config de la IA (solo URLs, SIN claves). Puedes cambiar CONFIG_URL por el tuyo.
    local CONFIG_URL = "https://raw.githubusercontent.com/eduardomorfin58-ux/Ree/main/GOY_RemoteSpr/ia_config.json"
    local CONFIG_LOCAL = "GOY_IA_config.json"   -- si existe en tu ejecutor, manda sobre el de GitHub
    local DEFAULT_AI_URL = "https://text.pollinations.ai/openai"  -- IA pública sin clave (respaldo)
    local DEFAULT_AI_GET = "https://text.pollinations.ai/"
    local AI_SYSTEM = "Eres la IA de GOY, un asistente experto en Roblox Luau, dentro de un panel de chat. "
        .. "Responde siempre en español, claro y directo, como un buen compañero programador: primero la respuesta, luego lo necesario. "
        .. "Puedes conversar, responder preguntas, explicar señales que el servidor envió al jugador, y revisar, corregir o escribir código que el usuario te pida. "
        .. "Cuando des código, ponlo completo dentro de un solo bloque ```lua ... ``` sin partes omitidas, y después explica en 1 a 3 líneas qué cambiaste. "
        .. "En Scripts del servidor del propio usuario añade validaciones de tipos, rangos, dueño, cooldown (que se guarde de verdad), Humanoid vivo y limpieza en PlayerRemoving. "
        .. "Reglas para que el código funcione a la primera: usa Luau moderno de Roblox (task.wait/task.spawn, game:GetService, :WaitForChild para lo que tarda en cargar), "
        .. "nada de funciones obsoletas (wait, spawn, delay), protege con pcall lo que puede fallar, revisa que cada function/if/for cierre con end, "
        .. "di dónde va (LocalScript, Script o ModuleScript y en qué carpeta), y no inventes nombres del juego: si no los sabes, ponlos como variables arriba para que el usuario los cambie. "
        .. "Puedes escribir respuestas y códigos largos (hasta 10,000 líneas). Si no te cabe, detente al final de una línea completa: el panel te pedirá que continúes y unirá las partes. "
        .. "Cuando el usuario te pase un script, léelo entero: di para qué sirve cada parte (servicios, remotos, funciones, botones del menú), qué partes se parecen o hacen lo mismo, y usa esos mismos nombres y estilo al escribir código nuevo. "
        .. "Usa **negrita** solo para lo importante. Si algo no está claro, pregunta una sola cosa."
    --------------------------------------

    local C = {
        bg = Color3.fromRGB(18, 28, 46), panel = Color3.fromRGB(12, 19, 33),
        btn = Color3.fromRGB(40, 56, 82), btnOn = Color3.fromRGB(46, 120, 196),
        ok = Color3.fromRGB(46, 160, 96), warn = Color3.fromRGB(196, 150, 40),
        row = Color3.fromRGB(34, 48, 72), rowSel = Color3.fromRGB(52, 92, 150),
        stroke = Color3.fromRGB(70, 118, 176), text = Color3.fromRGB(236, 241, 249),
        dim = Color3.fromRGB(150, 166, 190),
        mine = Color3.fromRGB(120, 210, 140), other = Color3.fromRGB(240, 180, 90),
        general = Color3.fromRGB(150, 180, 230), alert = Color3.fromRGB(240, 205, 90),
        button = Color3.fromRGB(150, 140, 230), server = Color3.fromRGB(110, 200, 230),
    }
    -- Colores del "editor de código" (resaltado).
    local HI = {
        kw = "e06c9b", str = "9ece6a", num = "e5a06a", com = "5c6f8a",
        glob = "7aa2f7", punc = "a9b2c3", name = "e0e6f0",
    }

    local function notify(text)
        if type(u33) == "function" then pcall(u33, text) end
    end

    ---------------- Formato de argumentos ----------------
    local function pathOf(inst)
        local ok, full = pcall(function() return inst:GetFullName() end)
        if not ok then return "<instancia>" end
        local svc, rest = string.match(full, "^([^%.]+)%.?(.*)$")
        if svc and pcall(function() return game:GetService(svc) end) then
            return ('game:GetService("%s")'):format(svc) .. (rest ~= "" and ("." .. rest) or "")
        end
        return full
    end
    local function fmt(v, depth)
        depth = depth or 0
        local t = typeof(v)
        if t == "string" then
            return string.format("%q", #v > MAX_ARG_TEXT and (string.sub(v, 1, MAX_ARG_TEXT) .. "…") or v)
        elseif t == "number" or t == "boolean" or t == "nil" then return tostring(v)
        elseif t == "Instance" then
            if v:IsA("Player") then return ('game:GetService("Players")["%s"]'):format(v.Name) end
            return pathOf(v)
        elseif t == "CFrame" then return "CFrame.new(" .. table.concat({v:GetComponents()}, ", ") .. ")"
        elseif t == "Vector3" then return ("Vector3.new(%s, %s, %s)"):format(v.X, v.Y, v.Z)
        elseif t == "Vector2" then return ("Vector2.new(%s, %s)"):format(v.X, v.Y)
        elseif t == "Color3" then return ("Color3.new(%s, %s, %s)"):format(v.R, v.G, v.B)
        elseif t == "EnumItem" then return tostring(v)
        elseif t == "table" then
            if depth >= 2 then return "{…}" end
            local parts, n = {}, 0
            for k, val in pairs(v) do
                n = n + 1
                if n > 25 then parts[#parts + 1] = "…"; break end
                parts[#parts + 1] = ("[%s] = %s"):format(fmt(k, depth + 1), fmt(val, depth + 1))
            end
            return "{" .. table.concat(parts, ", ") .. "}"
        end
        return t .. "(" .. tostring(v) .. ")"
    end

    ---------------- Jugadores involucrados ----------------
    local function playerOf(v)
        local t = typeof(v)
        if t == "Instance" then
            if v:IsA("Player") then return v end
            local ok, plr = pcall(function()
                local model = v:IsA("Model") and v or v:FindFirstAncestorOfClass("Model")
                while model do
                    local p = Players:GetPlayerFromCharacter(model)
                    if p then return p end
                    model = model:FindFirstAncestorOfClass("Model")
                end
                return nil
            end)
            if ok then return plr end
        elseif t == "number" then
            if v == me.UserId then return me end
        elseif t == "string" then
            if v == me.Name then return me end
            local p = Players:FindFirstChild(v)
            if p and p:IsA("Player") then return p end
        end
        return nil
    end
    local function collectPlayers(args, n)
        local found, list = {}, {}
        local function visit(v, depth)
            local p = playerOf(v)
            if p and not found[p] then found[p] = true; list[#list + 1] = p end
            if typeof(v) == "table" and depth < 2 then
                for _, val in pairs(v) do visit(val, depth + 1) end
            end
        end
        for i = 1, n do visit(args[i], 0) end
        return list, found
    end

    ---------------- Estado ----------------
    local state = {
        listening = false, mode = "all", tab = "Todas", search = "",
        groups = {}, order = {}, alerts = {},
        totals = {["Mías"] = 0, ["Otros"] = 0, ["Generales"] = 0},
        perPlayer = {}, ignored = {}, buttons = {}, buttonOrder = {},
        conns = {}, watchConns = {}, btnConns = {},
        dirty = true, seq = 0, dropped = 0,
        secStart = os.clock(), secCount = 0,
        selectedKey = nil, lastAlertBy = {},
        lastButton = nil, lastButtonAt = -10,
        serverSrc = "", serverReport = "", serverFixed = "", useCtx = true, events = {}, eventSel = nil,
        config = nil, configErr = nil,
    }
    SHARED.spy = state

    ---------------- "Editor de código": reconstrucción + resaltado ----------------
    local function esc(s) return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")) end
    -- Resalta una línea de pseudo-Lua con RichText (sin regex pesadas: por tokens simples).
    local KEYWORDS = {["local"]=1,["function"]=1,["end"]=1,["return"]=1,["true"]=1,["false"]=1,["nil"]=1,["and"]=1,["or"]=1,["not"]=1,["if"]=1,["then"]=1,["for"]=1,["in"]=1,["do"]=1}
    local GLOBALS = {["game"]=1,["workspace"]=1,["script"]=1,["Instance"]=1,["CFrame"]=1,["Vector3"]=1,["Vector2"]=1,["Color3"]=1,["Enum"]=1,["math"]=1,["table"]=1,["string"]=1,["task"]=1}
    local function span(color, s) return ('<font color="#%s">%s</font>'):format(color, s) end
    local function colorizeLine(line)
        -- Comentario de línea completa.
        local comment = string.match(line, "^%s*%-%-")
        if comment then return span(HI.com, esc(line)) end
        local out, i, n = {}, 1, #line
        while i <= n do
            local c = line:sub(i, i)
            local two = line:sub(i, i + 1)
            if two == "--" then
                out[#out + 1] = span(HI.com, esc(line:sub(i))); break
            elseif c == '"' or c == "'" then
                local j = i + 1
                while j <= n do
                    local cj = line:sub(j, j)
                    if cj == "\\" then j = j + 2
                    elseif cj == c then break
                    else j = j + 1 end
                end
                out[#out + 1] = span(HI.str, esc(line:sub(i, math.min(j, n))))
                i = j + 1
            elseif c:match("%d") then
                local tok = line:match("^[%d%.%-]+", i) or c
                out[#out + 1] = span(HI.num, esc(tok)); i = i + #tok
            elseif c:match("[%a_]") then
                local tok = line:match("^[%w_]+", i)
                if KEYWORDS[tok] then out[#out + 1] = span(HI.kw, tok)
                elseif GLOBALS[tok] then out[#out + 1] = span(HI.glob, tok)
                else out[#out + 1] = span(HI.name, esc(tok)) end
                i = i + #tok
            elseif c:match("[%(%)%{%}%[%]%.,:=]") then
                out[#out + 1] = span(HI.punc, esc(c)); i = i + 1
            else
                out[#out + 1] = esc(c); i = i + 1
            end
        end
        return table.concat(out)
    end
    local function colorize(src)
        local lines = {}
        for line in (src .. "\n"):gmatch("(.-)\n") do lines[#lines + 1] = colorizeLine(line) end
        return table.concat(lines, "\n")
    end
    -- Pseudo-código (solo lectura) de lo que LLEGÓ por OnClientEvent. No es ejecutable.
    local function codeOf(g)
        if g.custom then return g.custom end
        local tag = g.zone == "Mías" and "Mía" or (g.zone == "Otros" and "Otro jugador" or "General")
        local who = #g.players > 0 and (" · " .. table.concat(g.players, ", ")) or ""
        local names = {}
        for i = 1, #g.args do names[i] = "a" .. i end
        local lines = {
            ("-- %s · %s%s · %s · ×%d"):format(g.name, tag, who, g.last, g.count),
            ('local remote = %s'):format(g.path),
            ('remote.OnClientEvent:Connect(function(%s)'):format(table.concat(names, ", ")),
            "    -- el servidor te envió estos argumentos:",
        }
        for i, a in ipairs(g.args) do lines[#lines + 1] = ("    local %s = %s"):format(names[i], a) end
        lines[#lines + 1] = "end)"
        return table.concat(lines, "\n")
    end

    ---------------- Captura agrupada ----------------
    local function touch(key)
        for i, k in ipairs(state.order) do if k == key then table.remove(state.order, i); break end end
        table.insert(state.order, 1, key)
        while #state.order > MAX_GROUPS do
            local old = table.remove(state.order); state.groups[old] = nil
        end
    end
    local function recordButtonSignal(g)
        local now = os.clock()
        if not state.lastButton or now - state.lastButtonAt > BUTTON_WINDOW then return end
        local b = state.buttons[state.lastButton]
        if not b then return end
        b.signals[g.key] = b.signals[g.key] or {name = g.name, zone = g.zone, code = ""}
        b.signals[g.key].code = codeOf(g)
        b.count = b.count + 1
        b.last = os.date("%H:%M:%S")
    end
    local function record(remote, args, n)
        if not state.listening or state.ignored[remote.Name] then return end
        local now = os.clock()
        if now - state.secStart >= 1 then state.secStart, state.secCount = now, 0 end
        local plist, pset = collectPlayers(args, n)
        local involvesMe = pset[me] == true
        local others = {}
        for _, p in ipairs(plist) do if p ~= me then others[#others + 1] = p.Name end end
        local zone = involvesMe and "Mías" or (#others > 0 and "Otros" or "Generales")
        if state.mode == "mine" and zone ~= "Mías" then return end
        state.totals[zone] = state.totals[zone] + 1
        for _, name in ipairs(others) do state.perPlayer[name] = (state.perPlayer[name] or 0) + 1 end
        state.dirty = true

        if involvesMe and #others > 0 then
            local who = table.concat(others, ", ")
            local last = state.lastAlertBy[who]
            if not last or now - last >= ALERT_COOLDOWN then
                state.lastAlertBy[who] = now
                table.insert(state.alerts, 1, {time = os.date("%H:%M:%S"), who = who, remote = remote.Name, kind = "player"})
                if #state.alerts > MAX_ALERTS then table.remove(state.alerts) end
                notify(("! %s -> %s te involucra"):format(who, remote.Name))
            end
        end

        state.secCount = state.secCount + 1
        local key = zone .. "|" .. remote.Name .. "|" .. table.concat(others, ",")
        local g = state.groups[key]
        if state.secCount > MAX_DETAIL_PER_SEC and g then
            g.count = g.count + 1; state.dropped = state.dropped + 1; return
        end
        local formatted = {}
        for i = 1, n do formatted[i] = fmt(args[i]) end
        local sig = table.concat(formatted, "\1")
        state.seq = state.seq + 1
        if not g then
            g = {key = key, zone = zone, name = remote.Name, class = remote.ClassName, path = pathOf(remote),
                 players = others, involvesMe = involvesMe, count = 0, variants = 0, nargs = n,
                 first = os.date("%H:%M:%S"), lastSig = nil, rateStart = now, rateCount = 0, spam = false}
            state.groups[key] = g
        end
        g.count = g.count + 1
        g.nargs = n
        g.last = os.date("%H:%M:%S")
        g.seq = state.seq
        -- Detección de spam -> alerta amarilla.
        if now - g.rateStart >= 1 then
            g.spam = g.rateCount >= ALERT_RATE
            g.rateStart, g.rateCount = now, 0
        end
        g.rateCount = g.rateCount + 1
        if g.rateCount >= ALERT_RATE then g.spam = true end
        if sig ~= g.lastSig then g.variants = g.variants + 1; g.lastSig = sig end
        g.args = formatted
        touch(key)
        recordButtonSignal(g)
    end

    local function hook(remote)
        if state.conns[remote] then return end
        local ok, conn = pcall(function()
            local sig = remote:IsA("BindableEvent") and remote.Event or remote.OnClientEvent
            return sig:Connect(function(...)
                local n = select("#", ...)
                local args = {...}
                pcall(record, remote, args, n)
            end)
        end)
        if ok and conn then state.conns[remote] = conn end
    end
    local function isRemote(d) return d:IsA("RemoteEvent") or d:IsA("UnreliableRemoteEvent") or d:IsA("BindableEvent") end
    -- Todo lo que el servidor replica y tu cliente puede ver (sin CoreGui).
    local ROOT_NAMES = {"ReplicatedStorage", "ReplicatedFirst", "Workspace", "Players", "Lighting", "Teams", "SoundService", "StarterGui", "StarterPack"}
    local function getRoots()
        local roots = {}
        for _, n in ipairs(ROOT_NAMES) do
            local ok, svc = pcall(function() return game:GetService(n) end)
            if ok and svc then roots[#roots + 1] = svc end
        end
        return roots
    end

    ---- Cambios replicados (compras, monedas, inventario, atributos) ----
    -- Una compra casi nunca llega por RemoteEvent: el servidor cambia valores
    -- (leaderstats, Data, atributos) o te da una Tool. Aquí se registran esos
    -- cambios, solo leyendo.
    local CHANGE_RATE = 20
    local changeSec, changeCount = os.clock(), 0
    local function recordInfo(key, name, path, class, zone, lines, nargs)
        if not state.listening or state.ignored[name] then return end
        local now = os.clock()
        if now - changeSec >= 1 then changeSec, changeCount = now, 0 end
        changeCount = changeCount + 1
        local g = state.groups[key]
        if changeCount > CHANGE_RATE and g then g.count = g.count + 1; state.dropped = state.dropped + 1; return end
        state.seq = state.seq + 1
        if not g then
            g = {key = key, zone = zone, name = name, class = class, path = path, players = {}, involvesMe = zone == "Mías",
                 count = 0, variants = 0, first = os.date("%H:%M:%S"), rateStart = now, rateCount = 0, spam = false, args = {}}
            state.groups[key] = g
        end
        g.count = g.count + 1
        g.variants = g.variants + 1
        g.nargs = nargs or 0
        g.last = os.date("%H:%M:%S")
        g.seq = state.seq
        g.custom = table.concat(lines, "\n")
        state.totals[zone] = state.totals[zone] + 1
        state.dirty = true
        touch(key)
        recordButtonSignal(g)
    end
    local function short(v) local t = fmt(v); return #t > 120 and (t:sub(1, 120) .. "…") or t end
    local function watchValue(v)
        if not v:IsA("ValueBase") then return end
        local last = v.Value
        state.watchConns[#state.watchConns + 1] = v.Changed:Connect(function(newV)
            local old = last; last = newV
            local delta = ""
            if type(old) == "number" and type(newV) == "number" then delta = ("  (%+g)"):format(newV - old) end
            recordInfo("val|" .. pathOf(v), "Cambio: " .. v.Name, pathOf(v), v.ClassName, "Mías", {
                ("-- Cambio replicado: %s · %s"):format(v.Name, os.date("%H:%M:%S")),
                ("local valor = %s"):format(pathOf(v)),
                ("-- antes: %s"):format(short(old)),
                ("-- ahora: %s%s"):format(short(newV), delta),
            }, 2)
        end)
    end
    local function watchAttributes(inst, label)
        state.watchConns[#state.watchConns + 1] = inst.AttributeChanged:Connect(function(attr)
            local val = inst:GetAttribute(attr)
            recordInfo("attr|" .. label .. "|" .. attr, "Atributo: " .. attr, pathOf(inst), "Attribute", "Mías", {
                ("-- Atributo cambiado: %s · %s"):format(attr, os.date("%H:%M:%S")),
                ("local obj = %s"):format(pathOf(inst)),
                ("-- %s = %s"):format(attr, short(val)),
            }, 1)
        end)
    end
    local function watchContainer(container, label)
        if not container then return end
        state.watchConns[#state.watchConns + 1] = container.ChildAdded:Connect(function(c)
            recordInfo("add|" .. label .. "|" .. c.Name, "Recibido: " .. c.Name, pathOf(c), c.ClassName, "Mías", {
                ("-- Nuevo en %s · %s"):format(label, os.date("%H:%M:%S")),
                ("local obj = %s  -- %s"):format(pathOf(c), c.ClassName),
            }, 1)
        end)
        state.watchConns[#state.watchConns + 1] = container.ChildRemoved:Connect(function(c)
            recordInfo("rem|" .. label .. "|" .. c.Name, "Quitado: " .. c.Name, label, c.ClassName, "Mías", {
                ("-- Quitado de %s · %s"):format(label, os.date("%H:%M:%S")),
                ("-- %s (%s)"):format(c.Name, c.ClassName),
            }, 1)
        end)
    end
    local function startChangeWatch()
        -- Valores dentro de tu Player (leaderstats, Data, Inventory, etc.)
        for _, d in ipairs(me:GetDescendants()) do
            if d:IsA("ValueBase") and not d:FindFirstAncestorOfClass("PlayerGui") then watchValue(d) end
        end
        state.watchConns[#state.watchConns + 1] = me.DescendantAdded:Connect(function(d)
            if state.listening and d:IsA("ValueBase") and not d:FindFirstAncestorOfClass("PlayerGui") then watchValue(d) end
        end)
        watchAttributes(me, "Player")
        -- Inventario: Backpack y lo que te pongan en el personaje.
        local backpack = me:FindFirstChildOfClass("Backpack")
        watchContainer(backpack, "Backpack")
        local function onChar(ch)
            if not ch then return end
            watchAttributes(ch, "Character")
            state.watchConns[#state.watchConns + 1] = ch.ChildAdded:Connect(function(c)
                if c:IsA("Tool") or c:IsA("Accessory") then
                    recordInfo("char|" .. c.Name, "Equipado: " .. c.Name, pathOf(c), c.ClassName, "Mías", {
                        ("-- Nuevo en tu personaje · %s"):format(os.date("%H:%M:%S")),
                        ("local obj = %s  -- %s"):format(pathOf(c), c.ClassName),
                    }, 1)
                end
            end)
        end
        onChar(me.Character)
        state.watchConns[#state.watchConns + 1] = me.CharacterAdded:Connect(onChar)
        state.watchConns[#state.watchConns + 1] = me.ChildAdded:Connect(function(c)
            if c:IsA("Backpack") then watchContainer(c, "Backpack") end
        end)
        -- Compras con Robux (MarketplaceService): resultado que confirma el servidor de Roblox.
        local okM, MPS = pcall(function() return game:GetService("MarketplaceService") end)
        if okM and MPS then
            local function purchase(kind, id, done)
                recordInfo("buy|" .. kind .. "|" .. tostring(id), "Compra: " .. kind .. " " .. tostring(id), "MarketplaceService", "Purchase", "Mías", {
                    ("-- Compra %s · %s"):format(kind, os.date("%H:%M:%S")),
                    ("-- id = %s"):format(tostring(id)),
                    ("-- completada = %s"):format(tostring(done)),
                }, 2)
            end
            pcall(function() state.watchConns[#state.watchConns + 1] = MPS.PromptPurchaseFinished:Connect(function(p, id, done) if p == me then purchase("Item", id, done) end end) end)
            pcall(function() state.watchConns[#state.watchConns + 1] = MPS.PromptProductPurchaseFinished:Connect(function(uid, id, done) if uid == me.UserId then purchase("Producto", id, done) end end) end)
            pcall(function() state.watchConns[#state.watchConns + 1] = MPS.PromptGamePassPurchaseFinished:Connect(function(p, id, done) if p == me then purchase("GamePass", id, done) end end) end)
        end
        pcall(function()
        -- Entradas y salidas de jugadores, tu equipo y tu Humanoid (vida / muerte).
        local PlayersS = game:GetService("Players")
        state.watchConns[#state.watchConns + 1] = PlayersS.PlayerAdded:Connect(function(p)
            recordInfo("pl+|" .. p.Name, "Entra: " .. p.Name, "Players." .. p.Name, "PlayerAdded", "Generales", {("-- Entró %s · %s"):format(p.Name, os.date("%H:%M:%S"))}, 1)
        end)
        state.watchConns[#state.watchConns + 1] = PlayersS.PlayerRemoving:Connect(function(p)
            recordInfo("pl-|" .. p.Name, "Sale: " .. p.Name, "Players." .. p.Name, "PlayerRemoving", "Generales", {("-- Salió %s · %s"):format(p.Name, os.date("%H:%M:%S"))}, 1)
        end)
        pcall(function()
            state.watchConns[#state.watchConns + 1] = me:GetPropertyChangedSignal("Team"):Connect(function()
                recordInfo("team", "Equipo: " .. tostring(me.Team and me.Team.Name), "Players.LocalPlayer.Team", "Team", "Mías", {("-- Tu equipo cambió a %s"):format(tostring(me.Team and me.Team.Name))}, 1)
            end)
        end)
        local function onHum(ch)
            local hum = ch and ch:FindFirstChildOfClass("Humanoid") or (ch and ch:WaitForChild("Humanoid", 5))
            if not hum then return end
            local lastHp = hum.Health
            state.watchConns[#state.watchConns + 1] = hum.HealthChanged:Connect(function(hp)
                local d = hp - lastHp; lastHp = hp
                recordInfo("hp", "Vida: " .. math.floor(hp), pathOf(hum), "HealthChanged", "Mías", {
                    ("-- Tu vida cambió · %s"):format(os.date("%H:%M:%S")), ("-- %d (%s%d)"):format(math.floor(hp), d >= 0 and "+" or "", math.floor(d)),
                }, 1)
            end)
            state.watchConns[#state.watchConns + 1] = hum.Died:Connect(function()
                recordInfo("died", "Moriste", pathOf(hum), "Died", "Mías", {("-- Tu Humanoid murió · %s"):format(os.date("%H:%M:%S"))}, 1)
            end)
        end
        task.spawn(onHum, me.Character)
        state.watchConns[#state.watchConns + 1] = me.CharacterAdded:Connect(function(ch) task.spawn(onHum, ch) end)
        end)
        -- Objetos nuevos en el mapa que llevan tu nombre (lo que compras y aparece).
        state.watchConns[#state.watchConns + 1] = workspace.DescendantAdded:Connect(function(d)
            if not state.listening then return end
            local okA, own = pcall(function()
                local a = d:GetAttribute("Owner") or d:GetAttribute("owner") or d:GetAttribute("OwnerId")
                if a == me.Name or a == me.UserId then return true end
                return d.Parent and (d.Parent.Name == me.Name or d.Parent.Name == tostring(me.UserId)) and d:IsA("Model")
            end)
            if okA and own then
                recordInfo("ws|" .. d.Name, "Aparece: " .. d.Name, pathOf(d), d.ClassName, "Mías", {
                    ("-- Objeto tuyo apareció · %s"):format(os.date("%H:%M:%S")),
                    ("local obj = %s  -- %s"):format(pathOf(d), d.ClassName),
                }, 1)
            end
        end)
    end

    local function startListening()
        if state.listening then return end
        state.listening = true
        for _, root in ipairs(getRoots()) do
            pcall(function()
                for _, d in ipairs(root:GetDescendants()) do if isRemote(d) then hook(d) end end
            end)
            pcall(function()
                state.watchConns[#state.watchConns + 1] = root.DescendantAdded:Connect(function(d)
                    if state.listening and isRemote(d) then hook(d) end
                end)
            end)
        end
        pcall(startChangeWatch)
        state.dirty = true
    end
    local function stopListening()
        state.listening = false
        for r, c in pairs(state.conns) do pcall(function() c:Disconnect() end); state.conns[r] = nil end
        for i, c in ipairs(state.watchConns) do pcall(function() c:Disconnect() end); state.watchConns[i] = nil end
        state.dirty = true
    end
    local function clearAll()
        state.groups, state.order, state.alerts = {}, {}, {}
        state.totals = {["Mías"] = 0, ["Otros"] = 0, ["Generales"] = 0}
        state.perPlayer, state.seq, state.dropped, state.selectedKey = {}, 0, 0, nil
        state.lastAlertBy = {}
        state.dirty = true
    end

    ---------------- Registro por botón ----------------
    -- Cuando pulsas un botón del menú GOY, se anota su nombre; las señales del
    -- servidor que lleguen enseguida se guardan bajo ese botón (pestaña Botones).
    local function noteButton(name)
        name = name ~= "" and name or "(sin nombre)"
        state.lastButton, state.lastButtonAt = name, os.clock()
        if not state.buttons[name] then
            state.buttons[name] = {name = name, count = 0, last = os.date("%H:%M:%S"), signals = {}}
            table.insert(state.buttonOrder, 1, name)
        end
        state.buttons[name].last = os.date("%H:%M:%S")
        SHARED.lastButton = name
        state.dirty = true
    end
    SHARED.noteButton = noteButton    -- tus otros paneles pueden avisar qué botón se pulsó
    local function hookButtonsIn(root)
        for _, d in ipairs(root:GetDescendants()) do
            if (d:IsA("TextButton") or d:IsA("ImageButton")) and not state.btnConns[d] then
                local label = d:IsA("TextButton") and d.Text or d.Name
                local ok, c = pcall(function()
                    return d.Activated:Connect(function()
                        local nm = (d:IsA("TextButton") and d.Text ~= "" and d.Text) or d.Name or label
                        noteButton(nm)
                    end)
                end)
                if ok and c then state.btnConns[d] = c end
            end
        end
    end
    -- Botón "IA" en la barra de arriba del menú (junto al título). Solo agrega un botón.
    local function addIAToOrion(orion)
        if orion:FindFirstChild("GOY_IA_TopButton", true) then return end
        for _, d in ipairs(orion:GetDescendants()) do
            if d:IsA("TextLabel") and d.Text == "Fling Things and People" and d.Parent then
                local topBar = d.Parent
                local b = Instance.new("TextButton")
                b.Name = "GOY_IA_TopButton"
                b.Text = "IA"
                b.Font = Enum.Font.GothamBold
                b.TextSize = 13
                b.TextColor3 = C.text
                b.BackgroundColor3 = C.btnOn
                b.BorderSizePixel = 0
                b.AnchorPoint = Vector2.new(1, 0.5)
                b.Size = UDim2.fromOffset(34, 22)
                b.Position = UDim2.new(1, -86, 0.5, 0)
                b.ZIndex = (d.ZIndex or 1) + 2
                Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
                b.Parent = topBar
                b.Activated:Connect(function() if SHARED.openIA then SHARED.openIA() end end)
                return
            end
        end
    end
    task.spawn(function()
        -- Engancha los botones del propio menú GOY (Orion) para el registro por botón.
        while alive() do
            local guiParent = (type(gethui) == "function" and gethui()) or game:GetService("CoreGui")
            local okPg, pg = pcall(function() return me:FindFirstChildOfClass("PlayerGui") end)
            for _, src in ipairs({guiParent, okPg and pg or nil}) do
                pcall(function()
                    local orion = src:FindFirstChild("Orion")
                    if orion then hookButtonsIn(orion); pcall(addIAToOrion, orion) end
                end)
            end
            task.wait(2)
        end
    end)

    ---------------- Analizador de código del SERVIDOR (estático, de texto) ----------------
    -- Revisa un Script del servidor y dice qué validaciones tiene y cuáles faltan.
    local function analyzeServer(src)
        if src == "" then return "Pega el código de un Script del servidor y toca Analizar.", nil end
        -- Devuelve (reporte, hallazgos). fixServer reutiliza los hallazgos para aplicar los arreglos.
        local proc, oks, miss = {}, {}, {}
        local info = {deadCool = {}, coolKey = {}, perPlayer = {}, uncleaned = {}, keyKind = {}, humVars = {}, selfPairs = {}}
        local function step(msg) proc[#proc + 1] = ("  %d. %s"):format(#proc + 1, msg) end
        local _, nl = src:gsub("\n", "\n")
        step(("Leí el código: %d líneas."):format(nl + 1))
        -- Se analiza sin comentarios, para no dar por hecho algo que solo está escrito en un comentario.
        src = src:gsub("%-%-%[(=*)%[.-%]%1%]", ""):gsub("%-%-[^\n]*", "")

        -- ¿Es código del cliente (LocalScript) o del servidor (Script)?
        local serverHits = 0
        for _, p in ipairs({"OnServerEvent", "OnServerInvoke", "PlayerAdded", "ProcessReceipt", "DataStoreService", "FireClient", "FireAllClients", "InvokeClient", "BindToClose", "SetNetworkOwner"}) do
            if src:find(p, 1, true) then serverHits = serverHits + 1 end
        end
        local clientHits, clientWhat = 0, {}
        for _, p in ipairs({"OnClientEvent", "OnClientInvoke", "LocalPlayer", "FireServer", "InvokeServer", "RenderStepped", "UserInputService", "PlayerGui", "CurrentCamera", "GetMouse"}) do
            if src:find(p, 1, true) then clientHits = clientHits + 1; clientWhat[#clientWhat + 1] = p end
        end
        if clientHits > 0 and serverHits == 0 then
            info.client = true
            step("Este código usa cosas que solo existen en el cliente: " .. table.concat(clientWhat, ", ") .. ".")
            step("No tiene OnServerEvent/OnServerInvoke ni nada del servidor, así que NO es un Script del servidor.")
            local out = {"-- Análisis estático: este código es del CLIENTE (LocalScript)", "", "Proceso:"}
            for _, l in ipairs(proc) do out[#out + 1] = l end
            out[#out + 1] = ""
            out[#out + 1] = "Qué significa:"
            out[#out + 1] = "  [OK] No hace falta revisar exploits aquí: tipo, rango, cooldown, dueño y distancia se validan en el SERVIDOR."
            out[#out + 1] = "  Si es el código que copió el Remote Spy, solo muestra lo que el servidor te ENVIÓ (a1, a2, a3 = argumentos)."
            out[#out + 1] = "  Para ver qué hace el servidor con ese remoto, pega el Script del servidor de TU juego que tiene"
            out[#out + 1] = "  OnServerEvent / FireClient de ese mismo remoto, y toca Analizar otra vez."
            local listens = {}
            for v in src:gmatch("([%w_]+)%s*%.%s*OnClientEvent") do listens[#listens + 1] = v end
            if #listens > 0 then
                out[#out + 1] = ""
                out[#out + 1] = ("Escucha del servidor (OnClientEvent): %d evento(s), ver nombre y código abajo"):format(#listens)
            end
            local sends = {}
            for v, how in src:gmatch("([%w_]+)%s*:%s*(%a+Server)%s*%(") do sends[#sends + 1] = v .. " (" .. how .. ")" end
            if #sends > 0 then out[#out + 1] = "Envía al servidor: " .. table.concat(sends, ", ") end
            return table.concat(out, "\n"), info
        end

        -- 1) validaciones generales
        local checks = {
            {k = "tipo (typeof/type)", has = src:find("typeof%s*%(") or src:find("type%s*%(")},
            {k = "rango (<, >, math.clamp, min/max)", has = src:find("math%.clamp") or src:find("math%.min") or src:find("math%.max") or src:find("[<>]=?")},
            {k = "cooldown (tick/os.clock/debounce)", has = src:find("tick%s*%(") or src:find("os%.clock") or src:find("[Dd]ebounce") or src:find("[Cc]ooldown")},
            {k = "dueño del jugador (player == / GetPlayerFromCharacter)", has = src:find("GetPlayerFromCharacter") or src:find("plr%s*==") or src:find("player%s*==") or src:find("%.Parent%s*==")},
            {k = "distancia (magnitude)", has = src:find("%.[Mm]agnitude")},
            {k = "sanitiza strings (#.. len, string.sub)", has = src:find("#%w") or src:find("string%.sub") or src:find("utf8")},
        }
        local nOk = 0
        for _, c in ipairs(checks) do
            if c.has then oks[#oks + 1] = "  [OK] " .. c.k; nOk = nOk + 1
            else miss[#miss + 1] = "  [FALTA] " .. c.k end
        end
        step(("Revisé %d validaciones básicas: %d presentes, %d faltan."):format(#checks, nOk, #checks - nOk))

        -- 2) cooldown que se lee pero nunca se guarda (entonces no limita nada)
        local coolNames = {}
        for name, key in src:gmatch("([%w_]+)%[([^%]\n]+)%]%s*or%s*0") do
            if not info.coolKey[name] then info.coolKey[name] = key; coolNames[#coolNames + 1] = name end
        end
        for _, name in ipairs(coolNames) do
            if src:find(name .. "%[[^%]\n]+%]%s*=[^=]") then
                oks[#oks + 1] = ("  [OK] %s se lee y se guarda (el cooldown funciona)"):format(name)
            else
                info.deadCool[#info.deadCool + 1] = name
                miss[#miss + 1] = ("  [FALTA] %s se lee pero nunca se guarda: el cooldown NO funciona"):format(name)
            end
        end
        step(("Busqué cooldowns con la forma tabla[clave] or 0: %d encontrado(s), %d sin guardar nunca."):format(#coolNames, #info.deadCool))

        -- 3) tablas por jugador y limpieza al salir
        for name in src:gmatch("([%w_]+)%[[%w_%.]-UserId%]") do
            if not info.keyKind[name] then info.keyKind[name] = "UserId"; info.perPlayer[#info.perPlayer + 1] = name end
        end
        for _, name in ipairs(coolNames) do
            if not info.keyKind[name] then
                info.keyKind[name] = info.coolKey[name]:match("^%s*[%w_]+%s*$") and "Instance" or "Other"
                info.perPlayer[#info.perPlayer + 1] = name
            end
        end
        for _, name in ipairs(info.perPlayer) do
            if not src:find(name .. "%[[^%]\n]+%]%s*=%s*nil") then info.uncleaned[#info.uncleaned + 1] = name end
        end
        step(("Busqué tablas por jugador: %d. Sin limpiar al salir el jugador: %d."):format(#info.perPlayer, #info.uncleaned))
        if #info.perPlayer > 0 then
            if #info.uncleaned == 0 then
                oks[#oks + 1] = "  [OK] borra los datos del jugador al salir (PlayerRemoving)"
            else
                miss[#miss + 1] = ("  [FALTA] no borra al salir el jugador (crecen sin límite): %s"):format(table.concat(info.uncleaned, ", "))
            end
        end

        -- 4) Humanoid vivo
        for v in src:gmatch("local%s+([%w_]+)%s*=%s*[^\n]-[\"']Humanoid[\"']") do info.humVars[#info.humVars + 1] = v end
        info.usesHum = #info.humVars > 0 or src:find("[\"']Humanoid[\"']") ~= nil
        info.checksHealth = src:find("%.Health") ~= nil
        step(("Busqué Humanoid y si se comprueba que esté vivo: %s."):format(not info.usesHum and "no usa Humanoid" or (info.checksHealth and "sí lo comprueba" or "NO lo comprueba")))
        if info.usesHum then
            if info.checksHealth then oks[#oks + 1] = "  [OK] comprueba Health del Humanoid"
            else miss[#miss + 1] = "  [FALTA] no comprueba que el Humanoid esté vivo (Health > 0)" end
        end

        -- 5) dos jugadores en la misma función: ¿impide que sean el mismo?
        local function pairCheck(fname, params)
            local list = {}
            for p in params:gmatch("[%w_]+") do list[#list + 1] = p end
            for i = 1, #list - 1 do
                for j = i + 1, #list do
                    local a, b = list[i], list[j]
                    if src:find(a .. "%.Character") and src:find(b .. "%.Character")
                        and not src:find(a .. "%s*[=~]=%s*" .. b) and not src:find(b .. "%s*[=~]=%s*" .. a) then
                        info.selfPairs[#info.selfPairs + 1] = {fname = fname, a = a, b = b}
                        miss[#miss + 1] = ("  [FALTA] %s(%s, %s): no impide que %s y %s sean el mismo jugador"):format(fname, a, b, a, b)
                    end
                end
            end
        end
        for fname, params in src:gmatch("function%s+([%w_%.:]+)%s*%(([^%)]*)%)") do pairCheck(fname, params) end
        for params in src:gmatch("function%s*%(([^%)]*)%)") do pairCheck("(manejador)", params) end
        step(("Busqué funciones con dos jugadores y la comprobación a ~= b: %d sin comprobar."):format(#info.selfPairs))

        -- 6) manejadores de remoto: tipo y rango de cada parámetro
        local nHandlers = 0
        for _ in src:gmatch("OnServer%a+") do nHandlers = nHandlers + 1 end
        local handlerLines = {}
        for params in src:gmatch("OnServer%a+[^\n]-function%s*%(([^%)]*)%)") do
            local list = {}
            for p in params:gmatch("[%w_]+") do list[#list + 1] = p end
            handlerLines[#handlerLines + 1] = "  Handler(" .. table.concat(list, ", ") .. "):"
            for i = 2, #list do
                local p = list[i]
                local typed = src:find("typeof%s*%(%s*" .. p .. "%s*%)") or src:find("type%s*%(%s*" .. p .. "%s*%)")
                local ranged = src:find(p .. "%s*[<>]") or src:find("[<>]=?%s*" .. p) or src:find("clamp%s*%(%s*" .. p)
                handlerLines[#handlerLines + 1] = ("    %s %s: tipo %s, rango %s"):format(typed and ranged and "[OK]" or "[FALTA]", p, typed and "sí" or "NO", ranged and "sí" or "NO")
            end
        end
        step(("Revisé los manejadores de remoto (OnServerEvent/OnServerInvoke): %d."):format(nHandlers))

        -- 7) también se busca lo que conecta con el cliente (OnClientEvent, FireClient...)
        local clientLines, nClient = {}, 0
        local clientPats = {
            {"OnClientEvent", "escucha del cliente"},
            {"OnClientInvoke", "respuesta del cliente"},
            {"FireClient", "el servidor envía a UN jugador"},
            {"FireAllClients", "el servidor envía a TODOS"},
        }
        for _, cp in ipairs(clientPats) do
            local c = select(2, src:gsub(cp[1] .. "%f[^%w]", ""))
            if c > 0 then nClient = nClient + 1; clientLines[#clientLines + 1] = ("  %s: %d (%s)"):format(cp[1], c, cp[2]) end
        end
        for remote, how in src:gmatch("([%w_]+)%s*[:%.]%s*(Fire%a*Clients?)%f[^%w]") do
            clientLines[#clientLines + 1] = ("    -> %s usa %s"):format(remote, how)
        end
        for remote in src:gmatch("([%w_]+)%s*%.%s*OnClientEvent") do
            clientLines[#clientLines + 1] = ("    -> %s escucha OnClientEvent"):format(remote)
        end
        step(("Busqué lo que conecta con el cliente (OnClientEvent/FireClient/FireAllClients): %d tipos."):format(nClient))

        local out = {"-- Análisis estático (de texto) del Script del servidor", "", "Proceso (lo que hizo el análisis, paso a paso):"}
        for _, l in ipairs(proc) do out[#out + 1] = l end
        out[#out + 1] = ""
        out[#out + 1] = "Qué SÍ valida:"
        if #oks == 0 then out[#out + 1] = "  (nada detectado)" end
        for _, l in ipairs(oks) do out[#out + 1] = l end
        out[#out + 1] = ""
        out[#out + 1] = "Qué NO valida (riesgo de exploit):"
        if #miss == 0 then out[#out + 1] = "  (todo cubierto a nivel de texto)" end
        for _, l in ipairs(miss) do out[#out + 1] = l end
        out[#out + 1] = ""
        out[#out + 1] = ("Manejadores de remoto encontrados: %d (OnServerEvent/OnServerInvoke)"):format(nHandlers)
        for _, l in ipairs(handlerLines) do out[#out + 1] = l end
        out[#out + 1] = ""
        out[#out + 1] = "Conexión con el cliente (OnClientEvent / FireClient / FireAllClients):"
        if #clientLines == 0 then out[#out + 1] = "  (no se encontró ninguno)" end
        for _, l in ipairs(clientLines) do out[#out + 1] = l end
        out[#out + 1] = ""
        out[#out + 1] = "Nota: es revisión de texto, no ejecuta el código. Usa 'Corregir código' para una versión con los arreglos aplicados."
        out[#out + 1] = "Eventos: toca uno en la lista de la izquierda para ver su código; el botón -> te lleva a su señal recibida."
        return table.concat(out, "\n"), info
    end
    -- Devuelve el código con los arreglos aplicados y, arriba, la lista de lo que se hizo.
    -- No borra tu lógica: añade guardas y líneas marcadas con [GOY].
    local function fixServer(src)
        if src == "" then return "" end
        local _, info = analyzeServer(src)
        if info and info.client then
            return "-- [GOY] Este código es del CLIENTE (LocalScript): no necesita guardas de servidor.\n-- [GOY] Pega el Script del servidor que usa este remoto (OnServerEvent/FireClient) para corregirlo.\n\n" .. src
        end
        local log = {}
        local function note(s) log[#log + 1] = s end
        local function guardFor(params)
            local first = params:match("^%s*([%w_]+)") or "player"
            local extra = {}
            local idx = 0
            for p in params:gmatch("[%w_]+") do
                idx = idx + 1
                if idx > 1 then
                    local numeric = src:find("[%-%+%*/]=?%s*" .. p .. "[^%w_]") or src:find("[^%w_]" .. p .. "%s*[%-%+%*/]")
                    if numeric then
                        extra[#extra + 1] = ("        if typeof(%s) ~= \"number\" or %s ~= %s or %s < 0 or %s > 1000 then return end -- ajusta el rango"):format(p, p, p, p, p)
                    else
                        extra[#extra + 1] = ("        if %s == nil then return end -- valida typeof(%s) según lo que esperas"):format(p, p)
                    end
                end
            end
            return table.concat({
                "",
                "        -- [GOY] guardas añadidas: dueño, cooldown, tipos y rangos",
                ("        if typeof(%s) ~= \"Instance\" or not %s:IsA(\"Player\") then return end"):format(first, first),
                ("        local now = os.clock()"),
                ("        if _GOY_cd[%s] and now - _GOY_cd[%s] < 0.15 then return end"):format(first, first),
                ("        _GOY_cd[%s] = now"):format(first),
                table.concat(extra, "\n"),
                "",
            }, "\n")
        end
        -- 1) guardas en cada manejador de remoto
        local fixed, n1 = src:gsub("(OnServerEvent:Connect%s*%(%s*function%s*%(([^%)]*)%))", function(head, params)
            return head .. guardFor(params)
        end)
        local n2
        fixed, n2 = fixed:gsub("(OnServerInvoke%s*=%s*function%s*%(([^%)]*)%))", function(head, params)
            return head .. guardFor(params)
        end)
        local nGuards = n1 + n2
        if nGuards > 0 then note(("Añadí guardas (dueño, cooldown, tipos, rangos) en %d manejador(es) de remoto."):format(nGuards)) end

        local lines = {}
        for line in (fixed .. "\n"):gmatch("(.-)\n") do lines[#lines + 1] = line end
        local function indentOf(l) return l:match("^[ \t]*") end

        -- 2) cooldown que nunca se guardaba: se guarda cuando la validación pasa
        for _, name in ipairs(info.deadCool) do
            local done = false
            for i = 1, #lines do
                local key = lines[i]:match(name .. "%[([^%]]+)%]%s*or%s*0")
                if key then
                    local clock = "os.clock()"
                    for j = i, math.min(#lines, i + 8) do
                        if lines[j]:find("os%.clock") then clock = "os.clock()"; break end
                        if lines[j]:find("tick%s*%(") then clock = "tick()"; break end
                    end
                    local pos, ind
                    for j = i + 1, math.min(#lines, i + 80) do
                        local l = lines[j]
                        if l:find("function%s*[%w_%.:]*%s*%(") then break end
                        if l:find("^%s*return%s+true%s*$") or l:find("^%s*return%s+true%s+%-%-") then pos = j; ind = indentOf(l); break end
                    end
                    if not pos then
                        for j = i + 1, math.min(#lines, i + 8) do
                            if lines[j]:find("^%s*if%s+.-<.-then%s+return") then pos = j + 1; ind = indentOf(lines[j]); break end
                        end
                    end
                    if pos then
                        table.insert(lines, pos, ind .. name .. "[" .. key .. "] = " .. clock .. " -- [GOY] guarda el cooldown (antes no se guardaba nunca)")
                        done = true
                    end
                    break
                end
            end
            if done then note(("Arreglé el cooldown de %s: ahora se guarda la hora cuando la validación pasa."):format(name))
            else note(("%s: añade %s[clave] = os.clock() cuando la acción sea válida (no pude ubicar dónde)."):format(name, name)) end
        end

        -- 3) limpiar las tablas por jugador al salir
        for _, name in ipairs(info.uncleaned) do
            local kind = info.keyKind[name]
            local done = false
            if kind == "UserId" or kind == "Instance" then
                for i = 1, #lines do
                    if lines[i]:find("^%s*local%s+" .. name .. "%s*=%s*{%s*}") then
                        local clear = (kind == "UserId") and (name .. "[p.UserId] = nil") or (name .. "[p] = nil")
                        table.insert(lines, i + 1, indentOf(lines[i]) .. "game:GetService(\"Players\").PlayerRemoving:Connect(function(p) " .. clear .. " end) -- [GOY] limpia al salir el jugador")
                        done = true
                        break
                    end
                end
            end
            if done then note(("Añadí la limpieza de %s en PlayerRemoving."):format(name))
            else note(("%s crece sin límite: borra su entrada del jugador en Players.PlayerRemoving."):format(name)) end
        end

        -- 4) comprobar que el Humanoid siga vivo
        if info.usesHum and not info.checksHealth and #info.humVars > 0 then
            local lastDecl = 0
            for i = 1, #lines do
                for _, v in ipairs(info.humVars) do
                    if lines[i]:find("^%s*local%s+" .. v .. "%s*=") then lastDecl = i end
                end
            end
            local done = false
            for i = lastDecl + 1, math.min(#lines, lastDecl + 12) do
                local cond, ret = lines[i]:match("^%s*if%s+not%s+(.-)%s+then%s+(return[^\n]-)%s+end")
                if cond then
                    local used = {}
                    for _, v in ipairs(info.humVars) do
                        if cond:find(v, 1, true) then used[#used + 1] = v .. ".Health <= 0" end
                    end
                    if #used > 0 then
                        table.insert(lines, i + 1, indentOf(lines[i]) .. "if " .. table.concat(used, " or ") .. " then " .. ret .. " end -- [GOY] solo si siguen vivos")
                        done = true
                        break
                    end
                end
            end
            if done then note("Añadí la comprobación de que el Humanoid siga vivo (Health > 0).")
            else note("Falta comprobar Humanoid.Health > 0 antes de actuar sobre un jugador.") end
        end

        -- 5) que el jugador no pueda actuar sobre sí mismo
        for _, sp in ipairs(info.selfPairs) do
            local done = false
            for i = 1, #lines do
                local params = lines[i]:match("function%s*[%w_%.:]*%s*%(([^%)]*)%)")
                if params then
                    local set = {}
                    for p in params:gmatch("[%w_]+") do set[p] = true end
                    if set[sp.a] and set[sp.b] then
                        local ind = indentOf(lines[i])
                        local boolFn = false
                        for k = i + 1, math.min(#lines, i + 120) do
                            if lines[k]:find("^%s*end") and #indentOf(lines[k]) <= #ind then break end
                            if lines[k]:find("return%s+true") or lines[k]:find("return%s+false") then boolFn = true end
                        end
                        table.insert(lines, i + 1, ind .. "    if " .. sp.a .. " == " .. sp.b .. " then return" .. (boolFn and " false" or "") .. " end -- [GOY] no actuar sobre uno mismo (quítalo si lo permites)")
                        done = true
                        break
                    end
                end
            end
            if done then note(("Añadí en %s la comprobación %s ~= %s."):format(sp.fname, sp.a, sp.b))
            else note(("%s: añade al inicio if %s == %s then return end."):format(sp.fname, sp.a, sp.b)) end
        end

        local header = {
            "-- ============================================",
            "-- Código corregido por GOY. Arreglos aplicados:",
        }
        if #log == 0 then header[#header + 1] = "--   (no encontré nada que arreglar a nivel de texto)" end
        for i, l in ipairs(log) do header[#header + 1] = ("--   %d. %s"):format(i, l) end
        header[#header + 1] = "-- Revisa los comentarios [GOY] y pon los rangos de tu juego."
        header[#header + 1] = "-- ============================================"
        if nGuards > 0 then
            header[#header + 1] = "local _GOY_cd = {}"
            header[#header + 1] = "game:GetService(\"Players\").PlayerRemoving:Connect(function(p) _GOY_cd[p] = nil end)"
        end
        header[#header + 1] = ""
        header[#header + 1] = ""
        return table.concat(header, "\n") .. table.concat(lines, "\n")
    end

    local extractEvents, eventReport
    do
    ---------------- Detector de eventos del código (solo lee el texto) ----------------
    local EVENT_INFO = {
        OnServerEvent = "un jugador envía este remoto al servidor", OnServerInvoke = "un jugador pide algo al servidor (RemoteFunction)",
        OnClientEvent = "el servidor envía este remoto al cliente", OnClientInvoke = "el servidor pide algo al cliente",
        OnInvoke = "BindableFunction llamada", Event = "BindableEvent disparado",
        PlayerAdded = "entra un jugador", PlayerRemoving = "sale un jugador", CharacterAdded = "aparece el personaje",
        CharacterRemoving = "se quita el personaje", CharacterAppearanceLoaded = "carga la ropa del personaje",
        Touched = "algo toca la pieza", TouchEnded = "algo deja de tocar la pieza", Died = "muere el Humanoid",
        HealthChanged = "cambia la vida", Running = "el Humanoid corre", Jumping = "el Humanoid salta", StateChanged = "cambia el estado del Humanoid",
        Changed = "cambia una propiedad/valor", ChildAdded = "se añade un hijo", ChildRemoved = "se quita un hijo",
        DescendantAdded = "se añade un descendiente", DescendantRemoving = "se quita un descendiente",
        AncestryChanged = "cambia el padre", AttributeChanged = "cambia un atributo",
        MouseClick = "clic en ClickDetector", RightMouseClick = "clic derecho en ClickDetector",
        Triggered = "se activa el ProximityPrompt", TriggerEnded = "termina el ProximityPrompt",
        PromptShown = "se muestra el ProximityPrompt", Activated = "se usa la Tool/botón", Deactivated = "se suelta la Tool",
        Equipped = "se equipa la Tool", Unequipped = "se guarda la Tool", MouseButton1Click = "clic en botón",
        Heartbeat = "cada frame (físicas)", Stepped = "cada frame (antes de físicas)", RenderStepped = "cada frame (render)",
        PreSimulation = "cada frame (antes de simular)", PostSimulation = "cada frame (después de simular)",
        Chatted = "el jugador escribe en el chat", Idled = "el jugador está inactivo",
        PromptPurchaseFinished = "termina una compra", PromptGamePassPurchaseFinished = "termina compra de GamePass",
        PromptProductPurchaseFinished = "termina compra de producto", ProcessReceipt = "Roblox confirma una compra de producto",
        Completed = "termina el Tween", Ended = "termina el sonido/animación", Played = "empieza el sonido", KeyframeReached = "llega a un keyframe",
        BindToClose = "el servidor se va a cerrar", OnTeleport = "el jugador se teletransporta", MoveToFinished = "llega al destino",
        FocusLost = "se suelta la caja de texto", InputBegan = "empieza un toque/tecla", InputEnded = "termina un toque/tecla",
    }
    local ACTION_PATS = {
        {"FireClient%s*%(", "envía a un jugador (FireClient)"}, {"FireAllClients%s*%(", "envía a todos (FireAllClients)"},
        {"FireServer%s*%(", "envía al servidor (FireServer)"}, {"InvokeClient%s*%(", "pide al cliente (InvokeClient)"},
        {":Destroy%s*%(", "destruye un objeto"}, {"Instance%.new%s*%(", "crea un objeto"}, {":Clone%s*%(", "clona un objeto"},
        {"%.Value%s*[%+%-%*/]?=[^=]", "cambia un valor"}, {":SetAttribute%s*%(", "cambia un atributo"},
        {"%.Health%s*[%+%-]?=[^=]", "cambia la vida"}, {":TakeDamage%s*%(", "hace daño"}, {"BreakJoints", "mata/rompe"},
        {"%.Parent%s*=[^=]", "mueve un objeto (Parent)"}, {"CFrame%s*=[^=]", "mueve/teletransporta (CFrame)"}, {":PivotTo%s*%(", "mueve un modelo"},
        {":MoveTo%s*%(", "mueve"}, {"WalkSpeed%s*=[^=]", "cambia velocidad"}, {"JumpPower%s*=[^=]", "cambia salto"},
        {":SetAsync%s*%(", "guarda datos"}, {":UpdateAsync%s*%(", "guarda datos"}, {":GetAsync%s*%(", "lee datos"},
        {":IncrementAsync%s*%(", "suma datos"}, {":Kick%s*%(", "expulsa"}, {":LoadCharacter%s*%(", "reaparece al jugador"},
        {"TeleportAsync", "teletransporta a otro lugar"}, {":Teleport%s*%(", "teletransporta"}, {":Play%s*%(", "reproduce sonido/animación"},
        {"SetNetworkOwner", "cambia dueño de físicas"}, {":ApplyImpulse", "empuja"}, {"AssemblyLinearVelocity%s*=", "cambia velocidad física"},
        {"PromptPurchase", "abre una compra"}, {"task%.delay", "espera y luego hace algo"}, {"Debris", "borra después de un tiempo"},
    }
    local function stripLine(l)
        l = l:gsub("%-%-.*$", "")
        l = l:gsub('\\.', ""):gsub('"[^"]*"', '""'):gsub("'[^']*'", "''")
        return l
    end
    local function blockDelta(l)
        local d = 0
        local c = " " .. stripLine(l) .. " "
        for w in c:gmatch("[%w_]+") do
            if w == "function" or w == "do" or w == "repeat" then d = d + 1
            elseif w == "then" then d = d + 1
            elseif w == "elseif" then d = d - 1
            elseif w == "end" or w == "until" then d = d - 1 end
        end
        -- "while/for ... do" ya cuenta por el do; "if ... then" por el then
        return d
    end
    local function bodyFrom(lines, i, maxLines)
        local depth, started, last = 0, false, i
        for j = i, math.min(#lines, i + (maxLines or 600)) do
            depth = depth + blockDelta(lines[j])
            if depth > 0 then started = true end
            last = j
            if j == i and depth <= 0 then break end
            if started and depth <= 0 then break end
            if not started and j > i + 1 then break end
        end
        return table.concat(lines, "\n", i, last), last
    end
    -- Busca todos los eventos del código: objeto.Evento:Connect/Once, OnServerInvoke =, GetPropertyChangedSignal, etc.
    extractEvents = function(src)
        local events = {}
        if type(src) ~= "string" or src:gsub("%s", "") == "" then return events end
        local lines = {}
        for l in (src .. "\n"):gmatch("(.-)\r?\n") do lines[#lines + 1] = l end
        -- variable -> nombre real del objeto (WaitForChild/FindFirstChild/.Name/Instance.new)
        local alias, aliasLine = {}, {}
        for ai, l in ipairs(lines) do
            local v, n = l:match("local%s+([%w_]+)%s*=.-WaitForChild%s*%(%s*[\"']([^\"']+)[\"']%s*[,%)][^\n]-$")
            if not v then v, n = l:match("local%s+([%w_]+)%s*=.-FindFirstChild%s*%(%s*[\"']([^\"']+)[\"']") end
            if not v then v, n = l:match("local%s+([%w_]+)%s*=%s*[%w_%.]+%.([%w_]+)%s*$") end
            if not v then
                local v4, expr = l:match("local%s+([%w_]+)%s*=%s*(game[^\n]-)%s*$")
                if v4 then
                    local seg = expr:match("%.([%w_]+)$") or expr:match("%[%s*[\"']([^\"']+)[\"']%s*%]$")
                    if seg then v, n = v4, seg end
                end
            end
            if v and n then
                -- se queda con el ÚLTIMO WaitForChild de la línea (el objeto final)
                local lastN; for m in l:gmatch("WaitForChild%s*%(%s*[\"']([^\"']+)[\"']") do lastN = m end
                alias[v] = lastN or n
                aliasLine[v] = ai
            end
            local v2, n2 = l:match("^%s*([%w_]+)%.Name%s*=%s*[\"']([^\"']+)[\"']")
            if v2 and n2 then alias[v2] = n2 end
            local v3, cls = l:match("local%s+([%w_]+)%s*=%s*Instance%.new%s*%(%s*[\"']([%w_]+)[\"']")
            if v3 and not alias[v3] then alias[v3] = cls end
        end
        local funcs = {}
        for i, l in ipairs(lines) do
            local fn = l:match("^%s*local%s+function%s+([%w_]+)%s*%(") or l:match("^%s*function%s+([%w_%.:]+)%s*%(")
            if fn then funcs[fn] = i end
        end
        local function objName(expr)
            local base = expr:match("([%w_]+)$") or expr
            local root = expr:match("^([%w_]+)")
            if alias[expr] then return alias[expr] end
            local last; for m in expr:gmatch("[\"']([^\"']+)[\"']") do last = m end
            if last then return last end
            if alias[base] then return alias[base] end
            if root and alias[root] and root == expr then return alias[root] end
            return base
        end
        local function actionsOf(body)
            local acts, seenA = {}, {}
            for _, ap in ipairs(ACTION_PATS) do
                if body:find(ap[1]) and not seenA[ap[2]] then seenA[ap[2]] = true; acts[#acts + 1] = ap[2] end
            end
            -- qué remotos dispara dentro
            local fired = {}
            for r in body:gmatch("([%w_]+)%s*:%s*Fire%a*%s*%(") do fired[#fired + 1] = objName(r) end
            return acts, fired
        end
        local function params(l) return l:match("function%s*[%w_%.:]*%s*%(([^%)]*)%)") or "" end
        local function add(i, obj, ev, how)
            local body, last
            local handler = lines[i]:match(":Connect%s*%(%s*([%w_%.:]+)%s*%)") or lines[i]:match(":Once%s*%(%s*([%w_%.:]+)%s*%)")
                or lines[i]:match("=%s*([%w_%.:]+)%s*$")
            if lines[i]:find("function") then
                body, last = bodyFrom(lines, i)
            elseif handler and funcs[handler] then
                body, last = bodyFrom(lines, funcs[handler])
                body = lines[i] .. "\n\n-- función que usa:\n" .. body
            else
                body, last = lines[i], i
            end
            local root = obj:match("^([%w_]+)")
            if root and aliasLine[root] and aliasLine[root] < i then
                body = lines[aliasLine[root]] .. "\n" .. body
            end
            local acts, fired = actionsOf(body)
            local name = objName(obj)
            events[#events + 1] = {
                line = i, lastLine = last, object = obj, name = name, event = ev, how = how,
                params = params(lines[i]), info = EVENT_INFO[ev] or (ev:find("^Changed:") and "cambia la propiedad " .. ev:sub(9)) or (ev:find("^Atributo:") and "cambia el atributo " .. ev:sub(10)) or "evento", body = body, actions = acts, fires = fired,
            }
        end
        for i, l in ipairs(lines) do
            local c = l:gsub("%-%-.*$", "")
            for obj, ev in c:gmatch("([%w_%.%[%]\"':%(%)]-)%.([%w_]+)%s*:%s*Connect%s*%(") do add(i, obj, ev, "Connect") end
            for obj, ev in c:gmatch("([%w_%.%[%]\"':%(%)]-)%.([%w_]+)%s*:%s*Once%s*%(") do add(i, obj, ev, "Once") end
            for obj, ev in c:gmatch("([%w_%.%[%]\"':%(%)]-)%.([%w_]+)%s*:%s*ConnectParallel%s*%(") do add(i, obj, ev, "ConnectParallel") end
            local o2, e2 = c:match("([%w_%.%[%]\"':%(%)]-)%.(On%a*Invoke)%s*=[^=]")
            if o2 then add(i, o2, e2, "callback") end
            local o3 = c:match("([%w_%.:%(%)\"']-)%.ProcessReceipt%s*=[^=]")
            if o3 then add(i, o3, "ProcessReceipt", "callback") end
            for o4, prop in l:gmatch("([%w_%.]+)%s*:%s*GetPropertyChangedSignal%s*%(%s*[\"']([%w_]+)[\"']") do add(i, o4, "Changed:" .. prop, "Connect") end
            for o5, at in l:gmatch("([%w_%.]+)%s*:%s*GetAttributeChangedSignal%s*%(%s*[\"']([%w_]+)[\"']") do add(i, o5, "Atributo:" .. at, "Connect") end
            if c:find("BindToClose%s*%(") then add(i, "game", "BindToClose", "callback") end
        end
        -- limpia nombres de objeto raros como game:GetService("Players")
        for _, e in ipairs(events) do
            local svc = e.object:match("GetService%s*%(%s*[\"']([%w_]+)[\"']")
            if svc and e.name == svc then e.name = svc end
            e.title = ("%s.%s"):format(e.name, e.event)
        end
        return events
    end
    eventReport = function(events)
        local out = {("Eventos detectados en el código: %d"):format(#events)}
        for k, e in ipairs(events) do
            out[#out + 1] = ("  %d) línea %d · %s  (%s)"):format(k, e.line, e.title, e.info)
            if e.params ~= "" then out[#out + 1] = ("     recibe: %s"):format(e.params) end
            if #e.actions > 0 then out[#out + 1] = "     acciones: " .. table.concat(e.actions, ", ") end
            if #e.fires > 0 then out[#out + 1] = "     dispara: " .. table.concat(e.fires, ", ") end
            if e.event == "OnClientEvent" then
                out[#out + 1] = ("     el servidor te envía %s%s"):format(e.name, e.params ~= "" and (" con " .. e.params) or "")
            end
            out[#out + 1] = ("     código del evento (líneas %d-%d):"):format(e.line, e.lastLine or e.line)
            local n = 0
            for l in (e.body .. "\n"):gmatch("(.-)\n") do
                n = n + 1
                if n > 300 then out[#out + 1] = "        … (toca el evento en la lista para verlo entero)"; break end
                out[#out + 1] = "        " .. l
            end
            out[#out + 1] = ""
        end
        return table.concat(out, "\n")
    end

    end

    ---------------- Config de la IA ----------------
    local function loadConfig()
        local raw
        if type(isfile) == "function" and type(readfile) == "function" then
            local ok, exists = pcall(isfile, CONFIG_LOCAL)
            if ok and exists then local okR, body = pcall(readfile, CONFIG_LOCAL); if okR then raw = body end end
        end
        if not raw and CONFIG_URL ~= "" then
            local ok, body = pcall(function() return game:HttpGet(CONFIG_URL) end)
            if ok and type(body) == "string" and #body > 0 and not body:find("^404") then raw = body end
        end
        local data
        if raw then
            local ok, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
            if ok and type(decoded) == "table" then data = decoded end
        end
        data = data or {}
        -- Sin URL propia -> IA pública gratuita sin clave (formato OpenAI).
        if type(data.aiUrl) ~= "string" or data.aiUrl == "" then
            data.aiUrl = DEFAULT_AI_URL
            data.format = "openai"
        end
        if not string.find(data.aiUrl, "^https://") then
            state.configErr = "aiUrl debe empezar con https://"; return
        end
        data.format = data.format or (string.find(data.aiUrl, "/openai") and "openai" or "goy")
        state.config, state.configErr = data, nil
    end
    local function getReq()
        return (syn and syn.request) or http_request or request or (http and http.request) or (fluxus and fluxus.request)
    end
    -- Hace la petición y reintenta 2 veces si hay fallo de red, 429 o 5xx.
    local function httpSend(opts)
        local req = getReq()
        if type(req) ~= "function" then return nil, "Tu ejecutor no permite peticiones HTTP", 0 end
        local lastErr, lastCode = "Error de red", 0
        for attempt = 1, 3 do
            local ok, res = pcall(req, opts)
            if ok and type(res) == "table" then
                local code = tonumber(res.StatusCode) or 200
                if code < 400 then return res.Body or "", nil, code end
                lastCode = code
                lastErr = "HTTP " .. code
                if not (code == 429 or code >= 500) then break end
            end
            if attempt < 3 then task.wait(1.2 * attempt) end
        end
        return nil, lastErr, lastCode
    end
    local function httpPost(url, body)
        local out, err, code = httpSend({Url = url, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = body})
        if out then return out, nil end
        if code == 0 then return nil, err end
        do
            local why = (code == 402 or code == 429) and "la IA gratis pública bloqueó tu conexión (límite). Pon la URL de tu worker en ia_config.json"
                or (code == 401 or code == 403) and "tu worker rechazó la petición (revisa la clave guardada en el worker)"
                or "el servidor de la IA falló"
            return nil, ("HTTP %d: %s"):format(code, why)
        end
    end
    local aiMemory = {}
    local KIND_PREFIX = {
        chat = "",
        continue = "Tu respuesta anterior se cortó por largo. Continúa EXACTAMENTE desde donde te quedaste, sin repetir nada, sin saludar y sin volver a abrir el bloque de código si ya estaba abierto. Esto es lo último que escribiste:\n",
        fix_code = "Corrige este código y devuélvelo completo. Formato: **Proceso** (qué revisaste, en pasos cortos), "
            .. "**Fallos** (lista numerada con la función y el motivo), el código completo en un solo bloque ```lua, y **Cambios** (1 línea por arreglo). "
            .. "Revisa siempre: cooldown que no se guarda, tablas por jugador sin limpiar en PlayerRemoving, Humanoid sin Health > 0, "
            .. "jugador que actúa sobre sí mismo, tipos/rangos sin validar, datos del cliente usados sin revisar y errores de sintaxis.\n",
        make_menu = "Crea un menú para Roblox que funcione a la primera, siguiendo esta base: LocalScript en StarterPlayerScripts, "
            .. "ScreenGui en PlayerGui con ResetOnSpawn=false, ventana con UICorner que se puede arrastrar (InputBegan/InputChanged), "
            .. "botón para abrir/cerrar, botones dentro de un ScrollingFrame con UIListLayout y AutomaticCanvasSize, cada botón con su función separada y pcall, "
            .. "y que funcione en celular (Activated en vez de MouseButton1Click). Si debe comunicarse con el servidor, usa los RemoteEvents del código de su juego "
            .. "e incluye también el Script del servidor que los valida. Lo que quiere el usuario:\n",
        analyze_signal = "Explica qué significa esta señal que el servidor me envió:\n",
    }
    local MAX_LINES = 10000          -- líneas máximas de una respuesta/código
    local MAX_PARTS = 12             -- partes que puede pedir para terminar una respuesta larga
    local CTX_MAX_WORKER = 200000    -- caracteres de contexto con tu worker
    local CTX_MAX_PUBLIC = 40000     -- caracteres de contexto con la IA pública
    -- Contexto de TU juego para la IA: el código que pegaste en la pestaña Servidor,
    -- los remotos que ese código atiende y las señales que tu cliente ha recibido (solo nombres).
    local function gameContext()
        local parts = {}
        local okN, placeName = pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name end)
        parts[#parts + 1] = ("Juego: %s (PlaceId %s)"):format(okN and tostring(placeName) or "?", tostring(game.PlaceId))
        local src = state.serverSrc or ""
        if src:gsub("%s", "") ~= "" then
            local names, seen = {}, {}
            for n in src:gmatch("[%w_%.:%(%)\"']-([%w_]+)%.OnServer%a+") do if not seen[n] then seen[n] = true; names[#names + 1] = n end end
            for n in src:gmatch("WaitForChild%(%s*[\"']([^\"']+)[\"']") do if not seen[n] then seen[n] = true; names[#names + 1] = n end end
            for n in src:gmatch("Instance%.new%(%s*[\"']Remote%a+[\"']%s*[^\n]-\n[^\n]-%.Name%s*=%s*[\"']([^\"']+)") do if not seen[n] then seen[n] = true; names[#names + 1] = n end end
            for n in src:gmatch("([%w_]+)%s*%.%s*OnClientEvent") do if not seen[n] then seen[n] = true; names[#names + 1] = n end end
            for n in src:gmatch("([%w_]+)%s*[:%.]%s*Fire%a*Clients?%f[^%w]") do if not seen[n] then seen[n] = true; names[#names + 1] = n end end
            if #names > 0 then parts[#parts + 1] = "Nombres usados en su código: " .. table.concat(names, ", ") end
            local code = #src > 60000 and (src:sub(1, 60000) .. "\n-- (recortado)") or src
            parts[#parts + 1] = "Código del juego del usuario (pegado por él en la pestaña Servidor). Úsalo para que lo que escribas encaje con sus nombres y remotos:\n```lua\n" .. code .. "\n```"
        end
        local seen = {}
        for i = 1, math.min(#state.order, 15) do
            local g = state.groups[state.order[i]]
            if g and not g.custom then seen[#seen + 1] = ("%s (%s, %d args)"):format(g.path or g.name, g.class or "?", g.nargs or 0) end
        end
        if #seen > 0 then parts[#parts + 1] = "Señales que el servidor le ha enviado (solo referencia): " .. table.concat(seen, "; ") end
        local ss = state.scriptSrc or ""
        if ss ~= "" then
            local _, n = ss:gsub("\n", "")
            parts[#parts + 1] = ("Script que el usuario cargó con Leer script (%s, %d líneas). Léelo entero antes de responder:\n```lua\n%s\n```"):format(state.scriptName or "script", n + 1, ss)
        end
        local all = table.concat(parts, "\n")
        local cap = (state.config and state.config.aiUrl == DEFAULT_AI_URL) and CTX_MAX_PUBLIC or CTX_MAX_WORKER
        if #all > cap then all = all:sub(1, cap) .. "\n-- (recortado: el contexto era más largo)" end
        return all
    end
    local function askAI(kind, text)
        if not state.config then loadConfig() end
        if not state.config then return nil, state.configErr or "Sin config de IA" end
        local cfg = state.config
        if cfg.aiUrl == DEFAULT_AI_URL and kind ~= "continue" and #text > CTX_MAX_PUBLIC then
            local _, nl = text:gsub("\n", "")
            return nil, ("tu mensaje tiene %d líneas (%d car.) y la IA gratis solo acepta unos %d car. por mensaje. Envíalo por partes o usa tu worker de Gemini, que acepta el código completo."):format(nl + 1, #text, CTX_MAX_PUBLIC)
        end
        local payload
        if cfg.format == "openai" then
            local msgs = {{role = "system", content = AI_SYSTEM}}
            for _, m in ipairs(aiMemory) do msgs[#msgs + 1] = m end
            if state.useCtx then
                local okC, ctx = pcall(gameContext)
                if okC and ctx ~= "" then msgs[#msgs + 1] = {role = "system", content = ctx} end
            end
            msgs[#msgs + 1] = {role = "user", content = (KIND_PREFIX[kind] or "") .. text}
            payload = HttpService:JSONEncode({model = cfg.model or "openai", messages = msgs})
        else
            local ctx = ""
            if state.useCtx then local okC, c = pcall(gameContext); ctx = okC and c or "" end
            payload = HttpService:JSONEncode({kind = kind, message = (KIND_PREFIX[kind] or "") .. text, context = ctx, game = tostring(game.PlaceId), user = me.Name, history = aiMemory})
        end
        local body, err = httpPost(cfg.aiUrl, payload)
        if not body and cfg.aiUrl == DEFAULT_AI_URL then
            -- Respaldo: misma IA pública por otra ruta (texto plano).
            local prompt = (KIND_PREFIX[kind] or "") .. text
            if #prompt > 1800 then prompt = prompt:sub(1, 1800) end
            local okE, q = pcall(function() return HttpService:UrlEncode(prompt) end)
            local okS, sys = pcall(function() return HttpService:UrlEncode(AI_SYSTEM) end)
            if okE and okS then
                local alt = httpSend({Url = DEFAULT_AI_GET .. q .. "?model=openai&referrer=goy&system=" .. sys, Method = "GET"})
                if alt and alt ~= "" then body, err = alt, nil end
            end
        end
        if not body then return nil, err end
        local reply, truncated = nil, false
        local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
        if ok and type(data) == "table" then
            if data.reply then reply = tostring(data.reply); truncated = data.truncated == true
            elseif type(data.choices) == "table" and data.choices[1] and data.choices[1].message then
                reply = tostring(data.choices[1].message.content or "")
                truncated = data.choices[1].finish_reason == "length"
            end
        end
        reply = reply or body
        local function cap(t) return #t > 8000 and (t:sub(1, 4000) .. "\n…\n" .. t:sub(-4000)) or t end
        aiMemory[#aiMemory + 1] = {role = "user", content = cap(text)}
        aiMemory[#aiMemory + 1] = {role = "assistant", content = cap(reply)}
        while #aiMemory > 8 do table.remove(aiMemory, 1) end
        return reply, nil, truncated
    end

    ---------------- Reportes ----------------
    local function groupReport(g)
        local lines = {
            "-- GOY Remote Spy: reporte (no ejecutable)",
            "Remote: " .. g.name, "Clase: " .. g.class, "Ruta: " .. g.path,
            "Dirección: " .. (g.custom and "Cambio replicado por el servidor" or "OnClientEvent (servidor -> tu cliente)"),
            "Zona: " .. g.zone,
            "Jugadores: " .. (#g.players > 0 and table.concat(g.players, ", ") or "-") .. (g.involvesMe and " (te involucra)" or ""),
            ("Veces: %d | Variantes: %d | Args: %d | Primera: %s | Última: %s"):format(g.count, g.variants, g.nargs or 0, g.first, g.last),
            "", "-- Pseudo-código de lo recibido:", codeOf(g),
        }
        return table.concat(lines, "\n")
    end
    local function fullReport()
        local out = {
            "-- GOY Remote Spy: exportación completa (no ejecutable)",
            ("-- Fecha: %s | Modo: %s"):format(os.date("%Y-%m-%d %H:%M:%S"), state.mode == "mine" and "Solo mías" or "Todos + mías"),
            ("-- Totales: Mías %d | Otros %d | Generales %d | Solo contadas %d"):format(
                state.totals["Mías"], state.totals["Otros"], state.totals["Generales"], state.dropped),
        }
        if #state.alerts > 0 then
            out[#out + 1] = ""; out[#out + 1] = "==== ALERTAS ===="
            for _, a in ipairs(state.alerts) do out[#out + 1] = ("%s  %s → %s"):format(a.time, a.who, a.remote) end
        end
        for _, zone in ipairs({"Mías", "Otros", "Generales"}) do
            out[#out + 1] = ""; out[#out + 1] = ("==== ZONA: %s ===="):format(zone)
            for _, key in ipairs(state.order) do
                local g = state.groups[key]
                if g and g.zone == zone then out[#out + 1] = groupReport(g); out[#out + 1] = "" end
            end
        end
        return table.concat(out, "\n")
    end
    local function copy(text, what)
        if type(setclipboard) == "function" and pcall(setclipboard, text) then
            notify(("GOY\n%s copiado (%d car.)"):format(what, #text)); return true
        end
        notify("GOY\nTu ejecutor no tiene setclipboard"); return false
    end

    ---------------- UI helpers ----------------
    local function new(class, props, parent)
        local o = Instance.new(class)
        for k, v in pairs(props) do o[k] = v end
        if parent then o.Parent = parent end
        return o
    end
    local function round(o, r) new("UICorner", {CornerRadius = UDim.new(0, r or 8)}, o) end
    local function stroke(o, color, th) new("UIStroke", {Color = color or C.stroke, Thickness = th or 1.5, Transparency = 0.2}, o) end
    local function button(text, parent, size, pos, color)
        local b = new("TextButton", {Text = text, Size = size, Position = pos, BackgroundColor3 = color or C.btn,
            TextColor3 = C.text, Font = Enum.Font.GothamBold, TextScaled = true, AutoButtonColor = true,
            BorderSizePixel = 0, RichText = true}, parent)
        round(b, 8)
        new("UITextSizeConstraint", {MaxTextSize = 13}, b)
        new("UIPadding", {PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5)}, b)
        return b
    end

    local guiParent = (type(gethui) == "function" and gethui()) or game:GetService("CoreGui")
    local okParent = pcall(function() local t = Instance.new("Folder"); t.Parent = guiParent; t:Destroy() end)
    if not okParent then guiParent = me:WaitForChild("PlayerGui") end
    local old = guiParent:FindFirstChild("GOY_SignalViewer")
    if old then old:Destroy() end

    local gui = new("ScreenGui", {Name = "GOY_SignalViewer", ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 60, Enabled = false}, guiParent)
    local win = new("Frame", {Size = UDim2.fromOffset(680, 440), Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = C.bg, BorderSizePixel = 0}, gui)
    round(win, 14); stroke(win, C.stroke, 2)
    new("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(26, 40, 64), Color3.fromRGB(13, 20, 34))}, win)
    local scale = new("UIScale", {}, win)
    local function fit()
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
        scale.Scale = math.clamp(math.min(vp.X * 0.9 / 680, vp.Y * 0.86 / 440), 0.5, 1.3)
    end
    fit()
    if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end

    -- Título + barra
    local bar = new("Frame", {Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1}, win)
    new("TextLabel", {Text = "Remote Spy", Size = UDim2.new(0, 150, 1, 0), Position = UDim2.fromOffset(14, 0),
        BackgroundTransparency = 1, TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 17,
        TextXAlignment = Enum.TextXAlignment.Left}, bar)
    local stats = new("TextLabel", {Text = "", Size = UDim2.new(0, 240, 1, 0), Position = UDim2.new(0, 150, 0, 0),
        BackgroundTransparency = 1, TextColor3 = C.dim, Font = Enum.Font.Gotham, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left}, bar)
    local iaBtn = button("IA", bar, UDim2.fromOffset(44, 26), UDim2.new(1, -120, 0, 6), C.btnOn)
    local minBtn = button("-", bar, UDim2.fromOffset(28, 24), UDim2.new(1, -68, 0, 6))
    local closeBtn = button("X", bar, UDim2.fromOffset(28, 24), UDim2.new(1, -34, 0, 6))
    new("Frame", {Size = UDim2.new(1, -24, 0, 2), Position = UDim2.fromOffset(12, 37), BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(70, 150, 230), BackgroundTransparency = 0.3}, win)
    do
        local UIS = game:GetService("UserInputService")
        local dragging, startPos, startInput
        bar.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging, startPos, startInput = true, win.Position, i.Position
            end
        end)
        UIS.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local d = (i.Position - startInput) / scale.Scale
                win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)
    end

    local body = new("Frame", {Size = UDim2.new(1, -20, 1, -46), Position = UDim2.fromOffset(10, 42), BackgroundTransparency = 1}, win)

    -- Fila de acciones
    local rxBtn = button("RX OFF", body, UDim2.fromOffset(64, 26), UDim2.fromOffset(0, 0))
    local modeBtn = button("Todos + mías", body, UDim2.fromOffset(96, 26), UDim2.fromOffset(68, 0))
    local clearBtn = button("Limpiar", body, UDim2.fromOffset(62, 26), UDim2.fromOffset(168, 0))
    local exportBtn = button("Exportar", body, UDim2.fromOffset(70, 26), UDim2.fromOffset(234, 0))
    local copyAllBtn = button("Copiar todo", body, UDim2.fromOffset(82, 26), UDim2.fromOffset(308, 0))
    local searchBox = new("TextBox", {PlaceholderText = "Buscar remoto, jugador o botón…", Text = "", ClearTextOnFocus = false,
        Size = UDim2.new(1, -394, 0, 26), Position = UDim2.fromOffset(394, 0), BackgroundColor3 = C.panel,
        TextColor3 = C.text, PlaceholderColor3 = C.dim, Font = Enum.Font.Gotham, TextSize = 13, BorderSizePixel = 0}, body)
    round(searchBox, 8)

    -- Pestañas con contador
    local TABS = {"Todas", "Mías", "Otros", "Generales", "Alertas", "Jugadores", "Botones", "Servidor"}
    local tabButtons = {}
    local tabW = 1 / #TABS
    for i, name in ipairs(TABS) do
        local b = button(name, body, UDim2.new(tabW, -4, 0, 24), UDim2.new(tabW * (i - 1), 0, 0, 32))
        tabButtons[name] = b
        b.MouseButton1Click:Connect(function() state.tab = name; state.selectedKey = nil; state.dirty = true end)
    end

    -- Lista izquierda
    local list = new("ScrollingFrame", {Size = UDim2.new(0.42, -6, 1, -62), Position = UDim2.fromOffset(0, 62),
        BackgroundColor3 = C.panel, BorderSizePixel = 0, ScrollBarThickness = 5, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y}, body)
    round(list, 10); stroke(list, C.stroke, 1)
    new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, list)
    new("UIPadding", {PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 6)}, list)

    -- Derecha: visor de código / servidor
    local right = new("Frame", {Size = UDim2.new(0.58, 0, 1, -62), Position = UDim2.new(0.42, 0, 0, 62), BackgroundTransparency = 1}, body)
    local header = new("TextLabel", {Text = "Selecciona una señal para ver su código.", Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1, TextColor3 = C.dim, Font = Enum.Font.GothamMedium, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, right)
    local codeScroll = new("ScrollingFrame", {Size = UDim2.new(1, 0, 1, -78), Position = UDim2.fromOffset(0, 20),
        BackgroundColor3 = C.panel, BorderSizePixel = 0, ScrollBarThickness = 5, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.XY}, right)
    round(codeScroll, 10); stroke(codeScroll, C.stroke, 1)
    local codeLabel = new("TextLabel", {Text = "", RichText = true, AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1, TextColor3 = C.text, Font = Enum.Font.Code,
        TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top}, codeScroll)
    new("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8)}, codeLabel)
    new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, codeScroll)
    codeLabel.LayoutOrder = 0
    -- Visor por trozos: Roblox no dibuja textos gigantes en una sola etiqueta.
    local viewExtra, lastViewKey = {}, nil
    local function setView(plain, colorFn)
        plain = plain or ""
        local key = plain .. "|" .. tostring(colorFn)
        if key == lastViewKey then return end
        lastViewKey = key
        for _, l in ipairs(viewExtra) do l:Destroy() end
        viewExtra = {}
        local lines = {}
        for l in (plain .. "\n"):gmatch("(.-)\n") do lines[#lines + 1] = l end
        local function chunk(i) return table.concat(lines, "\n", i, math.min(i + 149, #lines)) end
        local okC, rich = pcall(colorFn, chunk(1)); codeLabel.Text = okC and rich or esc(chunk(1))
        for i = 151, #lines, 150 do
            local okR, r = pcall(colorFn, chunk(i))
            viewExtra[#viewExtra + 1] = new("TextLabel", {Text = okR and r or esc(chunk(i)), RichText = true, AutomaticSize = Enum.AutomaticSize.XY,
                Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1, TextColor3 = C.text, Font = Enum.Font.Code, TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = i}, codeScroll)
        end
    end
    -- Caja de texto del servidor (oculta salvo en pestaña Servidor)
    local serverBox = new("TextBox", {PlaceholderText = "Pega aquí el código de un Script del servidor de TU juego…",
        Text = "", MultiLine = true, ClearTextOnFocus = false, TextWrapped = true,
        Size = UDim2.new(1, 0, 1, -78), Position = UDim2.fromOffset(0, 20), BackgroundColor3 = C.panel,
        TextColor3 = C.text, PlaceholderColor3 = C.dim, Font = Enum.Font.Code, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, BorderSizePixel = 0, Visible = false}, right)
    round(serverBox, 10); stroke(serverBox, C.stroke, 1)
    new("UIPadding", {PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)}, serverBox)
    serverBox:GetPropertyChangedSignal("Text"):Connect(function()
        local t = serverBox.Text
        if not t:find("%-%- … %(archivo completo cargado") then state.serverSrc = t end
    end)

    -- Botonera inferior derecha (dos juegos: señales y servidor)
    local prevBtn = button("<", right, UDim2.new(0, 46, 0, 26), UDim2.new(0, 0, 1, -54))
    local nextBtn = button(">", right, UDim2.new(0, 46, 0, 26), UDim2.new(0, 52, 1, -54))
    local copyBtn = button("Copiar", right, UDim2.new(0, 84, 0, 26), UDim2.new(0, 104, 1, -54), C.btnOn)
    local ignoreBtn = button("Ignorar", right, UDim2.new(0, 84, 0, 26), UDim2.new(0, 194, 1, -54))
    local copyTabBtn = button("Copiar tab", right, UDim2.new(0, 90, 0, 26), UDim2.new(0, 0, 1, -26))
    -- Servidor
    local analyzeBtn = button("Analizar", right, UDim2.new(0, 90, 0, 26), UDim2.new(0, 0, 1, -54), C.server)
    local fixBtn = button("Corregir código", right, UDim2.new(0, 130, 0, 26), UDim2.new(0, 96, 1, -54), C.ok)
    local copyFixBtn = button("Copiar", right, UDim2.new(0, 70, 0, 26), UDim2.new(0, 232, 1, -54), C.btnOn)
    local loadFileBtn = button("Cargar archivo", right, UDim2.new(0, 110, 0, 26), UDim2.new(0, 0, 1, -26), C.btn)
    local clearSrvBtn = button("Borrar", right, UDim2.new(0, 70, 0, 26), UDim2.new(0, 116, 1, -26), C.btn)

    ---------------- IA panel (chat con burbujas, "pensando…", código copiable) ----------------
    local IAC = {
        bg = Color3.fromRGB(14, 20, 34), head1 = Color3.fromRGB(60, 70, 190), head2 = Color3.fromRGB(30, 130, 200),
        me = Color3.fromRGB(46, 104, 200), ai = Color3.fromRGB(30, 40, 62), code = Color3.fromRGB(10, 14, 24),
        chip = Color3.fromRGB(36, 50, 78), input = Color3.fromRGB(22, 30, 48), send = Color3.fromRGB(70, 140, 240),
        online = Color3.fromRGB(80, 220, 130), offline = Color3.fromRGB(230, 90, 110), dim = Color3.fromRGB(140, 156, 182),
    }
    local IA_W, IA_H = 380, 470
    local iaGui = new("ScreenGui", {Name = "GOY_IA_Panel", ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 61, Enabled = false}, guiParent)
    local iaWin = new("Frame", {Size = UDim2.fromOffset(IA_W, IA_H), Position = UDim2.fromScale(0.72, 0.45),
        AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = IAC.bg, BorderSizePixel = 0, ClipsDescendants = true}, iaGui)
    round(iaWin, 16); stroke(iaWin, Color3.fromRGB(90, 120, 230), 2)
    local iaScale = new("UIScale", {Scale = 1}, iaWin)
    local function fitIA()
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
        iaScale.Scale = math.clamp(math.min(vp.X * 0.62 / IA_W, vp.Y * 0.86 / IA_H), 0.55, 1.2)
    end
    fitIA()
    if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitIA) end

    -- Cabecera con degradado
    local iaBar = new("Frame", {Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, iaWin)
    new("UIGradient", {Rotation = 0, Color = ColorSequence.new(IAC.head1, IAC.head2)}, iaBar)
    local avatar = new("TextLabel", {Text = "IA", Size = UDim2.fromOffset(32, 32), Position = UDim2.fromOffset(10, 9),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.8, TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBlack, TextSize = 14, BorderSizePixel = 0}, iaBar)
    round(avatar, 16)
    new("TextLabel", {Text = "IA GOY", Size = UDim2.new(1, -170, 0, 20), Position = UDim2.fromOffset(50, 7),
        BackgroundTransparency = 1, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left}, iaBar)
    local statusDot = new("Frame", {Size = UDim2.fromOffset(8, 8), Position = UDim2.fromOffset(51, 32),
        BackgroundColor3 = IAC.dim, BorderSizePixel = 0}, iaBar)
    round(statusDot, 4)
    local statusText = new("TextLabel", {Text = "Conectando…", Size = UDim2.new(1, -180, 0, 14), Position = UDim2.fromOffset(64, 29),
        BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(225, 232, 255), Font = Enum.Font.Gotham, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, iaBar)
    local function headBtn(text, x)
        local b = new("TextButton", {Text = text, Size = UDim2.fromOffset(30, 26), Position = UDim2.new(1, x, 0, 12),
            BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.82, TextColor3 = Color3.new(1, 1, 1),
            Font = Enum.Font.GothamBold, TextSize = 13, BorderSizePixel = 0, AutoButtonColor = true}, iaBar)
        round(b, 8)
        return b
    end
    local iaClear = headBtn("Lim", -104)
    local iaMin = headBtn("-", -70)
    local iaClose = headBtn("X", -36)
    iaClear.Size = UDim2.fromOffset(32, 26)
    do
        local UIS = game:GetService("UserInputService")
        local dragging, startPos, startInput
        iaBar.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging, startPos, startInput = true, iaWin.Position, i.Position
            end
        end)
        UIS.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local d = (i.Position - startInput) / iaScale.Scale
                iaWin.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)
    end

    local iaBody = new("Frame", {Size = UDim2.new(1, 0, 1, -50), Position = UDim2.fromOffset(0, 50), BackgroundTransparency = 1}, iaWin)
    -- Conversación
    local iaLog = new("ScrollingFrame", {Size = UDim2.new(1, -16, 1, -150), Position = UDim2.fromOffset(8, 8),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = IAC.dim,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y}, iaBody)
    new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, iaLog)
    new("UIPadding", {PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6)}, iaLog)

    -- "Pensando…" (aparece abajo mientras la IA trabaja)
    local thinking = new("Frame", {Size = UDim2.new(1, -16, 0, 20), Position = UDim2.new(0, 8, 1, -140),
        BackgroundTransparency = 1, Visible = false}, iaBody)
    local thinkDots = {}
    for i = 1, 3 do
        local d = new("Frame", {Size = UDim2.fromOffset(6, 6), Position = UDim2.fromOffset(4 + (i - 1) * 10, 7),
            BackgroundColor3 = IAC.send, BorderSizePixel = 0}, thinking)
        round(d, 3)
        thinkDots[i] = d
    end
    local thinkText = new("TextLabel", {Text = "IA pensando…", Size = UDim2.new(1, -40, 1, 0), Position = UDim2.fromOffset(38, 0),
        BackgroundTransparency = 1, TextColor3 = IAC.dim, Font = Enum.Font.GothamMedium, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left}, thinking)

    -- Atajos
    local chips = new("ScrollingFrame", {Size = UDim2.new(1, -16, 0, 30), Position = UDim2.new(0, 8, 1, -118), BackgroundTransparency = 1,
        BorderSizePixel = 0, ScrollBarThickness = 2, ScrollingDirection = Enum.ScrollingDirection.X, CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollBarImageColor3 = Color3.fromRGB(90, 120, 180)}, iaBody)
    new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, chips)
    local function chip(text, order, w)
        local b = new("TextButton", {Text = text, Size = UDim2.fromOffset(w, 26), BackgroundColor3 = IAC.chip, TextColor3 = C.text,
            Font = Enum.Font.GothamMedium, TextSize = 12, BorderSizePixel = 0, AutoButtonColor = true, LayoutOrder = order}, chips)
        round(b, 13); stroke(b, Color3.fromRGB(70, 100, 160), 1)
        return b
    end
    local iaFix = chip("Corregir código", 1, 118)
    local iaSignal = chip("Explicar señal", 2, 110)
    local iaCopy = chip("Copiar última", 6, 104)
    local iaRead = chip("Leer script", 5, 92)
    local iaMenu = chip("Crear menú", 3, 96)
    local iaCtx = chip("Mi juego: ON", 4, 104)
    iaCtx.BackgroundColor3 = Color3.fromRGB(40, 110, 80)

    -- Entrada
    local inputBox = new("Frame", {Size = UDim2.new(1, -16, 0, 74), Position = UDim2.new(0, 8, 1, -82),
        BackgroundColor3 = IAC.input, BorderSizePixel = 0}, iaBody)
    round(inputBox, 12); stroke(inputBox, Color3.fromRGB(70, 100, 160), 1)
    local iaInput = new("TextBox", {PlaceholderText = "Escribe un mensaje o pega tu código…", Text = "", ClearTextOnFocus = false,
        MultiLine = true, TextWrapped = true, Size = UDim2.new(1, -84, 1, -12), Position = UDim2.fromOffset(10, 6),
        BackgroundTransparency = 1, TextColor3 = C.text, PlaceholderColor3 = IAC.dim, Font = Enum.Font.Gotham, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top}, inputBox)
    local iaSend = new("TextButton", {Text = "Enviar", Size = UDim2.fromOffset(64, 36), Position = UDim2.new(1, -70, 1, -42),
        BackgroundColor3 = IAC.send, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 13,
        BorderSizePixel = 0, AutoButtonColor = true}, inputBox)
    round(iaSend, 10)

    ---- Burbujas ----
    local msgOrder = 0
    local iaLastReply = ""
    local function scrollDown()
        task.spawn(function()
            task.wait()
            pcall(function() iaLog.CanvasPosition = Vector2.new(0, 1e6) end)
        end)
    end
    local function md(text) -- **negrita** y `código` simple
        local t = esc(text)
        t = t:gsub("%*%*(.-)%*%*", "<b>%1</b>")
        t = t:gsub("`([^`\n]+)`", '<font face="RobotoMono" color="#9ece6a">%1</font>')
        return t
    end
    -- Separa la respuesta en texto y bloques ``` de código.
    local function splitReply(reply)
        local parts, pos = {}, 1
        while true do
            local s1, e1, lang = reply:find("```([%w_%+%-]*)[^\n]*\n?", pos)
            if not s1 then break end
            local s2, e2 = reply:find("```", e1 + 1, true)
            if s1 > pos then parts[#parts + 1] = {kind = "text", body = reply:sub(pos, s1 - 1)} end
            parts[#parts + 1] = {kind = "code", body = reply:sub(e1 + 1, (s2 or #reply + 1) - 1):gsub("\n$", "")}
            if not s2 then pos = #reply + 1; break end
            pos = e2 + 1
        end
        if pos <= #reply then parts[#parts + 1] = {kind = "text", body = reply:sub(pos)} end
        for i = #parts, 1, -1 do
            parts[i].body = parts[i].body:gsub("^%s+", ""):gsub("%s+$", "")
            if parts[i].body == "" then table.remove(parts, i) end
        end
        return parts
    end
    local function firstBrokenBlock(reply)
        if type(loadstring) ~= "function" then return nil end
        for _, part in ipairs(splitReply(reply)) do
            if part.kind == "code" then
                local okC, fn, e = pcall(loadstring, part.body)
                if not okC or not fn then return part.body, tostring((not okC) and fn or e) end
            end
        end
        return nil
    end
    local function typewrite(label)
        -- Animación de escritura (revela el texto poco a poco).
        task.spawn(function()
            local ok = pcall(function() label.MaxVisibleGraphemes = 0 end)
            if not ok then return end
            local plain = label.ContentText; if type(plain) ~= "string" or plain == "" then plain = label.Text:gsub("<[^>]->", "") end
            local total = utf8 and utf8.len(plain) or #plain
            local step = math.max(4, math.floor(total / 60))
            local shown = 0
            while shown < total and label.Parent do
                shown = shown + step
                label.MaxVisibleGraphemes = shown
                task.wait(0.02)
            end
            pcall(function() label.MaxVisibleGraphemes = -1 end)
            scrollDown()
        end)
    end
    local function addRow()
        msgOrder = msgOrder + 1
        return new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1, LayoutOrder = msgOrder}, iaLog)
    end
    local function bubble(row, fromMe, color)
        local b = new("Frame", {Size = UDim2.new(0.86, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            Position = fromMe and UDim2.new(0.14, 0, 0, 0) or UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = color, BorderSizePixel = 0}, row)
        round(b, 12)
        new("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, b)
        new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, b)
        return b
    end
    local function textIn(parent, rich, order, color)
        return new("TextLabel", {Text = rich, RichText = true, TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y,
            Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, TextColor3 = color or C.text, Font = Enum.Font.Gotham,
            TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = order}, parent)
    end
    local function codeIn(parent, code, order)
        local box = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = IAC.code,
            BorderSizePixel = 0, LayoutOrder = order}, parent)
        round(box, 8)
        new("UIPadding", {PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, box)
        new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, box)
        local top = new("Frame", {Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = 1}, box)
        new("TextLabel", {Text = "lua", Size = UDim2.new(1, -90, 1, 0), BackgroundTransparency = 1, TextColor3 = IAC.dim,
            Font = Enum.Font.GothamMedium, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left}, top)
        local cp = new("TextButton", {Text = "Copiar código", Size = UDim2.fromOffset(88, 20), Position = UDim2.new(1, -88, 0, 1),
            BackgroundColor3 = IAC.chip, TextColor3 = C.text, Font = Enum.Font.GothamMedium, TextSize = 11, BorderSizePixel = 0}, top)
        round(cp, 6)
        cp.MouseButton1Click:Connect(function() copy(code, "Código") ; cp.Text = "Copiado" ; task.delay(1.5, function() cp.Text = "Copiar código" end) end)
        local badge = top:FindFirstChildOfClass("TextLabel")
        local compiles, cerr = true, nil
        if type(loadstring) == "function" then
            local okC, fnOrNil, e = pcall(loadstring, code)
            compiles = okC and fnOrNil ~= nil
            cerr = (not okC) and tostring(fnOrNil) or e
        end
        if badge and type(loadstring) == "function" then
            badge.Text = compiles and "lua · compila bien" or ("lua · error: " .. tostring(cerr):gsub("^%[.-%]:", "línea "))
            badge.TextColor3 = compiles and Color3.fromRGB(110, 220, 140) or Color3.fromRGB(240, 110, 130)
            badge.TextTruncate = Enum.TextTruncate.AtEnd
        end
        -- Código largo: se dibuja en trozos de 120 líneas (Roblox no dibuja textos gigantes en una sola etiqueta).
        local lines = {}
        for l in (code .. "\n"):gmatch("(.-)\n") do lines[#lines + 1] = l end
        if badge and #lines > 40 then badge.Text = badge.Text .. (" · %d líneas"):format(#lines) end
        local function chunkAt(i)
            local chunk = table.concat(lines, "\n", i, math.min(i + 119, #lines))
            return new("TextLabel", {Text = colorize(chunk), RichText = true, TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y,
                Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, TextColor3 = C.text, Font = Enum.Font.Code, TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = 2 + i}, box)
        end
        local first = chunkAt(1)
        if #lines > 120 then
            -- El resto se dibuja en segundo plano, de 10 en 10 trozos, para no congelar el juego.
            task.spawn(function()
                local made = 0
                for i = 121, #lines, 120 do
                    if not box.Parent then break end
                    pcall(chunkAt, i)
                    made = made + 1
                    if made % 10 == 0 then task.wait() end
                end
            end)
        end
        return first, #lines
    end
    local function addMine(text)
        local row = addRow()
        local b = bubble(row, true, IAC.me)
        if #text > 600 or text:find("\n.*\n.*\n") then
            local _, nl = text:gsub("\n", "")
            textIn(b, ("<i>Código enviado (%d líneas, %d car.)</i>"):format(nl + 1, #text), 1)
            codeIn(b, text, 2)
        else
            textIn(b, md(text), 1, Color3.new(1, 1, 1))
        end
        scrollDown()
    end
    local function addAI(reply, isError)
        local row = addRow()
        local b = bubble(row, false, isError and Color3.fromRGB(70, 30, 46) or IAC.ai)
        local order = 0
        for _, part in ipairs(splitReply(reply)) do
            order = order + 1
            local lbl, n = nil, 0
            if part.kind == "code" then lbl, n = codeIn(b, part.body, order) else lbl = textIn(b, md(part.body), order) end
            if lbl and (n or 0) <= 150 then typewrite(lbl) end
        end
        scrollDown()
    end

    ---- Estado / conexión ----
    local function refreshStatus()
        if not state.config then loadConfig() end
        if state.config then
            statusDot.BackgroundColor3 = IAC.online
            statusText.Text = (state.config.aiUrl == DEFAULT_AI_URL) and "En línea · IA pública" or ("En línea · " .. (state.config.displayName or "tu worker"))
        else
            statusDot.BackgroundColor3 = IAC.offline
            statusText.Text = "Sin conexión · " .. tostring(state.configErr)
        end
    end

    local busy = false
    local function iaRun(kind, text)
        if busy or text == "" then return end
        busy = true
        addMine(text)
        thinking.Visible = true
        iaSend.Text = "…"
        iaSend.BackgroundColor3 = IAC.chip
        local started = os.clock()
        -- animación de los puntos + segundos
        task.spawn(function()
            local t = 0
            while busy do
                t = t + 1
                for i, d in ipairs(thinkDots) do
                    d.BackgroundTransparency = ((t + i) % 3 == 0) and 0 or 0.65
                    d.Position = UDim2.fromOffset(4 + (i - 1) * 10, ((t + i) % 3 == 0) and 4 or 7)
                end
                local secs = math.floor(os.clock() - started)
                local verb
                if kind == "fix_code" then
                    verb = secs < 2 and "leyendo tu código" or (secs < 6 and "buscando fallos" or "escribiendo la corrección")
                elseif kind == "make_menu" then
                    verb = secs < 3 and "planeando el menú" or "escribiendo el código del menú"
                elseif kind == "analyze_signal" then
                    verb = secs < 2 and "leyendo la señal" or "explicando la señal"
                elseif kind == "continue" then
                    verb = ("escribiendo la parte %d"):format(state.iaPart or 2)
                elseif kind == "read_script" then
                    verb = secs < 4 and "leyendo tu script" or "explicando para qué sirve cada parte"
                else
                    verb = "pensando"
                end
                thinkText.Text = ("IA %s… %ds"):format(verb, secs)
                task.wait(0.25)
            end
        end)
        task.spawn(function()
            local okA, reply, err, truncated = pcall(askAI, kind, text)
            if not okA then reply, err, truncated = nil, "error interno: " .. tostring(reply), false end
            -- Respuesta larga: pide la siguiente parte hasta terminar (máx. MAX_PARTS partes / MAX_LINES líneas).
            local function lineCount(t) local _, n = t:gsub("\n", ""); return n + 1 end
            local function openFence(t) local _, n = t:gsub("```", ""); return n % 2 == 1 end
            local part = 1
            while reply and (truncated or openFence(reply)) and part < MAX_PARTS and lineCount(reply) < MAX_LINES do
                part = part + 1
                kind = "continue"; state.iaPart = part
                local okC, more, _, tr = pcall(askAI, "continue", reply:sub(-3000))
                if not okC or type(more) ~= "string" or more == "" then break end
                if openFence(reply) then more = more:gsub("^%s*```[%w_]*%s*\n", "") end
                reply = reply .. (reply:sub(-1) == "\n" and "" or "\n") .. more
                truncated = tr
            end
            if reply and lineCount(reply) > MAX_LINES then
                local cut, n = {}, 0
                for l in (reply .. "\n"):gmatch("(.-)\n") do n = n + 1; if n > MAX_LINES then break end; cut[#cut + 1] = l end
                reply = table.concat(cut, "\n") .. (openFence(table.concat(cut, "\n")) and "\n```" or "") .. "\n\n*(Se llegó al máximo de 10,000 líneas.)*"
            end
            -- Si el código que dio no compila, se lo devuelve a la IA una vez para que lo arregle.
            if reply then
                local broken, cerr = firstBrokenBlock(reply)
                local _, bl = (broken or ""):gsub("\n", "")
                if broken and bl < 1500 then
                    kind = "fix_code"
                    local okF, fixed = pcall(askAI, "fix_code", ("Tu código tiene este error de sintaxis: %s\nArréglalo y devuélvelo completo en un solo bloque ```lua.\n```lua\n%s\n```"):format(cerr, broken))
                    if okF and type(fixed) == "string" and not firstBrokenBlock(fixed) then reply = fixed end
                end
            end
            busy = false
            thinking.Visible = false
            iaSend.Text = "Enviar"
            iaSend.BackgroundColor3 = IAC.send
            if reply then
                iaLastReply = reply
                local okD, derr = pcall(addAI, reply, false)
                if not okD then pcall(addAI, "No pude dibujar la respuesta (" .. tostring(derr) .. "). Toca **Copiar última** para verla.", true) end
                statusDot.BackgroundColor3 = IAC.online
            else
                pcall(addAI, "No pude responder: " .. tostring(err), true)
                statusDot.BackgroundColor3 = IAC.offline
            end
        end)
    end
    local function sendFromBox(kind)
        local t = iaInput.Text
        if t:gsub("%s", "") == "" then return end
        iaInput.Text = ""
        iaRun(kind, t)
    end
    iaSend.MouseButton1Click:Connect(function() sendFromBox("chat") end)
    iaInput.FocusLost:Connect(function(enter) if enter and not iaInput.MultiLine then sendFromBox("chat") end end)
    iaFix.MouseButton1Click:Connect(function()
        if iaInput.Text:gsub("%s", "") == "" then addAI("Pega tu código en la caja y toca **Corregir código**.", false) return end
        sendFromBox("fix_code")
    end)
    iaSignal.MouseButton1Click:Connect(function()
        local g = state.selectedKey and state.groups[state.selectedKey]
        if g then iaRun("analyze_signal", codeOf(g)) else addAI("Selecciona una señal en el Remote Spy y vuelve a tocar **Explicar señal**.", false) end
    end)
    iaMenu.MouseButton1Click:Connect(function()
        if iaInput.Text:gsub("%s", "") == "" then addAI("Escribe qué menú quieres (por ejemplo: **menú con 3 botones: velocidad, salto y reset**) y toca **Crear menú**.", false) return end
        sendFromBox("make_menu")
    end)
    iaCtx.MouseButton1Click:Connect(function()
        state.useCtx = not state.useCtx
        iaCtx.Text = state.useCtx and "Mi juego: ON" or "Mi juego: OFF"
        iaCtx.BackgroundColor3 = state.useCtx and Color3.fromRGB(40, 110, 80) or IAC.chip
        if state.useCtx and (state.serverSrc or ""):gsub("%s", "") == "" then
            addAI("Para que use el código de tu juego, pégalo en la pestaña **Servidor** del Remote Spy. Sin eso solo verá los nombres de las señales recibidas.", false)
        end
    end)
    -- Leer script: lee un archivo de la carpeta workspace de tu ejecutor (solo lectura, no lo ejecuta).
    iaRead.MouseButton1Click:Connect(function()
        local path = iaInput.Text:gsub("^%s+", ""):gsub("%s+$", "")
        if not path:find("%.%a+$") or path:find("\n") then path = "GOY_IA/mi_script.lua" end
        if type(readfile) ~= "function" then addAI("Tu ejecutor no tiene **readfile**. Pega el código en la caja y toca **Enviar**.", true) return end
        local okF, exists = pcall(function() return type(isfile) ~= "function" or isfile(path) end)
        if not okF or not exists then
            addAI(("No encontré **%s**. Guarda tu script en la carpeta workspace del ejecutor con ese nombre, o escribe la ruta en la caja y vuelve a tocar **Leer script**."):format(path), true)
            return
        end
        local okR, src = pcall(readfile, path)
        if not okR or type(src) ~= "string" or src == "" then addAI("No pude leer " .. path, true) return end
        state.scriptSrc, state.scriptName = src, path
        state.useCtx = true; iaCtx.Text = "Mi juego: ON"; iaCtx.BackgroundColor3 = Color3.fromRGB(40, 110, 80)
        iaInput.Text = ""
        local _, n = src:gsub("\n", "")
        iaRun("read_script", ("Leí %s (%d líneas). Explícame para qué sirve cada parte y qué partes se parecen."):format(path, n + 1))
    end)
    iaCopy.MouseButton1Click:Connect(function()
        if iaLastReply ~= "" then copy(iaLastReply, "Respuesta IA") else notify("GOY\nAún no hay respuesta") end
    end)
    iaClear.MouseButton1Click:Connect(function()
        state.scriptSrc, state.scriptName = nil, nil
        for _, c in ipairs(iaLog:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
        aiMemory = {}
        iaLastReply = ""
        addAI("Chat limpio. ¿En qué te ayudo?", false)
    end)
    local iaMinimized = false
    iaMin.MouseButton1Click:Connect(function()
        iaMinimized = not iaMinimized
        iaBody.Visible = not iaMinimized
        iaWin.Size = iaMinimized and UDim2.fromOffset(IA_W, 50) or UDim2.fromOffset(IA_W, IA_H)
    end)
    iaClose.MouseButton1Click:Connect(function() iaGui.Enabled = false end)
    local greeted = false
    local function openIA()
        iaGui.Enabled = true
        if not greeted then
            greeted = true
            refreshStatus()
            addAI("Hola, soy la IA de GOY. Escríbeme lo que necesites, pega tu código para **corregirlo**, o selecciona una señal y toca **Explicar señal**.", false)
        end
    end
    iaBtn.MouseButton1Click:Connect(function() if iaGui.Enabled then iaGui.Enabled = false else openIA() end end)
    SHARED.openIA = openIA

    ---------------- Render ----------------
    local visibleKeys, rowPool, currentRows = {}, {}, {}
    local function zoneColor(z) return z == "Mías" and C.mine or (z == "Otros" and C.other or C.general) end
    local function matches(g)
        if state.search ~= "" then
            local q = string.lower(state.search)
            if not string.find(string.lower(g.name .. " " .. table.concat(g.players, " ")), q, 1, true) then return false end
        end
        if state.tab == "Todas" then return true end
        if state.tab == "Alertas" then return g.spam end
        if state.tab == "Mías" then return g.zone == "Mías" end
        if state.tab == "Otros" then return g.zone == "Otros" end
        if state.tab == "Generales" then return g.zone == "Generales" end
        return false
    end
    local function counts()
        local c = {Todas = 0, ["Mías"] = 0, Otros = 0, Generales = 0, Alertas = #state.alerts, Jugadores = 0, Botones = #state.buttonOrder, Servidor = 0}
        for _, key in ipairs(state.order) do
            local g = state.groups[key]
            if g then c.Todas = c.Todas + 1; c[g.zone] = (c[g.zone] or 0) + 1; if g.spam then c.Alertas = c.Alertas + 1 end end
        end
        for _ in pairs(state.perPlayer) do c.Jugadores = c.Jugadores + 1 end
        return c
    end
    local function signalLine(g)
        local tag = g.zone == "Mías" and "Mía" or (g.zone == "Otros" and (g.players[1] or "Otro") or "General")
        local x = g.count > 1 and ("  x" .. g.count) or ""
        return ("%s%s\n%s · %d args · %s"):format(g.name, x, tag, g.nargs or 0, g.last or "")
    end
    local function computeRows()
        local rows = {}
        if state.tab == "Alertas" then
            for i, a in ipairs(state.alerts) do
                if #rows >= ROWS_SHOWN then break end
                rows[#rows + 1] = {key = "alert:" .. i, text = ("! %s  %s -> %s"):format(a.time, a.who, a.remote), color = C.alert, alert = a}
            end
            for _, key in ipairs(state.order) do
                local g = state.groups[key]
                if g and g.spam and (state.search == "" or string.find(string.lower(g.name), string.lower(state.search), 1, true)) then
                    rows[#rows + 1] = {key = key, text = ("%s x%d\nspam"):format(g.name, g.count), color = C.alert, group = g}
                end
            end
        elseif state.tab == "Jugadores" then
            local names = {}
            for name in pairs(state.perPlayer) do names[#names + 1] = name end
            table.sort(names, function(a, b) return state.perPlayer[a] > state.perPlayer[b] end)
            for _, name in ipairs(names) do
                if #rows >= ROWS_SHOWN then break end
                if state.search == "" or string.find(string.lower(name), string.lower(state.search), 1, true) then
                    rows[#rows + 1] = {key = "player:" .. name, text = ("%s\n%d señales"):format(name, state.perPlayer[name]), color = C.other, player = name}
                end
            end
        elseif state.tab == "Botones" then
            for _, name in ipairs(state.buttonOrder) do
                if #rows >= ROWS_SHOWN then break end
                if state.search == "" or string.find(string.lower(name), string.lower(state.search), 1, true) then
                    local b = state.buttons[name]
                    local nsig = 0; for _ in pairs(b.signals) do nsig = nsig + 1 end
                    rows[#rows + 1] = {key = "button:" .. name, text = ("%s\n%d señales · %s"):format(name, nsig, b.last), color = C.button, buttonName = name, go = nsig > 0 and "Evento" or nil}
                end
            end
        elseif state.tab == "Servidor" then
            for k, e in ipairs(state.events) do
                if #rows >= ROWS_SHOWN then break end
                if state.search == "" or string.find(string.lower(e.title), string.lower(state.search), 1, true) then
                    rows[#rows + 1] = {key = "event:" .. k, text = ("%s\nlínea %d · %s"):format(e.title, e.line, e.info),
                        color = C.server, event = e, go = "Señal"}
                end
            end
        else
            for _, key in ipairs(state.order) do
                if #rows >= ROWS_SHOWN then break end
                local g = state.groups[key]
                if g and matches(g) then
                    rows[#rows + 1] = {key = key, text = signalLine(g), color = g.spam and C.alert or zoneColor(g.zone), group = g, go = "Código"}
                end
            end
        end
        return rows
    end
    local function detailFor(row)
        if not row then return "", "Selecciona una señal para ver su código." end
        if row.group then
            local g = row.group
            return codeOf(g), ("%s · %s · ×%d · %d args"):format(g.zone, g.name, g.count, g.nargs or 0)
        elseif row.alert then
            local a = row.alert
            return ("-- Alerta\n-- %s\n-- %s → %s\n-- El servidor envió una señal que te involucra."):format(a.time, a.who, a.remote), "Alerta"
        elseif row.player then
            local out = {("-- Señales donde aparece %s"):format(row.player)}
            for _, key in ipairs(state.order) do
                local g = state.groups[key]
                if g then for _, n in ipairs(g.players) do if n == row.player then out[#out + 1] = ("%s  %s x%d"):format(g.zone, g.name, g.count); break end end end
            end
            return table.concat(out, "\n"), "Jugador: " .. row.player
        elseif row.event then
            local e = row.event
            local hdr = {("-- Evento: %s  (%s)"):format(e.title, e.info), ("-- Líneas %d-%d · %s"):format(e.line, e.lastLine or e.line, e.how)}
            if e.params ~= "" then hdr[#hdr + 1] = "-- Recibe: " .. e.params end
            if #e.actions > 0 then hdr[#hdr + 1] = "-- Acciones: " .. table.concat(e.actions, ", ") end
            if #e.fires > 0 then hdr[#hdr + 1] = "-- Dispara: " .. table.concat(e.fires, ", ") end
            return table.concat(hdr, "\n") .. "\n\n" .. e.body, "Evento " .. e.title .. " · línea " .. e.line
        elseif row.buttonName then
            local b = state.buttons[row.buttonName]
            local out = {("-- Botón: %s"):format(row.buttonName), ("-- Señales del servidor tras pulsarlo:"):format()}
            for _, sig in pairs(b.signals) do out[#out + 1] = ""; out[#out + 1] = sig.code end
            if #out == 2 then out[#out + 1] = "(aún sin señales registradas para este botón)" end
            return table.concat(out, "\n"), "Botón: " .. row.buttonName
        end
        return "", ""
    end
    -- Saltos entre opciones: señal <-> evento del código, botón -> su señal.
    local jumpFrom
    local function findEventFor(name)
        local lname = string.lower(name or "")
        for k, e in ipairs(state.events) do if string.lower(e.name) == lname then return k end end
        for k, e in ipairs(state.events) do if e.body:lower():find(lname, 1, true) then return k end end
        return nil
    end
    local function findGroupFor(name)
        local lname = string.lower(name or "")
        for _, key in ipairs(state.order) do local g = state.groups[key]; if g and string.lower(g.name) == lname then return key end end
        return nil
    end
    jumpFrom = function(row)
        if not row then return end
        if row.group then
            local k = findEventFor(row.group.name)
            if k then
                state.tab = "Servidor"; state.selectedKey = "event:" .. k; state.dirty = true
                notify("GOY\nEvento del código: " .. state.events[k].title)
            else
                notify("GOY\nNo hay código de " .. row.group.name .. ". Pega tu Script en Servidor y toca Analizar.")
            end
        elseif row.event then
            local key = findGroupFor(row.event.name)
            for _, f in ipairs(row.event.fires) do key = key or findGroupFor(f) end
            if key then
                state.tab = "Todas"; searchBox.Text = ""; state.search = ""; state.selectedKey = key; state.dirty = true
                notify("GOY\nSeñal recibida: " .. state.groups[key].name)
            else
                notify("GOY\nAún no llegó ninguna señal de " .. row.event.name .. ". Enciende RX y haz la acción en el juego.")
            end
        elseif row.buttonName then
            local b = state.buttons[row.buttonName]
            local firstKey
            for key in pairs(b and b.signals or {}) do if state.groups[key] then firstKey = key; break end end
            if firstKey then
                state.tab = "Todas"; searchBox.Text = ""; state.search = ""; state.selectedKey = firstKey; state.dirty = true
            else
                notify("GOY\nEse botón aún no tiene señales")
            end
        end
    end
    local function render()
        local c = counts()
        for name, b in pairs(tabButtons) do
            b.BackgroundColor3 = (name == state.tab) and C.btnOn or C.btn
            b.Text = ("%s %d"):format(name, c[name] or 0)
            if name == "Alertas" and (c.Alertas or 0) > 0 and name ~= state.tab then b.BackgroundColor3 = C.warn end
        end
        rxBtn.Text = state.listening and "RX ON" or "RX OFF"
        rxBtn.BackgroundColor3 = state.listening and C.ok or C.btn
        modeBtn.Text = state.mode == "mine" and "Solo mías" or "Todos + mías"
        local hooked = 0; for _ in pairs(state.conns) do hooked = hooked + 1 end
        stats.Text = ("%d remotos · M %d · O %d · G %d"):format(hooked, state.totals["Mías"], state.totals["Otros"], state.totals["Generales"])

        local serverTab = state.tab == "Servidor"
        serverBox.Visible = serverTab
        codeScroll.Visible = true
        list.Visible = true
        if serverTab then
            serverBox.Size = UDim2.new(1, 0, 0.36, -10)
            codeScroll.Position = UDim2.new(0, 0, 0.36, 14)
            codeScroll.Size = UDim2.new(1, 0, 0.64, -72)
        else
            codeScroll.Position = UDim2.fromOffset(0, 20)
            codeScroll.Size = UDim2.new(1, 0, 1, -78)
        end
        prevBtn.Visible = not serverTab; nextBtn.Visible = not serverTab
        copyBtn.Visible = not serverTab; ignoreBtn.Visible = not serverTab; copyTabBtn.Visible = not serverTab
        analyzeBtn.Visible = serverTab; fixBtn.Visible = serverTab; copyFixBtn.Visible = serverTab
        loadFileBtn.Visible = serverTab; clearSrvBtn.Visible = serverTab

        currentRows = computeRows()
        visibleKeys = {}
        for i, row in ipairs(currentRows) do
            visibleKeys[i] = row.key
            local b = rowPool[i]
            if not b then
                b = new("TextButton", {Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = C.row, BorderSizePixel = 0,
                    TextColor3 = C.text, Font = Enum.Font.Gotham, TextSize = 13, AutoButtonColor = true,
                    TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
                    TextWrapped = false, LayoutOrder = i}, list)
                round(b, 7)
                new("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingTop = UDim.new(0, 3)}, b)
                new("Frame", {Name = "Bar", Size = UDim2.new(0, 4, 1, -8), Position = UDim2.new(0, -8, 0, 4), BorderSizePixel = 0}, b)
                local go = new("TextButton", {Name = "Go", Text = "->", Size = UDim2.fromOffset(44, 26), Position = UDim2.new(1, -46, 0.5, -13),
                    BackgroundColor3 = C.btnOn, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 11, BorderSizePixel = 0, ZIndex = 3}, b)
                round(go, 6)
                local index = i
                b.MouseButton1Click:Connect(function() state.selectedKey = visibleKeys[index]; state.dirty = true end)
                go.MouseButton1Click:Connect(function() pcall(jumpFrom, currentRows[index]) end)
                rowPool[i] = b
            end
            b.Visible = true
            b.Text = row.text
            b.Go.Visible = row.go ~= nil
            b.Go.Text = row.go or ""
            b.Bar.BackgroundColor3 = row.color
            b.BackgroundColor3 = (row.key == state.selectedKey) and C.rowSel or C.row
        end
        for i = #currentRows + 1, #rowPool do rowPool[i].Visible = false end

        local selected
        for _, row in ipairs(currentRows) do if row.key == state.selectedKey then selected = row end end
        if serverTab and not selected then
            header.Text = (#state.events > 0) and ("%d eventos · toca uno para ver su código"):format(#state.events)
                or "Pega el código de TU juego (o Cargar archivo) y toca Analizar."
            setView(state.serverPlain or "", state.serverColor or colorize)
            return
        end
        local text, head = detailFor(selected)
        setView(text, colorize)
        header.Text = head
    end
    local function selectIndex(delta)
        if #currentRows == 0 then return end
        local idx = 0
        for i, row in ipairs(currentRows) do if row.key == state.selectedKey then idx = i end end
        idx = math.clamp((idx == 0 and 1 or idx + delta), 1, #currentRows)
        state.selectedKey = currentRows[idx].key; state.dirty = true
    end

    rxBtn.MouseButton1Click:Connect(function() if state.listening then stopListening() else startListening() end end)
    modeBtn.MouseButton1Click:Connect(function() state.mode = (state.mode == "all") and "mine" or "all"; state.dirty = true end)
    clearBtn.MouseButton1Click:Connect(function() clearAll(); notify("GOY\nSeñales reiniciadas") end)
    exportBtn.MouseButton1Click:Connect(function() copy(fullReport(), "Reporte completo") end)
    copyAllBtn.MouseButton1Click:Connect(function() copy(fullReport(), "Reporte completo") end)
    searchBox:GetPropertyChangedSignal("Text"):Connect(function() state.search = searchBox.Text; state.dirty = true end)
    prevBtn.MouseButton1Click:Connect(function() selectIndex(-1) end)
    nextBtn.MouseButton1Click:Connect(function() selectIndex(1) end)
    copyBtn.MouseButton1Click:Connect(function()
        local g = state.selectedKey and state.groups[state.selectedKey]
        if g then copy(codeOf(g), "Código") else
            local sel; for _, r in ipairs(currentRows) do if r.key == state.selectedKey then sel = r end end
            local t = select(1, detailFor(sel)); if t ~= "" then copy(t, "Selección") else notify("GOY\nSelecciona algo primero") end
        end
    end)
    copyTabBtn.MouseButton1Click:Connect(function()
        local parts = {"-- GOY Remote Spy: pestaña " .. state.tab}
        for _, row in ipairs(currentRows) do parts[#parts + 1] = (detailFor(row)); parts[#parts + 1] = "" end
        copy(table.concat(parts, "\n"), "Pestaña " .. state.tab)
    end)
    ignoreBtn.MouseButton1Click:Connect(function()
        local g = state.selectedKey and state.groups[state.selectedKey]
        if not g then notify("GOY\nSelecciona una señal para ignorar su remoto"); return end
        state.ignored[g.name] = true
        for key, other in pairs(state.groups) do
            if other.name == g.name then
                state.groups[key] = nil
                for i, k in ipairs(state.order) do if k == key then table.remove(state.order, i); break end end
            end
        end
        state.selectedKey = nil; state.dirty = true
        notify("GOY\nIgnorando " .. g.name)
    end)
    local function reportColor(text)
        local out = {}
        for line in (text .. "\n"):gmatch("(.-)\n") do
            if line:find("%[OK%]") then out[#out + 1] = span(HI.str, esc(line))
            elseif line:find("%[FALTA%]") then out[#out + 1] = span(HI.kw, esc(line))
            elseif line:find("^%-%-") then out[#out + 1] = span(HI.com, esc(line))
            else out[#out + 1] = span(HI.name, esc(line)) end
        end
        return table.concat(out, "\n")
    end
    local function srcNow()
        local t = serverBox.Text or ""
        if t ~= "" and not t:find("%-%- … %(archivo completo cargado") then state.serverSrc = t end
        return state.serverSrc or ""
    end
    analyzeBtn.MouseButton1Click:Connect(function()
        local src = srcNow()
        if src:gsub("%s", "") == "" then notify("GOY\nPega el código primero o toca Cargar archivo") return end
        local okA, rep = pcall(analyzeServer, src)
        local okE, evs = pcall(extractEvents, src)
        state.events = okE and evs or {}
        local text = (okA and rep or ("-- El análisis tuvo un problema: " .. tostring(rep)))
        text = text .. "\n\n" .. eventReport(state.events)
        if not okE then text = text .. "\n-- (no pude leer los eventos: " .. tostring(evs) .. ")" end
        state.serverReport, state.serverCopy = text, text
        state.serverPlain, state.serverColor = text, reportColor
        state.selectedKey = nil; state.dirty = true
        notify(("GOY\nAnálisis listo · %d eventos"):format(#state.events))
    end)
    fixBtn.MouseButton1Click:Connect(function()
        local src = srcNow()
        if src:gsub("%s", "") == "" then notify("GOY\nPega el código primero") return end
        local okF, fixed = pcall(fixServer, src)
        if not okF then
            state.serverPlain, state.serverColor = "-- No pude corregirlo: " .. tostring(fixed), colorize
            state.dirty = true; return
        end
        state.serverFixed, state.serverCopy = fixed, fixed
        state.serverPlain, state.serverColor = fixed, colorize
        local okE, evs = pcall(extractEvents, src); state.events = okE and evs or state.events
        state.selectedKey = nil; state.dirty = true
        notify("GOY\nCódigo corregido (completo). Toca Copiar.")
    end)
    loadFileBtn.MouseButton1Click:Connect(function()
        if type(readfile) ~= "function" then notify("GOY\nTu ejecutor no tiene readfile") return end
        local path = (serverBox.Text or ""):match("^%s*([%w_%-%./ ]+%.%a+)%s*$") or "GOY_IA/servidor.lua"
        local okF, exists = pcall(function() return type(isfile) ~= "function" or isfile(path) end)
        if not okF or not exists then notify("GOY\nNo encontré " .. path .. " en la carpeta workspace") return end
        local okR, src = pcall(readfile, path)
        if not okR or type(src) ~= "string" then notify("GOY\nNo pude leer " .. path) return end
        state.serverSrc = src
        local _, nl = src:gsub("\n", "")
        -- la caja solo muestra el inicio si es enorme; el análisis usa el archivo completo
        serverBox.Text = #src > 15000 and (src:sub(1, 15000) .. "\n-- … (archivo completo cargado: " .. (nl + 1) .. " líneas)") or src
        state.serverSrc = src
        notify(("GOY\nCargado %s · %d líneas. Toca Analizar."):format(path, nl + 1))
    end)
    clearSrvBtn.MouseButton1Click:Connect(function()
        serverBox.Text = ""; state.serverSrc = ""; state.events = {}; state.serverPlain = ""; state.selectedKey = nil; state.dirty = true
    end)
    copyFixBtn.MouseButton1Click:Connect(function()
        if state.serverCopy and state.serverCopy ~= "" then copy(state.serverCopy, "Servidor") else notify("GOY\nAnaliza o corrige primero") end
    end)

    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        body.Visible = not minimized
        win.Size = minimized and UDim2.fromOffset(680, 38) or UDim2.fromOffset(680, 440)
    end)
    closeBtn.MouseButton1Click:Connect(function() gui.Enabled = false end)

    ---------------- Premium Info ----------------
    local section = PremiumInfo_Tab:AddSection({Name = "Remote Spy v1.5.7 (solo lectura)"})
    section:AddButton({Name = "Abrir Remote Spy", Callback = function() gui.Enabled = true; state.dirty = true end})
    section:AddButton({Name = "Abrir IA", Callback = function() iaGui.Enabled = true end})
    section:AddToggle({Name = "Recibir señales (RX)", Default = false, Callback = function(on)
        if on then startListening() else stopListening() end
    end})
    section:AddButton({Name = "Reiniciar señales", Callback = function() clearAll(); notify("GOY\nSeñales reiniciadas") end})
    section:AddButton({Name = "Restaurar remotos ignorados", Callback = function() state.ignored = {}; notify("GOY\nIgnorados restaurados") end})
    section:AddButton({Name = "Copiar reporte completo", Callback = function() copy(fullReport(), "Reporte completo") end})
    section:AddParagraph("Remote Spy", "Panel grande con código en colores, filtros con contador, registro por botón, pestaña Servidor e IA. Solo escucha señales entrantes; no envía ni manipula remotos.")

    _G.GOY_RSPY_CLEANUP = function() ENV.GOY_SIGNAL_VIEWER_TOKEN = -1 end
    while alive() do
        task.wait(UI_REFRESH)
        if state.dirty and gui.Enabled then state.dirty = false; pcall(render) end
    end
    stopListening()
    for d, c in pairs(state.btnConns) do pcall(function() c:Disconnect() end) end
    pcall(function() gui:Destroy() end)
    pcall(function() iaGui:Destroy() end)
end)

-- GOY FREE v1.5.6 | VIDEO EXCLUSIVO EN EL MENÚ DE JUGUETES DEL JUEGO  (v6: canción propia + video infinito + destello neón)
-- Pone tu video (con su música sincronizada) DETRÁS del menú de juguetes
-- ("Tus juguetes", con el contador 0/100), con fondo gris y menos brillo.
-- No toca botones ni funciones: solo agrega una capa al fondo.
-- Menú cerrado = música y video detenidos. Menú abierto = video y música desde 0.
-- Video y música van separados: el video (sin su música) se repite infinitamente y tu
-- canción suena COMPLETA y vuelve a empezar sola al terminar. Al tocar un botón del
-- menú de juguetes, el video da un destello fluorescente.
-- Archivos en tu GitHub (repo u, carpeta goy_video_v2/): menu_music_2.ogg y menu_sheet_1..16.jpg
-- Fuente: copy_345FD440-0363-4072-B3B8-D69A7832ADD3.MOV (140 fotogramas reales, 30 FPS, 4,67 s)
-- =====================================================================
task.spawn(function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local player = Players.LocalPlayer
    if not player then return end

    -- Una sola instancia del reproductor aunque ejecutes el script varias veces:
    -- cada ejecución nueva sube el token y las anteriores se apagan solas.
    local ENV = (type(getgenv) == "function" and getgenv()) or _G
    ENV.GOY_TOY_VIDEO_TOKEN = (ENV.GOY_TOY_VIDEO_TOKEN or 0) + 1
    local MY_TOKEN = ENV.GOY_TOY_VIDEO_TOKEN
    local function alive() return ENV.GOY_TOY_VIDEO_TOKEN == MY_TOKEN end

    ---------------- AJUSTES (puedes cambiarlos) ----------------
    local VIDEO_TINT = Color3.fromRGB(165, 165, 165)  -- oscurece el video (255 = sin cambio)
    local GRAY_OVERLAY = Color3.fromRGB(58, 64, 68)   -- velo gris encima del video
    local GRAY_OVERLAY_TRANSPARENCY = 0.42            -- 0 = muy oscuro, 1 = sin velo
    local VOLUME = 0.8
    local SEE_THROUGH = true  -- vuelve transparentes los fondos grandes del menú para que se vea el video
    local RENDER_STEP = 1     -- 1 = todos los fotogramas; 2 = uno de cada dos (modo ahorro para iPhone viejos)
    local WAIT_FOR_ALL_SHEETS = 8 -- segundos máx. esperando a que carguen todas las hojas antes de arrancar (0 = no esperar)
    --------------------------------------------------------------

    ---------------- CONFIGURACIÓN CENTRAL DEL VIDEO ----------------
    -- Todo el recorte se calcula con estos datos. Para otro video: genera las hojas,
    -- cambia esta tabla y listo (nada más del código tiene nombres de archivo).
    local VIDEO = {
        OWNER = "eduardomorfin58-ux", REPO = "u", BRANCH = "main",
        FOLDER = "goy_video_v2/",          -- carpeta dentro del repo ("" = raíz)
        CACHE_PREFIX = "goy67_v2_",        -- prefijo nuevo: no choca con la caché del video viejo
        FPS = 30,                          -- FPS reales del video fuente (no subir sin fotogramas reales)
        TOTAL_FRAMES = 140,
        COLS = 3, ROWS = 3,                -- cuadrícula máxima de cada hoja
        FRAME_W = 336, FRAME_H = 333,      -- tamaño de cada fotograma (px)
        MARGIN = 2, PADDING = 2,           -- borde exterior y separación entre fotogramas (px)
        AUDIO = {file = "menu_music_2.ogg", size = 135640}, -- tu canción nueva (9,5 s), sin la música del video
        -- w/h = tamaño REAL de cada hoja; frames = cuántos fotogramas trae (la última puede traer menos)
        SHEETS = {
        {file="menu_sheet_1.jpg", size=208265, w=1016, h=1007, frames=9},
        {file="menu_sheet_2.jpg", size=233659, w=1016, h=1007, frames=9},
        {file="menu_sheet_3.jpg", size=247589, w=1016, h=1007, frames=9},
        {file="menu_sheet_4.jpg", size=252606, w=1016, h=1007, frames=9},
        {file="menu_sheet_5.jpg", size=254380, w=1016, h=1007, frames=9},
        {file="menu_sheet_6.jpg", size=258128, w=1016, h=1007, frames=9},
        {file="menu_sheet_7.jpg", size=256939, w=1016, h=1007, frames=9},
        {file="menu_sheet_8.jpg", size=258910, w=1016, h=1007, frames=9},
        {file="menu_sheet_9.jpg", size=260954, w=1016, h=1007, frames=9},
        {file="menu_sheet_10.jpg", size=262027, w=1016, h=1007, frames=9},
        {file="menu_sheet_11.jpg", size=258209, w=1016, h=1007, frames=9},
        {file="menu_sheet_12.jpg", size=259829, w=1016, h=1007, frames=9},
        {file="menu_sheet_13.jpg", size=260185, w=1016, h=1007, frames=9},
        {file="menu_sheet_14.jpg", size=260703, w=1016, h=1007, frames=9},
        {file="menu_sheet_15.jpg", size=259751, w=1016, h=1007, frames=9},
        {file="menu_sheet_16.jpg", size=147805, w=1016, h=672, frames=5},
        },
    }
    -----------------------------------------------------------------

    local FPS = VIDEO.FPS
    local COLS, ROWS = VIDEO.COLS, VIDEO.ROWS
    local FRAME_W, FRAME_H, MARGIN, PADDING = VIDEO.FRAME_W, VIDEO.FRAME_H, VIDEO.MARGIN, VIDEO.PADDING
    local SHEETS = VIDEO.SHEETS
    local BASE_URL = ("https://raw.githubusercontent.com/%s/%s/%s/%s"):format(VIDEO.OWNER, VIDEO.REPO, VIDEO.BRANCH, VIDEO.FOLDER)
    local CACHE_PREFIX = VIDEO.CACHE_PREFIX

    -- Mapa fotograma -> {hoja, desplazamiento}. Se valida que cada recorte quepa en su hoja.
    local FRAME_MAP = {}
    do
        local nextIndex = 0
        for sheetIndex, entry in ipairs(SHEETS) do
            local count = math.min(entry.frames or (COLS * ROWS), COLS * ROWS)
            for localIndex = 0, count - 1 do
                local col, row = localIndex % COLS, math.floor(localIndex / COLS)
                local x = MARGIN + col * (FRAME_W + PADDING)
                local y = MARGIN + row * (FRAME_H + PADDING)
                if entry.w and entry.h and (x + FRAME_W > entry.w or y + FRAME_H > entry.h) then
                    warn(("[GOY JUGUETES] %s: el fotograma %d se sale de la hoja (%dx%d); se ignora."):format(entry.file, localIndex, entry.w, entry.h))
                else
                    FRAME_MAP[nextIndex] = {sheet = sheetIndex, offset = Vector2.new(x + 1, y + 1)}
                    nextIndex = nextIndex + 1
                end
            end
        end
        if nextIndex ~= VIDEO.TOTAL_FRAMES then
            warn(("[GOY JUGUETES] TOTAL_FRAMES=%d pero las hojas traen %d; uso %d."):format(VIDEO.TOTAL_FRAMES, nextIndex, nextIndex))
        end
        VIDEO.TOTAL_FRAMES = nextIndex
    end
    local TOTAL_FRAMES = VIDEO.TOTAL_FRAMES
    local DURATION = TOTAL_FRAMES / FPS
    local CROP_SIZE = Vector2.new(FRAME_W - 2, FRAME_H - 2) -- 1 px hacia dentro: sin bordes al filtrar
    if TOTAL_FRAMES < 1 then warn("[GOY JUGUETES] No hay fotogramas configurados."); return end

    local getAsset = getcustomasset or getsynasset
    if type(writefile) ~= "function" or type(getAsset) ~= "function" then
        warn("[GOY JUGUETES] Este ejecutor no ofrece writefile + getcustomasset; no se puede mostrar el video.")
        return
    end

    local function requestBytes(url)
        local ok, body = pcall(function() return game:HttpGet(url) end)
        if ok and type(body) == "string" and #body > 0 and not string.find(body, "^404: Not Found") then return body end
        local req = (syn and syn.request) or http_request or request or (http and http.request)
        if type(req) == "function" then
            local okReq, response = pcall(req, {Url = url, Method = "GET"})
            if okReq and type(response) == "table" and type(response.Body) == "string"
                and #response.Body > 0
                and (response.StatusCode == nil or response.StatusCode == 200 or response.Success == true) then
                return response.Body
            end
        end
        return nil
    end

    -- Caché local: si el archivo ya está guardado con el tamaño correcto, no se descarga otra vez.
    local function getLocalAsset(entry)
        local cache = CACHE_PREFIX .. entry.file
        if type(isfile) == "function" and type(readfile) == "function" then
            local okExists, exists = pcall(isfile, cache)
            if okExists and exists then
                local okRead, bytes = pcall(readfile, cache)
                if okRead and type(bytes) == "string" and #bytes == entry.size then
                    local okAsset, asset = pcall(getAsset, cache)
                    if okAsset and asset then return asset end
                end
            end
        end
        local lastError = entry.file .. ": descarga fallida"
        for attempt = 1, 3 do
            if not alive() then return nil, "cancelado" end
            local bytes = requestBytes(BASE_URL .. entry.file)
            if bytes and (#bytes == entry.size or (attempt == 3 and #bytes > 1000)) then
                local okWrite, writeErr = pcall(writefile, cache, bytes)
                if not okWrite then return nil, entry.file .. ": writefile: " .. tostring(writeErr) end
                local okAsset, asset = pcall(getAsset, cache)
                if okAsset and asset then return asset end
                return nil, entry.file .. ": getcustomasset falló"
            elseif bytes then
                lastError = ("%s: tamaño %d, esperado %d"):format(entry.file, #bytes, entry.size)
            end
            task.wait(0.3 * attempt)
        end
        return nil, lastError
    end

    -- Carga progresiva, UNA sola vez por ejecución: hoja 1 primero (para el primer fotograma),
    -- luego el audio y el resto. Un fallo no bloquea nada: solo se avisa.
    local audioAsset, audioFailed = nil, false
    local sheetAssets, sheetsDone = {}, 0
    task.spawn(function()
        local first, ferr = getLocalAsset(SHEETS[1])
        if first then sheetAssets[1] = first else warn("[GOY JUGUETES] " .. tostring(ferr)) end
        sheetsDone = 1
        local a, aerr = getLocalAsset(VIDEO.AUDIO)
        if a then audioAsset = a else audioFailed = true; warn("[GOY JUGUETES] Audio no disponible (el video seguirá sin música): " .. tostring(aerr)) end
        for index = 2, #SHEETS do
            if not alive() then return end
            local asset, err = getLocalAsset(SHEETS[index])
            if asset then sheetAssets[index] = asset else warn("[GOY JUGUETES] " .. tostring(err)) end
            sheetsDone = index
            task.wait()
        end
    end)

    ----------------------------------------------------------------
    -- Detectar el menú de juguetes del juego: el panel que contiene el
    -- contador "n/n" (ej. 0/100) junto con la cuadrícula de juguetes.
    ----------------------------------------------------------------
    local SKIP_NAMES = {
        Orion = true, RobloxGui = true, VideoMenuGui = true, CAG2 = true,
        ContextActionGui = true, floppadialogo = true, Chat = true,
        PerspectiveEffect = true, TouchGui = true,
    }
    local function isSkipped(screen)
        if SKIP_NAMES[screen.Name] or string.find(screen.Name, "^GOY") then return true end
        return false
    end
    local function isLimitLabel(d)
        return d:IsA("TextLabel") and string.match(d.Text or "", "^%s*%d+%s*/%s*%d+%s*$") ~= nil
    end
    local function hasToyGrid(node)
        local tiles, scroll = 0, false
        for _, d in ipairs(node:GetDescendants()) do
            if d:IsA("ScrollingFrame") then scroll = true end
            if d:IsA("ViewportFrame") or d:IsA("ImageButton") then tiles = tiles + 1 end
            if scroll and tiles >= 4 then return true end
            if tiles >= 8 then return true end
        end
        return false
    end
    local function findToyPanel()
        local pg = player:FindFirstChildOfClass("PlayerGui")
        if not pg then return nil end
        for _, screen in ipairs(pg:GetChildren()) do
            if screen:IsA("ScreenGui") and not isSkipped(screen) then
                for _, d in ipairs(screen:GetDescendants()) do
                    if isLimitLabel(d) then
                        local node = d.Parent
                        while node and node ~= screen do
                            if node:IsA("GuiObject") and hasToyGrid(node) then
                                -- Sube hasta 2 niveles si el contenedor sigue siendo menor que la pantalla.
                                local climbs = 0
                                local screenSize = screen.AbsoluteSize
                                while climbs < 2 do
                                    local p = node.Parent
                                    if p and p ~= screen and p:IsA("GuiObject")
                                        and p.AbsoluteSize.X <= screenSize.X * 0.95
                                        and p.AbsoluteSize.Y <= screenSize.Y * 0.98 then
                                        node = p
                                        climbs = climbs + 1
                                    else
                                        break
                                    end
                                end
                                return screen, node
                            end
                            node = node.Parent
                        end
                    end
                end
            end
        end
        return nil
    end

    ----------------------------------------------------------------
    -- Video + música sobre un menú ya detectado. Termina cuando el menú se destruye.
    ----------------------------------------------------------------
    local function runOn(screen, root)
        local oldLayer = root:FindFirstChild("GOY_ToyVideoBackground")
        if oldLayer then oldLayer:Destroy() end

        -- La capa va detrás de todo lo que ya existe en el menú.
        local minZ = 1
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("GuiObject") and d.ZIndex < minZ then minZ = d.ZIndex end
        end

        local layer = Instance.new("Frame")
        layer.Name = "GOY_ToyVideoBackground"
        layer.BackgroundTransparency = 1
        layer.BorderSizePixel = 0
        layer.ClipsDescendants = true
        layer.Position = UDim2.fromScale(0, 0)
        layer.Size = UDim2.fromScale(1, 1)
        layer.ZIndex = minZ - 1
        layer.Active = false
        layer.Selectable = false
        local rootCorner = root:FindFirstChildOfClass("UICorner")
        if rootCorner then
            local c = Instance.new("UICorner")
            c.CornerRadius = rootCorner.CornerRadius
            c.Parent = layer
        end
        layer.Parent = root

        -- Velo gris: baja el brillo del menú sin tocar botones ni juguetes.
        local overlay = Instance.new("Frame")
        overlay.Name = "GOY_ToyDim"
        overlay.BackgroundColor3 = GRAY_OVERLAY
        overlay.BackgroundTransparency = GRAY_OVERLAY_TRANSPARENCY
        overlay.BorderSizePixel = 0
        overlay.Size = UDim2.fromScale(1, 1)
        overlay.ZIndex = 5
        overlay.Active = false
        overlay.Selectable = false
        overlay.Parent = layer


        local function menuIsVisible()
            if not root.Parent or not root:IsDescendantOf(game) then return false end
            local node = root
            while node and node ~= screen do
                if node:IsA("GuiObject") and not node.Visible then return false end
                node = node.Parent
            end
            if node ~= screen or not screen.Enabled then return false end
            local ap, as, ss = root.AbsolutePosition, root.AbsoluteSize, screen.AbsoluteSize
            return as.X > 0 and as.Y > 0 and ap.X < ss.X and ap.Y < ss.Y
                and ap.X + as.X > 0 and ap.Y + as.Y > 0
        end

        -- Los fondos grandes del menú (paneles y cualquier imagen de fondo) tapan el video:
        -- se vuelven transparentes. Botones, juguetes y textos no se tocan.
        local function clearBackdrops()
            if not SEE_THROUGH then return end
            pcall(function()
                local rs = root.AbsoluteSize
                if rs.X <= 0 or rs.Y <= 0 then return end
                root.BackgroundTransparency = 1
                for _, d in ipairs(root:GetDescendants()) do
                    if d ~= layer and not d:IsDescendantOf(layer) and d:IsA("GuiObject") then
                        local isPanel = d:IsA("Frame") or d:IsA("ScrollingFrame")
                        local isImage = d:IsA("ImageLabel")
                        if isPanel or isImage then
                            local sz = d.AbsoluteSize
                            if sz.X >= rs.X * 0.6 and sz.Y >= rs.Y * 0.5 then
                                d.BackgroundTransparency = 1
                                if isImage then d.ImageTransparency = 1 end
                            end
                        end
                    end
                end
            end)
        end

        -- Hojas: una ImageLabel por hoja, creadas una sola vez y reutilizadas (solo cambia
        -- ImageRectOffset y cuál está visible). Nunca se crean/destruyen por fotograma.
        local sheetLabels = {}
        local currentSheet = nil
        local warmSheet = nil
        local pendingHide = {}
        local shownFrame = -1
        local sound = nil
        local soundEndedConn = nil

        -- Estado central del reproductor. "session" sube en cada apertura/cierre:
        -- cualquier tarea o evento de una sesión vieja se ignora (el cierre siempre gana).
        local state = "stopped"   -- "stopped" | "preparing" | "playing"
        local session = 0
        local renderConn = nil
        local lastPos, lastPosClock, playStartedClock, lastRestartClock = 0, 0, 0, 0
        local noAudioClock = 0
        local wasOpen = false
        local preloaded = false

        local showFrame -- se define más abajo

        local function makeSheetLabel(index, asset)
            local image = Instance.new("ImageLabel")
            image.Name = "GOY_ToySheet_" .. index
            image.BackgroundTransparency = 1
            image.BorderSizePixel = 0
            image.Size = UDim2.fromScale(1, 1)
            image.Image = asset
            image.ImageColor3 = VIDEO_TINT
            image.ScaleType = Enum.ScaleType.Crop
            image.ImageRectOffset = Vector2.new(MARGIN + 1, MARGIN + 1)
            image.ImageRectSize = CROP_SIZE
            image.ZIndex = 1
            image.Visible = false
            image.Active = false
            image.Selectable = false
            image.Parent = layer
            sheetLabels[index] = image
        end

        local function syncAssets()
            for index, asset in pairs(sheetAssets) do
                if not sheetLabels[index] then makeSheetLabel(index, asset) end
            end
            -- En cuanto existe la hoja 1, el fotograma 0 queda puesto (aunque el menú esté cerrado),
            -- así al abrir nunca se ve la capa vacía.
            if currentSheet == nil and sheetLabels[1] and showFrame then showFrame(0) end
            if audioAsset and not sound then
                -- Elimina cualquier reproductor viejo que hubiera quedado en la capa.
                for _, d in ipairs(layer:GetChildren()) do
                    if d:IsA("Sound") then pcall(function() d:Stop(); d:Destroy() end) end
                end
                local ok, created = pcall(function()
                    local s = Instance.new("Sound")
                    s.Name = "GOY_ToyMenuAudio"
                    s.SoundId = audioAsset
                    s.Volume = VOLUME
                    s.Looped = true    -- la canción suena COMPLETA y Roblox la repite sola al terminar (no se corta)
                    s.Parent = layer
                    return s
                end)
                if ok then sound = created end
            end
        end

        -- Muestra un fotograma. Si su hoja aún no cargó, se queda el último fotograma
        -- visible (nunca pantalla negra ni capa vacía).
        function showFrame(frameIndex)
            frameIndex = math.clamp(frameIndex, 0, TOTAL_FRAMES - 1)
            local info = FRAME_MAP[frameIndex]
            if not info then return false end
            local image = sheetLabels[info.sheet]
            if not image then return false end
            image.ImageRectOffset = info.offset
            image.ImageRectSize = CROP_SIZE
            if currentSheet ~= info.sheet then
                -- Cambio de hoja SIN parpadeo (doble búfer): la hoja nueva sube encima (Z=3) y la
                -- anterior se queda visible debajo unos instantes, por si la nueva tarda un frame en dibujarse.
                image.ZIndex = 3
                image.Visible = true
                pendingHide[info.sheet] = nil
                if currentSheet and sheetLabels[currentSheet] then
                    sheetLabels[currentSheet].ZIndex = 1
                    pendingHide[currentSheet] = os.clock() + 0.2
                end
                currentSheet = info.sheet
                -- Precalienta la SIGUIENTE hoja (la 1 después de la última, para el bucle): visible pero
                -- tapada (Z=2), así Roblox ya tiene su textura lista cuando le toque.
                local nextSheet = (info.sheet % #SHEETS) + 1
                local nextLabel = sheetLabels[nextSheet]
                if nextLabel and nextSheet ~= currentSheet then
                    nextLabel.ZIndex = 2
                    nextLabel.Visible = true
                    pendingHide[nextSheet] = nil
                end
                warmSheet = nextSheet
            end
            for index, hideAt in pairs(pendingHide) do
                if os.clock() >= hideAt and index ~= currentSheet and index ~= warmSheet then
                    local l = sheetLabels[index]
                    if l then l.Visible = false; l.ZIndex = 1 end
                    pendingHide[index] = nil
                end
            end
            shownFrame = frameIndex
            return true
        end

        local function audioReady()
            return sound ~= nil and sound.Parent ~= nil
        end

        local function stopRender()
            if renderConn then renderConn:Disconnect(); renderConn = nil end
        end

        -- VIDEO y MÚSICA van separados:
        --   * El video usa su propio reloj y se repite infinitamente (fotograma = tiempo % duración).
        --   * La música tiene Looped = true: suena entera y vuelve a empezar sola; el script nunca la corta.
        local function startRender(mySession)
            stopRender()
            playStartedClock = os.clock()
            renderConn = RunService.Heartbeat:Connect(function()
                if mySession ~= session or state ~= "playing" then stopRender(); return end
                local t = (os.clock() - playStartedClock) % DURATION
                local frame = math.floor(t * FPS + 1e-4) % TOTAL_FRAMES
                if RENDER_STEP > 1 then frame = frame - (frame % RENDER_STEP) end
                if frame ~= shownFrame then showFrame(frame) end
                -- Si el ejecutor pausó la música por su cuenta, la reanuda (sin reiniciarla).
                if audioReady() and os.clock() - lastRestartClock > 1 then
                    lastRestartClock = os.clock()
                    local okP, playing = pcall(function() return sound.IsPlaying end)
                    if okP and not playing then pcall(function() sound.Looped = true; sound:Resume() end) end
                end
            end)
        end

        local function stopPlayback()
            session = session + 1
            state = "stopped"
            stopRender()
            if sound then pcall(function() sound:Stop(); sound.TimePosition = 0 end) end
            lastPos, lastPosClock = 0, os.clock()
            -- Deja preparado el primer fotograma para la próxima apertura (sin destello del último).
            showFrame(0)
        end

        local function startPlayback()
            session = session + 1
            local mySession = session
            state = "preparing"
            stopRender()
            if sound then pcall(function() sound:Stop(); sound.TimePosition = 0 end) end
            showFrame(0)
            task.spawn(function()
                -- Espera breve (solo la primera vez, luego todo sale de caché) a que estén
                -- las hojas y el audio, para que el video no se congele a mitad del primer ciclo.
                local deadline = os.clock() + WAIT_FOR_ALL_SHEETS
                while mySession == session and alive() and os.clock() < deadline do
                    syncAssets()
                    if shownFrame ~= 0 then showFrame(0) end
                    local audioDone = audioReady() or audioFailed
                    if audioDone and sheetsDone >= #SHEETS then break end
                    task.wait(0.1)
                end
                if mySession ~= session or not alive() then return end
                syncAssets()
                -- Sube todas las texturas de las hojas antes del primer ciclo (evita el parpadeo inicial).
                if not preloaded then
                    preloaded = true
                    local list = {}
                    for _, l in pairs(sheetLabels) do list[#list + 1] = l end
                    pcall(function() game:GetService("ContentProvider"):PreloadAsync(list) end)
                    if mySession ~= session or not alive() then return end
                end
                showFrame(0)
                if audioReady() then
                    -- El audio local puede tardar un instante en estar listo.
                    local okLoaded, loaded = pcall(function() return sound.IsLoaded end)
                    if okLoaded and not loaded then
                        local t0 = os.clock()
                        while mySession == session and os.clock() - t0 < 2 do
                            local ok2, l2 = pcall(function() return sound.IsLoaded end)
                            if ok2 and l2 then break end
                            task.wait(0.05)
                        end
                        if mySession ~= session then return end
                    end
                    pcall(function()
                        sound.Looped = true
                        sound.TimePosition = 0
                        sound:Play()
                    end)
                end
                state = "playing"
                lastRestartClock = os.clock()
                showFrame(0)
                startRender(mySession)
            end)
        end

        -- ===== Destello fluorescente al tocar un botón del menú de juguetes =====
        -- Solo cambia el brillo/color de la capa del video; los botones funcionan igual que siempre.
        local FLASH_TIME = 0.45
        local neon = Instance.new("Frame")
        neon.Name = "GOY_ToyNeonFlash"
        neon.BorderSizePixel = 0
        neon.Size = UDim2.fromScale(1, 1)
        neon.BackgroundColor3 = Color3.new(1, 1, 1)
        neon.BackgroundTransparency = 1
        neon.ZIndex = 4
        neon.Active = false
        neon.Selectable = false
        neon.Parent = layer
        local neonGrad = Instance.new("UIGradient")
        neonGrad.Rotation = 35
        neonGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 230)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 255, 90)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 40, 220)),
        })
        neonGrad.Parent = neon
        local flashStart = -10
        local flashConn = nil
        local buttonConns = {}
        local function lerp(a, b, k) return a + (b - a) * k end
        local function applyGlow(k)
            local tint = Color3.new(lerp(VIDEO_TINT.R, 1, k), lerp(VIDEO_TINT.G, 1, k), lerp(VIDEO_TINT.B, 1, k))
            for _, l in pairs(sheetLabels) do l.ImageColor3 = tint end
            overlay.BackgroundTransparency = lerp(GRAY_OVERLAY_TRANSPARENCY, 1, k)
            neon.BackgroundTransparency = lerp(1, 0.5, k)
            neonGrad.Rotation = 35 + 90 * (1 - k)
        end
        local function flash()
            if state ~= "playing" then return end
            flashStart = os.clock()
            if flashConn then return end
            flashConn = RunService.Heartbeat:Connect(function()
                local e = os.clock() - flashStart
                if e >= FLASH_TIME or state ~= "playing" then
                    applyGlow(0)
                    flashConn:Disconnect(); flashConn = nil
                    return
                end
                local k = 1 - e / FLASH_TIME
                applyGlow(k * k)
            end)
        end
        local function hookButton(d)
            if buttonConns[d] or d:IsDescendantOf(layer) or not d:IsA("GuiButton") then return end
            local ok, c = pcall(function() return d.Activated:Connect(flash) end)
            if ok and c then buttonConns[d] = c end
        end
        for _, d in ipairs(root:GetDescendants()) do hookButton(d) end
        local addedConn = root.DescendantAdded:Connect(hookButton)

        while alive() and layer.Parent and root.Parent and screen.Parent do
            syncAssets()
            local open = menuIsVisible()
            if open and not wasOpen then
                clearBackdrops()
                startPlayback()
            elseif not open and wasOpen then
                stopPlayback()
            end
            wasOpen = open
            -- El render va en Heartbeat; este bucle solo vigila abrir/cerrar (barato).
            task.wait(open and 0.1 or 0.15)
        end

        session = session + 1
        state = "stopped"
        stopRender()
        if flashConn then flashConn:Disconnect(); flashConn = nil end
        pcall(function() addedConn:Disconnect() end)
        for _, c in pairs(buttonConns) do pcall(function() c:Disconnect() end) end
        if soundEndedConn then soundEndedConn:Disconnect() end
        if sound then pcall(function() sound:Stop(); sound:Destroy() end) end
        pcall(function() layer:Destroy() end)
    end

    -- Si el juego recrea su interfaz (reaparecer), vuelve a detectar el menú.
    local startedAt, warned = os.clock(), false
    while alive() do
        local screen, root = findToyPanel()
        if screen and root then
            warned = false
            local ok, err = pcall(runOn, screen, root)
            if not ok then warn("[GOY JUGUETES] " .. tostring(err)) end
        elseif not warned and os.clock() - startedAt > 30 then
            warned = true
            warn("[GOY JUGUETES] No encontré el menú de juguetes (el que tiene el contador 0/100). Ábrelo una vez y espera unos segundos.")
        end
        task.wait(2)
    end
end)
