if G.__rvl4_drawCleanup then pcall(G.__rvl4_drawCleanup) end
local hlCache = {}
local bbCache = {}
G.__rvl4_distCol = G.__rvl4_distCol or Color3.fromRGB(230, 230, 230)

local function espColor(p, frac)
    local mode = cfg.esp.colormode
    if mode == "体力" then
        return hpColor(frac or 1)
    end
    if mode == "レインボー" then
        local step = math.floor(((os.clock() * .3 + (p.UserId or 0) % 10 * .07) % 1) * 32)
        local memo = G.__rvl4_hsvMemo
        if not memo then
            memo = {}
            G.__rvl4_hsvMemo = memo
        end
        local col = memo[step]
        if not col then
            col = Color3.fromHSV(step / 32, .85, 1)
            memo[step] = col
        end
        return col
    end
    local preset = G.__rvl4_espPreset
    if not preset then
        preset = { ["白"] = Color3.fromRGB(245, 245, 245), ["緑"] = Color3.fromRGB(80, 255, 120), ["青"] = Color3.fromRGB(80, 160, 255), ["黄"] = Color3.fromRGB(255, 215, 80), ["紫"] = Color3.fromRGB(190, 110, 255) }
        G.__rvl4_espPreset = preset
    end
    local pc2 = preset[mode]
    if pc2 then return pc2 end
    local red = G.__rvl4_espRed
    if not red then
        red = Color3.fromRGB(255, 70, 70)
        G.__rvl4_espRed = red
    end
    return red
end

local function makeBB(p)
    local c = p.Character
    local head = c and c:FindFirstChild("Head")
    if not head then return end
    if bbCache[p] then pcall(function() bbCache[p].gui:Destroy() end) end
    local g = Instance.new("BillboardGui")
    g.Name = "rvl_bb"
    g.Size = UDim2.new(0, 150, 0, 34)
    g.StudsOffset = Vector3.new(0, 2.8, 0)
    g.AlwaysOnTop = true
    g.MaxDistance = cfg.esp.max
    g.Adornee = head
    g.Enabled = false
    g.Parent = head
    local nm = Instance.new("TextLabel")
    nm.BackgroundTransparency = 1
    nm.Size = UDim2.new(1, 0, 0, 16)
    nm.Font = Enum.Font.BuilderSansBold
    nm.TextSize = 12
    nm.TextStrokeTransparency = .4
    nm.TextColor3 = Color3.fromRGB(255, 255, 255)
    nm.Parent = g
    local wp = Instance.new("TextLabel")
    wp.BackgroundTransparency = 1
    wp.Position = UDim2.new(0, 0, 0, 16)
    wp.Size = UDim2.new(1, 0, 0, 14)
    wp.Font = Enum.Font.BuilderSans
    wp.TextSize = 11
    wp.TextColor3 = Color3.fromRGB(210, 210, 210)
    wp.TextStrokeTransparency = .5
    wp.Parent = g
    bbCache[p] = { gui = g, name = nm, wp = wp, head = head }
end

local function espTickPlayer(p)
    local c = p.Character
    local enemy = c and cfg.esp.on and isFoe(p) or false
    local cc = c and getChar(p) or nil

    local foeL = enemy
    if not foeL and c and cfg.esp.on then foeL = isFoeLoose(p) end
    local h = hlCache[p]
    local humC = cc and cc.hum
    if c and foeL and cfg.esp.chams and not (humC and humC.Health <= 0) then
        if not h or h.Parent ~= c then
            if h then pcall(function() h:Destroy() end) end
            h = Instance.new("Highlight")
            h.Name = "rvl"
            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            h.FillColor = Color3.fromRGB(255, 70, 70)
            h.OutlineColor = Color3.fromRGB(255, 160, 160)
            h.FillTransparency = .4
            h.Parent = c
            hlCache[p] = h
        end
        h.Enabled = true
        local hum = humC
        local frac = hum and math.clamp(G.__rvl4_hpRatio(hum), 0, 1) or nil
        local fc = espColor(p, frac)
        if h.FillColor ~= fc then h.FillColor = fc end
    elseif h then
        h.Enabled = false
    end

    local head = cc and cc.head
    local b = bbCache[p]
    if b and not foeL and (not (b.gui and b.gui.Parent) or (head and b.head ~= head)) then
        pcall(function() b.gui:Destroy() end)
        bbCache[p] = nil
        b = nil
    end
    if not c or not head then
        if b then b.gui.Enabled = false b._en = false end
        return
    end
    if not (cfg.esp.name or cfg.esp.wp) then
        if b then b.gui.Enabled = false b._en = false end
        return
    end
    if foeL and (not b or b.head ~= head or not b.gui.Parent) then
        makeBB(p)
        b = bbCache[p]
    end
    if not b then return end
    local hum = cc and cc.hum
    local dist = (head.Position - cam.CFrame.Position).Magnitude
    local show = foeL and hum and hum.Health > 0 and dist <= cfg.esp.max
    if b._en ~= show then
        b._en = show
        b.gui.Enabled = show and true or false
    end
    if b._md ~= cfg.esp.max then
        b._md = cfg.esp.max
        b.gui.MaxDistance = cfg.esp.max
    end
    if not show then return end
    local tool = c:FindFirstChildOfClass("Tool")
    local nameTxt = cfg.esp.name and (p.DisplayName ~= "" and p.DisplayName or p.Name) or ""
    if b._ts ~= cfg.esp.tsize then
        b._ts = cfg.esp.tsize
        b.name.TextSize = cfg.esp.tsize
        b.wp.TextSize = math.max(9, cfg.esp.tsize - 1)
    end
    if b._n ~= nameTxt then b._n = nameTxt b.name.Text = nameTxt end
    local wpTxt = cfg.esp.wp and (tool and tool.Name or "") or ""
    if b._w ~= wpTxt then b._w = wpTxt b.wp.Text = wpTxt end
end

bind(plrs.PlayerRemoving, function(p)
    local h = hlCache[p]
    if h then hlCache[p] = nil pcall(function() h:Destroy() end) end
    local b = bbCache[p]
    if b then bbCache[p] = nil pcall(function() b.gui:Destroy() end) end
end)

local function espTick()
    if not cfg.esp.on and not next(hlCache) and not next(bbCache) then return end
    for _, p in ipairs(getPlist()) do
        if p ~= lp then pcall(espTickPlayer, p) end
    end
end

local dc = {}
local killDraw
do
    local BONES_R15 = {
        { "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" },
        { "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" }, { "LeftLowerArm", "LeftHand" },
        { "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" },
        { "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" }, { "LeftLowerLeg", "LeftFoot" },
        { "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" },
    }
    local BONES_R6 = {
        { "Head", "Torso" }, { "Torso", "Left Arm" }, { "Torso", "Right Arm" },
        { "Torso", "Left Leg" }, { "Torso", "Right Leg" },
    }

    local function makeDraw()
        local d = {}
        d.phase = math.random(0, 3)
        local okD = pcall(function()
            d.boxFill = Drawing.new("Square") d.boxFill.Filled = true d.boxFill.Color = Color3.fromRGB(8, 8, 8) d.boxFill.Transparency = .82 d.boxFill.ZIndex = 0
            d.boxBg = Drawing.new("Square") d.boxBg.Thickness = 3 d.boxBg.Filled = false d.boxBg.Color = Color3.fromRGB(5, 5, 5) d.boxBg.Transparency = .9 d.boxBg.ZIndex = 1
            d.box = Drawing.new("Square") d.box.Thickness = 1 d.box.Filled = false d.box.ZIndex = 2
            d.dist = Drawing.new("Text") d.dist.Size = 12 d.dist.Center = true d.dist.Outline = true
            d.trc = Drawing.new("Line") d.trc.Thickness = 1
            d.barBg = Drawing.new("Square") d.barBg.Filled = true d.barBg.Color = Color3.fromRGB(15, 15, 15) d.barBg.Transparency = .8
            d.barFg = Drawing.new("Square") d.barFg.Filled = true d.barFg.Transparency = .95
        end)
        if not okD then
            for _, key in ipairs({ "box", "boxBg", "boxFill", "dist", "trc", "barBg", "barFg" }) do
                if d[key] then pcall(function() d[key]:Remove() end) end
            end
            return nil
        end
        return d
    end
    local drawFailAt = {}
    killDraw = function(p)
        local d = dc[p]
        drawFailAt[p] = nil
        if not d then return end
        for _, key in ipairs({ "box", "boxBg", "boxFill", "dist", "trc", "barBg", "barFg" }) do
            pcall(function() d[key]:Remove() end)
        end
        for _, l in ipairs(d.bones or {}) do pcall(function() l:Remove() end) end
        dc[p] = nil
    end
    bind(plrs.PlayerRemoving, function(p) killDraw(p) end)
    local function hideDraw(d)
        if d._hid then return end
        d._hid = true
        d._vb, d._vd, d._vt, d._vbar = nil, nil, nil, nil
        d.box.Visible = false
        d.boxBg.Visible = false
        d.boxFill.Visible = false
        d.dist.Visible = false
        d.trc.Visible = false
        d.barBg.Visible = false
        d.barFg.Visible = false
        if d.bones then
            for _, l in ipairs(d.bones) do l.Visible = false end
        end
    end

    local dcLive = false
    local BODY_PARTS = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }
    local projParts = setmetatable({}, { __mode = "k" })
    local function projBox(c)
        local root = c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso")
        if not root then return nil end
        local nowP = os.clock()
        local pe = projParts[c]
        if not pe or nowP - pe.at > 5 or not pe.core then
            local arr = {}
            for _, nm in ipairs(BODY_PARTS) do
                local part = c:FindFirstChild(nm)
                if part then arr[#arr + 1] = part end
            end
            pe = { arr = arr, at = nowP, core = (c:FindFirstChild("Head") ~= nil) }
            projParts[c] = pe
        end
        local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
        local lnX, lnY, lnZ = math.huge, math.huge, math.huge
        local lxX, lxY, lxZ = -math.huge, -math.huge, -math.huge
        local front = 0
        local rcf = root.CFrame
        local rPos, rRight, rUp, rLook = rcf.Position, rcf.RightVector, rcf.UpVector, rcf.LookVector
        for _, part in ipairs(pe.arr) do
            if part.Parent then
                local pcf = part.CFrame
                local pPos, pR, pU, pL = pcf.Position, pcf.RightVector, pcf.UpVector, pcf.LookVector
                local hx, hy, hz = part.Size.X * .5, part.Size.Y * .5, part.Size.Z * .5
                for i = 0, 7 do
                    local sx = (i % 2 == 0) and -hx or hx
                    local sy = (math.floor(i / 2) % 2 == 0) and -hy or hy
                    local sz = (math.floor(i / 4) % 2 == 0) and -hz or hz
                    local wp = pPos + pR * sx + pU * sy - pL * sz
                    local rel = wp - rPos
                    local ax, ay, az = rel:Dot(rRight), rel:Dot(rUp), rel:Dot(rLook)
                    if ax < lnX then lnX = ax end
                    if ay < lnY then lnY = ay end
                    if az < lnZ then lnZ = az end
                    if ax > lxX then lxX = ax end
                    if ay > lxY then lxY = ay end
                    if az > lxZ then lxZ = az end
                    local s = cam:WorldToViewportPoint(wp)
                    if s.Z > 0 then
                        front = front + 1
                        if s.X < minX then minX = s.X end
                        if s.X > maxX then maxX = s.X end
                        if s.Y < minY then minY = s.Y end
                        if s.Y > maxY then maxY = s.Y end
                    end
                end
            end
        end
        if front == 0 then return nil end
        return minX, minY, maxX, maxY, Vector3.new(lxX - lnX, lxY - lnY, lxZ - lnZ), (lnX + lxX) * .5, (lnY + lxY) * .5
    end
    local fullEspNow = false
    local function drawPlayer(p, vp, projPart, capSet, pre, vStamp)
        local c = p.Character
        local cc0 = c and getChar(p)
        local r = cc0 and (cc0.root or cc0.head)
        local show = cfg.esp.on and r and pre
        local dist = 0
        if show then
            dist = pre
            if dist > cfg.esp.max then show = false end
        end
        if show and capSet and not capSet[p] then show = false end
        local d = dc[p]
        local fracNow = nil
        if cc0 and cc0.hum then
            fracNow = math.clamp(G.__rvl4_hpRatio(cc0.hum), 0, 1)
        end
        if show and d and not d._hid and not fullEspNow and dist > 800 and (frameId + d.phase) % 4 == 3
            and cfg.esp.colormode ~= "レインボー"
            and d.lastPos and (r.Position - d.lastPos).Magnitude < 1 and d.lastFrac == fracNow
            and d._vs == vStamp and d._cm == cfg.esp.colormode and d._mx == cfg.esp.max then
        elseif not show then
            if d then hideDraw(d) end
        else
            if d then d._hid = nil end
            if not d then
                if os.clock() - (drawFailAt[p] or 0) < .5 then
                    d = nil
                else
                    d = makeDraw()
                    if d then
                        dc[p] = d
                        drawFailAt[p] = nil
                    else
                        drawFailAt[p] = os.clock()
                    end
                end
            end
            if not d then
                -- creation failed (hostile Drawing): skip this player this frame
            else
            local bx0, by0, bx1, by1
            local now = os.clock()
            if d.bbChar == c and d.bbSize and cc0.root and now - d.bbAt < .4 then
                local rcf3 = r.CFrame
                local side3 = rcf3.RightVector * (d.bbOffX or 0)
                local up3 = rcf3.UpVector * ((d.bbOffY or 0) + d.bbSize.Y * .5)
                local dn3 = rcf3.UpVector * ((d.bbOffY or 0) - d.bbSize.Y * .5)
                local tp3, ton3 = cam:WorldToViewportPoint(r.Position + side3 + up3)
                local bt3, bon3 = cam:WorldToViewportPoint(r.Position + side3 + dn3)
                if ton3 and bon3 and tp3.Z > 0 and bt3.Z > 0 then
                    local hgt3 = math.abs(bt3.Y - tp3.Y)
                    local wid3 = math.clamp(hgt3 * d.bbRatio, 6, math.max(hgt3 * 2, 6))
                    bx0, by0, bx1, by1 = tp3.X - wid3 / 2, tp3.Y, tp3.X + wid3 / 2, bt3.Y
                end
            end
            if not bx0 and now - (d.bbFailAt or 0) >= .3 and (G.__rvl4_projLeft or 0) > 0 then
                G.__rvl4_projLeft = G.__rvl4_projLeft - 1
                local sz, offX, offY
                bx0, by0, bx1, by1, sz, offX, offY = projBox(c)
                if bx0 and sz then
                    d.bbChar, d.bbSize, d.bbAt = c, sz, now
                    d.bbRatio = sz.X / math.max(sz.Y, .1)
                    d.bbOffX, d.bbOffY = offX or 0, offY or 0
                else
                    d.bbFailAt = now
                end
            end
            if bx0 then
                bx0, by0 = math.max(bx0, 0), math.max(by0, 0)
                bx1, by1 = math.min(bx1, vp.X), math.min(by1, vp.Y)
            end
            if not bx0 or bx1 - bx0 < 2 or by1 - by0 < 2 then
                local tp2, ton2 = cam:WorldToViewportPoint(r.Position + Vector3.new(0, 3.2, 0))
                local bt2, bon2 = cam:WorldToViewportPoint(r.Position + Vector3.new(0, -3.2, 0))
                if ton2 and bon2 and tp2.Z > 0 and bt2.Z > 0 then
                    local hh2 = math.abs(bt2.Y - tp2.Y)
                    local ww2 = math.max(hh2 * .62, 24)
                    bx0, by0, bx1, by1 = tp2.X - ww2 / 2, tp2.Y, tp2.X + ww2 / 2, bt2.Y
                    bx0, by0 = math.max(bx0, 0), math.max(by0, 0)
                    bx1, by1 = math.min(bx1, vp.X), math.min(by1, vp.Y)
                end
            end
            if not bx0 or bx1 - bx0 < 2 or by1 - by0 < 2 then
                hideDraw(d)
            else
                local wid, hgt = bx1 - bx0, by1 - by0
                local x, y = bx0, by0
                local sameRect = d._gx == x and d._gy == y and d._gw == wid and d._gh == hgt and d._gvx == vp.X and d._gvy == vp.Y
                if d._vb ~= cfg.esp.box then
                    d._vb = cfg.esp.box
                    d.box.Visible = cfg.esp.box
                    d.boxBg.Visible = cfg.esp.box
                    d.boxFill.Visible = cfg.esp.box
                end
                if not sameRect then
                    d.box.Size = Vector2.new(wid, hgt)
                    d.box.Position = Vector2.new(x, y)
                    d.boxBg.Size = Vector2.new(wid + 2, hgt + 2)
                    d.boxBg.Position = Vector2.new(x - 1, y - 1)
                    d.boxFill.Size = Vector2.new(wid, hgt)
                    d.boxFill.Position = Vector2.new(x, y)
                end
                local frac = (cfg.esp.hp or cfg.esp.colormode == "体力") and fracNow or nil
                local bc = espColor(p, frac)
                if d._col ~= bc then
                    d._col = bc
                    d.box.Color = bc
                    d.trc.Color = bc
                    if d.bones then
                        for _, l in ipairs(d.bones) do l.Color = bc end
                    end
                end
                if d._vd ~= cfg.esp.dist then d._vd = cfg.esp.dist d.dist.Visible = cfg.esp.dist end
                local ld = math.floor(dist)
                if d._ts ~= cfg.esp.tsize then d._ts = cfg.esp.tsize d.dist.Size = cfg.esp.tsize end
                if d._ld ~= ld then d._ld = ld d.dist.Text = "[" .. ld .. "]" end
                if not sameRect then
                    d.dist.Position = Vector2.new(x + wid / 2, y + hgt + 2)
                    d.dist.Color = G.__rvl4_distCol
                    d.trc.From = Vector2.new(vp.X / 2, vp.Y)
                    d.trc.To = Vector2.new(x + wid / 2, y + hgt)
                end
                if d._vt ~= cfg.esp.trc then d._vt = cfg.esp.trc d.trc.Visible = cfg.esp.trc end
                if cfg.esp.hp and frac then
                    local bw = math.max(wid, 24)
                    local bx = x + (wid - bw) / 2
                    local barOff = cfg.esp.dist and cfg.esp.tsize + 6 or 16
                    if d._vbar ~= true then
                        d._vbar = true
                        d.barBg.Visible = true
                        d.barFg.Visible = true
                    end
                    if not sameRect or d._gf ~= frac or d._bk ~= barOff then
                        d.barBg.Size = Vector2.new(bw, 4)
                        d.barBg.Position = Vector2.new(bx, y + hgt + barOff)
                        d.barFg.Size = Vector2.new(bw * frac, 4)
                        d.barFg.Position = d.barBg.Position
                    end
                    local bfc = hpColor(frac)
                    if d._bfc ~= bfc then d._bfc = bfc d.barFg.Color = bfc end
                elseif d._vbar ~= false then
                    d._vbar = false
                    d.barBg.Visible = false
                    d.barFg.Visible = false
                end
                d._gx, d._gy, d._gw, d._gh, d._gf, d._gvx, d._gvy = x, y, wid, hgt, frac, vp.X, vp.Y
                d._bk = cfg.esp.dist and cfg.esp.tsize + 6 or 16
                d.lastPos = r.Position
                d.lastFrac = fracNow
                d._vs = vStamp
                d._cm = cfg.esp.colormode
                d._mx = cfg.esp.max
                if cfg.esp.skel then
                    if d.boneChar ~= c or (d.boneDirty and now - (d.boneAt or 0) > .5) then
                        d.boneChar = c
                        d.boneAt = now
                        d.boneList = {}
                        d.boneDirty = false
                        local pl = c:FindFirstChild("UpperTorso") and BONES_R15 or BONES_R6
                        d.bonePairs = pl
                        for idx, pair in ipairs(pl) do
                            local pa, pb = c:FindFirstChild(pair[1]), c:FindFirstChild(pair[2])
                            if not pa or not pb then d.boneDirty = true end
                            d.boneList[idx] = { pa, pb }
                        end
                    end
                    local wantB = #(d.bonePairs or BONES_R15)
                    if (not d.bones or #d.bones < wantB) and now - (d.boneFailAt or 0) >= .4 then
                        local nb = d.bones or {}
                        local baseB = #nb
                        local okB = pcall(function()
                            for i = baseB + 1, wantB do
                                local bl = Drawing.new("Line")
                                bl.Thickness = 1
                                bl.Transparency = .65
                                bl.Color = d._col or Color3.fromRGB(255, 255, 255)
                                nb[i] = bl
                            end
                        end)
                        if okB then
                            d.bones = nb
                        else
                            d.boneFailAt = now
                            for i = baseB + 1, #nb do pcall(function() nb[i]:Remove() end) nb[i] = nil end
                        end
                    end
                    for idx, bp in ipairs(d.boneList or {}) do
                        local l = d.bones and d.bones[idx]
                        local drawn = false
                        local a, b2 = bp[1], bp[2]
                        if (a and not a.Parent) or (b2 and not b2.Parent) then d.boneDirty = true end
                        if l and a and b2 and a.Parent and b2.Parent then
                            local s1, o1 = projPart(a)
                            local s2, o2 = projPart(b2)
                            if o1 and o2 and s1.Z > 0 and s2.Z > 0 then
                                l.Visible = true
                                l.From = Vector2.new(s1.X, s1.Y)
                                l.To = Vector2.new(s2.X, s2.Y)
                                drawn = true
                            end
                        end
                        if l and not drawn then l.Visible = false end
                    end
                    for j = #(d.boneList or {}) + 1, #(d.bones or {}) do d.bones[j].Visible = false end
                elseif d.bones then
                    for _, l in ipairs(d.bones) do l.Visible = false end
                end
            end
            end
        end
    end
    local function preOne(p)
        if not isFoeLoose(p) then return nil end
        local cc9 = getChar(p)
        local r9 = cc9 and (cc9.root or cc9.head)
        if not r9 then return nil end
        local d9 = (r9.Position - cam.CFrame.Position).Magnitude
        if d9 <= cfg.esp.max then return d9 end
        return nil
    end
    local function drawTick()
        if os.clock() - (G.__rvl4_espFullAt or 0) >= 1 then
            G.__rvl4_espFullAt = os.clock()
            fullEspNow = true
        else
            fullEspNow = false
        end
        local anyDraw = cfg.esp.on and (cfg.esp.box or cfg.esp.dist or cfg.esp.trc or cfg.esp.skel or cfg.esp.hp)
        if not anyDraw then
            if dcLive then
                for p in pairs(dc) do killDraw(p) end
                dcLive = false
            end
            return
        end
        dcLive = true
        local vp = cam.ViewportSize
        local projCache = G.__rvl4_projCache or {}
        G.__rvl4_projCache = projCache
        local pStamp = (G.__rvl4_projStamp or 0) + 1
        G.__rvl4_projStamp = pStamp
        local function projPart(part)
            local e = projCache[part]
            if e and e[3] == pStamp then return e[1], e[2] end
            local s, o = cam:WorldToViewportPoint(part.Position)
            if not e then e = {} projCache[part] = e end
            e[1], e[2], e[3] = s, o, pStamp
            return s, o
        end
        local capSet = nil
        local preMap = nil
        if cfg.esp.on then
            preMap = G.__rvl4_preMap or {}
            G.__rvl4_preMap = preMap
            for k in pairs(preMap) do preMap[k] = nil end
            local candN = 0
            for _, p in ipairs(getPlist()) do
                if p ~= lp then
                    local okD, d9 = pcall(preOne, p)
                    if okD then
                        if d9 then
                            preMap[p] = d9
                            candN = candN + 1
                        end
                    elseif os.clock() - (G.__rvl4_espErrAt or 0) > 10 then
                        G.__rvl4_espErrAt = os.clock()
                        G.__rvl4_errPush("esp: " .. string.sub(tostring(d9), 1, 60))
                    end
                end
            end
            if candN > cfg.esp.maxCount then
                local candD = {}
                for p9, d9 in pairs(preMap) do candD[#candD + 1] = { p = p9, d = d9 } end
                table.sort(candD, function(a, b) return a.d < b.d end)
                capSet = {}
                for i = 1, cfg.esp.maxCount do capSet[candD[i].p] = true end
            end
        end
        local ldP = G.__rvl4_load or 0
        G.__rvl4_projLeft = ldP >= 2 and 1 or (ldP == 1 and 2 or 4)
        local vStamp = (cfg.esp.box and 1 or 0) + (cfg.esp.trc and 2 or 0) + (cfg.esp.skel and 4 or 0) + (cfg.esp.hp and 8 or 0) + (cfg.esp.dist and 16 or 0) + (cfg.esp.tsize or 0) * 32
        for _, p in ipairs(getPlist()) do
            if p == lp then
                if dc[p] then killDraw(p) end
            else
                local pre = nil
                if preMap then pre = preMap[p] or false end
                local okP, errP = pcall(drawPlayer, p, vp, projPart, capSet, pre, vStamp)
                if not okP and os.clock() - (G.__rvl4_espErrAt or 0) > 10 then
                    G.__rvl4_espErrAt = os.clock()
                    local e = "esp: " .. string.sub(tostring(errP), 1, 60)
                    G.__rvl4_errPush(e)
                end
            end
        end
    end
    if Drawing then
        bind(run.RenderStepped, function()
            if not alive() then return end
            local nowG = os.clock()
            local dtG = nowG - (G.__rvl4_loadAt or nowG)
            G.__rvl4_loadAt = nowG
            if dtG > 0 and dtG < .25 then
                local ema = G.__rvl4_loadEma or .016
                ema = ema + (dtG - ema) * .03
                G.__rvl4_loadEma = ema
                local ld = G.__rvl4_load or 0
                if ema > .045 then ld = 2 elseif ema > .028 then ld = 1 elseif ema < .016 then ld = 0 end
                G.__rvl4_load = ld
            end
            local ld2 = G.__rvl4_load or 0
            if ld2 > 0 then
                G.__rvl4_drawN = (G.__rvl4_drawN or 0) + 1
                if ld2 == 1 and G.__rvl4_drawN % 2 == 0 then return end
                if ld2 >= 2 and G.__rvl4_drawN % 3 ~= 0 then return end
            end
            drawTick()
        end)
    end
end

local radarFr, radarDots = nil, nil
local featCleanup
do
    local dmgPool = {}
    local lastHpMap = {}
    local arrowPool = {}
    local radarAt = 0

    local function makeDmgGui()
        local g = Instance.new("BillboardGui")
        g.Size = UDim2.new(0, 90, 0, 26)
        g.AlwaysOnTop = true
        g.ExtentsOffset = Vector3.new(0, 2.4, 0)
        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1, 0, 1, 0)
        t.BackgroundTransparency = 1
        t.TextColor3 = Color3.fromRGB(255, 214, 90)
        t.Font = Enum.Font.BuilderSansBold
        t.TextSize = 15
        t.TextStrokeTransparency = .4
        t.Parent = g
        return g, t
    end

    local function spawnDmg(head, amt)
        local slot = nil
        for _, sl in ipairs(dmgPool) do
            if not sl.busy then slot = sl break end
        end
        if not slot then
            if #dmgPool >= 16 then return end
            local g, t = makeDmgGui()
            slot = { gui = g, tx = t, busy = false, used = false }
            table.insert(dmgPool, slot)
        end
        if slot.used and not slot.gui.Parent then
            slot.gui, slot.tx = makeDmgGui()
        end
        slot.used = true
        slot.busy = true
        slot.tx.Text = "-" .. amt
        slot.tx.TextColor3 = amt >= 50 and Color3.fromRGB(255, 140, 60) or Color3.fromRGB(255, 214, 90)
        slot.tx.TextTransparency = 0
        slot.gui.Adornee = head
        slot.gui.Parent = head
        slot.gui.Enabled = true
        local g2, t2 = slot.gui, slot.tx
        task.spawn(function()
            local t0 = os.clock()
            while alive() and g2.Parent and os.clock() - t0 < .8 do
                local k = (os.clock() - t0) / .8
                g2.ExtentsOffset = Vector3.new(0, 2.4 + k * 1.6, 0)
                t2.TextTransparency = k
                task.wait()
            end
            g2.Enabled = false
            if slot.gui == g2 then slot.busy = false end
        end)
    end

    local featN = 0
    local wasDmg = false
    bind(plrs.PlayerRemoving, function(p) lastHpMap[p] = nil end)
    local function featTick()
        featN = featN + 1
        if featN % 2 == 0 then return end
        if (G.__rvl4_load or 0) >= 2 and featN % 4 ~= 1 then return end
        if cfg.esp.dmg and not wasDmg then lastHpMap = {} end
        wasDmg = cfg.esp.dmg
        if not cfg.esp.arrow and #arrowPool > 0 then
            for _, l in ipairs(arrowPool) do pcall(function() l:Remove() end) end
            arrowPool = {}
        end
        local vp = cam.ViewportSize
        local cx, cy = vp.X * .5, vp.Y * .5
        local now = os.clock()
        local doRadar = cfg.esp.radar and radarFr and now - radarAt > .04
        if doRadar then radarAt = now end
        local myC = doRadar and getChar(lp) or nil
        local ai, di = 0, 0
        if cfg.esp.dmg or cfg.esp.arrow or doRadar then
        for _, p in ipairs(getPlist()) do
            if p ~= lp and isFoe(p) then
                local cc = getChar(p)
                if cc and cc.hum and cc.root then
                    if cfg.esp.dmg then
                        local hp = cc.hum.Health
                        local prevE = lastHpMap[p]
                        if prevE and prevE.c == cc.c and hp < prevE.hp and cc.head then
                            pcall(spawnDmg, cc.head, math.floor(prevE.hp - hp + .5))
                        end
                        if prevE then
                            prevE.hp, prevE.c = hp, cc.c
                        else
                            lastHpMap[p] = { hp = hp, c = cc.c }
                        end
                    end
                    if cfg.esp.arrow then
                        local sv, on = cam:WorldToViewportPoint(cc.root.Position)
                        if not on or sv.Z <= 0 or sv.X < 0 or sv.X > vp.X or sv.Y < 0 or sv.Y > vp.Y then
                            ai = ai + 1
                            local l = arrowPool[ai]
                            if not l and Drawing and ai <= 20 then
                                local okA, na = pcall(function()
                                    local l2 = Drawing.new("Line")
                                    l2.Thickness = 2
                                    l2.Color = Color3.fromRGB(255, 84, 84)
                                    l2.Transparency = .9
                                    return l2
                                end)
                                if okA and na then
                                    l = na
                                    arrowPool[ai] = l
                                end
                            end
                            if l then
                                local vx, vy = sv.X - cx, sv.Y - cy
                                if sv.Z <= 0 then vx, vy = -vx, -vy end
                                local len = math.sqrt(vx * vx + vy * vy)
                                if len > 1 then
                                    local dx, dy = vx / len, vy / len
                                    local rr = math.min(vp.X, vp.Y) * .5 - 46
                                    local ex, ey = cx + dx * rr, cy + dy * rr
                                    l.From = Vector2.new(ex, ey)
                                    l.To = Vector2.new(ex - dx * 18, ey - dy * 18)
                                    l.Visible = true
                                else
                                    l.Visible = false
                                end
                            end
                        end
                    end
                    if doRadar then
                        di = di + 1
                        local d = radarDots and radarDots[di]
                        if d then
                            if myC and myC.root then
                                local rel = cc.root.Position - myC.root.Position
                                local cf = cam.CFrame
                                local px = math.clamp(rel:Dot(cf.RightVector) / cfg.esp.rd, -1, 1) * 68
                                local pz = math.clamp(rel:Dot(cf.LookVector) / cfg.esp.rd, -1, 1) * 68
                                d.Position = UDim2.new(.5, px - 3, .5, -pz - 3)
                                local fr2 = math.clamp(G.__rvl4_hpRatio(cc.hum), 0, 1)
                                d.BackgroundColor3 = hpColor(fr2)
                                d.Visible = true
                            else
                                d.Visible = false
                            end
                        end
                    end
                end
            end
        end
        end
        for j = ai + 1, #arrowPool do arrowPool[j].Visible = false end
        if radarFr then
            radarFr.Visible = cfg.esp.radar and true or false
            if doRadar and radarDots then
                for j = di + 1, #radarDots do radarDots[j].Visible = false end
            end
        end
        for p in pairs(lastHpMap) do
            if not p.Parent then lastHpMap[p] = nil end
        end
    end

    featCleanup = function()
        for _, l in ipairs(arrowPool) do pcall(function() l:Remove() end) end
        for _, sl in ipairs(dmgPool) do pcall(function() sl.gui:Destroy() end) end
    end
    bind(run.RenderStepped, function()
        if alive() and (cfg.esp.dmg or cfg.esp.arrow or cfg.esp.radar or #arrowPool > 0 or (radarFr and radarFr.Visible)) then featTick() end
    end)
end

G.__rvl4_drawCleanup = function()
    for p in pairs(dc) do killDraw(p) end
    if featCleanup then pcall(featCleanup) end
    for p, h in pairs(hlCache) do pcall(function() h:Destroy() end) hlCache[p] = nil end
    for p, b in pairs(bbCache) do pcall(function() if b.gui then b.gui:Destroy() end end) bbCache[p] = nil end
    if fovD then pcall(function() fovD:Remove() end) end
    if tLineD then pcall(function() tLineD:Remove() end) end
    if tgtD then pcall(function() tgtD:Remove() end) end
end
