import struct
from PIL import Image

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

    # Extract Scrap metadata
    if 'Textures\\Scrap' in filename and 'Alpha' not in filename and 'jpg' not in filename:
        raw = data[file_offset:file_offset+file_size]
        dec = bytes([b ^ 0xA5 for b in raw])
        text = dec.decode('ascii', errors='replace')
        parts = [p.strip() for p in text.split(';') if p.strip()]
        print('Scrap rect count:', len(parts) // 4)
        rects = []
        for j in range(0, len(parts)-3, 4):
            try:
                x, y, w, h = int(parts[j]), int(parts[j+1]), int(parts[j+2]), int(parts[j+3])
                rects.append((x, y, w, h))
            except:
                break
        print('Total valid rects:', len(rects))
        # Print first 30 rects
        for j, (x, y, w, h) in enumerate(rects[:30]):
            print(f'  [{j:3d}] ({x:4d}, {y:4d}) {w:4d}x{h:4d}')
        print('  ...')
        # Print last 10 rects
        for j, (x, y, w, h) in enumerate(rects[-10:]):
            idx = len(rects) - 10 + j
            print(f'  [{idx:3d}] ({x:4d}, {y:4d}) {w:4d}x{h:4d}')
        
        # Open the scrap sheet and try to extract some regions
        img = Image.open(r'd:\project\E_I_RMK_2\Extracted_Textures\scrap_sheet.jpg')
        for j, (x, y, w, h) in enumerate(rects[:50]):
            if w > 0 and h > 0 and x + w <= 2048 and y + h <= 2048:
                crop = img.crop((x, y, x+w, y+h))
                name = f'region_{j}_{w}x{h}.png'
                crop.save(r'd:\project\E_I_RMK_2\Extracted_Textures\\' + name)
        
        print('\nAll regions saved as region_N_WxH.png')
        break
