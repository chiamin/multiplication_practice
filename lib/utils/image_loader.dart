import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 圖片載入輔助類
/// 
/// 在 Web 平台上使用 Image.network 載入圖片（支援 GitHub Pages）
/// 在其他平台上使用 Image.asset 載入本地資源
class ImageLoader {
  /// 獲取圖標的 URL 路徑
  /// 
  /// [assetPath] 例如 'icons/add.png' 或 'pictures/rabbits.png'
  /// 返回完整的路徑，例如 'assets/icons/add.png'
  /// 
  /// 在 Web 平台上使用相對路徑，這樣可以支援 GitHub Pages 部署
  /// （配合 Flutter 的 base-href 設定）
  static String getImageUrl(String assetPath) {
    // 在 Web 平台上，使用相對路徑（不帶前導斜線）
    // 這樣可以配合 Flutter 的 base-href 正常工作
    if (kIsWeb) {
      // 移除前導斜線（如果有），然後構建相對路徑
      final cleanPath = assetPath.startsWith('/') 
          ? assetPath.substring(1) 
          : assetPath;
      return 'assets/$cleanPath';
    }
    // 非 Web 平台使用 asset 路徑
    return 'assets/$assetPath';
  }

  /// 載入圖標（Icons）
  /// 
  /// 自動處理 Web 和其他平台的差異
  static Widget loadIcon({
    required String iconName,
    double? width,
    double? height,
    BoxFit? fit,
    Widget? errorWidget,
  }) {
    final String imagePath = 'icons/$iconName';
    
    if (kIsWeb) {
      return Image.network(
        getImageUrl(imagePath),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorWidget != null
            ? (context, error, stackTrace) => errorWidget
            : (context, error, stackTrace) => Icon(
                Icons.error,
                size: width ?? height ?? 24,
                color: Colors.red,
              ),
      );
    } else {
      return Image.asset(
        getImageUrl(imagePath),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorWidget != null
            ? (context, error, stackTrace) => errorWidget
            : (context, error, stackTrace) => Icon(
                Icons.error,
                size: width ?? height ?? 24,
                color: Colors.red,
              ),
      );
    }
  }

  /// 載入圖片（Pictures）
  /// 
  /// 自動處理 Web 和其他平台的差異
  static Widget loadPicture({
    required String pictureName,
    double? width,
    double? height,
    BoxFit? fit,
    Widget? errorWidget,
  }) {
    final String imagePath = 'pictures/$pictureName';
    
    if (kIsWeb) {
      return Image.network(
        getImageUrl(imagePath),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorWidget != null
            ? (context, error, stackTrace) => errorWidget
            : (context, error, stackTrace) => Icon(
                Icons.error,
                size: width ?? height ?? 24,
                color: Colors.red,
              ),
      );
    } else {
      return Image.asset(
        getImageUrl(imagePath),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorWidget != null
            ? (context, error, stackTrace) => errorWidget
            : (context, error, stackTrace) => Icon(
                Icons.error,
                size: width ?? height ?? 24,
                color: Colors.red,
              ),
      );
    }
  }
}

