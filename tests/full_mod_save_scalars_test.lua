-- Actual main/module loading with damaged core fields and intact owner maps.
-- The detached table codec is not the game's JSON parser or native Continue.
local root=assert(arg[1])
local Full=dofile(root.."/tests/lib/full_mod_env.lua")
local defaults={risk=0,ip="0.0.0.0",sharedUsers=0,silentMult=1,
    residentialApplied=false,relayApplied=false,constitutionApplied=false,constitutionBlockUsed=false}
local good={risk=47,ip="12.34.56.78",sharedUsers=137,silentMult=1.17,
    residentialApplied=true,relayApplied=true,constitutionApplied=true,constitutionBlockUsed=true}
local function copy(t)
    if type(t)~="table" then return t end
    local r={}; for k,v in pairs(t) do r[k]=copy(v) end; return r
end
local function same(a,b,label)
    assert(type(a)==type(b),label.." type")
    if type(a)~="table" then assert(a==b,label); return end
    for k,v in pairs(a) do same(v,b[k],label.."/"..tostring(k)) end
    for k in pairs(b) do assert(a[k]~=nil,label.." extra key "..tostring(k)) end
end
local function load(e,payload)
    e.mod.saved=require("json").encode(payload)
    e.Risk:Load(e.mod)
    return e.Risk.state
end
local function hit(e,p)
    -- Supply the base Entity API for these player/enemy damage stand-ins.
    function p:IsEnemy() return false end
    local enemy=e.npc(900)
    function enemy:IsEnemy() return true end
    return e.fire("MC_ENTITY_TAKE_DMG",EntityType.ENTITY_PLAYER,p,1,0,EntityRef(enemy),0)
end

if not arg[2] or arg[2]=="fields" then
    local e=Full.New(root,{100})
    local bad={
        risk={"47",false,{},-1,101,47.5},
        ip={false,{},17,"","1.2.3","1.2.3.4.5","256.2.3.4","-1.2.3.4","1.2.3.4\n","1234.2.3.4"},
        sharedUsers={"12",false,{},-1,221,12.5},
        silentMult={"1.1",false,{},0,-1,0.79,1.31},
        residentialApplied={"false",0,1,{}},relayApplied={"true",0,1,{}},
        constitutionApplied={"true",0,1,{}},constitutionBlockUsed={"false",0,1,{}},
    }
    local checks=0
    for field,values in pairs(bad) do
        for _,value in ipairs(values) do
            local payload=copy(good); payload[field]=value
            payload.extensionState={version=3,players={["0"]={value=19}}}
            payload.accountAge=4
            local state=load(e,payload)
            assert(state[field]==defaults[field],field.." must use its safe default")
            for other,want in pairs(good) do
                if other~=field then assert(state[other]==want,field.." cannot reset valid "..other) end
            end
            same(state.extensionState,payload.extensionState,"unrelated module retained")
            assert(state.accountAge==4,"legacy character migration field retained")
            e.fire("MC_POST_RENDER")
            checks=checks+1
        end
    end
    for _,payload in ipairs({{},false,17,"old text"}) do
        same(load(e,payload),defaults,"missing/non-table core")
    end
    for _,payload in ipairs({good,
        {risk=0,ip="0.0.0.0",sharedUsers=0,silentMult=0.8},
        {risk=100,ip="255.255.255.255",sharedUsers=220,silentMult=1.3}}) do
        local state=load(e,payload)
        for field,value in pairs(payload) do assert(state[field]==value,"valid boundary "..field) end
    end
    -- Parser failure and non-finite return values are supplied fault cases,
    -- not values claimed to round-trip through the real game's JSON library.
    local codec=require("json"); local decode=codec.decode
    codec.decode=function() error("supplied decode failure") end
    e.Risk:Load(e.mod); same(e.Risk.state,defaults,"invalid JSON fallback")
    for _,field in ipairs({"risk","sharedUsers","silentMult"}) do
        for _,value in ipairs({0/0,math.huge,-math.huge}) do
            codec.decode=function() local payload=copy(good);payload[field]=value;return payload end
            e.Risk:Load(e.mod)
            assert(e.Risk.state[field]==defaults[field],"non-finite "..field)
        end
    end
    codec.decode=decode
    print("PASS save core: "..checks.." isolated invalid fields, boundaries, legacy extras and decode faults")
end

if not arg[2] or arg[2]=="continue" then
    for kind=100,121 do
        local seed=Full.New(root,{kind}); seed.step(2)
        local p=seed.players[1]
        p.items[seed.Item.SILENT_UPDATE]=1
        p.items[seed.Item.CONSTITUTION]=1
        seed.step()
        assert(hit(seed,p)==false)
        local saved=seed.saveSnapshot()
        saved.risk="broken";saved.ip={bad=true};saved.sharedUsers={};saved.silentMult={}
        saved.extensionState={version=3,marker="keep me"}
        -- Preserve all valid per-form maps and item consumption on Continue.
        local resumed=Full.New(root,{kind},{snapshot=saved,inventory={p.items},identityBase=30000+kind})
        for field,value in pairs(saved) do
            if defaults[field]==nil then same(resumed.Risk.state[field],value,"continued module "..field) end
        end
        local q=resumed.players[1];q.reward=0
        function q:AddSoulHearts(n) self.reward=self.reward+n end
        resumed.step(2)
        q:AddCacheFlags(CacheFlag.CACHE_DAMAGE);q:EvaluateItems()
        assert(q.Damage==q.Damage and q.Damage>0 and q.Damage<math.huge,"finite continued damage")
        assert(q.reward==0,"valid Constitution pickup bit cannot be erased")
        assert(hit(resumed,q)~=false,
            "valid spent Constitution shield cannot be rearmed by core repair")
        local risk=resumed.Risk:Get()
        resumed.Risk:Add(7)
        if kind==100 or kind==101 then assert(resumed.Risk:Get()==risk+7,"Claude retains Risk")
        else assert(resumed.Risk:Get()==0,"core repair cannot enable non-Claude Risk") end
        local roundtrip=resumed.saveSnapshot()
        same(roundtrip.extensionState,saved.extensionState,"extension after re-save")
        assert(type(roundtrip.risk)=="number" and roundtrip.silentMult==1,"re-save repaired core")
    end
    print("PASS save core: 22-form Continue/update/render/cache/re-save with intact module maps and spent shields")
end

if not arg[2] or arg[2]=="legacy" then
    local e=Full.New(root,{100},{snapshot={risk=35,accountAge=3,
        constitutionApplied=true,constitutionBlockUsed=true}})
    e.players[1].items[e.Item.CONSTITUTION]=1
    local reward=0
    local p=e.players[1]
    function p:AddSoulHearts(n) reward=reward+n end
    e.step()
    assert(reward==0,"legacy applied bit must reach Constitution migration")
    assert(hit(e,e.players[1])~=false,
        "legacy used bit must reach Constitution migration")
    assert(e.Risk.state.claudeUsage["0"].age==3,"legacy account age must reach Claude migration")
    assert(e.Risk:Get()==36,"legacy risk retained before the ordinary damage update")
    print("PASS save core: valid legacy Constitution and Claude fields migrate through real startup")
end
