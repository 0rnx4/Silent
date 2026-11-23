G.__rvl4_hbRestorePart = function(part, o)
    part.Size = o.s
    part.Transparency = o.t
    part.CanCollide = o.c
end
G.__rvl4_isFx = function(v)
    return v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("PointLight") or v:IsA("SpotLight") or v:IsA("SurfaceLight")
end
local hbOrig = G.__rvl4_hbOrig or {}
local hbOwner = G.__rvl4_hbOwner or {}
G.__rvl4_hbOrig, G.__rvl4_hbOwner = hbOrig, hbOwner
bind(plrs.PlayerRemoving, function(p)
    plistAt = 0
    spawnPos[p] = nil
    spawnAt[p] = nil
    charCache[p] = nil
    visCache[p] = nil
    if locked == p then locked = nil end
    for part, owner in pairs(hbOwner) do
        if owner == p then
            local o = hbOrig[part]
            if o then
                pcall(G.__rvl4_hbRestorePart, part, o)
            end
            hbOrig[part] = nil
            hbOwner[part] = nil
        end
    end
end)

local nocOrig = G.__rvl4_nocOrig or {}
G.__rvl4_nocOrig = nocOrig
local noclipTick
do
    local nocParts, nocPartsAt, nocChar = nil, 0, nil
    function noclipTick()
        if not cfg.noc then
            if next(nocOrig) then
                for part, v in pairs(nocOrig) do
                    pcall(function() part.CanCollide = v end)
                end
                nocOrig = {}
                G.__rvl4_nocOrig = nocOrig
            end
            return
        end
        local c = lp.Character
        if not c then return end
        if nocChar ~= c or not nocParts or os.clock() - nocPartsAt > .1 then
            nocChar, nocParts, nocPartsAt = c, {}, os.clock()
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then table.insert(nocParts, p) end
            end
            for part in pairs(nocOrig) do
                if not part.Parent then nocOrig[part] = nil end
            end
        end
        for _, p in ipairs(nocParts) do
            if p.Parent then
                if nocOrig[p] == nil then nocOrig[p] = p.CanCollide end
                if p.CanCollide then p.CanCollide = false end
            end
        end
    end
end

local resetMove, moveTick
do
    local spdWas, spdDef = false, nil
    local spdHum, jmpHum = nil, nil
    local jmpWas, jmpDef, jmpUseDef = false, nil, nil
    local bhopAt = 0
    function moveTick()
        if not spdWas and not jmpWas and not cfg.spd.on and not cfg.jmp.on and not cfg.bhop and not G.__rvl4_spdDef and not G.__rvl4_jmpDef then return end
        local c = lp.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if not h then return end
        if not cfg.spd.on and not spdWas and G.__rvl4_spdDef then
            if h.WalkSpeed == cfg.spd.val then
                local sd = G.__rvl4_spdDef
                pcall(function() h.WalkSpeed = sd end)
            end
            G.__rvl4_spdDef = nil
        end
        if not cfg.jmp.on and not jmpWas and G.__rvl4_jmpDef then
            if h.JumpPower == cfg.jmp.val then
                local jd, ju = G.__rvl4_jmpDef, G.__rvl4_jmpUseDef
                pcall(function() h.JumpPower = jd end)
                if ju ~= nil then pcall(function() h.UseJumpPower = ju end) end
            end
            G.__rvl4_jmpDef, G.__rvl4_jmpUseDef = nil, nil
        end
        if spdHum ~= h then spdWas = false end
        if jmpHum ~= h then jmpWas = false end
        if cfg.spd.on then
            if not spdWas then
                spdDef = h.WalkSpeed
                if spdDef == cfg.spd.val and G.__rvl4_spdDef then spdDef = G.__rvl4_spdDef end
                G.__rvl4_spdDef = spdDef
                spdWas = true
                spdHum = h
            end
            pcall(function() if h.WalkSpeed ~= cfg.spd.val then h.WalkSpeed = cfg.spd.val end end)
        elseif spdWas then
            spdWas = false
            pcall(function() h.WalkSpeed = spdDef end)
        end
        if cfg.jmp.on then
            if not jmpWas then
                jmpDef = h.JumpPower
                jmpUseDef = h.UseJumpPower
                if jmpDef == cfg.jmp.val and G.__rvl4_jmpDef then
                    jmpDef = G.__rvl4_jmpDef
                    if G.__rvl4_jmpUseDef ~= nil then jmpUseDef = G.__rvl4_jmpUseDef end
                end
                G.__rvl4_jmpDef, G.__rvl4_jmpUseDef = jmpDef, jmpUseDef
                jmpWas = true
                jmpHum = h
            end
            pcall(function()
                if h.UseJumpPower ~= true then h.UseJumpPower = true end
                if h.JumpPower ~= cfg.jmp.val then h.JumpPower = cfg.jmp.val end
            end)
        elseif jmpWas then
            jmpWas = false
            pcall(function()
                h.JumpPower = jmpDef
                h.UseJumpPower = jmpUseDef
            end)
        end
        if cfg.bhop then
            local now = os.clock()
            if now - bhopAt > .02 and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > .1 then
                bhopAt = now
                pcall(function() h.Jump = true end)
                pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end)
            end
        end
    end
    function resetMove()
        spdWas, jmpWas = false, false
        spdHum, jmpHum = nil, nil
    end
end
bind(run.Stepped, function() if alive() then noclipTick() end end)
bind(run.Heartbeat, function() if alive() then moveTick() end end)
bind(uis.JumpRequest, function()
    if not alive() or not cfg.infj then return end
    local c = lp.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
end)

local function restoreHB()
    for part, o in pairs(hbOrig) do
        pcall(G.__rvl4_hbRestorePart, part, o)
    end
    hbOrig = {}
    hbOwner = {}
    G.__rvl4_hbOrig, G.__rvl4_hbOwner = hbOrig, hbOwner
end
local function hbTick()
    if not cfg.hb.on then
        if next(hbOrig) then restoreHB() end
        return
    end
    local sz = Vector3.new(cfg.hb.size, cfg.hb.size, cfg.hb.size)
    local verdict = {}
    for _, p in ipairs(getPlist()) do
        if p ~= lp and isEnemy(p) then
            local cc = getChar(p)
            if cc then
                local hp1, hp2, hp3, hp4 = cc.head, cc.root, cc.upper, cc.lower
                if cfg.hb.part == "頭" then hp2, hp3, hp4 = nil, nil, nil end
                if cfg.hb.part == "胴体" then hp1 = nil end
                local hps = { hp1, hp2, hp3, hp4 }
                for i = 1, 4 do
                    local part = hps[i]
                    if part then
                        if not hbOrig[part] then
                            hbOrig[part] = { s = part.Size, t = part.Transparency, c = part.CanCollide }
                            hbOwner[part] = p
                        end
                        pcall(function()
                            if part.Size ~= sz then part.Size = sz end
                            if part.Transparency ~= .6 then part.Transparency = .6 end
                            if part.CanCollide then part.CanCollide = false end
                        end)
                    end
                end
            end
        end
    end
    for part, o in pairs(hbOrig) do
        if not part.Parent then
            hbOrig[part] = nil
            hbOwner[part] = nil
        else
            local owner = hbOwner[part]
            local want = true
            if owner then
                local cc2 = getChar(owner)
                if cc2 then
                    if cfg.hb.part == "頭" and part ~= cc2.head then want = false end
                    if cfg.hb.part == "胴体" and part == cc2.head then want = false end
                    if part ~= cc2.head and part ~= cc2.root and part ~= cc2.upper and part ~= cc2.lower then want = false end
                end
            end
            local drop = not want
            if not drop then
                if not owner then
                    drop = true
                else
                    local ev = verdict[owner]
                    if ev == nil then
                        ev = isEnemy(owner)
                        verdict[owner] = ev
                    end
                    if not ev then drop = true end
                end
            end
            if drop then
                pcall(G.__rvl4_hbRestorePart, part, o)
                hbOrig[part] = nil
                hbOwner[part] = nil
            end
        end
    end
end

local attrOrig = G.__rvl4_attrOrig or {}
G.__rvl4_attrOrig = attrOrig
local function restoreAttr(tool, name)
    local rec = attrOrig[tool]
    if rec and rec[name] ~= nil then
        pcall(function() tool:SetAttribute(name, rec[name]) end)
        rec[name] = nil
        if not next(rec) then attrOrig[tool] = nil end
    end
end
local function combatTick()
    for tool in pairs(attrOrig) do
        if not tool.Parent then attrOrig[tool] = nil end
    end
    if cfg.combat.norecoil or cfg.combat.nospread then
        if not cfg.combat.norecoil then
            for tool in pairs(attrOrig) do restoreAttr(tool, "Recoil") end
        end
        if not cfg.combat.nospread then
            for tool in pairs(attrOrig) do restoreAttr(tool, "Spread") end
        end
        local function zeroAttr(tool, name, flag)
            local rec = attrOrig[tool]
            local okA, cur = pcall(function() return tool:GetAttribute(name) end)
            if not okA then return end
            if flag then
                if cur ~= nil and cur ~= 0 then
                    if not rec then
                        rec = {}
                        attrOrig[tool] = rec
                    end
                    if rec[name] == nil then rec[name] = cur end
                    pcall(function() tool:SetAttribute(name, 0) end)
                end
            elseif rec and rec[name] ~= nil then
                pcall(function() tool:SetAttribute(name, rec[name]) end)
                rec[name] = nil
            end
        end
        local c = lp.Character
        if c then
            for _, tool in ipairs(c:GetChildren()) do
                if tool:IsA("Tool") then
                    zeroAttr(tool, "Recoil", cfg.combat.norecoil)
                    zeroAttr(tool, "Spread", cfg.combat.nospread)
                end
            end
        end
    elseif next(attrOrig) then
        for tool, rec in pairs(attrOrig) do
            for name, orig in pairs(rec) do
                pcall(function() tool:SetAttribute(name, orig) end)
            end
        end
        attrOrig = {}
        G.__rvl4_attrOrig = attrOrig
    end
end

local modsTick, probeLib
local modStatTx = nil
do
    local wlib, wstats = nil, nil
    local worig = G.__rvl4_worig or {}
    G.__rvl4_worig = worig
    local wNextTry = 0
    local modWas = false
    local WKEYS = { "ShootRecoil", "ShootSpread", "AimSpreadMultiplier", "ShootCooldown", "ReloadLength", "EmptyReloadLength", "EquipCooldown", "MaxAmmo", "MaxAmmoReserve", "Recoil", "Spread" }
    local LIBNAMES = { "ItemLibrary", "ItemData", "WeaponData", "GunLibrary", "WeaponLibrary", "ItemDB", "Weapons" }
    local AUTOKEYS = { "Automatic", "AutoFire", "FullAuto", "IsAutomatic" }
    local KEYOWNER = {
        ShootRecoil = "norecoil", Recoil = "norecoil",
        ShootSpread = "nospread", AimSpreadMultiplier = "nospread", Spread = "nospread",
        ShootCooldown = "rapid",
        ReloadLength = "reload", EmptyReloadLength = "reload",
        EquipCooldown = "equip",
        MaxAmmo = "ammo", MaxAmmoReserve = "ammo",
        Automatic = "fullauto", AutoFire = "fullauto", FullAuto = "fullauto", IsAutomatic = "fullauto",
        AimDownSightsTime = "ads", ADSTime = "ads", ScopeTime = "ads", AimTime = "ads", AdsTime = "ads",
        Damage = "dmgmod", BaseDamage = "dmgmod", DamagePerBullet = "dmgmod", BulletDamage = "dmgmod",
    }
    local ADSKEYS = { "AimDownSightsTime", "ADSTime", "ScopeTime", "AimTime", "AdsTime" }
    local DMGKEYS = { "Damage", "BaseDamage", "DamagePerBullet", "BulletDamage" }

    local function collectStats(t, depth, out, seen)
        if type(t) ~= "table" or depth > 4 or seen[t] then return end
        seen[t] = true
        local wk, tot = 0, 0
        for _, k in ipairs(WKEYS) do
            if type(t[k]) == "number" then wk = wk + 1 tot = tot + 1 end
        end
        for _, k in ipairs(AUTOKEYS) do
            if type(t[k]) == "boolean" or type(t[k]) == "number" then tot = tot + 1 end
        end
        for _, k in ipairs(ADSKEYS) do
            if type(t[k]) == "number" then tot = tot + 1 end
        end
        for _, k in ipairs(DMGKEYS) do
            if type(t[k]) == "number" then tot = tot + 1 end
        end
        if wk >= 1 or tot >= 2 then table.insert(out, t) end
        for _, v in pairs(t) do
            if type(v) == "table" then collectStats(v, depth + 1, out, seen) end
        end
    end

    local lastModStat, lastModObj = "", nil
    local function setModStat(txt)
        if txt == lastModStat and modStatTx == lastModObj then return end
        lastModStat, lastModObj = txt, modStatTx
        if modStatTx then pcall(function() modStatTx.Text = txt end) end
    end

    local libFails = 0
    local wlibSrc, wlibSrcAt = nil, 0
    local function findLib()
        if wlib then
            local now0 = os.clock()
            if wlibSrc and now0 - wlibSrcAt > 5 then
                wlibSrcAt = now0
                local cur = nil
                pcall(function()
                    local rs = game:GetService("ReplicatedStorage")
                    for _, nm in ipairs(LIBNAMES) do
                        local f = rs:FindFirstChild(nm, true)
                        if f and f:IsA("ModuleScript") then cur = f break end
                    end
                end)
                if cur and cur ~= wlibSrc then
                    if next(worig) then
                        for t, per in pairs(worig) do
                            for k, v in pairs(per) do
                                pcall(function() t[k] = v end)
                            end
                        end
                        worig = {} G.__rvl4_worig = worig
                    end
                    wlib, wstats, wlibSrc = nil, nil, nil
                end
            end
            if wlib then return true end
        end
        local now = os.clock()
        if now < wNextTry then return false end
        wNextTry = now + math.min(5 * (2 ^ libFails), 8)
        local cand = nil
        pcall(function()
            local rs = game:GetService("ReplicatedStorage")
            for _, nm in ipairs(LIBNAMES) do
                local f = rs:FindFirstChild(nm, true)
                if f and f:IsA("ModuleScript") then cand = f break end
            end
            if not cand then
                pcall(function()
                    local rf = game:GetService("ReplicatedFirst")
                    for _, v in ipairs(rf:GetDescendants()) do
                        if v:IsA("ModuleScript") and string.find(v.Name, "ItemLibrary") then cand = v break end
                    end
                end)
            end
            if not cand then
                for _, v in ipairs(rs:GetDescendants()) do
                    if v:IsA("ModuleScript") and string.find(v.Name, "ItemLibrary") then cand = v break end
                end
            end
        end)
        if cand then pcall(function() wlib = require(cand) end) end
        if not wlib and getloadedmodules then
            pcall(function()
                for _, m in ipairs(getloadedmodules()) do
                    if string.find(m.Name, "ItemLibrary") then wlib = require(m) break end
                end
            end)
        end
        if type(wlib) == "table" then
            local out = {}
            collectStats(wlib, 0, out, {})
            if #out > 0 then
                wstats = out
                libFails = 0
                if cand then wlibSrc = cand end
                wlibSrcAt = os.clock()
                return true
            end
        end
        if getloadedmodules then
            local wlib2, src2 = nil, nil
            pcall(function()
                for _, m in ipairs(getloadedmodules()) do
                    if string.find(m.Name, "ItemLibrary") then wlib2 = require(m) src2 = m break end
                end
            end)
            if type(wlib2) == "table" and wlib2 ~= wlib then
                local out = {}
                collectStats(wlib2, 0, out, {})
                if #out > 0 then
                    wlib = wlib2
                    wstats = out
                    libFails = 0
                    wlibSrc = src2
                    wlibSrcAt = os.clock()
                    return true
                end
            end
        end
        wlib, wstats = nil, nil
        libFails = libFails + 1
        return false
    end

    local function wstore(t, k)
        local per = worig[t]
        if not per then
            per = {}
            worig[t] = per
        end
        if per[k] == nil then per[k] = t[k] end
        return per[k]
    end
    local function wset(t, k, v)
        if type(t[k]) ~= "number" then return end
        wstore(t, k)
        if t[k] ~= v then t[k] = v end
    end
    local function wsetB(t, k, v)
        if type(t[k]) ~= "boolean" then return end
        wstore(t, k)
        if t[k] ~= v then t[k] = v end
    end
    local function scaleFromOrig(t, k, factor)
        if type(t[k]) == "number" then
            local nv = wstore(t, k) * factor
            if t[k] ~= nv then t[k] = nv end
        end
    end

    local function modsActive()
        local c = cfg.combat
        return c.norecoil or c.nospread or c.rapid or c.reload or c.equip or c.ammo or c.fullauto or c.ads or c.dmgmod
    end

    function modsTick()
        local actNow = modsActive()
        if actNow and not modWas then
            libFails = 0
            wNextTry = 0
        end
        modWas = actNow
        if not modsActive() then
            if next(worig) then
                for t, per in pairs(worig) do
                    for k, v in pairs(per) do
                        pcall(function() t[k] = v end)
                    end
                end
                worig = {} G.__rvl4_worig = worig
            end
            setModStat("武器MOD: 待機中")
            return
        end
        if not findLib() then
            setModStat("武器MOD: ライブラリ未検出")
            return
        end
        if wlib and wstats and os.clock() - (G.__rvl4_wrecAt or 0) > 5 then
            G.__rvl4_wrecAt = os.clock()
            local seenW = {}
            for _, t in ipairs(wstats) do seenW[t] = true end
            local freshW = {}
            collectStats(wlib, 0, freshW, {})
            for _, t in ipairs(freshW) do
                if not seenW[t] then wstats[#wstats + 1] = t end
            end
        end
        local c = cfg.combat
        for t, per in pairs(worig) do
            for k, v in pairs(per) do
                local owner = KEYOWNER[k]
                if owner and not c[owner] then
                    pcall(function() t[k] = v end)
                    per[k] = nil
                end
            end
        end
        for _, t in ipairs(wstats) do
            if c.norecoil then wset(t, "ShootRecoil", 0) wset(t, "Recoil", 0) end
            if c.nospread then wset(t, "ShootSpread", 0) wset(t, "AimSpreadMultiplier", 0) wset(t, "Spread", 0) end
            if c.rapid then scaleFromOrig(t, "ShootCooldown", .1) end
            if c.reload then wset(t, "ReloadLength", .01) wset(t, "EmptyReloadLength", .01) end
            if c.equip then wset(t, "EquipCooldown", .01) end
            if c.ammo then wset(t, "MaxAmmo", 9999) wset(t, "MaxAmmoReserve", 9999) end
            if c.fullauto then
                for _, k in ipairs(AUTOKEYS) do wsetB(t, k, true) end
            end
            if c.ads then
                for _, k in ipairs(ADSKEYS) do scaleFromOrig(t, k, .05) end
            end
            if c.dmgmod then
                for _, k in ipairs(DMGKEYS) do scaleFromOrig(t, k, 3) end
            end
        end
        setModStat("武器MOD: 適用中 (" .. #wstats .. "種)")
    end
    probeLib = function() return findLib() end
end

local rainbowOrig = G.__rvl4_rainbowOrig or {}
G.__rvl4_rainbowOrig = rainbowOrig
local function rainbowTick()
    if not cfg.misc.rainbow then
        if next(rainbowOrig) then
            for part, col in pairs(rainbowOrig) do
                pcall(function() part.Color = col end)
            end
            rainbowOrig = {}
            G.__rvl4_rainbowOrig = rainbowOrig
        end
        return
    end
    local c = lp.Character
    local tool = c and c:FindFirstChildOfClass("Tool")
    for part, col in pairs(rainbowOrig) do
        local inside = false
        if tool then pcall(function() inside = part:IsDescendantOf(tool) end) end
        if not inside then
            pcall(function() part.Color = col end)
            rainbowOrig[part] = nil
        end
    end
    if not tool then return end
    local col = Color3.fromHSV((os.clock() * .25) % 1, .85, 1)
    for _, d in ipairs(tool:GetDescendants()) do
        if d:IsA("BasePart") then
            pcall(function()
                if rainbowOrig[d] == nil then rainbowOrig[d] = d.Color end
                d.Color = col
            end)
        end
    end
end

local reloadAt = 0
local arLatchAmmo = nil
local function autoReloadTick()
    if not cfg.combat.autoreload then return end
    if os.clock() - reloadAt < .5 then return end
    local c = lp.Character
    local tool = c and c:FindFirstChildOfClass("Tool")
    if not tool then return end
    local ammo, maxA = nil, nil
    pcall(function() ammo = tool:GetAttribute("Ammo") end)
    pcall(function() maxA = tool:GetAttribute("MaxAmmo") end)
    if ammo == nil then
        local nv = tool:FindFirstChild("Ammo")
        if nv then pcall(function() ammo = nv.Value end) end
    end
    ammo, maxA = tonumber(ammo), tonumber(maxA)
    if ammo == 0 or (ammo and maxA and maxA > 0 and ammo / maxA <= .4) then
        if arLatchAmmo == ammo and os.clock() - reloadAt < 1.5 then return end
        arLatchAmmo = ammo
        reloadAt = os.clock()
        if keypress and keyrelease then
            pcall(function() keypress(0x52) end)
            task.delay(.05, function()
                pcall(function() keyrelease(0x52) end)
            end)
        else
            pcall(function()
                local vim = game:GetService("VirtualInputManager")
                vim:SendKeyEvent(true, Enum.KeyCode.R, false, game)
                task.delay(.05, function()
                    pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.R, false, game) end)
                end)
            end)
        end
    else
        arLatchAmmo = nil
    end
end

local thirdOrig = G.__rvl4_thirdOrig
local function thirdTick()
    if cfg.misc.third then
        if not thirdOrig then
            thirdOrig = { lp.CameraMode, lp.CameraMinZoomDistance, lp.CameraMaxZoomDistance }
            G.__rvl4_thirdOrig = thirdOrig
        end
        if lp.CameraMode ~= Enum.CameraMode.Classic then lp.CameraMode = Enum.CameraMode.Classic end
        if lp.CameraMinZoomDistance ~= 7 then lp.CameraMinZoomDistance = 7 end
        if lp.CameraMaxZoomDistance ~= 7 then lp.CameraMaxZoomDistance = 7 end
    elseif thirdOrig then
        lp.CameraMode = thirdOrig[1]
        lp.CameraMinZoomDistance = thirdOrig[2]
        lp.CameraMaxZoomDistance = thirdOrig[3]
        thirdOrig = nil
        G.__rvl4_thirdOrig = nil
    end
end

local baseShadow = G.__rvl4_baseShadow
local function syncShadows()
    if cfg.vis.fb or cfg.fpsb then
        if lt.GlobalShadows ~= false then baseShadow = lt.GlobalShadows G.__rvl4_baseShadow = baseShadow end
        lt.GlobalShadows = false
    elseif baseShadow ~= nil then
        lt.GlobalShadows = baseShadow
        baseShadow = nil
        G.__rvl4_baseShadow = nil
    end
end

local applyFps
do
    local fpsOn, fpsQual = G.__rvl4_fpsOn or false, G.__rvl4_fpsQual
    local fpsParts = G.__rvl4_fpsParts or {}
    local fpsSet = {}
    G.__rvl4_fpsParts = fpsParts
    for _, e in ipairs(fpsParts) do fpsSet[e[1]] = true end
    local fpsScanning = false
    local fpsEpoch = 0
    function applyFps()
        if cfg.fpsb then
            if fpsOn and (fpsScanning or G.__rvl4_fpsSwept) then return end
            if not fpsOn then
                fpsOn = true
                G.__rvl4_fpsOn = true
                fpsEpoch = fpsEpoch + 1
                syncShadows()
                fpsQual = G.__rvl4_fpsQual
                if fpsQual == nil then
                    pcall(function() fpsQual = settings().Rendering.QualityLevel end)
                    G.__rvl4_fpsQual = fpsQual
                end
                pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
                pcall(function()
                    if setfpscap then
                        if getfpscap then G.__rvl4_fpsCap = getfpscap() end
                        setfpscap(999)
                    end
                end)
            end
            if fpsScanning then return end
            fpsScanning = true
            G.__rvl4_fpsScan = true
            local myEpoch = fpsEpoch
            task.spawn(function()
                local list = ws:GetDescendants()
                for i = #fpsParts, 1, -1 do
                    if not (fpsParts[i][1] and fpsParts[i][1].Parent) then table.remove(fpsParts, i) end
                end
                fpsSet = {}
                for _, e in ipairs(fpsParts) do fpsSet[e[1]] = true end
                for i, v in ipairs(list) do
                    if not alive() then break end
                    if G.__rvl4_isFx(v) then
                        if cfg.fpsb then
                            if not fpsSet[v] then fpsSet[v] = true table.insert(fpsParts, { v, v.Enabled }) end
                            v.Enabled = false
                        end
                    end
                    if fpsEpoch ~= myEpoch then break end
                    if i % 1000 == 0 then
                        if not cfg.fpsb or fpsEpoch ~= myEpoch or not alive() then break end
                        task.wait()
                    end
                end
                if fpsEpoch == myEpoch then fpsScanning = false G.__rvl4_fpsScan = false G.__rvl4_fpsSwept = true end
            end)
        elseif fpsOn then
            fpsEpoch = fpsEpoch + 1
            fpsScanning = false
            G.__rvl4_fpsScan = false
            fpsOn = false
            G.__rvl4_fpsOn = false
            G.__rvl4_fpsSwept = nil
            syncShadows()
            if fpsQual ~= nil then
                local q = fpsQual
                fpsQual = nil
                G.__rvl4_fpsQual = nil
                pcall(function() settings().Rendering.QualityLevel = q end)
            end
            pcall(function() if setfpscap then setfpscap(G.__rvl4_fpsCap or 60) end end)
            G.__rvl4_fpsCap = nil
            for _, pr in ipairs(fpsParts) do
                pcall(function() pr[1].Enabled = pr[2] end)
            end
            fpsParts = {}
            fpsSet = {}
            G.__rvl4_fpsParts = fpsParts
        end
    end
    bind(ws.DescendantAdded, function(v)
        if not fpsOn or not cfg.fpsb then return end
        if G.__rvl4_isFx(v) then
            if fpsSet[v] then return end
            fpsSet[v] = true
            table.insert(fpsParts, { v, v.Enabled })
            v.Enabled = false
        end
    end)
end

local applyVis
do
    local oAmb, oBri, oFogS, oFogE, oOut = nil, nil, nil, nil, nil
    if G.__rvl4_visOrig then local vt = G.__rvl4_visOrig oAmb, oBri, oFogS, oFogE, oOut = vt[1], vt[2], vt[3], vt[4], vt[5] end
    function applyVis()
        if cfg.vis.fb then
            if not oAmb then
                oAmb, oBri, oOut = lt.Ambient, lt.Brightness, lt.OutdoorAmbient
                G.__rvl4_visOrig = { oAmb, oBri, oFogS, oFogE, oOut }
            end
            local c180 = Color3.fromRGB(180, 180, 180)
            if lt.Ambient ~= c180 then lt.Ambient = c180 end
            if lt.OutdoorAmbient ~= c180 then lt.OutdoorAmbient = c180 end
            if lt.Brightness ~= 2 then lt.Brightness = 2 end
            syncShadows()
        elseif oAmb then
            lt.Ambient = oAmb
            lt.Brightness = oBri
            lt.OutdoorAmbient = oOut
            oAmb = nil
            G.__rvl4_visOrig = { oAmb, oBri, oFogS, oFogE, oOut }
            syncShadows()
        end
        if cfg.vis.nf then
            if not oFogE then
                oFogE, oFogS = lt.FogEnd, lt.FogStart
                G.__rvl4_visOrig = { oAmb, oBri, oFogS, oFogE, oOut }
            end
            if lt.FogEnd ~= 100000 then lt.FogEnd = 100000 end
            if lt.FogStart ~= 100000 then lt.FogStart = 100000 end
        elseif oFogE then
            lt.FogEnd = oFogE
            lt.FogStart = oFogS
            oFogE = nil
            G.__rvl4_visOrig = { oAmb, oBri, oFogS, oFogE, oOut }
        end
    end
end


G.__rvl4_emote = function(play)
    pcall(function()
        if G.__rvl4_emoteTrack then
            pcall(function() G.__rvl4_emoteTrack:Stop() end)
            G.__rvl4_emoteTrack = nil
        end
        if not play then return end
        local id = tostring(cfg.misc.emoteId or ""):gsub("%D", "")
        if id == "" then return end
        local ch = lp.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        local anim = hum and hum:FindFirstChildOfClass("Animator")
        if not anim then return end
        local a = Instance.new("Animation")
        a.AnimationId = "rbxassetid://" .. id
        local tr = anim:LoadAnimation(a)
        tr.Looped = true
        tr:Play()
        G.__rvl4_emoteTrack = tr
    end)
end

task.spawn(function()
    while alive() do
        task.wait(touch and .15 or .1)
        if not alive() then break end
        pcall(rainbowTick)
        pcall(autoReloadTick)
        pcall(thirdTick)
    end
end)

task.spawn(function()
    while alive() do
        task.wait(touch and .08 or .1)
        if not alive() then break end
        G.__rvl4_espN = (G.__rvl4_espN or 0) + 1
        if (G.__rvl4_load or 0) < 1 or G.__rvl4_espN % 2 == 1 then pcall(espTick) end
    end
end)

local afkClock = os.clock()
bind(uis.InputBegan, function() afkClock = os.clock() end)
task.spawn(function()
    local vu = nil
    pcall(function() vu = game:GetService("VirtualUser") end)
    local lastMouse = nil
    while alive() do
        task.wait(30)
        if not alive() then break end
        pcall(function()
            local mp = uis:GetMouseLocation()
            if lastMouse and (mp - lastMouse).Magnitude > 2 then afkClock = os.clock() end
            lastMouse = mp
        end)
        if cfg.afk and vu and os.clock() - afkClock > 540 then
            afkClock = os.clock()
            pcall(function()
                vu:CaptureController()
                vu:ClickButton2(Vector2.new(0, 0))
            end)
        end
    end
end)

task.spawn(function()
    local tick2 = false
    while alive() do
        task.wait(.15)
        if not alive() then break end
        local nc = ws.CurrentCamera
        if nc and nc ~= cam then cam = nc end
        pcall(hbTick)
        pcall(modsTick)
        tick2 = not tick2
        if tick2 then
            pcall(combatTick)
            pcall(applyFps)
            pcall(applyVis)
        end
    end
end)

bind(lp.CharacterAdded, function()
    task.wait(.4)
    if not alive() then return end
    if cfg.fly.on then setFly(true) end
    for part, v in pairs(nocOrig) do
        pcall(function() part.CanCollide = v end)
    end
    nocOrig = {}
    G.__rvl4_nocOrig = nocOrig
    resetMove()
end)
stage("sys")
