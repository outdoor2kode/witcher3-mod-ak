"""錄電腦正在播的聲音（WASAPI loopback），檢查遊戲裡有沒有播出聲音（Claude 聽不到；第 22 項，2026-10-18）

用法：
    python -X utf8 tools/audio_rec.py rec <秒數> <輸出.wav> [準備好時建立的檔案]
    python -X utf8 tools/audio_rec.py tones <錄音.wav>
    python -X utf8 tools/audio_rec.py onsets <錄音.wav> <原始檔.wav>...

- rec：錄預設喇叭的輸出（48 kHz 立體聲）；開始錄之後才建立「準備好」的檔案 → 呼叫的人等這個檔出現再操作遊戲
  （Python 載入要 1 秒左右；不等的話會漏掉開頭）
- tones：每 50 毫秒的主要頻率（300～5000 Hz），印出單一頻率佔大部分能量的時段 → 用測試音確認媒體有播、音高對
- onsets：用原始檔開頭 30 毫秒（多個就平均）找出每一發的起點、間隔，印出 100 毫秒音量的最大值
- 需要 tools/_vendor/pylib314（soundcard 0.4.6、numpy：pip install --target tools/_vendor/pylib314 soundcard）

2026-10-18 實測（findings.md §33.5）：遊戲暫停（例：拍照模式）時錄到的是全 0
"""
import os
import sys
import wave

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '_vendor', 'pylib314'))
import numpy as np  # noqa: E402

RATE = 48000


def load(path):
    """讀 16 位元 WAV、換成 48 kHz；回傳（樣本數 × 聲道）"""
    with wave.open(path, 'rb') as w:
        ch, sr, n = w.getnchannels(), w.getframerate(), w.getnframes()
        a = np.frombuffer(w.readframes(n), '<i2').astype(np.float64).reshape(-1, ch) / 32768
    if sr != RATE:
        t = np.arange(int(len(a) * RATE / sr)) / RATE
        a = np.stack([np.interp(t, np.arange(len(a)) / sr, a[:, c]) for c in range(ch)], axis=1)
    return a


def ncc(sig, tpl):
    """正規化相關（FFT）：sig 每個位置和 tpl 的相關係數"""
    n = len(sig) + len(tpl)
    size = 1 << (n - 1).bit_length()
    c = np.fft.irfft(np.fft.rfft(sig, size) * np.conj(np.fft.rfft(tpl, size)), size)[:len(sig) - len(tpl) + 1]
    cs = np.concatenate([[0], np.cumsum(sig ** 2)])
    e = np.sqrt(np.maximum(cs[len(tpl):] - cs[:-len(tpl)], 0))
    return c / (e * np.linalg.norm(tpl) + 1e-12)


def rec(sec, out, ready=None):
    import soundcard as sc
    spk = sc.default_speaker()
    mic = sc.get_microphone(id=str(spk.name), include_loopback=True)
    with mic.recorder(samplerate=RATE, channels=2) as r:
        r.record(numframes=480)
        if ready:
            open(ready, 'w').close()
        data = r.record(numframes=int(RATE * sec))
    with wave.open(out, 'wb') as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes((np.clip(data, -1, 1) * 32767).astype('<i2').tobytes())
    print(f'{spk.name}：峰值 {np.abs(data).max():.3f}、RMS {np.sqrt((data ** 2).mean()):.4f} → {out}')


def tones(path):
    m = load(path).mean(axis=1)
    win = int(RATE * 0.05)
    f = np.fft.rfftfreq(8 * win, 1 / RATE)
    band = (f > 300) & (f < 5000)
    for i in range(0, len(m) - win, win):
        x = np.abs(np.fft.rfft(m[i:i + win] * np.hanning(win), 8 * win)) * band
        k = int(np.argmax(x))
        share = (x[max(k - 8, 0):k + 9] ** 2).sum() / ((x ** 2).sum() + 1e-12)
        lvl = 20 * np.log10(np.sqrt((m[i:i + win] ** 2).mean()) + 1e-9)
        if share > 0.5 and lvl > -45:
            print(f'{i / RATE:5.2f} 秒  {f[k]:7.1f} Hz  {lvl:6.1f} dBFS  佔 {share:.2f}')


def onsets(path, sources):
    r = load(path).mean(axis=1)
    tpl = np.mean([load(s).mean(axis=1)[:int(0.03 * RATE)] for s in sources], axis=0)
    c = ncc(r, tpl)
    peaks = []
    for i in np.argsort(-c):
        if c[i] < 0.42:
            break
        if all(abs(i - p) > 0.06 * RATE for p in peaks):
            peaks.append(i)
    t = sorted(p / RATE for p in peaks)
    print('起點（秒）：', ' '.join(f'{x:.2f}' for x in t))
    print('間隔（秒）：', ' '.join(f'{b - a:.3f}' for a, b in zip(t, t[1:])))
    e = np.sqrt(np.convolve(r ** 2, np.ones(RATE // 10) / (RATE // 10), 'valid'))
    print(f'100 毫秒音量最大 {20 * np.log10(e.max()):.1f} dBFS、峰值 {np.abs(load(path)).max():.3f}')


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else ''
    if cmd == 'rec':
        rec(float(sys.argv[2]), sys.argv[3], sys.argv[4] if len(sys.argv) > 4 else None)
    elif cmd == 'tones':
        tones(sys.argv[2])
    elif cmd == 'onsets':
        onsets(sys.argv[2], sys.argv[3:])
    else:
        raise SystemExit(__doc__)


if __name__ == '__main__':
    main()
