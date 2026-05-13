import struct

exe_path = r'e:\EvilInvasion\EvilInvasion.exe'

with open(exe_path, 'rb') as f:
    data = f.read()

# 搜索 SWF 签名: FWS (未压缩) 或 CWS (压缩)
# Flash SWF 文件头: FWS + 版本(1 byte) + 文件大小(4 bytes)
signatures = [b'FWS', b'CWS']

for sig in signatures:
    pos = 0
    while True:
        pos = data.find(sig, pos)
        if pos == -1:
            break
        
        if pos + 8 > len(data):
            pos += 1
            continue
        
        version = data[pos + 3]
        file_size = struct.unpack('<I', data[pos+4:pos+8])[0]
        
        print(f"Found {sig.decode()} at offset {pos}, version={version}, size={file_size}")
        
        # 提取 SWF
        swf_data = data[pos:pos+file_size]
        
        # 如果是CWS（压缩），需要解压
        if sig == b'CWS':
            import zlib
            try:
                # CWS格式: 头(8 bytes) + 压缩的zlib数据
                compressed = swf_data[8:]
                decompressed = zlib.decompress(compressed)
                print(f"  Decompressed size: {len(decompressed)}")
            except Exception as e:
                print(f"  Decompress error: {e}")
        
        out_name = f"EvilInvasion_{sig.decode()}.swf"
        with open(rf'e:\EvilInvasion\{out_name}', 'wb') as out:
            out.write(swf_data)
        print(f"  Saved to {out_name}")
        
        pos += 1
    
print("Done searching.")
