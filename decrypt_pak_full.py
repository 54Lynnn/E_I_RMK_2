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
        # 读取文件名长度
        name_len = struct.unpack('<I', data[offset:offset+4])[0]
        offset += 4
        
        # 读取文件名
        filename = data[offset:offset+name_len].decode('ascii', errors='replace')
        offset += name_len
        
        # 读取文件偏移和大小
        file_offset = struct.unpack('<I', data[offset:offset+4])[0]
        offset += 4
        file_size = struct.unpack('<I', data[offset:offset+4])[0]
        offset += 4
        
        files.append({
            'name': filename,
            'offset': file_offset,
            'size': file_size
        })
    except Exception as e:
        print(f'解析文件 {i} 时出错: {e}')
        break

# 显示所有文件
print(f'\n所有文件列表:')
for i, file_info in enumerate(files):
    print(f'{i}: {file_info["name"]} (偏移: {file_info["offset"]}, 大小: {file_info["size"]})')

# 提取并解密所有 Balance 和 Hero 相关文件
print(f'\n提取关键文件...')
for file_info in files:
    filename = file_info['name']
    if 'Balance' in filename or 'Hero' in filename or 'Level' in filename or 'Exp' in filename:
        print(f'\n找到: {filename}')
        file_data = data[file_info['offset']:file_info['offset']+file_info['size']]
        
        # 尝试 XOR 解密
        decrypted = bytearray()
        for b in file_data:
            decrypted.append(b ^ 0xA5)
        
        # 保存解密后的文件
        output_name = f'E:\\EvilInvasion\\Extracted_{filename.replace("\\", "_")}'
        with open(output_name, 'wb') as out:
            out.write(decrypted)
        print(f'  -> 已保存到: {output_name}')
        
        # 尝试显示文本内容
        try:
            text = decrypted.decode('ascii', errors='replace')
            print(f'  -> 内容预览 (前500字符):')
            print(text[:500])
        except:
            print(f'  -> 二进制文件，无法显示文本')

print('\n完成！')
