"""Deck props, painted-kawaii style. blender -b -P tools/blender/build_props.py
-> assets/art/export/models/<prop>.glb (+ assets/art/source/blender/props.blend)

Every prop is modelled in its station's own frame (origin on the deck at the station node), so the
game drops it in place without adjusting anything. Animated parts are separate named objects
(the pump's "Lever", the helm's "Wheel")."""
import math
import os
import sys

sys.path.append(os.path.dirname(__file__))
import kit  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets/art/export/models")


def chest():
    """Treasure chest replacing the cargo crate (0.8 m cube, origin at the bottom centre)."""
    p = [kit.box("ChestBody", (0, 0.24, 0), (0.82, 0.48, 0.6), "wood_light", bevel=0.06)]
    # Domed lid: a half cylinder along x.
    lid = kit.cylinder("ChestLid", (-0.41, 0.48, 0), (0.41, 0.48, 0), 0.3, mat="paint_red", verts=24)
    kit.finish(lid, bevel=0.03)
    p.append(lid)
    for x in (-0.3, 0.3):  # gold bands over the lid and body
        p.append(kit.torus("LidBand%.0f" % (x * 10), (x, 0.48, 0), 0.305, 0.035, "gold", axis="x"))
        p.append(kit.box("BodyBand%.0f" % (x * 10), (x, 0.24, 0), (0.08, 0.5, 0.64), "gold", bevel=0.02))
    p.append(kit.box("Lock", (0, 0.45, 0.31), (0.16, 0.2, 0.06), "gold", bevel=0.03))
    p.append(kit.sphere("Keyhole", (0, 0.43, 0.345), 0.03, "eye"))
    # Coins peeking out under the lid.
    for i, x in enumerate((-0.2, -0.05, 0.12, 0.25)):
        p.append(kit.cylinder("Coin%d" % i, (x, 0.5, 0.18 + (i % 2) * 0.05), (x, 0.52, 0.2 + (i % 2) * 0.05), 0.07,
                              mat="gold", verts=12))
    return p


def plank():
    p = [kit.box("Plank", (0, 0.06, 0), (1.2, 0.12, 0.35), "wood_light", bevel=0.03)]
    for x in (-0.45, 0.45):
        p.append(kit.sphere("Nail%.0f" % (x * 10), (x, 0.125, 0), 0.03, "iron"))
    return p


def pin():
    p = [kit.cylinder("PinShaft", (-0.42, 0.11, 0), (0.3, 0.11, 0), 0.07, mat="iron", verts=12)]
    p.append(kit.cylinder("PinHead", (0.3, 0.11, 0), (0.45, 0.11, 0), 0.13, mat="gold", verts=16))
    p.append(kit.torus("PinRing", (-0.42, 0.11, 0), 0.08, 0.025, "gold", axis="x"))
    return p


def shovel():
    """A shovel heaped with coal (the "coal" item)."""
    p = [kit.cylinder("ShovelHandle", (-0.5, 0.12, 0), (0.15, 0.1, 0), 0.04, mat="wood_light", verts=8)]
    p.append(kit.box("ShovelBlade", (0.3, 0.06, 0), (0.36, 0.04, 0.34), "iron", bevel=0.02))
    p.append(kit.torus("ShovelGrip", (-0.55, 0.12, 0), 0.08, 0.025, "wood_dark", axis="z"))
    for i, (x, z) in enumerate(((0.25, -0.08), (0.35, 0.06), (0.28, 0.08), (0.38, -0.06), (0.32, 0.0))):
        p.append(kit.sphere("CoalLump%d" % i, (x, 0.12 + (i % 2) * 0.03, z), 0.08 - i * 0.006, "coal"))
    return p


def coal_pile():
    p = []
    lumps = [(0, 0.2, 0, 0.42), (0.35, 0.14, 0.2, 0.28), (-0.3, 0.13, 0.25, 0.26), (0.2, 0.12, -0.32, 0.25),
             (-0.28, 0.12, -0.25, 0.25), (0.05, 0.42, 0.05, 0.25), (0.45, 0.1, -0.05, 0.2)]
    for i, (x, y, z, r) in enumerate(lumps):
        p.append(kit.sphere("Lump%d" % i, (x, y, z), r, "coal", segments=10, rings=6))
    p.append(kit.cylinder("PileRim", (0, 0, 0), (0, 0.08, 0), 0.8, 0.75, "wood_dark", verts=20))
    return p


def pump():
    """Hand pump against the port rail (station origin; body at z = -0.85, spout over the side)."""
    p = [kit.cylinder("PumpBarrel", (0, 0, -0.85), (0, 1.0, -0.85), 0.34, 0.3, "paint_teal", verts=20)]
    p.append(kit.torus("PumpBand1", (0, 0.2, -0.85), 0.34, 0.04, "gold"))
    p.append(kit.torus("PumpBand2", (0, 0.85, -0.85), 0.31, 0.04, "gold"))
    p.append(kit.sphere("PumpCap", (0, 1.0, -0.85), 0.31, "gold", scale=(1, 0.45, 1)))
    # Spout: out over the rail, curving down to the sea.
    p.append(kit.cylinder("Spout1", (0, 0.75, -0.95), (0, 1.0, -1.45), 0.09, 0.09, "iron", verts=12))
    p.append(kit.cylinder("Spout2", (0, 1.0, -1.45), (0, 0.85, -1.75), 0.09, 0.11, "iron", verts=12))
    # The lever: a post on top and a long handle (exported as one object named Lever, pivot at its hinge).
    p.append(kit.cylinder("LeverPost", (0, 1.05, -0.85), (0, 1.45, -0.85), 0.05, mat="iron", verts=8))
    return p


def pump_lever():
    """The pump handle, modelled around its hinge at (0, 1.45, -0.85); the game rocks it."""
    p = [kit.cylinder("LeverArm", (-0.1, 1.45, -0.85), (0.85, 1.45, -0.85), 0.045, mat="wood_dark", verts=8)]
    p.append(kit.sphere("LeverKnob", (0.9, 1.45, -0.85), 0.09, "paint_red"))
    p.append(kit.cylinder("LeverRod", (-0.1, 1.45, -0.85), (-0.1, 1.05, -0.85), 0.03, mat="iron", verts=6))
    return p


def helm():
    p = [kit.cylinder("HelmPost", (0.7, 0, 0), (0.7, 1.05, 0), 0.16, 0.12, "wood_dark", verts=12)]
    p.append(kit.cylinder("HelmBase", (0.7, 0, 0), (0.7, 0.12, 0), 0.3, 0.26, "wood_light", verts=16))
    p.append(kit.cylinder("HelmCompass", (0.95, 0.85, 0), (0.95, 0.95, 0), 0.17, mat="gold", verts=16))
    return p


def wheel():
    """The ship's wheel, centred on its axle at the origin, facing along x (rotates about x)."""
    p = [kit.torus("WheelRim", (0, 0, 0), 0.5, 0.05, "wood_light", axis="x")]
    p.append(kit.cylinder("WheelHub", (-0.06, 0, 0), (0.06, 0, 0), 0.11, mat="gold", verts=16))
    for i in range(8):
        a = i * math.pi / 4
        y, z = math.sin(a), math.cos(a)
        p.append(kit.cylinder("Spoke%d" % i, (0, y * 0.1, z * 0.1), (0, y * 0.68, z * 0.68), 0.03, 0.035, "wood_light",
                              verts=6))
        p.append(kit.sphere("Handle%d" % i, (0, y * 0.7, z * 0.7), 0.06, "wood_dark", segments=8, rings=6))
    return p


def map_table():
    p = [kit.box("TableTop", (0, 0.86, -0.85), (1.7, 0.1, 0.9), "wood_light", bevel=0.04)]
    for x in (-0.7, 0.7):
        for z in (-1.2, -0.5):
            p.append(kit.cylinder("Leg%.0f%.0f" % (x * 10, z * 10), (x, 0, z), (x, 0.82, z), 0.07, 0.05, "wood_dark",
                                  verts=8))
    p.append(kit.box("Chart", (0, 0.92, -0.85), (1.45, 0.02, 0.72), "sand", bevel=0.0))
    p.append(kit.box("ChartX", (0.35, 0.935, -0.75), (0.2, 0.01, 0.05), "paint_red", bevel=0.0, rot=(0, 0.8, 0)))
    p.append(kit.box("ChartX2", (0.35, 0.935, -0.75), (0.2, 0.01, 0.05), "paint_red", bevel=0.0, rot=(0, -0.8, 0)))
    p.append(kit.cylinder("Compass", (-0.5, 0.92, -1.05), (-0.5, 0.97, -1.05), 0.12, mat="gold", verts=16))
    p.append(kit.cylinder("Candle", (0.65, 0.9, -1.1), (0.65, 1.1, -1.1), 0.05, mat="trim_cream", verts=8))
    p.append(kit.sphere("Flame", (0.65, 1.16, -1.1), 0.045, "glow", scale=(1, 1.6, 1)))
    return p


def spares_box(kind):
    """An open crate of planks, or a small barrel of rudder pins (origin at the station)."""
    if kind == "planks":
        p = [kit.box("Crate", (0, 0.3, -0.85), (1.0, 0.6, 0.8), "wood_hull", bevel=0.05)]
        for i in range(4):
            p.append(kit.box("Slat%d" % i, (0, 0.2 + i * 0.13, -0.44), (1.04, 0.05, 0.04), "wood_dark", bevel=0.01))
        for i, z in enumerate((-1.05, -0.85, -0.65)):
            p.append(kit.box("Spare%d" % i, (0.05 * i, 0.68, z), (1.1, 0.1, 0.18), "wood_light", bevel=0.02,
                             rot=(0, 0.1 * (i - 1), 0.08)))
        return p
    p = [kit.cylinder("Barrel", (0, 0, -0.85), (0, 0.7, -0.85), 0.36, 0.33, "wood_hull", verts=20)]
    for y in (0.12, 0.58):
        p.append(kit.torus("Hoop%.0f" % (y * 100), (0, y, -0.85), 0.36, 0.03, "iron"))
    for i, a in enumerate((0.0, 1.6, 3.4)):
        x, z = math.cos(a) * 0.12, -0.85 + math.sin(a) * 0.12
        p.append(kit.cylinder("SparePin%d" % i, (x, 0.5, z), (x + 0.05, 0.95, z), 0.05, mat="iron", verts=8))
        p.append(kit.sphere("SparePinHead%d" % i, (x + 0.05, 0.97, z), 0.08, "gold"))
    return p


def engine():
    """A chubby little boiler (station origin; body centred at (0, 0.6, 0.85)), chimney at (-0.4, *, 0.85)."""
    p = [kit.box("Boiler", (0, 0.62, 0.85), (1.6, 1.15, 0.8), "iron", bevel=0.22)]
    p.append(kit.box("BoilerBase", (0, 0.08, 0.85), (1.75, 0.16, 0.9), "wood_dark", bevel=0.05))
    for x in (-0.6, 0.0, 0.6):
        p.append(kit.box("Rivets%.0f" % (x * 10), (x, 0.62, 0.85), (0.06, 1.18, 0.84), "gold", bevel=0.02))
    p.append(kit.cylinder("Chimney", (-0.4, 1.15, 0.85), (-0.4, 2.45, 0.85), 0.2, 0.22, "iron", verts=16))
    p.append(kit.cylinder("ChimneyTop", (-0.4, 2.45, 0.85), (-0.4, 2.65, 0.85), 0.24, 0.3, "paint_red", verts=16))
    p.append(kit.cylinder("Whistle", (0.5, 1.15, 0.85), (0.5, 1.45, 0.85), 0.06, 0.05, "gold", verts=10))
    return p


def cooling_pipe():
    p = [kit.cylinder("Pipe", (-1.1, 0.7, 0.75), (1.1, 0.7, 0.75), 0.11, mat="gold", verts=14)]
    for x in (-0.6, 0.6):
        p.append(kit.torus("Joint%.0f" % (x * 10), (x, 0.7, 0.75), 0.12, 0.04, "iron", axis="x"))
    p.append(kit.cylinder("Valve", (0, 0.7, 0.75), (0, 1.0, 0.75), 0.04, mat="iron", verts=8))
    p.append(kit.torus("ValveWheel", (0, 1.02, 0.75), 0.13, 0.025, "paint_red"))
    for x in (-1.0, 1.0):
        p.append(kit.cylinder("Bracket%.0f" % x, (x, 0, 0.75), (x, 0.62, 0.75), 0.05, mat="wood_dark", verts=8))
    return p


def telescope():
    p = [kit.cylinder("TripodPost", (0.5, 0, 0), (0.5, 1.15, 0), 0.06, mat="wood_dark", verts=8)]
    p.append(kit.cylinder("Tube", (0.2, 1.15, 0), (1.2, 1.3, 0), 0.12, 0.09, "gold", verts=14))
    p.append(kit.cylinder("Lens", (1.2, 1.3, 0), (1.24, 1.305, 0), 0.1, mat="glass", verts=14))
    return p


def buoy():
    p = [kit.cylinder("BuoyBody", (0, -0.4, 0), (0, 1.2, 0), 0.75, 0.5, "paint_red", verts=20)]
    p.append(kit.torus("BuoyStripe", (0, 0.6, 0), 0.6, 0.1, "trim_cream"))
    p.append(kit.cylinder("BuoyMast", (0, 1.2, 0), (0, 2.6, 0), 0.08, mat="iron", verts=8))
    p.append(kit.sphere("BuoyLight", (0, 2.75, 0), 0.22, "glow"))
    return p


def leak_hole():
    """A splintered hole in the deck boards, water glinting inside (origin at its centre)."""
    import random
    random.seed(4)
    p = [kit.cylinder("HoleDark", (0, 0.0, 0), (0, 0.035, 0), 0.45, mat="eye", verts=18)]
    p[0].scale = (1.0, 0.65, 1.0)
    p.append(kit.cylinder("HoleWater", (0, 0.036, 0), (0, 0.04, 0), 0.3, mat="water", verts=14))
    for i in range(9):
        a = i * 2 * math.pi / 9 + random.uniform(-0.2, 0.2)
        r = 0.42 + random.uniform(-0.05, 0.08)
        p.append(kit.box("Splinter%d" % i, (math.cos(a) * r, 0.05, math.sin(a) * r * 0.65),
                         (0.28, 0.05, 0.08), "wood_light", bevel=0.01, rot=(random.uniform(-0.4, 0.4), -a, 0.3)))
    return p


PROPS = {
    "leak_hole": leak_hole,
    "chest": chest, "plank": plank, "pin": pin, "shovel": shovel, "coal_pile": coal_pile, "pump": pump,
    "pump_lever": pump_lever, "helm": helm, "wheel": wheel, "map_table": map_table,
    "plank_box": lambda: spares_box("planks"), "pin_box": lambda: spares_box("pins"), "engine": engine,
    "cooling_pipe": cooling_pipe, "telescope": telescope, "buoy": buoy,
}


def main():
    kit.reset()
    os.makedirs(OUT, exist_ok=True)
    for name, build in PROPS.items():
        kit.into(name)
        kit.parent_all(name, build())
        kit.export(name, os.path.join(OUT, name + ".glb"))
    kit.save(os.path.join(ROOT, "assets/art/source/blender/props.blend"))


main()
