import numpy as np
from PIL import Image

def remove_background(input_path: str, output_path: str, proof_path: str, tolerance: int = 25, max_colors: int = 128):
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

    # 5. 儲存去背後 PNG（先轉回 Image 物件）
    final_img = Image.fromarray(data)

    # 5-1. 顏色數量壓縮（減少檔案大小）
    # 先把透明區域填回背景色做量化，以避免邊緣產生太奇怪的色塊
    tmp_rgb = Image.new("RGB", final_img.size, tuple(bg_color.astype(int)))
    tmp_rgb.paste(final_img, mask=final_img.split()[3])  # 用 alpha 貼回前景

    # 使用 quantize 減少顏色數量（預設 256 色），大幅縮小 PNG 檔案
    quantized = tmp_rgb.quantize(colors=max_colors, method=Image.MEDIANCUT)

    # 再把 quantized 的 RGB + 原本的 alpha 合併回 RGBA
    quantized_rgba = Image.new("RGBA", final_img.size)
    quantized_rgba.paste(quantized.convert("RGBA"), mask=final_img.split()[3])

    # 儲存壓縮後 PNG（optimize + compress_level 再壓一點檔案大小）
    quantized_rgba.save(output_path, optimize=True, compress_level=9)

    # 6. 產生黃色背景的檢查圖
    yellow_bg = Image.new("RGBA", final_img.size, (255, 230, 0, 255))
    proof_img = Image.alpha_composite(yellow_bg, quantized_rgba)
    proof_img.save(proof_path)


if __name__ == "__main__":
    # 這裡改成處理 celebrate2.png
    input_file = "celebrate2.png"
    output_file = "celebrate2_transparent.png"
    proof_file = "celebrate2_proof_preview.png"

    # tolerance 可以依照實際效果調整（例如 20, 25, 30）
    remove_background(input_file, output_file, proof_file, tolerance=20)

    print(f"完成！去背後的圖片已儲存為: {output_file}")
    print(f"檢查用的黃色背景圖片已儲存為: {proof_file}")
