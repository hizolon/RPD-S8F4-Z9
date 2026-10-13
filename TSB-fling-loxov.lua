--[[
    ЕСЛИ РАБОТАЕТ ТО НЕ ХУЙ ЛЕЗТЬ, БИЛЯЯЯЯЯ 67 ПОКОЁ ВЕНОМ
    (Изменено: одна цель + позиция ПОД целью, обновление каждый кадр)
]]
-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "hizolonBelowGUI"
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
Title.Text = "HIZOLON BELOW TARGET"
Title.TextColor3 = Color3.fromRGB(255, 80, 80)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
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
StatusLabel.Text = "Select ONE target"
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

-- Deselect Button
local DeselectAllButton = Instance.new("TextButton")
DeselectAllButton.Position = UDim2.new(0, 10, 0, 330)
DeselectAllButton.Size = UDim2.new(1, -20, 0, 30)
DeselectAllButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
DeselectAllButton.BorderSizePixel = 0
DeselectAllButton.Text = "DESELECT"
DeselectAllButton.TextColor3 = Color3.fromRGB(255, 255, 255)
DeselectAllButton.Font = Enum.Font.SourceSans
DeselectAllButton.TextSize = 14
DeselectAllButton.Parent = MainFrame

-- Variables
local SelectedTarget = nil
local PlayerCheckboxes = {}
local FollowActive = false
local HeartbeatConnection = nil

-- Function to update player list
local function RefreshPlayerList()
    for _, child in pairs(PlayerScrollFrame:GetChildren()) do
        child:Destroy()
    end
    PlayerCheckboxes = {}

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
            Checkmark.Visible = SelectedTarget and SelectedTarget.Name == player.Name
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
                if SelectedTarget and SelectedTarget.Name == player.Name then
                    SelectedTarget = nil
                    Checkmark.Visible = false
                else
                    for _, data in pairs(PlayerCheckboxes) do
                        data.Checkmark.Visible = false
                    end
                    SelectedTarget = player
                    Checkmark.Visible = true
                end
                UpdateStatus()
            end)

            PlayerCheckboxes[player.Name] = {
                Entry = PlayerEntry,
                Checkmark = Checkmark
            }

            yPosition = yPosition + 35
        end
    end

    PlayerScrollFrame.CanvasSize = UDim2.new(0, 0, 0, yPosition + 5)
end

-- Update status display
function UpdateStatus()
    if FollowActive and SelectedTarget then
        StatusLabel.Text = "Below: " .. SelectedTarget.Name
        StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    elseif SelectedTarget then
        StatusLabel.Text = "Selected: " .. SelectedTarget.Name
        StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        StatusLabel.Text = "Select ONE target"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end

-- Show notification
local function Message(Title, Text, Time)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = Title,
        Text = Text,
        Duration = Time or 5
    })
end

-- Позиционирование ПОД целью
local function PositionBelowTarget(TargetPlayer)
    local Character = Player.Character
    if not Character then return end
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    if not RootPart then return end

    local TCharacter = TargetPlayer.Character
    if not TCharacter then return end
    local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    if not TRootPart then return end

    -- Позиция ПОД целью (3 стада вниз)
    local targetPos = TRootPart.Position
    local belowPos = Vector3.new(targetPos.X, targetPos.Y - 3, targetPos.Z)

    RootPart.Velocity = Vector3.new(0, 0, 0)
    RootPart.RotVelocity = Vector3.new(0, 0, 0)
    RootPart.CFrame = CFrame.new(belowPos)
    Character:SetPrimaryPartCFrame(CFrame.new(belowPos))
end

-- Start follow (Heartbeat = каждый кадр, максимум возможного)
local function StartFollow()
    if FollowActive then return end
    if not SelectedTarget or not SelectedTarget.Parent then
        StatusLabel.Text = "No target selected!"
        task.wait(1)
        UpdateStatus()
        return
    end

    FollowActive = true
    UpdateStatus()
    Message("Started", "Below " .. SelectedTarget.Name, 2)

    HeartbeatConnection = RunService.Heartbeat:Connect(function()
        if not FollowActive then return end
        if not SelectedTarget or not SelectedTarget.Parent then
            FollowActive = false
            if HeartbeatConnection then
                HeartbeatConnection:Disconnect()
                HeartbeatConnection = nil
            end
            UpdateStatus()
            return
        end
        PositionBelowTarget(SelectedTarget)
    end)
end

-- Stop follow
local function StopFollow()
    if not FollowActive then return end
    FollowActive = false
    if HeartbeatConnection then
        HeartbeatConnection:Disconnect()
        HeartbeatConnection = nil
    end
    UpdateStatus()
    Message("Stopped", "Follow stopped", 2)
end

-- Button connections
StartButton.MouseButton1Click:Connect(StartFollow)
StopButton.MouseButton1Click:Connect(StopFollow)
DeselectAllButton.MouseButton1Click:Connect(function()
    SelectedTarget = nil
    for _, data in pairs(PlayerCheckboxes) do
        data.Checkmark.Visible = false
    end
    UpdateStatus()
end)
CloseButton.MouseButton1Click:Connect(function()
    StopFollow()
    ScreenGui:Destroy()
end)

-- Player join/leave
Players.PlayerAdded:Connect(RefreshPlayerList)
Players.PlayerRemoving:Connect(function(player)
    if SelectedTarget and SelectedTarget.Name == player.Name then
        SelectedTarget = nil
    end
    RefreshPlayerList()
    UpdateStatus()
end)

-- Initialize
RefreshPlayerList()
UpdateStatus()
Message("Loaded", "HIZOLON Below-Target GUI loaded!", 3)
