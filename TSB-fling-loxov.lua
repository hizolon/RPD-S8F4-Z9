--[[
    Invisible Backstabber for TSB (The Strongest Battlegrounds)
    Реконструкция обфусцированного скрипта (Evoke Obfuscator)
    
    Функционал:
    - Невидимый персонаж
    - Позиционирование строго позади цели
    - Пинг-компенсация (предсказание движения)
    - Автоатака без промахов
    
    ⚠️ ВНИМАНИЕ: Использование в TSB = бан аккаунта (Hyperion/Byfron)
]]

-- ============================================================
-- 1. СЕРВИСЫ И ССЫЛКИ
-- ============================================================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Stats             = game:GetService("Stats")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

-- ============================================================
-- 2. КОНФИГ
-- ============================================================
local CONFIG = {
    -- Позиционирование
    BEHIND_STUDS     = 3,       -- на сколько studs позади цели стоять
    HEIGHT_OFFSET    = 0,       -- смещение по высоте
    UPDATE_RATE      = 0,       -- 0 = каждый кадр (RenderStepped)

    -- Невидимость
    INVISIBLE        = true,
    INVISIBLE_PARTS  = true,    -- скрывать все части (не только HRP)

    -- Атака
    AUTO_ATTACK      = true,
    ATTACK_RANGE     = 8,       -- дистанция для автоатаки
    ATTACK_COOLDOWN  = 0.15,    -- задержка между ударами

    -- Пинг-компенсация
    PING_COMPENSATE  = true,
    PREDICTION_MULT  = 1.0,     -- множитель предсказания

    -- Цель
    TARGET_NAME      = nil,     -- ник цели (nil = выбрать первого врага)
}

-- ============================================================
-- 3. УТИЛИТЫ
-- ============================================================

-- XOR-расшифровка строк (как в оригинале)
local function xorDecode(encoded, key1, key2)
    local out = {}
    for i = 1, #encoded do
        local b = string.byte(encoded, i)
        local k = (key1 + 57 * (i - 1)) % 256
        out[i] = string.char(bit32.bxor(b, k, key2))
    end
    return table.concat(out)
end

-- Получить пинг игрока (мс)
local function getPing()
    local ok, ping = pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    return ok and ping or 50
end

-- Проверка живой ли персонаж
local function isAlive(plr)
    if not plr or not plr.Character then return false end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

-- Получить HRP (HumanoidRootPart)
local function getHRP(plr)
    if not plr or not plr.Character then return nil end
    return plr.Character:FindFirstChild("HumanoidRootPart")
end

-- ============================================================
-- 4. СИСТЕМА ЦЕЛЕЙ
-- ============================================================
local TargetModule = {}
TargetModule.current = nil

function TargetModule.getEnemies()
    local enemies = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and isAlive(plr) then
            table.insert(enemies, plr)
        end
    end
    return enemies
end

function TargetModule.getNearest()
    local myHRP = getHRP(LocalPlayer)
    if not myHRP then return nil end

    local nearest, minDist = nil, math.huge
    for _, plr in ipairs(TargetModule.getEnemies()) do
        local hrp = getHRP(plr)
        if hrp then
            local d = (hrp.Position - myHRP.Position).Magnitude
            if d < minDist then
                nearest, minDist = plr, d
            end
        end
    end
    return nearest
end

function TargetModule.setByName(name)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Name:lower():find(name:lower(), 1, true) then
            TargetModule.current = plr
            return plr
        end
    end
    return nil
end

function TargetModule.update()
    if CONFIG.TARGET_NAME then
        TargetModule.setByName(CONFIG.TARGET_NAME)
    end
    if not isAlive(TargetModule.current) then
        TargetModule.current = TargetModule.getNearest()
    end
    return TargetModule.current
end

-- ============================================================
-- 5. НЕВИДИМОСТЬ
-- ============================================================
local Invisibility = {}

function Invisibility.apply()
    local char = LocalPlayer.Character
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
    local char = LocalPlayer.Character
    if not char then return end

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.LocalTransparencyModifier = 0
            part.Transparency = 0
        end
    end
end

-- ============================================================
-- 6. ПОЗИЦИОНИРОВАНИЕ ПОЗАДИ ЦЕЛИ
-- ============================================================
local Positioner = {}

function Positioner.getBehindCFrame(targetHRP, myHRP)
    if not targetHRP or not myHRP then return nil end

    -- Базовая позиция: позади цели по её LookVector
    local targetCF = targetHRP.CFrame
    local behindCF = targetCF * CFrame.new(0, CONFIG.HEIGHT_OFFSET, CONFIG.BEHIND_STUDS)

    -- Пинг-компенсация: предсказание позиции цели
    if CONFIG.PING_COMPENSATE then
        local ping = getPing() / 1000  -- в секунды
        local velocity = targetHRP.AssemblyLinearVelocity
        local predictedPos = targetHRP.Position + velocity * ping * CONFIG.PREDICTION_MULT

        -- Смотрим на предсказанную позицию, стоим позади неё
        behindCF = CFrame.new(
            predictedPos - targetCF.LookVector * CONFIG.BEHIND_STUDS,
            predictedPos
        ) * CFrame.new(0, CONFIG.HEIGHT_OFFSET, 0)
    end

    return behindCF
end

function Positioner.teleport()
    local target = TargetModule.current
    if not isAlive(target) then return end

    local targetHRP = getHRP(target)
    local myHRP     = getHRP(LocalPlayer)
    if not targetHRP or not myHRP then return end

    local newCF = Positioner.getBehindCFrame(targetHRP, myHRP)
    if not newCF then return end

    -- Прямая установка CFrame (телепорт)
    myHRP.CFrame = newCF
    myHRP.AssemblyLinearVelocity = Vector3.zero
end

-- ============================================================
-- 7. АВТОАТАКА
-- ============================================================
local Attacker = {}
Attacker.lastAttack = 0

-- Попытка найти Remote для атаки
local function findAttackRemote()
    local candidates = {
        "Remotes",
        "RemoteEvents",
        "Combat",
        "Attack",
    }

    for _, name in ipairs(candidates) do
        local obj = ReplicatedStorage:FindFirstChild(name, true)
        if obj then return obj end
    end
    return nil
end

function Attacker.attack()
    local now = tick()
    if now - Attacker.lastAttack < CONFIG.ATTACK_COOLDOWN then return end

    local target = TargetModule.current
    if not isAlive(target) then return end

    local targetHRP = getHRP(target)
    local myHRP     = getHRP(LocalPlayer)
    if not targetHRP or not myHRP then return end

    local dist = (targetHRP.Position - myHRP.Position).Magnitude
    if dist > CONFIG.ATTACK_RANGE then return end

    -- Попытка вызвать атаку через Remote
    local remote = findAttackRemote()
    if remote and remote:IsA("RemoteEvent") then
        pcall(function()
            remote:FireServer()
        end)
    end

    -- Альтернатива: имитация нажатия мыши
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait(0.05)
        vim:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end)

    Attacker.lastAttack = now
end

-- ============================================================
-- 8. ОСНОВНОЙ ЦИКЛ (корутины)
-- ============================================================

-- Поток 1: обновление цели
local function targetLoop()
    while task.wait(0.5) do
        TargetModule.update()
    end
end

-- Поток 2: позиционирование (каждый кадр)
local function positionLoop()
    RunService.RenderStepped:Connect(function()
        pcall(Positioner.teleport)
    end)
end

-- Поток 3: невидимость
local function invisibilityLoop()
    RunService.Stepped:Connect(function()
        if CONFIG.INVISIBLE then
            pcall(Invisibility.apply)
        end
    end)
end

-- Поток 4: автоатака
local function attackLoop()
    while task.wait(0.05) do
        if CONFIG.AUTO_ATTACK then
            pcall(Attacker.attack)
        end
    end
end

-- Поток 5: слежка за респавном
local function respawnLoop()
    LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(1)
        if CONFIG.INVISIBLE then
            Invisibility.apply()
        end
    end)
end

-- ============================================================
-- 9. UI (простой список игроков)
-- ============================================================
local function createUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "InvisBackstabberUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 250, 0, 350)
    Frame.Position = UDim2.new(0, 20, 0, 100)
    Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    Frame.BorderSizePixel = 0
    Frame.Parent = ScreenGui

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    Title.Text = "Invisible Backstabber"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 14
    Title.Parent = Frame

    local Scrolling = Instance.new("ScrollingFrame")
    Scrolling.Size = UDim2.new(1, -10, 1, -40)
    Scrolling.Position = UDim2.new(0, 5, 0, 35)
    Scrolling.BackgroundTransparency = 1
    Scrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
    Scrolling.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Scrolling.Parent = Frame

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 4)
    Layout.Parent = Scrolling

    -- Кнопки для каждого игрока
    local function refreshPlayers()
        for _, child in ipairs(Scrolling:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, -8, 0, 28)
                btn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
                btn.Text = plr.Name .. "  [" .. plr.DisplayName .. "]"
                btn.TextColor3 = Color3.fromRGB(230, 230, 230)
                btn.Font = Enum.Font.Gotham
                btn.TextSize = 12
                btn.Parent = Scrolling

                btn.MouseButton1Click:Connect(function()
                    TargetModule.current = plr
                    CONFIG.TARGET_NAME = plr.Name
                    btn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
                end)
            end
        end
    end

    refreshPlayers()
    Players.PlayerAdded:Connect(refreshPlayers)
    Players.PlayerRemoving:Connect(function() task.wait(0.1) refreshPlayers() end)
end

-- ============================================================
-- 10. ЗАПУСК
-- ============================================================
local function main()
    -- UI
    pcall(createUI)

    -- Стартуем все потоки
    coroutine.wrap(targetLoop)()
    coroutine.wrap(positionLoop)()
    coroutine.wrap(invisibilityLoop)()
    coroutine.wrap(attackLoop)()
    coroutine.wrap(respawnLoop)()

    -- Невидимость сразу
    if CONFIG.INVISIBLE then
        task.wait(0.5)
        Invisibility.apply()
    end

    print("[Invisible Backstabber] Загружено. Цель: " .. tostring(TargetModule.current))
end

main()
