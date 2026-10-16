local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local LP = Players.LocalPlayer

-- =====================================================================
--  CUSTOM UI  (tema ungu-biru, sidebar tab, bisa dilipat dengan tombol - / +)
-- =====================================================================
local C = {
    bg     = Color3.fromRGB(8, 8, 140),     -- bingkai luar
    panel  = Color3.fromRGB(92, 75, 158),   -- panel isi
    side   = Color3.fromRGB(62, 48, 128),   -- sidebar
    row    = Color3.fromRGB(100, 82, 170),  -- tombol / baris
    tabOn  = Color3.fromRGB(145, 120, 235), -- tab terpilih
    off    = Color3.fromRGB(70, 55, 140),   -- toggle mati / track slider
    line   = Color3.fromRGB(45, 25, 255),   -- garis biru
    text   = Color3.fromRGB(255, 255, 255),
    dim    = Color3.fromRGB(215, 205, 240),
    accent = Color3.fromRGB(150, 125, 255),
    on     = Color3.fromRGB(120, 255, 170), -- toggle nyala
}

local function create(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do
        o[k] = v
    end
    o.Parent = parent
    return o
end

local function corner(o, r)
    create("UICorner", { CornerRadius = UDim.new(0, r or 6) }, o)
end

local function stroke(o, color, thick)
    create("UIStroke", { Color = color or C.line, Thickness = thick or 1 }, o)
end

local function padding(o, p)
    create("UIPadding", {
        PaddingTop = UDim.new(0, p), PaddingBottom = UDim.new(0, p),
        PaddingLeft = UDim.new(0, p), PaddingRight = UDim.new(0, p),
    }, o)
end

local function label(parent, text, size, color, align)
    return create("TextLabel", {
        BackgroundTransparency = 1,
        Text = text,
        TextSize = size or 14,
        TextColor3 = color or C.text,
        Font = Enum.Font.FredokaOne,
        TextXAlignment = align or Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 1, 0),
    }, parent)
end

local function tween(o, props)
    TweenService:Create(o, TweenInfo.new(0.15), props):Play()
end

local function safe(fn, ...)
    if fn then
        pcall(fn, ...)
    end
end

local function isPointer(i)
    return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end

local function isMove(i)
    return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch
end

-- baris dasar: judul + (opsional) description di bawahnya
local function makeRow(scroll, order, cfg, centered, reserve)
    local hasDesc = cfg.Description ~= nil and cfg.Description ~= ""
    local h = hasDesc and 52 or 38
    local row = create("Frame", { BackgroundColor3 = C.row, Size = UDim2.new(1, 0, 0, h), LayoutOrder = order }, scroll)
    corner(row, 6)
    stroke(row, C.line, 2)

    local align = centered and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
    local t = label(row, cfg.Title, 15, C.text, align)
    t.Position = UDim2.fromOffset(10, hasDesc and 5 or 0)
    t.Size = UDim2.new(1, -(20 + (reserve or 0)), 0, hasDesc and 22 or h)

    if hasDesc then
        local d = label(row, cfg.Description, 11, C.dim, align)
        d.Font = Enum.Font.Gotham
        d.TextTruncate = Enum.TextTruncate.AtEnd
        d.Position = UDim2.fromOffset(10, 28)
        d.Size = UDim2.new(1, -(20 + (reserve or 0)), 0, 16)
    end
    return row
end

local function makeColumn(scroll)
    local col = {}
    local order = 0
    local function nextOrder()
        order += 1
        return order
    end

    -- judul kolom (seperti "button", "Dropdown", "Toggle")
    function col:Section(text)
        local l = label(scroll, text, 17, C.text, Enum.TextXAlignment.Center)
        l.Size = UDim2.new(1, 0, 0, 24)
        l.LayoutOrder = nextOrder()
    end

    function col:Paragraph(text)
        local l = create("TextLabel", {
            BackgroundTransparency = 1,
            Text = text or "",
            TextWrapped = true,
            TextColor3 = C.text,
            TextSize = 13,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = nextOrder(),
        }, scroll)
        return { Set = function(_, s) l.Text = s end }
    end

    function col:Button(cfg)
        local row = makeRow(scroll, nextOrder(), cfg, true, 0)
        local hit = create("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0) }, row)
        hit.Activated:Connect(function()
            safe(cfg.Callback)
        end)
    end

    function col:Toggle(cfg)
        local state = cfg.Default or false
        local row = makeRow(scroll, nextOrder(), cfg, false, 56)

        local sw = create("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(44, 22), BackgroundColor3 = C.off }, row)
        corner(sw, 6)
        local knob = create("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, 0), Size = UDim2.fromOffset(18, 18), BackgroundColor3 = Color3.fromRGB(40, 20, 130) }, sw)
        corner(knob, 4)

        local function render(anim)
            local pos = state and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
            local color = state and C.on or C.off
            if anim then
                tween(knob, { Position = pos })
                tween(sw, { BackgroundColor3 = color })
            else
                knob.Position = pos
                sw.BackgroundColor3 = color
            end
        end
        render(false)

        local hit = create("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0) }, row)
        hit.Activated:Connect(function()
            state = not state
            render(true)
            safe(cfg.Callback, state)
        end)

        return { Set = function(_, v) state = v; render(true) end }
    end

    function col:Slider(cfg)
        local min, max = cfg.Min, cfg.Max
        local value = cfg.Default or min

        local row = create("Frame", { BackgroundColor3 = C.row, Size = UDim2.new(1, 0, 0, 56), LayoutOrder = nextOrder() }, scroll)
        corner(row, 6)
        stroke(row, C.line, 2)

        local t = label(row, cfg.Title, 15)
        t.Position = UDim2.fromOffset(10, 4)
        t.Size = UDim2.new(1, -70, 0, 22)
        local v = label(row, tostring(value), 15, C.text, Enum.TextXAlignment.Right)
        v.Position = UDim2.new(1, -60, 0, 4)
        v.Size = UDim2.new(0, 50, 0, 22)

        local bar = create("Frame", { BackgroundColor3 = C.off, BorderSizePixel = 0, Position = UDim2.fromOffset(12, 36), Size = UDim2.new(1, -24, 0, 8) }, row)
        corner(bar, 4)
        local fill = create("Frame", { BackgroundColor3 = C.accent, BorderSizePixel = 0, Size = UDim2.new(0, 0, 1, 0) }, bar)
        corner(fill, 4)
        local knob = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, bar)
        corner(knob, 4)

        local function render()
            local a = (value - min) / (max - min)
            fill.Size = UDim2.new(a, 0, 1, 0)
            knob.Position = UDim2.new(a, 0, 0.5, 0)
            v.Text = tostring(value)
        end
        render()

        local dragging = false
        local function update(x)
            local a = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local nv = math.floor(min + a * (max - min) + 0.5)
            if nv ~= value then
                value = nv
                render()
                safe(cfg.Callback, value)
            end
        end

        local hit = create("TextButton", { Text = "", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 30) }, row)
        hit.InputBegan:Connect(function(i)
            if isPointer(i) then
                dragging = true
                update(i.Position.X)
            end
        end)
        UIS.InputChanged:Connect(function(i)
            if dragging and isMove(i) then
                update(i.Position.X)
            end
        end)
        UIS.InputEnded:Connect(function(i)
            if isPointer(i) then
                dragging = false
            end
        end)
    end

    function col:Dropdown(cfg)
        local current = cfg.Default or cfg.Options[1]

        local box = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 38), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = nextOrder() }, scroll)
        create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, box)

        local head = makeRow(box, 1, cfg, false, 150)

        local sel = create("TextButton", {
            Text = current,
            AutoButtonColor = false,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -8, 0.5, 0),
            Size = UDim2.fromOffset(136, 26),
            BackgroundColor3 = C.off,
            TextColor3 = C.text,
            TextSize = 12,
            Font = Enum.Font.FredokaOne,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, head)
        corner(sel, 5)
        stroke(sel, C.line, 1)

        local list = create("Frame", { BackgroundTransparency = 1, Visible = false, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2 }, box)
        create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, list)

        for idx, opt in ipairs(cfg.Options) do
            local ob = create("TextButton", {
                Text = opt,
                AutoButtonColor = false,
                BackgroundColor3 = C.row,
                TextColor3 = C.text,
                TextSize = 14,
                Font = Enum.Font.FredokaOne,
                Size = UDim2.new(1, 0, 0, 32),
                LayoutOrder = idx,
            }, list)
            corner(ob, 6)
            stroke(ob, C.line, 2)
            ob.Activated:Connect(function()
                current = opt
                sel.Text = opt
                list.Visible = false
                safe(cfg.Callback, opt)
            end)
        end

        sel.Activated:Connect(function()
            list.Visible = not list.Visible
        end)
    end

    return col
end

local function newScroll(parent, pos, size)
    local s = create("ScrollingFrame", {
        BackgroundColor3 = C.panel,
        BorderSizePixel = 0,
        Position = pos,
        Size = size,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollingDirection = Enum.ScrollingDirection.Y,
    }, parent)
    corner(s, 8)
    padding(s, 8)
    create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, s)
    return s
end

-- buat ScreenGui; coba beberapa parent (gethui -> CoreGui -> PlayerGui) sampai ada yang berhasil
local function makeGui(name)
    local gui = Instance.new("ScreenGui")
    gui.Name = name
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999

    if syn and syn.protect_gui then
        pcall(syn.protect_gui, gui)
    end

    local candidates = {
        function() return gethui and gethui() end,
        function() return CoreGui end,
        function() return LP:WaitForChild("PlayerGui", 5) end,
    }
    for _, getParent in ipairs(candidates) do
        local ok, p = pcall(getParent)
        if ok and p then
            local ok2 = pcall(function() gui.Parent = p end)
            if ok2 and gui.Parent == p then
                return gui
            end
        end
    end
    error("Tidak bisa menaruh UI di parent mana pun")
end

-- cfg: { Name = "...", Dev = "...", Description = "..." }
local function createWindow(cfg)
    local win = {}
    local gui = makeGui("YSSHub")

    local FULL = UDim2.fromOffset(540, 330)
    local FOLDED = UDim2.fromOffset(300, 78)

    local main = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = FULL,
        BackgroundColor3 = C.bg,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, gui)
    corner(main, 12)
    stroke(main, C.line, 3)

    -- header: nama hub, developer, description (selalu terlihat, juga saat dilipat)
    local header = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 72) }, main)

    local nameLbl = label(header, cfg.Name, 20, C.text)
    nameLbl.Position = UDim2.fromOffset(14, 6)
    nameLbl.Size = UDim2.new(1, -70, 0, 24)

    local devLbl = label(header, cfg.Dev, 12, C.dim)
    devLbl.Position = UDim2.fromOffset(14, 30)
    devLbl.Size = UDim2.new(1, -70, 0, 16)

    local descLbl = label(header, cfg.Description or "", 11, C.dim)
    descLbl.Font = Enum.Font.Gotham
    descLbl.TextTruncate = Enum.TextTruncate.AtEnd
    descLbl.Position = UDim2.fromOffset(14, 48)
    descLbl.Size = UDim2.new(1, -70, 0, 16)

    local foldBtn = create("TextButton", {
        Text = "-",
        AutoButtonColor = false,
        BackgroundColor3 = C.row,
        TextColor3 = C.text,
        TextSize = 26,
        Font = Enum.Font.FredokaOne,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -12, 0, 10),
        Size = UDim2.fromOffset(40, 40),
    }, header)
    corner(foldBtn, 8)
    stroke(foldBtn, C.line, 2)

    -- geser window lewat header
    local dragging, dragStart, startPos = false, nil, nil
    header.InputBegan:Connect(function(i)
        if isPointer(i) then
            dragging = true
            dragStart = i.Position
            startPos = main.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and isMove(i) then
            local d = i.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if isPointer(i) then
            dragging = false
        end
    end)

    -- isi: sidebar tab + konten
    local body = create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 74), Size = UDim2.new(1, -20, 1, -84) }, main)

    local side = create("ScrollingFrame", {
        BackgroundColor3 = C.side,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 120, 1, 0),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 0,
    }, body)
    corner(side, 8)
    padding(side, 6)
    create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, side)

    local content = create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(128, 0), Size = UDim2.new(1, -128, 1, 0) }, body)

    -- lipat / buka lagi (- dan +)
    local folded = false
    foldBtn.Activated:Connect(function()
        folded = not folded
        if folded then
            body.Visible = false
            foldBtn.Text = "+"
            TweenService:Create(main, TweenInfo.new(0.2), { Size = FOLDED }):Play()
        else
            foldBtn.Text = "-"
            TweenService:Create(main, TweenInfo.new(0.2), { Size = FULL }):Play()
            task.delay(0.2, function()
                if not folded then
                    body.Visible = true
                end
            end)
        end
    end)

    local tabs = {}
    local function selectTab(tab)
        for _, t in ipairs(tabs) do
            t.page.Visible = (t == tab)
            t.btn.BackgroundColor3 = (t == tab) and C.tabOn or C.row
        end
    end

    function win:AddTab(name)
        local btn = create("TextButton", {
            Text = name,
            AutoButtonColor = false,
            BackgroundColor3 = C.row,
            TextColor3 = C.text,
            TextSize = 15,
            Font = Enum.Font.FredokaOne,
            Size = UDim2.new(1, 0, 0, 40),
            LayoutOrder = #tabs + 1,
        }, side)
        corner(btn, 6)
        stroke(btn, C.line, 2)

        local page = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Visible = false }, content)
        local left = newScroll(page, UDim2.new(0, 0, 0, 0), UDim2.new(0.5, -4, 1, 0))
        local right = newScroll(page, UDim2.new(0.5, 4, 0, 0), UDim2.new(0.5, -4, 1, 0))

        local tab = { btn = btn, page = page, Left = makeColumn(left), Right = makeColumn(right) }
        table.insert(tabs, tab)
        btn.Activated:Connect(function()
            selectTab(tab)
        end)
        if #tabs == 1 then
            selectTab(tab)
        end
        return tab
    end

    function win:Notify(title, text, duration)
        local toast = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, -70),
            Size = UDim2.fromOffset(260, 50),
            BackgroundColor3 = C.bg,
        }, gui)
        corner(toast, 8)
        stroke(toast, C.line, 2)
        local a = label(toast, title or "", 14)
        a.Position = UDim2.fromOffset(10, 4)
        a.Size = UDim2.new(1, -20, 0, 20)
        local b = label(toast, text or "", 12, C.dim)
        b.Font = Enum.Font.Gotham
        b.Position = UDim2.fromOffset(10, 25)
        b.Size = UDim2.new(1, -20, 0, 20)
        tween(toast, { Position = UDim2.new(0.5, 0, 0, 12) })
        task.delay(duration or 3, function()
            tween(toast, { Position = UDim2.new(0.5, 0, 0, -70) })
            task.wait(0.3)
            toast:Destroy()
        end)
    end

    return win
end

-- =====================================================================
--  DATA & LOGIKA EGG
-- =====================================================================
local Zones = {
    { "Spooky Passage", Vector3.new(43.27, 122.00, 929.84) },
    { "Dead Zone",      Vector3.new(141.46, 122.00, 1436.46) },
    { "Monster Valley", Vector3.new(62.16, 122.00, 1920.62) },
    { "Pumpkins", Vector3.new(138.60, 122.00, 557.62) },
    { "Cholate Island", Vector3.new(142.18, 121.94, -131.31) },
    { "Candy Island", Vector3.new(47.01, 122.00, -369.22) },
    { "Starter", Vector3.new(49.36, 122.00, -687.12) },
}
local HOME = Vector3.new(91.04, 122.00, -750.97)

local ALTITUDE    = 50    -- naik berapa studs sebelum jalan
local STEP_DIST   = 50    -- jarak tiap teleport menuju Home
local STEP_DELAY  = 0.9   -- jeda tiap teleport (detik), bisa diganti lewat dropdown
local TWEEN_SPEED = 950   -- kecepatan tween ke zona (studs/detik)
local GRAB_TIME   = 0.5   -- lama menembak prompt egg di zona (detik)

local ZoneNames = {}
for _, z in ipairs(Zones) do
    table.insert(ZoneNames, z[1])
end

local SpeedOptions = {
    "1.0 (LOW SPEED)",
    "0.9 (Reasonable SPEED)",
    "0.5 (HIGH SPEED)",
    "0.1 (NOT SAFE)",
    "0.09 (NOT SAFE+)",
    "0.001 (NOT SAFE++++++++++++++)",
}

local selected = ZoneNames[1]
local running = false      -- Auto Egg
local grabRunning = false  -- Dual Auto Grab
local state = "Idle"
local cycles = 0

local statusLabel = nil
local notify = function() end

local function refresh()
    if statusLabel then
        statusLabel:Set(string.format(
            "Zone: %s\nState: %s\nSiklus selesai: %d\nTP delay: %.2fs\nTween speed: %d\nAltitude: %d | Step: %d studs",
            selected, state, cycles, STEP_DELAY, TWEEN_SPEED, ALTITUDE, STEP_DIST
        ))
    end
end

local function setState(s)
    state = s
    refresh()
end

local function getParts()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hrp, hum
end

local function zonePos(name)
    for _, z in ipairs(Zones) do
        if z[1] == name then
            return z[2]
        end
    end
end

local function moveTo(hrp, cf)
    hrp.CFrame = cf
    hrp.AssemblyLinearVelocity = Vector3.zero
end

-- block pengaman yang mengikuti di bawah kaki
local platform, platConn

local function startPlatform()
    if platform then
        return
    end
    platform = Instance.new("Part")
    platform.Name = "ZonePlatform"
    platform.Size = Vector3.new(10, 1, 10)
    platform.Anchored = true
    platform.CanCollide = true
    platform.Transparency = 0.6
    platform.Parent = workspace

    platConn = RunService.Heartbeat:Connect(function()
        local hrp, hum = getParts()
        if not hrp or not platform then
            return
        end
        local feet = (hum and hum.RigType == Enum.HumanoidRigType.R6) and 3 or ((hum and hum.HipHeight or 2) + hrp.Size.Y / 2)
        platform.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y - feet - 0.5, hrp.Position.Z)
    end)
end

local function stopPlatform()
    if platConn then
        platConn:Disconnect()
        platConn = nil
    end
    if platform then
        platform:Destroy()
        platform = nil
    end
end

-- Dual Auto Grab: fire sampai 2 ProximityPrompt dalam radius 100 studs
local function dualGrabEgg()
    local hrp = getParts()
    if not hrp then
        return
    end

    local prompts = {}
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Parent then
            local pPart = d.Parent:IsA("BasePart") and d.Parent or d.Parent:FindFirstChildWhichIsA("BasePart")
            if pPart and (pPart.Position - hrp.Position).Magnitude <= 100 then
                table.insert(prompts, d)
            end
        end
    end

    if #prompts >= 2 then
        task.spawn(function() pcall(fireproximityprompt, prompts[1]) end)
        task.spawn(function() pcall(fireproximityprompt, prompts[2]) end)
    elseif #prompts == 1 then
        task.spawn(function() pcall(fireproximityprompt, prompts[1]) end)
    end
end

-- loop toggle "Dual Auto Grab" (jalan terus selama toggle nyala)
task.spawn(function()
    while true do
        if grabRunning then
            dualGrabEgg()
        end
        task.wait(0.1)
    end
end)

-- tween halus ke posisi tujuan (bisa dihentikan lewat toggle)
local function tweenTo(targetCF)
    local hrp = getParts()
    if not hrp then
        return
    end

    local distance = (hrp.Position - targetCF.Position).Magnitude
    local duration = math.max(distance / TWEEN_SPEED, 0.01)
    local tw = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), { CFrame = targetCF })

    local conn = RunService.Stepped:Connect(function()
        local h = getParts()
        if h then
            h.AssemblyLinearVelocity = Vector3.zero
        end
    end)

    tw:Play()
    local t0 = tick()
    while running and tw.PlaybackState == Enum.PlaybackState.Playing and tick() - t0 < duration + 2 do
        task.wait(0.05)
    end
    tw:Cancel()
    conn:Disconnect()

    local h = getParts()
    if h and running then
        h.CFrame = targetCF
    end
end

local function runOnce(zone)
    local hrp, hum = getParts()
    if not hrp or not hum then
        return
    end

    -- 1) naik dulu + pasang block
    setState("Naik " .. ALTITUDE .. " studs")
    startPlatform()
    moveTo(hrp, hrp.CFrame + Vector3.new(0, ALTITUDE, 0))
    task.wait(0.05)

    -- 2) tween ke atas zona tujuan
    setState("Tween ke zona")
    tweenTo(CFrame.new(zone + Vector3.new(0, ALTITUDE, 0)))
    if not running then
        return
    end

    -- 3) turun ke zona
    hrp, hum = getParts()
    if not hrp or not hum then
        return
    end
    setState("Turun ke zona")
    moveTo(hrp, CFrame.new(zone))
    task.wait(0.2)

    -- 4) WalkTo pakai speed sendiri, lalu ambil egg (tembak prompt terus selama GRAB_TIME)
    setState("Ambil egg")
    hum:MoveTo(zone)
    task.wait(0.5)
    local t1 = tick()
    while running and tick() - t1 < GRAB_TIME do
        dualGrabEgg()
        task.wait(0.1)
    end
    if not running then
        return
    end

    -- 5) naik dulu lagi
    hrp = getParts()
    if not hrp then
        return
    end
    setState("Naik lagi")
    moveTo(hrp, CFrame.new(hrp.Position + Vector3.new(0, ALTITUDE, 0)))
    task.wait(0.05)

    -- 6) teleport bertahap (STEP_DIST studs tiap STEP_DELAY detik) ke atas Home
    setState("Menuju Home")
    hrp = getParts()
    if not hrp then
        return
    end
    local startPos = hrp.Position
    local endPos = HOME + Vector3.new(0, ALTITUDE, 0)
    local total = (endPos - startPos).Magnitude
    if total > 0 then
        local unit = (endPos - startPos).Unit
        local travelled = 0
        while running and travelled < total do
            travelled = math.min(travelled + STEP_DIST, total)
            local h = getParts()
            if h then
                moveTo(h, CFrame.new(startPos + unit * travelled))
            end
            task.wait(STEP_DELAY)
        end
    end
    if not running then
        return
    end

    -- 7) turun ke Home
    hrp = getParts()
    if hrp then
        moveTo(hrp, CFrame.new(HOME))
    end
    cycles += 1
    refresh()
    task.wait(0.5)
end

-- =====================================================================
--  BUILD UI
-- =====================================================================
local function BuildHub()
    local Window = createWindow({
        Name = "YSS HUB",
        Dev = "DEV: GG SIH LUH",
        Description = "Anti Ragdoll And anti Banned| UPDATE-9.5",
    })
    notify = function(title, text, duration)
        Window:Notify(title, text, duration)
    end

    -- ===== Tab 1: Egg =====
    local Tab = Window:AddTab("Egg")
    local L, R = Tab.Left, Tab.Right

    L:Section("Zone")
    L:Dropdown({
        Title = "Pilih Zone",
        Description = "Zona tujuan auto egg",
        Options = ZoneNames,
        Default = ZoneNames[1],
        Callback = function(v)
            selected = v
            refresh()
        end,
    })

    L:Section("Auto")
    L:Dropdown({
        Title = "Teleport Speed",
        Description = "Jeda tiap teleport ke Home",
        Options = SpeedOptions,
        Default = SpeedOptions[2],
        Callback = function(v)
            local num = tonumber(tostring(v):match("^[%d%.]+"))
            if num then
                STEP_DELAY = num
                refresh()
            end
        end,
    })

    L:Toggle({
        Title = "Auto Egg",
        Description = "Naik, tween, ambil egg, balik Home",
        Default = false,
        Callback = function(v)
            running = v
            if v then
                task.spawn(function()
                    while running do
                        local pos = zonePos(selected)
                        if pos then
                            runOnce(pos)
                        end
                        task.wait(1)
                    end
                    stopPlatform()
                    setState("Idle")
                end)
            else
                stopPlatform()
                setState("Idle")
            end
        end,
    })

    L:Toggle({
        Title = "Dual Auto Grab",
        Description = "Ambil egg otomatis radius 100 studs",
        Default = false,
        Callback = function(v)
            grabRunning = v
        end,
    })

    L:Slider({
        Title = "TWEEN FORCE",
        Min = 200,
        Max = 2800,
        Default = TWEEN_SPEED,
        Callback = function(v)
            TWEEN_SPEED = v
            refresh()
        end,
    })

    L:Slider({
        Title = "OFFSET HIGHER (studs)",
        Min = 10,
        Max = 150,
        Default = ALTITUDE,
        Callback = function(v)
            ALTITUDE = v
            refresh()
        end,
    })

    L:Slider({
        Title = "STEP STUDS (studs)",
        Min = 15,
        Max = 500,
        Default = STEP_DIST,
        Callback = function(v)
            STEP_DIST = v
            refresh()
        end,
    })

    R:Section("Status Server")
    statusLabel = R:Paragraph("")
    refresh()

    -- ===== Tab 2: Teleport =====
    local TpTab = Window:AddTab("Teleport")
    local TL, TR = TpTab.Left, TpTab.Right
    local tpZone = ZoneNames[1]

    TL:Section("Zone")
    TL:Dropdown({
        Title = "Zone",
        Description = "Pilih tujuan teleport",
        Options = ZoneNames,
        Default = ZoneNames[1],
        Callback = function(v)
            tpZone = v
        end,
    })

    TL:Button({
        Title = "Tap To Tp",
        Description = "Langsung ke zone terpilih",
        Callback = function()
            local hrp = getParts()
            local pos = zonePos(tpZone)
            if hrp and pos then
                moveTo(hrp, CFrame.new(pos + Vector3.new(0, 3, 0)))
            end
        end,
    })

    TL:Button({
        Title = "Teleport Home",
        Description = "Langsung ke Home",
        Callback = function()
            local hrp = getParts()
            if hrp then
                moveTo(hrp, CFrame.new(HOME + Vector3.new(0, 3, 0)))
            end
        end,
    })

    TR:Section("Info")
    TR:Paragraph("YSS HUB\nDEV: GG SIH LUH\nKlik tombol - di pojok untuk melipat UI, + untuk membukanya lagi.")

    Window:Notify("YSS HUB", "DEV: GG SIH LUH", 3)
end

-- =====================================================================
--  KEY SYSTEM + LAUNCH
-- =====================================================================
local KEY = "UPDATE-9.5"

local function showError(err)
    warn("[YSS HUB] " .. tostring(err))
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "YSS HUB Error",
            Text = tostring(err):sub(1, 180),
            Duration = 20,
        })
    end)
end

local function showKeyScreen(onSuccess)
    local gui = makeGui("YSSHubKey")

    local frame = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(320, 210),
        BackgroundColor3 = C.bg,
        BorderSizePixel = 0,
    }, gui)
    corner(frame, 10)
    stroke(frame, C.accent, 1)

    local title = label(frame, "YSS HUB", 22, C.accent, Enum.TextXAlignment.Center)
    title.Font = Enum.Font.GothamBold
    title.Position = UDim2.fromOffset(0, 12)
    title.Size = UDim2.new(1, 0, 0, 28)

    local dev = label(frame, "DEV: GG SIH LUH", 13, Color3.fromRGB(150, 150, 150), Enum.TextXAlignment.Center)
    dev.Position = UDim2.fromOffset(0, 42)
    dev.Size = UDim2.new(1, 0, 0, 20)

    local box = create("TextBox", {
        PlaceholderText = "Masukkan key...",
        PlaceholderColor3 = Color3.fromRGB(120, 120, 120),
        Text = "",
        ClearTextOnFocus = false,
        BackgroundColor3 = C.row,
        TextColor3 = C.text,
        TextSize = 14,
        Font = Enum.Font.Gotham,
        Position = UDim2.new(0, 20, 0, 76),
        Size = UDim2.new(1, -40, 0, 38),
    }, frame)
    corner(box, 6)

    local msg = label(frame, "", 12, Color3.fromRGB(255, 100, 100), Enum.TextXAlignment.Center)
    msg.Position = UDim2.fromOffset(0, 119)
    msg.Size = UDim2.new(1, 0, 0, 18)

    local btn = create("TextButton", {
        Text = "Verify",
        AutoButtonColor = false,
        BackgroundColor3 = C.accent,
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 15,
        Font = Enum.Font.GothamBold,
        Position = UDim2.new(0, 20, 0, 148),
        Size = UDim2.new(1, -40, 0, 38),
    }, frame)
    corner(btn, 6)

    btn.Activated:Connect(function()
        local entered = string.match(box.Text, "^%s*(.-)%s*$")
        if entered == KEY then
            gui:Destroy()
            onSuccess()
        else
            msg.Text = "Key salah!"
        end
    end)
end

local function launch()
    local ok, err = xpcall(BuildHub, debug.traceback)
    if not ok then
        showError(err)
    end
end

local ok, err = xpcall(function()
    showKeyScreen(launch)
end, debug.traceback)
if not ok then
    showError(err)
end
