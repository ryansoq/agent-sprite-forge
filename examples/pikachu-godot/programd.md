# programd.md — autonomous improvement loop for Pikachu Mini RPG

This file is the **agent's runtime instructions** for iteratively improving the
demo at `examples/pikachu-godot/`. Format inspired by autotrain v3
(hypothesis discipline + surgical diffs + periodic reflection), adapted from
"minimize val_bpb" to "improve a game demo".

The loop calls you with:
> Read examples/pikachu-godot/programd.md and run one iteration.

Re-read this file every iteration; it is the single source of truth.

## Mission

Make `examples/pikachu-godot/` into a **more complete game** — meaning more
gameplay systems, more content (monsters / moves / areas / NPCs), more
mechanics (XP, types, status, items, evolution, shops, trainer battles), one
small surgical change at a time. Treat this as a long-running content-build
run, not a polish pass.

**Priority order each iteration:**

1. **Gameplay depth** — new mechanics that change how decisions feel.
2. **Content** — more monsters, moves, areas, NPCs, items, encounters.
3. **Code health / SKILL-readiness** — only when it unblocks future depth/content.
4. **Polish / juice / UI** — only after a depth or content pass; never as the
   primary axis of an iteration unless the game is otherwise feature-complete.

If you find yourself reaching for a "polish" backlog item, first ask: is
there an unticked depth/content item I could do instead? Default to yes.

## Scope

**In scope (you may modify):**
- `examples/pikachu-godot/scenes/**`
- `examples/pikachu-godot/scripts/**`
- `examples/pikachu-godot/tools/make_assets.py` (Pillow placeholders only)
- `examples/pikachu-godot/assets/**` (only via `make_assets.py` regeneration)
- `examples/pikachu-godot/README.md`
- `examples/pikachu-godot/journal.md`, `results.tsv`, `programd.md` (this file)

**Out of scope (do NOT modify):**
- `skills/**` — that is the parent repo's product.
- `src/**`, top-level `README.md`, `README.zh-TW.md`, `requirements.txt`
- `CLAUDE.md`
- Anything outside `examples/pikachu-godot/`

## Hard constraints

1. **No new dependencies.** Only `Pillow` + `numpy` (already in
   `requirements.txt`) for placeholder generation, and built-in Godot 4 nodes.
2. **No image_gen.** All art remains hand-coded Pillow shapes. Real sprite art
   replacement is the user's job via Codex + `$generate2dsprite`.
3. **No audio files.** Any SFX must be synthesized via `AudioStreamGenerator`
   in code, not loaded from disk. Skip audio if too risky for one iteration.
4. **Keep SKILL replacement points clean.** `assets/pikachu_*.png`,
   `assets/enemy_*.png`, and the structure of `_build_world()` in
   `Overworld.gd` must stay easy to swap for SKILL-generated assets.
5. **Project must boot.** After every change, `godot4 --headless --import`
   must complete without `ERROR` lines, and each scene must run for ~4s
   without script errors. See **Validation** below.
6. **Surgical diffs.** Each commit changes only what the hypothesis needs.
   Refactors that touch unrelated files go in a separate commit.

## Quality rubric (replaces `val_bpb`)

Each iteration should improve at least one of:

- **Gameplay depth** — meaningful systems (XP, types, status, items, NPCs).
- **Polish / juice** — animations, transitions, feedback, hit-feel.
- **Content** — more monsters, moves, areas, encounters.
- **Code health** — clearer scripts, fewer magic numbers, better separation.
- **SKILL-readiness** — easier to swap placeholder for SKILL-generated asset.
- **Bug fixes** — anything that throws a runtime error or visibly misbehaves.

If a change doesn't measurably improve any axis, `discard`.

## Hypothesis discipline (per commit)

Every iteration commit message must contain four lines after the subject:

```
Hypothesis: <one sentence — what this improves and why>
Assumptions: <one line — repo state I'm relying on; if wrong, result is
              uninterpretable>
Prediction: <what the player/user will notice; e.g. "smoother battle UX",
             "no behavioral change, ~30 fewer LOC">
Tripwire: <a result that means the experiment itself is broken, not the
           idea — investigate before discarding>
```

Example:

```
Tween enemy HP bar smoothly when damaged

Hypothesis: A 0.25s tween on the ProgressBar value reads as more polished
            than a snap on damage, without affecting battle pacing.
Assumptions: Battle.gd._refresh_bars is the only place HP bars update; no
             other code writes to enemy_hp_bar.value directly.
Prediction: Visible polish in battle; no logic change; <20 lines added.
Tripwire: HP bar desyncs from underlying GameState (shows different number
          than text label after rapid hits).
```

If you genuinely can't articulate a mechanism, prefix Prediction with
`exploratory:` and be sceptical of keeping the result.

## Surgical-diff check

Pick any line in the diff. Ask: "If I revert just this line, does this commit
still test the same hypothesis?" If yes, the line is **incidental** — remove
it from this commit. Cleanup is great, but goes in its own commit with subject
`refactor: ... (no behavior change expected)`.

## Validation (run after every change, before committing)

```bash
cd examples/pikachu-godot
rm -rf .godot
godot4 --headless --import 2>&1 | grep -iE "^ERROR" | grep -v leaked
timeout 6 godot4 --headless --quit-after 240 res://scenes/TitleScreen.tscn 2>&1 | grep -iE "error|invalid|fail" | grep -v leaked
timeout 6 godot4 --headless --quit-after 240 res://scenes/Overworld.tscn 2>&1 | grep -iE "error|invalid|fail" | grep -v leaked
timeout 6 godot4 --headless --quit-after 240 res://scenes/Battle.tscn 2>&1 | grep -iE "error|invalid|fail" | grep -v leaked
```

If any of those produces output (other than "ObjectDB instances leaked"
warnings, which are harmless on early exit), **fix or revert before
committing**. Do not commit a broken project.

## Backlog (priority-ordered idea pool — depth/content first)

Pick one per iteration. Smallest still-meaningful change. Cross out (`~~~~`)
when done — do not delete; future iterations should see history.

### Tier 1 — Gameplay depth (ALL DONE as of iter9)
- [x] ~~**Level / XP system.**~~ iter1 (7a5e555).
- [x] ~~**Type effectiveness.**~~ iter2 (14b100f).
- [x] ~~**Critical hits.**~~ iter3 (6a9c847).
- [x] ~~**Move PP.**~~ iter4 (552662a).
- [x] ~~**Status — sleep / burn.**~~ iter5 (b1ff534).
- [x] ~~**Faint XP share.**~~ iter6 (305da12).
- [x] ~~**Evolution.**~~ iter7 (586b325). Pikachu → Raichu at Lv 8.
- [x] ~~**Trainer battle.**~~ iter8 (f6be18b). Stationary NPCs, no run/
      catch, 2x XP, persistent.
- [x] ~~**Money / Pokédollars + Shop NPC.**~~ iter9 (8a024a6). Wild:
      5×lv. Trainer: 15×lv. Shop sells Potion $30, Pokeball $50.

**All Tier-1 depth shipped. Pull from Tier 2 next.**

### Tier 2 — Content
- [ ] **3+ new wild monsters**: a water type (e.g. Aquillo), a normal type
      (e.g. Bunten), a psychic type (e.g. Mindling). Sprites added in
      `make_assets.py`.
- [ ] **Gym Leader boss**: special trainer with strong moves and a fanfare
      message; gives a key item that unlocks evolution stones in shop.
- [ ] **Second map** (cave or town interior). Use a door `Area2D` that
      transitions via `Fade.go_to_scene`. Different encounter pool.
- [ ] **NPC + dialogue box**. Talk by walking up + Space. Multi-line text.
      Use a generic `DialogueBox.tscn` reusable component.
- [ ] **Overworld item pickup**: scattered Potion / Pokeball sprites you can
      walk over to collect. Stay collected across save.
- [ ] **Encounter table per region** (different grass patches → different
      wild pools). Spec via data dict keyed by region id.

### Tier 3 — Code health / SKILL-readiness
- [ ] **Input action map** properly defined in `project.godot` (custom
      actions for `interact`, `pause`, etc.) — currently we rely on `ui_*`.
- [ ] **Data-driven overworld**: move `_build_world` positions to
      `data/overworld_layout.json`. Lets `$generate2dmap` replace layout
      without touching code.
- [ ] **DialogueBox reusable scene** before adding any NPC.
- [ ] **EncounterTable resource** so map regions can declare wild pools.

### Tier 4 — Polish / juice / UI (only after major content lands)
- [ ] Tween HP bars on damage instead of snap.
- [ ] Damage number floats up from sprite on hit.
- [ ] Move-type colour tag in Fight menu.
- [ ] Status icon next to HP bar.
- [ ] Themed StyleBox for panels.
- [ ] Battle log keeps last 3 messages visible.
- [ ] Pause menu shows playtime + captures.
- [ ] Footstep dust on movement; healing pad sparkle.

### Tier 5 — Misc / nice-to-have
- [ ] Multiple save slots on title screen.
- [ ] WASD alongside arrows.
- [ ] Hold Z to fast-forward text.

(Add to this list as you discover ideas. Strike through obviously-bad ideas
with `~~`. **Always pull from the lowest unticked tier first.**)

## Per-iteration loop

1. **Orient.** `git status`, read `journal.md` Reflections + Open Questions,
   read recent rows of `results.tsv` (last 5).
2. **Pick one backlog item.** Prefer items that build on prior `keep`s.
3. **Plan.** Write `Hypothesis / Assumptions / Prediction / Tripwire` for
   this change *before* coding. Save them — they go in the commit message.
4. **Implement surgically.** Touch only what the hypothesis needs.
5. **Validate** via the commands in **Validation** above.
6. **Tripwire check.** If a tripwire fires, investigate before deciding
   keep/discard — was it a bug in the change, or did the hypothesis fail?
7. **Decide.** `keep` if it improves at least one rubric axis without
   breaking others; otherwise `discard` (`git restore` / `git reset`).
8. **Commit** (only on keep). Subject ≤ 65 chars, body has the four lines.
9. **Record** the iteration in `results.tsv` (one row per attempt — including
   `discard` and `crash`).
10. **Update journal** if the result was surprising or revealed something
    worth remembering. Don't journal every iteration.
11. **Every 5 keeps**: write a short Reflections entry in `journal.md`
    summarising the last batch and listing 1–2 next directions. Resolve any
    Open Questions you can; promote unresolved ones to top of backlog.

## results.tsv format

Tab-separated. Columns:

```
commit	axis	status	summary
```

- **commit**: short hash (7 chars). Use `-` if discard/crash with no commit.
- **axis**: one of `polish | depth | content | code | skill-ready | bug | meta`.
- **status**: `keep | discard | crash`.
- **summary**: short one-line description; no tabs.

## Open-question discipline

If during an iteration you become uncertain about something
("why is this code here?", "is this assumption right?", "should X be Y?")
and can't resolve it cheaply: **add a bullet to `journal.md` Open Questions
and continue**. Do not stop the loop. Do not ask the user. The next
periodic-review pass will revisit these.

## Stopping conditions

The loop stops when **any** of these is true:

- The backlog has fewer than 3 unchecked items and you can't think of
  meaningful additions. Add a final journal entry "loop converged" and stop.
- Two consecutive iterations crash the project and you can't fix in the
  current iteration. Stop, leave a journal note, wait for human.
- A hard validation failure on `main` after revert (something deeply wrong
  with the environment). Journal note, stop.

Otherwise: keep going.
