import subprocess
import time
import os

# 尝试运行原版游戏并获取经验值数据
# 由于无法直接读取游戏内存，我们可以尝试：
# 1. 检查是否有游戏日志文件
# 2. 检查是否有存档文件可以解析

print('检查游戏日志和存档文件...')

# 检查 stdout.txt 和 stderr.txt（游戏可能输出的日志）
log_files = ['stdout.txt', 'stderr.txt', 'godot_log.txt']
for log_file in log_files:
    if os.path.exists(log_file):
        print(f'\n找到日志文件: {log_file}')
        with open(log_file, 'r') as f:
            content = f.read()
            if 'experience' in content.lower() or 'level' in content.lower():
                print(f'  包含经验/等级信息！')
                print(f'  内容: {content[:500]}')

# 检查存档文件
save_files = ['Profiles/123.ei', 'Profiles/profiles.dat', 'HighScores.dat']
for save_file in save_files:
    if os.path.exists(save_file):
        print(f'\n找到存档文件: {save_file}')
        with open(save_file, 'rb') as f:
            data = f.read()
            # 尝试查找数字模式
            import struct
            print(f'  文件大小: {len(data)} bytes')
            
            # 搜索可能的等级/经验值
            for i in range(0, len(data)-4, 4):
                val = struct.unpack('<I', data[i:i+4])[0]
                if 1 <= val <= 100:  # 可能的等级
                    print(f'  可能的等级值 @ {i}: {val}')
                if 100 <= val <= 100000:  # 可能的经验值
                    print(f'  可能的经验值 @ {i}: {val}')

print('\n完成！')
