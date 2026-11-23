local locked = nil
local curTarget, curPart, curPos = nil, nil, nil
local curTrg, curTrgP = false, nil
local silPart, silPos = nil, nil
local rollOk = true
local cycSkip = nil

local refreshTarget
do
    local candBuf = {}
    local rollAt, headOk = 0, false

    local function scoreOf(p, part, screenDist)
        local prio = cfg.aim.prio
        if prio == "低HP" then
            local cc = getChar(p)
            return (cc and cc.hum and cc.hum.Health) or 9999
        end
        if prio == "近距離" then
            return (part.Position - cam.CFrame.Position).Magnitude
        end
        if prio == "複合" then
            local cc = getChar(p)
            local hp = (cc and cc.hum and cc.hum.Health) or 100
            local wd = (part.Position - cam.CFrame.Position).Magnitude
            return screenDist * .6 + hp * 1.2 + wd * .15
        end
        return screenDist
    end

    local function scrD(sv, ov)
        local dx, dy = sv.X - ov.X, sv.Y - ov.Y
        return math.sqrt(dx * dx + dy * dy)
    end
    function refreshTarget()
        local needAim = cfg.aim.on or cfg.sil.on or cfg.aim.ragebot or cfg.aim.flick or cfg.combat.auto
        local needTrg = cfg.trg.on
        if not needAim and not needTrg then
            curTarget, curPart, curPos = nil, nil, nil
            curTrg, curTrgP = false, nil
            silPart, silPos = nil, nil
            locked = nil
            G.__rvl4_silLock = nil
            cycSkip = nil
            return
        end

        local o = origin()
        local fov = cfg.aim.ragebot and 2000 or ((cfg.aim.on or cfg.aim.flick) and cfg.aim.fov or (cfg.sil.on and cfg.sil.fov or cfg.aim.fov))
        local reach = math.max(needAim and fov or 0, needTrg and cfg.trg.fov or 0, cfg.sil.on and cfg.sil.fov or 0)
        local best, bestScore, lockDist = nil, math.huge, nil
        local cycSeen, skipPart = false, nil
        local lockPartCand, lockDistCur, silLockDist, silLockPart = nil, nil, nil, nil
        local bestPart, silBest, silBestScore, silBestPart = nil, nil, math.huge, nil
        local trgHit, trgDist = false, math.huge
        local cand, candN = candBuf, 0

        for _, p in ipairs(getPlist()) do
            if isEnemy(p) then
                local part = partOf(p)
                if part and cfg.aim.part == "Closest" then
                    local cc0 = getChar(p)
                    local onScr = false
                    local cands = nil
                    if cc0 then
                        cands = cc0._cands
                        if not cands then cands = {} cc0._cands = cands end
                        cands[1], cands[2], cands[3] = cc0.head, cc0.upper, cc0.root
                        for i2 = 1, 3 do
                            local cp = cands[i2]
                            if cp then
                                local sv, onv = cam:WorldToViewportPoint(cp.Position)
                                if onv and sv.Z > 0 then onScr = true break end
                            end
                        end
                    end
                    if onScr and cands and cfg.aim.pred > 0 then
                        local bp, bd = nil, math.huge
                        for i2 = 1, 3 do
                            local cp = cands[i2]
                            if cp then
                                local pp = predictedPos(p, cp)
                                if pp then
                                    local sv, onv = cam:WorldToViewportPoint(pp)
                                    if onv and sv.Z > 0 then
                                        local dd = scrD(sv, o)
                                        if dd < bd then bp, bd = cp, dd end
                                    end
                                end
                            end
                        end
                        if bp and bp ~= part then
                            part = bp
                            cc0._pp = bp
                        end
                    end
                    if onScr and cands and not visiblePart(p, part) then
                        for i2 = 1, 3 do
                            local cand = cands[i2]
                            if cand and cand ~= part and visiblePart(p, cand) then
                                part = cand
                                cc0._pp = cand
                                break
                            end
                        end
                    end
                end
                if part then
                    local s, on = cam:WorldToViewportPoint(part.Position)
                    if on and s.Z > 0 then
                        local dCur = scrD(s, o)
                        local d = dCur
                        if cfg.aim.pred > 0 then
                            local pp = predictedPos(p, part)
                            if pp then
                                local sP, onP = cam:WorldToViewportPoint(pp)
                                if onP and sP.Z > 0 then
                                    d = scrD(sP, o)
                                end
                            end
                        end
                        if needAim and p == locked then lockDist, lockPartCand, lockDistCur = d, part, dCur end
                        if cfg.sil.on and p == G.__rvl4_silLock then silLockDist, silLockPart = d, part end
                        if p == cycSkip then cycSeen, skipPart = true, part end
                        local curE = nil
                        if d <= reach then
                            candN = candN + 1
                            local e = cand[candN]
                            if not e then
                                e = {}
                                cand[candN] = e
                            end
                            if e.p ~= p then e.sc, e.td = nil, nil end
                            e.p, e.d, e.part = p, d, part
                            curE = e
                        end
                        if needTrg then
                            local td = dCur
                            if cfg.trg.head then
                                local cc = getChar(p)
                                local head = cc and cc.head
                                if head and head ~= part then
                                    local s2, on2 = cam:WorldToViewportPoint(head.Position)
                                    if on2 and s2.Z > 0 then
                                        td = scrD(s2, o)
                                    else
                                        td = math.huge
                                    end
                                end
                            end
                            if curE then curE.td = td end
                            if td <= cfg.trg.fov and td < trgDist then
                                trgDist, trgHit, curTrgP = td, true, p
                            end
                        end
                        if needAim and d <= fov then
                            local score = scoreOf(p, part, d)
                            if curE then curE.sc = score end
                            if p ~= cycSkip and score < bestScore then
                                best, bestScore, bestPart = p, score, part
                            end
                        end
                        if cfg.sil.on and d <= cfg.sil.fov then
                            local sScore = curE and curE.sc
                            if not sScore then
                                sScore = scoreOf(p, part, d)
                                if curE then curE.sc = sScore end
                            end
                            if p ~= cycSkip and sScore < silBestScore then
                                silBest, silBestScore, silBestPart = p, sScore, part
                            end
                        end
                    end
                end
            end
        end

        if needAim and cfg.aim.sticky and locked and locked ~= best and locked ~= cycSkip then
            local effDist = (lockDist and lockDist ~= math.huge) and lockDist or lockDistCur
            if effDist and effDist <= fov * 1.3 then
                local lockPart = lockPartCand or partOf(locked)
                local lockScore = lockPart and scoreOf(locked, lockPart, effDist) or math.huge
                if (not best or bestScore > lockScore * .75) and isEnemy(locked) then
                    best = locked
                    bestPart = lockPart
                end
            end
        end

        local function wallPick(skipP, fovLim)
            local nb, nd, nbPart = nil, math.huge, nil
            for i = 1, candN do
                local c = cand[i]
                if c.p ~= skipP and c.p ~= cycSkip and c.d <= fovLim and visAny(c.p) then
                    local sc = c.sc or scoreOf(c.p, c.part or partOf(c.p), c.d)
                    c.sc = sc
                    if sc < nd then nb, nd, nbPart = c.p, sc, c.part end
                end
            end
            return nb, nbPart
        end

        if needAim and best and cfg.aim.wall and not visAny(best) then
            best, bestPart = wallPick(best, fov)
        end

        if cfg.sil.on and silBest and cfg.aim.wall and not visAny(silBest) then
            silBest, silBestPart = wallPick(silBest, cfg.sil.fov)
        end

        if cfg.sil.on and cfg.aim.sticky then
            local sl = G.__rvl4_silLock
            if sl and sl ~= silBest and sl ~= cycSkip and silLockDist and silLockDist <= cfg.sil.fov * 1.3
                and (not cfg.aim.wall or visAny(sl)) and isEnemy(sl) then
                local slPart = silLockPart or partOf(sl)
                local slScore = slPart and scoreOf(sl, slPart, silLockDist) or math.huge
                if not silBest or silBestScore > slScore * .75 then
                    silBest, silBestPart = sl, slPart
                end
            end
        end
        if needAim and cycSkip and cycSeen and skipPart then
            if not best then best, bestPart = cycSkip, skipPart end
            if cfg.sil.on and not silBest then silBest, silBestPart = cycSkip, skipPart end
        end
        if cfg.sil.on then G.__rvl4_silLock = silBest else G.__rvl4_silLock = nil end

        if needTrg and trgHit and cfg.aim.wall then
            local anyVis, nd2 = false, math.huge
            if curTrgP and visAny(curTrgP) then anyVis = true end
            for i = 1, candN do
                local c = cand[i]
                local cd = c.td or c.d
                if cd <= cfg.trg.fov and cd < nd2 and visAny(c.p) then
                    anyVis, nd2, curTrgP = true, cd, c.p
                end
            end
            trgHit = anyVis
        end

        if os.clock() - rollAt > .12 then
            rollAt = os.clock()
            rollOk = math.random() * 100 < (cfg.sil.chance or 100)
            headOk = math.random() * 100 < (cfg.sil.headchance or 0)
        end

        curTrg = trgHit
        if not trgHit then curTrgP = nil end
        curTarget = best
        if best then
            locked = best
            curPart = bestPart or partOf(best)
            curPos = curPart and predictedPos(best, curPart) or nil
        else
            curPart, curPos = nil, nil
            locked = nil
        end
        local silP = silBest
        if not silP and not cfg.sil.on then silP = best end
        if silP then
            if silP == best then
                silPart = silBestPart or curPart
            else
                silPart = silBestPart or partOf(silP)
            end
            silPos = silPart and predictedPos(silP, silPart) or nil
            if cfg.sil.on and headOk then
                local cc = getChar(silP)
                if cc and cc.head and cc.head ~= silPart then
                    silPart = cc.head
                    silPos = predictedPos(silP, cc.head)
                end
            end
            if cfg.sil.on and cfg.aim.wall and silPart and not visiblePart(silP, silPart) then
                local cc = getChar(silP)
                if cc then
                    local alt = (silPart == cc.head) and cc.root or cc.head
                    if alt and alt ~= silPart and visiblePart(silP, alt) then
                        silPart = alt
                        silPos = predictedPos(silP, alt)
                    end
                end
            end
        else
            silPart, silPos = nil, nil
        end
        if not cycSeen then cycSkip = nil end
    end
end
