# multiplication_practice

# 算術練習應用 (Multiplication Practice)

一個用 Flutter 開發的算術練習應用，支援加法、減法、乘法和除法練習。

## 🌐 線上版本

**GitHub Pages 部署地址**：https://chiamin.github.io/multiplication_practice/

> ⚠️ **注意**：如果網頁無法打開，請檢查：
> 1. GitHub Pages 是否已啟用（Settings > Pages > Source 選擇 `gh-pages` 分支）
> 2. 等待幾分鐘讓 GitHub 完成部署
> 3. 清除瀏覽器快取後重新載入

## 📱 功能特色

- ✅ 支援四則運算（加、減、乘、除）
- ✅ 可自訂數字範圍
- ✅ 可選擇練習題數（5、10、15、20、30 題）
- ✅ 手寫板功能
- ✅ 完成一組題目後顯示慶祝動畫
- ✅ 音效回饋
- ✅ 響應式設計（支援手機和平板）

## 🚀 本地運行

```bash
# 安裝依賴
flutter pub get

# 運行應用
flutter run -d chrome  # Web
flutter run -d linux   # Linux 桌面
```

## 📦 部署到 GitHub Pages

使用提供的部署腳本：

```bash
chmod +x update_git
./update_git
```

部署腳本會：
1. 清理舊構建
2. 構建 Flutter Web 應用（使用正確的 base-href）
3. 推送到 `gh-pages` 分支
4. 自動更新源代碼到 `main` 分支

## 🧪 測試

```bash
# 運行所有測試
flutter test

# 運行特定測試
flutter test test/rabbits_celebration_test.dart
```

## 📝 專案結構

```
lib/
├── main.dart                          # 應用入口
├── models/
│   └── operation.dart                 # 運算類型定義
├── pages/
│   └── multiplication_practice_page.dart  # 主頁面
├── utils/
│   ├── image_loader.dart              # 圖片載入工具（支援 Web）
│   └── question_generator.dart       # 題目生成器
└── widgets/
    ├── handwriting_painter.dart       # 手寫板繪製器
    └── rabbits_celebration.dart        # 慶祝動畫組件
```

## 🐛 已知問題修復

- ✅ 修復完成一組題目後動畫不顯示的問題
  - 使用 `ImageLoader.loadPicture` 替代 `Image.asset` 以支援 Web 平台
  - 優化 Dialog 顯示時機

## 📄 授權

此專案為個人學習專案。

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
