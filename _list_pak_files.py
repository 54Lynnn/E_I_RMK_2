import struct

with open(r'd:\project\E_I_RMK_2\Data.pak', 'rb') as f:
    data = f.read()

file_count = struct.unpack('<I', data[8:12])[0]
offset = 12
files = []
for i in range(file_count):
    try:
        name_len = struct.unpack('<I', data[offset:offset+4])[0]
        offset += 4
        filename = data[offset:offset+name_len].decode('ascii', errors='replace')
        offset += name_len
        file_offset = struct.unpack('<I', data[offset:offset+4])[0]
        offset += 4
        file_size = struct.unpack('<I', data[offset:offset+4])[0]
        offset += 4
        files.append({'name': filename, 'offset': file_offset, 'size': file_size, 'i': i})
    except:
        break

# Print files 0 to 47 (textures+scripts)
for f in files:
    if f['i'] >= 47:
        break
    name = f['name']
    ext = name.split('.')[-1] if '.' in name else 'N/E'
    print('%3d: %-55s %6d bytes [%s]' % (f['i'], name[:55], f['size'], ext))
