import glob
import os

for f in glob.glob("scripts/*.sh"):
    print(f"Fixing {f}")
    with open(f, "rb") as bf:
        data = bf.read().replace(b"\r", b"")
    with open(f, "wb") as bf:
        bf.write(data)
print("Done.")
