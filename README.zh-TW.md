# Agent Sprite Forge

English README: [README.md](./README.md)

以 Codex 為核心的 2D sprite 生成技能，專門用來做可直接用在遊戲裡的 pixel assets。

目前這個 repo 只保留一個通用 skill：

- [`skills/generate2dsprite`](skills/generate2dsprite)

之所以先以 Codex 為主，是因為 Codex 有內建 image generation，可以把整個流程收在同一個 agent 裡：

1. 讓 agent 規劃資產類型與動畫形式
2. 讓 Codex 直接生成 raw sprite sheet
3. 讓本地 processor 做洋紅去背、切格、對齊、基本 QC、輸出透明 PNG / GIF

目前這個 repo 的焦點是「可重用的 2D 單體資產」，不是整包遊戲 pack。

## 可以生成什麼

- 怪物
- 角色
- 玩家角色與 NPC
- 法術施法動畫
- 飛行物
- 命中特效與爆炸特效
- FX sheet
- 小型 bundle，例如：
  - `unit_bundle`
  - `spell_bundle`
  - `combat_bundle`

## 為什麼先以 Codex 為主

這個 repo 是刻意以 Codex 為核心，因為 Codex 可以在同一個工作流中直接生成圖片。

這樣整條 pipeline 會乾淨很多：

- 不需要額外串 image API
- 不需要獨立的 prompt builder service
- 不需要另一個 sprite backend
- 由 agent 決定資產規劃
- 由本地 processor 負責 deterministic 的清理與輸出

processor script 不是創意來源。真正決策的是 agent，它會決定：

- 資產類型
- 動作類型
- bundle 結構
- sheet 形式
- 幀數
- 對齊策略
- 要不要保留分離式特效

script 只負責 deterministic 的像素操作。

## Repo 結構

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

## 安裝方式

### Option 1: Windows PowerShell

先 clone 這個 repo，再把 skill 複製到你的 Codex skills 目錄：

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

安裝完成後，建議開一個新的 Codex session，讓 skill 重新載入。

## 推薦 Prompt

### 基本範例

```text
使用 $generate2dsprite 幫我做一個究極地元素巨人的 3x3 idle 動畫
```

```text
使用 $generate2dsprite 幫我做一個側視雷電騎士的攻擊動畫
```

```text
使用 $generate2dsprite 幫我做一個戰國浪人主角的 4 方向 player_sheet
```

### 法術 / 特效範例

```text
使用 $generate2dsprite 幫我做一個巫師施法 bundle，包含 cast、projectile、impact
```

```text
使用 $generate2dsprite 幫我做一個火球飛行循環跟對應的爆炸命中特效
```

```text
使用 $generate2dsprite 幫我做一個雷狼召喚登場特效
```

### 角色 / 怪物範例

```text
使用 $generate2dsprite 幫我做一個奧米加獸的攻擊元素和向右移動元素
```

```text
使用 $generate2dsprite 幫我做一個黃金版神豬的 2x2 idle 動畫
```

```text
使用 $generate2dsprite 幫我做一個漩渦鳴人使用螺旋丸的 2x3 cast sheet
```

## 會輸出什麼

一般 sheet 類型通常會輸出：

- `raw-sheet.png`
- `raw-sheet-clean.png`
- `sheet-transparent.png`
- 每格 frame PNG
- `animation.gif`
- `prompt-used.txt`
- `pipeline-meta.json`

如果是 `player_sheet`，還會額外輸出：

- 四方向 strip
- 四方向 GIF

## 設計理念

這個 skill 的核心不是把規則全部寫死，而是把責任切開：

- 美術規劃交給 agent
- 去背、切格、對齊、輸出交給 deterministic processor

也就是說：

- Agent 決定要做 `idle`、`cast`、`projectile`、`impact` 還是 `bundle`
- Agent 決定用 `2x2`、`2x3`、`3x3`、`1x4` 還是 `4x4`
- Script 只做可重現的像素工作

這樣比較容易往後延伸到更多通用 2D 資產流程。

## 備註

- 最好的結果通常來自明確的 prompt，至少要交代：
  - 視角
  - 動作
  - 預期的 sheet 形式或動畫節奏
  - containment 規則
- 大型怪物通常更適合 `3x3 idle`
- 小型法術或飛行物通常更適合 `1x4`、`2x2`、`2x3`
- 如果要用在商業作品，建議優先使用你自己可控的原創角色或 IP
