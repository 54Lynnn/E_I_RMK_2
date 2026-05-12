import struct

dll_path = r'e:\EvilInvasion\Logic.dll'
with open(dll_path, 'rb') as f:
    data = f.read()

# 搜索难度相关的字符串
keywords = [b'DIFFICULTY', b'difficulty', b'Easy', b'Normal', b'Hard', 
            b'Nightmare', b'Hell', b'wave', b'WAVE', b'ROUND']

print('=== Searching for difficulty/wave keywords ===')
for keyword in keywords:
    pos = 0
    count = 0
    while True:
        pos = data.find(keyword, pos)
        if pos < 0 or count > 5:
            break
        ctx_start = max(0, pos - 40)
        ctx_end = min(len(data), pos + 60)
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

# 搜索 Quest 相关的数据
print('\n=== Searching for Quest/Wave data ===')
quest_keywords = [b'Quest', b'QUEST', b'quest']
for keyword in quest_keywords:
    pos = 0
    count = 0
    while True:
        pos = data.find(keyword, pos)
        if pos < 0 or count > 5:
            break
        ctx_start = max(0, pos - 50)
        ctx_end = min(len(data), pos + 80)
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
