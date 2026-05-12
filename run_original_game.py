import subprocess
import time
import os

print('运行原版游戏 EvilInvasion.exe')
print('=' * 60)

# 检查游戏文件是否存在
if not os.path.exists('E:\\EvilInvasion\\EvilInvasion.exe'):
    print('错误：找不到 EvilInvasion.exe')
    exit(1)

print('游戏文件存在')
print('正在启动游戏...')

try:
    # 启动游戏
    process = subprocess.Popen(
        ['E:\\EvilInvasion\\EvilInvasion.exe'],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        cwd='E:\\EvilInvasion'
    )
    
    print(f'游戏已启动，PID: {process.pid}')
    print('等待游戏运行...')
    
    # 等待一段时间
    time.sleep(10)
    
    # 检查游戏是否还在运行
    if process.poll() is None:
        print('游戏正在运行')
        print('请在游戏中击杀一些怪物，观察经验值变化')
        print('游戏将在60秒后自动关闭...')
        
        # 等待60秒
        time.sleep(60)
        
        # 关闭游戏
        print('正在关闭游戏...')
        process.terminate()
        
        # 等待游戏关闭
        try:
            process.wait(timeout=5)
            print('游戏已关闭')
        except:
            print('强制关闭游戏...')
            process.kill()
    else:
        print('游戏已退出')
        stdout, stderr = process.communicate()
        if stdout:
            print(f'标准输出: {stdout.decode()}')
        if stderr:
            print(f'标准错误: {stderr.decode()}')

except Exception as e:
    print(f'运行游戏时出错: {e}')
    print('注意：服务器环境可能无法运行图形界面程序')

print('\n完成！')
