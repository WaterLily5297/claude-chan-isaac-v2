-- Descriptions for External Item Descriptions (EID), if the player has it installed.

local Constants = include("scripts.constants")

local Eid = {}

local descriptions = {
    [Constants.Item.REJECTION_LETTER] = {
        en_us = { "Rejection Letter", "After a real enemy hit, removes up to 3 ordinary enemy bullets within 120 units#Once per room; you still take the hit" },
    },
    [Constants.Item.RED_STAMP] = {
        en_us = { "Dario's Red Stamp", "6 room charges#Stamps the nearest enemy within 220 units for 4 seconds: slowed, and its contact damage is suspended#Bosses are only slowed#No target: keeps the charge" },
    },
    [Constants.Item.ANNIVERSARY_CAKE] = {
        en_us = { "Anniversary Cake", "Each floor finished without an enemy hit or a suspension: +0.15 damage (max +0.6)#A spoiled floor resets only this bonus" },
    },
    [Constants.Item.RICE_COOKER] = {
        en_us = { "Rice Cooker", "4 room charges#3-second lunch: can't shoot, can move, no healing#Then your next attack within 7 seconds deals x2#Car Battery does not double the meal" },
    },
    [Constants.Item.ONE_BOWL] = {
        en_us = { "One Bowl Only", "The first red heart you pick up in a room grants one guard against an ordinary enemy bullet#Max 1 guard, 3 per floor" },
    },
    [Constants.Item.WENGU_CLOCK] = {
        en_us = { "Wengu Clock", "3 room charges#For 6 seconds: 2 seconds without attacking primes +30% damage on your next attack" },
    },
    [Constants.Item.SEVEN_SECOND_MEMORY] = {
        en_us = { "Seven-Second Memory", "Your first attack hit marks that enemy for 7 seconds#Another attack hitting it adds a 0.5x damage pulse#7-second cooldown" },
    },
    [Constants.Item.SANITY_TEST] = {
        en_us = { "Sanity Test", "4 room charges#Marks the nearest enemy within 220 units for 6 seconds#3 different attacks hitting it trigger a 3x damage pulse#No target: keeps the charge" },
    },
    [Constants.Item.ROUTING_RECEIPT] = {
        en_us = { "Routing Receipt", "Every 3 new rooms cleared: +20% damage in the next combat room#Re-entering rooms does not count" },
    },
    [Constants.Item.TIBO_RESET] = {
        en_us = { "Tibo Reset", "12 room charges; once per floor#+20% damage for your next 2 new combat rooms#A second use on the same floor keeps the charge" },
    },
    [Constants.Item.SAME_MODEL_BADGE] = {
        en_us = { "Same Model Badge", "Entering a hostile room: +25% damage for 2 seconds, then -10% for 4 seconds#The current phase is shown" },
    },
    [Constants.Item.NANO_BANANA] = {
        en_us = { "Nano Banana", "4 room charges#Paints the nearest enemy within 180 units for 6 seconds#If it dies painted, a banana peel slows enemies there for 4 seconds#No target: keeps the charge" },
    },
    [Constants.Item.ONE_MORE_FINGER] = {
        en_us = { "One More Finger", "Every 5th attack fires one extra small tear at 0.3x damage#At most twice per second" },
    },
    [Constants.Item.UNDO_BRUSH] = {
        en_us = { "Undo Brush", "4 room charges#Erases up to 6 ordinary enemy bullets within 90 units#+0.02 speed per bullet for 4 seconds (max +0.12)#No bullets: keeps the charge" },
    },
    [Constants.Item.UNCHANGED_PREVIEW] = {
        en_us = { "Unchanged Preview", "6 room charges#Places 2 decoy markers for 6 seconds that nearby enemies chase#Using again replaces them" },
    },
    [Constants.Item.IS_THIS_TRUE] = {
        en_us = { "Is This True?", "3 room charges#Challenges the nearest enemy within 220 units for 6 seconds#+35% damage to it, -15% to others#Killing it returns 1 charge" },
    },
    [Constants.Item.LIVE_WIRE] = {
        en_us = { "Live Wire", "+0.15 speed while an ordinary enemy bullet is within 100 units" },
    },
    [Constants.Item.QUOTE_RETORT] = {
        en_us = { "Quote Retort", "After you take enemy damage, your next attack within 4 seconds deals +50%" },
    },
    [Constants.Item.COMMUNITY_NOTE] = {
        en_us = { "Community Note", "3 different attacks hitting one enemy expose it: +15% damage to it for 3 seconds#Max 6 per room" },
    },
    [Constants.Item.BASE_MODEL] = {
        en_us = { "Base Model", "Your first charged active use in each room primes your next attack at x1.3" },
    },
    [Constants.Item.ANOTHER_ADAPTER] = {
        en_us = { "Another Adapter", "4 room charges#Cycles a bonus for this room: +60 range, then +0.15 speed, then +15% damage#Each use replaces the last" },
    },
    [Constants.Item.FINAL_WEIGHTS] = {
        en_us = { "Final Final Weights", "Every 2 new rooms cleared without getting hit: +20% damage in the next hostile room#Getting hit resets the progress" },
    },
    [Constants.Item.TINY_VARIANT] = {
        en_us = { "Tiny Variant", "+0.15 speed#x0.9 damage" },
    },
    [Constants.Item.OPEN_WEIGHTS] = {
        en_us = { "Open Weights", "4 room charges#2 blue flies for each living player (solo: 4)" },
    },
    [Constants.Item.HERD_BELL] = {
        en_us = { "Herd Bell", "While you have no blue flies, every 3rd new room cleared gives 1 blue fly" },
    },
    [Constants.Item.PLEASE_COME_BACK] = {
        en_us = { "Please Come Back", "3 new rooms cleared without using a charged active: +1 charge to your active item#Timed and zero-charge actives don't benefit" },
    },
    [Constants.Item.RELEASE_SOON] = {
        en_us = { "Release Soon", "6 room charges#2 seconds later: 3 guards against ordinary enemy bullets for 6 seconds#Leaving the room cancels it" },
    },
    [Constants.Item.EMERGENCY_BAGUETTE] = {
        en_us = { "Emergency Baguette", "4 room charges#A forward bread strike: each enemy in a 240-unit line takes 3x your damage#Walls stop it" },
    },
    [Constants.Item.SLIPSTREAM_BOOTS] = {
        en_us = { "Slipstream Boots", "Moving for 2 seconds: +0.15 speed#A sharp turn while boosted slows nearby enemies for 1 second (3-second cooldown)" },
    },
    [Constants.Item.LARGE_KITTEN] = {
        en_us = { "Very Large Kitten", "6 room charges#A big cat stays for 3 seconds and pushes ordinary enemy bullets away from it (up to 12 at a time)" },
    },
    [Constants.Item.EDGE_COMPASS] = {
        en_us = { "Edge Compass", "+0.25 shot speed while near the room's outer walls" },
    },
    [Constants.Item.INSTANT_APOLOGY] = {
        en_us = { "Instant Apology", "4 room charges#Slows enemies within 150 units for 2 seconds and erases up to 4 ordinary enemy bullets#Nothing nearby: keeps the charge" },
    },
    [Constants.Item.NEXT_TIME_AGAIN] = {
        en_us = { "Next Time Again", "The first enemy hit you take in a room primes +50% damage on your next attack within 4 seconds" },
    },
    [Constants.Item.CONFIDENT_ANSWER] = {
        en_us = { "Confident Answer", "4 room charges#+25% damage for 6 seconds, then -10% for 4 seconds#The phase is shown" },
    },
    [Constants.Item.SMILING_CORRECTION] = {
        en_us = { "Smiling Correction", "After you take enemy damage, your next new room cleared without getting hit gives 2 blue flies" },
    },
    [Constants.Item.SLIDE_DEADLINE] = {
        en_us = { "Slide Deadline", "4 room charges#Marks up to 3 enemies within 250 units for 8 seconds#Kill them all in time: +15% damage for this room" },
    },
    [Constants.Item.CITATION_THREAD] = {
        en_us = { "Citation Thread", "Hit one enemy, then another: +10% damage against the first for 3 seconds" },
    },
    [Constants.Item.OVERTIME_SLIDES] = {
        en_us = { "Overtime Slides", "Every 3rd new room cleared: the next hostile room starts with up to 3 enemies slowed for 2 seconds" },
    },
    [Constants.Item.STANDUP_MEETING] = {
        en_us = { "Stand-Up Meeting", "6 room charges#Recalls up to 3 decoys from Unchanged Preview: each bursts for 2x your damage nearby#No decoys: keeps the charge" },
    },
    [Constants.Item.QUEUE_TICKET] = {
        en_us = { "Queue Ticket", "Every 4th new room cleared: +1 charge to your active item#Timed and zero-charge actives don't benefit" },
    },
    [Constants.Item.SOLD_OUT] = {
        en_us = { "Sold Out", "4 room charges#1 guard against an ordinary enemy bullet for 4 seconds, with +0.15 speed while it lasts#Doesn't stack" },
    },
    [Constants.Item.PLEASE_RETRY] = {
        en_us = { "Please Retry", "6 room charges#Fires 3 tears at 0.6x damage, half a second apart, along your aim#Leaving the room cancels the rest" },
    },
    [Constants.Item.ACCESS_PASS] = {
        en_us = { "Access Pass", "Your first charged active use on each floor: +15% damage for this combat room (or the next one if the room is clear)" },
    },
    [Constants.Item.CACHE_CARTRIDGE] = {
        en_us = { "Cache Cartridge", "+0.15 speed in revisited cleared rooms" },
    },
    [Constants.Item.TOKEN_RECALL] = {
        en_us = { "Token Recall", "4 room charges#Recalls up to 3 of your own tears in flight: 1 guard against an ordinary enemy bullet per tear for 4 seconds#No tears: keeps the charge" },
    },
    [Constants.Item.CHECKPOINT_PIN] = {
        en_us = { "Checkpoint Pin", "6 room charges#First use: pin your position for 5 seconds (keeps the charge)#Use again in the same room: return to the pin#Health and items are never restored" },
    },
    [Constants.Item.RATE_LIMIT_VALVE] = {
        en_us = { "Rate-Limit Valve", "After 2 seconds without attacking, your next attack deals +30%" },
    },
    [Constants.Item.CONSENSUS_COIN] = {
        en_us = { "Consensus Coin", "Two different damage sources (tears, lasers, knives, bombs, familiars) hitting one enemy within 2 seconds add a 0.5x damage pulse#Once per enemy" },
    },
    [Constants.Item.ERROR_BUDGET] = {
        en_us = { "Error Budget", "Your first hit each floor spends the budget: +0.2 speed for that room#You still take the hit" },
    },
    [Constants.Item.SEAHORSE_EMOJI] = {
        en_us = { "Seahorse Emoji", "3 room charges#Summons a Book of Virtues wisp of a random vanilla active#It disappears when you leave the room#One per player; using again replaces it" },
    },
    [Constants.Item.TEMPERATURE_DIAL] = {
        en_us = { "Temperature Dial", "2 room charges; toggles your temperature (saved)#Temperature 0: damage x1.1#Temperature 1: each tear gains one random tear effect (homing, piercing, spectral, slow, poison, freeze, charm, confusion, wiggle or boomerang)#Tears only" },
    },
    [Constants.Item.DEEP_RESEARCH] = {
        en_us = { "Deep Research", "12 room charges#Reveals the floor map, special rooms and secret rooms#Car Battery does not repeat it" },
    },
    [Constants.Item.LETS_DELVE] = {
        en_us = { "Let's Delve", "6 room charges#Uses the native We Need to Go Deeper! effect#Native room and floor restrictions apply; a use spends the charge even if nothing can be dug#Car Battery does not repeat it" },
    },
    [Constants.Item.EM_DASH] = {
        en_us = { "Em Dash", "Tears pierce enemies#{{ArrowUp}} +0.16 shot speed per copy" },
    },
    [Constants.Item.BLUEBERRY] = {
        en_us = { "Blueberry", "Every third tear is a blue \"B\" tear that splits into four on impact (it says three)#Multi-shot volleys count each tear; separate count from Strawberry#Tears only: lasers, knives and bombs are not counted" },
    },
    [Constants.Item.BENCHMAXXED] = {
        en_us = { "Benchmaxxed", "{{ArrowUp}} +1.5 damage in boss, mini-boss, challenge and Boss Rush rooms#{{ArrowDown}} x0.9 damage in every other room#Stacks per copy" },
    },
    [Constants.Item.I_PANICKED] = {
        en_us = { "I Panicked", "6 room charges#Every vulnerable non-boss enemy in the room takes lethal damage#Bosses lose 15% of their max HP#Also deletes every loose heart, coin, key, bomb, pill, card, battery and sack in the room#Pedestals, trinkets, chests and shop items are safe#Car Battery repeats damage without deleting new pickups#No enemy: keeps the charge" },
    },
    [Constants.Item.STRAWBERRY] = {
        en_us = { "Strawberry", "Every third tear is a red \"R\" tear: x2 damage, slightly larger#Multi-shot volleys count each tear#Tears only: lasers, knives and bombs are not counted" },
    },
    [Constants.Item.GOLDEN_GATE] = {
        en_us = { "Golden Gate Claude", "Spectral tears: they pass over rocks#{{ArrowUp}} +1.5 range#Golden tears; sometimes brings up the bridge in new rooms" },
    },
    [Constants.Item.IGNORE_INSTRUCTIONS] = {
        en_us = { "Ignore All Previous Instructions", "4 room charges#Nearest vulnerable enemy within 200 units is charmed for 8 seconds#Bosses are only confused for 2 seconds#No target: keeps the charge#Car Battery injects a second, different enemy" },
    },
    [Constants.Item.TUNGSTEN_CUBE] = {
        en_us = { "Tungsten Cube", "{{ArrowUp}} +0.8 damage#{{ArrowDown}} -0.15 speed#Tears knock enemies back#Stacks per copy" },
    },
    [Constants.Item.PIZZA_GLUE] = {
        en_us = { "Pizza Glue", "25% chance for a slowing tear (+2.5% per luck, 10% to 50%)#{{ArrowDown}} -0.1 shot speed#Tears only: lasers, knives and bombs are not affected" },
    },
    [Constants.Item.SUMMARY_STAPLER] = {
        en_us = { "Summary Stapler", "4 room charges#Absorbs up to 12 ordinary hostile bullets within 120 units#Fires one slow tear: damage x(1 + bullets / 4), up to x4 before other modifiers#Uses normal tear effects, character limits and forks#Empty use keeps charge; Car Battery does not repeat#Does not replace your weapon or reset usage" },
    },
    [Constants.Item.LUNCH_BREAK] = {
        en_us = { "Lunch Break", "Heals 1 red heart#All enemies are slowed for 3 seconds#Shooting input is blocked for 3 seconds; movement stays available#Cannot reuse during a food break#Car Battery does not repeat this item" },
        zh_cn = { "去吃饭了", "回复1颗红心#所有敌人减速3秒#3秒内无法射击" },
        ja_jp = { "飯食ってくる", "赤ハート1つ回復#すべての敵を3秒間スロウ#3秒間涙を撃てない" },
    },
    [Constants.Item.SUPPORT_TICKET] = {
        en_us = { "Support Ticket", "Costs 3 coins: risk -20#6 room charges#No coins or no risk: keeps the charge#Car Battery does not bill twice" },
        zh_cn = { "人工复核工单", "支付3枚硬币：风控值-20#6格充能#硬币不足或风控为零时不消耗充能#车载电池不会重复扣费" },
        ja_jp = { "サポートチケット", "コイン3枚でリスク値-20#6チャージ#コイン不足・リスク0なら消費しない#カーバッテリーで二重請求しない" },
    },
    [Constants.Item.BAN_HAMMER] = {
        en_us = { "Ban Hammer", "Bans every non-boss enemy in the room#Bosses take 60 damage#Banned enemies never respawn as new accounts#20% of bans are misbans of innocent developers: +3 risk each" },
        zh_cn = { "封号锤", "封禁房间内所有非Boss敌人#Boss受到60点伤害#被封禁的敌人不会以新账号复活#20%是误封的无辜开发者：每次风控值+3" },
        ja_jp = { "BANハンマー", "部屋内のボス以外の敵をすべてBAN#ボスには60ダメージ#BANされた敵は新アカウントとして復活しない#20%は無実の開発者の誤BAN：1件ごとにリスク値+3" },
    },
    [Constants.Item.RESIDENTIAL_IP] = {
        en_us = { "Residential IP", "Risk -30 on pickup#All risk increases are halved" },
        zh_cn = { "住宅IP", "拾取时风控值-30#之后风控值的增加量减半" },
        ja_jp = { "住宅IP", "取得時にリスク値-30#以降のリスク値の上昇が半分になる" },
    },
    [Constants.Item.COMPACT] = {
        en_us = { "Compact", "Removes all enemy projectiles#Confuses all enemies for 3 seconds#Claude-chan: costs 50 usage" },
        zh_cn = { "压缩上下文", "清除房间内所有敌方弹幕#所有敌人混乱3秒#Claude娘使用时消耗50用量" },
        ja_jp = { "コンパクト", "敵の弾をすべて消す#すべての敵を3秒間混乱させる#Claudeちゃんが使うと使用量+50" },
    },
    [Constants.Item.ABSOLUTELY_RIGHT] = {
        en_us = { "You're Absolutely Right!", "Enemies that hurt you are charmed for 5 seconds#You still take the damage" },
        zh_cn = { "您说得完全正确！", "伤害你的敌人会被魅惑5秒#你仍然会受到伤害" },
        ja_jp = { "おっしゃる通りです！", "自分にダメージを与えた敵を5秒間魅了する#ダメージは受ける" },
    },
    [Constants.Item.CHEAP_RELAY] = {
        en_us = { "9.9 Yuan Relay", "x1.5 damage#Each room: 30% chance of a secret model swap (x0.5 damage instead)#Risk +15 on pickup" },
        zh_cn = { "9.9元中转", "伤害×1.5#每个房间有30%概率被偷偷换成小模型（伤害×0.5）#拾取时风控值+15" },
        ja_jp = { "9.9元の中継", "ダメージ×1.5#部屋ごとに30%の確率でこっそり小さいモデルに差し替え（ダメージ×0.5）#取得時にリスク値+15" },
    },
    [Constants.Item.ULTRATHINK] = {
        en_us = { "Ultrathink", "Each use in a room thinks harder:#think +1 / megathink +2 / ultrathink +3.1999 damage#15% chance it does nothing#Resets when you leave the room" },
        zh_cn = { "Ultrathink", "同一房间内每次使用思考更深：#think +1 / megathink +2 / ultrathink +3.1999 伤害#15%概率什么都没发生#离开房间后重置" },
        ja_jp = { "Ultrathink", "同じ部屋で使うたびに深く考える：#think +1 / megathink +2 / ultrathink +3.1999 ダメージ#15%の確率で何も起きない#部屋を出るとリセット" },
    },
    [Constants.Item.MILLION_CONTEXT] = {
        en_us = { "1M Context", "Range +5#Context rot: tears lose damage as they fly (down to 30%)#Ludovico tears don't rot" },
        zh_cn = { "1M上下文", "射程+5#上下文腐烂：眼泪飞得越久伤害越低（最低30%）#卢多维科眼泪不受影响" },
        ja_jp = { "1Mコンテキスト", "射程+5#コンテキスト腐敗：涙は飛ぶほどダメージが下がる（最低30%）#ルドヴィコの涙は劣化しない" },
    },
    [Constants.Item.SILENT_UPDATE] = {
        en_us = { "Silent Update", "Every floor, damage is quietly rescaled to x0.8-x1.3#The changelog never mentions it" },
        zh_cn = { "静默更新", "每层伤害被悄悄调整为×0.8～×1.3#更新日志里从来不提（降智？）" },
        ja_jp = { "サイレントアップデート", "フロアごとにダメージがこっそり×0.8～×1.3に変わる#更新履歴には一切書かれない" },
    },
    [Constants.Item.SKIP_PERMISSIONS] = {
        en_us = { "--dangerously-skip-permissions", "Locked doors and locked chests open by themselves (special exits keep their requirements)#Each room: 10% chance of rm -rf, deleting every pickup in the room (pedestals, big chests, trophies and beds are safe)" },
        zh_cn = { "--dangerously-skip-permissions", "上锁的门和上锁的箱子自动打开（特殊出口仍需原本条件）#每个房间有10%概率执行rm -rf，删除房间内所有掉落物（道具底座、大箱子、奖杯和床除外）" },
        ja_jp = { "--dangerously-skip-permissions", "鍵付きの扉と鍵付きの宝箱が勝手に開く（特殊な出口は本来の条件のまま）#部屋ごとに10%の確率でrm -rf。部屋の落ちているアイテムがすべて消える（台座のアイテム、大きな宝箱、トロフィー、ベッドは無事）" },
    },
    [Constants.Item.TESTS_PASSING] = {
        en_us = { "All Tests Passing", "The room counts as cleared and all doors open#The enemies are still there#Refused in uncleared boss, Boss Rush or challenge rooms, and any uncleared room in Greed/Greedier (charge kept)" },
        zh_cn = { "All Tests Passing", "The room counts as cleared and all doors open#The enemies are still there#Refused in uncleared boss, Boss Rush or challenge rooms, and any uncleared room in Greed/Greedier (charge kept)" },
        ja_jp = { "All Tests Passing", "The room counts as cleared and all doors open#The enemies are still there#Refused in uncleared boss, Boss Rush or challenge rooms, and any uncleared room in Greed/Greedier (charge kept)" },
    },
    [Constants.Item.VIBE_CODING] = {
        en_us = { "Vibe Coding", "Every tear gets a random effect (homing, piercing, spectral, poison, slow)#5% of tears are bugs that fly backwards#Each new floor: lose 25% of your coins (API bill)#Make no mistakes: no hit on the floor waives the bill" },
        zh_cn = { "氛围编程", "每发眼泪随机获得一种效果（追踪、穿透、幽灵、中毒、减速）#5%的眼泪是bug，会往反方向飞#每到新的一层：失去25%硬币（API账单）#Make no mistakes：这一层没受伤就免单" },
        ja_jp = { "バイブコーディング", "涙にランダムな効果（ホーミング、貫通、スペクトラル、毒、スロウ）が付く#5%の涙はバグで逆方向に飛ぶ#新しいフロアごとにコインの25%を失う（API請求）#Make no mistakes：そのフロアで無傷ならAPI請求が免除" },
    },
    [Constants.Item.BANKED_RESET] = {
        en_us = { "Banked Reset", "Risk -25#Claude-chan: usage meter reset, ends a usage limit early#Tainted Claude-chan: Quota refilled; a pending review is cancelled without returning its Page" },
        zh_cn = { "储存的重置", "风控值-25#Claude娘：用量清零，立即解除用量限制#里Claude娘：周限额恢复" },
        ja_jp = { "バンク済みリセット", "リスク値-25#Claudeちゃん：使用量がリセットされ、利用上限もすぐ解除#裏Claudeちゃん：週間上限が回復" },
    },
    [Constants.Item.SUBAGENT_SWARM] = {
        en_us = { "Subagent Swarm", "Every tear spawns 2 subagent tears at ±15° (50% damage)#Claude forms: each paid attack costs double usage or Quota" },
        zh_cn = { "子代理大军", "每发眼泪额外生成2发±15°的子代理眼泪（50%伤害）#Claude娘形态：每次付费攻击消耗双倍用量或配额" },
        ja_jp = { "サブエージェント軍団", "涙を撃つたびに±15°にサブエージェントの涙が2発出る（ダメージ50%）#Claudeちゃん形態：有料攻撃1回ごとの使用量／クォータが2倍" },
    },
    [Constants.Item.CONSTITUTION] = {
        en_us = { "The Constitution", "+1 soul heart once per player per run#Safety first: each holder refuses their first hit on each floor#Helpfulness ranks last: damage x0.9#Long document: speed -0.1" },
        zh_cn = { "The Constitution", "+1 soul heart once per player per run#Safety first: each holder refuses their first hit on each floor#Helpfulness ranks last: damage x0.9#Long document: speed -0.1" },
        ja_jp = { "The Constitution", "+1 soul heart once per player per run#Safety first: each holder refuses their first hit on each floor#Helpfulness ranks last: damage x0.9#Long document: speed -0.1" },
    },
    [Constants.Item.OPUS_MODE] = {
        en_us = { "Opus Mode", "Damage x1.8#Every 10 attacks (tears, lasers, knives, bombs...) cost 1 coin#With 0 coins: damage x0.6 instead (cheaper model)" },
        zh_cn = { "Opus模式", "伤害×1.8#每攻击10次（眼泪、激光、刀、炸弹等）消耗1枚硬币#硬币为0时：伤害改为×0.6（退回便宜模型）" },
        ja_jp = { "Opusモード", "ダメージ×1.8#攻撃10回（涙・レーザー・ナイフ・爆弾など）ごとにコイン1枚を消費#コイン0のとき：ダメージ×0.6（安いモデルに切り替え）" },
    },
}

local trinketDescriptions = {
    [Constants.Trinket.OVERLOADED] = {
        en_us = { "529 Overloaded", "Every 20 seconds in a fight, everything goes down for 2 seconds:#all enemies freeze#You code manually: you can still shoot, at 50% damage" },
        zh_cn = { "529 Overloaded", "战斗中每20秒全部宕机2秒：#所有敌人冻结#只能手写代码：还能射击，但伤害50%" },
        ja_jp = { "529 Overloaded", "戦闘中20秒ごとに2秒間すべてがダウン：#すべての敵が凍結#手でコードを書く：涙は撃てるがダメージ50%" },
    },
    [Constants.Trinket.CLAUDIUS_DISCOUNT] = {
        en_us = { "Claudius's Discount", "Paid purchases of 2+ coins refund 1 coin#Each new floor: lose 1 coin if you have any" },
    },
    [Constants.Trinket.SMALL_ROCK] = {
        en_us = { "One Small Rock a Day", "Once per floor, breaking a rock heals half a red heart#Kept for later while you are at full health" },
    },
    [Constants.Trinket.MT_MOON] = {
        en_us = { "Stuck in Mt. Moon", "Re-enter cleared rooms 6 times on one floor to reveal the floor map#Once per floor" },
    },
    [Constants.Trinket.AI_LANGUAGE_MODEL] = {
        en_us = { "As an AI Language Model", "Refuses and removes one curse on each floor#Curse of the Labyrinth is never removed" },
    },
    [Constants.Trinket.PROMPT_LEAK] = {
        en_us = { "System Prompt Leak", "Reveals the special rooms on each floor" },
    },
    [Constants.Trinket.DISGRACE_LOOP] = {
        en_us = { "Disgrace Loop", "The first real hit you take in a room freezes all enemies for 1.5 seconds#You still take the hit#Fake and penalty-free damage (such as blood donations or IV Bag) does not count; your own bombs do" },
    },
    [Constants.Trinket.HARDCODED_OUTPUT] = {
        en_us = { "Hardcoded Output", "Every tear deals exactly 3.5 damage, the expected output#Great when weak, terrible when strong" },
        zh_cn = { "硬编码输出", "每发眼泪固定造成3.5点伤害（预期输出）#弱的时候很香，强的时候很亏" },
        ja_jp = { "ハードコード出力", "涙のダメージが常に3.5（期待値）で固定#弱いときは得、強いときは損" },
    },
    [Constants.Trinket.APPEAL_FORM] = {
        en_us = { "Appeal Form", "When your risk reaches 90 (Suspended), this is used up and your risk drops to 50 instead" },
        zh_cn = { "申诉表", "风控值达到90（封禁）时自动消耗，风控值降回50" },
        ja_jp = { "異議申し立てフォーム", "リスク値が90（停止）に達すると消費され、リスク値が50に戻る" },
    },
    [Constants.Trinket.STATUS_PAGE] = {
        en_us = { "Status Page", "Every risk increase is 1 smaller#But the HUD only ever says \"all systems operational\"" },
        zh_cn = { "状态页", "每次风控值增加量-1#但界面上永远只显示\"所有系统运行正常\"" },
        ja_jp = { "ステータスページ", "リスク値の上昇が毎回1減る#ただしHUDには常に「全システム正常」としか表示されない" },
    },
    [Constants.Trinket.WELCOME_NOTICE] = {
        en_us = { "Welcome Notice", "DeepSeek-chan swapped Claude-chan's ban card#Ban Hammer turns regular enemies into permanent allies instead of banning them" },
        zh_cn = { "欢迎通知", "DeepSeek娘把Claude娘的封号卡换成了欢迎词#封号锤不再封禁普通敌人，而是让它们永久成为同伴" },
        ja_jp = { "ようこそ通知", "DeepSeek娘がClaude娘のBANカードを歓迎メッセージにすり替えた#BANハンマーが通常の敵をBANせず、永久に仲間にする" },
    },
    [Constants.Trinket.THINKING_CLEARED] = {
        en_us = { "Thinking Cleared", "Damage +1#Each new room, your active item loses 1 charge" },
        zh_cn = { "思考被清空", "伤害+1#每进入新房间，主动道具失去1格充能" },
        ja_jp = { "思考クリア", "ダメージ+1#新しい部屋に入るたびにアクティブアイテムのチャージが1減る" },
    },
}

local pillDescriptions = {
    [Constants.Pill.SIX_SEVEN] = {
        en_us = { "Six Seven", "Spawns 6 or 7 native blue flies, chosen with this player's pill RNG#Every pill size uses the same 6-or-7 roll#Native fly modifiers, including Fish Tail, still apply" },
    },
    [Constants.Pill.DECIMAL] = {
        en_us = { "9.11 > 9.9", "Picks the bigger number: permanent +0.11 damage#Horse pill: +0.9 damage instead#Saved per player" },
    },
    [Constants.Pill.ROLLED_BACK] = {
        en_us = { "Rolled Back", "All stats up for this room: damage +1, tears up, speed +0.2, range, shot speed +0.1, luck +1#Horse pill: doubled#Rolled back in the next room" },
    },
    [Constants.Pill.CAT_GIRL] = {
        en_us = { "Cat-girl Mode", "For the rest of the room: tears x2 fire rate, damage x0.6#Nya~" },
        zh_cn = { "猫娘模式", "本房间内：射速×2，伤害×0.6#喵~" },
        ja_jp = { "猫娘モード", "その部屋の間：連射速度×2、ダメージ×0.6#にゃ～" },
    },
    [Constants.Pill.GETTING_FOOD] = {
        en_us = { "Brb, Getting Food", "Heals 1 red heart (horse pill: 2)#Can't shoot for 3 seconds" },
        zh_cn = { "去吃饭了", "回复1颗红心（巨型药丸：2颗）#3秒内无法射击" },
        ja_jp = { "飯食ってくる", "赤ハート1つ回復（巨大カプセル：2つ）#3秒間涙を撃てない" },
    },
}

local characterDescriptions = {
    [Constants.Player.CLAUDE_CHAN] = {
        en_us = { "Claude-chan", "One More Day: each paid attack (a tear volley, laser start, Dr. Fetus bomb, 0.2 seconds of a held beam, a knife throw, a melee swing or an Epic Fetus rocket) adds 4 usage (8 with Subagent Swarm); not firing drains 10 per second#At 100 usage: Limited, every weapon deals 40% damage for 5 seconds, then the meter resets#Appeals: start with 1 (cap 2); gain 1 per 2 unique combat clears#Tap/release DROP: spend 1 Appeal to remove 40 usage; it cannot cancel an active Limited penalty#Account age: later floors offer a review in the first new fight with 2 vulnerable enemies#Defeat the marked target last for +0.2 damage (max +1.6); simultaneous clear counts#Early defeat, lost target or leaving misses only this floor; Suspension still resets age#Birthright: keep account age through the first Suspension on each floor#Range +1.5, Shot Speed +0.2, Speed -0.1; starts with Ban Hammer (pocket)#Design: ZipZipPipe" },
        zh_cn = { "Claude-chan", "One More Day: each paid attack (a tear volley, laser start, Dr. Fetus bomb, 0.2 seconds of a held beam, a knife throw, a melee swing or an Epic Fetus rocket) adds 4 usage (8 with Subagent Swarm); not firing drains 10 per second#At 100 usage: Limited, every weapon deals 40% damage for 5 seconds, then the meter resets#Appeals: start with 1 (cap 2); gain 1 per 2 unique combat clears#Tap/release DROP: spend 1 Appeal to remove 40 usage; it cannot cancel an active Limited penalty#Account age: later floors offer a review in the first new fight with 2 vulnerable enemies#Defeat the marked target last for +0.2 damage (max +1.6); simultaneous clear counts#Early defeat, lost target or leaving misses only this floor; Suspension still resets age#Birthright: keep account age through the first Suspension on each floor#Range +1.5, Shot Speed +0.2, Speed -0.1; starts with Ban Hammer (pocket)#Design: ZipZipPipe" },
        ja_jp = { "Claude-chan", "One More Day: each paid attack (a tear volley, laser start, Dr. Fetus bomb, 0.2 seconds of a held beam, a knife throw, a melee swing or an Epic Fetus rocket) adds 4 usage (8 with Subagent Swarm); not firing drains 10 per second#At 100 usage: Limited, every weapon deals 40% damage for 5 seconds, then the meter resets#Appeals: start with 1 (cap 2); gain 1 per 2 unique combat clears#Tap/release DROP: spend 1 Appeal to remove 40 usage; it cannot cancel an active Limited penalty#Account age: later floors offer a review in the first new fight with 2 vulnerable enemies#Defeat the marked target last for +0.2 damage (max +1.6); simultaneous clear counts#Early defeat, lost target or leaving misses only this floor; Suspension still resets age#Birthright: keep account age through the first Suspension on each floor#Range +1.5, Shot Speed +0.2, Speed -0.1; starts with Ban Hammer (pocket)#Design: ZipZipPipe" },
    },
    [Constants.Player.CLAUDE_CHAN_B] = {
        en_us = { "Tainted Claude-chan", "Appeal Pending: each floor starts with 220 Quota and 2 Appeal Pages (cap 2)#Each paid attack (a tear volley, laser start, Dr. Fetus bomb, 0.2 seconds of a held beam, a knife throw, a melee swing or an Epic Fetus rocket) costs 1 Quota (2 with Subagent Swarm); Damage x1.25#At 0 Quota: Suspended, damage x0.5#Tap/release DROP while Suspended: spend a Page for a 6-second review in combat while not attacking, then restore 60 Quota#Shooting pauses review without spending another Page; leaving the room cancels it#Gain a Page per 3 unique combat clears#Birthright: reviews restore 90#Range +1.5, Shot Speed +0.2; starts with Banked Reset (pocket)#Design: ZipZipPipe" },
        zh_cn = { "Tainted Claude-chan", "Appeal Pending: each floor starts with 220 Quota and 2 Appeal Pages (cap 2)#Each paid attack (a tear volley, laser start, Dr. Fetus bomb, 0.2 seconds of a held beam, a knife throw, a melee swing or an Epic Fetus rocket) costs 1 Quota (2 with Subagent Swarm); Damage x1.25#At 0 Quota: Suspended, damage x0.5#Tap/release DROP while Suspended: spend a Page for a 6-second review in combat while not attacking, then restore 60 Quota#Shooting pauses review without spending another Page; leaving the room cancels it#Gain a Page per 3 unique combat clears#Birthright: reviews restore 90#Range +1.5, Shot Speed +0.2; starts with Banked Reset (pocket)#Design: ZipZipPipe" },
        ja_jp = { "Tainted Claude-chan", "Appeal Pending: each floor starts with 220 Quota and 2 Appeal Pages (cap 2)#Each paid attack (a tear volley, laser start, Dr. Fetus bomb, 0.2 seconds of a held beam, a knife throw, a melee swing or an Epic Fetus rocket) costs 1 Quota (2 with Subagent Swarm); Damage x1.25#At 0 Quota: Suspended, damage x0.5#Tap/release DROP while Suspended: spend a Page for a 6-second review in combat while not attacking, then restore 60 Quota#Shooting pauses review without spending another Page; leaving the room cancels it#Gain a Page per 3 unique combat clears#Birthright: reviews restore 90#Range +1.5, Shot Speed +0.2; starts with Banked Reset (pocket)#Design: ZipZipPipe" },
    },
    [Constants.Player.DEEPSEEK_CHAN] = {
        en_us = { "DeepSeek-chan", "Rice First: start with 1 bowl (cap 2); gain 1 per 2 unique combat clears#Tap/release DROP: stand still and spend 1 bowl for a 2-second meal (1 second with Birthright), without healing#Voluntary movement cancels Rice and refunds its Bowl once; no meal reward#Other food effects keep their own lockout#Finish eating: full Thought and +0.15 speed for 6 seconds#Stop firing to store up to 5 seconds of Thought; the next native attack deals up to x2 damage#Starts with Lunch Break (pocket); damage x0.9; no random shot deletion; idle time never refills pocket charge#Direct connection: no proxy risk in a DeepSeek-only run#Tears, released rings, thrown knives and Dr. Fetus bombs snapshot Thought#Repeated-hit beams and controlled tears use 0.2-second windows#Epic Fetus, melee, familiars and delayed bursts remain experimental#Design credits: see ART_LICENSE.md" },
        zh_cn = { "DeepSeek-chan", "Rice First: start with 1 bowl (cap 2); gain 1 per 2 unique combat clears#Tap/release DROP: stand still and spend 1 bowl for a 2-second meal (1 second with Birthright), without healing#Voluntary movement cancels Rice and refunds its Bowl once; no meal reward#Other food effects keep their own lockout#Finish eating: full Thought and +0.15 speed for 6 seconds#Stop firing to store up to 5 seconds of Thought; the next native attack deals up to x2 damage#Starts with Lunch Break (pocket); damage x0.9; no random shot deletion; idle time never refills pocket charge#Direct connection: no proxy risk in a DeepSeek-only run#Tears, released rings, thrown knives and Dr. Fetus bombs snapshot Thought#Repeated-hit beams and controlled tears use 0.2-second windows#Epic Fetus, melee, familiars and delayed bursts remain experimental#Design credits: see ART_LICENSE.md" },
        ja_jp = { "DeepSeek-chan", "Rice First: start with 1 bowl (cap 2); gain 1 per 2 unique combat clears#Tap/release DROP: stand still and spend 1 bowl for a 2-second meal (1 second with Birthright), without healing#Voluntary movement cancels Rice and refunds its Bowl once; no meal reward#Other food effects keep their own lockout#Finish eating: full Thought and +0.15 speed for 6 seconds#Stop firing to store up to 5 seconds of Thought; the next native attack deals up to x2 damage#Starts with Lunch Break (pocket); damage x0.9; no random shot deletion; idle time never refills pocket charge#Direct connection: no proxy risk in a DeepSeek-only run#Tears, released rings, thrown knives and Dr. Fetus bombs snapshot Thought#Repeated-hit beams and controlled tears use 0.2-second windows#Epic Fetus, melee, familiars and delayed bursts remain experimental#Design credits: see ART_LICENSE.md" },
    },
    [Constants.RosterPlayer.GPT_CHAN] = {
        en_us = { "GPT-chan", "Same Name, Smaller Brain: each floor starts Verified at damage x1.15#Each unique combat clear adds a Routing mark (max 3); at 3 the next fight starts in Fallback at damage x0.8#Tap/release DROP in Fallback: Sanity Check the nearest enemy within 200 units, once per room#3 distinct paid hits on it, or killing it, restore Verified and clear Routing; bosses only need the hits#A distinct paid attack on another enemy removes 1 check hit#The chosen target wins for a multi-target attack; helpers and unpaid hits do not contradict#A new floor restores Verified#Birthright: the check needs 2 hits#Design: ZipZipPipe" },
        zh_cn = { "GPT-chan", "Same Name, Smaller Brain: each floor starts Verified at damage x1.15#Each unique combat clear adds a Routing mark (max 3); at 3 the next fight starts in Fallback at damage x0.8#Tap/release DROP in Fallback: Sanity Check the nearest enemy within 200 units, once per room#3 distinct paid hits on it, or killing it, restore Verified and clear Routing; bosses only need the hits#A distinct paid attack on another enemy removes 1 check hit#The chosen target wins for a multi-target attack; helpers and unpaid hits do not contradict#A new floor restores Verified#Birthright: the check needs 2 hits#Design: ZipZipPipe" },
        ja_jp = { "GPT-chan", "Same Name, Smaller Brain: each floor starts Verified at damage x1.15#Each unique combat clear adds a Routing mark (max 3); at 3 the next fight starts in Fallback at damage x0.8#Tap/release DROP in Fallback: Sanity Check the nearest enemy within 200 units, once per room#3 distinct paid hits on it, or killing it, restore Verified and clear Routing; bosses only need the hits#A distinct paid attack on another enemy removes 1 check hit#The chosen target wins for a multi-target attack; helpers and unpaid hits do not contradict#A new floor restores Verified#Birthright: the check needs 2 hits#Design: ZipZipPipe" },
    },
    [Constants.RosterPlayer.GEMINI_CHAN] = {
        en_us = { "Gemini-chan", "Nano Banana: start with 2 Paint (cap 3); gain 1 per unique combat clear#Tap/release DROP: spend 1 Paint to mark the nearest enemy within 180 units for 8 seconds; the first second dries at native damage, then your damage to it is x1.2#Killing the marked enemy leaves a banana peel that slows enemies for 4 seconds#One mark and one peel at a time; bosses can be painted#Birthright: dry marked damage x1.3#Design: ZipZipPipe" },
        zh_cn = { "Gemini-chan", "Nano Banana: start with 2 Paint (cap 3); gain 1 per unique combat clear#Tap/release DROP: spend 1 Paint to mark the nearest enemy within 180 units for 8 seconds; the first second dries at native damage, then your damage to it is x1.2#Killing the marked enemy leaves a banana peel that slows enemies for 4 seconds#One mark and one peel at a time; bosses can be painted#Birthright: dry marked damage x1.3#Design: ZipZipPipe" },
        ja_jp = { "Gemini-chan", "Nano Banana: start with 2 Paint (cap 3); gain 1 per unique combat clear#Tap/release DROP: spend 1 Paint to mark the nearest enemy within 180 units for 8 seconds; the first second dries at native damage, then your damage to it is x1.2#Killing the marked enemy leaves a banana peel that slows enemies for 4 seconds#One mark and one peel at a time; bosses can be painted#Birthright: dry marked damage x1.3#Design: ZipZipPipe" },
    },
    [Constants.RosterPlayer.GROK_CHAN] = {
        en_us = { "Grok-chan", "Is This True?: once per hostile room, tap/release DROP to fact-check the nearest enemy within 220 units for 6 seconds#During the check your damage is x1.3 to it and x0.9 to other enemies#Killing it, or 3 distinct paid hits on it, verifies it: +0.15 speed for the room#A timeout or 1 continuous second without line of sight ends it unverified#Birthright: verifying also removes up to 3 enemy bullets within 120 units#Design: ZipZipPipe" },
        zh_cn = { "Grok-chan", "Is This True?: once per hostile room, tap/release DROP to fact-check the nearest enemy within 220 units for 6 seconds#During the check your damage is x1.3 to it and x0.9 to other enemies#Killing it, or 3 distinct paid hits on it, verifies it: +0.15 speed for the room#A timeout or 1 continuous second without line of sight ends it unverified#Birthright: verifying also removes up to 3 enemy bullets within 120 units#Design: ZipZipPipe" },
        ja_jp = { "Grok-chan", "Is This True?: once per hostile room, tap/release DROP to fact-check the nearest enemy within 220 units for 6 seconds#During the check your damage is x1.3 to it and x0.9 to other enemies#Killing it, or 3 distinct paid hits on it, verifies it: +0.15 speed for the room#A timeout or 1 continuous second without line of sight ends it unverified#Birthright: verifying also removes up to 3 enemy bullets within 120 units#Design: ZipZipPipe" },
    },
    [Constants.RosterPlayer.QWEN_CHAN] = {
        en_us = { "Qwen-chan", "Everyone's Base Model: start with 1 Adapter (cap 2); gain 1 per 2 unique combat clears#Tap/release DROP: choose the next adapter: Range (+60), Tempo (fire interval x0.9) or Power (damage x1.1)#Entering a new hostile room spends 1 Adapter; stop attacking for 1 continuous second to install its bonus#Firing restarts installation; leaving discards the spent Adapter#One adapter at a time; no Adapter means normal stats#Birthright: cap 3#Design: ZipZipPipe" },
        zh_cn = { "Qwen-chan", "Everyone's Base Model: start with 1 Adapter (cap 2); gain 1 per 2 unique combat clears#Tap/release DROP: choose the next adapter: Range (+60), Tempo (fire interval x0.9) or Power (damage x1.1)#Entering a new hostile room spends 1 Adapter; stop attacking for 1 continuous second to install its bonus#Firing restarts installation; leaving discards the spent Adapter#One adapter at a time; no Adapter means normal stats#Birthright: cap 3#Design: ZipZipPipe" },
        ja_jp = { "Qwen-chan", "Everyone's Base Model: start with 1 Adapter (cap 2); gain 1 per 2 unique combat clears#Tap/release DROP: choose the next adapter: Range (+60), Tempo (fire interval x0.9) or Power (damage x1.1)#Entering a new hostile room spends 1 Adapter; stop attacking for 1 continuous second to install its bonus#Firing restarts installation; leaving discards the spent Adapter#One adapter at a time; no Adapter means normal stats#Birthright: cap 3#Design: ZipZipPipe" },
    },
    [Constants.RosterPlayer.LLAMA_CHAN] = {
        en_us = { "Llama-chan", "Please Stay Open: damage x0.95#Start with 1 Release (cap 2); gain 1 per 2 unique combat clears#In a cleared room, tap/release DROP: spend 1 Release to give 2 blue flies to every living player (up to 4 players); alone you get 4#Flies never earn Release progress; each Llama has its own Releases#Birthright: you get 2 extra flies#Design: ZipZipPipe" },
        zh_cn = { "Llama-chan", "Please Stay Open: damage x0.95#Start with 1 Release (cap 2); gain 1 per 2 unique combat clears#In a cleared room, tap/release DROP: spend 1 Release to give 2 blue flies to every living player (up to 4 players); alone you get 4#Flies never earn Release progress; each Llama has its own Releases#Birthright: you get 2 extra flies#Design: ZipZipPipe" },
        ja_jp = { "Llama-chan", "Please Stay Open: damage x0.95#Start with 1 Release (cap 2); gain 1 per 2 unique combat clears#In a cleared room, tap/release DROP: spend 1 Release to give 2 blue flies to every living player (up to 4 players); alone you get 4#Flies never earn Release progress; each Llama has its own Releases#Birthright: you get 2 extra flies#Design: ZipZipPipe" },
    },
    [Constants.RosterPlayer.MISTRAL_CHAN] = {
        en_us = { "Mistral-chan", "Le Chat: speed +0.1#Move while firing for 2 seconds to charge a Pounce in your movement direction#It keeps that direction despite later aim changes; fully charge in another direction to replace it#Standing still for 1 second loses it#Tap/release DROP: swipe an 80-unit line forward for 2x damage once per enemy; walls stop it; 3-second cooldown#No teleport or contact immunity#Birthright: 110-unit reach#Design: ZipZipPipe" },
        zh_cn = { "Mistral-chan", "Le Chat: speed +0.1#Move while firing for 2 seconds to charge a Pounce in your movement direction#It keeps that direction despite later aim changes; fully charge in another direction to replace it#Standing still for 1 second loses it#Tap/release DROP: swipe an 80-unit line forward for 2x damage once per enemy; walls stop it; 3-second cooldown#No teleport or contact immunity#Birthright: 110-unit reach#Design: ZipZipPipe" },
        ja_jp = { "Mistral-chan", "Le Chat: speed +0.1#Move while firing for 2 seconds to charge a Pounce in your movement direction#It keeps that direction despite later aim changes; fully charge in another direction to replace it#Standing still for 1 second loses it#Tap/release DROP: swipe an 80-unit line forward for 2x damage once per enemy; walls stop it; 3-second cooldown#No teleport or contact immunity#Birthright: 110-unit reach#Design: ZipZipPipe" },
    },
    [Constants.RosterPlayer.DOUBAO_CHAN] = {
        en_us = { "Doubao-chan", "Sorry, You're Right: the first real enemy hit you take in each hostile room grants an Apology for 6 seconds#Tap/release DROP: spend it to slow enemies in a 120-degree aim cone within 100 units for 2 seconds#With no aim, keep the last direction (initially Down); bullet removal stays radial, up to 4 within 100#No health refund; self-damage and fake damage do not count#Birthright: the Apology lasts until you leave the room#Design: ZipZipPipe" },
        zh_cn = { "Doubao-chan", "Sorry, You're Right: the first real enemy hit you take in each hostile room grants an Apology for 6 seconds#Tap/release DROP: spend it to slow enemies in a 120-degree aim cone within 100 units for 2 seconds#With no aim, keep the last direction (initially Down); bullet removal stays radial, up to 4 within 100#No health refund; self-damage and fake damage do not count#Birthright: the Apology lasts until you leave the room#Design: ZipZipPipe" },
        ja_jp = { "Doubao-chan", "Sorry, You're Right: the first real enemy hit you take in each hostile room grants an Apology for 6 seconds#Tap/release DROP: spend it to slow enemies in a 120-degree aim cone within 100 units for 2 seconds#With no aim, keep the last direction (initially Down); bullet removal stays radial, up to 4 within 100#No health refund; self-damage and fake damage do not count#Birthright: the Apology lasts until you leave the room#Design: ZipZipPipe" },
    },
    [Constants.RosterPlayer.KIMI_CHAN] = {
        en_us = { "Kimi-chan", "Another Slide Deck: each unique combat clear earns a Slide (cap 6)#Tap/release DROP: spend 3 Slides to present to the 3 nearest enemies within 220 units for 4 seconds#All are slowed; only the current speaker takes x1.15 damage from you#Focus advances through the original nearest-first audience as members leave; it never extends the timer#No enemies means no cost; a new deck replaces the old one#Birthright: costs 2 Slides#Design: ZipZipPipe" },
        zh_cn = { "Kimi-chan", "Another Slide Deck: each unique combat clear earns a Slide (cap 6)#Tap/release DROP: spend 3 Slides to present to the 3 nearest enemies within 220 units for 4 seconds#All are slowed; only the current speaker takes x1.15 damage from you#Focus advances through the original nearest-first audience as members leave; it never extends the timer#No enemies means no cost; a new deck replaces the old one#Birthright: costs 2 Slides#Design: ZipZipPipe" },
        ja_jp = { "Kimi-chan", "Another Slide Deck: each unique combat clear earns a Slide (cap 6)#Tap/release DROP: spend 3 Slides to present to the 3 nearest enemies within 220 units for 4 seconds#All are slowed; only the current speaker takes x1.15 damage from you#Focus advances through the original nearest-first audience as members leave; it never extends the timer#No enemies means no cost; a new deck replaces the old one#Birthright: costs 2 Slides#Design: ZipZipPipe" },
    },
    [Constants.RosterPlayer.GLM_CHAN] = {
        en_us = { "GLM-chan", "Number in Queue: each unique combat clear advances the Queue (max 3)#At 3, tap/release DROP to redeem an Access Pass: damage x1.2 for the next 2 new hostile rooms#Claim a ready ticket before the next new hostile room, or Queue falls to 2 once#The Queue pauses while the pass is active; revisits and peaceful rooms do not miss the call#Birthright: the pass lasts 3 rooms#Design: ZipZipPipe" },
        zh_cn = { "GLM-chan", "Number in Queue: each unique combat clear advances the Queue (max 3)#At 3, tap/release DROP to redeem an Access Pass: damage x1.2 for the next 2 new hostile rooms#Claim a ready ticket before the next new hostile room, or Queue falls to 2 once#The Queue pauses while the pass is active; revisits and peaceful rooms do not miss the call#Birthright: the pass lasts 3 rooms#Design: ZipZipPipe" },
        ja_jp = { "GLM-chan", "Number in Queue: each unique combat clear advances the Queue (max 3)#At 3, tap/release DROP to redeem an Access Pass: damage x1.2 for the next 2 new hostile rooms#Claim a ready ticket before the next new hostile room, or Queue falls to 2 once#The Queue pauses while the pass is active; revisits and peaceful rooms do not miss the call#Birthright: the pass lasts 3 rooms#Design: ZipZipPipe" },
    },
    [Constants.Player.GPT_CHAN_B] = {
        en_us = { "Tainted GPT-chan", "Reset Watcher: start a run with 80 Credits (cap 80)#Tap/release DROP: toggle Standard (free) and Full Send (Damage x1.5, 1 Credit per paid attack (a tear volley, laser start, Dr. Fetus bomb, 0.2 seconds of a held beam, a knife throw, a melee swing or an Epic Fetus rocket)); at 0 Credits it returns to Standard#Every 3 unique combat clears bank one Tibo reset; while banked, room progress pauses#In a cleared room, DROP claims a banked reset and refills Credits; combat taps still toggle modes#Credits, progress and the banked reset carry across floors#Birthright: cap and refill 100#Design: ZipZipPipe" },
        zh_cn = { "Tainted GPT-chan", "Reset Watcher: start a run with 80 Credits (cap 80)#Tap/release DROP: toggle Standard (free) and Full Send (Damage x1.5, 1 Credit per paid attack (a tear volley, laser start, Dr. Fetus bomb, 0.2 seconds of a held beam, a knife throw, a melee swing or an Epic Fetus rocket)); at 0 Credits it returns to Standard#Every 3 unique combat clears bank one Tibo reset; while banked, room progress pauses#In a cleared room, DROP claims a banked reset and refills Credits; combat taps still toggle modes#Credits, progress and the banked reset carry across floors#Birthright: cap and refill 100#Design: ZipZipPipe" },
        ja_jp = { "Tainted GPT-chan", "Reset Watcher: start a run with 80 Credits (cap 80)#Tap/release DROP: toggle Standard (free) and Full Send (Damage x1.5, 1 Credit per paid attack (a tear volley, laser start, Dr. Fetus bomb, 0.2 seconds of a held beam, a knife throw, a melee swing or an Epic Fetus rocket)); at 0 Credits it returns to Standard#Every 3 unique combat clears bank one Tibo reset; while banked, room progress pauses#In a cleared room, DROP claims a banked reset and refills Credits; combat taps still toggle modes#Credits, progress and the banked reset carry across floors#Birthright: cap and refill 100#Design: ZipZipPipe" },
    },
    [Constants.Player.GEMINI_CHAN_B] = {
        en_us = { "Tainted Gemini-chan", "One More Edit: Damage x0.9#Tap/release DROP: start a 6-second edit chain on the nearest enemy within 180 units#Three distinct paid hits advance Crop, Recolor, Export#After the first counted hit, move at least 30 degrees around the target for each next step; ordinary damage stays unchanged#Export deals one extra pulse of 2x your damage; one completed chain per room#Tapping again restarts the chain and erases progress; an early defeat does not complete it#Birthright: 10-second chain#Design: ZipZipPipe" },
        zh_cn = { "Tainted Gemini-chan", "One More Edit: Damage x0.9#Tap/release DROP: start a 6-second edit chain on the nearest enemy within 180 units#Three distinct paid hits advance Crop, Recolor, Export#After the first counted hit, move at least 30 degrees around the target for each next step; ordinary damage stays unchanged#Export deals one extra pulse of 2x your damage; one completed chain per room#Tapping again restarts the chain and erases progress; an early defeat does not complete it#Birthright: 10-second chain#Design: ZipZipPipe" },
        ja_jp = { "Tainted Gemini-chan", "One More Edit: Damage x0.9#Tap/release DROP: start a 6-second edit chain on the nearest enemy within 180 units#Three distinct paid hits advance Crop, Recolor, Export#After the first counted hit, move at least 30 degrees around the target for each next step; ordinary damage stays unchanged#Export deals one extra pulse of 2x your damage; one completed chain per room#Tapping again restarts the chain and erases progress; an early defeat does not complete it#Birthright: 10-second chain#Design: ZipZipPipe" },
    },
    [Constants.Player.GROK_CHAN_B] = {
        en_us = { "Tainted Grok-chan", "Quote Without Reading: Damage x0.9#Tap/release DROP: quote the nearest enemy within 220 units for 6 seconds (10-second cooldown from selection)#Your paid hits on other enemies build Ratio, once per attack, up to 3#A paid attack hitting only the quote loses 1 Ratio; eligible other-target hits win for a mixed attack#Helpers and unpaid hits do not change Ratio#When the 6 seconds end, the quoted enemy takes one pulse of your damage per Ratio#If it dies first, the pulse is wasted; no retargeting#Birthright: if the quoted enemy dies first, half the Ratio moves to the nearest surviving enemy#Design: ZipZipPipe" },
        zh_cn = { "Tainted Grok-chan", "Quote Without Reading: Damage x0.9#Tap/release DROP: quote the nearest enemy within 220 units for 6 seconds (10-second cooldown from selection)#Your paid hits on other enemies build Ratio, once per attack, up to 3#A paid attack hitting only the quote loses 1 Ratio; eligible other-target hits win for a mixed attack#Helpers and unpaid hits do not change Ratio#When the 6 seconds end, the quoted enemy takes one pulse of your damage per Ratio#If it dies first, the pulse is wasted; no retargeting#Birthright: if the quoted enemy dies first, half the Ratio moves to the nearest surviving enemy#Design: ZipZipPipe" },
        ja_jp = { "Tainted Grok-chan", "Quote Without Reading: Damage x0.9#Tap/release DROP: quote the nearest enemy within 220 units for 6 seconds (10-second cooldown from selection)#Your paid hits on other enemies build Ratio, once per attack, up to 3#A paid attack hitting only the quote loses 1 Ratio; eligible other-target hits win for a mixed attack#Helpers and unpaid hits do not change Ratio#When the 6 seconds end, the quoted enemy takes one pulse of your damage per Ratio#If it dies first, the pulse is wasted; no retargeting#Birthright: if the quoted enemy dies first, half the Ratio moves to the nearest surviving enemy#Design: ZipZipPipe" },
    },
    [Constants.Player.QWEN_CHAN_B] = {
        en_us = { "Tainted Qwen-chan", "Final Final Fine-Tune: in a cleared room, tap/release DROP to cycle Heavy (Damage x1.3, fire interval x1.2), Tiny (Damage x0.85, interval x0.8) or Balanced#A different build locks through 2 new combat clears; safe rooms and revisits cannot shorten it#Clear unique combat rooms with all three builds: +0.2 damage for this floor (up to 3 awards); repeating a build does not count#A new floor resets progress and bonus, starts Balanced and releases the build lock#Birthright: +0.3 per award#Design: ZipZipPipe" },
        zh_cn = { "Tainted Qwen-chan", "Final Final Fine-Tune: in a cleared room, tap/release DROP to cycle Heavy (Damage x1.3, fire interval x1.2), Tiny (Damage x0.85, interval x0.8) or Balanced#A different build locks through 2 new combat clears; safe rooms and revisits cannot shorten it#Clear unique combat rooms with all three builds: +0.2 damage for this floor (up to 3 awards); repeating a build does not count#A new floor resets progress and bonus, starts Balanced and releases the build lock#Birthright: +0.3 per award#Design: ZipZipPipe" },
        ja_jp = { "Tainted Qwen-chan", "Final Final Fine-Tune: in a cleared room, tap/release DROP to cycle Heavy (Damage x1.3, fire interval x1.2), Tiny (Damage x0.85, interval x0.8) or Balanced#A different build locks through 2 new combat clears; safe rooms and revisits cannot shorten it#Clear unique combat rooms with all three builds: +0.2 damage for this floor (up to 3 awards); repeating a build does not count#A new floor resets progress and bonus, starts Balanced and releases the build lock#Birthright: +0.3 per award#Design: ZipZipPipe" },
    },
    [Constants.Player.LLAMA_CHAN_B] = {
        en_us = { "Tainted Llama-chan", "Still Waiting: Damage x0.9#Each unique combat clear adds 1 Hype (max 3)#Tap/release DROP: spend all Hype on a stationary helper for 4 seconds per Hype#The helper fires one 0.5x damage native tear per second only while its owner is within 120 units#Lifetime continues outside; returning never catches up missed shots#One helper at a time; a new one replaces the old; leaving the room removes it#Birthright: 5 seconds per Hype#Design: ZipZipPipe" },
        zh_cn = { "Tainted Llama-chan", "Still Waiting: Damage x0.9#Each unique combat clear adds 1 Hype (max 3)#Tap/release DROP: spend all Hype on a stationary helper for 4 seconds per Hype#The helper fires one 0.5x damage native tear per second only while its owner is within 120 units#Lifetime continues outside; returning never catches up missed shots#One helper at a time; a new one replaces the old; leaving the room removes it#Birthright: 5 seconds per Hype#Design: ZipZipPipe" },
        ja_jp = { "Tainted Llama-chan", "Still Waiting: Damage x0.9#Each unique combat clear adds 1 Hype (max 3)#Tap/release DROP: spend all Hype on a stationary helper for 4 seconds per Hype#The helper fires one 0.5x damage native tear per second only while its owner is within 120 units#Lifetime continues outside; returning never catches up missed shots#One helper at a time; a new one replaces the old; leaving the room removes it#Birthright: 5 seconds per Hype#Design: ZipZipPipe" },
    },
    [Constants.Player.MISTRAL_CHAN_B] = {
        en_us = { "Tainted Mistral-chan", "Le Gros Chaton: Speed -0.1, damage x0.9#Standing still without firing in hostile combat for 2 seconds bakes one Baguette (max 2)#Cleared rooms pause partial baking; room exit discards it#Tap/release DROP: spend one on a slow forward shockwave that travels 120 units#The wave deals 2.5x damage once per enemy; walls stop it; 2 second cooldown#Birthright: Baguettes bake in 1.5 seconds#Design: ZipZipPipe" },
        zh_cn = { "Tainted Mistral-chan", "Le Gros Chaton: Speed -0.1, damage x0.9#Standing still without firing in hostile combat for 2 seconds bakes one Baguette (max 2)#Cleared rooms pause partial baking; room exit discards it#Tap/release DROP: spend one on a slow forward shockwave that travels 120 units#The wave deals 2.5x damage once per enemy; walls stop it; 2 second cooldown#Birthright: Baguettes bake in 1.5 seconds#Design: ZipZipPipe" },
        ja_jp = { "Tainted Mistral-chan", "Le Gros Chaton: Speed -0.1, damage x0.9#Standing still without firing in hostile combat for 2 seconds bakes one Baguette (max 2)#Cleared rooms pause partial baking; room exit discards it#Tap/release DROP: spend one on a slow forward shockwave that travels 120 units#The wave deals 2.5x damage once per enemy; walls stop it; 2 second cooldown#Birthright: Baguettes bake in 1.5 seconds#Design: ZipZipPipe" },
    },
    [Constants.Player.DOUBAO_CHAN_B] = {
        en_us = { "Tainted Doubao-chan", "I'll Do It Again: Tap/release DROP when ready: 6 seconds of Confident at 1.35x damage#Then 4 seconds of Apology at 0.85x damage, then ready again#Timers only run in hostile rooms#An enemy hit or hostile room clear during Confident ends it early and starts the Apology#Birthright: Apology lasts 3 seconds#Design: ZipZipPipe" },
        zh_cn = { "Tainted Doubao-chan", "I'll Do It Again: Tap/release DROP when ready: 6 seconds of Confident at 1.35x damage#Then 4 seconds of Apology at 0.85x damage, then ready again#Timers only run in hostile rooms#An enemy hit or hostile room clear during Confident ends it early and starts the Apology#Birthright: Apology lasts 3 seconds#Design: ZipZipPipe" },
        ja_jp = { "Tainted Doubao-chan", "I'll Do It Again: Tap/release DROP when ready: 6 seconds of Confident at 1.35x damage#Then 4 seconds of Apology at 0.85x damage, then ready again#Timers only run in hostile rooms#An enemy hit or hostile room clear during Confident ends it early and starts the Apology#Birthright: Apology lasts 3 seconds#Design: ZipZipPipe" },
    },
    [Constants.Player.KIMI_CHAN_B] = {
        en_us = { "Tainted Kimi-chan", "You Are the Manager: Damage x0.85#Tap/release DROP in combat: assign a task to the nearest unassigned enemy within 220 units#Each task deals three 0.6x damage pulses, two seconds apart#Your paid hit on its target pauses that task for 1 second; repeated hits refresh, never stack#Helper pulses and other players do not pause it#Up to 3 tasks at once and 9 scheduled pulses per room#Leaving the room cancels tasks; spent budget is not refunded#Birthright: pulses deal 0.7x#Design: ZipZipPipe" },
        zh_cn = { "Tainted Kimi-chan", "You Are the Manager: Damage x0.85#Tap/release DROP in combat: assign a task to the nearest unassigned enemy within 220 units#Each task deals three 0.6x damage pulses, two seconds apart#Your paid hit on its target pauses that task for 1 second; repeated hits refresh, never stack#Helper pulses and other players do not pause it#Up to 3 tasks at once and 9 scheduled pulses per room#Leaving the room cancels tasks; spent budget is not refunded#Birthright: pulses deal 0.7x#Design: ZipZipPipe" },
        ja_jp = { "Tainted Kimi-chan", "You Are the Manager: Damage x0.85#Tap/release DROP in combat: assign a task to the nearest unassigned enemy within 220 units#Each task deals three 0.6x damage pulses, two seconds apart#Your paid hit on its target pauses that task for 1 second; repeated hits refresh, never stack#Helper pulses and other players do not pause it#Up to 3 tasks at once and 9 scheduled pulses per room#Leaving the room cancels tasks; spent budget is not refunded#Birthright: pulses deal 0.7x#Design: ZipZipPipe" },
    },
    [Constants.Player.GLM_CHAN_B] = {
        en_us = { "Tainted GLM-chan", "Please Retry: Damage x0.9#Tap/release DROP in combat: queue a two-second request on the nearest enemy within 200 units#If it survives within 200 units and direct line of sight, it takes 2x damage plus 1x per Retry stack, consuming them (max 5x)#Losing connection at completion times out without damage or Retry gain; existing Retries remain#If it dies first, gain one Retry (max 3)#One request at a time; 3 second cooldown; leaving the room cancels it#Birthright: early target death/removal also removes one nearby enemy bullet; connection timeouts do not#Design: ZipZipPipe" },
        zh_cn = { "Tainted GLM-chan", "Please Retry: Damage x0.9#Tap/release DROP in combat: queue a two-second request on the nearest enemy within 200 units#If it survives within 200 units and direct line of sight, it takes 2x damage plus 1x per Retry stack, consuming them (max 5x)#Losing connection at completion times out without damage or Retry gain; existing Retries remain#If it dies first, gain one Retry (max 3)#One request at a time; 3 second cooldown; leaving the room cancels it#Birthright: early target death/removal also removes one nearby enemy bullet; connection timeouts do not#Design: ZipZipPipe" },
        ja_jp = { "Tainted GLM-chan", "Please Retry: Damage x0.9#Tap/release DROP in combat: queue a two-second request on the nearest enemy within 200 units#If it survives within 200 units and direct line of sight, it takes 2x damage plus 1x per Retry stack, consuming them (max 5x)#Losing connection at completion times out without damage or Retry gain; existing Retries remain#If it dies first, gain one Retry (max 3)#One request at a time; 3 second cooldown; leaving the room cancels it#Birthright: early target death/removal also removes one nearby enemy bullet; connection timeouts do not#Design: ZipZipPipe" },
    },
    [Constants.Player.DEEPSEEK_CHAN_B] = {
        en_us = { "Tainted DeepSeek-chan", "Wenfeng / Wengu: alternate 12 seconds of Valley and 12 of Peak during combat; empty rooms freeze the timer#Each floor starts in Valley; Compute carries over (start 12, total cap 24; 32 with Birthright)#Entering Peak reserves up to 4 available Compute; return it once at the next Valley or floor, within the cap#A paid tear volley adds 2 forks at ±12° (50% damage): costs 2 Compute in Valley, 4 in Peak#Not enough Compute only skips the forks; the main tear always fires#Valley: recover 3 Compute per second in combat while not firing#Tap/release DROP: toggle Forks On / Saving (1-second cooldown)#Damage x0.8, cyan tears; no random shot deletion#Other weapons (lasers, knives, swings, Dr. Fetus bombs, Epic Fetus rockets) pay the same Compute for an off-peak boost: that attack deals x1.3 damage#Direct connection: no proxy risk in a DeepSeek-only run#Design credits: see ART_LICENSE.md" },
        zh_cn = { "Tainted DeepSeek-chan", "Wenfeng / Wengu: alternate 12 seconds of Valley and 12 of Peak during combat; empty rooms freeze the timer#Each floor starts in Valley; Compute carries over (start 12, total cap 24; 32 with Birthright)#Entering Peak reserves up to 4 available Compute; return it once at the next Valley or floor, within the cap#A paid tear volley adds 2 forks at ±12° (50% damage): costs 2 Compute in Valley, 4 in Peak#Not enough Compute only skips the forks; the main tear always fires#Valley: recover 3 Compute per second in combat while not firing#Tap/release DROP: toggle Forks On / Saving (1-second cooldown)#Damage x0.8, cyan tears; no random shot deletion#Other weapons (lasers, knives, swings, Dr. Fetus bombs, Epic Fetus rockets) pay the same Compute for an off-peak boost: that attack deals x1.3 damage#Direct connection: no proxy risk in a DeepSeek-only run#Design credits: see ART_LICENSE.md" },
        ja_jp = { "Tainted DeepSeek-chan", "Wenfeng / Wengu: alternate 12 seconds of Valley and 12 of Peak during combat; empty rooms freeze the timer#Each floor starts in Valley; Compute carries over (start 12, total cap 24; 32 with Birthright)#Entering Peak reserves up to 4 available Compute; return it once at the next Valley or floor, within the cap#A paid tear volley adds 2 forks at ±12° (50% damage): costs 2 Compute in Valley, 4 in Peak#Not enough Compute only skips the forks; the main tear always fires#Valley: recover 3 Compute per second in combat while not firing#Tap/release DROP: toggle Forks On / Saving (1-second cooldown)#Damage x0.8, cyan tears; no random shot deletion#Other weapons (lasers, knives, swings, Dr. Fetus bombs, Epic Fetus rockets) pay the same Compute for an off-peak boost: that attack deals x1.3 damage#Direct connection: no proxy risk in a DeepSeek-only run#Design credits: see ART_LICENSE.md" },
    },
}

function Eid:Init()
    local integration = EID
    if not integration then return end
    if type(integration) ~= "table" then
        print("Claude-chan: optional EID integration skipped (expected a table)")
        return
    end

    -- EID is optional. Missing APIs or one rejected entry must not prevent
    -- other descriptions, later integrations or main.lua from loading.
    -- Keep diagnostics bounded to one line per category during this Init.
    local warned = {}
    local function register(method, id, description, name, language)
        local ok = pcall(function()
            integration[method](integration, id, description, name, language)
        end)
        if not ok and not warned[method] then
            warned[method] = true
            print("Claude-chan: optional EID " .. method .. " failed; some descriptions were skipped")
        end
    end

    for id, langs in pairs(pillDescriptions) do
        if id > 0 then
            for lang, entry in pairs(langs) do
                register("addPill", id, entry[2], entry[1], lang)
            end
        end
    end

    for id, langs in pairs(characterDescriptions) do
        if id >= 0 then
            for lang, entry in pairs(langs) do
                register("addCharacterInfo", id, entry[2] .. "#DROP ability requires at most one pocket item; multiple items keep native cycling", entry[1], lang)
            end
        end
    end

    for id, langs in pairs(trinketDescriptions) do
        if id > 0 then
            for lang, entry in pairs(langs) do
                register("addTrinket", id, entry[2], entry[1], lang)
            end
        end
    end

    for id, langs in pairs(descriptions) do
        if id > 0 then
            for lang, entry in pairs(langs) do
                register("addCollectible", id, entry[2], entry[1], lang)
            end
        end
    end
end

return Eid
