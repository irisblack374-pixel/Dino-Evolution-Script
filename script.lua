--[[
    Ride a Pet Hub - Fixed UI Edition
    Game: Ride a Pet
    Lua / Roblox
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Config = {
    AutoFarmEggs = false,
    AutoHatch = false,
    AutoRide = false,
    AutoSell = false,
    AutoCollect = false,
    InfJump = false,
    FlyEnabled = false,
    Noclip = false,
    AntiAFK = true,
    WalkSpeed = 16,
    JumpPower = 50,
    FlySpeed = 50,
    TweenSpeed = 135,
}

local function getCharacter()
    return LocalPlayer.Character
end

local function getRoot()
    local c = getCharacter()
    return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso"))
end

local function getHumanoid()
    local c = getCharacter()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function alive()
    local h = getHumanoid()
    return h and h.Health > 0
end

local function findEggs()
    local out = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local n = string.lower(obj.Name)
        if n:find("egg") then
            local p = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
            if p then table.insert(out, p) end
        end
    end
    return out
end

local function findCollectibles()
    local out = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = string.lower(obj.Name)
            if n:find("coin") or n:find("star") or n:find("candy") or n:find("gift") or n:find("treat") or n:find("bone") then
                table.insert(out, obj)
            end
        end
    end
    return out
end

local function moveTo(part)
    local root = getRoot()
    if not root or not part then return end
    local distance = (root.Position - part.Position).Magnitude
    local duration = math.clamp(distance / math.max(Config.TweenSpeed, 50), 0.15, 5)
    local tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        CFrame = part.CFrame + Vector3.new(0, 3, 0)
    })
    tween:Play()
    tween.Completed:Wait()
end

local function touch(part)
    if not part or not alive() then return end
    local root = getRoot()
    if not root then return end
    pcall(function()
        moveTo(part)
        if firetouchinterest then
            firetouchinterest(root, part, 0)
            firetouchinterest(root, part, 1)
        end
    end)
end

local function findRemote(pattern)
    local p = string.lower(pattern)
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and string.lower(obj.Name):find(p) then
            return obj
        end
    end
end

local Remotes = {}

local function initRemotes()
    Remotes.Hatch = findRemote("hatch") or findRemote("open")
    Remotes.Ride = findRemote("ride") or findRemote("equip") or findRemote("mount")
    Remotes.Collect = findRemote("collect") or findRemote("grab") or findRemote("pickup")
    Remotes.Sell = findRemote("sell") or findRemote("shop")
end

local function fireRemote(remote, ...)
    if not remote then return end
    pcall(function()
        if remote:IsA("RemoteEvent") then
            remote:FireServer(...)
        elseif remote:IsA("RemoteFunction") then
            remote:InvokeServer(...)
        end
    end)
end

local function startAutoFarm()
    task.spawn(function()
        while Config.AutoFarmEggs do
            pcall(function()
                local eggs = findEggs()
                local root = getRoot()
                local nearest, dist = nil, math.huge
                if root then
                    for _, egg in ipairs(eggs) do
                        local d = (root.Position - egg.Position).Magnitude
                        if d < dist then nearest, dist = egg, d end
                    end
                end
                if nearest then touch(nearest) end
            end)
            task.wait(0.4)
        end
    end)
end

local function startAutoCollect()
    task.spawn(function()
        while Config.AutoCollect do
            pcall(function()
                local items = findCollectibles()
                local root = getRoot()
                local nearest, dist = nil, math.huge
                if root then
                    for _, item in ipairs(items) do
                        local d = (root.Position - item.Position).Magnitude
                        if d < dist then nearest, dist = item, d end
                    end
                end
                if nearest then
                    touch(nearest)
                    fireRemote(Remotes.Collect, nearest)
                end
            end)
            task.wait(0.3)
        end
    end)
end

local function startAutoHatch()
    task.spawn(function()
        while Config.AutoHatch do
            fireRemote(Remotes.Hatch)
            task.wait(0.6)
        end
    end)
end

local function startAutoRide()
    task.spawn(function()
        while Config.AutoRide do
            pcall(function()
                local pets = LocalPlayer:FindFirstChild("Pets") or LocalPlayer:FindFirstChild("Inventory")
                local pet = pets and pets:GetChildren()[1]
                if pet then fireRemote(Remotes.Ride, pet) end
            end)
            task.wait(2)
        end
    end)
end

local function startAutoSell()
    task.spawn(function()
        while Config.AutoSell do
            fireRemote(Remotes.Sell)
            task.wait(1.5)
        end
    end)
end

local infConn
local function setInfJump(v)
    if infConn then infConn:Disconnect(); infConn = nil end
    if v then
        infConn = UserInputService.JumpRequest:Connect(function()
            local h = getHumanoid()
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end
end

local noclipConn
local function setNoclip(v)
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    if v then
        noclipConn = RunService.Stepped:Connect(function()
            local c = getCharacter()
            if c then
                for _, p in ipairs(c:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
    end
end

local antiConn
local function setAntiAFK(v)
    if antiConn then antiConn:Disconnect(); antiConn = nil end
    if v then
        antiConn = LocalPlayer.Idled:Connect(function()
            pcall(function()
                local vu = game:GetService("VirtualUser")
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end)
        end)
    end
end

local function buildUI()
    local old = game:GetService("CoreGui"):FindFirstChild("RideAPetHub")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "RideAPetHub"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = game:GetService("CoreGui")

    local main = Instance.new("Frame")
    main.Size = UDim2.fromOffset(330, 430)
    main.Position = UDim2.new(0.5, -165, 0.5, -215)
    main.BackgroundColor3 = Color3.fromRGB(18,18,22)
    main.BorderSizePixel = 0
    main.Parent = gui

    Instance.new("UICorner", main).CornerRadius = UDim.new(0,12)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,50)
    title.BackgroundTransparency = 1
    title.Text = "Ride a Pet Hub"
    title.TextColor3 = Color3.new(1,1,1)
    title.TextSize = 22
    title.Font = Enum.Font.GothamBold
    title.Parent = main

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1,-20,0,25)
    sub.Position = UDim2.fromOffset(10,45)
    sub.BackgroundTransparency = 1
    sub.Text = "Fixed Edition"
    sub.TextColor3 = Color3.fromRGB(160,160,160)
    sub.TextSize = 12
    sub.Font = Enum.Font.Gotham
    sub.Parent = main

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1,-20,1,-85)
    scroll.Position = UDim2.fromOffset(10,75)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.CanvasSize = UDim2.new()
    scroll.Parent = main

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0,7)
    layout.Parent = scroll

    local function button(text, callback)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1,0,0,40)
        b.BackgroundColor3 = Color3.fromRGB(32,32,38)
        b.BorderSizePixel = 0
        b.Text = text
        b.TextColor3 = Color3.new(1,1,1)
        b.TextSize = 14
        b.Font = Enum.Font.GothamMedium
        b.AutoButtonColor = true
        b.Parent = scroll
        Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
        b.MouseButton1Click:Connect(callback)
        return b
    end

    local function toggle(label, key, start)
        local b
        local function refresh()
            b.Text = label .. ": " .. (Config[key] and "ON" or "OFF")
        end
        b = button(label, function()
            Config[key] = not Config[key]
            refresh()
            if key == "AutoFarmEggs" and Config[key] then startAutoFarm() end
            if key == "AutoCollect" and Config[key] then startAutoCollect() end
            if key == "AutoHatch" and Config[key] then startAutoHatch() end
            if key == "AutoRide" and Config[key] then startAutoRide() end
            if key == "AutoSell" and Config[key] then startAutoSell() end
            if key == "InfJump" then setInfJump(Config[key]) end
            if key == "Noclip" then setNoclip(Config[key]) end
            if key == "AntiAFK" then setAntiAFK(Config[key]) end
        end)
        refresh()
    end

    toggle("Auto Farm Eggs", "AutoFarmEggs")
    toggle("Auto Collect", "AutoCollect")
    toggle("Auto Hatch", "AutoHatch")
    toggle("Auto Ride", "AutoRide")
    toggle("Auto Sell", "AutoSell")
    toggle("Infinite Jump", "InfJump")
    toggle("Noclip", "Noclip")
    toggle("Anti AFK", "AntiAFK")

    button("Refresh Remotes", function()
        initRemotes()
        title.Text = "Ride a Pet Hub ✓"
        task.delay(1.2, function() title.Text = "Ride a Pet Hub" end)
    end)

    button("Close", function()
        gui:Destroy()
    end)

    scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 10)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 10)
    end)

    -- Mobile drag
    local dragging, dragStart, startPos
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

initRemotes()
setAntiAFK(true)
buildUI()

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if Config.InfJump then setInfJump(true) end
    if Config.Noclip then setNoclip(true) end
end)
