import numpy as np
from PIL import Image, ImageOps

# 1. 讀取原始圖片
image_path = "celebrate.png"
img = Image.open(image_path).convert("RGBA")
data = np.array(img)

# 2. 強力去背邏輯 (Threshold)
# 轉灰階
gray = np.mean(data[:, :, :3], axis=2)

# 設定嚴格的門檻：只有亮度小於 140 (接近黑色) 的像素才保留
# 灰白格子通常亮度都在 200 以上，這樣可以確保它們被刪掉
threshold = 140

# 建立遮罩：黑色線條保留 (255)，其他全變透明 (0)
alpha = np.where(gray < threshold, 255, 0).astype(np.uint8)

# 為了線條好看，將保留下來的像素全部設為「純黑」
data[:, :, 0] = 0
data[:, :, 1] = 0
data[:, :, 2] = 0
data[:, :, 3] = alpha

# 建立最終的透明 PNG
final_transparent_img = Image.fromarray(data)
final_output_path = "celebrate_final_clean.png"
final_transparent_img.save(final_output_path)

# 3. 製作驗證圖 (Proof)
# 建立一個黃色的背景
yellow_bg = Image.new("RGBA", final_transparent_img.size, (255, 230, 0, 255))
# 把去背後的圖貼上去
proof_img = Image.alpha_composite(yellow_bg, final_transparent_img)
proof_output_path = "celebrate_proof_preview.png"
proof_img.save(proof_output_path)

print(f"Clean PNG saved to: {final_output_path}")
print(f"Proof image saved to: {proof_output_path}")
