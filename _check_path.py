import struct
import re

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
        text = bytes([b ^ 0xA5 for b in raw]).decode('ascii', errors='replace')
        
        # Show lines with "Units" 
        for line in text.split('\n'):
            if 'Units\\Hero' in line or 'Units/Hero' in line:
                print(repr(line[:200]))
            if 'Units' in line and 'Hero' not in line:
                # Show first few monster entries
                pass
        
        # Count all unit entries
        unit_count = 0
        for line in text.split('\n'):
            if '"Units' in line:
                unit_count += 1
        
        print(f'\nTotal lines with "Units": {unit_count}')
        break
