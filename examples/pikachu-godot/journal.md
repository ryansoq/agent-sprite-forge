# journal.md

Living notebook for the autonomous improvement loop on
`examples/pikachu-godot/`. Append-only mostly; resolve Open Questions by
moving them into Reflections with the answer.

## Open Questions
- ~~XP curve too slow~~ — partially mitigated by iter6 (faint share doubles
  effective team XP/battle). Curve itself unchanged; revisit if level cap or
  evolution thresholds make late grinding tedious.
- ~~Wild level rolls 3-7 randomly with type swings~~ — resolved by iter13
  (region-scoped pools/levels): central_meadow Lv3-6, south_field Lv4-7,
  northwest_thicket Lv5-8, east_pondside Lv5-9. Variance now bounded per
  area; player can choose difficulty by location.
- Status doesn't cure on faint+revive (heal_party_full clears it, but mid-
  battle KO + party-switch keeps the original member statused on next entry).
  Probably fine — adds permanence to status — but flag if it confuses players.

## Reflections
- **Iter 0 (seed)** — Demo currently at: title screen, 1280×720 overworld
  with tree/rock walls + tall grass + healing pad, four-direction Pikachu
  movement, three wild monsters with own movesets, Battle with
  Fight/Bag/Party/Run menu, Potion + Pokeball items, party of up to 6,
  ConfigFile save/load, pause menu, fade transitions. Validated headless.
  **Biggest gaps:** no XP/levels, no type effectiveness, no status beyond
  paralyze, no trainer/NPC/dialogue, no shop, no second map. **Priority:
  ship Tier 1 gameplay-depth items first.**
- **After iter1–iter6 (6 keeps)** — Six consecutive keep iterations on
  Tier-1 depth: Level/XP (iter1, bundled with scaffold), Type effectiveness
  (iter2), Critical hits (iter3), Move PP (iter4), Status sleep+burn
  (iter5, biggest at 132+/53−), Faint XP share (iter6, smallest at 14+).
  Zero discards, zero crashes; all hypotheses matched predictions. The
  battle layer now has all the standard Pokémon-like decision pressures:
  type matchup, PP economy, status threats, XP planning. **Remaining
  Tier-1 are larger features:** Evolution, Trainer battles, Money+Shop —
  each ~80-100 LOC and pulls in 1+ new asset/scene. **Next direction:**
  Evolution — cleanest extension of Level/XP, needs a new Raichu sprite
  via Pillow + a new monster id; surgical scope possible if held to
  level-threshold evolution only (stones/triggers later).

## Done log

- **Iter1 (7a5e555)** — Level/XP system. HP/damage scale ±10% per level
  off baseline 5; wild monsters roll level 3-7. Bundled with scaffold
  commit because the demo was untracked when the loop started — iter2+
  will be properly surgical (one feature per commit).
- **Meta (bde6cee)** — gitignore `.godot/` and `*.uid`; cleanup so future
  iteration diffs are readable.
- **Iter2 (14b100f)** — Type effectiveness; 4-element chart, 2× / 0.5× /
  1×, "super effective" / "not very effective" messages.
- **Iter3 (6a9c847)** — Critical hits; 1/16 chance, 1.5×; both sides.
- **Iter4 (552662a)** — Move PP; per-member persistent PP; healing pad
  refills.
- **Iter5 (b1ff534)** — Status sleep & burn; unified `_can_act` +
  `_apply_burn_damage` helpers; both sides can be statused.
- **Iter6 (305da12)** — Faint XP share; non-fainted bench gets ½ XP.
- **Iter7 (586b325)** — Evolution; Pikachu → Raichu at Lv 8;
  evolves_at/evolves_to schema.
- **Iter8 (f6be18b)** — Trainer battles; 2 stationary NPCs, no run/catch,
  2× XP, defeated_trainers in save.
- **Iter9 (8a024a6)** — Money + Shop NPC; battle wins grant Pokédollars
  (5×lv wild, 15×lv trainer); shop sells Potion $30, Pokeball $50;
  closes the demo's economic loop. **🎯 Last Tier-1 item.**

## Milestone — All Tier-1 depth shipped (iter1–iter9)

The battle layer + economic loop now matches a Pokémon-like prototype:
- Levels, XP, faint share
- Type chart (4 types, 2× / 0.5×)
- Crits (1/16 × 1.5)
- PP economy
- Sleep / burn / paralyze statuses
- Evolution (Pikachu → Raichu)
- Trainer battles (no run/catch, 2× rewards, persistent)
- Money + shop economy

9 iterations, 9 keeps, zero discards, zero crashes. Next pulls go from
Tier 2 (content): new wild monsters, Gym Leader, second map, NPC
dialogue, overworld pickups, regional encounter pools.

## After iter10–iter13 (Tier-2, 4 more keeps)

- **Iter10 (4b694f0)** — 3 new wild monsters (Aquillo water / Bunten
  normal / Mindling psychic). WILD_POOL doubled to 6.
- **Iter11 (3f03421)** — Reusable DialogueBox component + 2 NPCs
  (Elder, Kid).
- **Iter12 (8271459)** — 4 overworld item pickups, persistent.
- **Iter13 (dd940b9)** — Encounter table per region (4 regions with
  distinct pools and level ranges); resolves Open Question 2.

13 iterations / 13 keeps / 0 discards / 0 crashes. The overworld now
has visible content depth (NPCs to talk to, items to pick up, regions
with their own ecology). **Remaining Tier-2:** Gym Leader boss,
second map. Both larger (~150 LOC). **Next direction:** Gym Leader —
reuses DialogueBox + Trainer battle infra; second map can wait until
the gym leader gives a reason to travel.

## Milestone — All Tier-1 + Tier-2 shipped (iter1–iter15)

- **Iter14 (9ad1cb8)** — Gym Leader "Thunder Lord" Lv 10 with pre-fight
  dialogue and bonus reward ($100 + 3 Pokeballs).
- **Iter15 (270114d)** — Second map (Cave) at NE corner; door transition
  via overworld_return_pos; cave-only encounter region Lv 6-10
  (Aquillo / Mindling / Bunten).

15 iterations / 15 keeps / 0 discards / 0 crashes. The demo is now
content-complete to the spec laid out at iter0:
- Battle: levels, types (4), crits, PP, status (sleep/burn/paralyze),
  evolution
- Economy: money, shop, item pickups
- World: 1280×720 overworld + 480×360 cave with door transitions, 4
  region encounter pools, 2 trainers, 1 gym leader, 2 NPCs, shop, healing
  pad, 4 ground items
- Persistence: save/load via ConfigFile, defeated_trainers, picked_up_
  items, money, party with level/xp/pp/status
- UI: title screen, pause menu, dialogue box (reusable), shop menu

Remaining backlog is Tier 3 (code health / SKILL-readiness:
data-driven layout, input map, dialogue scenes for shop/healing) and
Tier 4 (polish: tweens, damage popups, themed StyleBox, walking dust,
status icons). Per programd.md priority, future iterations should
prefer Tier 3 over Tier 4 — those unblock asset replacement via the
parent repo's SKILLs.

## After iter16–iter22 (Tier-3 + early Tier-4, 7 more keeps)

- **Iter16 (810b45c)** — Tier-3 input action map: semantic interact /
  pause via InputBindings autoload, replacing ui_accept/ui_cancel.
- **Iter17 (d15c00b)** — Tier-3 data-driven overworld: positions /
  patches / regions moved to data/overworld_layout.json. Direct SKILL
  replacement point.
- **Iter18 (5fa5a84)** — Tween HP bars on damage/heal/burn/potion.
- **Iter19 (9453311)** — Floating damage popups, color-coded.
- **Iter20 (a1c0f8a)** — Move-type colour tag in Fight menu.
- **Iter21 (53dba03)** — PAR / SLP / BRN status badges next to HP.
- **Iter22 (49d7edd)** — Pause menu playtime + summary line.

22 iterations / 22 keeps / 0 discards / 0 crashes. **Tier-3 done**
(EncounterTable resource superseded by iter17 JSON). **Tier-4 in
progress** — battle UI now has tween bars, damage popups, type
colors, status badges. Remaining Tier-4: Panel StyleBox theming,
battle log (last 3 messages), footstep dust / healing pad sparkle.
**Next direction:** Battle log — biggest remaining UX gap; players
can miss messages during fast resolution.

## Milestone — All Tier 1-4 shipped (iter1–iter25)

- **Iter23 (ec68c4b)** — Theming autoload sets root.theme; consistent
  dark-green panel style across all scenes.
- **Iter24 (a4f4dfd)** — Battle log; resize MessagePanel + _say() helper +
  sed-converted 40 message.text= sites; last 3 messages visible.
- **Iter25 (7ba4536)** — Footstep dust trail (every 0.18s while moving) +
  healing pad sparkles (8 yellow stars rising on use); last Tier-4 item.

25 iterations / 25 keeps / 0 discards / 0 crashes.

Tier completion: T1 9/9 ✓ · T2 6/6 ✓ · T3 2/2 + 1 superseded ✓ · T4 8/8 ✓.

Remaining backlog is Tier 5 (multiple save slots, WASD movement, hold-Z
to fast-forward text). Beyond that, new ideas would need to be invented
(broader battle moves, day/night, weather, NPC schedules, fishing,
breeding, etc.) per programd.md "Add to this list as you discover ideas".

## 🏆 Final milestone — All five tiers shipped (iter1–iter27)

- **Iter26 (4bfd34f)** — Tier-5 input QoL: WASD alongside arrows; hold Z
  for 4× battle fast-forward via Engine.time_scale.
- **Iter27 (16538f6)** — Tier-5 multiple save slots: 3 per-slot files,
  title screen peek_slot summary, click/1-2-3 to play, R resets all.

27 iterations / 27 keeps / 0 discards / 0 crashes.

Final tier completion:
- Tier 1 (gameplay depth):              9/9   ✓
- Tier 2 (content):                     6/6   ✓
- Tier 3 (code health / SKILL-ready):   2/2   ✓ (+1 superseded)
- Tier 4 (polish):                      8/8   ✓
- Tier 5 (misc QoL):                    3/3   ✓

The original backlog is empty. From here, new directions need to be
invented anew. The programd.md file lists candidate themes (day/night,
move learning, more monsters/types, trainer roster, second gym).
The loop can keep firing as long as it's seeded with new ideas.

## After iter23–iter30 (Tier-4 finish + Tier-5 + new themes, 8 more keeps)

- **Iter23 (ec68c4b)** — Themed panel StyleBox via root theme (dark-green).
- **Iter24 (a4f4dfd)** — Battle log, last 3 messages stacked, 40-site sed
  rewrite to _say(...).
- **Iter25 (7ba4536)** — Footstep dust + healing pad sparkles; LAST Tier-4.
- **Iter26 (4bfd34f)** — Tier-5 input QoL: WASD + hold-Z fast-forward.
- **Iter27 (16538f6)** — Tier-5 multiple save slots; LAST Tier-5.
- **Iter28 (aeb2312)** — Day/night cycle (4-min sine, dark-blue overlay
  below UI). First post-Tier-5 idea.
- **Iter29 (3c51123)** — Trainer roster expansion + 2nd gym leader.
- **Iter30 (0751db7)** — Nighttime encounter pool variants per region;
  extends iter28.

30 iterations / 30 keeps / 0 discards / 0 crashes. The original
five-tier backlog has been fully shipped (iter1–iter27) and three
post-backlog content/atmosphere additions added on top
(iter28–iter30). The day/night system (iter28) inspired a follow-up
gameplay variant (iter30) the same week — pattern: a single
atmospheric mechanic naturally seeds gameplay rules. **Next
direction:** move learning at level-up — biggest remaining
mechanical gap, requires per-member moves field + sync helper.

## After iter31–iter40 (mid-late content + depth, 10 more keeps)

- **Iter31 (4976f69)** — Move learning at level-up (per-member moves).
- **Iter32 (3e90821)** — Ground type + Pebbleon, counters electric.
- **Iter33 (0fad58d)** — Poison type + Toxidew in south_field.
- **Iter34 (0f27c83)** — Move replace dialog (ChoiceDialog reusable).
- **Iter35 (b468157)** — Multi-monster trainer parties; gyms + 2 trainers
  now field 2 monsters.
- **Iter36 (b4b19c5)** — HUD enrichment: time-of-day label + Seen N/M.
- **Iter37 (8a30de1)** — Pokedex menu via PauseMenu.
- **Iter38 (1255d6c)** — Item tiers: 3 potions ($30/80/200) + 3 balls
  (+0/15/30% catch); ItemData autoload; ChoiceDialog tier-pick.
- **Iter39 (a6962aa)** — Flying type + Skywing in central meadow; chart
  reaches 7 types.
- **Iter40 (b028c15)** — Starter choice (Pikachu/Twigling/Embertail) on
  new-slot via ChoiceDialog.

40 iterations / 40 keeps / 0 discards / 0 crashes. Pattern observation:
**ChoiceDialog (introduced iter34) became the reuse engine** — iter38
shop/bag tier picks and iter40 starter choice both lean on it without
adding new scenes. The "atmospheric → gameplay rule" pattern from
iter28→iter30 also held: HUD enrichment (iter36 atmospheric) seeded
Pokedex (iter37 mechanical). **Type chart now 7 types** with full
asymmetric matchups — matches mid-tier Pokemon Gen 1 in coverage. **No
remaining clear "must-have" backlog items** — future iters need to
invent new directions (stat moves, weather, item pickups in cave,
trainer rematches, deeper learnsets).

## After iter41–iter50 (post-Tier mid-game expansion, 10 more keeps)

- **Iter41 (72ebe10)** — Cave item pickups (3 tier-tinted items).
- **Iter42 (f49ab76)** — Stat-modifying moves (Iron Defense / Growl).
- **Iter43 (dff6dd6)** — Catch streak (+5%/streak, capped +30%).
- **Iter44 (4d18551)** — Trainer rematches after Aqua Warden.
- **Iter45 (0033dcf)** — Ice type + Frostling (chart now 8 types).
- **Iter46 (4f637f9)** — Battle quick keys (F/B/P/R + 1-4).
- **Iter47 (ac00873)** — Visual polish: softer night + sprite shadow.
- **Iter48 (35ba958)** — Snappier battle pacing (~40% faster) + ChoiceDialog _input.
- **Iter49 (2a81def)** — PauseMenu Use Potion + ChoiceDialog respects opener pause.
- **Iter50 (e03f696)** — Move Tutor NPC.

50 iterations / 50 keeps / 0 discards / 0 crashes. 🎉

Pattern observation: **User feedback drove iter47-iter49**. iter47 night
softer + shadow was a "feel" guess. iter48 was triggered by user reporting
"attack screen feels stuck" — fix was timer compression (40% across the
board) + ChoiceDialog _input correctness. iter49 was natural follow-up
(pause-respecting ChoiceDialog enables the whole "use items in pause"
ergonomic). The single user note "very slow attack" exposed FOUR hidden
correctness/UX bugs in stacked modal pause + timer length — investing in
direct user feedback is highest-ROI.

Type chart now 8 species: electric/fire/water/grass/ground/poison/flying/
ice. 12 monsters total. 5 trainers + 2 gyms (4 of those 2-mon parties)
+ rematch unlock. 6 tier-3 items. Move learning + tutor closes the
move-management loop completely.

**Next direction:** Trainer eye-contact line-of-sight (auto-engage when
walked into trainer's facing line). Or: held items, weather, badge
collection. Or polish the existing visuals (animated battle intro,
critical-hit screen shake). User redirection welcome.
