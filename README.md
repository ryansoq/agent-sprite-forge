# Agent Sprite Forge

Traditional Chinese README: [README.zh-TW.md](./README.zh-TW.md)

Codex-first 2D sprite generation skill for game-ready pixel assets.

This repository currently ships one generic skill: [`skills/generate2dsprite`](skills/generate2dsprite).

It is designed for Codex first because Codex has built-in image generation. That means you can stay inside one agent workflow:

1. Let the agent plan the asset.
2. Let Codex generate the raw sprite sheet.
3. Let the local processor remove the magenta background, split frames, align sprites, run basic QC, and export transparent PNG/GIF outputs.

The current focus is self-contained 2D assets, not whole game packs.

## What It Can Generate

- Creatures
- Characters
- Players and NPCs
- Spell casts
- Projectiles
- Impacts and explosions
- FX sheets
- Small bundles such as:
  - `unit_bundle`
  - `spell_bundle`
  - `combat_bundle`

## Why Codex First

This repo is intentionally Codex-first because Codex can generate images directly inside the same workflow.

That gives you a much cleaner pipeline:

- no extra image API wiring
- no separate prompt builder service
- no external sprite backend
- one agent decides the plan
- one local processor handles deterministic cleanup and export

The processor script is not the creative brain. The agent decides:

- asset type
- action type
- bundle shape
- sheet layout
- frame count
- alignment strategy
- whether detached effects should be kept or filtered

The script only performs deterministic pixel operations.

## Repository Layout

```text
agent-sprite-forge/
  README.md
  README.zh-TW.md
  skills/
    generate2dsprite/
      SKILL.md
      agents/
        openai.yaml
      references/
        modes.md
        prompt-rules.md
      scripts/
        generate2dsprite.py
```

## Install

### Option 1: Windows PowerShell

Clone the repo, then copy the skill into your Codex skills directory:

```powershell
git clone https://github.com/0x0funky/agent-sprite-forge.git
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.codex\skills" | Out-Null
Copy-Item -Recurse -Force `
  ".\agent-sprite-forge\skills\generate2dsprite" `
  "$env:USERPROFILE\.codex\skills\generate2dsprite"
```

### Option 2: macOS / Linux

```bash
git clone https://github.com/0x0funky/agent-sprite-forge.git
mkdir -p ~/.codex/skills
cp -R ./agent-sprite-forge/skills/generate2dsprite ~/.codex/skills/generate2dsprite
```

After installation, start a new Codex session so the skill is loaded cleanly.

## Suggested Prompts

### Basic

```text
Use $generate2dsprite to create a 3x3 idle for an ultimate earth titan.
```

```text
Use $generate2dsprite to create a side-view lightning knight attack animation.
```

```text
Use $generate2dsprite to create a late-Sengoku player_sheet for a wandering fire swordsman.
```

### Spell / FX

```text
Use $generate2dsprite to create a wizard spell bundle with cast, projectile, and impact sprites.
```

```text
Use $generate2dsprite to create a fireball projectile loop and a matching explosion impact.
```

```text
Use $generate2dsprite to create a side-view summon entrance effect for a thunder wolf spirit.
```

### Character / Monster Examples

```text
Use $generate2dsprite to create Omegamon attack and right-move animation assets.
```

```text
Use $generate2dsprite to create a golden divine boar 2x2 idle animation.
```

```text
Use $generate2dsprite to create a Naruto-style rasengan cast sheet in 2x3.
```

## What You Get

For a typical sheet output:

- `raw-sheet.png`
- `raw-sheet-clean.png`
- `sheet-transparent.png`
- frame PNGs
- `animation.gif`
- `prompt-used.txt`
- `pipeline-meta.json`

For player walk sheets, you also get direction strips and per-direction GIFs.

## Notes

- Best results come from prompts that clearly specify:
  - view
  - action
  - sheet size or expected motion style
  - containment rules
- Large creatures often work better as `3x3 idle`.
- Small spells and projectiles often work better as `1x4`, `2x2`, or `2x3`.
- For commercial projects, prefer original characters or IP that you control.
