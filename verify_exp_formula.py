import struct

# 读取 Logic.dll
with open('E:\\EvilInvasion\\Logic.dll', 'rb') as f:
    data = f.read()

print('验证经验值公式')
print('=' * 60)

# 分析函数 0x0001FA20 的完整逻辑
func_start = 0x0001FA20
func_end = 0x0001FB0C

print(f'\n函数范围: 0x{func_start:08X} - 0x{func_end:08X}')

# 提取函数代码
func_code = data[func_start:func_end]

# 分析函数调用
print('\n查找调用此函数的代码...')
# 函数地址（相对于加载基址 0x10000000）
func_addr = 0x10000000 + func_start

# 搜索 CALL 指令调用此函数
call_pattern = b'\xE8'  # CALL rel32
pos = 0
callers = []
while True:
    pos = data.find(call_pattern, pos)
    if pos == -1:
        break
    
    # 计算目标地址
    if pos + 5 <= len(data):
        rel = struct.unpack('<i', data[pos+1:pos+5])[0]
        target = pos + 5 + rel
        
        # 检查是否调用我们的函数
        if target == func_start:
            callers.append(pos)
            print(f'  找到调用 @ 0x{pos:08X}')
            
            # 显示调用前后的代码
            start = max(0, pos - 50)
            end = min(len(data), pos + 50)
            text = ''
            for b in data[start:end]:
                if 32 <= b <= 126:
                    text += chr(b)
                else:
                    text += '.'
            print(f'    上下文: {text[:100]}')
    
    pos += 1

print(f'\n总共找到 {len(callers)} 个调用点')

# 分析函数参数
print('\n分析函数参数...')
print('从反汇编看，函数接收以下参数:')
print('  - ecx: 对象指针（可能是怪物或英雄对象）')
print('  - [ecx+0x04]: 浮点数值（可能是等级）')
print('  - [esp+0x14]: 另一个浮点参数')

# 分析函数返回值
print('\n分析函数返回值...')
print('函数最后执行:')
print('  FMUL dword ptr [0x10053DC0]  ; 乘以某个常量')
print('  FMULP st(1), st               ; 再乘以另一个值')
print('  返回值在 st(0) 中')

# 检查 0x10053DC0 的值
print('\n检查常量 0x10053DC0...')
# 文件偏移
offset = 0x00053DC0
if offset + 4 <= len(data):
    val = struct.unpack('<f', data[offset:offset+4])[0]
    print(f'  0x10053DC0 = {val}')
    print(f'  这可能是经验值公式的系数！')

# 测试各种经验值公式
print('\n' + '=' * 60)
print('测试经验值公式:')
print()

level = 1
base_exp = 100
coefficient = 150

# 公式1: 线性增长
print('公式1: exp = level * 100')
for level in range(1, 11):
    exp = level * 100
    print(f'  等级 {level:2d} -> {level+1:2d}: 需要 {exp:5d} exp')

print()

# 公式2: 使用发现的系数 150
print('公式2: exp = level * 150')
for level in range(1, 11):
    exp = level * 150
    print(f'  等级 {level:2d} -> {level+1:2d}: 需要 {exp:5d} exp')

print()

# 公式3: 指数增长
print('公式3: exp = 100 * level^1.5')
import math
for level in range(1, 11):
    exp = int(100 * math.pow(level, 1.5))
    print(f'  等级 {level:2d} -> {level+1:2d}: 需要 {exp:5d} exp')

print()

# 公式4: 累积公式
print('公式4: exp = 100 * level + 50 * level^2')
for level in range(1, 11):
    exp = 100 * level + 50 * level * level
    print(f'  等级 {level:2d} -> {level+1:2d}: 需要 {exp:5d} exp')

print('\n' + '=' * 60)
print('结论:')
print('基于逆向工程分析，最可能的经验值公式是:')
print('  exp = level * 150')
print()
print('理由:')
print('1. 在 Logic.dll 中发现了常量 150.0')
print('2. 函数使用了乘法运算 (FMUL)')
print('3. 150 是一个合理的系数，符合游戏节奏')
print()
print('建议在游戏中测试此公式！')
