import os
import struct

# 要搜索的关键词
keywords = [b'experience', b'EXPERIENCE', b'level', b'LEVEL', b'exp', b'EXP', 
            b'next level', b'NEXT LEVEL', b'required', b'REQUIRED',
            b'level up', b'LEVEL UP', b'levelup', b'LEVELUP']

# 搜索目录
search_dir = 'E:\\EvilInvasion'

# 要跳过的文件扩展名（二进制文件）
skip_extensions = ['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.ogg', '.wav', '.mp3', 
                   '.exe', '.dll', '.bin', '.dds', '.fnt', '.ctex', '.md5', '.cache',
                   '.vulkan', '.cfg', '.prp', '.dat', '.db', '.gbf', '.bak', '.journal']

found_files = []

for root, dirs, files in os.walk(search_dir):
    # 跳过 Godot 项目目录和 .git 目录
    dirs[:] = [d for d in dirs if d not in ['.git', '.godot', 'GodotReMake']]
    
    for filename in files:
        filepath = os.path.join(root, filename)
        
        # 跳过特定扩展名
        if any(filename.lower().endswith(ext) for ext in skip_extensions):
            continue
        
        try:
            with open(filepath, 'rb') as f:
                data = f.read()
            
            # 检查是否包含关键词
            for keyword in keywords:
                if keyword in data:
                    found_files.append(filepath)
                    print(f'\n找到: {filepath}')
                    
                    # 尝试显示上下文
                    try:
                        text = data.decode('ascii', errors='replace')
                        for keyword in keywords:
                            idx = text.lower().find(keyword.decode().lower())
                            if idx != -1:
                                start = max(0, idx - 50)
                                end = min(len(text), idx + 150)
                                print(f'  -> ...{text[start:end]}...')
                                break
                    except:
                        pass
                    break
                    
        except Exception as e:
            pass  # 跳过无法读取的文件

print(f'\n\n总共找到 {len(found_files)} 个包含关键词的文件')
for f in found_files:
    print(f'  - {f}')
