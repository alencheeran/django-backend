import dis
import marshal
import sys

for filename in ["apps.cpython-313.pyc", "admin.cpython-313.pyc"]:
    with open(rf"c:\Users\cbijo\OneDrive\Desktop\Trading backend\users\__pycache__\{filename}", "rb") as f:
        f.read(16)
        code = marshal.load(f)
        print(f"\n--- Disassembly of {filename} ---")
        dis.dis(code)
