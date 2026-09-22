#!/usr/bin/env python3
"""合成鹈鹕监工的音效（纯标准库，无依赖）。
用法: python3 make_sounds.py <输出目录>
产物: 6 个 22050Hz 单声道 16-bit WAV。
"""
import math
import os
import struct
import sys
import wave

SR = 22050
OUT = sys.argv[1] if len(sys.argv) > 1 else "."
os.makedirs(OUT, exist_ok=True)


def env(t, d, a=0.004, r=0.06):
    if t < a:
        return t / a
    if t > d - r:
        return max(0.0, (d - t) / r)
    return 1.0


def tone(f0, d, v=0.5, f1=None, shape="sine"):
    n = int(SR * d)
    out = []
    ph = 0.0
    for i in range(n):
        t = i / SR
        f = f0 + (f1 - f0) * (i / n) if f1 is not None else f0
        ph += 2 * math.pi * f / SR
        if shape == "tri":
            s = 2.0 / math.pi * math.asin(math.sin(ph))
        else:
            s = math.sin(ph)
        out.append(s * v * env(t, d))
    return out


def delay(samples, secs):
    return [0.0] * int(SR * secs) + samples


def mix(*parts):
    n = max(len(p) for p in parts)
    acc = [0.0] * n
    for p in parts:
        for i, x in enumerate(p):
            acc[i] += x
    return acc


def buzz(d=0.42, f=110.0):
    n = int(SR * d)
    out = []
    for i in range(n):
        t = i / SR
        sq = 1.0 if math.sin(2 * math.pi * f * t) >= 0 else -1.0
        vib = 0.55 + 0.45 * math.sin(2 * math.pi * 30 * t)
        out.append(sq * 0.22 * vib * env(t, d, a=0.005, r=0.09))
    return out


def thud():
    n = int(SR * 0.5)
    out = []
    for i in range(n):
        t = i / SR
        f = 75 + 50 * math.exp(-t * 18)
        s = math.sin(2 * math.pi * f * t) * 0.75 + math.sin(2 * math.pi * 45 * t) * 0.35
        out.append(s * math.exp(-t * 10))
    return out


def bell(f, d=0.9, v=0.5):
    n = int(SR * d)
    out = []
    for i in range(n):
        t = i / SR
        s = (math.sin(2 * math.pi * f * t)
             + 0.35 * math.sin(2 * math.pi * f * 2.76 * t)
             + 0.12 * math.sin(2 * math.pi * f * 5.4 * t))
        out.append(s * v * math.exp(-t * 4.2))
    return out


def normalize(samples, peak=0.95):
    m = max(1e-9, max(abs(x) for x in samples))
    k = peak / m
    return [x * k for x in samples]


def write(name, samples):
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, x)) * 32767)) for x in samples))
    print("wrote", path)


# 1. 起来休息：欢快的上行三连音
write("s_break_start", normalize(
    mix(tone(660, .10, .38), delay(tone(880, .10, .40), .08), delay(tone(1175, .18, .44), .16))))

# 2. 被抓包：嗡嗡警报
write("s_caught", normalize(mix(buzz(.42, 110), buzz(.42, 165), tone(55, .42, .18))))

# 3. 进入生病：哇-哇下滑
write("s_sick", normalize(
    mix(tone(392, .26, .42, f1=365, shape="tri"), delay(tone(311, .38, .42, f1=285, shape="tri"), .28))))

# 4. 卧床：闷响
write("s_bed", normalize(thud()))

# 5. 回满/高兴：叮
write("s_ding", normalize(bell(1318, 1.0, .5)))

# 6. 免费住院：叮-咚
write("s_hospital", normalize(mix(bell(987, .8, .5), delay(bell(659, 1.0, .5), .3))))

print("all sounds done ->", OUT)
