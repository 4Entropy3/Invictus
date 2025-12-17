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
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local BallsFolder = Workspace:WaitForChild("Balls", 9999999)

local OriginalAmbient = Lighting.Ambient
local OriginalFogColor = Lighting.FogColor
local OriginalClockTime = Lighting.ClockTime

local Parried = false
local BallConnection = nil

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
    BallSpeed = 0,
    LoopType = "Old",
    SemiBlatant = false
}

local ClashSettings = {
    HitsTillClash = 4,
    DistanceToActivate = 30,
    DistanceBallActivate = 35,
    BackUpDistanceToActivate = 30,
    DistanceToActivateDynamic = false,
    DynamicAddedDistance = 10
}

local VisualBall = true
local VisualClash = true
local VisualDistance = true
local VisualCircleBall = true
local VisualCircleClash = true
local VisualCircleDistance = true
local DistanceToHitValue = 10
local DistanceToHitBackup = 10
local AutoRageEnabled = false
local VisualizerShape = "Ball"
local VisualizerColor = Color3.fromRGB(255, 255, 255)
local CircleVisualizerColor = Color3.fromRGB(255, 255, 255)
local VisualizerTransparency = 0
local VisualizerMaterial = "ForceField"
local CircleHeight = 0.5
local CurveStyleBackup = "Upwards"

local IsTargeted = false
local IsJumping = false
local CurveReady = true
local ManualSpamEnabled = false
local PCSpamActive = false
local AutoSpamActive = false
local ClashCount = 0

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
    Default = "2",
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
    Default = true,
})

Toggles.VisDistanceToHit:OnChanged(function()
    VisualBall = Toggles.VisDistanceToHit.Value
end)

VisBallGroup:AddToggle("VisClashRange", {
    Text = "Clash Range Visualizer",
    Default = true,
})

Toggles.VisClashRange:OnChanged(function()
    VisualClash = Toggles.VisClashRange.Value
end)

VisBallGroup:AddToggle("VisBallDistance", {
    Text = "Ball Distance Visualizer",
    Default = true,
})

Toggles.VisBallDistance:OnChanged(function()
    VisualDistance = Toggles.VisBallDistance.Value
end)

local VisCircleGroup = Tabs.Visuals:AddRightGroupbox("Circle Visualizers")

VisCircleGroup:AddToggle("VisCircleDistance", {
    Text = "Distance To Hit Circle",
    Default = true,
})

Toggles.VisCircleDistance:OnChanged(function()
    VisualCircleBall = Toggles.VisCircleDistance.Value
end)

VisCircleGroup:AddToggle("VisCircleClash", {
    Text = "Clash Range Circle",
    Default = true,
})

Toggles.VisCircleClash:OnChanged(function()
    VisualCircleClash = Toggles.VisCircleClash.Value
end)

VisCircleGroup:AddToggle("VisCircleBallDist", {
    Text = "Ball Distance Circle",
    Default = true,
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

local function GetBall()
    for _, ball in ipairs(BallsFolder:GetChildren()) do
        if ball:GetAttribute("realBall") then
            return ball
        end
    end
    return nil
end

local function GetBallSpeed(ball)
    if ball then
        if ball:FindFirstChild("zoomies") then
            return ball.zoomies.VectorVelocity.Magnitude
        else
            return ball.AssemblyLinearVelocity.Magnitude
        end
    end
    return 0
end

local function Parry()
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

local function FireCurve()
    if AutoParrySettings.AutoCurveStyle == "Upwards" then
        local args = {0.5, CFrame.new(-288.835, 28.226, -142.125, -0.9899, 0.1391, 0.0245, 0, 0.1736, -0.9848, -0.1412, -0.9749, -0.1719), {["Dogman123456ho"] = Vector3.new()}, {357, 66}}
        pcall(function() ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ParryAttempt"):FireServer(unpack(args)) end)
    elseif AutoParrySettings.AutoCurveStyle == "Backwards" then
        local args = {0.5, CFrame.new(-377.111, 28.594, -193.371, 0.7151, 0.1741, 0.6769, 0, 0.9684, -0.2491, -0.6989, 0.1781, 0.6925), {["Dogman123456ho"] = Vector3.new()}, {306, 92}}
        pcall(function() ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ParryAttempt"):FireServer(unpack(args)) end)
    elseif AutoParrySettings.AutoCurveStyle == "Left" then
        local args = {0.5, CFrame.new(-274.416, 28.725, 55.725, 0.0328, -0.0118, 0.9993, 0, 0.9999, 0.0118, -0.9994, -0.0003, 0.0328), {["Dogman123456ho"] = Vector3.new()}, {571, 164}}
        pcall(function() ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ParryAttempt"):FireServer(unpack(args)) end)
    elseif AutoParrySettings.AutoCurveStyle == "Right" then
        local args = {0.5, CFrame.new(-186.265, 28.679, -144.889, 0.7096, 0.0559, 0.7023, 0, 0.9968, -0.0794, -0.7045, 0.0563, 0.7074), {["Dogman123456ho"] = Vector3.new()}, {372, 62}}
        pcall(function() ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ParryAttempt"):FireServer(unpack(args)) end)
    end
end

local function SpamParry()
    for _ = 1, SpamSettings.SpamSpeed do
        Parry()
    end
end

local function ExecuteSpam()
    if SpamSettings.BallSpeed ~= 0 or not SpamSettings.SpeedCheck then
        if SpamSettings.SpamSpeed < 2 then
            Parry()
        else
            SpamParry()
        end
    end
end

local function GetHumanoidRootPart()
    if LocalPlayer.Character then
        return LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

local function GetAliveCount()
    local count = 0
    local aliveFolder = Workspace:FindFirstChild("Alive")
    if aliveFolder then
        for _, char in pairs(aliveFolder:GetChildren()) do
            if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 50 then
                count = count + 1
            end
        end
    end
    return count
end

local function GetClosestEnemy()
    local closest = nil
    local closestDist = math.huge
    local hrp = GetHumanoidRootPart()
    local aliveFolder = Workspace:FindFirstChild("Alive")
    if not aliveFolder or not hrp then return nil end
    
    for _, char in pairs(aliveFolder:GetChildren()) do
        if char.Name ~= LocalPlayer.Name and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health >= 50 then
            local dist = (char.HumanoidRootPart.Position - hrp.Position).Magnitude
            if dist < closestDist then
                closest = char
                closestDist = dist
            end
        end
    end
    return closest
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

local slashEffects = {"particleemitter"}

local function RemoveSlashEffect(descendant)
    if not UtilitySettings.NoSlash then return end
    for _, effectName in pairs(slashEffects) do
        if string.find(string.lower(descendant.ClassName), effectName) then
            pcall(function()
                descendant.Lifetime = NumberRange.new(0)
            end)
            break
        end
    end
end

task.spawn(function()
    Workspace.DescendantAdded:Connect(RemoveSlashEffect)
end)

local function ResetBallConnection()
    if BallConnection then
        BallConnection:Disconnect()
        BallConnection = nil
    end
end

BallsFolder.ChildAdded:Connect(function()
    local ball = GetBall()
    if not ball then return end
    ResetBallConnection()
    Parried = false
    IsTargeted = false
    BallConnection = ball:GetAttributeChangedSignal("target"):Connect(function()
        Parried = false
        if ball:GetAttribute("target") == LocalPlayer.Name then
            IsTargeted = true
        else
            IsTargeted = false
        end
    end)
end)

RunService.PostSimulation:Connect(function()
    local ball = GetBall()
    if ball then
        SpamSettings.BallSpeed = GetBallSpeed(ball)
    end
end)

RunService.PostSimulation:Connect(function()
    if AutoParrySettings.AutoParry and AutoParrySettings.RandomizeDistance then
        local min = AutoParrySettings.RandomizeMin
        local max = AutoParrySettings.RandomizeMax
        local randomVal = math.random(min, max)
        AutoParrySettings.JumpHit = tonumber(randomVal * 5 / 100)
        AutoParrySettings.StandHit = tonumber(randomVal)
        DistanceToHitValue = tonumber(randomVal)
    elseif AutoParrySettings.AutoParry then
        AutoParrySettings.JumpHit = BackupSettings.BackUpJumpHit
        AutoParrySettings.StandHit = BackupSettings.BackUpStanHit
        DistanceToHitValue = DistanceToHitBackup
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
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        pcall(function()
            IsJumping = LocalPlayer.Character.Humanoid:GetState() == Enum.HumanoidStateType.Freefall
        end)
    end
end)

RunService.PreRender:Connect(function()
    local ball = GetBall()
    if ball and AutoParrySettings.LookAt then
        local hrp = GetHumanoidRootPart()
        if hrp then
            if AutoParrySettings.LookAtMethod == "Player CFrame" then
                hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(ball.Position.X, hrp.Position.Y, ball.Position.Z))
            elseif AutoParrySettings.LookAtMethod == "Camera CFrame" then
                Workspace.CurrentCamera.CFrame = CFrame.lookAt(Workspace.CurrentCamera.CFrame.Position, ball.Position)
            end
        end
    end
end)

BallsFolder.ChildAdded:Connect(function(ball)
    if not ball:GetAttribute("realBall") then return end
    
    local lastPosition = ball.CFrame.Position
    local lastTime = time()
    
    ball:GetPropertyChangedSignal("Position"):Connect(function()
        if not AutoParrySettings.AutoParry then return end
        if AutoRageEnabled then return end
        
        local currentBall = GetBall()
        if not currentBall then return end
        
        local hrp = GetHumanoidRootPart()
        if not hrp then return end
        
        local speed = GetBallSpeed(currentBall)
        local travelDistance = (lastPosition - currentBall.CFrame.Position).Magnitude
        
        if IsJumping and AutoParrySettings.CurveAnti then
            AutoParrySettings.DistanceHit = AutoParrySettings.JumpHit
            travelDistance = speed
        else
            AutoParrySettings.DistanceHit = AutoParrySettings.StandHit
        end
        
        if AutoParrySettings.CurveAnti then
            speed = travelDistance
        end
        
        local ballPos = currentBall.Position
        local playerPos = LocalPlayer.Character.PrimaryPart.Position
        local distance = LocalPlayer:DistanceFromCharacter(ballPos)
        local pingOffset = currentBall.AssemblyLinearVelocity:Dot((playerPos - ballPos).Unit) * (game.Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000)
        
        if AutoParrySettings.PingBased then
            distance = distance - pingOffset - AutoParrySettings.Offset
        end
        
        local isTarget = currentBall:GetAttribute("target") == LocalPlayer.Name
        
        if speed ~= 0 then
            if distance / speed <= AutoParrySettings.DistanceHit and isTarget and not Parried then
                Parried = true
                if AutoParrySettings.AutoCurve then
                    FireCurve()
                end
                Parry()
            end
            
            if time() - lastTime >= 0.016666666666666666 then
                lastTime = time()
                lastPosition = currentBall.CFrame.Position
            end
        end
    end)
end)

RunService.PostSimulation:Connect(function()
    local ball = GetBall()
    if not ball then return end
    if not AutoParrySettings.AutoParry then return end
    if not (VisualBall or VisualClash or VisualDistance or VisualCircleBall or VisualCircleClash or VisualCircleDistance) then return end
    
    local hrp = GetHumanoidRootPart()
    if not hrp then return end
    
    local hipHeight = LocalPlayer.Character.Humanoid.HipHeight + CircleHeight
    local ballDist = (ball.Position - Workspace.CurrentCamera.Focus.Position).Magnitude
    
    if VisualBall then
        VisualizerPart1.Shape = VisualizerShape
        VisualizerPart1.Material = VisualizerMaterial or Enum.Material.ForceField
        VisualizerPart1.Transparency = VisualizerTransparency
        VisualizerPart1.Size = Vector3.new(DistanceToHitValue, DistanceToHitValue, DistanceToHitValue)
        VisualizerPart1.Color = AutoParrySettings.Rainbow and Color3.fromHSV(tick() % 5 / 5, 1, 1) or VisualizerColor
        VisualizerPart1.CFrame = hrp.CFrame
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
        VisualizerPart2.CFrame = hrp.CFrame
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
        VisualizerPart3.CFrame = hrp.CFrame
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
end)

BallsFolder.ChildAdded:Connect(function(ball)
    ball:GetPropertyChangedSignal("Position"):Connect(function()
        if SpamSettings.LoopType == "New" then
            if ManualSpamEnabled then
                ExecuteSpam()
                if SpamSettings.SpamLoops == "Dual" or SpamSettings.SpamLoops == "Triple" or SpamSettings.SpamLoops == "Quad" then ExecuteSpam() end
                if SpamSettings.SpamLoops == "Triple" or SpamSettings.SpamLoops == "Quad" then ExecuteSpam() end
                if SpamSettings.SpamLoops == "Quad" then ExecuteSpam() end
            end
            
            if PCSpamActive and SpamSettings.PCSpam then
                ExecuteSpam()
                if SpamSettings.SpamLoops == "Dual" or SpamSettings.SpamLoops == "Triple" or SpamSettings.SpamLoops == "Quad" then ExecuteSpam() end
                if SpamSettings.SpamLoops == "Triple" or SpamSettings.SpamLoops == "Quad" then ExecuteSpam() end
                if SpamSettings.SpamLoops == "Quad" then ExecuteSpam() end
            end
            
            if AutoSpamActive and AutoParrySettings.AutoSpam then
                ExecuteSpam()
                if SpamSettings.SpamLoops == "Dual" or SpamSettings.SpamLoops == "Triple" or SpamSettings.SpamLoops == "Quad" then ExecuteSpam() end
                if SpamSettings.SpamLoops == "Triple" or SpamSettings.SpamLoops == "Quad" then ExecuteSpam() end
                if SpamSettings.SpamLoops == "Quad" then ExecuteSpam() end
            end
        end
    end)
end)

task.spawn(function()
    while task.wait() do
        if SpamSettings.LoopType == "Old" then
            if ManualSpamEnabled then ExecuteSpam() end
            if PCSpamActive and SpamSettings.PCSpam then ExecuteSpam() end
            if AutoSpamActive and AutoParrySettings.AutoSpam then ExecuteSpam() end
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
    
    RunService.PreRender:Connect(function()
        if not AutoParrySettings.AutoSpam then 
            AutoSpamActive = false
            return 
        end
        
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
                if not currentBall or not hrp or not closestEnemy then 
                    AutoSpamActive = false
                    return 
                end
                
                local target = currentBall:GetAttribute("target")
                local enemyHRP = closestEnemy:FindFirstChild("HumanoidRootPart")
                if not enemyHRP then return end
                
                local enemyDistance = (enemyHRP.Position - hrp.Position).Magnitude
                
                if target == closestEnemy.Name or target == LocalPlayer.Name then
                    if enemyDistance <= ClashSettings.DistanceToActivate then
                        ClashCount = ClashCount + 1
                    end
                else
                    ClashCount = 0
                end
                
                if ClashSettings.DistanceToActivateDynamic then
                    ClashSettings.DistanceToActivate = ClashSettings.BackUpDistanceToActivate + math.clamp(ClashCount / 3, 0, ClashSettings.DynamicAddedDistance)
                end
                
                local enemyHighlight = closestEnemy:FindFirstChild("Highlight")
                local playerHighlight = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Highlight")
                
                if (enemyHighlight or playerHighlight) and enemyHRP then
                    local ballPlayerDist = (currentBall.Position - hrp.Position).Magnitude
                    
                    if enemyDistance <= ClashSettings.DistanceToActivate and ballPlayerDist <= ClashSettings.DistanceBallActivate and ClashCount >= ClashSettings.HitsTillClash then
                        AutoSpamActive = true
                    else
                        AutoSpamActive = false
                    end
                else
                    AutoSpamActive = false
                end
            end)
            lastBall = ball
        end
    end)
end

InitializeClashSystem()

Library:OnUnload(function()
    ResetBallConnection()
    SpamGui:Destroy()
    VisualizerPart1:Destroy()
    VisualizerPart2:Destroy()
    VisualizerPart3:Destroy()
    CircleAdornee:Destroy()
    CircleAdornment1:Destroy()
    CircleAdornment2:Destroy()
    CircleAdornment3:Destroy()
end)

Library:Notify({
    Title = "Invictus",
    Description = "Script loaded successfully! Enjoy.",
    Time = 5,
})

Window:SelectTab(1)
