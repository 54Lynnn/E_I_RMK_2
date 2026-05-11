print('高等级经验值表')
print('=' * 60)

print('\n公式: exp = level * 200')
print('每级固定增加200经验值\n')

print(f'{"等级":<12} {"需要经验":<12} {"累积经验":<15}')
print('-' * 45)

cumulative = 0
for level in range(1, 101):
    exp_needed = level * 200
    cumulative += exp_needed
    
    # 只显示关键等级
    if level <= 10 or level % 10 == 0:
        print(f'{level:<12} {exp_needed:<12} {cumulative:<15,}')

print('-' * 45)

print('\n关键数据:')
print(f'  升到10级需要总经验: {sum(i*200 for i in range(1, 10)):,}')
print(f'  升到50级需要总经验: {sum(i*200 for i in range(1, 50)):,}')
print(f'  升到100级需要总经验: {sum(i*200 for i in range(1, 100)):,}')

print('\n100级的情况:')
print(f'  99→100级需要: {99 * 200} 经验')
print(f'  100→101级需要: {100 * 200} 经验')
