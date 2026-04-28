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
