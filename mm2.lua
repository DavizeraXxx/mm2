--[[
    Proton Mini - Menu Secundário com Coin Farm + Fly + Speed
    Proporção: 300x350
]]

-- Serviços
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- ======================
-- VARIÁVEIS
-- ======================
local Mini = {
    Open = true,
    SelectedTab = "Main",
    GUI = {},
    Options = {
        CoinFarm = false,
        XRay = false,
        KillAll = false,
        KillAura = false,
        FarmSpeed = 50
    },
    Connections = {},
    XRayObjects = {},
    FarmTarget = nil,
    CurrentSpeed = 50
}

-- ======================
-- NOTIFICAÇÃO
-- ======================
function Mini:Notify(text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Proton Mini",
            Text = text,
            Duration = 2
        })
    end)
    print("[Proton Mini]", text)
end

-- ======================
-- ANTI-CHEAT BYPASS
-- ======================
local function BypassAntiCheat()
    pcall(function()
        local antiCheat = game:FindFirstChild("AntiCheat")
        if antiCheat then antiCheat:Destroy() end
    end)
end
BypassAntiCheat()

-- ======================
-- FUNÇÃO: GET TEAM
-- ======================
function Mini:GetTeam(player)
    local char = player.Character
    local bp = player:FindFirstChild("Backpack")
    if (bp and bp:FindFirstChild("Knife")) or (char and char:FindFirstChild("Knife")) then
        return "Murderer"
    elseif (bp and bp:FindFirstChild("Gun")) or (char and char:FindFirstChild("Gun")) then
        return "Sheriff"
    else
        return "Innocent"
    end
end

-- ======================
-- FUNÇÃO: APLICAR NOCLIP (ATRAVESSAR PAREDES)
-- ======================
local noclipActive = false
local noclipConnection = nil

function Mini:EnableNoclip(state)
    noclipActive = state
    if state then
        if noclipConnection then noclipConnection:Disconnect() end
        noclipConnection = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

-- ======================
-- FUNÇÃO: SETAR VELOCIDADE
-- ======================
function Mini:SetSpeed(speed)
    Mini.CurrentSpeed = math.clamp(speed, 16, 200)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = Mini.CurrentSpeed
    end
end

-- ======================
-- FUNÇÃO: VOAR ATÉ A MOEDA
-- ======================
function Mini:FlyToTarget(targetPosition)
    local char = LocalPlayer.Character
    if not char then return false end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChild("Humanoid")
    if not hrp or not humanoid then return false end
    
    -- Ativar noclip
    Mini:EnableNoclip(true)
    
    -- Definir velocidade
    humanoid.WalkSpeed = Mini.CurrentSpeed
    
    -- Calcular direção e distância
    local direction = (targetPosition - hrp.Position).Unit
    local distance = (hrp.Position - targetPosition).Magnitude
    
    -- Mover em direção ao alvo
    humanoid:MoveTo(targetPosition)
    
    -- Loop de movimento com noclip
    local timeout = tick() + 10
    local lastPos = hrp.Position
    local stuckCount = 0
    
    while distance > 3 and tick() < timeout do
        RunService.Heartbeat:Wait()
        
        -- Atualizar distância
        distance = (hrp.Position - targetPosition).Magnitude
        
        -- Verificar se está preso
        if (hrp.Position - lastPos).Magnitude < 0.5 then
            stuckCount = stuckCount + 1
            if stuckCount > 5 then
                -- Se estiver preso, tentar subir
                local newTarget = targetPosition + Vector3.new(0, 5, 0)
                humanoid:MoveTo(newTarget)
                stuckCount = 0
            end
        else
            stuckCount = 0
        end
        lastPos = hrp.Position
        
        -- Continuar movendo
        if distance > 3 then
            humanoid:MoveTo(targetPosition)
        end
    end
    
    -- Desativar noclip após chegar
    Mini:EnableNoclip(false)
    
    return distance <= 3
end

-- ======================
-- COIN FARM - COMPLETO
-- ======================
function Mini:FindNearestCoin()
    local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return nil end
    
    local nearest = nil
    local minDist = math.huge
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "Coin_Server" then
            local dist = (myHrp.Position - obj.Position).Magnitude
            if dist < minDist then
                minDist = dist
                nearest = obj
            end
        end
    end
    
    return nearest, minDist
end

function Mini:CollectCoin(coinPart)
    pcall(function()
        coinPart:Destroy()
        local parent = coinPart.Parent
        if parent then
            local visual = parent:FindFirstChild("CoinVisual")
            if visual then visual:Destroy() end
        end
        Mini:Notify("💰 Moeda coletada!")
        return true
    end)
    return false
end

function Mini:ToggleCoinFarm(state)
    Mini.Options.CoinFarm = state
    
    if state then
        if Mini.Connections.CoinFarm then Mini.Connections.CoinFarm:Disconnect() end
        
        Mini:Notify("💰 Coin Farm ativada - velocidade: " .. Mini.CurrentSpeed)
        
        -- Aplicar velocidade e noclip
        Mini:SetSpeed(Mini.CurrentSpeed)
        Mini:EnableNoclip(true)
        
        Mini.Connections.CoinFarm = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            
            local humanoid = char:FindFirstChild("Humanoid")
            if not humanoid then return end
            
            -- Manter velocidade
            if humanoid.WalkSpeed ~= Mini.CurrentSpeed then
                humanoid.WalkSpeed = Mini.CurrentSpeed
            end
            
            -- Encontrar moeda mais próxima
            local coin, dist = Mini:FindNearestCoin()
            if coin and dist then
                if dist > 5 then
                    -- Voar até a moeda
                    Mini:FlyToTarget(coin.Position)
                else
                    -- Coletar moeda
                    local collected = Mini:CollectCoin(coin)
                    if collected then
                        task.wait(0.1)
                    end
                end
            end
        end)
    else
        if Mini.Connections.CoinFarm then
            Mini.Connections.CoinFarm:Disconnect()
            Mini.Connections.CoinFarm = nil
        end
        -- Desativar noclip
        Mini:EnableNoclip(false)
        -- Resetar velocidade
        Mini:SetSpeed(16)
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid:MoveTo(Vector3.new(0, 0, 0))
        end
        Mini:Notify("💰 Coin Farm desativada")
    end
end

-- ======================
-- X-RAY
-- ======================
function Mini:ToggleXRay(state)
    Mini.Options.XRay = state
    
    for _, obj in pairs(Mini.XRayObjects) do
        if obj then obj:Destroy() end
    end
    Mini.XRayObjects = {}
    
    if state then
        Mini:Notify("👁️ X-Ray ativado")
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local highlight = Instance.new("Highlight")
                highlight.FillColor = Color3.fromRGB(255, 255, 0)
                highlight.FillTransparency = 0.3
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.OutlineTransparency = 0.2
                highlight.Adornee = player.Character
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Parent = player
                table.insert(Mini.XRayObjects, highlight)
            end
        end
    else
        Mini:Notify("👁️ X-Ray desativado")
    end
end

-- ======================
-- KILL AURA
-- ======================
function Mini:ToggleKillAura(state)
    Mini.Options.KillAura = state
    
    if state then
        if Mini.Connections.KillAura then Mini.Connections.KillAura:Disconnect() end
        
        Mini.Connections.KillAura = RunService.Heartbeat:Connect(function()
            local myTeam = Mini:GetTeam(LocalPlayer)
            if myTeam ~= "Murderer" then return end
            
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") then
                    local humanoid = player.Character.Humanoid
                    local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local targetHrp = player.Character:FindFirstChild("HumanoidRootPart")
                    
                    if myHrp and targetHrp then
                        local dist = (myHrp.Position - targetHrp.Position).Magnitude
                        if dist < 15 and humanoid.Health > 0 then
                            humanoid.Health = 0
                            Mini:Notify("⚔️ Matou " .. player.Name)
                        end
                    end
                end
            end
        end)
        Mini:Notify("⚔️ Kill Aura ativada")
    else
        if Mini.Connections.KillAura then
            Mini.Connections.KillAura:Disconnect()
            Mini.Connections.KillAura = nil
        end
        Mini:Notify("⚔️ Kill Aura desativada")
    end
end

-- ======================
-- KILL ALL
-- ======================
function Mini:KillAll()
    Mini:Notify("🔪 Matando todos...")
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") then
            local humanoid = player.Character.Humanoid
            if humanoid.Health > 0 then
                humanoid.Health = 0
            end
        end
    end
    Mini:Notify("✅ Todos mortos!")
end

-- ======================
-- TELEPORT
-- ======================
function Mini:TeleportToGun()
    Mini:Notify("🔫 Procurando arma...")
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Tool") and obj.Name:lower():find("gun") and obj:FindFirstChild("Handle") then
            local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if myHrp then
                myHrp.CFrame = obj.Handle.CFrame + Vector3.new(0, 2, 0)
                Mini:Notify("✅ Teleportado para arma!")
                return
            end
        end
    end
    Mini:Notify("❌ Arma não encontrada!")
end

function Mini:TeleportToMurder()
    Mini:Notify("🔪 Procurando Murderer...")
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local team = Mini:GetTeam(player)
            if team == "Murderer" and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if myHrp then
                    myHrp.CFrame = player.Character.HumanoidRootPart.CFrame + Vector3.new(0, 2, 0)
                    Mini:Notify("✅ Teleportado para Murderer: " .. player.Name)
                    return
                end
            end
        end
    end
    Mini:Notify("❌ Murderer não encontrado!")
end

function Mini:TeleportToSheriff()
    Mini:Notify("⭐ Procurando Sheriff...")
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local team = Mini:GetTeam(player)
            if team == "Sheriff" and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if myHrp then
                    myHrp.CFrame = player.Character.HumanoidRootPart.CFrame + Vector3.new(0, 2, 0)
                    Mini:Notify("✅ Teleportado para Sheriff: " .. player.Name)
                    return
                end
            end
        end
    end
    Mini:Notify("❌ Sheriff não encontrado!")
end

function Mini:TeleportToLobby()
    Mini:Notify("🏠 Teleportando para o lobby...")
    local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if myHrp then
        myHrp.CFrame = CFrame.new(0, 3, 0)
        Mini:Notify("✅ Teleportado para o centro!")
    else
        Mini:Notify("❌ Não foi possível teleportar!")
    end
end

-- ======================
-- CRIAR MENU
-- ======================
function Mini:CreateWindow()
    local gui = Instance.new("ScreenGui")
    gui.Name = "ProtonMini"
    gui.ResetOnSpawn = false
    gui.Parent = CoreGui
    self.GUI.ScreenGui = gui

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 300, 0, 380)
    main.Position = UDim2.new(0.5, -150, 0.5, -190)
    main.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Visible = true
    main.Parent = gui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)
    
    local stroke = Instance.new("UIStroke", main)
    stroke.Color = Color3.fromRGB(30, 58, 95)
    stroke.Thickness = 1.5
    self.GUI.Main = main

    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = main
    
    local title = Instance.new("TextLabel", titleBar)
    title.Size = UDim2.new(0, 60, 1, 0)
    title.Position = UDim2.new(0, 8, 0, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = "Proton"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left

    local miniLabel = Instance.new("TextLabel", titleBar)
    miniLabel.Size = UDim2.new(0, 30, 1, 0)
    miniLabel.Position = UDim2.new(0, 55, 0, 2)
    miniLabel.BackgroundTransparency = 1
    miniLabel.Font = Enum.Font.Gotham
    miniLabel.Text = "Mini"
    miniLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    miniLabel.TextSize = 10
    miniLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Botões de controle
    local minimizeBtn = Instance.new("TextButton", titleBar)
    minimizeBtn.Size = UDim2.new(0, 20, 0, 20)
    minimizeBtn.Position = UDim2.new(1, -44, 0.5, -10)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.Text = "−"
    minimizeBtn.TextColor3 = Color3.new(1, 1, 1)
    minimizeBtn.TextSize = 14
    Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 4)

    local closeBtn = Instance.new("TextButton", titleBar)
    closeBtn.Size = UDim2.new(0, 20, 0, 20)
    closeBtn.Position = UDim2.new(1, -22, 0.5, -10)
    closeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.TextSize = 14
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)
    closeBtn.MouseButton1Click:Connect(function() self.GUI.ScreenGui:Destroy() end)

    -- Minimizar
    local minimized = false
    local originalSize = main.Size
    minimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                Size = UDim2.new(0, 300, 0, 30)
            }):Play()
            self.GUI.Content.Visible = false
            for _, btn in pairs(self.GUI.TabButtons or {}) do
                btn.Visible = false
            end
            minimizeBtn.Text = "+"
        else
            TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                Size = originalSize
            }):Play()
            self.GUI.Content.Visible = true
            for _, btn in pairs(self.GUI.TabButtons or {}) do
                btn.Visible = true
            end
            minimizeBtn.Text = "−"
        end
    end)

    -- Tabs
    local tabs = {"Main", "Player", "Teleport"}
    local tabBtns = {}
    
    for i, name in pairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(0, 90, 0, 24)
        btn.Position = UDim2.new(0, 5 + ((i-1) * 95), 0, 35)
        btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        btn.Font = Enum.Font.Gotham
        btn.Text = name
        btn.TextColor3 = Color3.new(0.8, 0.8, 0.8)
        btn.TextSize = 11
        btn.Parent = main
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        
        btn.MouseButton1Click:Connect(function()
            Mini.SelectedTab = name
            for _, b in pairs(tabBtns) do 
                b.BackgroundColor3 = Color3.fromRGB(20, 20, 20) 
            end
            btn.BackgroundColor3 = Color3.fromRGB(30, 58, 95)
            Mini:LoadTab(name)
        end)
        
        table.insert(tabBtns, btn)
    end
    tabBtns[1].BackgroundColor3 = Color3.fromRGB(30, 58, 95)
    self.GUI.TabButtons = tabBtns

    -- Content
    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1, -10, 1, -75)
    content.Position = UDim2.new(0, 5, 0, 70)
    content.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 3
    content.ScrollBarImageColor3 = Color3.fromRGB(30, 58, 95)
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.Parent = main
    Instance.new("UICorner", content).CornerRadius = UDim.new(0, 4)
    self.GUI.Content = content

    -- Dragging
    local dragging, dragStart, startPos
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    Mini:LoadTab("Main")
    Mini:Notify("Proton Mini aberto!")
end

-- ======================
-- CARREGAR TAB
-- ======================
function Mini:LoadTab(name)
    local content = self.GUI.Content
    for _, child in pairs(content:GetChildren()) do
        child:Destroy()
    end
    
    local y = 5
    local function addToggle(text, option, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 25)
        frame.Position = UDim2.new(0, 5, 0, y)
        frame.BackgroundTransparency = 1
        frame.Parent = content

        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(1, -40, 1, 0)
        label.Font = Enum.Font.Gotham
        label.Text = text
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.BackgroundTransparency = 1

        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.new(0, 30, 0, 16)
        btn.Position = UDim2.new(1, -30, 0.5, -8)
        btn.BackgroundColor3 = option and Color3.fromRGB(30, 58, 95) or Color3.fromRGB(60, 60, 60)
        btn.Text = ""
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

        local knob = Instance.new("Frame", btn)
        knob.Size = UDim2.new(0, 12, 0, 12)
        knob.Position = option and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
        knob.BackgroundColor3 = Color3.new(1, 1, 1)
        Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 6)

        local state = option
        btn.MouseButton1Click:Connect(function()
            state = not state
            callback(state)
            btn.BackgroundColor3 = state and Color3.fromRGB(30, 58, 95) or Color3.fromRGB(60, 60, 60)
            knob.Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
        end)

        y = y + 28
        return frame
    end
    
    local function addSlider(text, min, max, value, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 45)
        frame.Position = UDim2.new(0, 5, 0, y)
        frame.BackgroundTransparency = 1
        frame.Parent = content

        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(1, 0, 0, 18)
        label.Font = Enum.Font.Gotham
        label.Text = text .. ": " .. value
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextSize = 12
        label.BackgroundTransparency = 1

        local bar = Instance.new("Frame", frame)
        bar.Size = UDim2.new(1, 0, 0, 6)
        bar.Position = UDim2.new(0, 0, 0, 22)
        bar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 3)

        local fill = Instance.new("Frame", bar)
        fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(30, 58, 95)
        Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 3)

        local thumb = Instance.new("TextButton", bar)
        thumb.Size = UDim2.new(0, 14, 0, 14)
        thumb.Position = UDim2.new((value - min) / (max - min), -7, 0.5, -7)
        thumb.BackgroundColor3 = Color3.new(1, 1, 1)
        thumb.Text = ""
        Instance.new("UICorner", thumb).CornerRadius = UDim.new(0, 7)

        local dragging = false
        local currentValue = value
        
        local function update(input)
            local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + (max - min) * rel)
            currentValue = val
            fill.Size = UDim2.new(rel, 0, 1, 0)
            thumb.Position = UDim2.new(rel, -7, 0.5, -7)
            label.Text = text .. ": " .. val
            if callback then callback(val) end
        end

        thumb.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging = true
            end
        end)
        thumb.InputEnded:Connect(function() dragging = false end)
        bar.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                update(i)
            end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                update(i)
            end
        end)

        y = y + 48
        return frame
    end
    
    local function addButton(text, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 28)
        btn.Position = UDim2.new(0, 5, 0, y)
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        btn.Font = Enum.Font.Gotham
        btn.Text = text
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.TextSize = 12
        btn.Parent = content
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        
        btn.MouseButton1Click:Connect(function()
            if callback then pcall(callback) end
        end)
        
        y = y + 32
        return btn
    end
    
    local function addLabel(text, color)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -10, 0, 20)
        label.Position = UDim2.new(0, 5, 0, y)
        label.Font = Enum.Font.Gotham
        label.Text = text
        label.TextColor3 = color or Color3.new(1, 1, 1)
        label.TextSize = 12
        label.BackgroundTransparency = 1
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = content
        y = y + 22
        return label
    end

    if name == "Main" then
        addToggle("💰 Coin Farm", Mini.Options.CoinFarm, function(v)
            Mini:ToggleCoinFarm(v)
        end)
        
        -- Slider de velocidade
        addSlider("🚀 Speed", 16, 200, Mini.CurrentSpeed, function(v)
            Mini.CurrentSpeed = v
            if Mini.Options.CoinFarm then
                Mini:SetSpeed(v)
                Mini:Notify("🚀 Velocidade: " .. v)
            end
        end)
        
        addToggle("👁️ X-Ray", Mini.Options.XRay, function(v)
            Mini:ToggleXRay(v)
        end)
        
        addButton("🔪 Kill All (Murder)", function()
            Mini:KillAll()
        end)
        
        addToggle("⚔️ Kill Aura", Mini.Options.KillAura, function(v)
            Mini:ToggleKillAura(v)
        end)
        
    elseif name == "Player" then
        local avatarFrame = Instance.new("Frame")
        avatarFrame.Size = UDim2.new(1, -10, 0, 55)
        avatarFrame.Position = UDim2.new(0, 5, 0, y)
        avatarFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        avatarFrame.BackgroundTransparency = 0
        avatarFrame.Parent = content
        Instance.new("UICorner", avatarFrame).CornerRadius = UDim.new(0, 4)
        y = y + 60
        
        local avatar = Instance.new("ImageLabel", avatarFrame)
        avatar.Size = UDim2.new(0, 45, 0, 45)
        avatar.Position = UDim2.new(0, 5, 0.5, -22.5)
        avatar.BackgroundTransparency = 1
        
        local success, thumb = pcall(function()
            return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
        end)
        if success and thumb then
            avatar.Image = thumb
        end
        
        local nameLabel = Instance.new("TextLabel", avatarFrame)
        nameLabel.Size = UDim2.new(1, -65, 0, 20)
        nameLabel.Position = UDim2.new(0, 55, 0, 5)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.Text = LocalPlayer.Name
        nameLabel.TextColor3 = Color3.new(1, 1, 1)
        nameLabel.TextSize = 13
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        addLabel("👤 Time: " .. Mini:GetTeam(LocalPlayer), Color3.fromRGB(200, 200, 200))
        
        local fpsLabel = addLabel("🎮 FPS: 0", Color3.fromRGB(200, 200, 200))
        
        if Mini.Connections.FPS then Mini.Connections.FPS:Disconnect() end
        Mini.Connections.FPS = RunService.Heartbeat:Connect(function()
            if fpsLabel and fpsLabel.Parent then
                local fps = math.floor(1 / RunService.Heartbeat:Wait())
                fpsLabel.Text = "🎮 FPS: " .. fps
            end
        end)
        
    elseif name == "Teleport" then
        addButton("🔫 Teleport Gun", function()
            Mini:TeleportToGun()
        end)
        
        addButton("🔪 Teleport Murder", function()
            Mini:TeleportToMurder()
        end)
        
        addButton("⭐ Teleport Sheriff", function()
            Mini:TeleportToSheriff()
        end)
        
        addButton("🏠 Teleport Lobby", function()
            Mini:TeleportToLobby()
        end)
    end
    
    content.CanvasSize = UDim2.new(0, 0, 0, y + 20)
end

-- ======================
-- INICIAR
-- ======================
Mini:CreateWindow()
print("[Proton Mini] Carregado e aberto! (300x380)")
return Mini