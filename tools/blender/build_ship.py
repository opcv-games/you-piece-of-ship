"""The player's ship, painted-kawaii style (Olivier, 2026-10-22: "a ship, not a barge").
blender -b -P tools/blender/build_ship.py  ->  assets/art/export/ship.glb + assets/art/source/ship.blend

Gameplay space (unchanged): a flat deck 18 m x 7 m at y = 0 from x = -9 to 9, rails at its edges.
Around it: a round-bellied hull with a pointed, rising bow (forecastle step at x = 9), a raised
quarterdeck with a cute cabin at the stern (x < -9), a mast at x = 1 with a billowing sail and a
crow's nest, a bowsprit with a jib, and a smiling golden fish figurehead.
"""
import math
import os
import sys

sys.path.append(os.path.dirname(__file__))
import kit  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
STERN, BOW = -10.9, 14.6


def half_width(x):
    if x > 8.2:  # the bow: full around the deck, then a quick taper to a point
        t = (x - 8.2) / (BOW - 8.2)
        return max(0.06, 3.85 * math.cos(t * math.pi / 2) ** 0.9)
    if x < -9.4:  # the stern: slightly narrower, cut flat (transom)
        t = (x + 9.4) / (STERN + 9.4)
        return 3.85 - 0.5 * t ** 2
    return 3.85


def top(x):
    """Top of the bulwark (the hull side above the deck)."""
    base = 0.85
    if x > 8.6:
        base += 1.15 * ((x - 8.6) / (BOW - 8.6)) ** 1.6  # the bow sweeps up
    if x < -9.0:
        base += 0.9 * ((-9.0 - x) / (-9.0 - STERN)) ** 1.4  # and the stern too
    return base


def bottom(x):
    if x > 6.0:
        t = (x - 6.0) / (BOW - 6.0)
        return -2.35 + 2.0 * t ** 1.6
    if x < -7.0:
        t = (x + 7.0) / (STERN + 7.0)
        return -2.35 + 0.9 * t ** 2
    return -2.35


def hull():
    stations = [STERN + i * (BOW - STERN) / 59 for i in range(60)]
    n = 22  # points per cross-section, port top -> keel -> starboard top
    verts, faces = [], []
    for x in stations:
        hw, t, b = half_width(x), top(x), bottom(x)
        for k in range(n):
            u = -math.pi / 2 + math.pi * k / (n - 1)
            s = math.sin(u)
            p = 3.2  # superellipse: a round belly with a fairly upright side
            z = hw * math.copysign(abs(s) ** (2 / p), s)
            y = t - (t - b) * abs(math.cos(u)) ** (2 / p)
            if y > -0.2:
                z *= 1.0 - 0.05 * min(1.0, (y + 0.2) / (t + 0.2))  # tumblehome near the top
            verts.append((x, y, z))
    for i in range(len(stations) - 1):
        for k in range(n - 1):
            a = i * n + k
            faces.append((a, a + 1, a + n + 1, a + n))
    faces.append(tuple(range(n - 1, -1, -1)))  # the transom
    obj = kit.mesh_from("Hull", verts, faces)
    kit.finish(obj, smooth=True, solidify=0.16, subdiv=1)

    def paint(c):
        x, y, z = c
        if x < STERN + 0.05:
            return "paint_teal"  # the transom
        if y < -1.05:
            return "paint_red"  # below the waterline
        if -0.55 < y < -0.25:
            return "trim_cream"  # a stripe along the side
        if y > top(x) - 0.12:
            return "wood_dark"  # the cap rail
        return "wood_hull"
    kit.set_face_materials(obj, paint)
    return obj


def deck_outline(y, x0, x1, inset=0.1, steps=18):
    """Polygon of the hull's inside at height y between x0 and x1 (game space, CCW from above)."""
    xs = [x0 + (x1 - x0) * i / steps for i in range(steps + 1)]
    port = [(x, y, -(half_width(x) - inset)) for x in xs]
    starboard = [(x, y, half_width(x) - inset) for x in reversed(xs)]
    return port + starboard


def decks():
    parts = []
    main = kit.box("Deck", (0, -0.06, 0), (18.4, 0.12, 7.5), "deck", bevel=0.0)
    parts.append(main)
    # Plank seams: thin dark lines along the deck.
    for i in range(-3, 4):
        parts.append(kit.box("Seam%d" % (i + 3), (0, 0.003, i * 1.0 + 0.5), (18.2, 0.01, 0.04), "wood_hull", bevel=0.0))
    fore = deck_outline(0.62, 9.0, BOW - 1.2, 0.18)
    parts.append(kit.mesh_from("Forecastle", fore, [tuple(range(len(fore)))], "deck", smooth=False))
    parts.append(kit.box("ForecastleStep", (9.05, 0.31, 0), (0.25, 0.62, 7.2), "wood_light", bevel=0.05))
    aft = deck_outline(0.82, STERN + 0.15, -9.0, 0.18)
    parts.append(kit.mesh_from("Quarterdeck", aft, [tuple(range(len(aft)))], "deck", smooth=False))
    parts.append(kit.box("QuarterdeckStep", (-9.05, 0.41, 0), (0.25, 0.82, 6.8), "wood_light", bevel=0.05))
    # Little balusters along the step edges (they explain the invisible rails at x = +-9).
    for side, height in ((9.0, 0.62), (-9.0, 0.82)):
        for i in range(9):
            z = -3.0 + i * 0.75
            parts.append(kit.cylinder("Baluster%.0f_%d" % (side, i), (side, height, z), (side, height + 0.5, z), 0.06,
                                      0.05, "trim_cream", verts=8))
        parts.append(kit.box("StepRail%.0f" % side, (side, height + 0.55, 0), (0.16, 0.1, 6.4), "wood_dark", bevel=0.04))
    return parts


def stern_cabin():
    parts = [kit.box("Cabin", (-9.95, 1.65, 0), (1.3, 1.7, 4.6), "wood_light", bevel=0.12)]
    parts.append(kit.box("CabinRoof", (-9.95, 2.6, 0), (1.6, 0.22, 5.1), "paint_teal", bevel=0.1))
    for z in (-1.4, 0.0, 1.4):  # round windows facing the deck (dark glass: no lamps in the 1700s)
        win = kit.cylinder("Window%.0f" % (z * 10), (-9.28, 1.75, z), (-9.24, 1.75, z), 0.32, mat="glass", verts=20)
        parts.append(win)
        parts.append(kit.torus("WindowRim%.0f" % (z * 10), (-9.26, 1.75, z), 0.34, 0.06, "gold", axis="x"))
    return parts


def mast_and_sails():
    parts = [kit.cylinder("Mast", (1, 0, 0), (1, 9.2, 0), 0.26, 0.17, "wood_dark", verts=14)]
    parts.append(kit.torus("MastBand1", (1, 1.2, 0), 0.26, 0.05, "gold"))
    parts.append(kit.torus("MastBand2", (1, 4.0, 0), 0.23, 0.05, "gold"))
    # Crow's nest: a little round basket.
    parts.append(kit.cylinder("CrowsNest", (1, 7.0, 0), (1, 7.6, 0), 0.75, 0.85, "wood_light", verts=20))
    parts.append(kit.torus("CrowsNestRim", (1, 7.6, 0), 0.85, 0.08, "wood_dark"))
    # Yard and a billowing square sail hanging under it, high enough to keep the deck visible.
    parts.append(kit.cylinder("Yard", (1.25, 6.4, -3.6), (1.25, 6.4, 3.6), 0.11, mat="wood_dark", verts=10))
    cols, rows = 12, 8
    verts, faces = [], []
    for r in range(rows + 1):
        v = r / rows
        y = 6.35 - v * 2.9
        width = 3.4 - 0.25 * v
        for c in range(cols + 1):
            u = c / cols * 2 - 1
            belly = (1 - u * u) * math.sin(v * math.pi * 0.9) * 0.95  # billows forward in the wind
            verts.append((1.35 + belly, y, u * width))
    for r in range(rows):
        for c in range(cols):
            a = r * (cols + 1) + c
            faces.append((a, a + 1, a + cols + 2, a + cols + 1))
    sail = kit.mesh_from("Sail", verts, faces, "sail")
    kit.finish(sail, solidify=0.03)
    parts.append(sail)
    # A stripe painted across the sail.
    sv, sf = [], []
    for r, y in enumerate((5.2, 4.75)):
        for c in range(cols + 1):
            u = c / cols * 2 - 1
            v = (6.35 - y) / 2.9
            belly = (1 - u * u) * math.sin(v * math.pi * 0.9) * 0.95
            sv.append((1.37 + belly, y, u * (3.4 - 0.25 * v)))
    for c in range(cols):
        sf.append((c, c + 1, c + cols + 2, c + cols + 1))
    parts.append(kit.mesh_from("SailStripe", sv, sf, "paint_red"))
    # Flag at the top.
    parts.append(kit.mesh_from("Flag", [(1, 9.1, 0), (1, 8.4, 0), (-0.4, 8.85, 0.15), (-0.2, 8.6, 0.1)],
                               [(0, 1, 3, 2)], "flag"))
    # Shrouds (rope ladders) from the crow's nest down to the bulwarks.
    for side in (-1, 1):
        for dx in (-0.7, 0.0, 0.7):
            parts.append(kit.cylinder("Shroud%d%.0f" % (side, dx * 10), (1 + dx * 0.2, 7.0, side * 0.7),
                                      (1 + dx * 1.6, top(1 + dx) - 0.05, side * 3.55), 0.02, mat="rope", verts=6))
    return parts


def bow_dressing():
    tip = (BOW - 0.35, top(BOW - 0.35) - 0.25, 0)
    parts = [kit.cylinder("Bowsprit", (BOW - 2.6, top(BOW - 2.6) - 0.1, 0), (BOW + 3.6, tip[1] + 1.3, 0), 0.16, 0.08,
                          "wood_dark", verts=12)]
    jib = kit.mesh_from("Jib", [(1.1, 8.6, 0), (BOW + 3.3, tip[1] + 1.35, 0), (BOW - 0.4, tip[1] + 0.9, 0)],
                        [(0, 1, 2)], "sail", smooth=False)
    kit.finish(jib, smooth=False, solidify=0.03)
    parts.append(jib)
    # A smiling golden fish figurehead under the bowsprit.
    fx, fy = BOW + 0.15, tip[1] - 0.15
    parts.append(kit.sphere("FigureheadBody", (fx, fy, 0), 0.42, "gold", scale=(1.25, 0.95, 0.75)))
    parts.append(kit.mesh_from("FigureheadTail", [(fx - 0.45, fy, 0), (fx - 0.95, fy + 0.4, 0), (fx - 0.95, fy - 0.4, 0)],
                               [(0, 1, 2)], "gold", smooth=False))
    for side in (-1, 1):
        parts.append(kit.sphere("FigureheadEye%d" % side, (fx + 0.3, fy + 0.12, side * 0.27), 0.09, "eye"))
        parts.append(kit.sphere("FigureheadShine%d" % side, (fx + 0.34, fy + 0.16, side * 0.33), 0.03, "white"))
        parts.append(kit.sphere("FigureheadBlush%d" % side, (fx + 0.22, fy - 0.08, side * 0.29), 0.07, "blush",
                                scale=(1, 0.6, 0.4)))
    return parts


def gunports():
    """Painted gunport lids along both sides (the cannons arrive with the battle system)."""
    parts = []
    for side in (-1, 1):
        for x in (-4.5, 0.0, 4.5):
            parts.append(kit.box("Gunport%d_%.0f" % (side, x), (x, -0.05, side * 3.93), (0.9, 0.6, 0.08), "wood_dark",
                                 bevel=0.04))
    return parts


def main():
    kit.reset()
    kit.into("Ship")
    objects = [hull()] + decks() + stern_cabin() + mast_and_sails() + bow_dressing() + gunports()
    kit.parent_all("ShipModel", objects)
    os.makedirs(os.path.join(ROOT, "assets/art/export/models"), exist_ok=True)
    os.makedirs(os.path.join(ROOT, "assets/art/source/blender"), exist_ok=True)
    kit.export("Ship", os.path.join(ROOT, "assets/art/export/models/ship.glb"))
    kit.save(os.path.join(ROOT, "assets/art/source/blender/ship.blend"))


main()
