local function Signal() local s={c={}} function s:Connect(f) local con={f=f,on=true} table.insert(self.c,con) function con:Disconnect() self.on=false end return con end function s:Once(f) local c c=self:Connect(function(...) c:Disconnect() f(...) end) return c end function s:Fire(...) for _,c in ipairs(self.c) do if c.on then c.f(...) end end end function s:count() local n=0 for _,c in ipairs(self.c) do if c.on then n=n+1 end end return n end return s end
TASKS={} CLOCK=1000 os.clock=function() return CLOCK end
local function run(co,...) local ok,e=coroutine.resume(co,...) if not ok then error(debug.traceback(co,e)) end end
task={spawn=function(f,...) run(coroutine.create(f),...) end,
 wait=function(t) table.insert(TASKS,{co=coroutine.running(),at=CLOCK+(t or 0.016)}) coroutine.yield() return t end,
 defer=function(f,...) local a={...} table.insert(TASKS,{fn=function() f(table.unpack(a)) end,at=CLOCK}) end,
 delay=function(t,f,...) local a={...} table.insert(TASKS,{fn=function() f(table.unpack(a)) end,at=CLOCK+t}) end}
function STEP(dt) CLOCK=CLOCK+dt RENDER:Fire(dt) HB:Fire(dt) local due,keep={}, {} for _,t in ipairs(TASKS) do if t.at<=CLOCK then due[#due+1]=t else keep[#keep+1]=t end end TASKS=keep for _,t in ipairs(due) do if t.fn then t.fn() else run(t.co) end end end
math.clamp=function(x,a,b) return math.max(a,math.min(b,x)) end
local SIG={FocusLost=1,Changed=1,AttributeChanged=1,ChildAdded=1,ChildRemoved=1,CharacterAdded=1,Activated=1,InputBegan=1,InputChanged=1,InputEnded=1,DescendantAdded=1,DescendantRemoving=1,OnClientEvent=1,Event=1,AncestryChanged=1,Equipped=1,Unequipped=1,Died=1,MessageOut=1,RenderStepped=1,Heartbeat=1,MouseButton1Click=1,OnTeleport=1}
local I={}
I.__index=function(self,k)
  if I[k] then return I[k] end
  local p=rawget(self,"_p")
  if p[k]~=nil then return p[k] end
  if SIG[k] then p[k]=Signal() return p[k] end
  for _,c in ipairs(rawget(self,"_ch")) do if c.Name==k then return c end end
  if PROPERR then error(k.." is not a valid member") end
  return nil
end
local function fireDesc(v,inst,ev) local a=v while a do a[ev]:Fire(inst) a=rawget(a,"_p").Parent end end
I.__newindex=function(self,k,v) local p=rawget(self,"_p")
 if k=="Parent" then
  local old=p.Parent
  if old then local all={self} for _,d in ipairs(self:GetDescendants()) do all[#all+1]=d end for _,d in ipairs(all) do fireDesc(old,d,"DescendantRemoving") end local ch=rawget(old,"_ch") for i,c in ipairs(ch) do if c==self then table.remove(ch,i) break end end end
  p.Parent=v
  if v then table.insert(rawget(v,"_ch"),self) v.ChildAdded:Fire(self) local all={self} for _,d in ipairs(self:GetDescendants()) do all[#all+1]=d end for _,d in ipairs(all) do fireDesc(v,d,"DescendantAdded") end end
  self.AncestryChanged:Fire(self,v)
 else p[k]=v if rawget(p,"chg_"..k) then p["chg_"..k]:Fire() end self.Changed:Fire(k) end end
function NEW(cls,name,parent) local o=setmetatable({_p={ClassName=cls,Name=name or cls},_ch={}},I) if parent then o.Parent=parent end return o end
local ISA={ValueBase={IntValue=1,StringValue=1,NumberValue=1,BoolValue=1},GuiObject={Frame=1,TextButton=1,ImageButton=1,TextLabel=1,TextBox=1,ScrollingFrame=1},LayerCollector={ScreenGui=1},GuiButton={TextButton=1,ImageButton=1}}
function I:IsA(c) local cn=self.ClassName if cn==c then return true end return ISA[c] and ISA[c][cn]~=nil or false end
function I:GetAttribute(a) local at=rawget(self,"_p").attrs return at and at[a] end
function I:GetAttributes() return rawget(self,"_p").attrs or {} end
function I:SetAttribute(a,v) local p=rawget(self,"_p") p.attrs=p.attrs or {} p.attrs[a]=v self.AttributeChanged:Fire(a) end
function I:FindFirstChildOfClass(c) for _,x in ipairs(rawget(self,"_ch")) do if x.ClassName==c then return x end end end
function I:GetDescendants() local t={} local function r(n) for _,c in ipairs(rawget(n,"_ch")) do t[#t+1]=c r(c) end end r(self) return t end
function I:GetChildren() local t={} for i,c in ipairs(rawget(self,"_ch")) do t[i]=c end return t end
function I:FindFirstChild(n) for _,c in ipairs(rawget(self,"_ch")) do if c.Name==n then return c end end end
function I:GetFullName() local p={} local n=self while n and n.ClassName~="DataModel" do table.insert(p,1,n.Name) n=n.Parent end return table.concat(p,".") end
function I:FindFirstAncestorOfClass(c) local p=self.Parent while p do if p.ClassName==c then return p end p=p.Parent end end
function I:IsDescendantOf(a) local p=self.Parent while p do if p==a then return true end p=p.Parent end return false end
function I:Destroy() self.Parent=nil end
function I:GetPropertyChangedSignal(k) local p=rawget(self,"_p") p["chg_"..k]=p["chg_"..k] or Signal() return p["chg_"..k] end
function I:WaitForChild(n) return self:FindFirstChild(n) end
Instance={new=function(c) return NEW(c) end}
UDim={new=function(a,b) return {a,b} end}
UDim2={new=function(a,b,c,d) return {X={Scale=a,Offset=b},Y={Scale=c,Offset=d}} end, fromOffset=function(a,b) return {X={Scale=0,Offset=a},Y={Scale=0,Offset=b}} end, fromScale=function(a,b) return {X={Scale=a,Offset=0},Y={Scale=b,Offset=0}} end}
Vector2={new=function(x,y) return {X=x,Y=y} end}
Color3={fromRGB=function(r,g,b) return {r,g,b} end, new=function(r,g,b) return {r,g,b} end, fromHex=function(h) return {h} end}
ColorSequence={new=function(a,b) return {a,b} end}
Enum=setmetatable({},{__index=function(t,k) return setmetatable({},{__index=function(_,v) return k.."."..v end}) end})
game=NEW("DataModel","game") game.PlaceId=123
RS=NEW("ReplicatedStorage","ReplicatedStorage",game) workspace=NEW("Workspace","Workspace",game)
workspace.CurrentCamera=NEW("Camera","Camera") workspace.CurrentCamera.ViewportSize=Vector2.new(844,390)
function workspace:GetRealPhysicsFPS() return 60 end
PlayersS=NEW("Players","Players",game) CoreGui=NEW("CoreGui","CoreGui",game) UIS=NEW("UserInputService","UIS",game) UIS.TouchEnabled=true
RunS=NEW("RunService","RunService",game) RENDER=RunS.RenderStepped HB=RunS.Heartbeat
StatsS=NEW("Stats","Stats",game) function StatsS:GetTotalMemoryUsageMb() return 812.4 end StatsS.DataReceiveKbps=12.5 StatsS.DataSendKbps=3.1
LogS=NEW("LogService","LogService",game) CS=NEW("CollectionService","CollectionService",game) function CS:GetTags() return {} end
ME=NEW("Player","Goy671079",PlayersS) ME.UserId=8812345 function ME:GetNetworkPing() return 0.065 end
PG=NEW("PlayerGui","PlayerGui",ME) BP=NEW("Backpack","Backpack",ME)
LS=NEW("Folder","leaderstats",ME) COINS=NEW("IntValue","Coins",LS) COINS.Value=5
myChar=NEW("Model","Goy671079",workspace) HUM=NEW("Humanoid","Humanoid",myChar)
ME.Character=myChar
function PlayersS:GetPlayerFromCharacter(m) if m==myChar then return ME end end
PlayersS.LocalPlayer=ME
local svcs={Players=PlayersS,ReplicatedStorage=RS,Workspace=workspace,CoreGui=CoreGui,UserInputService=UIS,RunService=RunS,Stats=StatsS,LogService=LogS,CollectionService=CS}
function game:GetService(n) local s=svcs[n] if not s then error("no svc "..n) end return s end
function typeof(v) if type(v)=="table" and getmetatable(v)==I then return "Instance" end return type(v) end
GE=NEW("Folder","GrabEvents",RS) R1=NEW("RemoteEvent","CreateGrabLine",GE) R2=NEW("UnreliableRemoteEvent","Look",RS)
RF=NEW("RemoteFunction","GetData",RS) BE=NEW("BindableEvent","LocalSignal",RS) BF=NEW("BindableFunction","LocalFunc",RS)
SG=NEW("ScreenGui","Shop",PG) B1=NEW("TextButton","BuyBtn",SG) B1.Text="Comprar" B1.Visible=true SG.Enabled=true
B2=NEW("ImageButton","Hidden",SG) B2.Visible=false
CLIP=nil function setclipboard(t) CLIP=t end
FILES={} function writefile(p,t) FILES[p]=t end function makefolder() end function isfolder() return false end
function identifyexecutor() return "Delta","2.6" end
function getgenv() return _G end
function GUI() return CoreGui:FindFirstChild("GOY_Diagnostics") end
function find(root,pred) for _,d in ipairs(root:GetDescendants()) do if pred(d) then return d end end end
function btn(text) return find(GUI(),function(d) return d.ClassName=="TextButton" and d.Text==text end) end
function rowsOf(tab) local out={} local page for _,d in ipairs(GUI():GetDescendants()) do if d.ClassName=="ScrollingFrame" and d.Visible~=false and d.Parent and d.Parent.Visible==true and d.Parent.Parent and d.Parent.Parent.Name~="Panel" and d.AutomaticCanvasSize=="AutomaticSize.Y" and d.ScrollBarImageColor3 and d.ScrollBarThickness==5 and d.Parent.Parent.ClassName=="Frame" then page=d end end
 if not page then return out end
 for _,r in ipairs(page:GetChildren()) do if r.ClassName=="TextButton" and r.Visible then local ls={} for _,c in ipairs(r:GetChildren()) do if c.ClassName=="TextLabel" then ls[#ls+1]=c.Text end end out[#out+1]=table.concat(ls," || ") end end return out end
HttpS=NEW("HttpService","HttpService",game)
function HttpS:JSONEncode(t) local p={} for k,v in pairs(t) do p[#p+1]=string.format("[%q]=%s",k,type(v)=="string" and string.format("%q",v) or tostring(v)) end return "{"..table.concat(p,",").."}" end
function HttpS:JSONDecode(s) return load("return "..s)() end
svcs_extra={HttpService=HttpS}
local og=game.GetService function game:GetService(n) if svcs_extra[n] then return svcs_extra[n] end return og(self,n) end
function readfile(p) return FILES[p] end function isfile(p) return FILES[p]~=nil end
