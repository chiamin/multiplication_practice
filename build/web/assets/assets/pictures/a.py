import numpy as np
from PIL import Image

def remove_background(input_path: str, output_path: str, tolerance: int = 25):
    """
    將圖片背景變透明，只針對「接近背景顏色」的像素做處理，不會把前景顏色去掉。

    參數：
    - input_path: 原始 PNG 檔名（含路徑）
    - output_path: 去背後 PNG 檔名（含路徑）
    - tolerance: 容許顏色差距 (0~255)，數字越大，去背範圍越廣
    """
    # 1. 讀取圖片（確保有 Alpha 通道）
    img = Image.open(input_path).convert("RGBA")
    data = np.array(img)

    # 2. 從四個角落估計「背景顏色」
    h, w, _ = data.shape
    corner_pixels = np.vstack([
        data[0, 0, :3],          # 左上
        data[0, w - 1, :3],      # 右上
        data[h - 1, 0, :3],      # 左下
        data[h - 1, w - 1, :3],  # 右下
    ])
    bg_color = corner_pixels.mean(axis=0)  # 取平均當作背景顏色 (R,G,B)

    # 3. 計算每個像素與背景色的距離（在 RGB 空間）
    rgb = data[:, :, :3].astype(np.float32)
    diff = np.linalg.norm(rgb - bg_color, axis=2)  # 每個像素與背景色的距離

    # 4. 建立遮罩：距離小於 tolerance 的視為背景 → 變透明
    bg_mask = diff < tolerance
    data[:, :, 3][bg_mask] = 0  # Alpha 設為 0（透明）

    # 5. 儲存去背後 PNG
    final_img = Image.fromarray(data)
    final_img.save(output_path)


if __name__ == "__main__":
    # 這裡改成處理 celebrate2.png
    input_file = "celebrate2.png"
    output_file = "celebrate2_transparent.png"

    # tolerance 可以依照實際效果調整（例如 20, 25, 30）
    remove_background(input_file, output_file, tolerance=25)

    print(f"完成！去背後的圖片已儲存為: {output_file}")
