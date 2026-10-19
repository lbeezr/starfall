#!/usr/bin/env python3
"""Reproduce four original local celebration cues; no samples or external tools."""
from pathlib import Path
import math
import struct
import wave

DESTINATION = Path(__file__).resolve().parents[1] / "App/Audio"
RATE = 44100


def render(name, notes, duration=0.74):
    samples = []
    for index in range(int(RATE * duration)):
        time = index / RATE
        # A short, low contact gives the bright resolution some physical weight.
        contact = 0.4 * math.sin(2 * math.pi * (170 * time - 55 * time * time)) * math.exp(-time * 44)
        value = contact
        for onset, frequency, amplitude in notes:
            age = time - onset
            if age < 0:
                continue
            envelope = min(1, age / 0.003) * math.exp(-age * 11)
            tone = math.sin(2 * math.pi * frequency * age)
            tone += 0.18 * math.sin(2 * math.pi * frequency * 2.01 * age) * math.exp(-age * 18)
            value += amplitude * envelope * tone
        value *= min(1, (duration - time) / 0.035)
        samples.append(max(-32767, min(32767, round(value * 24000))))
    with wave.open(str(DESTINATION / name), "wb") as output:
        output.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        output.writeframes(struct.pack("<" + "h" * len(samples), *samples))


if __name__ == "__main__":
    render("sf_brilliant.wav", [(0, 523.25, 0.28), (0.075, 783.99, 0.24), (0.18, 1046.5, 0.22)])
    render("sf_constellation.wav", [(0, 523.25, 0.3), (0.06, 659.25, 0.23),
                                    (0.13, 783.99, 0.25), (0.27, 1046.5, 0.28), (0.27, 1318.51, 0.08)])

    # A compact paired chord marks an exact shape; a two-part rising answer marks a relay.
    render("sf_recipe.wav", [(0, 659.25, 0.24), (0, 987.77, 0.12),
                             (0.10, 783.99, 0.22), (0.10, 1174.66, 0.10)], duration=0.42)
    render("sf_relay.wav", [(0, 523.25, 0.22), (0.045, 659.25, 0.20),
                            (0.18, 783.99, 0.22), (0.225, 1046.5, 0.20),
                            (0.225, 1318.51, 0.06)], duration=0.54)
