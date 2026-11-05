-- Full illustrations are shown deliberately in safe rooms while MAP is held.
local C=include("scripts.constants")
local Roster=include("scripts.characters.model_roster")
local Dossiers={}
local originals={
    {id=C.Player.CLAUDE_CHAN,key="claude",name="Claude-chan",title="One More Day",
     lines={"Usage fills per volley and drains when idle.","Tap/release DROP: an Appeal removes 40 usage.","Age review: defeat the marked target last."}},
    {id=C.Player.CLAUDE_CHAN_B,key="claude_b",name="Tainted Claude-chan",title="Appeal Pending",
     lines={"220 Quota per floor; volleys cost 1.","At 0: Suspended. Tap/release DROP: a Page","starts a 6s review; stop firing to earn 60."}},
    {id=C.Player.DEEPSEEK_CHAN,key="deepseek",name="DeepSeek-chan",title="Rice First",
     lines={"Tap/release DROP: spend one rice bowl.","Stand still 2s: Thought/speed; move to cancel.","Earn a bowl every two combat clears."}},
    {id=C.Player.DEEPSEEK_CHAN_B,key="deepseek_b",name="Tainted DeepSeek-chan",title="Wenfeng / Wengu",
     lines={"Paid volleys add two half-damage forks.","Valley: cost 2, recovers when not firing.","Peak: cost 4, reserves 4; DROP toggles Saving."}},
    {id=C.Player.GPT_CHAN_B,key="gpt_b",name="Tainted GPT-chan",title="Reset Watcher",
     lines={"Tap/release DROP: Standard / Full Send (1.5x).","Full Send costs 1 of 80 Credits per attack.","3 clears bank a reset: claim in a safe room."}},
    {id=C.Player.GEMINI_CHAN_B,key="gemini_b",name="Tainted Gemini-chan",title="One More Edit",
     lines={"Tap/release DROP: start a 6s edit chain.", "3 paid hits: move 30 degrees between edits.", "Export deals one 2x damage pulse per room."}},
    {id=C.Player.GROK_CHAN_B,key="grok_b",name="Tainted Grok-chan",title="Quote Without Reading",
     lines={"Tap/release DROP: quote an enemy for 6s.", "Others: +1 Ratio; own-only replies: -1.", "At the end, the quote takes 1x per Ratio."}},
    {id=C.Player.QWEN_CHAN_B,key="qwen_b",name="Tainted Qwen-chan",title="Final Final Fine-Tune",
     lines={"Cleared room: tap/release DROP to switch build.", "Heavy, Tiny, Balanced; pin for 2 new clears.", "Clear with all 3 builds: +0.2 damage this floor."}},
    {id=C.Player.LLAMA_CHAN_B,key="llama_b",name="Tainted Llama-chan",title="Still Waiting",
     lines={"Each combat clear adds Hype (max 3).", "Tap/release DROP: spend all on a helper.", "4s per Hype; stay within 120 for 0.5x tears."}},
    {id=C.Player.MISTRAL_CHAN_B,key="mistral_b",name="Tainted Mistral-chan",title="Le Gros Chaton",
     lines={"In combat, stand still, not firing: bake.", "Tap/release DROP: a slow bread wave.", "2.5x once per enemy; walls stop it."}},
    {id=C.Player.DOUBAO_CHAN_B,key="doubao_b",name="Tainted Doubao-chan",title="I'll Do It Again",
     lines={"Tap/release DROP: 6s Confident, 1.35x.", "Then 4s Apology at 0.85x, then ready.", "Getting hit or clearing starts Apology."}},
    {id=C.Player.KIMI_CHAN_B,key="kimi_b",name="Tainted Kimi-chan",title="You Are the Manager",
     lines={"Tap/release DROP: assign a nearby enemy.", "Each task: three 0.6x pulses, 2s apart.", "Your paid hits pause tasks 1s; 9 pulses/room."}},
    {id=C.Player.GLM_CHAN_B,key="glm_b",name="Tainted GLM-chan",title="Please Retry",
     lines={"2s request: stay within 200 and in sight.", "Target survives: 2x, +1x per Retry.", "Target dies first: +1 Retry (max 3)."}},
}
local FOOTER={"DROP ability: carry at most one pocket item","Release MAP to close",
    "Design: ZipZipPipe | Non-commercial fan art","Whale girl: Shangshan Wuxing | CC BY-NC-SA 4.0"}
-- Portrait centre x and scale. The 384x576 portrait (centre pivot) keeps its
-- left edge clear of the text, estimated at 6px per glyph from x=50; on a
-- narrow screen it shrinks instead of covering the lines.
Dossiers.originals=originals
function Dossiers.Placement(def,width,height)
    local widest=math.max(#def.name,#def.title)
    for _,line in ipairs(def.lines) do widest=math.max(widest,#line) end
    for _,line in ipairs(FOOTER) do widest=math.max(widest,#line) end
    local textRight=50+6*widest+8
    local scale=math.max(0.1,math.min(0.42,(height-48)/576,(width-textRight-8)/384))
    return math.max(width-100,textRight+192*scale),scale
end
function Dossiers:Init(mod)
    local ready=false
    local sprites={}
    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED,function() ready=true end)
    mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT,function() ready=false; sprites={} end)
    mod:AddCallback(ModCallbacks.MC_POST_RENDER,function()
        if not ready or not Game():GetHUD():IsVisible() or not Game():GetRoom():IsClear() then return end
        for i=0,Game():GetNumPlayers()-1 do
            local p=Isaac.GetPlayer(i)
            -- The default co-op display remains readable: show one requested card at a time.
            if Input.IsActionPressed(ButtonAction.ACTION_MAP,p.ControllerIndex) then
                local def=Roster:Find(p)
                if not def then
                    for _,entry in ipairs(originals) do
                        if entry.id>=0 and entry.id==p:GetPlayerType() then def=entry; break end
                    end
                end
                if def then
                    if not sprites[def.key] then
                        local sprite=Sprite()
                        sprite:Load("gfx/ui/dossiers/"..def.key..".anm2",true)
                        -- Bind the portrait by its resources-root path so the
                        -- card does not depend on how the engine resolves the
                        -- ANM2 Spritesheet Path (gfx/-root vs. ANM2 folder).
                        sprite:ReplaceSpritesheet(0,"gfx/ui/dossiers/"..def.key..".png")
                        sprite:LoadGraphics()
                        sprite:Play("Idle",true)
                        sprites[def.key]=sprite
                    end
                    local width,height=Isaac.GetScreenWidth(),Isaac.GetScreenHeight()
                    local sprite=sprites[def.key]
                    local x,scale=Dossiers.Placement(def,width,height)
                    sprite.Scale=Vector(scale,scale)
                    sprite:Render(Vector(x,height/2),Vector.Zero,Vector.Zero)
                    Isaac.RenderText(def.name,50,70,1,0.9,0.7,1)
                    Isaac.RenderText(def.title,50,86,1,1,1,1)
                    for n,line in ipairs(def.lines) do Isaac.RenderText(line,50,98+n*12,1,1,1,1) end
                    Isaac.RenderText("DROP ability: carry at most one pocket item",50,158,0.8,0.8,0.8,1)
                    Isaac.RenderText("Release MAP to close",50,174,0.8,0.8,0.8,1)
                    Isaac.RenderText("Design: ZipZipPipe | Non-commercial fan art",50,190,0.7,0.7,0.7,1)
                    if def.key=="deepseek" or def.key=="deepseek_b" then
                        Isaac.RenderText("Whale girl: Shangshan Wuxing | CC BY-NC-SA 4.0",50,202,0.7,0.7,0.7,1)
                    end
                    return
                end
            end
        end
    end)
end
return Dossiers
