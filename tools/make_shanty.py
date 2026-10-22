"""Synthesises the placeholder music loop: "Drunken Sailor" (traditional, public domain),
arranged as accordion melody + oom-pah bass + deck stomp. Original arrangement, no samples.

Run:  python3 tools/make_shanty.py  ->  assets/audio/music/drunken_sailor_loop.wav
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
BPM = 132.0
BEAT = 60.0 / BPM
OUT = Path(__file__).resolve().parent.parent / "assets/audio/music/drunken_sailor_loop.wav"

NOTE = {"C4": 261.63, "D4": 293.66, "E4": 329.63, "F4": 349.23, "G4": 392.00, "A4": 440.00,
        "B4": 493.88, "C5": 523.25, "D5": 587.33, "D3": 146.83, "A2": 110.00, "C3": 130.81,
        "G2": 98.00, "A3": 220.00, "F3": 174.61, "E3": 164.81, "G3": 196.00}

# Melody as (note, beats). One bar = 4 beats; 16 bars, verse then chorus.
VERSE_A = [("A4", 1), ("A4", .5), ("A4", .5), ("A4", 1), ("A4", .5), ("A4", .5), ("A4", 1), ("D4", 1), ("F4", 1), ("A4", 1)]
VERSE_G = [("G4", 1), ("G4", .5), ("G4", .5), ("G4", 1), ("G4", .5), ("G4", .5), ("G4", 1), ("C4", 1), ("E4", 1), ("G4", 1)]
VERSE_UP = [("A4", 1), ("A4", .5), ("A4", .5), ("A4", 1), ("A4", .5), ("A4", .5), ("A4", 1), ("B4", 1), ("C5", 1), ("D5", 1)]
ENDING = [("C5", 1), ("A4", 1), ("G4", 1), ("E4", 1), ("D4", 2), ("D4", 2)]
CHORUS_A = [("A4", 2), ("A4", 1), ("A4", 1), ("A4", 1), ("D4", 1), ("F4", 1), ("A4", 1)]
CHORUS_G = [("G4", 2), ("G4", 1), ("G4", 1), ("G4", 1), ("C4", 1), ("E4", 1), ("G4", 1)]
CHORUS_UP = [("A4", 2), ("A4", 1), ("A4", 1), ("A4", 1), ("B4", 1), ("C5", 1), ("D5", 1)]
MELODY = VERSE_A + VERSE_G + VERSE_UP + ENDING + CHORUS_A + CHORUS_G + CHORUS_UP + ENDING

# One chord per bar: (bass root, chord tones for the "pah").
DM = ("D3", ["F3", "A3"])
C = ("C3", ["E3", "G3"])
AM = ("A2", ["E3", "A3"])
CHORDS = [DM, DM, C, C, DM, DM, AM, DM] * 2


def accordion(freq: float, t: float) -> float:
    """Two slightly detuned reedy oscillators with a little tremolo."""
    tone = 0.0
    for detune in (1.0, 1.004):
        f = freq * detune
        for harmonic, weight in ((1, 1.0), (2, 0.5), (3, 0.35), (4, 0.2), (5, 0.12)):
            tone += weight * math.sin(2 * math.pi * f * harmonic * t)
    return tone * 0.12 * (1.0 + 0.08 * math.sin(2 * math.pi * 5.5 * t))


def envelope(t: float, length: float, attack=0.02, release=0.06) -> float:
    if t < attack:
        return t / attack
    if t > length - release:
        return max(0.0, (length - t) / release)
    return 1.0


def main() -> None:
    total_beats = sum(beats for _, beats in MELODY)
    assert total_beats == len(CHORDS) * 4, total_beats
    samples = [0.0] * int(total_beats * BEAT * RATE)

    def add(start: float, length: float, voice) -> None:
        first = int(start * RATE)
        for i in range(int(length * RATE)):
            if first + i < len(samples):
                samples[first + i] += voice(i / RATE, length)

    # Melody
    time = 0.0
    for name, beats in MELODY:
        freq = NOTE[name]
        length = beats * BEAT * 0.92
        add(time, length, lambda t, L, f=freq: accordion(f, t) * envelope(t, L))
        time += beats * BEAT

    # Oom-pah bass and deck stomp
    rng = random.Random(3)
    for bar, (root, tones) in enumerate(CHORDS):
        for beat in range(4):
            start = (bar * 4 + beat) * BEAT
            if beat % 2 == 0:
                f = NOTE[root]
                add(start, BEAT * 0.8, lambda t, L, f=f: 0.45 * math.sin(2 * math.pi * f * t) * envelope(t, L, 0.01, 0.15))
                # stomp: a short pitched-down thump
                add(start, 0.14, lambda t, L: 0.6 * math.sin(2 * math.pi * (90 - 300 * t) * t) * (1 - t / L) ** 2)
            else:
                for tone in tones:
                    f = NOTE[tone]
                    add(start, BEAT * 0.45, lambda t, L, f=f: 0.5 * accordion(f, t) * envelope(t, L, 0.01, 0.08))
                # hand clap: a burst of noise
                add(start, 0.06, lambda t, L: 0.25 * (rng.random() * 2 - 1) * (1 - t / L))

    peak = max(abs(s) for s in samples) or 1.0
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(b"".join(struct.pack("<h", int(s / peak * 0.85 * 32767)) for s in samples))
    print(f"{OUT.name}: {len(samples) / RATE:.1f} s")


if __name__ == "__main__":
    main()
