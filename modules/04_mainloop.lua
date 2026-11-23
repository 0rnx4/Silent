local fovD, tLineD, tgtD = nil, nil, nil
pcall(function()
    if not Drawing then return end
    tLineD = Drawing.new("Line")
    tLineD.Thickness = 1
    tLineD.Color = Color3.fromRGB(255, 84, 84)
    tLineD.Transparency = .7
    tLineD.Visible = false
    fovD = Drawing.new("Circle")
    fovD.Thickness = 1
    fovD.Color = Color3.fromRGB(255, 255, 255)
    fovD.Transparency = .85
    fovD.NumSides = touch and 32 or 64
    fovD.Filled = false
    tgtD = Drawing.new("Text")
    tgtD.Size = 15
    tgtD.Center = true
    tgtD.Outline = true
    tgtD.Color = Color3.fromRGB(255, 255, 255)
    tgtD.Transparency = .95
    tgtD.Visible = false
end)

local afPressed = false
local tracerLive = 0
local flyBV, flyBG, upHeld, dnHeld = nil, nil, nil, nil
if G.__rvl4_flyBV then pcall(function() G.__rvl4_flyBV:Destroy() end) G.__rvl4_flyBV = nil end
if G.__rvl4_flyBG then pcall(function() G.__rvl4_flyBG:Destroy() end) G.__rvl4_flyBG = nil end
if G.__rvl4_snap then
    pcall(function()
        local cc9 = ws.CurrentCamera
        if cc9 then cc9.CFrame = G.__rvl4_snap end
    end)
    G.__rvl4_snap = nil
    G.__rvl4_snapTail = nil
end
if G.__rvl4_afHeld then
    G.__rvl4_afHeld = nil
    if G.__rvl4_afVim then
        pcall(function()
            local vim3 = game:GetService("VirtualInputManager")
            local vs3 = cam.ViewportSize
            vim3:SendMouseButtonEvent(vs3.X / 2, vs3.Y / 2, 0, false, game, 0)
        end)
    else
        pcall(function() if mouse1release then mouse1release() end end)
    end
end

local function spawnTracer(toPos)
    if not cfg.combat.tracer or not Drawing then return end
    local s, on = cam:WorldToViewportPoint(toPos)
    if not on or s.Z <= 0 then return end
    if tracerLive >= 32 then return end
    local l
    local okT = pcall(function()
        l = Drawing.new("Line")
        l.Thickness = 1
        l.Color = Color3.fromRGB(255, 210, 90)
        l.Transparency = .9
        l.From = Vector2.new(cam.ViewportSize.X * .5, cam.ViewportSize.Y * .78)
        l.To = Vector2.new(s.X, s.Y)
        l.Visible = true
    end)
    if not okT or not l then return end
    tracerLive = tracerLive + 1
    task.delay(.12, function()
        tracerLive = tracerLive - 1
        pcall(function() l:Remove() end)
    end)
end

local function setFly(on)
    local c = lp.Character
    local r = c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso"))
    if flyBV then pcall(function() flyBV:Destroy() end) flyBV = nil G.__rvl4_flyBV = nil end
    if flyBG then pcall(function() flyBG:Destroy() end) flyBG = nil G.__rvl4_flyBG = nil end
    if on and r then
        flyBV = Instance.new("BodyVelocity")
        flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyBV.Velocity = Vector3.zero
        flyBV.Parent = r
        G.__rvl4_flyBV = flyBV
        flyBG = Instance.new("BodyGyro")
        flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        flyBG.P = 8000
        flyBG.Parent = r
        G.__rvl4_flyBG = flyBG
    end
end

do
    local lastClick = 0
    local trgNext = .07
    local lastTrgP = nil
    local lastTrgTrueAt = 0
    local lastTracerAt = 0
    local wasMB1 = false
    local wasFT = false
    local fovWasLock, tgtVpX, tgtVpY = nil, nil, nil
    local tgtLastP, tgtLastHp = nil, nil
    local mb1OnUi = false
    bind(uis.InputBegan, function(i, gp)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            mb1OnUi = gp and true or false
        end
    end)
    local fireTouch = false
    local fireInput = nil
    local strafeSign, strafeAt = 1, 0
    bind(uis.InputEnded, function(i)
        if i == fireInput then
            fireTouch = false
            fireInput = nil
        end
    end)
    local icSig = nil
    pcall(function() icSig = uis.InputCancelled end)
    if icSig then
        bind(icSig, function(i)
            if i == fireInput then
                fireTouch = false
                fireInput = nil
            end
        end)
    end
    local lastSafe, lastSafeAt, lastSafeChar = nil, 0, nil
    local MELEE = { "katana", "scythe", "fist", "shield", "knife" }

    local function myMelee()
        local c = lp.Character
        local tool = c and c:FindFirstChildOfClass("Tool")
        if not tool then
            G.__rvl4_meleeTool = nil
            return false
        end
        if tool == G.__rvl4_meleeTool then return G.__rvl4_meleeVal end
        local n = " " .. string.lower(tool.Name) .. " "
        local res = false
        for _, w in ipairs(MELEE) do
            if string.find(n, " " .. w .. " ", 1, true) then res = true break end
        end
        G.__rvl4_meleeTool, G.__rvl4_meleeVal = tool, res
        return res
    end

    G.__rvl4_snapHooksDead = function()
        if G.__rvl4_dispatchDead then return true end
        if not (G.__rvl4_idxok or G.__rvl4_ncok) then return true end
        return G.__rvl4_bendStuck and G.__rvl4_bendStuck() or false
    end
    G.__rvl4_snapNow = function()
        local ccam = ws.CurrentCamera
        if not ccam then return end
        if cfg.aim.on and ((not touch and uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)) or (touch and touchAimActive())) then return end
        if not (cfg.sil.on and G.__rvl4_snapHooksDead() and rollOk
            and silPos and silPos.Magnitude > .01 and not G.__rvl4_aimSteer and not myMelee()
            and ccam.CameraType ~= Enum.CameraType.Scriptable) then return end
        if not G.__rvl4_snap then G.__rvl4_snap = ccam.CFrame G.__rvl4_snapAt = os.clock() end
        ccam.CFrame = CFrame.new(ccam.CFrame.Position, silPos)
    end
    local function vimBtn(down)
        local okV = pcall(function()
            local vim = game:GetService("VirtualInputManager")
            local vs = cam.ViewportSize
            vim:SendMouseButtonEvent(vs.X / 2, vs.Y / 2, 0, down, game, 0)
        end)
        return okV
    end
    bind(uis.InputBegan, function(i, gp)
        if touch and i.UserInputType == Enum.UserInputType.Touch and gp then
            local pos = i.Position
            local vp = cam.ViewportSize
            if pos and pos.X > vp.X * .5 and pos.X < vp.X * .95 and pos.Y > vp.Y * .3 and pos.Y < vp.Y * .85 and not hitsOwnUi(pos) then
                fireTouch = true
                fireInput = i
                G.__rvl4_snapNow()
            end
        end
    end)
    bind(uis.InputBegan, function(i, gp)
        if not touch and i.UserInputType == Enum.UserInputType.MouseButton1 and not gp then
            G.__rvl4_snapNow()
        end
    end)
    local meleeMemo, defMemo = -1, nil
    local meleeNow = false
    local function deflectNow(p)
        if not p then return false end
        if not defMemo then defMemo = {} end
        local v = defMemo[p]
        if v == nil then
            v = targetDeflecting(p)
            defMemo[p] = v
        end
        return v
    end
    G.__rvl4_afRelease = function()
        if not afPressed then return end
        afPressed = false
        G.__rvl4_afHeld = nil
        if G.__rvl4_afVim then
            vimBtn(false)
        elseif mouse1release then
            pcall(function() mouse1release() end)
        else
            vimBtn(false)
        end
    end
    bind(run.RenderStepped, function(dt)
        if not alive() then return end
        frameId = frameId + 1
        if afPressed and not G.__rvl4_afDone then G.__rvl4_afRelease() end
        G.__rvl4_afDone = false
        if cfg.sil.on and not (G.__rvl4_ncok or G.__rvl4_idxok) and G.__rvl4_armHooks then
            local nowA = os.clock()
            if nowA - (G.__rvl4_armAt or 0) > 2 then
                G.__rvl4_armAt = nowA
                G.__rvl4_armHooks()
            end
        end
        dt = math.clamp(dt or .016, .001, .1)
        local ccLP = getChar(lp)
        visTtl = visTtl + (math.clamp(dt * 3, .03, .07) * ((G.__rvl4_load or 0) >= 1 and 1.8 or 1) - visTtl) * .1
        local nc2 = ws.CurrentCamera
        if nc2 and nc2 ~= cam then
            cam = nc2
            baseFov = cam.FieldOfView or baseFov
            if G.__rvl4_snap then
                G.__rvl4_snap = nil
                G.__rvl4_snapTail = 0
            end
        end
        if meleeMemo ~= frameId then
            meleeMemo = frameId
            meleeNow = myMelee()
            defMemo = nil
        end
        local mb1Now = uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
        local mb2Now = uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        local engaged = cfg.aim.ragebot or cfg.aim.always or cfg.trg.on or mb1Now or mb2Now or (touch and touchAimActive())
        if engaged or frameId % 2 == 1 then
            local okRT, errRT = pcall(refreshTarget)
            if not okRT then G.__rvl4_tgtErr = tostring(errRT) end
        end
        if G.__rvl4_state then
            G.__rvl4_state.part = silPart
            local okP2, pp2 = false, nil
            if G.__rvl4_silLock and silPart then okP2, pp2 = pcall(predictedPos, G.__rvl4_silLock, silPart) end
            G.__rvl4_state.pos = (okP2 and pp2) or silPos
            G.__rvl4_state.rollOk = rollOk
        end

        local aimSteer = false
        if cfg.aim.on and curPart and curPos and not meleeNow and not deflectNow(curTarget) then
            aimSteer = cfg.aim.ragebot or cfg.aim.always
                or (cfg.aim.fire and mb1Now and not mb1OnUi)
                or (touch and touchAimActive())
                or (not touch and mb2Now)
            if aimSteer then
                local s = cfg.aim.ragebot and math.max(cfg.aim.sm, .85) or cfg.aim.sm
                if cfg.aim.adaptive and not cfg.aim.ragebot then
                    local dNow = (curPos - cam.CFrame.Position).Magnitude
                    local blend = math.clamp((dNow - 35) / 20, 0, 1)
                    s = s * (cfg.aim.smNear + (cfg.aim.smFar - cfg.aim.smNear) * blend)
                end
                s = math.clamp(s, .02, 1)
                local a = 1 - (1 - s) ^ (dt * 60)
                local toT = curPos - cam.CFrame.Position
                if toT.Magnitude > .25 then
                    local skipDz = false
                    if cam.CFrame.LookVector:Dot(toT.Unit) > .9999985 then
                        local rt = rootOf(curTarget)
                        local tv = rt and smoothVel(rt)
                        if not tv or tv.Magnitude < 10 then skipDz = true end
                    end
                    if not skipDz then
                        local goal = CFrame.new(cam.CFrame.Position, curPos)
                        cam.CFrame = cam.CFrame:Lerp(goal, a)
                    end
                end
            end
        end

        G.__rvl4_aimSteer = aimSteer
        if cfg.aim.flick and ((mb1Now and not wasMB1) or (touch and fireTouch and not wasFT)) and not mb1OnUi and curPart and curPos and not meleeNow and not deflectNow(curTarget) and (not cfg.aim.wall or visAny(curTarget)) then
            cam.CFrame = CFrame.new(cam.CFrame.Position, curPos)
        end
        wasMB1 = mb1Now
        wasFT = fireTouch

        local firing = (mb1Now and not mb1OnUi) or (touch and fireTouch) or afPressed
        G.__rvl4_firing = firing
        if cfg.strafe.on and not cfg.fly.on and not G.__rvl4_guiopen then
            local ccS = ccLP
            local humS = ccS and ccS.hum
            if humS then
                local sAct = cfg.strafe.mode == "常時" or (cfg.strafe.mode == "発射中" and firing)
                if cfg.strafe.mode == "空中" then sAct = humS.FloorMaterial == Enum.Material.Air end
                if not sAct and G.__rvl4_strafeOff then pcall(G.__rvl4_strafeOff) end
                if sAct then
                    local nowS = os.clock()
                    if nowS - strafeAt >= cfg.strafe.int / 1000 then
                        strafeAt = nowS
                        strafeSign = -strafeSign
                    end
                    local rvS = cam.CFrame.RightVector
                    local latS = Vector3.new(rvS.X * strafeSign, 0, rvS.Z * strafeSign)
                    G.__rvl4_strafeLat = latS
                    G.__rvl4_strafeHum = humS
                    G.__rvl4_strafeRoot = ccS.root
                    G.__rvl4_strafeAt = os.clock()
                    if not G.__rvl4_strafeBound and G.__rvl4_strafeShape then
                        pcall(G.__rvl4_strafeShape, ccS.root, humS, latS, dt)
                    end
                end
            end
        elseif G.__rvl4_strafeOff then
            pcall(G.__rvl4_strafeOff)
        end
        if G.__rvl4_snapWas and not firing and G.__rvl4_snap then G.__rvl4_snapTail = os.clock() + .05 end
        G.__rvl4_snapWas = firing
        local snapLive = cfg.sil.on and G.__rvl4_snapHooksDead()
        if snapLive then G.__rvl4_snapLiveAt = os.clock() end
        local snapHardOff = not silPos or meleeNow or cam.CameraType == Enum.CameraType.Scriptable
        local snapFresh = os.clock() - math.max(G.__rvl4_snapAt or 0, G.__rvl4_snapLiveAt or 0) <= .5
        if G.__rvl4_snap and (not snapLive or snapHardOff) then
            if not aimSteer and snapFresh then cam.CFrame = G.__rvl4_snap end
            G.__rvl4_snap = nil
            G.__rvl4_snapTail = 0
        elseif snapLive and (firing or os.clock() < (G.__rvl4_snapTail or 0)) then
            G.__rvl4_snapNow()
        elseif G.__rvl4_snap then
            if not aimSteer and snapFresh then cam.CFrame = G.__rvl4_snap end
            G.__rvl4_snap = nil
            G.__rvl4_snapTail = 0
        end

        local trgFiredNow = false
        if cfg.trg.on and not G.__rvl4_guiopen and curTrg and not deflectNow(curTrgP) and not meleeNow
            and (cfg.trg.mode ~= "単発" or curTrgP ~= lastTrgP)
            and (not cfg.trg.scope or (not cfg.camf.on and cam.FieldOfView < baseFov - 4) or mb2Now or (touch and touchAimActive()))
            and os.clock() - lastClick >= trgNext then
            local gate
            if touch then
                gate = touchAimActive()
            else
                gate = not cfg.trg.ads or mb2Now
            end
            if gate then
                trgFiredNow = true
                lastClick = os.clock()
                lastTrgP = curTrgP
                trgNext = (cfg.trg.delay or 70) / 1000
                local okClk = false
                if mouse1click then okClk = pcall(mouse1click) end
                if not okClk then
                    vimBtn(true)
                    task.delay(.05, function() vimBtn(false) end)
                end
                local tp = partOf(curTrgP)
                if tp then pcall(spawnTracer, tp.Position) end
            end
        end
        if curTrg then lastTrgTrueAt = os.clock() end
        if not curTrg and os.clock() - lastTrgTrueAt > .75 then lastTrgP = nil end

        local fireWant = false
        if curTarget and not G.__rvl4_guiopen and not deflectNow(curTarget) and not meleeNow then
            if cfg.aim.ragebot then
                fireWant = not cfg.aim.wall or visible(curTarget)
            elseif cfg.combat.auto then
                if touch then
                    fireWant = touchAimActive()
                else
                    fireWant = mb2Now or mb1Now
                end
            end
        end
        if fireWant and not afPressed and not trgFiredNow then
            local afOk = false
            if mouse1press then
                local okP = pcall(function() mouse1press() end)
                if okP then
                    afOk = true
                    G.__rvl4_afVim = false
                end
            end
            if not afOk and vimBtn(true) then
                afOk = true
                G.__rvl4_afVim = true
            end
            if afOk then
                afPressed = true
                G.__rvl4_afHeld = true
            end
        elseif not fireWant and afPressed then
            G.__rvl4_afRelease()
        end
        G.__rvl4_afDone = true
        if fireWant and curPos and curPos.Magnitude > .01 and os.clock() - lastTracerAt > .09 then
            lastTracerAt = os.clock()
            pcall(spawnTracer, curPos)
        end

        if fovD then
            local silLock = cfg.sil.on and silPart ~= nil
            fovD.Visible = (cfg.aim.on or cfg.sil.on) and not cfg.aim.ragebot and not G.__rvl4_guiopen
            if fovD.Visible then fovD.Position = origin() end
            local wantR
            if cfg.aim.on and curTarget then
                wantR = cfg.aim.fov
            elseif silLock then
                wantR = cfg.sil.fov
            else
                wantR = cfg.aim.on and cfg.aim.fov or cfg.sil.fov
            end
            if fovD.Radius ~= wantR then fovD.Radius = wantR end
            local lockNow = (curTarget ~= nil) or silLock
            if lockNow ~= fovWasLock then
                fovWasLock = lockNow
                fovD.Color = lockNow and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(255, 255, 255)
            end
        end

        if tLineD then
            local show = false
            if cfg.esp.tline and not G.__rvl4_guiopen and curPart and (cfg.aim.on or cfg.sil.on) then
                local s, on = cam:WorldToViewportPoint(curPart.Position)
                if on and s.Z > 0 then
                    tLineD.From = origin()
                    tLineD.To = Vector2.new(s.X, s.Y)
                    show = true
                end
            end
            tLineD.Visible = show
        end

        if tgtD then
            if cfg.esp.tgt and not G.__rvl4_guiopen and curTarget and curPart then
                local cc = getChar(curTarget)
                local hp = cc and cc.hum and math.floor(G.__rvl4_hpRatio(cc.hum) * 100) or 0
                if curTarget ~= tgtLastP or hp ~= tgtLastHp then
                    tgtLastP, tgtLastHp = curTarget, hp
                    tgtD.Text = "対象： " .. (curTarget.DisplayName or curTarget.Name) .. "  HP " .. hp .. "%"
                end
                local vsx, vsy = cam.ViewportSize.X, cam.ViewportSize.Y
                if tgtVpX ~= vsx or tgtVpY ~= vsy then
                    tgtVpX, tgtVpY = vsx, vsy
                    tgtD.Position = Vector2.new(vsx / 2, vsy / 2 + 96)
                end
                tgtD.Visible = true
            else
                tgtD.Visible = false
            end
        end

        if cfg.fly.on then
            local ccF = ccLP
            local fr = ccF and ccF.root
            if fr and (not flyBV or not flyBG or flyBV.Parent ~= fr or flyBG.Parent ~= fr) then setFly(true) end
        end
        if cfg.fly.on and flyBV and flyBG then
            local ccF2 = ccLP
            local h = ccF2 and ccF2.hum
            if h then
                if touch then
                    local md = h.MoveDirection
                    local horiz = Vector3.new(md.X, 0, md.Z)
                    local vert = ((upHeld and 1 or 0) - (dnHeld and 1 or 0)) * cfg.fly.spd
                    flyBV.Velocity = flyBV.Velocity:Lerp(horiz * cfg.fly.spd + Vector3.new(0, vert, 0), 1 - math.exp(-dt * 20))
                else
                    local look = cam.CFrame.LookVector
                    local right = cam.CFrame.RightVector
                    local f, r, u = 0, 0, 0
                    if uis:IsKeyDown(Enum.KeyCode.W) then f = f + 1 end
                    if uis:IsKeyDown(Enum.KeyCode.S) then f = f - 1 end
                    if uis:IsKeyDown(Enum.KeyCode.A) then r = r - 1 end
                    if uis:IsKeyDown(Enum.KeyCode.D) then r = r + 1 end
                    if uis:IsKeyDown(Enum.KeyCode.Space) then u = u + 1 end
                    if uis:IsKeyDown(Enum.KeyCode.LeftShift) then u = u - 1 end
                    if upHeld then u = u + 1 end
                    if dnHeld then u = u - 1 end
                    local dir = look * f + right * r + Vector3.new(0, u, 0)
                    if dir.Magnitude > 1 then dir = dir.Unit end
                    flyBV.Velocity = flyBV.Velocity:Lerp(dir * cfg.fly.spd, 1 - math.exp(-dt * 20))
                end
                flyBG.CFrame = cam.CFrame
            end
        end

        if cfg.void.on then
            local mc = lp.Character
            if mc ~= lastSafeChar then
                lastSafeChar, lastSafe = mc, nil
            end
            local ccV = ccLP
            local mr = ccV and ccV.root
            local mh = ccV and ccV.hum
            if mr and mh then
                if mh.FloorMaterial ~= Enum.Material.Air and (mr.Position.Y > -40 or (spawnAt[lp] and os.clock() - spawnAt[lp] < 1.5)) then
                    lastSafe, lastSafeAt = mr.Position, os.clock()
                elseif mr.Position.Y < -60 and mh.FloorMaterial == Enum.Material.Air and not cfg.fly.on and lastSafe and os.clock() - lastSafeAt <= 20 and (lastSafe - mr.Position).Magnitude < 1500 then
                    mr.Position = lastSafe + Vector3.new(0, 3, 0)
                    mr.AssemblyLinearVelocity = Vector3.zero
                end
            end
        end

        if cfg.camf.on and cam.FieldOfView ~= cfg.camf.val then
            cam.FieldOfView = cfg.camf.val
        end
    end)
    G.__rvl4_strafeOff = function()
        G.__rvl4_strafeLat = nil
        G.__rvl4_strafeHum = nil
        G.__rvl4_strafeRoot = nil
        local lv = G.__rvl4_strafeLv
        G.__rvl4_strafeLv = nil
        if lv then
            local att = nil
            pcall(function() att = lv.Attachment0 end)
            pcall(function() lv:Destroy() end)
            if att then pcall(function() att:Destroy() end) end
        end
    end
    G.__rvl4_strafeShape = function(rootS, humS, latS, dtS)
        if not rootS or not rootS.Parent or not humS or not latS then return end
        local vel = rootS.AssemblyLinearVelocity
        local lx, lz = latS.X, latS.Z
        local ll = math.sqrt(lx * lx + lz * lz)
        if ll < .05 then return end
        lx, lz = lx / ll, lz / ll
        local cur = vel.X * lx + vel.Z * lz
        local inAir = humS.FloorMaterial == Enum.Material.Air
        local target = (humS.WalkSpeed or 16) * math.min(cfg.strafe.str, 3)
        local rate = (inAir and 200 or 400) * cfg.strafe.str
        local step = rate * math.clamp(dtS or .016, .001, .08)
        local diff = target - cur
        if diff > step then diff = step elseif diff < -step then diff = -step end
        local nvx, nvz = vel.X + lx * diff, vel.Z + lz * diff
        rootS.AssemblyLinearVelocity = Vector3.new(nvx, vel.Y, nvz)
    end
    G.__rvl4_strafeBound = nil
    if run.BindToRenderStep then
        local okSB = pcall(function()
            run:BindToRenderStep("rvl4_strafe", Enum.RenderPriority.Last.Value, function(dtB)
                if not alive() then return end
                local lS = G.__rvl4_strafeLat
                local hS = G.__rvl4_strafeHum
                local rS = G.__rvl4_strafeRoot
                if lS and hS and hS.Parent and rS and os.clock() - (G.__rvl4_strafeAt or 0) < .1 then
                    pcall(G.__rvl4_strafeShape, rS, hS, lS, dtB)
                end
            end)
        end)
        if okSB then G.__rvl4_strafeBound = true end
    end
end
stage("loop")
