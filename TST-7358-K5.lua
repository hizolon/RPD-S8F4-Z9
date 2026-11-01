local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local MaterialService = game:GetService("MaterialService")
local Player = Players.LocalPlayer

local CONFIG = {
    BEHIND_STUDS = 3,
    HEIGHT_OFFSET = 0,
    AUTO_RESET = false,
    RESET_THRESHOLD = 0.30,
    SAFE_DEPTH = 80,
    SAFE_HEIGHT = 130,
    PING_COMPENSATE = true,
    PREDICTION_MULT = 1.0,
    PING_SAFETY = 1.3,
    MAX_LEAD_TIME = 0.12,
    FPS_BOOST = false,
    ESP = false,
    SAFE_ZONE = false,
}

if not _G.Ignore then
    _G.Ignore = {}
end
_G.SendNotifications = false
_G.ConsoleLogs = false
_G.LoadedWait = 1

if not _G.Settings then
    _G.Settings = {
        Players = {
            ["Ignore Me"] = true,
            ["Ignore Others"] = true,
            ["Ignore Tools"] = true,
        },
        Meshes = { NoMesh = false, NoTexture = false, Destroy = false },
        Images = { Invisible = true, Destroy = false },
        Explosions = { Smaller = true, Invisible = false, Destroy = false },
        Particles = { Invisible = true, Destroy = false },
        TextLabels = { LowerQuality = false, Invisible = false, Destroy = false },
        MeshParts = { LowerQuality = true, Invisible = false, NoTexture = false, NoMesh = false, Destroy = false },
        Other = {
            ["FPS Cap"] = true,
            ["No Camera Effects"] = true,
            ["No Clothes"] = true,
            ["Low Water Graphics"] = true,
            ["No Shadows"] = true,
            ["Low Rendering"] = true,
            ["Low Quality Parts"] = true,
            ["Low Quality Models"] = true,
            ["Reset Materials"] = true,
            ["Lower Quality MeshParts"] = true,
            ClearNilInstances = false,
        },
    }
end

local ME = Players.LocalPlayer
local CanBeEnabled = { "ParticleEmitter", "Trail", "Smoke", "Fire", "Sparkles" }

local function PartOfCharacter(Inst)
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= ME and v.Character and Inst:IsDescendantOf(v.Character) then
            return true
        end
    end
    return false
end

local function DescendantOfIgnore(Inst)
    for _, v in pairs(_G.Ignore) do
        if typeof(v) == "Instance" and Inst:IsDescendantOf(v) then
            return true
        end
    end
    return false
end

local function CheckIfBad(Inst)
    if not Inst or not Inst.Parent then return end
    if not Inst:IsDescendantOf(Players) and (_G.Settings.Players["Ignore Others"] and not PartOfCharacter(Inst)
    or not _G.Settings.Players["Ignore Others"]) and (_G.Settings.Players["Ignore Me"] and ME.Character and not Inst:IsDescendantOf(ME.Character)
    or not _G.Settings.Players["Ignore Me"]) and (_G.Settings.Players["Ignore Tools"] and not Inst:IsA("BackpackItem") and not Inst:FindFirstAncestorWhichIsA("BackpackItem")
    or not _G.Settings.Players["Ignore Tools"]) and (_G.Ignore and not table.find(_G.Ignore, Inst) and not DescendantOfIgnore(Inst)
    or (not _G.Ignore or type(_G.Ignore) ~= "table" or #_G.Ignore <= 0)) then
        if Inst:IsA("DataModelMesh") then
            if Inst:IsA("SpecialMesh") then
                if _G.Settings.Meshes.NoMesh then Inst.MeshId = "" end
                if _G.Settings.Meshes.NoTexture then Inst.TextureId = "" end
            end
            if _G.Settings.Meshes.Destroy or _G.Settings["No Meshes"] then Inst:Destroy() end
        elseif Inst:IsA("FaceInstance") then
            if _G.Settings.Images.Invisible then
                Inst.Transparency = 1
                Inst.Shiny = 1
            end
            if _G.Settings.Images.LowDetail then Inst.Shiny = 1 end
            if _G.Settings.Images.Destroy then Inst:Destroy() end
        elseif Inst:IsA("ShirtGraphic") then
            if _G.Settings.Images.Invisible then Inst.Graphic = "" end
            if _G.Settings.Images.Destroy then Inst:Destroy() end
        elseif table.find(CanBeEnabled, Inst.ClassName) then
            if _G.Settings["Invisible Particles"] or _G.Settings["No Particles"] or (_G.Settings.Other and _G.Settings.Other["Invisible Particles"]) or (_G.Settings.Particles and _G.Settings.Particles.Invisible) then
                Inst.Enabled = false
            end
            if (_G.Settings.Other and _G.Settings.Other["No Particles"]) or (_G.Settings.Particles and _G.Settings.Particles.Destroy) then
                Inst:Destroy()
            end
        elseif Inst:IsA("PostEffect") and (_G.Settings["No Camera Effects"] or (_G.Settings.Other and _G.Settings.Other["No Camera Effects"])) then
            Inst.Enabled = false
        elseif Inst:IsA("Explosion") then
            if _G.Settings["Smaller Explosions"] or (_G.Settings.Other and _G.Settings.Other["Smaller Explosions"]) or (_G.Settings.Explosions and _G.Settings.Explosions.Smaller) then
                Inst.BlastPressure = 1
                Inst.BlastRadius = 1
            end
            if _G.Settings["Invisible Explosions"] or (_G.Settings.Other and _G.Settings.Other["Invisible Explosions"]) or (_G.Settings.Explosions and _G.Settings.Explosions.Invisible) then
                Inst.BlastPressure = 1
                Inst.BlastRadius = 1
                Inst.Visible = false
            end
            if _G.Settings["No Explosions"] or (_G.Settings.Other and _G.Settings.Other["No Explosions"]) or (_G.Settings.Explosions and _G.Settings.Explosions.Destroy) then
                Inst:Destroy()
            end
        elseif Inst:IsA("Clothing") or Inst:IsA("SurfaceAppearance") or Inst:IsA("BaseWrap") then
            if _G.Settings["No Clothes"] or (_G.Settings.Other and _G.Settings.Other["No Clothes"]) then
                Inst:Destroy()
            end
        elseif Inst:IsA("BasePart") and not Inst:IsA("MeshPart") then
            if _G.Settings["Low Quality Parts"] or (_G.Settings.Other and _G.Settings.Other["Low Quality Parts"]) then
                Inst.Material = Enum.Material.Plastic
                Inst.Reflectance = 0
            end
        elseif Inst:IsA("TextLabel") and Inst:IsDescendantOf(workspace) then
            if _G.Settings["Lower Quality TextLabels"] or (_G.Settings.Other and _G.Settings.Other["Lower Quality TextLabels"]) or (_G.Settings.TextLabels and _G.Settings.TextLabels.LowerQuality) then
                Inst.Font = Enum.Font.SourceSans
                Inst.TextScaled = false
                Inst.RichText = false
                Inst.TextSize = 14
            end
            if _G.Settings["Invisible TextLabels"] or (_G.Settings.Other and _G.Settings.Other["Invisible TextLabels"]) or (_G.Settings.TextLabels and _G.Settings.TextLabels.Invisible) then
                Inst.Visible = false
            end
            if _G.Settings["No TextLabels"] or (_G.Settings.Other and _G.Settings.Other["No TextLabels"]) or (_G.Settings.TextLabels and _G.Settings.TextLabels.Destroy) then
                Inst:Destroy()
            end
        elseif Inst:IsA("Model") then
            if _G.Settings["Low Quality Models"] or (_G.Settings.Other and _G.Settings.Other["Low Quality Models"]) then
                Inst.LevelOfDetail = 1
            end
        elseif Inst:IsA("MeshPart") then
            if _G.Settings["Low Quality MeshParts"] or (_G.Settings.Other and _G.Settings.Other["Low Quality MeshParts"]) or (_G.Settings.MeshParts and _G.Settings.MeshParts.LowerQuality) then
                Inst.RenderFidelity = 2
                Inst.Reflectance = 0
                Inst.Material = Enum.Material.Plastic
            end
            if _G.Settings["Invisible MeshParts"] or (_G.Settings.Other and _G.Settings.Other["Invisible MeshParts"]) or (_G.Settings.MeshParts and _G.Settings.MeshParts.Invisible) then
                Inst.Transparency = 1
                Inst.RenderFidelity = 2
                Inst.Reflectance = 0
                Inst.Material = Enum.Material.Plastic
            end
            if _G.Settings.MeshParts and _G.Settings.MeshParts.NoTexture then Inst.TextureID = "" end
            if _G.Settings.MeshParts and _G.Settings.MeshParts.NoMesh then Inst.MeshId = "" end
            if _G.Settings["No MeshParts"] or (_G.Settings.Other and _G.Settings.Other["No MeshParts"]) or (_G.Settings.MeshParts and _G.Settings.MeshParts.Destroy) then
                Inst:Destroy()
            end
        end
    end
end

local function applyLowWaterGraphics()
    if (_G.Settings["Low Water Graphics"] or (_G.Settings.Other and _G.Settings.Other["Low Water Graphics"])) then
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if not terrain then
            repeat task.wait() until workspace:FindFirstChildOfClass("Terrain")
            terrain = workspace:FindFirstChildOfClass("Terrain")
        end
        terrain.WaterWaveSize = 0
        terrain.WaterWaveSpeed = 0
        terrain.WaterReflectance = 0
        terrain.WaterTransparency = 0
        if sethiddenproperty then
            sethiddenproperty(terrain, "Decoration", false)
        end
    end
end

local function applyNoShadows()
    if _G.Settings["No Shadows"] or (_G.Settings.Other and _G.Settings.Other["No Shadows"]) then
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.ShadowSoftness = 0
        if sethiddenproperty then
            sethiddenproperty(Lighting, "Technology", 2)
        end
    end
end

local function applyLowRendering()
    if _G.Settings["Low Rendering"] or (_G.Settings.Other and _G.Settings.Other["Low Rendering"]) then
        settings().Rendering.QualityLevel = 1
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
    end
end

local function applyResetMaterials()
    if _G.Settings["Reset Materials"] or (_G.Settings.Other and _G.Settings.Other["Reset Materials"]) then
        for _, v in pairs(MaterialService:GetChildren()) do v:Destroy() end
        MaterialService.Use2022Materials = false
    end
end

local function applyFpsCap()
    if _G.Settings["FPS Cap"] or (_G.Settings.Other and _G.Settings.Other["FPS Cap"]) then
        if setfpscap then
            local v = _G.Settings["FPS Cap"] or (_G.Settings.Other and _G.Settings.Other["FPS Cap"])
            if type(v) == "string" or type(v) == "number" then
                setfpscap(tonumber(v))
            elseif v == true then
                setfpscap(1e6)
            end
        end
    end
end

local function applyClearNilInstances()
    if _G.Settings.Other["ClearNilInstances"] then
        if getnilinstances then
            for _, v in pairs(getnilinstances()) do
                pcall(v.Destroy, v)
            end
        end
    end
end

local FpsBoostRunning = false
local FpsAddedConnection = nil

local function startFpsBoost()
    if FpsBoostRunning then return end
    FpsBoostRunning = true
    coroutine.wrap(pcall)(applyLowWaterGraphics)
    coroutine.wrap(pcall)(applyNoShadows)
    coroutine.wrap(pcall)(applyLowRendering)
    coroutine.wrap(pcall)(applyResetMaterials)
    coroutine.wrap(pcall)(applyFpsCap)
    coroutine.wrap(pcall)(applyClearNilInstances)
    local Descendants = game:GetDescendants()
    for _, v in pairs(Descendants) do
        CheckIfBad(v)
    end
    FpsAddedConnection = game.DescendantAdded:Connect(function(value)
        wait(_G.LoadedWait or 1)
        CheckIfBad(value)
    end)
end

local function stopFpsBoost()
    if not FpsBoostRunning then return end
    FpsBoostRunning = false
    if FpsAddedConnection then FpsAddedConnection:Disconnect(); FpsAddedConnection = nil end
end

local function getGuiParent()
    local ok, parent = pcall(function() return CoreGui end)
    if ok and parent then return parent end
    return Player:WaitForChild("PlayerGui")
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ID:5620429005"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = getGuiParent()

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 210, 0, 286)
MainFrame.Position = UDim2.new(0.5, -105, 0.5, -143)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainFrameStroke = Instance.new("UIStroke")
MainFrameStroke.Color = Color3.fromRGB(255, 0, 0)
MainFrameStroke.Thickness = 1.2
MainFrameStroke.Parent = MainFrame

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 21)
TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleBarCorner = Instance.new("UICorner")
TitleBarCorner.CornerRadius = UDim.new(0, 4)
TitleBarCorner.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -26, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "ID:5620429005 | by: Flarnux | Gm: TSB"
Title.TextColor3 = Color3.fromRGB(255, 0, 0)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 11
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Position = UDim2.new(0, 7, 0, 0)
Title.Parent = TitleBar

local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Name = "Minimize"
MinimizeButton.Position = UDim2.new(1, -21, 0, 0)
MinimizeButton.Size = UDim2.fromOffset(21, 21)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
MinimizeButton.BorderSizePixel = 0
MinimizeButton.Text = "-"
MinimizeButton.TextColor3 = Color3.new(1, 1, 1)
MinimizeButton.Font = Enum.Font.SourceSansBold
MinimizeButton.TextSize = 15
MinimizeButton.Parent = TitleBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 4)
MinCorner.Parent = MinimizeButton

local minimized = false
MinimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    MainFrame.Size = UDim2.fromOffset(210, minimized and 21 or 286)
    MinimizeButton.Text = minimized and "+" or "-"
    for _, child in ipairs(MainFrame:GetChildren()) do
        if child:IsA("GuiObject") and child ~= TitleBar and child.Name ~= "LockOverlay" then
            child.Visible = not minimized
        end
    end
end)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Position = UDim2.new(0, 7, 0, 28)
StatusLabel.Size = UDim2.new(1, -14, 0, 18)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Select target to backstab"
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = MainFrame

local SelectionFrame = Instance.new("Frame")
SelectionFrame.Position = UDim2.new(0, 7, 0, 49)
SelectionFrame.Size = UDim2.new(1, -14, 0, 140)
SelectionFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
SelectionFrame.BorderSizePixel = 0
SelectionFrame.Parent = MainFrame

local SelectionCorner = Instance.new("UICorner")
SelectionCorner.CornerRadius = UDim.new(0, 4)
SelectionCorner.Parent = SelectionFrame

local PlayerScrollFrame = Instance.new("ScrollingFrame")
PlayerScrollFrame.Position = UDim2.new(0, 4, 0, 4)
PlayerScrollFrame.Size = UDim2.new(1, -8, 1, -8)
PlayerScrollFrame.BackgroundTransparency = 1
PlayerScrollFrame.BorderSizePixel = 0
PlayerScrollFrame.ScrollBarThickness = 4
PlayerScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 80, 80)
PlayerScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerScrollFrame.Parent = SelectionFrame

local StartButton = Instance.new("TextButton")
StartButton.Position = UDim2.new(0, 7, 0, 196)
StartButton.Size = UDim2.new(0.5, -10, 0, 28)
StartButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
StartButton.BorderSizePixel = 0
StartButton.Text = "START"
StartButton.TextColor3 = Color3.fromRGB(255, 255, 255)
StartButton.Font = Enum.Font.SourceSansBold
StartButton.TextSize = 12
StartButton.Parent = MainFrame

local StartCorner = Instance.new("UICorner")
StartCorner.CornerRadius = UDim.new(0, 4)
StartCorner.Parent = StartButton

local StopButton = Instance.new("TextButton")
StopButton.Position = UDim2.new(0.5, 3, 0, 196)
StopButton.Size = UDim2.new(0.5, -10, 0, 28)
StopButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
StopButton.BorderSizePixel = 0
StopButton.Text = "STOP"
StopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
StopButton.Font = Enum.Font.SourceSansBold
StopButton.TextSize = 12
StopButton.Parent = MainFrame

local StopCorner = Instance.new("UICorner")
StopCorner.CornerRadius = UDim.new(0, 4)
StopCorner.Parent = StopButton

local function makeToggle(name, x, width)
    local button = Instance.new("TextButton")
    button.Name = name:gsub(" ", "")
    button.Position = UDim2.new(0, x, 0, 231)
    button.Size = UDim2.new(0, width, 0, 21)
    button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    button.BorderSizePixel = 0
    button.TextColor3 = Color3.fromRGB(255, 80, 80)
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 10
    button.Parent = MainFrame
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = button
    return button
end

local SafeToggle = makeToggle("SAVE ZONA", 7, 94)
local ResetToggle = makeToggle("AUTO RESET", 108, 95)
local FpsBoostToggle = makeToggle("FPS BOOST", 7, 94)
FpsBoostToggle.Position = UDim2.new(0, 7, 0, 258)
local EspToggle = makeToggle("ESP", 108, 95)
EspToggle.Position = UDim2.new(0, 108, 0, 258)

local function paintToggle(button, title, enabled)
    button.Text = title .. (enabled and ": ON" or ": OFF")
    button.TextColor3 = enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 80, 80)
end

paintToggle(SafeToggle, "SAVE ZONA", CONFIG.SAFE_ZONE)
paintToggle(ResetToggle, "AUTO RESET", CONFIG.AUTO_RESET)
paintToggle(FpsBoostToggle, "FPS BOOST", CONFIG.FPS_BOOST)
paintToggle(EspToggle, "ESP", CONFIG.ESP)

local SelectedTarget = nil
local PlayerButtons = {}
local BackstabActive = false
local PositionConnection = nil
local HealthConnection = nil
local DeathConnection = nil
local SafePlatform = nil
local PreviousAutoRotate = nil
local CharacterConnection = nil
local CleanupConnections = {}
local ResetInProgress = false

local EspGui = nil
local EspConnection = nil
local EspEntries = {}

local Unlocked = false
local LockOverlay = nil
local KeyInput = nil
local KeyStatus = nil
local UnlockButton = nil

local StatsGuiRunning = false
local StatsScreenGui = nil

local SafePlatformY = -1000
local SafePlatformSize = Vector3.new(1000, 2, 1000)
local SafePos = Vector3.new(0, SafePlatformY + 5, 0)
local SafeActive = false
local SafeConnections = {}
local SafeSavedCFrame = nil

local function getPing()
    local ok, ping = pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    return ok and ping or 50
end
local function isAlive(plr)
    if not plr or not plr.Character then return false end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end
local function getHRP(plr)
    if not plr or not plr.Character then return nil end
    return plr.Character:FindFirstChild("HumanoidRootPart")
end

local function enableSafeZone()
    if SafeActive then return end
    SafeActive = true

    local char = Player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        SafeSavedCFrame = char.HumanoidRootPart.CFrame
    end

    if SafePlatform then SafePlatform:Destroy() end
    SafePlatform = Instance.new("Part")
    SafePlatform.Name = "AntiFallPlatform"
    SafePlatform.Size = SafePlatformSize
    SafePlatform.Position = Vector3.new(0, SafePlatformY, 0)
    SafePlatform.Anchored = true
    SafePlatform.CanCollide = true
    SafePlatform.Transparency = 0.5
    SafePlatform.Material = Enum.Material.SmoothPlastic
    SafePlatform.Color = Color3.fromRGB(0, 255, 255)
    SafePlatform.Parent = workspace

    local c1 = RunService.Heartbeat:Connect(function()
        workspace.FallenPartsDestroyHeight = -math.huge
    end)
    table.insert(SafeConnections, c1)

    local function hookChar(c)
        local hum = c:WaitForChild("Humanoid")
        local c2 = hum.HealthChanged:Connect(function(h)
            if h <= 0 and SafeActive then
                hum.Health = hum.MaxHealth
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end
        end)
        table.insert(SafeConnections, c2)
    end
    if Player.Character then hookChar(Player.Character) end
    local c3 = Player.CharacterAdded:Connect(hookChar)
    table.insert(SafeConnections, c3)

    task.spawn(function()
        task.wait(0.1)
        local c = Player.Character
        if c and c:FindFirstChild("HumanoidRootPart") then
            c.HumanoidRootPart.CFrame = CFrame.new(SafePos)
        end
    end)

    local c4 = RunService.Heartbeat:Connect(function()
        local c = Player.Character
        if c and c:FindFirstChild("HumanoidRootPart") then
            local hrp = c.HumanoidRootPart
            if hrp.Position.Y < SafePlatformY - 10 then
                hrp.CFrame = CFrame.new(SafePos)
            end
        end
    end)
    table.insert(SafeConnections, c4)
end

local function disableSafeZone()
    if not SafeActive then return end
    SafeActive = false

    if SafePlatform then SafePlatform:Destroy() end
    SafePlatform = nil

    for _, c in ipairs(SafeConnections) do
        if c then c:Disconnect() end
    end
    SafeConnections = {}

    workspace.FallenPartsDestroyHeight = -50

    local char = Player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        if SafeSavedCFrame then
            char.HumanoidRootPart.CFrame = SafeSavedCFrame
        else
            char.HumanoidRootPart.CFrame = CFrame.new(0, 10, 0)
        end
    end
    SafeSavedCFrame = nil
end

local function emergencyRetreat()
    if ResetInProgress then return end
    local char = Player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp or hum.Health <= 0 then return end
    ResetInProgress = true
    local y = -CONFIG.SAFE_DEPTH
    pcall(function()
        y = math.min(y, workspace.FallenPartsDestroyHeight - 15)
    end)
    hrp.CFrame = CFrame.new(hrp.Position.X, y, hrp.Position.Z)
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    StatusLabel.Text = "AUTO RESET: LOW HP"
    StatusLabel.TextColor3 = Color3.fromRGB(255, 180, 40)
    hum.Health = 0
end

local function monitorHealth(character)
    if HealthConnection then HealthConnection:Disconnect(); HealthConnection = nil end
    if DeathConnection then DeathConnection:Disconnect(); DeathConnection = nil end
    ResetInProgress = false
    local hum = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 10)
    if not hum then return end
    local function checkHealth(health)
        if CONFIG.AUTO_RESET and not ResetInProgress and health > 0
            and hum.MaxHealth > 0 and health / hum.MaxHealth <= CONFIG.RESET_THRESHOLD then
            emergencyRetreat()
        end
    end
    HealthConnection = hum.HealthChanged:Connect(checkHealth)
    DeathConnection = hum.Died:Connect(function()
        if CONFIG.AUTO_RESET then
            for _, obj in ipairs(character:GetDescendants()) do
                if obj:IsA("BasePart") then obj.LocalTransparencyModifier = 1 end
            end
        end
    end)
    checkHealth(hum.Health)
end

local Positioner = {}
function Positioner.getBehindCFrame(targetHRP)
    if not targetHRP then return nil end
    local targetCF = targetHRP.CFrame
    local targetPos = targetHRP.Position
    local targetLook = targetCF.LookVector
    local pingRaw = getPing() / 1000
    local leadTime = math.min(pingRaw * CONFIG.PING_SAFETY, CONFIG.MAX_LEAD_TIME)
    local predictedPos = targetPos
    local predictedLook = targetLook
    if CONFIG.PING_COMPENSATE then
        local vel = targetHRP.AssemblyLinearVelocity
        local predMult = math.clamp(CONFIG.PREDICTION_MULT, 0.5, 1.5)
        predictedPos = targetPos + vel * leadTime * predMult
        local angVel = targetHRP.AssemblyAngularVelocity
        if angVel.Magnitude > 0.1 then
            local angle = angVel.Magnitude * leadTime * predMult
            angle = math.clamp(angle, -math.pi / 2, math.pi / 2)
            local rotDelta = CFrame.fromAxisAngle(angVel.Unit, angle)
            predictedLook = (rotDelta * targetLook).Unit
        end
        predictedPos = predictedPos + Vector3.new(0, vel.Y * leadTime * 0.5, 0)
    end
    local behindPos = predictedPos - predictedLook * CONFIG.BEHIND_STUDS
    behindPos = behindPos + Vector3.new(0, CONFIG.HEIGHT_OFFSET, 0)
    local facePos = Vector3.new(predictedPos.X, behindPos.Y, predictedPos.Z)
    if (facePos - behindPos).Magnitude < 0.01 then return CFrame.new(behindPos) end
    return CFrame.lookAt(behindPos, facePos)
end
function Positioner.teleport()
    if ResetInProgress or not SelectedTarget or not isAlive(SelectedTarget) then return end
    local targetHRP = getHRP(SelectedTarget)
    local myHRP = getHRP(Player)
    if not targetHRP or not myHRP then return end
    local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end
    if hum.AutoRotate then hum.AutoRotate = false end
    local newCF = Positioner.getBehindCFrame(targetHRP)
    if not newCF then return end
    myHRP.CFrame = newCF
    myHRP.AssemblyLinearVelocity = Vector3.zero
    myHRP.AssemblyAngularVelocity = Vector3.zero
end

function UpdateStatus()
    if BackstabActive and SelectedTarget then
        StatusLabel.Text = "Backstabbing: " .. SelectedTarget.Name
        StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    elseif SelectedTarget then
        StatusLabel.Text = "Пизда этому: " .. SelectedTarget.Name
        StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        StatusLabel.Text = "Выбери долбаёба для секса >:3"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end

local function RefreshPlayerList()
    for _, child in pairs(PlayerScrollFrame:GetChildren()) do child:Destroy() end
    PlayerButtons = {}
    local list = Players:GetPlayers()
    table.sort(list, function(a, b) return a.Name:lower() < b.Name:lower() end)
    local y = 4
    for _, plr in ipairs(list) do
        if plr ~= Player then
            local entry = Instance.new("Frame")
            entry.Size = UDim2.new(1, -7, 0, 21)
            entry.Position = UDim2.new(0, 4, 0, y)
            entry.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            entry.BorderSizePixel = 0
            entry.Parent = PlayerScrollFrame

            local c1 = Instance.new("UICorner")
            c1.CornerRadius = UDim.new(0, 4)
            c1.Parent = entry

            local check = Instance.new("TextButton")
            check.Size = UDim2.new(0, 17, 0, 17)
            check.Position = UDim2.new(0, 2, 0.5, -8)
            check.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
            check.BorderSizePixel = 0
            check.Text = ""
            check.Parent = entry

            local c2 = Instance.new("UICorner")
            c2.CornerRadius = UDim.new(0, 3)
            c2.Parent = check

            local mark = Instance.new("TextLabel")
            mark.Size = UDim2.new(1, 0, 1, 0)
            mark.BackgroundTransparency = 1
            mark.Text = "✓"
            mark.TextColor3 = Color3.fromRGB(0, 255, 0)
            mark.TextSize = 12
            mark.Font = Enum.Font.SourceSansBold
            mark.Visible = (SelectedTarget == plr)
            mark.Parent = check

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -25, 1, 0)
            nameLabel.Position = UDim2.new(0, 21, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = plr.DisplayName .. " (@" .. plr.Name .. ")"
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.TextSize = 11
            nameLabel.Font = Enum.Font.SourceSans
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
            nameLabel.Parent = entry

            local click = Instance.new("TextButton")
            click.Size = UDim2.new(1, 0, 1, 0)
            click.BackgroundTransparency = 1
            click.Text = ""
            click.ZIndex = 2
            click.Parent = entry

            click.MouseButton1Click:Connect(function()
                if SelectedTarget == plr then
                    SelectedTarget = nil
                    mark.Visible = false
                else
                    SelectedTarget = plr
                    for _, d in pairs(PlayerButtons) do d.mark.Visible = false end
                    mark.Visible = true
                end
                UpdateStatus()
            end)

            PlayerButtons[plr.Name] = { mark = mark }
            y = y + 25
        end
    end
    PlayerScrollFrame.CanvasSize = UDim2.new(0, 0, 0, y + 4)
end

local function Message(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = duration or 5 })
    end)
end

local function createEspGui()
    if EspGui then return end
    local gui = Instance.new("ScreenGui")
    gui.Name = "HizolonESP"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = getGuiParent()
    EspGui = gui
end

local function destroyEspGui()
    if EspGui then EspGui:Destroy(); EspGui = nil end
    EspEntries = {}
end

local function ensureEspEntry(plr)
    local entry = EspEntries[plr]
    if entry and entry.frame and entry.frame.Parent then return entry end
    local frame = Instance.new("Frame")
    frame.Name = "Box_" .. plr.Name
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.ZIndex = 5
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 1.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = frame
    frame.Parent = EspGui

    local line = Instance.new("Frame")
    line.Name = "Line_" .. plr.Name
    line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    line.BorderSizePixel = 0
    line.Visible = false
    line.ZIndex = 5
    line.Parent = EspGui

    entry = { frame = frame, line = line, stroke = stroke }
    EspEntries[plr] = entry
    return entry
end

local function updateEsp()
    if not EspGui then return end
    local cam = workspace.CurrentCamera
    if not cam then return end
    for plr, entry in pairs(EspEntries) do
        local hide = true
        if plr ~= Player and isAlive(plr) then
            local char = plr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local head = char and char:FindFirstChild("Head")
            if hrp and head then
                local headVec, headOn = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local footVec, footOn = cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 2.5, 0))
                if headOn or footOn then
                    local topY, botY = headVec.Y, footVec.Y
                    if topY > botY then topY, botY = botY, topY end
                    local height = math.max(botY - topY, 6)
                    local width = height * 0.55
                    local centerX = headVec.X
                    entry.frame.Position = UDim2.fromOffset(centerX - width / 2, topY)
                    entry.frame.Size = UDim2.fromOffset(width, height)
                    entry.frame.Visible = true
                    local lineTop = topY + height
                    local lineBottom = lineTop + math.max(height * 0.35, 8)
                    entry.line.Position = UDim2.fromOffset(centerX - 0.75, lineTop)
                    entry.line.Size = UDim2.fromOffset(1.5, lineBottom - lineTop)
                    entry.line.Visible = true
                    hide = false
                end
            end
        end
        if hide then
            entry.frame.Visible = false
            entry.line.Visible = false
        end
    end
end

local function startEsp()
    createEspGui()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player then ensureEspEntry(plr) end
    end
    if EspConnection then return end
    EspConnection = RunService.RenderStepped:Connect(updateEsp)
end

local function stopEsp()
    if EspConnection then EspConnection:Disconnect(); EspConnection = nil end
    destroyEspGui()
end

local function StartBackstab()
    if not Unlocked then return end
    if BackstabActive then return end
    if not SelectedTarget then
        StatusLabel.Text = "Цель не выбрана!"
        task.wait(1)
        UpdateStatus()
        return
    end
    BackstabActive = true
    local myHum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    if myHum then
        PreviousAutoRotate = myHum.AutoRotate
        myHum.AutoRotate = false
    end
    UpdateStatus()
    Message("Prototype by Flarnux V43.2", "Backstabbing " .. SelectedTarget.Name, 2)
    if CONFIG.SAFE_ZONE then
        disableSafeZone()
        CONFIG.SAFE_ZONE = false
        paintToggle(SafeToggle, "SAVE ZONA", false)
    end
    Positioner.teleport()
    PositionConnection = RunService.PreSimulation:Connect(function()
        pcall(Positioner.teleport)
    end)
end

local function StopBackstab()
    if not BackstabActive then return end
    BackstabActive = false
    if PositionConnection then PositionConnection:Disconnect(); PositionConnection = nil end
    local myHum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    if myHum and PreviousAutoRotate ~= nil then myHum.AutoRotate = PreviousAutoRotate end
    PreviousAutoRotate = nil
    UpdateStatus()
    Message("Prototype by Flarnux V43.2", "Backstab stopped", 2)
end

local function startStatsGui()
    if StatsGuiRunning then return end
    StatsGuiRunning = true

    local W, H, SP, X, Y = 64, 24, 4, 10, 10
    local guiParent = Player:WaitForChild("PlayerGui", 10)
    if not guiParent then return end

    local old = guiParent:FindFirstChild("ServerStatsGUI")
    if old then old:Destroy() end

    StatsScreenGui = Instance.new("ScreenGui")
    StatsScreenGui.Name = "ServerStatsGUI"
    StatsScreenGui.ResetOnSpawn = false
    StatsScreenGui.IgnoreGuiInset = true
    StatsScreenGui.DisplayOrder = 999
    StatsScreenGui.Parent = guiParent

    local function makePlate(index)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.fromOffset(W, H)
        frame.AnchorPoint = Vector2.new(1, 0)
        frame.Position = UDim2.new(1, -X, 0, Y + (index - 1) * (H + SP))
        frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        frame.BackgroundTransparency = 0.5
        frame.BorderSizePixel = 0
        frame.Parent = StatsScreenGui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = frame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.Text = "..."
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 12
        label.Font = Enum.Font.SourceSansBold
        label.TextXAlignment = Enum.TextXAlignment.Center
        label.TextYAlignment = Enum.TextYAlignment.Center
        label.Parent = frame

        return label
    end

    local pingLabel = makePlate(1)
    local fpsLabel = makePlate(2)
    local timeLabel = makePlate(3)
    local playersLabel = makePlate(4)

    local creditFrame = Instance.new("Frame")
    creditFrame.Size = UDim2.fromOffset(W, H)
    creditFrame.AnchorPoint = Vector2.new(1, 0)
    creditFrame.Position = UDim2.new(1, -X, 0, Y + 4 * (H + SP))
    creditFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    creditFrame.BackgroundTransparency = 0.5
    creditFrame.BorderSizePixel = 0
    creditFrame.Parent = StatsScreenGui

    local creditCorner = Instance.new("UICorner")
    creditCorner.CornerRadius = UDim.new(0, 6)
    creditCorner.Parent = creditFrame

    local creditStroke = Instance.new("UIStroke")
    creditStroke.Color = Color3.fromRGB(255, 255, 255)
    creditStroke.Thickness = 1.5
    creditStroke.Parent = creditFrame

    local creditLabel = Instance.new("TextLabel")
    creditLabel.Size = UDim2.fromScale(1, 1)
    creditLabel.BackgroundTransparency = 1
    creditLabel.Text = "By: flarnux"
    creditLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    creditLabel.TextSize = 12
    creditLabel.Font = Enum.Font.SourceSansBold
    creditLabel.TextXAlignment = Enum.TextXAlignment.Center
    creditLabel.TextYAlignment = Enum.TextYAlignment.Center
    creditLabel.Parent = creditFrame

    local startTime = tick()
    local fpsFrames = 0
    local fpsLast = tick()
    local fpsValue = 0
    local accum = 0

    RunService.RenderStepped:Connect(function()
        fpsFrames = fpsFrames + 1
        local now = tick()
        if now - fpsLast >= 1 then
            fpsValue = math.floor(fpsFrames / (now - fpsLast) + 0.5)
            fpsFrames = 0
            fpsLast = now
        end
    end)

    RunService.Heartbeat:Connect(function(dt)
        accum = accum + dt
        local elapsed = math.floor(tick() - startTime)
        local h = math.floor(elapsed / 3600)
        local m = math.floor((elapsed % 3600) / 60)
        local s = elapsed % 60
        timeLabel.Text = string.format("%d:%02d:%02d", h, m, s)

        if accum >= 0.25 then
            accum = 0

            local ping = 0
            local ok, val = pcall(function()
                return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
            end)
            if ok and tonumber(val) then
                ping = tonumber(val)
            end

            local country
            if ping < 40 then
                country = "LOCAL"
            elseif ping < 80 then
                country = "EU"
            elseif ping < 140 then
                country = "US"
            elseif ping < 220 then
                country = "ASIA"
            else
                country = "FAR"
            end
            pingLabel.Text = string.format("%d ms (%s)", math.floor(ping + 0.5), country)

            fpsLabel.Text = string.format("%d FPS", fpsValue)

            local cur = #Players:GetPlayers()
            local max = 0
            local okMax, mv = pcall(function()
                return Players.MaxPlayers
            end)
            if okMax and type(mv) == "number" and mv > 0 then
                max = mv
            end
            playersLabel.Text = max > 0 and string.format("%d/%d plrs", cur, max) or string.format("%d plrs", cur)
        end
    end)
end

local function buildLockOverlay()
    LockOverlay = Instance.new("Frame")
    LockOverlay.Name = "LockOverlay"
    LockOverlay.Size = UDim2.new(1, 0, 1, -21)
    LockOverlay.Position = UDim2.new(0, 0, 0, 21)
    LockOverlay.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    LockOverlay.BackgroundTransparency = 0.05
    LockOverlay.BorderSizePixel = 0
    LockOverlay.ZIndex = 10
    LockOverlay.Parent = MainFrame

    local lockTitle = Instance.new("TextLabel")
    lockTitle.Size = UDim2.new(1, -14, 0, 20)
    lockTitle.Position = UDim2.new(0, 7, 0, 16)
    lockTitle.BackgroundTransparency = 1
    lockTitle.Text = "ВВЕДИТЕ КЛЮЧ ДЛЯ ЗАПУСКА"
    lockTitle.TextColor3 = Color3.fromRGB(255, 0, 0)
    lockTitle.Font = Enum.Font.SourceSansBold
    lockTitle.TextSize = 14
    lockTitle.ZIndex = 11
    lockTitle.Parent = LockOverlay

    KeyInput = Instance.new("TextBox")
    KeyInput.Size = UDim2.new(1, -14, 0, 28)
    KeyInput.Position = UDim2.new(0, 7, 0, 50)
    KeyInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    KeyInput.BorderSizePixel = 0
    KeyInput.Text = ""
    KeyInput.PlaceholderText = "Введите ключ..."
    KeyInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyInput.Font = Enum.Font.SourceSans
    KeyInput.TextSize = 13
    KeyInput.ClearTextOnFocus = false
    KeyInput.ZIndex = 11
    KeyInput.Parent = LockOverlay

    local kc = Instance.new("UICorner")
    kc.CornerRadius = UDim.new(0, 4)
    kc.Parent = KeyInput

    UnlockButton = Instance.new("TextButton")
    UnlockButton.Size = UDim2.new(1, -14, 0, 30)
    UnlockButton.Position = UDim2.new(0, 7, 0, 88)
    UnlockButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
    UnlockButton.BorderSizePixel = 0
    UnlockButton.Text = "ПОДТВЕРДИТЬ"
    UnlockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    UnlockButton.Font = Enum.Font.SourceSansBold
    UnlockButton.TextSize = 13
    UnlockButton.ZIndex = 11
    UnlockButton.Parent = LockOverlay

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 4)
    bc.Parent = UnlockButton

    KeyStatus = Instance.new("TextLabel")
    KeyStatus.Size = UDim2.new(1, -14, 0, 18)
    KeyStatus.Position = UDim2.new(0, 7, 0, 126)
    KeyStatus.BackgroundTransparency = 1
    KeyStatus.Text = "Ключ привязан строго к ID пользователя"
    KeyStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
    KeyStatus.Font = Enum.Font.SourceSans
    KeyStatus.TextSize = 11
    KeyStatus.ZIndex = 11
    KeyStatus.Parent = LockOverlay

    UnlockButton.MouseButton1Click:Connect(function()
        KeyStatus.Text = "Ключ привязан строго к ID пользователя"
        KeyStatus.TextColor3 = Color3.fromRGB(200, 200, 200)

        if Player.UserId == 5620429005 and KeyInput.Text == "ABC" then
            Unlocked = true
            KeyStatus.Text = "Скрипт разблокирован! ;3"
            KeyStatus.TextColor3 = Color3.fromRGB(0, 255, 0)
            KeyInput.Visible = false
            UnlockButton.Visible = false
            task.wait(0.4)
            if LockOverlay then LockOverlay:Destroy(); LockOverlay = nil end
            RefreshPlayerList()
            UpdateStatus()
            Message("Наш приватный дискорд сервер :3", "тест ссылка", 5)
            startStatsGui()
        else
            KeyStatus.Text = "Неверный ключ или нет доступа!"
            KeyStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
            Message("КЛЮЧ МОЖНО ПОЛУЧИТЬ ЗДЕСЬ", "тест ссылка", 5)
        end
    end)

    KeyInput:GetPropertyChangedSignal("Text"):Connect(function()
        if not Unlocked then
            KeyStatus.Text = "Ключ привязан строго к ID пользователя"
            KeyStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end)
end

StartButton.MouseButton1Click:Connect(StartBackstab)
StopButton.MouseButton1Click:Connect(StopBackstab)

SafeToggle.MouseButton1Click:Connect(function()
    if not Unlocked then return end
    CONFIG.SAFE_ZONE = not CONFIG.SAFE_ZONE
    if CONFIG.SAFE_ZONE then
        if BackstabActive then StopBackstab() end
        enableSafeZone()
    else
        disableSafeZone()
    end
    paintToggle(SafeToggle, "SAVE ZONA", CONFIG.SAFE_ZONE)
end)

ResetToggle.MouseButton1Click:Connect(function()
    if not Unlocked then return end
    CONFIG.AUTO_RESET = not CONFIG.AUTO_RESET
    paintToggle(ResetToggle, "AUTO RESET", CONFIG.AUTO_RESET)
    if CONFIG.AUTO_RESET then
        local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 and hum.MaxHealth > 0
            and hum.Health / hum.MaxHealth < CONFIG.RESET_THRESHOLD then
            emergencyRetreat()
        end
    end
end)

FpsBoostToggle.MouseButton1Click:Connect(function()
    if not Unlocked then return end
    CONFIG.FPS_BOOST = not CONFIG.FPS_BOOST
    if CONFIG.FPS_BOOST then
        startFpsBoost()
    else
        stopFpsBoost()
    end
    paintToggle(FpsBoostToggle, "FPS BOOST", CONFIG.FPS_BOOST)
end)

EspToggle.MouseButton1Click:Connect(function()
    if not Unlocked then return end
    CONFIG.ESP = not CONFIG.ESP
    if CONFIG.ESP then
        startEsp()
    else
        stopEsp()
    end
    paintToggle(EspToggle, "ESP", CONFIG.ESP)
end)

table.insert(CleanupConnections, Players.PlayerAdded:Connect(function(plr)
    task.wait(0.5)
    if Unlocked then
        RefreshPlayerList()
        if CONFIG.ESP and EspGui and plr ~= Player then ensureEspEntry(plr) end
    end
end))

table.insert(CleanupConnections, Players.PlayerRemoving:Connect(function(plr)
    if SelectedTarget == plr then SelectedTarget = nil end
    local entry = EspEntries[plr]
    if entry then
        if entry.frame then entry.frame:Destroy() end
        if entry.line then entry.line:Destroy() end
        EspEntries[plr] = nil
    end
    task.wait(0.1)
    if Unlocked then
        RefreshPlayerList()
        UpdateStatus()
    end
end))

CharacterConnection = Player.CharacterAdded:Connect(function(character)
    PreviousAutoRotate = nil
    if SafeActive then
        local hum = character:WaitForChild("Humanoid", 5)
        if hum then
            local c2 = hum.HealthChanged:Connect(function(h)
                if h <= 0 and SafeActive then
                    hum.Health = hum.MaxHealth
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                end
            end)
            table.insert(SafeConnections, c2)
        end
    end
    if Unlocked then
        monitorHealth(character)
        if BackstabActive then
            local hum = character:WaitForChild("Humanoid", 10)
            if hum then PreviousAutoRotate = hum.AutoRotate; hum.AutoRotate = false end
        end
    end
end)

if Player.Character then task.defer(function()
    if Unlocked then monitorHealth(Player.Character) end
end) end

buildLockOverlay()
