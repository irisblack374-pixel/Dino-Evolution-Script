-- Ride a Pet Hub - Compact Edition (Kavo UI / Keyless)
-- Games: Ride a Pet / Pet Riding / +1 Dino / Adopt Pets
-- Platform: Delta Executor Mobile - No Key / Open Source

local Players=game:GetService("Players")local Workspace=game:GetService("Workspace")local TweenService=game:GetService("TweenService")local RunService=game:GetService("RunService")local ReplicatedStorage=game:GetService("ReplicatedStorage")local CoreGui=game:GetService("CoreGui")local UserInputService=game:GetService("UserInputService")local Lighting=game:GetService("Lighting")
local LocalPlayer=Players.LocalPlayer
local Camera=Workspace.CurrentCamera

local Config={AutoFarmEggs=false,AutoHatch=false,AutoRide=false,AutoSell=false,AutoCollect=false,EggRarity="All",TweenSpeed=135,WalkSpeed=16,JumpPower=50,InfJump=false,FlyEnabled=false,FlySpeed=50,Noclip=false,AntiAFK=true,EggESP=false,PlayerESP=false,BaseCFrame=CFrame.new(0,5,0),ShopCFrame=CFrame.new(0,5,0)}
local Rarities={"All","Common","Rare","Epic","Legendary","Mythic","Godly"}
local RarityColor={Common=Color3.fromRGB(180,180,180),Rare=Color3.fromRGB(0,150,255),Epic=Color3.fromRGB(150,0,255),Legendary=Color3.fromRGB(255,200,0),Mythic=Color3.fromRGB(255,0,100),Godly=Color3.fromRGB(255,50,50)}
local RarityPriority={Godly=5,Mythic=4,Legendary=3,Epic=2,Rare=1,Common=0}

local function getRoot()local c=LocalPlayer.Character if not c then return nil end return c:FindFirstChild("HumanoidRootPart")or c:FindFirstChild("Torso")or c:FindFirstChild("UpperTorso")end
local function getHum()local c=LocalPlayer.Character if not c then return nil end return c:FindFirstChildOfClass("Humanoid")end
local function isAlive()local h=getHum()return h~=nil and h.Health>0 end
local function waitForChar()local t=os.clock()while(os.clock()-t)<30 do if getRoot()and getHum()and getHum().Health>0 then return true end task.wait(0.2)end return false end

local function detectLocs()pcall(function()local s=Workspace:FindFirstChildWhichIsA("SpawnLocation")if s then Config.BaseCFrame=s.CFrame+Vector3.new(0,5,0)end for _,o in ipairs(Workspace:GetChildren())do local n=string.lower(o.Name)if n:match("spawn")or n:match("base")or n:match("home")then local p=o:IsA("BasePart")and o or o:FindFirstChildWhichIsA("BasePart")if p then Config.BaseCFrame=p.CFrame+Vector3.new(0,5,0)break end end end for _,o in ipairs(Workspace:GetDescendants())do local n=string.lower(o.Name)if n:match("shop")or n:match("sell")or n:match("market")then local p=o:IsA("BasePart")and o or o:FindFirstChildWhichIsA("BasePart")if p then Config.ShopCFrame=p.CFrame+Vector3.new(0,5,0)break end end end)end

local function findEggs()local list={}pcall(function()for _,o in ipairs(Workspace:GetDescendants())do local m=false local r="Common"if o:IsA("BasePart")then local n=string.lower(o.Name)if n:find("egg")then m=true elseif o.Parent and string.lower(o.Parent.Name):find("egg")then m=true end elseif o:IsA("Model")and string.lower(o.Name):find("egg")then m=true end if m then pcall(function()if o:GetAttribute("Rarity")then r=o:GetAttribute("Rarity")elseif o.Parent and o.Parent:GetAttribute("Rarity")then r=o.Parent:GetAttribute("Rarity")else local rc=o:FindFirstChild("Rarity")or(o.Parent and o.Parent:FindFirstChild("Rarity"))if rc and rc.Value then r=tostring(rc.Value)else for _,rn in ipairs({"Godly","Mythic","Legendary","Epic","Rare"})do if string.lower(o.Name):find(string.lower(rn))then r=rn break end end end end end)local p=o:IsA("BasePart")and o or o:FindFirstChildWhichIsA("BasePart")or o.PrimaryPart if p then table.insert(list,{Part=p,CFrame=p.CFrame,Name=o.Name,Rarity=r})end end end end)return list end

local function findCol()local l={}pcall(function()for _,o in ipairs(Workspace:GetDescendants())do if o:IsA("BasePart")then local n=string.lower(o.Name)if n:match("coin")or n:match("star")or n:match("candy")or n:match("gift")or n:match("treat")or n:match("bone")then table.insert(l,o)end end end end)return l end

local function tweenTo(cf)if not isAlive()then return false end local r=getRoot()if not r or not cf then return false end local d=(r.CFrame.Position-cf.Position).Magnitude if d<1 then return true end local sp=math.clamp(Config.TweenSpeed,50,500)local du=math.clamp(d/sp,0.15,8)local info=TweenInfo.new(du,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,0,0,0)local done=false pcall(function()local tw=TweenService:Create(r,info,{CFrame=cf})tw:Play()local c c=tw.Completed:Connect(function()done=true if c then c:Disconnect()end end)local t0=os.clock()while not done and isAlive()and(os.clock()-t0)<(du+1)do task.wait(0.05)end if not done then pcall(function()tw:Cancel()end)end end)return done end

local function touchObj(o)if not o or not isAlive()then return end local r=getRoot()if not r then return end local cf=(typeof(o)=="table")and o.CFrame or o.CFrame local ep=(typeof(o)=="table")and o.Part or o tweenTo(cf+Vector3.new(0,3,0))pcall(function()firetouchinterest(r,ep,0)firetouchinterest(r,ep,1)r.CFrame=ep.CFrame+Vector3.new(0,2,0)task.wait(0.05)firetouchinterest(r,ep,0)firetouchinterest(r,ep,1)end)end

local RCache={}local function findRemote(p,par)par=par or ReplicatedStorage if RCache[p]then return RCache[p]end local f=nil pcall(function()for _,o in ipairs(par:GetDescendants())do if(o:IsA("RemoteEvent")or o:IsA("RemoteFunction"))and string.lower(o.Name):find(string.lower(p))then f=o break end end end)RCache[p]=f return f end
local Remotes={}local function initRemotes()pcall(function()Remotes.Hatch=findRemote("Hatch")or findRemote("Open")Remotes.Ride=findRemote("Ride")or findRemote("Equip")or findRemote("Mount")Remotes.Collect=findRemote("Collect")or findRemote("Grab")Remotes.Sell=findRemote("Sell")or findRemote("Shop")end)end
local function fireR(r,...)if not r then return end if not r:IsA("RemoteEvent")and not r:IsA("RemoteFunction")then return end pcall(function()r:FireServer(...)end)end

local function getPets()local p={}pcall(function()local locs={LocalPlayer:FindFirstChild("Pets"),LocalPlayer:FindFirstChild("Inventory"),LocalPlayer:FindFirstChild("Backpack"),ReplicatedStorage:FindFirstChild("Pets")}for _,l in ipairs(locs)do if l then for _,x in ipairs(l:GetChildren())do table.insert(p,x)end end end end)return p end

local function shouldFarm(e)if Config.EggRarity=="All"then return true end return e.Rarity==Config.EggRarity end

local function startFarm()task.spawn(function()while Config.AutoFarmEggs do pcall(function()if isAlive()then local eggs=findEggs()local r=getRoot()if r then local n,nd=nil,math.huge for _,e in ipairs(eggs)do if shouldFarm(e)then local d=(r.Position-e.CFrame.Position).Magnitude if d<nd then nd=d n=e end end end if n then touchObj(n)end end end)task.wait(0.3)end end)end
local function startCollect()task.spawn(function()while Config.AutoCollect do pcall(function()if isAlive()then local items=findCol()local r=getRoot()if r then local n,nd=nil,math.huge for _,c in ipairs(items)do local d=(r.Position-c.Position).Magnitude if d<nd then nd=d n=c end end if n then touchObj(n)if Remotes.Collect then fireR(Remotes.Collect,n)end end end end)task.wait(0.2)end end)end
local function startHatch()task.spawn(function()while Config.AutoHatch do pcall(function()if Remotes.Hatch then fireR(Remotes.Hatch)fireR(Remotes.Hatch,"Best")fireR(Remotes.Hatch,Config.EggRarity)end end)task.wait(0.5)end end)end
local function startRide()task.spawn(function()while Config.AutoRide do pcall(function()local pets=getPets()if #pets>0 and Remotes.Ride then fireR(Remotes.Ride,pets[1])end end)task.wait(2)end end)end
local function startSell()task.spawn(function()while Config.AutoSell do pcall(function()if Remotes.Sell then fireR(Remotes.Sell)fireR(Remotes.Sell,"All")end end)task.wait(1.5)end end)end

local function applyMove()task.spawn(function()while true do pcall(function()local h=getHum()if h then h.WalkSpeed=Config.WalkSpeed h.JumpPower=Config.JumpPower end end)task.wait(0.5)end end)end

local ijc local function toggleIJ(s)if ijc then ijc:Disconnect()ijc=nil end if s then ijc=UserInputService.JumpRequest:Connect(function()pcall(function()local h=getHum()if h then h:ChangeState(Enum.HumanoidStateType.Jumping)end end)end)end end

local nc local function toggleNoclip(s)if nc then nc:Disconnect()nc=nil end if s then nc=RunService.Stepped:Connect(function()pcall(function()local c=LocalPlayer.Character if c then for _,p in ipairs(c:GetDescendants())do if p:IsA("BasePart")and p.CanCollide then p.CanCollide=false end end end end)end)else pcall(function()local c=LocalPlayer.Character if c then for _,p in ipairs(c:GetDescendants())do if p:IsA("BasePart")then p.CanCollide=true end end end end)end end

local fBP,fBG local function getFlyIn()local d=Vector3.new(0,0,0)if UserInputService:IsKeyDown(Enum.KeyCode.W)then d=d+Camera.CFrame.LookVector end if UserInputService:IsKeyDown(Enum.KeyCode.S)then d=d-Camera.CFrame.LookVector end if UserInputService:IsKeyDown(Enum.KeyCode.A)then d=d-Camera.CFrame.RightVector end if UserInputService:IsKeyDown(Enum.KeyCode.D)then d=d+Camera.CFrame.RightVector end if UserInputService:IsKeyDown(Enum.KeyCode.Space)then d=d+Vector3.new(0,1,0)end if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)then d=d-Vector3.new(0,1,0)end return d end
local function toggleFly(s)if fBP then fBP:Destroy()fBP=nil end if fBG then fBG:Destroy()fBG=nil end if s then task.spawn(function()while Config.FlyEnabled do pcall(function()local r=getRoot()if r and isAlive()then if not fBP then fBP=Instance.new("BodyPosition")fBP.MaxForce=Vector3.new(1e5,1e5,1e5)fBP.Position=r.Position fBP.Parent=r end if not fBG then fBG=Instance.new("BodyGyro")fBG.MaxTorque=Vector3.new(1e5,1e5,1e5)fBG.CFrame=r.CFrame fBG.Parent=r end local d=getFlyIn()if d.Magnitude>0 then fBP.Position=r.Position+(d.Unit*Config.FlySpeed)else fBP.Position=r.Position end fBG.CFrame=Camera.CFrame end end)task.wait(0.03)end if fBP then fBP:Destroy()fBP=nil end if fBG then fBG:Destroy()fBG=nil end end)end end

local aac local function toggleAFK(s)if aac then aac:Disconnect()aac=nil end if s then aac=LocalPlayer.Idled:Connect(function()pcall(function()local VU=game:GetService("VirtualUser")VU:CaptureController()VU:ClickButton2(Vector2.new())end)end)end end

local eggHL={}local function clearEggHL()for i=#eggHL,1,-1 do pcall(function()eggHL[i]:Destroy()end)table.remove(eggHL,i)end end
local function updEggHL()if not Config.EggESP then return end clearEggHL()pcall(function()local eggs=findEggs()for _,e in ipairs(eggs)do if e.Part and e.Part.Parent then local h=Instance.new("Highlight")h.FillColor=RarityColor[e.Rarity]or Color3.fromRGB(255,255,0)h.OutlineColor=Color3.fromRGB(255,255,255)h.FillTransparency=0.5 h.Adornee=e.Part h.Parent=CoreGui table.insert(eggHL,h)local b=Instance.new("BillboardGui")b.Size=UDim2.new(0,100,0,30)b.Adornee=e.Part b.AlwaysOnTop=true b.Parent=CoreGui table.insert(eggHL,b)local l=Instance.new("TextLabel")l.Size=UDim2.new(1,0,1,0)l.BackgroundTransparency=1 l.Text=e.Rarity l.TextColor3=RarityColor[e.Rarity]or Color3.fromRGB(255,255,255)l.TextScaled=true l.Font=Enum.Font.GothamBold l.Parent=b table.insert(eggHL,l)end end end)end
task.spawn(function()while true do if Config.EggESP then pcall(updEggHL)end task.wait(3)end end)

local pHl={}local function clearPHL()for i=#pHl,1,-1 do pcall(function()pHl[i]:Destroy()end)table.remove(pHl,i)end end
local function updPHL()if not Config.PlayerESP then return end clearPHL()pcall(function()for _,p in ipairs(Players:GetPlayers())do if p~=LocalPlayer and p.Character then local h=Instance.new("Highlight")h.FillColor=Color3.fromRGB(0,200,100)h.OutlineColor=Color3.fromRGB(255,255,255)h.FillTransparency=0.5 h.Adornee=p.Character h.Parent=CoreGui table.insert(pHl,h)local hd=p.Character:FindFirstChild("Head")if hd then local b=Instance.new("BillboardGui")b.Size=UDim2.new(0,120,0,30)b.Adornee=hd b.AlwaysOnTop=true b.Parent=CoreGui table.insert(pHl,b)local l=Instance.new("TextLabel")l.Size=UDim2.new(1,0,1,0)l.BackgroundTransparency=1 l.Text=p.Name l.TextColor3=Color3.fromRGB(255,255,255)l.TextScaled=true l.Font=Enum.Font.GothamBold l.Parent=b table.insert(pHl,l)end end end end)end
task.spawn(function()while true do if Config.PlayerESP then pcall(updPHL)end task.wait(5)end end)

local Library=nil local ok,lib=pcall(function()return loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-library/main/source.lua"))()end)
if ok and lib then Library=lib else warn("[Hub] Failed to load Kavo UI")return end

local Window=Library.CreateLib("Ride a Pet Hub - Pro","DarkTheme")
local MainTab=Window:NewTab("Main")MainTab:AddSection("Auto Farm")
MainTab:AddToggle({Name="Auto Farm Eggs",Default=false,Callback=function(v)Config.AutoFarmEggs=v if v then startFarm()end end})
MainTab:AddToggle({Name="Auto Collect Coins",Default=false,Callback=function(v)Config.AutoCollect=v if v then startCollect()end end})
MainTab:AddToggle({Name="Auto Hatch Eggs",Default=false,Callback=function(v)Config.AutoHatch=v if v then startHatch()end end})
MainTab:AddToggle({Name="Auto Ride Best Pet",Default=false,Callback=function(v)Config.AutoRide=v if v then startRide()end end})
MainTab:AddToggle({Name="Auto Sell",Default=false,Callback=function(v)Config.AutoSell=v if v then startSell()end end})
MainTab:AddSection("Rarity Filter")
MainTab:AddDropdown({Name="Target Egg Rarity",Options=Rarities,Default="All",Callback=function(v)Config.EggRarity=v end})
MainTab:AddSection("Speed")
MainTab:AddSlider({Name="Tween Speed",Min=50,Max=300,Default=135,Color=Color3.fromRGB(255,255,255),Increment=5,Callback=function(v)Config.TweenSpeed=v end})

local PT=Window:NewTab("Player")PT:AddSection("Movement")
PT:AddSlider({Name="Walk Speed",Min=16,Max=200,Default=16,Color=Color3.fromRGB(255,255,255),Increment=1,Callback=function(v)Config.WalkSpeed=v end})
PT:AddSlider({Name="Jump Power",Min=50,Max=300,Default=50,Color=Color3.fromRGB(255,255,255),Increment=5,Callback=function(v)Config.JumpPower=v end})
PT:AddToggle({Name="Infinite Jump",Default=false,Callback=function(v)Config.InfJump=v toggleIJ(v)end})
PT:AddToggle({Name="Noclip",Default=false,Callback=function(v)Config.Noclip=v toggleNoclip(v)end})
PT:AddSection("Fly")
PT:AddToggle({Name="Fly Mode (WASD+Space/Shift)",Default=false,Callback=function(v)Config.FlyEnabled=v toggleFly(v)end})
PT:AddSlider({Name="Fly Speed",Min=10,Max=200,Default=50,Color=Color3.fromRGB(255,255,255),Increment=5,Callback=function(v)Config.FlySpeed=v end})
PT:AddSection("Utility")
PT:AddToggle({Name="Anti-AFK",Default=true,Callback=function(v)Config.AntiAFK=v toggleAFK(v)end})

local VT=Window:NewTab("Visuals")VT:AddSection("ESP")
VT:AddToggle({Name="Egg ESP (by Rarity)",Default=false,Callback=function(v)Config.EggESP=v if not v then clearEggHL()end end})
VT:AddToggle({Name="Player ESP",Default=false,Callback=function(v)Config.PlayerESP=v if not v then clearPHL()end end})
VT:AddSection("Light")
VT:AddToggle({Name="Fullbright",Default=false,Callback=function(v)pcall(function()if v then Lighting.Brightness=2 Lighting.ClockTime=14 Lighting.FogEnd=1e6 Lighting.GlobalShadows=false else Lighting.Brightness=1 Lighting.ClockTime=12 Lighting.GlobalShadows=true end end)end})

local TT=Window:NewTab("Teleports")TT:AddSection("Quick Travel")
TT:AddButton({Name="Teleport to Spawn/Base",Callback=function()detectLocs()task.spawn(function()tweenTo(Config.BaseCFrame)end)end})
TT:AddButton({Name="Instant TP to Base",Callback=function()detectLocs()local r=getRoot()if r then pcall(function()r.CFrame=Config.BaseCFrame end)end end})
TT:AddButton({Name="Teleport to Nearest Egg",Callback=function()task.spawn(function()local e=findEggs()if #e==0 then return end local r=getRoot()if not r then return end local n,d=nil,math.huge for _,x in ipairs(e)do local dd=(r.Position-x.CFrame.Position).Magnitude if dd<d then d=dd n=x end end if n then tweenTo(n.CFrame+Vector3.new(0,4,0))end end)end})
TT:AddButton({Name="Teleport to Rarest Egg",Callback=function()task.spawn(function()local e=findEggs()if #e==0 then return end local b=nil for _,x in ipairs(e)do if not b or(RarityPriority[x.Rarity]or 0)>(RarityPriority[b.Rarity]or 0)then b=x end end if b then tweenTo(b.CFrame+Vector3.new(0,4,0))end end)end})
TT:AddButton({Name="Teleport to Shop",Callback=function()detectLocs()task.spawn(function()tweenTo(Config.ShopCFrame)end)end})
TT:AddButton({Name="Save Current as Base",Callback=function()local r=getRoot()if r then Config.BaseCFrame=r.CFrame end end})
TT:AddButton({Name="Save Current as Shop",Callback=function()local r=getRoot()if r then Config.ShopCFrame=r.CFrame end end})
TT:AddButton({Name="TP to Random Player",Callback=function()task.spawn(function()local o={}for _,p in ipairs(Players:GetPlayers())do if p~=LocalPlayer and p.Character then table.insert(o,p)end end if #o>0 then local t=o[math.random(#o)]local r=t.Character:FindFirstChild("HumanoidRootPart")if r then tweenTo(r.CFrame+Vector3.new(0,3,0))end end end)end})

local DT=Window:NewTab("Debug")DT:AddSection("Scanners")
DT:AddButton({Name="List All Remotes (Output)",Callback=function()print("=== ReplicatedStorage Remotes ===")for _,o in ipairs(ReplicatedStorage:GetDescendants())do if o:IsA("RemoteEvent")or o:IsA("RemoteFunction")then print(o:GetFullName(),"(",o.ClassName,")")end end print("=== Workspace Remotes ===")for _,o in ipairs(Workspace:GetDescendants())do if o:IsA("RemoteEvent")or o:IsA("RemoteFunction")then print(o:GetFullName(),"(",o.ClassName,")")end end end})
DT:AddButton({Name="List Owned Pets",Callback=function()local p=getPets()print("=== You own "..#p.." pets ===")for i,x in ipairs(p)do print(i,x.Name,x.ClassName)end end})
DT:AddButton({Name="List Eggs Found",Callback=function()local e=findEggs()print("=== Found "..#e.." eggs ===")for i,x in ipairs(e)do print(i,x.Name,"Rarity:",x.Rarity)end end})
DT:AddSection("Maintenance")
DT:AddButton({Name="Re-init Remotes & Locations",Callback=function()detectLocs()RCache={}initRemotes()print("[Hub] Re-init complete.")end})
DT:AddButton({Name="Destroy UI",Callback=function()pcall(function()if CoreGui:FindFirstChild("KavoUI")then CoreGui.KavoUI:Destroy()end end)end})

local function safeInit()local r=waitForChar()if not r then warn("[Hub] Character not ready after 30s.")end pcall(detectLocs)pcall(initRemotes)pcall(applyMove)pcall(function()toggleAFK(Config.AntiAFK)end)print("[Ride a Pet Hub Pro] Loaded - Keyless / Open Source")end
LocalPlayer.CharacterAdded:Connect(function()task.spawn(function()task.wait(0.5)pcall(function()waitForChar()detectLocs()initRemotes()end)end)end)
task.spawn(safeInit)
