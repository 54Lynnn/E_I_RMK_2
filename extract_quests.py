import struct
import os

pak_path = r'e:\EvilInvasion\Data.pak'

with open(pak_path, 'rb') as f:
    f.seek(8)
    num_files = struct.unpack('<I', f.read(4))[0]
    
    interesting_files = []
    
    for i in range(num_files):
        name_len = struct.unpack('<I', f.read(4))[0]
        name = f.read(name_len).decode('utf-8', errors='ignore')
        offset = struct.unpack('<I', f.read(4))[0]
        size = struct.unpack('<I', f.read(4))[0]
        
        # 查找所有可能包含怪物生成数据的文件
        if any(keyword in name.lower() for keyword in ['quest', 'wave', 'spawn', 'level', 'balance', 'difficulty']):
            interesting_files.append((name, offset, size))
    
    print('=== Interesting files found ===')
    for name, offset, size in interesting_files:
        print('  ' + name + ' (offset=' + str(offset) + ', size=' + str(size) + ')')
    
    # 尝试解密这些文件
    for name, offset, size in interesting_files:
        f.seek(offset)
        data = f.read(size)
        
        # 尝试用XOR 0xA5解密
        decrypted = bytes([b ^ 0xA5 for b in data])
        
        try:
            text = decrypted.decode('ascii', errors='strict')
            if len(text.strip()) > 10:
                print('\n=== ' + name + ' (decrypted) ===')
                print(text[:1000])
                
                # 保存
                safe_name = name.replace('\\', '_').replace('/', '_')
                out_path = os.path.join(r'e:\EvilInvasion', safe_name + '_decrypted.txt')
                with open(out_path, 'w', encoding='utf-8') as out:
                    out.write(text)
                print('Saved to: ' + out_path)
        except:
            pass  # 不是文本文件或解密失败
