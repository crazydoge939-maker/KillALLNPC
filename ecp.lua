local autoKill = false
local killIntervalSeconds = 5 -- Значение по умолчанию, можно изменить в игре
local killedCount = 0
local killedHumanoids = {} -- таблица для текущего периода: имя Humanoid -> количество
local highlightedNPCs = {} -- для хранения подсвеченных NPC

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.Name = "Humanoid"

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 100, 0, 30)
toggleButton.Position = UDim2.new(0, 10, 0, 10)
toggleButton.Text = "Вкл"
toggleButton.Parent = ScreenGui

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(0, 250, 0, 150)
infoLabel.Position = UDim2.new(0, 10, 0, 50)
infoLabel.Text = "Убитых: 0\n"
infoLabel.TextWrapped = true
infoLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
infoLabel.Parent = ScreenGui

local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.new(0, 250, 0, 30)
timerLabel.Position = UDim2.new(0, 10, 0, 210)
timerLabel.Text = "Следующий цикл через: " .. tostring(killIntervalSeconds) .. " сек"
timerLabel.TextWrapped = true
timerLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
timerLabel.Parent = ScreenGui

-- Поле для задания времени между циклами
local timeInput = Instance.new("TextBox")
timeInput.Size = UDim2.new(0, 100, 0, 30)
timeInput.Position = UDim2.new(0, 270, 0, 210)
timeInput.Text = tostring(killIntervalSeconds)
timeInput.PlaceholderText = "Время (сек)"
timeInput.Parent = ScreenGui

local function updateGUI()
    local text = "Убитых: " .. tostring(killedCount) .. "\n"
    for name, count in pairs(killedHumanoids) do
        text = text .. name .. " x" .. count .. "\n"
    end
    infoLabel.Text = text
end

local function addHighlight(npc)
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

local function clearHighlights()
    for _, npc in pairs(workspace:GetChildren()) do
        if npc:FindFirstChild("AutoKillHighlight") then
            npc.AutoKillHighlight:Destroy()
        end
    end
    highlightedNPCs = {}
end

local function refreshHighlights()
    clearHighlights()
    if autoKill then
        for _, npc in pairs(workspace:GetChildren()) do
            local humanoid = npc:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 and npc ~= game.Players.LocalPlayer.Character then
                addHighlight(npc)
            end
        end
    end
end

toggleButton.MouseButton1Click:Connect(function()
    autoKill = not autoKill
    if autoKill then
        toggleButton.Text = "Выкл"
        -- обновляем время из текстового поля
        local newTime = tonumber(timeInput.Text)
        if newTime and newTime > 0 then
            killIntervalSeconds = newTime
        end
        -- обновляем таймер
        timeLeft = killIntervalSeconds
        -- создаем подсветку для текущего цикла
        refreshHighlights()
    else
        toggleButton.Text = "Вкл"
        -- снимаем подсветку
        clearHighlights()
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
            -- Обновляем время из поля
            local newTime = tonumber(timeInput.Text)
            if newTime and newTime > 0 then
                killIntervalSeconds = newTime
            end
            -- Перед началом нового цикла убираем старые подсветки и создаем новые
            clearHighlights()
            refreshHighlights()

            -- Убиваем NPC
            local killedThisCycle = false
            for _, npc in pairs(workspace:GetChildren()) do
                local humanoid = npc:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 and npc ~= game.Players.LocalPlayer.Character then
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
