#!/bin/bash

# 簡單的 GitHub Pages 部署

flutter build web --release
cd build/web
git init
git add .
git commit -m "deploy"
git push -f git@github.com:chiamin/multiplication_practice.git HEAD:gh-pages

echo "✅ 部署完成！"
echo "🌐 https://chiamin.github.io/multiplication_practice/"

