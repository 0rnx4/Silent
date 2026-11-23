local G = (getgenv and getgenv()) or _G
G.__rvl4_gen = (G.__rvl4_gen or 0) + 1
G.__rvl4_guiopen = nil
local myGen = G.__rvl4_gen
local function alive()
    return G.__rvl4_gen == myGen
end

local prevStage = nil
pcall(function()
    if isfile and isfile("rvl_stage.txt") then
        prevStage = readfile("rvl_stage.txt")
    end
end)
if prevStage and prevStage ~= "ok" then
    print("[rvl] previous boot stopped at stage: " .. tostring(prevStage))
end
print("[rvl] v118 starting")
local beaconText = "rvl v118 起動中"
local beaconTx = nil
local beaconLock = false
local function beaconSay(t, final)
    if beaconLock and not final then return end
    if final then beaconLock = true end
    beaconText = t
    if beaconTx then pcall(function() beaconTx.Text = t end) end
end
G.__rvl4_beaconSay = beaconSay
local function makeBeacon(pgB)
    if beaconTx or not pgB then return end
    pcall(function()
        local old = pgB:FindFirstChild("rvl_beacon")
        if old then old:Destroy() end
        local g = Instance.new("ScreenGui")
        g.Name = "rvl_beacon"
        g.ResetOnSpawn = false
        g.DisplayOrder = 999
        g.Parent = pgB
        local b = Instance.new("TextButton")
        b.Name = "tx"
        b.AnchorPoint = Vector2.new(1, 0)
        b.Size = UDim2.new(0, 208, 0, 40)
        b.Position = UDim2.new(1, -10, 0, 10)
        b.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
        b.TextColor3 = Color3.fromRGB(238, 238, 240)
        b.Font = Enum.Font.BuilderSansBold
        b.TextSize = 12
        b.TextWrapped = true
        b.AutoButtonColor = false
        b.Text = beaconText
        b.Parent = g
        beaconTx = b
        b.Activated:Connect(function()
            if G.__rvl4_beaconAct then pcall(G.__rvl4_beaconAct) end
        end)
    end)
end
pcall(function()
    local lpB = game:GetService("Players").LocalPlayer
    local pgB = lpB and lpB:FindFirstChild("PlayerGui")
    if pgB then makeBeacon(pgB) end
end)
if not beaconTx then
    task.spawn(function()
        local plrsB = game:GetService("Players")
        local t0 = os.clock()
        while not plrsB.LocalPlayer and os.clock() - t0 < 30 do task.wait(.2) end
        if not alive() or beaconTx then return end
        local lpB = plrsB.LocalPlayer
        if not lpB then return end
        local pgB = lpB:WaitForChild("PlayerGui", 10)
        if pgB and alive() then makeBeacon(pgB) end
    end)
end
local function stage(nm)
    G.__rvl4_lastStage = nm
    G.__rvl4_stageAt = os.clock()
    pcall(function()
        if writefile then writefile("rvl_stage.txt", nm) end
    end)
    if nm ~= "ok" then beaconSay("rvl v118: " .. nm) end
end
stage("boot")
task.spawn(function()
    while alive() and not G.__rvl4_chunkDone do
        task.wait(3)
        if os.clock() - (G.__rvl4_stageAt or 0) > 9 then
            beaconSay("rvl v118 停止: " .. tostring(G.__rvl4_lastStage), true)
            break
        end
    end
end)

local safeMode = false
local safeLevel = 0
local plrs = game:GetService("Players")
local run = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local ws = game:GetService("Workspace")
local lt = game:GetService("Lighting")
local hs = game:GetService("HttpService")
local tps = game:GetService("TeleportService")

local function loadedOk()
    local okL, r = pcall(function() return game:IsLoaded() end)
    return (not okL) or r
end
if game.IsLoaded and not loadedOk() then
    local t0 = os.clock()
    repeat task.wait(.1) G.__rvl4_stageAt = os.clock() until loadedOk() or os.clock() - t0 > 15
end
local lp = plrs.LocalPlayer
if not lp then
    local t0 = os.clock()
    repeat
        task.wait(.1)
        lp = plrs.LocalPlayer
        G.__rvl4_stageAt = os.clock()
    until lp or os.clock() - t0 > 10
    if not lp then
        beaconSay("rvl v118 起動失敗: プレイヤーなし", true)
        G.__rvl4_chunkDone = true
        return
    end
end
local cam = ws.CurrentCamera
if not cam then
    local t0 = os.clock()
    repeat
        task.wait(.1)
        cam = ws.CurrentCamera
        G.__rvl4_stageAt = os.clock()
    until cam or os.clock() - t0 > 10
    if not cam then
        beaconSay("rvl v118 起動失敗: カメラなし", true)
        G.__rvl4_chunkDone = true
        return
    end
end
pcall(function()
    if not (readfile and writefile) then return end
    local prev = nil
    if isfile and isfile("rvl_boot.txt") then
        pcall(function() prev = readfile("rvl_boot.txt") end)
    end
    local n = 0
    if prev and string.sub(prev, 1, 3) == "run" then
        n = tonumber(string.sub(prev, 4)) or 1
    end
    if prevStage == "ok" then n = 0 end
    if prev == "hooks" then n = math.max(n, 2) end
    if prev == "hooksL" then n = math.max(n, 6) end
    local dbg = nil
    if isfile and isfile("rvl_hookdbg.txt") then
        pcall(function() dbg = readfile("rvl_hookdbg.txt") end)
    end
    G.__rvl4_hookDbg = dbg
    G.__rvl4_hmDead = (dbg == "nc-install")
    n = math.min(n, 6)
    if n >= 6 then
        safeMode = true
        safeLevel = 2
    elseif n >= 2 then
        safeMode = true
        safeLevel = 1
    end
    if prev == "hookokL" and safeLevel == 0 then
        safeMode = true
        safeLevel = 1
    end
    safeMode = true
    safeLevel = 1
    pcall(function() if delfile and isfile and isfile("rvl_skins.json") then delfile("rvl_skins.json") end end)
    writefile("rvl_boot.txt", "run" .. (n + 1))
end)
safeMode = true
safeLevel = 1
pcall(function()
    if G.__rvl4_hookDbg == nil and isfile and readfile and isfile("rvl_hookdbg.txt") then
        local d2 = readfile("rvl_hookdbg.txt")
        G.__rvl4_hookDbg = d2
        G.__rvl4_hmDead = (d2 == "nc-install")
    end
end)
G.__rvl4_mtSet = function(mt, field, val)
    pcall(function() if setreadonly then setreadonly(mt, false) end end)
    pcall(function() mt[field] = val end)
    pcall(function() if setreadonly then setreadonly(mt, true) end end)
end
G.__rvl4_rebuilds = 0
if G.__rvl4_hookGen ~= G.__rvl4_gen then
    if G.__rvl4_oldnc or G.__rvl4_oldidx then
        pcall(function()
            local mt = getrawmetatable and getrawmetatable(game)
            if mt then
                if G.__rvl4_oldnc then G.__rvl4_mtSet(mt, "__namecall", G.__rvl4_oldnc) end
                if G.__rvl4_oldidx then G.__rvl4_mtSet(mt, "__index", G.__rvl4_oldidx) end
            end
        end)
    end
    G.__rvl4_namecall, G.__rvl4_ncok, G.__rvl4_silent, G.__rvl4_idxok = nil, nil, nil, nil
    G.__rvl4_oldnc, G.__rvl4_oldidx = nil, nil
    G.__rvl4_ncAt, G.__rvl4_lastBendAt, G.__rvl4_ncRan, G.__rvl4_usedDirect = nil, nil, nil, nil
    G.__rvl4_dispatchDead, G.__rvl4_hmTried, G.__rvl4_usedHm, G.__rvl4_dirTried = nil, nil, nil, nil
    G.__rvl4_probeSelf, G.__rvl4_probeHit = nil, nil
    G.__rvl4_ncCalls = 0
end
if safeLevel == 1 then
    print("[rvl] safe mode (light): hooks via the direct path, delayed")
elseif safeLevel == 2 then
    print("[rvl] safe mode: hooks disabled (repeated unstable runs)")
end
local baseFov = cam.FieldOfView or 70
local mouse = nil
pcall(function() mouse = lp:GetMouse() end)
local touch = uis.TouchEnabled and not uis.KeyboardEnabled
if uis.TouchEnabled and uis.KeyboardEnabled then
    task.wait(.3)
    touch = uis.TouchEnabled and not uis.MouseEnabled
end
if cam.ViewportSize.X <= 0 then
    local t0 = os.clock()
    repeat task.wait() G.__rvl4_stageAt = os.clock() until cam.ViewportSize.X > 0 or os.clock() - t0 > 10
end

local function defaults()
    return {
        aim = { on = false, fov = 160, sm = .6, team = true, wall = false, part = "Head", pred = .22, sticky = true, always = false, ragebot = false, prio = "クロスヘア", cyclekey = "T", flick = false, fire = false, adaptive = false, smNear = 1.35, smFar = .8 },
        sil = { on = false, chance = 100, headchance = 0, fov = 250, remotes = true, extra = "", callers = "" },
        trg = { on = false, fov = 20, delay = 25, ads = false, mode = "連射", head = false, scope = false },
        esp = { on = true, team = true, chams = true, box = true, name = true, wp = true, hp = true, dist = true, trc = false, tline = false, skel = false, max = 1500, radar = false, rd = 120, dmg = false, arrow = false, tgt = true, colormode = "赤", tsize = 12, maxCount = 100 },
        fly = { on = false, spd = 48 },
        strafe = { on = false, mode = "発射中", int = 120, str = 1 },
        void = { on = false },
        spd = { on = false, val = 26 },
        jmp = { on = false, val = 70 },
        noc = false,
        infj = false, bhop = false, fpsb = false, afk = false,
        xhair = { on = false, size = 6, gap = 8, thick = 2 },
        hb = { on = false, size = 6, part = "両方" },
        vis = { fb = false, nf = false },
        camf = { on = false, val = 100 },
        combat = { norecoil = false, nospread = false, auto = false, rapid = false, reload = false, equip = false, ammo = false, fullauto = false, hsnd = false, hsndVol = .5, hsndId = "", ksnd = false, tracer = false, autoreload = false, ads = false, dmgmod = false, meleeExtra = "" },
        misc = { prof = 1, rainbow = false, third = false, qot = false, nohook = false, teammode = "自動", hookmode = "リモートのみ", uiscale = "標準", emoteId = "", mig110 = false },
    }
end
local cfg = defaults()
local function deepCopy(t)
    local o = {}
    for k, v in pairs(t) do
        o[k] = type(v) == "table" and deepCopy(v) or v
    end
    return o
end
local defCfg = deepCopy(cfg)
local function applyDefaults(keepProf)
    for k in pairs(cfg) do cfg[k] = nil end
    for k, v in pairs(defCfg) do
        cfg[k] = type(v) == "table" and deepCopy(v) or v
    end
    cfg.misc.prof = keepProf or 1
end

local cfFile = "rvl_tools_v3.json"
pcall(function()
    if isfile and isfile("rvl_tools_prof.json") then
        local d = hs:JSONDecode(readfile("rvl_tools_prof.json"))
        if d and (d.prof == 2 or d.prof == 3) then
            cfFile = "rvl_tools_v3_p" .. d.prof .. ".json"
            cfg.misc.prof = d.prof
        end
    end
end)
local function save()
    local okS, errS = pcall(function()
        if not writefile then error("writefile unavailable") end
        local enc = hs:JSONEncode(cfg)
        local prev = nil
        pcall(function() if readfile then prev = readfile(cfFile) end end)
        if prev and prev ~= "" then
            local okB, errB = pcall(function() writefile(cfFile .. ".bak", prev) end)
            G.__rvl4_bakOk = okB
            G.__rvl4_bakErr = (not okB) and tostring(errB) or nil
        else
            G.__rvl4_bakOk, G.__rvl4_bakErr = nil, nil
        end
        writefile(cfFile, enc)
    end)
    G.__rvl4_saveOk = okS
    G.__rvl4_saveErr = (not okS) and tostring(errS) or nil
end
local function mergeCfg(d)
    local nMerged = 0
    for k, v in pairs(d) do
        local key = (k == "cam") and "camf" or k
        if type(v) == "table" and type(cfg[key]) == "table" then
            for k2, v2 in pairs(v) do
                if cfg[key][k2] ~= nil and type(v2) == type(cfg[key][k2]) and not (key == "misc" and k2 == "prof") then
                    cfg[key][k2] = v2
                    nMerged = nMerged + 1
                end
            end
        elseif cfg[key] ~= nil and type(v) == type(cfg[key]) then
            cfg[key] = v
            nMerged = nMerged + 1
        end
    end
    return nMerged
end
local function loadCfg()
    local function tryLoad(f)
        local nMerged = 0
        pcall(function()
            if not (isfile and isfile(f)) then return end
            local d = hs:JSONDecode(readfile(f))
            if type(d) ~= "table" then return end
            nMerged = mergeCfg(d)
        end)
        return nMerged > 0
    end
    if not tryLoad(cfFile) then tryLoad(cfFile .. ".bak") end
end
loadCfg()

local function clampNum(v, d, mn, mx)
    return math.clamp(tonumber(v) or d, mn, mx)
end
local function sanitize()
    local partOk = { Head = true, HumanoidRootPart = true, UpperTorso = true, Closest = true }
    if not partOk[cfg.aim.part] then cfg.aim.part = "Head" end
    local prioOk = { ["クロスヘア"] = true, ["低HP"] = true, ["近距離"] = true, ["複合"] = true }
    if not prioOk[cfg.aim.prio] then cfg.aim.prio = "クロスヘア" end
    cfg.aim.fov = clampNum(cfg.aim.fov, 160, 20, 1200)
    cfg.aim.sm = clampNum(cfg.aim.sm, .35, .05, 1)
    cfg.aim.pred = clampNum(cfg.aim.pred, .22, 0, .5)
    cfg.aim.smNear = clampNum(cfg.aim.smNear, 1.35, .3, 2.5)
    cfg.aim.smFar = clampNum(cfg.aim.smFar, .8, .2, 1.5)
    if type(cfg.sil.extra) ~= "string" then cfg.sil.extra = "" end
    if #cfg.sil.extra > 300 then cfg.sil.extra = string.sub(cfg.sil.extra, 1, 300) end
    if type(cfg.sil.callers) ~= "string" then cfg.sil.callers = "" end
    if #cfg.sil.callers > 300 then cfg.sil.callers = string.sub(cfg.sil.callers, 1, 300) end
    if type(cfg.combat.meleeExtra) ~= "string" then cfg.combat.meleeExtra = "" end
    if #cfg.combat.meleeExtra > 300 then cfg.combat.meleeExtra = string.sub(cfg.combat.meleeExtra, 1, 300) end
    cfg.esp.maxCount = clampNum(cfg.esp.maxCount, 100, 5, 300)
    cfg.sil.chance = clampNum(cfg.sil.chance, 100, 0, 100)
    cfg.sil.headchance = clampNum(cfg.sil.headchance, 0, 0, 100)
    cfg.sil.fov = clampNum(cfg.sil.fov, 250, 30, 1200)
    if cfg.trg.mode ~= "連射" and cfg.trg.mode ~= "単発" then cfg.trg.mode = "連射" end
    local ckOk = { T = true, Q = true, V = true, ["なし"] = true }
    if not ckOk[cfg.aim.cyclekey] then cfg.aim.cyclekey = "T" end
    if cfg.hb.part ~= "両方" and cfg.hb.part ~= "頭" and cfg.hb.part ~= "胴体" then cfg.hb.part = "両方" end
    cfg.trg.fov = clampNum(cfg.trg.fov, 20, 2, 120)
    cfg.trg.delay = clampNum(cfg.trg.delay, 25, 0, 300)
    cfg.esp.max = clampNum(cfg.esp.max, 1500, 100, 10000)
    cfg.esp.tsize = clampNum(cfg.esp.tsize, 12, 10, 28)
    cfg.esp.rd = clampNum(cfg.esp.rd, 120, 40, 600)
    if cfg.esp.colormode ~= "赤" and cfg.esp.colormode ~= "白" and cfg.esp.colormode ~= "緑" and cfg.esp.colormode ~= "青" and cfg.esp.colormode ~= "黄" and cfg.esp.colormode ~= "紫" and cfg.esp.colormode ~= "体力" and cfg.esp.colormode ~= "レインボー" then
        cfg.esp.colormode = "赤"
    end
    cfg.hb.size = clampNum(cfg.hb.size, 6, 2, 30)
    cfg.camf.val = clampNum(cfg.camf.val, 100, 60, 140)
    cfg.misc.prof = math.clamp(math.floor(tonumber(cfg.misc.prof) or 1), 1, 3)
    if cfg.misc.teammode ~= "自動" and cfg.misc.teammode ~= "全員敵" then cfg.misc.teammode = "自動" end
    if cfg.misc.uiscale ~= "標準" and cfg.misc.uiscale ~= "大" and cfg.misc.uiscale ~= "特大" then cfg.misc.uiscale = "標準" end
    cfg.xhair.size = math.clamp(math.floor(cfg.xhair.size or 6), 2, 14)
    cfg.xhair.gap = math.clamp(math.floor(cfg.xhair.gap or 8), 4, 16)
    cfg.xhair.thick = math.clamp(math.floor(cfg.xhair.thick or 2), 1, 4)
    cfg.combat.hsndVol = math.clamp(cfg.combat.hsndVol or .5, .05, 1)
    if cfg.misc.hookmode ~= "両方" and cfg.misc.hookmode ~= "リモートのみ" and cfg.misc.hookmode ~= "なし" then cfg.misc.hookmode = "リモートのみ" end
    cfg.fly.spd = clampNum(cfg.fly.spd, 48, 10, 500)
    if type(cfg.strafe) ~= "table" then cfg.strafe = { on = false, mode = "発射中", int = 120 } end
    if cfg.strafe.mode ~= "発射中" and cfg.strafe.mode ~= "常時" and cfg.strafe.mode ~= "空中" then cfg.strafe.mode = "発射中" end
    cfg.strafe.int = clampNum(cfg.strafe.int, 120, 30, 300)
    cfg.strafe.str = clampNum(cfg.strafe.str, 1, .3, 3)
    cfg.spd.val = clampNum(cfg.spd.val, 26, 16, 400)
    cfg.jmp.val = clampNum(cfg.jmp.val, 70, 50, 1000)
    if not cfg.misc.mig110 then
        cfg.misc.mig110 = true
        if cfg.aim.sm < .6 then cfg.aim.sm = .6 end
        if cfg.aim.pred < .22 then cfg.aim.pred = .22 end
        if cfg.trg.fov < 20 then cfg.trg.fov = 20 end
        if cfg.trg.delay > 25 then cfg.trg.delay = 25 end
        if cfg.esp.maxCount < 100 then cfg.esp.maxCount = 100 end
    end
end
if G.__rvl4_pendingCfg then
    local pc2 = G.__rvl4_pendingCfg
    G.__rvl4_pendingCfg = nil
    if type(pc2) == "table" then mergeCfg(pc2) end
end
sanitize()
G.__rvl4_cfg = cfg
stage("core")

local splitCsvCache = {}
local function splitCsv(s)
    s = s or ""
    local cached = splitCsvCache[s]
    if cached then return cached end
    local out = {}
    for tok in string.gmatch(s, "[^,]+") do
        local t2 = string.match(tok, "^%s*(.-)%s*$")
        if t2 ~= "" then out[#out + 1] = string.lower(t2) end
    end
    local nC = 0
    for _ in pairs(splitCsvCache) do nC = nC + 1 end
    if nC >= 64 then splitCsvCache = {} end
    splitCsvCache[s] = out
    return out
end

local plist, plistAt = nil, 0
local function getPlist()
    local now = os.clock()
    if not plist or now - plistAt > .1 then
        plist = plrs:GetPlayers()
        plistAt = now
    end
    return plist
end

G.__rvl4_disconnectAll = function(list)
    if list then for _, c in ipairs(list) do pcall(function() c:Disconnect() end) end end
end
if G.__rvl4_conns then G.__rvl4_disconnectAll(G.__rvl4_conns) end
pcall(function() if run.UnbindFromRenderStep then run:UnbindFromRenderStep("rvl4_strafe") end end)
if G.__rvl4_strafeOff then pcall(G.__rvl4_strafeOff) end
G.__rvl4_strafeBound = nil
G.__rvl4_strafeDir = nil
G.__rvl4_strafeRoot = nil
G.__rvl4_strafeLat = nil
local conns = {}
G.__rvl4_conns = conns
local errHist = ""
G.__rvl4_errPush = function(e)
    errHist = (errHist == "" and e or (errHist .. " | " .. e))
    if #errHist > 220 then errHist = string.sub(errHist, -220) end
end
local function bind(ev, fn)
    if not ev then return nil end
    local c = ev:Connect(function(...)
        if not alive() then return end
        local ok, err = pcall(fn, ...)
        if not ok then
            local e = tostring(err)
            G.__rvl4_errPush(e)
        end
    end)
    table.insert(conns, c)
    return c
end

G.__rvl4_rootOfChar = function(c)
    return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso")
end
local charCache = setmetatable({}, { __mode = "k" })
local frameId = 0
local function getChar(p)
    local c = p.Character
    if not c or not c.Parent then
        charCache[p] = nil
        return nil
    end
    local cc = charCache[p]
    if cc and cc.c == c then
        if not cc.hum or not cc.hum.Parent then cc.hum = c:FindFirstChildOfClass("Humanoid") end
        local gone = (cc.head and not cc.head.Parent) or (cc.root and not cc.root.Parent) or (cc.upper and not cc.upper.Parent)
        if gone or frameId - (cc._scanF or -30) >= ((cc.head and cc.root) and 16 or 8) then
            cc._scanF = frameId
            if not cc.head or not cc.head.Parent then cc.head = c:FindFirstChild("Head") end
            if not cc.root or not cc.root.Parent then cc.root = G.__rvl4_rootOfChar(c) end
            if not cc.upper or not cc.upper.Parent then cc.upper = c:FindFirstChild("UpperTorso") end
            if not cc.lower or not cc.lower.Parent then cc.lower = c:FindFirstChild("LowerTorso") or c:FindFirstChild("Torso") end
        end
        return cc
    end
    cc = {
        c = c,
        hum = c:FindFirstChildOfClass("Humanoid"),
        head = c:FindFirstChild("Head"),
        root = G.__rvl4_rootOfChar(c),
        upper = c:FindFirstChild("UpperTorso"),
        lower = c:FindFirstChild("LowerTorso") or c:FindFirstChild("Torso"),
    }
    charCache[p] = cc
    return cc
end

local function origin()
    if G.__rvl4_orgF == frameId then return G.__rvl4_orgV end
    local v
    if touch then
        v = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    else
        v = uis:GetMouseLocation()
    end
    G.__rvl4_orgF, G.__rvl4_orgV = frameId, v
    return v
end

local function partOf(p)
    local cc = getChar(p)
    if not cc then return nil end
    local want = cfg.aim.part
    if cc._pf == frameId and cc._pw == want then return cc._pp end
    local r = nil
    if want == "Closest" then
        local o = origin()
        local bestD = math.huge
        local function probe(cand)
            if not cand then return end
            local s, on = cam:WorldToViewportPoint(cand.Position)
            if on and s.Z > 0 then
                local dx, dy = s.X - o.X, s.Y - o.Y
                local d = math.sqrt(dx * dx + dy * dy)
                if d < bestD then r, bestD = cand, d end
            end
        end
        probe(cc.head)
        probe(cc.root)
        probe(cc.upper)
        r = r or cc.head or cc.root
    elseif want == "Head" then
        r = cc.head or cc.root
    elseif want == "HumanoidRootPart" then
        r = cc.root or cc.head
    elseif want == "UpperTorso" then
        r = cc.upper or cc.root or cc.head
    else
        r = cc.c:FindFirstChild(want) or cc.head or cc.root
    end
    cc._pf, cc._pw, cc._pp = frameId, want, r
    return r
end

G.__rvl4_hpRatio = function(h)
    return h.Health / math.max(h.MaxHealth, 1)
end
local function hpColor(fr)
    if fr ~= fr then fr = 1 end
    local g = G.__rvl4_hpGrad
    if not g then
        g = {}
        for i = 0, 100 do
            local f = i / 100
            g[i] = Color3.fromRGB(math.floor(255 * (1 - f)), math.floor(255 * f), 40)
        end
        G.__rvl4_hpGrad = g
    end
    return g[math.clamp(math.floor(fr * 100 + .5), 0, 100)]
end
local function rootOf(p)
    local cc = getChar(p)
    return cc and cc.root
end

local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Exclude
local selfRay = false
local visCache = setmetatable({}, { __mode = "k" })
local visTtl = .04
local visChar = nil
local function castVisible(part)
    local me = lp.Character
    if visChar ~= me then
        visChar = me
        rp.FilterDescendantsInstances = me and { me } or {}
    end
    local o = cam.CFrame.Position
    selfRay = true
    local okR, res = pcall(function()
        local hit = ws:Raycast(o, part.Position - o, rp)
        if not hit then return true end
        local par = part.Parent
        if not par then return false end
        return hit.Instance:IsDescendantOf(par)
    end)
    selfRay = false
    if not okR then return nil end
    return res
end
local function visible(p)
    local now = os.clock()
    local t = partOf(p)
    local vc = visCache[p]
    if t and vc and vc.part == t and now - vc.t < visTtl then return vc.v end
    local res = false
    if t then
        res = castVisible(t) == true
    end
    if t then
        if vc then
            vc.t, vc.v, vc.part = now, res, t
        else
            visCache[p] = { t = now, v = res, part = t }
        end
    end
    return res
end
local vpCache = setmetatable({}, { __mode = "k" })
local function visiblePart(p, part)
    if not part then return false end
    local now = os.clock()
    local vc = visCache[p]
    if vc and vc.part == part and now - vc.t < visTtl then return vc.v end
    local c = vpCache[part]
    if c and (c.f == frameId or (not c.v and now - c.t < .03)) then return c.v end
    local res = castVisible(part) == true
    if c then
        c.v, c.t, c.f = res, now, frameId
    else
        vpCache[part] = { v = res, t = now, f = frameId }
    end
    return res
end
local function visAny(p)
    if visible(p) then return true end
    local cc = getChar(p)
    if not cc then return false end
    if cc.head and visiblePart(p, cc.head) then return true end
    if cc.root and visiblePart(p, cc.root) then return true end
    return false
end

local ownUi = {}
local function hitsOwnUi(pos)
    for _, b in ipairs(ownUi) do
        if b.Visible ~= false then
            local ap, as = b.AbsolutePosition, b.AbsoluteSize
            if pos.X >= ap.X and pos.X <= ap.X + as.X and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y then
                return true
            end
        end
    end
    return false
end
local rightTouch = {}
local rightTouchN = 0
if touch then
    bind(uis.InputBegan, function(i)
        if i.UserInputType == Enum.UserInputType.Touch and i.Position.X > cam.ViewportSize.X * .35 and not hitsOwnUi(i.Position) then
            if not rightTouch[i] then
                rightTouchN = rightTouchN + 1
            end
            rightTouch[i] = os.clock()
        end
    end)
    local function releaseTouch(i)
        if rightTouch[i] then
            rightTouch[i] = nil
            rightTouchN = math.max(rightTouchN - 1, 0)
        end
    end
    bind(uis.InputChanged, function(i)
        if i.UserInputState == Enum.UserInputState.End or i.UserInputState == Enum.UserInputState.Cancel then
            releaseTouch(i)
        end
    end)
    bind(uis.InputEnded, function(i)
        if i.UserInputType == Enum.UserInputType.Touch then releaseTouch(i) end
    end)
end
local function touchAimActive()
    if G.__rvl4_taaF == frameId then return G.__rvl4_taaV end
    if rightTouchN > 0 then
        local now = os.clock()
        local n = 0
        for i, t in pairs(rightTouch) do
            if now - t > 4 then
                rightTouch[i] = nil
            else
                n = n + 1
            end
        end
        rightTouchN = n
    end
    G.__rvl4_taaF = frameId
    G.__rvl4_taaV = rightTouchN > 0
    return G.__rvl4_taaV
end

local velCache = setmetatable({}, { __mode = "k" })
local function smoothVel(root)
    local v = root.AssemblyLinearVelocity or Vector3.zero
    if v.X ~= v.X or v.Y ~= v.Y or v.Z ~= v.Z then
        velCache[root] = nil
        return Vector3.zero, Vector3.zero, 0
    end
    local now = os.clock()
    local e = velCache[root]
    if not e then
        velCache[root] = { v = v, raw = v, a = Vector3.zero, t = now, f = frameId }
        return v, Vector3.zero, v.Magnitude
    end
    if e.f == frameId then return e.v, e.a, e.raw.Magnitude end
    e.f = frameId
    local dtv = math.max(now - e.t, .001)
    local nv = e.v:Lerp(v, 1 - math.exp(-dtv * 30))
    local acc = (v - e.raw) / dtv
    if acc.Magnitude ~= acc.Magnitude then
        acc = Vector3.zero
    elseif acc.Magnitude > 350 then
        acc = acc.Unit * 350
    end
    e.a = e.a:Lerp(acc, 1 - math.exp(-dtv * 26))
    e.raw = v
    e.t = now
    e.v = nv
    return e.v, e.a, v.Magnitude
end
local pingSec, pingAt = 0, 0
local function getPing()
    local now = os.clock()
    if now - pingAt > .5 then
        local firstP = pingAt == 0
        pingAt = now
        pcall(function()
            local s = math.clamp(lp:GetNetworkPing(), 0, .5)
            if firstP or math.abs(s - pingSec) > .05 then
                pingSec = s
            else
                pingSec = pingSec + (s - pingSec) * .35
            end
        end)
    end
    return pingSec
end
local function predictedPos(p, part)
    if cfg.aim.pred <= 0 then return part.Position end
    local ccP = getChar(p)
    if ccP and ccP._pvF == frameId and ccP._pvPart == part then return ccP._pv end
    local root = rootOf(p)
    local v, a, rawSp
    if root then
        v, a, rawSp = smoothVel(root)
    else
        v, a = part.AssemblyLinearVelocity or Vector3.zero, Vector3.zero
        rawSp = v.Magnitude
    end
    if ccP and ccP.hum and ccP.hum.FloorMaterial ~= Enum.Material.Air then
        a = Vector3.new(a.X, 0, a.Z)
    end
    local t = math.min(cfg.aim.pred + getPing() * .5, .55)
    local vT = v * t
    local aT = a * (t * t * .5)
    local aMax = math.max(vT.Magnitude, (rawSp or 0) * t) * .6 + 2
    if aT.Magnitude > aMax then aT = aT.Unit * aMax end
    local lead = vT + aT
    if lead.Magnitude > 45 then lead = lead.Unit * 45 end
    local dist = (part.Position - cam.CFrame.Position).Magnitude
    if dist < 15 then lead = lead * math.max(dist / 15, .8) end
    local out = part.Position + lead
    if ccP then ccP._pvF, ccP._pvPart, ccP._pv = frameId, part, out end
    return out
end
