from PIL import Image
import os

# Check all DDS files in Extracted_Textures - convert and examine
dds_dir = r'd:\project\E_I_RMK_2\Extracted_Textures'
for f in sorted(os.listdir(dds_dir)):
    if f.endswith('.dds'):
        fp = os.path.join(dds_dir, f)
        try:
            # Try to determine if these need XOR decryption
            with open(fp, 'rb') as fh:
                header = fh.read(4)
            # DDS magic = b'DDS '
            if header == b'DDS ':
                img = Image.open(fp)
                print(f'{f:40s} {img.size[0]:4}x{img.size[1]:<4} {img.mode:>5} (ALREADY VALID DDS)')
            else:
                # Try XOR decrypt
                with open(fp, 'rb') as fh:
                    raw = fh.read()
                dec = bytes([b ^ 0xA5 for b in raw])
                if dec[:4] == b'DDS ':
                    print(f'{f:40s} XOR-decrypt needed! First 20 bytes hex: {raw[:20].hex()}')
                    # Write decrypted version
                    outpath = os.path.join(dds_dir, f.replace('.dds', '_decrypted.dds'))
                    with open(outpath, 'wb') as fout:
                        fout.write(dec)
                    img = Image.open(outpath)
                    print(f'       -> Decrypted: {img.size[0]}x{img.size[1]} {img.mode}')
                else:
                    print(f'{f:40s} NOT DDS, size={len(raw)} bytes, first bytes: {raw[:20].hex()}')
        except Exception as e:
            print(f'{f:40s} ERROR: {e}')
