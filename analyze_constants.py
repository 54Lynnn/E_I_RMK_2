import struct

# 读取 Logic.dll
with open('E:\\EvilInvasion\\Logic.dll', 'rb') as f:
    data = f.read()

print('分析关键常量地址')
print('=' * 60)

# 从反汇编中发现的常量地址
constants = {
    '0x10052230': 0x00052230 - 0x10000000,  # 需要转换为文件偏移
    '0x100522BC': 0x000522BC - 0x10000000,
    '0x10053DC0': 0x00053DC0 - 0x10000000,
}

# 注意：DLL 加载基址通常是 0x10000000
# 文件偏移 = 虚拟地址 - 加载基址

print('注意：Logic.dll 的加载基址是 0x10000000')
print('文件偏移 = 虚拟地址 - 0x10000000')
print()

for name, offset in constants.items():
    if offset >= 0 and offset + 4 <= len(data):
        val = struct.unpack('<f', data[offset:offset+4])[0]
        print(f'{name} (文件偏移 0x{offset:08X}): {val}')
    else:
        print(f'{name}: 偏移超出范围')

# 也检查 0x00052230 等直接偏移
print('\n直接检查文件偏移...')
direct_offsets = [0x00052230, 0x000522BC, 0x00053DC0]
for offset in direct_offsets:
    if offset >= 0 and offset + 4 <= len(data):
        val = struct.unpack('<f', data[offset:offset+4])[0]
        int_val = struct.unpack('<I', data[offset:offset+4])[0]
        print(f'文件偏移 0x{offset:08X}: 浮点数={val}, 整数={int_val}')

# 查找函数中的其他常量
print('\n分析函数中的常量...')
# 从反汇编中看到的常量
func_constants = {
    0x0001FA24: '300.00',
    0x0001FA29: '200.00',
    0x0001FA3C: '60.00',
    0x0001FA43: '300.00',
    0x0001FA4A: '400.00',
    0x0001FA51: '150.00',
    0x0001FAE0: '120.00',
    0x0001FAE5: '60.00',
}

print('\n函数中使用的常量:')
for addr, desc in func_constants.items():
    print(f'  0x{addr:08X}: {desc}')

# 尝试理解函数逻辑
print('\n' + '=' * 60)
print('函数逻辑分析:')
print('1. 初始化对象属性 (60, 300, 400, 150)')
print('2. 进行浮点比较和条件运算')
print('3. 使用乘法 (FMUL) 和加法 (FADD)')
print('4. 最终返回计算结果')
print()
print('关键常量:')
print('  - 150.0: 可能是经验值系数')
print('  - 300.0: 可能是基础值')
print('  - 400.0: 可能是上限值')
print('  - 60.0: 可能是速度或时间相关')
print('  - 120.0: 可能是另一个系数')
print('  - 200.0: 可能是范围或距离')

print('\n' + '=' * 60)
print('经验值公式推测:')
print('基于发现的常量和运算:')
print('  可能公式1: exp = level * 150')
print('  可能公式2: exp = base + level * 150')
print('  可能公式3: exp = level * (100 + level * 50)')
print()
print('建议: 在游戏中测试这些公式')
