print('验证新的经验值公式')
print('=' * 60)

print('\n新的简化公式: exp = level * 200')
print('\n升级表:')
print('-' * 40)
print(f'{"等级":<10} {"需要经验":<10} {"累积经验":<10}')
print('-' * 40)

cumulative = 0
for level in range(1, 21):
    exp_needed = level * 200
    cumulative += exp_needed
    print(f'{level:<10} {exp_needed:<10} {cumulative:<10}')

print('-' * 40)

print('\n与原版的对比:')
print('-' * 60)
print(f'{"等级":<8} {"原版经验":<10} {"新版经验":<10} {"差异":<10}')
print('-' * 60)

original = [150, 450, 600, 800, 1000, 1200, 1400, 1600, 1800, 2000, 2200]
for i, level in enumerate(range(1, 12)):
    orig = original[i] if i < len(original) else level * 200
    new = level * 200
    diff = new - orig
    print(f'{level:<8} {orig:<10} {new:<10} {diff:+<10}')

print('-' * 60)

print('\n结论:')
print('新版公式更加简单统一，每级固定增加200经验值')
print('这样玩家更容易理解和预测升级需求')
