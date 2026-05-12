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
            
            # 尝试不同的解密方法
            print('Trying different decryption methods...')
            
            # 方法1: 简单XOR
            for key in range(256):
                decrypted = bytes([b ^ key for b in data])
                try:
                    text = decrypted.decode('ascii', errors='strict')
                    if 'MONSTER' in text or 'HEALTH' in text or 'COEFF' in text:
                        print('Found with XOR key 0x' + hex(key)[2:] + ':')
                        print(text[:500])
                        print('...')
                        break
                except:
                    pass
            
            # 方法2: 尝试找到正确的XOR密钥
            # 我们知道文件应该以某种格式开头
            # 尝试用已知的文件头模式
            print('\nTrying pattern-based decryption...')
            
            # 保存原始数据供分析
            with open(r'e:\EvilInvasion\MonsterBalance_raw.bin', 'wb') as out:
                out.write(data)
            print('Raw data saved to MonsterBalance_raw.bin')
            
            break
