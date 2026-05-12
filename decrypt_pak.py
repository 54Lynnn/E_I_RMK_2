import os
import struct

# 读取 Data.pak 文件
with open('E:\\EvilInvasion\\Data.pak', 'rb') as f:
    data = f.read()

print(f'文件大小: {len(data)} bytes')
print(f'前100字节 (hex): {data[:100].hex()}')

# 解析文件头
print(f'\n文件头分析:')
print(f'版本信息: {data[:8]}')
file_count = struct.unpack('<I', data[8:12])[0]
print(f'文件数量: {file_count}')

# 尝试解析文件列表
offset = 12
for i in range(min(file_count, 20)):  # 只显示前20个文件
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
        
        print(f'文件 {i}: {filename} (偏移: {file_offset}, 大小: {file_size})')
        
        # 如果文件名包含 Balance 或 Hero，提取内容
        if 'Balance' in filename or 'Hero' in filename:
            print(f'  -> 找到关键文件！')
            file_data = data[file_offset:file_offset+file_size]
            
            # 尝试 XOR 解密
            decrypted = bytearray()
            for b in file_data:
                decrypted.append(b ^ 0xA5)
            
            # 保存解密后的文件
            output_name = f'E:\\EvilInvasion\\Extracted_{filename.replace("\\", "_")}'
            with open(output_name, 'wb') as out:
                out.write(decrypted)
            print(f'  -> 已保存到: {output_name}')
            
            # 显示前200字节
            print(f'  -> 内容预览: {decrypted[:200]}')
            
    except Exception as e:
        print(f'解析文件 {i} 时出错: {e}')
        break

print('\n完成！')
