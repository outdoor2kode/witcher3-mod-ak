"""把巫師3的 CR2W 二進位檔（例：動畫圖 .w2beh）的物件和屬性印成文字，方便搜尋。

用法：
    python -X utf8 tools/cr2w_dump.py <檔案> [--out 輸出.txt] [--tree N ...] [--find 值 ...]

- 只讀檔案，不修改
- 預設印出全部物件；--tree N 只印第 N 個物件和它底下的物件（以 parent 判斷）
- --find 值：列出屬性值（CName、String）等於「值」的物件編號，再印出這些物件
- 指標（ptr、handle）印成 #N，N 是物件編號（從 0 起算）
- 看不懂的型別照大小跳過，印出位元組數；屬性串列之後的自訂資料只印出大小

格式（使用者 2026-10-13 同意寫這個工具；用 pc_overlay.w2beh 實際檢查過，docs/findings.md §17.9）：
- 檔頭：'CR2W'、版本（REDkit 的檔案是 164）、……、10 個表（各 12 bytes：位置、數量、CRC），從第 40 byte 開始
- 表 0：字串區（以 0 結尾的 UTF-8）；表 1：名稱（8 bytes：字串位置、雜湊）；表 2：匯入（8 bytes：路徑字串位置、類別名稱、旗標）
- 表 4：物件（24 bytes：類別名稱、旗標、parent（從 1 起算，0 = 沒有）、資料大小、資料位置、範本、CRC）
- 物件資料：1 個 0，接著屬性串列「名稱（u16）、型別（u16）、大小（u32，含自己 4 bytes）、值」，名稱 0 表示結束
"""
import argparse
import struct
import sys
from pathlib import Path

SIMPLE_TYPES = {
    'Bool': '<?', 'Int8': '<b', 'Uint8': '<B', 'Int16': '<h', 'Uint16': '<H',
    'Int32': '<i', 'Uint32': '<I', 'Int64': '<q', 'Uint64': '<Q',
    'Float': '<f', 'Double': '<d',
}


class Cr2wFile:
    def __init__(self, data: bytes):
        self.data = data
        magic, self.version = struct.unpack_from('<4sI', data, 0)
        if magic != b'CR2W':
            raise ValueError('不是 CR2W 檔案')
        tables = [struct.unpack_from('<III', data, 40 + 12 * i) for i in range(10)]

        str_off, str_size, _ = tables[0]
        self.strings = data[str_off:str_off + str_size]

        name_off, name_count, _ = tables[1]
        self.names = [self.string_at(struct.unpack_from('<I', data, name_off + 8 * i)[0]) for i in range(name_count)]

        imp_off, imp_count, _ = tables[2]
        self.imports = []
        for i in range(imp_count):
            path_pos, class_id, _flags = struct.unpack_from('<IHH', data, imp_off + 8 * i)
            self.imports.append((self.string_at(path_pos), self.names[class_id]))

        exp_off, exp_count, _ = tables[4]
        self.exports = []
        for i in range(exp_count):
            class_id, _flags, parent, size, offset, _tmpl, _crc = struct.unpack_from('<HHIIIII', data, exp_off + 24 * i)
            self.exports.append({'class': self.names[class_id], 'parent': parent - 1, 'size': size, 'offset': offset})

    def string_at(self, pos: int) -> str:
        end = self.strings.index(b'\0', pos)
        return self.strings[pos:end].decode('utf-8', 'replace')

    # ---- 讀值 ----

    def name(self, idx: int) -> str:
        return self.names[idx] if 0 <= idx < len(self.names) else f'<name {idx}?>'

    def read_props(self, pos: int, end: int):
        """讀屬性串列，回傳（[(名稱, 型別, 值)], 結束位置）；格式不對時丟出 ValueError"""
        props = []
        while True:
            if pos + 2 > end:
                raise ValueError('屬性串列沒有結束')
            name_id = struct.unpack_from('<H', self.data, pos)[0]
            pos += 2
            if name_id == 0:
                return props, pos
            if pos + 6 > end:
                raise ValueError('屬性標頭不完整')
            type_id, size = struct.unpack_from('<HI', self.data, pos)
            if name_id >= len(self.names) or type_id >= len(self.names) or size < 4 or pos + 2 + size > end:
                raise ValueError('屬性標頭不合理')
            value_start = pos + 6
            value_end = pos + 2 + size
            type_name = self.names[type_id]
            props.append((self.names[name_id], type_name, self.read_value(type_name, value_start, value_end)))
            pos = value_end

    def read_value(self, type_name: str, pos: int, end: int):
        size = end - pos
        if type_name in SIMPLE_TYPES:
            fmt = SIMPLE_TYPES[type_name]
            if struct.calcsize(fmt) == size:
                return struct.unpack_from(fmt, self.data, pos)[0]
        if type_name == 'CName' and size == 2:
            return self.name(struct.unpack_from('<H', self.data, pos)[0])
        if type_name == 'String':
            return self.read_string(pos, end)
        if type_name.startswith('ptr:') or type_name.startswith('handle:'):
            if size == 4:
                ref = struct.unpack_from('<i', self.data, pos)[0]
                if ref > 0:
                    return Ref(ref - 1)
                if ref < 0:
                    return ImportRef(-ref - 1, self)
                return None
        if type_name.startswith('soft:') and size == 2:
            return ImportRef(struct.unpack_from('<H', self.data, pos)[0] - 1, self)
        if type_name.startswith('array:'):
            return self.read_array(type_name.split(',', 2)[2], pos, end)
        # 列舉：存成一個名稱（2 bytes）
        if size == 2:
            return self.name(struct.unpack_from('<H', self.data, pos)[0])
        # 結構：巢狀的屬性串列（前面通常也有 1 個 0，同物件資料）
        props = self.try_struct(pos, end)
        if props is not None:
            return Struct(props)
        return Raw(self.data[pos:end])

    def try_struct(self, pos: int, end: int):
        """整段剛好是一個結構（可能有開頭的 0）時回傳屬性串列，否則 None"""
        starts = [pos + 1, pos] if pos < end and self.data[pos] == 0 else [pos]
        for start in starts:
            try:
                props, stop = self.read_props(start, end)
                if stop == end:
                    return props
            except ValueError:
                pass
        return None

    def read_array(self, elem_type: str, pos: int, end: int):
        count = struct.unpack_from('<I', self.data, pos)[0]
        pos += 4
        items = []
        fixed = None
        if elem_type in SIMPLE_TYPES:
            fixed = struct.calcsize(SIMPLE_TYPES[elem_type])
        elif elem_type == 'CName' or elem_type.startswith('soft:'):
            fixed = 2
        elif elem_type.startswith('ptr:') or elem_type.startswith('handle:'):
            fixed = 4
        if fixed is not None:
            if pos + fixed * count != end:
                return Raw(self.data[pos - 4:end])
            for i in range(count):
                items.append(self.read_value(elem_type, pos + fixed * i, pos + fixed * (i + 1)))
            return items
        # 結構陣列：每個元素都是一串屬性（前面有 1 個 0）
        start = pos
        try:
            for _ in range(count):
                if pos < end and self.data[pos] == 0:
                    pos += 1
                props, pos = self.read_props(pos, end)
                items.append(Struct(props))
            if pos == end:
                return items
        except ValueError:
            pass
        return Raw(self.data[start - 4:end])

    def read_string(self, pos: int, end: int):
        # 長度前綴：第 1 byte 的 bit7 = 一般字元（否則 UTF-16），bit6 = 長度還有下一個 byte
        first = self.data[pos]
        length = first & 0x3F
        cur = pos + 1
        if first & 0x40:
            shift = 6
            while True:
                b = self.data[cur]
                cur += 1
                length |= (b & 0x7F) << shift
                shift += 7
                if not b & 0x80:
                    break
        if first & 0x80:
            raw = self.data[cur:cur + length]
            return raw.decode('utf-8', 'replace') if cur + length <= end else Raw(self.data[pos:end])
        raw = self.data[cur:cur + 2 * length]
        return raw.decode('utf-16-le', 'replace') if cur + 2 * length <= end else Raw(self.data[pos:end])

    def read_export(self, idx: int):
        """回傳（屬性串列, 串列之後的自訂資料 bytes 數）"""
        exp = self.exports[idx]
        pos = exp['offset']
        end = pos + exp['size']
        if pos < end and self.data[pos] == 0:
            pos += 1
        try:
            props, stop = self.read_props(pos, end)
        except ValueError as err:
            return [('<讀取失敗>', '', str(err))], end - pos
        return props, end - stop


class Ref:
    def __init__(self, idx):
        self.idx = idx

    def __repr__(self):
        return f'#{self.idx}'


class ImportRef:
    def __init__(self, idx, f):
        self.text = f'import:{f.imports[idx][0]}' if 0 <= idx < len(f.imports) else f'import:{idx}?'

    def __repr__(self):
        return self.text


class Struct:
    def __init__(self, props):
        self.props = props


class Raw:
    def __init__(self, b):
        self.b = b

    def __repr__(self):
        head = self.b[:16].hex(' ')
        return f'<{len(self.b)} bytes: {head}{" …" if len(self.b) > 16 else ""}>'


# ---- 輸出 ----

def format_value(value, indent: str, out: list):
    """單行能表示的回傳字串；結構、結構陣列寫進 out（多行）並回傳空字串"""
    if isinstance(value, Struct):
        for name, type_name, v in value.props:
            sub = []
            line = format_value(v, indent + '  ', sub)
            out.append(f'{indent}{name} : {type_name} = {line}')
            out.extend(sub)
        return ''
    if isinstance(value, list):
        if all(not isinstance(v, (Struct, list)) for v in value):
            return '[' + ', '.join(str(v) for v in value) + ']'
        out.append(f'{indent}(陣列 {len(value)} 個)')
        for i, v in enumerate(value):
            out.append(f'{indent}[{i}]')
            format_value(v, indent + '  ', out)
        return ''
    if isinstance(value, str):
        return repr(value)
    return str(value)


def dump_export(f: Cr2wFile, idx: int, lines: list):
    exp = f.exports[idx]
    props, extra = f.read_export(idx)
    parent = f'#{exp["parent"]}' if exp['parent'] >= 0 else '-'
    lines.append(f'#{idx} {exp["class"]}  parent={parent}' + (f'  (+{extra} bytes 自訂資料)' if extra else ''))
    for name, type_name, value in props:
        sub = []
        text = format_value(value, '    ', sub)
        lines.append(f'  {name} : {type_name} = {text}')
        lines.extend(sub)


def collect_values(value, acc: set):
    if isinstance(value, Struct):
        for _, _, v in value.props:
            collect_values(v, acc)
    elif isinstance(value, list):
        for v in value:
            collect_values(v, acc)
    elif isinstance(value, str):
        acc.add(value)


def main() -> int:
    parser = argparse.ArgumentParser(description='把 CR2W 檔（.w2beh 等）的物件和屬性印成文字')
    parser.add_argument('file', type=Path)
    parser.add_argument('--out', type=Path, help='輸出到檔案（預設印到畫面）')
    parser.add_argument('--tree', type=int, nargs='*', default=[], help='只印這些物件和它們底下的物件')
    parser.add_argument('--find', nargs='*', default=[], help='只印屬性值（CName、String）等於這些值的物件')
    args = parser.parse_args()

    f = Cr2wFile(args.file.read_bytes())
    lines = [f'{args.file}  版本 {f.version}  名稱 {len(f.names)}  匯入 {len(f.imports)}  物件 {len(f.exports)}']

    if args.find:
        wanted = set(args.find)
        hits = []
        for idx in range(len(f.exports)):
            props, _ = f.read_export(idx)
            acc = set()
            for _, _, v in props:
                collect_values(v, acc)
            if acc & wanted:
                hits.append(idx)
        lines.append(f'找到 {len(hits)} 個物件：' + ', '.join(f'#{i}' for i in hits))
        targets = hits
    elif args.tree:
        children = {}
        for idx, exp in enumerate(f.exports):
            children.setdefault(exp['parent'], []).append(idx)
        targets = []
        stack = list(reversed(args.tree))
        while stack:
            idx = stack.pop()
            targets.append(idx)
            stack.extend(reversed(children.get(idx, [])))
    else:
        targets = range(len(f.exports))

    for idx in targets:
        dump_export(f, idx, lines)

    text = '\n'.join(lines) + '\n'
    if args.out:
        args.out.write_text(text, encoding='utf-8')
        print(f'寫入 {args.out}（{len(lines)} 行）')
    else:
        sys.stdout.write(text)
    return 0


if __name__ == '__main__':
    sys.exit(main())
