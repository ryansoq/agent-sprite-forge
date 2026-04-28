# journal.md

Living notebook for the autonomous improvement loop on
`examples/pikachu-godot/`. Append-only mostly; resolve Open Questions by
moving them into Reflections with the answer.

## Open Questions
- Should xp_to_next be `level * 25` or curve faster (e.g. `level * level * 5`)?
  Current curve: 5→6 needs 125, 6→7 needs 150, ... — could feel too slow once
  a few captures stack via "Faint XP share". Revisit after that lands.
- Wild level rolls 3-7 randomly. With type effectiveness (next iteration) this
  may swing damage too wildly. Consider capping wild range or scaling per-region.

## Reflections
- **Iter 0 (seed)** — Demo currently at: title screen, 1280×720 overworld
  with tree/rock walls + tall grass + healing pad, four-direction Pikachu
  movement, three wild monsters with own movesets, Battle with
  Fight/Bag/Party/Run menu, Potion + Pokeball items, party of up to 6,
  ConfigFile save/load, pause menu, fade transitions. Validated headless.
  **Biggest gaps:** no XP/levels, no type effectiveness, no status beyond
  paralyze, no trainer/NPC/dialogue, no shop, no second map. **Priority:
  ship Tier 1 gameplay-depth items first.**

## Done log

- **Iter1 (7a5e555)** — Level/XP system. HP/damage scale ±10% per level
  off baseline 5; wild monsters roll level 3-7. Bundled with scaffold
  commit because the demo was untracked when the loop started — iter2+
  will be properly surgical (one feature per commit).
- **Meta (bde6cee)** — gitignore `.godot/` and `*.uid`; cleanup so future
  iteration diffs are readable.
