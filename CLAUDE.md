# 算術練習 Web App

給孩童練習基本四則運算（加、減、乘、除）的網頁應用。介面以中文為主。

## 技術棧

- **Svelte 5**（runes 模式：`$state` / `$derived` / `$effect`，**不要**用舊的 `writable` store）
- **TypeScript** + **Vite 8**
- **Tailwind CSS 4**（透過 `@tailwindcss/vite`，**不需要** tailwind.config.js）
- **GitHub Pages** 部署（`gh-pages` branch，遠端是 `chiamin/multiplication_practice`）

## 架構

單一頁面 app，沒有 router。狀態集中在一個 Svelte 5 class store。

```
src/
├── App.svelte                   依 store 切換 SettingsView / PracticeView，疊上 Celebration
├── main.ts
├── app.css
└── lib/
    ├── practiceStore.svelte.ts  ★ 唯一 store，singleton `practice`
    ├── types.ts                 Operation enum、i18n 標籤、QUESTION_COUNT_OPTIONS
    ├── questionGenerator.ts     依運算產生合法題目（純函式）
    ├── answerChecker.ts         一般 / 除法（商+餘數）判分（純函式）
    └── components/
        ├── SettingsView.svelte
        ├── PracticeView.svelte
        ├── QuestionDisplay.svelte
        ├── NumericKeypad.svelte
        └── Celebration.svelte
```

**Store 模式**：`PracticeStore` 是 class 帶 runes (`$state`)，導出 singleton `practice`。所有 UI 直接操作 `practice.xxx`。不用 props drilling。

**不重複出題**：[practiceStore.svelte.ts](src/lib/practiceStore.svelte.ts) 的 `questionKey()` 對加、乘做交換律標準化（`(3,5)` 等同 `(5,3)`），存入 `usedQuestions: Set<string>`。

**除法**：商+餘數兩個輸入框，`activeField` 切換，Tab 鍵也可切換。

## 資源路徑（重要）

`vite.config.ts` 設 `base: '/multiplication_practice/'`。所有對 `public/assets/` 的引用都**必須**用 `import.meta.env.BASE_URL` 拼路徑：

```ts
const BASE = import.meta.env.BASE_URL
<img src="{BASE}assets/icons/add.png" />
fetch(`${BASE}assets/sounds/ding.mp3`)
```

直接用相對路徑 `'assets/...'` 在某些 URL 形式（例如缺結尾 `/`）下會 404。

## 音效

[practiceStore.svelte.ts](src/lib/practiceStore.svelte.ts) 用 **`HTMLAudioElement`**（`new Audio()`）播 ding／eoh／cheer。
選擇 HTMLAudioElement 而非 Web Audio API 的原因：**HTMLAudioElement 走鈴聲音道，音量鍵可控制；Web Audio API 走媒體音道，不受音量鍵影響**，在 iPad 上體驗不直覺。

- module load 時為每個音檔建立一個 `preload='auto'` 的 Audio 元素，**只是要把檔案灌進瀏覽器 HTTP cache**，元素本身用完即丟、不保留。
- `playSound()` **每次都 `new Audio()` 建立全新元素**再 `play()`。檔案已在 HTTP cache，建立成本極低；改成這樣是要徹底消除元素重用造成的 race condition——舊作法在 iOS 上若前一次 `play()` 的 Promise 還在 pending、就被下一次 `currentTime = 0` 或 `pause()` 干擾，會導致後續 `play()` 靜默失敗（Promise resolve 但沒聲音）。
- `unlockSounds()` 在第一次 user gesture 裡建立**獨立的 dummy 元素**（`muted = true`）播一次 ding.mp3，讓 iOS Safari / iPad Chrome 解鎖後續非 gesture 內的播放權限（例如答完最後一題 800ms 後才播的 cheer）。用 dummy 元素是為了使用者聽不到那聲解鎖。一次只跑一個（`unlockInFlight` 旗標守住），成功設 `audioUnlocked = true`；失敗則只清掉 `unlockInFlight`，下個 gesture 會再試。
- 加新音效：在 `SoundName` union 和 `SOUND_FILES` 各加一筆，其餘自動處理。
- **不要**回退到「共用 `<audio>` 元素 + `currentTime = 0` + `pause()`」的舊作法——已知會在 iPad 上造成音效間歇性無聲。

## Build / Deploy

```
npm run dev      # 本機開發
npm run build    # 產出 dist/
npm run deploy   # build + 推到 gh-pages
npm run check    # svelte-check + tsc
```

**Node 版本陷阱**：系統預設 `node` 是 v12，跑不動 Vite 8（`SyntaxError: Unexpected token '.'`）。執行任何 npm 指令前要先：

```sh
export NVM_DIR="$HOME/.nvm" && . "$NVM_DIR/nvm.sh" && nvm use 20
```

## 行為慣例

- 所有 UI 文字用**繁體中文**。
- 錯題時保留題目，清空輸入讓孩子重答（不跳下一題）。
- 答對後延遲 800ms 再進下一題，讓回饋訊息看得到。
- 答完 `questionsPerSet` 題進入 `celebrating`，4 秒動畫後彈出對話框。
- 字體刻意放大（`text-7xl` / `text-8xl`），鍵盤按鈕也大顆，給小手用。
