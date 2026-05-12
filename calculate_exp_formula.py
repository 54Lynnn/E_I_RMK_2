import math

print('从怪物数据和游戏机制推导经验值公式')
print('=' * 60)

# 怪物基础经验值（从 MonsterBalance.txt 提取）
monster_exp = {
    'Troll': 30,
    'Spider': 40,
    'Demon': 60,
    'Bear': 70,
    'Archer': 50,
    'Reaper': 80,
    'Boss': 200
}

print('\n怪物基础经验值:')
for name, exp in monster_exp.items():
    print(f'  {name}: {exp}')

# 计算平均经验值
avg_exp = sum(monster_exp.values()) / len(monster_exp)
print(f'\n平均经验值: {avg_exp:.1f}')

# 游戏手册信息：
# - 英雄升级获得 5 属性点 + 1 技能点
# - 属性上限 100，技能上限 10
# - 假设英雄最终等级约为 20-30 级（根据属性点推算）
# - 如果每级5点属性，要达到100属性需要20级
# - 但通常游戏会设计为 20-30 级通关

print('\n推导升级经验公式...')
print('假设条件:')
print('  - 英雄平均需要 20-25 级通关')
print('  - 每级需要击杀 5-10 只怪物')
print('  - 平均经验值约为 65')

# 测试不同的公式
print('\n测试公式:')

# 公式1: 线性增长
print('\n1. 线性公式: exp = base * level')
for base in [50, 100, 150, 200]:
    total = sum(base * i for i in range(1, 21))
    print(f'   base={base}: 1-20级总经验={total}')

# 公式2: 指数增长
print('\n2. 指数公式: exp = base * level^power')
for base in [50, 100]:
    for power in [1.5, 2.0]:
        total = sum(int(base * math.pow(i, power)) for i in range(1, 21))
        print(f'   base={base}, power={power}: 1-20级总经验={total}')

# 公式3: 累积公式
print('\n3. 累积公式: exp = base * (level + previous_levels)')
for base in [50, 100, 150]:
    total = 0
    cumulative = 0
    for level in range(1, 21):
        needed = base * level
        cumulative += needed
        total += needed
    print(f'   base={base}: 1-20级总经验={total}')

# 公式4: 基于怪物击杀数
print('\n4. 基于击杀数的公式:')
print('   如果每级需要击杀 5-10 只怪物:')
for kills_per_level in [5, 8, 10]:
    exp_per_level = int(avg_exp * kills_per_level)
    total = sum(exp_per_level * i for i in range(1, 21))
    print(f'   每级{kills_per_level}只怪物: 每级经验={exp_per_level}, 1-20级总经验={total}')

# 推荐公式
print('\n' + '=' * 60)
print('推荐公式（基于分析）:')
print('  当前代码使用: hero_level * 100')
print('  这意味着:')
print('    1级升2级: 100 exp')
print('    2级升3级: 200 exp')
print('    5级升6级: 500 exp')
print('    10级升11级: 1000 exp')
print('    20级升21级: 2000 exp')
print('\n  根据怪物数据:')
print('    击杀1只Troll获得 30 exp')
print('    击杀1只Boss获得 200 exp')
print('    1级升2级需要击杀约 3-4 只普通怪物')
print('    这个节奏看起来合理！')

print('\n' + '=' * 60)
print('结论:')
print('  当前公式 hero_level * 100 是一个合理的起点')
print('  但为了更接近原版游戏，建议调整为 hero_level * 150 或 200')
print('  这样升级会稍微慢一些，更符合原版游戏的节奏')
