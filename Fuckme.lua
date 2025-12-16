if _G.InvictusLoaded then
    warn("Invictus already loaded.")
    return
end
_G.InvictusLoaded = true

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

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

local Connections_Manager = {}
local Tornado_Time = tick()
local Speed_Divisor_Multiplier = 1.1
local LobbyAP_Speed_Divisor_Multiplier = 1.1
local Selected_Parry_Type = "Camera"
local Parried = false
local Training_Parried = false
local Last_Parry = 0
local Parries = 0
local Infinity = false
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

local PropertyChangeOrder = {}
local HashOne, HashTwo, HashThree
local ShouldPlayerJump, MainRemote, GetOpponentPosition
local Parry_Key

LPH_NO_VIRTUALIZE = LPH_NO_VIRTUALIZE or function(f) return f end
LPH_JIT = LPH_JIT or function(f) return f end
LPH_JIT_MAX = LPH_JIT_MAX or function(f) return f end

LPH_NO_VIRTUALIZE(function()
    for Index, Value in next, getgc() do
        if rawequal(typeof(Value), "function") and islclosure(Value) then
            local success, source = pcall(function()
                return getrenv().debug.info(Value, "s")
            end)
            if success and source and source:find("SwordsController") then
                local success2, line = pcall(function()
                    return getrenv().debug.info(Value, "l")
                end)
                if success2 and rawequal(line, 276) then
                    HashOne = getconstant(Value, 62)
                    HashTwo = getconstant(Value, 64)
                    HashThree = getconstant(Value, 65)
                end
            end
        end
    end
end)()

LPH_NO_VIRTUALIZE(function()
    for Index, Object in next, game:GetDescendants() do
        if Object:IsA("RemoteEvent") and string.find(Object.Name, "\n") then
            Object.Changed:Once(function()
                table.insert(PropertyChangeOrder, Object)
            end)
        end
    end
end)()

repeat task.wait() until #PropertyChangeOrder == 3

ShouldPlayerJump = PropertyChangeOrder[1]
MainRemote = PropertyChangeOrder[2]
GetOpponentPosition = PropertyChangeOrder[3]

for Index, Value in pairs(getconnections(Player.PlayerGui.Hotbar.Block.Activated)) do
    if Value and Value.Function and not iscclosure(Value.Function) then
        for Index2, Value2 in pairs(getupvalues(Value.Function)) do
            if type(Value2) == "function" then
                Parry_Key = getupvalue(getupvalue(Value2, 2), 17)
            end
        end
    end
end

local function Parry(...)
    ShouldPlayerJump:FireServer(HashOne, Parry_Key, ...)
    MainRemote:FireServer(HashTwo, Parry_Key, ...)
    GetOpponentPosition:FireServer(HashThree, Parry_Key, ...)
end

local Auto_Parry = {}

function Auto_Parry.Get_Ball()
    for _, Instance in pairs(workspace.Balls:GetChildren()) do
        if Instance:GetAttribute("realBall") then
            Instance.CanCollide = false
            return Instance
        end
    end
end

function Auto_Parry.Get_Balls()
    local Balls = {}
    for _, Instance in pairs(workspace.Balls:GetChildren()) do
        if Instance:GetAttribute("realBall") then
            Instance.CanCollide = false
            table.insert(Balls, Instance)
        end
    end
    return Balls
end

function Auto_Parry.Lobby_Balls()
    for _, Instance in pairs(workspace.TrainingBalls:GetChildren()) do
        if Instance:GetAttribute("realBall") then
            return Instance
        end
    end
end

function Auto_Parry.Closest_Player()
    local Max_Distance = math.huge
    local Found_Entity = nil
    for _, Entity in pairs(workspace.Alive:GetChildren()) do
        if tostring(Entity) ~= tostring(Player) then
            if Entity.PrimaryPart then
                local Distance = Player:DistanceFromCharacter(Entity.PrimaryPart.Position)
                if Distance < Max_Distance then
                    Max_Distance = Distance
                    Found_Entity = Entity
                end
            end
        end
    end
    Closest_Entity = Found_Entity
    return Found_Entity
end

function Auto_Parry.Linear_Interpolation(a, b, time_volume)
    return a + (b - a) * time_volume
end

function Auto_Parry.Is_Curved()
    local Ball = Auto_Parry.Get_Ball()
    if not Ball then return false end
    local Zoomies = Ball:FindFirstChild("zoomies")
    if not Zoomies then return false end

    local Velocity = Zoomies.VectorVelocity
    local Ball_Direction = Velocity.Unit
    local Direction = (Player.Character.PrimaryPart.Position - Ball.Position).Unit
    local Dot = Direction:Dot(Ball_Direction)
    local Speed = Velocity.Magnitude
    local Speed_Threshold = math.min(Speed / 100, 40)
    local Direction_Difference = (Ball_Direction - Velocity).Unit
    local Direction_Similarity = Direction:Dot(Direction_Difference)
    local Dot_Difference = Dot - Direction_Similarity
    local Distance = (Player.Character.PrimaryPart.Position - Ball.Position).Magnitude
    local Pings = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
    local Dot_Threshold = 0.5 - (Pings / 1000)
    local Reach_Time = Distance / Speed - (Pings / 1000)
    local Ball_Distance_Threshold = 15 - math.min(Distance / 1000, 15) + Speed_Threshold
    local Clamped_Dot = math.clamp(Dot, -1, 1)
    local Radians = math.rad(math.asin(Clamped_Dot))

    Lerp_Radians = Auto_Parry.Linear_Interpolation(Lerp_Radians, Radians, 0.8)

    if Speed > 100 and Reach_Time > Pings / 10 then
        Ball_Distance_Threshold = math.max(Ball_Distance_Threshold - 15, 15)
    end
    if Distance < Ball_Distance_Threshold then return false end
    if Dot_Difference < Dot_Threshold then return true end
    if Lerp_Radians < 0.018 then Last_Warping = tick() end
    if (tick() - Last_Warping) < (Reach_Time / 1.5) then return true end
    if (tick() - Curving) < (Reach_Time / 1.5) then return true end

    return Dot < Dot_Threshold
end

function Auto_Parry.Parry_Data(Parry_Type)
    Auto_Parry.Closest_Player()
    local Events = {}
    local Camera = workspace.CurrentCamera
    local Vector2_Mouse_Location

    if isMobile then
        Vector2_Mouse_Location = {Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2}
    else
        local Mouse_Location = UserInputService:GetMouseLocation()
        Vector2_Mouse_Location = {Mouse_Location.X, Mouse_Location.Y}
    end

    for _, v in pairs(workspace.Alive:GetChildren()) do
        if v ~= Player.Character then
            local worldPos = v.PrimaryPart.Position
            local screenPos, isOnScreen = Camera:WorldToScreenPoint(worldPos)
            Events[tostring(v)] = screenPos
        end
    end

    if Parry_Type == "Camera" then
        return {0, Camera.CFrame, Events, Vector2_Mouse_Location}
    end
    if Parry_Type == "Backwards" then
        local Backwards_Direction = Camera.CFrame.LookVector * -10000
        Backwards_Direction = Vector3.new(Backwards_Direction.X, 0, Backwards_Direction.Z)
        return {0, CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Backwards_Direction), Events, Vector2_Mouse_Location}
    end
    if Parry_Type == "Straight" then
        if Closest_Entity and Closest_Entity.PrimaryPart then
            return {0, CFrame.new(Player.Character.PrimaryPart.Position, Closest_Entity.PrimaryPart.Position), Events, Vector2_Mouse_Location}
        end
    end
    if Parry_Type == "Random" then
        return {0, CFrame.new(Camera.CFrame.Position, Vector3.new(math.random(-4000, 4000), math.random(-4000, 4000), math.random(-4000, 4000))), Events, Vector2_Mouse_Location}
    end
    if Parry_Type == "High" then
        local High_Direction = Camera.CFrame.UpVector * 10000
        return {0, CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + High_Direction), Events, Vector2_Mouse_Location}
    end
    if Parry_Type == "Left" then
        local Left_Direction = Camera.CFrame.RightVector * 10000
        return {0, CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position - Left_Direction), Events, Vector2_Mouse_Location}
    end
    if Parry_Type == "Right" then
        local Right_Direction = Camera.CFrame.RightVector * 10000
        return {0, CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Right_Direction), Events, Vector2_Mouse_Location}
    end

    return {0, Camera.CFrame, Events, Vector2_Mouse_Location}
end

function Auto_Parry.Parry_Animation()
    pcall(function()
        local Parry_Animation = ReplicatedStorage.Shared.SwordAPI.Collection.Default:FindFirstChild("GrabParry")
        local Current_Sword = Player.Character:GetAttribute("CurrentlyEquippedSword")
        if not Current_Sword or not Parry_Animation then return end

        local Sword_Data = ReplicatedStorage.Shared.ReplicatedInstances.Swords.GetSword:Invoke(Current_Sword)
        if not Sword_Data or not Sword_Data["AnimationType"] then return end

        for _, object in pairs(ReplicatedStorage.Shared.SwordAPI.Collection:GetChildren()) do
            if object.Name == Sword_Data["AnimationType"] then
                if object:FindFirstChild("GrabParry") or object:FindFirstChild("Grab") then
                    local sword_animation_type = object:FindFirstChild("Grab") and "Grab" or "GrabParry"
                    Parry_Animation = object[sword_animation_type]
                end
            end
        end

        local track = Player.Character.Humanoid.Animator:LoadAnimation(Parry_Animation)
        track:Play()
    end)
end

function Auto_Parry.Do_Parry(Parry_Type)
    local Parry_Data = Auto_Parry.Parry_Data(Parry_Type)

    if getgenv().AutoParryKeypress then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
        task.wait()
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
    else
        Parry(Parry_Data[1], Parry_Data[2], Parry_Data[3], Parry_Data[4])
    end

    if Parries <= 7 then
        Parries = Parries + 1
        task.delay(0.5, function()
            if Parries > 0 then
                Parries = Parries - 1
            end
        end)
    end
end

pcall(function()
    ReplicatedStorage.Remotes.InfinityBall.OnClientEvent:Connect(function(a, b)
        if b then
            Infinity = true
        else
            Infinity = false
        end
    end)
end)

local Runtime = workspace:FindFirstChild("Runtime")

workspace.Balls.ChildAdded:Connect(function(Value)
    Value.ChildAdded:Connect(function(Child)
        if getgenv().SlashOfFuryDetection and Child.Name == "ComboCounter" then
            local Sof_Label = Child:FindFirstChildOfClass("TextLabel")
            if Sof_Label then
                repeat
                    local Slashes_Counter = tonumber(Sof_Label.Text)
                    if Slashes_Counter and Slashes_Counter < 32 then
                        Auto_Parry.Do_Parry(Selected_Parry_Type)
                    end
                    task.wait()
                until not Sof_Label.Parent or not Sof_Label
            end
        end
    end)
end)

local BlatantLeft = Tabs.Blatant:AddLeftGroupbox("Auto Parry", "zap")

BlatantLeft:AddToggle("AutoParryToggle", {
    Text = "Auto Parry",
    Default = false,
    Callback = function(Value)
        if Value then
            Connections_Manager["Auto Parry"] = RunService.PreSimulation:Connect(function()
                local One_Ball = Auto_Parry.Get_Ball()
                local Balls = Auto_Parry.Get_Balls()

                for _, Ball in pairs(Balls) do
                    if not Ball then return end
                    if not Player.Character or not Player.Character.PrimaryPart then return end

                    local Zoomies = Ball:FindFirstChild("zoomies")
                    if not Zoomies then return end

                    Ball:GetAttributeChangedSignal("target"):Once(function()
                        Parried = false
                    end)

                    if Parried then return end

                    local Ball_Target = Ball:GetAttribute("target")
                    local One_Target = One_Ball and One_Ball:GetAttribute("target")
                    local Velocity = Zoomies.VectorVelocity
                    local Distance = (Player.Character.PrimaryPart.Position - Ball.Position).Magnitude
                    local Ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() / 10
                    local Ping_Threshold = math.clamp(Ping / 10, 5, 17)
                    local Speed = Velocity.Magnitude

                    local cappedSpeedDiff = math.min(math.max(Speed - 9.5, 0), 650)
                    local speed_divisor_base = 2.4 + cappedSpeedDiff * 0.002
                    local effectiveMultiplier = Speed_Divisor_Multiplier

                    if getgenv().RandomParryAccuracyEnabled then
                        if Speed < 200 then
                            effectiveMultiplier = 0.7 + (math.random(40, 100) - 1) * (0.35 / 99)
                        else
                            effectiveMultiplier = 0.7 + (math.random(1, 100) - 1) * (0.35 / 99)
                        end
                    end

                    local speed_divisor = speed_divisor_base * effectiveMultiplier
                    local Parry_Accuracy = Ping_Threshold + math.max(Speed / speed_divisor, 9.5)

                    local Curved = Auto_Parry.Is_Curved()

                    if Ball:FindFirstChild("AeroDynamicSlashVFX") then
                        Debris:AddItem(Ball.AeroDynamicSlashVFX, 0)
                        Tornado_Time = tick()
                    end

                    if Runtime and Runtime:FindFirstChild("Tornado") then
                        if (tick() - Tornado_Time) < (Runtime.Tornado:GetAttribute("TornadoTime") or 1) + 0.314159 then
                            return
                        end
                    end

                    if One_Target == tostring(Player) and Curved then return end
                    if Ball:FindFirstChild("ComboCounter") then return end

                    local Singularity_Cape = Player.Character.PrimaryPart:FindFirstChild("SingularityCape")
                    if Singularity_Cape then return end

                    if getgenv().InfinityDetection and Infinity then return end

                    if Ball_Target == tostring(Player) and Distance <= Parry_Accuracy then
                        local Parry_Time = os.clock()
                        local Time_View = Parry_Time - Last_Parry

                        if Time_View > 0.5 then
                            Auto_Parry.Parry_Animation()
                        end

                        Auto_Parry.Do_Parry(Selected_Parry_Type)
                        Last_Parry = Parry_Time
                        Parried = true
                    end

                    local Last_Parrys = tick()
                    repeat
                        RunService.PreSimulation:Wait()
                    until (tick() - Last_Parrys) >= 1 or not Parried
                    Parried = false
                end
            end)
        else
            if Connections_Manager["Auto Parry"] then
                Connections_Manager["Auto Parry"]:Disconnect()
                Connections_Manager["Auto Parry"] = nil
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

BlatantLeft:AddToggle("RandomAccuracy", {
    Text = "Random Accuracy",
    Default = false,
    Callback = function(Value)
        getgenv().RandomParryAccuracyEnabled = Value
    end
})

BlatantLeft:AddToggle("InfinityDetect", {
    Text = "Infinity Detection",
    Default = false,
    Callback = function(Value)
        getgenv().InfinityDetection = Value
    end
})

BlatantLeft:AddToggle("KeypressMode", {
    Text = "Keypress Mode",
    Default = false,
    Callback = function(Value)
        getgenv().AutoParryKeypress = Value
    end
})

BlatantLeft:AddToggle("SlashFuryDetect", {
    Text = "Slash of Fury Detection",
    Default = false,
    Callback = function(Value)
        getgenv().SlashOfFuryDetection = Value
    end
})

local BlatantRight = Tabs.Blatant:AddRightGroupbox("Lobby AP", "home")

BlatantRight:AddToggle("LobbyAPToggle", {
    Text = "Lobby Auto Parry",
    Default = false,
    Callback = function(Value)
        if Value then
            Connections_Manager["Lobby AP"] = RunService.Heartbeat:Connect(function()
                local Ball = Auto_Parry.Lobby_Balls()
                if not Ball then return end
                if not Player.Character or not Player.Character.PrimaryPart then return end

                local Zoomies = Ball:FindFirstChild("zoomies")
                if not Zoomies then return end

                Ball:GetAttributeChangedSignal("target"):Once(function()
                    Training_Parried = false
                end)

                if Training_Parried then return end

                local Ball_Target = Ball:GetAttribute("target")
                local Velocity = Zoomies.VectorVelocity
                local Distance = Player:DistanceFromCharacter(Ball.Position)
                local Speed = Velocity.Magnitude
                local Ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() / 10

                local LobbyAPcappedSpeedDiff = math.min(math.max(Speed - 9.5, 0), 650)
                local LobbyAPspeed_divisor_base = 2.4 + LobbyAPcappedSpeedDiff * 0.002
                local LobbyAPeffectiveMultiplier = LobbyAP_Speed_Divisor_Multiplier

                if getgenv().LobbyAPRandomParryAccuracyEnabled then
                    LobbyAPeffectiveMultiplier = 0.7 + (math.random(1, 100) - 1) * (0.35 / 99)
                end

                local LobbyAPspeed_divisor = LobbyAPspeed_divisor_base * LobbyAPeffectiveMultiplier
                local LobbyAPParry_Accuracys = Ping + math.max(Speed / LobbyAPspeed_divisor, 9.5)

                if Ball_Target == tostring(Player) and Distance <= LobbyAPParry_Accuracys then
                    Auto_Parry.Do_Parry(Selected_Parry_Type)
                    Training_Parried = true
                end

                local Last_Parrys = tick()
                repeat
                    RunService.PreSimulation:Wait()
                until (tick() - Last_Parrys) >= 1 or not Training_Parried
                Training_Parried = false
            end)
        else
            if Connections_Manager["Lobby AP"] then
                Connections_Manager["Lobby AP"]:Disconnect()
                Connections_Manager["Lobby AP"] = nil
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

BlatantRight:AddToggle("LobbyRandomAccuracy", {
    Text = "Random Accuracy",
    Default = false,
    Callback = function(Value)
        getgenv().LobbyAPRandomParryAccuracyEnabled = Value
    end
})

local SpamGroup = Tabs.Blatant:AddRightGroupbox("Auto Spam", "repeat")

SpamGroup:AddToggle("AutoSpamToggle", {
    Text = "Auto Spam Parry",
    Default = false,
    Callback = function(Value)
        if Value then
            Connections_Manager["Auto Spam"] = RunService.PreSimulation:Connect(function()
                local Ball = Auto_Parry.Get_Ball()
                if not Ball then return end
                if not Player.Character or not Player.Character.PrimaryPart then return end

                local Zoomies = Ball:FindFirstChild("zoomies")
                if not Zoomies then return end

                Auto_Parry.Closest_Player()
                if not Closest_Entity or not Closest_Entity.PrimaryPart then return end

                local Ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
                local Ping_Threshold = math.clamp(Ping / 10, 18.5, 70)
                local Ball_Target = Ball:GetAttribute("target")

                local Velocity = Zoomies.VectorVelocity
                local Speed = Velocity.Magnitude
                local Distance = Player:DistanceFromCharacter(Ball.Position)
                local Target_Distance = Player:DistanceFromCharacter(Closest_Entity.PrimaryPart.Position)
                local Maximum_Spam_Distance = Ping_Threshold + math.min(Speed / 6, 95)

                if not Ball_Target then return end
                if Target_Distance > Maximum_Spam_Distance or Distance > Maximum_Spam_Distance then return end

                local Pulsed = Player.Character:GetAttribute("Pulsed")
                if Pulsed then return end

                if Ball_Target == tostring(Player) and Target_Distance > 25 and Distance > 25 then return end

                if Distance <= Maximum_Spam_Distance and Parries > 2.5 then
                    Auto_Parry.Do_Parry(Selected_Parry_Type)
                end
            end)
        else
            if Connections_Manager["Auto Spam"] then
                Connections_Manager["Auto Spam"]:Disconnect()
                Connections_Manager["Auto Spam"] = nil
            end
        end
    end
})

local StrafeSpeed = 36
local spinSpeed = 5

local PlayerLeft = Tabs.Player:AddLeftGroupbox("Movement", "move")

PlayerLeft:AddToggle("SpeedToggle", {
    Text = "Speed Hack",
    Default = false,
    Callback = function(Value)
        if Value then
            Connections_Manager["Speed"] = RunService.Heartbeat:Connect(function()
                if Player.Character and Player.Character:FindFirstChild("Humanoid") then
                    Player.Character.Humanoid.WalkSpeed = StrafeSpeed
                end
            end)
        else
            if Player.Character and Player.Character:FindFirstChild("Humanoid") then
                Player.Character.Humanoid.WalkSpeed = 36
            end
            if Connections_Manager["Speed"] then
                Connections_Manager["Speed"]:Disconnect()
                Connections_Manager["Speed"] = nil
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
            Connections_Manager["FOV"] = RunService.RenderStepped:Connect(function()
                if getgenv().CustomFOV then
                    workspace.CurrentCamera.FieldOfView = getgenv().FOVValue or 70
                end
            end)
        else
            workspace.CurrentCamera.FieldOfView = 70
            if Connections_Manager["FOV"] then
                Connections_Manager["FOV"]:Disconnect()
                Connections_Manager["FOV"] = nil
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

local function CreateESP(plr)
    if plr == Player then return end

    local function Setup(char)
        if not char then return end
        task.wait(1)

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
                    Connections_Manager[plr.Name .. "_Health"] = humanoid.HealthChanged:Connect(function(health)
                        healthLabel.Text = math.floor(health) .. "/" .. math.floor(humanoid.MaxHealth)
                        local ratio = health / humanoid.MaxHealth
                        healthLabel.TextColor3 = Color3.fromRGB(255 * (1 - ratio), 255 * ratio, 0)
                    end)
                end
            end
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

    if plr.Character then Setup(plr.Character) end
    Connections_Manager[plr.Name .. "_CharAdded"] = plr.CharacterAdded:Connect(Setup)
end

local function RemoveESP(plr)
    if ESPObjects[plr.Name] then
        for _, obj in pairs(ESPObjects[plr.Name]) do
            pcall(function() obj:Destroy() end)
        end
        ESPObjects[plr.Name] = nil
    end
    if Connections_Manager[plr.Name .. "_Health"] then
        Connections_Manager[plr.Name .. "_Health"]:Disconnect()
        Connections_Manager[plr.Name .. "_Health"] = nil
    end
    if Connections_Manager[plr.Name .. "_CharAdded"] then
        Connections_Manager[plr.Name .. "_CharAdded"]:Disconnect()
        Connections_Manager[plr.Name .. "_CharAdded"] = nil
    end
end

local function RefreshAllESP()
    for _, plr in pairs(Players:GetPlayers()) do
        RemoveESP(plr)
    end
    if getgenv().BoxESPEnabled or getgenv().NameESPEnabled or getgenv().SkeletonESPEnabled then
        for _, plr in pairs(Players:GetPlayers()) do
            CreateESP(plr)
        end
    end
end

Players.PlayerAdded:Connect(function(plr)
    if getgenv().BoxESPEnabled or getgenv().NameESPEnabled or getgenv().SkeletonESPEnabled then
        CreateESP(plr)
    end
end)

Players.PlayerRemoving:Connect(RemoveESP)

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

            Connections_Manager["BallTracer"] = RunService.RenderStepped:Connect(function()
                local Ball = Auto_Parry.Get_Ball()
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
            if Connections_Manager["BallTracer"] then
                Connections_Manager["BallTracer"]:Disconnect()
                Connections_Manager["BallTracer"] = nil
            end
        end
    end
})

VisualsRight:AddToggle("BallTrail", {
    Text = "Ball Trail",
    Default = false,
    Callback = function(Value)
        if Value then
            Connections_Manager["BallTrail"] = RunService.RenderStepped:Connect(function()
                local Ball = Auto_Parry.Get_Ball()
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
                        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 255))
                    })
                end
            end)
        else
            if Connections_Manager["BallTrail"] then
                Connections_Manager["BallTrail"]:Disconnect()
                Connections_Manager["BallTrail"] = nil
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
            Connections_Manager["BallHighlight"] = RunService.RenderStepped:Connect(function()
                local Ball = Auto_Parry.Get_Ball()
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
            if Connections_Manager["BallHighlight"] then
                Connections_Manager["BallHighlight"]:Disconnect()
                Connections_Manager["BallHighlight"] = nil
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
            Connections_Manager["Rainbow"] = RunService.RenderStepped:Connect(function()
                hue = (hue + 1) % 360
                cc.TintColor = Color3.fromHSV(hue / 360, 1, 1)
            end)
        else
            local cc = Lighting:FindFirstChild("InvictusRainbow")
            if cc then cc:Destroy() end
            if Connections_Manager["Rainbow"] then
                Connections_Manager["Rainbow"]:Disconnect()
                Connections_Manager["Rainbow"] = nil
            end
        end
    end
})

WorldLeft:AddToggle("ViewBall", {
    Text = "View Ball",
    Default = false,
    Callback = function(Value)
        if Value then
            Connections_Manager["ViewBall"] = RunService.RenderStepped:Connect(function()
                local Ball = Auto_Parry.Get_Ball()
                if Ball then
                    workspace.CurrentCamera.CameraSubject = Ball
                end
            end)
        else
            workspace.CurrentCamera.CameraSubject = Player.Character or Player
            if Connections_Manager["ViewBall"] then
                Connections_Manager["ViewBall"]:Disconnect()
                Connections_Manager["ViewBall"] = nil
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
        for _, conn in pairs(Connections_Manager) do
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
    Description = "Loaded!\nDeveloper: Entropy\ndiscord.gg/nbPHzKzafN",
    Time = 5
})
