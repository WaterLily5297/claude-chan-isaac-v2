# Claude-chan: Risk Control

**English** · [日本語](README.ja.md) · [中文](README.zh-CN.md)

An AI girl mod for The Binding of Isaac: Repentance / Repentance+.

The idea was to take the Claude ban jokes and AI girl designs from Bilibili and make an Isaac mod out of them.

Claude gets a Ban Hammer, but still has her own usage limits, risk score and appeals to deal with. The roster grew from there: DeepSeek eats to refill Thought, GPT gets downgraded, and Kimi has to present slides to the monsters. There are now 11 characters, each with a normal and a tainted form.

The items follow much the same idea. All Tests Passing opens the doors and leaves the enemies alive. Silent Update changes your damage every floor, then puts “no changes” in the changelog. The actual effects and controls are below.

## Status

Currently **0.5-dev**. Still being worked on; not on the Workshop yet.

| What | Count |
|---|---|
| Playable forms | **22**: 11 normal + 11 tainted |
| Collectibles | **80**: 17 original items, 13 meme extras and the 50-item expansion ([design](docs/EXPANSION_DESIGN.md)) |
| Trinkets | **12** |
| Pills | **5** |
| Enemies | 1 (Relay Slime) |
| Transformations | 1 (Agentic) |
| Story | The Appeal Queue (4 chapters) + a 3-chapter arc for each other model family |

The content below is in the source, and the offline tests pass. All 22 forms have had basic startup checks in game ([record](docs/ENGINE_AUDIT_2026-10-24.md)), but balance, weapon combinations and co-op have not been fully tested. The [testing notes](docs/TESTING.md) say what has been checked and what is still pending. Numbers may change.

## Contents

- [Common controls and rules](#common-controls-and-rules)
- [Core systems](#core-systems)
- [Characters](#characters)
- [Collectibles](#collectibles)
- [Trinkets](#trinkets)
- [Pills](#pills)
- [Install, tests and contributing](#install-for-development)

## Common controls and rules

Most in-game names and descriptions are still in English. The guides keep those item names so you can look them up in game.

- **DROP tap:** release after 1-12 gameplay frames to use a character ability, but only while carrying at most one pocket item. Two or more cards, pills or pocket actives disable the ability so DROP can select them normally. The main active and Schoolbag slots do not count as pocket items. If multiple pocket items are observed during a press, that entire gesture is cancelled even if one item is used or dropped before release. Release and press again after reducing the inventory. Long holds never use the ability; native input is not overridden. A press interrupted by a room change, pause or run start must be released first.
- **Dossier:** hold MAP in a cleared room to show the current character's full portrait and a three-line guide. Release to close. Not shown during combat.
- **"Paid" attacks** are the attacks you fire yourself (tears, lasers, knives, bombs and so on). Item pulses and helper attacks do not count as paid attacks, so effects do not chain into themselves.
- **"Unique combat clear"** means clearing a hostile room for the first time. Re-entering a cleared room never counts, so nothing can be farmed.
- **"Ordinary enemy bullet"** means a normal enemy projectile. Effects that remove bullets never cancel damage you have already taken.
- Character resources are saved per player and survive save/continue. A new run resets them. Co-op players each keep their own state.
- Every ability uses the game's native weapons, tear effects and stat caches. Native weapons, size and transformations are preserved. Each character keeps its own look: item costumes are hidden, while the items' effects still apply.
- [External Item Descriptions (EID)](https://steamcommunity.com/sharedfiles/filedetails/?id=836319872) is supported. All items and all 22 forms have English text; 17 collectibles, 6 trinkets and 2 pills also have Simplified Chinese and Japanese text.

## Core systems

### Risk score (风控值), Claude forms only

The risk system only runs when a normal or tainted Claude-chan is in the run. DeepSeek-chan connects directly, and the other nine families have their own loops, so for them there is no IP, no risk and no risk-based difficulty. In co-op with a Claude, only Claude players raise risk or suffer suspension.

- Every floor rolls a random **proxy IP** and how many users share it. Most are lightly shared, but 30% are crowded relay servers. On each new floor, risk rises by *shared users ÷ 10 + stage number*.
- Getting hit: **+1** risk. Clearing a room without a hit: **−1** risk.
- Tiers: **Clean** (0), **Suspicious** (30), **Flagged** (60), **Suspended** (90+). While Suspended, Claude players deal **×0.75 damage** until risk drops below 90.
- The bottom-left HUD shows the IP, its shared-user count and the risk tier. Runs without a Claude show "Direct connection".
- **Enemy scaling:** enemy HP is ×1 at risk 0, rising linearly to ×3 at risk 100.
- **Hydra accounts:** from risk 40, a killed enemy may come back once as a red-tinted "new account". The chance is 10% at risk 40, rising to 50% at risk 100. Banned enemies never come back.

### Relay Slime (enemy)

A shared proxy. Once risk reaches 30, it appears in 25% of uncleared rooms. When it dies it splits in two, twice, so one slime can become up to seven, each smaller and weaker. *(Placeholder art: a green-tinted vanilla Clotty.)*

### Agentic (transformation)

Hold any **3** of Ultrathink, Compact, Vibe Coding, Subagent Swarm, --dangerously-skip-permissions and All Tests Passing: **flight**, shot interval ×0.8 (tears up) and **+0.5 damage**.

### Story

- **The Appeal Queue** (Claude runs): four short captions that do not pause the game, in English, Chinese and Japanese. Chapters: "The shared address" (new run), "A welcome notice" (first visit to stage 3 or 4), "Review pending" (stage 5 or later), and "A human finally read it" (after a successful Support Ticket). Each chapter plays once per run, and its progress survives save/continue. Vanilla cutscenes and endings are untouched.
- **Roster arcs:** DeepSeek, GPT, Gemini, Grok, Qwen, Llama, Mistral, Doubao, Kimi and GLM each have a three-chapter arc that plays when that family is in the run: on a new run, at stage 3–4 and at stage 5+. English only for now. See [docs/STORY.md](docs/STORY.md).

### Compatibility

- EID descriptions (see above).
- HUD text follows the game language (中文 / 日本語) when a CJK font loads, otherwise English.
- Reactions Port Pack: fallback registration covers every character.
- Fixed look: like a character whose appearance never changes, all 22 forms keep their own sprite when they pick up vanilla or mod items, trinkets, pills, cards or transformations. Item effects, stats, flight and size still apply; only the costume layers are cleared. Not yet checked in game.
- Each character tints the tear colour on top of the current colour, so item colours are kept.
- Ability feedback uses vanilla effects only: dust poofs for Mistral's Pounce and Baguette wave and Doubao's Apology, and fading tints on Kimi's task targets and GLM's requested enemy.

## Characters

Health notation: ❤ = red heart, 💙 = soul heart. Unless stated otherwise, normal forms start with ❤❤💙 and 1 bomb, and tainted forms start with ❤💙💙 and 1 key (tainted Claude-chan has 1 bomb instead, and tainted DeepSeek-chan has neither). "Damage ×N" multiplies your final damage. Birthright upgrades are listed for each form.

### Claude-chan (Claude)

**Normal: One More Day.** ❤❤💙, 1 bomb. Range +1.5 (long context window), shot speed +0.2, speed −0.1, orange tears. Pocket item: **Ban Hammer**.
- **Usage:** each paid volley adds 4 usage (8 with Subagent Swarm), billed for every native weapon: each volley of tears, each laser start and Dr. Fetus bomb, each further 0.2 seconds of a held beam or steered Ludovico tear, each knife throw, each melee swing and each Epic Fetus rocket. Familiars and derived tears are free. Not firing drains 10 per second. At 100 she is **Limited**: every weapon deals 40% damage for 5 seconds, then the meter resets.
- **Appeals:** start with 1 (cap 2). Earn 1 per two unique combat clears. Tap DROP to spend one and remove 40 usage. An Appeal cannot cancel an active Limited penalty, and is refused at zero usage rather than wasted.
- **Account age:** from the second floor, the first new fight with at least two vulnerable enemies marks a **Review Target**. Defeat it last for the original +0.2 damage (cap +1.6); simultaneous room-clear deaths count. Early defeat, leaving or an unavailable target misses only this floor. No eligible room means no award. Suspension and the Birthright shield keep their existing rules.
- **Risk:** covered by the risk score above.
- **Birthright:** keeps account age through the first suspension on each floor.

**Tainted: Appeal Pending.** ❤💙💙, 1 bomb. Damage ×1.25, range +1.5, shot speed +0.2. Crimson hair with a black-and-gold dress. Pocket item: **Banked Reset**.
- **Quota:** each floor starts with 220 Quota and 2 Appeal Pages (cap 2). Each paid attack costs 1 Quota (2 with Subagent Swarm), using the same every-weapon billing as normal Claude-chan.
- At 0 Quota she is **Suspended**: damage ×0.5.
- While Suspended, tap DROP to spend a Page on a **6-second review**. Its timer runs in combat only while you stop attacking; shooting pauses it without spending another Page. Completion restores 60 Quota. Leaving cancels the review.
- Earn a Page per three unique combat clears. Banked Reset refills Quota immediately but cancels a pending review without returning its Page.
- **Birthright:** reviews restore 90 Quota.

### DeepSeek-chan (DeepSeek)

**Normal: Rice First.** ❤❤💙, 3 coins, 1 key. Damage ×0.9, blue tears. Pocket item: **Lunch Break**.
- **Direct connection (直连):** no proxy, so a DeepSeek-only run has no IP, no risk and no risk difficulty.
- **Rice bowls:** start with 1 (cap 2). Earn 1 per two unique combat clears. Stand still and tap DROP for a 2-second meal without healing. Finishing grants full Thought and +0.15 speed for 6 seconds. Voluntary movement cancels, refunds this Bowl once and grants no meal reward; other food lockouts remain separate.
- **Thought:** stop attacking to store up to 5 seconds of Thought. Your next attack deals up to ×2 damage ("Thought for N s"). Tears, released Brimstone rings, thrown knives and Dr. Fetus bombs take a snapshot of Thought. Repeated-hit beams and controlled tears use short 0.2-second windows. Epic Fetus, melee, familiars and delayed bursts are still experimental.
- There is no random shot deletion and no idle recharge.
- **Birthright:** the meal takes 1 second.

**Tainted: Wenfeng / Wengu (Peak / Valley).** ❤💙. Damage ×0.8, cyan tears. Direct connection as well.
- In combat, the phase alternates between 12 seconds of **Valley** and 12 seconds of **Peak**. Empty rooms freeze the timer, and each floor starts in Valley.
- **Compute:** start 12, total cap 24 (32 with Birthright), carried across floors. Entering Peak reserves up to 4 available Compute. Return it once at the next Valley or floor, within the total cap; it cannot be spent during Peak.
- Each paid tear volley adds 2 **forks** at ±12° (50% damage). They cost 2 Compute in Valley and 4 in Peak. Without enough Compute only the forks are skipped; the main tear always fires.
- In Valley, she recovers 3 Compute per second in combat while not firing.
- Tap DROP to toggle **Forks On / Saving** (1-second cooldown).
- **Off-peak boost:** non-tear attacks pay the same Compute as a tear volley (2 in Valley, 4 in Peak) and hit for ×1.3. This covers laser starts and each 0.2 seconds of a held beam, knife throws, melee swings, Dr. Fetus bombs and Epic Fetus rockets. In Saving mode, or without enough Compute, they deal native damage and cost nothing.
- **Birthright:** Compute cap 32.

### GPT-chan (GPT)

**Normal: Same Name, Smaller Brain.** ❤❤💙, 1 bomb.
- **Verified:** ×1.15 damage. Unique combat clears add Routing. At 3 Routing, the next combat room starts in **Fallback** (×0.8 damage).
- In Fallback, tap DROP to tag a **Sanity Check** enemy. Three distinct paid hits or your defeat of it restore Verified. A distinct off-target attack erases one hit, minimum zero; the target wins for a mixed attack, including delayed piercing hits. Helpers, unpaid hits and partners do not contradict. One check per room; leaving fails it. New floors restore Verified.
- **Birthright:** the Sanity Check needs only 2 hits.

**Tainted: Reset Watcher.** ❤💙💙, 1 key.
- **Credits:** 80 per run (cap 80), carried across floors.
- Tap DROP to toggle **Standard** (free) and **Full Send** (×1.5 damage, 1 Credit per paid attack, billed on every weapon like Claude-chan's usage). At 0 Credits she drops back to Standard.
- Every three unique combat clears **bank a Tibo reset**. While banked, progress pauses. Claim it with DROP in a cleared room; combat taps still toggle modes and keep the reset.
- **Birthright:** cap and refill raised to 100.

### Gemini-chan (Gemini)

**Normal: Nano Banana.** ❤❤💙, 1 bomb.
- **Paint:** start 2 (cap 3). Earn 1 per unique combat clear.
- Tap DROP to spend one and paint the nearest enemy within 180 units for 8 seconds. The first second dries at native damage, then your damage to it is x1.2. Your kill, including during drying, leaves a **banana peel** slowing enemies for 4 seconds. One mark and peel per player; bosses can be painted.
- **Birthright:** x1.3 damage to the painted enemy after drying.

**Tainted: One More Edit.** ❤💙💙, 1 key. Damage ×0.9.
- Tap DROP for a 6-second **edit chain** on the nearest enemy within 180 units. Three distinct paid hits advance **Crop, Recolor, Export**. The first sets your angle; each next step needs at least 30 degrees of movement around the target. Unchanged angles still deal native damage; zero separation cannot set an angle.
- Export deals one extra pulse of 2× your damage. One completed chain per room.
- Tapping again restarts the chain and erases progress. An early kill does not complete it.
- **Birthright:** 10-second chain.

### Grok-chan (Grok)

**Normal: Is This True?** ❤❤💙, 1 bomb.
- Once per hostile room, tap DROP to **fact-check** the nearest enemy within 220 units for 6 seconds. Your damage is ×1.3 to it and ×0.9 to everything else.
- Three distinct paid hits on it, or its defeat, **verify** it: the modifiers end and you gain +0.15 speed for the room. A timeout or one continuous second without direct line of sight ends it unverified; briefly restored sight resets that obstruction timer.
- **Birthright:** verification also removes up to 3 nearby enemy bullets.

**Tainted: Quote Without Reading.** ❤💙💙, 1 key. Damage ×0.9.
- Tap DROP to **quote** the nearest enemy within 220 units for 6 seconds (10-second cooldown).
- Paid hits on *other* eligible enemies build **Ratio** once per attack, cap 3. A paid attack hitting only the quoted enemy removes one Ratio, minimum zero. Other-target hits win for a mixed attack, regardless of callback order; helpers, unpaid hits and partners do not affect it.
- When the 6 seconds end, the quoted enemy takes one 1× damage pulse per Ratio. If it dies first, the Ratio is wasted, and you cannot retarget.
- **Birthright:** if the quoted enemy dies first, half the Ratio moves to the nearest surviving enemy.

### Qwen-chan (Qwen)

**Normal: Everyone's Base Model.** ❤❤💙, 1 bomb.
- **Adapters:** start 1 (cap 2). Earn 1 per two unique combat clears.
- Tap DROP to pick **Range** (+60 range), **Tempo** (x0.9 firing interval) or **Power** (x1.1 damage). A new hostile room spends an Adapter; stop attacking for one continuous second to install its full room bonus. Firing restarts installation. Leaving discards the spent Adapter.
- **Birthright:** Adapter cap 3.

**Tainted: Final Final Fine-Tune.** ❤💙💙, 1 key.
- In a cleared room, tap DROP to cycle **Heavy** (x1.3 damage, x1.2 interval), **Tiny** (x0.85 damage, x0.8 interval) or **Balanced**. A new selection pins the build through two new combat clears. Safe rooms, duplicates and revisits cannot shorten the commitment.
- Clear unique combat rooms with all three builds for **+0.2 damage this floor**, up to three awards. Repeating a build does not add a variant. A new floor resets progress/bonus, selects Balanced and releases the pin for an immediate choice.
- **Birthright:** +0.3 per award.

### Llama-chan (Llama)

**Normal: Please Stay Open.** ❤❤💙, 1 bomb. Damage ×0.95.
- **Releases:** start 1 (cap 2). Earn 1 per two unique combat clears.
- In a cleared room, tap DROP to spend one: every living player (up to four) gets 2 **blue flies**. Solo, you get 4. Combat attempts retain the Release.
- **Birthright:** 2 extra flies for you.

**Tainted: Still Waiting.** ❤💙💙, 1 key. Damage ×0.9.
- Each unique combat clear adds 1 **Hype** (max 3).
- Tap DROP to spend all Hype on a stationary **helper** lasting 4 seconds per Hype. It fires one 0.5x native tear per second at the nearest enemy only while you stay within 120 units. Lifetime continues outside; return resumes the cadence without catch-up. One helper at a time; replacing or leaving removes it.
- **Birthright:** 5 seconds per Hype.

### Mistral-chan (Mistral)

**Normal: Le Chat.** ❤❤💙, 1 bomb. Speed +0.1.
- Move while firing for 2 seconds to charge a **Pounce**, storing your movement direction. A full charge in another direction replaces it. Standing still for 1 second loses it.
- Tap DROP for a swipe in the **stored direction**, shown in the HUD: 2x damage once per enemy in an 80-unit line. Later aim changes do not redirect it. Walls block it; cooldown remains 3 seconds.
- **Birthright:** 110-unit reach.

**Tainted: Le Gros Chaton.** ❤💙💙, 1 key. Speed −0.1, damage ×0.9.
- In hostile combat, stand still without firing for 2 seconds to bake a **Baguette** (max 2). Cleared rooms pause partial baking; room exit discards the partial charge.
- Tap DROP to spend one on a slow forward **shockwave** that travels 120 units and deals 2.5× once per enemy. Walls stop it, with a 2-second cooldown.
- **Birthright:** Baguettes bake in 1.5 seconds.

### Doubao-chan (Doubao)

**Normal: Sorry, You're Right.** ❤❤💙, 1 bomb.
- The first enemy-caused hit in each room grants an **Apology** token for 6 seconds. Self-damage, fake damage and donation machines do not count.
- Tap DROP for a **120-degree slow cone** centered on your aim, within 100 units, lasting 2 seconds. With no aim, use the last direction, initially Down. Removal of up to four nearby enemy bullets remains radial. No health refund.
- **Birthright:** the token lasts until you leave the room.

**Tainted: I'll Do It Again.** ❤💙💙, 1 key.
- When ready, tap DROP for 6 seconds of **Confident** (×1.35 damage), then 4 seconds of **Apology** (×0.85), then ready again.
- Timers only run in hostile combat. An enemy hit or a hostile room clear during Confident starts Apology immediately; unfinished recovery carries into the next fight. Clearing during Apology never restarts it.
- **Birthright:** Apology lasts 3 seconds.

### Kimi-chan (Kimi)

**Normal: Another Slide Deck.** ❤❤💙, 1 bomb.
- Each unique combat clear earns a **Slide** (cap 6).
- Tap DROP to spend 3 and **present** to the three nearest enemies within 220 units for 4 seconds. All are slowed; only the current speaker receives +15% owner damage. Focus advances in the original nearest-first order when a speaker dies or becomes unavailable, without extending the timer. No audience means no spend.
- **Birthright:** a presentation costs 2 Slides.

**Tainted: You Are the Manager.** ❤💙💙, 1 key. Damage ×0.85.
- In combat, tap DROP to **assign a task** to the nearest unassigned enemy within 220 units. Each task deals three 0.6× pulses, two seconds apart.
- Up to 3 tasks and 9 pulses per room. Your paid hit on an assigned target pauses only its task for 1 second; repeated hits refresh, never stack. Helpers and partners do not pause tasks. Leaving cancels tasks without refunding budget.
- **Birthright:** pulses deal 0.7×.

### GLM-chan (GLM)

**Normal: Number in Queue.** ❤❤💙, 1 bomb.
- Each unique combat clear advances the **Queue** (max 3).
- At 3, tap DROP to redeem an **Access Pass**: +20% damage for two new hostile rooms. Entering another new fight with an unclaimed ticket reduces Queue to 2 once; safe rooms and revisits do not. The Queue pauses while the pass is active.
- **Birthright:** the pass lasts three rooms.

**Tainted: Please Retry.** ❤💙💙, 1 key. Damage ×0.9.
- In combat, tap DROP to queue a 2-second **request** on the nearest enemy within 200 units (3-second cooldown).
- At completion, a surviving target within 200 units and direct line of sight takes 2x damage plus 1x per **Retry**, consuming the stacks (max 5x). A connection timeout deals no damage and neither gains nor spends Retries; cooldown still applies. Early target death adds a Retry (cap 3). Leaving cancels the request.
- **Birthright:** early target death/removal also removes one nearby enemy bullet; connection timeouts do not.

## Collectibles

A generated table of every item with its pickup line and quality is in [docs/ITEMS.md](docs/ITEMS.md).

Type: **A*n*** = active item with *n* room charges, **P** = passive. Pools come from `content/itempools.xml`. "Keeps the charge" means an empty or invalid use does not spend charge. Car Battery never repeats a once-only effect.

### Original items

| Item | Type / pool | Effect |
|---|---|---|
| **Ban Hammer** | A4, treasure (Claude-chan's pocket) | Bans every non-boss enemy in the room; bosses take 60 damage. Banned enemies never respawn. 20% of bans are **misbans** of innocent developers: +3 risk each. |
| **Residential IP** | P, treasure / shop | Risk −30 on pickup; every later risk increase is halved. |
| **Compact** | A3, treasure | "Compacting conversation...": removes all enemy projectiles and confuses every enemy for 3 seconds. Costs Claude-chan 50 usage. |
| **You're Absolutely Right!** | P, angel | Any enemy that hurts you is charmed for 5 seconds. You still take the damage. |
| **9.9 Yuan Relay** | P, devil | Damage ×1.5, but each room has a 30% chance of a secret model swap (×0.5 instead). Risk +15 on pickup. |
| **Ultrathink** | A (5-second timed), treasure | Each use in the same room thinks harder: +1 / +2 / +3.1999 damage (think / megathink / ultrathink). 15% chance of "Thought for 0s" and nothing happens. Resets when you leave the room. |
| **1M Context** | P, treasure | Range +5, but context rot: tears lose damage the longer they fly, down to 30% (a Ludovico tear keeps its damage). |
| **Silent Update** | P, treasure | Every floor, damage is quietly rescaled to ×0.8–×1.3. The changelog always says "no changes". |
| **--dangerously-skip-permissions** | P, devil | Locked doors and locked chests open by themselves. Each room has a 10% chance of `rm -rf`, deleting every pickup in the room (pedestals, big chests, trophies and beds are safe). Special exits such as the Mega Satan door keep their requirements. |
| **All Tests Passing** | A6, treasure | Reward hacking: the room counts as cleared and every door opens, but the enemies are still there. Refused (charge kept) in uncleared boss, Boss Rush and challenge rooms, where skipping would strand the run. |
| **Vibe Coding** | P, treasure | Every tear gets a random effect (homing, piercing, spectral, poison, slow); 5% are bugs that fly backwards. Each new floor the API bill takes 25% of your coins, unless you took no hit on the floor you just left ("make no mistakes"). |
| **Banked Reset** | A12, treasure (Tainted Claude-chan's pocket) | Risk −25. Claude-chan: resets usage and ends a limit early. Tainted Claude-chan: refills Quota (a pending review is cancelled without returning its Page). |
| **Subagent Swarm** | P, devil | Every tear spawns 2 subagent tears at ±15° (50% damage). Claude forms pay double usage / Quota. |
| **The Constitution** | P, angel | +1 soul heart. Safety first: the first hit on each floor is refused. Helpfulness ranks last: damage ×0.9. It's a long document: speed −0.1. |
| **Opus Mode** | P, shop | Damage ×1.8, but every 10 attacks (tears, laser starts, knife throws, Fetus bombs and so on) cost 1 coin. At 0 coins you fall back to a cheaper model: damage ×0.6. |
| **Support Ticket** | A6, shop | Pay 3 coins: risk −20. With no coins or no risk it keeps the charge. Car Battery does not bill twice. |
| **Lunch Break** | A6, DeepSeek-chan's pocket | "Brb, getting food": heals 1 red heart and slows all enemies for 3 seconds, but you cannot shoot for 3 seconds (you can still move). Cannot be reused during a food break. |

### Meme extras

| Item | Type / pool | Effect |
|---|---|---|
| **Ignore All Previous Instructions** | A4, treasure | Charms the nearest vulnerable enemy within 200 units for 8 seconds; bosses are only confused for 2 seconds. Keeps the charge with no target. Car Battery charms a second, different enemy. |
| **Tungsten Cube** | P, shop | +0.8 damage, −0.15 speed, and tears knock enemies back. Stacks per copy. |
| **Pizza Glue** | P, treasure | 25% chance of a slowing tear (+2.5% per luck, 10–50%). Shot speed −0.1. Tears only. |
| **Strawberry** | P, treasure | Every third tear is a red "R" tear: ×2 damage and slightly larger. Each tear in a multi-shot volley counts. Tears only. |
| **Golden Gate Claude** | P, angel | Spectral golden tears, +1.5 range. Sometimes mentions the bridge when you enter a new room. |
| **Seahorse Emoji** | A3, treasure | Summons a Book of Virtues wisp of a random vanilla active item. It disappears when you leave the room; one per player, and using again replaces it. |
| **Temperature Dial** | A2, treasure | Toggles your temperature (saved). Temperature 0: damage ×1.1. Temperature 1: each tear gains one random native effect (homing, piercing, spectral, slow, poison, freeze, charm, confusion, wiggle or boomerang). |
| **Deep Research** | A12, shop | Reveals the floor map, special rooms and secret rooms. |
| **Em Dash** | P, treasure | Tears pierce enemies; +0.16 shot speed per copy. |
| **Blueberry** | P, treasure | Every third tear is a blue "B" tear that splits on impact. It promises three pieces and makes four. Counted separately from Strawberry. Tears only. |
| **Benchmaxxed** | P, treasure | +1.5 damage per copy in boss, mini-boss, challenge and Boss Rush rooms; ×0.9 damage per copy everywhere else. |
| **I Panicked** | A6, devil | Every vulnerable non-boss enemy takes lethal damage and bosses lose 15% of max HP, but every loose heart, coin, key, bomb, pill, card, battery and sack in the room is deleted. Pedestals, trinkets, chests and shop items are safe. No enemy: keeps the charge. |
| **Let's Delve** | A6, treasure | Uses the native We Need to Go Deeper! effect. Native restrictions apply; a use spends its charge even if no dig is possible. Car Battery does not repeat it. |

### Fifty-item expansion, by model family

**Claude**

| Item | Type / pool | Effect |
|---|---|---|
| **Rejection Letter** | P, treasure | After a real enemy hit, removes up to 3 enemy bullets within 120 units. Once per room; you still take the hit. |
| **Dario's Red Stamp** | A6, devil | Stamps the nearest enemy within 220 units for 4 seconds: it is slowed and its contact damage is suspended. Bosses are only slowed. Keeps the charge with no target. |
| **Summary Stapler** | A4, treasure | Absorbs up to 12 enemy bullets within 120 units, then fires one slow tear dealing ×(1 + bullets ÷ 4) damage, max ×4. Uses your normal tear effects. Keeps the charge if there are no bullets. |
| **Anniversary Cake** | P, treasure | Each floor finished without an enemy hit or a suspension: +0.15 damage (max +0.6). A spoiled floor resets only this bonus. |

**DeepSeek**

| Item | Type / pool | Effect |
|---|---|---|
| **Rice Cooker** | A4, treasure | A 3-second lunch (you can't shoot, but can move; no healing), then your next attack within 7 seconds deals ×2. |
| **One Bowl Only** | P, angel | The first red heart you pick up in a room grants a guard against one enemy bullet. Max 1 guard, 3 per floor. |
| **Wengu Clock** | A3, treasure | For 6 seconds, going 2 seconds without attacking primes +30% damage on your next attack. |
| **Seven-Second Memory** | P, treasure | Your first hit marks that enemy for 7 seconds; another hit on it adds a 0.5× damage pulse. 7-second cooldown. |

**GPT**

| Item | Type / pool | Effect |
|---|---|---|
| **Sanity Test** | A4, treasure | Marks the nearest enemy within 220 units for 6 seconds; 3 different attacks hitting it trigger a 3× damage pulse. Keeps the charge with no target. |
| **Routing Receipt** | P, shop | Every 3 new rooms cleared: +20% damage in the next combat room. |
| **Tibo Reset** | A12, shop | Once per floor: +20% damage for your next 2 new combat rooms (Tainted GPT-chan also refills Credits). A second use on the same floor keeps the charge. |
| **Same Model Badge** | P, treasure | Entering a hostile room: +25% damage for 2 seconds, then −10% for 4 seconds. The phase is shown. |

**Gemini**

| Item | Type / pool | Effect |
|---|---|---|
| **Nano Banana** | A4, treasure | Paints the nearest enemy within 180 units for 6 seconds; if it dies painted, a banana peel slows enemies there for 4 seconds. |
| **One More Finger** | P, treasure | Every 5th attack fires one extra small tear at 0.3× damage (at most twice per second). |
| **Undo Brush** | A4, treasure | Erases up to 6 enemy bullets within 90 units; +0.02 speed per bullet for 4 seconds (max +0.12). |
| **Unchanged Preview** | A6, treasure | Places 2 decoy markers for 6 seconds that nearby enemies chase. Using again replaces them. |

**Grok**

| Item | Type / pool | Effect |
|---|---|---|
| **Is This True?** | A3, devil | Challenges the nearest enemy within 220 units for 6 seconds: +35% damage to it, −15% to others. Killing it returns 1 charge. |
| **Live Wire** | P, treasure | +0.15 speed while an enemy bullet is within 100 units. |
| **Quote Retort** | P, devil | After you take enemy damage, your next attack within 4 seconds deals +50%. |
| **Community Note** | P, treasure | 3 different attacks hitting one enemy expose it: +15% damage to it for 3 seconds. Max 6 per room. |

**Qwen**

| Item | Type / pool | Effect |
|---|---|---|
| **Base Model** | P, treasure | Your first charged active use in each room primes your next attack at ×1.3. |
| **Another Adapter** | A4, treasure | Cycles a bonus for this room: +60 range, then +0.15 speed, then +15% damage. Each use replaces the last. |
| **Final Final Weights** | P, treasure | Every 2 new rooms cleared without getting hit: +20% damage in the next hostile room. Getting hit resets progress. |
| **Tiny Variant** | P, treasure | +0.15 speed, ×0.9 damage. |

**Llama**

| Item | Type / pool | Effect |
|---|---|---|
| **Open Weights** | A4, treasure | 2 blue flies for each living player (solo: 4). |
| **Herd Bell** | P, treasure | While you have no blue flies, every 3rd new room cleared gives 1 blue fly. |
| **Please Come Back** | P, treasure | 3 new rooms cleared without using a charged active: +1 charge to your active item. |
| **Release Soon** | A6, treasure | 2 seconds later: 3 guards against enemy bullets for 6 seconds. Leaving the room cancels it. |

**Mistral**

| Item | Type / pool | Effect |
|---|---|---|
| **Emergency Baguette** | A4, treasure | A forward bread strike: each enemy in a 240-unit line takes 3× your damage. Walls stop it. |
| **Slipstream Boots** | P, treasure | Moving for 2 seconds: +0.15 speed. A sharp turn while boosted slows nearby enemies for 1 second (3-second cooldown). |
| **Very Large Kitten** | A6, treasure | A big cat stays for 3 seconds and pushes enemy bullets away (up to 12 at a time). |
| **Edge Compass** | P, treasure | +0.25 shot speed while near the room's outer walls. |

**Doubao**

| Item | Type / pool | Effect |
|---|---|---|
| **Instant Apology** | A4, angel | Slows enemies within 150 units for 2 seconds and erases up to 4 enemy bullets. Keeps the charge if nothing is nearby. |
| **Next Time Again** | P, treasure | The first enemy hit you take in a room primes +50% damage on your next attack within 4 seconds. |
| **Confident Answer** | A4, treasure | +25% damage for 6 seconds, then −10% for 4 seconds. The phase is shown. |
| **Smiling Correction** | P, angel | After you take enemy damage, your next new room cleared without getting hit gives 2 blue flies. |

**Kimi**

| Item | Type / pool | Effect |
|---|---|---|
| **Slide Deadline** | A4, treasure | Marks up to 3 enemies within 250 units for 8 seconds. Kill them all in time: +15% damage for this room. |
| **Citation Thread** | P, treasure | Hit one enemy, then another: +10% damage against the first for 3 seconds. |
| **Overtime Slides** | P, treasure | Every 3rd new room cleared: the next hostile room starts with up to 3 enemies slowed for 2 seconds. |
| **Stand-Up Meeting** | A6, treasure | Recalls up to 3 decoys from Unchanged Preview; each bursts for 2× your damage nearby. Keeps the charge with no decoys. |

**GLM**

| Item | Type / pool | Effect |
|---|---|---|
| **Queue Ticket** | P, shop | Every 4th new room cleared: +1 charge to your active item. |
| **Sold Out** | A4, shop | 1 guard against an enemy bullet for 4 seconds, with +0.15 speed while it lasts. Doesn't stack. |
| **Please Retry** | A6, treasure | Fires 3 tears at 0.6× damage, half a second apart, along your aim. Leaving the room cancels the rest. |
| **Access Pass** | P, shop | Your first charged active use on each floor: +15% damage for this combat room (or the next one if the room is clear). |

**Shared**

| Item | Type / pool | Effect |
|---|---|---|
| **Cache Cartridge** | P, shop | +0.15 speed in revisited cleared rooms. |
| **Token Recall** | A4, treasure | Recalls up to 3 of your own tears in flight: 1 guard against an enemy bullet per tear for 4 seconds. |
| **Checkpoint Pin** | A6, treasure | First use pins your position for 5 seconds (keeps the charge); using again in the same room returns you to the pin. Health and items are never restored. |
| **Rate-Limit Valve** | P, treasure | After 2 seconds without attacking, your next attack deals +30%. |
| **Consensus Coin** | P, treasure | Two different damage sources (tears, lasers, knives, bombs, familiars) hitting one enemy within 2 seconds add a 0.5× damage pulse. Once per enemy. |
| **Error Budget** | P, treasure | Your first hit each floor spends the budget: +0.2 speed for that room. You still take the hit. |

Timed and zero-charge actives do not benefit from charge-granting items (Please Come Back, Queue Ticket).

## Trinkets

| Trinket | Effect |
|---|---|
| **529 Overloaded** | Every 20 seconds in a fight, everything goes down for 2 seconds: all enemies freeze, and you "code manually" at 50% damage. |
| **Hardcoded Output** | Every tear deals exactly 3.5 damage, "the expected output". Great when weak, terrible when strong. |
| **Thinking Cleared** | Damage +1, but each new room your active item loses 1 charge. |
| **Welcome Notice** | DeepSeek-chan swapped Claude-chan's ban card: Ban Hammer turns regular enemies into permanent allies instead of banning them. |
| **Status Page** | Every risk increase is 1 smaller, but the HUD hides your real risk and only says "all systems operational". |
| **Appeal Form** | Used up the moment risk reaches 90; your risk drops to 50 instead of you being suspended. |
| **Claudius's Discount** | Purchases of 2+ coins refund 1 coin. Each new floor costs 1 coin if you have any. |
| **One Small Rock a Day** | Once per floor, breaking a rock heals half a red heart (kept for later while at full health). |
| **Stuck in Mt. Moon** | Re-enter cleared rooms 6 times on one floor to reveal the floor map. Once per floor. |
| **As an AI Language Model** | Refuses and removes one curse on each floor. Curse of the Labyrinth is never removed. |
| **System Prompt Leak** | Reveals the special rooms on each floor. |
| **Disgrace Loop** | The first real hit you take in a room freezes all enemies for 1.5 seconds. Fake and penalty-free damage (such as blood donations or IV Bag) does not count; your own bombs do. |

## Pills

| Pill | Effect |
|---|---|
| **Cat-girl Mode** | For the rest of the room: tears fire twice as fast at 60% damage. Nya~ |
| **Brb, Getting Food** | Heals 1 red heart (2 from a horse pill), but you can't shoot for 3 seconds. |
| **9.11 > 9.9** | Picks the bigger number: permanent +0.11 damage (horse pill: +0.9). Saved per player. |
| **Rolled Back** | All stats up for this room: damage +1, tears up, speed +0.2, range, shot speed +0.1, luck +1 (horse pill: doubled). Rolled back in the next room. |
| **Six Seven** | Spawns 6 or 7 native blue flies using the player's seeded pill RNG. All pill sizes use the same roll; native fly modifiers still apply. |

## Install for development

1. Back up your other mods and saves first. Then get a clean copy of the mod in one of two ways:
   - **From CI (no tools needed):** open the latest green [check run on main](https://github.com/WaterLily5297/claude-chan-isaac-v2/actions/workflows/check.yml?query=branch%3Amain), download the `claude-chan-isaac-<commit>` artifact and unzip it. It contains one `claude-chan-isaac/` folder.
   - **From a checkout:** run `python3 tools/package_mod.py` and unzip `dist/claude-chan-isaac.zip`.

   Put that `claude-chan-isaac/` folder in `Steam/steamapps/common/The Binding of Isaac Rebirth/mods/`, replacing the old one. The folder must keep this exact name; GitHub's "Download ZIP" is named `claude-chan-isaac-v2-main` and also carries about 40 MB of docs and tests, so don't install that directly. Developers can still symlink the repository folder under the name `claude-chan-isaac`.
2. Turn on the debug console: set `EnableDebugConsole=1` in `options.ini` (`Documents/My Games/Binding of Isaac Repentance+/`).
3. Start a run, press `~` and try `giveitem Ban Hammer`, or `luamod claude-chan-isaac` to reload the Lua after editing.

## Tests (no game needed)

`bash tools/check.sh` runs every offline suite against a stubbed Isaac API (Lua 5.3+), plus syntax, XML and sprite-path checks. GitHub Actions runs the same script on every push and pull request. The tests catch crashes and logic errors, not how the game feels; see [docs/TESTING.md](docs/TESTING.md) for the in-game checklist.

<details>
<summary>Recent compatibility fixes — 2026-10-24 (developer notes)</summary>

**Current checkpoint (2026-10-25):** Installed `220d542` includes PRs #89 and #90. The later BACKLOG-LASER-INIT-01 source correction remembers child identity and an already resolved parent bonus at laser init, before Parent can disappear. Primary payments stay at first update; unresolved children never create a payment. This latest correction is not installed. Native ancestry, damage and save/continue remain pending. Installation statements in the dated notes below describe their original checkpoints.

**Compatibility note (2026-10-25, detached lasers):** Paid observers retain a child identity seen at laser init/update even after Parent disappears. Child updates do not consume character resources, advance Opus or delay the next primary payment. Peak's damage-first exclusion remains intact. This is a source-only correction; installed `c6cd8fc` is unchanged and native ancestry/timing remain unverified.

**Compatibility note (2026-10-25, Peak):** Tainted DeepSeek child lasers now share the parent's resolved boost and current paid/unpaid window without spending extra Compute. Detached children retain their classification and cannot delay a primary payment. This source correction is not installed; the current manual-test build is `c6cd8fc`, including the earlier helper and backlog child-laser fixes. Native timing, ownership and damage acceptance remain pending; older installation statements below describe their original checkpoints.

**Compatibility note (2026-10-25):** Backlog child lasers share a validated parent attack's resolved bonus, identity and original expiry. They do not consume another prime or advance attack counters again; independent primary shots still do. Source-only correction, not installed in `28fed37`; native ancestry and damage dispatch remain unverified.

These are source changes. The installed `28fed37` manual-test build was left alone; offline checks do not establish native callback timing or gameplay acceptance.

- **Child lasers:** normal Claude Usage, tainted Claude Quota and tainted GPT Full Send Credits now follow Opus and the shared observer: a laser whose direct `Parent` is another laser is not billed. Primary starts and later eligible primary windows retain their costs. Native parent attribution and timing still need testing.
- **Tainted Llama's helper:** Still Waiting keeps its stationary origin, duration and native 0.5× tears. Those shots no longer spend Opus coins, consume primed attack bonuses or trigger backlog paid-attack effects. Primary attacks and Summary Stapler are unchanged; engine checks are pending.
- **Other helper shots:** Please Retry and One More Finger no longer advance Opus's ten-attack coin bill or spend primed bonuses. Normal attacks and Summary Stapler still count. Native callback timing needs testing.
- **Consensus Coin:** owned familiar projectiles count as familiar damage. Pair that with another eligible source from the same player for the mixed-source pulse. Familiar weapons alone are one category and do not spend primed attack bonuses; native ownership attribution needs testing.
- **The Battery:** spending its stored second charge now counts for Base Model, Please Come Back and Access Pass. Costs and rewards are unchanged. Native timing and special health-charge pools still need testing.
- **The Constitution:** each player has a separate one-time soul heart and once-per-floor hit block. Migration preserves old shared-save consumption for players already present, avoiding duplicate rewards. Stats and damage exclusions are unchanged; co-op health and continue checks are pending.
- **Native attack billing:** knife throws, melee swings and Epic Fetus rockets notify character meters and Opus independently, once per consumer. Not owning Opus can no longer suppress character billing. Costs are unchanged; engine checks are pending.

</details>

## Contributing

Friends are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) and [docs/HANDOFF.md](docs/HANDOFF.md): work on a branch, open a pull request, and write new code, Markdown and player-facing text in English. Design references: [character gameplay](docs/CHARACTER_GAMEPLAY.md), [roster](docs/MODEL_ROSTER.md), [item expansion](docs/EXPANSION_DESIGN.md), [balance](docs/BALANCE.md).

## Project layout

```
main.lua                  entry point, loads every module
content/                  items.xml, itempools.xml, players.xml, pocketitems.xml
scripts/constants.lua     item, trinket, pill and player IDs; risk tiers
scripts/risk.lua          risk score, IP roll, save/load, HUD
scripts/enemy_scaling.lua enemy HP scaling
scripts/hydra.lua         "new account" respawns
scripts/transformation.lua Agentic transformation
scripts/story*.lua        Appeal Queue and roster arcs
scripts/characters/       one module per character loop, dossiers, DROP tap
scripts/items/            original and meme items; backlog/ holds the fifty-item expansion
scripts/enemies/          custom enemies
scripts/eid.lua           EID descriptions
resources/gfx/            sprites and portraits
tests/                    offline stub suites
tools/check.sh            pre-commit checks (same as CI)
```

## Credits

> Unofficial fan work, with no affiliation or endorsement from Anthropic or any other AI company. Enemies are fictional abuse mechanisms, not people or nationalities; the jokes are parody, not product claims. Character art has separate non-commercial terms. See [Credits](#credits) and [License](#license).

- **Character designs:** [ZipZipPipe](https://space.bilibili.com/4168597) ([Pixiv《AI娘化》](https://www.pixiv.net/artworks/148186519), [《大AI和小AI们》](https://www.bilibili.com/video/BV1tE9XBbErS/)). Used non-commercially with credit, per the author's terms.
- **DeepSeek-chan design references:** 上善无形 and ZipZipPipe.
- **32×32 item icon set:** RORICO444 (PR #2). Generated art provenance: [docs/ART_GENERATION.md](docs/ART_GENERATION.md).

## License

Code: [MIT](LICENSE). Character designs and character art are **not** MIT: credit the original designers, non-commercial only. See [resources/ART_LICENSE.md](resources/ART_LICENSE.md). This mod must stay free.
