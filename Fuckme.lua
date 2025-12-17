repeat task.wait() until game:IsLoaded()

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local plrs = game:GetService("Players")
local runService = game:GetService("RunService")
local lighting = game:GetService("Lighting")
local repStorage = game:GetService("ReplicatedStorage")
local vim = game:GetService("VirtualInputManager")

local me = plrs.LocalPlayer
local balls = workspace:WaitForChild("Balls", 999999)

local parried = false
local ballConn = nil

local origAmbient = lighting.Ambient
local origFog = lighting.FogColor
local origTime = lighting.ClockTime

local cfg = {
    autoParry = true,
    distanceHit = 10,
    offset = 0,
    lookAt = false,
    lookType = "Camera",
    rainbow = false,
    circleRainbow = false,
    rainbowAmbient = false,
    rainbowFog = false
}

local utils = {
    noSlash = false,
    autoClaim = false,
    autoSword = false,
    autoExplosion = false
}

local visuals = {
    ball = true,
    clash = true,
    distance = true,
    circleBall = true,
    circleClash = true,
    circleDistance = true
}

local visualCfg = {
    shape = "Ball",
    material = "ForceField",
    color = Color3.fromRGB(255, 255, 255),
    circleColor = Color3.fromRGB(255, 255, 255),
    transparency = 0,
    circleHeight = 0.5,
    clashDist = 30
}

local Window = Library:CreateWindow({
    Title = "Invictus",
    Footer = "invictus uwu",
    Icon = 85451000785501,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = {
    Home = Window:AddTab("Home", "home"),
    Main = Window:AddTab("Main", "swords"),
    Visuals = Window:AddTab("Visuals", "eye"),
    Utilities = Window:AddTab("Utilities", "wrench"),
    World = Window:AddTab("World", "globe-2"),
    Settings = Window:AddTab("Settings", "settings"),
}

local homeLeft = Tabs.Home:AddLeftGroupbox("Welcome")
homeLeft:AddLabel("yo " .. me.DisplayName .. "!", true)
homeLeft:AddLabel("hope u enjoy uwu", true)
homeLeft:AddDivider()
homeLeft:AddButton({
    Text = "Copy Discord",
    Func = function()
        setclipboard("https://discord.gg/nbPHzKzafN")
        Library:Notify({Title = "Invictus", Description = "copied!", Time = 2})
    end,
})

local homeRight = Tabs.Home:AddRightGroupbox("Credits")
homeRight:AddLabel("made by Entropy", true)
homeRight:AddLabel("discord: 4entropy3", true)

local mainLeft = Tabs.Main:AddLeftGroupbox("Auto Parry")

mainLeft:AddToggle("autoParry", {
    Text = "Auto Parry",
    Default = true,
})

Toggles.autoParry:OnChanged(function()
    cfg.autoParry = Toggles.autoParry.Value
end)

mainLeft:AddSlider("distance", {
    Text = "Distance To Hit",
    Default = 10,
    Min = 5,
    Max = 25,
    Rounding = 1,
})

Options.distance:OnChanged(function()
    cfg.distanceHit = Options.distance.Value
end)

mainLeft:AddSlider("offset", {
    Text = "Offset",
    Default = 0,
    Min = 0,
    Max = 15,
    Rounding = 1,
})

Options.offset:OnChanged(function()
    cfg.offset = Options.offset.Value
end)

local mainRight = Tabs.Main:AddRightGroupbox("Other")

mainRight:AddToggle("lookAt", {
    Text = "Look At Ball",
    Default = false,
})

Toggles.lookAt:OnChanged(function()
    cfg.lookAt = Toggles.lookAt.Value
end)

mainRight:AddDropdown("lookType", {
    Values = {"Camera", "Character"},
    Default = "Camera",
    Text = "Look Type",
})

Options.lookType:OnChanged(function()
    cfg.lookType = Options.lookType.Value
end)

local visLeft = Tabs.Visuals:AddLeftGroupbox("Ball Visualizers")

visLeft:AddToggle("visBall", {
    Text = "Distance To Hit",
    Default = true,
})

Toggles.visBall:OnChanged(function()
    visuals.ball = Toggles.visBall.Value
end)

visLeft:AddToggle("visClash", {
    Text = "Clash Range",
    Default = true,
})

Toggles.visClash:OnChanged(function()
    visuals.clash = Toggles.visClash.Value
end)

visLeft:AddToggle("visDist", {
    Text = "Ball Distance",
    Default = true,
})

Toggles.visDist:OnChanged(function()
    visuals.distance = Toggles.visDist.Value
end)

local visRight = Tabs.Visuals:AddRightGroupbox("Circle Visualizers")

visRight:AddToggle("circBall", {
    Text = "Distance To Hit",
    Default = true,
})

Toggles.circBall:OnChanged(function()
    visuals.circleBall = Toggles.circBall.Value
end)

visRight:AddToggle("circClash", {
    Text = "Clash Range",
    Default = true,
})

Toggles.circClash:OnChanged(function()
    visuals.circleClash = Toggles.circClash.Value
end)

visRight:AddToggle("circDist", {
    Text = "Ball Distance",
    Default = true,
})

Toggles.circDist:OnChanged(function()
    visuals.circleDistance = Toggles.circDist.Value
end)

local visSettings = Tabs.Visuals:AddLeftGroupbox("Settings")

visSettings:AddDropdown("shape", {
    Values = {"Ball", "Block", "Cylinder", "Wedge", "CornerWedge"},
    Default = "Ball",
    Text = "Shape",
})

Options.shape:OnChanged(function()
    visualCfg.shape = Options.shape.Value
end)

visSettings:AddDropdown("material", {
    Values = {"Plastic", "ForceField", "Glass", "Neon", "SmoothPlastic", "Metal"},
    Default = "ForceField",
    Text = "Material",
})

Options.material:OnChanged(function()
    visualCfg.material = Options.material.Value
end)

visSettings:AddLabel("Ball Color"):AddColorPicker("ballColor", {
    Default = Color3.fromRGB(255, 255, 255),
})

Options.ballColor:OnChanged(function()
    visualCfg.color = Options.ballColor.Value
end)

visSettings:AddLabel("Circle Color"):AddColorPicker("circColor", {
    Default = Color3.fromRGB(255, 255, 255),
})

Options.circColor:OnChanged(function()
    visualCfg.circleColor = Options.circColor.Value
end)

visSettings:AddSlider("transp", {
    Text = "Transparency",
    Default = 0,
    Min = 0,
    Max = 1,
    Rounding = 1,
})

Options.transp:OnChanged(function()
    visualCfg.transparency = Options.transp.Value
end)

visSettings:AddSlider("circHeight", {
    Text = "Circle Height",
    Default = 0.5,
    Min = 0.5,
    Max = 5,
    Rounding = 1,
})

Options.circHeight:OnChanged(function()
    visualCfg.circleHeight = Options.circHeight.Value
end)

visSettings:AddSlider("clashRange", {
    Text = "Clash Range Size",
    Default = 30,
    Min = 10,
    Max = 100,
    Rounding = 1,
})

Options.clashRange:OnChanged(function()
    visualCfg.clashDist = Options.clashRange.Value
end)

local visRainbow = Tabs.Visuals:AddRightGroupbox("Rainbow")

visRainbow:AddToggle("rainbowBall", {
    Text = "Rainbow Ball",
    Default = false,
})

Toggles.rainbowBall:OnChanged(function()
    cfg.rainbow = Toggles.rainbowBall.Value
end)

visRainbow:AddToggle("rainbowCirc", {
    Text = "Rainbow Circle",
    Default = false,
})

Toggles.rainbowCirc:OnChanged(function()
    cfg.circleRainbow = Toggles.rainbowCirc.Value
end)

local utilLeft = Tabs.Utilities:AddLeftGroupbox("Utilities")

utilLeft:AddToggle("noSlash", {
    Text = "Anti Slash Effect",
    Default = false,
})

Toggles.noSlash:OnChanged(function()
    utils.noSlash = Toggles.noSlash.Value
end)

local utilRight = Tabs.Utilities:AddRightGroupbox("Auto Stuff")

utilRight:AddToggle("autoClaim", {
    Text = "Auto Claim Rewards",
    Default = false,
})

Toggles.autoClaim:OnChanged(function()
    utils.autoClaim = Toggles.autoClaim.Value
end)

utilRight:AddToggle("autoExp", {
    Text = "Auto Explosion Crate",
    Default = false,
})

Toggles.autoExp:OnChanged(function()
    utils.autoExplosion = Toggles.autoExp.Value
end)

utilRight:AddToggle("autoSword", {
    Text = "Auto Sword Crate",
    Default = false,
})

Toggles.autoSword:OnChanged(function()
    utils.autoSword = Toggles.autoSword.Value
end)

local worldLeft = Tabs.World:AddLeftGroupbox("World")

worldLeft:AddButton({
    Text = "Reset World",
    Func = function()
        lighting.Ambient = origAmbient
        lighting.FogColor = origFog
        lighting.ClockTime = origTime
        Library:Notify({Title = "Invictus", Description = "reset!", Time = 2})
    end,
})

worldLeft:AddLabel("Ambient"):AddColorPicker("ambient", {
    Default = lighting.Ambient,
})

Options.ambient:OnChanged(function()
    lighting.Ambient = Options.ambient.Value
end)

worldLeft:AddLabel("Fog"):AddColorPicker("fog", {
    Default = lighting.FogColor,
})

Options.fog:OnChanged(function()
    lighting.FogColor = Options.fog.Value
end)

worldLeft:AddSlider("timeOfDay", {
    Text = "Time",
    Default = lighting.ClockTime,
    Min = 0,
    Max = 24,
    Rounding = 1,
})

Options.timeOfDay:OnChanged(function()
    lighting.ClockTime = Options.timeOfDay.Value
end)

local worldRight = Tabs.World:AddRightGroupbox("Rainbow World")

worldRight:AddToggle("rainbowAmb", {
    Text = "Rainbow Ambient",
    Default = false,
})

Toggles.rainbowAmb:OnChanged(function()
    cfg.rainbowAmbient = Toggles.rainbowAmb.Value
end)

worldRight:AddToggle("rainbowFog", {
    Text = "Rainbow Fog",
    Default = false,
})

Toggles.rainbowFog:OnChanged(function()
    cfg.rainbowFog = Toggles.rainbowFog.Value
end)

local menuGroup = Tabs.Settings:AddLeftGroupbox("Menu")

menuGroup:AddToggle("keybindMenu", {
    Default = false,
    Text = "Show Keybinds",
})

Toggles.keybindMenu:OnChanged(function()
    Library.KeybindFrame.Visible = Toggles.keybindMenu.Value
end)

menuGroup:AddLabel("Menu Key"):AddKeyPicker("menuKey", {
    Default = "RightShift",
    NoUI = true,
})

menuGroup:AddButton({
    Text = "Unload",
    Func = function()
        Library:Unload()
    end,
})

Library.ToggleKeybind = Options.menuKey

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"menuKey"})
ThemeManager:SetFolder("Invictus")
SaveManager:SetFolder("Invictus/BladeBall")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

local visPart1 = Instance.new("Part")
local visPart2 = Instance.new("Part")
local visPart3 = Instance.new("Part")
local circAdornee = Instance.new("Part", workspace.CurrentCamera)
local circ1 = Instance.new("CylinderHandleAdornment", game.CoreGui)
local circ2 = Instance.new("CylinderHandleAdornment", game.CoreGui)
local circ3 = Instance.new("CylinderHandleAdornment", game.CoreGui)

visPart1.CanCollide = false
visPart2.CanCollide = false
visPart3.CanCollide = false
visPart1.Anchored = false
visPart2.Anchored = false
visPart3.Anchored = false
visPart1.Parent = nil
visPart2.Parent = nil
visPart3.Parent = nil

circAdornee.Transparency = 1
circAdornee.CanCollide = false
circAdornee.Anchored = false
circAdornee.Size = Vector3.new(1, 1, 1)

circ1.Visible = false
circ2.Visible = false
circ3.Visible = false

local function getBall()
    for _, b in ipairs(balls:GetChildren()) do
        if b:GetAttribute("realBall") then
            return b
        end
    end
    return nil
end

local function getSpeed(ball)
    if ball then
        local zoomies = ball:FindFirstChild("zoomies")
        if zoomies then
            return zoomies.VectorVelocity.Magnitude
        end
        return ball.AssemblyLinearVelocity.Magnitude
    end
    return 0
end

local function parry()
    vim:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

local function getHrp()
    if me.Character then
        return me.Character:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

local function claimRewards()
    for i = 1, 6 do
        pcall(function()
            repStorage.Packages._Index["sleitnick_net@0.1.0"].net["RF/ClaimPlaytimeReward"]:InvokeServer(i)
        end)
    end
end

local function openExpCrate()
    pcall(function()
        repStorage.Remote.RemoteFunction:InvokeServer("PromptPurchaseCrate", workspace.Spawn.Crates.NormalExplosionCrate)
    end)
end

local function openSwordCrate()
    pcall(function()
        repStorage.Remote.RemoteFunction:InvokeServer("PromptPurchaseCrate", workspace.Spawn.Crates.NormalSwordCrate)
    end)
end

local function removeSlash(desc)
    if not utils.noSlash then return end
    if string.find(string.lower(desc.ClassName), "particleemitter") then
        pcall(function()
            desc.Lifetime = NumberRange.new(0)
        end)
    end
end

workspace.DescendantAdded:Connect(removeSlash)

local function resetConn()
    if ballConn then
        ballConn:Disconnect()
        ballConn = nil
    end
end

balls.ChildAdded:Connect(function()
    local ball = getBall()
    if not ball then return end
    resetConn()
    parried = false
    ballConn = ball:GetAttributeChangedSignal("target"):Connect(function()
        parried = false
    end)
end)

runService.PreSimulation:Connect(function()
    if not cfg.autoParry then return end
    
    local ball = getBall()
    local hrp = getHrp()
    if not ball or not hrp then return end
    
    local speed = getSpeed(ball)
    if speed == 0 then return end
    
    local dist = (hrp.Position - ball.Position).Magnitude
    local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() / 10
    local pingThreshold = math.clamp(ping / 10, 5, 17)
    
    local cappedSpeed = math.min(math.max(speed - 9.5, 0), 650)
    local divisor = 2.4 + cappedSpeed * 0.002
    local accuracy = pingThreshold + math.max(speed / divisor, 9.5) - cfg.offset
    
    local isTarget = ball:GetAttribute("target") == tostring(me)
    
    if isTarget and dist <= accuracy and not parried then
        parried = true
        parry()
    end
end)

runService.PreRender:Connect(function()
    if not cfg.lookAt then return end
    
    local ball = getBall()
    if not ball then return end
    
    local hrp = getHrp()
    local cam = workspace.CurrentCamera
    
    if cfg.lookType == "Character" and hrp then
        local lookPos = Vector3.new(ball.Position.X, hrp.Position.Y, ball.Position.Z)
        hrp.CFrame = CFrame.lookAt(hrp.Position, lookPos)
    elseif cfg.lookType == "Camera" then
        cam.CFrame = CFrame.lookAt(cam.CFrame.Position, ball.Position)
    end
end)

runService.PostSimulation:Connect(function()
    if cfg.rainbowAmbient then
        lighting.Ambient = Color3.fromHSV(tick() % 5 / 5, 1, 1)
    end
    if cfg.rainbowFog then
        lighting.FogColor = Color3.fromHSV(tick() % 5 / 5, 1, 1)
    end
end)

runService.PostSimulation:Connect(function()
    if utils.autoClaim then claimRewards() end
    if utils.autoSword then openSwordCrate() end
    if utils.autoExplosion then openExpCrate() end
end)

runService.PostSimulation:Connect(function()
    local ball = getBall()
    local hrp = getHrp()
    
    if not ball or not hrp then
        visPart1.Parent = nil
        visPart2.Parent = nil
        visPart3.Parent = nil
        circ1.Visible = false
        circ2.Visible = false
        circ3.Visible = false
        return
    end
    
    if not cfg.autoParry then return end
    
    local hipHeight = me.Character.Humanoid.HipHeight + visualCfg.circleHeight
    local ballDist = (ball.Position - workspace.CurrentCamera.Focus.Position).Magnitude
    local rainbowColor = Color3.fromHSV(tick() % 5 / 5, 1, 1)
    
    if visuals.ball then
        visPart1.Shape = visualCfg.shape
        visPart1.Material = visualCfg.material
        visPart1.Transparency = visualCfg.transparency
        visPart1.Size = Vector3.new(cfg.distanceHit, cfg.distanceHit, cfg.distanceHit)
        visPart1.Color = cfg.rainbow and rainbowColor or visualCfg.color
        visPart1.CFrame = hrp.CFrame
        visPart1.Parent = hrp
    else
        visPart1.Parent = nil
    end
    
    if visuals.clash then
        visPart2.Shape = visualCfg.shape
        visPart2.Material = visualCfg.material
        visPart2.Transparency = visualCfg.transparency
        visPart2.Size = Vector3.new(visualCfg.clashDist, visualCfg.clashDist, visualCfg.clashDist)
        visPart2.Color = cfg.rainbow and rainbowColor or visualCfg.color
        visPart2.CFrame = hrp.CFrame
        visPart2.Parent = workspace
    else
        visPart2.Parent = nil
    end
    
    if visuals.distance then
        visPart3.Shape = visualCfg.shape
        visPart3.Material = visualCfg.material
        visPart3.Transparency = visualCfg.transparency
        visPart3.Size = Vector3.new(ballDist, ballDist, ballDist)
        visPart3.Color = cfg.rainbow and rainbowColor or visualCfg.color
        visPart3.CFrame = hrp.CFrame
        visPart3.Parent = hrp
    else
        visPart3.Parent = nil
    end
    
    if visuals.circleBall or visuals.circleClash or visuals.circleDistance then
        circAdornee.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y - hipHeight, hrp.Position.Z)
    end
    
    local circColor = cfg.circleRainbow and rainbowColor or visualCfg.circleColor
    
    if visuals.circleBall then
        circ1.CFrame = CFrame.fromOrientation(math.rad(90), 0, 0)
        circ1.Adornee = circAdornee
        circ1.Radius = cfg.distanceHit
        circ1.InnerRadius = cfg.distanceHit
        circ1.Height = hipHeight
        circ1.Color3 = circColor
        circ1.Visible = true
    else
        circ1.Visible = false
    end
    
    if visuals.circleClash then
        circ2.CFrame = CFrame.fromOrientation(math.rad(90), 0, 0)
        circ2.Adornee = circAdornee
        circ2.Radius = visualCfg.clashDist
        circ2.InnerRadius = visualCfg.clashDist
        circ2.Height = hipHeight
        circ2.Color3 = circColor
        circ2.Visible = true
    else
        circ2.Visible = false
    end
    
    if visuals.circleDistance then
        circ3.CFrame = CFrame.fromOrientation(math.rad(90), 0, 0)
        circ3.Adornee = circAdornee
        circ3.Radius = ballDist
        circ3.InnerRadius = ballDist
        circ3.Height = hipHeight
        circ3.Color3 = circColor
        circ3.Visible = true
    else
        circ3.Visible = false
    end
end)

Library:OnUnload(function()
    resetConn()
    visPart1:Destroy()
    visPart2:Destroy()
    visPart3:Destroy()
    circAdornee:Destroy()
    circ1:Destroy()
    circ2:Destroy()
    circ3:Destroy()
end)

Library:Notify({
    Title = "Invictus",
    Description = "loaded! have fun :3",
    Time = 3,
})

Window:SelectTab(1)
