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
        
        # 查找 Quests.txt
        if 'Quests' in name or 'quests' in name.lower():
            f.seek(offset)
            data = f.read(size)
            
            # 尝试用XOR 0xA5解密
            decrypted = bytes([b ^ 0xA5 for b in data])
            
            try:
                text = decrypted.decode('ascii', errors='replace')
                print('=== ' + name + ' (decrypted) ===')
                print(text)
                
                # 保存
                safe_name = name.replace('\\', '_').replace('/', '_')
                out_path = os.path.join(r'e:\EvilInvasion', safe_name + '_decrypted.txt')
                with open(out_path, 'w', encoding='utf-8') as out:
                    out.write(text)
                print('\nSaved to: ' + out_path)
            except Exception as e:
                print('Error: ' + str(e))
