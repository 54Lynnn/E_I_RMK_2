import os
import struct

# 读取 Data.pak 文件
with open('E:\\EvilInvasion\\Data.pak', 'rb') as f:
    data = f.read()

print(f'文件大小: {len(data)} bytes')

# 解析文件头
file_count = struct.unpack('<I', data[8:12])[0]
print(f'文件数量: {file_count}')

# 解析所有文件
offset = 12
files = []
for i in range(file_count):
    try:
        name_len = struct.unpack('<I', data[offset:offset+4])[0]
        offset += 4
        filename = data[offset:offset+name_len].decode('ascii', errors='replace')
        offset += name_len
        file_offset = struct.unpack('<I', data[offset:offset+4])[0]
        offset += 4
        file_size = struct.unpack('<I', data[offset:offset+4])[0]
        offset += 4
        files.append({'name': filename, 'offset': file_offset, 'size': file_size})
    except:
        break

# 搜索所有文件内容中包含 "experience" 或 "level" 的文件
print(f'\n搜索包含经验/等级数据的文件...')
keywords = [b'experience', b'EXPERIENCE', b'level', b'LEVEL', b'exp', b'EXP']

found_files = []
for file_info in files:
    file_data = data[file_info['offset']:file_info['offset']+file_info['size']]
    
    # 尝试 XOR 解密
    decrypted = bytearray()
    for b in file_data:
        decrypted.append(b ^ 0xA5)
    
    # 检查是否包含关键词
    for keyword in keywords:
        if keyword in decrypted:
            found_files.append(file_info)
            print(f'\n找到: {file_info["name"]}')
            
            # 保存文件
            output_name = f'E:\\EvilInvasion\\Extracted_{file_info["name"].replace("\\", "_")}'
            with open(output_name, 'wb') as out:
                out.write(decrypted)
            print(f'  -> 已保存到: {output_name}')
            
            # 显示包含关键词的上下文
            try:
                text = decrypted.decode('ascii', errors='replace')
                for keyword in keywords:
                    idx = text.lower().find(keyword.decode().lower())
                    if idx != -1:
                        start = max(0, idx - 100)
                        end = min(len(text), idx + 200)
                        print(f'  -> 上下文: ...{text[start:end]}...')
            except:
                pass
            break

print(f'\n总共找到 {len(found_files)} 个相关文件')
