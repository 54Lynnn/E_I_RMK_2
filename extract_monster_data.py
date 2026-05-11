import struct

pak_path = r'e:\EvilInvasion\Data.pak'

with open(pak_path, 'rb') as f:
    f.seek(8)
    num_files = struct.unpack('<I', f.read(4))[0]
    
    for i in range(num_files):
        name_len = struct.unpack('<I', f.read(4))[0]
        name = f.read(name_len).decode('utf-8', errors='ignore')
        offset = struct.unpack('<I', f.read(4))[0]
        size = struct.unpack('<I', f.read(4))[0]
        
        if 'MonsterBalance' in name:
            f.seek(offset)
            data = f.read(size)
            
            # 用XOR 0xA5解密
            decrypted = bytes([b ^ 0xA5 for b in data])
            text = decrypted.decode('ascii', errors='replace')
            
            print('=== MonsterBalance.txt (decrypted) ===')
            print(text)
            
            # 保存解密后的文件
            with open(r'e:\EvilInvasion\MonsterBalance_decrypted.txt', 'w', encoding='utf-8') as out:
                out.write(text)
            print('\nSaved to MonsterBalance_decrypted.txt')
            break
