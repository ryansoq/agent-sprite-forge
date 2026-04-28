# journal.md

Living notebook for the autonomous improvement loop on
`examples/pikachu-godot/`. Append-only mostly; resolve Open Questions by
moving them into Reflections with the answer.

## Open Questions
- ~~XP curve too slow~~ — partially mitigated by iter6 (faint share doubles
  effective team XP/battle). Curve itself unchanged; revisit if level cap or
  evolution thresholds make late grinding tedious.
- Wild level rolls 3-7 randomly. With iter5 (sleep/burn) and iter2 (type x2)
  stacking, fights against high-level type-advantaged wilds can one-shot a low-
  level party member. Consider region-scoped wild level pools when a second
  map lands.
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
