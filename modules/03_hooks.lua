local hookErr = ""
local directOnly = true
G.__rvl4_state = G.__rvl4_state or {}

local function tryInstall(mt, field, handler, forceDirect)
    if not forceDirect and not G.__rvl4_hmDead and hookmetamethod then
        local okH = pcall(function() hookmetamethod(game, field, handler) end)
        if okH then G.__rvl4_usedHm = true return true end
    end
    if setreadonly then
        local assigned = false
        local okI = pcall(function()
            setreadonly(mt, false)
            mt[field] = handler
            assigned = true
            pcall(function() setreadonly(mt, true) end)
        end)
        if not okI and not assigned then pcall(function() setreadonly(mt, true) end) end
        if assigned or okI then
            local okV, isOurs = pcall(function() return mt[field] == handler end)
            if okV and isOurs then G.__rvl4_usedDirect = true return true end
        end
    end
    local okB = pcall(function() mt[field] = handler end)
    if okB then
        local okV2, isOurs2 = pcall(function() return mt[field] == handler end)
        if okV2 and isOurs2 then G.__rvl4_usedDirect = true return true end
    end
    return false
end

local function silentState()
    local c4 = G.__rvl4_cfg
    local st = G.__rvl4_state
    if c4 and c4.sil.on and st and st.part and st.pos and st.rollOk ~= false then
        return c4, st
    end
    return nil, nil
end

if checkcaller then
    G.__rvl4_checkc = function()
        local okC, r = pcall(checkcaller)
        if not okC then return true end
        return r
    end
else
    G.__rvl4_checkc = function() return selfRay end
end
G.__rvl4_wrap = (G.__rvl4_hmDead and function(f) return f end) or newcclosure or function(f) return f end
local function installIdxHook()
    if G.__rvl4_silent then return end
    G.__rvl4_silent = true
    G.__rvl4_state = G.__rvl4_state or {}
    local installed = false
    local okI2, errI2 = pcall(function()
        if not getrawmetatable then error("getrawmetatable missing") end
        local checkc = G.__rvl4_checkc
        local wrap = G.__rvl4_wrap
        local mt = getrawmetatable(game)
        local old = mt.__index
        if type(old) ~= "function" and type(old) ~= "table" then error("game __index is not callable") end
        local function callOld(s, k)
            if type(old) == "function" then return old(s, k) end
            return old[k]
        end
        local genAtInstall = G.__rvl4_gen
        local handler = wrap(function(s, k)
            if G.__rvl4_gen ~= genAtInstall then return callOld(s, k) end
            if not mouse and os.clock() - (G.__rvl4_mouseAt or 0) > 1 then
                G.__rvl4_mouseAt = os.clock()
                pcall(function() mouse = lp:GetMouse() end)
            end
            if s == mouse and not checkc() and (k == "Hit" or k == "Target" or k == "UnitRay") then
                local ok, res = pcall(function()
                    local _, st = silentState()
                    if not st then return false end
                    if k == "Hit" then
                        local ccam = ws.CurrentCamera
                        if ccam then return CFrame.new(st.pos, st.pos + ccam.CFrame.LookVector) end
                        return CFrame.new(st.pos)
                    end
                    if k == "Target" then return st.part end
                    local co = ws.CurrentCamera.CFrame.Position
                    local dv = st.pos - co
                    if dv.Magnitude <= .001 then return false end
                    return Ray.new(co, dv.Unit)
                end)
                if ok and res ~= false then return res end
            end
            return callOld(s, k)
        end)
        installed = tryInstall(mt, "__index", handler, directOnly)
        if installed then G.__rvl4_oldidx = old end
    end)
    if installed then
        G.__rvl4_idxok = true
    else
        G.__rvl4_silent = nil
        if hookErr == "" then hookErr = errI2 and tostring(errI2) or "idx hook unavailable" end
    end
end

local function targetDeflecting(p)
    if not p then return false end
    local cc = getChar(p)
    if not cc then return false end
    local tool = cc.c:FindFirstChildOfClass("Tool")
    if not tool then return false end
    local n = " " .. string.lower(tool.Name) .. " "
    for _, w in ipairs(splitCsv(cfg.combat.meleeExtra)) do
        if string.find(n, w, 1, true) then return true end
    end
    if string.find(n, " katana ", 1, true) or string.find(n, " shield ", 1, true) then
        return tool:GetAttribute("CanDeflect") ~= false
    end
    return false
end

local function nearOrigin(o, cp)
    if (o - cp).Magnitude < 6 then return true end
    local lc = getChar(lp)
    if lc and lc.root then
        return (o - lc.root.Position).Magnitude < 12
    end
    return false
end

local function installNcHook()
    if G.__rvl4_namecall then return end
    G.__rvl4_namecall = true
    local installed = false
    local okN2, errN2 = pcall(function()
        if not getrawmetatable then error("getrawmetatable missing") end
        local checkc = G.__rvl4_checkc
        local wrap = G.__rvl4_wrap
        local mt = getrawmetatable(game)
        local oldnc = mt.__namecall
        if type(oldnc) ~= "function" then
            oldnc = function(s, ...)
                local m = nil
                if getnamecallmethod then pcall(function() m = getnamecallmethod() end) end
                local f = m and s[m]
                if type(f) == "function" then return f(s, ...) end
                return nil
            end
        end

        local function relaxedNow()
            local stR = G.__rvl4_state
            if not (stR and stR.part) then return false end
            local bendAge = os.clock() - (G.__rvl4_lastBendAt or G.__rvl4_ncAt or 0)
            if bendAge > 5 then return true end
            if os.clock() - (G.__rvl4_rejAt or -10) > 6 then return false end
            return bendAge > 3
        end

        local function csvCached(raw, key)
            local cc3 = G[key]
            if cc3 and cc3.raw == raw then return cc3.list end
            local l = splitCsv(raw)
            G[key] = { raw = raw, list = l }
            return l
        end


        local function readCsName()
            local cs = getcallingscript()
            if cs then return tostring(cs) end
        end
        local function readGameCall()
            return not checkc()
        end
        local function readInstName(x)
            return x.Name
        end
        local function bendRayCall(s, method, args)
            local _, st = silentState()
            if not st then return false end
            local cc2 = ws.CurrentCamera
            local cp = cc2 and cc2.CFrame.Position
            if not cp then return false end
            G.__rvl4_bendTry = (G.__rvl4_bendTry or 0) + 1
            G.__rvl4_lastTry = os.clock()
            local csName = nil
            if getcallingscript then
                local okCs, nmCs = pcall(readCsName)
                if okCs then csName = nmCs end
            end
            local gunCaller = csName == "Equipment" or csName == "FighterController" or csName == "PlayerDataController" or csName == "ControlsController"
            if not gunCaller and csName then
                local csLower = string.lower(csName)
                local c4caller = G.__rvl4_cfg
                if c4caller then
                    for _, extraName in ipairs(csvCached(c4caller.sil.callers, "__rvl4_csvCallers")) do
                        if csLower == extraName then
                            gunCaller = true
                            break
                        end
                    end
                end
            end
            local okGc, gcV = pcall(readGameCall)
            local gameCall = okGc and gcV or false
            local relaxed = relaxedNow()
            local fireTrust = false
            if G.__rvl4_firing then
                local oPos = nil
                if typeof(args[1]) == "Vector3" then oPos = args[1] elseif typeof(args[1]) == "Ray" then oPos = args[1].Origin end
                if oPos then
                    local ccL = getChar(lp)
                    local myRoot = ccL and ccL.root
                    if myRoot and (oPos - myRoot.Position).Magnitude <= 14 then fireTrust = true end
                end
            end
            if csName ~= nil and not gunCaller and not gameCall and not fireTrust and not relaxed then
                G.__rvl4_rejCaller = csName
                G.__rvl4_rejAt = os.clock()
                return false
            end
            local bent = false
            pcall(function()
                if method == "Raycast" then
                    if typeof(args[1]) == "Vector3" and typeof(args[2]) == "Vector3" and (gameCall or gunCaller or fireTrust or relaxed) and (gunCaller or fireTrust or relaxed or nearOrigin(args[1], cp)) and (args[2].Magnitude > 50 or gunCaller or fireTrust or relaxed) then
                        local dv = st.pos - args[1]
                        if dv.Magnitude > .001 then
                            args[2] = dv.Unit * math.max(args[2].Magnitude, 1000)
                            bent = true
                        end
                    end
                elseif typeof(args[1]) == "Ray" and (gameCall or gunCaller or fireTrust or relaxed) and (gunCaller or fireTrust or relaxed or nearOrigin(args[1].Origin, cp)) and (args[1].Direction.Magnitude > 50 or gunCaller or fireTrust or relaxed) then
                    local r0 = args[1]
                    local dv = st.pos - r0.Origin
                    if dv.Magnitude > .001 then
                        args[1] = Ray.new(r0.Origin, dv.Unit * math.max(r0.Direction.Magnitude, 1000))
                        bent = true
                    end
                end
            end)
            if bent then
                G.__rvl4_lastBendAt = os.clock()
                local okC, res = pcall(function() return table.pack(oldnc(s, table.unpack(args, 1, args.n))) end)
                if okC then return true, res end
                return true, { n = 0 }
            end
            return false
        end

        G.__rvl4_useItemInst = function()
            local ui = G.__rvl4_useItem
            if ui and ui.Parent then return ui end
            local now = os.clock()
            if ui then
                G.__rvl4_useItem = nil
            elseif now - (G.__rvl4_uiTryAt or 0) < 1 then
                return nil
            end
            G.__rvl4_uiTryAt = now
            local found = nil
            pcall(function()
                local rs = game:GetService("ReplicatedStorage")
                local rem = rs and rs:FindFirstChild("Remotes")
                local rep = rem and rem:FindFirstChild("Replication")
                local fig = rep and rep:FindFirstChild("Fighter")
                found = fig and fig:FindFirstChild("UseItem")
            end)
            if found then G.__rvl4_useItem = found end
            return found
        end

        local function encCf(cf)
            local p = cf.Position
            local rx, ry, rz = cf:ToOrientation()
            return { ["\0"] = p.X, ["\1"] = p.Y, ["\2"] = p.Z, ["\3"] = rx, ["\4"] = ry, ["\5"] = rz }
        end

        local function bendPayload(args)
            local st = G.__rvl4_state
            if not st or not st.part or not st.pos or st.rollOk == false then return false end
            local part = st.part
            if typeof(part) ~= "Instance" then return false end
            local data = args[3]
            if type(data) ~= "table" then return false end
            local shot = data["\1"]
            if type(shot) ~= "table" then return false end
            local e0, e1 = shot["\0"], shot["\1"]
            if type(e0) ~= "table" or type(e1) ~= "table" then return false end
            if type(e0["\0"]) ~= "number" or type(e0["\1"]) ~= "number" or type(e0["\2"]) ~= "number" then return false end
            if type(e1["\0"]) ~= "number" or type(e1["\1"]) ~= "number" or type(e1["\2"]) ~= "number" then return false end
            local hp = shot["\2"]
            if hp ~= nil and typeof(hp) ~= "Instance" then return false end
            local oPos = Vector3.new(e0["\0"], e0["\1"], e0["\2"])
            local aPos = Vector3.new(e1["\0"], e1["\1"], e1["\2"])
            local tp = st.pos
            if (tp - aPos).Magnitude <= .001 then return false end
            local n0 = encCf(CFrame.new(oPos, tp))
            local n1 = encCf(CFrame.new(aPos, tp))
            local obj = nil
            G.__rvl4_plBusy = true
            local okR, res = pcall(function()
                local prm = G.__rvl4_plParams
                if not prm then
                    prm = RaycastParams.new()
                    G.__rvl4_plParams = prm
                end
                prm.FilterType = Enum.RaycastFilterType.Include
                prm.FilterDescendantsInstances = { part }
                return ws:Raycast(oPos, (tp - oPos) * 1.5, prm)
            end)
            G.__rvl4_plBusy = nil
            if okR and res and res.Position then
                local okO, ov = pcall(function() return part.CFrame:PointToObjectSpace(res.Position) end)
                if okO then obj = ov end
            end
            if not obj then
                local okC, cp = pcall(function() return part:GetClosestPointOnSurface(oPos) end)
                if okC and cp then
                    local okO2, ov2 = pcall(function() return part.CFrame:PointToObjectSpace(cp) end)
                    if okO2 then obj = ov2 end
                end
            end
            if not obj then
                local okO3, ov3 = pcall(function() return part.CFrame:PointToObjectSpace(tp) end)
                if okO3 then obj = ov3 end
            end
            shot["\0"] = n0
            shot["\1"] = n1
            shot["\2"] = part
            if obj then shot["\3"] = encCf(CFrame.new(obj)) end
            return true
        end

        local function bendRemoteCall(s, args)
            local c4 = G.__rvl4_cfg
            local st = G.__rvl4_state
            if not (c4 and c4.sil.on and c4.sil.remotes and st and st.part and st.pos and st.rollOk ~= false) then
                return false
            end
            if s == G.__rvl4_useItemInst() then
                local okP, bentP = pcall(bendPayload, args)
                if okP and bentP then
                    G.__rvl4_bendTry = (G.__rvl4_bendTry or 0) + 1
                    G.__rvl4_lastTry = os.clock()
                    G.__rvl4_lastBendAt = os.clock()
                    local okC, res = pcall(function() return table.pack(oldnc(s, table.unpack(args, 1, args.n))) end)
                    if okC then return true, res end
                    return true, { n = 0 }
                end
            end
            local okNm, nm = pcall(readInstName, s)
            if not okNm or not nm then return false end
            local ln = string.lower(nm)
            local exactNm = ln == "useitem" or ln == "useitemfeedback" or ln == "snowballthrow"
            if not exactNm then
                for _, xn in ipairs(csvCached(c4.sil.extra, "__rvl4_csvExtra")) do
                    if ln == xn then
                        exactNm = true
                        break
                    end
                end
            end
            local viaRelax = false
            if not exactNm then
                local tok = string.find(ln, "fire", 1, true) ~= nil or string.find(ln, "shoot", 1, true) ~= nil
                if not tok and not relaxedNow() and not G.__rvl4_firing then
                    G.__rvl4_rejAt = os.clock()
                    return false
                end
                if not tok then viaRelax = true end
                local shaped = false
                for i = 1, args.n do
                    local ta = typeof(args[i])
                    if ta == "Ray" or ta == "CFrame" or ta == "Vector3" then
                        shaped = true
                        break
                    end
                end
                if not shaped then return false end
            end
            G.__rvl4_bendTry = (G.__rvl4_bendTry or 0) + 1
            G.__rvl4_lastTry = os.clock()
            local cc2 = ws.CurrentCamera
            local eye = cc2 and cc2.CFrame.Position
            if not eye then return false end
            local bent = false
            pcall(function()
                local dv = st.pos - eye
                if dv.Magnitude > .001 then
                    local du = dv.Unit
                    for i = 1, args.n do
                        local a = args[i]
                        local ta = typeof(a)
                        if ta == "CFrame" then
                            if (a.Position - eye).Magnitude < 12 then
                                args[i] = CFrame.new(a.Position, a.Position + du)
                                bent = true
                            else
                                args[i] = CFrame.new(st.pos, st.pos + a.LookVector)
                                bent = true
                            end
                        elseif ta == "Vector3" then
                            if math.abs(a.Magnitude - 1) < .05 then
                                args[i] = du
                                bent = true
                            elseif (a - eye).Magnitude >= 12 then
                                args[i] = st.pos
                                bent = true
                            end
                        elseif ta == "Ray" then
                            args[i] = Ray.new(a.Origin, du * a.Direction.Magnitude)
                            bent = true
                        end
                        if viaRelax and bent then break end
                    end
                end
            end)
            if bent then
                G.__rvl4_lastBendAt = os.clock()
                local okC, res = pcall(function() return table.pack(oldnc(s, table.unpack(args, 1, args.n))) end)
                if okC then return true, res end
                return true, { n = 0 }
            end
            return false
        end

        local genAtInstall = G.__rvl4_gen
        local handler = wrap(function(s, ...)
            if G.__rvl4_gen ~= genAtInstall then return oldnc(s, ...) end
            if s == G.__rvl4_probeSelf then
                G.__rvl4_probeHit = true
                return
            end
            if G.__rvl4_plBusy then return oldnc(s, ...) end
            if (G.__rvl4_ncCalls or 0) < 1000 then G.__rvl4_ncCalls = (G.__rvl4_ncCalls or 0) + 1 end
            if not G.__rvl4_ncRan then
                G.__rvl4_ncRan = true
                pcall(function() if writefile then writefile("rvl_hookdbg.txt", "nc-ran") end end)
            end
            local c4 = G.__rvl4_cfg
            if not c4 or not c4.sil.on then
                return oldnc(s, ...)
            end
            local method = ""
            if getnamecallmethod then
                local okM, mM = pcall(getnamecallmethod)
                if not okM then return oldnc(s, ...) end
                method = mM or ""
            end
            if s == ws and (method == "Raycast" or method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist") then
                if not selfRay then
                    local _p0, st0 = silentState()
                    if st0 then
                        local okB, handled, res = pcall(bendRayCall, s, method, table.pack(...))
                        if okB and handled then return table.unpack(res, 1, res.n) end
                    end
                end
                return oldnc(s, ...)
            end
            local isCam = (method == "ViewportPointToRay" or method == "ScreenPointToRay") and s == ws.CurrentCamera
            if (method == "FireServer" or method == "InvokeServer" or isCam) and checkc() and not relaxedNow() and not G.__rvl4_firing then
                return oldnc(s, ...)
            end
            if method == "FireServer" or method == "InvokeServer" then
                if c4.sil.remotes then
                    local okR, handled, res = pcall(bendRemoteCall, s, table.pack(...))
                    if okR and handled then return table.unpack(res, 1, res.n) end
                end
            elseif isCam then
                local _p1, st = silentState()
                if st then
                    local a1, a2 = ...
                    local okCam, camRay = pcall(function()
                        local vs = s.ViewportSize
                        local nearCenter = type(a1) == "number" and type(a2) == "number"
                            and math.abs(a1 - vs.X / 2) < vs.X * .1 and math.abs(a2 - vs.Y / 2) < vs.Y * .1
                        if not nearCenter then return nil end
                        local cp = s.CFrame.Position
                        local dv = st.pos - cp
                        if dv.Magnitude <= .001 then return nil end
                        return Ray.new(cp, dv.Unit * 1000)
                    end)
                    if okCam and camRay then
                        G.__rvl4_lastBendAt = os.clock()
                        return camRay
                    end
                end
            end
            return oldnc(s, ...)
        end)
        installed = tryInstall(mt, "__namecall", handler, directOnly)
        if installed then G.__rvl4_oldnc = oldnc end
    end)
    if installed then
        G.__rvl4_ncok = true
    else
        G.__rvl4_namecall = nil
        if hookErr == "" then hookErr = errN2 and tostring(errN2) or "namecall hook unavailable" end
    end
end

local hookModeAtBoot = "リモートのみ"
if cfg.misc.nohook then
    hookModeAtBoot = "なし"
elseif cfg.misc.hookmode then
    hookModeAtBoot = cfg.misc.hookmode
end
local function installAll()
    if not alive() then return end
    local t0 = os.clock()
    while alive() and not lp.Character and os.clock() - t0 < 3 do
        task.wait(.25)
    end
    if not alive() then return end
    local mode = hookModeAtBoot
    if mode ~= "なし" then
        local dbgNow = nil
        pcall(function() if readfile then dbgNow = readfile("rvl_hookdbg.txt") end end)
        if not G.__rvl4_namecall and dbgNow ~= "nc-ran" then pcall(function() if writefile then writefile("rvl_hookdbg.txt", "nc-install") end end) end
        local a2, e2 = pcall(installNcHook)
        if not a2 and hookErr == "" then hookErr = tostring(e2) end
        if G.__rvl4_ncok and dbgNow ~= "nc-ran" then pcall(function() if writefile then writefile("rvl_hookdbg.txt", "nc-installed") end end) end
    end
    if mode == "両方" then
        local a1, e1 = pcall(installIdxHook)
        if not a1 and hookErr == "" then hookErr = tostring(e1) end
    end
    if G.__rvl4_ncok and (mode ~= "両方" or G.__rvl4_idxok) then hookErr = "" end
end
G.__rvl4_bendStuck = function()
    if not G.__rvl4_ncok then return false end
    if (G.__rvl4_bendTry or 0) < 2 then return false end
    local now = os.clock()
    if now - (G.__rvl4_lastTry or 0) > .5 then return false end
    if now - (G.__rvl4_lastBendAt or 0) <= 1 then return false end
    if directOnly and now - (G.__rvl4_reinstallAt or 0) > 10 then
        G.__rvl4_reinstallAt = now
        pcall(function()
            local mt3 = getrawmetatable and getrawmetatable(game)
            if mt3 and G.__rvl4_oldnc then
                G.__rvl4_mtSet(mt3, "__namecall", G.__rvl4_oldnc)
            end
            if mt3 and G.__rvl4_oldidx and hookModeAtBoot == "両方" then
                G.__rvl4_mtSet(mt3, "__index", G.__rvl4_oldidx)
            end
        end)
        G.__rvl4_namecall = nil
        G.__rvl4_ncok = nil
        if hookModeAtBoot == "両方" then G.__rvl4_silent = nil G.__rvl4_idxok = nil end
        pcall(installAll)
    end
    return true
end
local function installStaged()
    if not alive() or G.__rvl4_installing then return end
    G.__rvl4_installing = true
    G.__rvl4_hookGen = G.__rvl4_gen
    stage("hooks")
    pcall(function()
        if writefile then writefile("rvl_boot.txt", safeLevel == 1 and "hooksL" or "hooks") end
    end)
    G.__rvl4_ncCalls = 0
    local callsAtInstall = 0
    local proofTries = 0
    local function proofCheck()
        if not alive() then return end
        if (G.__rvl4_ncok or G.__rvl4_idxok) and (G.__rvl4_ncCalls or 0) > callsAtInstall then
            pcall(function() if writefile then writefile("rvl_boot.txt", G.__rvl4_usedDirect and "hookokL" or "hookok") end end)
            return
        end
        proofTries = proofTries + 1
        if proofTries <= 200 then task.delay(90, proofCheck) end
    end
    if G.__rvl4_proofGen ~= G.__rvl4_gen then
        G.__rvl4_proofGen = G.__rvl4_gen
        task.delay(90, proofCheck)
    end
    pcall(installAll)
    G.__rvl4_installing = false
    if G.__rvl4_ncok or G.__rvl4_idxok then
        G.__rvl4_instFails = 0
    else
        G.__rvl4_instFails = (G.__rvl4_instFails or 0) + 1
    end
    if G.__rvl4_ncok then
        G.__rvl4_ncAt = os.clock()
        G.__rvl4_lastBendAt = nil
    end
    stage("hooksdone")
    local probeTries = 0
    local function probePass()
        if not alive() then return end
        if not cfg.sil.on then
            task.delay(4, probePass)
            return
        end
        if not G.__rvl4_ncok then
            if not G.__rvl4_hmTried and not G.__rvl4_hmDead and safeLevel == 0 and hookmetamethod then
                G.__rvl4_hmTried = true
                directOnly = false
                pcall(installAll)
            else
                probeTries = probeTries + 1
                if probeTries <= 40 then task.delay(4, probePass) end
            end
            return
        end
        if (G.__rvl4_ncCalls or 0) > callsAtInstall then return end
        local probe = Instance.new("RemoteEvent")
        G.__rvl4_probeSelf = probe
        G.__rvl4_probeHit = nil
        pcall(function() probe:FireServer() end)
        task.delay(.5, function()
            G.__rvl4_probeSelf = nil
            if not alive() or G.__rvl4_probeHit or (G.__rvl4_ncCalls or 0) > callsAtInstall then return end
            local function probe2()
                if not G.__rvl4_ncok then return end
                G.__rvl4_ncAt = os.clock()
                G.__rvl4_lastBendAt = nil
                local p2 = Instance.new("RemoteEvent")
                G.__rvl4_probeSelf = p2
                G.__rvl4_probeHit = nil
                local base2 = G.__rvl4_ncCalls or 0
                pcall(function() p2:FireServer() end)
                task.delay(.5, function()
                    G.__rvl4_probeSelf = nil
                    if alive() and not G.__rvl4_probeHit and (G.__rvl4_ncCalls or 0) <= base2 then
                        directOnly = true
                        G.__rvl4_dispatchDead = true
                    end
                end)
            end
            if G.__rvl4_usedDirect and not G.__rvl4_hmTried and not G.__rvl4_hmDead and safeLevel == 0 then
                G.__rvl4_hmTried = true
                directOnly = false
                pcall(function()
                    local mt2 = getrawmetatable and getrawmetatable(game)
                    if mt2 and G.__rvl4_oldnc then mt2.__namecall = G.__rvl4_oldnc end
                end)
                G.__rvl4_namecall = nil
                G.__rvl4_ncok = nil
                G.__rvl4_usedDirect = nil
                pcall(installAll)
                probe2()
            elseif G.__rvl4_usedHm and not G.__rvl4_usedDirect and not G.__rvl4_dirTried then
                G.__rvl4_dirTried = true
                directOnly = true
                pcall(function()
                    if hookmetamethod and G.__rvl4_oldnc then hookmetamethod(game, "__namecall", G.__rvl4_oldnc) end
                end)
                G.__rvl4_namecall = nil
                G.__rvl4_ncok = nil
                G.__rvl4_usedHm = nil
                pcall(installAll)
                probe2()
            else
                G.__rvl4_dispatchDead = true
            end
        end)
    end
    if G.__rvl4_probeGen ~= G.__rvl4_gen then
        G.__rvl4_probeGen = G.__rvl4_gen
        task.delay(4, probePass)
    end
    local function hooksMissing()
        if hookModeAtBoot == "なし" or safeLevel == 2 then return false end
        if not G.__rvl4_ncok then return true end
        if hookModeAtBoot == "両方" and not G.__rvl4_idxok then return true end
        return false
    end
    if hooksMissing() then
        local tries = 0
        local function retry()
            tries = tries + 1
            if not alive() then return end
            if not hooksMissing() then return end
            pcall(installAll)
            if hooksMissing() and tries < 2 then
                task.delay(5, retry)
            end
        end
        task.delay(2, retry)
    end
end
if hookModeAtBoot == "なし" or safeLevel == 2 then
    print("[rvl] hooks disabled")
end
G.__rvl4_armHooks = function()
    if not alive() then return end
    if hookModeAtBoot == "なし" or safeLevel == 2 then return end
    if G.__rvl4_installing then return end
    if G.__rvl4_ncok and (hookModeAtBoot ~= "両方" or G.__rvl4_idxok) then return end
    local nowA = os.clock()
    if (G.__rvl4_instFails or 0) >= 4 and nowA - (G.__rvl4_lastArmAt or 0) < 30 then return end
    if nowA - (G.__rvl4_lastArmAt or 0) < 2 then return end
    G.__rvl4_lastArmAt = nowA
    if lp.Character then
        installStaged()
    else
        task.spawn(installStaged)
    end
end
task.spawn(function()
    while alive() do
        if cfg.sil.on and (not G.__rvl4_ncok or (hookModeAtBoot == "両方" and not G.__rvl4_idxok)) then pcall(G.__rvl4_armHooks) end
        task.wait(1)
    end
end)
