CLOCK=0 TASKS={}
function os.clock() return CLOCK end
local function run(co,...) local ok,a=coroutine.resume(co,...) if not ok then error(a) end if coroutine.status(co)~="dead" then TASKS[#TASKS+1]={co=co,at=CLOCK+(a or 0)} end end
task={spawn=function(f,...) run(coroutine.create(f),...) end, wait=function(s) return coroutine.yield(s or 0) end, defer=function(f,...) run(coroutine.create(f),...) end}
function Signal() local s={c={}} function s:Connect(f) table.insert(self.c,f) return {Disconnect=function() end} end function s:Fire(...) for _,f in ipairs(self.c) do f(...) end end return s end
function STEP(dt) CLOCK=CLOCK+dt HB:Fire(dt) local due,keep={}, {} for _,t in ipairs(TASKS) do if t.at<=CLOCK then due[#due+1]=t else keep[#keep+1]=t end end TASKS=keep for _,t in ipairs(due) do run(t.co) end end
PROF=0 debug.profilebegin=function() PROF=PROF+1 end debug.profileend=function() PROF=PROF-1 end
OUT={} PRINTS={} function print(...) PRINTS[#PRINTS+1]=table.concat({...}," ") end function warn(...) PRINTS[#PRINTS+1]="W "..table.concat({...}," ") end
Enum=setmetatable({},{__index=function(t,k) return setmetatable({},{__index=function(_,v) return k.."."..v end}) end})
local function inst(cls,name) local o={ClassName=cls,Name=name,Parent=true} function o:IsA(c) return self.ClassName==c end function o:GetFullName() return "ReplicatedStorage."..self.Name end return o end
function typeof(v) if type(v)=="table" and v.ClassName then return "Instance" end return type(v) end
REMOTES={}
function newRemote(name) local r=inst("RemoteEvent",name) r.OnServerEvent=Signal() function r:FireClient(p,msg) OUT[p.Name]=OUT[p.Name] or {} table.insert(OUT[p.Name],msg) end REMOTES[#REMOTES+1]=r return r end
RSchildren={}
RS={FindFirstChild=function(_,n) return RSchildren[n] end}
setmetatable(RS,{__newindex=function(t,k,v) rawset(t,k,v) end})
local oldnew=nil
Instance={new=function(c) local r=newRemote("?") local mt={} return setmetatable({},{__index=r,__newindex=function(t,k,v) if k=="Parent" then RSchildren[r.Name]=t rawset(t,"_r",r) else r[k]=v end end}) end}
PLAYERS={}
function newPlayer(name,uid) local p={Name=name,UserId=uid,Parent=true} function p:GetRankInGroup() error("http") end return p end
PlayersS={PlayerAdded=Signal(),PlayerRemoving=Signal()}
function PlayersS:GetPlayers() return PLAYERS end
function PlayersS:GetPlayerByUserId(i) for _,p in ipairs(PLAYERS) do if p.UserId==i then return p end end end
HB=Signal()
RunS={Heartbeat=HB} function RunS:IsStudio() return STUDIO end
StatsS={DataReceiveKbps=1,DataSendKbps=2} function StatsS:GetTotalMemoryUsageMb() return 900 end function StatsS:GetMemoryUsageMbForTag() return 100 end
DSS={} function DSS:GetRequestBudgetForRequestType() return 60 end
game={CreatorType="CreatorType.User",CreatorId=1, DescendantAdded=Signal()}
function game:GetService(n) return ({Players=PlayersS,ReplicatedStorage=RS,RunService=RunS,Stats=StatsS,DataStoreService=DSS})[n] end
function game:GetDescendants() return GAME_REMOTES end
_G=_G
