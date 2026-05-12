import struct, re

dll_path = r'e:\EvilInvasion\Logic.dll'
with open(dll_path, 'rb') as f:
    data = f.read()

# The HeroBalance.txt format is determined by the code that parses it
# Let me find ALL the attribute field names by looking at the string table
# around the area where _ON_HEALTH, START_VALUE, COEFF are found

# First, dump ALL strings in the .rdata section where these strings are
# We know HeroBalance.txt is at 0x55034
# The field names should be nearby

print('=== Complete string dump around HeroBalance parsing code ===')
hb_pos = data.find(b'HeroBalance.txt')
start = max(0, hb_pos - 300)
end = min(len(data), hb_pos + 300)

# Extract all null-terminated strings in this region
strings = []
pos = start
while pos < end:
    # Check if this is start of a readable string
    if 32 <= data[pos] <= 126:
        str_end = data.find(b'\x00', pos)
        if str_end >= 0 and str_end - pos >= 3 and str_end - pos <= 60:
            s = data[pos:str_end].decode('ascii', errors='replace')
            strings.append((pos, s))
            pos = str_end
    pos += 1

for p, s in sorted(strings):
    print(f'  0x{p:x}: "{s}"')

print('\n\n=== ALL Hero Balance parameters ===')
# The game code references specific parameter names 
# Let me search for _ATTR patterns that look like balance config keys
attrs = set()
pos = 0
while True:
    pos = data.find(b'_', pos)
    if pos < 0 or pos > 0x70000:
        break
    # Check if it's an attribute name (all caps with underscores)
    if pos > 0 and data[pos-1] == 0:
        str_end = data.find(b'\x00', pos)
        if str_end >= 0 and str_end - pos >= 4 and str_end - pos <= 40:
            s = data[pos:str_end].decode('ascii', errors='replace')
            if s.isupper() and '_' in s:
                attrs.add(s)
    pos += 1

print(f'Found {len(attrs)} attribute keys:')
for a in sorted(attrs):
    print(f'  {a}')

# Also look for the actual format string used for reading
# "starting %s" pattern suggests how values are read
print('\n=== Looking for scanf/sscanf format strings ===')
for i in range(len(data) - 12):
    if data[i:i+2] == b'%s' or data[i:i+2] == b'%d' or data[i:i+2] == b'%f':
        end = data.find(b'\x00', max(0, i-10))
        if end < 0 or end > i + 30:
            continue
        # Check the area before for interesting context
        start_ctx = max(0, i - 40)
        context = b''
        for j in range(start_ctx, min(len(data), i + 20)):
            if 32 <= data[j] <= 126:
                context += bytes([data[j]])
            elif data[j] == 0:
                context += b'.'
            else:
                context += b'.'
        name = context.decode('ascii', errors='replace')
        if any(kw in name for kw in ['Balance', 'balance', 'stat', 'hero', 'monster', 'spell']):
            print(f'  0x{i:x}: {name}')
