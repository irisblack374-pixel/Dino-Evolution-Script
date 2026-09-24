--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║                     Dino Legend Hub - VIP                      ║
    ║                  +1 Dino Evolution / Steal an Egg             ║
    ║         Delta Executor (Mobile) - No Key / Open Source       ║
    ║                  Built on Rayfield UI Library                ║
    ╚══════════════════════════════════════════════════════════════╝
]]

-- ============================================================
-- 1) Load Rayfield UI Library
-- ============================================================
local RayfieldLoaded, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not RayfieldLoaded or not Rayfield then
    local ok, lib = pcall(function()
        return loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()
    end)
    if ok and lib then
        Rayfield = lib
    else
        warn("[Dino Legend Hub] Failed to load Rayfield UI Library.")
        return
    end
end

-- ============================================================
-- 2) Services
-- ============================================================
local Players            = game:GetService("Players")
local Workspace          = game:GetService("Workspace")
local RunService          = game:GetService("RunService")
local TweenService       = game:GetService("TweenService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local UserInputService   = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- 3) State / Configuration
-- ============================================================
local State = {
    SelectedRarity      = "All",
    TargetRarityOnly    = false,
    AutoFarm            = false,
    AutoDeposit         = false,
    AutoOpen            = false,
    TweenSpeed          = 135,
    CurrentEggs         = {},
    BasePosition        = CFrame.new(0, 5, 0),
    SellPosition        = CFrame.new(0, 5, 0),
}

local Rarities = { "All", "Legendary", "Mythic", "Godly", "Secret" }

local RarityPriority = {
    ["Secret"]     = 5,
    ["Godly"]      = 4,
    ["Mythic"]     = 3,
    ["Legendary"]  = 2,
    ["Rare"]       = 1,
    ["Epic"]       = 1,
    ["Common"]     = 0,
    ["Uncommon"]   = 0,
}

-- ============================================================
-- 4) Utility / Safe wrappers
-- ============================================================
local function getRoot()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
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

local function tweenTo(targetCFrame, speedOverride)
    if not isAlive() then return false end
    local root = getRoot()
    if not root or not targetCFrame then return false end

    local speed = speedOverride or State.TweenSpeed
    local startPos = root.CFrame.Position
    local endPos   = targetCFrame.Position
    local distance = (startPos - endPos).Magnitude
    if distance < 1 then return true end

    local duration = math.clamp(distance / speed, 0.15, 10)
    local info = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, 0, 0)

    local success = false
    pcall(function()
        local tween = TweenService:Create(root, info, { CFrame = targetCFrame })
        tween:Play()

        local conn
        conn = tween.Completed:Connect(function()
            success = true
            conn:Disconnect()
        end)

        task.delay(duration + 0.5, function()
            if not success then pcall(function() tween:Cancel() end) end
        end)

        local startT = os.clock()
        while not success and isAlive() and (os.clock() - startT) < (duration + 1) do
            task.wait(0.05)
        end
    end)

    return success
end

local function instantTeleportTo(targetCFrame)
    local root = getRoot()
    if not root or not targetCFrame then return end
    pcall(function()
        root.CFrame = targetCFrame
    end)
end

local function fireRemote(remote, ...)
    pcall(function()
        remote:FireServer(...)
    end)
end

-- ============================================================
-- 5) Egg Scanner
-- ============================================================
local function scanEggs()
    local found = {}
    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local isEgg = false
            local name = obj.Name or ""
            local lowerName = string.lower(name)

            if obj:IsA("Model") and (lowerName:match("egg") or (obj.Parent and string.lower(obj.Parent.Name):match("egg"))) then
                isEgg = true
            elseif obj:IsA("BasePart") and (lowerName:match("egg") or (obj.Parent and string.lower(obj.Parent.Name):match("egg"))) then
                isEgg = true
            end

            if isEgg then
                local rarity = "Common"

                pcall(function()
                    if obj:GetAttribute("Rarity") then
                        rarity = obj:GetAttribute("Rarity")
                    elseif obj.Parent and obj.Parent:GetAttribute("Rarity") then
                        rarity = obj.Parent:GetAttribute("Rarity")
                    end
                end)

                if rarity == "Common" then
                    pcall(function()
                        local rChild = obj:FindFirstChild("Rarity")
                        if not rChild and obj.Parent then rChild = obj.Parent:FindFirstChild("Rarity") end
                        if rChild and rChild.Value then
                            rarity = tostring(rChild.Value)
                        end
                    end)
                end

                if rarity == "Common" then
                    for _, rName in ipairs({ "Secret", "Godly", "Mythic", "Legendary", "Epic", "Rare", "Uncommon" }) do
                        if lowerName:match(string.lower(rName)) then
                            rarity = rName
                            break
                        end
                    end
                end

                local part = obj:IsA("BasePart") and obj or (obj:FindFirstChildWhichIsA("BasePart") or obj.PrimaryPart)
                if not part and obj:IsA("Model") then
                    pcall(function()
                        part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                    end)
                end

                table.insert(found, {
                    Instance = obj,
                    Part     = part,
                    Name     = name,
                    Rarity   = rarity,
                    Priority = RarityPriority[rarity] or 0,
                    CFrame   = part and part.CFrame or nil,
                })
            end
        end
    end)
    return found
end

local function refreshEggs()
    State.CurrentEggs = scanEggs()
    return State.CurrentEggs
end

local function getBestEgg()
    local eggs = State.CurrentEggs
    if #eggs == 0 then eggs = refreshEggs() end

    local best = nil
    for _, e in ipairs(eggs) do
        if e.CFrame then
            if State.SelectedRarity == "All" then
                if not best or e.Priority > best.Priority then
                    best = e
                end
            else
                if e.Rarity == State.SelectedRarity then
                    if not best or e.Priority > best.Priority then
                        best = e
                    end
                end
            end
        end
    end
    return best
end

-- ============================================================
-- 6) Detect Base & Sell Zone
-- ============================================================
local function findBaseAndSell()
    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local n = string.lower(obj.Name)
            if n:match("base") or n:match("home") or n:match("spawn") or n:match("house") then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if part then
                    State.BasePosition = part.CFrame + Vector3.new(0, 5, 0)
                    break
                end
            end
        end

        for _, obj in ipairs(Workspace:GetDescendants()) do
            local n = string.lower(obj.Name)
            if n:match("sell") or n:match("shop") or n:match("merchant") or n:match("market") then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if part then
                    State.SellPosition = part.CFrame + Vector3.new(0, 5, 0)
                    break
                end
            end
        end

        if State.BasePosition == CFrame.new(0,5,0) then
            local spawn = Workspace:FindFirstChild("SpawnLocation") or Workspace:FindFirstChildWhichIsA("SpawnLocation")
            if spawn then
                State.BasePosition = spawn.CFrame + Vector3.new(0, 5, 0)
            end
        end
    end)
end

-- ============================================================
-- 7) Remote Discovery
-- ============================================================
local function findRemote(name, parent)
    parent = parent or ReplicatedStorage
    local found = nil
    pcall(function()
        for _, obj in ipairs(parent:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                if string.lower(obj.Name):match(string.lower(name)) then
                    found = obj
                    break
                end
            end
        end
    end)
    return found
end

local Remotes = {}
local function initRemotes()
    pcall(function()
        Remotes.CollectEgg = findRemote("CollectEgg") or findRemote("Collect")
        Remotes.Deposit    = findRemote("Deposit")    or findRemote("StoreEgg") or findRemote("ReturnEgg")
        Remotes.OpenEgg    = findRemote("OpenEgg")     or findRemote("HatchEgg")
        Remotes.StealEgg   = findRemote("StealEgg")    or findRemote("Steal")
    end)
end

-- ============================================================
-- 8) Auto Farm & Open Loops
-- ============================================================
local function touchEgg(egg)
    if not egg or not egg.Part or not egg.CFrame then return false end
    if not isAlive() then return false end

    local ok = tweenTo(egg.CFrame + Vector3.new(0, 3, 0))
    if not ok then return false end

    pcall(function()
        local root = getRoot()
        if root and egg.Part then
            firetouchinterest(root, egg.Part, 0)
            firetouchinterest(root, egg.Part, 1)
        end
    end)

    if Remotes.CollectEgg then fireRemote(Remotes.CollectEgg, egg.Instance) end
    if Remotes.StealEgg then fireRemote(Remotes.StealEgg, egg.Instance) end

    task.wait(0.1)
    return true
end

local farmRunning = false
local function autoFarmLoop()
    if farmRunning then return end
    farmRunning = true
    task.spawn(function()
        while State.AutoFarm do
            pcall(function()
                if isAlive() then
                    local eggs = refreshEggs()
                    local target = nil

                    if State.TargetRarityOnly and State.SelectedRarity ~= "All" then
                        for _, e in ipairs(eggs) do
                            if e.Rarity == State.SelectedRarity and e.CFrame then
                                target = e
                                break
                            end
                        end
                    else
                        target = getBestEgg()
                    end

                    if target then
                        touchEgg(target)
                        if State.AutoDeposit then
                            task.wait(0.2)
                            if Remotes.Deposit then
                                fireRemote(Remotes.Deposit)
                            else
                                tweenTo(State.BasePosition)
                            end
                        end
                    else
                        if State.AutoDeposit and Remotes.Deposit then
                            fireRemote(Remotes.Deposit)
                        end
                    end
                end
            end)
            task.wait(0.4)
        end
        farmRunning = false
    end)
end

local function autoOpenLoop()
    task.spawn(function()
        while State.AutoOpen do
            pcall(function()
                if Remotes.OpenEgg then
                    fireRemote(Remotes.OpenEgg, State.SelectedRarity)
                    fireRemote(Remotes.OpenEgg, "Best")
                end
            end)
            task.wait(1.0)
        end
    end)
end

-- ============================================================
-- 9) Build UI
-- ============================================================
local Window = Rayfield:CreateWindow({
    Name              = "Dino Legend Hub - VIP",
    LoadingTitle      = "Dino Legend Hub",
    LoadingSubtitle   = "+1 Dino Evolution / Steal an Egg",
    ConfigurationSaving = { Enabled = false },
    KeySystem         = false,
})

-- Main Tab
local MainTab = Window:CreateTab("Main", 4483362458)

MainTab:CreateSection("Quick Guide")
MainTab:CreateParagraph({
    Title = "How to use",
    Content = "1) Choose the egg rarity. 2) Turn on only the features you need. 3) Use Scan Eggs Now if the target list is empty. 4) Turn Auto Farm off before changing major settings."
})

MainTab:CreateParagraph({
    Title = "Feature status",
    Content = "Auto Farm: OFF | Auto Deposit: OFF | Auto Open: OFF\nStart with Auto Farm only, then enable Auto Deposit or Auto Open if needed."
})


MainTab:CreateDropdown({
    Name        = "Target Egg Rarity",
    Options     = Rarities,
    CurrentOption = "All",
    Flag        = "RarityFilter",
    Callback    = function(opt)
        State.SelectedRarity = opt
        Rayfield:Notify({ Title = "Rarity Set", Content = "Target: " .. opt, Duration = 3 })
    end,
})

MainTab:CreateToggle({
    Name        = "Target Rarity Only",
    CurrentValue = false,
    Flag        = "TargetOnly",
    Callback    = function(v)
        State.TargetRarityOnly = v
    end,
})

MainTab:CreateButton({
    Name     = "Scan Eggs Now",
    Callback = function()
        local list = refreshEggs()
        findBaseAndSell()
        Rayfield:Notify({
            Title    = "Scan Complete",
            Content  = string.format("Found %d eggs in map", #list),
            Duration = 4,
        })
    end,
})

MainTab:CreateSection("Auto Farm")

MainTab:CreateToggle({
    Name        = "Auto Farm Target Eggs",
    CurrentValue = false,
    Flag        = "AutoFarm",
    Callback    = function(v)
        State.AutoFarm = v
        if v then autoFarmLoop() end
    end,
})

MainTab:CreateToggle({
    Name        = "Auto Deposit (Return Base)",
    CurrentValue = false,
    Flag        = "AutoDeposit",
    Callback    = function(v)
        State.AutoDeposit = v
    end,
})

MainTab:CreateToggle({
    Name        = "Auto Open Best Eggs",
    CurrentValue = false,
    Flag        = "AutoOpen",
    Callback    = function(v)
        State.AutoOpen = v
        if v then autoOpenLoop() end
    end,
})

MainTab:CreateSlider({
    Name        = "Tween Speed (studs/sec)",
    Range       = {80, 200},
    Increment   = 5,
    Suffix      = " studs/s",
    CurrentValue = 135,
    Flag        = "TweenSpeed",
    Callback    = function(v)
        State.TweenSpeed = v
    end,
})

-- Teleports Tab
local TeleTab = Window:CreateTab("Teleports", 4483362458)

TeleTab:CreateSection("Teleport Guide")
TeleTab:CreateParagraph({
    Title = "What each button does",
    Content = "Base/Home: moves you to the detected base.\nRarest Egg: moves to the best detected egg.\nSell Zone: moves to the detected selling area.\nInstant TP: uses direct position movement."
})


TeleTab:CreateButton({
    Name     = "Teleport to Base / Home",
    Callback = function()
        findBaseAndSell()
        task.spawn(function()
            tweenTo(State.BasePosition)
        end)
    end,
})

TeleTab:CreateButton({
    Name     = "Teleport to Rarest Egg",
    Callback = function()
        refreshEggs()
        local best = getBestEgg()
        if best and best.CFrame then
            task.spawn(function()
                tweenTo(best.CFrame + Vector3.new(0, 4, 0))
            end)
        end
    end,
})

TeleTab:CreateButton({
    Name     = "Teleport to Sell Zone",
    Callback = function()
        findBaseAndSell()
        task.spawn(function()
            tweenTo(State.SellPosition)
        end)
    end,
})

TeleTab:CreateSection("Instant Teleport")

TeleTab:CreateButton({
    Name     = "Instant TP to Base",
    Callback = function()
        findBaseAndSell()
        instantTeleportTo(State.BasePosition)
    end,
})

TeleTab:CreateButton({
    Name     = "Instant TP to Rarest Egg",
    Callback = function()
        refreshEggs()
        local best = getBestEgg()
        if best and best.CFrame then
            instantTeleportTo(best.CFrame + Vector3.new(0, 3, 0))
        end
    end,
})

TeleTab:CreateButton({
    Name     = "Instant TP to Sell Zone",
    Callback = function()
        findBaseAndSell()
        instantTeleportTo(State.SellPosition)
    end,
})

TeleTab:CreateSection("Position Override")

TeleTab:CreateButton({
    Name     = "Save Current Position as Base",
    Callback = function()
        local root = getRoot()
        if root then
            State.BasePosition = root.CFrame
            Rayfield:Notify({ Title = "Saved", Content = "Base position updated.", Duration = 2 })
        end
    end,
})

TeleTab:CreateButton({
    Name     = "Save Current Position as Sell Zone",
    Callback = function()
        local root = getRoot()
        if root then
            State.SellPosition = root.CFrame
            Rayfield:Notify({ Title = "Saved", Content = "Sell position updated.", Duration = 2 })
        end
    end,
})

-- ============================================================
-- 10) Init
-- ============================================================
local function onCharacterAdded()
    task.wait(0.5)
    pcall(function()
        findBaseAndSell()
        initRemotes()
        refreshEggs()
    end)
end

task.spawn(onCharacterAdded)
LocalPlayer.CharacterAdded:Connect(function()
    pcall(onCharacterAdded)
end)

Rayfield:Notify({
    Title    = "Dino Legend Hub Loaded",
    Content  = "Interface ready. Start with Scan Eggs Now, then enable the features you want.",
    Duration = 6,
})