"""The crew: chubby kawaii sailors (Olivier, 2026-10-22). blender -b -P tools/blender/build_crew.py
-> assets/art/export/models/crew.glb (+ assets/art/source/blender/crew.blend)

One model, built facing +z (the game turns it), feet on the ground at the origin. Separate named
parts so the game can animate them without a skeleton: Body, Head (with face), HandL/HandR,
FootL/FootR, and one hat per style (Hat_tricorn, Hat_bandana, Hat_captain, Hat_beanie, Hat_straw,
Hat_crown); the game shows one hat and tints "player" parts in the player's colour."""
import math
import os
import sys

sys.path.append(os.path.dirname(__file__))
import kit  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
HEAD_Y = 1.42


def group(name, parts):
    return kit.parent_all(name, parts)


def body():
    p = [kit.sphere("Torso", (0, 0.68, 0), 0.42, "player", scale=(1.0, 1.1, 0.88))]
    p.append(kit.cylinder("Belt", (0, 0.5, 0), (0, 0.6, 0), 0.4, 0.41, "wood_dark", verts=20))
    p.append(kit.box("Buckle", (0, 0.55, 0.37), (0.16, 0.12, 0.05), "gold", bevel=0.02))
    p.append(kit.sphere("Shirt", (0, 0.86, 0.2), 0.22, "trim_cream", scale=(1.1, 0.8, 0.6)))
    return group("Body", p)


def head():
    y = HEAD_Y
    p = [kit.sphere("Skull", (0, y, 0), 0.56, "skin", scale=(1.05, 0.95, 1.0), segments=28, rings=16)]
    for side in (-1, 1):
        x = side * 0.21
        p.append(kit.sphere("Eye%d" % side, (x, y + 0.02, 0.48), 0.12, "eye", scale=(0.85, 1.15, 0.5)))
        p.append(kit.sphere("Shine%d" % side, (x + 0.04, y + 0.08, 0.54), 0.04, "white"))
        p.append(kit.sphere("ShineSmall%d" % side, (x - 0.03, y - 0.04, 0.545), 0.018, "white"))
        p.append(kit.sphere("Blush%d" % side, (side * 0.33, y - 0.13, 0.43), 0.08, "blush", scale=(1.2, 0.6, 0.4)))
        p.append(kit.sphere("Ear%d" % side, (side * 0.56, y, 0.0), 0.11, "skin", scale=(0.5, 1, 0.8)))
    # A small smile: a short curved row of dark beads.
    for i in range(5):
        a = (i - 2) * 0.22
        p.append(kit.sphere("Smile%d" % i, (math.sin(a) * 0.09, y - 0.17 + (1 - math.cos(a)) * 0.12, 0.535), 0.022,
                            "eye", segments=8, rings=5))
    return group("Head", p)


def hands_and_feet():
    parts = []
    for side, name in ((-1, "L"), (1, "R")):
        parts.append(group("Hand" + name, [kit.sphere("HandBall" + name, (side * 0.5, 0.7, 0.05), 0.14, "skin")]))
        parts.append(group("Foot" + name, [kit.sphere("Boot" + name, (side * 0.2, 0.1, 0.06), 0.16, "wood_dark",
                                                       scale=(1, 0.7, 1.35))]))
    return parts


def hats():
    y = HEAD_Y + 0.42
    hats = []
    # Tricorn: a flat brim folded up into three corners, with a gold trim.
    brim = []
    for i in range(3):
        a = i * 2 * math.pi / 3 + math.pi / 2
        brim.append(kit.box("TriWing%d" % i, (math.cos(a) * 0.25, y - 0.02, math.sin(a) * 0.25), (0.75, 0.24, 0.1),
                            "player", bevel=0.04, rot=(0.35, -a + math.pi / 2, 0)))
    brim.append(kit.sphere("TriCrown", (0, y + 0.02, 0), 0.4, "player", scale=(1, 0.55, 1)))
    brim.append(kit.torus("TriTrim", (0, y - 0.08, 0), 0.47, 0.035, "gold"))
    hats.append(group("Hat_tricorn", brim))
    # Bandana with a knot at the back.
    band = [kit.sphere("BandanaCap", (0, y - 0.12, 0), 0.58, "player", scale=(1.02, 0.6, 1.02))]
    band.append(kit.sphere("BandanaKnot", (0, y - 0.2, -0.56), 0.11, "player"))
    for side in (-1, 1):
        band.append(kit.sphere("BandanaTail%d" % side, (side * 0.12, y - 0.36, -0.62), 0.09, "player",
                               scale=(0.7, 1.6, 0.5)))
    for i in range(6):
        a = i * math.pi / 3
        band.append(kit.sphere("Dot%d" % i, (math.cos(a) * 0.35, y + 0.05, math.sin(a) * 0.35), 0.05, "white"))
    hats.append(group("Hat_bandana", band))
    # Captain's hat: tall, with a peak and a gold badge.
    cap = [kit.cylinder("CapBand", (0, y - 0.12, 0), (0, y + 0.12, 0), 0.5, 0.52, "player", verts=24)]
    cap.append(kit.sphere("CapTop", (0, y + 0.18, 0), 0.6, "trim_cream", scale=(1, 0.32, 1)))
    cap.append(kit.box("CapPeak", (0, y - 0.12, 0.45), (0.6, 0.05, 0.3), "eye", bevel=0.05))
    cap.append(kit.sphere("CapBadge", (0, y + 0.02, 0.5), 0.08, "gold", scale=(1, 1, 0.4)))
    hats.append(group("Hat_captain", cap))
    # Beanie with a pompom.
    beanie = [kit.sphere("BeanieCap", (0, y - 0.05, 0), 0.56, "player", scale=(1.02, 0.75, 1.02))]
    beanie.append(kit.torus("BeanieFold", (0, y - 0.25, 0), 0.54, 0.09, "player"))
    beanie.append(kit.sphere("Pompom", (0, y + 0.42, 0), 0.15, "white"))
    hats.append(group("Hat_beanie", beanie))
    # Straw hat with a coloured ribbon.
    straw = [kit.cylinder("StrawBrim", (0, y - 0.18, 0), (0, y - 0.13, 0), 0.85, 0.85, "sand", verts=28)]
    straw.append(kit.sphere("StrawCrown", (0, y - 0.1, 0), 0.45, "sand", scale=(1, 0.6, 1)))
    straw.append(kit.cylinder("StrawRibbon", (0, y - 0.13, 0), (0, y - 0.03, 0), 0.46, 0.45, "player", verts=24))
    hats.append(group("Hat_straw", straw))
    # A little golden crown (an unlockable).
    crown = [kit.cylinder("CrownBand", (0, y - 0.15, 0), (0, y + 0.05, 0), 0.38, 0.4, "gold", verts=20)]
    for i in range(5):
        a = i * 2 * math.pi / 5
        crown.append(kit.sphere("CrownPoint%d" % i, (math.cos(a) * 0.38, y + 0.12, math.sin(a) * 0.38), 0.07, "gold"))
        crown.append(kit.sphere("CrownGem%d" % i, (math.cos(a) * 0.4, y - 0.05, math.sin(a) * 0.4), 0.05, "player"))
    hats.append(group("Hat_crown", crown))
    return hats


def main():
    kit.reset()
    kit.into("Crew")
    kit.parent_all("CrewModel", [body(), head()] + hands_and_feet() + hats())
    kit.export("Crew", os.path.join(ROOT, "assets/art/export/models/crew.glb"))
    kit.save(os.path.join(ROOT, "assets/art/source/blender/crew.blend"))


main()
