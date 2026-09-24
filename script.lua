--[[
    Dino Legend Hub - Lite (Kavo UI)
    Game: +1 Dino Evolution / Steal an Egg
    Platform: Delta Executor (Mobile) - No Key / Open Source
    Strategy: Touch + Tween (135 studs/s default)
]]

-- ============================================================
-- 1) Services & Globals
-- ============================================================
local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- 2) Configuration State
-- ============================================================
local Config = {
    AutoFarm    = false,
    TweenSpeed  = 135,
    BaseCFrame  = CFrame.new(0, 5, 0),
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
-- 4) Base Detection (Spawn point fallback)
-- ============================================================
local function detectBase()
    pcall(function()
        local spawn = Workspace:FindFirstChildWhichIsA("SpawnLocation")
        if spawn then
            Config.BaseCFrame = spawn.CFrame + Vector3.new(0, 5, 0)
            return
        end
        for _, obj in ipairs(Workspace:GetChildren()) do
            local n = string.lower(obj.Name)
            if n:match("spawn") or n:match("base") or n:match("home") then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if part then
                    Config.BaseCFrame = part.CFrame + Vector3.new(0, 5, 0)
                    return
                end
            end
        end
    end)
end

-- ============================================================
-- 5) Egg Scanner (Parts containing "Egg" in name or parent)
-- ============================================================
local function findEggs()
    local list = {}
    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local matched = false
            if obj:IsA("BasePart") then
                local n = string.lower(obj.Name)
                if n:find("egg") then
                    matched = true
                elseif obj.Parent then
                    local pn = string.lower(obj.Parent.Name)
                    if pn:find("egg") then
                        matched = true
                    end
                end
            end
            if matched then
                table.insert(list, obj)
            end
        end
    end)
    return list
end

-- ============================================================
-- 6) Tween Movement (smooth, egg-safe)
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
-- 7) Touch Egg (collect via firetouchinterest)
-- ============================================================
local function touchEgg(eggPart)
    if not eggPart or not isAlive() then return end
    local root = getRoot()
    if not root then return end

    tweenTo(eggPart.CFrame + Vector3.new(0, 3, 0))

    pcall(function()
        firetouchinterest(root, eggPart, 0)
        firetouchinterest(root, eggPart, 1)
    end)

    pcall(function()
        root.CFrame = eggPart.CFrame + Vector3.new(0, 2, 0)
        task.wait(0.05)
        firetouchinterest(root, eggPart, 0)
        firetouchinterest(root, eggPart, 1)
    end)
end

-- ============================================================
-- 8) Auto Farm Loop
-- ============================================================
local farmRunning = false
local function startAutoFarm()
    if farmRunning then return end
    farmRunning = true
    task.spawn(function()
        while Config.AutoFarm do
            pcall(function()
                if isAlive() then
                    local eggs = findEggs()
                    if #eggs > 0 then
                        local root = getRoot()
                        local nearest, nearestDist = nil, math.huge
                        if root then
                            for _, e in ipairs(eggs) do
                                local d = (root.Position - e.Position).Magnitude
                                if d < nearestDist then
                                    nearestDist = d
                                    nearest = e
                                end
                            end
                        end
                        if nearest then
                            touchEgg(nearest)
                        end
                    end
                end
            end)
            task.wait(0.3)
        end
        farmRunning = false
    end)
end

-- ============================================================
-- 9) Load Kavo UI Library
-- ============================================================
local KavoLoaded, Library = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-library/main/source.lua"))()
end)

if not KavoLoaded or not Library then
    local ok2, lib2 = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-library/main/source.lua"))()
    end)
    if ok2 and lib2 then
        Library = lib2
    else
        warn("[Dino Legend Hub] Failed to load Kavo UI.")
        return
    end
end

-- ============================================================
-- 10) Build UI
-- ============================================================
local Window = Library.CreateLib("Dino Legend Hub - Lite", "DarkTheme")

local MainTab = Window:NewTab("Main")
local MainSection = MainTab:AddSection("Auto Farm")

MainTab:AddToggle({
    Name = "Auto Farm Eggs",
    Default = false,
    Callback = function(value)
        Config.AutoFarm = value
        if value then
            startAutoFarm()
        end
    end
})

MainTab:AddSlider({
    Name = "Tween Speed",
    Min = 50,
    Max = 300,
    Default = 135,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 5,
    Callback = function(value)
        Config.TweenSpeed = value
    end
})

MainTab:AddButton({
    Name = "Scan Eggs Now",
    Callback = function()
        local eggs = findEggs()
        print("[Dino Legend Hub] Found " .. #eggs .. " egg parts.")
    end
})

local TeleTab = Window:NewTab("Teleports")
local TeleSection = TeleTab:AddSection("Quick Travel")

TeleTab:AddButton({
    Name = "Teleport to Spawn / Base",
    Callback = function()
        detectBase()
        task.spawn(function()
            tweenTo(Config.BaseCFrame)
        end)
    end
})

TeleTab:AddButton({
    Name = "Instant TP to Base",
    Callback = function()
        detectBase()
        local root = getRoot()
        if root then
            pcall(function()
                root.CFrame = Config.BaseCFrame
            end)
        end
    end
})

TeleTab:AddButton({
    Name = "Teleport to Nearest Egg",
    Callback = function()
        task.spawn(function()
            local eggs = findEggs()
            if #eggs == 0 then return end
            local root = getRoot()
            if not root then return end
            local nearest, dist = nil, math.huge
            for _, e in ipairs(eggs) do
                local d = (root.Position - e.Position).Magnitude
                if d < dist then
                    dist = d
                    nearest = e
                end
            end
            if nearest then
                tweenTo(nearest.CFrame + Vector3.new(0, 4, 0))
            end
        end)
    end
})

TeleTab:AddButton({
    Name = "Save Current as Base",
    Callback = function()
        local root = getRoot()
        if root then
            Config.BaseCFrame = root.CFrame
        end
    end
})

local InfoTab = Window:NewTab("Info")
local InfoSection = InfoTab:AddSection("About")

InfoTab:AddButton({
    Name = "Re-detect Base",
    Callback = function()
        detectBase()
    end
})

InfoTab:AddButton({
    Name = "Destroy UI",
    Callback = function()
        pcall(function()
            if game.CoreGui:FindFirstChild("KavoUI") then
                game.CoreGui.KavoUI:Destroy()
            end
        end)
    end
})

-- ============================================================
-- 11) Init + Character Re-Hook
-- ============================================================
local function onCharacterAdded()
    task.wait(0.5)
    pcall(function()
        detectBase()
    end)
end

task.spawn(onCharacterAdded)
LocalPlayer.CharacterAdded:Connect(function()
    pcall(onCharacterAdded)
end)

print("[Dino Legend Hub] Loaded successfully - Keyless / Open Source")