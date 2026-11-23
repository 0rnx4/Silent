local QOT_URL = "https://raw.githubusercontent.com/0rnx4/Silent/main/main.lua"
local tws = game:GetService("TweenService")
local function tw(obj, props, t)
    pcall(function()
        tws:Create(obj, TweenInfo.new(t or .18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
    end)
end

local C = {
    bg = Color3.fromRGB(10, 10, 10),
    sidebar = Color3.fromRGB(15, 15, 15),
    card = Color3.fromRGB(20, 20, 20),
    hover = Color3.fromRGB(35, 35, 35),
    stroke = Color3.fromRGB(44, 44, 50),
    text = Color3.fromRGB(245, 245, 245),
    sub = Color3.fromRGB(163, 163, 168),
    faint = Color3.fromRGB(112, 112, 118),
    accent = Color3.fromRGB(245, 245, 247),
    accentTx = Color3.fromRGB(10, 10, 12),
    track = Color3.fromRGB(32, 32, 36),
    warn = Color3.fromRGB(255, 84, 84),
}
local function corner(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = obj
    return c
end
local function stroke(obj, col, th)
    local s = Instance.new("UIStroke")
    s.Color = col or Color3.fromRGB(255, 255, 255)
    if not col then s.Transparency = .88 end
    s.Thickness = th or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = obj
    return s
end

local function applyQot()
    if not cfg.misc.qot then return end
    pcall(function()
        local q = queueonteleport or queue_on_teleport
        if q then
            q('loadstring(game:HttpGet("' .. QOT_URL .. '"))()')
        end
    end)
end

local dragSet = G.__rvl4_dragSet or {}
G.__rvl4_dragSet = dragSet
task.delay(0, function()
    local okD, errD = pcall(function()
        if myGen == G.__rvl4_gen and G.__rvl4_dragBound ~= myGen then
            if G.__rvl4_dragConns then
                G.__rvl4_disconnectAll(G.__rvl4_dragConns)
            end
            G.__rvl4_dragBound = myGen
            local dc2 = {}
            dc2[#dc2 + 1] = bind(uis.InputChanged, function(i)
                for d in pairs(dragSet) do d.move(i) end
            end)
            dc2[#dc2 + 1] = bind(uis.InputEnded, function(i)
                for d in pairs(dragSet) do d.finish(i) end
            end)
            local icS = nil
            pcall(function() icS = uis.InputCancelled end)
            if icS then
                dc2[#dc2 + 1] = bind(icS, function(i)
                    for d in pairs(dragSet) do d.finish(i, true) end
                end)
            end
            task.spawn(function()
                while G.__rvl4_gen == myGen do
                    task.wait(2)
                    if G.__rvl4_gen ~= myGen then break end
                    for d in pairs(dragSet) do
                        if d.input and os.clock() - (d.at or 0) > 30 then d.finish(d.input, true) end
                    end
                end
            end)
            G.__rvl4_dragConns = dc2
        end
    end)
    if not okD then
        if G.__rvl4_beaconSay then G.__rvl4_beaconSay("rvl v118 drag失敗: " .. string.sub(tostring(errD), 1, 50)) end
    end
end)

local WG = {}
local wPage, wOrd = nil, 0
local wRows = {}
local wRefreshers = {}
local wDepOf = {}
local wSrchOf = {}
local wDirty = function() end
local ROWH = touch and 56 or 52
local ctrlAt = 0
function WG.markCtrl() ctrlAt = os.clock() end
function WG.ctrlFresh() return os.clock() - ctrlAt < .08 end
local function markable(b)
    b.InputBegan:Connect(function() ctrlAt = os.clock() end)
    return b
end

function WG.setDirty(fn) wDirty = fn end
function WG.reset()
    WG._emptyRows = nil
    WG._cardCi, WG._refN = nil, nil
    wOrd = 0
    wRows = {}
    wRefreshers = {}
    wDepOf = {}
    wSrchOf = {}
    WG._dep = nil
    wPage = nil
    WG._cols, WG._colN, WG._host, WG._colCard = nil, nil, nil, nil
    WG._pageCols, WG._colH = nil, nil
    WG._searchQ = nil
end
WG._fx = function(b, getCol, isText)
    local prop = isText and "TextColor3" or "BackgroundColor3"
    local function shift(c, a)
        return Color3.fromRGB(math.min(255, c.R * 255 + a), math.min(255, c.G * 255 + a), math.min(255, c.B * 255 + a))
    end
    if not touch then
        b.MouseEnter:Connect(function() tw(b, { [prop] = shift(getCol(), 16) }, .08) end)
        b.MouseLeave:Connect(function() tw(b, { [prop] = getCol() }, .08) end)
    end
    b.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            tw(b, { [prop] = shift(getCol(), 34) }, .05)
        end
    end)
    b.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            tw(b, { [prop] = getCol() }, .12)
        end
    end)
end
function WG.rollback(page)
    local rec = WG._pageCols and WG._pageCols[page]
    if rec then rec.tok = (rec.tok or 0) + 1 end
    if rec and rec.cols then pcall(function() rec.cols:Destroy() end) end
    if WG._pageCols then WG._pageCols[page] = nil end
    if WG._emptyRows and WG._emptyRows[page] then
        pcall(function() WG._emptyRows[page]:Destroy() end)
        WG._emptyRows[page] = nil
    end
    WG._host, WG._colCard, WG._cardCi = nil, nil, nil
    WG._cols, WG._colN, WG._colH = nil, nil, nil
    if WG._searchQ then WG._searchQ[page] = nil end
    if wRows[page] then
        for _, e in ipairs(wRows[page]) do
            if e.f then wDepOf[e.f] = nil wSrchOf[e.f] = nil end
        end
    end
    wRows[page] = nil
    WG._dep = nil
    pcall(function() page.CanvasSize = UDim2.new(0, 0, 0, 0) page.ScrollingEnabled = true end)
    if WG._refN then
        for i = #wRefreshers, WG._refN + 1, -1 do wRefreshers[i] = nil end
    end
end
WG._bump = function()
    local ci = WG._colCard
    if ci and WG._colN then WG._colN[ci] = WG._colN[ci] + 1 end
end
function WG.begin(page)
    WG._dep = nil
    WG._refN = #wRefreshers
    wPage = page
    wOrd = 0
    local cols = Instance.new("Frame")
    cols.Size = UDim2.new(1, 0, 0, 0)
    cols.AutomaticSize = Enum.AutomaticSize.Y
    cols.BackgroundTransparency = 1
    cols.BorderSizePixel = 0
    cols.Parent = page
    local cp = Instance.new("UIPadding")
    cp.PaddingTop = UDim.new(0, 12)
    cp.PaddingBottom = UDim.new(0, 12)
    cp.PaddingLeft = UDim.new(0, 12)
    cp.PaddingRight = UDim.new(0, 12)
    cp.Parent = cols
    local lay = Instance.new("UIListLayout")
    lay.FillDirection = Enum.FillDirection.Horizontal
    lay.Padding = UDim.new(0, 10)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.VerticalAlignment = Enum.VerticalAlignment.Top
    lay.Parent = cols
    local function mkCol(ord, wScale, wOff)
        local col = Instance.new("Frame")
        col.Size = UDim2.new(wScale, wOff, 0, 0)
        col.AutomaticSize = Enum.AutomaticSize.Y
        col.BackgroundTransparency = 1
        col.BorderSizePixel = 0
        col.LayoutOrder = ord
        col.Parent = cols
        local cl = Instance.new("UIListLayout")
        cl.Padding = UDim.new(0, 7)
        cl.SortOrder = Enum.SortOrder.LayoutOrder
        cl.Parent = col
        return col
    end
    WG._colN = { 0, 0 }
    if touch then
        local col = mkCol(1, 1, 0)
        WG._cols = { col, col }
    else
        WG._cols = { mkCol(1, .5, -5), mkCol(2, .5, -5) }
    end
    WG._colH = { 0, 0 }
    WG._pageCols = WG._pageCols or {}
    WG._pageCols[page] = { cols = cols, list = WG._cols, colH = WG._colH }
    WG._cardCi = 1
    WG._host = page
    WG._colCard = nil
end
function WG.fixCanvas(page)
    local rec = WG._pageCols and WG._pageCols[page]
    if not rec then return end
    rec.tok = (rec.tok or 0) + 1
    local tok = rec.tok
    local function apply(quick)
        pcall(function()
            local searching = WG._searchQ and WG._searchQ[page] and WG._searchQ[page] ~= ""
            local ah = 0
            if rec.colH and not searching then
                if rec.list and rec.list[1] == rec.list[2] then
                    ah = (rec.colH[1] or 0) + (rec.colH[2] or 0) + 24
                else
                    ah = math.max(rec.colH[1] or 0, rec.colH[2] or 0) + 24
                end
            end
            local h = nil
            if quick and ah > 0 then
                h = ah
            else
                local bottom = 0
                local colM = 0
                if rec.list then for _, c in ipairs(rec.list) do colM = math.max(colM, c.AbsoluteSize.Y) end end
                local lst = wRows[page]
                if lst then
                    for _, e in ipairs(lst) do
                        if e.f.Visible then
                            local b2 = e.f.AbsolutePosition.Y + e.f.AbsoluteSize.Y
                            if b2 > bottom then bottom = b2 end
                        end
                    end
                end
                if bottom > 0 then
                    h = math.max(bottom - page.AbsolutePosition.Y + page.CanvasPosition.Y + 28, colM)
                elseif searching then
                    h = 0
                else
                    h = colM > 0 and colM or ah
                end
            end
            if h and h > 0 then
                page.CanvasSize = UDim2.new(0, 0, 0, h + 24)
            end
        end)
    end
    apply(true)
    task.defer(function() if rec.tok == tok then apply() end end)
    task.delay(.15, function() if rec.tok == tok then apply() end end)
end
local function depOk(f)
    local d = wDepOf[f]
    if not d then return true end
    local ok, v = pcall(d)
    return (ok and v) and true or false
end
local function rowVis(f)
    f.Visible = depOk(f) and wSrchOf[f] ~= false
end
function WG.dep(fn) WG._dep = fn end
function WG.depRefresh()
    for f2 in pairs(wDepOf) do pcall(rowVis, f2) end
    for page, lst in pairs(wRows) do
        for _, e in ipairs(lst) do
            if e.f and wDepOf[e.f] then WG.fixCanvas(page) break end
        end
    end
end

function WG.refresh()
    for _, fn in ipairs(wRefreshers) do
        local okF, errF = pcall(fn)
        if not okF and os.clock() - (G.__rvl4_refErrAt or 0) > 10 then
            G.__rvl4_refErrAt = os.clock()
            G.__rvl4_errPush("refresh: " .. string.sub(tostring(errF), 1, 50))
        end
    end
    WG.depRefresh()
end
function WG.applySearch(page, q)
    local lst = wRows[page]
    if not lst then return end
    WG._searchQ = WG._searchQ or {}
    WG._searchQ[page] = q
    if q == "" then
        for _, e in ipairs(lst) do wSrchOf[e.f] = true rowVis(e.f) end
        local er0 = WG._emptyRows and WG._emptyRows[page]
        if er0 then er0.Visible = false end
        WG.fixCanvas(page)
        return
    end
    local ql = string.lower(q)
    for _, e in ipairs(lst) do
        if not e.sec then
            wSrchOf[e.f] = string.find(string.lower(e.t), ql, 1, true) ~= nil
            rowVis(e.f)
        end
    end
    local n = #lst
    for i, e in ipairs(lst) do
        if e.sec then
            local show = string.find(string.lower(e.t), ql, 1, true) ~= nil
            if not show then
                for j = i + 1, n do
                    local e2 = lst[j]
                    if e2.sec then break end
                    if e2.f.Visible then
                        show = true
                        break
                    end
                end
            end
            e.f.Visible = show
        end
    end
    local anyVis = false
    for _, e in ipairs(lst) do
        if not e.sec and e.f.Visible then
            anyVis = true
            break
        end
    end
    WG._emptyRows = WG._emptyRows or {}
    local er = WG._emptyRows[page]
    if not anyVis then
        if not er then
            er = Instance.new("TextLabel")
            er.Size = UDim2.new(1, -24, 0, 20)
            er.Position = UDim2.new(0, 12, 0, 14)
            er.BackgroundTransparency = 1
            er.Text = "該当する設定がありません"
            er.TextColor3 = C.sub
            er.Font = Enum.Font.BuilderSans
            er.TextSize = 13
            er.TextXAlignment = Enum.TextXAlignment.Left
            er.Parent = page
            WG._emptyRows[page] = er
        end
        er.Visible = true
        page.CanvasPosition = Vector2.new(0, 0)
        page.CanvasSize = UDim2.new(0, 0, 0, 120)
    elseif er then
        er.Visible = false
    end
    G.__rvl4_searchTok = (G.__rvl4_searchTok or 0) + 1
    local stok = G.__rvl4_searchTok
    task.delay(.15, function() if G.__rvl4_searchTok == stok then WG.fixCanvas(page) end end)
end

local lastEntry = nil
local function regEntry(f, t, isSec)
    local entry = { f = f, t = t or "", sec = isSec or false }
    local lst = wRows[wPage]
    if not lst then lst = {} wRows[wPage] = lst end
    table.insert(lst, entry)
    lastEntry = entry
    return entry
end

WG._setT = function(f, t)
    if lastEntry and lastEntry.f == f then lastEntry.t = t end
end

local function rowBase(h)
    wOrd = wOrd + 1
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, h)
    f.BackgroundColor3 = C.card
    f.BorderSizePixel = 0
    f.LayoutOrder = wOrd
    f.Parent = WG._host or wPage
    regEntry(f)
    if WG._dep then
        wDepOf[f] = WG._dep
        rowVis(f)
    end
    if WG._colH then
        local ci3 = WG._cardCi or 1
        WG._colH[ci3] = WG._colH[ci3] + h + 7
    end
    WG._bump()
    local inSec = WG._colCard ~= nil
    if inSec then
        f.BackgroundTransparency = 1
    else
        corner(f, 10)
        stroke(f)
    end
    if not touch then
        if inSec then
            f.MouseEnter:Connect(function() f.BackgroundColor3 = C.hover f.BackgroundTransparency = .45 end)
            f.MouseLeave:Connect(function() f.BackgroundTransparency = 1 end)
        else
            f.MouseEnter:Connect(function() tw(f, { BackgroundColor3 = C.hover }, .12) end)
            f.MouseLeave:Connect(function() tw(f, { BackgroundColor3 = C.card }, .12) end)
        end
    end
    return f
end
WG.row = rowBase

function WG.label(f, t, w)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -(w or 60), 1, 0)
    l.Position = UDim2.new(0, 14, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = t
    l.TextColor3 = C.text
    l.Font = Enum.Font.BuilderSans
    l.TextSize = touch and 15 or 14
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f
    WG._setT(f, t)
    return l
end

function WG.sec(t)
    wOrd = wOrd + 1
    local ci = 1
    if WG._colH and WG._colH[2] < WG._colH[1] then ci = 2 end
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = C.card
    card.BorderSizePixel = 0
    card.LayoutOrder = wOrd
    card.Parent = (WG._cols and WG._cols[ci]) or wPage
    corner(card, 10)
    stroke(card)
    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 7)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Parent = card
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 10)
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.Parent = card
    regEntry(card, t, true)
    if WG._dep then
        wDepOf[card] = WG._dep
        rowVis(card)
    end
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -12, 0, 24)
    l.Position = UDim2.new(0, 12, 0, 0)
    l.BackgroundTransparency = 1
    l.LayoutOrder = 0
    l.Text = t
    l.TextColor3 = C.sub
    l.Font = Enum.Font.BuilderSansBold
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = card
    local bar2 = Instance.new("Frame")
    bar2.Size = UDim2.new(0, 3, 0, 12)
    bar2.Position = UDim2.new(0, -10, 0, 6)
    bar2.BackgroundColor3 = C.accent
    bar2.BorderSizePixel = 0
    bar2.Parent = l
    corner(bar2, 2)
    WG._host = card
    WG._colCard = ci
    WG._cardCi = ci
    if WG._colH then WG._colH[ci] = WG._colH[ci] + 49 end
    if WG._colN then WG._colN[ci] = WG._colN[ci] + 1 end
end

function WG.note(t)
    wOrd = wOrd + 1
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 15)
    l.BackgroundTransparency = 1
    l.TextWrapped = true
    l.AutomaticSize = Enum.AutomaticSize.Y
    l.LayoutOrder = wOrd
    l.Parent = WG._host or wPage
    regEntry(l, t)
    if WG._dep then
        wDepOf[l] = WG._dep
        rowVis(l)
    end
    if WG._colH then
        local ci4 = WG._cardCi or 1
        local lines = math.max(1, math.ceil((#t / 3) / (touch and 36 or 19)))
        WG._colH[ci4] = WG._colH[ci4] + 7 + 15 * lines
    end
    WG._bump()
    l.Text = t
    l.TextColor3 = C.sub
    l.Font = Enum.Font.BuilderSans
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
end

function WG.tog(t, get, set)
    local f = rowBase(ROWH)
    WG.label(f, t, 70)
    local sw = Instance.new("Frame")
    sw.Size = UDim2.new(0, touch and 54 or 50, 0, touch and 30 or 28)
    sw.Position = UDim2.new(1, touch and -66 or -62, .5, touch and -15 or -14)
    sw.BackgroundColor3 = C.track
    sw.BorderSizePixel = 0
    sw.Parent = f
    corner(sw, touch and 15 or 14)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, touch and 24 or 22, 0, touch and 24 or 22)
    knob.AnchorPoint = Vector2.new(0, .5)
    knob.Position = UDim2.new(0, 3, .5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(128, 128, 138)
    knob.BorderSizePixel = 0
    knob.Parent = sw
    corner(knob, touch and 12 or 11)
    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1, 0, 1, 0)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.AutoButtonColor = false
    hit.ZIndex = 3
    hit.Parent = f
    markable(hit)
    local function paint(anim)
        local v = get()
        local props = {
            Position = UDim2.new(0, v and (touch and 27 or 25) or 3, .5, 0),
            BackgroundColor3 = v and C.accentTx or Color3.fromRGB(128, 128, 138),
        }
        if anim then
            tw(knob, props, .16)
            tw(sw, { BackgroundColor3 = v and C.accent or C.track }, .16)
        else
            knob.Position = props.Position
            knob.BackgroundColor3 = props.BackgroundColor3
            sw.BackgroundColor3 = v and C.accent or C.track
        end
    end
    paint(false)
    table.insert(wRefreshers, function() paint(false) end)
    bind(hit.Activated, function()
        set(not get())
        paint(true)
        WG.depRefresh()
        wDirty()
    end)
end

function WG.num(t, get, set, mn, mx)
    local dec = ((mx - mn) <= 5) and 2 or 0
    local function fmt(v)
        if dec == 2 then return string.format("%.2f", v) end
        return tostring(math.floor(v + .5))
    end
    local function round(v)
        if dec == 2 then return math.floor(v * 100 + .5) / 100 end
        return math.floor(v + .5)
    end
    local f = rowBase(ROWH + 26)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -190, 0, 18)
    l.Position = UDim2.new(0, 14, 0, 10)
    l.BackgroundTransparency = 1
    l.Text = t
    l.TextColor3 = C.text
    l.Font = Enum.Font.BuilderSans
    l.TextSize = touch and 14 or 13
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f
    WG._setT(f, t)
    local val = Instance.new("TextButton")
    val.Size = UDim2.new(0, 110, 0, 34)
    val.Position = UDim2.new(1, touch and -200 or -184, 0, 2)
    val.BackgroundTransparency = 1
    val.Text = fmt(get())
    val.TextColor3 = C.sub
    val.Font = Enum.Font.BuilderSansBold
    val.TextSize = 12
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.AutoButtonColor = false
    val.Parent = f
    markable(val)
    local edit = Instance.new("TextBox")
    edit.Size = UDim2.new(0, touch and 110 or 84, 0, touch and 32 or 24)
    edit.Position = UDim2.new(1, touch and -194 or -152, 0, touch and 3 or 7)
    edit.BackgroundColor3 = C.track
    edit.BorderSizePixel = 0
    edit.Text = ""
    edit.PlaceholderText = "数値"
    edit.TextColor3 = C.text
    edit.PlaceholderColor3 = C.faint
    edit.Font = Enum.Font.BuilderSansBold
    edit.TextSize = 12
    edit.Visible = false
    edit.ZIndex = 5
    edit.Parent = f
    corner(edit, 6)
    markable(edit)
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -28, 0, 6)
    track.Position = UDim2.new(0, 14, 1, -21)
    track.BackgroundColor3 = C.track
    track.BorderSizePixel = 0
    track.Parent = f
    corner(track, 3)
    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = C.accent
    fill.BorderSizePixel = 0
    fill.Parent = track
    corner(fill, 3)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, touch and 21 or 17, 0, touch and 21 or 17)
    knob.AnchorPoint = Vector2.new(.5, .5)
    knob.BackgroundColor3 = C.accent
    knob.BorderSizePixel = 0
    knob.ZIndex = 2
    knob.Parent = track
    corner(knob, touch and 11 or 9)
    stroke(knob, Color3.fromRGB(8, 8, 10), 2)
    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1, -14, 0, 36)
    hit.Position = UDim2.new(0, 7, 1, -38)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.AutoButtonColor = false
    hit.ZIndex = 3
    hit.Parent = f
    markable(hit)
    local function paint()
        local v = math.clamp(get(), mn, mx)
        local frac = (v - mn) / math.max(mx - mn, .0001)
        fill.Size = UDim2.new(frac, 0, 1, 0)
        knob.Position = UDim2.new(frac, 0, .5, 0)
        val.Text = fmt(v)
    end
    local step = dec == 2 and 0.01 or math.min(10, math.max(1, math.floor((mx - mn) / 100)))
    local function stepper(txt, x)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, touch and 32 or 26, 0, touch and 32 or 26)
        b.Position = UDim2.new(1, x, 0, touch and 4 or 6)
        b.BackgroundColor3 = C.track
        b.BorderSizePixel = 0
        b.Text = txt
        b.TextColor3 = C.text
        b.Font = Enum.Font.BuilderSansBold
        b.TextSize = 14
        b.AutoButtonColor = false
        b.Parent = f
        corner(b, 7)
        stroke(b)
        markable(b)
        return b
    end
    local minusB = stepper("－", touch and -78 or -70)
    local plusB = stepper("＋", touch and -42 or -40)
    bind(minusB.Activated, function()
        set(round(math.clamp(get() - step, mn, mx)))
        paint()
        wDirty()
    end)
    bind(plusB.Activated, function()
        set(round(math.clamp(get() + step, mn, mx)))
        paint()
        wDirty()
    end)
    paint()
    table.insert(wRefreshers, paint)
    bind(val.Activated, function()
        edit.Text = fmt(get())
        edit.Visible = true
        edit:CaptureFocus()
    end)
    bind(edit.FocusLost, function()
        edit.Visible = false
        local nv = tonumber(edit.Text)
        if nv then
            set(round(math.clamp(nv, mn, mx)))
            paint()
            wDirty()
        end
    end)
    local page = wPage
    local function apply(x)
        local ax = track.AbsolutePosition.X
        local aw = math.max(track.AbsoluteSize.X, 1)
        local frac = math.clamp((x - ax) / aw, 0, 1)
        set(round(mn + (mx - mn) * frac))
        paint()
        wDirty()
    end
    local dstate = { input = nil }
    dstate.move = function(i)
        if dstate.input and os.clock() - (dstate.at or 0) > 30 then
            dstate.input = nil
            dragSet[dstate] = nil
            if page then page.ScrollingEnabled = true end
            return
        end
        if alive() and (i.UserInputType == Enum.UserInputType.MouseMovement or (i.UserInputType == Enum.UserInputType.Touch and i == dstate.input)) then
            apply(i.Position.X)
        end
    end
    dstate.finish = function(i, canc)
        if i == dstate.input or (canc and dstate.input and i.UserInputType == dstate.input.UserInputType) then
            dstate.input = nil
            dragSet[dstate] = nil
            if page then page.ScrollingEnabled = true end
        end
    end
    hit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dstate.input = i
            dstate.at = os.clock()
            dragSet[dstate] = true
            if page then page.ScrollingEnabled = false end
            apply(i.Position.X)
        end
    end)
end

function WG.btn(t, fn, danger)
    local f = rowBase(ROWH - 4)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 1, 0)
    b.BackgroundTransparency = danger and 0 or 1
    if danger then b.BackgroundColor3 = Color3.fromRGB(46, 24, 24) end
    corner(b, 8)
    b.Text = t
    b.TextColor3 = danger and Color3.fromRGB(240, 150, 150) or C.text
    b.Font = Enum.Font.BuilderSans
    b.TextSize = touch and 14 or 13
    b.AutoButtonColor = false
    b.Parent = f
    WG._setT(f, t)
    markable(b)
    bind(b.Activated, fn)
    return b
end

function WG.cycle(t, get, set, options)
    local f = rowBase(ROWH)
    WG.label(f, t, 150)
    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(0, 150, 1, 0)
    val.Position = UDim2.new(1, -164, 0, 0)
    val.BackgroundTransparency = 1
    val.TextColor3 = C.sub
    val.Font = Enum.Font.BuilderSansBold
    val.TextSize = 12
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.Parent = f
    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1, 0, 1, 0)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.AutoButtonColor = false
    hit.ZIndex = 3
    hit.Parent = f
    markable(hit)
    WG._fx(hit, function() return C.sub end, true)
    local function paint() val.Text = tostring(get()) .. "  ›" end
    paint()
    table.insert(wRefreshers, paint)
    bind(hit.Activated, function()
        local cur = get()
        local idx = 0
        for i, v in ipairs(options) do
            if v == cur then idx = i break end
        end
        set(options[idx % #options + 1])
        paint()
        wDirty()
    end)
end

function WG.text(t, get, set, ph)
    local f = rowBase(ROWH + 26)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -24, 0, 18)
    l.Position = UDim2.new(0, 14, 0, 10)
    l.BackgroundTransparency = 1
    l.Text = t
    l.TextColor3 = C.text
    l.Font = Enum.Font.BuilderSans
    l.TextSize = touch and 14 or 13
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f
    WG._setT(f, t)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -28, 0, 28)
    box.Position = UDim2.new(0, 14, 1, -38)
    box.BackgroundColor3 = C.track
    box.BorderSizePixel = 0
    box.TextColor3 = C.text
    box.PlaceholderColor3 = C.faint
    box.PlaceholderText = ph or ""
    box.Font = Enum.Font.BuilderSans
    box.TextSize = 12
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ClearTextOnFocus = false
    box.Text = get() or ""
    box.Parent = f
    corner(box, 8)
    markable(box)
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 8)
    pad.Parent = box
    table.insert(wRefreshers, function()
        local okF, foc = pcall(function() return box:IsFocused() end)
        if not (okF and foc) then box.Text = get() or "" end
    end)
    bind(box.FocusLost, function()
        if box.Text ~= (get() or "") then
            set(box.Text)
            wDirty()
        end
    end)
end

function WG.seg(t, get, set, options)
    local widths = {}
    local total = 6
    for i, opt in ipairs(options) do
        local w = 22 + (utf8.len(opt) or #opt) * 13
        widths[i] = w
        total = total + w + 3
    end
    local f = rowBase(ROWH + 26)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -24, 0, 18)
    l.Position = UDim2.new(0, 14, 0, 10)
    l.BackgroundTransparency = 1
    l.Text = t
    l.TextColor3 = C.text
    l.Font = Enum.Font.BuilderSans
    l.TextSize = touch and 14 or 13
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f
    WG._setT(f, t)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(0, total, 0, touch and 34 or 30)
    holder.Position = UDim2.new(0, 14, 1, touch and -40 or -36)
    holder.BackgroundColor3 = C.track
    holder.BorderSizePixel = 0
    holder.Parent = f
    corner(holder, 8)
    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.new(0, widths[1], 0, touch and 28 or 24)
    thumb.Position = UDim2.new(0, 3, 0, 3)
    thumb.BackgroundColor3 = C.accent
    thumb.BorderSizePixel = 0
    thumb.ZIndex = 1
    thumb.Parent = holder
    corner(thumb, 6)
    local btns = {}
    local function paint(anim)
        local cur = get()
        local xi = 3
        for i, b in ipairs(btns) do
            local on = options[i] == cur
            if on then
                local tp = { Position = UDim2.new(0, xi, 0, 3), Size = UDim2.new(0, widths[i], 0, touch and 28 or 24) }
                if anim then
                    tw(thumb, tp, .15)
                else
                    thumb.Position = tp.Position
                    thumb.Size = tp.Size
                end
            end
            b.TextColor3 = on and C.accentTx or C.sub
            xi = xi + widths[i] + 3
        end
    end
    local x = 3
    for i, opt in ipairs(options) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, widths[i], 0, touch and 28 or 24)
        b.Position = UDim2.new(0, x, 0, 3)
        b.BackgroundTransparency = 1
        b.BorderSizePixel = 0
        b.ZIndex = 2
        b.Text = opt
        b.TextColor3 = C.sub
        b.Font = Enum.Font.BuilderSansBold
        b.TextSize = 12
        b.AutoButtonColor = false
        b.Parent = holder
        corner(b, 6)
        markable(b)
        btns[i] = b
        x = x + widths[i] + 3
        bind(b.Activated, function()
            set(opt)
            paint(true)
            wDirty()
        end)
    end
    paint(false)
    table.insert(wRefreshers, function() paint(false) end)
end

stage("lib")
