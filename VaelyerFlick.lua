local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera
local Lighting = game:GetService("Lighting")

local Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/farehamhz/RedzLib/main/RedzLib'))()
local Window = Library:MakeWindow({
    Title = 'SmithSC Project',
    SubTitle = 'By Archaes `78',
    SaveFolder = 'SmithSC Project',
})
local Tab = Window:MakeTab({
    Name = 'Features',
    Icon = 'rbxassetid://4483345998',
    PremiumOnly = false
})

local Config = {
    AIMBOT_ESP = false,
    SPEEDHACK = false,
    PING_FPS_UI = false,
    ZERO_RECOIL = false,
    BOOST_FPS = false,
    SpeedValue = 55,
    OriginalWalkSpeed = 16
}

local currentTarget = nil
local ESPConnections = {}
local PingUIGui = nil
local speedLoopConnection = nil
local originalBulletFire = nil

local boostData = {
    originalShadows = nil,
    originalAmbient = nil,
    originalAtmosphere = nil,
    originalBloom = nil,
    originalColorCorrection = nil,
    particleEmitters = {},
    decals = {},
    beams = {},
    trails = {}
}

local function collectOptimizableObjects()
    boostData.particleEmitters = {}
    boostData.decals = {}
    boostData.beams = {}
    boostData.trails = {}
    local function scan(instance)
        for _, child in ipairs(instance:GetChildren()) do
            if child:IsA("ParticleEmitter") then
                table.insert(boostData.particleEmitters, child)
            elseif child:IsA("Decal") then
                table.insert(boostData.decals, child)
            elseif child:IsA("Beam") then
                table.insert(boostData.beams, child)
            elseif child:IsA("Trail") then
                table.insert(boostData.trails, child)
            end
            scan(child)
        end
    end
    scan(workspace)
    scan(Lighting)
    scan(game:GetService("ReplicatedStorage"))
end

local function enableBoostFPS()
    if boostData.originalShadows == nil then
        boostData.originalShadows = Lighting.Shadows
        boostData.originalAmbient = Lighting.Ambient
        if Lighting.Atmosphere then boostData.originalAtmosphere = Lighting.Atmosphere.Enabled end
        if Lighting.Bloom then boostData.originalBloom = Lighting.Bloom.Enabled end
        if Lighting.ColorCorrection then boostData.originalColorCorrection = Lighting.ColorCorrection.Enabled end
    end
    Lighting.Shadows = false
    Lighting.Ambient = Color3.fromRGB(100, 100, 100)
    if Lighting.Atmosphere then Lighting.Atmosphere.Enabled = false end
    if Lighting.Bloom then Lighting.Bloom.Enabled = false end
    if Lighting.ColorCorrection then Lighting.ColorCorrection.Enabled = false end
    for _, emitter in ipairs(boostData.particleEmitters) do emitter.Enabled = false end
    for _, decal in ipairs(boostData.decals) do decal.Visible = false end
    for _, beam in ipairs(boostData.beams) do beam.Enabled = false end
    for _, trail in ipairs(boostData.trails) do trail.Enabled = false end
    pcall(function() if Camera.MaxRenderDistance then Camera.MaxRenderDistance = 500 end end)
end

local function disableBoostFPS()
    Lighting.Shadows = boostData.originalShadows
    Lighting.Ambient = boostData.originalAmbient
    if Lighting.Atmosphere and boostData.originalAtmosphere ~= nil then Lighting.Atmosphere.Enabled = boostData.originalAtmosphere end
    if Lighting.Bloom and boostData.originalBloom ~= nil then Lighting.Bloom.Enabled = boostData.originalBloom end
    if Lighting.ColorCorrection and boostData.originalColorCorrection ~= nil then Lighting.ColorCorrection.Enabled = boostData.originalColorCorrection end
    for _, emitter in ipairs(boostData.particleEmitters) do emitter.Enabled = true end
    for _, decal in ipairs(boostData.decals) do decal.Visible = true end
    for _, beam in ipairs(boostData.beams) do beam.Enabled = true end
    for _, trail in ipairs(boostData.trails) do trail.Enabled = true end
    pcall(function() if Camera.MaxRenderDistance then Camera.MaxRenderDistance = 1000 end end)
end

local function applyBoostFPS()
    if Config.BOOST_FPS then enableBoostFPS() else disableBoostFPS() end
end

spawn(function()
    wait(2)
    collectOptimizableObjects()
    if Config.BOOST_FPS then applyBoostFPS() end
end)

local function getLocalHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("Humanoid")
end

local function getLocalHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function saveOriginalSpeed()
    local hum = getLocalHumanoid()
    if hum and hum.WalkSpeed > 0 then Config.OriginalWalkSpeed = hum.WalkSpeed end
end

local function maintainSpeedLoop()
    if speedLoopConnection then speedLoopConnection:Disconnect() speedLoopConnection = nil end
    if not Config.SPEEDHACK then return end
    speedLoopConnection = RunService.Heartbeat:Connect(function()
        local hum = getLocalHumanoid()
        if hum then
            if hum.WalkSpeed ~= Config.SpeedValue then hum.WalkSpeed = Config.SpeedValue end
            local hrp = getLocalHRP()
            if hrp and hrp.AssemblyLinearVelocity.Magnitude < 0.1 and hum.MoveDirection.Magnitude > 0 then
                hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity + (hum.MoveDirection * 5)
            end
        end
    end)
end

local function applySpeedHack()
    local hum = getLocalHumanoid()
    if not hum then return end
    if Config.SPEEDHACK then
        saveOriginalSpeed()
        hum.WalkSpeed = Config.SpeedValue
        maintainSpeedLoop()
    else
        if speedLoopConnection then speedLoopConnection:Disconnect() speedLoopConnection = nil end
        hum.WalkSpeed = Config.OriginalWalkSpeed
        local hrp = getLocalHRP()
        if hrp then hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0) end
    end
end

local function watchSpeedReset()
    local hum = getLocalHumanoid()
    if not hum then return end
    hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if Config.SPEEDHACK and hum.WalkSpeed ~= Config.SpeedValue then
            hum.WalkSpeed = Config.SpeedValue
        end
    end)
end

local function onCharacterAdded()
    wait(0.5)
    saveOriginalSpeed()
    applySpeedHack()
    watchSpeedReset()
end

if LocalPlayer.Character then onCharacterAdded() else LocalPlayer.CharacterAdded:Connect(onCharacterAdded) end
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

local function isAlive(h)
    return h and h.Health > 0
end

local function isVisible(pos, character)
    local localChar = LocalPlayer.Character
    if not localChar then return false end
    local origin = Camera.CFrame.Position
    local direction = pos - origin
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {localChar, character}
    params.FilterType = Enum.RaycastFilterType.Blacklist
    local result = workspace:Raycast(origin, direction, params)
    return result == nil
end

local function getTarget()
    local best = nil
    local bestScore = math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local head = player.Character:FindFirstChild("Head")
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if head and humanoid and isAlive(humanoid) then
                local dist3D = (head.Position - Camera.CFrame.Position).Magnitude
                if dist3D <= 350 then
                    local visible = isVisible(head.Position, player.Character)
                    local skip = (not visible and dist3D > 90)
                    if not skip then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                        if onScreen then
                            local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                            local dist2D = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                            if dist2D <= 90 then
                                local score = dist2D + (dist3D * 0.04)
                                if visible and dist3D <= 120 then score = dist2D * 0.1 end
                                if not visible then score = score + 150 end
                                if score < bestScore then bestScore = score best = player end
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

local function getClosestHeadForZeroRecoil()
    if not Camera then return nil end
    local closestHead = nil
    local shortestDistance = 500
    local viewportSize = Camera.ViewportSize
    if not viewportSize then return nil end
    local screenCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                local head = char:FindFirstChild("Head")
                if humanoid and head and humanoid.Health > 0 then
                    local screenPosition, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local targetPos2D = Vector2.new(screenPosition.X, screenPosition.Y)
                        local distance = (targetPos2D - screenCenter).Magnitude
                        if distance < shortestDistance then shortestDistance = distance closestHead = head end
                    end
                end
            end
        end
    end
    return closestHead
end

local function setupZeroRecoil()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local bulletHandler = nil
    local replicatedStorageModules = ReplicatedStorage:FindFirstChild("ModuleScripts")
    if replicatedStorageModules then
        local gunModules = replicatedStorageModules:FindFirstChild("GunModules")
        if gunModules then
            local foundHandler = gunModules:FindFirstChild("BulletHandler")
            if foundHandler then bulletHandler = require(foundHandler) end
        end
    end
    if not bulletHandler and type(getloadedmodules) == "function" then
        for _, mod in ipairs(getloadedmodules()) do
            if mod.Name == "BulletHandler" then bulletHandler = require(mod) break end
        end
    end
    if bulletHandler and type(bulletHandler.Fire) == "function" and not originalBulletFire then
        originalBulletFire = bulletHandler.Fire
        bulletHandler.Fire = function(p6)
            if Config.ZERO_RECOIL and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health > 0 then
                if type(p6) == "table" and p6.Origin and p6.Direction then
                    local targetHead = getClosestHeadForZeroRecoil()
                    if targetHead then
                        local newDirection = (targetHead.Position - p6.Origin).Unit
                        if newDirection.X == newDirection.X then p6.Direction = newDirection end
                    end
                end
            end
            return originalBulletFire(p6)
        end
    end
end

local function setupPingUI()
    if PingUIGui then PingUIGui:Destroy() PingUIGui = nil end
    if not Config.PING_FPS_UI then return end
    pcall(function()
        local existing = CoreGui:FindFirstChild("VaelyerPingUI")
        if existing then existing:Destroy() end
        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "VaelyerPingUI"
        ScreenGui.ResetOnSpawn = false
        ScreenGui.Parent = CoreGui
        PingUIGui = ScreenGui
        local MainFrame = Instance.new("Frame")
        MainFrame.Size = UDim2.new(0,220,0,55)
        MainFrame.Position = UDim2.new(0.02,0,0.15,0)
        MainFrame.BackgroundColor3 = Color3.fromRGB(15,15,15)
        MainFrame.BackgroundTransparency = 0.15
        MainFrame.BorderSizePixel = 0
        MainFrame.Active = true
        MainFrame.Parent = ScreenGui
        Instance.new("UICorner",MainFrame).CornerRadius = UDim.new(0,10)
        local InfoText = Instance.new("TextLabel")
        InfoText.Size = UDim2.new(1,0,0.55,0)
        InfoText.Position = UDim2.new(0,5,0,2)
        InfoText.BackgroundTransparency = 1
        InfoText.Font = Enum.Font.GothamBold
        InfoText.TextSize = 16
        InfoText.TextColor3 = Color3.fromRGB(255,255,255)
        InfoText.TextXAlignment = Enum.TextXAlignment.Left
        InfoText.Text = "Ping: -- ms | FPS: --"
        InfoText.Parent = MainFrame
        local NameText = Instance.new("TextLabel")
        NameText.Size = UDim2.new(1,0,0.35,0)
        NameText.Position = UDim2.new(0,5,0.6,0)
        NameText.BackgroundTransparency = 1
        NameText.Font = Enum.Font.GothamBold
        NameText.TextSize = 14
        NameText.TextColor3 = Color3.fromRGB(255,255,255)
        NameText.TextXAlignment = Enum.TextXAlignment.Left
        NameText.Text = "Vaelyer | By Archaes `78"
        NameText.Parent = MainFrame
        local TextGradient = Instance.new("UIGradient")
        TextGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(90,180,255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180,120,255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(120,255,180))
        }
        TextGradient.Parent = InfoText
        local NameGradient = TextGradient:Clone()
        NameGradient.Parent = NameText
        local PingToggle = Instance.new("TextButton")
        PingToggle.Size = UDim2.new(0,28,0,28)
        PingToggle.Position = UDim2.new(1,-32,0,4)
        PingToggle.BackgroundColor3 = Color3.fromRGB(30,30,30)
        PingToggle.Text = "–"
        PingToggle.Font = Enum.Font.GothamBold
        PingToggle.TextSize = 18
        PingToggle.TextColor3 = Color3.fromRGB(255,255,255)
        PingToggle.BorderSizePixel = 0
        PingToggle.Parent = MainFrame
        Instance.new("UICorner",PingToggle).CornerRadius = UDim.new(0,8)
        local VisibleState = true
        PingToggle.MouseButton1Click:Connect(function()
            VisibleState = not VisibleState
            InfoText.Visible = VisibleState
            NameText.Visible = VisibleState
            MainFrame.Size = VisibleState and UDim2.new(0,220,0,55) or UDim2.new(0,45,0,35)
            PingToggle.Text = VisibleState and "–" or "+"
        end)
        spawn(function()
            local Stats = game:GetService("Stats")
            while wait(1) do
                if not ScreenGui.Parent then break end
                local pingValue = "--"
                local Net = Stats:FindFirstChild("Network")
                if Net and Net.ServerStatsItem:FindFirstChild("Data Ping") then
                    pingValue = math.floor(Net.ServerStatsItem["Data Ping"]:GetValue())
                end
                local fpsPart = InfoText.Text:match("| FPS: .+") or "| FPS: --"
                InfoText.Text = "Ping: "..pingValue.." ms "..fpsPart
            end
        end)
        local frameCount = 0
        local lastTime = tick()
        RunService.RenderStepped:Connect(function()
            if not ScreenGui.Parent then return end
            frameCount = frameCount + 1
            local now = tick()
            if now - lastTime >= 1 then
                local fps = frameCount
                frameCount = 0
                lastTime = now
                local pingPart = InfoText.Text:match("Ping:.-ms") or "Ping: -- ms"
                InfoText.Text = pingPart.." | FPS: "..fps
            end
        end)
        local rot = 0
        RunService.RenderStepped:Connect(function()
            if not ScreenGui.Parent then return end
            rot = (rot + 2) % 360
            TextGradient.Rotation = rot
            NameGradient.Rotation = rot
        end)
        local dragging, dragStart, startPos
        MainFrame.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging = true dragStart = i.Position startPos = MainFrame.Position
            end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local d = i.Position - dragStart
                MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end)
        UserInputService.InputEnded:Connect(function() dragging = false end)
    end)
end

local function clearESP(char)
    if not char then return end
    local hl = char:FindFirstChild("HL")
    if hl then hl:Destroy() end
    local head = char:FindFirstChild("Head")
    if head then
        local esp = head:FindFirstChild("ESP")
        if esp then esp:Destroy() end
    end
end

local function createESP(player, char)
    clearESP(char)
    local head = char:FindFirstChild("Head")
    local humanoid = char:FindFirstChild("Humanoid")
    if not head or not humanoid then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "HL"
    highlight.FillColor = Color3.fromRGB(0, 170, 255)
    highlight.FillTransparency = 0.75
    highlight.OutlineColor = Color3.fromRGB(0, 170, 255)
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = char
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP"
    billboard.Size = UDim2.new(0, 120, 0, 22)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.ResetOnSpawn = false
    billboard.MaxDistance = 350
    billboard.Parent = head
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.TextScaled = true
    text.Font = Enum.Font.GothamBold
    text.TextStrokeTransparency = 0.4
    text.TextColor3 = Color3.fromRGB(255,255,255)
    text.Parent = billboard
    local t = 0
    if ESPConnections[player] then ESPConnections[player]:Disconnect() ESPConnections[player] = nil end
    ESPConnections[player] = RunService.RenderStepped:Connect(function(dt)
        if not Config.AIMBOT_ESP then highlight.Enabled = false billboard.Enabled = false return end
        if not char.Parent or not head.Parent then highlight.Enabled = false billboard.Enabled = false return end
        if humanoid.Health <= 0 then highlight.Enabled = false billboard.Enabled = false return end
        local dist = (head.Position - Camera.CFrame.Position).Magnitude
        if dist <= 350 then
            highlight.Enabled = true
            billboard.Enabled = true
            local visible = isVisible(head.Position, char)
            local isTarget = (currentTarget == player and visible)
            if isTarget then
                highlight.FillColor = Color3.fromRGB(255, 60, 60)
                highlight.OutlineColor = Color3.fromRGB(255, 60, 60)
            else
                highlight.FillColor = Color3.fromRGB(0, 170, 255)
                highlight.OutlineColor = Color3.fromRGB(0, 170, 255)
            end
            text.Text = "Name: " .. player.Name .. " | Studs: " .. math.floor(dist)
            t = t + (dt * 2)
            local pulse = (math.sin(t) + 1) / 2
            local hpRatio = humanoid.Health / humanoid.MaxHealth
            local r = 255 * (1 - hpRatio)
            local g = 255
            local b = 120 * hpRatio
            local glow = 0.2 + (pulse * 0.4)
            text.TextColor3 = Color3.fromRGB(r, g, b)
            text.TextStrokeTransparency = 1 - glow
        else
            highlight.Enabled = false
            billboard.Enabled = false
        end
    end)
end

local function setupESP(player)
    if player == LocalPlayer then return end
    local function onCharacter(char)
        wait(0.8)
        if not char or not char.Parent then return end
        createESP(player, char)
    end
    if player.Character then spawn(function() onCharacter(player.Character) end) end
    player.CharacterAdded:Connect(onCharacter)
    player.CharacterRemoving:Connect(function()
        if ESPConnections[player] then ESPConnections[player]:Disconnect() ESPConnections[player] = nil end
    end)
end

-- Aimbot Loop
RunService.RenderStepped:Connect(function()
    if not Config.AIMBOT_ESP then currentTarget = nil return end
    local newTarget = getTarget()
    currentTarget = newTarget
    if currentTarget and currentTarget.Character then
        local head = currentTarget.Character:FindFirstChild("Head")
        local humanoid = currentTarget.Character:FindFirstChild("Humanoid")
        if head and humanoid and isAlive(humanoid) then
            local velocity = head.AssemblyLinearVelocity
            local distance = (head.Position - Camera.CFrame.Position).Magnitude
            local predFactor = math.clamp(distance / 320, 0.01, 0.05)
            local predicted = head.Position + (velocity * predFactor)
            if (predicted - head.Position).Magnitude > 1.2 then predicted = head.Position end
            local finalPos = head.Position:Lerp(predicted, 99.9 / 100)
            finalPos = finalPos + Vector3.new(0, 0.06, 0)
            local newCF = CFrame.new(Camera.CFrame.Position, finalPos)
            local smooth = 0.4
            if distance < 20 then smooth = 0.7 elseif distance > 120 then smooth = 0.45 end
            Camera.CFrame = Camera.CFrame:Lerp(newCF, smooth)
        end
    end
end)

-- ESP Setup
for _, player in ipairs(Players:GetPlayers()) do
    spawn(function() setupESP(player) end)
end
Players.PlayerAdded:Connect(function(player) wait(1) setupESP(player) end)
Players.PlayerRemoving:Connect(function(player)
    if ESPConnections[player] then ESPConnections[player]:Disconnect() ESPConnections[player] = nil end
end)
setupZeroRecoil()

-- RedzLib Toggles (pengganti tombol lama)
Tab:AddToggle({
    Name = "Aimbot + ESP",
    Default = false,
    Save = false,
    Flag = "AIMBOT_ESP",
    Callback = function(value)
        Config.AIMBOT_ESP = value
    end
})

Tab:AddToggle({
    Name = "SpeedHack",
    Default = false,
    Save = false,
    Flag = "SPEEDHACK",
    Callback = function(value)
        Config.SPEEDHACK = value
        applySpeedHack()
    end
})

Tab:AddToggle({
    Name = "Zero Recoil",
    Default = false,
    Save = false,
    Flag = "ZERO_RECOIL",
    Callback = function(value)
        Config.ZERO_RECOIL = value
        setupZeroRecoil()
    end
})

Tab:AddToggle({
    Name = "Ping / FPS",
    Default = false,
    Save = false,
    Flag = "PING_FPS_UI",
    Callback = function(value)
        Config.PING_FPS_UI = value
        setupPingUI()
    end
})

Tab:AddToggle({
    Name = "Boost FPS",
    Default = false,
    Save = false,
    Flag = "BOOST_FPS",
    Callback = function(value)
        Config.BOOST_FPS = value
        applyBoostFPS()
    end
})
