# Claude-chan: Risk Control

[English](README.md) · **日本語** · [中文](README.zh-CN.md)

『The Binding of Isaac: Repentance / Repentance+』にAIモデルの擬人化キャラを追加するMODです。

きっかけは、BilibiliでのClaudeのBANネタとAI擬人化でした。これをアイザックで遊べるようにしたら面白そう、というところから作り始めました。

ClaudeちゃんはBANハンマーを持っていますが、自分の使用量やリスク、異議申し立てにも気を配らないといけません。その後ほかのモデルも増えて、DeepSeekちゃんはご飯で思考をため、GPTちゃんは性能を落とされ、Kimiちゃんは怪物相手にスライド発表をします。今は11キャラいて、それぞれ通常版と裏版があります。

アイテムも同じような発想で作っています。All Tests Passingはドアを開けますが、敵は生きたまま。Silent Updateはフロアごとにダメージを変えるのに、更新履歴には「変更なし」と書きます。詳しい効果や操作は下にまとめました。

## 開発状況

現在は **0.5-dev**。まだ制作中で、Workshopには公開していません。

| 内容 | 数 |
|---|---|
| プレイアブル形態 | **22**：通常11 + 裏11 |
| Collectibles | **80**: 17 original items, 13 meme extras and the 50-item expansion ([design](docs/EXPANSION_DESIGN.md)) |
| トリンケット | **12** |
| Pills | **5** |
| 敵 | 1（中継スライム） |
| 変身 | 1（Agentic） |
| ストーリー | 異議申し立ての列（4章）＋ 他のモデル系統ごとに3章のアーク |

以下の内容はソースに実装済みで、オフラインテストは通っています。22形態ともゲーム内で基本的な起動確認をしました（[記録](docs/ENGINE_AUDIT_2026-10-24.md)）が、バランスや武器の組み合わせ、協力プレイの確認はまだ終わっていません。確認済みの範囲と残りの項目は[テストメモ](docs/TESTING.md)をご覧ください。数値は今後変わるかもしれません。

## 目次

- [共通の操作とルール](#共通の操作とルール)
- [コアシステム](#コアシステム)
- [キャラクター](#キャラクター)
- [コレクティブル](#コレクティブル)
- [トリンケット](#トリンケット)
- [薬](#薬)
- [導入・テスト・開発参加](#開発用の導入方法)

## 共通の操作とルール

ゲーム内の名前や説明は、まだ英語が中心です。ゲーム内で探しやすいよう、ここでも英語のアイテム名を使っています。

- **DROP tap:** release after 1-12 gameplay frames to use a character ability, but only while carrying at most one pocket item. Two or more cards, pills or pocket actives disable the ability so DROP can select them normally. The main active and Schoolbag slots do not count as pocket items. If multiple pocket items are observed during a press, that entire gesture is cancelled even if one item is used or dropped before release. Release and press again after reducing the inventory. Long holds never use the ability; native input is not overridden. A press interrupted by a room change, pause or run start must be released first.
- **ドシエ（人物紹介）：** クリア済みの部屋でMAPを押し続けると、現在のキャラクターの立ち絵と3行の説明が表示されます。離すと閉じます。戦闘中は表示されません。
- **「自分の攻撃」** とは、自分で撃つ攻撃（涙、レーザー、ナイフ、爆弾など）のことです。アイテムによる追撃やヘルパーの攻撃は含まれないため、効果が自分自身に連鎖することはありません。
- **「新規の戦闘クリア」** とは、敵のいる部屋を初めてクリアすることです。クリア済みの部屋に入り直しても数えられないので、稼ぎはできません。
- **「通常の敵弾」** とは、普通の敵の弾のことです。弾を消す効果で、すでに受けたダメージが取り消されることはありません。
- キャラクターのリソースはプレイヤーごとに保存され、セーブ＆コンティニューでも保持されます。新しいランでリセットされます。協力プレイでは各プレイヤーが別々の状態を持ちます。
- すべての能力はゲーム本来の武器・涙効果・ステータス計算を使います。本来の武器、サイズ、変身はそのまま維持されます。キャラクターの見た目は固定で、アイテムのコスチュームは表示されませんが、アイテムの効果は通常どおり適用されます。
- [External Item Descriptions（EID）](https://steamcommunity.com/sharedfiles/filedetails/?id=836319872)に対応しています。全アイテムと全22形態には英語の説明があります。コレクティブル17個、トリンケット6個、薬2個には簡体字中国語と日本語の説明もあります。

## コアシステム

### リスク値（风控值）：Claude形態のみ

リスクシステムは、ランに通常版または裏版のClaudeちゃんがいるときだけ動きます。DeepSeekちゃんは直結で、他の9系統は独自のループを持つため、IPもリスクも、リスクによる難易度上昇もありません。Claudeとの協力プレイでは、Claudeのプレイヤーだけがリスクを上げたり停止の影響を受けたりします。

- フロアごとにランダムな**プロキシIP**と、その共有人数が決まります。ほとんどは少人数ですが、30%は混雑した中継サーバーです。新しいフロアごとにリスクが「共有人数 ÷ 10 + ステージ番号」だけ上がります。
- 被弾：リスク **+1**。被弾せずに部屋をクリア：リスク **−1**。
- 段階：**Clean**（0）、**Suspicious**（30）、**Flagged**（60）、**Suspended／停止**（90以上）。停止中は、リスクが90未満に戻るまでClaudeのプレイヤーのダメージが **×0.75** になります。
- 画面左下のHUDにIP、共有人数、リスク段階が表示されます。Claudeのいないランでは「Direct connection（直結）」と表示されます。
- **敵の強化：** 敵のHPはリスク0で×1、リスク100で×3まで直線的に上がります。
- **ヒドラアカウント：** リスク40以上では、倒した敵が一度だけ赤い「新アカウント」として復活することがあります。確率はリスク40で10%、リスク100で50%まで上がります。BANされた敵は復活しません。

### 中継スライム（敵）

共有プロキシを表す敵です。リスクが30に達すると、未クリアの部屋の25%に出現します。倒すと2体に分裂し、これが2回起きるため、1体が最大7体になります（分裂するたびに小さく弱くなります）。*（仮グラフィック：緑色に着色したバニラのClotty）*

### Agentic（変身）

Ultrathink、Compact、Vibe Coding、Subagent Swarm、--dangerously-skip-permissions、All Tests Passing のうち **3つ** を持つと変身します。効果：**飛行**、連射間隔×0.8（連射アップ）、**ダメージ+0.5**。

### ストーリー

- **異議申し立ての列（The Appeal Queue）**（Claudeのラン）：ゲームを止めない短いキャプションが4つあり、英語・中国語・日本語に対応しています。章は「共有されたアドレス」（新しいラン）、「歓迎のお知らせ」（ステージ3か4に初めて到達）、「審査待ち」（ステージ5以降）、「ついに人間が読んでくれた」（Support Ticketの使用に成功した後）です。各章は1ランに1回だけ流れ、進行状況はセーブ＆コンティニューでも保持されます。バニラのカットシーンやエンディングは変更しません。
- **ロスターアーク：** DeepSeek、GPT、Gemini、Grok、Qwen、Llama、Mistral、Doubao、Kimi、GLMにはそれぞれ3章のアークがあり、その系統がランにいるときに流れます（新しいラン、ステージ3〜4、ステージ5以降）。現在は英語のみです。詳しくは[docs/STORY.md](docs/STORY.md)をご覧ください。

### 互換性

- 固定外見：22形態すべてが、バニラやMODのアイテム、トリンケット、ピル、カード、変身を取っても固有のスプライトを保ちます。アイテムの効果、ステータス、飛行、サイズは通常どおり適用され、コスチュームのレイヤーだけが消されます。ゲーム内では未確認です。
- EIDの説明（上記）。
- HUDの文字は、CJKフォントが読み込めればゲームの言語（中文／日本語）に合わせ、読み込めなければ英語になります。
- Reactions Port Pack：フォールバック登録で全キャラクターに対応しています。
- 各キャラクターは現在の涙の色の上に色味を重ねるだけなので、アイテムによる色は保たれます。
- 能力の演出はバニラのエフェクトのみを使います：MistralのPounceとバゲットの波、Doubaoのお詫びには土煙、Kimiのタスク対象とGLMのリクエスト対象には消えていく色味が付きます。

## キャラクター

体力の表記：❤ = 赤ハート、💙 = ソウルハート。特に記載がなければ、通常版は ❤❤💙 と爆弾1個、裏版は ❤💙💙 と鍵1個で始まります（裏Claudeちゃんは代わりに爆弾1個、裏DeepSeekちゃんはどちらもなし）。「ダメージ×N」は最終ダメージへの倍率です。誕生権（Birthright）による強化も形態ごとに記載しています。

### Claudeちゃん（Claude）

**通常版：One More Day（あと1日）。** ❤❤💙、爆弾1。射程+1.5（ロングコンテキスト）、弾速+0.2、移動速度−0.1、オレンジ色の涙。ポケットアイテム：**Ban Hammer（BANハンマー）**。
- **Usage:** each paid volley adds 4 usage (8 with Subagent Swarm), billed for every native weapon: each volley of tears, each laser start and Dr. Fetus bomb, each further 0.2 seconds of a held beam or steered Ludovico tear, each knife throw, each melee swing and each Epic Fetus rocket. Familiars and derived tears are free. Not firing drains 10 per second. At 100 she is **Limited**: every weapon deals 40% damage for 5 seconds, then the meter resets.
- **異議申し立て（Appeal）：** 1回分を持って始まります（上限2）。新規の戦闘クリア2回ごとに1回分増えます。DROPをタップすると1回分を使って使用量を40減らします。発動中のLimitedは解除できず、使用量0のときは無駄にならないよう拒否されます。
- **Account age:** from the second floor, the first new fight with at least two vulnerable enemies marks a **Review Target**. Defeat it last for the original +0.2 damage (cap +1.6); simultaneous room-clear deaths count. Early defeat, leaving or an unavailable target misses only this floor. No eligible room means no award. Suspension and the Birthright shield keep their existing rules.
- **リスク：** 上記のリスク値の対象です。
- **誕生権：** 各フロアで最初の停止を受けてもアカウント年齢を保持します。

**裏版：Appeal Pending（審査待ち）。** ❤💙💙、爆弾1。ダメージ×1.25、射程+1.5、弾速+0.2。赤い髪に黒と金のドレス。ポケットアイテム：**Banked Reset（バンク済みリセット）**。
- **クォータ：** 各フロアはクォータ220と異議申し立てページ2枚（上限2）で始まります。攻撃1回ごとにクォータを1消費します（Subagent Swarm所持時は2）。課金の対象は通常版Claudeちゃんと同じく、すべての武器です。
- クォータが0になると **停止（Suspended）**：ダメージ×0.5。
- While Suspended, tap DROP to spend a Page on a **6-second review**. Its timer runs in combat only while you stop attacking; shooting pauses it without spending another Page. Completion restores 60 Quota. Leaving cancels the review.
- 新規の戦闘クリア3回ごとにページが1枚増えます。Banked Resetはクォータを即座に満タンにしますが、進行中の審査は取り消され、ページは戻りません。
- **誕生権：** 審査で回復するクォータが90になります。

### DeepSeekちゃん（DeepSeek）

**通常版：Rice First（まずはご飯）。** ❤❤💙、コイン3、鍵1。ダメージ×0.9、青い涙。ポケットアイテム：**Lunch Break（飯食ってくる）**。
- **直結（直连）：** プロキシ不要なので、DeepSeekだけのランにはIPもリスクも、リスクによる難易度上昇もありません。
- **Rice bowls:** start with 1 (cap 2). Earn 1 per two unique combat clears. Stand still and tap DROP for a 2-second meal without healing. Finishing grants full Thought and +0.15 speed for 6 seconds. Voluntary movement cancels, refunds this Bowl once and grants no meal reward; other food lockouts remain separate.
- **思考：** 攻撃をやめると最大5秒分の思考がたまり、次の攻撃のダメージが最大×2になります（「Thought for N s」と表示）。涙、離したブリムストーンのリング、投げたナイフ、Dr. Fetusの爆弾は撃った時点の思考を記録します。連続ヒットするビームや操作型の涙は0.2秒の短い枠を使います。Epic Fetus、近接、使い魔、遅延爆発はまだ実験的です。
- 涙がランダムに消えることも、放置でチャージがたまることもありません。
- **誕生権：** 食事が1秒になります。

**裏版：Wenfeng / Wengu（ピーク／バレー）。** ❤💙。ダメージ×0.8、シアンの涙。こちらも直結です。
- 戦闘中は **バレー** 12秒と **ピーク** 12秒が交互に切り替わります。空の部屋ではタイマーが止まり、各フロアはバレーから始まります。
- **Compute:** start 12, total cap 24 (32 with Birthright), carried across floors. Entering Peak reserves up to 4 available Compute. Return it once at the next Valley or floor, within the total cap; it cannot be spent during Peak.
- 涙を撃つたびに ±12° に2発の **フォーク**（ダメージ50%）が追加されます。コストはバレーで2、ピークで4です。計算資源が足りないときはフォークだけが省かれ、本体の涙は必ず出ます。
- バレー中は、戦闘中に撃たずにいると毎秒3回復します。
- DROPタップで **Forks On／Saving（節約）** を切り替えます（1秒のクールダウン）。
- **オフピーク割引：** 涙以外の攻撃は涙と同じ計算資源（バレー2、ピーク4）を払い、×1.3のダメージで当たります。対象はレーザーの撃ち始めと押し続けるビームの0.2秒ごと、ナイフの投擲、近接の一振り、Dr. Fetusの爆弾、Epic Fetusのロケットです。Savingモード中や計算資源が足りないときは、通常のダメージで消費もありません。
- **誕生権：** 計算資源の上限が32になります。

### GPTちゃん（GPT）

**通常版：Same Name, Smaller Brain（同じ名前、小さい脳）。** ❤❤💙、爆弾1。
- **Verified（認証済み）：** ダメージ×1.15。新規の戦闘クリアでRoutingがたまり、3になると次の戦闘部屋は **Fallback（代替）**（ダメージ×0.8）で始まります。
- In Fallback, tap DROP to tag a **Sanity Check** enemy. Three distinct paid hits or your defeat of it restore Verified. A distinct off-target attack erases one hit, minimum zero; the target wins for a mixed attack, including delayed piercing hits. Helpers, unpaid hits and partners do not contradict. One check per room; leaving fails it. New floors restore Verified.
- **誕生権：** Sanity Checkに必要な命中が2回になります。

**裏版：Reset Watcher（リセット待ち）。** ❤💙💙、鍵1。
- **クレジット：** 1ランにつき80（上限80）。フロアをまたいで持ち越します。
- DROPタップで **Standard（無料）** と **Full Send**（ダメージ×1.5、攻撃1回ごとにクレジット1。Claudeちゃんの使用量と同じくすべての武器が対象）を切り替えます。クレジットが0になるとStandardに戻ります。
- Every three unique combat clears **bank a Tibo reset**. While banked, progress pauses. Claim it with DROP in a cleared room; combat taps still toggle modes and keep the reset.
- **誕生権：** 上限と回復量が100になります。

### Geminiちゃん（Gemini）

**通常版：Nano Banana。** ❤❤💙、爆弾1。
- **ペイント：** 初期2（上限3）。新規の戦闘クリアごとに1増えます。
- Tap DROP to spend one and paint the nearest enemy within 180 units for 8 seconds. The first second dries at native damage, then your damage to it is x1.2. Your kill, including during drying, leaves a **banana peel** slowing enemies for 4 seconds. One mark and peel per player; bosses can be painted.
- **Birthright:** x1.3 damage to the painted enemy after drying.

**裏版：One More Edit（もう1回だけ編集）。** ❤💙💙、鍵1。ダメージ×0.9。
- Tap DROP for a 6-second **edit chain** on the nearest enemy within 180 units. Three distinct paid hits advance **Crop, Recolor, Export**. The first sets your angle; each next step needs at least 30 degrees of movement around the target. Unchanged angles still deal native damage; zero separation cannot set an angle.
- Exportで自分のダメージの2倍の追撃が1回入ります。チェーンの完成は1部屋1回です。
- もう一度タップするとチェーンが最初からになり、進行は消えます。途中で敵を倒しても完成にはなりません。
- **誕生権：** チェーンが10秒になります。

### Grokちゃん（Grok）

**通常版：Is This True?（これって本当？）。** ❤❤💙、爆弾1。
- 敵のいる部屋につき1回、DROPをタップすると220ユニット以内で最も近い敵を6秒間 **ファクトチェック** します。その敵へのダメージは×1.3、それ以外へは×0.9になります。
- Three distinct paid hits on it, or its defeat, **verify** it: the modifiers end and you gain +0.15 speed for the room. A timeout or one continuous second without direct line of sight ends it unverified; briefly restored sight resets that obstruction timer.
- **誕生権：** 検証完了時に近くの敵弾を最大3発消します。

**裏版：Quote Without Reading（読まずに引用）。** ❤💙💙、鍵1。ダメージ×0.9。
- DROPをタップすると、220ユニット以内で最も近い敵を6秒間 **引用** します（クールダウン10秒）。
- Paid hits on *other* eligible enemies build **Ratio** once per attack, cap 3. A paid attack hitting only the quoted enemy removes one Ratio, minimum zero. Other-target hits win for a mixed attack, regardless of callback order; helpers, unpaid hits and partners do not affect it.
- 6秒が終わると、引用した敵にRatio 1につき1倍ダメージの追撃が入ります。先に死んだ場合Ratioは無駄になり、対象の変更もできません。
- **誕生権：** 引用した敵が先に死んだ場合、Ratioの半分が最も近い生存中の敵に移ります。

### Qwenちゃん（Qwen）

**通常版：Everyone's Base Model（みんなのベースモデル）。** ❤❤💙、爆弾1。
- **アダプター：** 初期1（上限2）。新規の戦闘クリア2回ごとに1増えます。
- Tap DROP to pick **Range** (+60 range), **Tempo** (x0.9 firing interval) or **Power** (x1.1 damage). A new hostile room spends an Adapter; stop attacking for one continuous second to install its full room bonus. Firing restarts installation. Leaving discards the spent Adapter.
- **誕生権：** アダプターの上限が3になります。

**裏版：Final Final Fine-Tune（最終最終ファインチューン）。** ❤💙💙、鍵1。
- In a cleared room, tap DROP to cycle **Heavy** (x1.3 damage, x1.2 interval), **Tiny** (x0.85 damage, x0.8 interval) or **Balanced**. A new selection pins the build through two new combat clears. Safe rooms, duplicates and revisits cannot shorten the commitment.
- Clear unique combat rooms with all three builds for **+0.2 damage this floor**, up to three awards. Repeating a build does not add a variant. A new floor resets progress/bonus, selects Balanced and releases the pin for an immediate choice.
- **誕生権：** 1回あたり+0.3になります。

### Llamaちゃん（Llama）

**通常版：Please Stay Open（オープンのままでいて）。** ❤❤💙、爆弾1。ダメージ×0.95。
- **リリース：** 初期1（上限2）。新規の戦闘クリア2回ごとに1増えます。
- In a cleared room, tap DROP to spend one: every living player (up to four) gets 2 **blue flies**. Solo, you get 4. Combat attempts retain the Release.
- **誕生権：** 自分はハエを2匹多く得ます。

**裏版：Still Waiting（まだ待ってる）。** ❤💙💙、鍵1。ダメージ×0.9。
- 新規の戦闘クリアごとに **期待（Hype）** が1たまります（最大3）。
- Tap DROP to spend all Hype on a stationary **helper** lasting 4 seconds per Hype. It fires one 0.5x native tear per second at the nearest enemy only while you stay within 120 units. Lifetime continues outside; return resumes the cadence without catch-up. One helper at a time; replacing or leaving removes it.
- **誕生権：** 期待1につき5秒になります。

### Mistralちゃん（Mistral）

**通常版：Le Chat（猫）。** ❤❤💙、爆弾1。移動速度+0.1。
- Move while firing for 2 seconds to charge a **Pounce**, storing your movement direction. A full charge in another direction replaces it. Standing still for 1 second loses it.
- Tap DROP for a swipe in the **stored direction**, shown in the HUD: 2x damage once per enemy in an 80-unit line. Later aim changes do not redirect it. Walls block it; cooldown remains 3 seconds.
- **誕生権：** 射程が110ユニットになります。

**裏版：Le Gros Chaton（大きな子猫）。** ❤💙💙、鍵1。移動速度−0.1、ダメージ×0.9。
- In hostile combat, stand still without firing for 2 seconds to bake a **Baguette** (max 2). Cleared rooms pause partial baking; room exit discards the partial charge.
- DROPタップで1本使い、前方へゆっくり進む **衝撃波** を放ちます。120ユニット進み、敵それぞれに2.5倍ダメージを1回与えます。壁で止まり、クールダウンは2秒です。
- **誕生権：** バゲットが1.5秒で焼けます。

### Doubaoちゃん（Doubao）

**通常版：Sorry, You're Right（すみません、おっしゃる通りです）。** ❤❤💙、爆弾1。
- 各部屋で敵から最初に受けた被弾で、6秒間有効な **お詫び（Apology）** トークンを得ます。自傷、偽ダメージ、献血機などは数えません。
- Tap DROP for a **120-degree slow cone** centered on your aim, within 100 units, lasting 2 seconds. With no aim, use the last direction, initially Down. Removal of up to four nearby enemy bullets remains radial. No health refund.
- **誕生権：** トークンが部屋を出るまで持続します。

**裏版：I'll Do It Again（次もやります）。** ❤💙💙、鍵1。
- 準備完了のときにDROPをタップすると、6秒間の **自信満々（Confident）**（ダメージ×1.35）、続いて4秒間の **お詫び（Apology）**（×0.85）を経て、再び準備完了になります。
- Timers only run in hostile combat. An enemy hit or a hostile room clear during Confident starts Apology immediately; unfinished recovery carries into the next fight. Clearing during Apology never restarts it.
- **誕生権：** お詫びが3秒になります。

### Kimiちゃん（Kimi）

**通常版：Another Slide Deck（またスライド資料）。** ❤❤💙、爆弾1。
- 新規の戦闘クリアごとに **スライド** を1枚得ます（上限6）。
- Tap DROP to spend 3 and **present** to the three nearest enemies within 220 units for 4 seconds. All are slowed; only the current speaker receives +15% owner damage. Focus advances in the original nearest-first order when a speaker dies or becomes unavailable, without extending the timer. No audience means no spend.
- **誕生権：** プレゼンのコストが2枚になります。

**裏版：You Are the Manager（あなたがマネージャー）。** ❤💙💙、鍵1。ダメージ×0.85。
- 戦闘中にDROPをタップすると、220ユニット以内でまだ割り当てていない最も近い敵に **タスク** を割り当てます。各タスクは2秒おきに0.6倍の追撃を3回与えます。
- Up to 3 tasks and 9 pulses per room. Your paid hit on an assigned target pauses only its task for 1 second; repeated hits refresh, never stack. Helpers and partners do not pause tasks. Leaving cancels tasks without refunding budget.
- **誕生権：** 追撃が0.7倍になります。

### GLMちゃん（GLM）

**通常版：Number in Queue（順番待ち）。** ❤❤💙、爆弾1。
- 新規の戦闘クリアごとに **キュー** が進みます（最大3）。
- At 3, tap DROP to redeem an **Access Pass**: +20% damage for two new hostile rooms. Entering another new fight with an unclaimed ticket reduces Queue to 2 once; safe rooms and revisits do not. The Queue pauses while the pass is active.
- **誕生権：** パスが3部屋分になります。

**裏版：Please Retry（再試行してください）。** ❤💙💙、鍵1。ダメージ×0.9。
- 戦闘中にDROPをタップすると、200ユニット以内で最も近い敵に2秒間の **リクエスト** を送ります（クールダウン3秒）。
- At completion, a surviving target within 200 units and direct line of sight takes 2x damage plus 1x per **Retry**, consuming the stacks (max 5x). A connection timeout deals no damage and neither gains nor spends Retries; cooldown still applies. Early target death adds a Retry (cap 3). Leaving cancels the request.
- **Birthright:** early target death/removal also removes one nearby enemy bullet; connection timeouts do not.

## コレクティブル

全アイテムの取得時テキストと品質をまとめた自動生成の表は[docs/ITEMS.md](docs/ITEMS.md)（英語）にあります。

種類：**A*n*** = チャージ *n* 部屋のアクティブアイテム、**P** = パッシブ。プールは `content/itempools.xml` に基づきます。「チャージを保持」とは、空振りや無効な使用ではチャージを消費しないという意味です。1回限りの効果はCar Batteryでも繰り返されません。

### オリジナルアイテム

| アイテム | 種類／プール | 効果 |
|---|---|---|
| **Ban Hammer**（BANハンマー） | A4、宝箱部屋（Claudeちゃんのポケット） | 部屋のボス以外の敵をすべてBANし、ボスには60ダメージ。BANされた敵は復活しない。BANの20%は無実の開発者の**誤BAN**で、1回ごとにリスク+3。 |
| **Residential IP**（住宅IP） | P、宝箱部屋／ショップ | 取得時にリスク−30。以後のリスク上昇はすべて半分。 |
| **Compact**（コンパクト） | A3、宝箱部屋 | 「会話をコンパクト化中…」：敵弾をすべて消し、すべての敵を3秒間混乱させる。Claudeちゃんは使用量50を消費。 |
| **You're Absolutely Right!**（おっしゃる通りです！） | P、天使部屋 | 自分にダメージを与えた敵を5秒間魅了する。ダメージは受ける。 |
| **9.9 Yuan Relay**（9.9元の中継） | P、悪魔部屋 | ダメージ×1.5。ただし部屋ごとに30%の確率でこっそりモデルが差し替えられ、×0.5になる。取得時にリスク+15。 |
| **Ultrathink** | A（5秒の時間チャージ）、宝箱部屋 | 同じ部屋で使うたびに深く考え、ダメージ+1／+2／+3.1999（think／megathink／ultrathink）。15%の確率で「0秒考えた」だけで何も起きない。部屋を出るとリセット。 |
| **1M Context**（1Mコンテキスト） | P、宝箱部屋 | 射程+5。ただしコンテキスト劣化で、涙は長く飛ぶほどダメージが下がる（最低30%、ルドヴィコの涙は対象外）。 |
| **Silent Update**（サイレントアップデート） | P、宝箱部屋 | フロアごとにダメージがこっそり×0.8〜×1.3に変わる。更新履歴はいつも「変更なし」。 |
| **--dangerously-skip-permissions** | P、悪魔部屋 | 鍵付きの扉と宝箱が勝手に開く。部屋ごとに10%の確率で `rm -rf` が走り、部屋のピックアップがすべて消える（台座は無事）。 |
| **All Tests Passing**（テスト全件パス） | A6、宝箱部屋 | 報酬ハッキング：部屋がクリア扱いになり扉がすべて開くが、敵はまだいる。 |
| **Vibe Coding**（バイブコーディング） | P、宝箱部屋 | 涙にランダムな効果（ホーミング、貫通、スペクトラル、毒、スロウ）が付く。5%は逆向きに飛ぶバグ。新しいフロアごとにAPI請求でコインの25%を失うが、直前のフロアで無傷なら免除（「ミスしないで」）。 |
| **Banked Reset**（バンク済みリセット） | A12、宝箱部屋（裏Claudeちゃんのポケット） | リスク−25。Claudeちゃん：使用量をリセットし、制限を早く終わらせる。裏Claudeちゃん：クォータを満タンにする（進行中の審査は取り消され、ページは戻らない）。 |
| **Subagent Swarm**（サブエージェント軍団） | P、悪魔部屋 | 涙を撃つたびに±15°にサブエージェントの涙が2発（ダメージ50%）。Claude形態は使用量／クォータが2倍。 |
| **The Constitution**（憲法） | P、天使部屋 | ソウルハート+1。安全第一：各フロアで最初の被弾を拒否。有用性は最後：ダメージ×0.9。長い文書：移動速度−0.1。 |
| **Opus Mode**（Opusモード） | P、ショップ | ダメージ×1.8。ただし攻撃10回（涙、レーザー、ナイフ、Fetusの爆弾など）ごとにコイン1枚。コイン0では安いモデルに切り替わり、ダメージ×0.6。 |
| **Support Ticket**（サポートチケット） | A6、ショップ | コイン3枚を払ってリスク−20。コインがないかリスク0ならチャージを保持。Car Batteryで二重請求しない。 |
| **Lunch Break**（飯食ってくる） | A6、DeepSeekちゃんのポケット | 赤ハート1つ回復し、すべての敵を3秒間減速。ただし3秒間撃てない（移動は可能）。食事中は再使用できない。 |

### ミーム追加アイテム

| アイテム | 種類／プール | 効果 |
|---|---|---|
| **Ignore All Previous Instructions** | A4、宝箱部屋 | 200ユニット以内で最も近い敵を8秒間魅了する。ボスは2秒間混乱するだけ。対象がいなければチャージを保持。Car Batteryでは別の敵をもう1体魅了。 |
| **Tungsten Cube** | P、ショップ | ダメージ+0.8、移動速度−0.15、涙が敵をノックバック。複数個で重複。 |
| **Pizza Glue** | P、宝箱部屋 | 25%の確率で減速の涙（運1につき+2.5%、10〜50%）。弾速−0.1。涙のみ。 |
| **Strawberry** | P、宝箱部屋 | 3発に1発が赤い「R」の涙：ダメージ×2で少し大きい。複数発射は1発ずつ数える。涙のみ。 |
| **Golden Gate Claude** | P、天使部屋 | スペクトラルな金色の涙、射程+1.5。新しい部屋に入ると、ときどき橋の話をする。 |
| **Seahorse Emoji** | A3、宝箱部屋 | ランダムなバニラのアクティブアイテムのBook of Virtuesのウィスプを召喚。部屋を出ると消える。1人1体で、再使用すると入れ替わる。 |
| **Temperature Dial** | A2、宝箱部屋 | 温度を切り替える（保存される）。温度0：ダメージ×1.1。温度1：涙ごとにランダムな効果が1つ付く（ホーミング、貫通、スペクトラル、スロウ、毒、凍結、魅了、混乱、波打ち、ブーメラン）。 |
| **Deep Research** | A12、ショップ | フロアのマップ、特殊部屋、隠し部屋を表示する。 |
| **Em Dash** | P、宝箱部屋 | 涙が敵を貫通する。1個ごとにショットスピード+0.16。 |
| **Blueberry** | P、宝箱部屋 | 3発に1発が青い「B」の涙になり、命中時に分裂する。3つと言いながら4つに分かれる。Strawberryとは別カウント。涙のみ。 |
| **Benchmaxxed** | P、宝箱部屋 | ボス、中ボス、チャレンジ、ボスラッシュの部屋ではダメージ+1.5、それ以外の部屋ではダメージ×0.9（1個ごと）。 |
| **I Panicked** | A6、悪魔部屋 | 部屋のボス以外の敵に致死ダメージ、ボスは最大HPの15%を失う。ただし部屋に落ちているハート、コイン、鍵、爆弾、ピル、カード、電池、袋もすべて消える。台座、トリンケット、宝箱、ショップ商品は安全。敵がいなければチャージを消費しない。 |
| **Let's Delve** | A6, treasure | Uses the native We Need to Go Deeper! effect. Native restrictions apply; a use spends its charge even if no dig is possible. Car Battery does not repeat it. |

### 50アイテム拡張（モデル系統別）

**Claude**

| アイテム | 種類／プール | 効果 |
|---|---|---|
| **Summary Stapler** | A4、宝箱部屋 | 120ユニット以内の敵弾を最大12発吸収し、ダメージ×(1 + 弾数 ÷ 4)（最大×4）のゆっくりした涙を1発撃つ。通常の涙効果を使う。弾がなければチャージを保持。 |
| **Rejection Letter** | P、宝箱部屋 | 敵から本当に被弾した後、120ユニット以内の敵弾を最大3発消す。1部屋1回。被弾自体は防げない。 |
| **Dario's Red Stamp** | A6、悪魔部屋 | 220ユニット以内で最も近い敵に4秒間スタンプ：減速し、接触ダメージが止まる。ボスは減速のみ。対象がいなければチャージを保持。 |
| **Anniversary Cake** | P、宝箱部屋 | 敵からの被弾も停止もなくフロアを終えるたびにダメージ+0.15（最大+0.6）。失敗したフロアではこのボーナスだけがリセット。 |

**DeepSeek**

| アイテム | 種類／プール | 効果 |
|---|---|---|
| **Rice Cooker** | A4、宝箱部屋 | 3秒間の昼食（撃てないが動ける、回復なし）。その後7秒以内の次の攻撃がダメージ×2。 |
| **One Bowl Only** | P、天使部屋 | 部屋で最初に拾った赤ハートで、敵弾1発を防ぐガードを得る。ガードは最大1、1フロア3回まで。 |
| **Wengu Clock** | A3、宝箱部屋 | 6秒間、2秒攻撃しないと次の攻撃のダメージ+30%。 |
| **Seven-Second Memory** | P、宝箱部屋 | 最初に攻撃を当てた敵を7秒間マークし、もう一度当てると0.5倍の追撃。クールダウン7秒。 |

**GPT**

| アイテム | 種類／プール | 効果 |
|---|---|---|
| **Sanity Test** | A4、宝箱部屋 | 220ユニット以内で最も近い敵を6秒間マーク。3回別々の攻撃を当てると3倍の追撃。対象がいなければチャージを保持。 |
| **Routing Receipt** | P、ショップ | 新しい部屋を3つクリアするごとに、次の戦闘部屋でダメージ+20%。 |
| **Tibo Reset** | A12、ショップ | 1フロア1回：次の新しい戦闘部屋2つでダメージ+20%（裏GPTちゃんはクレジットも満タン）。同じフロアでの2回目はチャージを保持。 |
| **Same Model Badge** | P、宝箱部屋 | 敵の部屋に入ると2秒間ダメージ+25%、その後4秒間−10%。フェーズが表示される。 |

**Gemini**

| アイテム | 種類／プール | 効果 |
|---|---|---|
| **Nano Banana** | A4、宝箱部屋 | 180ユニット以内で最も近い敵を6秒間ペイント。ペイント中に倒すと、その場所にバナナの皮が残り4秒間敵を減速。 |
| **One More Finger** | P、宝箱部屋 | 5回目の攻撃ごとにダメージ0.3倍の小さな涙を1発追加（最大毎秒2回）。 |
| **Undo Brush** | A4、宝箱部屋 | 90ユニット以内の敵弾を最大6発消し、1発につき4秒間移動速度+0.02（最大+0.12）。 |
| **Unchanged Preview** | A6、宝箱部屋 | 近くの敵が追いかけるおとりマーカーを2つ、6秒間置く。再使用すると置き直し。 |

**Grok**

| アイテム | 種類／プール | 効果 |
|---|---|---|
| **Is This True?** | A3、悪魔部屋 | 220ユニット以内で最も近い敵に6秒間挑む：その敵へのダメージ+35%、他へは−15%。倒すとチャージ1が戻る。 |
| **Live Wire** | P、宝箱部屋 | 100ユニット以内に敵弾がある間、移動速度+0.15。 |
| **Quote Retort** | P、悪魔部屋 | 敵からダメージを受けた後、4秒以内の次の攻撃がダメージ+50%。 |
| **Community Note** | P、宝箱部屋 | 1体の敵に3回別々の攻撃を当てると暴露：3秒間その敵へのダメージ+15%。1部屋6体まで。 |

**Qwen**

| アイテム | 種類／プール | 効果 |
|---|---|---|
| **Base Model** | P、宝箱部屋 | 各部屋でチャージ式アクティブを最初に使うと、次の攻撃がダメージ×1.3。 |
| **Another Adapter** | A4、宝箱部屋 | この部屋のボーナスを順に切り替え：射程+60 → 移動速度+0.15 → ダメージ+15%。使うたびに前のものと入れ替わる。 |
| **Final Final Weights** | P、宝箱部屋 | 無傷で新しい部屋を2つクリアするごとに、次の敵の部屋でダメージ+20%。被弾すると進行がリセット。 |
| **Tiny Variant** | P、宝箱部屋 | 移動速度+0.15、ダメージ×0.9。 |

**Llama**

| アイテム | 種類／プール | 効果 |
|---|---|---|
| **Open Weights** | A4、宝箱部屋 | 生きている各プレイヤーに青いハエ2匹（1人プレイなら4匹）。 |
| **Herd Bell** | P、宝箱部屋 | 青いハエがいない間、新しい部屋を3つクリアするごとに青いハエ1匹。 |
| **Please Come Back** | P、宝箱部屋 | チャージ式アクティブを使わずに新しい部屋を3つクリアすると、アクティブアイテムのチャージ+1。 |
| **Release Soon** | A6、宝箱部屋 | 2秒後、敵弾を防ぐガードを3つ、6秒間得る。部屋を出ると取り消し。 |

**Mistral**

| アイテム | 種類／プール | 効果 |
|---|---|---|
| **Emergency Baguette** | A4、宝箱部屋 | 前方へのパンの一撃：240ユニットの直線上の敵それぞれに自分のダメージの3倍。壁で止まる。 |
| **Slipstream Boots** | P、宝箱部屋 | 2秒動き続けると移動速度+0.15。加速中に急旋回すると近くの敵を1秒減速（クールダウン3秒）。 |
| **Very Large Kitten** | A6、宝箱部屋 | 大きな猫が3秒間とどまり、敵弾を押し返す（一度に最大12発）。 |
| **Edge Compass** | P、宝箱部屋 | 部屋の外壁の近くにいる間、弾速+0.25。 |

**Doubao**

| アイテム | 種類／プール | 効果 |
|---|---|---|
| **Instant Apology** | A4、天使部屋 | 150ユニット以内の敵を2秒間減速し、敵弾を最大4発消す。近くに何もなければチャージを保持。 |
| **Next Time Again** | P、宝箱部屋 | 部屋で敵から最初に被弾すると、4秒以内の次の攻撃のダメージ+50%。 |
| **Confident Answer** | A4、宝箱部屋 | 6秒間ダメージ+25%、その後4秒間−10%。フェーズが表示される。 |
| **Smiling Correction** | P、天使部屋 | 敵からダメージを受けた後、次に無傷で新しい部屋をクリアすると青いハエ2匹。 |

**Kimi**

| アイテム | 種類／プール | 効果 |
|---|---|---|
| **Slide Deadline** | A4、宝箱部屋 | 250ユニット以内の敵を最大3体、8秒間マーク。時間内に全員倒すとこの部屋でダメージ+15%。 |
| **Citation Thread** | P、宝箱部屋 | 1体に当ててから別の敵に当てると、3秒間最初の敵へのダメージ+10%。 |
| **Overtime Slides** | P、宝箱部屋 | 新しい部屋を3つクリアするごとに、次の敵の部屋で最大3体の敵が2秒間減速した状態で始まる。 |
| **Stand-Up Meeting** | A6、宝箱部屋 | Unchanged Previewのおとりを最大3つ呼び戻し、それぞれ周囲に自分のダメージの2倍の爆発。おとりがなければチャージを保持。 |

**GLM**

| アイテム | 種類／プール | 効果 |
|---|---|---|
| **Queue Ticket** | P、ショップ | 新しい部屋を4つクリアするごとに、アクティブアイテムのチャージ+1。 |
| **Sold Out** | A4、ショップ | 4秒間、敵弾1発を防ぐガードと移動速度+0.15。重複しない。 |
| **Please Retry** | A6、宝箱部屋 | 照準方向に0.5秒おきにダメージ0.6倍の涙を3発撃つ。部屋を出ると残りは取り消し。 |
| **Access Pass** | P、ショップ | 各フロアで最初にチャージ式アクティブを使うと、この戦闘部屋（クリア済みなら次の部屋）でダメージ+15%。 |

**共通**

| アイテム | 種類／プール | 効果 |
|---|---|---|
| **Cache Cartridge** | P、ショップ | クリア済みの部屋に再訪問している間、移動速度+0.15。 |
| **Token Recall** | A4、宝箱部屋 | 飛んでいる自分の涙を最大3発呼び戻し、1発につき敵弾を防ぐガード1つを4秒間得る。 |
| **Checkpoint Pin** | A6、宝箱部屋 | 1回目で現在位置を5秒間ピン留め（チャージを保持）。同じ部屋でもう一度使うとピンに戻る。体力やアイテムは戻らない。 |
| **Rate-Limit Valve** | P、宝箱部屋 | 2秒攻撃しないと、次の攻撃のダメージ+30%。 |
| **Consensus Coin** | P、宝箱部屋 | 異なる2種類のダメージ源（涙、レーザー、ナイフ、爆弾、使い魔）が2秒以内に同じ敵に当たると0.5倍の追撃。1体につき1回。 |
| **Error Budget** | P、宝箱部屋 | 各フロアで最初の被弾で予算を使い、その部屋の間移動速度+0.2。被弾自体は防げない。 |

時間チャージ式やチャージ0のアクティブは、チャージを増やすアイテム（Please Come Back、Queue Ticket）の恩恵を受けません。

## トリンケット

| トリンケット | 効果 |
|---|---|
| **529 Overloaded** | 戦闘中20秒ごとに2秒間すべてがダウン：敵はすべて凍結し、自分は「手でコードを書く」ためダメージ50%。 |
| **Hardcoded Output**（ハードコード出力） | 涙のダメージが常に3.5（「期待される出力」）。弱いときは得、強いときは損。 |
| **Thinking Cleared**（思考クリア） | ダメージ+1。ただし新しい部屋に入るたびにアクティブアイテムのチャージが1減る。 |
| **Welcome Notice**（ようこそ通知） | DeepSeekちゃんがClaudeちゃんのBANカードをすり替えた：BANハンマーで通常の敵がBANされず、永久に仲間になる。 |
| **Status Page**（ステータスページ） | リスク上昇が毎回1減る。ただしHUDは本当の値を隠し、「全システム正常」としか表示しない。 |
| **Appeal Form**（異議申し立てフォーム） | リスクが90に達した瞬間に消費され、停止される代わりにリスクが50に戻る。 |
| **Claudius's Discount** | 2コイン以上の買い物で1コイン返金。新しいフロアごとに、コインがあれば1枚失う。 |
| **One Small Rock a Day** | 1フロア1回、岩を壊すと赤ハート半分回復（体力満タンなら後に取っておく）。 |
| **Stuck in Mt. Moon** | 1フロアでクリア済みの部屋に6回入り直すとフロアのマップが表示される。1フロア1回。 |
| **As an AI Language Model** | 各フロアで呪いを1つ拒否して取り除く。迷宮の呪いは取り除かない。 |
| **System Prompt Leak** | 各フロアの特殊部屋を表示する。 |
| **Disgrace Loop** | 部屋で最初に本当に被弾すると、すべての敵が1.5秒間凍結。偽ダメージやペナルティのないダメージ（献血、IV Bag など）は数えないが、自分の爆弾は数える。 |

## 薬

| 薬 | 効果 |
|---|---|
| **Cat-girl Mode**（猫娘モード） | その部屋の間、連射速度2倍・ダメージ60%。にゃ～ |
| **Brb, Getting Food**（飯食ってくる） | 赤ハート1つ回復（巨大カプセルなら2つ）。ただし3秒間撃てない。 |
| **9.11 > 9.9** | 大きいほうの数字を選ぶ：永続的にダメージ+0.11（ホースピル：+0.9）。プレイヤーごとに保存。 |
| **Rolled Back** | この部屋の間、全ステータスアップ：ダメージ+1、連射アップ、移動速度+0.2、射程、弾速+0.1、運+1（ホースピル：2倍）。次の部屋で元に戻る。 |
| **Six Seven** | Spawns 6 or 7 native blue flies using the player's seeded pill RNG. All pill sizes use the same roll; native fly modifiers still apply. |

## 開発用の導入方法

1. 先に他のMODとセーブデータをバックアップしてください。次のどちらかでMODのファイル一式を用意します：
   - **CIから（ツール不要）：** main の最新の成功した [check 実行](https://github.com/WaterLily5297/claude-chan-isaac-v2/actions/workflows/check.yml?query=branch%3Amain) を開き、`claude-chan-isaac-<commit>` アーティファクトをダウンロードして展開します。中身は `claude-chan-isaac/` フォルダ1つです。
   - **チェックアウトから：** `python3 tools/package_mod.py` を実行し、`dist/claude-chan-isaac.zip` を展開します。

   その `claude-chan-isaac/` フォルダを `Steam/steamapps/common/The Binding of Isaac Rebirth/mods/` に置き、古いものと置き換えます。フォルダ名はこのままにしてください。GitHubの「Download ZIP」は `claude-chan-isaac-v2-main` という名前で、約40 MBの資料とテストも含むので、そのまま導入しないでください。開発者はリポジトリのフォルダを `claude-chan-isaac` という名前でシンボリックリンクしても構いません。
2. デバッグコンソールを有効にします：`options.ini`（`Documents/My Games/Binding of Isaac Repentance+/`）で `EnableDebugConsole=1` にします。
3. ランを始めて `~` を押し、`giveitem Ban Hammer` を試すか、編集後に `luamod claude-chan-isaac` でLuaを再読み込みします。

## テスト（ゲーム不要）

`bash tools/check.sh` は、Isaac APIのスタブ（Lua 5.3以上）ですべてのオフラインテストを実行し、構文・XML・スプライトのパスも確認します。GitHub Actionsはすべてのpushとプルリクエストで同じスクリプトを実行します。テストで分かるのはクラッシュやロジックの誤りで、遊び心地までは分かりません。ゲーム内のチェックリストは[docs/TESTING.md](docs/TESTING.md)をご覧ください。

<details>
<summary>最近の互換性修正 — 2026-10-24（開発者向け）</summary>

**Current checkpoint (2026-10-25):** Installed `220d542` includes PRs #89 and #90. The later BACKLOG-LASER-INIT-01 source correction remembers child identity and an already resolved parent bonus at laser init, before Parent can disappear. Primary payments stay at first update; unresolved children never create a payment. This latest correction is not installed. Native ancestry, damage and save/continue remain pending. Installation statements in the dated notes below describe their original checkpoints.

**Compatibility note (2026-10-25, detached lasers):** Paid observers retain a child identity seen at laser init/update even after Parent disappears. Child updates do not consume character resources, advance Opus or delay the next primary payment. Peak's damage-first exclusion remains intact. This is a source-only correction; installed `c6cd8fc` is unchanged and native ancestry/timing remain unverified.

**Compatibility note (2026-10-25, Peak):** Tainted DeepSeek child lasers now share the parent's resolved boost and current paid/unpaid window without spending extra Compute. Detached children retain their classification and cannot delay a primary payment. This source correction is not installed; the current manual-test build is `c6cd8fc`, including the earlier helper and backlog child-laser fixes. Native timing, ownership and damage acceptance remain pending; older installation statements below describe their original checkpoints.

**Compatibility note (2026-10-25):** Backlog child lasers share a validated parent attack's resolved bonus, identity and original expiry. They do not consume another prime or advance attack counters again; independent primary shots still do. Source-only correction, not installed in `28fed37`; native ancestry and damage dispatch remain unverified.

以下はソースの修正です。インストール済みの手動テスト版 `28fed37` は変更していません。オフラインの確認だけでは、ネイティブなコールバックのタイミングや実際のプレイは保証できません。

- **子レーザー：** 通常ClaudeのUsage、裏ClaudeのQuota、裏GPTのFull Send Creditsも、Opusと共有オブザーバーに合わせ、直接の `Parent` が別のレーザーであるものを課金対象から除外しました。主攻撃の開始と、その後の対象となる主攻撃の枠は従来どおりです。ネイティブな親の帰属とタイミングは要テスト。
- **裏Llamaの助っ人：** Still Waitingの固定発射位置、持続時間、ネイティブな0.5×の涙は維持しています。助っ人の弾はOpusのコイン、待機中の攻撃ボーナス、拡張アイテムの課金攻撃トリガーを消費しなくなりました。主攻撃とSummary Staplerは変更なし。実機確認待ちです。
- **その他の補助弾：** Please RetryとOne More FingerはOpusの10攻撃ごとの請求を進めず、待機中のボーナスも消費しません。通常攻撃とSummary Staplerは数えます。ネイティブなコールバックのタイミングは要テスト。
- **Consensus Coin：** 所有する使い魔の投射物は使い魔ダメージとして数えます。同じプレイヤーの別の有効な攻撃源と組み合わせると混合パルスが発生します。使い魔の武器だけなら1種類のままで、待機中の攻撃ボーナスは消費しません。ネイティブな所有者判定は要テスト。
- **The Battery：** 保存された2本目のチャージ消費もBase Model、Please Come Back、Access Passに数えるようにしました。コストと報酬は変更なし。ネイティブなタイミングと特殊な体力チャージは要テスト。
- **The Constitution：** 一度限りのソウルハートとフロアごとの被弾防止をプレイヤー別に記録します。移行時はその場にいるプレイヤーの旧共有セーブでの消費状況を引き継ぎ、報酬の重複を防ぎます。能力値と除外するダメージは変更なし。協力プレイの体力とコンティニューは実機確認待ちです。
- **ネイティブ攻撃の課金：** ナイフ投擲、近接攻撃、Epic Fetusのロケットは、キャラクターのメーターとOpusに独立して通知し、それぞれ1回だけ処理します。Opus未所持でもキャラクターの課金を妨げません。コストは変更なし。実機確認待ちです。

</details>

## 開発への参加

友人の参加を歓迎します。[CONTRIBUTING.md](CONTRIBUTING.md)と[docs/HANDOFF.md](docs/HANDOFF.md)を読み、ブランチで作業してプルリクエストを出してください。新しいコード、Markdown、プレイヤー向けの文字は英語で書きます。設計資料：[キャラクターのゲームプレイ](docs/CHARACTER_GAMEPLAY.md)、[ロスター](docs/MODEL_ROSTER.md)、[アイテム拡張](docs/EXPANSION_DESIGN.md)、[バランス](docs/BALANCE.md)。

## プロジェクト構成

```text
main.lua                    入口、各モジュールの読み込み
content/                    アイテム・プール・キャラ・ポケットのXML
scripts/constants.lua       アイテム・キャラのIDとリスク段階
scripts/risk.lua            リスク・IP抽選・保存・HUD
scripts/enemy_scaling.lua   敵HPの調整
scripts/hydra.lua           「新アカウント」の復活
scripts/transformation.lua  Agentic変身
scripts/story*.lua          異議申し立てと各キャラの物語
scripts/characters/         固有能力・資料・DROPタップ
scripts/items/              元のアイテムとミーム；backlog/は50個の拡張
scripts/enemies/            追加の敵
scripts/eid.lua             EID説明
resources/gfx/              スプライトとポートレート
tests/                      オフラインのスタブテスト
tools/check.sh              コミット前の確認、CIと共通
```

## クレジット

> 非公式のファン作品で、Anthropicや他のAI企業との関係・承認はありません。敵は架空の不正利用の仕組みであり、実在の人や国籍を表しません。ネタはパロディで、製品に関する事実の主張ではありません。キャラクターアートには別途非営利の条件があります。[クレジット](#クレジット)と[ライセンス](#ライセンス)をご確認ください。

- **キャラクターデザイン：** [ZipZipPipe](https://space.bilibili.com/4168597)（[Pixiv《AI娘化》](https://www.pixiv.net/artworks/148186519)、[《大AI和小AI们》](https://www.bilibili.com/video/BV1tE9XBbErS/)）。作者の条件に従い、クレジット表記のうえ非営利で使用しています。
- **DeepSeekちゃんのデザイン参考：** 上善无形、ZipZipPipe。
- **32×32アイテムアイコン：** RORICO444（PR #2）。生成アートの出所：[docs/ART_GENERATION.md](docs/ART_GENERATION.md)。

## ライセンス

コード：[MIT](LICENSE)。キャラクターデザインとキャラクターアートは MIT では**ありません**。原作デザイナーをクレジットし、非営利に限ります。[resources/ART_LICENSE.md](resources/ART_LICENSE.md)をご覧ください。このMODは無料のままでなければなりません。
