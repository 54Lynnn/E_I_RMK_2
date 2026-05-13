import struct

with open(r'd:\project\E_I_RMK_2\Data.pak', 'rb') as f:
    data = f.read()

file_count = struct.unpack('<I', data[8:12])[0]
offset = 12
for i in range(file_count):
    name_len = struct.unpack('<I', data[offset:offset+4])[0]
    offset += 4
    raw_name = data[offset:offset+name_len]
    filename = raw_name.decode('ascii', errors='replace')
    offset += name_len
    file_offset = struct.unpack('<I', data[offset:offset+4])[0]
    offset += 4
    file_size = struct.unpack('<I', data[offset:offset+4])[0]
    offset += 4

    if 'Textures\\Scrap' in filename and 'Alpha' not in filename and 'jpg' not in filename:
        raw = data[file_offset:file_offset+file_size]
        dec = bytes([b ^ 0xA5 for b in raw])
        text = dec.decode('ascii', errors='replace')
        
        # Split and look for texture references
        parts = text.split(';')
        
        print('=== Searching for Hero/Player related entries ===')
        print()
        hero_matches = []
        for j, p in enumerate(parts):
            p = p.strip()
            if 'Hero' in p or 'hero' in p or 'Player' in p or 'player' in p:
                # Get surrounding context (4 parts before and after)
                ctx_start = max(0, j-2)
                ctx_end = min(len(parts), j+5)
                context = parts[ctx_start:ctx_end]
                hero_matches.append((j, p, context))
        
        for idx, match, ctx in hero_matches:
            print(f'  Position {idx}: "{match}"')
            print(f'  Context: {ctx}')
            print()
        
        if not hero_matches:
            print('  No Hero/Player references found.')
        
        print()
        print('=== All unique texture paths referenced ===')
        texture_paths = set()
        for p in parts:
            p = p.strip()
            if p.startswith('"') and ('Pictures' in p or '.dds' in p or '.jpg' in p):
                texture_paths.add(p.strip('"'))
        for tp in sorted(texture_paths)[:40]:
            print(f'  {tp}')
        print(f'  ... and {max(0, len(texture_paths)-40)} more')
        print(f'  Total unique texture paths: {len(texture_paths)}')
        break
