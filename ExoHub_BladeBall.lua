-- ╔═══════════════════════════════════╗
--   EXO HUB | BLADE BALL
--   discord.gg/6QzV9pTWs
-- ╚═══════════════════════════════════╝

local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local TweenService    = game:GetService("TweenService")
local UserInputService= game:GetService("UserInputService")
local VIM             = game:GetService("VirtualInputManager")
local lp              = Players.LocalPlayer

-- ══════════════════════════════════════
--  STATE
-- ══════════════════════════════════════
local states = {
    autoParry = false,
    antiDie   = false,
    speed     = false,
    fly       = false,
    ballESP   = false,
}

local Parried     = false
local ballConn    = nil
local targetConn  = nil
local parryLoop   = nil
local antiDieConn = nil
local flyConn     = nil
local espHL       = nil
local flyActive   = false
local bodyGyro    = nil
local bodyVel     = nil
local flySpeed    = 60

-- ══════════════════════════════════════
--  HELPERS
-- ══════════════════════════════════════
local function getChar() return lp.Character end
local function getHRP()  local c=getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()  local c=getChar(); return c and c:FindFirstChildOfClass("Humanoid") end

local function GetBall()
    local ballFolder = workspace:FindFirstChild("Balls")
    if not ballFolder then return end
    for _, b in ipairs(ballFolder:GetChildren()) do
        if b:GetAttribute("realBall") then return b end
    end
end

-- ══════════════════════════════════════
--  AUTO PARRY (accurate targeting)
-- ══════════════════════════════════════
local function doParry()
    pcall(function()
        for _, g in ipairs(lp.PlayerGui:GetDescendants()) do
            if (g:IsA("TextButton") or g:IsA("ImageButton")) then
                local n = g.Name:lower()
                if n:find("block") or n:find("parry") then
                    g.MouseButton1Click:Fire()
                    pcall(function() g.Activated:Fire() end)
                end
            end
        end
    end)
    pcall(function()
        VIM:SendMouseButtonEvent(0,0,0,true,game,0)
        task.wait(0.03)
        VIM:SendMouseButtonEvent(0,0,0,false,game,0)
    end)
end

local function resetTargetConn(ball)
    if targetConn then targetConn:Disconnect(); targetConn = nil end
    if not ball then return end
    targetConn = ball:GetAttributeChangedSignal("target"):Connect(function()
        Parried = false
    end)
end

local function startAutoParry()
    local ballFolder = workspace:FindFirstChild("Balls")
    if ballFolder then
        ballConn = ballFolder.ChildAdded:Connect(function()
            task.wait(0.05)
            local ball = GetBall()
            if ball then resetTargetConn(ball) end
            Parried = false
        end)
        local ball = GetBall()
        if ball then resetTargetConn(ball) end
    end

    parryLoop = RunService.PreSimulation:Connect(function()
        if not states.autoParry then return end
        local ball = GetBall()
        local hrp  = getHRP()
        if not ball or not hrp then return end
        local vel   = ball:FindFirstChild("zoomies")
        local speed = vel and vel.VectorVelocity and vel.VectorVelocity.Magnitude or 60
        local dist  = (hrp.Position - ball.Position).Magnitude
        if ball:GetAttribute("target") == lp.Name and not Parried and dist / speed <= 0.55 then
            doParry()
            Parried = true
        end
    end)
end

local function stopAutoParry()
    if parryLoop  then parryLoop:Disconnect();  parryLoop  = nil end
    if ballConn   then ballConn:Disconnect();   ballConn   = nil end
    if targetConn then targetConn:Disconnect(); targetConn = nil end
    Parried = false
end

-- ══════════════════════════════════════
--  ANTI DIE
-- ══════════════════════════════════════
local function startAntiDie()
    antiDieConn = RunService.Heartbeat:Connect(function()
        if not states.antiDie then return end
        local hum = getHum()
        if hum then hum.Health = hum.MaxHealth end
    end)
end

local function stopAntiDie()
    if antiDieConn then antiDieConn:Disconnect(); antiDieConn = nil end
end

-- ══════════════════════════════════════
--  SPEED
-- ══════════════════════════════════════
local function setSpeed(on)
    local hum = getHum()
    if hum then hum.WalkSpeed = on and 80 or 16 end
end

-- ══════════════════════════════════════
--  FLY
-- ══════════════════════════════════════
local function startFly()
    local hrp = getHRP()
    local hum = getHum()
    if not hrp or not hum then return end
    hum.PlatformStand = true
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(9e9,9e9,9e9)
    bodyGyro.P = 9e4
    bodyGyro.CFrame = hrp.CFrame
    bodyGyro.Parent = hrp
    bodyVel = Instance.new("BodyVelocity")
    bodyVel.Velocity = Vector3.zero
    bodyVel.MaxForce = Vector3.new(9e9,9e9,9e9)
    bodyVel.P = 9e4
    bodyVel.Parent = hrp
    local cam = workspace.CurrentCamera
    flyConn = RunService.RenderStepped:Connect(function()
        if not flyActive then return end
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)     then dir += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0,1,0) end
        bodyVel.Velocity = dir.Magnitude > 0 and dir.Unit * flySpeed or Vector3.zero
        bodyGyro.CFrame  = cam.CFrame
    end)
end

local function stopFly()
    flyActive = false
    if flyConn  then flyConn:Disconnect();  flyConn  = nil end
    if bodyGyro then bodyGyro:Destroy();    bodyGyro = nil end
    if bodyVel  then bodyVel:Destroy();     bodyVel  = nil end
    local hum = getHum()
    if hum then hum.PlatformStand = false end
end

-- ══════════════════════════════════════
--  BALL ESP
-- ══════════════════════════════════════
local function startBallESP()
    RunService.Heartbeat:Connect(function()
        if not states.ballESP then
            if espHL then pcall(function() espHL:Destroy() end); espHL = nil end
            return
        end
        local ball = GetBall()
        if ball and ball.Parent then
            if not espHL then
                espHL = Instance.new("SelectionBox")
                espHL.Color3 = Color3.fromRGB(0,200,255)
                espHL.LineThickness = 0.06
                espHL.SurfaceTransparency = 0.7
                espHL.SurfaceColor3 = Color3.fromRGB(0,200,255)
            end
            espHL.Adornee = ball
            espHL.Parent  = workspace
        else
            if espHL then pcall(function() espHL:Destroy() end); espHL = nil end
        end
    end)
end

-- respawn
lp.CharacterAdded:Connect(function()
    task.wait(1)
    if states.speed    then setSpeed(true) end
    if states.fly      then flyActive=true; startFly() end
    if states.antiDie  then startAntiDie() end
    if states.autoParry then stopAutoParry(); task.wait(0.1); startAutoParry() end
end)

-- ══════════════════════════════════════
--  GUI
-- ══════════════════════════════════════
if lp.PlayerGui:FindFirstChild("ExoBBGui") then lp.PlayerGui.ExoBBGui:Destroy() end

local SG = Instance.new("ScreenGui")
SG.Name = "ExoBBGui"
SG.ResetOnSpawn = false
SG.DisplayOrder = 999
SG.IgnoreGuiInset = true
SG.Parent = lp.PlayerGui

local FULL_H = 372
local MINI_H = 48
local minimised = false

local W = Instance.new("Frame")
W.Size = UDim2.new(0, 256, 0, FULL_H)
W.Position = UDim2.new(0, 20, 0.5, -(FULL_H/2))
W.BackgroundColor3 = Color3.fromRGB(13, 13, 18)
W.BorderSizePixel = 0
W.ClipsDescendants = true
W.Active = true
W.Draggable = true
W.Parent = SG
Instance.new("UICorner", W).CornerRadius = UDim.new(0, 14)

local wGrad = Instance.new("UIGradient")
wGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(16,16,24)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10,10,15)),
})
wGrad.Rotation = 145
wGrad.Parent = W

local wStroke = Instance.new("UIStroke")
wStroke.Color = Color3.fromRGB(35, 35, 55)
wStroke.Thickness = 1
wStroke.Parent = W

local glow = Instance.new("Frame")
glow.Size = UDim2.new(1, 24, 1, 24)
glow.Position = UDim2.new(0, -12, 0, -12)
glow.BackgroundColor3 = Color3.fromRGB(0, 160, 255)
glow.BackgroundTransparency = 0.97
glow.BorderSizePixel = 0
glow.ZIndex = 0
glow.Parent = W
Instance.new("UICorner", glow).CornerRadius = UDim.new(0, 20)

-- top accent shimmer bar
local accent = Instance.new("Frame")
accent.Size = UDim2.new(1, 0, 0, 2)
accent.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
accent.BorderSizePixel = 0
accent.ZIndex = 6
accent.Parent = W
local aGrad = Instance.new("UIGradient")
aGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,0,0)),
    ColorSequenceKeypoint.new(0.3, Color3.fromRGB(0,180,255)),
    ColorSequenceKeypoint.new(0.7, Color3.fromRGB(0,220,255)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,0,0)),
})
aGrad.Parent = accent
task.spawn(function()
    local t = 0
    while SG.Parent do
        t += 0.03
        aGrad.Offset = Vector2.new(math.sin(t) * 0.9, 0)
        task.wait(0.03)
    end
end)

-- HEADER
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 52)
header.Position = UDim2.new(0, 0, 0, 2)
header.BackgroundTransparency = 1
header.ZIndex = 4
header.Parent = W

local iconCircle = Instance.new("Frame")
iconCircle.Size = UDim2.new(0, 34, 0, 34)
iconCircle.Position = UDim2.new(0, 12, 0.5, -17)
iconCircle.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
iconCircle.BackgroundTransparency = 0.75
iconCircle.BorderSizePixel = 0
iconCircle.ZIndex = 5
iconCircle.Parent = header
Instance.new("UICorner", iconCircle).CornerRadius = UDim.new(0, 10)
local iLbl = Instance.new("TextLabel")
iLbl.Size = UDim2.new(1,0,1,0)
iLbl.BackgroundTransparency = 1
iLbl.Text = "⚔️"
iLbl.TextSize = 17
iLbl.Font = Enum.Font.GothamBold
iLbl.ZIndex = 6
iLbl.Parent = iconCircle

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1,-110,0,18)
titleLbl.Position = UDim2.new(0,54,0,9)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "BLADE BALL"
titleLbl.Font = Enum.Font.GothamBlack
titleLbl.TextSize = 14
titleLbl.TextColor3 = Color3.fromRGB(235,235,255)
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.ZIndex = 5
titleLbl.Parent = header

local subLbl = Instance.new("TextLabel")
subLbl.Size = UDim2.new(1,-110,0,12)
subLbl.Position = UDim2.new(0,54,0,29)
subLbl.BackgroundTransparency = 1
subLbl.Text = "EXO HUB  •  discord.gg/6QzV9pTWs"
subLbl.Font = Enum.Font.GothamMedium
subLbl.TextSize = 8
subLbl.TextColor3 = Color3.fromRGB(55,55,85)
subLbl.TextXAlignment = Enum.TextXAlignment.Left
subLbl.ZIndex = 5
subLbl.Parent = header

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0,22,0,22)
minBtn.Position = UDim2.new(1,-52,0.5,-11)
minBtn.BackgroundColor3 = Color3.fromRGB(24,24,36)
minBtn.Text = "─"
minBtn.TextColor3 = Color3.fromRGB(100,100,140)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 10
minBtn.BorderSizePixel = 0
minBtn.ZIndex = 6
minBtn.Parent = header
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0,6)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,22,0,22)
closeBtn.Position = UDim2.new(1,-26,0.5,-11)
closeBtn.BackgroundColor3 = Color3.fromRGB(190,45,65)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 10
closeBtn.BorderSizePixel = 0
closeBtn.ZIndex = 6
closeBtn.Parent = header
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,6)

local hDiv = Instance.new("Frame")
hDiv.Size = UDim2.new(1,-24,0,1)
hDiv.Position = UDim2.new(0,12,0,53)
hDiv.BackgroundColor3 = Color3.fromRGB(28,28,42)
hDiv.BorderSizePixel = 0
hDiv.ZIndex = 4
hDiv.Parent = W

closeBtn.MouseButton1Click:Connect(function()
    for k in pairs(states) do states[k] = false end
    stopAutoParry(); stopAntiDie(); stopFly()
    SG:Destroy()
end)

minBtn.MouseButton1Click:Connect(function()
    minimised = not minimised
    minBtn.Text = minimised and "+" or "─"
    TweenService:Create(W, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 256, 0, minimised and MINI_H or FULL_H)
    }):Play()
end)

-- ══════════════════════════════════════
--  TOGGLE BUILDER
-- ══════════════════════════════════════
local yOff = 62

local function makeToggle(cfg)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,-16,0,52)
    row.Position = UDim2.new(0,8,0,yOff)
    row.BackgroundColor3 = Color3.fromRGB(19,19,28)
    row.BorderSizePixel = 0
    row.ZIndex = 4
    row.Parent = W
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,11)

    local rowStroke = Instance.new("UIStroke")
    rowStroke.Color = Color3.fromRGB(30,30,46)
    rowStroke.Thickness = 1
    rowStroke.Parent = row

    local iBg = Instance.new("Frame")
    iBg.Size = UDim2.new(0,34,0,34)
    iBg.Position = UDim2.new(0,9,0.5,-17)
    iBg.BackgroundColor3 = cfg.color
    iBg.BackgroundTransparency = 0.8
    iBg.BorderSizePixel = 0
    iBg.ZIndex = 5
    iBg.Parent = row
    Instance.new("UICorner", iBg).CornerRadius = UDim.new(0,9)

    local iLbl2 = Instance.new("TextLabel")
    iLbl2.Size = UDim2.new(1,0,1,0)
    iLbl2.BackgroundTransparency = 1
    iLbl2.Text = cfg.icon
    iLbl2.TextSize = 16
    iLbl2.Font = Enum.Font.GothamBold
    iLbl2.ZIndex = 6
    iLbl2.Parent = iBg

    local nLbl = Instance.new("TextLabel")
    nLbl.Size = UDim2.new(1,-100,0,17)
    nLbl.Position = UDim2.new(0,51,0,9)
    nLbl.BackgroundTransparency = 1
    nLbl.Text = cfg.name
    nLbl.Font = Enum.Font.GothamBold
    nLbl.TextSize = 12
    nLbl.TextColor3 = Color3.fromRGB(210,210,235)
    nLbl.TextXAlignment = Enum.TextXAlignment.Left
    nLbl.ZIndex = 5
    nLbl.Parent = row

    local dLbl = Instance.new("TextLabel")
    dLbl.Size = UDim2.new(1,-100,0,12)
    dLbl.Position = UDim2.new(0,51,0,27)
    dLbl.BackgroundTransparency = 1
    dLbl.Text = cfg.desc
    dLbl.Font = Enum.Font.GothamMedium
    dLbl.TextSize = 9
    dLbl.TextColor3 = Color3.fromRGB(50,50,78)
    dLbl.TextXAlignment = Enum.TextXAlignment.Left
    dLbl.ZIndex = 5
    dLbl.Parent = row

    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0,38,0,20)
    pill.AnchorPoint = Vector2.new(1,0.5)
    pill.Position = UDim2.new(1,-10,0.5,0)
    pill.BackgroundColor3 = Color3.fromRGB(26,26,40)
    pill.BorderSizePixel = 0
    pill.ZIndex = 5
    pill.Parent = row
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1,0)

    local pillStroke = Instance.new("UIStroke")
    pillStroke.Color = Color3.fromRGB(40,40,60)
    pillStroke.Thickness = 1
    pillStroke.Parent = pill

    local ballDot = Instance.new("Frame")
    ballDot.Size = UDim2.new(0,13,0,13)
    ballDot.AnchorPoint = Vector2.new(0.5,0.5)
    ballDot.Position = UDim2.new(0.28,0,0.5,0)
    ballDot.BackgroundColor3 = Color3.fromRGB(65,65,95)
    ballDot.BorderSizePixel = 0
    ballDot.ZIndex = 6
    ballDot.Parent = pill
    Instance.new("UICorner", ballDot).CornerRadius = UDim.new(1,0)

    local clickBtn = Instance.new("TextButton")
    clickBtn.Size = UDim2.new(1,0,1,0)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text = ""
    clickBtn.ZIndex = 7
    clickBtn.Parent = row

    local ti = TweenInfo.new(0.2, Enum.EasingStyle.Quart)
    clickBtn.MouseButton1Click:Connect(function()
        states[cfg.key] = not states[cfg.key]
        local on = states[cfg.key]
        TweenService:Create(pill,       ti, {BackgroundColor3 = on and cfg.color or Color3.fromRGB(26,26,40)}):Play()
        TweenService:Create(pillStroke, ti, {Color = on and cfg.color or Color3.fromRGB(40,40,60), Transparency = on and 0.5 or 0}):Play()
        TweenService:Create(ballDot,    ti, {Position = on and UDim2.new(0.72,0,0.5,0) or UDim2.new(0.28,0,0.5,0), BackgroundColor3 = on and Color3.fromRGB(255,255,255) or Color3.fromRGB(65,65,95)}):Play()
        TweenService:Create(iBg,        ti, {BackgroundTransparency = on and 0.5 or 0.8}):Play()
        TweenService:Create(rowStroke,  ti, {Color = on and cfg.color or Color3.fromRGB(30,30,46), Transparency = on and 0.4 or 0}):Play()
        if on then cfg.onEnable() else cfg.onDisable() end
    end)

    yOff = yOff + 58
end

makeToggle({key="autoParry", name="Auto Parry",  desc="Perfectly times the BLOCK button",  icon="🛡️", color=Color3.fromRGB(0,190,255),  onEnable=startAutoParry, onDisable=stopAutoParry})
makeToggle({key="antiDie",   name="Anti Die",    desc="Locks health at max every frame",    icon="💀",  color=Color3.fromRGB(255,100,0),  onEnable=startAntiDie,   onDisable=stopAntiDie})
makeToggle({key="speed",     name="Speed Hack",  desc="Walk speed boosted to 80",           icon="⚡",  color=Color3.fromRGB(255,200,0),  onEnable=function() setSpeed(true) end, onDisable=function() setSpeed(false) end})
makeToggle({key="fly",       name="Fly",         desc="WASD  •  Space up  •  Shift down",   icon="🛸",  color=Color3.fromRGB(130,70,255), onEnable=function() flyActive=true; startFly() end, onDisable=stopFly})
makeToggle({key="ballESP",   name="Ball ESP",    desc="Highlights the ball through walls",  icon="👁",  color=Color3.fromRGB(0,220,110),  onEnable=startBallESP, onDisable=function() states.ballESP=false; if espHL then pcall(function() espHL:Destroy() end); espHL=nil end end})

-- ══════════════════════════════════════
--  PULSE
-- ══════════════════════════════════════
local t = 0
RunService.Heartbeat:Connect(function(dt)
    if not SG.Parent then return end
    t += dt
    local pulse = (math.sin(t * 2.2) + 1) / 2
    local anyOn = states.autoParry or states.speed or states.fly or states.ballESP or states.antiDie
    if anyOn then
        wStroke.Color = Color3.fromRGB(
            math.floor(pulse * 20),
            math.floor(120 + pulse * 60),
            math.floor(200 + pulse * 55)
        )
        wStroke.Thickness = 1 + pulse * 0.6
        glow.BackgroundTransparency = 0.90 + pulse * 0.06
    else
        wStroke.Color = Color3.fromRGB(35,35,55)
        wStroke.Thickness = 1
        glow.BackgroundTransparency = 0.97
    end
end)

-- ══════════════════════════════════════
--  OPEN ANIMATION
-- ══════════════════════════════════════
W.Position = UDim2.new(-0.6, 0, 0.5, -(FULL_H/2))
TweenService:Create(W, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Position = UDim2.new(0, 20, 0.5, -(FULL_H/2))
}):Play()

print("[EXO HUB] Blade Ball loaded | discord.gg/6QzV9pTWs")
