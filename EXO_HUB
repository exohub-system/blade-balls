-- ╔═══════════════════════════════════╗
--   EXO HUB | BLADE BALL
--   discord.gg/6QzV9pTWs
-- ╚═══════════════════════════════════╝

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local lp = Players.LocalPlayer

-- ══════════════════════════════════════
--  STATE
-- ══════════════════════════════════════
local states = {
    autoParry  = false,
    speed      = false,
    fly        = false,
    ballESP    = false,
    antiDie    = false,
    autoSkill  = false,
}

local parryConn   = nil
local flyConn     = nil
local antiDieConn = nil
local skillConn   = nil
local espHL       = nil
local lastParry   = 0
local flyActive   = false
local bodyGyro    = nil
local bodyVel     = nil
local parryDist   = 30
local flySpeed    = 50

-- ══════════════════════════════════════
--  HELPERS
-- ══════════════════════════════════════
local function getChar() return lp.Character end
local function getHRP()  local c=getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()  local c=getChar(); return c and c:FindFirstChildOfClass("Humanoid") end

local function findBall()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if (n:find("ball") or n:find("blade") or n:find("proj") or n:find("kill")) and obj.Size.Magnitude < 12 then
                return obj
            end
        end
    end
end

-- ══════════════════════════════════════
--  AUTO PARRY
-- ══════════════════════════════════════
local function tryParry()
    local now = tick()
    if now - lastParry < 0.08 then return end
    lastParry = now

    -- fire all parry remotes
    pcall(function()
        for _, v in ipairs(game:GetDescendants()) do
            if v:IsA("RemoteEvent") then
                local n = v.Name:lower()
                if n:find("parry") or n:find("block") or n:find("deflect") or n:find("reflect") or n:find("guard") then
                    v:FireServer()
                end
            end
        end
    end)

    -- simulate E and F key presses (common parry keys)
    pcall(function()
        local vim = cloneref and cloneref(game:GetService("VirtualInputManager")) or game:GetService("VirtualInputManager")
        vim:SendKeyEvent(true,  Enum.KeyCode.E, false, game)
        task.wait(0.04)
        vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        vim:SendKeyEvent(true,  Enum.KeyCode.F, false, game)
        task.wait(0.04)
        vim:SendKeyEvent(false, Enum.KeyCode.F, false, game)
    end)

    -- click any parry GUI buttons
    pcall(function()
        for _, gui in ipairs(lp.PlayerGui:GetDescendants()) do
            if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                local n = gui.Name:lower()
                if n:find("parry") or n:find("block") or n:find("deflect") then
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
        local hrp = getHRP()
        if not hrp then return end
        if (ball.Position - hrp.Position).Magnitude <= parryDist then
            tryParry()
        end
    end)
end

local function stopAutoParry()
    if parryConn then parryConn:Disconnect(); parryConn = nil end
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
    local char = getChar()
    if not char then return end
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
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0,1,0) end
        bodyVel.Velocity = dir.Magnitude > 0 and dir.Unit * flySpeed or Vector3.zero
        bodyGyro.CFrame = cam.CFrame
    end)
end

local function stopFly()
    flyActive = false
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    local hum = getHum()
    local hrp = getHRP()
    if bodyGyro then bodyGyro:Destroy(); bodyGyro = nil end
    if bodyVel  then bodyVel:Destroy();  bodyVel  = nil end
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
        local ball = findBall()
        if ball and ball.Parent then
            if not espHL then
                espHL = Instance.new("SelectionBox")
                espHL.Color3 = Color3.fromRGB(0,200,255)
                espHL.LineThickness = 0.06
                espHL.SurfaceTransparency = 0.7
                espHL.SurfaceColor3 = Color3.fromRGB(0,200,255)
            end
            espHL.Adornee = ball
            espHL.Parent = workspace
        else
            if espHL then pcall(function() espHL:Destroy() end); espHL = nil end
        end
    end)
end

-- ══════════════════════════════════════
--  AUTO SKILL
-- ══════════════════════════════════════
local function startAutoSkill()
    skillConn = RunService.Heartbeat:Connect(function()
        if not states.autoSkill then return end
        local ball = findBall()
        local hrp = getHRP()
        if not ball or not hrp then return end
        if (ball.Position - hrp.Position).Magnitude > 40 then return end
        pcall(function()
            local vim = cloneref and cloneref(game:GetService("VirtualInputManager")) or game:GetService("VirtualInputManager")
            vim:SendKeyEvent(true,  Enum.KeyCode.Q, false, game)
            task.wait(0.04)
            vim:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
        end)
        pcall(function()
            for _, v in ipairs(game:GetDescendants()) do
                if v:IsA("RemoteEvent") then
                    local n = v.Name:lower()
                    if n:find("skill") or n:find("ability") or n:find("power") then
                        v:FireServer()
                    end
                end
            end
        end)
    end)
end

local function stopAutoSkill()
    if skillConn then skillConn:Disconnect(); skillConn = nil end
end

-- ══════════════════════════════════════
--  ANTI DIE
-- ══════════════════════════════════════
local function startAntiDie()
    antiDieConn = RunService.Heartbeat:Connect(function()
        if not states.antiDie then return end
        local hum = getHum()
        if hum and hum.Health < hum.MaxHealth then
            hum.Health = hum.MaxHealth
        end
    end)
end

local function stopAntiDie()
    if antiDieConn then antiDieConn:Disconnect(); antiDieConn = nil end
end

-- respawn handler
lp.CharacterAdded:Connect(function()
    task.wait(1)
    if states.speed   then setSpeed(true) end
    if states.fly     then flyActive=true; startFly() end
    if states.antiDie then startAntiDie() end
end)

-- ══════════════════════════════════════
--  GUI — RAYFIELD-INSPIRED CLEAN UI
-- ══════════════════════════════════════
if lp.PlayerGui:FindFirstChild("ExoBBGui") then lp.PlayerGui.ExoBBGui:Destroy() end

local SG = Instance.new("ScreenGui")
SG.Name = "ExoBBGui"
SG.ResetOnSpawn = false
SG.DisplayOrder = 999
SG.IgnoreGuiInset = true
SG.Parent = lp.PlayerGui

local FULL_W = 300
local FULL_H = 460
local MINI_H = 48
local minimised = false

-- MAIN WINDOW
local W = Instance.new("Frame")
W.Size = UDim2.new(0, FULL_W, 0, FULL_H)
W.Position = UDim2.new(0.5, -(FULL_W/2), 0.5, -(FULL_H/2))
W.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
W.BorderSizePixel = 0
W.ClipsDescendants = true
W.Active = true
W.Draggable = true
W.Parent = SG
Instance.new("UICorner", W).CornerRadius = UDim.new(0, 12)

-- shadow
local shadow = Instance.new("ImageLabel")
shadow.Size = UDim2.new(1, 30, 1, 30)
shadow.Position = UDim2.new(0, -15, 0, -15)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://6015897843"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.5
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(49,49,450,450)
shadow.ZIndex = 0
shadow.Parent = W

local wStroke = Instance.new("UIStroke")
wStroke.Color = Color3.fromRGB(40, 40, 55)
wStroke.Thickness = 1
wStroke.Parent = W

-- SIDEBAR
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 52, 1, 0)
sidebar.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
sidebar.BorderSizePixel = 0
sidebar.ZIndex = 2
sidebar.Parent = W

local sideGrad = Instance.new("UIGradient")
sideGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(12,12,18)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8,8,12)),
})
sideGrad.Rotation = 90
sideGrad.Parent = sidebar

-- sidebar accent line
local sideAccent = Instance.new("Frame")
sideAccent.Size = UDim2.new(0, 1, 1, 0)
sideAccent.Position = UDim2.new(1, 0, 0, 0)
sideAccent.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
sideAccent.BorderSizePixel = 0
sideAccent.ZIndex = 3
sideAccent.Parent = sidebar

-- logo on sidebar
local logoFrame = Instance.new("Frame")
logoFrame.Size = UDim2.new(1, 0, 0, 52)
logoFrame.BackgroundTransparency = 1
logoFrame.ZIndex = 3
logoFrame.Parent = sidebar

local logoLbl = Instance.new("TextLabel")
logoLbl.Size = UDim2.new(1,0,1,0)
logoLbl.BackgroundTransparency = 1
logoLbl.Text = "⚔️"
logoLbl.TextSize = 22
logoLbl.Font = Enum.Font.GothamBold
logoLbl.ZIndex = 4
logoLbl.Parent = logoFrame

-- CONTENT AREA
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -52, 1, 0)
content.Position = UDim2.new(0, 52, 0, 0)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ZIndex = 2
content.Parent = W

-- HEADER
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 52)
header.BackgroundTransparency = 1
header.BorderSizePixel = 0
header.ZIndex = 3
header.Parent = content

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1, -70, 0, 28)
titleLbl.Position = UDim2.new(0, 16, 0, 6)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "Blade Ball"
titleLbl.Font = Enum.Font.GothamBlack
titleLbl.TextSize = 18
titleLbl.TextColor3 = Color3.fromRGB(240, 240, 255)
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.ZIndex = 4
titleLbl.Parent = header

local subLbl = Instance.new("TextLabel")
subLbl.Size = UDim2.new(1, -70, 0, 14)
subLbl.Position = UDim2.new(0, 16, 0, 32)
subLbl.BackgroundTransparency = 1
subLbl.Text = "EXO HUB  •  discord.gg/6QzV9pTWs"
subLbl.Font = Enum.Font.GothamMedium
subLbl.TextSize = 9
subLbl.TextColor3 = Color3.fromRGB(70, 70, 100)
subLbl.TextXAlignment = Enum.TextXAlignment.Left
subLbl.ZIndex = 4
subLbl.Parent = header

-- header buttons
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 24, 0, 24)
minBtn.Position = UDim2.new(1, -54, 0.5, -12)
minBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
minBtn.Text = "─"
minBtn.TextColor3 = Color3.fromRGB(120, 120, 160)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 11
minBtn.BorderSizePixel = 0
minBtn.ZIndex = 5
minBtn.Parent = header
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -26, 0.5, -12)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 70)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 10
closeBtn.BorderSizePixel = 0
closeBtn.ZIndex = 5
closeBtn.Parent = header
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

-- header divider
local hDiv = Instance.new("Frame")
hDiv.Size = UDim2.new(1, -16, 0, 1)
hDiv.Position = UDim2.new(0, 8, 0, 51)
hDiv.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
hDiv.BorderSizePixel = 0
hDiv.ZIndex = 3
hDiv.Parent = content

closeBtn.MouseButton1Click:Connect(function()
    states.autoParry = false
    states.speed = false
    states.fly = false
    states.ballESP = false
    states.antiDie = false
    states.autoSkill = false
    stopFly()
    stopAntiDie()
    stopAutoParry()
    stopAutoSkill()
    SG:Destroy()
end)

minBtn.MouseButton1Click:Connect(function()
    minimised = not minimised
    minBtn.Text = minimised and "+" or "─"
    TweenService:Create(W, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, FULL_W, 0, minimised and MINI_H or FULL_H)
    }):Play()
end)

-- SCROLL AREA
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, 0, 1, -60)
scroll.Position = UDim2.new(0, 0, 0, 60)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 2
scroll.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 90)
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ZIndex = 3
scroll.Parent = content

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 4)
layout.Parent = scroll

local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0,10)
pad.PaddingRight = UDim.new(0,10)
pad.PaddingTop = UDim.new(0,8)
pad.PaddingBottom = UDim.new(0,8)
pad.Parent = scroll

-- ══════════════════════════════════════
--  SECTION LABEL
-- ══════════════════════════════════════
local function makeSection(labelTxt, order)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1,0,0,24)
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.LayoutOrder = order
    f.ZIndex = 4
    f.Parent = scroll

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelTxt:upper()
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextColor3 = Color3.fromRGB(80,80,120)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LetterSpacing = 2
    lbl.ZIndex = 5
    lbl.Parent = f
end

-- ══════════════════════════════════════
--  TOGGLE ROW
-- ══════════════════════════════════════
local function makeToggle(cfg)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,52)
    row.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    row.BorderSizePixel = 0
    row.LayoutOrder = cfg.order
    row.ZIndex = 4
    row.Parent = scroll
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)

    -- icon
    local iconBox = Instance.new("Frame")
    iconBox.Size = UDim2.new(0, 34, 0, 34)
    iconBox.Position = UDim2.new(0, 10, 0.5, -17)
    iconBox.BackgroundColor3 = cfg.color
    iconBox.BackgroundTransparency = 0.85
    iconBox.BorderSizePixel = 0
    iconBox.ZIndex = 5
    iconBox.Parent = row
    Instance.new("UICorner", iconBox).CornerRadius = UDim.new(0, 8)

    local iconLbl = Instance.new("TextLabel")
    iconLbl.Size = UDim2.new(1,0,1,0)
    iconLbl.BackgroundTransparency = 1
    iconLbl.Text = cfg.icon
    iconLbl.TextSize = 16
    iconLbl.Font = Enum.Font.GothamBold
    iconLbl.ZIndex = 6
    iconLbl.Parent = iconBox

    -- name
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1,-100,0,18)
    nameLbl.Position = UDim2.new(0,52,0,9)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = cfg.name
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 13
    nameLbl.TextColor3 = Color3.fromRGB(210, 210, 230)
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.ZIndex = 5
    nameLbl.Parent = row

    -- desc
    local descLbl = Instance.new("TextLabel")
    descLbl.Size = UDim2.new(1,-100,0,14)
    descLbl.Position = UDim2.new(0,52,0,28)
    descLbl.BackgroundTransparency = 1
    descLbl.Text = cfg.desc
    descLbl.Font = Enum.Font.GothamMedium
    descLbl.TextSize = 10
    descLbl.TextColor3 = Color3.fromRGB(60, 60, 90)
    descLbl.TextXAlignment = Enum.TextXAlignment.Left
    descLbl.ZIndex = 5
    descLbl.Parent = row

    -- toggle pill
    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 38, 0, 20)
    pill.AnchorPoint = Vector2.new(1, 0.5)
    pill.Position = UDim2.new(1, -10, 0.5, 0)
    pill.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    pill.BorderSizePixel = 0
    pill.ZIndex = 5
    pill.Parent = row
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

    local ball = Instance.new("Frame")
    ball.Size = UDim2.new(0, 14, 0, 14)
    ball.AnchorPoint = Vector2.new(0.5, 0.5)
    ball.Position = UDim2.new(0.28, 0, 0.5, 0)
    ball.BackgroundColor3 = Color3.fromRGB(80, 80, 110)
    ball.BorderSizePixel = 0
    ball.ZIndex = 6
    ball.Parent = pill
    Instance.new("UICorner", ball).CornerRadius = UDim.new(1, 0)

    local clickArea = Instance.new("TextButton")
    clickArea.Size = UDim2.new(1,0,1,0)
    clickArea.BackgroundTransparency = 1
    clickArea.Text = ""
    clickArea.ZIndex = 7
    clickArea.Parent = row

    local ti = TweenInfo.new(0.2, Enum.EasingStyle.Quart)
    clickArea.MouseButton1Click:Connect(function()
        states[cfg.key] = not states[cfg.key]
        local on = states[cfg.key]
        TweenService:Create(pill, ti, {BackgroundColor3 = on and cfg.color or Color3.fromRGB(30,30,45)}):Play()
        TweenService:Create(ball, ti, {
            Position = on and UDim2.new(0.72,0,0.5,0) or UDim2.new(0.28,0,0.5,0),
            BackgroundColor3 = on and Color3.fromRGB(255,255,255) or Color3.fromRGB(80,80,110)
        }):Play()
        TweenService:Create(iconBox, ti, {BackgroundTransparency = on and 0.6 or 0.85}):Play()
        TweenService:Create(row, ti, {BackgroundColor3 = on and Color3.fromRGB(26,26,36) or Color3.fromRGB(22,22,30)}):Play()
        if on then cfg.onEnable() else cfg.onDisable() end
    end)

    -- hover
    clickArea.MouseEnter:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(26,26,36)}):Play()
    end)
    clickArea.MouseLeave:Connect(function()
        if not states[cfg.key] then
            TweenService:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(22,22,30)}):Play()
        end
    end)
end

-- ══════════════════════════════════════
--  SLIDER
-- ══════════════════════════════════════
local function makeSlider(cfg)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,58)
    row.BackgroundColor3 = Color3.fromRGB(22,22,30)
    row.BorderSizePixel = 0
    row.LayoutOrder = cfg.order
    row.ZIndex = 4
    row.Parent = scroll
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,10)

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1,-60,0,16)
    nameLbl.Position = UDim2.new(0,12,0,10)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = cfg.name
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 12
    nameLbl.TextColor3 = Color3.fromRGB(210,210,230)
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.ZIndex = 5
    nameLbl.Parent = row

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0,50,0,16)
    valLbl.Position = UDim2.new(1,-58,0,10)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(cfg.default) .. cfg.suffix
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 11
    valLbl.TextColor3 = cfg.color
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.ZIndex = 5
    valLbl.Parent = row

    local trackBg = Instance.new("Frame")
    trackBg.Size = UDim2.new(1,-24,0,4)
    trackBg.Position = UDim2.new(0,12,0,38)
    trackBg.BackgroundColor3 = Color3.fromRGB(35,35,50)
    trackBg.BorderSizePixel = 0
    trackBg.ZIndex = 5
    trackBg.Parent = row
    Instance.new("UICorner", trackBg).CornerRadius = UDim.new(1,0)

    local pct = (cfg.default - cfg.min) / (cfg.max - cfg.min)
    local trackFill = Instance.new("Frame")
    trackFill.Size = UDim2.new(pct, 0, 1, 0)
    trackFill.BackgroundColor3 = cfg.color
    trackFill.BorderSizePixel = 0
    trackFill.ZIndex = 6
    trackFill.Parent = trackBg
    Instance.new("UICorner", trackFill).CornerRadius = UDim.new(1,0)

    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.new(0,12,0,12)
    thumb.AnchorPoint = Vector2.new(0.5,0.5)
    thumb.Position = UDim2.new(pct,0,0.5,0)
    thumb.BackgroundColor3 = Color3.fromRGB(240,240,255)
    thumb.BorderSizePixel = 0
    thumb.ZIndex = 7
    thumb.Parent = trackBg
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1,0)

    local dragging = false
    thumb.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then return end
        local rel = math.clamp((i.Position.X - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X, 0, 1)
        local val = math.floor(cfg.min + rel * (cfg.max - cfg.min))
        trackFill.Size = UDim2.new(rel,0,1,0)
        thumb.Position = UDim2.new(rel,0,0.5,0)
        valLbl.Text = tostring(val) .. cfg.suffix
        cfg.onChange(val)
    end)
end

-- ══════════════════════════════════════
--  BUILD FEATURES
-- ══════════════════════════════════════
makeSection("Combat", 1)

makeToggle({
    key="autoParry", name="Auto Parry", desc="Automatically parries the ball",
    icon="🛡️", color=Color3.fromRGB(0,200,255), order=2,
    onEnable = startAutoParry,
    onDisable = stopAutoParry,
})

makeToggle({
    key="autoSkill", name="Auto Skill", desc="Auto fires skill when ball is close",
    icon="✨", color=Color3.fromRGB(180,0,255), order=3,
    onEnable = startAutoSkill,
    onDisable = stopAutoSkill,
})

makeToggle({
    key="antiDie", name="Anti Die", desc="Locks health at max every frame",
    icon="💀", color=Color3.fromRGB(255,120,0), order=4,
    onEnable = startAntiDie,
    onDisable = stopAntiDie,
})

makeSection("Movement", 5)

makeToggle({
    key="speed", name="Speed Hack", desc="Increases walk speed to 80",
    icon="⚡", color=Color3.fromRGB(255,200,0), order=6,
    onEnable = function() setSpeed(true) end,
    onDisable = function() setSpeed(false) end,
})

makeToggle({
    key="fly", name="Fly", desc="WASD to move, Space/Shift up/down",
    icon="🛸", color=Color3.fromRGB(120,80,255), order=7,
    onEnable = function() flyActive=true; startFly() end,
    onDisable = stopFly,
})

makeSlider({
    name="Fly Speed", suffix=" sp", min=10, max=150, default=50,
    color=Color3.fromRGB(120,80,255), order=8,
    onChange = function(v) flySpeed = v end,
})

makeSection("Visuals", 9)

makeToggle({
    key="ballESP", name="Ball ESP", desc="Highlights the ball through walls",
    icon="👁", color=Color3.fromRGB(0,230,120), order=10,
    onEnable = startBallESP,
    onDisable = function()
        states.ballESP = false
        if espHL then pcall(function() espHL:Destroy() end); espHL = nil end
    end,
})

makeSlider({
    name="Parry Distance", suffix=" st", min=5, max=80, default=30,
    color=Color3.fromRGB(0,200,255), order=11,
    onChange = function(v) parryDist = v end,
})

-- ══════════════════════════════════════
--  PULSE ANIMATION
-- ══════════════════════════════════════
local t = 0
RunService.Heartbeat:Connect(function(dt)
    if not SG.Parent then return end
    t += dt
    local pulse = (math.sin(t*2)+1)/2
    local anyOn = states.autoParry or states.speed or states.fly or states.ballESP or states.antiDie or states.autoSkill
    if anyOn then
        wStroke.Color = Color3.fromRGB(
            math.floor(40 + pulse*20),
            math.floor(40 + pulse*20),
            math.floor(60 + pulse*30)
        )
    else
        wStroke.Color = Color3.fromRGB(40,40,55)
    end
end)

-- ══════════════════════════════════════
--  OPEN ANIMATION
-- ══════════════════════════════════════
W.Position = UDim2.new(0.5, -(FULL_W/2), -0.5, 0)
TweenService:Create(W, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Position = UDim2.new(0.5, -(FULL_W/2), 0.5, -(FULL_H/2))
}):Play()

print("[EXO HUB] Blade Ball loaded | discord.gg/6QzV9pTWs")
