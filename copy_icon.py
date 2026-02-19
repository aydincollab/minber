import shutil
import os

src = r"C:\Users\Aydin\.gemini\antigravity\brain\2c582a4c-442e-4455-8c1b-e8b458d07091\media__1771518814364.jpg"
dst = r"C:\Users\Aydin\minber\flutter_app\assets\images\icon.png"

os.makedirs(os.path.dirname(dst), exist_ok=True)
shutil.copy2(src, dst)
print(f"Copied {src} to {dst}")
