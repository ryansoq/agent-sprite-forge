#!/usr/bin/env python3
"""Generate placeholder pixel-art PNG assets for the Pikachu Godot demo.

These are hand-drawn with Pillow because Claude Code does not have the
`image_gen` tool that the parent repository's skills rely on. Run with Codex
later to swap these out for proper image-generated sprites and tilesets.

Usage:
    python3 tools/make_assets.py
"""

from pathlib import Path

from PIL import Image, ImageDraw

ASSETS = Path(__file__).resolve().parent.parent / "assets"
ASSETS.mkdir(parents=True, exist_ok=True)

YELLOW = (248, 208, 48, 255)
YELLOW_DARK = (200, 160, 40, 255)
BLACK = (24, 24, 24, 255)
WHITE = (255, 255, 255, 255)
RED = (240, 100, 100, 255)
RED_DARK = (180, 50, 50, 255)
BROWN = (140, 90, 50, 255)
GREEN = (108, 180, 100, 255)


def _new() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def make_pikachu_down() -> None:
    img, d = _new()
    d.polygon([(8, 1), (4, 14), (13, 11)], fill=YELLOW, outline=BLACK)
    d.polygon([(24, 1), (28, 14), (19, 11)], fill=YELLOW, outline=BLACK)
    d.polygon([(8, 1), (6, 7), (10, 7)], fill=BLACK)
    d.polygon([(24, 1), (26, 7), (22, 7)], fill=BLACK)
    d.ellipse([4, 10, 28, 30], fill=YELLOW, outline=BLACK)
    d.ellipse([5, 19, 11, 25], fill=RED)
    d.ellipse([21, 19, 27, 25], fill=RED)
    d.ellipse([10, 14, 14, 18], fill=BLACK)
    d.ellipse([18, 14, 22, 18], fill=BLACK)
    d.point((12, 15), fill=WHITE)
    d.point((20, 15), fill=WHITE)
    d.line([(14, 22), (16, 23), (18, 22)], fill=BLACK)
    img.save(ASSETS / "pikachu_down.png")


def make_pikachu_up() -> None:
    img, d = _new()
    d.polygon([(8, 1), (4, 14), (13, 11)], fill=YELLOW, outline=BLACK)
    d.polygon([(24, 1), (28, 14), (19, 11)], fill=YELLOW, outline=BLACK)
    d.polygon([(8, 1), (6, 7), (10, 7)], fill=BLACK)
    d.polygon([(24, 1), (26, 7), (22, 7)], fill=BLACK)
    d.ellipse([4, 10, 28, 30], fill=YELLOW, outline=BLACK)
    # back stripe markings
    d.line([(10, 14), (14, 14)], fill=BLACK)
    d.line([(18, 14), (22, 14)], fill=BLACK)
    d.line([(11, 18), (13, 18)], fill=BLACK)
    d.line([(19, 18), (21, 18)], fill=BLACK)
    img.save(ASSETS / "pikachu_up.png")


def make_pikachu_side() -> None:
    img, d = _new()
    # ears (one tilted forward, one slightly behind)
    d.polygon([(14, 1), (8, 13), (18, 11)], fill=YELLOW, outline=BLACK)
    d.polygon([(22, 4), (18, 14), (26, 13)], fill=YELLOW, outline=BLACK)
    d.polygon([(14, 1), (12, 6), (15, 6)], fill=BLACK)
    d.polygon([(22, 4), (20, 9), (23, 9)], fill=BLACK)
    # head/body (slightly elongated)
    d.ellipse([4, 11, 30, 30], fill=YELLOW, outline=BLACK)
    # cheek (right side, since facing right)
    d.ellipse([21, 19, 27, 25], fill=RED)
    # eye (right side)
    d.ellipse([20, 15, 23, 18], fill=BLACK)
    d.point((21, 16), fill=WHITE)
    # mouth (small)
    d.line([(24, 21), (26, 22)], fill=BLACK)
    img.save(ASSETS / "pikachu_side.png")


def make_raichu() -> None:
    img, d = _new()
    orange = (240, 160, 80, 255)
    orange_dark = (180, 100, 30, 255)
    cheek = (250, 220, 100, 255)

    # smaller ears than Pikachu, with darker tips
    d.polygon([(8, 3), (5, 13), (13, 11)], fill=orange, outline=BLACK)
    d.polygon([(24, 3), (27, 13), (19, 11)], fill=orange, outline=BLACK)
    d.polygon([(8, 3), (7, 8), (10, 8)], fill=orange_dark)
    d.polygon([(24, 3), (25, 8), (22, 8)], fill=orange_dark)

    # body
    d.ellipse([4, 10, 28, 30], fill=orange, outline=BLACK)

    # yellow cheek pouches (vs red on Pikachu)
    d.ellipse([5, 19, 11, 25], fill=cheek)
    d.ellipse([21, 19, 27, 25], fill=cheek)

    # eyes
    d.ellipse([10, 14, 14, 18], fill=BLACK)
    d.ellipse([18, 14, 22, 18], fill=BLACK)
    d.point((12, 15), fill=WHITE)
    d.point((20, 15), fill=WHITE)

    # smirking mouth (slightly more aggressive than Pikachu)
    d.line([(13, 22), (16, 24), (19, 22)], fill=BLACK)

    img.save(ASSETS / "raichu.png")


def make_volty() -> None:
    """Original electric mouse-like creature; not Pikachu."""
    img, d = _new()
    blue = (140, 180, 240, 255)
    blue_dark = (90, 120, 200, 255)
    d.polygon([(7, 4), (4, 13), (12, 11)], fill=blue_dark, outline=BLACK)
    d.polygon([(25, 4), (28, 13), (20, 11)], fill=blue_dark, outline=BLACK)
    d.ellipse([4, 10, 28, 30], fill=blue, outline=BLACK)
    d.ellipse([10, 15, 13, 18], fill=BLACK)
    d.ellipse([19, 15, 22, 18], fill=BLACK)
    d.point((11, 16), fill=WHITE)
    d.point((20, 16), fill=WHITE)
    # zigzag mouth
    d.line([(13, 22), (15, 24), (17, 22), (19, 24)], fill=BLACK)
    img.save(ASSETS / "enemy_volty.png")


def make_twigling() -> None:
    """Original grass-type creature."""
    img, d = _new()
    leaf = (110, 180, 90, 255)
    leaf_dark = (60, 110, 50, 255)
    # leaf on top
    d.polygon([(16, 1), (10, 8), (22, 8)], fill=leaf, outline=leaf_dark)
    d.line([(16, 2), (16, 8)], fill=leaf_dark)
    # body
    d.ellipse([4, 10, 28, 30], fill=leaf, outline=BLACK)
    # eyes
    d.ellipse([10, 15, 13, 18], fill=BLACK)
    d.ellipse([19, 15, 22, 18], fill=BLACK)
    d.point((11, 16), fill=WHITE)
    d.point((20, 16), fill=WHITE)
    # smile
    d.arc([13, 20, 19, 24], 0, 180, fill=BLACK)
    img.save(ASSETS / "enemy_twigling.png")


def make_embertail() -> None:
    """Original fire-type creature."""
    img, d = _new()
    orange = (240, 140, 70, 255)
    orange_dark = (180, 80, 30, 255)
    flame = (255, 200, 80, 255)
    # ears
    d.polygon([(7, 4), (4, 12), (11, 10)], fill=orange_dark, outline=BLACK)
    d.polygon([(25, 4), (28, 12), (21, 10)], fill=orange_dark, outline=BLACK)
    # body
    d.ellipse([4, 10, 28, 30], fill=orange, outline=BLACK)
    # eyes (angry)
    d.line([(10, 14), (13, 16)], fill=BLACK)
    d.line([(22, 14), (19, 16)], fill=BLACK)
    d.ellipse([10, 16, 13, 19], fill=BLACK)
    d.ellipse([19, 16, 22, 19], fill=BLACK)
    # fangs
    d.polygon([(13, 22), (14, 25), (15, 22)], fill=WHITE)
    d.polygon([(17, 22), (18, 25), (19, 22)], fill=WHITE)
    # flame tuft on head
    d.polygon([(16, 1), (13, 8), (19, 8)], fill=flame, outline=orange_dark)
    img.save(ASSETS / "enemy_embertail.png")


def make_grass_tile() -> None:
    img = Image.new("RGBA", (32, 32), GREEN)
    d = ImageDraw.Draw(img)
    darker = (88, 158, 80, 255)
    lighter = (140, 200, 120, 255)
    spots = [(4, 6), (12, 3), (20, 8), (28, 5), (8, 18), (18, 16),
             (26, 22), (3, 26), (14, 28)]
    for x, y in spots:
        d.point((x, y), fill=darker)
        d.point((x + 1, y), fill=darker)
        d.point((x, y + 1), fill=lighter)
    img.save(ASSETS / "grass.png")


def make_tall_grass_tile() -> None:
    img = Image.new("RGBA", (32, 32), (78, 140, 70, 255))
    d = ImageDraw.Draw(img)
    dark = (50, 100, 50, 255)
    light = (130, 200, 110, 255)
    for x in range(2, 32, 4):
        d.line([(x, 30), (x, 8)], fill=dark)
        d.line([(x + 1, 28), (x + 1, 12)], fill=light)
    img.save(ASSETS / "tall_grass.png")


def make_dirt_tile() -> None:
    img = Image.new("RGBA", (32, 32), (180, 140, 90, 255))
    d = ImageDraw.Draw(img)
    dark = (140, 100, 60, 255)
    spots = [(5, 8), (15, 4), (24, 11), (8, 20), (20, 22), (28, 27), (3, 28)]
    for x, y in spots:
        d.point((x, y), fill=dark)
        d.point((x + 1, y), fill=dark)
    img.save(ASSETS / "dirt.png")


def make_tree() -> None:
    img, d = _new()
    canopy = (60, 130, 60, 255)
    canopy_light = (100, 170, 90, 255)
    canopy_dark = (40, 90, 40, 255)
    trunk = (110, 70, 40, 255)
    trunk_dark = (70, 40, 20, 255)
    d.rectangle([13, 22, 19, 31], fill=trunk, outline=trunk_dark)
    d.line([(15, 24), (15, 30)], fill=trunk_dark)
    d.ellipse([2, 2, 30, 26], fill=canopy, outline=canopy_dark)
    d.ellipse([6, 4, 16, 14], fill=canopy_light)
    d.ellipse([18, 8, 26, 16], fill=canopy_light)
    img.save(ASSETS / "tree.png")


def make_rock() -> None:
    img, d = _new()
    grey = (160, 160, 160, 255)
    grey_dark = (100, 100, 100, 255)
    grey_light = (200, 200, 200, 255)
    d.polygon([(6, 24), (4, 16), (10, 8), (22, 8), (28, 16), (26, 26)],
              fill=grey, outline=grey_dark)
    d.polygon([(8, 20), (10, 12), (16, 10)], fill=grey_light)
    img.save(ASSETS / "rock.png")


def make_water() -> None:
    img = Image.new("RGBA", (32, 32), (90, 150, 220, 255))
    d = ImageDraw.Draw(img)
    light = (140, 200, 240, 255)
    dark = (50, 100, 180, 255)
    for y in (8, 20):
        d.line([(2, y), (10, y)], fill=light)
        d.line([(20, y + 4), (28, y + 4)], fill=light)
    for y in (4, 16, 28):
        d.line([(15, y), (22, y)], fill=dark)
    img.save(ASSETS / "water.png")


def make_healing_pad() -> None:
    img = Image.new("RGBA", (32, 32), (240, 240, 240, 255))
    d = ImageDraw.Draw(img)
    pink = (240, 130, 160, 255)
    pink_dark = (180, 70, 100, 255)
    d.rectangle([0, 0, 31, 31], outline=pink_dark)
    # plus sign
    d.rectangle([13, 6, 18, 25], fill=pink, outline=pink_dark)
    d.rectangle([6, 13, 25, 18], fill=pink, outline=pink_dark)
    img.save(ASSETS / "healing_pad.png")


def make_pokeball() -> None:
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([1, 1, 14, 14], fill=WHITE, outline=BLACK)
    d.pieslice([1, 1, 14, 14], 180, 360, fill=RED, outline=BLACK)
    d.line([(1, 8), (14, 8)], fill=BLACK)
    d.ellipse([6, 6, 9, 9], fill=WHITE, outline=BLACK)
    img.save(ASSETS / "pokeball.png")


def make_potion() -> None:
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cap = (90, 90, 90, 255)
    glass = (240, 70, 70, 255)
    glass_light = (255, 160, 160, 255)
    d.rectangle([5, 1, 10, 4], fill=cap, outline=BLACK)
    d.rectangle([4, 4, 11, 5], fill=cap, outline=BLACK)
    d.rectangle([3, 5, 12, 14], fill=glass, outline=BLACK)
    d.rectangle([4, 7, 6, 12], fill=glass_light)
    img.save(ASSETS / "potion.png")


def main() -> None:
    make_pikachu_down()
    make_pikachu_up()
    make_pikachu_side()
    make_raichu()
    make_volty()
    make_twigling()
    make_embertail()
    make_grass_tile()
    make_tall_grass_tile()
    make_dirt_tile()
    make_tree()
    make_rock()
    make_water()
    make_healing_pad()
    make_pokeball()
    make_potion()
    # Backwards-compat aliases for the original demo files.
    (ASSETS / "pikachu.png").write_bytes((ASSETS / "pikachu_down.png").read_bytes())
    (ASSETS / "enemy.png").write_bytes((ASSETS / "enemy_volty.png").read_bytes())
    print(f"Generated {len(list(ASSETS.glob('*.png')))} PNGs in {ASSETS}")


if __name__ == "__main__":
    main()
