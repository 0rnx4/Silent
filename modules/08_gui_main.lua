local V = {}
local statDot, statTx, fpsTx, W, H
local setGuiVisible
local xhair, xhParts

local function buildGui()
    local function touchSize()
        local w, h
        if cam.ViewportSize.Y < 550 then
            w = math.min(cam.ViewportSize.X * .84, 600)
            h = math.min(cam.ViewportSize.Y * .88, 500)
        else
            w = math.min(cam.ViewportSize.X * .68, 600)
            h = math.min(cam.ViewportSize.Y * .68, 500)
        end
        return math.max(w, math.min(320, cam.ViewportSize.X - 16)), h
    end
    WG.reset()
    if G.__rvl4_dragSet then for d in pairs(G.__rvl4_dragSet) do G.__rvl4_dragSet[d] = nil end end
    G.__rvl4_guiBuilds = (G.__rvl4_guiBuilds or 0) + 1
    local myBuild = G.__rvl4_guiBuilds
    local pg = lp:FindFirstChild("PlayerGui")
    if not pg then pg = lp:WaitForChild("PlayerGui", 5) end
    if not pg then
        pcall(function() if gethui then pg = gethui() end end)
    end
    if not pg then error("PlayerGui not found") end
    local prev = pg:FindFirstChild("rvl_ui")
    if prev then prev:Destroy() end
    local prevR = pg:FindFirstChild("rvl_retry")
    if prevR then prevR:Destroy() end
    pcall(function()
        if gethui then
            local h = gethui()
            if h and h ~= pg then
                local prevH = h:FindFirstChild("rvl_ui")
                if prevH then prevH:Destroy() end
                local prevR2 = h:FindFirstChild("rvl_retry")
                if prevR2 then prevR2:Destroy() end
            end
        end
    end)
    for i = #ownUi, 1, -1 do ownUi[i] = nil end
    radarFr, radarDots = nil, nil

    V.ui = Instance.new("ScreenGui")
    V.ui.Name = "rvl_ui"
    V.ui.ResetOnSpawn = false
    V.ui.IgnoreGuiInset = true
    V.ui.DisplayOrder = 100
    V.ui.Parent = pg

    if touch then
        W, H = touchSize()
    else
        W, H = 704, 512
    end

    V.shadow = Instance.new("Frame")
    V.shadow.Size = UDim2.new(0, W, 0, H)
    V.shadow.AnchorPoint = Vector2.new(.5, .5)
    V.shadow.Position = UDim2.new(.5, 4, .5, 8)
    V.shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    V.shadow.BackgroundTransparency = .45
    V.shadow.BorderSizePixel = 0
    V.shadow.Parent = V.ui
    corner(V.shadow, 10)

    V.main = Instance.new("Frame")
    V.main.Size = UDim2.new(0, W, 0, H)
    V.main.AnchorPoint = Vector2.new(.5, .5)
    V.main.Position = UDim2.new(.5, 0, .5, 0)
    V.main.BackgroundColor3 = C.bg
    V.main.BorderSizePixel = 0
    V.main.Active = true
    V.main.ClipsDescendants = true
    V.main.Parent = V.ui
    table.insert(ownUi, V.main)
    corner(V.main, 10)
    stroke(V.main)
    local function fitScale()
        if touch then return 1 end
        if cam.ViewportSize.Y >= 760 and cam.ViewportSize.X >= 820 then return 1 end
        return math.max(.6, math.min(cam.ViewportSize.X / 820, cam.ViewportSize.Y / 760))
    end
    local function uiFactor()
        local u = cfg.misc.uiscale
        if u == "大" then return 1.15 end
        if u == "特大" then return 1.3 end
        return 1
    end
    local us1 = Instance.new("UIScale") us1.Scale = fitScale() * uiFactor() us1.Parent = V.main
    local us2 = Instance.new("UIScale") us2.Scale = us1.Scale us2.Parent = V.shadow
    pcall(function()
        local watched = {}
        local function watchCam(c2)
            if not c2 or watched[c2] then return end
            watched[c2] = true
            bind(c2:GetPropertyChangedSignal("ViewportSize"), function()
                if G.__rvl4_guiBuilds ~= myBuild or ws.CurrentCamera ~= c2 then return end
                local s = fitScale() * uiFactor()
                us1.Scale = s
                us2.Scale = s
                if touch then
                    W, H = touchSize()
                    local HH = G.__rvl4_mini and 38 or H
                    V.main.Size = UDim2.new(0, W, 0, HH)
                    V.shadow.Size = UDim2.new(0, W, 0, HH)
                end
                local vp2 = cam.ViewportSize
                local szx, szy = V.main.Size.X.Offset, V.main.Size.Y.Offset
                local pp = V.main.Position
                local cx = math.clamp(vp2.X / 2 + pp.X.Offset, 60 - szx / 2, vp2.X - 60 + szx / 2)
                local cy = math.clamp(vp2.Y / 2 + pp.Y.Offset, szy / 2, vp2.Y - 38 + szy / 2)
                V.main.Position = UDim2.new(pp.X.Scale, cx - vp2.X / 2, pp.Y.Scale, cy - vp2.Y / 2)
            end)
        end
        watchCam(cam)
        bind(ws:GetPropertyChangedSignal("CurrentCamera"), function()
            if G.__rvl4_guiBuilds ~= myBuild then return end
            watchCam(ws.CurrentCamera)
        end)
    end)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, 38)
    bar.BackgroundTransparency = 1
    bar.BorderSizePixel = 0
    bar.Parent = V.main

    local logo = Instance.new("Frame")
    logo.Size = UDim2.new(0, 28, 0, 28)
    logo.Position = UDim2.new(0, 12, 0, 5)
    logo.BackgroundColor3 = C.card
    logo.BorderSizePixel = 0
    logo.Parent = bar
    corner(logo, 8)
    stroke(logo)
    local ring = Instance.new("Frame")
    ring.Size = UDim2.new(0, 16, 0, 16)
    ring.AnchorPoint = Vector2.new(.5, .5)
    ring.Position = UDim2.new(.5, 0, .5, 0)
    ring.BackgroundTransparency = 1
    ring.BorderSizePixel = 0
    ring.Parent = logo
    corner(ring, 8)
    local rst = Instance.new("UIStroke")
    rst.Color = C.accent
    rst.Thickness = 2
    rst.Parent = ring
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 4, 0, 4)
    dot.AnchorPoint = Vector2.new(.5, .5)
    dot.Position = UDim2.new(.5, 0, .5, 0)
    dot.BackgroundColor3 = C.accent
    dot.BorderSizePixel = 0
    dot.Parent = logo
    corner(dot, 2)

    local ttl = Instance.new("TextLabel")
    ttl.Size = UDim2.new(0, 330, 0, 20)
    ttl.Position = UDim2.new(0, 50, 0, 9)
    ttl.BackgroundTransparency = 1
    ttl.Text = "discord@kurudojindegomen"
    ttl.TextColor3 = C.text
    ttl.Font = Enum.Font.BuilderSansBold
    ttl.TextSize = 16
    ttl.TextXAlignment = Enum.TextXAlignment.Left
    ttl.Parent = bar

    local verTx = Instance.new("TextLabel")
    verTx.Size = UDim2.new(0, 44, 0, 14)
    verTx.Position = UDim2.new(1, -130, 0, 12)
    verTx.BackgroundTransparency = 1
    verTx.Text = "v118"
    verTx.TextColor3 = C.faint
    verTx.Font = Enum.Font.BuilderSans
    verTx.TextSize = 11
    verTx.TextXAlignment = Enum.TextXAlignment.Right
    verTx.Parent = bar

    local function topBtn(txt, x)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, touch and 34 or 30, 0, touch and 34 or 30)
        b.Position = UDim2.new(1, x, 0, touch and 2 or 4)
        b.BackgroundColor3 = C.card
        b.BorderSizePixel = 0
        b.Text = txt
        b.TextColor3 = C.sub
        b.Font = Enum.Font.BuilderSansBold
        b.TextSize = 14
        b.AutoButtonColor = false
        b.Parent = bar
        corner(b, 8)
        stroke(b)
        WG._fx(b, function() return C.sub end, true)
        b.InputBegan:Connect(function() WG.markCtrl() end)
        return b
    end
    V.closeB = topBtn("×", touch and -40 or -36)
    V.minB = topBtn("–", touch and -80 or -72)
    bind(V.minB.Activated, function()
        local mini2 = not G.__rvl4_mini
        G.__rvl4_mini = mini2
        local h = mini2 and 38 or H
        tw(V.main, { Size = UDim2.new(0, W, 0, h) }, .22)
        tw(V.shadow, { Size = UDim2.new(0, W, 0, h) }, .22)
        V.side.Visible = not mini2
        V.pages.Visible = not mini2
        V.minB.Text = mini2 and "+" or "–"
    end)
    bind(V.closeB.Activated, function() setGuiVisible(false) end)

    V.side = Instance.new("Frame")
    V.side.Size = UDim2.new(0, touch and 98 or 152, 1, -38)
    V.side.Position = UDim2.new(0, 0, 0, 38)
    V.side.BackgroundColor3 = C.sidebar
    V.side.BorderSizePixel = 0
    V.side.Parent = V.main
    V.side.ClipsDescendants = true
    local tabScroll = Instance.new("ScrollingFrame")
    tabScroll.Size = UDim2.new(1, -16, 1, -82)
    tabScroll.Position = UDim2.new(0, 8, 0, 48)
    tabScroll.BackgroundTransparency = 1
    tabScroll.BorderSizePixel = 0
    tabScroll.ScrollBarThickness = 2
    tabScroll.ScrollBarImageColor3 = C.faint
    tabScroll.CanvasSize = UDim2.new(0, 0, 0, 6 * ((touch and 52 or 40) + 6))
    tabScroll.Parent = V.side
    local tabLay = Instance.new("UIListLayout")
    tabLay.Padding = UDim.new(0, 6)
    tabLay.SortOrder = Enum.SortOrder.LayoutOrder
    tabLay.Parent = tabScroll

    statDot = Instance.new("Frame")
    statDot.Size = UDim2.new(0, 7, 0, 7)
    statDot.Position = UDim2.new(0, 14, 1, -24)
    statDot.BackgroundColor3 = C.faint
    statDot.BorderSizePixel = 0
    statDot.Parent = V.side
    corner(statDot, 4)
    statTx = Instance.new("TextLabel")
    statTx.Size = UDim2.new(1, -31, 0, 14)
    statTx.Position = UDim2.new(0, 27, 1, -28)
    statTx.BackgroundTransparency = 1
    statTx.Text = "待機中"
    statTx.TextColor3 = C.sub
    statTx.Font = Enum.Font.BuilderSans
    statTx.TextSize = 13
    statTx.TextXAlignment = Enum.TextXAlignment.Left
    statTx.Parent = V.side
    fpsTx = Instance.new("TextLabel")
    fpsTx.Size = UDim2.new(0, 60, 0, 14)
    fpsTx.Position = UDim2.new(1, -196, 0, 13)
    fpsTx.BackgroundTransparency = 1
    fpsTx.Text = ""
    fpsTx.TextColor3 = C.faint
    fpsTx.Font = Enum.Font.BuilderSans
    fpsTx.TextSize = 10
    fpsTx.TextXAlignment = Enum.TextXAlignment.Right
    fpsTx.Parent = bar

    V.pages = Instance.new("Frame")
    V.pages.Size = UDim2.new(1, -(touch and 98 or 152), 1, -38)
    V.pages.Position = UDim2.new(0, touch and 98 or 152, 0, 38)
    V.pages.BackgroundTransparency = 1
    V.pages.BorderSizePixel = 0
    V.pages.ClipsDescendants = true
    V.pages.Parent = V.main

    local savePend = false
    local function noteFail(okF, errF, notedF, label)
        if G[okF] == false then
            if not G[notedF] then
                G[notedF] = true
                G.__rvl4_errPush(label .. ": " .. (G[errF] or "?"))
            end
        else
            G[notedF] = false
        end
    end
    local function markDirty()
        if savePend then return end
        savePend = true
        G.__rvl4_pendingCfg = cfg
        task.delay(1, function()
            savePend = false
            if alive() then
                save()
                if G.__rvl4_saveOk then G.__rvl4_pendingCfg = nil end
                noteFail("__rvl4_saveOk", "__rvl4_saveErr", "__rvl4_saveNoted", "save失敗")
                noteFail("__rvl4_bakOk", "__rvl4_bakErr", "__rvl4_bakNoted", "bak失敗")
            end
        end)
    end
    WG.setDirty(markDirty)
    local function refreshAll() WG.refresh() end
    WG.applyLoaded = function()
        sanitize()
        refreshAll()
        setFly(cfg.fly.on)
        if not cfg.hb.on then restoreHB() end
        applyVis()
        applyFps()
        applyQot()
        if not cfg.camf.on then cam.FieldOfView = baseFov end
    end
    local function resetCfg()
        applyDefaults(cfg.misc.prof)
        WG.applyLoaded()
        save()
    end
    local tabs = {}
    local builders = {}
    local curTab = nil
    local curPage = nil
    local tabOrder = 0
    local searchQuery = ""
    local function selectTab(id)
        curTab = id
        G.__rvl4_tab = id
        local prevPage = curPage
        for tid, t in pairs(tabs) do
            local on = (tid == id)
            t.page.Visible = on
            tw(t.btn, { BackgroundColor3 = on and C.hover or C.card })
            t.btn.TextColor3 = on and C.text or C.sub
            if t.bar then t.bar.Visible = on end
            if on then curPage = t.page end
        end
        local b = builders[id]
        if b then
            local okB, errB = pcall(b)
            if okB then
                builders[id] = nil
            else
                local eB = "gui構築失敗(" .. tostring(id) .. "): " .. string.sub(tostring(errB), 1, 60)
                errHist = (errHist == "" and eB or (errHist .. " | " .. eB))
                if #errHist > 220 then errHist = string.sub(errHist, -220) end
                local pgF = tabs[id] and tabs[id].page
                if pgF then WG.rollback(pgF) end
            end
        end
        if curPage and prevPage and curPage ~= prevPage then
            curPage.Position = UDim2.new(0, 0, 0, 6)
            tw(curPage, { Position = UDim2.new(0, 0, 0, 0) }, .15)
        end
        if curPage then
            if searchQuery ~= "" then
                WG.applySearch(curPage, searchQuery)
            else
                WG.fixCanvas(curPage)
            end
        end
    end

    local function createTab(id, label)
        tabOrder = tabOrder + 1
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 0, touch and 52 or 40)
        b.BackgroundColor3 = C.card
        b.BorderSizePixel = 0
        b.Text = label
        b.TextColor3 = C.sub
        b.Font = Enum.Font.BuilderSansBold
        b.TextSize = 14
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.AutoButtonColor = false
        b.LayoutOrder = tabOrder
        b.Parent = tabScroll
        corner(b, 8)
        local bar3 = Instance.new("Frame")
        bar3.Size = UDim2.new(0, 3, 0, 16)
        bar3.AnchorPoint = Vector2.new(0, .5)
        bar3.Position = UDim2.new(0, 0, .5, 0)
        bar3.BackgroundColor3 = C.accent
        bar3.BorderSizePixel = 0
        bar3.Visible = false
        bar3.ZIndex = 2
        bar3.Parent = b
        corner(bar3, 2)
        local bp = Instance.new("UIPadding")
        bp.PaddingLeft = UDim.new(0, 12)
        bp.Parent = b
        b.MouseEnter:Connect(function() if curTab ~= id then b.TextColor3 = C.text b.BackgroundColor3 = C.hover end end)
        b.MouseLeave:Connect(function() if curTab ~= id then b.TextColor3 = C.sub b.BackgroundColor3 = C.card end end)
        WG._fx(b, function() return curTab == id and C.hover or C.card end)

        local p = Instance.new("ScrollingFrame")
        p.Size = UDim2.new(1, 0, 1, 0)
        p.BackgroundTransparency = 1
        p.BorderSizePixel = 0
        p.ScrollBarThickness = 3
        p.ScrollBarImageColor3 = C.faint
        p.ScrollBarImageTransparency = .35
        p.CanvasSize = UDim2.new(0, 0, 0, 0)
        p.AutomaticCanvasSize = Enum.AutomaticSize.None
        p.ClipsDescendants = true
        p.Visible = false
        p.Parent = V.pages

        tabs[id] = { btn = b, page = p, bar = bar3 }
        b.InputBegan:Connect(function() WG.markCtrl() end)
        b.Activated:Connect(function() selectTab(id) end)
        return p
    end

    xhair = Instance.new("Frame")
    xhair.Size = UDim2.new(0, 20, 0, 20)
    xhair.AnchorPoint = Vector2.new(.5, .5)
    xhair.Position = UDim2.new(.5, 0, .5, 0)
    xhair.BackgroundTransparency = 1
    xhair.BorderSizePixel = 0
    xhair.Visible = false
    xhair.ZIndex = 60
    xhair.Parent = V.ui
    xhParts = {}
    local function xhRect(w2, h2, x, y)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(0, w2, 0, h2)
        f.AnchorPoint = Vector2.new(.5, .5)
        f.Position = UDim2.new(.5, x, .5, y)
        f.BackgroundColor3 = C.accent
        f.BorderSizePixel = 0
        f.ZIndex = 60
        f.Parent = xhair
        corner(f, 2)
        table.insert(xhParts, f)
        return f
    end
    xhRect(4, 4, 0, 0) xhRect(2, 6, 0, -8) xhRect(2, 6, 0, 8) xhRect(6, 2, -8, 0) xhRect(6, 2, 8, 0)

    local unload
    unload = function()
        cfg.misc.qot = false
        save()
        G.__rvl4_gen = G.__rvl4_gen + 1
        pcall(function()
            if writefile then writefile("rvl_boot.txt", "ok") end
        end)
        if G.__rvl4_cfg then
            G.__rvl4_cfg.sil.on = false
            G.__rvl4_cfg.sil.remotes = false
        end
        if G.__rvl4_state then
            G.__rvl4_state.part = nil
            G.__rvl4_state.pos = nil
        end
        G.__rvl4_guiopen = false
        if G.__rvl4_snap then
            pcall(function() cam.CFrame = G.__rvl4_snap end)
            G.__rvl4_snap = nil
        end
        pcall(function() if run.UnbindFromRenderStep then run:UnbindFromRenderStep("rvl4_strafe") end end)
        if G.__rvl4_strafeOff then pcall(G.__rvl4_strafeOff) end
        if G.__rvl4_thirdOrig then
            local t3 = G.__rvl4_thirdOrig
            G.__rvl4_thirdOrig = nil
            pcall(function()
                lp.CameraMode = t3[1]
                lp.CameraMinZoomDistance = t3[2]
                lp.CameraMaxZoomDistance = t3[3]
            end)
        end
        pcall(function()
            if not getrawmetatable then return end
            local mt = getrawmetatable(game)
            if G.__rvl4_oldidx ~= nil then tryInstall(mt, "__index", G.__rvl4_oldidx, directOnly) end
            if G.__rvl4_oldnc ~= nil then tryInstall(mt, "__namecall", G.__rvl4_oldnc, directOnly) end
        end)
        G.__rvl4_oldidx, G.__rvl4_oldnc = nil, nil
        G.__rvl4_silent, G.__rvl4_namecall, G.__rvl4_idxok, G.__rvl4_ncok = nil, nil, nil, nil
        if G.__rvl4_hsnd then
            pcall(function() G.__rvl4_hsnd:Destroy() end)
            G.__rvl4_hsnd = nil
        end
        if G.__rvl4_emote then G.__rvl4_emote(false) end
        if G.__rvl4_dragConns then
            G.__rvl4_disconnectAll(G.__rvl4_dragConns)
            G.__rvl4_dragConns = nil
        end
        G.__rvl4_disconnectAll(G.__rvl4_chromeConns)
        G.__rvl4_chromeConns = nil
        G.__rvl4_chromeFor = nil
        G.__rvl4_disconnectAll(conns)
        G.__rvl4_dragBound = nil
        G.__rvl4_dragSet = nil
        pcall(function() setFly(false) end)
        if afPressed then
            if G.__rvl4_afVim then
                pcall(function()
                    local vim2 = game:GetService("VirtualInputManager")
                    local vs2 = cam.ViewportSize
                    vim2:SendMouseButtonEvent(vs2.X / 2, vs2.Y / 2, 0, false, game, 0)
                end)
            else
                pcall(function() if mouse1release then mouse1release() end end)
            end
            afPressed = false
            G.__rvl4_afHeld = nil
        end
        cfg.combat.norecoil = false cfg.combat.nospread = false cfg.combat.rapid = false
        cfg.combat.reload = false cfg.combat.equip = false cfg.combat.ammo = false
        cfg.combat.fullauto = false cfg.combat.ads = false cfg.combat.dmgmod = false
        pcall(modsTick)
        pcall(combatTick)
        cfg.fpsb = false pcall(applyFps)
        restoreHB()
        cfg.noc = false pcall(noclipTick)
        cfg.spd.on = false cfg.jmp.on = false pcall(moveTick)
        cfg.vis.fb = false cfg.vis.nf = false pcall(applyVis)
        cfg.misc.third = false pcall(thirdTick)
        cfg.misc.rainbow = false pcall(rainbowTick)
        pcall(function() cam.FieldOfView = baseFov end)
        if fovD then pcall(function() fovD:Remove() end) end
        if tLineD then pcall(function() tLineD:Remove() end) end
        if tgtD then pcall(function() tgtD:Remove() end) end
        if featCleanup then featCleanup() end
        for p in pairs(dc) do killDraw(p) end
        for _, h in pairs(hlCache) do pcall(function() h:Destroy() end) end
        for _, b in pairs(bbCache) do pcall(function() b.gui:Destroy() end) end
        pcall(function() V.ui:Destroy() end)
        G.__rvl4_beaconAct = nil
        pcall(function()
            local pgb = lp:FindFirstChild("PlayerGui")
            local bc = pgb and pgb:FindFirstChild("rvl_beacon")
            if bc then bc:Destroy() end
        end)
    end

    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, -16, 0, 30)
    searchBox.Position = UDim2.new(0, 8, 0, 10)
    searchBox.BackgroundColor3 = C.card
    searchBox.BorderSizePixel = 0
    searchBox.PlaceholderText = "設定を検索"
    searchBox.PlaceholderColor3 = C.faint
    searchBox.Text = ""
    searchBox.TextColor3 = C.text
    searchBox.Font = Enum.Font.BuilderSans
    searchBox.TextSize = 12
    searchBox.ClearTextOnFocus = false
    searchBox.LayoutOrder = 0
    searchBox.Parent = V.side
    corner(searchBox, 8)
    local sbStroke = stroke(searchBox)
    searchBox.Focused:Connect(function() tw(sbStroke, { Transparency = .55 }, .12) end)
    searchBox.FocusLost:Connect(function() tw(sbStroke, { Transparency = .88 }, .12) end)
    searchBox.InputBegan:Connect(function() WG.markCtrl() end)
    local function onSearch()
        searchQuery = searchBox.Text or ""
        if curPage then WG.applySearch(curPage, searchQuery) end
    end
    pcall(function() searchBox:GetPropertyChangedSignal("Text"):Connect(onSearch) end)
    searchBox.FocusLost:Connect(function() onSearch() end)

    createTab("aim", "照準")
    createTab("esp", "ESP")
    createTab("combat", "戦闘")
    createTab("move", "移動")
    createTab("misc", "その他")
    createTab("server", "サーバー")

    builders.aim = function()
        WG.begin(tabs.aim.page)
        WG.sec("ターゲット")
        WG.tog("エイムボット", function() return cfg.aim.on end, function(v) cfg.aim.on = v end)
        WG.tog("サイレントエイム", function() return cfg.sil.on end, function(v) cfg.sil.on = v if v and G.__rvl4_armHooks then G.__rvl4_armHooks() end end)
        WG.tog("トリガーボット", function() return cfg.trg.on end, function(v) cfg.trg.on = v end)
        WG.cycle("狙う部位", function() return cfg.aim.part end, function(v) cfg.aim.part = v end, { "Head", "HumanoidRootPart", "UpperTorso", "Closest" })
        WG.tog("常時エイム", function() return cfg.aim.always end, function(v) cfg.aim.always = v end)
        WG.tog("発射中もエイム", function() return cfg.aim.fire end, function(v) cfg.aim.fire = v end)
        if touch then WG.note("スマホ：画面の右半分を押している間エイムします") end
        WG.tog("フリック", function() return cfg.aim.flick end, function(v) cfg.aim.flick = v end)
        WG.cycle("優先モード", function() return cfg.aim.prio end, function(v) cfg.aim.prio = v end, { "クロスヘア", "低HP", "近距離", "複合" })
        WG.cycle("ターゲット切替キー", function() return cfg.aim.cyclekey end, function(v) cfg.aim.cyclekey = v end, { "T", "Q", "V", "なし" })
        WG.sec("調整")
        WG.num("FOV（視野）", function() return cfg.aim.fov end, function(v) cfg.aim.fov = v end, 20, 1200)
        WG.num("なめらかさ", function() return cfg.aim.sm end, function(v) cfg.aim.sm = v end, 0.05, 1)
        WG.tog("距離でなめらかさを変える", function() return cfg.aim.adaptive end, function(v) cfg.aim.adaptive = v end)
        WG.dep(function() return cfg.aim.adaptive end)
        WG.num("近距離の効き", function() return cfg.aim.smNear end, function(v) cfg.aim.smNear = v end, 0.3, 2.5)
        WG.num("遠距離の効き", function() return cfg.aim.smFar end, function(v) cfg.aim.smFar = v end, 0.2, 1.5)
        WG.dep(nil)
        WG.num("予測", function() return cfg.aim.pred end, function(v) cfg.aim.pred = v end, 0, 0.5)
        WG.dep(function() return cfg.sil.on end)
        WG.num("命中率 %", function() return cfg.sil.chance end, function(v) cfg.sil.chance = v end, 10, 100)
        WG.num("頭部率 %", function() return cfg.sil.headchance end, function(v) cfg.sil.headchance = v end, 0, 100)
        WG.num("サイレントFOV", function() return cfg.sil.fov end, function(v) cfg.sil.fov = v end, 30, 1200)
        WG.tog("リモート改変（RIVALS専用）", function() return cfg.sil.remotes end, function(v) cfg.sil.remotes = v end)
        WG.text("追加リモート名", function() return cfg.sil.extra end, function(v) cfg.sil.extra = v end, "カンマ区切り")
        WG.text("追加の呼び出し元", function() return cfg.sil.callers end, function(v) cfg.sil.callers = v end, "カンマ区切り")
        WG.dep(nil)
        WG.note("サイレントをONにするとフックが自動で入ります。フックが効かない環境では、撃つ瞬間だけカメラが目標を向く旧方式が予備で働きます")
        WG.dep(function() return cfg.trg.on end)
        WG.num("トリガーFOV", function() return cfg.trg.fov end, function(v) cfg.trg.fov = v end, 2, 120)
        WG.num("トリガー遅延 ms", function() return cfg.trg.delay end, function(v) cfg.trg.delay = v end, 0, 300)
        WG.tog("トリガー: エイム中のみ", function() return cfg.trg.ads end, function(v) cfg.trg.ads = v end)
        WG.seg("トリガー方式", function() return cfg.trg.mode end, function(v) cfg.trg.mode = v end, { "連射", "単発" })
        WG.tog("トリガー: 頭のみ", function() return cfg.trg.head end, function(v) cfg.trg.head = v end)
        WG.tog("トリガー: スコープ時のみ", function() return cfg.trg.scope end, function(v) cfg.trg.scope = v end)
        WG.dep(nil)
        WG.tog("スティッキー", function() return cfg.aim.sticky end, function(v) cfg.aim.sticky = v end)
        WG.tog("チーム判定", function() return cfg.aim.team end, function(v) cfg.aim.team = v end)
        WG.seg("敵味方判定", function() return cfg.misc.teammode end, function(v) cfg.misc.teammode = v end, { "自動", "全員敵" })
        WG.tog("壁判定", function() return cfg.aim.wall end, function(v) cfg.aim.wall = v end)
        WG.tog("レイジボット", function() return cfg.aim.ragebot end, function(v) cfg.aim.ragebot = v end)

    end

    builders.esp = function()
        WG.begin(tabs.esp.page)
        WG.sec("ESP")
        if Drawing == nil then WG.note("この実行環境ではボックス系ESPとFOV円は使えません（チャムス・名前・体力は使えます）") end
        WG.tog("有効", function() return cfg.esp.on end, function(v) cfg.esp.on = v end)
        WG.dep(function() return cfg.esp.on end)
        WG.tog("味方を除外", function() return cfg.esp.team end, function(v) cfg.esp.team = v end)
        WG.tog("チャムス", function() return cfg.esp.chams end, function(v) cfg.esp.chams = v end)
        WG.tog("ボックス", function() return cfg.esp.box end, function(v) cfg.esp.box = v end)
        WG.tog("名前", function() return cfg.esp.name end, function(v) cfg.esp.name = v end)
        WG.tog("武器", function() return cfg.esp.wp end, function(v) cfg.esp.wp = v end)
        WG.tog("体力", function() return cfg.esp.hp end, function(v) cfg.esp.hp = v end)
        WG.tog("距離", function() return cfg.esp.dist end, function(v) cfg.esp.dist = v end)
        WG.tog("トレーサー", function() return cfg.esp.trc end, function(v) cfg.esp.trc = v end)
        WG.tog("スケルトン", function() return cfg.esp.skel end, function(v) cfg.esp.skel = v end)
        WG.tog("ターゲットライン", function() return cfg.esp.tline end, function(v) cfg.esp.tline = v end)
        WG.tog("レーダー", function() return cfg.esp.radar end, function(v) cfg.esp.radar = v end)
        WG.dep(function() return cfg.esp.on and cfg.esp.radar end)
        WG.num("レーダー範囲", function() return cfg.esp.rd end, function(v) cfg.esp.rd = v end, 40, 600)
        WG.dep(function() return cfg.esp.on end)
        WG.tog("ダメージ表示", function() return cfg.esp.dmg end, function(v) cfg.esp.dmg = v end)
        WG.tog("画面外矢印", function() return cfg.esp.arrow end, function(v) cfg.esp.arrow = v end)
        WG.tog("対象表示", function() return cfg.esp.tgt end, function(v) cfg.esp.tgt = v end)
        WG.num("最大距離", function() return cfg.esp.max end, function(v) cfg.esp.max = v end, 100, 10000)
        WG.num("最大表示人数", function() return cfg.esp.maxCount end, function(v) cfg.esp.maxCount = v end, 5, 300)
        WG.num("ESP文字サイズ", function() return cfg.esp.tsize end, function(v) cfg.esp.tsize = v end, 10, 28)
        WG.seg("色モード", function() return cfg.esp.colormode end, function(v) cfg.esp.colormode = v end, { "赤", "白", "緑", "青", "黄", "紫", "体力", "レインボー" })
        WG.dep(nil)

    end

    builders.combat = function()
        WG.begin(tabs.combat.page)
        WG.sec("戦闘")
        WG.tog("リコイルなし", function() return cfg.combat.norecoil end, function(v) cfg.combat.norecoil = v end)
        WG.tog("拡散なし", function() return cfg.combat.nospread end, function(v) cfg.combat.nospread = v end)
        WG.tog("オートファイア", function() return cfg.combat.auto end, function(v) cfg.combat.auto = v end)
        WG.tog("ヒットサウンド", function() return cfg.combat.hsnd end, function(v) cfg.combat.hsnd = v end)
        WG.tog("キルサウンド", function() return cfg.combat.ksnd end, function(v) cfg.combat.ksnd = v end)
        WG.dep(function() return cfg.combat.hsnd or cfg.combat.ksnd end)
        WG.num("ヒット音量", function() return cfg.combat.hsndVol end, function(v) cfg.combat.hsndVol = v end, .05, 1)
        WG.text("ヒット音ID（空=既定）", function() return cfg.combat.hsndId end, function(v) cfg.combat.hsndId = v end, "数値ID")
        WG.dep(nil)
        WG.tog("弾丸トレーサー", function() return cfg.combat.tracer end, function(v) cfg.combat.tracer = v end)
        WG.text("追加の偏向武器名", function() return cfg.combat.meleeExtra end, function(v) cfg.combat.meleeExtra = v end, "カンマ区切り")
        WG.sec("武器MOD")
        local mf = WG.row(touch and 52 or 46)
        modStatTx = WG.label(mf, "武器MOD: —", 10)
        WG.tog("連射", function() return cfg.combat.rapid end, function(v) cfg.combat.rapid = v end)
        WG.tog("フルオート化", function() return cfg.combat.fullauto end, function(v) cfg.combat.fullauto = v end)
        WG.tog("ADS高速", function() return cfg.combat.ads end, function(v) cfg.combat.ads = v end)
        WG.tog("オートリロード", function() return cfg.combat.autoreload end, function(v) cfg.combat.autoreload = v end)
        WG.tog("ダメージ倍増", function() return cfg.combat.dmgmod end, function(v) cfg.combat.dmgmod = v end)
        WG.tog("リロード高速", function() return cfg.combat.reload end, function(v) cfg.combat.reload = v end)
        WG.tog("持ち替え高速", function() return cfg.combat.equip end, function(v) cfg.combat.equip = v end)
        WG.tog("弾薬無限", function() return cfg.combat.ammo end, function(v) cfg.combat.ammo = v end)
    end

    builders.move = function()
        WG.begin(tabs.move.page)
        WG.sec("移動")
        WG.tog("飛行", function() return cfg.fly.on end, function(v) cfg.fly.on = v setFly(v) end)
        WG.dep(function() return cfg.fly.on end)
        WG.num("飛行速度", function() return cfg.fly.spd end, function(v) cfg.fly.spd = v end, 10, 500)
        WG.dep(nil)
        WG.tog("速度", function() return cfg.spd.on end, function(v) cfg.spd.on = v end)
        WG.dep(function() return cfg.spd.on end)
        WG.num("速度の値", function() return cfg.spd.val end, function(v) cfg.spd.val = v end, 16, 400)
        WG.dep(nil)
        WG.tog("ジャンプ", function() return cfg.jmp.on end, function(v) cfg.jmp.on = v end)
        WG.dep(function() return cfg.jmp.on end)
        WG.num("ジャンプ力", function() return cfg.jmp.val end, function(v) cfg.jmp.val = v end, 50, 1000)
        WG.dep(nil)
        WG.tog("壁抜け", function() return cfg.noc end, function(v) cfg.noc = v end)
        WG.tog("無限ジャンプ", function() return cfg.infj end, function(v) cfg.infj = v end)
        WG.tog("バニーホップ", function() return cfg.bhop end, function(v) cfg.bhop = v end)
        WG.tog("自動ストレイフ", function() return cfg.strafe.on end, function(v) cfg.strafe.on = v end)
        WG.dep(function() return cfg.strafe.on end)
        WG.seg("ストレイフ方式", function() return cfg.strafe.mode end, function(v) cfg.strafe.mode = v end, { "発射中", "常時", "空中" })
        WG.num("ストレイフ間隔", function() return cfg.strafe.int end, function(v) cfg.strafe.int = v end, 30, 300)
        WG.num("ストレイフ強さ", function() return cfg.strafe.str end, function(v) cfg.strafe.str = v end, .3, 3)
        WG.dep(nil)
        WG.tog("落下防止（奈落レスキュー）", function() return cfg.void.on end, function(v) cfg.void.on = v end)
        WG.btn("ターゲットへTP", function()
            pcall(function()
                if not curTarget then return end
                local cc = getChar(curTarget)
                local mc = lp.Character
                local mr = mc and (mc:FindFirstChild("HumanoidRootPart") or mc:FindFirstChild("Torso"))
                if cc and cc.root and mr then
                    mr.CFrame = cc.root.CFrame * CFrame.new(0, 0, 3.5)
                end
            end)
        end)
    end

    builders.misc = function()
        WG.begin(tabs.misc.page)
        WG.sec("その他")
        WG.tog("ヒットボックス拡大", function() return cfg.hb.on end, function(v) cfg.hb.on = v if not v then restoreHB() end end)
        WG.dep(function() return cfg.hb.on end)
        WG.num("拡大サイズ", function() return cfg.hb.size end, function(v) cfg.hb.size = v end, 2, 30)
        WG.seg("拡大部位", function() return cfg.hb.part end, function(v) cfg.hb.part = v end, { "両方", "頭", "胴体" })
        WG.dep(nil)
        WG.tog("FPSブースト", function() return cfg.fpsb end, function(v) cfg.fpsb = v applyFps() end)
        WG.tog("AFK防止", function() return cfg.afk end, function(v) cfg.afk = v end)
        WG.sec("画面")
        WG.tog("フルブライト", function() return cfg.vis.fb end, function(v) cfg.vis.fb = v applyVis() end)
        WG.tog("霧なし", function() return cfg.vis.nf end, function(v) cfg.vis.nf = v applyVis() end)
        WG.tog("カメラFOV", function() return cfg.camf.on end, function(v) cfg.camf.on = v if not v then cam.FieldOfView = baseFov end end)
        WG.dep(function() return cfg.camf.on end)
        WG.num("FOVの値", function() return cfg.camf.val end, function(v) cfg.camf.val = v end, 60, 140)
        WG.dep(nil)
        WG.tog("クロスヘア", function() return cfg.xhair.on end, function(v) cfg.xhair.on = v end)
        WG.dep(function() return cfg.xhair.on end)
        WG.num("クロスヘアサイズ", function() return cfg.xhair.size end, function(v) cfg.xhair.size = v end, 2, 14)
        WG.num("クロスヘア間隔", function() return cfg.xhair.gap end, function(v) cfg.xhair.gap = v end, 4, 16)
        WG.num("クロスヘア太さ", function() return cfg.xhair.thick end, function(v) cfg.xhair.thick = v end, 1, 4)
        WG.dep(nil)
        WG.seg("UIサイズ", function() return cfg.misc.uiscale end, function(v) cfg.misc.uiscale = v us1.Scale = fitScale() * uiFactor() us2.Scale = us1.Scale end, { "標準", "大", "特大" })
        WG.tog("レインボー武器", function() return cfg.misc.rainbow end, function(v) cfg.misc.rainbow = v end)
        WG.tog("三人称カメラ", function() return cfg.misc.third end, function(v) cfg.misc.third = v end)
        WG.tog("テレポート後も自動実行", function() return cfg.misc.qot end, function(v) cfg.misc.qot = v applyQot() end)
        WG.tog("フックを入れない", function() return cfg.misc.nohook end, function(v) cfg.misc.nohook = v save() end)
        WG.cycle("フック方式", function() return cfg.misc.hookmode end, function(v) cfg.misc.hookmode = v save() end, { "両方", "リモートのみ", "なし" })
        WG.note("フック方式は次回起動から。初期値はリモートのみ（本格サイレント）。両方はマウス判定を使うゲーム向けで、干渉が大きく落ちやすいです")
        WG.text("エモートID", function() return cfg.misc.emoteId end, function(v) cfg.misc.emoteId = v end, "アニメーションID（数値）")
        WG.btn("エモート再生", function() if G.__rvl4_emote then G.__rvl4_emote(true) end end)
        WG.btn("エモート停止", function() if G.__rvl4_emote then G.__rvl4_emote(false) end end)
        local diagTx = nil
        WG.btn("動作チェック", function()
            local hookOk = G.__rvl4_idxok or G.__rvl4_ncok
            local silMode = not cfg.sil.on and "OFF" or ((G.__rvl4_ncok and cfg.sil.remotes and "本格") or (hookOk and "レイ") or "不可")
            local drawOk = Drawing ~= nil
            local saveOk = writefile ~= nil
            local libOk = probeLib and probeLib()
            local n = 0
            for _, p in ipairs(getPlist()) do
                if isEnemy(p) then n = n + 1 end
            end
            if diagTx then
                diagTx.Text = "モード " .. (safeLevel == 2 and "セーフ（フック無効）" or safeMode and "セーフ軽" or "通常") .. " / フック " .. (hookOk and "OK" or "不可") .. " / サイレント " .. silMode .. " / 状態 " .. (G.__rvl4_state and G.__rvl4_state.part and "ロック中" or "待機") .. " / 描画 " .. (drawOk and "OK" or "なし") .. " / 保存 " .. (saveOk and "OK" or "不可") .. " / 武器 " .. (libOk and "OK" or "未検出") .. " / 敵 " .. n .. "人" .. " / 判定 " .. teamBasis() .. " / ping " .. math.floor(getPing() * 1000) .. "ms" .. (prevStage and prevStage ~= "ok" and (" / 前回 " .. prevStage .. "で停止") or "") .. (hookErr ~= "" and (" / フックエラー " .. string.sub(hookErr, -40)) or (errHist ~= "" and (" / エラー " .. string.sub(errHist, -110)) or " / エラーなし")) .. (G.__rvl4_rejCaller and (" / 却caller " .. tostring(G.__rvl4_rejCaller)) or "") .. ((G.__rvl4_hookDbg == "nc-install" or G.__rvl4_hookDbg == "nc-installed") and (" / 前回フック " .. G.__rvl4_hookDbg) or "")
            end
        end)
        local df = WG.row(touch and 108 or 96)
        diagTx = WG.label(df, "動作チェックを押すと結果を表示します", 10)
        diagTx.TextWrapped = true
        diagTx.TextSize = 11
    end

    builders.server = function()
        WG.begin(tabs.server.page)
        WG.sec("サーバー")
        WG.btn("再参加", function()
            save()
            pcall(function() tps:Teleport(game.PlaceId, lp) end)
        end)
        WG.btn("サーバー移動", function()
            save()
            pcall(function()
                local d = hs:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"))
                local list = {}
                for _, s in ipairs(d.data or {}) do
                    if s.playing < s.maxPlayers and s.id ~= game.JobId then
                        table.insert(list, s.id)
                    end
                end
                if #list > 0 then
                    tps:TeleportToPlaceInstance(game.PlaceId, list[math.random(#list)], lp)
                end
            end)
        end)
        WG.sec("設定")
        WG.seg("プロファイル", function() return tostring(cfg.misc.prof or 1) end, function(v)
            save()
            local okW = pcall(function()
                if writefile then writefile("rvl_tools_prof.json", hs:JSONEncode({ prof = tonumber(v) })) end
            end)
            if writefile and not okW then return end
            cfg.misc.prof = tonumber(v)
            cfFile = (v == "1") and "rvl_tools_v3.json" or "rvl_tools_v3_p" .. v .. ".json"
            applyDefaults(cfg.misc.prof)
            loadCfg()
            WG.applyLoaded()
        end, { "1", "2", "3" })
        WG.btn("設定を保存", save)
        WG.btn("設定を読込", function()
            loadCfg()
            WG.applyLoaded()
        end)
        do
            local rb = WG.btn("設定をリセット", function() end)
            local armed, armAt = false, 0
            rb.Activated:Connect(function()
                if armed and os.clock() - armAt < 3 then
                    armed = false
                    rb.Text = "設定をリセット"
                    resetCfg()
                else
                    armed = true
                    armAt = os.clock()
                    rb.Text = "本当にリセットする？"
                    task.delay(3, function()
                        if armed then
                            armed = false
                            pcall(function() rb.Text = "設定をリセット" end)
                        end
                    end)
                end
            end)
        end
        WG.btn("起動フラグをリセット", function()
            pcall(function()
                if writefile then writefile("rvl_boot.txt", "ok") end
            end)
        end)
        WG.sec("終了")
        WG.btn("完全終了", unload, true)
    end

    selectTab(G.__rvl4_tab or "aim")
    if G.__rvl4_guiopen == false then
        V.main.Visible = false
        V.shadow.Visible = false
    else
        G.__rvl4_guiopen = true
    end
end

local function makeRadar()
    if not V.ui then return end
    if radarFr then return end
    radarFr = Instance.new("Frame")
    radarFr.Size = UDim2.new(0, 148, 0, 148)
    radarFr.Position = UDim2.new(1, -162, 0, 66)
    radarFr.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
    radarFr.BackgroundTransparency = .25
    radarFr.BorderSizePixel = 0
    radarFr.Visible = false
    radarFr.Parent = V.ui
    corner(radarFr, 10)
    stroke(radarFr)
    table.insert(ownUi, radarFr)
    radarDots = {}
    for i = 1, 32 do
        local d = Instance.new("Frame")
        d.Size = UDim2.new(0, 7, 0, 7)
        d.BackgroundColor3 = Color3.fromRGB(255, 84, 84)
        d.BorderSizePixel = 0
        d.Visible = false
        d.Parent = radarFr
        corner(d, 4)
        radarDots[i] = d
    end
    local meDot = Instance.new("Frame")
    meDot.Size = UDim2.new(0, 7, 0, 7)
    meDot.Position = UDim2.new(.5, -3, .5, -3)
    meDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    meDot.BorderSizePixel = 0
    meDot.Parent = radarFr
    corner(meDot, 4)
end

stage("gui")
local guiOk, guiErr = pcall(buildGui)
local armBeaconOk = nil
V.finishBuild = function()
    local okM, errM = pcall(makeRadar)
    if not okM then G.__rvl4_errPush("radar: " .. string.sub(tostring(errM), 1, 60)) end
    if V.setupChrome then pcall(V.setupChrome) end
    stage("gui")
    if armBeaconOk then armBeaconOk() end
end
local function showRetry(errText)
    pcall(function()
        local pg2 = lp:WaitForChild("PlayerGui", 5)
        if not pg2 then return end
        local old = pg2:FindFirstChild("rvl_retry")
        if old then old:Destroy() end
        local g = Instance.new("ScreenGui")
        g.Name = "rvl_retry"
        g.ResetOnSpawn = false
        g.Parent = pg2
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 150, 0, 52)
        b.Position = UDim2.new(1, -164, 0, 14)
        b.BackgroundColor3 = C.card
        b.Text = "メニュー再試行\n" .. string.sub(tostring(errText), 1, 90)
        b.TextWrapped = true
        b.TextColor3 = C.text
        b.Font = Enum.Font.BuilderSansBold
        b.TextSize = 14
        b.AutoButtonColor = false
        b.Parent = g
        corner(b, 10)
        stroke(b)
        b.Activated:Connect(function()
            local okR, errR = pcall(buildGui)
            if okR then
                V.finishBuild()
                g:Destroy()
            else
                b.Text = "メニュー再試行\n" .. string.sub(tostring(errR), 1, 90)
            end
        end)
    end)
end
if not guiOk then
    print("[rvl] gui build failed: " .. tostring(guiErr))
    pcall(function() if V.ui then V.ui:Destroy() end end)
    V.ui = nil
    V.main, V.shadow = nil, nil
    statTx, statDot, fpsTx, xhair, xhParts = nil, nil, nil, nil, nil
    showRetry(guiErr)
    G.__rvl4_beaconAct = function()
        local okA, errA = pcall(buildGui)
        if okA then
            V.finishBuild()
            local pg5 = lp:FindFirstChild("PlayerGui")
            local oldR = pg5 and pg5:FindFirstChild("rvl_retry")
            if oldR then oldR:Destroy() end
        else
            showRetry(errA)
        end
    end
    if beaconTx then beaconTx.Visible = true end
    if G.__rvl4_beaconSay then G.__rvl4_beaconSay("rvl v118 GUI失敗（タップで再試行）: " .. string.sub(tostring(guiErr), 1, 70), true) end
end

do
    local okM2, errM2 = pcall(makeRadar)
    if not okM2 then G.__rvl4_errPush("radar: " .. string.sub(tostring(errM2), 1, 60)) end
end

task.delay(2.5, function()
    if not alive() then return end
    if V.ui then
        pcall(function()
            local pg3 = lp:FindFirstChild("PlayerGui")
            if pg3 and V.ui.Parent ~= pg3 then V.ui.Parent = pg3 end
        end)
    else
        local pg3 = lp:FindFirstChild("PlayerGui")
        if pg3 and not pg3:FindFirstChild("rvl_retry") then
            showRetry(guiErr)
        end
    end
end)

setGuiVisible = function(v)
    if not V.main then return end
    V.main.Visible = v
    V.shadow.Visible = v
    G.__rvl4_guiopen = v
end

armBeaconOk = function()
    G.__rvl4_beaconAct = function()
        local pg4 = lp:FindFirstChild("PlayerGui")
        if pg4 and pg4:FindFirstChild("rvl_ui") and V.ui then
            pcall(function()
                if V.ui.Parent ~= pg4 then V.ui.Parent = pg4 end
            end)
            setGuiVisible(true)
        elseif G.__rvl4_ensureGui then
            G.__rvl4_ensureGui()
        end
    end
    if G.__rvl4_beaconSay then G.__rvl4_beaconSay("rvl v118 OK（タップでGUIを出す）", true) end
    if beaconTx then beaconTx.Visible = false end
end

V.setupChrome = function()
    if not (V.main and V.minB and V.closeB) then return end
    if G.__rvl4_chromeFor == V.main then return end
    local myChrome = G.__rvl4_guiBuilds
    if G.__rvl4_chromeConns then
        G.__rvl4_disconnectAll(G.__rvl4_chromeConns)
    end
    local chConns = {}
    G.__rvl4_chromeConns = chConns
    local function cbind(ev, fn)
        local c = bind(ev, fn)
        if c then chConns[#chConns + 1] = c end
        return c
    end
    local drag, dStart, startPos, dragObj = nil, nil, nil, nil
    local function syncShadow()
        V.shadow.Position = UDim2.new(V.main.Position.X.Scale, V.main.Position.X.Offset + 4, V.main.Position.Y.Scale, V.main.Position.Y.Offset + 8)
        V.shadow.Size = V.main.Size
    end
    cbind(V.main.InputBegan, function(i)
        if WG.ctrlFresh() then return end
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag = true
            dragObj = i
            dStart = i.Position
            startPos = V.main.Position
        end
    end)
    cbind(uis.InputChanged, function(i)
        if G.__rvl4_guiBuilds ~= myChrome then return end
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or (i.UserInputType == Enum.UserInputType.Touch and i == dragObj)) then
            local d = i.Position - dStart
            local nx, ny = startPos.X.Offset + d.X, startPos.Y.Offset + d.Y
            local vp3 = cam.ViewportSize
            local szx, szy = V.main.Size.X.Offset, V.main.Size.Y.Offset
            local cx = math.clamp(vp3.X / 2 + nx, 60 - szx / 2, vp3.X - 60 + szx / 2)
            local cy = math.clamp(vp3.Y / 2 + ny, szy / 2, vp3.Y - 38 + szy / 2)
            V.main.Position = UDim2.new(startPos.X.Scale, cx - vp3.X / 2, startPos.Y.Scale, cy - vp3.Y / 2)
            syncShadow()
        end
    end)
    cbind(uis.InputEnded, function(i)
        if G.__rvl4_guiBuilds ~= myChrome then return end
        if drag and i == dragObj then
            drag = false
            dragObj = nil
        end
    end)
    local icS2 = nil
    pcall(function() icS2 = uis.InputCancelled end)
    if icS2 then
        cbind(icS2, function(i)
            if G.__rvl4_guiBuilds ~= myChrome then return end
            if drag and dragObj and i.UserInputType == dragObj.UserInputType then
                drag = false
                dragObj = nil
            end
        end)
    end

    local mini = G.__rvl4_mini or false
    if mini then
        V.side.Visible = false
        V.pages.Visible = false
        V.minB.Text = "+"
    end
    cbind(uis.InputBegan, function(i, gp)
        if G.__rvl4_guiBuilds ~= myChrome then return end
        if not gp and i.KeyCode == Enum.KeyCode.F6 then
            setGuiVisible(not V.main.Visible)
        end
    end)

    if touch and V.ui and V._tbFor ~= V.ui then
    V._tbFor = V.ui
    local function roundBtn(txt, y)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 58, 0, 58)
        b.Position = UDim2.new(1, -74, 1, y)
        b.BackgroundColor3 = C.card
        b.BackgroundTransparency = .15
        b.Text = txt
        b.TextColor3 = C.text
        b.Font = Enum.Font.BuilderSansBold
        b.TextSize = 24
        b.Parent = V.ui
        corner(b, 29)
        stroke(b)
        return b
    end
    local up = roundBtn("↑", -162)
    local dn = roundBtn("↓", -94)
    local upIn, dnIn = nil, nil
    local function hold(b, fn, setIn)
        cbind(b.InputBegan, function(i) if i.UserInputType == Enum.UserInputType.Touch then setIn(i) fn(true) end end)
        cbind(b.InputEnded, function(i) if i.UserInputType == Enum.UserInputType.Touch then setIn(nil) fn(false) end end)
    end
    hold(up, function(v) upHeld = v end, function(i) upIn = i end)
    hold(dn, function(v) dnHeld = v end, function(i) dnIn = i end)
    cbind(uis.InputEnded, function(i)
        if G.__rvl4_guiBuilds ~= myChrome then return end
        if upIn and i == upIn then upIn = nil upHeld = false end
        if dnIn and i == dnIn then dnIn = nil dnHeld = false end
    end)
    table.insert(ownUi, up)
    table.insert(ownUi, dn)
    cbind(run.RenderStepped, function()
        if not alive() or G.__rvl4_guiBuilds ~= myChrome then return end
        if not cfg.fly.on then upHeld, dnHeld = false, false end
        up.Visible = cfg.fly.on
        dn.Visible = cfg.fly.on
    end)
    local mb = Instance.new("TextButton")
    mb.AnchorPoint = Vector2.new(1, 0)
    mb.Size = UDim2.new(0, 46, 0, 46)
    mb.Position = UDim2.new(1, -10, 0, 10)
    mb.BackgroundColor3 = C.card
    mb.BackgroundTransparency = .1
    mb.Text = "≡"
    mb.TextColor3 = C.text
    mb.Font = Enum.Font.BuilderSansBold
    mb.TextSize = 22
    mb.Parent = V.ui
    corner(mb, 10)
    stroke(mb)
    table.insert(ownUi, mb)
    chConns[#chConns + 1] = mb.Activated:Connect(function()
        if not V.main then return end
        setGuiVisible(not V.main.Visible)
    end)
    end

    local startH = G.__rvl4_mini and 38 or H
    if G.__rvl4_tweenGen ~= G.__rvl4_gen then
        G.__rvl4_tweenGen = G.__rvl4_gen
        V.main.Size = UDim2.new(0, W * .94, 0, startH * .94)
        V.shadow.Size = UDim2.new(0, W * .94, 0, startH * .94)
        tw(V.main, { Size = UDim2.new(0, W, 0, startH) }, .32)
        tw(V.shadow, { Size = UDim2.new(0, W, 0, startH) }, .32)
    else
        V.main.Size = UDim2.new(0, W, 0, startH)
        V.shadow.Size = UDim2.new(0, W, 0, startH)
    end
    G.__rvl4_chromeFor = V.main
end
if guiOk and armBeaconOk then armBeaconOk() end
G.__rvl4_chromeOk, G.__rvl4_chromeErr = pcall(V.setupChrome)
if not G.__rvl4_chromeOk and G.__rvl4_beaconSay then
    if beaconTx then beaconTx.Visible = true end
    G.__rvl4_beaconSay("rvl v118 chrome失敗（タップでGUIを出す）: " .. string.sub(tostring(G.__rvl4_chromeErr), 1, 50), true)
end

G.__rvl4_ensureGui = function()
    if not alive() then return end
    local pg5 = lp:FindFirstChild("PlayerGui")
    if not pg5 then return end
    local foundGui = pg5:FindFirstChild("rvl_ui") ~= nil
    if not foundGui then
        pcall(function()
            if gethui then
                local h = gethui()
                if h and h:FindFirstChild("rvl_ui") then foundGui = true end
            end
        end)
    end
    if foundGui then
        if V.ui then pcall(function() if V.ui.Parent ~= pg5 then V.ui.Parent = pg5 end end) end
        return
    end
    if os.clock() - (G.__rvl4_rebuildAt or 0) > 60 then G.__rvl4_rebuilds = 0 end
    G.__rvl4_rebuilds = (G.__rvl4_rebuilds or 0) + 1
    if G.__rvl4_rebuilds > 4 then return end
    G.__rvl4_rebuildAt = os.clock()
    if pcall(buildGui) then
        V.finishBuild()
        task.delay(5, function()
            if alive() and pg5:FindFirstChild("rvl_ui") then G.__rvl4_rebuilds = 0 end
        end)
    else
        G.__rvl4_rebuilds = math.max(0, G.__rvl4_rebuilds - 1)
        if V.ui then pcall(function() V.ui:Destroy() end) V.ui = nil end
        if not pg5:FindFirstChild("rvl_retry") then
            pcall(function() showRetry("GUI再構築に失敗しました") end)
        end
    end
end
task.delay(4, function() if G.__rvl4_ensureGui then G.__rvl4_ensureGui() end end)
task.delay(10, function() if G.__rvl4_ensureGui then G.__rvl4_ensureGui() end end)
task.delay(20, function() if G.__rvl4_ensureGui then G.__rvl4_ensureGui() end end)
task.spawn(function()
    while alive() do
        task.wait(15)
        if not alive() then break end
        if G.__rvl4_ensureGui then pcall(G.__rvl4_ensureGui) end
    end
end)
bind(lp.CharacterAdded, function()
    task.delay(1.5, function() if G.__rvl4_ensureGui then G.__rvl4_ensureGui() end end)
end)

bind(uis.InputBegan, function(i, gp)
    if gp or not alive() then return end
    local ck = cfg.aim.cyclekey
    if ck and ck ~= "なし" and i.KeyCode == Enum.KeyCode[ck] then
        cycSkip = curTarget or G.__rvl4_silLock
    end
end)
bind(uis.InputBegan, function(i, p)
    if p or not alive() then return end
    if i.KeyCode == Enum.KeyCode.Insert and V.main then
        setGuiVisible(not V.main.Visible)
    end
end)
