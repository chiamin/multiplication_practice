#!/bin/bash

# GitHub Pages 部署腳本
# 將 Flutter Web 構建結果推送到 gh-pages 分支

set -e  # 遇到錯誤立即退出

echo "🚀 開始部署到 GitHub Pages..."

# 1. 構建 Flutter Web 應用
echo "📦 正在構建 Flutter Web 應用..."
flutter build web --release

# 2. 切換到 gh-pages 分支（如果不存在則創建）
echo "🌿 切換到 gh-pages 分支..."
if git show-ref --verify --quiet refs/heads/gh-pages; then
    git checkout gh-pages
else
    git checkout --orphan gh-pages
    git rm -rf .
fi

# 3. 複製構建結果到當前目錄
echo "📋 複製構建結果..."
cp -r build/web/* .

# 4. 添加所有文件
echo "➕ 添加文件到 Git..."
git add -A

# 5. 提交更改
echo "💾 提交更改..."
git commit -m "Deploy: $(date '+%Y-%m-%d %H:%M:%S')" || echo "沒有更改需要提交"

# 6. 推送到遠程 gh-pages 分支
echo "📤 推送到 GitHub..."
git push origin gh-pages --force

# 7. 切換回 main 分支
echo "🔄 切換回 main 分支..."
git checkout main

echo "✅ 部署完成！"
echo "🌐 您的網站應該在幾分鐘後在以下地址可用："
echo "   https://chiamin.github.io/multiplication_practice/"

