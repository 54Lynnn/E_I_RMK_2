import struct

dll_path = r'e:\EvilInvasion\Logic.dll'
with open(dll_path, 'rb') as f:
    data = f.read()

# 搜索怪物相关的字符串
monster_keywords = [b'Monster', b'monster', b'SPIDER', b'ZOMBIE', b'BEAR', b'DEMON', b'REAPER', b'ARCHER', b'BOSS']

print('=== Monster-related strings in Logic.dll ===')
for keyword in monster_keywords:
    pos = 0
    count = 0
    while True:
        pos = data.find(keyword, pos)
        if pos < 0 or count > 10:
            break
        # 提取周围的字符串
        start = max(0, pos - 50)
        end = min(len(data), pos + 100)
        context = b''
        for i in range(start, end):
            if 32 <= data[i] <= 126:
                context += bytes([data[i]])
            elif data[i] == 0:
                context += b'|'
            else:
                context += b'.'
        print('  Found ' + keyword.decode() + ' at 0x' + hex(pos)[2:] + ':')
        print('    Context: ' + context.decode('ascii', errors='replace'))
        pos += 1
        count += 1
