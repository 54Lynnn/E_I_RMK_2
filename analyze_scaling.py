import struct

dll_path = r'e:\EvilInvasion\Logic.dll'
with open(dll_path, 'rb') as f:
    data = f.read()

# 找到 MonsterBalance.txt 解析代码附近的字符串
# 我们知道 PER_LEVEL 相关字符串在 0x554ce 附近
pos = 0x55400
end = 0x55600

print('=== Strings around scaling code (0x55400-0x55600) ===')
i = pos
while i < end:
    if 32 <= data[i] <= 126:
        str_start = i
        while i < end and 32 <= data[i] <= 126:
            i += 1
        s = data[str_start:i].decode('ascii', errors='replace')
        if len(s) >= 3:
            print('  0x' + hex(str_start)[2:] + ': "' + s + '"')
    i += 1

# 搜索 HERO 相关的属性
print('\n=== Searching for HERO stats ===')
hero_keywords = [b'HERO', b'Hero', b'hero']
for keyword in hero_keywords:
    pos = 0
    count = 0
    while True:
        pos = data.find(keyword, pos)
        if pos < 0 or count > 10:
            break
        ctx_start = max(0, pos - 30)
        ctx_end = min(len(data), pos + 50)
        ctx = data[ctx_start:ctx_end]
        clean = b''
        for b in ctx:
            if 32 <= b <= 126:
                clean += bytes([b])
            elif b == 0:
                clean += b'|'
            else:
                clean += b'.'
        print('  Found ' + keyword.decode() + ' at 0x' + hex(pos)[2:] + ': ' + clean.decode('ascii', errors='replace'))
        pos += 1
        count += 1
