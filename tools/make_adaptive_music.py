"""Synthesises the adaptive soundtrack: "Drunken Sailor" (traditional, public domain) as synced
layers that the game fades in and out with the ship's stability, plus one-shot stings.
Original arrangement and sounds, no samples. 100 BPM, 16 bars, every layer exactly the same length.

Run:  python3 tools/make_adaptive_music.py  ->  assets/audio/music/adaptive/*.wav
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
BPM = 100.0
BEAT = 60.0 / BPM
BARS = 16
LENGTH = BARS * 4 * BEAT
OUT = Path(__file__).resolve().parent.parent / "assets/audio/music/adaptive"

NAMES = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]


def hz(name: str) -> float:
    """'D4' -> frequency."""
    note, octave = name[:-1], int(name[-1])
    semis = NAMES.index(note) + 12 * (octave + 1)
    return 440.0 * 2 ** ((semis - 69) / 12)


def shift(name: str, semitones: int) -> str:
    note, octave = name[:-1], int(name[-1])
    i = NAMES.index(note) + semitones + 12 * octave
    return NAMES[i % 12] + str(i // 12)


# --- The tune (same as the original loop) --------------------------------------------------
VERSE_A = [("A4", 1), ("A4", .5), ("A4", .5), ("A4", 1), ("A4", .5), ("A4", .5), ("A4", 1), ("D4", 1), ("F4", 1), ("A4", 1)]
VERSE_G = [("G4", 1), ("G4", .5), ("G4", .5), ("G4", 1), ("G4", .5), ("G4", .5), ("G4", 1), ("C4", 1), ("E4", 1), ("G4", 1)]
VERSE_UP = [("A4", 1), ("A4", .5), ("A4", .5), ("A4", 1), ("A4", .5), ("A4", .5), ("A4", 1), ("B4", 1), ("C5", 1), ("D5", 1)]
ENDING = [("C5", 1), ("A4", 1), ("G4", 1), ("E4", 1), ("D4", 2), ("D4", 2)]
CHORUS_A = [("A4", 2), ("A4", 1), ("A4", 1), ("A4", 1), ("D4", 1), ("F4", 1), ("A4", 1)]
CHORUS_G = [("G4", 2), ("G4", 1), ("G4", 1), ("G4", 1), ("C4", 1), ("E4", 1), ("G4", 1)]
CHORUS_UP = [("A4", 2), ("A4", 1), ("A4", 1), ("A4", 1), ("B4", 1), ("C5", 1), ("D5", 1)]
MELODY = VERSE_A + VERSE_G + VERSE_UP + ENDING + CHORUS_A + CHORUS_G + CHORUS_UP + ENDING

# One harmony per bar, three flavours of the same progression (adaptive harmony).
ROOTS = ["D3", "D3", "C3", "C3", "D3", "D3", "A2", "D3"] * 2
STABLE = {"D3": ["D4", "F4", "A4"], "C3": ["C4", "E4", "G4"], "A2": ["A3", "C4", "E4"]}
TENSE = {"D3": ["D4", "G4", "Ab4", "C5"], "C3": ["C4", "E4", "Bb4", "Db5"], "A2": ["A3", "Db4", "G4", "Bb4"]}
CLUSTER = {"D3": ["D4", "Eb4", "E4", "F4"], "C3": ["C4", "Db4", "D4", "Gb4"], "A2": ["A3", "Bb3", "B3", "Eb4"]}


# --- Instruments ------------------------------------------------------------------------------
def env(t, length, attack=0.01, release=0.08):
    if t < attack:
        return t / attack
    if t > length - release:
        return max(0.0, (length - t) / release)
    return 1.0


def accordion(f, t):
    s = 0.0
    for detune in (1.0, 1.004):
        for h, w in ((1, 1.0), (2, 0.5), (3, 0.35), (4, 0.2), (5, 0.12)):
            s += w * math.sin(2 * math.pi * f * detune * h * t)
    return s * 0.12 * (1.0 + 0.08 * math.sin(2 * math.pi * 5.5 * t))


def tuba(f, t):
    return (math.sin(2 * math.pi * f * t) + 0.35 * math.sin(4 * math.pi * f * t)) * math.exp(-2.5 * t)


def pluck(f, t):
    s = 0.0
    for h, w in ((1, 1.0), (2, 0.6), (3, 0.3), (4, 0.15)):
        s += w * math.sin(2 * math.pi * f * h * t) * math.exp(-(4 + 3 * h) * t)
    return s * 0.5


def strings(f, t, tremolo=0.0):
    vib = 1.0 + 0.006 * math.sin(2 * math.pi * 6 * t)
    s = 0.0
    for h in range(1, 7):
        s += math.sin(2 * math.pi * f * vib * h * t) / h # sawtooth-ish
    trem = 1.0 - tremolo * (0.5 + 0.5 * math.sin(2 * math.pi * 14 * t))
    return s * 0.18 * trem


def brass(f, t):
    s = 0.0
    bright = min(1.0, t * 20)
    for h in range(1, 9):
        s += (math.sin(2 * math.pi * f * h * t) / h) * (bright if h > 3 else 1.0)
    return math.tanh(s * 0.9) * 0.4


def kazoo(f, t):
    vib = 1.0 + 0.02 * math.sin(2 * math.pi * 7 * t)
    x = (f * vib * t) % 1.0
    buzz = 1.0 if x < 0.3 else -0.6 # nasal pulse wave
    return buzz * 0.3


rng = random.Random(42)


def noise():
    return rng.random() * 2 - 1


# --- Rendering helpers -------------------------------------------------------------------------
def track(seconds=LENGTH):
    return [0.0] * int(seconds * RATE)


def add(buf, start, length, voice, gain=1.0):
    first = int(start * RATE)
    for i in range(int(length * RATE)):
        j = first + i
        if 0 <= j < len(buf):
            buf[j] += voice(i / RATE, length) * gain


def save(name, buf, gain=1.0):
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / (name + ".wav")), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s * gain)) * 32000)) for s in buf))
    print(f"{name}.wav  {len(buf) / RATE:.1f} s")


def beats():
    for bar in range(BARS):
        for beat in range(4):
            yield bar, beat, (bar * 4 + beat) * BEAT


# --- Layers ---------------------------------------------------------------------------------------
def melody():
    buf = track()
    time = 0.0
    for note, b in MELODY:
        f = hz(note)
        add(buf, time, b * BEAT * 0.92, lambda t, L, f=f: accordion(f, t) * env(t, L))
        time += b * BEAT
    return buf


def bass_stable():
    buf = track()
    for bar, beat, start in beats():
        if beat % 2 == 0:
            f = hz(ROOTS[bar] if beat == 0 else shift(ROOTS[bar], 7))
            add(buf, start, BEAT * 0.9, lambda t, L, f=f: tuba(f, t) * env(t, L, 0.01, 0.1), 0.7)
    return buf


def chords(table, tremolo=0.0, every="offbeat"):
    buf = track()
    for bar, beat, start in beats():
        tones = table[ROOTS[bar]]
        if every == "offbeat" and beat % 2 == 1:
            for n in tones:
                f = hz(n)
                add(buf, start, BEAT * 0.45, lambda t, L, f=f: accordion(f, t) * env(t, L), 0.45)
        elif every == "sustain" and beat == 0:
            for n in tones:
                f = hz(n)
                add(buf, start, BEAT * 3.9, lambda t, L, f=f: strings(f, t, tremolo) * env(t, L, 0.05, 0.2), 0.5)
    return buf


def flourish():
    buf = track()
    for bar, beat, start in beats():
        tones = STABLE[ROOTS[bar]]
        for k in range(2): # eighth-note arpeggio runs on beats 2 and 4
            if beat in (1, 3):
                f = hz(shift(tones[(beat + k) % 3], 12))
                add(buf, start + k * BEAT / 2, BEAT / 2, lambda t, L, f=f: pluck(f, t), 0.5)
    return buf


def perc_light():
    buf = track()
    for bar, beat, start in beats():
        if beat % 2 == 0:
            add(buf, start, 0.15, lambda t, L: math.sin(2 * math.pi * (90 - 300 * t) * t) * (1 - t / L) ** 2, 0.7)
        else:
            add(buf, start, 0.07, lambda t, L: noise() * (1 - t / L), 0.25)
    return buf


def perc_busy():
    buf = track()
    for bar, beat, start in beats():
        for k in range(2): # shaker on every eighth, accent on the off-beat
            add(buf, start + k * BEAT / 2, 0.05, lambda t, L: noise() * (1 - t / L) ** 2, 0.18 if k == 0 else 0.3)
        if beat == 3: # snare
            add(buf, start, 0.18, lambda t, L: (noise() * 0.7 + 0.3 * math.sin(2 * math.pi * 190 * t)) * math.exp(-18 * t), 0.5)
    return buf


def perc_frantic():
    buf = track()
    for bar, beat, start in beats():
        for k in range(4): # sixteenth hats
            add(buf, start + k * BEAT / 4, 0.03, lambda t, L: noise() * (1 - t / L), 0.15 + 0.1 * (k % 2))
        add(buf, start + BEAT * 0.75, 0.12, lambda t, L: math.sin(2 * math.pi * (80 - 250 * t) * t) * (1 - t / L) ** 2, 0.5)
        if beat == 3 and bar % 2 == 1: # tom fill
            for k in range(4):
                f = 180 - k * 25
                add(buf, start + k * BEAT / 4, 0.12, lambda t, L, f=f: math.sin(2 * math.pi * f * t) * math.exp(-15 * t), 0.45)
        if beat == 0 and bar % 4 == 0: # cymbal
            add(buf, start, 1.2, lambda t, L: noise() * math.exp(-3 * t), 0.18)
    return buf


def bass_chromatic():
    buf = track()
    for bar, beat, start in beats():
        root = ROOTS[bar]
        nxt = ROOTS[(bar + 1) % BARS]
        line = [root, shift(root, 3), shift(root, 7), shift(nxt, -1)] # walk up, approach the next root chromatically
        for k in range(2):
            n = line[beat] if k == 0 else shift(line[beat], 1 if beat == 3 else 12)
            f = hz(n)
            add(buf, start + k * BEAT / 2, BEAT * 0.45, lambda t, L, f=f: tuba(f, t) * env(t, L, 0.005, 0.05), 0.6)
    return buf


def counter():
    buf = track()
    for bar, beat, start in beats():
        base = hz("A5")
        for k in range(2): # a nervous climbing line, eighth notes
            semis = (bar * 8 + beat * 2 + k) % 12
            f = base * 2 ** (semis / 12)
            add(buf, start + k * BEAT / 2, BEAT * 0.48, lambda t, L, f=f: strings(f, t, 0.8) * env(t, L, 0.01, 0.04), 0.35)
    return buf


def brass_agitated():
    buf = track()
    for bar, beat, start in beats():
        tones = TENSE[ROOTS[bar]]
        for k in (1, 3): # stabs on the sixteenth off-beats
            f = hz(shift(tones[(beat + k) % len(tones)], -12))
            add(buf, start + k * BEAT / 4, BEAT * 0.18, lambda t, L, f=f: brass(f, t) * env(t, L, 0.005, 0.03), 0.6)
    return buf


def meltdown():
    buf = track()
    for bar, beat, start in beats():
        tones = CLUSTER[ROOTS[bar]]
        off = rng.choice([0.0, 0.25, 0.4, 0.66]) * BEAT # displaced accents
        if rng.random() < 0.7:
            for n in tones:
                f = hz(n)
                add(buf, start + off, BEAT * 0.3, lambda t, L, f=f: brass(f, t) * env(t, L, 0.002, 0.05), 0.35)
        if beat == 2 and rng.random() < 0.5: # a kazoo honks the wrong note of the tune
            f = hz(rng.choice(["Eb5", "Ab4", "Db5", "Gb5"]))
            add(buf, start, BEAT * 0.8, lambda t, L, f=f: kazoo(f, t) * env(t, L, 0.01, 0.1), 0.5)
        if beat == 0 and bar % 2 == 1: # slide whistle
            add(buf, start, BEAT * 1.5, lambda t, L: math.sin(2 * math.pi * (1400 - 700 * t / L) * t) * env(t, L, 0.02, 0.1), 0.25)
        if rng.random() < 0.2: # random crashes
            add(buf, start + off, 0.9, lambda t, L: noise() * math.exp(-3.5 * t), 0.25)
    return buf


# --- Stings ------------------------------------------------------------------------------------------
def sting_crash():
    buf = track(1.8)
    for n in ["D3", "Eb4", "A4", "Ab5"]:
        f = hz(n)
        add(buf, 0.0, 0.5, lambda t, L, f=f: brass(f, t) * env(t, L, 0.002, 0.2), 0.4)
    add(buf, 0.0, 1.7, lambda t, L: noise() * math.exp(-2.5 * t), 0.5)
    add(buf, 0.0, 0.3, lambda t, L: math.sin(2 * math.pi * (70 - 150 * t) * t) * (1 - t / L), 0.9)
    return buf


def sting_honk():
    buf = track(0.9)
    add(buf, 0.0, 0.25, lambda t, L: kazoo(hz("Db5"), t) * env(t, L), 0.8)
    add(buf, 0.3, 0.5, lambda t, L: kazoo(hz("C5") * (1 - 0.1 * t / L), t) * env(t, L), 0.8)
    return buf


def sting_fanfare():
    buf = track(3.2)
    run = ["D4", "F#4" if False else "Gb4", "A4", "D5"] # D major (Picardy third): we survived!
    for i, n in enumerate(run):
        f = hz(n)
        add(buf, i * 0.18, 0.5 if i < 3 else 2.2, lambda t, L, f=f: brass(f, t) * env(t, L, 0.01, 0.3), 0.55)
    for n in ["D3", "A3", "D4", "Gb4"]:
        f = hz(n)
        add(buf, 0.54, 2.4, lambda t, L, f=f: strings(f, t) * env(t, L, 0.05, 0.4), 0.4)
    add(buf, 0.54, 2.0, lambda t, L: noise() * math.exp(-2 * t), 0.2)
    return buf


def sting_cadence():
    buf = track(3.0)
    for start, chord in ((0.0, ["A3", "Db4", "E4", "G4"]), (0.9, ["D3", "A3", "D4", "Gb4", "A4"])): # A7 -> D major
        for n in chord:
            f = hz(n)
            add(buf, start, 0.85 if start == 0.0 else 2.0, lambda t, L, f=f: accordion(f, t) * env(t, L, 0.02, 0.4), 0.5)
    add(buf, 0.9, 1.8, lambda t, L: tuba(hz("D2"), t * 0.5), 0.6)
    return buf


def sting_sad_trombone():
    buf = track(3.2)
    for i, n in enumerate(["G3", "Gb3", "F3"]):
        f = hz(n)
        add(buf, i * 0.6, 0.55, lambda t, L, f=f: brass(f, t) * env(t, L, 0.02, 0.1), 0.6)
    add(buf, 1.8, 1.3, lambda t, L: brass(hz("E3") * (1 + 0.02 * math.sin(2 * math.pi * 6 * t)), t) * env(t, L, 0.02, 0.4), 0.6)
    return buf


if __name__ == "__main__":
    layers = {
        # Gains balance the layers so the melody always leads (measured RMS, see git history).
        "melody": (melody, 1.4), "bass_stable": (bass_stable, 0.75), "chords_stable": (lambda: chords(STABLE), 1.4),
        "flourish": (flourish, 1.1), "perc_light": (perc_light, 1.0), "perc_busy": (perc_busy, 2.0),
        "bass_chromatic": (bass_chromatic, 0.5), "counter": (counter, 2.2),
        "chords_tense": (lambda: chords(TENSE, 0.7, "sustain"), 0.9), "brass": (brass_agitated, 1.2),
        "perc_frantic": (perc_frantic, 0.9), "meltdown": (meltdown, 1.0),
    }
    for name, (make, gain) in layers.items():
        save(name, make(), 0.55 * gain)
    for name, make in {"sting_crash": sting_crash, "sting_honk": sting_honk, "sting_fanfare": sting_fanfare,
            "sting_cadence": sting_cadence, "sting_sad_trombone": sting_sad_trombone}.items():
        save(name, make(), 0.6)
