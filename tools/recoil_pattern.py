"""把 AK-47 的後座力資料換算成角度，輸出每一發落點與每發的後座（不進遊戲）。

用法：
    python -X utf8 tools/recoil_pattern.py [--compare 參考CSV] [--svg 輸出.svg] [--ascii]

- 資料：data/recoil/ak47_artanis-rcs.csv（來源、授權、換算依據見 data/recoil/README.md）
- 每一列是「開完一槍後把準心拉回去的滑鼠位移」→ 落點 = 位移累加後取負號
  - 第 k 發落點 = -(第 0～k 列的位移總和)，第 0 發在原點（與 CSGODOT 的換算方式相同）
- 一個單位 = 2.45 × 0.022°（Artanis-RCS 的倍率 × CS2 的 m_yaw／m_pitch）
- 座標：x 往右為正、y 往上為正，單位度
- --compare：和另一份 `shot,x_degrees,y_degrees` 格式的彈道比對（例：CSGODOT 的 ak47.csv），
  算出最合適的縮放倍率與均方根誤差（# 開頭的行會略過）
- --svg：輸出彈道圖；--ascii：在終端機畫粗略的彈道圖
- --ws：印出 WitcherScript 的位移表（GfgRecoilKickRight／GfgRecoilKickUp），貼進 workspace/scripts/local/gfg_recoil.ws
"""
import argparse
import math
import sys
from pathlib import Path

PROJECT_DIR = Path(__file__).resolve().parent.parent
DEFAULT_DATA = PROJECT_DIR / 'data' / 'recoil' / 'ak47_artanis-rcs.csv'

RCS_COUNTS_PER_UNIT = 2.45   # Artanis-RCS data/config_repository.py:195（再除以遊戲靈敏度）
CS2_DEGREES_PER_COUNT = 0.022  # CS2 convars.txt:4681 m_pitch、:4684 m_yaw（再乘以遊戲靈敏度）
DEGREES_PER_UNIT = RCS_COUNTS_PER_UNIT * CS2_DEGREES_PER_COUNT


def load_rcs_rows(path: Path) -> list[tuple[float, float, float]]:
    rows = []
    for line in path.read_text(encoding='utf-8-sig').splitlines():
        parts = line.strip().split(',')
        if len(parts) >= 3:
            rows.append((float(parts[0]), float(parts[1]), float(parts[2])))
    return rows


def pattern_from_rcs(rows: list[tuple[float, float, float]]) -> list[tuple[float, float]]:
    # 補償往右（dx > 0）＝彈道往左；送出的垂直位移是 -dy（recoil_service.py:374），往下補償＝彈道往上
    x = y = 0.0
    points = []
    for dx, dy, _delay in rows:
        x -= dx * DEGREES_PER_UNIT
        y -= dy * DEGREES_PER_UNIT
        points.append((x, y))
    return points


def load_reference(path: Path) -> list[tuple[float, float]]:
    points = []
    for line in path.read_text(encoding='utf-8-sig').splitlines():
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        parts = line.split(',')
        points.append((float(parts[1]), float(parts[2])))
    return points


def rms_error(ours: list[tuple[float, float]], ref: list[tuple[float, float]], s: float) -> float:
    # ours 乘上 s 之後，和 ref 逐發的均方根距離（度）
    n = min(len(ours), len(ref))
    sq = sum((s * ours[i][0] - ref[i][0]) ** 2 + (s * ours[i][1] - ref[i][1]) ** 2 for i in range(n))
    return math.sqrt(sq / n)


def best_fit_scale(ours: list[tuple[float, float]], ref: list[tuple[float, float]]) -> float:
    # 最小平方法：找 s 使 Σ|s·ours − ref|² 最小
    n = min(len(ours), len(ref))
    dot = sum(ours[i][0] * ref[i][0] + ours[i][1] * ref[i][1] for i in range(n))
    norm = sum(ours[i][0] ** 2 + ours[i][1] ** 2 for i in range(n))
    return dot / norm


def describe_sideways(points: list[tuple[float, float]], threshold: float = 1.5) -> str:
    # 找左右轉折點：從目前方向的最遠點退回超過 threshold 度，才算轉向（忽略較小的來回）
    xs = [p[0] for p in points]
    turns = [0]
    direction = 0
    extreme = 0
    for i in range(1, len(xs)):
        if direction == 0:
            if abs(xs[i] - xs[0]) >= threshold / 3:
                direction = 1 if xs[i] > xs[0] else -1
                extreme = i
        elif (xs[i] - xs[extreme]) * direction >= 0:
            extreme = i
        elif abs(xs[extreme] - xs[i]) >= threshold:
            turns.append(extreme)
            direction = -direction
            extreme = i
    turns.append(len(xs) - 1)
    parts = []
    for a, b in zip(turns, turns[1:]):
        name = '往右' if xs[b] > xs[a] else '往左'
        parts.append(f'第 {a}～{b} 發{name}（x {xs[a]:+.2f}° → {xs[b]:+.2f}°）')
    return '；'.join(parts) + f'（忽略 {threshold}° 以下的來回）'


def ascii_plot(points: list[tuple[float, float]], width: int = 61, height: int = 25) -> str:
    xs = [p[0] for p in points]
    ys = [p[1] for p in points]
    span_x = max(abs(min(xs)), abs(max(xs)))
    top = max(ys)
    grid = [[' '] * width for _ in range(height)]
    for i, (x, y) in enumerate(points):
        col = round((x / span_x) * (width // 2)) + width // 2
        row = height - 1 - round((y / top) * (height - 1))
        grid[row][col] = str(i % 10) if grid[row][col] == ' ' else '*'
    lines = [''.join(r).rstrip() for r in grid]
    return '\n'.join(lines) + f'\n（橫向 ±{span_x:.1f}°、縱向 0～{top:.1f}°，比例不同；數字是發數的個位數，* 是重疊）'


def ws_tables(points: list[tuple[float, float]]) -> str:
    # 第 k 發相對第 k-1 發的位移（度），k 從 1 起算
    out = []
    for name, axis, label in (('GfgRecoilKickRight', 0, '往右'), ('GfgRecoilKickUp', 1, '往上')):
        out += [f'// 第 shot 發相對前一發{label}幾度（shot 從 1 起算，超過資料長度回傳 0）',
                '@addMethod(Crossbow)',
                f'function {name}( shot : int ) : float',
                '{',
                '\tswitch ( shot )',
                '\t{']
        for k in range(1, len(points)):
            out.append(f'\t\tcase {k}: return {points[k][axis] - points[k - 1][axis]:.4f}f;')
        out += ['\t}', '\treturn 0.f;', '}', '']
    return '\n'.join(out)


def write_svg(path: Path, points: list[tuple[float, float]]) -> None:
    scale = 30.0  # 每度 30 像素
    xs = [p[0] for p in points]
    ys = [p[1] for p in points]
    pad = 40
    min_x, max_x = min(xs + [0]), max(xs + [0])
    max_y = max(ys)
    w = (max_x - min_x) * scale + pad * 2
    h = max_y * scale + pad * 2

    def to_px(x: float, y: float) -> tuple[float, float]:
        return pad + (x - min_x) * scale, pad + (max_y - y) * scale

    out = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{w:.0f}" height="{h:.0f}" font-family="sans-serif" font-size="10">',
           f'<rect width="100%" height="100%" fill="white"/>']
    cx, cy = to_px(0, 0)
    out.append(f'<line x1="{cx:.1f}" y1="{pad / 2:.1f}" x2="{cx:.1f}" y2="{h - pad / 2:.1f}" stroke="#ccc"/>')
    path_d = ' '.join(('M' if i == 0 else 'L') + '{:.1f},{:.1f}'.format(*to_px(x, y)) for i, (x, y) in enumerate(points))
    out.append(f'<path d="{path_d}" fill="none" stroke="#999" stroke-width="1"/>')
    for i, (x, y) in enumerate(points):
        px, py = to_px(x, y)
        out.append(f'<circle cx="{px:.1f}" cy="{py:.1f}" r="4" fill="#c33"/>')
        out.append(f'<text x="{px + 6:.1f}" y="{py + 3:.1f}">{i}</text>')
    out.append(f'<text x="{pad / 2:.0f}" y="{h - 8:.0f}">AK-47：x 往右、y 往上，每格 1° = {scale:.0f}px（資料：Artanis-RCS，換算見 data/recoil/README.md）</text>')
    out.append('</svg>')
    path.write_text('\n'.join(out), encoding='utf-8')


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('data', nargs='?', default=str(DEFAULT_DATA))
    parser.add_argument('--compare', help='參考彈道（shot,x_degrees,y_degrees）')
    parser.add_argument('--svg', help='輸出彈道圖的路徑')
    parser.add_argument('--ascii', action='store_true', help='在終端機畫彈道圖')
    parser.add_argument('--ws', action='store_true', help='只印出 WitcherScript 的位移表')
    args = parser.parse_args()

    rows = load_rcs_rows(Path(args.data))
    points = pattern_from_rcs(rows)
    if args.ws:
        print(ws_tables(points))
        return 0
    print(f'資料：{args.data}（{len(rows)} 列 → {len(points)} 發），一個單位 = {DEGREES_PER_UNIT:.4f}°')
    print(f'{"發":>3} {"x°":>8} {"y°":>8} {"這發的後座 x°":>12} {"y°":>8}')
    for i, (x, y) in enumerate(points):
        kx = x - points[i - 1][0] if i else 0.0
        ky = y - points[i - 1][1] if i else 0.0
        print(f'{i:>3} {x:>8.3f} {y:>8.3f} {kx:>12.3f} {ky:>8.3f}')

    top = max(range(len(points)), key=lambda i: points[i][1])
    print(f'最高點：第 {top} 發，往上 {points[top][1]:.2f}°')
    print(f'左右範圍：{min(p[0] for p in points):+.2f}° ～ {max(p[0] for p in points):+.2f}°')
    print('左右形狀：' + describe_sideways(points))

    if args.compare:
        ref = load_reference(Path(args.compare))
        s = best_fit_scale(points, ref)
        print(f'比對 {args.compare}（{len(ref)} 發）：最合適縮放 {s:.4f}，'
              f'縮放後均方根誤差 {rms_error(points, ref, s):.3f}°（不縮放 {rms_error(points, ref, 1.0):.3f}°）')

    if args.ascii:
        print(ascii_plot(points))

    if args.svg:
        write_svg(Path(args.svg), points)
        print(f'已輸出：{args.svg}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
