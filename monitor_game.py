import subprocess
import time
import os
import struct

print('监控原版游戏经验值')
print('=' * 60)

# 检查存档文件
save_file = 'E:\\EvilInvasion\\Profiles\\123.ei'

if os.path.exists(save_file):
    print(f'找到存档文件: {save_file}')
    
    # 读取存档
    with open(save_file, 'rb') as f:
        data = f.read()
    
    print(f'存档大小: {len(data)} bytes')
    
    # 解析存档中的关键数据
    print('\n存档内容分析:')
    
    # 尝试解析为4字节整数
    print('\n作为4字节整数:')
    for i in range(0, len(data)-3, 4):
        val = struct.unpack('<I', data[i:i+4])[0]
        if val > 0 and val < 1000000:
            print(f'  偏移 {i:3d}: {val:8d}', end='')
            if val < 100:
                print(f' <- 可能是等级/技能点')
            elif val < 1000:
                print(f' <- 可能是属性值')
            elif val < 100000:
                print(f' <- 可能是经验值')
            else:
                print()

print('\n' + '=' * 60)
print('手动测试步骤:')
print('1. 运行原版游戏 EvilInvasion.exe')
print('2. 开始游戏并击杀1只怪物')
print('3. 记录获得的经验值')
print('4. 查看当前等级和升级所需经验')
print('5. 重复步骤2-4，记录多组数据')
print()
print('或者使用 Cheat Engine 等内存编辑工具:')
print('1. 打开 Cheat Engine')
print('2. 附加到 EvilInvasion.exe 进程')
print('3. 搜索当前经验值（精确数值）')
print('4. 击杀怪物后再次搜索新的经验值')
print('5. 找到经验值地址后，观察升级时的变化')

print('\n完成！')
