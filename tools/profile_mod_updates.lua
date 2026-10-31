-- Full main.lua update workloads with supplied engine APIs; not an FPS benchmark.
-- Usage: texlua tools/profile_mod_updates.lua . [frames=300] [scenario] [Gemini override] [Grok override]
-- Use '-' for an omitted override when supplying the later one.
local root=assert(arg[1],"repository root required")
local frames=tonumber(arg[2]) or 300
assert(frames>=30 and frames<=3000 and frames%1==0,"frames must be an integer from 30 to 3000")
local Full=dofile(root.."/tests/lib/full_mod_env.lua")
local scenarios={{name="vanilla",kinds={0},enemies=0}}
for i,name in ipairs(Full.families) do
    scenarios[#scenarios+1]={name=name.."_normal",kinds={100+(i-1)*2},enemies=12}
    scenarios[#scenarios+1]={name=name.."_tainted",kinds={101+(i-1)*2},enemies=12}
end
scenarios[#scenarios+1]={name="four_players",kinds={100,102,111,119},enemies=48}
scenarios[#scenarios+1]={name="preview_solo",kinds={103},enemies=48,preview=true}
scenarios[#scenarios+1]={name="preview_four",kinds={103,107,119,121},enemies=48,preview=true}
scenarios[#scenarios+1]={name="mixed_items_four",kinds={103,107,119,121},enemies=48,preview=true,items=true}
for _,players in ipairs({1,4}) do for _,bullets in ipairs({0,12,96}) do
    local kinds={}; for i=1,players do kinds[i]=0 end
    scenarios[#scenarios+1]={name="wire_"..players.."_"..bullets,kinds=kinds,enemies=48,bullets=bullets}
end end
print("# ".._VERSION.."; instrumented Lua and stand-in allocation, not native CPU/GPU/FPS")
print("scenario,players,enemies,frames,callbacks,player_reads,type_reads,entity_scans,scanned_entries,cache_rebuilds,heap_KiB,cpu_seconds")
local ran=0
for _,s in ipairs(scenarios) do if not arg[3] or arg[3]==s.name then
    local env=Full.New(root,s.kinds,{enemies=s.enemies,
        geminiModule=arg[4]~="-" and arg[4] or nil,grokModule=arg[5]~="-" and arg[5] or nil})
    env.step(10)
    if s.bullets then
        local owner=env.npc(1000)
        for i,p in ipairs(env.players) do
            p.Position=Vector((i-1)*150,0); p.items[env.Item.LIVE_WIRE]=1; p:EvaluateItems()
        end
        for i=1,s.bullets do env.bullet((i%#env.players)*150,0,owner) end
        env.step(5) -- Settle transitions before measuring steady-state queries.
    end
    if s.items then env.allItems() end
    if s.preview then env.preview() end
    if s.items then
        for _,p in ipairs(env.players) do env.buttons[p.ControllerIndex]=true end
        env.step()
        for _,p in ipairs(env.players) do env.buttons[p.ControllerIndex]=false end
        env.step()
    end
    env.resetMetrics()
    collectgarbage("collect"); collectgarbage("stop")
    local before,started=collectgarbage("count"),os.clock()
    env.step(frames)
    local seconds,allocated=os.clock()-started,collectgarbage("count")-before
    collectgarbage("restart")
    local m=env.metrics
    print(string.format("%s,%d,%d,%d,%d,%d,%d,%d,%d,%d,%.3f,%.6f",s.name,#s.kinds,s.enemies,frames,
        m.callbacks or 0,m.playerReads or 0,m.typeReads or 0,m.scans or 0,m.scannedEntries or 0,
        m.cacheRebuilds or 0,allocated,seconds))
    local sources={}
    for key in pairs(m) do if key:sub(1,5)=="scan:" then sources[#sources+1]=key end end
    table.sort(sources)
    for _,key in ipairs(sources) do print("# "..s.name.." "..key.."="..m[key]) end
    ran=ran+1
end end
assert(ran>0,"unknown scenario")
