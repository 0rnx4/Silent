local lastStat, lastHp, hitAt = "", nil, 0
local lastXhCol = nil
local lastTgt = nil
local fpsSm, fpsAt = 0, 0
local dotAt = 0
G.__rvl4_playSnd = function(kill)
    pcall(function()
        local id = tostring(cfg.combat.hsndId or ""):gsub("%D", "")
        local want = id ~= "" and ("rbxassetid://" .. id) or "rbxasset://sounds/electronicpingshort.wav"
        local snd = G.__rvl4_hsnd
        if not snd or not snd.Parent or snd.SoundId ~= want then
            if snd then pcall(function() snd:Destroy() end) end
            snd = Instance.new("Sound")
            snd.SoundId = want
            snd.Parent = game:GetService("SoundService")
            G.__rvl4_hsnd = snd
        end
        local vol = math.clamp(cfg.combat.hsndVol or .5, .05, 1)
        if kill then vol = math.min(1, vol * 1.25) end
        snd.Volume = vol
        snd.PlaybackSpeed = kill and .65 or 1
        snd.TimePosition = 0
        snd:Play()
    end)
end
bind(run.RenderStepped, function(dt)
    if not alive() then return end
    if G.__rvl4_guiBuilds ~= G.__rvl4_seenBuild then
        G.__rvl4_seenBuild = G.__rvl4_guiBuilds
        lastStat, lastHp = nil, nil
        G.__rvl4_xhGeo = nil
        lastXhCol = nil
    end
    if dt and dt > 0 then
        local fr = 1 / dt
        fpsSm = fpsSm == 0 and fr or fpsSm + (fr - fpsSm) * .05
        if fpsTx and os.clock() - fpsAt > .5 then
            fpsAt = os.clock()
            fpsTx.Text = math.floor(fpsSm + .5) .. " FPS"
        end
        if statDot and os.clock() - dotAt > .1 then
            dotAt = os.clock()
            statDot.BackgroundTransparency = curTarget and (.3 + .5 * math.abs(math.sin(os.clock() * 5))) or 0
        end
    end
    local cc = curTarget and getChar(curTarget) or nil
    if cc and cc.hum then
        local hp = cc.hum.Health
        if lastTgt == curTarget and lastHp and hp < lastHp then
            hitAt = os.clock()
            if hp <= 0 and cfg.combat.ksnd then
                G.__rvl4_playSnd(true)
            elseif cfg.combat.hsnd then
                G.__rvl4_playSnd(false)
            end
        end
        lastHp = hp
        lastTgt = curTarget
    else
        lastHp = nil
        lastTgt = nil
    end
    local s = curTarget and "ロック中" or "待機中"
    if statTx and s ~= lastStat then
        lastStat = s
        statTx.Text = s
        if statDot then statDot.BackgroundColor3 = curTarget and C.warn or C.faint end
    end
    local xhOn = cfg.xhair.on and not G.__rvl4_guiopen
    if xhair and xhair.Visible ~= xhOn then xhair.Visible = xhOn end
    if xhair and xhParts then
        local xg = cfg.xhair.size * 10000 + cfg.xhair.gap * 100 + cfg.xhair.thick
        if xg ~= G.__rvl4_xhGeo then
            G.__rvl4_xhGeo = xg
            local sz2, gp2, th2 = cfg.xhair.size, cfg.xhair.gap, cfg.xhair.thick
            local spec2 = { { th2 * 2, th2 * 2, 0, 0 }, { th2, sz2, 0, -gp2 }, { th2, sz2, 0, gp2 }, { sz2, th2, -gp2, 0 }, { sz2, th2, gp2, 0 } }
            for i2, p2 in ipairs(xhParts) do
                local s3 = spec2[i2]
                if s3 then
                    p2.Size = UDim2.new(0, s3[1], 0, s3[2])
                    p2.Position = UDim2.new(.5, s3[3], .5, s3[4])
                end
            end
        end
    end
    if xhOn and xhParts then
        local col = (os.clock() - hitAt < .09) and C.warn or C.accent
        if col ~= lastXhCol then
            lastXhCol = col
            for _, f in ipairs(xhParts) do f.BackgroundColor3 = col end
        end
    end
end)

if not pcall(applyQot) then G.__rvl4_errPush("boot: qot apply failed") end
if cfg.fly.on and not pcall(function() setFly(true) end) then G.__rvl4_errPush("boot: fly apply failed") end
if not pcall(applyVis) then G.__rvl4_errPush("boot: vis apply failed") end
if not pcall(applyFps) then G.__rvl4_errPush("boot: fps apply failed") end
if not pcall(thirdTick) then G.__rvl4_errPush("boot: third apply failed") end
G.__rvl4_chunkDone = true
task.delay(6, function()
    if alive() then
            stage("ok")
        pcall(function()
            if writefile then writefile("rvl_boot.txt", "ok") end
        end)
    end
end)
