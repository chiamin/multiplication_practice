#!/bin/bash

# GitHub Pages 部署腳本（改進版）
# 使用 git subtree 方式，保持歷史記錄乾淨

set -e  # 遇到錯誤立即退出

echo "🚀 開始部署到 GitHub Pages..."

# 1. 清理並獲取依賴
echo "🧹 清理舊構建..."
flutter clean
flutter pub get

# 2. 構建 Flutter Web 應用（使用 base-href 以支援 GitHub Pages）
echo "📦 正在構建 Flutter Web 應用..."
flutter build web --release --base-href /multiplication_practice/ --web-renderer html

# 3. 移除 service worker（避免緩存問題）
echo "🗑️  移除 service worker..."
rm -f build/web/flutter_service_worker.js

# 4. 提交源代碼更改（如果有）
echo "💾 提交源代碼更改..."
git add .
if ! git diff --staged --quiet; then
    git commit -m "Update source code"
    git push origin main
fi

# 5. 使用 git subtree 推送到 gh-pages 分支
echo "📤 部署到 gh-pages 分支..."
git add -f build/web
if ! git diff --staged --quiet; then
    git commit -m "Deploy latest version - $(date '+%Y-%m-%d %H:%M:%S')"
fi

# 使用 subtree split 方式推送到 gh-pages
git subtree split --prefix=build/web -b gh-pages-temp
git push origin gh-pages-temp:gh-pages --force
git branch -D gh-pages-temp

echo "✅ 部署完成！"
echo "🌐 您的網站應該在幾分鐘後在以下地址可用："
echo "   https://chiamin.github.io/multiplication_practice/"

