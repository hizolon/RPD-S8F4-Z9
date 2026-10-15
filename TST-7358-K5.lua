--[[
██████╗ ██████╗ ██╗██████╗ ██╗ ██╗ █████╗ ████████╗
██╔══██╗██╔════╝██║██╔══██╗██║ ██║██╔══██╗╚══██╔══╝
██████╔╝██║ ██║██████╔╝██║ ██║███████║ ██║
██╔═══╝ ██║ ██║██╔══██╗╚██╗ ██╔╝██╔══██║ ██║
██║ ╚██████╗██║██║ ██║ ╚████╔╝ ██║ ██║ ██║
╚═╝ ╚═════╝╚═╝╚═╝ ╚═╝ ╚═══╝ ╚═╝ ╚═╝ ╚═╝
SCRIPT HIZOLON PRIVAT SS+
─────────────────────────
• Невидимый персонаж
• Позиционирование строго позади цели
• Разворот ЛИЦОМ к цели
• Корректная пинг-компенсация (без перелёта)
• Управление через GUI
• Размер GUI: ×0.7
Стиль: HIZOLON Fling TSB
Версия: SS+
]]
-- ============================================================
-- SERVICES
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
-- ============================================================
-- CONFIG
-- ============================================================
local CONFIG = {
-- Позиционирование
BEHIND_STUDS = 3,
HEIGHT_OFFSET = 0,
-- Невидимость
INVISIBLE = true,
-- Пинг-компенсация (умеренная, без «перелёта»)
PING_COMPENSATE = true,
PREDICTION_MULT = 1.0,
PING_SAFETY = 1.3,
-- Ограничения (внутренние)
MAX_LEAD_TIME = 0.12,
SMOOTH_FACTOR = 0.15,
}
-- ============================================================
-- GUI SETUP (стиль HIZOLON) — размер ×0.7
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ScriptHizolonPrivatSSPlus"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui
-- Главное окно (300×380 → 210×266)
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 210, 0, 266)
MainFrame.Position = UDim2.new(0.5, -105, 0.5, -133)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
local MainFrameStroke = Instance.new("UIStroke")
MainFrameStroke.Color = Color3.fromRGB(255, 80, 80)
MainFrameStroke.Thickness = 1.2
MainFrameStroke.Parent = MainFrame
-- Заголовок (30 → 21)
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 21)
TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
local TitleBarCorner = Instance.new("UICorner")
TitleBarCorner.CornerRadius = UDim.new(0, 4)
TitleBarCorner.Parent = TitleBar
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -25, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "SCRIPT HIZOLON PRIVAT SS+"
Title.TextColor3 = Color3.fromRGB(255, 80, 80)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 11
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Position = UDim2.new(0, 7, 0, 0)
Title.Parent = TitleBar
-- Кнопка закрытия (30×30 → 21×21)
local CloseButton = Instance.new("TextButton")
CloseButton.Position = UDim2.new(1, -21, 0, 0)
CloseButton.Size = UDim2.new(0, 21, 0, 21)
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CloseButton.BorderSizePixel = 0
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.TextSize = 11
CloseButton.Parent = TitleBar
local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 4)
CloseCorner.Parent = CloseButton
-- Статус
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
-- Рамка выбора цели (200 → 140)
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
-- Кнопка START (40 → 28)
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
-- Кнопка STOP
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
-- Тумблер невидимости (30 → 21)
local InvisToggle = Instance.new("TextButton")
InvisToggle.Position = UDim2.new(0, 7, 0, 231)
InvisToggle.Size = UDim2.new(1, -14, 0, 21)
InvisToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
InvisToggle.BorderSizePixel = 0
InvisToggle.Text = "INVIS: ON"
InvisToggle.TextColor3 = Color3.fromRGB(0, 255, 0)
InvisToggle.Font = Enum.Font.SourceSansBold
InvisToggle.TextSize = 10
InvisToggle.Parent = MainFrame
local InvisCorner = Instance.new("UICorner")
InvisCorner.CornerRadius = UDim.new(0, 4)
InvisCorner.Parent = InvisToggle
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
-- POSITIONER v2
-- Чёткое позиционирование позади + разворот ЛИЦОМ к цели
-- + корректная пинг-компенсация (без "перелёта")
-- ============================================================
local Positioner = {}
function Positioner.getBehindCFrame(targetHRP)
if not targetHRP then return nil end
-- === 1. БАЗОВЫЕ ДАННЫЕ ЦЕЛИ ===
local targetCF = targetHRP.CFrame
local targetPos = targetHRP.Position
local targetLook = targetCF.LookVector
-- === 2. КОРРЕКТНАЯ ПИНГ-КОМПЕНСАЦИЯ ===
local pingRaw = getPing() / 1000
local leadTime = math.min(pingRaw * CONFIG.PING_SAFETY,
CONFIG.MAX_LEAD_TIME)
local predictedPos = targetPos
local predictedLook = targetLook
if CONFIG.PING_COMPENSATE then
local vel = targetHRP.AssemblyLinearVelocity
-- Умеренный множитель предсказания (clamp 0.5–1.5)
local predMult = math.clamp(CONFIG.PREDICTION_MULT, 0.5, 1.5)
predictedPos = targetPos + vel * leadTime * predMult
-- Предсказание поворота — только если цель реально вращается
local angVel = targetHRP.AssemblyAngularVelocity
if angVel.Magnitude > 0.1 then
local angle = angVel.Magnitude * leadTime * predMult
angle = math.clamp(angle, -math.pi / 2, math.pi / 2)
local axis = angVel.Unit
local rotDelta = CFrame.fromAxisAngle(axis, angle)
predictedLook = (rotDelta * targetLook).Unit
end
-- Вертикальная компенсация (прыжок / падение)
predictedPos = predictedPos + Vector3.new(0, vel.Y * leadTime * 0.5, 0)
end
-- === 3. ЧЁТКАЯ ПОЗИЦИЯ ПОЗАДИ ===
local behindPos = predictedPos - predictedLook * CONFIG.BEHIND_STUDS
behindPos = behindPos + Vector3.new(0, CONFIG.HEIGHT_OFFSET, 0)
-- === 4. РАЗВОРОТ ЛИЦОМ К РЕАЛЬНОЙ ЦЕЛИ ===
local facePos = targetPos + Vector3.new(0, 2, 0)
local faceCFrame = CFrame.lookAt(behindPos, facePos)
return faceCFrame
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
myHRP.AssemblyAngularVelocity = Vector3.zero
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
-- PLAYER LIST (×0.7)
-- ============================================================
local function RefreshPlayerList()
for _, child in pairs(PlayerScrollFrame:GetChildren()) do
child:Destroy()
end
PlayerButtons = {}
local PlayerList = Players:GetPlayers()
table.sort(PlayerList, function(a, b) return a.Name:lower() < b.Name:lower() end)
local yPosition = 4
for _, player in ipairs(PlayerList) do
if player ~= Player then
local PlayerEntry = Instance.new("Frame")
PlayerEntry.Size = UDim2.new(1, -7, 0, 21)
PlayerEntry.Position = UDim2.new(0, 4, 0, yPosition)
PlayerEntry.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
PlayerEntry.BorderSizePixel = 0
PlayerEntry.Parent = PlayerScrollFrame
local EntryCorner = Instance.new("UICorner")
EntryCorner.CornerRadius = UDim.new(0, 4)
EntryCorner.Parent = PlayerEntry
local Checkbox = Instance.new("TextButton")
Checkbox.Size = UDim2.new(0, 17, 0, 17)
Checkbox.Position = UDim2.new(0, 2, 0.5, -8)
Checkbox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
Checkbox.BorderSizePixel = 0
Checkbox.Text = ""
Checkbox.Parent = PlayerEntry
local CheckCorner = Instance.new("UICorner")
CheckCorner.CornerRadius = UDim.new(0, 3)
CheckCorner.Parent = Checkbox
local Checkmark = Instance.new("TextLabel")
Checkmark.Size = UDim2.new(1, 0, 1, 0)
Checkmark.BackgroundTransparency = 1
Checkmark.Text = "✓"
Checkmark.TextColor3 = Color3.fromRGB(0, 255, 0)
Checkmark.TextSize = 12
Checkmark.Font = Enum.Font.SourceSansBold
Checkmark.Visible = (SelectedTarget == player)
Checkmark.Parent = Checkbox
local NameLabel = Instance.new("TextLabel")
NameLabel.Size = UDim2.new(1, -25, 1, 0)
NameLabel.Position = UDim2.new(0, 21, 0, 0)
NameLabel.BackgroundTransparency = 1
NameLabel.Text = player.Name
NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
NameLabel.TextSize = 11
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
yPosition = yPosition + 25
end
end
PlayerScrollFrame.CanvasSize = UDim2.new(0, 0, 0, yPosition + 4)
end
-- ============================================================
-- NOTIFICATION
-- ============================================================
local function Message(Title, Text, Time)
pcall(function()
StarterGui:SetCore("SendNotification", {
Title = Title,
Text = Text,
Duration = Time or 5
})
end)
end
-- ============================================================
-- START / STOP
-- ============================================================
local function StartBackstab()
if BackstabActive then return end
if not SelectedTarget then
StatusLabel.Text = "No target selected!"
task.wait(1)
UpdateStatus()
return
end
BackstabActive = true
UpdateStatus()
Message("Script Hizolon Privat SS+", "Backstabbing " .. SelectedTarget.Name, 2)
if CONFIG.INVISIBLE then
task.wait(0.5)
Invisibility.apply()
end
PositionConnection = RunService.RenderStepped:Connect(function()
pcall(Positioner.teleport)
end)
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
Message("Script Hizolon Privat SS+", "Backstab stopped", 2)
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
Players.PlayerAdded:Connect(function()
task.wait(0.5)
RefreshPlayerList()
end)
Players.PlayerRemoving:Connect(function(player)
if SelectedTarget == player then
SelectedTarget = nil
end
task.wait(0.1)
RefreshPlayerList()
UpdateStatus()
end)
-- ============================================================
-- RESPAWN HANDLER
-- ============================================================
Player.CharacterAdded:Connect(function()
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
Message("Script Hizolon Privat SS+", "Loaded successfully!", 3)
