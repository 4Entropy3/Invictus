if _G.InvictusLoaded then
    warn("Invictus already loaded.")
    return
end
_G.InvictusLoaded = true

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Window = Library:CreateWindow({
    Title = "Blade Ball - Invictus",
    Footer = "The best keyless script | discord.gg/nbPHzKzafN",
    Icon = 85451000785501,
    NotifySide = "Right",
    ShowCustomCursor = true,
    Acrylic = false,
})

local Tabs = {
    Blatant = Window:AddTab("Blatant", "zap"),
    Player = Window:AddTab("Player", "user"),
    Visuals = Window:AddTab("Visuals", "eye"),
    World = Window:AddTab("World", "globe"),
    Settings = Window:AddTab("Settings", "sliders"),
}

local Connections = {}
local Tornado_Time = tick()
local Speed_Divisor_Multiplier = 1.1
local LobbyAP_Speed_Divisor_Multiplier = 1.1
local Selected_Parry_Type = "Camera"
local Parried = false
local Last_Parry = 0
local Parries = 0
local Infinity = false
local Training_Parried = false
local Closest_Entity = nil
local Lerp_Radians = 0
local Last_Warping = tick()
local Curving = tick()
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

local HashOne, HashTwo, HashThree
local ShouldPlayerJump, MainRemote, GetOpponentPosition
local Parry_Key

local function SafeInit()
    pcall(function()
        local PropertyChangeOrder = {}
        
        for _, Value in next, getgc() do
            if typeof(Value) == "function" and islclosure(Value) then
                local info = debug.info(Value, "s")
                if info and info:find("SwordsController") then
                    local line = debug.info(Value, "l")
                    if line == 276 then
                        HashOne = getconstant(Value, 62)
                        HashTwo = getconstant(Value, 64)
                        HashThree = getconstant(Value, 65)
                    end
                end
            end
        end
        
        for _, Object in next, game:GetDescendants() do
            if Object:IsA("RemoteEvent") and Object.Name:find("\n") then
                Object.Changed:Once(function()
                    table.insert(PropertyChangeOrder, Object)
                end)
            end
        end
        
        local startTime = tick()
        repeat task.wait() until #PropertyChangeOrder >= 3 or tick() - startTime > 5
        
        if #PropertyChangeOrder >= 3 then
            ShouldPlayerJump = PropertyChangeOrder[1]
            MainRemote = PropertyChangeOrder[2]
            GetOpponentPosition = PropertyChangeOrder[3]
        end
        
        for _, v in pairs(getconnections(Player.PlayerGui.Hotbar.Block.Activated)) do
            if v and v.Function and not iscclosure(v.Function) then
                for _, v2 in pairs(getupvalues(v.Function)) do
                    if type(v2) == "function" then
                        Parry_Key = getupvalue(getupvalue(v2, 2), 17)
                    end
                end
            end
        end
    end)
end

task.spawn(SafeInit)

local function Parry(...)
    if ShouldPlayerJump and MainRemote and GetOpponentPosition and Parry_Key then
        ShouldPlayerJump:FireServer(HashOne, Parry_Key, ...)
        MainRemote:FireServer(HashTwo, Parry_Key, ...)
        GetOpponentPosition:FireServer(HashThree, Parry_Key, ...)
    end
end

local function GetBall()
    for _, Ball in pairs(workspace.Balls:GetChildren()) do
        if Ball:GetAttribute("realBall") then
            Ball.CanCollide = false
            return Ball
        end
    end
end

local function GetBalls()
    local BallsTable = {}
    for _, Ball in pairs(workspace.Balls:GetChildren()) do
        if Ball:GetAttribute("realBall") then
            Ball.CanCollide = false
            table.insert(BallsTable, Ball)
        end
    end
    return BallsTable
end

local function GetLobbyBall()
    for _, Ball in pairs(workspace.TrainingBalls:GetChildren()) do
        if Ball:GetAttribute("realBall") then
            return Ball
        end
    end
end

local function GetClosestPlayer()
    local MaxDist = math.huge
    local Found = nil
    for _, Entity in pairs(workspace.Alive:GetChildren()) do
        if tostring(Entity) ~= tostring(Player) and Entity.PrimaryPart then
            local Dist = Player:DistanceFromCharacter(Entity.PrimaryPart.Position)
            if Dist < MaxDist then
                MaxDist = Dist
                Found = Entity
            end
        end
    end
    Closest_Entity = Found
    return Found
end

local function IsCurved()
    local Ball = GetBall()
    if not Ball then return false end
    local Zoomies = Ball:FindFirstChild("zoomies")
    if not Zoomies then return false end
    
    local Velocity = Zoomies.VectorVelocity
    local BallDir = Velocity.Unit
    local Direction = (Player.Character.PrimaryPart.Position - Ball.Position).Unit
    local Dot = Direction:Dot(BallDir)
    local Speed = Velocity.Magnitude
    local Distance = (Player.Character.PrimaryPart.Position - Ball.Position).Magnitude
    local Ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
    local DotThreshold = 0.5 - (Ping / 1000)
    local ReachTime = Distance / Speed - (Ping / 1000)
    local BallDistThreshold = 15 - math.min(Distance / 1000, 15) + math.min(Speed / 100, 40)
    local ClampedDot = math.clamp(Dot, -1, 1)
    local Radians = math.rad(math.asin(ClampedDot))
    
    Lerp_Radians = Lerp_Radians + (Radians - Lerp_Radians) * 0.8
    
    if Speed > 100 and ReachTime > Ping / 10 then
        BallDistThreshold = math.max(BallDistThreshold - 15, 15)
    end
    if Distance < BallDistThreshold then return false end
    if Lerp_Radians < 0.018 then Last_Warping = tick() end
    if (tick() - Last_Warping) < (ReachTime / 1.5) then return true end
    if (tick() - Curving) < (ReachTime / 1.5) then return true end
    
    return Dot < DotThreshold
end

local function GetParryData(ParryType)
    GetClosestPlayer()
    local Events = {}
    local Camera = workspace.CurrentCamera
    local MouseLoc
    
    if isMobile then
        MouseLoc = {Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2}
    else
        local ML = UserInputService:GetMouseLocation()
        MouseLoc = {ML.X, ML.Y}
    end
    
    for _, v in pairs(workspace.Alive:GetChildren()) do
        if v ~= Player.Character and v.PrimaryPart then
            local screenPos = Camera:WorldToScreenPoint(v.PrimaryPart.Position)
            Events[tostring(v)] = screenPos
        end
    end
    
    if ParryType == "Camera" then
        return {0, Camera.CFrame, Events, MouseLoc}
    elseif ParryType == "Backwards" then
        local BackDir = Camera.CFrame.LookVector * -10000
        BackDir = Vector3.new(BackDir.X, 0, BackDir.Z)
        return {0, CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + BackDir), Events, MouseLoc}
    elseif ParryType == "Straight" and Closest_Entity then
        return {0, CFrame.new(Player.Character.PrimaryPart.Position, Closest_Entity.PrimaryPart.Position), Events, MouseLoc}
    elseif ParryType == "Random" then
        return {0, CFrame.new(Camera.CFrame.Position, Vector3.new(math.random(-4000, 4000), math.random(-4000, 4000), math.random(-4000, 4000))), Events, MouseLoc}
    elseif ParryType == "High" then
        return {0, CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Camera.CFrame.UpVector * 10000), Events, MouseLoc}
    elseif ParryType == "Left" then
        return {0, CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position - Camera.CFrame.RightVector * 10000), Events, MouseLoc}
    elseif ParryType == "Right" then
        return {0, CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Camera.CFrame.RightVector * 10000), Events, MouseLoc}
    end
    
    return {0, Camera.CFrame, Events, MouseLoc}
end

local function DoParry(ParryType)
    local Data = GetParryData(ParryType)
    
    if getgenv().UseKeypress then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, nil)
        task.wait()
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, nil)
    else
        Parry(Data[1], Data[2], Data[3], Data[4])
    end
    
    if Parries <= 7 then
        Parries = Parries + 1
        task.delay(0.5, function()
            if Parries > 0 then Parries = Parries - 1 end
        end)
    end
end

pcall(function()
    ReplicatedStorage.Remotes.InfinityBall.OnClientEvent:Connect(function(a, b)
        Infinity = b == true
    end)
end)

local Runtime = workspace:FindFirstChild("Runtime")

local BlatantLeft = Tabs.Blatant:AddLeftGroupbox("Auto Parry", "zap")

BlatantLeft:AddToggle("AutoParryToggle", {
    Text = "Auto Parry",
    Default = false,
    Callback = function(Value)
        if Value then
            Connections["AutoParry"] = RunService.PreSimulation:Connect(function()
                if not Player.Character or not Player.Character.PrimaryPart then return end
                
                local BallsList = GetBalls()
                
                for _, Ball in pairs(BallsList) do
                    if not Ball then continue end
                    
                    local Zoomies = Ball:FindFirstChild("zoomies")
                    if not Zoomies then continue end
                    
                    Ball:GetAttributeChangedSignal("target"):Once(function()
                        Parried = false
                    end)
                    
                    if Parried then continue end
                    
                    local BallTarget = Ball:GetAttribute("target")
                    local Velocity = Zoomies.VectorVelocity
                    local Distance = (Player.Character.PrimaryPart.Position - Ball.Position).Magnitude
                    local Ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() / 10
                    local PingThreshold = math.clamp(Ping / 10, 5, 17)
                    local Speed = Velocity.Magnitude
                    
                    local cappedDiff = math.min(math.max(Speed - 9.5, 0), 650)
                    local divisorBase = 2.4 + cappedDiff * 0.002
                    local multiplier = Speed_Divisor_Multiplier
                    
                    if getgenv().RandomAccuracy then
                        multiplier = Speed < 200 and (0.7 + (math.random(40, 100) - 1) * (0.35 / 99)) or (0.7 + (math.random(1, 100) - 1) * (0.35 / 99))
                    end
                    
                    local ParryAccuracy = PingThreshold + math.max(Speed / (divisorBase * multiplier), 9.5)
                    
                    if Ball:FindFirstChild("AeroDynamicSlashVFX") then
                        Debris:AddItem(Ball.AeroDynamicSlashVFX, 0)
                        Tornado_Time = tick()
                    end
                    
                    if Runtime and Runtime:FindFirstChild("Tornado") then
                        local tornadoTime = Runtime.Tornado:GetAttribute("TornadoTime") or 1
                        if (tick() - Tornado_Time) < tornadoTime + 0.314159 then continue end
                    end
                    
                    local OneBall = GetBall()
                    if OneBall and OneBall:GetAttribute("target") == tostring(Player) and IsCurved() then continue end
                    if Ball:FindFirstChild("ComboCounter") then continue end
                    
                    local cape = Player.Character.PrimaryPart:FindFirstChild("SingularityCape")
                    if cape then continue end
                    
                    if getgenv().InfinityDetect and Infinity then continue end
                    
                    if BallTarget == tostring(Player) and Distance <= ParryAccuracy then
                        local now = os.clock()
                        if now - Last_Parry > 0.5 then
                            pcall(function()
                                local anim = ReplicatedStorage.Shared.SwordAPI.Collection.Default:FindFirstChild("GrabParry")
                                if anim then
                                    local track = Player.Character.Humanoid.Animator:LoadAnimation(anim)
                                    track:Play()
                                end
                            end)
                        end
                        
                        DoParry(Selected_Parry_Type)
                        Last_Parry = now
                        Parried = true
                    end
                end
                
                local waitStart = tick()
                repeat RunService.PreSimulation:Wait() until (tick() - waitStart) >= 1 or not Parried
                Parried = false
            end)
        else
            if Connections["AutoParry"] then
                Connections["AutoParry"]:Disconnect()
                Connections["AutoParry"] = nil
            end
        end
    end
})

BlatantLeft:AddDropdown("CurveType", {
    Text = "Curve Type",
    Values = {"Camera", "Random", "Backwards", "Straight", "High", "Left", "Right"},
    Default = "Camera",
    Callback = function(Value)
        Selected_Parry_Type = Value
    end
})

BlatantLeft:AddSlider("ParryAccuracy", {
    Text = "Parry Accuracy",
    Default = 100,
    Min = 1,
    Max = 100,
    Rounding = 0,
    Callback = function(Value)
        Speed_Divisor_Multiplier = 0.7 + (Value - 1) * (0.35 / 99)
    end
})

BlatantLeft:AddDivider()

BlatantLeft:AddToggle("RandomAccuracyToggle", {
    Text = "Random Accuracy",
    Default = false,
    Callback = function(Value)
        getgenv().RandomAccuracy = Value
    end
})

BlatantLeft:AddToggle("InfinityDetectToggle", {
    Text = "Infinity Detection",
    Default = false,
    Callback = function(Value)
        getgenv().InfinityDetect = Value
    end
})

BlatantLeft:AddToggle("KeypressToggle", {
    Text = "Use Keypress",
    Default = false,
    Callback = function(Value)
        getgenv().UseKeypress = Value
    end
})

local BlatantRight = Tabs.Blatant:AddRightGroupbox("Lobby AP", "home")

BlatantRight:AddToggle("LobbyAPToggle", {
    Text = "Lobby Auto Parry",
    Default = false,
    Callback = function(Value)
        if Value then
            Connections["LobbyAP"] = RunService.Heartbeat:Connect(function()
                if not Player.Character or not Player.Character.PrimaryPart then return end
                
                local Ball = GetLobbyBall()
                if not Ball then return end
                
                local Zoomies = Ball:FindFirstChild("zoomies")
                if not Zoomies then return end
                
                Ball:GetAttributeChangedSignal("target"):Once(function()
                    Training_Parried = false
                end)
                
                if Training_Parried then return end
                
                local BallTarget = Ball:GetAttribute("target")
                local Velocity = Zoomies.VectorVelocity
                local Distance = Player:DistanceFromCharacter(Ball.Position)
                local Speed = Velocity.Magnitude
                local Ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() / 10
                
                local cappedDiff = math.min(math.max(Speed - 9.5, 0), 650)
                local divisorBase = 2.4 + cappedDiff * 0.002
                local multiplier = LobbyAP_Speed_Divisor_Multiplier
                
                if getgenv().LobbyRandomAccuracy then
                    multiplier = 0.7 + (math.random(1, 100) - 1) * (0.35 / 99)
                end
                
                local ParryAccuracy = Ping + math.max(Speed / (divisorBase * multiplier), 9.5)
                
                if BallTarget == tostring(Player) and Distance <= ParryAccuracy then
                    DoParry(Selected_Parry_Type)
                    Training_Parried = true
                end
                
                local waitStart = tick()
                repeat RunService.PreSimulation:Wait() until (tick() - waitStart) >= 1 or not Training_Parried
                Training_Parried = false
            end)
        else
            if Connections["LobbyAP"] then
                Connections["LobbyAP"]:Disconnect()
                Connections["LobbyAP"] = nil
            end
        end
    end
})

BlatantRight:AddSlider("LobbyAccuracy", {
    Text = "Lobby Accuracy",
    Default = 100,
    Min = 1,
    Max = 100,
    Rounding = 0,
    Callback = function(Value)
        LobbyAP_Speed_Divisor_Multiplier = 0.7 + (Value - 1) * (0.35 / 99)
    end
})

BlatantRight:AddToggle("LobbyRandomToggle", {
    Text = "Random Accuracy",
    Default = false,
    Callback = function(Value)
        getgenv().LobbyRandomAccuracy = Value
    end
})

local SpamGroup = Tabs.Blatant:AddRightGroupbox("Auto Spam", "repeat")

SpamGroup:AddToggle("AutoSpamToggle", {
    Text = "Auto Spam Parry",
    Default = false,
    Callback = function(Value)
        if Value then
            Connections["AutoSpam"] = RunService.PreSimulation:Connect(function()
                if not Player.Character or not Player.Character.PrimaryPart then return end
                
                local Ball = GetBall()
                if not Ball then return end
                
                local Zoomies = Ball:FindFirstChild("zoomies")
                if not Zoomies then return end
                
                GetClosestPlayer()
                if not Closest_Entity or not Closest_Entity.PrimaryPart then return end
                
                local Ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
                local PingThreshold = math.clamp(Ping / 10, 18.5, 70)
                local BallTarget = Ball:GetAttribute("target")
                local Distance = Player:DistanceFromCharacter(Ball.Position)
                local TargetDist = Player:DistanceFromCharacter(Closest_Entity.PrimaryPart.Position)
                local Speed = Zoomies.VectorVelocity.Magnitude
                local SpamAccuracy = PingThreshold + math.min(Speed / 6, 95)
                
                if not BallTarget then return end
                if TargetDist > SpamAccuracy or Distance > SpamAccuracy then return end
                if Player.Character:GetAttribute("Pulsed") then return end
                if BallTarget == tostring(Player) and TargetDist > 25 and Distance > 25 then return end
                
                if Distance <= SpamAccuracy and Parries > 2.5 then
                    DoParry(Selected_Parry_Type)
                end
            end)
        else
            if Connections["AutoSpam"] then
                Connections["AutoSpam"]:Disconnect()
                Connections["AutoSpam"] = nil
            end
        end
    end
})

local StrafeSpeed = 36

local PlayerLeft = Tabs.Player:AddLeftGroupbox("Movement", "move")

PlayerLeft:AddToggle("SpeedToggle", {
    Text = "Speed Hack",
    Default = false,
    Callback = function(Value)
        if Value then
            Connections["Speed"] = RunService.PreSimulation:Connect(function()
                if Player.Character and Player.Character:FindFirstChild("Humanoid") then
                    Player.Character.Humanoid.WalkSpeed = StrafeSpeed
                end
            end)
        else
            if Player.Character and Player.Character:FindFirstChild("Humanoid") then
                Player.Character.Humanoid.WalkSpeed = 36
            end
            if Connections["Speed"] then
                Connections["Speed"]:Disconnect()
                Connections["Speed"] = nil
            end
        end
    end
})

PlayerLeft:AddSlider("SpeedValue", {
    Text = "Speed",
    Default = 36,
    Min = 36,
    Max = 200,
    Rounding = 0,
    Callback = function(Value)
        StrafeSpeed = Value
    end
})

local spinSpeed = 1

PlayerLeft:AddToggle("SpinToggle", {
    Text = "Spinbot",
    Default = false,
    Callback = function(Value)
        getgenv().Spinning = Value
        if Value then
            task.spawn(function()
                while getgenv().Spinning do
                    RunService.Heartbeat:Wait()
                    if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                        Player.Character.HumanoidRootPart.CFrame = Player.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(spinSpeed), 0)
                    end
                end
            end)
        end
    end
})

PlayerLeft:AddSlider("SpinSpeed", {
    Text = "Spin Speed",
    Default = 1,
    Min = 1,
    Max = 50,
    Rounding = 0,
    Callback = function(Value)
        spinSpeed = Value
    end
})

local PlayerRight = Tabs.Player:AddRightGroupbox("Misc", "settings")

PlayerRight:AddToggle("FOVToggle", {
    Text = "Custom FOV",
    Default = false,
    Callback = function(Value)
        getgenv().CustomFOV = Value
        if Value then
            Connections["FOV"] = RunService.RenderStepped:Connect(function()
                if getgenv().CustomFOV then
                    workspace.CurrentCamera.FieldOfView = getgenv().FOVValue or 70
                end
            end)
        else
            workspace.CurrentCamera.FieldOfView = 70
            if Connections["FOV"] then
                Connections["FOV"]:Disconnect()
                Connections["FOV"] = nil
            end
        end
    end
})

PlayerRight:AddSlider("FOVValue", {
    Text = "FOV",
    Default = 70,
    Min = 50,
    Max = 120,
    Rounding = 0,
    Callback = function(Value)
        getgenv().FOVValue = Value
    end
})

local ESPFolder = Instance.new("Folder", CoreGui)
ESPFolder.Name = "InvictusESP"

local function CreateESP(plr)
    if plr == Player then return end
    
    local function Setup(char)
        if not char then return end
        
        task.wait(0.5)
        
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        local head = char:WaitForChild("Head", 5)
        local humanoid = char:WaitForChild("Humanoid", 5)
        
        if not hrp or not head or not humanoid then return end
        
        if getgenv().BoxESPEnabled then
            local box = Instance.new("BoxHandleAdornment")
            box.Name = plr.Name .. "_Box"
            box.Adornee = hrp
            box.Size = Vector3.new(4, 5, 2)
            box.Color3 = Color3.fromRGB(255, 255, 255)
            box.Transparency = 0.5
            box.AlwaysOnTop = true
            box.ZIndex = 5
            box.Parent = ESPFolder
        end
        
        if getgenv().NameESPEnabled then
            local bill = Instance.new("BillboardGui")
            bill.Name = plr.Name .. "_Name"
            bill.Adornee = head
            bill.Size = UDim2.new(0, 100, 0, 40)
            bill.StudsOffset = Vector3.new(0, 2, 0)
            bill.AlwaysOnTop = true
            bill.Parent = ESPFolder
            
            local name = Instance.new("TextLabel", bill)
            name.Size = UDim2.new(1, 0, 0.5, 0)
            name.BackgroundTransparency = 1
            name.TextColor3 = Color3.fromRGB(255, 255, 255)
            name.TextStrokeTransparency = 0
            name.Font = Enum.Font.GothamBold
            name.TextScaled = true
            name.Text = plr.DisplayName
            
            local health = Instance.new("TextLabel", bill)
            health.Size = UDim2.new(1, 0, 0.5, 0)
            health.Position = UDim2.new(0, 0, 0.5, 0)
            health.BackgroundTransparency = 1
            health.TextColor3 = Color3.fromRGB(0, 255, 0)
            health.TextStrokeTransparency = 0
            health.Font = Enum.Font.GothamBold
            health.TextScaled = true
            
            Connections[plr.Name .. "_Health"] = RunService.Heartbeat:Connect(function()
                if humanoid and humanoid.Parent then
                    health.Text = math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
                end
            end)
        end
        
        if getgenv().SkeletonESPEnabled then
            local bones = {
                {"Head", "UpperTorso"},
                {"UpperTorso", "LowerTorso"},
                {"UpperTorso", "LeftUpperArm"},
                {"LeftUpperArm", "LeftLowerArm"},
                {"LeftLowerArm", "LeftHand"},
                {"UpperTorso", "RightUpperArm"},
                {"RightUpperArm", "RightLowerArm"},
                {"RightLowerArm", "RightHand"},
                {"LowerTorso", "LeftUpperLeg"},
                {"LeftUpperLeg", "LeftLowerLeg"},
                {"LeftLowerLeg", "LeftFoot"},
                {"LowerTorso", "RightUpperLeg"},
                {"RightUpperLeg", "RightLowerLeg"},
                {"RightLowerLeg", "RightFoot"},
            }
            
            for i, bone in pairs(bones) do
                local part0 = char:FindFirstChild(bone[1])
                local part1 = char:FindFirstChild(bone[2])
                
                if part0 and part1 then
                    local beam = Instance.new("Beam")
                    beam.Name = plr.Name .. "_Bone_" .. i
                    beam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
                    beam.Width0 = 0.1
                    beam.Width1 = 0.1
                    beam.FaceCamera = true
                    beam.Parent = ESPFolder
                    
                    local a0 = Instance.new("Attachment", part0)
                    local a1 = Instance.new("Attachment", part1)
                    beam.Attachment0 = a0
                    beam.Attachment1 = a1
                end
            end
        end
        
        humanoid.Died:Connect(function()
            for _, obj in pairs(ESPFolder:GetChildren()) do
                if obj.Name:find(plr.Name) then
                    obj:Destroy()
                end
            end
            if Connections[plr.Name .. "_Health"] then
                Connections[plr.Name .. "_Health"]:Disconnect()
            end
        end)
    end
    
    if plr.Character then Setup(plr.Character) end
    plr.CharacterAdded:Connect(Setup)
end

local function ClearESP()
    ESPFolder:ClearAllChildren()
    for name, conn in pairs(Connections) do
        if name:find("_Health") then
            conn:Disconnect()
            Connections[name] = nil
        end
    end
end

local function RefreshESP()
    ClearESP()
    if getgenv().BoxESPEnabled or getgenv().NameESPEnabled or getgenv().SkeletonESPEnabled then
        for _, plr in pairs(Players:GetPlayers()) do
            CreateESP(plr)
        end
    end
end

local VisualsLeft = Tabs.Visuals:AddLeftGroupbox("Player ESP", "users")

VisualsLeft:AddToggle("BoxESP", {
    Text = "Box ESP",
    Default = false,
    Callback = function(Value)
        getgenv().BoxESPEnabled = Value
        RefreshESP()
    end
})

VisualsLeft:AddToggle("NameESP", {
    Text = "Name ESP",
    Default = false,
    Callback = function(Value)
        getgenv().NameESPEnabled = Value
        RefreshESP()
    end
})

VisualsLeft:AddToggle("SkeletonESP", {
    Text = "Skeleton ESP",
    Default = false,
    Callback = function(Value)
        getgenv().SkeletonESPEnabled = Value
        RefreshESP()
    end
})

Players.PlayerAdded:Connect(function(plr)
    if getgenv().BoxESPEnabled or getgenv().NameESPEnabled or getgenv().SkeletonESPEnabled then
        CreateESP(plr)
    end
end)

Players.PlayerRemoving:Connect(function(plr)
    for _, obj in pairs(ESPFolder:GetChildren()) do
        if obj.Name:find(plr.Name) then
            obj:Destroy()
        end
    end
end)

local VisualsRight = Tabs.Visuals:AddRightGroupbox("Ball Visuals", "target")

local tracerLine = nil

VisualsRight:AddToggle("BallTracer", {
    Text = "Ball Tracer",
    Default = false,
    Callback = function(Value)
        if Value then
            tracerLine = Drawing.new("Line")
            tracerLine.Visible = true
            tracerLine.Color = Color3.fromRGB(255, 0, 0)
            tracerLine.Thickness = 2
            tracerLine.Transparency = 1
            
            Connections["BallTracer"] = RunService.RenderStepped:Connect(function()
                local Ball = GetBall()
                if Ball and tracerLine then
                    local Camera = workspace.CurrentCamera
                    local screenPos, onScreen = Camera:WorldToViewportPoint(Ball.Position)
                    
                    if onScreen then
                        tracerLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        tracerLine.To = Vector2.new(screenPos.X, screenPos.Y)
                        tracerLine.Visible = true
                    else
                        tracerLine.Visible = false
                    end
                elseif tracerLine then
                    tracerLine.Visible = false
                end
            end)
        else
            if tracerLine then
                tracerLine:Remove()
                tracerLine = nil
            end
            if Connections["BallTracer"] then
                Connections["BallTracer"]:Disconnect()
                Connections["BallTracer"] = nil
            end
        end
    end
})

VisualsRight:AddToggle("BallTrail", {
    Text = "Ball Trail",
    Default = false,
    Callback = function(Value)
        if Value then
            Connections["BallTrail"] = RunService.RenderStepped:Connect(function()
                local Ball = GetBall()
                if Ball and not Ball:FindFirstChild("InvictusTrail") then
                    local a0 = Instance.new("Attachment", Ball)
                    a0.Position = Vector3.new(0, 0.5, 0)
                    local a1 = Instance.new("Attachment", Ball)
                    a1.Position = Vector3.new(0, -0.5, 0)
                    
                    local trail = Instance.new("Trail", Ball)
                    trail.Name = "InvictusTrail"
                    trail.Attachment0 = a0
                    trail.Attachment1 = a1
                    trail.Lifetime = 0.3
                    trail.MinLength = 0.1
                    trail.FaceCamera = true
                    trail.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 255))
                    })
                end
            end)
        else
            if Connections["BallTrail"] then
                Connections["BallTrail"]:Disconnect()
                Connections["BallTrail"] = nil
            end
            for _, Ball in pairs(workspace.Balls:GetChildren()) do
                local trail = Ball:FindFirstChild("InvictusTrail")
                if trail then trail:Destroy() end
                for _, att in pairs(Ball:GetChildren()) do
                    if att:IsA("Attachment") then att:Destroy() end
                end
            end
        end
    end
})

local WorldLeft = Tabs.World:AddLeftGroupbox("Effects", "sparkles")

WorldLeft:AddToggle("RainbowFilter", {
    Text = "Rainbow Filter",
    Default = false,
    Callback = function(Value)
        if Value then
            local cc = Instance.new("ColorCorrectionEffect", Lighting)
            cc.Name = "InvictusRainbow"
            cc.Saturation = 1
            
            local hue = 0
            Connections["Rainbow"] = RunService.RenderStepped:Connect(function()
                hue = (hue + 1) % 360
                cc.TintColor = Color3.fromHSV(hue / 360, 1, 1)
            end)
        else
            local cc = Lighting:FindFirstChild("InvictusRainbow")
            if cc then cc:Destroy() end
            if Connections["Rainbow"] then
                Connections["Rainbow"]:Disconnect()
                Connections["Rainbow"] = nil
            end
        end
    end
})

WorldLeft:AddToggle("ViewBall", {
    Text = "View Ball",
    Default = false,
    Callback = function(Value)
        if Value then
            Connections["ViewBall"] = RunService.RenderStepped:Connect(function()
                local Ball = GetBall()
                if Ball then
                    workspace.CurrentCamera.CameraSubject = Ball
                end
            end)
        else
            workspace.CurrentCamera.CameraSubject = Player.Character or Player
            if Connections["ViewBall"] then
                Connections["ViewBall"]:Disconnect()
                Connections["ViewBall"] = nil
            end
        end
    end
})

local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu", "sliders")

MenuGroup:AddToggle("KeybindMenu", {
    Text = "Keybind Menu",
    Default = false,
    Callback = function(Value)
        Library.KeybindFrame.Visible = Value
    end
})

MenuGroup:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", {
    Default = "RightControl",
    NoUI = true,
    Text = "Menu Keybind"
})

MenuGroup:AddButton({
    Text = "Copy Discord",
    Func = function()
        setclipboard("https://discord.gg/nbPHzKzafN")
        Library:Notify({Title = "Invictus", Description = "Discord copied!", Time = 2})
    end
})

MenuGroup:AddButton({
    Text = "Unload",
    Func = function()
        for _, conn in pairs(Connections) do
            if typeof(conn) == "RBXScriptConnection" then
                conn:Disconnect()
            end
        end
        ESPFolder:Destroy()
        if tracerLine then tracerLine:Remove() end
        Library:Unload()
        _G.InvictusLoaded = false
    end
})

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("Invictus")
SaveManager:SetFolder("Invictus/BladeBall")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

Library:Notify({
    Title = "Blade Ball - Invictus",
    Description = "Loaded! Developer: Entropy\ndiscord.gg/nbPHzKzafN",
    Time = 5
})
