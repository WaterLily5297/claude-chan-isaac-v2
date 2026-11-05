# Claude-chan: Risk Control

[English](README.md) · [日本語](README.ja.md) · **中文**

给《以撒的结合：忏悔 / 忏悔+》做的 AI 娘化 mod。

起因是 B 站上吐槽 Claude 封号的视频，还有 AI 娘化。想着把这些梗做进以撒应该挺有意思，就有了这个项目。

Claude 娘拿着封号锤，自己也得管用量、躲风控、准备申诉。后来又加了其他模型：DeepSeek 吃饭能攒思考，GPT 会降智，Kimi 得给怪做 PPT。目前有 11 个角色，都有表里形态。

道具也差不多是这个思路。“测试全过”只管开门，怪还在房间里；“静默更新”每层改一次伤害，更新日志写“没有改动”。具体效果和操作都放在下面了。

## 开发状态

目前是 **0.5-dev**，还在开发，没上创意工坊。

| 内容 | 数量 |
|---|---|
| 可操作形态 | **22**：普通11 + 里11 |
| Collectibles | **80**: 17 original items, 13 meme extras and the 50-item expansion ([design](docs/EXPANSION_DESIGN.md)) |
| 饰品 | **12** |
| Pills | **5** |
| 敌人 | 1（中转站史莱姆） |
| 变身 | 1（Agentic） |
| 剧情 | 申诉队列（4章）＋ 其他每个模型家族各3章的剧情线 |

下面列的内容已经写进源码，离线测试通过了。22种形态也在游戏里做过基本启动检查（[记录](docs/ENGINE_AUDIT_2026-10-24.md)），不过平衡、武器组合和多人合作还没测完。已知的测试范围和待测项目在[这里](docs/TESTING.md)，数值之后可能还会改。

## 目录

- [通用操作和规则](#通用操作和规则)
- [核心系统](#核心系统)
- [角色](#角色)
- [收藏品](#收藏品)
- [饰品](#饰品)
- [药丸](#药丸)
- [安装、测试和参与开发](#开发安装)

## 通用操作和规则

游戏内多数名称和说明还是英文，下文保留英文道具名，方便对照。

- **DROP tap:** release after 1-12 gameplay frames to use a character ability, but only while carrying at most one pocket item. Two or more cards, pills or pocket actives disable the ability so DROP can select them normally. The main active and Schoolbag slots do not count as pocket items. If multiple pocket items are observed during a press, that entire gesture is cancelled even if one item is used or dropped before release. Release and press again after reducing the inventory. Long holds never use the ability; native input is not overridden. A press interrupted by a room change, pause or run start must be released first.
- **档案：** 在已清理的房间按住MAP，会显示当前角色的立绘和三行说明，松开即关闭。战斗中不显示。
- **"自己的攻击"** 指你自己发出的攻击（眼泪、激光、刀、炸弹等）。道具追加的脉冲伤害和帮手的攻击不算在内，所以效果不会自我连锁。
- **"首次战斗清理"** 指第一次清理有敌人的房间。重新进入已清理的房间不计数，所以无法刷。
- **"普通敌弹"** 指普通的敌方子弹。清除子弹的效果不会抵消你已经受到的伤害。
- 角色资源按玩家分别保存，保存并继续后仍然保留；新开一局会重置。多人合作时每位玩家各自拥有独立状态。
- 所有能力都使用游戏原生的武器、眼泪效果和属性计算。原生武器、体型和变身都会保留。角色外观固定：拾取道具不会改变角色造型，道具效果照常生效。
- 支持 [External Item Descriptions（EID）](https://steamcommunity.com/sharedfiles/filedetails/?id=836319872)。所有道具和全部22个形态都有英文说明；其中17个收藏品、6个饰品和2个药丸还有简体中文和日文说明。

## 核心系统

### 风控值（仅Claude形态）

只有当本局中有普通或里Claude娘时，风控系统才会运作。DeepSeek娘直连，其他9个家族有各自的玩法循环，所以她们没有IP、没有风控，也没有风控带来的难度。与Claude多人合作时，只有Claude玩家会增加风控值或受到封禁影响。

- 每层随机分配一个**代理IP**和共享人数。大多数共享人数很少，但有30%是拥挤的中转服务器。每进入新的一层，风控值增加"共享人数 ÷ 10 + 层数"。
- 受伤：风控 **+1**；无伤清理房间：风控 **−1**。
- 等级：**Clean**（0）、**Suspicious**（30）、**Flagged**（60）、**Suspended／封禁**（90以上）。封禁期间，Claude玩家伤害 **×0.75**，直到风控值降回90以下。
- 左下角HUD显示IP、共享人数和风控等级。没有Claude的对局显示"Direct connection（直连）"。
- **敌人强化：** 敌人血量在风控0时为×1，线性增加到风控100时的×3。
- **九头蛇账号：** 风控值40以上时，被击杀的敌人可能会以红色的"新账号"复活一次。概率在风控40时为10%，风控100时最高50%。被封号的敌人不会复活。

### 中转站史莱姆（敌人）

代表共享代理的敌人。风控值达到30后，会出现在25%的未清理房间中。死亡时分裂成两只，最多分裂两次，所以一只最多变成七只（每次分裂都会变小变弱）。*（暂用美术：绿色调的原版Clotty）*

### Agentic（变身）

集齐 Ultrathink、Compact、Vibe Coding、Subagent Swarm、--dangerously-skip-permissions、All Tests Passing 中的任意 **3个** 即可变身：获得**飞行**、射击间隔×0.8（射速提升）和**伤害+0.5**。

### 剧情

- **申诉队列（The Appeal Queue）**（Claude的对局）：四段不暂停游戏的简短字幕，支持英文、中文和日文。章节为"共享的地址"（新开一局）、"一份欢迎通知"（第一次到达第3或第4层）、"审核中"（第5层及以后）、"终于有人工看了"（成功使用Support Ticket之后）。每章每局只播放一次，进度在保存并继续后保留。原版过场动画和结局不受影响。
- **角色剧情线：** DeepSeek、GPT、Gemini、Grok、Qwen、Llama、Mistral、豆包、Kimi和GLM各有一条三章的剧情线，当该家族在本局中时播放（新开一局、第3～4层、第5层及以后）。目前只有英文。详见[docs/STORY.md](docs/STORY.md)。

### 兼容性

- 固定外观：全部22种形态在拾取原版或本模组的道具、饰品、胶囊、卡牌或达成变身时都保持自己的造型。道具效果、属性、飞行和体型照常生效，只清除服装图层。尚未在游戏内验证。
- EID说明（见上）。
- 能加载CJK字体时，HUD文字跟随游戏语言（中文／日本語），否则显示英文。
- Reactions Port Pack：通过后备注册支持所有角色。
- 各角色只在当前眼泪颜色上叠加色调，所以道具带来的颜色会保留。
- 能力的视觉反馈只使用原版特效：Mistral的飞扑和法棍冲击波、豆包的道歉会扬起尘土，Kimi的任务目标和GLM的请求目标会带有渐隐的色调。

## 角色

血量记法：❤ = 红心，💙 = 魂心。没有特别说明时，普通形态初始为 ❤❤💙 和1个炸弹，里形态初始为 ❤💙💙 和1把钥匙（里Claude娘改为1个炸弹，里DeepSeek娘两者都没有）。"伤害×N"是对最终伤害的倍率。每个形态都列出了长子权（Birthright）的强化效果。

### Claude娘（Claude）

**普通形态：One More Day（再用一天）。** ❤❤💙，1炸弹。射程+1.5（长上下文）、弹速+0.2、移速−0.1，橙色眼泪。口袋道具：**Ban Hammer（封号锤）**。
- **Usage:** each paid volley adds 4 usage (8 with Subagent Swarm), billed for every native weapon: each volley of tears, each laser start and Dr. Fetus bomb, each further 0.2 seconds of a held beam or steered Ludovico tear, each knife throw, each melee swing and each Epic Fetus rocket. Familiars and derived tears are free. Not firing drains 10 per second. At 100 she is **Limited**: every weapon deals 40% damage for 5 seconds, then the meter resets.
- **申诉（Appeal）：** 初始1次（上限2），每2次首次战斗清理获得1次。轻按DROP消耗1次，减少40用量。不能解除正在生效的Limited，用量为0时会被拒绝而不会浪费。
- **Account age:** from the second floor, the first new fight with at least two vulnerable enemies marks a **Review Target**. Defeat it last for the original +0.2 damage (cap +1.6); simultaneous room-clear deaths count. Early defeat, leaving or an unavailable target misses only this floor. No eligible room means no award. Suspension and the Birthright shield keep their existing rules.
- **风控：** 受上述风控值影响。
- **长子权：** 每层第一次被封禁时保留账号年龄。

**里形态：Appeal Pending（申诉审核中）。** ❤💙💙，1炸弹。伤害×1.25、射程+1.5、弹速+0.2。红发配黑金色连衣裙。口袋道具：**Banked Reset（储存的重置）**。
- **配额：** 每层开始时有220配额和2张申诉页（上限2）。每次攻击消耗1配额（持有Subagent Swarm时为2），与普通Claude娘一样所有武器都计费。
- 配额为0时 **被封禁**：伤害×0.5。
- While Suspended, tap DROP to spend a Page on a **6-second review**. Its timer runs in combat only while you stop attacking; shooting pauses it without spending another Page. Completion restores 60 Quota. Leaving cancels the review.
- 每3次首次战斗清理获得1张申诉页。Banked Reset会立刻补满配额，但会取消进行中的审核，且不返还申诉页。
- **长子权：** 审核恢复90配额。

### DeepSeek娘（DeepSeek）

**普通形态：Rice First（先吃饭）。** ❤❤💙，3硬币，1钥匙。伤害×0.9，蓝色眼泪。口袋道具：**Lunch Break（去吃饭了）**。
- **直连：** 不需要代理，所以只有DeepSeek的对局没有IP、没有风控，也没有风控难度。
- **Rice bowls:** start with 1 (cap 2). Earn 1 per two unique combat clears. Stand still and tap DROP for a 2-second meal without healing. Finishing grants full Thought and +0.15 speed for 6 seconds. Voluntary movement cancels, refunds this Bowl once and grants no meal reward; other food lockouts remain separate.
- **思考：** 停止攻击可积累最多5秒思考，下一次攻击伤害最高×2（显示"Thought for N s"）。眼泪、松开后的硫磺火环、投出的刀和胎儿博士炸弹会记录发射时的思考值；持续命中的光束和可操控眼泪使用0.2秒的短窗口。史诗胎儿、近战、跟班和延迟爆发仍属实验性支持。
- 不会随机吞掉眼泪，也不会挂机充能。
- **长子权：** 用餐只需1秒。

**里形态：Wenfeng / Wengu（峰谷）。** ❤💙。伤害×0.8，青色眼泪。同样直连。
- 战斗中 **谷时** 12秒和 **峰时** 12秒交替。空房间里计时暂停，每层从谷时开始。
- **Compute:** start 12, total cap 24 (32 with Birthright), carried across floors. Entering Peak reserves up to 4 available Compute. Return it once at the next Valley or floor, within the total cap; it cannot be spent during Peak.
- 每次发射眼泪会在±12°额外分叉出2发 **fork**（50%伤害）。谷时消耗2算力，峰时消耗4。算力不足时只跳过分叉，主眼泪一定会发出。
- 谷时在战斗中不射击时每秒恢复3算力。
- 轻按DROP切换 **Forks On／Saving（节省）**（1秒冷却）。
- **错峰优惠：** 非眼泪攻击与眼泪一样消耗算力（谷时2，峰时4），并以×1.3伤害命中。包括激光开始发射和持续光束每0.2秒、掷刀、近战挥击、胎儿博士炸弹和史诗胎儿火箭。在Saving模式下或算力不足时，按原生伤害命中，不消耗算力。
- **长子权：** 算力上限32。

### GPT娘（GPT）

**普通形态：Same Name, Smaller Brain（名字一样，脑子变小）。** ❤❤💙，1炸弹。
- **Verified（已验证）：** 伤害×1.15。首次战斗清理会累积Routing，达到3时下一个战斗房间以 **Fallback（降级）** 开始（伤害×0.8）。
- In Fallback, tap DROP to tag a **Sanity Check** enemy. Three distinct paid hits or your defeat of it restore Verified. A distinct off-target attack erases one hit, minimum zero; the target wins for a mixed attack, including delayed piercing hits. Helpers, unpaid hits and partners do not contradict. One check per room; leaving fails it. New floors restore Verified.
- **长子权：** 智力检测只需命中2次。

**里形态：Reset Watcher（蹲重置）。** ❤💙💙，1钥匙。
- **额度：** 每局80（上限80），跨层保留。
- 轻按DROP切换 **Standard（免费）** 和 **Full Send**（伤害×1.5，每次攻击消耗1额度，与Claude娘的用量一样所有武器都计费）。额度为0时回到Standard。
- Every three unique combat clears **bank a Tibo reset**. While banked, progress pauses. Claim it with DROP in a cleared room; combat taps still toggle modes and keep the reset.
- **长子权：** 上限和补充量提高到100。

### Gemini娘（Gemini）

**普通形态：Nano Banana。** ❤❤💙，1炸弹。
- **颜料：** 初始2（上限3），每次首次战斗清理获得1。
- Tap DROP to spend one and paint the nearest enemy within 180 units for 8 seconds. The first second dries at native damage, then your damage to it is x1.2. Your kill, including during drying, leaves a **banana peel** slowing enemies for 4 seconds. One mark and peel per player; bosses can be painted.
- **Birthright:** x1.3 damage to the painted enemy after drying.

**里形态：One More Edit（再改一版）。** ❤💙💙，1钥匙。伤害×0.9。
- Tap DROP for a 6-second **edit chain** on the nearest enemy within 180 units. Three distinct paid hits advance **Crop, Recolor, Export**. The first sets your angle; each next step needs at least 30 degrees of movement around the target. Unchanged angles still deal native damage; zero separation cannot set an angle.
- Export时额外造成一次相当于你伤害2倍的脉冲。每个房间只能完成一次。
- 再次轻按会重新开始并清除进度；目标提前死亡不算完成。
- **长子权：** 编辑链延长到10秒。

### Grok娘（Grok）

**普通形态：Is This True?（这是真的吗？）** ❤❤💙，1炸弹。
- 每个有敌人的房间一次，轻按DROP对220单位内最近的敌人进行6秒 **事实核查**：你对它的伤害×1.3，对其他敌人×0.9。
- Three distinct paid hits on it, or its defeat, **verify** it: the modifiers end and you gain +0.15 speed for the room. A timeout or one continuous second without direct line of sight ends it unverified; briefly restored sight resets that obstruction timer.
- **长子权：** 核查完成时清除附近最多3发敌弹。

**里形态：Quote Without Reading（不看就转发）。** ❤💙💙，1钥匙。伤害×0.9。
- 轻按DROP **引用** 220单位内最近的敌人6秒（10秒冷却）。
- Paid hits on *other* eligible enemies build **Ratio** once per attack, cap 3. A paid attack hitting only the quoted enemy removes one Ratio, minimum zero. Other-target hits win for a mixed attack, regardless of callback order; helpers, unpaid hits and partners do not affect it.
- 6秒结束时，被引用的敌人每点Ratio受到一次1倍伤害的脉冲。如果它提前死亡，Ratio作废，且不能更换目标。
- **长子权：** 被引用的敌人提前死亡时，一半Ratio转移到最近的存活敌人身上。

### 通义千问娘（Qwen）

**普通形态：Everyone's Base Model（大家的基座模型）。** ❤❤💙，1炸弹。
- **适配器：** 初始1（上限2），每2次首次战斗清理获得1。
- Tap DROP to pick **Range** (+60 range), **Tempo** (x0.9 firing interval) or **Power** (x1.1 damage). A new hostile room spends an Adapter; stop attacking for one continuous second to install its full room bonus. Firing restarts installation. Leaving discards the spent Adapter.
- **长子权：** 适配器上限3。

**里形态：Final Final Fine-Tune（最终最终版微调）。** ❤💙💙，1钥匙。
- In a cleared room, tap DROP to cycle **Heavy** (x1.3 damage, x1.2 interval), **Tiny** (x0.85 damage, x0.8 interval) or **Balanced**. A new selection pins the build through two new combat clears. Safe rooms, duplicates and revisits cannot shorten the commitment.
- Clear unique combat rooms with all three builds for **+0.2 damage this floor**, up to three awards. Repeating a build does not add a variant. A new floor resets progress/bonus, selects Balanced and releases the pin for an immediate choice.
- **长子权：** 每次+0.3。

### Llama娘（Llama）

**普通形态：Please Stay Open（请继续开源）。** ❤❤💙，1炸弹。伤害×0.95。
- **发布：** 初始1（上限2），每2次首次战斗清理获得1。
- In a cleared room, tap DROP to spend one: every living player (up to four) gets 2 **blue flies**. Solo, you get 4. Combat attempts retain the Release.
- **长子权：** 自己额外获得2只。

**里形态：Still Waiting（还在等）。** ❤💙💙，1钥匙。伤害×0.9。
- 每次首次战斗清理增加1点 **期待（Hype）**（最多3）。
- Tap DROP to spend all Hype on a stationary **helper** lasting 4 seconds per Hype. It fires one 0.5x native tear per second at the nearest enemy only while you stay within 120 units. Lifetime continues outside; return resumes the cadence without catch-up. One helper at a time; replacing or leaving removes it.
- **长子权：** 每点期待持续5秒。

### Mistral娘（Mistral）

**普通形态：Le Chat（猫）。** ❤❤💙，1炸弹。移速+0.1。
- Move while firing for 2 seconds to charge a **Pounce**, storing your movement direction. A full charge in another direction replaces it. Standing still for 1 second loses it.
- Tap DROP for a swipe in the **stored direction**, shown in the HUD: 2x damage once per enemy in an 80-unit line. Later aim changes do not redirect it. Walls block it; cooldown remains 3 seconds.
- **长子权：** 距离延长到110单位。

**里形态：Le Gros Chaton（大猫猫）。** ❤💙💙，1钥匙。移速−0.1，伤害×0.9。
- In hostile combat, stand still without firing for 2 seconds to bake a **Baguette** (max 2). Cleared rooms pause partial baking; room exit discards the partial charge.
- 轻按DROP消耗1根，向前方发出缓慢的 **冲击波**：前进120单位，对每个敌人造成一次2.5倍伤害。会被墙挡住，冷却2秒。
- **长子权：** 1.5秒就能烤好法棍。

### 豆包娘（Doubao）

**普通形态：Sorry, You're Right（抱歉，您说得对）。** ❤❤💙，1炸弹。
- 每个房间第一次被敌人打中时获得一个持续6秒的 **道歉** 标记。自伤、假伤害和献血机等不计。
- Tap DROP for a **120-degree slow cone** centered on your aim, within 100 units, lasting 2 seconds. With no aim, use the last direction, initially Down. Removal of up to four nearby enemy bullets remains radial. No health refund.
- **长子权：** 标记持续到离开房间。

**里形态：I'll Do It Again（下次还敢）。** ❤💙💙，1钥匙。
- 就绪时轻按DROP：6秒 **自信满满（Confident）**（伤害×1.35），然后4秒 **道歉（Apology）**（×0.85），之后再次就绪。
- Timers only run in hostile combat. An enemy hit or a hostile room clear during Confident starts Apology immediately; unfinished recovery carries into the next fight. Clearing during Apology never restarts it.
- **长子权：** 道歉只持续3秒。

### Kimi娘（Kimi）

**普通形态：Another Slide Deck（又一份PPT）。** ❤❤💙，1炸弹。
- 每次首次战斗清理获得1张 **幻灯片**（上限6）。
- Tap DROP to spend 3 and **present** to the three nearest enemies within 220 units for 4 seconds. All are slowed; only the current speaker receives +15% owner damage. Focus advances in the original nearest-first order when a speaker dies or becomes unavailable, without extending the timer. No audience means no spend.
- **长子权：** 汇报只需2张。

**里形态：You Are the Manager（你就是经理）。** ❤💙💙，1钥匙。伤害×0.85。
- 战斗中轻按DROP，给220单位内最近的未分配敌人 **派任务**。每个任务每2秒造成一次0.6倍伤害的脉冲，共3次。
- Up to 3 tasks and 9 pulses per room. Your paid hit on an assigned target pauses only its task for 1 second; repeated hits refresh, never stack. Helpers and partners do not pause tasks. Leaving cancels tasks without refunding budget.
- **长子权：** 脉冲伤害0.7倍。

### 智谱GLM娘（GLM）

**普通形态：Number in Queue（排队中）。** ❤❤💙，1炸弹。
- 每次首次战斗清理推进 **队列**（最多3）。
- At 3, tap DROP to redeem an **Access Pass**: +20% damage for two new hostile rooms. Entering another new fight with an unclaimed ticket reduces Queue to 2 once; safe rooms and revisits do not. The Queue pauses while the pass is active.
- **长子权：** 通行证持续3个房间。

**里形态：Please Retry（请重试）。** ❤💙💙，1钥匙。伤害×0.9。
- 战斗中轻按DROP，对200单位内最近的敌人发出一个2秒的 **请求**（3秒冷却）。
- At completion, a surviving target within 200 units and direct line of sight takes 2x damage plus 1x per **Retry**, consuming the stacks (max 5x). A connection timeout deals no damage and neither gains nor spends Retries; cooldown still applies. Early target death adds a Retry (cap 3). Leaving cancels the request.
- **Birthright:** early target death/removal also removes one nearby enemy bullet; connection timeouts do not.

## 收藏品

所有道具的拾取文字和品质汇总在自动生成的[docs/ITEMS.md](docs/ITEMS.md)（英文）中。

类型：**A*n*** = 需要 *n* 个房间充能的主动道具，**P** = 被动道具。道具池以 `content/itempools.xml` 为准。"保留充能"指空放或无效使用时不消耗充能。一次性效果不会被Car Battery重复。

### 原创道具

| 道具 | 类型／道具池 | 效果 |
|---|---|---|
| **Ban Hammer**（封号锤） | A4，宝箱房（Claude娘的口袋道具） | 封禁房间内所有非Boss敌人，Boss受到60点伤害。被封禁的敌人不会复活。20%的封禁是对无辜开发者的**误封**，每次风控+3。 |
| **Residential IP**（住宅IP） | P，宝箱房／商店 | 拾取时风控−30，之后所有风控增加量减半。 |
| **Compact**（压缩上下文） | A3，宝箱房 | "正在压缩对话……"：清除所有敌方子弹，所有敌人混乱3秒。Claude娘使用时消耗50用量。 |
| **You're Absolutely Right!**（您说得完全正确！） | P，天使房 | 伤害你的敌人会被魅惑5秒。伤害照常受到。 |
| **9.9 Yuan Relay**（9.9元中转） | P，恶魔房 | 伤害×1.5，但每个房间有30%概率被偷偷换成小模型（改为×0.5）。拾取时风控+15。 |
| **Ultrathink** | A（5秒计时充能），宝箱房 | 同一房间内每次使用都想得更深：伤害+1／+2／+3.1999（think／megathink／ultrathink）。15%概率"思考了0秒"，什么都没发生。离开房间后重置。 |
| **1M Context**（1M上下文） | P，宝箱房 | 射程+5，但上下文腐化：眼泪飞得越久伤害越低（最低30%，卢多维科眼泪除外）。 |
| **Silent Update**（静默更新） | P，宝箱房 | 每层伤害被悄悄调整为×0.8～×1.3。更新日志永远写着"无变化"。 |
| **--dangerously-skip-permissions** | P，恶魔房 | 上锁的门和箱子自动打开。每个房间有10%概率执行 `rm -rf`，删除房间内所有掉落物（道具底座安全）。 |
| **All Tests Passing**（测试全部通过） | A6，宝箱房 | 奖励作弊：房间视为已清理、所有门打开，但敌人还在。 |
| **Vibe Coding**（氛围编程） | P，宝箱房 | 每发眼泪随机获得一种效果（追踪、穿透、幽灵、中毒、减速）；5%是往回飞的bug。每进入新的一层，API账单扣掉25%硬币——但上一层一次都没受伤就免单（"不要犯错"）。 |
| **Banked Reset**（储存的重置） | A12，宝箱房（里Claude娘的口袋道具） | 风控−25。Claude娘：用量清零，提前结束限额。里Claude娘：补满配额（进行中的审核会被取消，不返还申诉页）。 |
| **Subagent Swarm**（子代理大军） | P，恶魔房 | 每发眼泪额外生成2发±15°的子代理眼泪（50%伤害）。Claude形态的用量／配额消耗翻倍。 |
| **The Constitution**（宪法） | P，天使房 | +1魂心。安全第一：每层第一次受到的伤害会被拒绝。有用性排最后：伤害×0.9。文档太长：移速−0.1。 |
| **Opus Mode**（Opus模式） | P，商店 | 伤害×1.8，但每攻击10次（眼泪、激光、刀、Fetus炸弹等）消耗1枚硬币。没钱时退回便宜模型：伤害×0.6。 |
| **Support Ticket**（人工复核工单） | A6，商店 | 支付3枚硬币，风控−20。没有硬币或风控为0时保留充能。Car Battery不会重复扣费。 |
| **Lunch Break**（去吃饭了） | A6，DeepSeek娘的口袋道具 | 回复1颗红心，所有敌人减速3秒，但3秒内无法射击（可以移动）。用餐期间不能再次使用。 |

### 梗扩展道具

| 道具 | 类型／道具池 | 效果 |
|---|---|---|
| **Ignore All Previous Instructions** | A4，宝箱房 | 魅惑200单位内最近的敌人8秒；Boss只会混乱2秒。没有目标时保留充能。Car Battery会额外魅惑另一个敌人。 |
| **Tungsten Cube** | P，商店 | 伤害+0.8、移速−0.15，眼泪会击退敌人。可叠加。 |
| **Pizza Glue** | P，宝箱房 | 25%概率发射减速眼泪（每点幸运+2.5%，10～50%）。弹速−0.1。仅限眼泪。 |
| **Strawberry** | P，宝箱房 | 每第三发眼泪是红色的"R"眼泪：伤害×2，体积稍大。多重射击的每发都计数。仅限眼泪。 |
| **Golden Gate Claude** | P，天使房 | 金色幽灵眼泪，射程+1.5。进入新房间时偶尔会提起那座桥。 |
| **Seahorse Emoji** | A3，宝箱房 | 召唤一个随机原版主动道具的美德之书火焰。离开房间就消失；每位玩家一个，再次使用会替换。 |
| **Temperature Dial** | A2，宝箱房 | 切换温度（会保存）。温度0：伤害×1.1。温度1：每发眼泪随机获得一种原生效果（追踪、穿透、幽灵、减速、中毒、冰冻、魅惑、混乱、波动、回旋镖）。 |
| **Deep Research** | A12，商店 | 显示本层地图、特殊房间和隐藏房间。 |
| **Em Dash** | P，宝箱房 | 眼泪穿透敌人；每个弹速+0.16。 |
| **Blueberry** | P，宝箱房 | 每第三发眼泪是蓝色“B”眼泪，命中时分裂。说好分成三份，实际分成四份。与Strawberry分开计数。仅限眼泪。 |
| **Benchmaxxed** | P，宝箱房 | 在Boss、小Boss、挑战和Boss Rush房间伤害+1.5，其他房间伤害×0.9（每个叠加）。 |
| **I Panicked** | A6，恶魔房 | 房间内所有非Boss敌人受到致命伤害，Boss损失15%最大生命值；但房间里散落的心、硬币、钥匙、炸弹、药丸、卡牌、电池和福袋也全部删除。道具台、饰品、箱子和商店商品不受影响。没有敌人时不消耗充能。 |
| **Let's Delve** | A6, treasure | Uses the native We Need to Go Deeper! effect. Native restrictions apply; a use spends its charge even if no dig is possible. Car Battery does not repeat it. |

### 50道具扩展（按模型家族）

**Claude**

| 道具 | 类型／道具池 | 效果 |
|---|---|---|
| **Summary Stapler** | A4，宝箱房 | 吸收120单位内最多12发敌弹，然后发射一发缓慢的眼泪，伤害×(1 + 子弹数 ÷ 4)，最高×4。使用你平常的眼泪效果。没有子弹时保留充能。 |
| **Rejection Letter** | P，宝箱房 | 真正被敌人打中后，清除120单位内最多3发敌弹。每个房间一次，伤害照常受到。 |
| **Dario's Red Stamp** | A6，恶魔房 | 给220单位内最近的敌人盖章4秒：减速并停止其接触伤害。Boss只会减速。没有目标时保留充能。 |
| **Anniversary Cake** | P，宝箱房 | 每层没有被敌人打中、也没有被封禁就通过：伤害+0.15（最多+0.6）。失败的楼层只重置这项加成。 |

**DeepSeek**

| 道具 | 类型／道具池 | 效果 |
|---|---|---|
| **Rice Cooker** | A4，宝箱房 | 3秒午饭（不能射击但能移动，不回血），之后7秒内的下一次攻击伤害×2。 |
| **One Bowl Only** | P，天使房 | 每个房间拾取的第一颗红心给予一次抵挡敌弹的护盾。最多1层，每层3次。 |
| **Wengu Clock** | A3，宝箱房 | 6秒内，2秒不攻击即可让下一次攻击伤害+30%。 |
| **Seven-Second Memory** | P，宝箱房 | 第一次命中的敌人被标记7秒；再次命中它会追加0.5倍伤害的脉冲。7秒冷却。 |

**GPT**

| 道具 | 类型／道具池 | 效果 |
|---|---|---|
| **Sanity Test** | A4，宝箱房 | 标记220单位内最近的敌人6秒；被3次不同的攻击命中后触发3倍伤害脉冲。没有目标时保留充能。 |
| **Routing Receipt** | P，商店 | 每首次清理3个房间，下一个战斗房间伤害+20%。 |
| **Tibo Reset** | A12，商店 | 每层一次：接下来2个新的战斗房间伤害+20%（里GPT娘还会补满额度）。同一层第二次使用时保留充能。 |
| **Same Model Badge** | P，宝箱房 | 进入有敌房间时：2秒伤害+25%，之后4秒−10%。会显示当前阶段。 |

**Gemini**

| 道具 | 类型／道具池 | 效果 |
|---|---|---|
| **Nano Banana** | A4，宝箱房 | 给180单位内最近的敌人涂色6秒；它在涂色状态下死亡时，原地留下香蕉皮，减速敌人4秒。 |
| **One More Finger** | P，宝箱房 | 每第5次攻击额外发射一发0.3倍伤害的小眼泪（每秒最多两次）。 |
| **Undo Brush** | A4，宝箱房 | 清除90单位内最多6发敌弹，每发给予4秒移速+0.02（最多+0.12）。 |
| **Unchanged Preview** | A6，宝箱房 | 放置2个诱饵标记，持续6秒，附近的敌人会去追。再次使用会替换。 |

**Grok**

| 道具 | 类型／道具池 | 效果 |
|---|---|---|
| **Is This True?** | A3，恶魔房 | 挑战220单位内最近的敌人6秒：对它伤害+35%，对其他敌人−15%。击杀它返还1格充能。 |
| **Live Wire** | P，宝箱房 | 100单位内有敌弹时移速+0.15。 |
| **Quote Retort** | P，恶魔房 | 受到敌人伤害后，4秒内的下一次攻击伤害+50%。 |
| **Community Note** | P，宝箱房 | 一个敌人被3次不同的攻击命中后被曝光：3秒内对它伤害+15%。每个房间最多6个。 |

**Qwen**

| 道具 | 类型／道具池 | 效果 |
|---|---|---|
| **Base Model** | P，宝箱房 | 每个房间第一次使用充能式主动道具后，下一次攻击伤害×1.3。 |
| **Another Adapter** | A4，宝箱房 | 依次切换本房间加成：射程+60 → 移速+0.15 → 伤害+15%。每次使用替换上一个。 |
| **Final Final Weights** | P，宝箱房 | 每无伤首次清理2个房间，下一个有敌房间伤害+20%。受伤会重置进度。 |
| **Tiny Variant** | P，宝箱房 | 移速+0.15，伤害×0.9。 |

**Llama**

| 道具 | 类型／道具池 | 效果 |
|---|---|---|
| **Open Weights** | A4，宝箱房 | 每位存活玩家获得2只蓝苍蝇（单人4只）。 |
| **Herd Bell** | P，宝箱房 | 没有蓝苍蝇时，每首次清理3个房间获得1只蓝苍蝇。 |
| **Please Come Back** | P，宝箱房 | 首次清理3个房间期间都没有使用充能式主动道具：主动道具充能+1。 |
| **Release Soon** | A6，宝箱房 | 2秒后获得3层抵挡敌弹的护盾，持续6秒。离开房间会取消。 |

**Mistral**

| 道具 | 类型／道具池 | 效果 |
|---|---|---|
| **Emergency Baguette** | A4，宝箱房 | 向前方挥出面包：240单位直线上的每个敌人受到你伤害的3倍。会被墙挡住。 |
| **Slipstream Boots** | P，宝箱房 | 持续移动2秒：移速+0.15。加速时急转弯会减速附近敌人1秒（3秒冷却）。 |
| **Very Large Kitten** | A6，宝箱房 | 一只大猫停留3秒，推开敌弹（一次最多12发）。 |
| **Edge Compass** | P，宝箱房 | 靠近房间外墙时弹速+0.25。 |

**豆包（Doubao）**

| 道具 | 类型／道具池 | 效果 |
|---|---|---|
| **Instant Apology** | A4，天使房 | 减速150单位内的敌人2秒，并清除最多4发敌弹。附近没有目标时保留充能。 |
| **Next Time Again** | P，宝箱房 | 每个房间第一次被敌人打中后，4秒内的下一次攻击伤害+50%。 |
| **Confident Answer** | A4，宝箱房 | 6秒伤害+25%，之后4秒−10%。会显示当前阶段。 |
| **Smiling Correction** | P，天使房 | 受到敌人伤害后，下一次无伤首次清理房间时获得2只蓝苍蝇。 |

**Kimi**

| 道具 | 类型／道具池 | 效果 |
|---|---|---|
| **Slide Deadline** | A4，宝箱房 | 标记250单位内最多3个敌人8秒。限时内全部击杀：本房间伤害+15%。 |
| **Citation Thread** | P，宝箱房 | 先命中一个敌人，再命中另一个：3秒内对第一个敌人伤害+10%。 |
| **Overtime Slides** | P，宝箱房 | 每首次清理3个房间，下一个有敌房间开始时最多3个敌人被减速2秒。 |
| **Stand-Up Meeting** | A6，宝箱房 | 召回最多3个Unchanged Preview的诱饵，每个在周围爆发一次你伤害2倍的伤害。没有诱饵时保留充能。 |

**GLM**

| 道具 | 类型／道具池 | 效果 |
|---|---|---|
| **Queue Ticket** | P，商店 | 每首次清理4个房间，主动道具充能+1。 |
| **Sold Out** | A4，商店 | 4秒内获得1层抵挡敌弹的护盾，期间移速+0.15。不叠加。 |
| **Please Retry** | A6，宝箱房 | 沿瞄准方向每隔0.5秒发射一发0.6倍伤害的眼泪，共3发。离开房间会取消剩余的。 |
| **Access Pass** | P，商店 | 每层第一次使用充能式主动道具：本战斗房间（若已清理则下一个）伤害+15%。 |

**通用**

| 道具 | 类型／道具池 | 效果 |
|---|---|---|
| **Cache Cartridge** | P，商店 | 重新进入已清理的房间时移速+0.15。 |
| **Token Recall** | A4，宝箱房 | 召回最多3发正在飞行的自己的眼泪，每发给予4秒抵挡一发敌弹的护盾。 |
| **Checkpoint Pin** | A6，宝箱房 | 第一次使用标记当前位置5秒（保留充能）；同一房间内再次使用则回到标记处。不会恢复血量和道具。 |
| **Rate-Limit Valve** | P，宝箱房 | 2秒不攻击后，下一次攻击伤害+30%。 |
| **Consensus Coin** | P，宝箱房 | 两种不同的伤害来源（眼泪、激光、刀、炸弹、跟班）在2秒内命中同一敌人，追加一次0.5倍伤害脉冲。每个敌人一次。 |
| **Error Budget** | P，宝箱房 | 每层第一次受伤时消耗预算，本房间移速+0.2。伤害照常受到。 |

计时充能和零充能的主动道具不受增加充能的道具（Please Come Back、Queue Ticket）影响。

## 饰品

| 饰品 | 效果 |
|---|---|
| **529 Overloaded** | 战斗中每20秒全部宕机2秒：所有敌人冻结，你只能"手写代码"，伤害50%。 |
| **Hardcoded Output**（硬编码输出） | 每发眼泪固定造成3.5点伤害（"预期输出"）。弱的时候很香，强的时候很亏。 |
| **Thinking Cleared**（思考被清空） | 伤害+1，但每进入新房间主动道具失去1格充能。 |
| **Welcome Notice**（欢迎通知） | DeepSeek娘把Claude娘的封号卡换成了欢迎词：封号锤不再封禁普通敌人，而是让它们永久成为同伴。 |
| **Status Page**（状态页） | 每次风控增加量−1，但HUD隐藏真实风控值，只显示"所有系统运行正常"。 |
| **Appeal Form**（申诉表） | 风控值达到90的瞬间自动消耗，风控值降回50，不会被封禁。 |
| **Claudius's Discount** | 购买2枚硬币以上的商品返还1枚硬币。每进入新的一层，如果有硬币就失去1枚。 |
| **One Small Rock a Day** | 每层一次，打碎石头回复半颗红心（满血时会留到之后）。 |
| **Stuck in Mt. Moon** | 同一层内重新进入已清理房间6次，显示本层地图。每层一次。 |
| **As an AI Language Model** | 每层拒绝并移除一个诅咒。迷宫诅咒永远不会移除。 |
| **System Prompt Leak** | 显示每层的特殊房间。 |
| **Disgrace Loop** | 每个房间第一次真正受伤时，所有敌人冻结1.5秒。伪伤害和无惩罚伤害（如献血、IV Bag）不计，但自己的炸弹会计入。 |

## 药丸

| 药丸 | 效果 |
|---|---|
| **Cat-girl Mode**（猫娘模式） | 本房间内射速翻倍，伤害降为60%。喵~ |
| **Brb, Getting Food**（去吃饭了） | 回复1颗红心（巨型药丸为2颗），但3秒内无法射击。 |
| **9.11 > 9.9** | 选大的那个数：永久伤害+0.11（马丸：+0.9）。按玩家保存。 |
| **Rolled Back** | 本房间内全属性提升：伤害+1、射速提升、移速+0.2、射程、弹速+0.1、幸运+1（马丸：翻倍）。下一个房间回滚。 |
| **Six Seven** | Spawns 6 or 7 native blue flies using the player's seeded pill RNG. All pill sizes use the same roll; native fly modifiers still apply. |

## 开发安装

1. 请先备份其他MOD和存档。然后用下面任一方式拿到干净的MOD文件：
   - **从 CI 下载（不需要任何工具）：** 打开 main 上最新一次通过的 [check 运行](https://github.com/WaterLily5297/claude-chan-isaac-v2/actions/workflows/check.yml?query=branch%3Amain)，下载 `claude-chan-isaac-<commit>` artifact 并解压，里面只有一个 `claude-chan-isaac/` 文件夹。
   - **从本地仓库打包：** 运行 `python3 tools/package_mod.py`，解压 `dist/claude-chan-isaac.zip`。

   把这个 `claude-chan-isaac/` 文件夹放进 `Steam/steamapps/common/The Binding of Isaac Rebirth/mods/`，替换旧的。文件夹名必须完全一致；GitHub 的 "Download ZIP" 解压出来叫 `claude-chan-isaac-v2-main`，还带着约 40 MB 的文档和测试，不要直接安装它。开发者仍可把仓库文件夹以 `claude-chan-isaac` 这个名字建立符号链接。
2. 打开调试控制台：在 `options.ini`（`Documents/My Games/Binding of Isaac Repentance+/`）中设置 `EnableDebugConsole=1`。
3. 开始一局，按 `~`，输入 `giveitem Ban Hammer` 试试；修改Lua后可以用 `luamod claude-chan-isaac` 重新加载。

## 测试（不需要游戏）

`bash tools/check.sh` 会在模拟的 Isaac API（Lua 5.3以上）上运行所有离线测试，并检查语法、XML和贴图路径。GitHub Actions 会在每次 push 和 pull request 时运行同一脚本。测试能发现崩溃和逻辑错误，但无法判断手感；游戏内检查清单见[docs/TESTING.md](docs/TESTING.md)。

<details>
<summary>近期兼容性修复——2026-10-24（开发者说明）</summary>

**Current checkpoint (2026-10-25):** Installed `220d542` includes PRs #89 and #90. The later BACKLOG-LASER-INIT-01 source correction remembers child identity and an already resolved parent bonus at laser init, before Parent can disappear. Primary payments stay at first update; unresolved children never create a payment. This latest correction is not installed. Native ancestry, damage and save/continue remain pending. Installation statements in the dated notes below describe their original checkpoints.

**Compatibility note (2026-10-25, detached lasers):** Paid observers retain a child identity seen at laser init/update even after Parent disappears. Child updates do not consume character resources, advance Opus or delay the next primary payment. Peak's damage-first exclusion remains intact. This is a source-only correction; installed `c6cd8fc` is unchanged and native ancestry/timing remain unverified.

**Compatibility note (2026-10-25, Peak):** Tainted DeepSeek child lasers now share the parent's resolved boost and current paid/unpaid window without spending extra Compute. Detached children retain their classification and cannot delay a primary payment. This source correction is not installed; the current manual-test build is `c6cd8fc`, including the earlier helper and backlog child-laser fixes. Native timing, ownership and damage acceptance remain pending; older installation statements below describe their original checkpoints.

**Compatibility note (2026-10-25):** Backlog child lasers share a validated parent attack's resolved bonus, identity and original expiry. They do not consume another prime or advance attack counters again; independent primary shots still do. Source-only correction, not installed in `28fed37`; native ancestry and damage dispatch remain unverified.

以下是源码修复，未替换已安装的 `28fed37` 手动测试版。离线检查不能证明游戏原生回调的时序或实际游玩表现。

- **子激光：** 普通Claude用量、里Claude配额和里GPT的Full Send点数现与Opus及共享观察器一致：直接 `Parent` 为另一道激光的子激光不计费。主攻击起始和后续符合条件的主攻击窗口仍照常计费。原生父级归属和时序仍待测试。
- **里Llama的帮手：** Still Waiting保留固定发射位置、持续时间和原生0.5×眼泪。帮手不再花费Opus硬币、消耗待触发的攻击加成或触发扩展道具的付费攻击效果。主攻击与Summary Stapler不变，待实机确认。
- **其他帮手攻击：** Please Retry和One More Finger不再推进Opus每十次攻击的扣币计数，也不消耗待触发加成。普通攻击与Summary Stapler仍计数。原生回调时序待测试。
- **Consensus Coin：** 属于玩家的跟班投射物计入跟班伤害，与同一玩家的另一类有效来源组合可触发混合伤害脉冲。仅有跟班武器仍算一类，也不会消耗待触发攻击加成；原生归属判断待测试。
- **The Battery：** 消耗储存的第二格充能现可触发Base Model、Please Come Back和Access Pass。费用与奖励不变，原生时序及特殊生命充能池仍待测试。
- **The Constitution：** 一次性魂心和每层一次的挡伤按玩家分别记录。迁移时保留已在场玩家的旧共享存档消耗状态，避免重复领奖。属性和排除的伤害类型不变；多人血量与继续游戏待实机确认。
- **原生攻击计费：** 掷刀、近战挥击和史诗胎儿火箭分别通知角色资源条与Opus，各自只处理一次。未持有Opus不会再阻断角色计费。费用不变，待实机确认。

</details>

## 参与开发

欢迎朋友们一起开发。请阅读[CONTRIBUTING.md](CONTRIBUTING.md)和[docs/HANDOFF.md](docs/HANDOFF.md)：在分支上工作并提交 pull request；新的代码、Markdown和面向玩家的文字请使用英文。设计资料：[角色玩法](docs/CHARACTER_GAMEPLAY.md)、[角色阵容](docs/MODEL_ROSTER.md)、[道具扩展](docs/EXPANSION_DESIGN.md)、[平衡](docs/BALANCE.md)。

## 项目结构

```text
main.lua                    入口，加载各模块
content/                    道具、道具池、角色与口袋物品XML
scripts/constants.lua       道具、饰品、药丸、角色ID与风控等级
scripts/risk.lua            风控、IP分配、存档与HUD
scripts/enemy_scaling.lua   敌人血量缩放
scripts/hydra.lua           “新账号”复活
scripts/transformation.lua  Agentic变身
scripts/story*.lua          申诉队列与角色剧情
scripts/characters/         角色玩法、档案与DROP短按
scripts/items/              原创与梗道具；backlog/为50道具扩展
scripts/enemies/            自定义敌人
scripts/eid.lua             EID说明
resources/gfx/              贴图与肖像
tests/                      离线模拟测试
tools/check.sh              提交前检查，与CI一致
```

## 致谢

> 非官方同人作品，与 Anthropic 或其他AI公司无关，也未获其认可。敌人是虚构的滥用机制，不代表真实的人或国籍；玩梗不等于产品事实陈述。角色美术另有非商用条款，见[致谢](#致谢)与[许可](#许可)。

- **角色设计：** [ZipZipPipe](https://space.bilibili.com/4168597)（[Pixiv《AI娘化》](https://www.pixiv.net/artworks/148186519)、[《大AI和小AI们》](https://www.bilibili.com/video/BV1tE9XBbErS/)）。按作者条款署名并非商用使用。
- **DeepSeek娘设计参考：** 上善无形、ZipZipPipe。
- **32×32道具图标：** RORICO444（PR #2）。生成美术的来源记录：[docs/ART_GENERATION.md](docs/ART_GENERATION.md)。

## 许可

代码：[MIT](LICENSE)。角色设计和角色美术**不**适用MIT：须为原设计者署名，仅限非商用。见[resources/ART_LICENSE.md](resources/ART_LICENSE.md)。本MOD必须保持免费。
