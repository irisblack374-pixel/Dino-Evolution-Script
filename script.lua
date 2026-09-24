--[[
    Ride a Pet Hub - Pro Edition (Kavo UI)
    Game: Ride a Pet
    Platform: Delta Executor (Mobile) - No Key / Open Source
    Features:
      • Auto Farm / Collect / Hatch / Ride / Sell
      • Egg ESP (rare highlight) + Player ESP
      • WalkSpeed / JumpPower / Infinite Jump
      • Fly Mode + Noclip
      • Anti-AFK
      • Teleports (Base/Egg/Shop/Save)
      • Pet Stats Display
]]

-- ============================================================
-- 1) Services & Globals
-- ============================================================
local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui           = game:GetService("CoreGui")
local UserInputService  = game:GetService("UserInputService")
local Lighting          = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera     = Workspace.CurrentCamera

-- ============================================================
-- 2) Configuration State
-- ============================================================
local Config = {
    AutoFarmEggs   = false,
    AutoHatch      = false,
    AutoRide       = false,
    AutoSell       = false,
    AutoCollect    = false,
    EggRarity      = "All",
    TweenSpeed     = 135,
    WalkSpeed      = 16,
    JumpPower      = 50,
    InfJump        = false,
    FlyEnabled     = false,
    FlySpeed       = 50,
    Noclip         = false,
    AntiAFK        = true,
    EggESP         = false,
    PlayerESP      = false,
    BaseCFrame     = CFrame.new(0, 5, 0),
    ShopCFrame     = CFrame.new(0, 5, 0),
}

local Rarities = { "All", "Common", "Rare", "Epic", "Legendary", "Mythic", "Godly" }

local RarityColor = {
    Common    = Color3.fromRGB(180, 180, 180),
    Rare      = Color3.fromRGB(0, 150, 255),
    Epic      = Color3.fromRGB(150, 0, 255),
    Legendary = Color3.fromRGB(255, 200, 0),
    Mythic    = Color3.fromRGB(255, 0, 100),
    Godly     = Color3.fromRGB(255, 50, 50),
}

-- ============================================================
-- 3) Safe Character Helpers
-- ============================================================
local function getRoot()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChild("Torso")
        or char:FindFirstChild("UpperTorso")
end

local function getHumanoid()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function isAlive()
    local hum = getHumanoid()
    return hum ~= nil and hum.Health > 0
end

-- ============================================================
-- 4) Location Detection
-- ============================================================
local function detectLocations()
    pcall(function()
        local spawn = Workspace:FindFirstChildWhichIsA("SpawnLocation")
        if spawn then
            Config.BaseCFrame = spawn.CFrame + Vector3.new(0, 5, 0)
        end

        for _, obj in ipairs(Workspace:GetChildren()) do
            local n = string.lower(obj.Name)
            if n:match("spawn") or n:match("base") or n:match("home") then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if part then
                    Config.BaseCFrame = part.CFrame + Vector3.new(0, 5, 0)
                    break
                end
            end
        end

        for _, obj in ipairs(Workspace:GetDescendants()) do
            local n = string.lower(obj.Name)
            if n:match("shop") or n:match("sell") or n:match("market") then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if part then
                    Config.ShopCFrame = part.CFrame + Vector3.new(0, 5, 0)
                    break
                end
            end
        end
    end)
end

-- ============================================================
-- 5) Egg Scanner (with rarity detection)
-- ============================================================
local function findEggs()
    local list = {}
    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local matched = false
            local rarity = "Common"

            if obj:IsA("BasePart") then
                local n = string.lower(obj.Name)
                if n:find("egg") then
                    matched = true
                elseif obj.Parent and string.lower(obj.Parent.Name):find("egg") then
                    matched = true
                end
            elseif obj:IsA("Model") and string.lower(obj.Name):find("egg") then
                matched = true
            end

            if matched then
                pcall(function()
                    if obj:GetAttribute("Rarity") then
                        rarity = obj:GetAttribute("Rarity")
                    elseif obj.Parent and obj.Parent:GetAttribute("Rarity") then
                        rarity = obj.Parent:GetAttribute("Rarity")
                    else
                        local rChild = obj:FindFirstChild("Rarity")
                                   or (obj.Parent and obj.Parent:FindFirstChild("Rarity"))
                        if rChild and rChild.Value then
                            rarity = tostring(rChild.Value)
                        else
                            for _, rName in ipairs({ "Godly", "Mythic", "Legendary", "Epic", "Rare" }) do
                                if string.lower(obj.Name):find(string.lower(rName)) then
                                    rarity = rName
                                    break
                                end
                            end
                        end
                    end
                end)

                local part = obj:IsA("BasePart") and obj
                          or obj:FindFirstChildWhichIsA("BasePart")
                          or obj.PrimaryPart
                if part then
                    table.insert(list, {
                        Part = part,
                        CFrame = part.CFrame,
                        Name = obj.Name,
                        Rarity = rarity,
                    })
                end
            end
        end
    end)
    return list
end

-- ============================================================
-- 6) Collectible Scanner
-- ============================================================
local function findCollectibles()
    local list = {}
    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local n = string.lower(obj.Name)
                if n:match("coin") or n:match("star") or n:match("candy")
                   or n:match("gift") or n:match("treat") or n:match("bone") then
                    table.insert(list, obj)
                end
            end
        end
    end)
    return list
end

-- ============================================================
-- 7) Tween Movement
-- ============================================================
local function tweenTo(targetCFrame)
    if not isAlive() then return false end
    local root = getRoot()
    if not root or not targetCFrame then return false end

    local startPos = root.CFrame.Position
    local endPos   = targetCFrame.Position
    local distance = (startPos - endPos).Magnitude
    if distance < 1 then return true end

    local speed    = math.clamp(Config.TweenSpeed, 50, 500)
    local duration = math.clamp(distance / speed, 0.15, 8)
    local info     = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, 0, 0)

    local done = false
    pcall(function()
        local tween = TweenService:Create(root, info, { CFrame = targetCFrame })
        tween:Play()
        local conn
        conn = tween.Completed:Connect(function()
            done = true
            if conn then conn:Disconnect() end
        end)
        local t0 = os.clock()
        while not done and isAlive() and (os.clock() - t0) < (duration + 1) do
            task.wait(0.05)
        end
        if not done then
            pcall(function() tween:Cancel() end)
        end
    end)
    return done
end

-- ============================================================
-- 8) Touch Object
-- ============================================================
local function touchObject(obj)
    if not obj or not isAlive() then return end
    local root = getRoot()
    if not root then return end

    local cf = (typeof(obj) == "table") and obj.CFrame or obj.CFrame
    tweenTo(cf + Vector3.new(0, 3, 0))

    pcall(function()
        local eggPart = (typeof(obj) == "table") and obj.Part or obj
        firetouchinterest(root, eggPart, 0)
        firetouchinterest(root, eggPart, 1)
        root.CFrame = eggPart.CFrame + Vector3.new(0, 2, 0)
        task.wait(0.05)
        firetouchinterest(root, eggPart, 0)
        firetouchinterest(root, eggPart, 1)
    end)
end

-- ============================================================
-- 9) Remote Discovery
-- ============================================================
local RemoteCache = {}
local function findRemote(pattern, parent)
    parent = parent or ReplicatedStorage
    if RemoteCache[pattern] then return RemoteCache[pattern] end
    local found = nil
    pcall(function()
        for _, obj in ipairs(parent:GetDescendants()) do
            if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction"))
               and string.lower(obj.Name):find(string.lower(pattern)) then
                found = obj
                break
            end
        end
    end)
    RemoteCache[pattern] = found
    return found
end

local Remotes = {}
local function initRemotes()
    pcall(function()
        Remotes.Hatch   = findRemote("Hatch")  or findRemote("Open")
        Remotes.Ride    = findRemote("Ride")   or findRemote("Equip") or findRemote("Mount")
        Remotes.Collect = findRemote("Collect") or findRemote("Grab") or findRemote("Pickup")
        Remotes.Sell    = findRemote("Sell")   or findRemote("Shop")
    end)
end

local function fireRemote(remote, ...)
    if not remote then return end
    pcall(function() remote:FireServer(...) end)
end

-- ============================================================
-- 10) Pet Inventory
-- ============================================================
local function getOwnedPets()
    local pets = {}
    pcall(function()
        local locations = {
            LocalPlayer:FindFirstChild("Pets"),
            LocalPlayer:FindFirstChild("Inventory"),
            LocalPlayer:FindFirstChild("Backpack"),
            ReplicatedStorage:FindFirstChild("Pets"),
        }
        for _, loc in ipairs(locations) do
            if loc then
                for _, p in ipairs(loc:GetChildren()) do
                    table.insert(pets, p)
                end
            end
        end
    end)
    return pets
end

-- ============================================================
-- 11) Auto Farm Loops
-- ============================================================
local function shouldFarmEgg(egg)
    if Config.EggRarity == "All" then return true end
    return egg.Rarity == Config.EggRarity
end

local function startAutoFarmEggs()
    task.spawn(function()
        while Config.AutoFarmEggs do
            pcall(function()
                if isAlive() then
                    local eggs = findEggs()
                    local root = getRoot()
                    local nearest, nearestDist = nil, math.huge
                    for _, e in ipairs(eggs) do
                        if shouldFarmEgg(e) and root then
                            local d = (root.Position - e.CFrame.Position).Magnitude
                            if d < nearestDist then
                                nearestDist = d
                                nearest = e
                            end
                        end
                    end
                    if nearest then touchObject(nearest) end
                end
            end)
            task.wait(0.3)
        end
    end)
end

local function startAutoCollect()
    task.spawn(function()
        while Config.AutoCollect do
            pcall(function()
                if isAlive() then
                    local items = findCollectibles()
                    local root = getRoot()
                    local nearest, nearestDist = nil, math.huge
                    for _, c in ipairs(items) do
                        if root then
                            local d = (root.Position - c.Position).Magnitude
                            if d < nearestDist then
                                nearestDist = d
                                nearest = c
                            end
                        end
                    end
                    if nearest then
                        touchObject(nearest)
                        if Remotes.Collect then fireRemote(Remotes.Collect, nearest) end
                    end
                end
            end)
            task.wait(0.2)
        end
    end)
end

local function startAutoHatch()
    task.spawn(function()
        while Config.AutoHatch do
            pcall(function()
                if Remotes.Hatch then
                    fireRemote(Remotes.Hatch)
                    fireRemote(Remotes.Hatch, "Best")
                    fireRemote(Remotes.Hatch, Config.EggRarity)
                end
            end)
            task.wait(0.5)
        end
    end)
end

local function startAutoRide()
    task.spawn(function()
        while Config.AutoRide do
            pcall(function()
                local pets = getOwnedPets()
                if #pets > 0 and Remotes.Ride then
                    fireRemote(Remotes.Ride, pets[1])
                end
            end)
            task.wait(2)
        end
    end)
end

local function startAutoSell()
    task.spawn(function()
        while Config.AutoSell do
            pcall(function()
                if Remotes.Sell then
                    fireRemote(Remotes.Sell)
                    fireRemote(Remotes.Sell, "All")
                end
            end)
            task.wait(1.5)
        end
    end)
end

-- ============================================================
-- 12) WalkSpeed / JumpPower
-- ============================================================
local function applyMovementStats()
    task.spawn(function()
        while true do
            pcall(function()
                local hum = getHumanoid()
                if hum then
                    hum.WalkSpeed = Config.WalkSpeed
                    hum.JumpPower = Config.JumpPower
                end
            end)
            task.wait(0.5)
        end
    end)
end

-- ============================================================
-- 13) Infinite Jump
-- ============================================================
local infJumpConn
local function toggleInfJump(state)
    if infJumpConn then infJumpConn:Disconnect() infJumpConn = nil end
    if state then
        infJumpConn = UserInputService.JumpRequest:Connect(function()
            pcall(function()
                local hum = getHumanoid()
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        end)
    end
end

-- ============================================================
-- 14) Noclip
-- ============================================================
local noclipConn
local function toggleNoclip(state)
    if noclipConn then noclipConn:Disconnect() noclipConn = nil end
    if state then
        noclipConn = RunService.Stepped:Connect(function()
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    for _, p in ipairs(char:GetDescendants()) do
                        if p:IsA("BasePart") and p.CanCollide then
                            p.CanCollide = false
                        end
                    end
                end
            end)
        end)
    else
        pcall(function()
            local char = LocalPlayer.Character
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then
                        p.CanCollide = true
                    end
                end
            end
        end)
    end
end

-- ============================================================
-- 15) Fly Mode
-- ============================================================
local flyConn
local flyBP, flyBG

local function getFlyInput()
    local dir = Vector3.new(0, 0, 0)
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
    return dir
end

local function toggleFly(state)
    if flyConn then flyConn:Disconnect() flyConn = nil end
    if flyBP then flyBP:Destroy() flyBP = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end

    if state then
        task.spawn(function()
            while Config.FlyEnabled do
                pcall(function()
                    local root = getRoot()
                    if root and isAlive() then
                        if not flyBP then
                            flyBP = Instance.new("BodyPosition")
                            flyBP.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                            flyBP.Position = root.Position
                            flyBP.Parent = root
                        end
                        if not flyBG then
                            flyBG = Instance.new("BodyGyro")
                            flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
                            flyBG.CFrame = root.CFrame
                            flyBG.Parent = root
                        end

                        local dir = getFlyInput()
                        if dir.Magnitude > 0 then
                            dir = dir.Unit * Config.FlySpeed
                            flyBP.Position = root.Position + dir
                        else
                            flyBP.Position = root.Position
                        end
                        flyBG.CFrame = Camera.CFrame
                    end
                end)
                task.wait(0.03)
            end
            if flyBP then flyBP:Destroy() flyBP = nil end
            if flyBG then flyBG:Destroy() flyBG = nil end
        end)
    end
end

-- ============================================================
-- 16) Anti-AFK
-- ============================================================
local antiAFKConn
local function toggleAntiAFK(state)
    if antiAFKConn then antiAFKConn:Disconnect() antiAFKConn = nil end
    if state then
        antiAFKConn = LocalPlayer.Idled:Connect(function()
            pcall(function()
                local VirtualUser = game:GetService("VirtualUser")
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end)
    end
end

-- ============================================================
-- 17) Egg ESP (Highlight rare eggs)
-- ============================================================
local eggHighlights = {}
local function clearEggESP()
    for _, h in ipairs(eggHighlights) do
        pcall(function() h:Destroy() e
