repeat task.wait() until game:IsLoaded()

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local BallsFolder = Workspace:WaitForChild("Balls", 9000000000)

local OriginalAmbient = Lighting.Ambient
local OriginalFogColor = Lighting.FogColor
local OriginalClockTime = Lighting.ClockTime

local AutoParrySettings = {
    AutoParry = true,
    PingBased = true,
    DistanceHit = 0.5,
    Offset = 0,
    AutoCurve = false,
    AutoCurveStyle = "Upwards",
    CurveAnti = false,
    RandomizeDistance = false,
    RandomizeMin = 8,
    RandomizeMax = 15,
    Rainbow = false,
    RandomCurveStyles = false,
    CurveAntiV2 = false,
    AutoSpam = false,
    CircleRainbow = false,
    StandHit = 10,
    JumpHit = 0.5,
    RainbowAmbient = false,
    RainbowFog = false,
    ManualSpam = false,
    LookAt = false,
    LookAtMethod = "Player CFrame"
}

local BackupSettings = {
    BackUpStanHit = 10,
    BackUpJumpHit = 0.5
}

local UtilitySettings = {
    AutoClaimRewards = false,
    AutoSword = false,
    AutoExplosion = false,
    NoSlash = false
}

local SpamSettings = {
    PCSpam = false,
    KeyBind = Enum.KeyCode.E,
    SpamSpeed = 2,
    Legitize = false,
    SpamLoops = "Single",
    SpeedCheck = false,
    SpeedOfBall = nil,
    LoopType = "Old",
    SemiBlatant = false,
    BallSpeed = 0
}

local ClashSettings = {
    HitsTillClash = 4,
    DistanceToActivate = 30,
    DistanceBallActivate = 35,
    BackUpDistanceToActivate = 30,
    DistanceToActivateDynamic = false,
    DynamicAddedDistance = 10
}

local VisualBall = false
local VisualClash = false
local VisualDistance = false
local VisualCircleBall = false
local VisualCircleClash = false
local VisualCircleDistance = false
local DistanceToHitValue = 10
local AutoRageEnabled = false
local VisualizerShape = "Ball"
local VisualizerColor = Color3.fromRGB(255, 255, 255)
local CircleVisualizerColor = Color3.fromRGB(255, 255, 255)
local VisualizerTransparency = 0
local VisualizerMaterial = nil
local CircleHeight = 0.5
local DistanceToHitBackup = 10
local JumpHitBackup = 10
local CurveStyleBackup = "Upwards"

local IsTargeted = false
local IsJumping = false
local CurveReady = false
local ManualSpamEnabled = false
local PCSpamActive = false
local AutoSpamActive = false
local ClashCount = 0

local ScreenPosition = Workspace.CurrentCamera:WorldToScreenPoint(LocalPlayer.Character.HumanoidRootPart.Position)
local AbilityGradient = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Hotbar").Ability.UIGradient

local Window = Library:CreateWindow({
    Title = "Invictus",
    Footer = "Blade Ball | Developer: Entropy",
    Icon = 85451000785501,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = {
    Home = Window:AddTab("Home", "home"),
    Main = Window:AddTab("Main", "swords"),
    Adjustments = Window:AddTab("Adjustments", "sliders-horizontal"),
    Utilities = Window:AddTab("Utilities", "wrench"),
    Visuals = Window:AddTab("Visuals", "eye"),
    World = Window:AddTab("World", "globe-2"),
    Settings = Window:AddTab("Settings", "settings"),
}

local HomeGroup = Tabs.Home:AddLeftGroupbox("Welcome")
HomeGroup:AddLabel("Welcome To Invictus, " .. LocalPlayer.DisplayName, true)
HomeGroup:AddLabel("We hope to satisfy your needs!", true)
HomeGroup:AddDivider()
HomeGroup:AddButton({
    Text = "Copy Discord Invite",
    Func = function()
        setclipboard("https://discord.gg/nbPHzKzafN")
        Library:Notify({
            Title = "Invictus",
            Description = "Discord invite copied to clipboard!",
            Time = 3,
        })
    end,
    Tooltip = "Copies the Discord invite link",
})

local CreditsGroup = Tabs.Home:AddRightGroupbox("Credits")
CreditsGroup:AddLabel("Developer: Entropy", true)
CreditsGroup:AddLabel("Discord: 4entropy3", true)

local CombatGroup = Tabs.Main:AddLeftGroupbox("Combat")

CombatGroup:AddToggle("AutoParry", {
    Text = "Auto Parry",
    Default = true,
    Tooltip = "Automatically parries the ball for you",
})

Toggles.AutoParry:OnChanged(function()
    AutoParrySettings.AutoParry = Toggles.AutoParry.Value
end)

CombatGroup:AddToggle("PingBased", {
    Text = "Ping Based",
    Default = true,
    Tooltip = "Makes the auto parry calculations ping based",
})

Toggles.PingBased:OnChanged(function()
    AutoParrySettings.PingBased = Toggles.PingBased.Value
end)

CombatGroup:AddToggle("BetaAutoParry", {
    Text = "Beta Auto Parry",
    Default = false,
    Tooltip = "Resistant to curves but can sometimes miscalculate",
})

Toggles.BetaAutoParry:OnChanged(function()
    AutoParrySettings.CurveAnti = Toggles.BetaAutoParry.Value
end)

CombatGroup:AddToggle("RandomizeDistance", {
    Text = "Randomize Distance To Hit",
    Default = false,
    Tooltip = "Randomizes the distance to hit value",
})

Toggles.RandomizeDistance:OnChanged(function()
    AutoParrySettings.RandomizeDistance = Toggles.RandomizeDistance.Value
end)

CombatGroup:AddToggle("AutoSpam", {
    Text = "Auto Spam/Clash",
    Default = false,
    Tooltip = "Automatically spams/clashes for you",
})

Toggles.AutoSpam:OnChanged(function()
    AutoParrySettings.AutoSpam = Toggles.AutoSpam.Value
end)

CombatGroup:AddToggle("AutoCurve", {
    Text = "Auto Curve",
    Default = false,
    Tooltip = "Automatically curves the ball for you",
})

Toggles.AutoCurve:OnChanged(function()
    AutoParrySettings.AutoCurve = Toggles.AutoCurve.Value
end)

CombatGroup:AddToggle("AutoRage", {
    Text = "Auto Raging Deflection/Rapture",
    Default = false,
    Tooltip = "Automatically uses raging deflection or rapture skill",
})

Toggles.AutoRage:OnChanged(function()
    AutoRageEnabled = Toggles.AutoRage.Value
end)

local OtherGroup = Tabs.Main:AddRightGroupbox("Other")

OtherGroup:AddToggle("LookAtBall", {
    Text = "Look At Ball",
    Default = false,
    Tooltip = "Makes your character look at the ball",
})

Toggles.LookAtBall:OnChanged(function()
    AutoParrySettings.LookAt = Toggles.LookAtBall.Value
end)

OtherGroup:AddToggle("ManualSpamMobile", {
    Text = "Manual Spam [Mobile]",
    Default = false,
    Tooltip = "Shows a GUI button to spam parry",
})

Toggles.ManualSpamMobile:OnChanged(function()
    AutoParrySettings.ManualSpam = Toggles.ManualSpamMobile.Value
end)

OtherGroup:AddToggle("ManualSpamPC", {
    Text = "Manual Spam [PC]",
    Default = false,
    Tooltip = "Press keybind to spam parry",
})

Toggles.ManualSpamPC:OnChanged(function()
    SpamSettings.PCSpam = Toggles.ManualSpamPC.Value
end)

OtherGroup:AddLabel("Spam Keybind"):AddKeyPicker("SpamKeybind", {
    Default = "E",
    Mode = "Toggle",
    Text = "Manual Spam Keybind",
})

Options.SpamKeybind:OnChanged(function()
    SpamSettings.KeyBind = Options.SpamKeybind.Value
end)

OtherGroup:AddDivider()

OtherGroup:AddButton({
    Text = "FPS Boost Heavy",
    Func = function()
        loadstring(game:HttpGet("https://pastebin.com/raw/eJQ7ziB9"))()
        Library:Notify({
            Title = "Invictus",
            Description = "Heavy FPS boost applied!",
            Time = 3,
        })
    end,
    Tooltip = "Reduces graphics significantly for more FPS",
})

OtherGroup:AddButton({
    Text = "FPS Boost Lite",
    Func = function()
        loadstring(game:HttpGet("https://pastebin.com/raw/8Ft6DSs1"))()
        Library:Notify({
            Title = "Invictus",
            Description = "Lite FPS boost applied!",
            Time = 3,
        })
    end,
    Tooltip = "Reduces some graphics for slightly more FPS",
})

local ParryAdjGroup = Tabs.Adjustments:AddLeftGroupbox("Auto Parry Adjustments")

ParryAdjGroup:AddSlider("DistanceToHit", {
    Text = "Distance To Hit",
    Default = 10,
    Min = 5,
    Max = 25,
    Rounding = 1,
    Tooltip = "Distance at which auto parry activates",
})

Options.DistanceToHit:OnChanged(function()
    local value = Options.DistanceToHit.Value
    AutoParrySettings.JumpHit = tonumber(value * 5 / 100)
    AutoParrySettings.StandHit = tonumber(value)
    BackupSettings.BackUpJumpHit = tonumber(value * 5 / 100)
    BackupSettings.BackUpStanHit = tonumber(value)
    DistanceToHitValue = value
    JumpHitBackup = value * 5 / 100
    DistanceToHitBackup = value
end)

ParryAdjGroup:AddSlider("PingOffset", {
    Text = "Ping Based Offset",
    Default = 0,
    Min = 0,
    Max = 15,
    Rounding = 1,
    Tooltip = "Offset for ping based calculations",
})

Options.PingOffset:OnChanged(function()
    AutoParrySettings.Offset = tonumber(Options.PingOffset.Value)
end)

ParryAdjGroup:AddSlider("RandomMin", {
    Text = "Minimum Random Value",
    Default = 8,
    Min = 5,
    Max = 25,
    Rounding = 1,
    Tooltip = "Minimum value for randomize distance",
})

Options.RandomMin:OnChanged(function()
    AutoParrySettings.RandomizeMin = tonumber(Options.RandomMin.Value)
end)

ParryAdjGroup:AddSlider("RandomMax", {
    Text = "Maximum Random Value",
    Default = 15,
    Min = 5,
    Max = 25,
    Rounding = 1,
    Tooltip = "Maximum value for randomize distance",
})

Options.RandomMax:OnChanged(function()
    AutoParrySettings.RandomizeMax = tonumber(Options.RandomMax.Value)
end)

local ClashAdjGroup = Tabs.Adjustments:AddRightGroupbox("Auto Spam/Clash Adjustments")

ClashAdjGroup:AddToggle("DynamicClash", {
    Text = "Add Distance Each Parry",
    Default = false,
    Tooltip = "Adds distance to clash each parry",
})

Toggles.DynamicClash:OnChanged(function()
    ClashSettings.DistanceToActivateDynamic = Toggles.DynamicClash.Value
end)

ClashAdjGroup:AddSlider("PlayerDistance", {
    Text = "Distance From Player To Clash",
    Default = 30,
    Min = 10,
    Max = 100,
    Rounding = 1,
    Tooltip = "Distance between you and player for clash",
})

Options.PlayerDistance:OnChanged(function()
    ClashSettings.DistanceToActivate = tonumber(Options.PlayerDistance.Value)
    ClashSettings.BackUpDistanceToActivate = tonumber(Options.PlayerDistance.Value)
end)

ClashAdjGroup:AddSlider("DynamicAdd", {
    Text = "Dynamic Distance Amount",
    Default = 10,
    Min = 10,
    Max = 100,
    Rounding = 1,
    Tooltip = "How much distance is added each parry",
})

Options.DynamicAdd:OnChanged(function()
    ClashSettings.DynamicAddedDistance = tonumber(Options.DynamicAdd.Value + 5)
end)

ClashAdjGroup:AddSlider("HitsTillClash", {
    Text = "Parries Till Clash",
    Default = 4,
    Min = 1,
    Max = 15,
    Rounding = 1,
    Tooltip = "How many parries until clash activates",
})

Options.HitsTillClash:OnChanged(function()
    ClashSettings.HitsTillClash = tonumber(Options.HitsTillClash.Value)
end)

ClashAdjGroup:AddSlider("BallDistance", {
    Text = "Ball Distance To Clash",
    Default = 35,
    Min = 10,
    Max = 100,
    Rounding = 1,
    Tooltip = "Ball distance for clash to activate",
})

Options.BallDistance:OnChanged(function()
    ClashSettings.DistanceBallActivate = tonumber(Options.BallDistance.Value)
end)

local SpamAdjGroup = Tabs.Adjustments:AddLeftGroupbox("Spam Adjustments")

SpamAdjGroup:AddToggle("SpeedCheck", {
    Text = "Ball Speed Check",
    Default = false,
    Tooltip = "Stops spam when ball is not moving",
})

Toggles.SpeedCheck:OnChanged(function()
    SpamSettings.SpeedCheck = Toggles.SpeedCheck.Value
end)

SpamAdjGroup:AddDropdown("SpamSpeed", {
    Values = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "10"},
    Default = "1",
    Text = "Spam Speed",
    Tooltip = "How fast the spam is",
})

Options.SpamSpeed:OnChanged(function()
    SpamSettings.SpamSpeed = tonumber(Options.SpamSpeed.Value)
    if SpamSettings.SpamSpeed >= 4 then
        Library:Notify({
            Title = "Invictus",
            Description = "Warning: High spam speed can cause ping spikes!",
            Time = 5,
        })
    end
end)

SpamAdjGroup:AddDropdown("LoopType", {
    Values = {"New", "Old"},
    Default = "Old",
    Text = "Spam Loop Type",
    Tooltip = "Which loop type the spam uses",
})

Options.LoopType:OnChanged(function()
    SpamSettings.LoopType = Options.LoopType.Value
end)

SpamAdjGroup:AddDropdown("SpamLoops", {
    Values = {"Single", "Dual", "Triple", "Quad"},
    Default = "Single",
    Text = "Spam Loops",
    Tooltip = "How many loops run in the spam",
})

Options.SpamLoops:OnChanged(function()
    SpamSettings.SpamLoops = Options.SpamLoops.Value
    if Options.SpamLoops.Value == "Triple" or Options.SpamLoops.Value == "Quad" then
        Library:Notify({
            Title = "Invictus",
            Description = "Warning: High spam loops might fluctuate ping!",
            Time = 5,
        })
    end
end)

SpamAdjGroup:AddToggle("LegitSpam", {
    Text = "Legit Spam",
    Default = false,
    Tooltip = "Makes the spam more legit",
})

Toggles.LegitSpam:OnChanged(function()
    SpamSettings.Legitize = Toggles.LegitSpam.Value
end)

local VisualBallGroup = Tabs.Adjustments:AddRightGroupbox("Ball Visualizer Settings")

VisualBallGroup:AddDropdown("VisualizerShape", {
    Values = {"Ball", "Block", "Cylinder", "Wedge", "CornerWedge"},
    Default = "Ball",
    Text = "Visualizer Shape",
})

Options.VisualizerShape:OnChanged(function()
    VisualizerShape = Options.VisualizerShape.Value
end)

VisualBallGroup:AddDropdown("VisualizerMaterial", {
    Values = {"Plastic", "Concrete", "Grass", "Metal", "WoodPlanks", "ForceField", "Glass", "Neon", "SmoothPlastic", "Fabric", "Brick", "Foil", "Snow", "Slate", "Rock", "Salt", "Pebble", "Pavement", "Marble", "Ice", "Granite", "CrackedLava", "DiamondPlate", "Limestone", "Mud", "Sand"},
    Default = "ForceField",
    Text = "Visualizer Material",
})

Options.VisualizerMaterial:OnChanged(function()
    VisualizerMaterial = Options.VisualizerMaterial.Value
end)

VisualBallGroup:AddLabel("Visualizer Color"):AddColorPicker("VisualizerColor", {
    Default = Color3.fromRGB(255, 255, 255),
    Title = "Visualizer Color",
})

Options.VisualizerColor:OnChanged(function()
    VisualizerColor = Options.VisualizerColor.Value
end)

VisualBallGroup:AddToggle("RainbowVisualizer", {
    Text = "Rainbow Visualizer",
    Default = false,
})

Toggles.RainbowVisualizer:OnChanged(function()
    AutoParrySettings.Rainbow = Toggles.RainbowVisualizer.Value
end)

VisualBallGroup:AddSlider("VisualizerTransparency", {
    Text = "Visualizer Transparency",
    Default = 0,
    Min = 0,
    Max = 1,
    Rounding = 1,
})

Options.VisualizerTransparency:OnChanged(function()
    VisualizerTransparency = tonumber(Options.VisualizerTransparency.Value)
end)

local VisualCircleGroup = Tabs.Adjustments:AddLeftGroupbox("Circle Visualizer Settings")

VisualCircleGroup:AddLabel("Circle Color"):AddColorPicker("CircleColor", {
    Default = Color3.fromRGB(255, 255, 255),
    Title = "Circle Visualizer Color",
})

Options.CircleColor:OnChanged(function()
    CircleVisualizerColor = Options.CircleColor.Value
end)

VisualCircleGroup:AddToggle("RainbowCircle", {
    Text = "Rainbow Circle Visualizer",
    Default = false,
})

Toggles.RainbowCircle:OnChanged(function()
    AutoParrySettings.CircleRainbow = Toggles.RainbowCircle.Value
end)

VisualCircleGroup:AddSlider("CircleHeight", {
    Text = "Circle Height",
    Default = 0.5,
    Min = 0.5,
    Max = 5,
    Rounding = 1,
})

Options.CircleHeight:OnChanged(function()
    CircleHeight = tonumber(Options.CircleHeight.Value)
end)

local OtherAdjGroup = Tabs.Adjustments:AddRightGroupbox("Other Adjustments")

OtherAdjGroup:AddDropdown("CurveStyle", {
    Values = {"Random", "Upwards", "Backwards", "Left", "Right"},
    Default = "Upwards",
    Text = "Curve Style",
    Tooltip = "Direction the ball curves",
})

Options.CurveStyle:OnChanged(function()
    AutoParrySettings.AutoCurveStyle = Options.CurveStyle.Value
    CurveStyleBackup = Options.CurveStyle.Value
    if Options.CurveStyle.Value == "Random" then
        AutoParrySettings.RandomCurveStyles = true
    else
        AutoParrySettings.RandomCurveStyles = false
    end
end)

OtherAdjGroup:AddDropdown("LookAtMethod", {
    Values = {"Player CFrame", "Camera CFrame"},
    Default = "Player CFrame",
    Text = "Look At Method",
})

Options.LookAtMethod:OnChanged(function()
    AutoParrySettings.LookAtMethod = Options.LookAtMethod.Value
end)

local UtilMainGroup = Tabs.Utilities:AddLeftGroupbox("Main Utilities")

UtilMainGroup:AddToggle("AntiSlash", {
    Text = "Anti Slash Effect",
    Default = false,
    Tooltip = "Removes slash effect to reduce lag",
})

Toggles.AntiSlash:OnChanged(function()
    UtilitySettings.NoSlash = Toggles.AntiSlash.Value
end)

UtilMainGroup:AddButton({
    Text = "Auto Parry Toggle Tool",
    Func = function()
        local tool = Instance.new("Tool")
        tool.RequiresHandle = false
        tool.Name = AutoParrySettings.AutoParry and "Auto Parry: On" or "Auto Parry: Off"
        tool.Activated:Connect(function()
            AutoParrySettings.AutoParry = not AutoParrySettings.AutoParry
            tool.Name = AutoParrySettings.AutoParry and "Auto Parry: On" or "Auto Parry: Off"
        end)
        tool.Parent = LocalPlayer.Backpack
        LocalPlayer.CharacterRemoving:Connect(function()
            tool.Parent = LocalPlayer.Backpack
        end)
        Library:Notify({
            Title = "Invictus",
            Description = "Auto Parry toggle tool added to backpack!",
            Time = 3,
        })
    end,
    Tooltip = "Creates a tool to toggle auto parry",
})

local AutoUtilGroup = Tabs.Utilities:AddRightGroupbox("Automatic Utilities")

AutoUtilGroup:AddToggle("AutoClaimRewards", {
    Text = "Auto Claim PlayTime Rewards",
    Default = false,
})

Toggles.AutoClaimRewards:OnChanged(function()
    UtilitySettings.AutoClaimRewards = Toggles.AutoClaimRewards.Value
end)

AutoUtilGroup:AddToggle("AutoExplosionCrate", {
    Text = "Auto Open Explosion Crate",
    Default = false,
})

Toggles.AutoExplosionCrate:OnChanged(function()
    UtilitySettings.AutoExplosion = Toggles.AutoExplosionCrate.Value
end)

AutoUtilGroup:AddToggle("AutoSwordCrate", {
    Text = "Auto Open Sword Crate",
    Default = false,
})

Toggles.AutoSwordCrate:OnChanged(function()
    UtilitySettings.AutoSword = Toggles.AutoSwordCrate.Value
end)

local VisBallGroup = Tabs.Visuals:AddLeftGroupbox("Ball Visualizers")

VisBallGroup:AddToggle("VisDistanceToHit", {
    Text = "Distance To Hit Visualizer",
    Default = false,
})

Toggles.VisDistanceToHit:OnChanged(function()
    VisualBall = Toggles.VisDistanceToHit.Value
end)

VisBallGroup:AddToggle("VisClashRange", {
    Text = "Clash Range Visualizer",
    Default = false,
})

Toggles.VisClashRange:OnChanged(function()
    VisualClash = Toggles.VisClashRange.Value
end)

VisBallGroup:AddToggle("VisBallDistance", {
    Text = "Ball Distance Visualizer",
    Default = false,
})

Toggles.VisBallDistance:OnChanged(function()
    VisualDistance = Toggles.VisBallDistance.Value
end)

local VisCircleGroup = Tabs.Visuals:AddRightGroupbox("Circle Visualizers")

VisCircleGroup:AddToggle("VisCircleDistance", {
    Text = "Distance To Hit Circle",
    Default = false,
})

Toggles.VisCircleDistance:OnChanged(function()
    VisualCircleBall = Toggles.VisCircleDistance.Value
end)

VisCircleGroup:AddToggle("VisCircleClash", {
    Text = "Clash Range Circle",
    Default = false,
})

Toggles.VisCircleClash:OnChanged(function()
    VisualCircleClash = Toggles.VisCircleClash.Value
end)

VisCircleGroup:AddToggle("VisCircleBallDist", {
    Text = "Ball Distance Circle",
    Default = false,
})

Toggles.VisCircleBallDist:OnChanged(function()
    VisualCircleDistance = Toggles.VisCircleBallDist.Value
end)

local WorldMainGroup = Tabs.World:AddLeftGroupbox("World Settings")

WorldMainGroup:AddButton({
    Text = "Reset Everything",
    Func = function()
        Lighting.Ambient = OriginalAmbient
        Lighting.FogColor = OriginalFogColor
        Lighting.ClockTime = OriginalClockTime
        Library:Notify({
            Title = "Invictus",
            Description = "World settings reset!",
            Time = 3,
        })
    end,
})

WorldMainGroup:AddLabel("Ambient Color"):AddColorPicker("AmbientColor", {
    Default = Lighting.Ambient,
    Title = "World Ambient Color",
})

Options.AmbientColor:OnChanged(function()
    Lighting.Ambient = Options.AmbientColor.Value
end)

WorldMainGroup:AddSlider("TimeOfDay", {
    Text = "Time Of Day",
    Default = Lighting.ClockTime,
    Min = 0,
    Max = 24,
    Rounding = 1,
})

Options.TimeOfDay:OnChanged(function()
    Lighting.ClockTime = tonumber(Options.TimeOfDay.Value)
end)

WorldMainGroup:AddLabel("Fog Color"):AddColorPicker("FogColor", {
    Default = Lighting.FogColor,
    Title = "World Fog Color",
})

Options.FogColor:OnChanged(function()
    Lighting.FogColor = Options.FogColor.Value
end)

local RainbowWorldGroup = Tabs.World:AddRightGroupbox("Rainbow Effects")

RainbowWorldGroup:AddToggle("RainbowAmbient", {
    Text = "Rainbow Ambient",
    Default = false,
})

Toggles.RainbowAmbient:OnChanged(function()
    AutoParrySettings.RainbowAmbient = Toggles.RainbowAmbient.Value
end)

RainbowWorldGroup:AddToggle("RainbowFog", {
    Text = "Rainbow Fog",
    Default = false,
})

Toggles.RainbowFog:OnChanged(function()
    AutoParrySettings.RainbowFog = Toggles.RainbowFog.Value
end)

local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")

MenuGroup:AddToggle("KeybindMenuOpen", {
    Default = false,
    Text = "Show Keybind Menu",
})

Toggles.KeybindMenuOpen:OnChanged(function()
    Library.KeybindFrame.Visible = Toggles.KeybindMenuOpen.Value
end)

MenuGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = true,
})

Toggles.ShowCustomCursor:OnChanged(function()
    Library.ShowCustomCursor = Toggles.ShowCustomCursor.Value
end)

MenuGroup:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    NoUI = true,
    Text = "Menu Toggle",
})

MenuGroup:AddButton({
    Text = "Unload Script",
    Func = function()
        Library:Unload()
    end,
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

local SpamGui = Instance.new("ScreenGui")
local SpamFrame = Instance.new("Frame")
local SpamButton = Instance.new("TextButton")

SpamGui.ResetOnSpawn = false
SpamGui.Parent = game.CoreGui

SpamFrame.Position = UDim2.new(0, 20, 0, 20)
SpamFrame.Size = UDim2.new(0, 100, 0, 50)
SpamFrame.BackgroundColor3 = Color3.new(0, 0, 0)
SpamFrame.BorderSizePixel = 0
SpamFrame.Parent = SpamGui

SpamButton.Text = "Spam: Off"
SpamButton.Size = UDim2.new(1, -10, 1, -10)
SpamButton.Position = UDim2.new(0, 5, 0, 5)
SpamButton.BackgroundColor3 = Color3.new(1, 1, 1)
SpamButton.BorderColor3 = Color3.new(0, 0, 0)
SpamButton.BorderSizePixel = 2
SpamButton.Font = Enum.Font.SourceSans
SpamButton.TextColor3 = Color3.new(0, 0, 0)
SpamButton.TextSize = 16
SpamButton.Parent = SpamFrame

local function ToggleManualSpam()
    ManualSpamEnabled = not ManualSpamEnabled
    SpamButton.Text = ManualSpamEnabled and "Spam: On" or "Spam: Off"
end

SpamButton.MouseButton1Click:Connect(ToggleManualSpam)

local dragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil

SpamFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = SpamFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

SpamFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        SpamFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == SpamSettings.KeyBind and not gameProcessed then
        PCSpamActive = not PCSpamActive
        Library:Notify({
            Title = "Invictus",
            Description = PCSpamActive and "PC Spam: On" or "PC Spam: Off",
            Time = 3,
        })
    end
end)

RunService.PostSimulation:Connect(function()
    SpamGui.Enabled = AutoParrySettings.ManualSpam
end)

local VisualizerPart1 = Instance.new("Part")
local VisualizerPart2 = Instance.new("Part")
local VisualizerPart3 = Instance.new("Part")
local CircleAdornee = Instance.new("Part", Workspace.CurrentCamera)
local CircleAdornment1 = Instance.new("CylinderHandleAdornment", game.CoreGui)
local CircleAdornment2 = Instance.new("CylinderHandleAdornment", game.CoreGui)
local CircleAdornment3 = Instance.new("CylinderHandleAdornment", game.CoreGui)

VisualizerPart1.Parent = nil
VisualizerPart2.Parent = nil
VisualizerPart3.Parent = nil
CircleAdornee.Transparency = 1
CircleAdornee.CanCollide = false
CircleAdornee.Anchored = false
CircleAdornee.Size = Vector3.new(1, 1, 1)

VisualizerPart1.CanCollide = false
VisualizerPart2.CanCollide = false
VisualizerPart3.CanCollide = false
VisualizerPart1.Anchored = false
VisualizerPart2.Anchored = false
VisualizerPart3.Anchored = false

CircleAdornment1.Visible = false
CircleAdornment2.Visible = false
CircleAdornment3.Visible = false

local function IsAbilityReady(gradient)
    return gradient.Offset.Y < 0.5
end

local function IsRealBall(ball)
    if typeof(ball) == "Instance" and ball:IsA("BasePart") and ball:IsDescendantOf(BallsFolder) and ball:GetAttribute("realBall") == true then
        return true
    end
    return false
end

local function GetBall()
    for _, child in pairs(BallsFolder:GetChildren()) do
        if child:GetAttribute("realBall") == true then
            return child
        end
    end
    return nil
end

local function FireParryRemote()
    local args = {
        1.5,
        Workspace.CurrentCamera.CFrame,
        {["2617721424"] = Vector3.new()},
        {ScreenPosition.X, ScreenPosition.Y}
    }
    ReplicatedStorage.Remotes.ParryAttempt:FireServer(unpack(args))
    Remotes:WaitForChild("ParryButtonPress"):Fire()
end

local function FireParryOnly()
    if SpamSettings.Legitize then
        FireParryRemote()
    else
        local args = {
            1.5,
            Workspace.CurrentCamera.CFrame,
            {["2617721424"] = Vector3.new()},
            {ScreenPosition.X, ScreenPosition.Y}
        }
        ReplicatedStorage.Remotes.ParryAttempt:FireServer(unpack(args))
    end
end

local function SpamParry()
    for _ = 1, SpamSettings.SpamSpeed do
        FireParryOnly()
    end
end

local function ExecuteSpam()
    if SpamSettings.BallSpeed ~= 0 or not SpamSettings.SpeedCheck then
        if SpamSettings.SpamSpeed < 2 then
            FireParryOnly()
        else
            SpamParry()
        end
    end
end

local function FireCurve()
    local curveArgs
    if AutoParrySettings.AutoCurveStyle == "Upwards" then
        curveArgs = {0.5, CFrame.new(-288.8354187011719, 28.22670555114746, -142.1251983642578, -0.9899671077728271, 0.1391517072916031, 0.02453617751598358, -7.188709627570233e-10, 0.17364804446697235, -0.9848078489303589, -0.1412983387708664, -0.9749273657798767, -0.17190583050251007), {["Dogman123456ho"] = Vector3.new()}, {357, 66}}
    elseif AutoParrySettings.AutoCurveStyle == "Backwards" then
        curveArgs = {0.5, CFrame.new(-377.11126708984375, 28.59453773498535, -193.3712921142578, 0.7151431441307068, 0.17414864897727966, 0.6769360899925232, 0, 0.9684654474258423, -0.24914753437042236, -0.6989780068397522, 0.178176149725914, 0.6925914883613586), {["Dogman123456ho"] = Vector3.new()}, {306, 92}}
    elseif AutoParrySettings.AutoCurveStyle == "Left" then
        curveArgs = {0.5, CFrame.new(-274.4162292480469, 28.725011825561523, 55.72505569458008, 0.03289260342717171, -0.011800095438957214, 0.9993892908096313, 2.9103830456733704e-11, 0.9999304413795471, 0.011806483380496502, -0.9994589686393738, -0.0003883459430653602, 0.032890308648347855), {["Dogman123456ho"] = Vector3.new()}, {571, 164}}
    elseif AutoParrySettings.AutoCurveStyle == "Right" then
        curveArgs = {0.5, CFrame.new(-186.2659912109375, 28.679378509521484, -144.88937377929688, 0.7096737623214722, 0.05598757416009903, 0.7023023366928101, 0, 0.9968374371528625, -0.07946792244911194, -0.7045304775238037, 0.05639629811048508, 0.7074293494224548), {["Dogman123456ho"] = Vector3.new()}, {372, 62}}
    end
    if curveArgs then
        ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ParryAttempt"):FireServer(unpack(curveArgs))
    end
end

local function ExecuteParry()
    if AutoParrySettings.AutoCurve then
        FireCurve()
    else
        Remotes:WaitForChild("ParryButtonPress"):Fire()
    end
end

local function IsBallClose()
    local ball = GetBall()
    if not ball then return false end
    local ballPos = ball.Position
    return (LocalPlayer.Character.HumanoidRootPart.Position - ballPos).Magnitude <= 6.5
end

local function ClaimPlaytimeRewards()
    for i = 1, 6 do
        pcall(function()
            ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.1.0"):WaitForChild("net"):WaitForChild("RF/ClaimPlaytimeReward"):InvokeServer(i)
        end)
    end
end

local function OpenExplosionCrate()
    pcall(function()
        ReplicatedStorage.Remote.RemoteFunction:InvokeServer("PromptPurchaseCrate", Workspace.Spawn.Crates.NormalExplosionCrate)
    end)
end

local function OpenSwordCrate()
    pcall(function()
        ReplicatedStorage.Remote.RemoteFunction:InvokeServer("PromptPurchaseCrate", Workspace.Spawn.Crates.NormalSwordCrate)
    end)
end

local function GetHumanoidRootPart()
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then return hrp end
    return nil
end

local function GetAliveCount()
    local count = 0
    for _, char in pairs(Workspace:WaitForChild("Alive", 20):GetChildren()) do
        if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 50 then
            count = count + 1
        end
    end
    return count
end

local function GetClosestEnemy()
    local closest = nil
    local closestDist = math.huge
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    for _, char in pairs(Workspace:WaitForChild("Alive"):GetChildren()) do
        if char.Name ~= LocalPlayer.Name and hrp and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health >= 50 then
            local dist = (char.PrimaryPart.Position - hrp.Position).Magnitude
            if dist <= closestDist then
                closest = char
                closestDist = dist
            end
        end
    end
    return closest
end

local slashEffects = {"particleemitter"}

local function RemoveSlashEffect(descendant)
    if not UtilitySettings.NoSlash then return end
    for _, effectName in pairs(slashEffects) do
        if string.find(string.lower(descendant.ClassName), effectName) then
            descendant.Lifetime = NumberRange.new(0)
            break
        end
    end
end

task.spawn(function()
    Workspace.DescendantAdded:Connect(RemoveSlashEffect)
end)

RunService.PostSimulation:Connect(function()
    local ball = GetBall()
    if ball then
        SpamSettings.BallSpeed = ball.AssemblyLinearVelocity.Magnitude
    end
end)

RunService.PostSimulation:Connect(function()
    if AutoParrySettings.AutoParry then
        if AutoParrySettings.RandomizeDistance then
            local max = AutoParrySettings.RandomizeMax
            local min = AutoParrySettings.RandomizeMin
            local randomVal = math.random(min, max)
            AutoParrySettings.JumpHit = tonumber(randomVal * 5 / 100)
            AutoParrySettings.StandHit = tonumber(randomVal)
            DistanceToHitValue = tonumber(randomVal)
        else
            AutoParrySettings.JumpHit = BackupSettings.BackUpJumpHit
            AutoParrySettings.StandHit = BackupSettings.BackUpStanHit
            DistanceToHitValue = DistanceToHitBackup
        end
    end
end)

RunService.PostSimulation:Connect(function()
    if AutoParrySettings.RainbowAmbient then
        Lighting.Ambient = Color3.fromHSV(tick() % 5 / 5, 1, 1)
    end
    if AutoParrySettings.RainbowFog then
        Lighting.FogColor = Color3.fromHSV(tick() % 5 / 5, 1, 1)
    end
end)

RunService.PostSimulation:Connect(function()
    if UtilitySettings.AutoClaimRewards then ClaimPlaytimeRewards() end
    if UtilitySettings.AutoSword then OpenSwordCrate() end
    if UtilitySettings.AutoExplosion then OpenExplosionCrate() end
end)

RunService.PostSimulation:Connect(function()
    if AutoParrySettings.RandomCurveStyles then
        local rand = math.random(1, 4)
        if rand == 1 then AutoParrySettings.AutoCurveStyle = "Right"
        elseif rand == 2 then AutoParrySettings.AutoCurveStyle = "Left"
        elseif rand == 3 then AutoParrySettings.AutoCurveStyle = "Backwards"
        elseif rand == 4 then AutoParrySettings.AutoCurveStyle = "Upwards"
        end
    else
        AutoParrySettings.AutoCurveStyle = CurveStyleBackup
    end
end)

RunService.PreRender:Connect(function()
    if Character:FindFirstChild("Humanoid") then
        pcall(function()
            IsJumping = LocalPlayer.Character.Humanoid:GetState() == Enum.HumanoidStateType.Freefall
        end)
    end
end)

RunService.PreRender:Connect(function()
    local ball = GetBall()
    if ball and AutoParrySettings.LookAt then
        if AutoParrySettings.LookAtMethod == "Player CFrame" then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(LocalPlayer.Character.HumanoidRootPart.Position, Vector3.new(ball.Position.X, LocalPlayer.Character.HumanoidRootPart.Position.Y, ball.Position.Z))
        elseif AutoParrySettings.LookAtMethod == "Camera CFrame" then
            Workspace.CurrentCamera.CFrame = CFrame.lookAt(Workspace.CurrentCamera.CFrame.Position, ball.CFrame.Position)
        end
    end
end)

RunService.PostSimulation:Connect(function()
    local ball = GetBall()
    if ball then
        local ballSpeed = ball.AssemblyLinearVelocity.Magnitude
        if ball:GetAttribute("Frozen") == true and ball:GetAttribute("target") == LocalPlayer.Name and not IsTargeted and ballSpeed == 0 then
            IsTargeted = true
        end
        if not IsTargeted and ball:GetAttribute("target") == LocalPlayer.Name and not ball:GetAttribute("Frozen") and ballSpeed == 0 then
            IsTargeted = true
        end
    end
end)

RunService.PostSimulation:Connect(function()
    local ball = GetBall()
    if not ball then return end
    if not AutoParrySettings.AutoParry then return end
    if not (VisualBall or VisualClash or VisualDistance or VisualCircleBall or VisualCircleClash or VisualCircleDistance) then return end
    
    local hipHeight = LocalPlayer.Character.Humanoid.HipHeight + CircleHeight
    local hrp = LocalPlayer.Character:WaitForChild("HumanoidRootPart")
    local ballDist = (ball.CFrame.Position - Workspace.CurrentCamera.Focus.Position).Magnitude
    
    if hrp then
        if VisualBall then
            VisualizerPart1.Shape = VisualizerShape
            VisualizerPart1.Material = VisualizerMaterial or Enum.Material.ForceField
            VisualizerPart1.Transparency = VisualizerTransparency
            VisualizerPart1.Size = Vector3.new(DistanceToHitValue, DistanceToHitValue, DistanceToHitValue)
            VisualizerPart1.Color = AutoParrySettings.Rainbow and Color3.fromHSV(tick() % 5 / 5, 1, 1) or VisualizerColor
            VisualizerPart1.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
            VisualizerPart1.Parent = hrp
        else
            VisualizerPart1.Parent = nil
        end
        
        if VisualClash then
            VisualizerPart2.Shape = VisualizerShape
            VisualizerPart2.Material = VisualizerMaterial or Enum.Material.ForceField
            VisualizerPart2.Transparency = VisualizerTransparency
            VisualizerPart2.Size = Vector3.new(ClashSettings.DistanceToActivate, ClashSettings.DistanceToActivate, ClashSettings.DistanceToActivate)
            VisualizerPart2.Color = AutoParrySettings.Rainbow and Color3.fromHSV(tick() % 5 / 5, 1, 1) or VisualizerColor
            VisualizerPart2.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
            VisualizerPart2.Parent = Workspace
        else
            VisualizerPart2.Parent = nil
        end
        
        if VisualDistance then
            VisualizerPart3.Shape = VisualizerShape
            VisualizerPart3.Material = VisualizerMaterial or Enum.Material.ForceField
            VisualizerPart3.Transparency = VisualizerTransparency
            VisualizerPart3.Size = Vector3.new(ballDist, ballDist, ballDist)
            VisualizerPart3.Color = AutoParrySettings.Rainbow and Color3.fromHSV(tick() % 5 / 5, 1, 1) or VisualizerColor
            VisualizerPart3.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
            VisualizerPart3.Parent = hrp
        else
            VisualizerPart3.Parent = nil
        end
        
        if VisualCircleBall or VisualCircleClash or VisualCircleDistance then
            CircleAdornee.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y - hipHeight, hrp.Position.Z)
        end
        
        if VisualCircleBall then
            CircleAdornment1.CFrame = CFrame.new() * CFrame.fromOrientation(math.rad(90), 0, 0)
            CircleAdornment1.Adornee = CircleAdornee
            CircleAdornment1.Radius = DistanceToHitValue
            CircleAdornment1.InnerRadius = DistanceToHitValue
            CircleAdornment1.Height = hipHeight
            CircleAdornment1.Color3 = AutoParrySettings.CircleRainbow and Color3.fromHSV(tick() % 5 / 5, 1, 1) or CircleVisualizerColor
            CircleAdornment1.Visible = true
        else
            CircleAdornment1.Visible = false
        end
        
        if VisualCircleClash then
            CircleAdornment2.CFrame = CFrame.new() * CFrame.fromOrientation(math.rad(90), 0, 0)
            CircleAdornment2.Adornee = CircleAdornee
            CircleAdornment2.Radius = ClashSettings.DistanceToActivate
            CircleAdornment2.InnerRadius = ClashSettings.DistanceToActivate
            CircleAdornment2.Height = hipHeight
            CircleAdornment2.Color3 = AutoParrySettings.CircleRainbow and Color3.fromHSV(tick() % 5 / 5, 1, 1) or CircleVisualizerColor
            CircleAdornment2.Visible = true
        else
            CircleAdornment2.Visible = false
        end
        
        if VisualCircleDistance then
            CircleAdornment3.CFrame = CFrame.new() * CFrame.fromOrientation(math.rad(90), 0, 0)
            CircleAdornment3.Adornee = CircleAdornee
            CircleAdornment3.Radius = ballDist
            CircleAdornment3.InnerRadius = ballDist
            CircleAdornment3.Height = hipHeight
            CircleAdornment3.Color3 = AutoParrySettings.CircleRainbow and Color3.fromHSV(tick() % 5 / 5, 1, 1) or CircleVisualizerColor
            CircleAdornment3.Visible = true
        else
            CircleAdornment3.Visible = false
        end
    end
end)

BallsFolder.ChildAdded:Connect(function(ball)
    if IsRealBall(ball) then
        ball:GetAttributeChangedSignal("target"):Connect(function()
            if AutoParrySettings.AutoParry and GetBall() then
                if ball:GetAttribute("target") ~= LocalPlayer.Name then
                    IsTargeted = false
                else
                    IsTargeted = true
                end
            end
        end)
    end
end)

BallsFolder.ChildAdded:Connect(function(ball)
    if IsRealBall(ball) then
        if GetBall() then
            if IsTargeted then return end
            if AutoParrySettings.AutoParry and ball:GetAttribute("target") == LocalPlayer.Name then
                IsTargeted = true
            end
        end
    end
end)

BallsFolder.ChildAdded:Connect(function(ball)
    if IsRealBall(ball) then
        if IsTargeted and IsBallClose() then
            IsTargeted = false
            ExecuteParry()
        end
    end
end)

BallsFolder.ChildAdded:Connect(function(ball)
    if IsRealBall(ball) then
        local lastPosition = ball.CFrame.Position
        local lastTime = time()
        
        ball:GetPropertyChangedSignal("Position"):Connect(function()
            if not GetBall() then return end
            if AutoRageEnabled then return end
            if not AutoParrySettings.AutoParry then return end
            
            local currentBall = GetBall()
            local velocity = currentBall.AssemblyLinearVelocity.Magnitude
            local travelDistance = (lastPosition - currentBall.CFrame.Position).Magnitude
            
            if IsJumping and AutoParrySettings.CurveAnti then
                AutoParrySettings.DistanceHit = AutoParrySettings.JumpHit
                travelDistance = velocity
            else
                AutoParrySettings.DistanceHit = AutoParrySettings.StandHit
            end
            
            if AutoParrySettings.CurveAnti then
                velocity = travelDistance
            else
                AutoParrySettings.DistanceHit = AutoParrySettings.JumpHit
            end
            
            local ballPos = currentBall.Position
            local playerPos = LocalPlayer.Character.PrimaryPart.Position
            local distance = LocalPlayer:DistanceFromCharacter(ballPos)
            local pingOffset = currentBall.AssemblyLinearVelocity:Dot((playerPos - ballPos).Unit) * (game.Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000)
            
            if AutoParrySettings.PingBased then
                distance = distance - pingOffset - AutoParrySettings.Offset
            end
            
            if currentBall.AssemblyLinearVelocity.Magnitude ~= 0 then
                if distance / velocity <= AutoParrySettings.DistanceHit and IsTargeted and CurveReady and AutoParrySettings.AutoParry and not AutoRageEnabled then
                    CurveReady = false
                    IsTargeted = false
                    ExecuteParry()
                end
                
                if time() - lastTime >= 0.016666666666666666 then
                    lastTime = time()
                    lastPosition = currentBall.CFrame.Position
                end
            end
        end)
    end
end)

BallsFolder.ChildAdded:Connect(function(ball)
    if IsRealBall(ball) then
        local lastPosition = ball.CFrame.Position
        local lastTime = time()
        
        ball:GetPropertyChangedSignal("Position"):Connect(function()
            if not GetBall() then return end
            if not AutoParrySettings.AutoParry then return end
            if not AutoRageEnabled then return end
            
            local currentBall = GetBall()
            local velocity = currentBall.AssemblyLinearVelocity.Magnitude
            local travelDistance = (lastPosition - currentBall.CFrame.Position).Magnitude
            
            if IsJumping and AutoParrySettings.CurveAnti then
                AutoParrySettings.DistanceHit = AutoParrySettings.JumpHit
                travelDistance = velocity
            else
                AutoParrySettings.DistanceHit = AutoParrySettings.StandHit
            end
            
            if AutoParrySettings.CurveAnti then
                velocity = travelDistance
            else
                AutoParrySettings.DistanceHit = AutoParrySettings.JumpHit
            end
            
            local ballPos = currentBall.Position
            local playerPos = LocalPlayer.Character.PrimaryPart.Position
            local distance = LocalPlayer:DistanceFromCharacter(ballPos)
            local pingOffset = currentBall.AssemblyLinearVelocity:Dot((playerPos - ballPos).Unit) * (game.Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000)
            
            if AutoParrySettings.PingBased then
                distance = distance - pingOffset - AutoParrySettings.Offset
            end
            
            if currentBall.AssemblyLinearVelocity.Magnitude ~= 0 then
                if distance / velocity <= AutoParrySettings.DistanceHit and IsTargeted and CurveReady and AutoParrySettings.AutoParry and AutoRageEnabled then
                    if IsAbilityReady(AbilityGradient) then
                        IsTargeted = false
                        CurveReady = false
                        ExecuteParry()
                    else
                        IsTargeted = false
                        CurveReady = false
                        Remotes:WaitForChild("AbilityButtonPress"):Fire()
                    end
                end
                
                if time() - lastTime >= 0.016666666666666666 then
                    lastTime = time()
                    lastPosition = currentBall.CFrame.Position
                end
            end
        end)
    end
end)

RunService.PostSimulation:Connect(function()
    if AutoParrySettings.CurveAnti then
        pcall(function()
            local ball = GetBall()
            if ball then
                local distance = (Workspace.CurrentCamera.Focus.Position - ball.CFrame.Position).Magnitude
                local pingOffset = ball.AssemblyLinearVelocity.Magnitude * (game.Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000)
                if AutoParrySettings.PingBased then
                    distance = distance - pingOffset + AutoParrySettings.Offset
                end
                CurveReady = true
            else
                CurveReady = false
            end
        end)
    else
        CurveReady = true
    end
end)

BallsFolder.ChildAdded:Connect(function(ball)
    ball:GetPropertyChangedSignal("Position"):Connect(function()
        if SpamSettings.LoopType == "New" then
            if ManualSpamEnabled then
                ExecuteSpam()
                if SpamSettings.SpamLoops == "Dual" or SpamSettings.SpamLoops == "Triple" or SpamSettings.SpamLoops == "Quad" then
                    ExecuteSpam()
                end
                if SpamSettings.SpamLoops == "Triple" or SpamSettings.SpamLoops == "Quad" then
                    ExecuteSpam()
                end
                if SpamSettings.SpamLoops == "Quad" then
                    ExecuteSpam()
                end
            end
            
            if PCSpamActive and SpamSettings.PCSpam then
                ExecuteSpam()
                if SpamSettings.SpamLoops == "Dual" or SpamSettings.SpamLoops == "Triple" or SpamSettings.SpamLoops == "Quad" then
                    ExecuteSpam()
                end
                if SpamSettings.SpamLoops == "Triple" or SpamSettings.SpamLoops == "Quad" then
                    ExecuteSpam()
                end
                if SpamSettings.SpamLoops == "Quad" then
                    ExecuteSpam()
                end
            end
        end
    end)
end)

task.spawn(function()
    while task.wait() do
        if ManualSpamEnabled and SpamSettings.LoopType == "Old" then
            ExecuteSpam()
        end
    end
end)

task.spawn(function()
    while task.wait() do
        if PCSpamActive and SpamSettings.PCSpam and SpamSettings.LoopType == "Old" then
            ExecuteSpam()
        end
    end
end)

BallsFolder.ChildAdded:Connect(function(ball)
    ball:GetPropertyChangedSignal("Position"):Connect(function()
        if SpamSettings.LoopType == "New" and AutoSpamActive and AutoParrySettings.AutoSpam then
            ExecuteSpam()
            if SpamSettings.SpamLoops == "Dual" or SpamSettings.SpamLoops == "Triple" or SpamSettings.SpamLoops == "Quad" then
                ExecuteSpam()
            end
            if SpamSettings.SpamLoops == "Triple" or SpamSettings.SpamLoops == "Quad" then
                ExecuteSpam()
            end
            if SpamSettings.SpamLoops == "Quad" then
                ExecuteSpam()
            end
        end
    end)
end)

task.spawn(function()
    while task.wait() do
        if AutoSpamActive and AutoParrySettings.AutoSpam and SpamSettings.LoopType == "Old" then
            ExecuteSpam()
        end
    end
end)

BallsFolder.ChildAdded:Connect(function(_)
    ClashCount = 0
    if ClashSettings.DistanceToActivateDynamic then
        ClashSettings.DistanceToActivate = ClashSettings.BackUpDistanceToActivate
    end
end)

local function InitializeClashSystem()
    local lastBall = nil
    local lastTarget = ""
    local distanceFromBall = 0
    local traveledDistance = 0
    local lastCheckTime = tick()
    local lastBallPosition = Vector3.new()
    
    RunService.PreRender:Connect(function()
        if AutoParrySettings.AutoSpam then
            local hrp = GetHumanoidRootPart()
            local ball = BallsFolder:FindFirstChildOfClass("Part")
            if hrp and ball then
                distanceFromBall = (hrp.Position - ball.Position).Magnitude
                traveledDistance = (lastBallPosition - ball.Position).Magnitude
                if tick() - lastCheckTime >= 0.016666666666666666 then
                    lastCheckTime = tick()
                    lastBallPosition = ball.Position
                end
            end
        end
    end)
    
    RunService.PreRender:Connect(function()
        if AutoParrySettings.AutoSpam then
            local ball = BallsFolder:FindFirstChildOfClass("Part")
            local hrp = GetHumanoidRootPart()
            local closestEnemy = GetClosestEnemy()
            
            if not ball then
                AutoSpamActive = false
                return
            end
            
            if ball and ball:GetAttribute("realBall") and lastBall ~= ball then
                ball.Changed:Connect(function()
                    task.wait()
                    local currentBall = BallsFolder:FindFirstChildOfClass("Part")
                    if currentBall then
                        lastTarget = currentBall:GetAttribute("target")
                        local enemyDistance = closestEnemy and (closestEnemy.PrimaryPart.Position - hrp.Position).Magnitude or math.huge
                        
                        if closestEnemy and (lastTarget == closestEnemy.Name or (LocalPlayer and lastTarget == LocalPlayer.Name)) and enemyDistance <= ClashSettings.DistanceToActivate then
                            ClashCount = ClashCount + 1
                        else
                            ClashCount = 0
                        end
                        
                        if ClashSettings.DistanceToActivateDynamic then
                            ClashSettings.DistanceToActivate = ClashSettings.DistanceToActivate + math.clamp(ClashCount / 3, 0, ClashSettings.DynamicAddedDistance)
                        else
                            ClashSettings.DistanceToActivate = ClashSettings.BackUpDistanceToActivate
                        end
                        
                        local enemyHighlight = closestEnemy and closestEnemy:FindFirstChild("Highlight")
                        local playerHighlight = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Highlight")
                        local enemyHRP = closestEnemy and closestEnemy:FindFirstChild("HumanoidRootPart")
                        
                        if hrp and (enemyHighlight or playerHighlight) and enemyHRP then
                            local playerEnemyDist = (closestEnemy.PrimaryPart.Position - hrp.Position).Magnitude
                            local ballPlayerDist = (currentBall.Position - hrp.Position).Magnitude
                            
                            if GetAliveCount() >= 3 then
                                if playerEnemyDist > ClashSettings.DistanceToActivate or ballPlayerDist > ClashSettings.DistanceBallActivate or ClashCount < ClashSettings.HitsTillClash then
                                    AutoSpamActive = false
                                else
                                    AutoSpamActive = true
                                end
                            else
                                if playerEnemyDist > ClashSettings.DistanceToActivate or ballPlayerDist > ClashSettings.DistanceBallActivate or ClashCount < ClashSettings.HitsTillClash then
                                    AutoSpamActive = false
                                else
                                    AutoSpamActive = true
                                end
                            end
                        else
                            AutoSpamActive = false
                        end
                    end
                end)
                lastBall = ball
            end
        end
    end)
end

InitializeClashSystem()

local UIToggleTool = Instance.new("Tool")
UIToggleTool.RequiresHandle = false
UIToggleTool.Name = "Toggle Invictus UI"
UIToggleTool.Activated:Connect(function()
    Library:ToggleUI()
end)

LocalPlayer.CharacterRemoving:Connect(function()
    UIToggleTool.Parent = LocalPlayer.Backpack
end)

UIToggleTool.Parent = LocalPlayer.Backpack

Library:OnUnload(function()
    SpamGui:Destroy()
    VisualizerPart1:Destroy()
    VisualizerPart2:Destroy()
    VisualizerPart3:Destroy()
    CircleAdornee:Destroy()
    CircleAdornment1:Destroy()
    CircleAdornment2:Destroy()
    CircleAdornment3:Destroy()
    UIToggleTool:Destroy()
end)

Library:Notify({
    Title = "Invictus",
    Description = "Script loaded successfully! Enjoy.",
    Time = 5,
})

Window:SelectTab(1)
