import struct

# 读取 Logic.dll
with open('E:\\EvilInvasion\\Logic.dll', 'rb') as f:
    data = f.read()

print('分析经验值相关函数')
print('=' * 60)

# 分析 0x0001FA54 周围的函数
func_start = 0x0001F98C
func_end = 0x0001FB0C

print(f'\n函数范围: 0x{func_start:08X} - 0x{func_end:08X}')
print(f'函数大小: {func_end - func_start} bytes')

# 提取函数代码
func_code = data[func_start:func_end]

# 显示反汇编（简化版）
print('\n反汇编代码:')
offset = 0
while offset < len(func_code):
    # 读取指令字节
    if offset + 1 <= len(func_code):
        opcode = func_code[offset]
        
        # 简单的 x86 指令识别
        if opcode == 0xD9:
            # FLD, FST, FSTP 等浮点指令
            if offset + 1 < len(func_code):
                modrm = func_code[offset + 1]
                if modrm == 0x05:
                    # FLD dword ptr [mem]
                    if offset + 5 < len(func_code):
                        addr = struct.unpack('<I', func_code[offset+2:offset+6])[0]
                        print(f'  0x{func_start+offset:08X}: FLD dword ptr [0x{addr:08X}]')
                        offset += 6
                        continue
                elif modrm == 0x41:
                    # FLD dword ptr [ecx+xx]
                    if offset + 2 < len(func_code):
                        disp = func_code[offset + 2]
                        print(f'  0x{func_start+offset:08X}: FLD dword ptr [ecx+0x{disp:02X}]')
                        offset += 3
                        continue
                elif modrm == 0x44:
                    # FLD dword ptr [esp+xx]
                    if offset + 3 < len(func_code):
                        disp = func_code[offset + 3]
                        print(f'  0x{func_start+offset:08X}: FLD dword ptr [esp+0x{disp:02X}]')
                        offset += 4
                        continue
        
        elif opcode == 0xD8:
            # FADD, FMUL, FSUB 等浮点运算
            if offset + 1 < len(func_code):
                modrm = func_code[offset + 1]
                if modrm == 0x05:
                    # FADD dword ptr [mem]
                    if offset + 5 < len(func_code):
                        addr = struct.unpack('<I', func_code[offset+2:offset+6])[0]
                        print(f'  0x{func_start+offset:08X}: FADD dword ptr [0x{addr:08X}]')
                        offset += 6
                        continue
                elif modrm == 0x0D:
                    # FMUL dword ptr [mem]
                    if offset + 5 < len(func_code):
                        addr = struct.unpack('<I', func_code[offset+2:offset+6])[0]
                        print(f'  0x{func_start+offset:08X}: FMUL dword ptr [0x{addr:08X}]')
                        offset += 6
                        continue
                elif modrm == 0x4E:
                    # FMUL dword ptr [esi+xx]
                    if offset + 2 < len(func_code):
                        disp = func_code[offset + 2]
                        print(f'  0x{func_start+offset:08X}: FMUL dword ptr [esi+0x{disp:02X}]')
                        offset += 3
                        continue
        
        elif opcode == 0xDE:
            # FADDP, FMULP 等
            if offset + 1 < len(func_code):
                modrm = func_code[offset + 1]
                if modrm == 0xC9:
                    print(f'  0x{func_start+offset:08X}: FMULP st(1), st')
                    offset += 2
                    continue
                elif modrm == 0xC1:
                    print(f'  0x{func_start+offset:08X}: FADDP st(1), st')
                    offset += 2
                    continue
        
        elif opcode == 0xDD:
            # FSTP 等
            if offset + 1 < len(func_code):
                modrm = func_code[offset + 1]
                if modrm == 0xD8:
                    print(f'  0x{func_start+offset:08X}: FSTP st')
                    offset += 2
                    continue
        
        elif opcode == 0xDF:
            # FISTP 等
            if offset + 1 < len(func_code):
                modrm = func_code[offset + 1]
                if modrm == 0xE0:
                    print(f'  0x{func_start+offset:08X}: FSTSW ax')
                    offset += 2
                    continue
        
        elif opcode == 0xDA:
            # FCMOVB 等
            if offset + 1 < len(func_code):
                modrm = func_code[offset + 1]
                if modrm == 0xE9:
                    print(f'  0x{func_start+offset:08X}: FUCOMPP')
                    offset += 2
                    continue
        
        elif opcode == 0xF6:
            # TEST
            if offset + 1 < len(func_code):
                modrm = func_code[offset + 1]
                if modrm == 0xC4:
                    if offset + 2 < len(func_code):
                        imm = func_code[offset + 2]
                        print(f'  0x{func_start+offset:08X}: TEST ah, 0x{imm:02X}')
                        offset += 3
                        continue
        
        elif opcode == 0x7A:
            # JP (跳转)
            if offset + 1 < len(func_code):
                rel = struct.unpack('<b', func_code[offset+1:offset+2])[0]
                target = func_start + offset + 2 + rel
                print(f'  0x{func_start+offset:08X}: JP 0x{target:08X}')
                offset += 2
                continue
        
        elif opcode == 0x7B:
            # JNP (跳转)
            if offset + 1 < len(func_code):
                rel = struct.unpack('<b', func_code[offset+1:offset+2])[0]
                target = func_start + offset + 2 + rel
                print(f'  0x{func_start+offset:08X}: JNP 0x{target:08X}')
                offset += 2
                continue
        
        elif opcode == 0xEB:
            # JMP short
            if offset + 1 < len(func_code):
                rel = struct.unpack('<b', func_code[offset+1:offset+2])[0]
                target = func_start + offset + 2 + rel
                print(f'  0x{func_start+offset:08X}: JMP 0x{target:08X}')
                offset += 2
                continue
        
        elif opcode == 0x68:
            # PUSH imm32
            if offset + 4 < len(func_code):
                imm = struct.unpack('<I', func_code[offset+1:offset+5])[0]
                # 检查是否是浮点数
                f_val = struct.unpack('<f', func_code[offset+1:offset+5])[0]
                if 0.1 < f_val < 1000:
                    print(f'  0x{func_start+offset:08X}: PUSH {f_val:.2f} (浮点数)')
                else:
                    print(f'  0x{func_start+offset:08X}: PUSH 0x{imm:08X} ({imm})')
                offset += 5
                continue
        
        elif opcode == 0xC7:
            # MOV dword ptr [mem], imm32
            if offset + 1 < len(func_code):
                modrm = func_code[offset + 1]
                if modrm == 0x46:
                    # MOV dword ptr [esi+xx], imm32
                    if offset + 6 < len(func_code):
                        disp = func_code[offset + 2]
                        imm = struct.unpack('<I', func_code[offset+3:offset+7])[0]
                        f_val = struct.unpack('<f', func_code[offset+3:offset+7])[0]
                        if 0.1 < f_val < 1000:
                            print(f'  0x{func_start+offset:08X}: MOV dword ptr [esi+0x{disp:02X}], {f_val:.2f}')
                        else:
                            print(f'  0x{func_start+offset:08X}: MOV dword ptr [esi+0x{disp:02X}], 0x{imm:08X}')
                        offset += 7
                        continue
        
        elif opcode == 0xE8:
            # CALL rel32
            if offset + 4 < len(func_code):
                rel = struct.unpack('<i', func_code[offset+1:offset+5])[0]
                target = func_start + offset + 5 + rel
                print(f'  0x{func_start+offset:08X}: CALL 0x{target:08X}')
                offset += 5
                continue
        
        # 默认：显示字节
        print(f'  0x{func_start+offset:08X}: DB 0x{opcode:02X}')
        offset += 1

print('\n' + '=' * 60)
print('分析结论:')
print('这个函数使用了浮点运算，可能涉及经验值计算')
print('发现了 150.0 和 200.0 等浮点数常量')
print('建议进一步分析调用此函数的代码')
