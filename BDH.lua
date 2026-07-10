-- [[ BDH UM TOQUE ]] --
-- [[ Script para o jogo "Um Toque" ]] --
-- [[ Versão: 6.0 ]] --

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local camera = game.Workspace.CurrentCamera
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local guiService = game:GetService("GuiService")

-- Variáveis principais
local aimbotEnabled = false
local aimbotMode = "Select"
local fovEnabled = false
local fovRadius = 200
local targetPlayer = nil
local selectedPlayerName = nil
local autoKillEnabled = false
local autoKillV2Enabled = false
local isDragging = false
local isMinimized = false
local isVisible = true
local espEnabled = false
local playerList = {}
local selectedIndex = 1
local aimbotActive = false

-- Variáveis para o tiro
local shootEvent = nil

-- Procurar o evento de tiro
local function findShootEvent()
    for _, v in pairs(replicatedStorage:GetChildren()) do
        if v:IsA("RemoteEvent") then
            if v.Name:lower():find("shoot") or v.Name:lower():find("fire") or v.Name:lower():find("click") or v.Name:lower():find("atirar") then
                shootEvent = v
                print("🔫 Evento de tiro encontrado: " .. v.Name)
                return
            end
        end
    end
    
    for _, service in pairs(game:GetChildren()) do
        if service:IsA("Folder") or service:IsA("ReplicatedStorage") then
            for _, v in service:GetChildren() do
                if v:IsA("RemoteEvent") then
                    if v.Name:lower():find("shoot") or v.Name:lower():find("fire") or v.Name:lower():find("click") or v.Name:lower():find("atirar") then
                        shootEvent = v
                        print("🔫 Evento de tiro encontrado em " .. service.Name .. ": " .. v.Name)
                        return
                    end
                end
            end
        end
    end
end

-- Função melhorada para atirar
local function shoot()
    -- Método 1: Click do mouse
    pcall(function()
        mouse.Button1Click:Fire()
        mouse.Button1Down:Fire()
        mouse.Button1Up:Fire()
    end)
    
    -- Método 2: VirtualInputManager
    pcall(function()
        local VirtualInputManager = game:GetService("VirtualInputManager")
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        wait(0.02)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end)
    
    -- Método 3: RemoteEvent
    if shootEvent then
        pcall(function()
            shootEvent:FireServer()
        end)
    end
    
    -- Método 4: Botões na interface
    for _, v in pairs(player.PlayerGui:GetDescendants()) do
        if v:IsA("TextButton") or v:IsA("ImageButton") then
            if v.Name:lower():find("shoot") or v.Name:lower():find("fire") or v.Name:lower():find("click") or v.Name:lower():find("atirar") then
                pcall(function()
                    v:Fire()
                end)
            end
        end
    end
    
    -- Método 5: Ferramenta
    if player.Character then
        local tool = player.Character:FindFirstChildOfClass("Tool")
        if tool then
            pcall(function()
                tool:Activate()
            end)
        end
    end
    
    -- Método 6: KeyCode E e R
    pcall(function()
        local VirtualInputManager = game:GetService("VirtualInputManager")
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        wait(0.02)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
        wait(0.02)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
    end)
end

-- Criação do FOV Circle com Drawing
local fovCircle = nil
local function createFOVCircle()
    if fovCircle then
        fovCircle:Remove()
        fovCircle = nil
    end
    
    fovCircle = Drawing.new("Circle")
    fovCircle.Visible = false
    fovCircle.Radius = fovRadius
    fovCircle.Color = Color3.fromRGB(255, 0, 0)
    fovCircle.Thickness = 2
    fovCircle.Filled = false
    fovCircle.Transparency = 0.5
    fovCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    fovCircle.ZIndex = 999
end

createFOVCircle()

-- Função para atualizar posição do FOV
local function updateFOV()
    if fovCircle then
        fovCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    end
end

-- Sistema ESP RGB
local espObjects = {}
local function createESP(p)
    if espObjects[p] then
        destroyESP(p)
    end
    
    local character = p.Character
    if not character then return end
    
    local head = character:FindFirstChild("Head")
    if not head then return end
    
    local esp = {}
    
    -- Box ESP
    local box = Instance.new("BoxHandleAdornment")
    box.Size = Vector3.new(2, 2.5, 2)
    box.Adornee = head
    box.Parent = head
    box.ZIndex = 10
    box.AlwaysOnTop = true
    esp.box = box
    
    -- Nome
    local nameTag = Instance.new("BillboardGui")
    nameTag.Size = UDim2.new(0, 200, 0, 50)
    nameTag.Adornee = head
    nameTag.Parent = head
    nameTag.AlwaysOnTop = true
    nameTag.StudsOffset = Vector3.new(0, 2, 0)
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.Text = p.Name
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Parent = nameTag
    esp.nameTag = nameTag
    
    espObjects[p] = esp
    
    -- Atualizar cor RGB
    spawn(function()
        while espObjects[p] and espObjects[p].box do
            local hue = tick() % 2 / 2
            local color = Color3.fromHSV(hue, 1, 1)
            esp.box.Color3 = color
            esp.box.Transparency = 0.3
            wait(0.05)
        end
    end)
end

local function destroyESP(p)
    if espObjects[p] then
        local esp = espObjects[p]
        if esp.box then esp.box:Destroy() end
        if esp.nameTag then esp.nameTag:Destroy() end
        espObjects[p] = nil
    end
end

local function updateESP()
    if not espEnabled then
        for p, _ in pairs(espObjects) do
            destroyESP(p)
        end
        return
    end
    
    for _, v in pairs(players:GetPlayers()) do
        if v ~= player then
            if v.Character and v.Character:FindFirstChild("Head") then
                if not espObjects[v] then
                    createESP(v)
                end
            else
                if espObjects[v] then
                    destroyESP(v)
                end
            end
        end
    end
end

-- Interface gráfica
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BDH_UM_TOQUE"
screenGui.Parent = player.PlayerGui
screenGui.ResetOnSpawn = false

-- Frame principal
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 350, 0, 480)
mainFrame.Position = UDim2.new(0.5, -175, 0.5, -240)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 15)
corner.Parent = mainFrame

-- Barra de título
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 35)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
titleBar.BackgroundTransparency = 0.8
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleBarCorner = Instance.new("UICorner")
titleBarCorner.CornerRadius = UDim.new(0, 15)
titleBarCorner.Parent = titleBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.7, 0, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = "⚡ BDH UM TOQUE"
title.TextSize = 14
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

-- Botões da barra de título
local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0, 25, 0, 25)
minimizeButton.Position = UDim2.new(1, -60, 0, 5)
minimizeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
minimizeButton.BackgroundTransparency = 0.5
minimizeButton.BorderSizePixel = 0
minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.Text = "─"
minimizeButton.TextSize = 18
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.Parent = titleBar

local minimizeCorner = Instance.new("UICorner")
minimizeCorner.CornerRadius = UDim.new(0, 5)
minimizeCorner.Parent = minimizeButton

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 25, 0, 25)
closeButton.Position = UDim2.new(1, -30, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.BackgroundTransparency = 0.5
closeButton.BorderSizePixel = 0
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Text = "✕"
closeButton.TextSize = 16
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 5)
closeCorner.Parent = closeButton

-- Container de conteúdo
local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(1, 0, 1, -35)
contentContainer.Position = UDim2.new(0, 0, 0, 35)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = mainFrame

-- Abas
local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(1, 0, 0, 35)
tabContainer.Position = UDim2.new(0, 0, 0, 0)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = contentContainer

local function createTab(text, position)
    local tab = Instance.new("TextButton")
    tab.Size = UDim2.new(0, 85, 1, 0)
    tab.Position = UDim2.new(position, 0, 0, 0)
    tab.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    tab.BackgroundTransparency = 0.5
    tab.BorderSizePixel = 0
    tab.TextColor3 = Color3.fromRGB(255, 255, 255)
    tab.Text = text
    tab.TextSize = 12
    tab.Font = Enum.Font.GothamMedium
    tab.Parent = tabContainer
    
    local tabCorner = Instance.new("UICorner")
    tabCorner.Parent = tab
    
    return tab
end

local tabAimbot = createTab("🎯 Aimbot", 0.02)
local tabAutoKill = createTab("💀 Auto Kill", 0.28)
local tabESP = createTab("👁️ ESP", 0.54)

-- Container das abas
local pageContainer = Instance.new("Frame")
pageContainer.Size = UDim2.new(1, 0, 1, -35)
pageContainer.Position = UDim2.new(0, 0, 0, 35)
pageContainer.BackgroundTransparency = 1
pageContainer.Parent = contentContainer

-- Aba Aimbot
local aimbotContainer = Instance.new("Frame")
aimbotContainer.Size = UDim2.new(1, 0, 1, 0)
aimbotContainer.BackgroundTransparency = 1
aimbotContainer.Visible = true
aimbotContainer.Parent = pageContainer

-- Toggle Aimbot
local aimbotToggle = Instance.new("TextButton")
aimbotToggle.Size = UDim2.new(0, 130, 0, 30)
aimbotToggle.Position = UDim2.new(0.5, -65, 0, 10)
aimbotToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
aimbotToggle.BorderSizePixel = 0
aimbotToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
aimbotToggle.Text = "🔒 Aimbot: OFF"
aimbotToggle.TextSize = 12
aimbotToggle.Font = Enum.Font.GothamMedium
aimbotToggle.Parent = aimbotContainer

local aimbotToggleCorner = Instance.new("UICorner")
aimbotToggleCorner.Parent = aimbotToggle

-- Lista de players
local playerListFrame = Instance.new("ScrollingFrame")
playerListFrame.Size = UDim2.new(0, 150, 0, 120)
playerListFrame.Position = UDim2.new(0.5, -75, 0, 50)
playerListFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
playerListFrame.BackgroundTransparency = 0.5
playerListFrame.BorderSizePixel = 0
playerListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
playerListFrame.ScrollBarThickness = 4
playerListFrame.Parent = aimbotContainer

local playerListCorner = Instance.new("UICorner")
playerListCorner.Parent = playerListFrame

local function updatePlayerList()
    for _, child in pairs(playerListFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    local playersList = {}
    for _, v in pairs(players:GetPlayers()) do
        if v ~= player then
            table.insert(playersList, v.Name)
        end
    end
    table.sort(playersList)
    
    -- Opção "All"
    local allButton = Instance.new("TextButton")
    allButton.Size = UDim2.new(1, -5, 0, 25)
    allButton.Position = UDim2.new(0, 2.5, 0, 0)
    allButton.BackgroundColor3 = (selectedPlayerName == nil and aimbotMode == "All") and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(50, 50, 55)
    allButton.BorderSizePixel = 0
    allButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    allButton.Text = "🌍 Todos (All)"
    allButton.TextSize = 11
    allButton.Font = Enum.Font.GothamMedium
    allButton.Parent = playerListFrame
    
    local allCorner = Instance.new("UICorner")
    allCorner.Parent = allButton
    
    allButton.MouseButton1Click:Connect(function()
        selectedPlayerName = nil
        targetPlayer = nil
        aimbotMode = "All"
        updatePlayerList()
        print("🌍 Modo: All")
        title.Text = "⚡ BDH UM TOQUE - Modo: All"
        wait(1.5)
        title.Text = "⚡ BDH UM TOQUE"
    end)
    
    local yPos = 30
    for _, name in pairs(playersList) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -5, 0, 25)
        btn.Position = UDim2.new(0, 2.5, 0, yPos)
        btn.BackgroundColor3 = (selectedPlayerName == name and aimbotMode == "Select") and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(50, 50, 55)
        btn.BorderSizePixel = 0
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Text = name
        btn.TextSize = 11
        btn.Font = Enum.Font.GothamMedium
        btn.Parent = playerListFrame
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            selectedPlayerName = name
            aimbotMode = "Select"
            -- Encontrar o player
            for _, v in pairs(players:GetPlayers()) do
                if v.Name == name then
                    targetPlayer = v
                    break
                end
            end
            updatePlayerList()
            print("🎯 Alvo selecionado: " .. name)
            title.Text = "⚡ BDH UM TOQUE - Alvo: " .. name
            wait(1.5)
            title.Text = "⚡ BDH UM TOQUE"
        end)
        
        yPos = yPos + 28
    end
    
    playerListFrame.CanvasSize = UDim2.new(0, 0, 0, yPos + 5)
end

-- FOV Toggle
local fovToggle = Instance.new("TextButton")
fovToggle.Size = UDim2.new(0, 130, 0, 30)
fovToggle.Position = UDim2.new(0.5, -65, 0, 185)
fovToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
fovToggle.BorderSizePixel = 0
fovToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
fovToggle.Text = "🎯 FOV: OFF"
fovToggle.TextSize = 12
fovToggle.Font = Enum.Font.GothamMedium
fovToggle.Parent = aimbotContainer

local fovToggleCorner = Instance.new("UICorner")
fovToggleCorner.Parent = fovToggle

-- Slider FOV
local radiusLabel = Instance.new("TextLabel")
radiusLabel.Size = UDim2.new(0, 80, 0, 20)
radiusLabel.Position = UDim2.new(0.5, -90, 0, 225)
radiusLabel.BackgroundTransparency = 1
radiusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
radiusLabel.Text = "Raio: 200"
radiusLabel.TextSize = 11
radiusLabel.Font = Enum.Font.GothamMedium
radiusLabel.Parent = aimbotContainer

local radiusSlider = Instance.new("Frame")
radiusSlider.Size = UDim2.new(0, 120, 0, 5)
radiusSlider.Position = UDim2.new(0.5, 10, 0, 233)
radiusSlider.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
radiusSlider.BorderSizePixel = 0
radiusSlider.Parent = aimbotContainer

local radiusFill = Instance.new("Frame")
radiusFill.Size = UDim2.new(0.75, 0, 1, 0)
radiusFill.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
radiusFill.BorderSizePixel = 0
radiusFill.Parent = radiusSlider

-- Aba Auto Kill
local autoKillContainer = Instance.new("Frame")
autoKillContainer.Size = UDim2.new(1, 0, 1, 0)
autoKillContainer.BackgroundTransparency = 1
autoKillContainer.Visible = false
autoKillContainer.Parent = pageContainer

local autoKillToggle = Instance.new("TextButton")
autoKillToggle.Size = UDim2.new(0, 160, 0, 35)
autoKillToggle.Position = UDim2.new(0.5, -80, 0, 20)
autoKillToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
autoKillToggle.BorderSizePixel = 0
autoKillToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
autoKillToggle.Text = "⚡ Auto Kill: OFF"
autoKillToggle.TextSize = 12
autoKillToggle.Font = Enum.Font.GothamMedium
autoKillToggle.Parent = autoKillContainer

local autoKillCorner = Instance.new("UICorner")
autoKillCorner.Parent = autoKillToggle

local autoKillV2Toggle = Instance.new("TextButton")
autoKillV2Toggle.Size = UDim2.new(0, 160, 0, 35)
autoKillV2Toggle.Position = UDim2.new(0.5, -80, 0, 70)
autoKillV2Toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
autoKillV2Toggle.BorderSizePixel = 0
autoKillV2Toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
autoKillV2Toggle.Text = "🎯 Auto Kill V2: OFF"
autoKillV2Toggle.TextSize = 12
autoKillV2Toggle.Font = Enum.Font.GothamMedium
autoKillV2Toggle.Parent = autoKillContainer

local autoKillV2Corner = Instance.new("UICorner")
autoKillV2Corner.Parent = autoKillV2Toggle

local autoKillInfo = Instance.new("TextLabel")
autoKillInfo.Size = UDim2.new(1, 0, 0, 30)
autoKillInfo.Position = UDim2.new(0, 0, 1, -30)
autoKillInfo.BackgroundTransparency = 1
autoKillInfo.TextColor3 = Color3.fromRGB(150, 150, 150)
autoKillInfo.Text = "Auto Kill: Mira e atira automaticamente"
autoKillInfo.TextSize = 10
autoKillInfo.Font = Enum.Font.GothamMedium
autoKillInfo.Parent = autoKillContainer

-- Aba ESP
local espContainer = Instance.new("Frame")
espContainer.Size = UDim2.new(1, 0, 1, 0)
espContainer.BackgroundTransparency = 1
espContainer.Visible = false
espContainer.Parent = pageContainer

local espToggle = Instance.new("TextButton")
espToggle.Size = UDim2.new(0, 160, 0, 35)
espToggle.Position = UDim2.new(0.5, -80, 0, 20)
espToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
espToggle.BorderSizePixel = 0
espToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
espToggle.Text = "🌈 ESP RGB: OFF"
espToggle.TextSize = 12
espToggle.Font = Enum.Font.GothamMedium
espToggle.Parent = espContainer

local espCorner = Instance.new("UICorner")
espCorner.Parent = espToggle

local espInfo = Instance.new("TextLabel")
espInfo.Size = UDim2.new(1, 0, 0, 30)
espInfo.Position = UDim2.new(0, 0, 1, -30)
espInfo.BackgroundTransparency = 1
espInfo.TextColor3 = Color3.fromRGB(150, 150, 150)
espInfo.Text = "ESP RGB com cores dinâmicas"
espInfo.TextSize = 10
espInfo.Font = Enum.Font.GothamMedium
espInfo.Parent = espContainer

-- Navegação entre abas
tabAimbot.MouseButton1Click:Connect(function()
    aimbotContainer.Visible = true
    autoKillContainer.Visible = false
    espContainer.Visible = false
    tabAimbot.BackgroundColor3 = Color3.fromRGB(70, 70, 75)
    tabAutoKill.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    tabESP.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    updatePlayerList()
end)

tabAutoKill.MouseButton1Click:Connect(function()
    aimbotContainer.Visible = false
    autoKillContainer.Visible = true
    espContainer.Visible = false
    tabAutoKill.BackgroundColor3 = Color3.fromRGB(70, 70, 75)
    tabAimbot.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    tabESP.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
end)

tabESP.MouseButton1Click:Connect(function()
    aimbotContainer.Visible = false
    autoKillContainer.Visible = false
    espContainer.Visible =
