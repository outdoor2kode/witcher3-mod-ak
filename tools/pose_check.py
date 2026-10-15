"""解析 editor.log 的 [Script_GFG] pose 紀錄（gfg_ak47.ws 的 GfgLogHoldPose），檢查雙手持槍第 1 步。

用法：python -X utf8 pose_check.py editor.log [最後幾筆=20]
- 右手掌心 = r_hand + 0.061·x + 0.032·y − 0.002·z（docs/handoff.md「偵測紀錄的讀法」）
- 握把在 l_weapon（= AK 本身）座標 (−0.3032, −0.0115, −0.2320)、槍管 (0.8033, 0.2140, 0.5558)（docs/m3.md 第 1 步）
"""
import math
import re
import sys

GRIP = (-0.3032, -0.0115, -0.2320)
BARREL = (0.8033, 0.2140, 0.5558)
PALM = (0.061, 0.032, -0.002)

line_re = re.compile(r'\[\d{4}\.\d\d\.\d\d (\d\d:\d\d:\d\d)\]\[Info\]\[Script_GFG\] pose (.*)$')


def sub(a, b): return tuple(x - y for x, y in zip(a, b))
def add(a, b): return tuple(x + y for x, y in zip(a, b))
def mul(a, s): return tuple(x * s for x in a)
def dot(a, b): return sum(x * y for x, y in zip(a, b))
def norm(a): return math.sqrt(dot(a, a))


def to_local(frame, p):
    o, ax = frame
    d = sub(p, o)
    return tuple(dot(d, a) for a in ax)


def to_world_dir(frame, v):
    _, ax = frame
    return add(add(mul(ax[0], v[0]), mul(ax[1], v[1])), mul(ax[2], v[2]))


def parse(path):
    recs, cur = [], None
    with open(path, 'rb') as f:
        for raw in f:
            m = line_re.search(raw.decode('utf-8', 'replace').rstrip())
            if not m:
                continue
            clock, body = m.groups()
            if body.startswith('t='):
                cur = {'clock': clock, 'head': body}
                recs.append(cur)
                continue
            if cur is None:
                continue
            parts = body.split()
            if parts[0] == 'camera':
                nums = [float(x) for x in parts[2:5]] + [float(x) for x in parts[7:10]]
                cur['eye'], cur['dir'] = tuple(nums[:3]), tuple(nums[3:])
            else:
                v = [float(x) for x in parts[2:6]] + [float(x) for x in parts[7:11]] + [float(x) for x in parts[12:16]] + [float(x) for x in parts[17:21]]
                cur[parts[0]] = (tuple(v[0:3]), (tuple(v[4:7]), tuple(v[8:11]), tuple(v[12:15])))
    return [r for r in recs if 'ak_handle' in r and 'dir' in r]


def main():
    recs = parse(sys.argv[1])
    n = int(sys.argv[2]) if len(sys.argv) > 2 else 20
    print(f'完整紀錄 {len(recs)} 筆；最後 {n} 筆：')
    print('時間     狀態                         鏡頭俯仰  掌心-握把(公分, l_weapon 座標)        距離  槍管-鏡頭  r_hand(玩家座標)          l_weapon(玩家座標)')
    for r in recs[-n:]:
        lw = r['l_weapon']
        rh = r['r_hand']
        palm = add(add(add(rh[0], mul(rh[1][0], PALM[0])), mul(rh[1][1], PALM[1])), mul(rh[1][2], PALM[2]))
        d = sub(to_local(lw, palm), GRIP)
        barrel = to_world_dir(r['ak'], BARREL)
        cam = r['dir']
        ang = math.degrees(math.acos(max(-1, min(1, dot(barrel, cam) / norm(barrel) / norm(cam)))))
        pitch = math.degrees(math.asin(cam[2] / norm(cam)))
        pl = r['player']
        state = re.sub(r'^t=\S+ ', '', r['head']).replace('player=', '').replace(' ak=', '/')
        rh_p = to_local(pl, rh[0])
        lw_p = to_local(pl, lw[0])
        print(f"{r['clock']} {state:28s} {pitch:6.1f}°  ({d[0]*100:5.1f}, {d[1]*100:5.1f}, {d[2]*100:5.1f})  {norm(d)*100:5.1f}  {ang:6.1f}°  "
              f"({rh_p[0]:.3f}, {rh_p[1]:.3f}, {rh_p[2]:.3f})  ({lw_p[0]:.3f}, {lw_p[1]:.3f}, {lw_p[2]:.3f})")


main()
