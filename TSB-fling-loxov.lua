--[[
    Invisible Backstabber GUI (стиль HIZOLON Fling)
    Функционал:
    - Невидимый персонаж
    - Позиционирование строго позади цели
    - Синхронизация поворота с целью
    - Пинг-компенсация (предсказание движения)

    Оболочка и стиль — из флингТСБ_код.txt
]]

-- ============================================================
-- SERVICES
-- ============================================================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local Stats             = game:GetService("Stats")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ============================================================
-- CONFIG
-- ============================================================
local CONFIG = {
    -- Позиционирование
    BEHIND_STUDS     = 3,
    HEIGHT_OFFSET    = 0,

    -- Невидимость
    INVISIBLE        = true,

    -- Пинг-компенсация
    PING_COMPENSATE  = true,
    PREDICTION_MULT  = 1.0,
}

-- ============================================================
-- GUI SETUP (стиль флинга)
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "InvisBackstabberGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 350)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -175)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -30, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "INVISIBLE BACKSTABBER"
Title.TextColor3 = Color3.fromRGB(255, 80, 80)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 18
Title.Parent = TitleBar

-- Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Position = UDim2.new(1, -30, 0, 0)
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CloseButton.BorderSizePixel = 0
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.TextSize = 18
CloseButton.Parent = TitleBar

-- Status Label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Position = UDim2.new(0, 10, 0, 40)
StatusLabel.Size = UDim2.new(1, -20, 0, 25)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Select target to backstab"
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.TextSize = 16
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = MainFrame

-- Player Selection Frame
local SelectionFrame = Instance.new("Frame")
SelectionFrame.Position = UDim2.new(0, 10, 0, 70)
SelectionFrame.Size = UDim2.new(1, -20, 0, 200)
SelectionFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
SelectionFrame.BorderSizePixel = 0
SelectionFrame.Parent = MainFrame

-- Player List ScrollFrame
local PlayerScrollFrame = Instance.new("ScrollingFrame")
PlayerScrollFrame.Position = UDim2.new(0, 5, 0, 5)
PlayerScrollFrame.Size = UDim2.new(1, -10, 1, -10)
PlayerScrollFrame.BackgroundTransparency = 1
PlayerScrollFrame.BorderSizePixel = 0
PlayerScrollFrame.ScrollBarThickness = 6
PlayerScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerScrollFrame.Parent = SelectionFrame

-- Start Button
local StartButton = Instance.new("TextButton")
StartButton.Position = UDim2.new(0, 10, 0, 280)
StartButton.Size = UDim2.new(0.5, -15, 0, 40)
StartButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
StartButton.BorderSizePixel = 0
StartButton.Text = "START"
StartButton.TextColor3 = Color3.fromRGB(255, 255, 255)
StartButton.Font = Enum.Font.SourceSansBold
StartButton.TextSize = 18
StartButton.Parent = MainFrame

-- Stop Button
local StopButton = Instance.new("TextButton")
StopButton.Position = UDim2.new(0.5, 5, 0, 280)
StopButton.Size = UDim2.new(0.5, -15, 0, 40)
StopButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
StopButton.BorderSizePixel = 0
StopButton.Text = "STOP"
StopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
StopButton.Font = Enum.Font.SourceSansBold
StopButton.TextSize = 18
StopButton.Parent = MainFrame

-- Invisibility Toggle
local InvisToggle = Instance.new("TextButton")
InvisToggle.Position = UDim2.new(0, 10, 0, 330)
InvisToggle.Size = UDim2.new(1, -20, 0, 30)
InvisToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
InvisToggle.BorderSizePixel = 0
InvisToggle.Text = "INVIS: ON"
InvisToggle.TextColor3 = Color3.fromRGB(0, 255, 0)
InvisToggle.Font = Enum.Font.SourceSans
InvisToggle.TextSize = 14
InvisToggle.Parent = MainFrame

-- ============================================================
-- VARIABLES
-- ============================================================
local SelectedTarget = nil
local PlayerButtons = {}
local BackstabActive = false
local PositionConnection = nil
local InvisConnection = nil

-- ============================================================
-- UTILITIES
-- ============================================================

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

-- ============================================================
-- INVISIBILITY
-- ============================================================
local Invisibility = {}

function Invisibility.apply()
    local char = Player.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.LocalTransparencyModifier = 1
            part.Transparency = 1
            part.CanCollide = false
        elseif part:IsA("Decal") or part:IsA("Texture") then
            part.Transparency = 1
        end
    end
end

function Invisibility.remove()
    local char = Player.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.LocalTransparencyModifier = 0
            part.Transparency = 0
        end
    end
end

-- ============================================================
-- POSITIONER (с синхронизацией поворота)
-- ============================================================
local Positioner = {}

-- Возвращает CFrame позади цели С ТЕМ ЖЕ ПОВОРОТОМ, что и у цели
function Positioner.getBehindCFrame(targetHRP)
    if not targetHRP then return nil end

    local targetCF = targetHRP.CFrame

    -- Предсказание позиции (пинг-компенсация)
    local predictedPos = targetHRP.Position
    if CONFIG.PING_COMPENSATE then
        local ping = getPing() / 1000
        local velocity = targetHRP.AssemblyLinearVelocity
        predictedPos = targetHRP.Position + velocity * ping * CONFIG.PREDICTION_MULT
    end

    -- Позиция позади цели по её LookVector
    local behindPos = predictedPos - targetCF.LookVector * CONFIG.BEHIND_STUDS
    behindPos = behindPos + Vector3.new(0, CONFIG.HEIGHT_OFFSET, 0)

    -- ВАЖНО: используем Rotation цели, чтобы персонаж смотрел туда же, куда и цель
    local behindCF = CFrame.new(behindPos) * (targetCF - targetCF.Position)

    return behindCF
end

function Positioner.teleport()
    if not SelectedTarget or not isAlive(SelectedTarget) then return end
    local targetHRP = getHRP(SelectedTarget)
    local myHRP = getHRP(Player)
    if not targetHRP or not myHRP then return end

    local newCF = Positioner.getBehindCFrame(targetHRP)
    if not newCF then return end

    myHRP.CFrame = newCF
    myHRP.AssemblyLinearVelocity = Vector3.zero
end

-- ============================================================
-- PLAYER LIST (стиль флинга)
-- ============================================================
local function RefreshPlayerList()
    for _, child in pairs(PlayerScrollFrame:GetChildren()) do
        child:Destroy()
    end
    PlayerButtons = {}

    local PlayerList = Players:GetPlayers()
    table.sort(PlayerList, function(a, b) return a.Name:lower() < b.Name:lower() end)

    local yPosition = 5
    for _, player in ipairs(PlayerList) do
        if player ~= Player then
            local PlayerEntry = Instance.new("Frame")
            PlayerEntry.Size = UDim2.new(1, -10, 0, 30)
            PlayerEntry.Position = UDim2.new(0, 5, 0, yPosition)
            PlayerEntry.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            PlayerEntry.BorderSizePixel = 0
            PlayerEntry.Parent = PlayerScrollFrame

            local Checkbox = Instance.new("TextButton")
            Checkbox.Size = UDim2.new(0, 24, 0, 24)
            Checkbox.Position = UDim2.new(0, 3, 0.5, -12)
            Checkbox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
            Checkbox.BorderSizePixel = 0
            Checkbox.Text = ""
            Checkbox.Parent = PlayerEntry

            local Checkmark = Instance.new("TextLabel")
            Checkmark.Size = UDim2.new(1, 0, 1, 0)
            Checkmark.BackgroundTransparency = 1
            Checkmark.Text = "✓"
            Checkmark.TextColor3 = Color3.fromRGB(0, 255, 0)
            Checkmark.TextSize = 18
            Checkmark.Font = Enum.Font.SourceSansBold
            Checkmark.Visible = (SelectedTarget == player)
            Checkmark.Parent = Checkbox

            local NameLabel = Instance.new("TextLabel")
            NameLabel.Size = UDim2.new(1, -35, 1, 0)
            NameLabel.Position = UDim2.new(0, 30, 0, 0)
            NameLabel.BackgroundTransparency = 1
            NameLabel.Text = player.Name
            NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            NameLabel.TextSize = 16
            NameLabel.Font = Enum.Font.SourceSans
            NameLabel.TextXAlignment = Enum.TextXAlignment.Left
            NameLabel.Parent = PlayerEntry

            local ClickArea = Instance.new("TextButton")
            ClickArea.Size = UDim2.new(1, 0, 1, 0)
            ClickArea.BackgroundTransparency = 1
            ClickArea.Text = ""
            ClickArea.ZIndex = 2
            ClickArea.Parent = PlayerEntry

            ClickArea.MouseButton1Click:Connect(function()
                if SelectedTarget == player then
                    SelectedTarget = nil
                    Checkmark.Visible = false
                else
                    SelectedTarget = player
                    for _, data in pairs(PlayerButtons) do
                        data.Checkmark.Visible = false
                    end
                    Checkmark.Visible = true
                end
                UpdateStatus()
            end)

            PlayerButtons[player.Name] = {
                Entry = PlayerEntry,
                Checkmark = Checkmark
            }

            yPosition = yPosition + 35
        end
    end

    PlayerScrollFrame.CanvasSize = UDim2.new(0, 0, 0, yPosition + 5)
end

-- ============================================================
-- STATUS
-- ============================================================
function UpdateStatus()
    if BackstabActive then
        if SelectedTarget then
            StatusLabel.Text = "Backstabbing: " .. SelectedTarget.Name
            StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        else
            StatusLabel.Text = "No target selected"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    else
        if SelectedTarget then
            StatusLabel.Text = "Target: " .. SelectedTarget.Name
            StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            StatusLabel.Text = "Select target to backstab"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end
end

-- ============================================================
-- NOTIFICATION
-- ============================================================
local function Message(Title, Text, Time)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = Title,
        Text = Text,
        Duration = Time or 5
    })
end

-- ============================================================
-- START / STOP
-- ============================================================
local function StartBackstab()
    if BackstabActive then return end
    if not SelectedTarget then
        StatusLabel.Text = "No target selected!"
        wait(1)
        UpdateStatus()
        return
    end

    BackstabActive = true
    UpdateStatus()
    Message("Started", "Backstabbing " .. SelectedTarget.Name, 2)

    if CONFIG.INVISIBLE then
        task.wait(0.5)
        Invisibility.apply()
    end

    -- Позиционирование + поворот каждый кадр
    PositionConnection = RunService.RenderStepped:Connect(function()
        pcall(Positioner.teleport)
    end)

    -- Невидимость
    InvisConnection = RunService.Stepped:Connect(function()
        if CONFIG.INVISIBLE then
            pcall(Invisibility.apply)
        end
    end)
end

local function StopBackstab()
    if not BackstabActive then return end
    BackstabActive = false

    if PositionConnection then PositionConnection:Disconnect() PositionConnection = nil end
    if InvisConnection then InvisConnection:Disconnect() InvisConnection = nil end

    Invisibility.remove()

    UpdateStatus()
    Message("Stopped", "Backstab stopped", 2)
end

-- ============================================================
-- BUTTON CONNECTIONS
-- ============================================================
StartButton.MouseButton1Click:Connect(StartBackstab)
StopButton.MouseButton1Click:Connect(StopBackstab)

InvisToggle.MouseButton1Click:Connect(function()
    CONFIG.INVISIBLE = not CONFIG.INVISIBLE
    if CONFIG.INVISIBLE then
        InvisToggle.Text = "INVIS: ON"
        InvisToggle.TextColor3 = Color3.fromRGB(0, 255, 0)
        Invisibility.apply()
    else
        InvisToggle.Text = "INVIS: OFF"
        InvisToggle.TextColor3 = Color3.fromRGB(255, 80, 80)
        Invisibility.remove()
    end
end)

CloseButton.MouseButton1Click:Connect(function()
    StopBackstab()
    ScreenGui:Destroy()
end)

-- ============================================================
-- PLAYER JOIN / LEAVE
-- ============================================================
Players.PlayerAdded:Connect(RefreshPlayerList)
Players.PlayerRemoving:Connect(function(player)
    if SelectedTarget == player then
        SelectedTarget = nil
    end
    RefreshPlayerList()
    UpdateStatus()
end)

-- ============================================================
-- RESPAWN HANDLER
-- ============================================================
Player.CharacterAdded:Connect(function(char)
    task.wait(1)
    if CONFIG.INVISIBLE then
        Invisibility.apply()
    end
end)

-- ============================================================
-- INIT
-- ============================================================
RefreshPlayerList()
UpdateStatus()
Message("Loaded", "Invisible Backstabber GUI loaded!", 3)
