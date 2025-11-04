local autoKill = false
local killIntervalSeconds = 5 -- начальное время
local killedCount = 0
local killedHumanoids = {} -- таблица для текущего периода: имя Humanoid -> количество
local highlightedNPCs = {} -- для хранения подсвеченных NPC

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.Name = "Humanoid"

-- Кнопка для переключения режима
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 100, 0, 30)
toggleButton.Position = UDim2.new(0, 10, 0, 10)
toggleButton.Text = "Вкл"
toggleButton.Parent = ScreenGui

-- UI для отображения убитых
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(0, 250, 0, 150)
infoLabel.Position = UDim2.new(0, 10, 0, 50)
infoLabel.Text = "Убитых: 0\n"
infoLabel.TextWrapped = true
infoLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
infoLabel.Parent = ScreenGui

-- Таймер до следующего цикла
local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.new(0, 250, 0, 30)
timerLabel.Position = UDim2.new(0, 10, 0, 210)
timerLabel.Text = "Следующий цикл через: " .. tostring(killIntervalSeconds) .. " сек"
timerLabel.TextWrapped = true
timerLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
timerLabel.Parent = ScreenGui

-- UI для ввода времени
local inputLabel = Instance.new("TextLabel")
inputLabel.Size = UDim2.new(0, 200, 0, 30)
inputLabel.Position = UDim2.new(0, 10, 0, 250)
inputLabel.Text = "Время цикла (сек):"
inputLabel.TextColor3 = Color3.fromRGB(255,255,255)
inputLabel.BackgroundColor3 = Color3.fromRGB(0,0,0)
inputLabel.Parent = ScreenGui

local timeInputBox = Instance.new("TextBox")
timeInputBox.Size = UDim2.new(0, 50, 0, 30)
timeInputBox.Position = UDim2.new(0, 210, 0, 250)
timeInputBox.Text = tostring(killIntervalSeconds)
timeInputBox.ClearTextOnFocus = false
timeInputBox.Parent = ScreenGui

-- Функция обновления GUI
local function updateGUI()
    local text = "Убитых: " .. tostring(killedCount) .. "\n"
    for name, count in pairs(killedHumanoids) do
        text = text .. name .. " x" .. count .. "\n"
    end
    infoLabel.Text = text
end

-- Добавление подсветки NPC
local function addHighlight(npc)
    if not npc:FindFirstChild("AutoKillHighlight") then
        local highlight = Instance.new("Highlight")
        highlight.Name = "AutoKillHighlight"
        highlight.Adornee = npc
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.OutlineTransparency = 0
        highlight.Parent = npc
        table.insert(highlightedNPCs, npc)
    end
end

-- Удаление всех подсветок
local function removeHighlights()
    for _, npc in pairs(workspace:GetChildren()) do
        if npc:FindFirstChild("AutoKillHighlight") then
            npc.AutoKillHighlight:Destroy()
        end
    end
    highlightedNPCs = {}
end

-- Обработчик переключения режима
toggleButton.MouseButton1Click: function()
    autoKill = not autoKill
    if autoKill then
        toggleButton.Text = "Выкл"
        -- добавляем подсветку всем существующим NPC
        for _, npc in pairs(workspace:GetChildren()) do
            local humanoid = npc:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 and npc ~= game.Players.LocalPlayer.Character then
                addHighlight(npc)
            end
        end
    else
        toggleButton.Text = "Вкл"
        removeHighlights()
    end
end

-- Обработка ввода времени
timeInputBox.FocusLost:Connect(function(enterPressed)
    if not autoKill then
        local newTime = tonumber(timeInputBox.Text)
        if newTime and newTime > 0 then
            killIntervalSeconds = newTime
            timerLabel.Text = "Следующий цикл через: " .. tostring(killIntervalSeconds) .. " сек"
        else
            -- Восстановить старое значение, если ввод некорректен
            timeInputBox.Text = tostring(killIntervalSeconds)
        end
    end
end)

-- Обнаружение новых NPC
workspace.ChildAdded:Connect(function(child)
    if autoKill then
        local humanoid = child:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 and child ~= game.Players.LocalPlayer.Character then
            addHighlight(child)
        end
    end
end)

local timeLeft = killIntervalSeconds -- оставшееся время

while true do
    wait(1)
    if autoKill then
        -- Обновляем таймер
        timeLeft = timeLeft - 1
        if timeLeft < 0 then
            timeLeft = killIntervalSeconds
            -- Перед началом нового цикла убираем старые подсветки и добавляем новые
            removeHighlights()
            for _, npc in pairs(workspace:GetChildren()) do
                local humanoid = npc:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 and npc ~= game.Players.LocalPlayer.Character then
                    addHighlight(npc)
                end
            end

            -- Убиваем NPC
            local killedThisCycle = false
            for _, npc in pairs(workspace:GetChildren()) do
                local humanoid = npc:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 and npc ~= game.Players.LocalPlayer.Character then
                    -- Убийство на любом расстоянии
                    humanoid.Health = 0
                    local name = npc.Name
                    -- Подсчет убитых по имени Humanoid
                    killedHumanoids[name] = (killedHumanoids[name] or 0) + 1
                    killedCount = killedCount + 1
                    print("Убит: " .. name)
                    killedThisCycle = true
                end
            end

            if killedThisCycle then
                updateGUI()
            end
        end
        -- Обновляем отображение таймера
        timerLabel.Text = "Следующий цикл через: " .. tostring(timeLeft) .. " сек"
    end
end
