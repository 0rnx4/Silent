local repo = "0rnx4/Silent"
local pin = "e108d52e80e2abd50a1a2c6a57f9e6a309a03af4"
local names = { "00_core.lua", "01_teams.lua", "02_targeting.lua", "03_hooks.lua", "04_mainloop.lua", "05_esp.lua", "06_systems.lua", "07_gui_lib.lua", "08_gui_main.lua", "09_boot.lua" }
local sources = {
    "https://raw.githubusercontent.com/" .. repo .. "/" .. pin .. "/modules/",
    "https://cdn.jsdelivr.net/gh/" .. repo .. "@" .. pin .. "/modules/",
}
local function fetch(name)
    for attempt = 1, 3 do
        for _, base in ipairs(sources) do
            local ok, body = pcall(function() return game:HttpGet(base .. name) end)
            if ok and type(body) == "string" and #body > 0 then return body end
        end
        if attempt < 3 then task.wait(.3) end
    end
    return nil
end
local parts, done, failed = {}, 0, nil
for i, name in ipairs(names) do
    task.spawn(function()
        local ok, body = pcall(fetch, name)
        if ok and body then
            parts[i] = body
        else
            failed = failed or name
        end
        done = done + 1
    end)
end
while done < #names do task.wait() end
if failed then error("[Silent] module fetch failed: " .. failed) end
local src = table.concat(parts)
if #src < 100000 then error("[Silent] source too small: " .. #src) end
local fn, err = loadstring(src)
if not fn then error("[Silent] compile failed: " .. tostring(err)) end
fn()
