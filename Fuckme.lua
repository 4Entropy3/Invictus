repeat task.wait() until game:IsLoaded()

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local BallsFolder = workspace:WaitForChild("Balls", 999999)
local AliveFolder = workspace:FindFirstChild("Alive") or workspace:WaitForChild("Alive")
local RuntimeFolder = workspace.Runtime

local OriginalAmbient = Lighting.Ambient
local OriginalFogColor = Lighting.FogColor
local OriginalClockTime = Lighting.ClockTime

local CapturedRemotes = {}
local HookedMetatables = {}
local CapturedParryKey = nil

local ParryConfig = {
    autoParryEnabled = true,
    pingBased = true,
    distanceToHit = 10,
    pingOffset = 0,
    curveMode = 1,
    playAnimation = false,
    divisorMultiplier = 1.1,
    accuracy = 50,
    hasParried = false,
    parryCount = 0,
    firstParryDone = false,
    tornadoTime = tick(),
    lerpRadians = 0,
    lastWarping = tick(),
    curvingTime = tick(),
    
    lookAtBall = false,
    lookAtType = "Camera",
    
    rainbowVisualizer = false,
    rainbowCircle = false,
    rainbowAmbient = false,
    rainbowFog = false,
    
    triggerbotEnabled = false,
    triggerbotParrying = false,
    triggerbotParries = 0,
    
    manualSpamEnabled = false,
    autoSpamEnabled = false,
    spamRate = 240,
    spamAccumulator = 0,
    spamThreshold = 1.5,
    
    infinityActive = false,
    deathslashActive = false,
    timeholeActive = false,
    slashesActive = false,
    slashesCount = 0
}

local UtilityConfig = {
    antiSlashEffect = false,
    autoClaimRewards = false,
    autoSwordCrate = false,
    autoExplosionCrate = false
}

local VisualizerToggles = {
    ballVisualizer = true,
    clashVisualizer = true,
    distanceVisualizer = true,
    circleBallVisualizer = true,
    circleClashVisualizer = true,
    circleDistanceVisualizer = true
}

local VisualizerSettings = {
    shape = "Ball",
    material = "ForceField",
    color = Color3.fromRGB(255, 255, 255),
    circleColor = Color3.fromRGB(255, 255, 255),
    transparency = 0,
    circleHeight = 0.5,
    clashDistance = 30
}

local CurveTypes = {
    "Camera",
    "Random", 
    "Accelerated",
    "Backwards",
    "Slow",
    "High"
}

local SwordsController = nil
local ParryFunction = nil

if ReplicatedStorage:FindFirstChild("Controllers") then
    for _, controller in ipairs(ReplicatedStorage.Controllers:GetChildren()) do
        if controller.Name:match("^SwordsController%s*$") then
            SwordsController = controller
        end
    end
end

if LocalPlayer.PlayerGui:FindFirstChild("Hotbar") and LocalPlayer.PlayerGui.Hotbar:FindFirstChild("Block") then
    for _, connection in next, getconnections(LocalPlayer.PlayerGui.Hotbar.Block.Activated) do
        if SwordsController and getfenv(connection.Function).script == SwordsController then
            ParryFunction = connection.Function
            break
        end
    end
end

local function IsValidParryArgs(args)
    return #args == 7 
        and type(args[2]) == "string" 
        and type(args[3]) == "number" 
        and typeof(args[4]) == "CFrame" 
        and type(args[5]) == "table" 
        and type(args[6]) == "table" 
        and type(args[7]) == "boolean"
end

local function HookRemote(remote)
    if not CapturedRemotes[remote] then
        if not HookedMetatables[getrawmetatable(remote)] then
            HookedMetatables[getrawmetatable(remote)] = true
            
            local metatable = getrawmetatable(remote)
            setreadonly(metatable, false)
            
            local originalIndex = metatable.__index
            metatable.__index = function(self, key)
                if key == "FireServer" and self:IsA("RemoteEvent") or key == "InvokeServer" and self:IsA("RemoteFunction") then
                    return function(obj, ...)
                        local args = {...}
                        if IsValidParryArgs(args) and not CapturedRemotes[self] then
                            CapturedRemotes[self] = args
                            CapturedParryKey = args[2]
                        end
                        return originalIndex(self, key)(obj, unpack(args))
                    end
                end
                return originalIndex(self, key)
            end
            
            setreadonly(metatable, true)
        end
    end
end

for _, child in pairs(ReplicatedStorage:GetChildren()) do
    if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
        HookRemote(child)
    end
end

ReplicatedStorage.ChildAdded:Connect(function(child)
    if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
        HookRemote(child)
    end
end)

local function UpdateDivisorMultiplier()
    ParryConfig.divisorMultiplier = 0.75 + (ParryConfig.accuracy - 1) * 0.0303
end

local function GetClosestPlayer()
    local closestPlayer = nil
    local closestDistance = math.huge
    
    for _, character in pairs(AliveFolder:GetChildren()) do
        if character ~= LocalPlayer.Character and character.PrimaryPart then
            local distance = LocalPlayer:DistanceFromCharacter(character.PrimaryPart.Position)
            if distance < closestDistance then
                closestDistance = distance
                closestPlayer = character
            end
        end
    end
    
    return closestPlayer
end

local function GetCurveCFrame()
    local camera = workspace.CurrentCamera
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if not hrp then 
        return camera.CFrame 
    end
    
    local closestPlayer = GetClosestPlayer()
    local targetHrp = closestPlayer and closestPlayer:FindFirstChild("HumanoidRootPart")
    local targetPosition = targetHrp and targetHrp.Position or hrp.Position + camera.CFrame.LookVector * 100
    
    local curveFunctions = {
        function()
            return camera.CFrame
        end,
        
        function()
            local direction = (targetPosition - hrp.Position).Unit
            local randomOffset
            local attempts = 0
            repeat
                randomOffset = Vector3.new(
                    math.random(-4000, 4000),
                    math.random(-4000, 4000),
                    math.random(-4000, 4000)
                )
                local newDirection = ((targetPosition + randomOffset) - hrp.Position).Unit
                local dotProduct = direction:Dot(newDirection)
                attempts = attempts + 1
            until dotProduct < 0.95 or attempts > 10
            return CFrame.new(hrp.Position, targetPosition + randomOffset)
        end,
        
        function()
            return CFrame.new(hrp.Position, targetPosition + Vector3.new(0, 5, 0))
        end,
        
        function()
            local backwardsDirection = (hrp.Position - targetPosition).Unit
            local backwardsPosition = (hrp.Position + backwardsDirection * 10000) + Vector3.new(0, 1000, 0)
            return CFrame.new(camera.CFrame.Position, backwardsPosition)
        end,
        
        function()
            return CFrame.new(hrp.Position, targetPosition + Vector3.new(0, -9e18, 0))
        end,
        
        function()
            return CFrame.new(hrp.Position, targetPosition + Vector3.new(0, 9e18, 0))
        end
    }
    
    return curveFunctions[ParryConfig.curveMode]()
end

local function ExecuteParry()
    if ParryConfig.parryCount > 10000 or not LocalPlayer.Character then 
        return 
    end
    
    local camera = workspace.CurrentCamera
    local success, mouseLocation = pcall(function()
        return UserInputService:GetMouseLocation()
    end)
    
    if not success then 
        return 
    end
    
    local mousePos = {mouseLocation.X, mouseLocation.Y}
    local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
    
    local playerScreenPositions = {}
    if AliveFolder then
        for _, character in pairs(AliveFolder:GetChildren()) do
            if character.PrimaryPart then
                local posSuccess, screenPos = pcall(function()
                    return camera:WorldToScreenPoint(character.PrimaryPart.Position)
                end)
                if posSuccess then
                    playerScreenPositions[character.Name] = screenPos
                end
            end
        end
    end
    
    local curveCFrame = GetCurveCFrame()
    
    if not ParryConfig.firstParryDone then
        for _, connection in pairs(getconnections(LocalPlayer.PlayerGui.Hotbar.Block.Activated)) do
            connection:Fire()
        end
        ParryConfig.firstParryDone = true
        return
    end
    
    local screenPosition
    if isMobile then
        local viewportSize = camera.ViewportSize
        screenPosition = {viewportSize.X / 2, viewportSize.Y / 2}
    else
        screenPosition = mousePos
    end
    
    for remote, originalArgs in pairs(CapturedRemotes) do
        local newArgs = {
            originalArgs[1],
            originalArgs[2],
            originalArgs[3],
            curveCFrame,
            playerScreenPositions,
            screenPosition,
            originalArgs[7]
        }
        
        pcall(function()
            if remote:IsA("RemoteEvent") then
                remote:FireServer(unpack(newArgs))
            elseif remote:IsA("RemoteFunction") then
                remote:InvokeServer(unpack(newArgs))
            end
        end)
    end
    
    if ParryConfig.parryCount > 10000 then 
        return 
    end
    
    ParryConfig.parryCount = ParryConfig.parryCount + 1
    task.delay(0.5, function()
        if ParryConfig.parryCount > 0 then
            ParryConfig.parryCount = ParryConfig.parryCount - 1
        end
    end)
end

local function ExecuteKeypress()
    if ParryConfig.parryCount > 10000 or not LocalPlayer.Character then 
        return 
    end
    
    if ParryFunction then
        ParryFunction()
    end
    
    if ParryConfig.parryCount > 10000 then 
        return 
    end
    
    ParryConfig.parryCount = ParryConfig.parryCount + 1
    task.delay(0.5, function()
        if ParryConfig.parryCount > 0 then
            ParryConfig.parryCount = ParryConfig.parryCount - 1
        end
    end)
end

local function PlayGrabAnimation()
    if not ParryConfig.playAnimation then 
        return 
    end
    
    local character = LocalPlayer.Character
    if not character then 
        return 
    end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
    
    if not humanoid or not animator then 
        return 
    end
    
    local equippedSword = character:GetAttribute("CurrentlyEquippedSword")
    if not equippedSword then 
        return 
    end
    
    local swordCollection = ReplicatedStorage.Shared.SwordAPI.Collection
    local grabAnimation = swordCollection.Default:FindFirstChild("GrabParry")
    
    if not grabAnimation then 
        return 
    end
    
    local swordData = ReplicatedStorage.Shared.ReplicatedInstances.Swords.GetSword:Invoke(equippedSword)
    if not swordData or not swordData.AnimationType then 
        return 
    end
    
    for _, animationFolder in pairs(swordCollection:GetChildren()) do
        if animationFolder.Name == swordData.AnimationType then
            if animationFolder:FindFirstChild("GrabParry") or animationFolder:FindFirstChild("Grab") then
                local animName = animationFolder:FindFirstChild("GrabParry") and "GrabParry" or "Grab"
                grabAnimation = animationFolder[animName]
            end
        end
    end
    
    local animationTrack = animator:LoadAnimation(grabAnimation)
    animationTrack.Priority = Enum.AnimationPriority.Action4
    animationTrack:Play()
end

local function ExecuteParryWithAnimation()
    PlayGrabAnimation()
    ExecuteParry()
end

local function Lerp(a, b, t)
    return a + (b - a) * t
end

local function GetBall()
    local ball = nil
    for _, child in pairs(BallsFolder:GetChildren()) do
        if child:GetAttribute("realBall") then
            child.CanCollide = false
            ball = child
            break
        end
    end
    return ball
end

local function IsBallCurved()
    local ball = GetBall()
    if not ball then 
        return false 
    end
    
    local zoomies = ball:FindFirstChild("zoomies")
    if not zoomies then 
        return false 
    end
    
    local velocity = zoomies.VectorVelocity
    local velocityDirection = velocity.Unit
    local toPlayerDirection = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Unit
    local dotProduct = toPlayerDirection:Dot(velocityDirection)
    
    local speed = velocity.Magnitude
    local speedThreshold = math.min(speed / 100, 40)
    
    local velocityDifference = (velocityDirection - velocity).Unit
    local directionSimilarity = toPlayerDirection:Dot(velocityDifference)
    local dotDifference = dotProduct - directionSimilarity
    
    local distance = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Magnitude
    local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    local dotThreshold = 0.5 - ping / 1000
    local reachTime = distance / speed - ping / 1000
    
    local distanceThreshold = (15 - math.min(distance / 1000, 15)) + speedThreshold
    local clampedDot = math.clamp(dotProduct, -1, 1)
    local radians = math.rad(math.asin(clampedDot))
    
    ParryConfig.lerpRadians = Lerp(ParryConfig.lerpRadians, radians, 0.8)
    
    if speed > 0 and reachTime > ping / 10 then
        distanceThreshold = math.max(distanceThreshold - 15, 15)
    end
    
    if distance < distanceThreshold then
        return false
    end
    
    if dotDifference < dotThreshold then
        return true
    end
    
    if ParryConfig.lerpRadians < 0.018 then
        ParryConfig.lastWarping = tick()
    end
    
    if tick() - ParryConfig.lastWarping < reachTime / 1.5 then
        return true
    end
    
    if tick() - ParryConfig.curvingTime < reachTime / 1.5 then
        return true
    end
    
    return dotProduct < dotThreshold
end

ReplicatedStorage.Remotes.DeathBall.OnClientEvent:Connect(function(_, active)
    ParryConfig.deathslashActive = active or false
end)

ReplicatedStorage.Remotes.InfinityBall.OnClientEvent:Connect(function(_, active)
    ParryConfig.infinityActive = active or false
end)

pcall(function()
    ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net["RE/TimeHoleActivate"].OnClientEvent:Connect(function(...)
        local args = {...}
        local target = args[1]
        if target == LocalPlayer or target == LocalPlayer.Name or (target and target.Name == LocalPlayer.Name) then
            ParryConfig.timeholeActive = true
        end
    end)
    
    ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net["RE/TimeHoleDeactivate"].OnClientEvent:Connect(function()
        ParryConfig.timeholeActive = false
    end)
    
    ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net["RE/SlashesOfFuryActivate"].OnClientEvent:Connect(function(...)
        local args = {...}
        local target = args[1]
        if target == LocalPlayer or target == LocalPlayer.Name or (target and target.Name == LocalPlayer.Name) then
            ParryConfig.slashesActive = true
            ParryConfig.slashesCount = 0
        end
    end)
    
    ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net["RE/SlashesOfFuryEnd"].OnClientEvent:Connect(function()
        ParryConfig.slashesActive = false
        ParryConfig.slashesCount = 0
    end)
end)

ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(function(_, source)
    if source.Parent and source.Parent ~= LocalPlayer.Character then
        if not AliveFolder or source.Parent.Parent ~= AliveFolder then
            return
        end
    end
    
    local closestPlayer = GetClosestPlayer()
    local ball = GetBall()
    
    if not ball or not closestPlayer then 
        return 
    end
    
    local playerDistance = (LocalPlayer.Character.PrimaryPart.Position - closestPlayer.PrimaryPart.Position).Magnitude
    local ballDistance = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Magnitude
    local ballDirection = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Unit
    local dotProduct = ballDirection:Dot(ball.AssemblyLinearVelocity.Unit)
    
    local isCurved = IsBallCurved()
    
    if playerDistance < 15 and ballDistance < 15 and dotProduct > -0.25 then
        if isCurved then
            ExecuteParryWithAnimation()
        end
    end
end)

RunService.PreSimulation:Connect(function()
    if not ParryConfig.autoParryEnabled or not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then
        return
    end
    
    local ball = GetBall()
    if not ball then 
        return 
    end
    
    local zoomies = ball:FindFirstChild("zoomies")
    if not zoomies then 
        return 
    end
    
    ball:GetAttributeChangedSignal("target"):Once(function()
        ParryConfig.hasParried = false
    end)
    
    if ParryConfig.hasParried then 
        return 
    end
    
    local target = ball:GetAttribute("target")
    local velocity = zoomies.VectorVelocity
    local distance = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Magnitude
    
    local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 10
    local pingThreshold = math.clamp(ping / 10, 5, 17)
    
    local speed = velocity.Magnitude
    local cappedSpeedDiff = math.min(math.max(speed - 9.5, 0), 650)
    local speedDivisor = (2.4 + cappedSpeedDiff * 0.002) * ParryConfig.divisorMultiplier
    local parryAccuracy = pingThreshold + math.max(speed / speedDivisor, 9.5)
    
    local isCurved = IsBallCurved()
    
    if ball:FindFirstChild("AeroDynamicSlashVFX") then
        ball.AeroDynamicSlashVFX:Destroy()
        ParryConfig.tornadoTime = tick()
    end
    
    if RuntimeFolder:FindFirstChild("Tornado") then
        local tornadoTime = RuntimeFolder.Tornado:GetAttribute("TornadoTime") or 1
        if tick() - ParryConfig.tornadoTime < tornadoTime + 0.314159 then
            return
        end
    end
    
    local mainBall = GetBall()
    if mainBall and mainBall:GetAttribute("target") == LocalPlayer.Name and isCurved then
        return
    end
    
    if ball:FindFirstChild("ComboCounter") then
        return
    end
    
    if LocalPlayer.Character.PrimaryPart:FindFirstChild("SingularityCape") then
        return
    end
    
    if ParryConfig.infinityActive then
        return
    end
    
    if ParryConfig.deathslashActive then
        return
    end
    
    if ParryConfig.timeholeActive then
        return
    end
    
    if ParryConfig.slashesActive then
        return
    end
    
    if target == LocalPlayer.Name and distance <= parryAccuracy then
        ExecuteParryWithAnimation()
        ParryConfig.hasParried = true
        
        local startTime = tick()
        repeat
            RunService.Stepped:Wait()
        until tick() - startTime >= 1 or not ParryConfig.hasParried
        
        ParryConfig.hasParried = false
    end
end)

local function TriggerBotParry(ball)
    if ParryConfig.triggerbotParrying or ParryConfig.triggerbotParries > 10000 then
        return
    end
    
    if LocalPlayer.Character and LocalPlayer.Character.PrimaryPart and LocalPlayer.Character.PrimaryPart:FindFirstChild("SingularityCape") then
        return
    end
    
    ParryConfig.triggerbotParrying = true
    ParryConfig.triggerbotParries = ParryConfig.triggerbotParries + 1
    
    ExecuteParryWithAnimation()
    
    task.delay(0.5, function()
        if ParryConfig.triggerbotParries > 0 then
            ParryConfig.triggerbotParries = ParryConfig.triggerbotParries - 1
        end
    end)
    
    local connection
    connection = ball:GetAttributeChangedSignal("target"):Once(function()
        ParryConfig.triggerbotParrying = false
        if connection then
            connection:Disconnect()
        end
    end)
    
    task.spawn(function()
        local startTime = tick()
        repeat
            RunService.Heartbeat:Wait()
        until tick() - startTime >= 1 or not ParryConfig.triggerbotParrying
        ParryConfig.triggerbotParrying = false
    end)
end

RunService.Heartbeat:Connect(function()
    if not ParryConfig.triggerbotEnabled then 
        return 
    end
    
    if LocalPlayer.Character and LocalPlayer.Character.PrimaryPart and LocalPlayer.Character.PrimaryPart:FindFirstChild("SingularityCape") then
        return
    end
    
    for _, ball in pairs(BallsFolder:GetChildren()) do
        if ball:IsA("BasePart") and ball:GetAttribute("target") == LocalPlayer.Name then
            TriggerBotParry(ball)
            break
        end
    end
end)

RunService.Heartbeat:Connect(function(deltaTime)
    if not ParryConfig.manualSpamEnabled then 
        return 
    end
    
    if not LocalPlayer.Character or LocalPlayer.Character.Parent ~= AliveFolder then
        return
    end
    
    ParryConfig.spamAccumulator = ParryConfig.spamAccumulator + deltaTime
    local spamInterval = 1 / ParryConfig.spamRate
    
    if ParryConfig.spamAccumulator >= spamInterval then
        ParryConfig.spamAccumulator = 0
        ExecuteParry()
    end
end)

RunService.PreSimulation:Connect(function()
    if not ParryConfig.autoSpamEnabled then 
        return 
    end
    
    local ball = GetBall()
    if not ball then 
        return 
    end
    
    if ParryConfig.slashesActive then 
        return 
    end
    
    local zoomies = ball:FindFirstChild("zoomies")
    if not zoomies then 
        return 
    end
    
    local closestPlayer = GetClosestPlayer()
    if not closestPlayer or not closestPlayer.PrimaryPart then 
        return 
    end
    
    local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    local pingThreshold = math.clamp(ping / 10, 1, 16)
    local target = ball:GetAttribute("target")
    
    local playerDistance = (LocalPlayer.Character.PrimaryPart.Position - closestPlayer.PrimaryPart.Position).Magnitude
    local ballDistance = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Magnitude
    local speed = zoomies.VectorVelocity.Magnitude
    
    local maxSpamDistance = pingThreshold + math.min(speed / 6, 255)
    
    if playerDistance > maxSpamDistance or ballDistance > maxSpamDistance then
        return
    end
    
    local isPulsed = LocalPlayer.Character:GetAttribute("Pulsed")
    if isPulsed then 
        return 
    end
    
    if target == LocalPlayer.Name and playerDistance > 30 and ballDistance > 30 then
        return
    end
    
    if ballDistance <= maxSpamDistance and ParryConfig.parryCount > ParryConfig.spamThreshold then
        ExecuteParry()
    end
end)

local function ClaimPlaytimeRewards()
    for i = 1, 6 do
        pcall(function()
            ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net["RF/ClaimPlaytimeReward"]:InvokeServer(i)
        end)
    end
end

local function OpenExplosionCrate()
    pcall(function()
        ReplicatedStorage.Remote.RemoteFunction:InvokeServer("PromptPurchaseCrate", workspace.Spawn.Crates.NormalExplosionCrate)
    end)
end

local function OpenSwordCrate()
    pcall(function()
        ReplicatedStorage.Remote.RemoteFunction:InvokeServer("PromptPurchaseCrate", workspace.Spawn.Crates.NormalSwordCrate)
    end)
end

local function RemoveSlashEffect(descendant)
    if not UtilityConfig.antiSlashEffect then 
        return 
    end
    
    if string.find(string.lower(descendant.ClassName), "particleemitter") then
        pcall(function()
            descendant.Lifetime = NumberRange.new(0)
        end)
    end
end

workspace.DescendantAdded:Connect(RemoveSlashEffect)

RunService.PreRender:Connect(function()
    if not ParryConfig.lookAtBall then 
        return 
    end
    
    local ball = GetBall()
    if not ball then 
        return 
    end
    
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local camera = workspace.CurrentCamera
    
    if ParryConfig.lookAtType == "Character" and hrp then
        local lookPosition = Vector3.new(ball.Position.X, hrp.Position.Y, ball.Position.Z)
        hrp.CFrame = CFrame.lookAt(hrp.Position, lookPosition)
    elseif ParryConfig.lookAtType == "Camera" then
        camera.CFrame = CFrame.lookAt(camera.CFrame.Position, ball.Position)
    end
end)

RunService.PostSimulation:Connect(function()
    if ParryConfig.rainbowAmbient then
        Lighting.Ambient = Color3.fromHSV(tick() % 5 / 5, 1, 1)
    end
    
    if ParryConfig.rainbowFog then
        Lighting.FogColor = Color3.fromHSV(tick() % 5 / 5, 1, 1)
    end
end)

RunService.PostSimulation:Connect(function()
    if UtilityConfig.autoClaimRewards then 
        ClaimPlaytimeRewards() 
    end
    
    if UtilityConfig.autoSwordCrate then 
        OpenSwordCrate() 
    end
    
    if UtilityConfig.autoExplosionCrate then 
        OpenExplosionCrate() 
    end
end)

local VisualizerPart1 = Instance.new("Part")
local VisualizerPart2 = Instance.new("Part")
local VisualizerPart3 = Instance.new("Part")
local CircleAdornee = Instance.new("Part", workspace.CurrentCamera)
local CircleAdornment1 = Instance.new("CylinderHandleAdornment", game.CoreGui)
local CircleAdornment2 = Instance.new("CylinderHandleAdornment", game.CoreGui)
local CircleAdornment3 = Instance.new("CylinderHandleAdornment", game.CoreGui)

VisualizerPart1.CanCollide = false
VisualizerPart2.CanCollide = false
VisualizerPart3.CanCollide = false
VisualizerPart1.Anchored = false
VisualizerPart2.Anchored = false
VisualizerPart3.Anchored = false
VisualizerPart1.Parent = nil
VisualizerPart2.Parent = nil
VisualizerPart3.Parent = nil

CircleAdornee.Transparency = 1
CircleAdornee.CanCollide = false
CircleAdornee.Anchored = false
CircleAdornee.Size = Vector3.new(1, 1, 1)

CircleAdornment1.Visible = false
CircleAdornment2.Visible = false
CircleAdornment3.Visible = false

RunService.PostSimulation:Connect(function()
    local ball = GetBall()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if not ball or not hrp then
        VisualizerPart1.Parent = nil
        VisualizerPart2.Parent = nil
        VisualizerPart3.Parent = nil
        CircleAdornment1.Visible = false
        CircleAdornment2.Visible = false
        CircleAdornment3.Visible = false
        return
    end
    
    if not ParryConfig.autoParryEnabled then 
        return 
    end
    
    local hipHeight = LocalPlayer.Character.Humanoid.HipHeight + VisualizerSettings.circleHeight
    local ballDistance = (ball.Position - workspace.CurrentCamera.Focus.Position).Magnitude
    local rainbowColor = Color3.fromHSV(tick() % 5 / 5, 1, 1)
    
    if VisualizerToggles.ballVisualizer then
        VisualizerPart1.Shape = VisualizerSettings.shape
        VisualizerPart1.Material = VisualizerSettings.material
        VisualizerPart1.Transparency = VisualizerSettings.transparency
        VisualizerPart1.Size = Vector3.new(ParryConfig.distanceToHit, ParryConfig.distanceToHit, ParryConfig.distanceToHit)
        VisualizerPart1.Color = ParryConfig.rainbowVisualizer and rainbowColor or VisualizerSettings.color
        VisualizerPart1.CFrame = hrp.CFrame
        VisualizerPart1.Parent = hrp
    else
        VisualizerPart1.Parent = nil
    end
    
    if VisualizerToggles.clashVisualizer then
        VisualizerPart2.Shape = VisualizerSettings.shape
        VisualizerPart2.Material = VisualizerSettings.material
        VisualizerPart2.Transparency = VisualizerSettings.transparency
        VisualizerPart2.Size = Vector3.new(VisualizerSettings.clashDistance, VisualizerSettings.clashDistance, VisualizerSettings.clashDistance)
        VisualizerPart2.Color = ParryConfig.rainbowVisualizer and rainbowColor or VisualizerSettings.color
        VisualizerPart2.CFrame = hrp.CFrame
        VisualizerPart2.Parent = workspace
    else
        VisualizerPart2.Parent = nil
    end
    
    if VisualizerToggles.distanceVisualizer then
        VisualizerPart3.Shape = VisualizerSettings.shape
        VisualizerPart3.Material = VisualizerSettings.material
        VisualizerPart3.Transparency = VisualizerSettings.transparency
        VisualizerPart3.Size = Vector3.new(ballDistance, ballDistance, ballDistance)
        VisualizerPart3.Color = ParryConfig.rainbowVisualizer and rainbowColor or VisualizerSettings.color
        VisualizerPart3.CFrame = hrp.CFrame
        VisualizerPart3.Parent = hrp
    else
        VisualizerPart3.Parent = nil
    end
    
    if VisualizerToggles.circleBallVisualizer or VisualizerToggles.circleClashVisualizer or VisualizerToggles.circleDistanceVisualizer then
        CircleAdornee.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y - hipHeight, hrp.Position.Z)
    end
    
    local circleColor = ParryConfig.rainbowCircle and rainbowColor or VisualizerSettings.circleColor
    
    if VisualizerToggles.circleBallVisualizer then
        CircleAdornment1.CFrame = CFrame.fromOrientation(math.rad(90), 0, 0)
        CircleAdornment1.Adornee = CircleAdornee
        CircleAdornment1.Radius = ParryConfig.distanceToHit
        CircleAdornment1.InnerRadius = ParryConfig.distanceToHit
        CircleAdornment1.Height = hipHeight
        CircleAdornment1.Color3 = circleColor
        CircleAdornment1.Visible = true
    else
        CircleAdornment1.Visible = false
    end
    
    if VisualizerToggles.circleClashVisualizer then
        CircleAdornment2.CFrame = CFrame.fromOrientation(math.rad(90), 0, 0)
        CircleAdornment2.Adornee = CircleAdornee
        CircleAdornment2.Radius = VisualizerSettings.clashDistance
        CircleAdornment2.InnerRadius = VisualizerSettings.clashDistance
        CircleAdornment2.Height = hipHeight
        CircleAdornment2.Color3 = circleColor
        CircleAdornment2.Visible = true
    else
        CircleAdornment2.Visible = false
    end
    
    if VisualizerToggles.circleDistanceVisualizer then
        CircleAdornment3.CFrame = CFrame.fromOrientation(math.rad(90), 0, 0)
        CircleAdornment3.Adornee = CircleAdornee
        CircleAdornment3.Radius = ballDistance
        CircleAdornment3.InnerRadius = ballDistance
        CircleAdornment3.Height = hipHeight
        CircleAdornment3.Color3 = circleColor
        CircleAdornment3.Visible = true
    else
        CircleAdornment3.Visible = false
    end
end)

local Window = Library:CreateWindow({
    Title = "Invictus",
    Footer = "Alpha Build v0.1 | invictus uwu",
    Icon = 85451000785501,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = {
    Home = Window:AddTab("Home", "home"),
    Main = Window:AddTab("Main", "swords"),
    Spam = Window:AddTab("Spam", "zap"),
    Visuals = Window:AddTab("Visuals", "eye"),
    Utilities = Window:AddTab("Utilities", "wrench"),
    World = Window:AddTab("World", "globe-2"),
    Settings = Window:AddTab("Settings", "settings"),
}

local HomeLeftGroup = Tabs.Home:AddLeftGroupbox("Welcome")
HomeLeftGroup:AddLabel("yo " .. LocalPlayer.DisplayName .. "!", true)
HomeLeftGroup:AddLabel("this is alpha build, expect bugs!", true)
HomeLeftGroup:AddLabel("some features may not work properly", true)
HomeLeftGroup:AddDivider()
HomeLeftGroup:AddButton({
    Text = "Copy Discord",
    Func = function()
        setclipboard("https://discord.gg/nbPHzKzafN")
        Library:Notify({
            Title = "Invictus",
            Description = "copied to clipboard!",
            Time = 2
        })
    end,
})

local HomeRightGroup = Tabs.Home:AddRightGroupbox("Credits")
HomeRightGroup:AddLabel("made by Entropy", true)
HomeRightGroup:AddLabel("discord: 4entropy3", true)
HomeRightGroup:AddDivider()
HomeRightGroup:AddLabel("ALPHA BUILD - NOT FINISHED", true)

local MainLeftGroup = Tabs.Main:AddLeftGroupbox("Auto Parry")

MainLeftGroup:AddToggle("autoParry", {
    Text = "Auto Parry",
    Default = true,
    Risky = true,
})

Toggles.autoParry:OnChanged(function()
    ParryConfig.autoParryEnabled = Toggles.autoParry.Value
end)

MainLeftGroup:AddSlider("accuracy", {
    Text = "Parry Accuracy",
    Default = 50,
    Min = 1,
    Max = 100,
    Rounding = 0,
})

Options.accuracy:OnChanged(function()
    ParryConfig.accuracy = Options.accuracy.Value
    UpdateDivisorMultiplier()
end)

MainLeftGroup:AddSlider("distanceToHit", {
    Text = "Distance To Hit",
    Default = 10,
    Min = 5,
    Max = 25,
    Rounding = 1,
})

Options.distanceToHit:OnChanged(function()
    ParryConfig.distanceToHit = Options.distanceToHit.Value
end)

MainLeftGroup:AddSlider("pingOffset", {
    Text = "Ping Offset",
    Default = 0,
    Min = 0,
    Max = 15,
    Rounding = 1,
})

Options.pingOffset:OnChanged(function()
    ParryConfig.pingOffset = Options.pingOffset.Value
end)

MainLeftGroup:AddToggle("playAnimation", {
    Text = "Play Animation",
    Default = false,
})

Toggles.playAnimation:OnChanged(function()
    ParryConfig.playAnimation = Toggles.playAnimation.Value
end)

MainLeftGroup:AddDropdown("curveType", {
    Values = CurveTypes,
    Default = "Camera",
    Text = "Curve Type",
})

Options.curveType:OnChanged(function()
    for index, curveName in ipairs(CurveTypes) do
        if curveName == Options.curveType.Value then
            ParryConfig.curveMode = index
            break
        end
    end
end)

local MainRightGroup = Tabs.Main:AddRightGroupbox("Other Features")

MainRightGroup:AddToggle("triggerbot", {
    Text = "Triggerbot",
    Default = false,
    Risky = true,
})

Toggles.triggerbot:OnChanged(function()
    ParryConfig.triggerbotEnabled = Toggles.triggerbot.Value
end)

MainRightGroup:AddToggle("lookAtBall", {
    Text = "Look At Ball",
    Default = false,
})

Toggles.lookAtBall:OnChanged(function()
    ParryConfig.lookAtBall = Toggles.lookAtBall.Value
end)

MainRightGroup:AddDropdown("lookAtType", {
    Values = {"Camera", "Character"},
    Default = "Camera",
    Text = "Look Type",
})

Options.lookAtType:OnChanged(function()
    ParryConfig.lookAtType = Options.lookAtType.Value
end)

local SpamLeftGroup = Tabs.Spam:AddLeftGroupbox("Manual Spam")

SpamLeftGroup:AddToggle("manualSpam", {
    Text = "Manual Spam",
    Default = false,
    Risky = true,
})

Toggles.manualSpam:OnChanged(function()
    ParryConfig.manualSpamEnabled = Toggles.manualSpam.Value
end)

SpamLeftGroup:AddSlider("spamRate", {
    Text = "Spam Rate",
    Default = 240,
    Min = 60,
    Max = 5000,
    Rounding = 0,
})

Options.spamRate:OnChanged(function()
    ParryConfig.spamRate = Options.spamRate.Value
end)

local SpamRightGroup = Tabs.Spam:AddRightGroupbox("Auto Spam")

SpamRightGroup:AddToggle("autoSpam", {
    Text = "Auto Spam",
    Default = false,
    Risky = true,
})

Toggles.autoSpam:OnChanged(function()
    ParryConfig.autoSpamEnabled = Toggles.autoSpam.Value
end)

SpamRightGroup:AddSlider("spamThreshold", {
    Text = "Parry Threshold",
    Default = 1.5,
    Min = 1,
    Max = 5,
    Rounding = 1,
})

Options.spamThreshold:OnChanged(function()
    ParryConfig.spamThreshold = Options.spamThreshold.Value
end)

local VisualsLeftGroup = Tabs.Visuals:AddLeftGroupbox("Ball Visualizers")

VisualsLeftGroup:AddToggle("ballVisualizer", {
    Text = "Distance To Hit",
    Default = true,
})

Toggles.ballVisualizer:OnChanged(function()
    VisualizerToggles.ballVisualizer = Toggles.ballVisualizer.Value
end)

VisualsLeftGroup:AddToggle("clashVisualizer", {
    Text = "Clash Range",
    Default = true,
})

Toggles.clashVisualizer:OnChanged(function()
    VisualizerToggles.clashVisualizer = Toggles.clashVisualizer.Value
end)

VisualsLeftGroup:AddToggle("distanceVisualizer", {
    Text = "Ball Distance",
    Default = true,
})

Toggles.distanceVisualizer:OnChanged(function()
    VisualizerToggles.distanceVisualizer = Toggles.distanceVisualizer.Value
end)

local VisualsRightGroup = Tabs.Visuals:AddRightGroupbox("Circle Visualizers")

VisualsRightGroup:AddToggle("circleBallVisualizer", {
    Text = "Distance To Hit",
    Default = true,
})

Toggles.circleBallVisualizer:OnChanged(function()
    VisualizerToggles.circleBallVisualizer = Toggles.circleBallVisualizer.Value
end)

VisualsRightGroup:AddToggle("circleClashVisualizer", {
    Text = "Clash Range",
    Default = true,
})

Toggles.circleClashVisualizer:OnChanged(function()
    VisualizerToggles.circleClashVisualizer = Toggles.circleClashVisualizer.Value
end)

VisualsRightGroup:AddToggle("circleDistanceVisualizer", {
    Text = "Ball Distance",
    Default = true,
})

Toggles.circleDistanceVisualizer:OnChanged(function()
    VisualizerToggles.circleDistanceVisualizer = Toggles.circleDistanceVisualizer.Value
end)

local VisualsSettingsGroup = Tabs.Visuals:AddLeftGroupbox("Visualizer Settings")

VisualsSettingsGroup:AddDropdown("visualizerShape", {
    Values = {"Ball", "Block", "Cylinder", "Wedge", "CornerWedge"},
    Default = "Ball",
    Text = "Shape",
})

Options.visualizerShape:OnChanged(function()
    VisualizerSettings.shape = Options.visualizerShape.Value
end)

VisualsSettingsGroup:AddDropdown("visualizerMaterial", {
    Values = {"Plastic", "ForceField", "Glass", "Neon", "SmoothPlastic", "Metal"},
    Default = "ForceField",
    Text = "Material",
})

Options.visualizerMaterial:OnChanged(function()
    VisualizerSettings.material = Options.visualizerMaterial.Value
end)

VisualsSettingsGroup:AddLabel("Ball Color"):AddColorPicker("visualizerColor", {
    Default = Color3.fromRGB(255, 255, 255),
})

Options.visualizerColor:OnChanged(function()
    VisualizerSettings.color = Options.visualizerColor.Value
end)

VisualsSettingsGroup:AddLabel("Circle Color"):AddColorPicker("circleVisualizerColor", {
    Default = Color3.fromRGB(255, 255, 255),
})

Options.circleVisualizerColor:OnChanged(function()
    VisualizerSettings.circleColor = Options.circleVisualizerColor.Value
end)

VisualsSettingsGroup:AddSlider("visualizerTransparency", {
    Text = "Transparency",
    Default = 0,
    Min = 0,
    Max = 1,
    Rounding = 1,
})

Options.visualizerTransparency:OnChanged(function()
    VisualizerSettings.transparency = Options.visualizerTransparency.Value
end)

VisualsSettingsGroup:AddSlider("circleHeight", {
    Text = "Circle Height",
    Default = 0.5,
    Min = 0.5,
    Max = 5,
    Rounding = 1,
})

Options.circleHeight:OnChanged(function()
    VisualizerSettings.circleHeight = Options.circleHeight.Value
end)

VisualsSettingsGroup:AddSlider("clashRangeSize", {
    Text = "Clash Range Size",
    Default = 30,
    Min = 10,
    Max = 100,
    Rounding = 1,
})

Options.clashRangeSize:OnChanged(function()
    VisualizerSettings.clashDistance = Options.clashRangeSize.Value
end)

local VisualsRainbowGroup = Tabs.Visuals:AddRightGroupbox("Rainbow Effects")

VisualsRainbowGroup:AddToggle("rainbowBallVisualizer", {
    Text = "Rainbow Ball Visualizer",
    Default = false,
})

Toggles.rainbowBallVisualizer:OnChanged(function()
    ParryConfig.rainbowVisualizer = Toggles.rainbowBallVisualizer.Value
end)

VisualsRainbowGroup:AddToggle("rainbowCircleVisualizer", {
    Text = "Rainbow Circle Visualizer",
    Default = false,
})

Toggles.rainbowCircleVisualizer:OnChanged(function()
    ParryConfig.rainbowCircle = Toggles.rainbowCircleVisualizer.Value
end)

local UtilitiesLeftGroup = Tabs.Utilities:AddLeftGroupbox("Utilities")

UtilitiesLeftGroup:AddToggle("antiSlashEffect", {
    Text = "Anti Slash Effect",
    Default = false,
})

Toggles.antiSlashEffect:OnChanged(function()
    UtilityConfig.antiSlashEffect = Toggles.antiSlashEffect.Value
end)

local UtilitiesRightGroup = Tabs.Utilities:AddRightGroupbox("Auto Features")

UtilitiesRightGroup:AddToggle("autoClaimRewards", {
    Text = "Auto Claim Rewards",
    Default = false,
    Risky = true,
})

Toggles.autoClaimRewards:OnChanged(function()
    UtilityConfig.autoClaimRewards = Toggles.autoClaimRewards.Value
end)

UtilitiesRightGroup:AddToggle("autoExplosionCrate", {
    Text = "Auto Explosion Crate",
    Default = false,
    Risky = true,
})

Toggles.autoExplosionCrate:OnChanged(function()
    UtilityConfig.autoExplosionCrate = Toggles.autoExplosionCrate.Value
end)

UtilitiesRightGroup:AddToggle("autoSwordCrate", {
    Text = "Auto Sword Crate",
    Default = false,
    Risky = true,
})

Toggles.autoSwordCrate:OnChanged(function()
    UtilityConfig.autoSwordCrate = Toggles.autoSwordCrate.Value
end)

local WorldLeftGroup = Tabs.World:AddLeftGroupbox("World Settings")

WorldLeftGroup:AddButton({
    Text = "Reset World",
    Func = function()
        Lighting.Ambient = OriginalAmbient
        Lighting.FogColor = OriginalFogColor
        Lighting.ClockTime = OriginalClockTime
        Library:Notify({
            Title = "Invictus",
            Description = "world settings reset!",
            Time = 2
        })
    end,
})

WorldLeftGroup:AddLabel("Ambient Color"):AddColorPicker("ambientColor", {
    Default = Lighting.Ambient,
})
