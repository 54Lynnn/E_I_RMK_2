import struct
import os

pak_path = r'e:\EvilInvasion\Data.pak'
out_dir = r'e:\EvilInvasion\extracted_all'

os.makedirs(out_dir, exist_ok=True)

with open(pak_path, 'rb') as f:
    # 文件头
    header = f.read(8)
    print(f"Header: {header.hex()}")
    
    num_files = struct.unpack('<I', f.read(4))[0]
    print(f"Total files in PAK: {num_files}")
    print()
    
    file_list = []
    
    for i in range(num_files):
        name_len = struct.unpack('<I', f.read(4))[0]
        name = f.read(name_len).decode('utf-8', errors='replace')
        offset = struct.unpack('<I', f.read(4))[0]
        size = struct.unpack('<I', f.read(4))[0]
        
        file_list.append((name, offset, size))
        print(f"[{i:3d}] {name:50s} offset={offset:8d} size={size:8d}")
    
    print("\n" + "="*80)
    print("Decrypting all text files...\n")
    
    for name, offset, size in file_list:
        f.seek(offset)
        data = f.read(size)
        
        # XOR 0xA5 解密
        decrypted = bytes([b ^ 0xA5 for b in data])
        
        safe_name = name.replace('\\', '_').replace('/', '_').replace(':', '_')
        out_path = os.path.join(out_dir, safe_name)
        
        # 如果是文本文件，尝试以文本保存
        try:
            text = decrypted.decode('ascii', errors='replace')
            with open(out_path + '.txt', 'w', encoding='utf-8') as out:
                out.write(text)
            print(f"  [TEXT] {name:50s} -> {safe_name}.txt")
        except:
            # 二进制文件直接保存
            with open(out_path, 'wb') as out:
                out.write(decrypted)
            print(f"  [BIN]  {name:50s} -> {safe_name}")
