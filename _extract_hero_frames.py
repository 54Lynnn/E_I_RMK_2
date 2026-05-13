import struct
import re
from PIL import Image
import io

with open(r'd:\project\E_I_RMK_2\Data.pak', 'rb') as f:
    data = f.read()

file_count = struct.unpack('<I', data[8:12])[0]
offset = 12
scrap_text = None
scrap_jpg_data = None

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
        scrap_text = bytes([b ^ 0xA5 for b in raw]).decode('ascii', errors='replace')
    
    if 'Textures\\Scrap.jpg' in filename:
        raw = data[file_offset:file_offset+file_size]
        scrap_jpg_data = bytes([b ^ 0xA5 for b in raw])

scrap_img = Image.open(io.BytesIO(scrap_jpg_data))
print(f'Scrap image: {scrap_img.size}')

# Parse entries with format: "path"; u; v; w; h;
entries = []
for match in re.finditer(r'"([^"]+\.(?:png|dds|jpg))"\s*;\s*([0-9.]+)\s*;\s*([0-9.]+)\s*;\s*([0-9.]+)\s*;\s*([0-9.]+)\s*;', scrap_text):
    fname = match.group(1)
    u = float(match.group(2))
    v = float(match.group(3))
    w = float(match.group(4))
    h = float(match.group(5))
    entries.append((fname, u, v, w, h))

print(f'Total entries: {len(entries)}')

# Extract all unit types
unit_types = ['Hero', 'Troll', 'Spider', 'Demon', 'Bear', 'Mummy', 'Reaper', 'Diablo']

output_dir = r'd:\project\E_I_RMK_2\Extracted_Textures\unit_frames'
import os
os.makedirs(output_dir, exist_ok=True)

for unit in unit_types:
    unit_entries = [e for e in entries if ('Units\\' + unit + '\\') in e[0] or ('Units/' + unit + '/') in e[0]]
    print(f'\n=== {unit}: {len(unit_entries)} frames ===')
    
    for fname, u, v, w, h in sorted(unit_entries):
        px = int(u * 2048)
        py = int(v * 2048)
        pw = int(w * 2048)
        ph = int(h * 2048)
        
        if pw > 0 and ph > 0 and px + pw <= 2048 and py + ph <= 2048:
            crop = scrap_img.crop((px, py, px+pw, py+ph))
            # Clean filename
            clean_name = fname.replace('\\', '_').replace('/', '_').replace('.png', '')
            outpath = os.path.join(output_dir, clean_name + '.png')
            crop.save(outpath)
    
    # Print first few entries to show structure
    for fname, u, v, w, h in sorted(unit_entries)[:5]:
        px = int(u * 2048)
        py = int(v * 2048)
        print(f'  {fname:45s} -> ({px:4d}, {py:4d})')
    if len(unit_entries) > 5:
        print(f'  ... ({len(unit_entries) - 5} more)')

print(f'\nAll unit frames saved to: {output_dir}')
print('\nDone!')
