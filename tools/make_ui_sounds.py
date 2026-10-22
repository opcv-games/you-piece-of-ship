"""Synthesises the interface sounds (hover tick, click, coin, whoosh, stamp, error). No samples.
Run:  python3 tools/make_ui_sounds.py  ->  assets/audio/ui/*.wav
"""
import math, random, struct, wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parent.parent / "assets/audio/ui"
rng = random.Random(7)


def render(seconds, voice):
    return [voice(i / RATE) for i in range(int(seconds * RATE))]


def save(name, buf, gain=0.7):
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / (name + ".wav")), "wb") as out:
        out.setnchannels(1); out.setsampwidth(2); out.setframerate(RATE)
        out.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s * gain)) * 32000)) for s in buf))


save("hover", render(0.06, lambda t: math.sin(2 * math.pi * 1800 * t) * math.exp(-60 * t)), 0.35)
save("click", render(0.12, lambda t: (math.sin(2 * math.pi * (600 - 2500 * t) * t) + 0.4 * math.sin(2 * math.pi * 1200 * t)) * math.exp(-35 * t)))
save("coin", render(0.35, lambda t: math.sin(2 * math.pi * (1320 if t < 0.07 else 1760) * t) * math.exp(-9 * t) * (1 if t > 0.005 else t / 0.005)))
save("whoosh", render(0.4, lambda t: (rng.random() * 2 - 1) * math.sin(math.pi * t / 0.4) * (0.4 + 0.6 * math.sin(2 * math.pi * (3 + 10 * t) * t))), 0.45)
save("stamp", render(0.35, lambda t: (math.sin(2 * math.pi * (110 - 200 * t) * t) * 0.9 + (rng.random() * 2 - 1) * 0.5 * math.exp(-25 * t)) * math.exp(-10 * t)))
save("error", render(0.3, lambda t: (1 if (220 * t) % 1 < 0.5 else -1) * 0.5 * math.exp(-6 * t)), 0.4)
print("ui sounds done")
