import struct
import os

pak_path = r'e:\EvilInvasion\Data.pak'

with open(pak_path, 'rb') as f:
    f.seek(8)
    num_files = struct.unpack('<I', f.read(4))[0]
    
    for i in range(num_files):
        name_len = struct.unpack('<I', f.read(4))[0]
        name = f.read(name_len).decode('utf-8', errors='ignore')
        offset = struct.unpack('<I', f.read(4))[0]
        size = struct.unpack('<I', f.read(4))[0]
        
        if 'HeroBalance' in name or 'HeroDesc' in name:
            f.seek(offset)
            data = f.read(size)
            
            # 尝试用XOR 0xA5解密（和MonsterBalance一样的密钥）
            decrypted = bytes([b ^ 0xA5 for b in data])
            
            try:
                text = decrypted.decode('ascii', errors='replace')
                print('=== ' + name + ' (decrypted) ===')
                print(text)
                print()
                
                # 保存
                safe_name = name.replace('\\', '_').replace('/', '_')
                out_path = os.path.join(r'e:\EvilInvasion', safe_name + '_decrypted.txt')
                with open(out_path, 'w', encoding='utf-8') as out:
                    out.write(text)
                print('Saved to: ' + out_path)
            except Exception as e:
                print('Error decrypting ' + name + ': ' + str(e))
