-- ╔═══════════════════════════════════════════╗
--   EXO HUB | Blade Ball Edition FIXED
--   Delta Ready  ·  discord.gg/TzNds43vb
-- ╚═══════════════════════════════════════════╝

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = cloneref and cloneref(game:GetService("VirtualInputManager")) or game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local states = {
    autoParry = false,
    speed = false,
    fly = false,
    ballESP = false,
    autoSkill = false,
    antiDie = false,
}

local flyActive = false
local tpwalking = false
local flySpeed = 1
local healthConnections = {}
local ballESPObj = nil
local parryConn = nil
local skillConn = nil
local speedDefault = 16
local lastParry = 0

-- ╔══════════════════╗
--   FIND BALL
-- ╚══════════════════╝

local function findBall()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (
            obj.Name:lower():find("ball") or
            obj.Name:lower():find("blade") or
            obj.Name:lower():find("kill") or
            obj.Name:lower():find("proj")
        ) then
            if obj.Size.Magnitude < 10 then
                return obj
            end
        end
    end
end

-- ╔══════════════════╗
--   FIND ALL REMOTES
-- ╚══════════════════╝

local function getAllRemotes()
    local remotes = {}
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            table.insert(remotes, v)
        end
    end
    return remotes
end

-- ╔══════════════════╗
--   AUTO PARRY
-- ╚══════════════════╝

local function tryParry()
    local now = tick()
    if now - lastParry < 0.08 then return end
    lastParry = now

    pcall(function()
        for _, remote in ipairs(getAllRemotes()) do
            local name = remote.Name:lower()
            if name:find("parry") or name:find("block") or name:find("deflect") or name:find("reflect") or name:find("guard") or name:find("defend") then
                if remote:IsA("RemoteEvent") then
                    remote:FireServer()
                end
            end
        end
    end)

    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)

    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
    end)

    pcall(function()
        for _, gui in ipairs(player.PlayerGui:GetDescendants()) do
            if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                local name = gui.Name:lower()
                if name:find("parry") or name:find("block") or name:find("deflect") then
                    gui.MouseButton1Click:Fire()
                end
            end
        end
    end)
end

local function startAutoParry()
    parryConn = RunService.Heartbeat:Connect(function()
        if not states.autoParry then return end
        local ball = findBall()
        if not ball then return end
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local dist = (ball.Position - hrp.Position).Magnitude
        if dist < 20 then
            tryParry()
        end
    end)
end

local function stopAutoParry()
    if parryConn then parryConn:Disconnect(); parryConn = nil end
end

-- ╔══════════════════╗
--   SPEED
-- ╚══════════════════╝

local function setSpeed(on)
    local char = player.Character
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    if hum then hum.WalkSpeed = on and 60 or speedDefault end
end

-- ╔══════════════════╗
--   FLY
-- ╚══════════════════╝

local function startTpWalking()
    tpwalking = false
    for i = 1, flySpeed do
        spawn(function()
            local hb = RunService.Heartbeat
            tpwalking = true
            local chr = player.Character
            local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
            while tpwalking and hb:Wait() and chr and hum and hum.Parent do
                if hum.MoveDirection.Magnitude > 0 then chr:TranslateBy(hum.MoveDirection) end
            end
        end)
    end
end

local function startFly()
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    if not hum then return end
    local isR6 = hum.RigType == Enum.HumanoidRigType.R6
    local torso = isR6 and char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    if not torso then return end

    char.Animate.Disabled = true
    for _, t in pairs(hum:GetPlayingAnimationTracks()) do t:AdjustSpeed(0) end
    for _, s in pairs(Enum.HumanoidStateType:GetEnumItems()) do
        pcall(function() hum:SetStateEnabled(s, false) end)
    end
    hum:ChangeState(Enum.HumanoidStateType.Swimming)
    startTpWalking()
    hum.PlatformStand = true

    local bg = Instance.new("BodyGyro", torso)
    bg.P = 9e4
    bg.maxTorque = Vector3.new(9e9,9e9,9e9)
    bg.cframe = torso.CFrame

    local bv = Instance.new("BodyVelocity", torso)
    bv.velocity = Vector3.new(0,0.1,0)
    bv.maxForce = Vector3.new(9e9,9e9,9e9)

    local ctrl = {f=0,b=0,l=0,r=0}
    local lastctrl = {f=0,b=0,l=0,r=0}
    local maxspeed = 50
    local spd = 0
    local conn

    conn = RunService.RenderStepped:Connect(function()
        if not flyActive then
            conn:Disconnect()
            pcall(function() bg:Destroy() end)
            pcall(function() bv:Destroy() end)
            hum.PlatformStand = false
            char.Animate.Disabled = false
            tpwalking = false
            for _, s in pairs(Enum.HumanoidStateType:GetEnumItems()) do
                pcall(function() hum:SetStateEnabled(s, true) end)
            end
            hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
            return
        end
        ctrl.f = UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0
        ctrl.b = UserInputService:IsKeyDown(Enum.KeyCode.S) and -1 or 0
        ctrl.l = UserInputService:IsKeyDown(Enum.KeyCode.A) and -1 or 0
        ctrl.r = UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0
        if ctrl.l+ctrl.r ~= 0 or ctrl.f+ctrl.b ~= 0 then
            spd = math.min(spd+0.5+(spd/maxspeed), maxspeed)
        else
            spd = math.max(spd-1, 0)
        end
        local cam = workspace.CurrentCamera.CoordinateFrame
        if (ctrl.l+ctrl.r) ~= 0 or (ctrl.f+ctrl.b) ~= 0 then
            bv.velocity = ((cam.lookVector*(ctrl.f+ctrl.b))+((cam*CFrame.new(ctrl.l+ctrl.r,(ctrl.f+ctrl.b)*.2,0).p)-cam.p))*spd
            lastctrl = {f=ctrl.f,b=ctrl.b,l=ctrl.l,r=ctrl.r}
        elseif spd ~= 0 then
            bv.velocity = ((cam.lookVector*(lastctrl.f+lastctrl.b))+((cam*CFrame.new(lastctrl.l+lastctrl.r,(lastctrl.f+lastctrl.b)*.2,0).p)-cam.p))*spd
        else
            bv.velocity = Vector3.new(0,0,0)
        end
        bg.cframe = cam*CFrame.Angles(-math.rad((ctrl.f+ctrl.b)*50*spd/maxspeed),0,0)
    end)
end

-- ╔══════════════════╗
--   BALL ESP
-- ╚══════════════════╝

local function startBallESP()
    RunService.Heartbeat:Connect(function()
        if not states.ballESP then
            if ballESPObj then pcall(function() ballESPObj:Destroy() end); ballESPObj = nil end
            return
        end
        local ball = findBall()
        if ball and not ballESPObj then
            ballESPObj = Instance.new("SelectionBox")
            ballESPObj.Color3 = Color3.fromRGB(255, 50, 50)
            ballESPObj.LineThickness = 0.05
            ballESPObj.SurfaceTransparency = 0.6
            ballESPObj.SurfaceColor3 = Color3.fromRGB(255, 80, 80)
            ballESPObj.Adornee = ball
            ballESPObj.Parent = workspace
        elseif not ball and ballESPObj then
            pcall(function() ballESPObj:Destroy() end)
            ballESPObj = nil
        end
    end)
end

-- ╔══════════════════╗
--   AUTO SKILL
-- ╚══════════════════╝

local lastSkill = 0

local function startAutoSkill()
    skillConn = RunService.Heartbeat:Connect(function()
        if not states.autoSkill then return end
        local now = tick()
        if now - lastSkill < 1 then return end
        local ball = findBall()
        if not ball then return end
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local dist = (ball.Position - hrp.Position).Magnitude
        if dist < 30 then
            lastSkill = now
            pcall(function()
                for _, remote in ipairs(getAllRemotes()) do
                    local name = remote.Name:lower()
                    if name:find("skill") or name:find("ability") or name:find("power") or name:find("spell") then
                        if remote:IsA("RemoteEvent") then remote:FireServer() end
                    end
                end
            end)
            pcall(function()
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
                task.wait(0.05)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
            end)
        end
    end)
end

local function stopAutoSkill()
    if skillConn then skillConn:Disconnect(); skillConn = nil end
end

-- ╔══════════════════╗
--   ANTI DIE
-- ╚══════════════════╝

local function setupAntiDie(char)
    if not char then return end
    for _, c in pairs(healthConnections) do if c then c:Disconnect() end end
    healthConnections = {}
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.BreakJointsOnDeath = false
    hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    local ff = Instance.new("ForceField")
    ff.Visible = false
    ff.Parent = char
    local hc = hum:GetPropertyChangedSignal("Health"):Connect(function()
        if states.antiDie and hum.Health <= 0 then
            task.wait(0.05)
            hum.Health = hum.MaxHealth
        end
    end)
    table.insert(healthConnections, hc)
end

local function stopAntiDie()
    for _, c in pairs(healthConnections) do if c then c:Disconnect() end end
    healthConnections = {}
    local char = player.Character
    if char then
        local ff = char:FindFirstChildOfClass("ForceField")
        if ff then ff:Destroy() end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true) end
    end
end

-- ╔══════════════════╗
--   GUI
-- ╚══════════════════╝

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ExoBladeBall"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = player.PlayerGui

local glowFrame = Instance.new("Frame")
glowFrame.Size = UDim2.new(0, 274, 0, 504)
glowFrame.Position = UDim2.new(0, 8, 0.5, -242)
glowFrame.BackgroundColor3 = Color3.fromRGB(255, 50, 80)
glowFrame.BackgroundTransparency = 0.85
glowFrame.BorderSizePixel = 0
glowFrame.Parent = ScreenGui
Instance.new("UICorner", glowFrame).CornerRadius = UDim.new(0, 18)

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 270, 0, 500)
frame.Position = UDim2.new(0, 10, 0.5, -240)
frame.BackgroundColor3 = Color3.fromRGB(8, 4, 18)
frame.BorderSizePixel = 0
frame.Parent = ScreenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)

local innerGrad = Instance.new("UIGradient")
innerGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 4, 8)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(8, 4, 18)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(4, 2, 14)),
})
innerGrad.Rotation = 135
innerGrad.Parent = frame

local borderStroke = Instance.new("UIStroke")
borderStroke.Color = Color3.fromRGB(255, 50, 80)
borderStroke.Thickness = 1.5
borderStroke.Transparency = 0.2
borderStroke.Parent = frame

local slash1 = Instance.new("Frame")
slash1.Size = UDim2.new(0, 80, 0, 4)
slash1.Position = UDim2.new(0, -15, 0, 0)
slash1.BackgroundColor3 = Color3.fromRGB(255, 50, 80)
slash1.BorderSizePixel = 0
slash1.Rotation = -15
slash1.Parent = frame

local slash2 = Instance.new("Frame")
slash2.Size = UDim2.new(0, 50, 0, 4)
slash2.Position = UDim2.new(0, 68, 0, 0)
slash2.BackgroundColor3 = Color3.fromRGB(200, 0, 40)
slash2.BorderSizePixel = 0
slash2.Rotation = -15
slash2.Parent = frame

local c1 = Instance.new("Frame")
c1.Size = UDim2.new(0, 30, 0, 2)
c1.Position = UDim2.new(1, -34, 1, -12)
c1.BackgroundColor3 = Color3.fromRGB(255, 50, 80)
c1.BackgroundTransparency = 0.3
c1.BorderSizePixel = 0
c1.Parent = frame

local c2 = Instance.new("Frame")
c2.Size = UDim2.new(0, 2, 0, 20)
c2.Position = UDim2.new(1, -6, 1, -24)
c2.BackgroundColor3 = Color3.fromRGB(255, 50, 80)
c2.BackgroundTransparency = 0.3
c2.BorderSizePixel = 0
c2.Parent = frame

-- Header / drag bar
local headerBg = Instance.new("Frame")
headerBg.Size = UDim2.new(1, 0, 0, 70)
headerBg.BackgroundColor3 = Color3.fromRGB(255, 50, 80)
headerBg.BackgroundTransparency = 0.92
headerBg.BorderSizePixel = 0
headerBg.Active = true
headerBg.Parent = frame

local logoLabel = Instance.new("TextLabel")
logoLabel.Size = UDim2.new(1, 0, 0, 36)
logoLabel.Position = UDim2.new(0, 0, 0, 4)
logoLabel.BackgroundTransparency = 1
logoLabel.Text = "✦ EXO HUB"
logoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
logoLabel.TextSize = 24
logoLabel.Font = Enum.Font.GothamBold
logoLabel.Parent = headerBg

local logoGrad = Instance.new("UIGradient")
logoGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 80, 110)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 50)),
})
logoGrad.Parent = logoLabel

local gameLabel = Instance.new("TextLabel")
gameLabel.Size = UDim2.new(1, 0, 0, 16)
gameLabel.Position = UDim2.new(0, 0, 0, 36)
gameLabel.BackgroundTransparency = 1
gameLabel.Text = "⚔️  BLADE BALL EDITION"
gameLabel.TextColor3 = Color3.fromRGB(255, 80, 100)
gameLabel.TextSize = 10
gameLabel.Font = Enum.Font.GothamBold
gameLabel.Parent = headerBg

local discordHeader = Instance.new("TextLabel")
discordHeader.Size = UDim2.new(1, 0, 0, 14)
discordHeader.Position = UDim2.new(0, 0, 0, 52)
discordHeader.BackgroundTransparency = 1
discordHeader.Text = "discord.gg/TzNds43vb"
discordHeader.TextColor3 = Color3.fromRGB(100, 60, 80)
discordHeader.TextSize = 9
discordHeader.Font = Enum.Font.Gotham
discordHeader.Parent = headerBg

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -34, 0, 8)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 80)
closeBtn.BackgroundTransparency = 0.3
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 11
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = frame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 7)

local headerDiv = Instance.new("Frame")
headerDiv.Size = UDim2.new(1, -20, 0, 1)
headerDiv.Position = UDim2.new(0, 10, 0, 70)
headerDiv.BackgroundColor3 = Color3.fromRGB(255, 50, 80)
headerDiv.BackgroundTransparency = 0.6
headerDiv.BorderSizePixel = 0
headerDiv.Parent = frame

local reopenBtn = Instance.new("TextButton")
reopenBtn.Size = UDim2.new(0, 110, 0, 30)
reopenBtn.Position = UDim2.new(0, 10, 0, 10)
reopenBtn.BackgroundColor3 = Color3.fromRGB(8, 4, 18)
reopenBtn.Text = "✦ EXO HUB"
reopenBtn.TextColor3 = Color3.fromRGB(255, 50, 80)
reopenBtn.TextSize = 11
reopenBtn.Font = Enum.Font.GothamBold
reopenBtn.BorderSizePixel = 0
reopenBtn.Visible = false
reopenBtn.Parent = ScreenGui
Instance.new("UICorner", reopenBtn).CornerRadius = UDim.new(0, 8)
local rs = Instance.new("UIStroke", reopenBtn)
rs.Color = Color3.fromRGB(255, 50, 80)
rs.Thickness = 1.5

closeBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
    glowFrame.Visible = false
    reopenBtn.Visible = true
end)
reopenBtn.MouseButton1Click:Connect(function()
    frame.Visible = true
    glowFrame.Visible = true
    reopenBtn.Visible = false
end)

-- Scroll
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 1, -160)
scrollFrame.Position = UDim2.new(0, 10, 0, 78)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 3
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 50, 80)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.Parent = frame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scrollFrame

local features = {
    {key="autoParry", name="Auto Parry",  desc="Auto deflects — fires E/F + all parry remotes", icon="🛡️", color=Color3.fromRGB(255,50,80),   onEnable=startAutoParry, onDisable=stopAutoParry},
    {key="speed",     name="Speed Hack",  desc="Move insanely fast to dodge",                   icon="⚡",  color=Color3.fromRGB(255,200,0),   onEnable=function() setSpeed(true) end, onDisable=function() setSpeed(false) end},
    {key="fly",       name="Fly",         desc="Fly above the ball — WASD to move",              icon="🛸",  color=Color3.fromRGB(120,80,255),  onEnable=function() flyActive=true; startFly() end, onDisable=function() flyActive=false end},
    {key="ballESP",   name="Ball ESP",    desc="Always see where the ball is",                   icon="👁",  color=Color3.fromRGB(0,200,255),   onEnable=startBallESP, onDisable=function() if ballESPObj then pcall(function() ballESPObj:Destroy() end); ballESPObj=nil end end},
    {key="autoSkill", name="Auto Skill",  desc="Auto fires Q + skill remotes when ball close",   icon="✨",  color=Color3.fromRGB(180,0,255),   onEnable=startAutoSkill, onDisable=stopAutoSkill},
    {key="antiDie",   name="Anti Die",    desc="Cannot be killed by the ball",                   icon="💀",  color=Color3.fromRGB(255,140,0),   onEnable=function() setupAntiDie(player.Character) end, onDisable=stopAntiDie},
}

local function makeCard(feature, index)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 68)
    card.BackgroundColor3 = feature.color
    card.BackgroundTransparency = 0.92
    card.BorderSizePixel = 0
    card.LayoutOrder = index
    card.Parent = scrollFrame
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = feature.color
    cardStroke.Thickness = 1
    cardStroke.Transparency = 0.7
    cardStroke.Parent = card

    local iconBg = Instance.new("Frame")
    iconBg.Size = UDim2.new(0, 44, 0, 44)
    iconBg.Position = UDim2.new(0, 10, 0.5, -22)
    iconBg.BackgroundColor3 = feature.color
    iconBg.BackgroundTransparency = 0.7
    iconBg.BorderSizePixel = 0
    iconBg.Parent = card
    Instance.new("UICorner", iconBg).CornerRadius = UDim.new(0, 10)

    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(1, 0, 1, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = feature.icon
    iconLabel.TextSize = 22
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.Parent = iconBg

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -120, 0, 22)
    nameLabel.Position = UDim2.new(0, 62, 0, 10)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = feature.name
    nameLabel.TextColor3 = Color3.fromRGB(220, 220, 240)
    nameLabel.TextSize = 13
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = card

    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -120, 0, 28)
    descLabel.Position = UDim2.new(0, 62, 0, 32)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = feature.desc
    descLabel.TextColor3 = Color3.fromRGB(100, 100, 140)
    descLabel.TextSize = 9
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextWrapped = true
    descLabel.Parent = card

    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 40, 0, 22)
    pill.Position = UDim2.new(1, -50, 0.5, -11)
    pill.BackgroundColor3 = Color3.fromRGB(20, 10, 35)
    pill.BorderSizePixel = 0
    pill.Parent = card
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
    Instance.new("UIStroke", pill).Color = feature.color

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 16, 0, 16)
    dot.Position = UDim2.new(0, 3, 0.5, -8)
    dot.BackgroundColor3 = Color3.fromRGB(180, 180, 200)
    dot.BorderSizePixel = 0
    dot.Parent = pill
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(1, 0, 1, 0)
    toggleBtn.BackgroundTransparency = 1
    toggleBtn.Text = ""
    toggleBtn.Parent = card

    toggleBtn.MouseButton1Click:Connect(function()
        states[feature.key] = not states[feature.key]
        local on = states[feature.key]
        TweenService:Create(pill, TweenInfo.new(0.2), {BackgroundColor3 = on and feature.color or Color3.fromRGB(20,10,35)}):Play()
        TweenService:Create(dot, TweenInfo.new(0.2), {
            Position = on and UDim2.new(0,21,0.5,-8) or UDim2.new(0,3,0.5,-8),
            BackgroundColor3 = on and Color3.fromRGB(255,255,255) or Color3.fromRGB(180,180,200)
        }):Play()
        TweenService:Create(cardStroke, TweenInfo.new(0.2), {Transparency = on and 0.2 or 0.7}):Play()
        TweenService:Create(iconBg, TweenInfo.new(0.2), {BackgroundTransparency = on and 0.3 or 0.7}):Play()
        if on then feature.onEnable() else feature.onDisable() end
    end)

    card.MouseEnter:Connect(function() TweenService:Create(card, TweenInfo.new(0.15), {BackgroundTransparency=0.85}):Play() end)
    card.MouseLeave:Connect(function() TweenService:Create(card, TweenInfo.new(0.15), {BackgroundTransparency=0.92}):Play() end)
end

for i, feat in ipairs(features) do makeCard(feat, i) end
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #features * 76)

-- Discord banner
local discordBanner = Instance.new("Frame")
discordBanner.Size = UDim2.new(1, -20, 0, 44)
discordBanner.Position = UDim2.new(0, 10, 1, -52)
discordBanner.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
discordBanner.BackgroundTransparency = 0.3
discordBanner.BorderSizePixel = 0
discordBanner.Parent = frame
Instance.new("UICorner", discordBanner).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", discordBanner).Color = Color3.fromRGB(88, 101, 242)

local dIcon = Instance.new("TextLabel", discordBanner)
dIcon.Size = UDim2.new(0, 40, 1, 0)
dIcon.BackgroundTransparency = 1
dIcon.Text = "💬"
dIcon.TextSize = 20
dIcon.Font = Enum.Font.GothamBold

local dText = Instance.new("TextLabel", discordBanner)
dText.Size = UDim2.new(1, -50, 0, 18)
dText.Position = UDim2.new(0, 42, 0, 4)
dText.BackgroundTransparency = 1
dText.Text = "Join our Discord!"
dText.TextColor3 = Color3.fromRGB(255, 255, 255)
dText.TextSize = 12
dText.Font = Enum.Font.GothamBold
dText.TextXAlignment = Enum.TextXAlignment.Left

local dLink = Instance.new("TextLabel", discordBanner)
dLink.Size = UDim2.new(1, -50, 0, 14)
dLink.Position = UDim2.new(0, 42, 0, 24)
dLink.BackgroundTransparency = 1
dLink.Text = "discord.gg/TzNds43vb"
dLink.TextColor3 = Color3.fromRGB(180, 190, 255)
dLink.TextSize = 10
dLink.Font = Enum.Font.Gotham
dLink.TextXAlignment = Enum.TextXAlignment.Left

-- ╔══════════════════╗
--   DRAGGING FIXED
-- ╚══════════════════╝

local dragging = false
local dragStart = nil
local startPos = nil

headerBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
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
        local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y)
        frame.Position = newPos
        glowFrame.Position = UDim2.new(newPos.X.Scale, newPos.X.Offset-2, newPos.Y.Scale, newPos.Y.Offset-2)
    end
end)

-- ╔══════════════════╗
--   IDLE ANIMATION
-- ╚══════════════════╝

local t = 0
RunService.Heartbeat:Connect(function(dt)
    t = t + dt
    local pulse = (math.sin(t*2)+1)/2
    borderStroke.Transparency = 0.1 + pulse*0.3
    glowFrame.BackgroundTransparency = 0.8 + pulse*0.1
    slash1.BackgroundTransparency = 0.2 + pulse*0.4
    slash2.BackgroundTransparency = 0.4 + pulse*0.3
    logoGrad.Rotation = (t*15) % 360
end)

player.CharacterAdded:Connect(function(char)
    character = char
    task.wait(0.5)
    if states.antiDie then setupAntiDie(char) end
    if states.speed then setSpeed(true) end
    if states.fly then flyActive = true; startFly() end
end)

print("[ExoHub] Blade Ball Hub Loaded ✓  |  discord.gg/TzNds43vb")
