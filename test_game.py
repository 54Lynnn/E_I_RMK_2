import subprocess
import time
import os

# 尝试运行原版游戏
print('尝试运行原版游戏 EvilInvasion.exe...')
print('注意：游戏可能需要图形界面，在服务器环境中可能无法运行')

try:
    # 尝试运行游戏
    process = subprocess.Popen(
        ['E:\\EvilInvasion\\EvilInvasion.exe'],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        cwd='E:\\EvilInvasion'
    )
    
    # 等待几秒钟
    print('游戏已启动，等待5秒...')
    time.sleep(5)
    
    # 检查游戏是否还在运行
    if process.poll() is None:
        print('游戏正在运行')
        # 终止游戏
        process.terminate()
        print('已终止游戏')
    else:
        print('游戏已退出')
        stdout, stderr = process.communicate()
        if stdout:
            print(f'标准输出: {stdout.decode()}')
        if stderr:
            print(f'标准错误: {stderr.decode()}')
            
except Exception as e:
    print(f'运行游戏时出错: {e}')
    print('这是正常的，因为服务器环境可能没有图形界面')

# 检查是否有新的日志文件生成
print('\n检查日志文件...')
log_files = ['stdout.txt', 'stderr.txt']
for log_file in log_files:
    if os.path.exists(log_file):
        print(f'\n{log_file}:')
        with open(log_file, 'r') as f:
            content = f.read()
            print(content[:500])
