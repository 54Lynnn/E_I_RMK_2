import struct

dll_path = r'e:\EvilInvasion\Logic.dll'
with open(dll_path, 'rb') as f:
    data = f.read()

# 搜索 Mummy 相关的字符串
print('=== Searching for MUMMY in Logic.dll ===')
pos = 0
count = 0
while True:
    pos = data.find(b'MUMMY', pos)
    if pos < 0 or count > 20:
        break
    # 提取上下文
    ctx_start = max(0, pos - 50)
    ctx_end = min(len(data), pos + 100)
    ctx = data[ctx_start:ctx_end]
    clean = b''
    for b in ctx:
        if 32 <= b <= 126:
            clean += bytes([b])
        elif b == 0:
            clean += b'|'
        else:
            clean += b'.'
    print('  Found MUMMY at 0x' + hex(pos)[2:] + ': ' + clean.decode('ascii', errors='replace'))
    pos += 1
    count += 1

# 也搜索小写的 mummy
print('\n=== Searching for mummy in Logic.dll ===')
pos = 0
count = 0
while True:
    pos = data.find(b'mummy', pos)
    if pos < 0 or count > 20:
        break
    ctx_start = max(0, pos - 50)
    ctx_end = min(len(data), pos + 100)
    ctx = data[ctx_start:ctx_end]
    clean = b''
    for b in ctx:
        if 32 <= b <= 126:
            clean += bytes([b])
        elif b == 0:
            clean += b'|'
        else:
            clean += b'.'
    print('  Found mummy at 0x' + hex(pos)[2:] + ': ' + clean.decode('ascii', errors='replace'))
    pos += 1
    count += 1

# 搜索所有怪物类型
print('\n=== All MONSTER_ types ===')
monster_types = []
pos = 0
while True:
    pos = data.find(b'MONSTER_', pos)
    if pos < 0:
        break
    # 提取怪物类型名称
    end = pos + 8
    while end < len(data) and 65 <= data[end] <= 90:  # 大写字母
        end += 1
    name = data[pos:end].decode('ascii', errors='replace')
    if name not in monster_types:
        monster_types.append(name)
    pos += 1

for mt in sorted(monster_types):
    print('  ' + mt)
