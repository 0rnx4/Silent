G.__rvl4_spawnTtl = 900
G.__rvl4_spawnRad = 45
local spawnPos = {}
local spawnAt = {}
do
    local function recordSpawn(plr)
        local c = plr.Character
        if not c then return end
        task.delay(.15, function()
            if not alive() or plr.Character ~= c then return end
            local r = c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso")
            if not (r and r.Parent) then return end
            local first = r.Position
            spawnPos[plr] = first
            spawnAt[plr] = os.clock()
            task.delay(.7, function()
                if not alive() or plr.Character ~= c then return end
                local r2 = c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso")
                if r2 and r2.Parent and (r2.Position - first).Magnitude > 60 then
                    spawnPos[plr] = r2.Position
                    spawnAt[plr] = os.clock()
                end
            end)
        end)
    end
    local watchConns = {}
    local function watchPlayer(plr)
        if watchConns[plr] then return end
        watchConns[plr] = bind(plr.CharacterAdded, function()
            spawnPos[plr] = nil
            spawnAt[plr] = nil
            recordSpawn(plr)
        end)
    end
    bind(plrs.PlayerAdded, function(p)
        plistAt = 0
        watchPlayer(p)
    end)
    bind(plrs.PlayerRemoving, function(p)
        local cn = watchConns[p]
        if cn then
            watchConns[p] = nil
            pcall(function() cn:Disconnect() end)
            local ca = G.__rvl4_conns
            if ca then
                for i = #ca, 1, -1 do
                    if ca[i] == cn then table.remove(ca, i) break end
                end
            end
        end
        spawnPos[p] = nil
        spawnAt[p] = nil
        plistAt = 0
    end)
    for _, p in ipairs(plrs:GetPlayers()) do watchPlayer(p) end
end

do
    local lastPos = {}
    local jumpHist = {}
    bind(plrs.PlayerRemoving, function(p) lastPos[p] = nil end)
    local function jumpTick()
        local jumps = {}
        for _, p in ipairs(getPlist()) do
            local cc = getChar(p)
            local r = cc and cc.root
            if r then
                local prev = lastPos[p]
                if prev then
                    local dj = r.Position - prev
                    local dxz = math.sqrt(dj.X * dj.X + dj.Z * dj.Z)
                    if dj.Magnitude > 60 and (dxz > 40 or dj.Y > -30) then
                        jumps[#jumps + 1] = p
                    end
                end
                lastPos[p] = r.Position
            else
                lastPos[p] = nil
            end
        end
        if #jumps > 0 then
            local nowJ = os.clock()
            for _, p in ipairs(jumps) do jumpHist[#jumpHist + 1] = { p = p, t = nowJ } end
            for i = #jumpHist, 1, -1 do
                if nowJ - jumpHist[i].t > 1.2 or not jumpHist[i].p.Parent then table.remove(jumpHist, i) end
            end
            local seenJ, massN = {}, 0
            for _, e in ipairs(jumpHist) do
                if not seenJ[e.p] then seenJ[e.p] = true massN = massN + 1 end
            end
            local mass = massN >= 2
            local todoJ = {}
            if mass then
                for _, e in ipairs(jumpHist) do todoJ[e.p] = true end
                jumpHist = {}
            else
                for _, p in ipairs(jumps) do todoJ[p] = true end
            end
            for p in pairs(todoJ) do
                if (mass or p ~= lp) and (mass or not spawnPos[p]) then
                    local cc = getChar(p)
                    if cc and cc.root then
                        spawnPos[p] = cc.root.Position
                        spawnAt[p] = os.clock()
                    end
                end
            end
        end
    end
    task.spawn(function()
        while alive() do
            task.wait(.3)
            if not alive() then break end
            local okJ, errJ = pcall(jumpTick)
            if not okJ then G.__rvl4_errPush("jump: " .. string.sub(tostring(errJ), 1, 50)) end
        end
    end)
end

local teamActive, teamsInUse
do
    local cActive, cInUse, cColor, cAt = false, false, false, 0
    local function scanTeams()
        local now = os.clock()
        if now - cAt < .15 then return end
        cAt = now
        cActive, cInUse, cColor = false, false, false
        local mine = lp.Team
        local myCol = lp.TeamColor
        if mine then cInUse = true end
        for _, p in ipairs(getPlist()) do
            if p ~= lp then
                if p.Team then
                    cInUse = true
                    if mine and p.Team ~= mine then cActive = true end
                end
                if myCol and p.TeamColor and p.TeamColor ~= myCol and (mine or p.Team) then
                    cColor = true
                end
            end
        end
    end
    function teamActive() scanTeams() return cActive or cColor end
    function teamsInUse() scanTeams() return cInUse end
end

local spawnGuardOk, spawnGuardAt = false, 0
local function spawnSide(p)
    local mine, theirs = spawnPos[lp], spawnPos[p]
    if not theirs then return nil end
    local now = os.clock()
    if not mine or now - (spawnAt[lp] or 0) > G.__rvl4_spawnTtl then
        local ccL = getChar(lp)
        if not (ccL and ccL.root) then return nil end
        mine = ccL.root.Position
    end
    if now - (spawnAt[p] or 0) > G.__rvl4_spawnTtl then return nil end
    if now - spawnGuardAt > .5 or not G.__rvl4_guardMine or (mine - G.__rvl4_guardMine).Magnitude > G.__rvl4_spawnRad then
        spawnGuardAt = now
        G.__rvl4_guardMine = mine
        local near, far = false, false
        for _, q in ipairs(getPlist()) do
            if q ~= lp and spawnPos[q] and now - (spawnAt[q] or 0) <= G.__rvl4_spawnTtl then
                local qd = (spawnPos[q] - mine).Magnitude
                if qd < G.__rvl4_spawnRad then near = true elseif qd >= G.__rvl4_spawnRad * 2 then far = true end
            end
        end
        spawnGuardOk = near and far
    end
    if not spawnGuardOk then return nil end
    return (mine - theirs).Magnitude < G.__rvl4_spawnRad and "friend" or "enemy"
end

local function classify(p)
    if p == lp then return "friend" end
    local ccM = getChar(p)
    if ccM and ccM._cf == frameId then return ccM._cv end
    local res
    if cfg.misc.teammode == "全員敵" then
        res = "enemy"
    else
        local mt, tt = lp.Team, p.Team
        if mt and tt then
            if mt == tt then
                res = "friend"
            else
                res = "enemy"
            end
        elseif mt and teamActive() then
            local mc, tc = lp.TeamColor, p.TeamColor
            if mc and tc then res = mc == tc and "friend" or "enemy" end
        end
        if not res then res = spawnSide(p) or "enemy" end
    end
    if ccM then ccM._cf, ccM._cv = frameId, res end
    return res
end

local function isEnemy(p)
    if p == lp then return false end
    local cc = getChar(p)
    if not cc or not cc.hum or cc.hum.Health <= 0 then return false end
    if cfg.aim.team and classify(p) == "friend" then return false end
    return true
end

local function isFoe(p)
    if p == lp then return false end
    local cc = getChar(p)
    if not cc or not cc.hum or cc.hum.Health <= 0 then return false end
    if cfg.esp.team and classify(p) == "friend" then return false end
    return true
end

local function isFoeLoose(p)
    if p == lp then return false end
    local cc = getChar(p)
    if not cc then return false end
    if cc.hum and cc.hum.Health <= 0 then return false end
    if cfg.esp.team and classify(p) == "friend" then return false end
    return true
end

local function teamBasis()
    if cfg.misc.teammode == "全員敵" then return "全員敵（手動）" end
    if teamsInUse() then return "チーム" end
    if teamActive() then return "チームカラー" end
    if spawnPos[lp] then return "スポーン位置" end
    return "FFA"
end
