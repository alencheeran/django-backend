import dis
import marshal

with open(r"c:\Users\cbijo\OneDrive\Desktop\Trading backend\users\__pycache__\models.cpython-313.pyc", "rb") as f:
    f.read(16) # Skip the magic and timestamp
    code = marshal.load(f)
    print("Disassembly of code:")
    dis.dis(code)
