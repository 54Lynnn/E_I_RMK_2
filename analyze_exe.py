import re

exe_path = r'e:\EvilInvasion\EvilInvasion.exe'

with open(exe_path, 'rb') as f:
    data = f.read()

print(f"File size: {len(data)} bytes")
print()

# 查看exe文件头
print("=== File header (first 64 bytes) ===")
for i in range(0, 64, 16):
    chunk = data[i:i+16]
    hex_str = ' '.join(f'{b:02x}' for b in chunk)
    ascii_str = ''.join(chr(b) if 32 <= b < 127 else '.' for b in chunk)
    print(f'{i:04x}: {hex_str:48s} {ascii_str}')

print()

# 搜索所有可能的SWF签名（包括大小写变体）
signatures_to_find = [b'FWS', b'CWS', b'ZWS', b'fws', b'cws']
for sig in signatures_to_find:
    pos = 0
    count = 0
    while True:
        pos = data.find(sig, pos)
        if pos == -1:
            break
        # FWS/CWS后跟版本(1字节)和文件大小(4字节)
        if pos + 8 <= len(data):
            version = data[pos + 3]
            file_size = int.from_bytes(data[pos+4:pos+8], 'little')
            count += 1
            print(f"Found {sig.decode()} at offset {pos}, version={version}, size={file_size}")
            
            # 如果是CWS，尝试zlib解压
            if sig == b'CWS':
                import zlib
                try:
                    compressed = data[pos+8:pos+file_size]
                    decompressed = zlib.decompress(compressed)
                    print(f"  -> Decompressed size: {len(decompressed)}")
                    # 保存swf
                    swf_data = data[pos:pos+file_size]
                    with open(r'e:\EvilInvasion\EvilInvasion_decompiled.swf', 'wb') as out:
                        out.write(swf_data)
                    print(f"  -> Saved to EvilInvasion_decompiled.swf")
                except Exception as e:
                    print(f"  -> Zlib error: {e}")
        pos += 1
    
    if count == 0:
        print(f"No {sig.decode()} signature found")

print()

# 搜索提示性字符串
keywords = [b'SWF', b'Flash', b'Adobe', b'Macromedia', b'Shockwave', 
            b'GFX', b'Scaleform', b'movie', b'swf', b'DoSWF', b'loaderInfo']
for kw in keywords:
    pos = 0
    while True:
        pos = data.find(kw, pos)
        if pos == -1:
            break
        context = data[max(0,pos-8):pos+len(kw)+16]
        try:
            ctx_str = context.decode('ascii', errors='replace')
            print(f"  '{kw.decode()}' at offset {pos}: ...{ctx_str}...")
        except:
            pass
        pos += 1

print()

# 检查文件末尾
print("=== Last 16 bytes ===")
for i in range(max(0, len(data)-16), len(data), 16):
    chunk = data[i:i+16]
    hex_str = ' '.join(f'{b:02x}' for b in chunk)
    ascii_str = ''.join(chr(b) if 32 <= b < 127 else '.' for b in chunk)
    print(f'{i:04x}: {hex_str:48s} {ascii_str}')
