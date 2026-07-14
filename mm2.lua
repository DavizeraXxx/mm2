--[[
    Proton Menu - Murder Mystery 2
    Versão Final - 100% Funcional
    ESP Box + Skeleton + Aimbot + Teleport + Logs + Noclip
--]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Proton Menu Table
local Proton = {
    Open = true,
    SelectedTab = "Aimbot",
    Options = {
        Aimbot = false,
        AimbotFOV = 100,
        ShowFOV = true,
        ESPEnabled = true,
        ESPBox = true,
        ESPSkeleton = false,
        ESPName = true,
        ESPDistance = true,
        Noclip = false,
        ESPGun = false,
    },
    FOVCircle = nil,
    ESPLines = {},
    ESPTexts = {},
}

-- Notify
function Proton:Notify(title, text, duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 3
        })
    end)
end

-- Tween
local function tween(obj, props, dur)
    local info = TweenInfo.new(dur or 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local t = TweenService:Create(obj, info, props)
    t:Play()
end

-- Get Player Team
function Proton:GetTeam(player)
    local char = player.Character
    local bp = player:FindFirstChild("Backpack")
    
    if (bp and bp:FindFirstChild("Knife")) or (char and char:FindFirstChild("Knife")) then
        return "Murderer", Color3.fromRGB(255, 50, 50)
    elseif (bp and bp:FindFirstChild("Gun")) or (char and char:FindFirstChild("Gun")) then
        return "Sheriff", Color3.fromRGB(50, 100, 255)
    else
        return "Innocent", Color3.fromRGB(50, 255, 50)
    end
end

-- ESP Functions
function Proton:GetCorners(part)
    local cf, sz = part.CFrame, part.Size / 2
    local c = {}
    for x = -1, 1, 2 do
        for y = -1, 1, 2 do
            for z = -1, 1, 2 do
                c[#c + 1] = (cf * CFrame.new(sz * Vector3.new(x, y, z))).Position
            end
        end
    end
    return c
end

function Proton:DrawLine(from, to, color)
    local fs, fv = Camera:WorldToViewportPoint(from)
    local ts, tv = Camera:WorldToViewportPoint(to)
    if not fv and not tv then return end
    
    local line = Drawing.new("Line")
    line.Thickness = 1.5
    line.From = Vector2.new(fs.X, fs.Y)
    line.To = Vector2.new(ts.X, ts.Y)
    line.Color = color
    line.Transparency = 1
    line.Visible = true
    table.insert(self.ESPLines, line)
end

function Proton:DrawText(pos, text, color, size)
    local sp, ov = Camera:WorldToViewportPoint(pos)
    if not ov then return end
    
    local txt = Drawing.new("Text")
    txt.Position = Vector2.new(sp.X, sp.Y)
    txt.Text = text
    txt.Color = color
    txt.Size = size or 14
    txt.Center = true
    txt.Outline = true
    txt.Visible = true
    table.insert(self.ESPTexts, txt)
end

function Proton:DrawBox(player, color)
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local corners = self:GetCorners({CFrame = hrp.CFrame * CFrame.new(0, -0.5, 0), Size = Vector3.new(3, 5, 3)})
    local edges = {{1,2},{2,6},{6,5},{5,1},{1,3},{2,4},{6,8},{5,7},{3,4},{4,8},{8,7},{7,3}}
    
    for _, e in pairs(edges) do
        self:DrawLine(corners[e[1]], corners[e[2]], color)
    end
end

function Proton:DrawSkeleton(player, color)
    local char = player.Character
    if not char then return end
    
    local bones = {
        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
        {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
    }
    
    for _, b in pairs(bones) do
        local p1 = char:FindFirstChild(b[1])
        local p2 = char:FindFirstChild(b[2])
        if p1 and p2 then
            self:DrawLine(p1.Position, p2.Position, color)
        end
    end
end

function Proton:UpdateESP()
    -- Clear
    for _, l in pairs(self.ESPLines) do if l then l:Remove() end end
    for _, t in pairs(self.ESPTexts) do if t then t:Remove() end end
    self.ESPLines = {}
    self.ESPTexts = {}
    
    if not self.Options.ESPEnabled then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local head = player.Character:FindFirstChild("Head")
            if not hrp or not head then continue end
            
            local teamName, teamColor = self:GetTeam(player)
            local dist = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and math.floor((LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude) or 0
            
            if self.Options.ESPBox then
                self:DrawBox(player, teamColor)
            end
            
            if self.Options.ESPSkeleton then
                self:DrawSkeleton(player, teamColor)
            end
            
            if self.Options.ESPName then
                self:DrawText(head.Position + Vector3.new(0, 1.5, 0), player.Name, Color3.new(1,1,1), 16)
            end
            
            if self.Options.ESPDistance then
                self:DrawText(head.Position + Vector3.new(0, 1.1, 0), "[" .. dist .. "m]", Color3.new(1,1,1), 14)
            end
        end
    end
end

-- Aimbot
function Proton:GetClosestMurderer()
    local closest = nil
    local minDist = self.Options.AimbotFOV
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local teamName, _ = self:GetTeam(player)
            if teamName == "Murderer" then
                local head = player.Character.Head
                local sp, ov = Camera:WorldToViewportPoint(head.Position)
                if ov then
                    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d < minDist then
                        minDist = d
                        closest = player
                    end
                end
            end
        end
    end
    
    return closest
end

function Proton:UpdateFOV()
    if self.Options.Aimbot and self.Options.ShowFOV then
        if not self.FOVCircle then
            local c = Drawing.new("Circle")
            c.Color = Color3.fromRGB(30, 58, 95)
            c.Thickness = 1.5
            c.Transparency = 0.7
            c.Filled = false
            c.Radius = self.Options.AimbotFOV
            c.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            c.Visible = true
            self.FOVCircle = c
        else
            self.FOVCircle.Radius = self.Options.AimbotFOV
            self.FOVCircle.Visible = true
        end
    else
        if self.FOVCircle then
            self.FOVCircle.Visible = false
        end
    end
end

-- Teleport
function Proton:TeleportToGun()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Tool") and obj.Name:lower():find("gun") and obj:FindFirstChild("Handle") then
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = obj.Handle.CFrame + Vector3.new(0, 3, 0)
                self:Notify("Teleport", "Arma encontrada!", 2)
                return
            end
        end
    end
    self:Notify("Erro", "Arma não encontrada!", 2)
end

function Proton:CopyLogs()
    local s, m = "Nenhum", "Nenhum"
    for _, p in pairs(Players:GetPlayers()) do
        local t, _ = self:GetTeam(p)
        if t == "Sheriff" then s = p.Name
        elseif t == "Murderer" then m = p.Name end
    end
    
    local log = "Sheriff: " .. s .. " | Murderer: " .. m
    pcall(setclipboard, log)
    pcall(function() syn.write_clipboard(log) end)
    self:Notify("Logs", "Copiado: " .. log, 3)
end

-- Create GUI
function Proton:CreateWindow()
    -- ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "ProtonMenu"
    gui.Parent = CoreGui
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Main
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 550, 0, 350)
    main.Position = UDim2.new(0.5, -275, 0.5, -175)
    main.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Parent = gui
    
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)
    
    local stroke = Instance.new("UIStroke", main)
    stroke.Color = Color3.fromRGB(30, 58, 95)
    stroke.Thickness = 1.5
    
    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = main
    
    local title = Instance.new("TextLabel", titleBar)
    title.Size = UDim2.new(0, 150, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = "Proton Menu"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextSize = 15
    title.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Close
    local close = Instance.new("TextButton", titleBar)
    close.Size = UDim2.new(0, 26, 0, 26)
    close.Position = UDim2.new(1, -30, 0, 2)
    close.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    close.Font = Enum.Font.GothamBold
    close.Text = "×"
    close.TextColor3 = Color3.new(1, 1, 1)
    close.TextSize = 16
    Instance.new("UICorner", close).CornerRadius = UDim.new(0, 4)
    
    close.MouseButton1Click:Connect(function()
        gui:Destroy()
        if Proton.FOVCircle then Proton.FOVCircle:Remove() end
    end)
    
    -- Tabs
    local tabs = {"Aimbot", "ESP", "Teleport", "Logs", "Misc"}
    local tabBtns = {}
    
    for i, name in pairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(0, 90, 0, 26)
        btn.Position = UDim2.new(0, 10 + ((i-1) * 95), 0, 35)
        btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        btn.Font = Enum.Font.Gotham
        btn.Text = name
        btn.TextColor3 = Color3.new(0.8, 0.8, 0.8)
        btn.TextSize = 13
        btn.Parent = main
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        
        btn.MouseButton1Click:Connect(function()
            Proton.SelectedTab = name
            for _, b in pairs(tabBtns) do b.BackgroundColor3 = Color3.fromRGB(20, 20, 20) end
            btn.BackgroundColor3 = Color3.fromRGB(30, 58, 95)
            Proton:LoadTab(name)
        end)
        
        table.insert(tabBtns, btn)
    end
    
    tabBtns[1].BackgroundColor3 = Color3.fromRGB(30, 58, 95)
    
    -- Content
    local content = Instance.new("ScrollingFrame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -20, 1, -75)
    content.Position = UDim2.new(0, 10, 0, 70)
    content.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 4
    content.ScrollBarImageColor3 = Color3.fromRGB(30, 58, 95)
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.Parent = main
    Instance.new("UICorner", content).CornerRadius = UDim.new(0, 4)
    
    self.GUI = {ScreenGui = gui, Main = main, Content = content}
    
    -- Dragging
    local dragging, dragStart, startPos
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    -- Load first tab
    Proton:LoadTab("Aimbot")
end

-- Load Tab Content
function Proton:LoadTab(name)
    local content = self.GUI.Content
    for _, c in pairs(content:GetChildren()) do c:Destroy() end
    
    local y = 10
    
    -- Helper functions
    local function AddToggle(text, option, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -20, 0, 30)
        frame.Position = UDim2.new(0, 10, 0, y)
        frame.BackgroundTransparency = 1
        frame.Parent = content
        
        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(1, -50, 1, 0)
        label.Font = Enum.Font.Gotham
        label.Text = text
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextSize = 14
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.BackgroundTransparency = 1
        
        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.new(0, 40, 0, 20)
        btn.Position = UDim2.new(1, -40, 0.5, -10)
        btn.BackgroundColor3 = option and Color3.fromRGB(30, 58, 95) or Color3.fromRGB(60, 60, 60)
        btn.Text = ""
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
        
        local knob = Instance.new("Frame", btn)
        knob.Size = UDim2.new(0, 16, 0, 16)
        knob.Position = option and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        knob.BackgroundColor3 = Color3.new(1, 1, 1)
        Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 8)
        
        local state = option
        btn.MouseButton1Click:Connect(function()
            state = not state
            callback(state)
            local c = state and Color3.fromRGB(30, 58, 95) or Color3.fromRGB(60, 60, 60)
            local p = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            tween(btn, {BackgroundColor3 = c}, 0.2)
            tween(knob, {Position = p}, 0.2)
        end)
        
        y = y + 35
    end
    
    local function AddSlider(text, min, max, value, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -20, 0, 50)
        frame.Position = UDim2.new(0, 10, 0, y)
        frame.BackgroundTransparency = 1
        frame.Parent = content
        
        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(1, 0, 0, 20)
        label.Font = Enum.Font.Gotham
        label.Text = text .. ": " .. value
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextSize = 14
        label.BackgroundTransparency = 1
        
        local bar = Instance.new("Frame", frame)
        bar.Size = UDim2.new(1, 0, 0, 8)
        bar.Position = UDim2.new(0, 0, 0, 25)
        bar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 4)
        
        local fill = Instance.new("Frame", bar)
        fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(30, 58, 95)
        Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)
        
        local thumb = Instance.new("TextButton", bar)
        thumb.Size = UDim2.new(0, 16, 0, 16)
        thumb.Position = UDim2.new((value - min) / (max - min), -8, 0.5, -8)
        thumb.BackgroundColor3 = Color3.new(1, 1, 1)
        thumb.Text = ""
        Instance.new("UICorner", thumb).CornerRadius = UDim.new(0, 8)
        
        local dragging = false
        local function update(input)
            local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + (max - min) * rel)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            thumb.Position = UDim2.new(rel, -8, 0.5, -8)
            label.Text = text .. ": " .. val
            callback(val)
        end
        
        thumb.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true end end)
        bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true update(i) end end)
        UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
        UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then update(i) end end)
        
        y = y + 55
    end
    
    local function AddButton(text, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -20, 0, 32)
        btn.Position = UDim2.new(0, 10, 0, y)
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        btn.Font = Enum.Font.Gotham
        btn.Text = text
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.TextSize = 14
        btn.Parent = content
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        
        btn.MouseButton1Click:Connect(function()
            pcall(callback)
        end)
        
        y = y + 40
    end
    
    -- Tab content
    if name == "Aimbot" then
        AddToggle("Aimbot", Proton.Options.Aimbot, function(v) Proton.Options.Aimbot = v Proton:UpdateFOV() end)
        AddSlider("FOV", 50, 300, Proton.Options.AimbotFOV, function(v) Proton.Options.AimbotFOV = v Proton:UpdateFOV() end)
        AddToggle("Show FOV Circle", Proton.Options.ShowFOV, function(v) Proton.Options.ShowFOV = v Proton:UpdateFOV() end)
        
    elseif name == "ESP" then
        AddToggle("Enable ESP", Proton.Options.ESPEnabled, function(v) Proton.Options.ESPEnabled = v end)
        AddToggle("Box ESP", Proton.Options.ESPBox, function(v) Proton.Options.ESPBox = v end)
        AddToggle("Skeleton ESP", Proton.Options.ESPSkeleton, function(v) Proton.Options.ESPSkeleton = v end)
        AddToggle("Show Name", Proton.Options.ESPName, function(v) Proton.Options.ESPName = v end)
        AddToggle("Show Distance", Proton.Options.ESPDistance, function(v) Proton.Options.ESPDistance = v end)
        content.CanvasSize = UDim2.new(0, 0, 0, y + 20)
        
    elseif name == "Teleport" then
        AddButton("Teleport to Gun", function() Proton:TeleportToGun() end)
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local teamName, teamColor = Proton:GetTeam(player)
                AddButton(player.Name .. " [" .. teamName .. "]", function()
                    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame + Vector3.new(0, 2, 0)
                        Proton:Notify("Teleport", "Teleportado para " .. player.Name, 2)
                    end
                end)
            end
        end
        content.CanvasSize = UDim2.new(0, 0, 0, y + 20)
        
    elseif name == "Logs" then
        AddButton("Copy Team Logs", function() Proton:CopyLogs() end)
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local teamName, teamColor = Proton:GetTeam(player)
                local infoLabel = Instance.new("TextLabel")
                infoLabel.Size = UDim2.new(1, -20, 0, 25)
                infoLabel.Position = UDim2.new(0, 10, 0, y)
                infoLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                infoLabel.Font = Enum.Font.Gotham
                infoLabel.Text = "  " .. player.Name .. " - " .. teamName
                infoLabel.TextColor3 = teamColor
                infoLabel.TextSize = 14
                infoLabel.TextXAlignment = Enum.TextXAlignment.Left
                infoLabel.Parent = content
                Instance.new("UICorner", infoLabel).CornerRadius = UDim.new(0, 4)
                y = y + 30
            end
        end
        content.CanvasSize = UDim2.new(0, 0, 0, y + 20)
        
    elseif name == "Misc" then
        AddToggle("Noclip", Proton.Options.Noclip, function(v) Proton.Options.Noclip = v end)
        AddToggle("ESP Gun (Dropped)", Proton.Options.ESPGun, function(v) Proton.Options.ESPGun = v end)
    end
end

-- Initialize
Proton:CreateWindow()
Proton:Notify("Proton Menu", "Carregado com sucesso!", 3)

-- ESP Render Loop
RunService.RenderStepped:Connect(function()
    Proton:UpdateESP()
end)

-- FOV Circle Update
RunService.RenderStepped:Connect(function()
    if Proton.FOVCircle then
        Proton.FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    end
end)

-- Noclip
RunService.Stepped:Connect(function()
    if Proton.Options.Noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Gun ESP
RunService.Heartbeat:Connect(function()
    if Proton.Options.ESPGun then
        for _, obj in pairs(workspace:GetChildren()) do
            if obj:IsA("Tool") and obj.Name:lower():find("gun") and not obj:FindFirstChild("ProtonGunESP") then
                local h = Instance.new("Highlight", obj)
                h.Name = "ProtonGunESP"
                h.FillColor = Color3.fromRGB(255, 255, 0)
                h.FillTransparency = 0.3
                h.Adornee = obj
            end
        end
    end
end)

-- Aimbot (Silent Aim)
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    
    if method == "FireServer" and Proton.Options.Aimbot then
        local target = Proton:GetClosestMurderer()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            for i, arg in pairs(args) do
                if typeof(arg) == "Vector3" then
                    args[i] = target.Character.Head.Position
                    break
                end
            end
        end
    end
    
    return oldNamecall(self, unpack(args))
end

setreadonly(mt, true)

return Proton