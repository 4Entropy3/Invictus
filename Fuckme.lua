if _G.InvictusLoaded then
    warn("Invictus already loaded. Preventing duplicate execution.")
    return
end
_G.InvictusLoaded = true

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")

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
    Main = Color3.fromRGB(25, 25, 25),
    Second = Color3.fromRGB(32, 32, 32),
    Stroke = Color3.fromRGB(60, 60, 60),
    Divider = Color3.fromRGB(50, 50, 50),
    Text = Color3.fromRGB(255, 255, 255),
    TextDark = Color3.fromRGB(180, 180, 180),
})

local Tabs = {
    Blatant = Window:AddTab("Blatant", "zap"),
    Player = Window:AddTab("Player", "user"),
    World = Window:AddTab("World", "globe"),
    Misc = Window:AddTab("Misc", "settings"),
    Settings = Window:AddTab("Settings", "sliders"),
}

local Tornado_Time = tick()
local Last_Input = UserInputService:GetLastInputType()
local Vector2_Mouse_Location = nil
local Grab_Parry = nil
local Remotes = {}
local Parry_Key = nil
local Speed_Divisor_Multiplier = 1.1
local LobbyAP_Speed_Divisor_Multiplier = 1.1
local firstParryFired = false
local ParryThreshold = 2.5
local firstParryType = "F_Key"
local Previous_Positions = {}
local Parries = 0
local Connections_Manager = {}
local Selected_Parry_Type = "Camera"
local Infinity = false
local Parried = false
local Last_Parry = 0
local AutoParry = true
local Balls = workspace:WaitForChild("Balls")
local CurrentBall = nil
local InputTask = nil
local Cooldown = 0.02
local RunTime = workspace:FindFirstChild("Runtime")
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

local function performFirstPress(parryType)
    if parryType == "F_Key" then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, nil)
    elseif parryType == "Left_Click" then
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    elseif parryType == "Navigation" then
        local button = Players.LocalPlayer.PlayerGui.Hotbar.Block
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
        task.wait(0.01)
    end
end

local PropertyChangeOrder = {}
local HashOne, HashTwo, HashThree

pcall(function()
    for Index, Value in next, getgc() do
        if rawequal(typeof(Value), "function") and islclosure(Value) and getrenv().debug.info(Value, "s"):find("SwordsController") then
            if rawequal(getrenv().debug.info(Value, "l"), 276) then
                HashOne = getconstant(Value, 62)
                HashTwo = getconstant(Value, 64)
                HashThree = getconstant(Value, 65)
            end
        end
    end
end)

pcall(function()
    for Index, Object in next, game:GetDescendants() do
        if Object:IsA("RemoteEvent") and string.find(Object.Name, "\n") then
            Object.Changed:Once(function()
                table.insert(PropertyChangeOrder, Object)
            end)
        end
    end
end)

repeat task.wait() until #PropertyChangeOrder == 3

local ShouldPlayerJump = PropertyChangeOrder[1]
local MainRemote = PropertyChangeOrder[2]
local GetOpponentPosition = PropertyChangeOrder[3]

pcall(function()
    for Index, Value in pairs(getconnections(game:GetService("Players").LocalPlayer.PlayerGui.Hotbar.Block.Activated)) do
        if Value and Value.Function and not iscclosure(Value.Function) then
            for Index2, Value2 in pairs(getupvalues(Value.Function)) do
                if type(Value2) == "function" then
                    Parry_Key = getupvalue(getupvalue(Value2, 2), 17)
                end
            end
        end
    end
end)

local function Parry(...)
    ShouldPlayerJump:FireServer(HashOne, Parry_Key, ...)
    MainRemote:FireServer(HashTwo, Parry_Key, ...)
    GetOpponentPosition:FireServer(HashThree, Parry_Key, ...)
end

function create_animation(object, info, value)
    local animation = TweenService:Create(object, info, value)
    animation:Play()
    task.wait(info.Time)
    Debris:AddItem(animation, 0)
    animation:Destroy()
    animation = nil
end

local Animation = {}
Animation.storage = {}
Animation.current = nil
Animation.track = nil

for _, v in pairs(game:GetService("ReplicatedStorage").Misc.Emotes:GetChildren()) do
    if v:IsA("Animation") and v:GetAttribute("EmoteName") then
        local Emote_Name = v:GetAttribute("EmoteName")
        Animation.storage[Emote_Name] = v
    end
end

local Emotes_Data = {}
for Object in pairs(Animation.storage) do
    table.insert(Emotes_Data, Object)
end
table.sort(Emotes_Data)

local Auto_Parry = {}

function Auto_Parry.Parry_Animation()
    local Parry_Animation = game:GetService("ReplicatedStorage").Shared.SwordAPI.Collection.Default:FindFirstChild("GrabParry")
    local Current_Sword = Player.Character:GetAttribute("CurrentlyEquippedSword")
    if not Current_Sword then return end
    if not Parry_Animation then return end
    local Sword_Data = game:GetService("ReplicatedStorage").Shared.ReplicatedInstances.Swords.GetSword:Invoke(Current_Sword)
    if not Sword_Data or not Sword_Data["AnimationType"] then return end
    for _, object in pairs(game:GetService("ReplicatedStorage").Shared.SwordAPI.Collection:GetChildren()) do
        if object.Name == Sword_Data["AnimationType"] then
            if object:FindFirstChild("GrabParry") or object:FindFirstChild("Grab") then
                local sword_animation_type = "GrabParry"
                if object:FindFirstChild("Grab") then
                    sword_animation_type = "Grab"
                end
                Parry_Animation = object[sword_animation_type]
            end
        end
    end
    Grab_Parry = Player.Character.Humanoid.Animator:LoadAnimation(Parry_Animation)
    Grab_Parry:Play()
end

function Auto_Parry.Play_Animation(v)
    local Animations = Animation.storage[v]
    if not Animations then return false end
    local Animator = Player.Character.Humanoid.Animator
    if Animation.track then
        Animation.track:Stop()
    end
    Animation.track = Animator:LoadAnimation(Animations)
    Animation.track:Play()
    Animation.current = v
end

function Auto_Parry.Get_Balls()
    local BallsTable = {}
    for _, Instance in pairs(workspace.Balls:GetChildren()) do
        if Instance:GetAttribute("realBall") then
            Instance.CanCollide = false
            table.insert(BallsTable, Instance)
        end
    end
    return BallsTable
end

function Auto_Parry.Get_Ball()
    for _, Instance in pairs(workspace.Balls:GetChildren()) do
        if Instance:GetAttribute("realBall") then
            Instance.CanCollide = false
            return Instance
        end
    end
end

function Auto_Parry.Lobby_Balls()
    for _, Instance in pairs(workspace.TrainingBalls:GetChildren()) do
        if Instance:GetAttribute("realBall") then
            return Instance
        end
    end
end

local Closest_Entity = nil

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

function Auto_Parry:Get_Entity_Properties()
    Auto_Parry.Closest_Player()
    if not Closest_Entity then return false end
    local Entity_Velocity = Closest_Entity.PrimaryPart.Velocity
    local Entity_Direction = (Player.Character.PrimaryPart.Position - Closest_Entity.PrimaryPart.Position).Unit
    local Entity_Distance = (Player.Character.PrimaryPart.Position - Closest_Entity.PrimaryPart.Position).Magnitude
    return {
        Velocity = Entity_Velocity,
        Direction = Entity_Direction,
        Distance = Entity_Distance
    }
end

function Auto_Parry.Parry_Data(Parry_Type)
    Auto_Parry.Closest_Player()
    local Events = {}
    local Camera = workspace.CurrentCamera
    local Vector2_Mouse_Location
    if Last_Input == Enum.UserInputType.MouseButton1 or (Enum.UserInputType.MouseButton2 or Last_Input == Enum.UserInputType.Keyboard) then
        local Mouse_Location = UserInputService:GetMouseLocation()
        Vector2_Mouse_Location = {Mouse_Location.X, Mouse_Location.Y}
    else
        Vector2_Mouse_Location = {Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2}
    end
    if isMobile then
        Vector2_Mouse_Location = {Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2}
    end
    local Players_Screen_Positions = {}
    for _, v in pairs(workspace.Alive:GetChildren()) do
        if v ~= Player.Character then
            local worldPos = v.PrimaryPart.Position
            local screenPos, isOnScreen = Camera:WorldToScreenPoint(worldPos)
            if isOnScreen then
                Players_Screen_Positions[v] = Vector2.new(screenPos.X, screenPos.Y)
            end
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
        local Aimed_Player = nil
        local Closest_Distance = math.huge
        local Mouse_Vector = Vector2.new(Vector2_Mouse_Location[1], Vector2_Mouse_Location[2])
        for _, v in pairs(workspace.Alive:GetChildren()) do
            if v ~= Player.Character then
                local worldPos = v.PrimaryPart.Position
                local screenPos, isOnScreen = Camera:WorldToScreenPoint(worldPos)
                if isOnScreen then
                    local playerScreenPos = Vector2.new(screenPos.X, screenPos.Y)
                    local distance = (Mouse_Vector - playerScreenPos).Magnitude
                    if distance < Closest_Distance then
                        Closest_Distance = distance
                        Aimed_Player = v
                    end
                end
            end
        end
        if Aimed_Player then
            return {0, CFrame.new(Player.Character.PrimaryPart.Position, Aimed_Player.PrimaryPart.Position), Events, Vector2_Mouse_Location}
        else
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
    if Parry_Type == "RandomTarget" then
        local candidates = {}
        for _, v in pairs(workspace.Alive:GetChildren()) do
            if v ~= Player.Character and v.PrimaryPart then
                local screenPos, isOnScreen = Camera:WorldToScreenPoint(v.PrimaryPart.Position)
                if isOnScreen then
                    table.insert(candidates, {
                        character = v,
                        screenXY = {screenPos.X, screenPos.Y}
                    })
                end
            end
        end
        if #candidates > 0 then
            local pick = candidates[math.random(1, #candidates)]
            local lookCFrame = CFrame.new(Player.Character.PrimaryPart.Position, pick.character.PrimaryPart.Position)
            return {0, lookCFrame, Events, pick.screenXY}
        else
            return {0, Camera.CFrame, Events, {Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2}}
        end
    end
    return Parry_Type
end

function Auto_Parry.Parry(Parry_Type)
    local Parry_Data = Auto_Parry.Parry_Data(Parry_Type)
    if not firstParryFired then
        performFirstPress(firstParryType)
        firstParryFired = true
    else
        Parry(Parry_Data[1], Parry_Data[2], Parry_Data[3], Parry_Data[4])
    end
    if Parries > 7 then return false end
    Parries += 1
    task.delay(0.5, function()
        if Parries > 0 then
            Parries -= 1
        end
    end)
end

local Lerp_Radians = 0
local Last_Warping = tick()

function Auto_Parry.Linear_Interpolation(a, b, time_volume)
    return a + (b - a) * time_volume
end

local Previous_Velocity = {}
local Curving = tick()
local Runtime = workspace.Runtime

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
    if Lerp_Radians < 0.018 then
        Last_Warping = tick()
    end
    if (tick() - Last_Warping) < (Reach_Time / 1.5) then return true end
    if (tick() - Curving) < (Reach_Time / 1.5) then return true end
    return Dot < Dot_Threshold
end

function Auto_Parry:Get_Ball_Properties()
    local Ball = Auto_Parry.Get_Ball()
    local Ball_Velocity = Vector3.zero
    local Ball_Origin = Ball
    local Ball_Direction = (Player.Character.PrimaryPart.Position - Ball_Origin.Position).Unit
    local Ball_Distance = (Player.Character.PrimaryPart.Position - Ball.Position).Magnitude
    local Ball_Dot = Ball_Direction:Dot(Ball_Velocity.Unit)
    return {
        Velocity = Ball_Velocity,
        Direction = Ball_Direction,
        Distance = Ball_Distance,
        Dot = Ball_Dot
    }
end

function Auto_Parry.Spam_Service(self)
    local Ball = Auto_Parry.Get_Ball()
    local Entity = Auto_Parry.Closest_Player()
    if not Ball then return false end
    if not Entity or not Entity.PrimaryPart then return false end
    local Spam_Accuracy = 0
    local Velocity = Ball.AssemblyLinearVelocity
    local Speed = Velocity.Magnitude
    local Direction = (Player.Character.PrimaryPart.Position - Ball.Position).Unit
    local Dot = Direction:Dot(Velocity.Unit)
    local Target_Position = Entity.PrimaryPart.Position
    local Target_Distance = Player:DistanceFromCharacter(Target_Position)
    local Maximum_Spam_Distance = self.Ping + math.min(Speed / 6, 95)
    if self.Entity_Properties.Distance > Maximum_Spam_Distance then return Spam_Accuracy end
    if self.Ball_Properties.Distance > Maximum_Spam_Distance then return Spam_Accuracy end
    if Target_Distance > Maximum_Spam_Distance then return Spam_Accuracy end
    local Maximum_Speed = 5 - math.min(Speed / 5, 5)
    local Maximum_Dot = math.clamp(Dot, -1, 0) * Maximum_Speed
    Spam_Accuracy = Maximum_Spam_Distance - Maximum_Dot
    return Spam_Accuracy
end

ReplicatedStorage.Remotes.InfinityBall.OnClientEvent:Connect(function(a, b)
    if b then
        Infinity = true
    else
        Infinity = false
    end
end)

local function GetBall()
    for _, Ball in ipairs(Balls:GetChildren()) do
        if Ball:FindFirstChild("ff") then
            return Ball
        end
    end
    return nil
end

local function SpamInput(Label)
    if InputTask then return end
    InputTask = task.spawn(function()
        while AutoParry do
            Auto_Parry.Parry(Selected_Parry_Type)
            task.wait(Cooldown)
        end
        InputTask = nil
    end)
end

Balls.ChildAdded:Connect(function(Value)
    Value.ChildAdded:Connect(function(Child)
        if getgenv().SlashOfFuryDetection and Child.Name == "ComboCounter" then
            local Sof_Label = Child:FindFirstChildOfClass("TextLabel")
            if Sof_Label then
                repeat
                    local Slashes_Counter = tonumber(Sof_Label.Text)
                    if Slashes_Counter and Slashes_Counter < 32 then
                        Auto_Parry.Parry(Selected_Parry_Type)
                    end
                    task.wait()
                until not Sof_Label.Parent or not Sof_Label
            end
        end
    end)
end)

Runtime.ChildAdded:Connect(function(Object)
    local Name = Object.Name
    if getgenv().PhantomV2Detection then
        if Name == "maxTransmission" or Name == "transmissionpart" then
            local Weld = Object:FindFirstChildWhichIsA("WeldConstraint")
            if Weld then
                local Character = Player.Character or Player.CharacterAdded:Wait()
                if Character and Weld.Part1 == Character.HumanoidRootPart then
                    CurrentBall = GetBall()
                    Weld:Destroy()
                    if CurrentBall then
                        local FocusConnection
                        FocusConnection = RunService.RenderStepped:Connect(function()
                            local Highlighted = CurrentBall:GetAttribute("highlighted")
                            if Highlighted == true then
                                Player.Character.Humanoid.WalkSpeed = 36
                                local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
                                if HumanoidRootPart then
                                    local PlayerPosition = HumanoidRootPart.Position
                                    local BallPosition = CurrentBall.Position
                                    local PlayerToBall = (BallPosition - PlayerPosition).Unit
                                    Player.Character.Humanoid:Move(PlayerToBall, false)
                                end
                            elseif Highlighted == false then
                                FocusConnection:Disconnect()
                                Player.Character.Humanoid.WalkSpeed = 10
                                Player.Character.Humanoid:Move(Vector3.new(0, 0, 0), false)
                                task.delay(3, function()
                                    Player.Character.Humanoid.WalkSpeed = 36
                                end)
                                CurrentBall = nil
                            end
                        end)
                        task.delay(3, function()
                            if FocusConnection and FocusConnection.Connected then
                                FocusConnection:Disconnect()
                                Player.Character.Humanoid:Move(Vector3.new(0, 0, 0), false)
                                Player.Character.Humanoid.WalkSpeed = 36
                                CurrentBall = nil
                            end
                        end)
                    end
                end
            end
        end
    end
end)

local playerGui = Player:WaitForChild("PlayerGui")
local Hotbar = playerGui:WaitForChild("Hotbar")
local ParryCD = playerGui.Hotbar.Block.UIGradient
local AbilityCD = playerGui.Hotbar.Ability.UIGradient

local function isCooldownInEffect1(uigradient)
    return uigradient.Offset.Y < 0.4
end

local function isCooldownInEffect2(uigradient)
    return uigradient.Offset.Y == 0.5
end

local function cooldownProtection()
    if isCooldownInEffect1(ParryCD) then
        game:GetService("ReplicatedStorage").Remotes.AbilityButtonPress:Fire()
        return true
    end
    return false
end

local function AutoAbility()
    if isCooldownInEffect2(AbilityCD) then
        if Player.Character.Abilities["Raging Deflection"].Enabled or Player.Character.Abilities["Rapture"].Enabled or Player.Character.Abilities["Calming Deflection"].Enabled or Player.Character.Abilities["Aerodynamic Slash"].Enabled or Player.Character.Abilities["Fracture"].Enabled or Player.Character.Abilities["Death Slash"].Enabled then
            Parried = true
            game:GetService("ReplicatedStorage").Remotes.AbilityButtonPress:Fire()
            task.wait(2.432)
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("DeathSlashShootActivation"):FireServer(true)
            return true
        end
    end
    return false
end

local BlatantLeft = Tabs.Blatant:AddLeftGroupbox("Auto Parry", "zap")

BlatantLeft:AddToggle("AutoParryToggle", {
    Text = "Auto Parry",
    Default = false,
    Tooltip = "Automatically parries the ball",
    Callback = function(Value)
        if Value then
            Connections_Manager["Auto Parry"] = RunService.PreSimulation:Connect(function()
                local One_Ball = Auto_Parry.Get_Ball()
                local BallsList = Auto_Parry.Get_Balls()
                for _, Ball in pairs(BallsList) do
                    if not Ball then return end
                    local Zoomies = Ball:FindFirstChild("zoomies")
                    if not Zoomies then return end
                    Ball:GetAttributeChangedSignal("target"):Once(function()
                        Parried = false
                    end)
                    if Parried then return end
                    local Ball_Target = Ball:GetAttribute("target")
                    local One_Target = One_Ball:GetAttribute("target")
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
                    if Runtime:FindFirstChild("Tornado") then
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
                        if getgenv().AutoAbility and AutoAbility() then return end
                    end
                    if Ball_Target == tostring(Player) and Distance <= Parry_Accuracy then
                        if getgenv().CooldownProtection and cooldownProtection() then return end
                        local Parry_Time = os.clock()
                        local Time_View = Parry_Time - (Last_Parry)
                        if Time_View > 0.5 then
                            Auto_Parry.Parry_Animation()
                        end
                        if getgenv().AutoParryKeypress then
                            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, nil)
                        else
                            Auto_Parry.Parry(Selected_Parry_Type)
                        end
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

local parryTypeMap = {
    ["Camera"] = "Camera",
    ["Random"] = "Random",
    ["Backwards"] = "Backwards",
    ["Straight"] = "Straight",
    ["High"] = "High",
    ["Left"] = "Left",
    ["Right"] = "Right",
    ["Random Target"] = "RandomTarget"
}

BlatantLeft:AddDropdown("CurveTypeDropdown", {
    Text = "Curve Type",
    Values = {"Camera", "Random", "Backwards", "Straight", "High", "Left", "Right", "Random Target"},
    Default = "Camera",
    Callback = function(Value)
        Selected_Parry_Type = parryTypeMap[Value] or Value
    end
})

BlatantLeft:AddSlider("ParryAccuracySlider", {
    Text = "Parry Accuracy",
    Default = 100,
    Min = -5,
    Max = 100,
    Rounding = 0,
    Callback = function(Value)
        Speed_Divisor_Multiplier = 0.7 + (Value - 1) * (0.35 / 99)
    end
})

BlatantLeft:AddDivider()

BlatantLeft:AddToggle("RandomParryAccuracy", {
    Text = "Randomized Parry Accuracy",
    Default = false,
    Callback = function(Value)
        getgenv().RandomParryAccuracyEnabled = Value
    end
})

BlatantLeft:AddToggle("PhantomDetection", {
    Text = "Phantom Detection",
    Default = false,
    Callback = function(Value)
        getgenv().PhantomV2Detection = Value
    end
})

BlatantLeft:AddToggle("InfinityDetection", {
    Text = "Infinity Detection",
    Default = false,
    Callback = function(Value)
        getgenv().InfinityDetection = Value
    end
})

BlatantLeft:AddToggle("AutoParryKeypress", {
    Text = "Keypress Mode",
    Default = false,
    Callback = function(Value)
        getgenv().AutoParryKeypress = Value
    end
})

local BlatantRight = Tabs.Blatant:AddRightGroupbox("Auto Spam", "repeat")

BlatantRight:AddToggle("AutoSpamToggle", {
    Text = "Auto Spam Parry",
    Default = false,
    Tooltip = "Automatically spam parries the ball",
    Callback = function(Value)
        if Value then
            Connections_Manager["Auto Spam"] = RunService.PreSimulation:Connect(function()
                local Ball = Auto_Parry.Get_Ball()
                if not Ball then return end
                local Zoomies = Ball:FindFirstChild("zoomies")
                if not Zoomies then return end
                Auto_Parry.Closest_Player()
                local Ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
                local Ping_Threshold = math.clamp(Ping / 10, 18.5, 70)
                local Ball_Target = Ball:GetAttribute("target")
                local Ball_Properties = Auto_Parry:Get_Ball_Properties()
                local Entity_Properties = Auto_Parry:Get_Entity_Properties()
                local Spam_Accuracy = Auto_Parry.Spam_Service({
                    Ball_Properties = Ball_Properties,
                    Entity_Properties = Entity_Properties,
                    Ping = Ping_Threshold
                })
                local Target_Position = Closest_Entity.PrimaryPart.Position
                local Target_Distance = Player:DistanceFromCharacter(Target_Position)
                local Direction = (Player.Character.PrimaryPart.Position - Ball.Position).Unit
                local Ball_Direction = Zoomies.VectorVelocity.Unit
                local Dot = Direction:Dot(Ball_Direction)
                local Distance = Player:DistanceFromCharacter(Ball.Position)
                if not Ball_Target then return end
                if Target_Distance > Spam_Accuracy or Distance > Spam_Accuracy then return end
                local Pulsed = Player.Character:GetAttribute("Pulsed")
                if Pulsed then return end
                if Ball_Target == tostring(Player) and Target_Distance > 25 and Distance > 25 then return end
                local threshold = ParryThreshold
                if Distance <= Spam_Accuracy and Parries > threshold then
                    if getgenv().SpamParryKeypress then
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
                    else
                        Auto_Parry.Parry(Selected_Parry_Type)
                    end
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

BlatantRight:AddSlider("SpamThresholdSlider", {
    Text = "Spam Threshold",
    Default = 2.5,
    Min = 1,
    Max = 3,
    Rounding = 1,
    Callback = function(Value)
        ParryThreshold = Value
    end
})

local LobbyGroup = Tabs.Blatant:AddLeftGroupbox("Lobby AP", "home")

LobbyGroup:AddToggle("LobbyAPToggle", {
    Text = "Lobby Auto Parry",
    Default = false,
    Tooltip = "Automatically parries in lobby",
    Callback = function(Value)
        if Value then
            Connections_Manager["Lobby AP"] = RunService.Heartbeat:Connect(function()
                local Ball = Auto_Parry.Lobby_Balls()
                if not Ball then return end
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
                    if getgenv().LobbyAPKeypress then
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
                    else
                        Auto_Parry.Parry(Selected_Parry_Type)
                    end
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

LobbyGroup:AddSlider("LobbyAPAccuracySlider", {
    Text = "Lobby AP Accuracy",
    Default = 100,
    Min = 1,
    Max = 100,
    Rounding = 0,
    Callback = function(Value)
        LobbyAP_Speed_Divisor_Multiplier = 0.7 + (Value - 1) * (0.325 / 99)
    end
})

LobbyGroup:AddToggle("LobbyAPRandomAccuracy", {
    Text = "Randomized Lobby Accuracy",
    Default = false,
    Callback = function(Value)
        getgenv().LobbyAPRandomParryAccuracyEnabled = Value
    end
})

LobbyGroup:AddToggle("LobbyAPKeypress", {
    Text = "Keypress Mode",
    Default = false,
    Callback = function(Value)
        getgenv().LobbyAPKeypress = Value
    end
})

local StrafeSpeed = 36

local PlayerLeft = Tabs.Player:AddLeftGroupbox("Movement", "move")

PlayerLeft:AddToggle("SpeedToggle", {
    Text = "Speed Hack",
    Default = false,
    Callback = function(Value)
        if Value then
            Connections_Manager["Strafe"] = RunService.PreSimulation:Connect(function()
                local character = Player.Character
                if character and character:FindFirstChild("Humanoid") then
                    character.Humanoid.WalkSpeed = StrafeSpeed
                end
            end)
        else
            local character = Player.Character
            if character and character:FindFirstChild("Humanoid") then
                character.Humanoid.WalkSpeed = 36
            end
            if Connections_Manager["Strafe"] then
                Connections_Manager["Strafe"]:Disconnect()
                Connections_Manager["Strafe"] = nil
            end
        end
    end
})

PlayerLeft:AddSlider("StrafeSpeedSlider", {
    Text = "Speed Value",
    Default = 36,
    Min = 36,
    Max = 200,
    Rounding = 0,
    Callback = function(Value)
        StrafeSpeed = Value
    end
})

PlayerLeft:AddToggle("NoSlowToggle", {
    Text = "No Slow",
    Default = false,
    Callback = function(Value)
        local noSlowConnection = nil
        local stateDisablers = {}
        local speedEnforcer = nil
        if Value then
            local character = Player.Character or Player.CharacterAdded:Wait()
            local humanoid = character:WaitForChild("Humanoid")
            local statesToDisable = {
                Enum.HumanoidStateType.Swimming,
                Enum.HumanoidStateType.Seated,
                Enum.HumanoidStateType.Climbing,
                Enum.HumanoidStateType.PlatformStanding
            }
            for _, state in ipairs(statesToDisable) do
                humanoid:SetStateEnabled(state, false)
                stateDisablers[state] = true
            end
            humanoid.WalkSpeed = 36
            Connections_Manager["NoSlow"] = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                if humanoid.WalkSpeed ~= 36 then
                    humanoid.WalkSpeed = 36
                end
            end)
            Connections_Manager["NoSlowEnforcer"] = RunService.RenderStepped:Connect(function()
                if humanoid and humanoid.WalkSpeed ~= 36 then
                    humanoid.WalkSpeed = 36
                end
            end)
        else
            local character = Player.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    for state, _ in pairs(stateDisablers) do
                        humanoid:SetStateEnabled(state, true)
                    end
                end
            end
            if Connections_Manager["NoSlow"] then
                Connections_Manager["NoSlow"]:Disconnect()
                Connections_Manager["NoSlow"] = nil
            end
            if Connections_Manager["NoSlowEnforcer"] then
                Connections_Manager["NoSlowEnforcer"]:Disconnect()
                Connections_Manager["NoSlowEnforcer"] = nil
            end
        end
    end
})

local flying = false
local ctrl = {f = 0, b = 0, l = 0, r = 0}
local lastCtrl = {f = 0, b = 0, l = 0, r = 0}
local speed = 0

local function Fly()
    local char = Player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Physics)
    end
    local bg = Instance.new("BodyGyro")
    local bv = Instance.new("BodyVelocity")
    bg.P = 9e4
    bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
    bg.cframe = hrp.CFrame
    bg.Parent = hrp
    bv.velocity = Vector3.new(0, 0.1, 0)
    bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Parent = hrp
    flying = true
    coroutine.wrap(function()
        while flying and Player.Character do
            if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
                speed = speed + 0.5 + (speed / 15)
                if speed > 50 then speed = 50 end
            elseif speed ~= 0 then
                speed = speed - 1
                if speed < 0 then speed = 0 end
            end
            if speed ~= 0 then
                bv.velocity = ((workspace.CurrentCamera.CFrame.lookVector * (ctrl.f + ctrl.b)) + (workspace.CurrentCamera.CFrame.RightVector * (ctrl.r + ctrl.l))) * speed
                lastCtrl = {f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r}
            else
                bv.velocity = Vector3.new(0, 0.1, 0)
            end
            bg.cframe = workspace.CurrentCamera.CFrame
            task.wait()
        end
        ctrl = {f = 0, b = 0, l = 0, r = 0}
        lastCtrl = {f = 0, b = 0, l = 0, r = 0}
        speed = 0
        bg:Destroy()
        bv:Destroy()
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)()
end

local function Unfly()
    flying = false
end

PlayerLeft:AddToggle("FlyToggle", {
    Text = "Fly",
    Default = false,
    Callback = function(Value)
        if Value then
            Fly()
        else
            Unfly()
        end
    end
})

local PlayerRight = Tabs.Player:AddRightGroupbox("Visuals", "eye")

PlayerRight:AddToggle("SpinbotToggle", {
    Text = "Spinbot",
    Default = false,
    Callback = function(Value)
        getgenv().Spinbot = Value
        if Value then
            getgenv().spin = true
            getgenv().spinSpeed = getgenv().spinSpeed or 1
            local function spinCharacter()
                while getgenv().spin do
                    RunService.Heartbeat:Wait()
                    local char = Player.Character
                    local funcHRP = char and char:FindFirstChild("HumanoidRootPart")
                    if char and funcHRP then
                        funcHRP.CFrame *= CFrame.Angles(0, getgenv().spinSpeed, 0)
                    end
                end
            end
            if not getgenv().spinThread then
                getgenv().spinThread = coroutine.create(spinCharacter)
                coroutine.resume(getgenv().spinThread)
            end
        else
            getgenv().spin = false
            if getgenv().spinThread then
                getgenv().spinThread = nil
            end
        end
    end
})

PlayerRight:AddSlider("SpinSpeedSlider", {
    Text = "Spin Speed",
    Default = 1,
    Min = 1,
    Max = 150,
    Rounding = 0,
    Callback = function(Value)
        getgenv().spinSpeed = math.rad(Value)
    end
})

PlayerRight:AddToggle("FOVToggle", {
    Text = "Custom FOV",
    Default = false,
    Callback = function(Value)
        getgenv().CameraEnabled = Value
        local Camera = workspace.CurrentCamera
        if Value then
            getgenv().CameraFOV = getgenv().CameraFOV or 70
            Camera.FieldOfView = getgenv().CameraFOV
            if not getgenv().FOVLoop then
                getgenv().FOVLoop = RunService.RenderStepped:Connect(function()
                    if getgenv().CameraEnabled then
                        Camera.FieldOfView = getgenv().CameraFOV
                    end
                end)
            end
        else
            Camera.FieldOfView = 70
            if getgenv().FOVLoop then
                getgenv().FOVLoop:Disconnect()
                getgenv().FOVLoop = nil
            end
        end
    end
})

PlayerRight:AddSlider("FOVSlider", {
    Text = "FOV Value",
    Default = 70,
    Min = 50,
    Max = 120,
    Rounding = 0,
    Callback = function(Value)
        getgenv().CameraFOV = Value
        if getgenv().CameraEnabled then
            workspace.CurrentCamera.FieldOfView = Value
        end
    end
})

local selected_animation = Emotes_Data[1] or ""
local Emotes_Enabled = false

PlayerRight:AddDropdown("EmoteDropdown", {
    Text = "Emotes",
    Values = Emotes_Data,
    Default = nil,
    Callback = function(Value)
        selected_animation = Value
        if Emotes_Enabled then
            Auto_Parry.Play_Animation(Value)
        end
    end
})

PlayerRight:AddToggle("EmoteToggle", {
    Text = "Play Emote",
    Default = false,
    Callback = function(Value)
        Emotes_Enabled = Value
        if Value and selected_animation then
            Auto_Parry.Play_Animation(selected_animation)
        else
            if Animation.track then
                Animation.track:Stop()
                Animation.track = nil
                Animation.current = nil
            end
        end
    end
})

local Sound_Effect = false
local sound_effect_type = "DC_15X"
local sound_assets = {
    DC_15X = "rbxassetid://936447863",
    Neverlose = "rbxassetid://8679627751",
    Minecraft = "rbxassetid://8766809464",
    MinecraftHit2 = "rbxassetid://8458185621",
    TeamfortressBonk = "rbxassetid://8255306220",
    TeamfortressBell = "rbxassetid://2868331684"
}

PlayerRight:AddToggle("HitSoundToggle", {
    Text = "Hit Sounds",
    Default = false,
    Callback = function(Value)
        Sound_Effect = Value
        if Value then
            Connections_Manager["SoundEffect"] = ReplicatedStorage.Remotes.ParrySuccess.OnClientEvent:Connect(function()
                if not Sound_Effect then return end
                local sound_id = sound_assets[sound_effect_type]
                if not sound_id then return end
                local sound = Instance.new("Sound")
                sound.SoundId = sound_id
                sound.Volume = 1
                sound.PlayOnRemove = true
                sound.Parent = workspace
                sound:Destroy()
            end)
        else
            if Connections_Manager["SoundEffect"] then
                Connections_Manager["SoundEffect"]:Disconnect()
                Connections_Manager["SoundEffect"] = nil
            end
        end
    end
})

PlayerRight:AddDropdown("SoundTypeDropdown", {
    Text = "Sound Type",
    Values = {"DC_15X", "Minecraft", "MinecraftHit2", "Neverlose", "TeamfortressBonk", "TeamfortressBell"},
    Default = "DC_15X",
    Callback = function(Value)
        sound_effect_type = Value
    end
})

local WorldLeft = Tabs.World:AddLeftGroupbox("Visual Effects", "sparkles")

local rainbowConnection = nil
local colorCorrection = nil

WorldLeft:AddToggle("RainbowHueToggle", {
    Text = "Rainbow Hue Filter",
    Default = false,
    Callback = function(Value)
        if Value then
            if not colorCorrection then
                colorCorrection = Instance.new("ColorCorrectionEffect")
                colorCorrection.Name = "RainbowFilter"
                colorCorrection.Saturation = 1
                colorCorrection.Contrast = 0.1
                colorCorrection.Brightness = 0
                colorCorrection.TintColor = Color3.fromRGB(255, 0, 0)
                colorCorrection.Parent = Lighting
            end
            local hue = 0
            rainbowConnection = RunService.RenderStepped:Connect(function()
                hue = (hue + 1) % 360
                local color = Color3.fromHSV(hue / 360, 1, 1)
                colorCorrection.TintColor = color
            end)
        else
            if rainbowConnection then
                rainbowConnection:Disconnect()
                rainbowConnection = nil
            end
            if colorCorrection then
                colorCorrection:Destroy()
                colorCorrection = nil
            end
        end
    end
})

local trailConnection = nil

WorldLeft:AddToggle("BallTrailToggle", {
    Text = "Rainbow Ball Trail",
    Default = false,
    Callback = function(Value)
        if Value then
            trailConnection = RunService.RenderStepped:Connect(function()
                local function GetBallForTrail()
                    for _, Ball in ipairs(workspace:WaitForChild("Balls"):GetChildren()) do
                        if Ball:GetAttribute("realBall") then
                            return Ball
                        end
                    end
                end
                local function CreateRainbowTrail(ball)
                    if ball:FindFirstChild("InvictusTrail") then return end
                    local at1 = Instance.new("Attachment", ball)
                    local at2 = Instance.new("Attachment", ball)
                    at1.Position = Vector3.new(0, 0.5, 0)
                    at2.Position = Vector3.new(0, -0.5, 0)
                    local trail = Instance.new("Trail")
                    trail.Name = "InvictusTrail"
                    trail.Attachment0 = at1
                    trail.Attachment1 = at2
                    trail.Lifetime = 0.3
                    trail.MinLength = 0.1
                    trail.WidthScale = NumberSequence.new(1)
                    trail.FaceCamera = true
                    trail.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 0, 0)),
                        ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 127, 0)),
                        ColorSequenceKeypoint.new(0.32, Color3.fromRGB(255, 255, 0)),
                        ColorSequenceKeypoint.new(0.48, Color3.fromRGB(0, 255, 0)),
                        ColorSequenceKeypoint.new(0.64, Color3.fromRGB(0, 0, 255)),
                        ColorSequenceKeypoint.new(0.80, Color3.fromRGB(75, 0, 130)),
                        ColorSequenceKeypoint.new(1.0, Color3.fromRGB(148, 0, 211))
                    })
                    trail.Parent = ball
                end
                local ball = GetBallForTrail()
                if ball and not ball:FindFirstChild("InvictusTrail") then
                    CreateRainbowTrail(ball)
                end
            end)
        else
            if trailConnection then
                trailConnection:Disconnect()
                trailConnection = nil
            end
            for _, Ball in ipairs(workspace:WaitForChild("Balls"):GetChildren()) do
                local trail = Ball:FindFirstChild("InvictusTrail")
                if trail then trail:Destroy() end
                for _, att in ipairs(Ball:GetChildren()) do
                    if att:IsA("Attachment") then att:Destroy() end
                end
            end
        end
    end
})

local cam = workspace.CurrentCamera
local viewConnection = nil

WorldLeft:AddToggle("ViewBallToggle", {
    Text = "View Ball",
    Default = false,
    Callback = function(Value)
        if Value then
            viewConnection = RunService.RenderStepped:Connect(function()
                local function GetBallForView()
                    for _, Ball in ipairs(workspace:WaitForChild("Balls"):GetChildren()) do
                        if Ball:GetAttribute("realBall") then
                            return Ball
                        end
                    end
                end
                local ball = GetBallForView()
                if ball and cam.CameraSubject ~= ball then
                    cam.CameraSubject = ball
                end
            end)
        else
            if viewConnection then
                viewConnection:Disconnect()
                viewConnection = nil
            end
            cam.CameraSubject = Player.Character or Player
        end
    end
})

local WorldRight = Tabs.World:AddRightGroupbox("ESP & Sky", "eye")

local abilityESPEnabled = false
local billboardLabels = {}

local function createBillboardGui(p)
    local character = p.Character
    while not character or not character.Parent do
        task.wait()
        character = p.Character
    end
    local head = character:WaitForChild("Head")
    local existingGui = billboardLabels[p] and billboardLabels[p].gui
    if existingGui then existingGui:Destroy() end
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "AbilityESP_Billboard"
    billboardGui.Adornee = head
    billboardGui.Size = UDim2.new(0, 200, 0, 25)
    billboardGui.StudsOffset = Vector3.new(0, 3.5, 0)
    billboardGui.AlwaysOnTop = true
    billboardGui.Parent = head
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextStrokeTransparency = 0.6
    textLabel.TextSize = 14
    textLabel.TextXAlignment = Enum.TextXAlignment.Center
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.TextWrapped = true
    textLabel.Parent = billboardGui
    textLabel.Visible = false
    textLabel.Text = ""
    billboardLabels[p] = {gui = billboardGui, label = textLabel}
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        humanoid.Died:Connect(function()
            textLabel.Visible = false
            textLabel.Text = ""
            billboardGui:Destroy()
            billboardLabels[p] = nil
        end)
    end
end

for _, p in Players:GetPlayers() do
    if p ~= Player then
        p.CharacterAdded:Connect(function()
            createBillboardGui(p)
        end)
        if p.Character then
            createBillboardGui(p)
        end
    end
end

Players.PlayerAdded:Connect(function(newPlayer)
    if newPlayer ~= Player then
        newPlayer.CharacterAdded:Connect(function()
            createBillboardGui(newPlayer)
        end)
    end
end)

WorldRight:AddToggle("AbilityESPToggle", {
    Text = "Ability ESP",
    Default = false,
    Callback = function(Value)
        abilityESPEnabled = Value
        if Value then
            Connections_Manager["AbilityESP"] = RunService.Heartbeat:Connect(function()
                for p, data in pairs(billboardLabels) do
                    local label = data.label
                    if p.Character and p.Character:FindFirstChild("Head") then
                        local ability = p:GetAttribute("EquippedAbility")
                        label.Text = ability and (p.DisplayName .. " [" .. ability .. "]") or p.DisplayName
                        label.Visible = true
                    else
                        label.Visible = false
                        label.Text = ""
                    end
                end
            end)
        else
            if Connections_Manager["AbilityESP"] then
                Connections_Manager["AbilityESP"]:Disconnect()
                Connections_Manager["AbilityESP"] = nil
            end
            for _, data in pairs(billboardLabels) do
                local label = data.label
                label.Visible = false
                label.Text = ""
            end
        end
    end
})

local selectedSky = "Default"
local skyen = false

local skyPresets = {
    Default = {"591058823", "591059876", "591058104", "591057861", "591057625", "591059642"},
    Vaporwave = {"1417494030", "1417494146", "1417494253", "1417494402", "1417494499", "1417494643"},
    Redshift = {"401664839", "401664862", "401664960", "401664881", "401664901", "401664936"},
    Desert = {"1013852", "1013853", "1013850", "1013851", "1013849", "1013854"},
    Minecraft = {"1876545003", "1876544331", "1876542941", "1876543392", "1876543764", "1876544642"},
    SpaceWave = {"16262356578", "16262358026", "16262360469", "16262362003", "16262363873", "16262366016"},
    DarkNight = {"6285719338", "6285721078", "6285722964", "6285724682", "6285726335", "6285730635"},
    BlueGalaxy = {"14961495673", "14961494492", "14961492844", "14961491298", "14961490439", "14961489508"}
}

local function applySkybox(presetName)
    if not skyen then return end
    local skyboxData = skyPresets[presetName]
    if not skyboxData then return end
    local Sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
    local faces = {"SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp"}
    for i, face in ipairs(faces) do
        Sky[face] = "rbxassetid://" .. skyboxData[i]
    end
end

WorldRight:AddToggle("CustomSkyToggle", {
    Text = "Custom Sky",
    Default = false,
    Callback = function(Value)
        local Sky = Lighting:FindFirstChildOfClass("Sky")
        if Value then
            skyen = true
            if not Sky then
                Sky = Instance.new("Sky", Lighting)
            end
            applySkybox(selectedSky)
        else
            if Sky then Sky:Destroy() end
            skyen = false
        end
    end
})

WorldRight:AddDropdown("SkyDropdown", {
    Text = "Sky Type",
    Values = {"Default", "Vaporwave", "Redshift", "Desert", "Minecraft", "SpaceWave", "DarkNight", "BlueGalaxy"},
    Default = "Default",
    Callback = function(Value)
        selectedSky = Value
        applySkybox(Value)
    end
})

local lookAtBallToggle = false
local parryLookType = "Camera"
local playerConn, cameraConn = nil, nil

local function EnableLookAt()
    if parryLookType == "Character" then
        playerConn = RunService.Stepped:Connect(function()
            local Ball = Auto_Parry.Get_Ball()
            local Character = Player.Character
            if not Ball or not Character then return end
            local HRP = Character:FindFirstChild("HumanoidRootPart")
            if not HRP then return end
            local lookPos = Vector3.new(Ball.Position.X, HRP.Position.Y, Ball.Position.Z)
            HRP.CFrame = CFrame.lookAt(HRP.Position, lookPos)
        end)
    elseif parryLookType == "Camera" then
        cameraConn = RunService.RenderStepped:Connect(function()
            local Ball = Auto_Parry.Get_Ball()
            if not Ball then return end
            local camPos = workspace.CurrentCamera.CFrame.Position
            workspace.CurrentCamera.CFrame = CFrame.lookAt(camPos, Ball.Position)
        end)
    end
end

local function DisableLookAt()
    if playerConn then playerConn:Disconnect() playerConn = nil end
    if cameraConn then cameraConn:Disconnect() cameraConn = nil end
end

WorldRight:AddToggle("LookAtBallToggle", {
    Text = "Look At Ball",
    Default = false,
    Callback = function(Value)
        lookAtBallToggle = Value
        if Value then
            EnableLookAt()
        else
            DisableLookAt()
        end
    end
})

WorldRight:AddDropdown("LookTypeDropdown", {
    Text = "Look Type",
    Values = {"Camera", "Character"},
    Default = "Camera",
    Callback = function(Value)
        parryLookType = Value
        if lookAtBallToggle then
            DisableLookAt()
            EnableLookAt()
        end
    end
})

local MiscLeft = Tabs.Misc:AddLeftGroupbox("Skin Changer", "wand")

local skinEnabled = false
local swordName = ""

MiscLeft:AddToggle("SkinChangerToggle", {
    Text = "Skin Changer",
    Default = false,
    Callback = function(Value)
        skinEnabled = Value
    end
})

MiscLeft:AddInput("SkinNameInput", {
    Default = "",
    Numeric = false,
    Finished = true,
    Placeholder = "Enter sword name...",
    Callback = function(Value)
        swordName = Value
    end
})

local MiscRight = Tabs.Misc:AddRightGroupbox("Ball Stats", "bar-chart-2")

local statsGui = nil
local statsConnection = nil

MiscRight:AddToggle("BallStatsToggle", {
    Text = "Show Ball Stats",
    Default = false,
    Callback = function(Value)
        if Value then
            statsGui = Instance.new("ScreenGui", Player:WaitForChild("PlayerGui"))
            statsGui.Name = "BallStatsUI"
            statsGui.ResetOnSpawn = false
            local frame = Instance.new("Frame", statsGui)
            frame.Size = UDim2.new(0, 180, 0, 80)
            frame.Position = UDim2.new(1, -200, 0, 100)
            frame.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
            frame.BackgroundTransparency = 0.2
            frame.BorderSizePixel = 0
            frame.Active = true
            frame.Draggable = true
            local label = Instance.new("TextLabel", frame)
            label.Size = UDim2.new(1, -10, 1, -10)
            label.Position = UDim2.new(0, 5, 0, 5)
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.new(1, 1, 1)
            label.TextScaled = true
            label.Font = Enum.Font.GothamBold
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextYAlignment = Enum.TextYAlignment.Top
            label.Text = "Loading..."
            statsConnection = RunService.RenderStepped:Connect(function()
                local function GetBallStats()
                    for _, Ball in ipairs(workspace:WaitForChild("Balls"):GetChildren()) do
                        if Ball:GetAttribute("realBall") then
                            return Ball
                        end
                    end
                end
                local ball = GetBallStats()
                if not ball then
                    label.Text = "No ball found"
                    return
                end
                local char = Player.Character or Player.CharacterAdded:Wait()
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                local speedVal = math.floor(ball.Velocity.Magnitude)
                local distance = math.floor((ball.Position - hrp.Position).Magnitude)
                local target = ball:GetAttribute("target") or "N/A"
                label.Text = string.format("Ball Stats | Invictus\nSpeed: %s\nDistance: %s\nTarget: %s", speedVal, distance, target)
            end)
        else
            if statsConnection then
                statsConnection:Disconnect()
                statsConnection = nil
            end
            if statsGui then
                statsGui:Destroy()
                statsGui = nil
            end
        end
    end
})

local fieldPart = nil
local visualizeConnection = nil

MiscRight:AddToggle("VisualizeToggle", {
    Text = "Visualize Range",
    Default = false,
    Callback = function(Value)
        if Value then
            local char = Player.Character or Player.CharacterAdded:Wait()
            local root = char:WaitForChild("HumanoidRootPart")
            if not fieldPart then
                fieldPart = Instance.new("Part")
                fieldPart.Anchored = true
                fieldPart.CanCollide = false
                fieldPart.Transparency = 0.5
                fieldPart.Shape = Enum.PartType.Ball
                fieldPart.Material = Enum.Material.ForceField
                fieldPart.CastShadow = false
                fieldPart.Color = Color3.fromRGB(88, 131, 202)
                fieldPart.Name = "VisualField"
                fieldPart.Parent = workspace
            end
            visualizeConnection = RunService.RenderStepped:Connect(function()
                local function GetBallVis()
                    for _, Ball in ipairs(workspace:WaitForChild("Balls"):GetChildren()) do
                        if Ball:GetAttribute("realBall") then
                            return Ball
                        end
                    end
                end
                local ball = GetBallVis()
                if not ball then return end
                local ballVel = ball.AssemblyLinearVelocity
                local speedVal = ballVel.Magnitude
                local size = math.clamp(speedVal, 25, 250)
                if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                    fieldPart.Position = Player.Character.HumanoidRootPart.Position
                    fieldPart.Size = Vector3.new(size, size, size)
                end
            end)
        else
            if visualizeConnection then
                visualizeConnection:Disconnect()
                visualizeConnection = nil
            end
            if fieldPart then
                fieldPart:Destroy()
                fieldPart = nil
            end
        end
    end
})

local targetDistance = 30
local autoPlayConnection = nil

MiscLeft:AddToggle("AutoPlayToggle", {
    Text = "Auto Play (AI)",
    Default = false,
    Callback = function(Value)
        if Value then
            autoPlayConnection = RunService.RenderStepped:Connect(function()
                if not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") then return end
                local rootPart = Player.Character.HumanoidRootPart
                local ball
                for _, b in ipairs(workspace:WaitForChild("Balls"):GetChildren()) do
                    if b:GetAttribute("realBall") then
                        ball = b
                        break
                    end
                end
                if not ball then return end
                local dir = (ball.Position - rootPart.Position).Unit
                local dist = (ball.Position - rootPart.Position).Magnitude
                local ballTarget = ball:GetAttribute("target")
                for _, key in pairs({"W", "A", "S", "D"}) do
                    VirtualInputManager:SendKeyEvent(false, key, false, game)
                end
                if dist < targetDistance or ballTarget == Player.Name then
                    local backDir = -dir
                    local backPos = rootPart.Position + backDir * 6
                    local safeToBack = true
                    for _, other in ipairs(Players:GetPlayers()) do
                        if other ~= Player and other.Character and other.Character:FindFirstChild("HumanoidRootPart") then
                            local otherHRP = other.Character.HumanoidRootPart
                            if (otherHRP.Position - backPos).Magnitude < 5 then
                                safeToBack = false
                                break
                            end
                        end
                    end
                    if safeToBack then
                        VirtualInputManager:SendKeyEvent(true, "S", false, game)
                    else
                        local sideKey = math.random(1, 2) == 1 and "A" or "D"
                        VirtualInputManager:SendKeyEvent(true, sideKey, false, game)
                    end
                    return
                end
                local buffer = 5
                if dist > targetDistance + buffer then
                    VirtualInputManager:SendKeyEvent(true, "W", false, game)
                end
            end)
        else
            if autoPlayConnection then
                autoPlayConnection:Disconnect()
                autoPlayConnection = nil
            end
            for _, key in pairs({"W", "A", "S", "D"}) do
                VirtualInputManager:SendKeyEvent(false, key, false, game)
            end
        end
    end
})

MiscLeft:AddSlider("AutoPlayDistanceSlider", {
    Text = "Distance From Ball",
    Default = 30,
    Min = 1,
    Max = 100,
    Rounding = 0,
    Callback = function(Value)
        targetDistance = Value
    end
})

local MenuGroup = Tabs.Settings:AddLeftGroupbox("UI Settings", "sliders")

MenuGroup:AddToggle("KeybindMenuToggle", {
    Text = "Open Keybind Menu",
    Default = Library.KeybindFrame.Visible,
    Callback = function(Value)
        Library.KeybindFrame.Visible = Value
    end
})

MenuGroup:AddToggle("CustomCursorToggle", {
    Text = "Custom Cursor",
    Default = true,
    Callback = function(Value)
        Library.ShowCustomCursor = Value
    end
})

MenuGroup:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", {
    Default = "RightControl",
    NoUI = true,
    Text = "Menu Keybind"
})

MenuGroup:AddButton({
    Text = "Copy Discord Link",
    Func = function()
        setclipboard("https://discord.gg/nbPHzKzafN")
        Library:Notify({Title = "Invictus", Description = "Discord link copied!", Time = 2})
    end
})

MenuGroup:AddButton({
    Text = "Unload Script",
    Func = function()
        Library:Unload()
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
    Description = "Script loaded successfully!\nDeveloper: Entropy (4entropy3)\nDiscord: discord.gg/nbPHzKzafN",
    Time = 5
})
