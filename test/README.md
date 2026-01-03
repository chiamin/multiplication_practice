# 測試文件說明

本目錄包含完整的單元測試，測試核心邏輯獨立於 UI 實現。

## 測試結構

### 1. `question_generator_test.dart`
測試題目生成器的所有功能：
- **基本功能測試**：亂數生成、範圍處理
- **加法測試**：基本範圍、大範圍、邊界值
- **減法測試**：確保 a >= b、範圍處理、邊界情況
- **乘法測試**：基本範圍、大範圍
- **除法測試**：基本範圍、用戶報告的問題範圍 (50-99, 1-4)、小範圍、邊界情況
- **統一接口測試**：測試所有運算類型的統一接口
- **可重現性測試**：使用固定種子確保可重現性

### 2. `answer_checker_test.dart`
測試答案檢查器的所有功能：
- **基本運算測試**：加法、減法、乘法、除法的正確答案計算
- **答案檢查測試**：正確答案和錯誤答案的檢查
- **除法答案檢查測試**：商和餘數的驗證、錯誤處理
- **邊界情況測試**：大數字、零值、負數結果
- **整合測試**：完整的生成題目 -> 計算答案 -> 檢查答案流程

### 3. `range_validation_test.dart`
測試範圍驗證的嚴格性：
- **所有運算都遵守範圍**：加法、減法、乘法、除法的嚴格範圍驗證
- **邊界情況測試**：單一值範圍、範圍反轉、極小範圍、極大範圍
- **特殊情況測試**：範圍衝突的處理
- **一致性測試**：多次生成應該都在範圍內

## 核心邏輯類

### `QuestionGenerator`
位於 `lib/utils/question_generator.dart`，提供：
- `randomNumberInRange()`: 從範圍中產生亂數
- `generateAddition()`: 生成加法題目
- `generateSubtraction()`: 生成減法題目（確保 a >= b）
- `generateMultiplication()`: 生成乘法題目
- `generateDivision()`: 生成除法題目（可以有餘數）
- `generateQuestion()`: 統一的題目生成接口

### `AnswerChecker`
位於 `lib/utils/question_generator.dart`，提供：
- `calculateCorrectAnswer()`: 計算正確答案（加法、減法、乘法）
- `checkDivisionAnswer()`: 檢查除法答案（商和餘數）
- `checkAnswer()`: 檢查答案（非除法）

## 運行測試

### 運行所有測試
```bash
flutter test
```

### 運行特定測試文件
```bash
flutter test test/question_generator_test.dart
flutter test test/answer_checker_test.dart
flutter test test/range_validation_test.dart
```

### 運行特定測試組
```bash
flutter test --name "QuestionGenerator - 加法測試"
flutter test --name "AnswerChecker - 除法答案檢查測試"
```

### 查看測試覆蓋率
```bash
flutter test --coverage
```

## 測試特點

1. **獨立於 UI**：所有測試都針對核心邏輯類，不依賴 Flutter widget
2. **詳細覆蓋**：涵蓋正常情況、邊界情況、錯誤情況
3. **可重現性**：使用固定種子測試可重現性
4. **嚴格驗證**：特別針對用戶報告的問題（除法範圍 50-99, 1-4）進行嚴格測試
5. **整合測試**：測試完整的生成 -> 計算 -> 檢查流程

## 測試統計

- **總測試數**：52+ 個測試用例
- **覆蓋範圍**：
  - 所有四則運算（加、減、乘、除）
  - 範圍驗證
  - 答案檢查
  - 邊界情況
  - 錯誤處理

## 維護建議

1. 當修改核心邏輯時，確保所有測試通過
2. 添加新功能時，添加對應的測試
3. 發現 bug 時，先寫測試重現問題，再修復
4. 定期運行測試確保代碼質量

