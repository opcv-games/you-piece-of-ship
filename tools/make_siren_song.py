"""The siren's song: a soft, dreamy "ooo-aaa" melody that loops (8 bars, original tune).
Run: python3 tools/make_siren_song.py -> assets/audio/sfx/siren_song.wav"""
import math
import struct
import wave
from pathlib import Path

RATE = 44100
BEAT = 0.5
# (MIDI note, beats): a slow, wistful line in A minor.
MELODY = [(69, 2), (72, 1), (76, 1), (74, 2), (72, 2), (71, 1), (72, 1), (74, 2), (69, 4),
          (76, 2), (77, 1), (76, 1), (74, 2), (72, 2), (71, 1), (69, 1), (68, 2), (69, 4)]


def freq(note):
    return 440.0 * 2 ** ((note - 69) / 12)


def voice(f, t, length):
    """A breathy vocal-ish tone: a few harmonics shaped like an "ah" plus vibrato."""
    vib = 1.0 + 0.008 * math.sin(2 * math.pi * 5.2 * t) * min(1.0, t / 0.3)
    phase = 2 * math.pi * f * vib * t
    tone = (math.sin(phase) * 1.0 + math.sin(2 * phase) * 0.45 + math.sin(3 * phase) * 0.25
            + math.sin(4 * phase) * 0.08)
    attack = min(1.0, t / 0.12)
    release = min(1.0, (length - t) / 0.25)
    return tone * attack * max(0.0, release)


def main():
    total = sum(b for _, b in MELODY) * BEAT
    samples = [0.0] * int(total * RATE)
    start = 0.0
    for note, beats in MELODY:
        length = beats * BEAT
        f = freq(note)
        for i in range(int(length * RATE)):
            t = i / RATE
            index = int((start + t) * RATE)
            if index < len(samples):
                samples[index] += voice(f, t, length) * 0.22
                # a soft harp-like drone a fifth below
                samples[index] += math.sin(2 * math.pi * f / 1.5 * t) * math.exp(-t * 2.0) * 0.08
        start += length
    peak = max(abs(s) for s in samples) or 1.0
    out = Path(__file__).resolve().parent.parent / "assets/audio/sfx/siren_song.wav"
    with wave.open(str(out), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(b"".join(struct.pack("<h", int(s / peak * 0.8 * 32767)) for s in samples))
    print(out)


main()
