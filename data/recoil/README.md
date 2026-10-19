# 後座力彈道資料

## `ak47_artanis-rcs.csv`

- 來源：Artanis-RCS（https://github.com/ArtanisInc/Artanis-RCS）的 `patterns/ak47.csv`
  - 這個檔案最後一次修改：commit `f050b44`（2025-06-09，Initial upload）
  - 下載時的 `main`：commit `7387d39`（2026-04-30）
  - 2026-10-13 下載，內容逐位元組相同（含 UTF-8 BOM）
- 這是 CS2 的「壓槍輔助工具」：每一列是「開完一槍後，把準心拉回去的滑鼠位移」
  - 格式：`dx,dy,延遲毫秒`，共 30 列
  - 第 1 列 `0,0,30` 是開火前的等待，不移動
- 換算成角度（依 Artanis-RCS 的程式）：
  - 讀檔：`滑鼠計數 = CSV 值 × 2.45 ÷ 遊戲靈敏度`（`data/config_repository.py:195、253-261`）
  - 送出：水平 `+dx`、垂直 `-dy`（`core/services/recoil_service.py:364-386`，Windows `SendInput`：x 往右、y 往下為正）
  - CS2 每個滑鼠計數轉 `靈敏度 × 0.022°`（GameTracking-CS2 `DumpSource2/convars.txt:4681` `m_pitch 0.022`、`:4684` `m_yaw 0.022`）
  - → **CSV 一個單位 = 2.45 × 0.022 = 0.0539°**，靈敏度互相抵消
- 方向：補償往右（`dx > 0`）表示彈道往左；補償往下（`dy < 0`）表示彈道往上
- 可信度：
  - 數據怎麼取得的，Artanis-RCS 沒有說明
  - CSGODOT（https://github.com/sidcarrollworks/CSGODOT ，`reference/spray_patterns/README.md`）把它和從 CS2 彈道圖讀出的 AK 比對：形狀幾乎重合
  - 整體大小沒有被實測確認：照工具的換算往上爬約 11.7°；CSGODOT 自己的版本則是**假設**爬 16°

## `m4a4_artanis-rcs.csv`（第 49 項 M4A1，2026-10-20）

- 來源：同一個 repo 的 `patterns/m4a4.csv`（main `7387d39` 下載；這個檔最後一次修改 `f050b44`）
- CS2 的 `weapon_m4a1` 在遊戲裡叫 M4A4 → 用 `m4a4.csv`（30 列、每發 88 毫秒，和 `m_flCycleTime` 0.09、彈匣 30 對得上）；`m4a1.csv` 是 M4A1-S（25 列），不用
- 換算同 AK（一個單位 0.0539°）：`python -X utf8 tools/recoil_pattern.py data/recoil/m4a4_artanis-rcs.csv`；最高往上 9.72°（第 29 發）、左右 −2.17°～+4.43°

### Artanis-RCS 的授權（MIT）

```
MIT License

Copyright (c) 2025 Achraf.O

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
