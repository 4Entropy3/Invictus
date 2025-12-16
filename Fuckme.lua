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
local CoreGui = game:GetService("CoreGui")

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

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "InvictusESP"
ESPFolder.Parent = CoreGui

local ESPObjects = {}
local TracerLine = nil

local function PressF()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
    task.wait()
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
end

local function GetBall()
    for _, Ball in pairs(workspace.Balls:GetChildren()) do
        if Ball:GetAttribute("realBall") then
            Ball.CanCollide = false
            return Ball
        end
    end
    return nil
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
    if not workspace:FindFirstChild("TrainingBalls") then return nil end
    for _, Ball in pairs(workspace.TrainingBalls:GetChildren()) do
        if Ball:GetAttribute("realBall") then
            return Ball
        end
    end
    return nil
end

local function GetClosestPlayer()
    local MaxDist = math.huge
    local Found = nil
    if not workspace:FindFirstChild("Alive") then return nil end
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
    if not Player.Character or not Player.Character.PrimaryPart then return false end
    
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
            Connections["AutoParry"] = RunService.Heartbeat:Connect(function()
                if not Player.Character or not Player.Character.PrimaryPart then return end
                
                local BallsList = GetBalls()
                
                for _, Ball in pairs(BallsList) do
                    if not Ball then continue end
                    
                    local Zoomies = Ball:FindFirstChild("zoomies")
                    if not Zoomies then continue end
                    
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
                        PressF()
                        Parried = true
                        Last_Parry = tick()
                        
                        task.delay(0.5, function()
                            Parried = false
                        end)
                        
                        break
                    end
                end
            end)
            
            Connections["ParryReset"] = workspace.Balls.ChildAdded:Connect(function(Ball)
                task.wait(0.1)
                Ball:GetAttributeChangedSignal("target"):Connect(function()
                    Parried = false
                end)
            end)
        else
            if Connections["AutoParry"] then
                Connections["AutoParry"]:Disconnect()
                Connections["AutoParry"] = nil
            end
            if Connections["ParryReset"] then
                Connections["ParryReset"]:Disconnect()
                Connections["ParryReset"] = nil
            end
        end
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
                    PressF()
                    Training_Parried = true
                    
                    task.delay(0.5, function()
                        Training_Parried = false
                    end)
                end
            end)
            
            Connections["LobbyReset"] = pcall(function()
                workspace.TrainingBalls.ChildAdded:Connect(function(Ball)
                    task.wait(0.1)
                    Ball:GetAttributeChangedSignal("target"):Connect(function()
                        Training_Parried = false
                    end)
                end)
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
            Connections["AutoSpam"] = RunService.Heartbeat:Connect(function()
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
                
                if Distance <= SpamAccuracy and Parries > 2 then
                    PressF()
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
            Connections["Speed"] = RunService.Heartbeat:Connect(function()
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

local spinSpeed = 5

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
    Default = 5,
    Min = 1,
    Max = 50,
    Rounding = 0,
    Callback = function(Value)
        spinSpeed = Value
    end
})

local PlayerRight = Tabs.Player:AddRightGroupbox("Camera", "camera")

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

local function CreateHighlight(plr)
    if plr == Player then return end
    
    local function Setup(char)
        if not char then return end
        task.wait(0.5)
        
        if ESPObjects[plr.Name] then
            for _, obj in pairs(ESPObjects[plr.Name]) do
                pcall(function() obj:Destroy() end)
            end
        end
        ESPObjects[plr.Name] = {}
        
        if getgenv().BoxESPEnabled then
            local highlight = Instance.new("Highlight")
            highlight.Name = plr.Name .. "_Highlight"
            highlight.Adornee = char
            highlight.FillColor = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency = 0.7
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = ESPFolder
            table.insert(ESPObjects[plr.Name], highlight)
        end
        
        if getgenv().NameESPEnabled then
            local head = char:FindFirstChild("Head")
            if head then
                local bill = Instance.new("BillboardGui")
                bill.Name = plr.Name .. "_Name"
                bill.Adornee = head
                bill.Size = UDim2.new(0, 150, 0, 50)
                bill.StudsOffset = Vector3.new(0, 2.5, 0)
                bill.AlwaysOnTop = true
                bill.Parent = ESPFolder
                table.insert(ESPObjects[plr.Name], bill)
                
                local nameLabel = Instance.new("TextLabel", bill)
                nameLabel.Name = "NameLabel"
                nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
                nameLabel.BackgroundTransparency = 1
                nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                nameLabel.TextStrokeTransparency = 0
                nameLabel.Font = Enum.Font.GothamBold
                nameLabel.TextScaled = true
                nameLabel.Text = plr.DisplayName
                
                local healthLabel = Instance.new("TextLabel", bill)
                healthLabel.Name = "HealthLabel"
                healthLabel.Size = UDim2.new(1, 0, 0.5, 0)
                healthLabel.Position = UDim2.new(0, 0, 0.5, 0)
                healthLabel.BackgroundTransparency = 1
                healthLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                healthLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                healthLabel.TextStrokeTransparency = 0
                healthLabel.Font = Enum.Font.GothamBold
                healthLabel.TextScaled = true
                healthLabel.Text = "100/100"
                
                local humanoid = char:FindFirstChild("Humanoid")
                if humanoid then
                    Connections[plr.Name .. "_Health"] = humanoid.HealthChanged:Connect(function(health)
                        healthLabel.Text = math.floor(health) .. "/" .. math.floor(humanoid.MaxHealth)
                        local ratio = health / humanoid.MaxHealth
                        healthLabel.TextColor3 = Color3.fromRGB(255 * (1 - ratio), 255 * ratio, 0)
                    end)
                end
            end
        end
        
        if getgenv().SkeletonESPEnabled then
            local function GetPart(name)
                return char:FindFirstChild(name)
            end
            
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
                local part0 = GetPart(bone[1])
                local part1 = GetPart(bone[2])
                
                if part0 and part1 then
                    local a0 = Instance.new("Attachment")
                    a0.Name = "BoneA0_" .. i
                    a0.Parent = part0
                    table.insert(ESPObjects[plr.Name], a0)
                    
                    local a1 = Instance.new("Attachment")
                    a1.Name = "BoneA1_" .. i
                    a1.Parent = part1
                    table.insert(ESPObjects[plr.Name], a1)
                    
                    local beam = Instance.new("Beam")
                    beam.Name = plr.Name .. "_Bone_" .. i
                    beam.Attachment0 = a0
                    beam.Attachment1 = a1
                    beam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
                    beam.Width0 = 0.15
                    beam.Width1 = 0.15
                    beam.FaceCamera = true
                    beam.Segments = 1
                    beam.Parent = ESPFolder
                    table.insert(ESPObjects[plr.Name], beam)
                end
            end
        end
    end
    
    if plr.Character then
        Setup(plr.Character)
    end
    
    Connections[plr.Name .. "_CharAdded"] = plr.CharacterAdded:Connect(function(char)
        Setup(char)
    end)
end

local function RemoveESP(plr)
    if ESPObjects[plr.Name] then
        for _, obj in pairs(ESPObjects[plr.Name]) do
            pcall(function() obj:Destroy() end)
        end
        ESPObjects[plr.Name] = nil
    end
    
    if Connections[plr.Name .. "_Health"] then
        Connections[plr.Name .. "_Health"]:Disconnect()
        Connections[plr.Name .. "_Health"] = nil
    end
    
    if Connections[plr.Name .. "_CharAdded"] then
        Connections[plr.Name .. "_CharAdded"]:Disconnect()
        Connections[plr.Name .. "_CharAdded"] = nil
    end
end

local function RefreshAllESP()
    for _, plr in pairs(Players:GetPlayers()) do
        RemoveESP(plr)
    end
    
    if getgenv().BoxESPEnabled or getgenv().NameESPEnabled or getgenv().SkeletonESPEnabled then
        for _, plr in pairs(Players:GetPlayers()) do
            CreateHighlight(plr)
        end
    end
end

Players.PlayerAdded:Connect(function(plr)
    if getgenv().BoxESPEnabled or getgenv().NameESPEnabled or getgenv().SkeletonESPEnabled then
        CreateHighlight(plr)
    end
end)

Players.PlayerRemoving:Connect(function(plr)
    RemoveESP(plr)
end)

local VisualsLeft = Tabs.Visuals:AddLeftGroupbox("Player ESP", "users")

VisualsLeft:AddToggle("BoxESP", {
    Text = "Box ESP (Highlight)",
    Default = false,
    Callback = function(Value)
        getgenv().BoxESPEnabled = Value
        RefreshAllESP()
    end
})

VisualsLeft:AddToggle("NameESP", {
    Text = "Name & Health ESP",
    Default = false,
    Callback = function(Value)
        getgenv().NameESPEnabled = Value
        RefreshAllESP()
    end
})

VisualsLeft:AddToggle("SkeletonESP", {
    Text = "Skeleton ESP",
    Default = false,
    Callback = function(Value)
        getgenv().SkeletonESPEnabled = Value
        RefreshAllESP()
    end
})

local VisualsRight = Tabs.Visuals:AddRightGroupbox("Ball Visuals", "target")

VisualsRight:AddToggle("BallTracer", {
    Text = "Ball Tracer",
    Default = false,
    Callback = function(Value)
        if Value then
            TracerLine = Drawing.new("Line")
            TracerLine.Visible = false
            TracerLine.Color = Color3.fromRGB(255, 0, 0)
            TracerLine.Thickness = 2
            TracerLine.Transparency = 1
            
            Connections["BallTracer"] = RunService.RenderStepped:Connect(function()
                local Ball = GetBall()
                if Ball and TracerLine then
                    local Camera = workspace.CurrentCamera
                    local screenPos, onScreen = Camera:WorldToViewportPoint(Ball.Position)
                    
                    if onScreen then
                        TracerLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        TracerLine.To = Vector2.new(screenPos.X, screenPos.Y)
                        TracerLine.Visible = true
                    else
                        TracerLine.Visible = false
                    end
                elseif TracerLine then
                    TracerLine.Visible = false
                end
            end)
        else
            if TracerLine then
                TracerLine:Remove()
                TracerLine = nil
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
                    a0.Name = "TrailA0"
                    a0.Position = Vector3.new(0, 0.5, 0)
                    
                    local a1 = Instance.new("Attachment", Ball)
                    a1.Name = "TrailA1"
                    a1.Position = Vector3.new(0, -0.5, 0)
                    
                    local trail = Instance.new("Trail", Ball)
                    trail.Name = "InvictusTrail"
                    trail.Attachment0 = a0
                    trail.Attachment1 = a1
                    trail.Lifetime = 0.5
                    trail.MinLength = 0.1
                    trail.FaceCamera = true
                    trail.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)),
                        ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 255, 0)),
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
                local a0 = Ball:FindFirstChild("TrailA0")
                if a0 then a0:Destroy() end
                local a1 = Ball:FindFirstChild("TrailA1")
                if a1 then a1:Destroy() end
            end
        end
    end
})

VisualsRight:AddToggle("BallHighlight", {
    Text = "Ball Highlight",
    Default = false,
    Callback = function(Value)
        if Value then
            Connections["BallHighlight"] = RunService.RenderStepped:Connect(function()
                local Ball = GetBall()
                if Ball and not Ball:FindFirstChild("InvictusHighlight") then
                    local hl = Instance.new("Highlight", Ball)
                    hl.Name = "InvictusHighlight"
                    hl.FillColor = Color3.fromRGB(255, 0, 0)
                    hl.FillTransparency = 0.5
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    hl.OutlineTransparency = 0
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                end
            end)
        else
            if Connections["BallHighlight"] then
                Connections["BallHighlight"]:Disconnect()
                Connections["BallHighlight"] = nil
            end
            for _, Ball in pairs(workspace.Balls:GetChildren()) do
                local hl = Ball:FindFirstChild("InvictusHighlight")
                if hl then hl:Destroy() end
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

WorldLeft:AddToggle("Fullbright", {
    Text = "Fullbright",
    Default = false,
    Callback = function(Value)
        if Value then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.fromRGB(178, 178, 178)
        else
            Lighting.Brightness = 1
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = true
            Lighting.Ambient = Color3.fromRGB(0, 0, 0)
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
    Text = "Unload Script",
    Func = function()
        for _, conn in pairs(Connections) do
            if typeof(conn) == "RBXScriptConnection" then
                pcall(function() conn:Disconnect() end)
            end
        end
        
        for _, plr in pairs(Players:GetPlayers()) do
            RemoveESP(plr)
        end
        
        pcall(function() ESPFolder:Destroy() end)
        
        if TracerLine then
            pcall(function() TracerLine:Remove() end)
        end
        
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
    Description = "Loaded successfully!\nDeveloper: Entropy\ndiscord.gg/nbPHzKzafN",
    Time = 5
})
