"""做槍聲的 SoundBank：CS2 的 WAV → Wwise 的 PCM WEM → <name>.bnk（不用 Wwise；第 22 項，2026-10-18；M4 第 49 項，10-20）

用法：
    python -X utf8 tools/ak_soundbank.py --template <combat.bnk> --out <gfg_ak47.bnk>
        [--name gfg_ak47] [--volume 0] [--pitch 1.0] [--limit 1] [--check <bank 資料夾>] <WAV>...

    例（<REDKIT_DEPOT> = REDkit 的 r4data）：
    python -X utf8 tools/ak_soundbank.py --template "<REDKIT_DEPOT>/soundbanks/Pc/combat.bnk"
        --out workspace/soundbanks/pc/gfg_ak47.bnk --check "<REDKIT_DEPOT>/soundbanks/Pc"
        assets/ak47/sound/ak47_01.wav assets/ak47/sound/ak47_02.wav assets/ak47/sound/ak47_04.wav
    M4：--name gfg_m4a1 --volume -3.8 --pitch 1.1 … assets/m4a1/sound/m4a1_01.wav … m4a1_04.wav
    （CS2 的 Weapon_M4A1.Single：volume 1.0、pitch 1.1；AK 的 Weapon_AK47.Single：volume 1.1 → M4 比 AK 小 0.83 dB）

做出來的 bank（Wwise bank 第 150 版，同遊戲的 combat.bnk）：
- 事件 <name>_shot → 播放 → 隨機容器（不連續播同一個；同時最多 --limit 個，新的蓋掉舊的）→ 每個 WAV 一個 Sound
- 隨機容器掛在原版十字弩射擊的上一層（combat.bnk 的 actor-mixer 850914486）：匯流排、3D 定位跟著十字弩
- Sound 用 PCM（plugin 0x00010001），媒體放在 bank 裡（DIDX、DATA）
- 遊戲裡：腳本 theSound.SoundLoadBank( "<name>.bnk", true ) 載入（sound.ws:88），SoundEvent( "<name>_shot" ) 播放
- --pitch：CS2 sound event 的 pitch（播放速度的倍率：音高、長度一起變）→ WAV 先重新取樣（窗函數 sinc，±16 點、Hann；
  倍率 > 1 時截止頻率跟著降，避免疊頻）；1.0 不動 WAV（AK 的 bank 和以前位元組相同）

格式的出處：
- 物件的欄位、位置：wwiser（bnnm/wwiser v20260808）解析 combat.bnk 的結果；寫入前先檢查範本的值
- WEM：RIFF 'WAVE'；fmt 0x18 bytes：格式 0xFFFE（vgmstream wwise.c：「PCM for Wwise Authoring」）、cbSize 6、
  第 0x14 byte 是聲道設定（聲道數 | 類型 << 8 | 遮罩 << 12：vgmstream wwise.c；遊戲的立體聲 WEM 都是 0x3102）；
  接 hash（16 bytes）、junk（讓樣本從第 96 byte 開始），同遊戲 fx_haptic.bnk 的 WEM（fmt 0x18、hash、junk 12、data）
- ID：Wwise 的 FNV-1 32 位元（小寫名稱）；用 combat 的 bank ID 2764240573 驗證過
"""
import argparse
import hashlib
import os
import struct
import wave

TEMPLATE_SOUND = 540419932      # weapon_crossbow_shot_01（combat.bnk）
TEMPLATE_CNTR = 615266803       # 隨機容器 weapon_crossbow_shot
TEMPLATE_ACTION = 918883412     # 事件 weapon_crossbow_shot 的播放動作
CROSSBOW_MIXER = 850914486      # 十字弩的 actor-mixer（隨機容器的上一層）
PLUGIN_VORBIS = 0x00040001
PLUGIN_PCM = 0x00010001


def fnv(name):
    h = 2166136261
    for c in name.lower().encode():
        h = (h * 16777619) & 0xffffffff
        h ^= c
    return h


def chunks(b):
    """bank 的區塊：{名稱: (資料位置, 大小)}"""
    out = {}
    p = 0
    while p < len(b):
        size = struct.unpack_from('<I', b, p + 4)[0]
        out[b[p:p + 4].decode()] = (p + 8, size)
        p += 8 + size
    return out


def hirc_objects(b, hirc):
    """HIRC 的物件：{(類型, ID): 物件的 bytes（含類型、大小）}"""
    off, size = hirc
    count = struct.unpack_from('<I', b, off)[0]
    p = off + 4
    objs = {}
    for _ in range(count):
        t, sz, oid = struct.unpack_from('<BII', b, p)
        objs[(t, oid)] = b[p:p + 5 + sz]
        p += 5 + sz
    if p != off + size:
        raise SystemExit('HIRC 的物件沒有剛好到區塊結尾')
    return objs


def expect(buf, off, fmt, value, what):
    got = struct.unpack_from(fmt, buf, off)[0]
    if got != value:
        raise SystemExit(f'範本不符：{what} 是 {got}，預期 {value}')


def resample(data, ch, mult):
    """16 位元 PCM 照播放速度倍率 mult 重新取樣（輸出長度 = 輸入 / mult）：窗函數 sinc（±16 點、Hann）"""
    import sys
    sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '_vendor', 'pylib314'))
    import numpy as np
    x = np.frombuffer(data, '<i2').astype(np.float64).reshape(-1, ch)
    n = len(x)
    m = int(round(n / mult))
    t = np.arange(m) * mult           # 每個輸出樣本在輸入的位置
    fc = min(1.0, 1.0 / mult)         # 截止頻率（相對奈奎斯特）
    half = 16
    i0 = np.floor(t).astype(np.int64)
    out = np.zeros((m, ch))
    for k in range(-half + 1, half + 1):
        idx = i0 + k
        d = t - idx
        w = fc * np.sinc(fc * d) * (0.5 + 0.5 * np.cos(np.pi * d / half))
        ok = (idx >= 0) & (idx < n)
        out[ok] += x[idx[ok]] * w[ok][:, None]
    clipped = int(np.sum(np.abs(out) > 32767))
    return np.clip(np.round(out), -32768, 32767).astype('<i2').tobytes(), m, clipped


def make_wem(path, pitch=1.0):
    with wave.open(path, 'rb') as w:
        ch, width, rate, n = w.getnchannels(), w.getsampwidth(), w.getframerate(), w.getnframes()
        data = w.readframes(n)
    if width != 2 or ch not in (1, 2):
        raise SystemExit(f'{path}：只收 16 位元的單聲道、立體聲（這個是 {width * 8} 位元 {ch} 聲道）')
    if pitch != 1.0:
        data, n, clipped = resample(data, ch, pitch)
        print(f'  pitch {pitch}：重新取樣成 {n} 個樣本（{n / rate:.3f} 秒），超出範圍被截掉 {clipped} 個')
    chcfg = {1: 0x4101, 2: 0x3102}[ch]  # 遮罩：單聲道 0x4（中央）、立體聲 0x3（左右）；類型 1 = 標準
    fmt = struct.pack('<HHIIHHHHI', 0xFFFE, ch, rate, rate * ch * 2, ch * 2, 16, 6, 0, chcfg)
    body = b'fmt ' + struct.pack('<I', len(fmt)) + fmt
    body += b'hash' + struct.pack('<I', 16) + hashlib.md5(data).digest()
    body += b'junk' + struct.pack('<I', 12) + bytes(12)
    body += b'data' + struct.pack('<I', len(data)) + data
    wem = b'RIFF' + struct.pack('<I', 4 + len(body)) + b'WAVE' + body
    assert wem.index(b'data') + 8 == 96
    return wem, ch, rate, n


def bank_ids(folder):
    """資料夾裡所有 bank 的 ID：bank、HIRC 物件、內嵌媒體；加上 Media 資料夾的串流 WEM"""
    banks, objs, media = set(), set(), set()
    for name in os.listdir(folder):
        if not name.lower().endswith('.bnk'):
            continue
        b = open(os.path.join(folder, name), 'rb').read()
        c = chunks(b)
        if 'BKHD' in c:
            banks.add(struct.unpack_from('<I', b, c['BKHD'][0] + 4)[0])
        if 'DIDX' in c:
            off, size = c['DIDX']
            media.update(struct.unpack_from('<I', b, off + i)[0] for i in range(0, size, 12))
        if 'HIRC' in c:
            objs.update(oid for _, oid in hirc_objects(b, c['HIRC']))
    mdir = os.path.join(folder, 'Media')
    if os.path.isdir(mdir):
        media.update(int(n[:-4]) for n in os.listdir(mdir) if n.endswith('.wem') and n[:-4].isdigit())
    return banks, objs, media


def main():
    ap = argparse.ArgumentParser(description='做槍聲的 SoundBank（<name>.bnk）')
    ap.add_argument('wavs', nargs='+')
    ap.add_argument('--template', required=True, help='combat.bnk（只讀）')
    ap.add_argument('--out', required=True)
    ap.add_argument('--name', default='gfg_ak47', help='bank 名稱（檔名不含 .bnk）；事件是 <name>_shot（預設 gfg_ak47）')
    ap.add_argument('--volume', type=float, default=0.0, help='隨機容器的音量（dB；十字弩的是 -3）')
    ap.add_argument('--pitch', type=float, default=1.0, help='播放速度倍率（CS2 sound event 的 pitch；預設 1.0 = 不變）')
    ap.add_argument('--limit', type=int, default=1, help='同時最多幾個（CS2 的 instance_limit 是 1）；0 = 不限')
    ap.add_argument('--check', help='bank 資料夾：檢查新的 ID 有沒有和這裡的 bank 撞到')
    args = ap.parse_args()

    tb = open(args.template, 'rb').read()
    tc = chunks(tb)
    expect(tb, tc['BKHD'][0], '<I', 150, 'bank 版本')
    objs = hirc_objects(tb, tc['HIRC'])
    snd = objs[(2, TEMPLATE_SOUND)]
    cntr = objs[(5, TEMPLATE_CNTR)]
    act = objs[(3, TEMPLATE_ACTION)]
    # 範本的欄位（位置照 wwiser 的解析）
    expect(snd, 1, '<I', 49, 'Sound 的大小')
    expect(snd, 9, '<I', PLUGIN_VORBIS, 'Sound 的 plugin')
    expect(snd, 13, '<B', 0, 'Sound 的 StreamType（0 = 媒體在 bank 裡）')
    expect(snd, 31, '<I', TEMPLATE_CNTR, 'Sound 的上一層')
    expect(cntr, 17, '<I', CROSSBOW_MIXER, '容器的上一層')
    expect(cntr, 22, '<B', 1, '容器的屬性數')
    expect(cntr, 23, '<B', 0, '容器的屬性（0 = Volume）')
    expect(cntr, 35, '<B', 0, '容器的 AdvSettings 位元')
    expect(cntr, 37, '<H', 0, '容器的 MaxNumInstance')
    expect(cntr, 63, '<H', 3, '容器的 AvoidRepeatCount')
    expect(cntr, 69, '<I', 5, '容器的子物件數')
    expect(cntr, 93, '<H', 5, '容器的播放清單數')
    if len(cntr) != 135:
        raise SystemExit(f'範本不符：容器 {len(cntr)} bytes，預期 135')
    expect(act, 9, '<H', 0x0403, '動作類型（Play）')
    expect(act, 11, '<I', TEMPLATE_CNTR, '動作的目標')
    expect(act, 19, '<I', fnv('combat'), '動作的 bank ID')

    name = args.name
    bank_id = fnv(name)
    event_id = fnv(f'{name}_shot')
    action_id = fnv(f'{name}_shot_play')
    cntr_id = fnv(f'{name}_shot_random')
    sounds = []  # (Sound ID, 媒體 ID, WEM)
    for i, path in enumerate(args.wavs, 1):
        wem, ch, rate, n = make_wem(path, args.pitch)
        sounds.append((fnv(f'{name}_shot_sound_{i:02d}'), fnv(f'{name}_shot_media_{i:02d}'), wem))
        print(f'{os.path.basename(path)}：{ch} 聲道 {rate} Hz {n / rate:.3f} 秒 → WEM {len(wem)} bytes')

    if args.check:
        banks, used, media = bank_ids(args.check)
        clash = [x for x in [bank_id] if x in banks]
        clash += [x for x in [event_id, action_id, cntr_id] + [s[0] for s in sounds] if x in used]
        clash += [s[1] for s in sounds if s[1] in media]
        if clash:
            raise SystemExit(f'ID 和 {args.check} 的 bank 撞到：{clash}')
        print(f'ID 檢查：沒撞到（{len(banks)} 個 bank、{len(used)} 個物件、{len(media)} 個媒體）')

    hirc = []
    for sid, mid, wem in sounds:
        o = bytearray(snd)
        struct.pack_into('<I', o, 5, sid)
        struct.pack_into('<I', o, 9, PLUGIN_PCM)
        struct.pack_into('<I', o, 14, mid)
        struct.pack_into('<I', o, 18, len(wem))
        struct.pack_into('<I', o, 31, cntr_id)
        hirc.append(bytes(o))
    # 隨機容器：前 69 bytes 照十字弩的（改 ID、音量、同時數、不重複數），後面換成我們的子物件、播放清單
    c = bytearray(cntr[:69])
    struct.pack_into('<I', c, 5, cntr_id)
    struct.pack_into('<f', c, 24, args.volume)
    if args.limit > 0:
        c[35] |= 0x08  # bIgnoreParentMaxNumInst：用自己的同時數；bKillNewest 0 = 蓋掉舊的
        struct.pack_into('<H', c, 37, args.limit)
    struct.pack_into('<H', c, 63, min(1, len(sounds) - 1))  # 不連續播同一個
    ids = sorted(s[0] for s in sounds)  # 子物件照 ID 由小到大（同 combat.bnk）
    c += struct.pack('<I', len(ids)) + b''.join(struct.pack('<I', x) for x in ids)
    c += struct.pack('<H', len(sounds)) + b''.join(struct.pack('<Ii', s[0], 50000) for s in sounds)
    struct.pack_into('<I', c, 1, len(c) - 5)
    hirc.append(bytes(c))
    a = bytearray(act)
    struct.pack_into('<I', a, 5, action_id)
    struct.pack_into('<I', a, 11, cntr_id)
    struct.pack_into('<I', a, 19, bank_id)
    hirc.append(bytes(a))
    # 事件：1 個動作（動作數是可變長度整數，小於 128 就是 1 byte，同 combat.bnk 的事件）
    ev = struct.pack('<IBI', event_id, 1, action_id)
    hirc.append(struct.pack('<BI', 4, len(ev)) + ev)
    hirc_body = struct.pack('<I', len(hirc)) + b''.join(hirc)

    # 媒體：DIDX 照媒體 ID 由小到大（同 combat.bnk）；每個從 16 的倍數開始（bank 的 uAlignment 16）
    data = bytearray()
    didx = bytearray()
    for mid, wem in sorted((s[1], s[2]) for s in sounds):
        data += bytes(-len(data) % 16)
        didx += struct.pack('<III', mid, len(data), len(wem))
        data += wem

    # 檔頭：照 combat.bnk（版本、語言、對齊、專案），換 bank ID、hash；補 0 讓 DATA 從 16 的倍數開始（同 combat.bnk）
    head = bytearray(tb[tc['BKHD'][0]:tc['BKHD'][0] + 40])
    struct.pack_into('<I', head, 4, bank_id)
    head[24:40] = hashlib.md5(bytes(didx) + bytes(data) + hirc_body).digest()
    head += bytes(-(8 + len(head) + 8 + len(didx) + 8) % 16)

    out = b'BKHD' + struct.pack('<I', len(head)) + head
    out += b'DIDX' + struct.pack('<I', len(didx)) + didx
    assert (len(out) + 8) % 16 == 0
    out += b'DATA' + struct.pack('<I', len(data)) + data
    out += b'HIRC' + struct.pack('<I', len(hirc_body)) + hirc_body

    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    with open(args.out, 'wb') as f:
        f.write(out)
    print(f'寫入 {args.out}（{len(out)} bytes）：bank {bank_id}、事件 {name}_shot {event_id}、'
          f'{len(sounds)} 個聲音、音量 {args.volume} dB、pitch {args.pitch}、同時最多 {args.limit or "不限"}')


if __name__ == '__main__':
    main()
