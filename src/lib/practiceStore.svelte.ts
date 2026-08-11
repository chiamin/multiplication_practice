import { Operation, FIXED_RANGE_OPERATIONS, type AnswerField } from './types'
import { generateQuestion } from './questionGenerator'
import { checkAnswer, checkDivisionAnswer } from './answerChecker'
import { LEVELS, TOTAL_LEVELS, type LevelConfig } from './levels'
import {
  DEFAULT_DIFFICULTY,
  clamp01,
  difficultyWeight,
  isMastered,
  updateDifficulty,
  type QuestionStat,
} from './mastery'

// Normalize commutative operations so (3,5) and (5,3) count as the same question
function questionKey(op: Operation, a: number, b: number): string {
  if (op === Operation.Add || op === Operation.AddCarry || op === Operation.Multiply) {
    const [lo, hi] = a <= b ? [a, b] : [b, a]
    return `${op}:${lo},${hi}`
  }
  return `${op}:${a},${b}`
}

const BASE = import.meta.env.BASE_URL

type SoundName = 'ding' | 'eoh' | 'cheer'

const SOUND_FILES: Record<SoundName, string> = {
  ding: 'ding.mp3',
  eoh: 'eoh.mp3',
  cheer: 'cheer.mp3',
}

// Pre-warmed element pool, keyed by sound name. Each element is created and
// load()ed at startup so the browser fetches AND decodes the audio up front —
// playback then starts from an already-decoded buffer instead of paying the
// "new Audio() → fetch from cache → decode" cost on every tap, which was the
// source of the audible delay.
//
// We keep HTMLAudioElement (not Web Audio) on purpose: it plays on the ringer
// channel so the iPad volume keys control it (see CLAUDE.md). The pool size > 1
// lets overlapping/rapid plays each grab a different idle element, so we never
// touch an element whose play() promise is still pending — which is the
// element-reuse race the old shared-element approach hit. We only ever reset
// currentTime on an element that has already finished (paused || ended), where
// its previous play() promise has long since settled.
const POOL_SIZE = 3
const pools: Record<SoundName, HTMLAudioElement[]> = {
  ding: [],
  eoh: [],
  cheer: [],
}

function makeElement(name: SoundName): HTMLAudioElement {
  const el = new Audio(`${BASE}assets/sounds/${SOUND_FILES[name]}`)
  el.preload = 'auto'
  el.load() // kick off fetch + decode now so the buffer is ready before first play
  return el
}

if (typeof window !== 'undefined') {
  for (const name of Object.keys(SOUND_FILES) as SoundName[]) {
    for (let i = 0; i < POOL_SIZE; i++) {
      pools[name].push(makeElement(name))
    }
  }
}

// iOS requires one user-gesture .play() before audio is allowed outside gestures
// (e.g. the cheer that plays 800ms after the last correct answer).
// Use a single muted dummy element — one at a time, retry on failure.
let audioUnlocked = false
let unlockInFlight = false

function unlockSounds() {
  if (audioUnlocked || unlockInFlight) return
  unlockInFlight = true
  const dummy = new Audio(`${BASE}assets/sounds/ding.mp3`)
  dummy.muted = true
  dummy.play()
    .then(() => { audioUnlocked = true; unlockInFlight = false })
    .catch(() => { unlockInFlight = false })
}

if (typeof document !== 'undefined') {
  const handler = () => unlockSounds()
  document.addEventListener('touchstart', handler, { capture: true, passive: true })
  document.addEventListener('touchend',   handler, { capture: true, passive: true })
  document.addEventListener('mousedown',  handler, { capture: true })
  document.addEventListener('click',      handler, { capture: true })
}

// Play from the pre-warmed pool. Pick an idle element (one that's finished or
// hasn't started); its decoded buffer is ready, so playback is near-instant.
// We only reset currentTime on a finished element — never on one whose play()
// promise is still pending, sidestepping the element-reuse race (see pool
// comment / CLAUDE.md). If every element is mid-play we spin up a throwaway one
// so a play is never dropped; it's GC'd after it ends.
function playSound(name: SoundName) {
  const pool = pools[name]
  let el = pool.find((e) => e.paused || e.ended)
  if (!el) {
    el = makeElement(name)
  } else if (el.currentTime !== 0) {
    el.currentTime = 0
  }
  el.play().catch((err) => console.warn(`play ${name} failed:`, err))
}

type MessageType = 'correct' | 'wrong' | 'info' | null
type View = 'settings' | 'map' | 'practice'

export interface LevelResult {
  level: number
  passed: boolean
  elapsedSec: number
  firstTryWrongs: number
  timeLimitSec: number
  maxErrors: number
  questions: number
  timeOk: boolean
  errorsOk: boolean
}

// ── Per-name progress（一般模式與遊戲模式共用同一份 profile）──
// questionStats：key 是 questionKey()，值是該題的難度分紀錄。
// 難度分由 mastery.ts 的公式依「答對／答錯」與「花幾秒」更新。
export interface Profile {
  name: string
  unlockedLevel: number
  flowers: number
  questionStats: Record<string, QuestionStat>
}

const PROFILES_KEY = 'game.profiles.v1'
const LEGACY_UNLOCKED_KEY = 'game.unlockedLevel'

// 每收集滿這麼多朵小花，就進位成 1 顆星星
const FLOWERS_PER_STAR = 10

// 複習機率：出題時若紀錄裡有可用的舊題，有這個機率改抽舊題來複習
// （抽中哪一題按 mastery.ts 的難度權重加權——越不熟越常出現）。
const REVIEW_CHANCE = 0.4

// 答錯的題目「隔幾題後」才可以在同一組內再出現。
// 設 2 表示中間至少插入 2 題別的，第 3 題起才有機會重播——孩子不會覺得被同
// 一題卡住，但又能在本組內再遇到它加深印象（即時複習）。
const REPLAY_GAP = 2

const OPERATION_VALUES = new Set<string>(Object.values(Operation))

function sanitizeQuestionStats(raw: unknown): Record<string, QuestionStat> {
  if (!raw || typeof raw !== 'object') return {}
  const out: Record<string, QuestionStat> = {}
  for (const [key, v] of Object.entries(raw as Record<string, unknown>)) {
    const s = v as Partial<QuestionStat> | null
    if (
      s &&
      typeof s.op === 'string' && OPERATION_VALUES.has(s.op) &&
      typeof s.a === 'number' && Number.isFinite(s.a) &&
      typeof s.b === 'number' && Number.isFinite(s.b) &&
      typeof s.difficulty === 'number' && Number.isFinite(s.difficulty)
    ) {
      out[key] = {
        op: s.op as Operation,
        a: s.a,
        b: s.b,
        difficulty: clamp01(s.difficulty),
        attempts: typeof s.attempts === 'number' && s.attempts >= 0 ? Math.floor(s.attempts) : 0,
        wrongs: typeof s.wrongs === 'number' && s.wrongs >= 0 ? Math.floor(s.wrongs) : 0,
        lastSec:
          typeof s.lastSec === 'number' && Number.isFinite(s.lastSec) && s.lastSec >= 0
            ? s.lastSec
            : null,
      }
    }
  }
  return out
}

/**
 * 舊版 wrongStats（{count: n}）轉成新的難度分紀錄，讓已經在用的孩子不會
 * 因為改公式而清空進度。count 越大代表越不熟，對應到越高的難度分。
 */
function migrateWrongStats(raw: unknown): Record<string, QuestionStat> {
  if (!raw || typeof raw !== 'object') return {}
  const out: Record<string, QuestionStat> = {}
  for (const [key, v] of Object.entries(raw as Record<string, unknown>)) {
    const s = v as { op?: unknown; a?: unknown; b?: unknown; count?: unknown } | null
    if (
      s &&
      typeof s.op === 'string' && OPERATION_VALUES.has(s.op) &&
      typeof s.a === 'number' && typeof s.b === 'number' &&
      typeof s.count === 'number' && s.count > 0
    ) {
      const count = Math.min(9, Math.floor(s.count))
      out[key] = {
        op: s.op as Operation,
        a: s.a,
        b: s.b,
        // count 1 → 0.6、2 → 0.7 …… 逐步逼近 0.95，維持「錯過的題目優先」
        difficulty: clamp01(0.5 + count * 0.1),
        attempts: count,
        wrongs: count,
        lastSec: null,
      }
    }
  }
  return out
}

function loadProfiles(): Profile[] {
  if (typeof localStorage === 'undefined') return []
  try {
    const raw = localStorage.getItem(PROFILES_KEY)
    if (raw) {
      const parsed = JSON.parse(raw)
      if (Array.isArray(parsed)) {
        return parsed
          .filter(
            (p): p is Profile =>
              p && typeof p.name === 'string' && typeof p.unlockedLevel === 'number',
          )
          .map((p) => {
            const anyP = p as Partial<Profile> & { wrongStats?: unknown }
            // 新欄位優先；只有舊版 wrongStats 的資料就轉換過來
            const stats = anyP.questionStats
              ? sanitizeQuestionStats(anyP.questionStats)
              : migrateWrongStats(anyP.wrongStats)
            return {
              name: p.name,
              unlockedLevel: Math.min(Math.max(1, p.unlockedLevel), TOTAL_LEVELS + 1),
              flowers: typeof p.flowers === 'number' && p.flowers >= 0 ? Math.floor(p.flowers) : 0,
              questionStats: stats,
            }
          })
      }
    }
    // Migrate from old single-profile key if present
    const legacy = localStorage.getItem(LEGACY_UNLOCKED_KEY)
    if (legacy) {
      const n = parseInt(legacy)
      if (!isNaN(n) && n >= 1) {
        const migrated: Profile[] = [
          { name: '小朋友', unlockedLevel: Math.min(n, TOTAL_LEVELS + 1), flowers: 0, questionStats: {} },
        ]
        saveProfiles(migrated)
        localStorage.removeItem(LEGACY_UNLOCKED_KEY)
        return migrated
      }
    }
  } catch (err) {
    console.warn('loadProfiles failed:', err)
  }
  return []
}

function saveProfiles(profiles: Profile[]) {
  if (typeof localStorage === 'undefined') return
  localStorage.setItem(PROFILES_KEY, JSON.stringify(profiles))
}

class PracticeStore {
  // ── Settings ──
  operation = $state<Operation>(Operation.Add)
  minA = $state(2)
  maxA = $state(9)
  minB = $state(2)
  maxB = $state(9)
  questionsPerSet = $state(10)

  // ── Navigation ──
  view = $state<View>('settings')
  gameMode = $state(false)
  currentLevel = $state(0) // 0 = not in a level

  // ── Profiles / per-name progress ──
  profiles = $state<Profile[]>(loadProfiles())
  currentProfileName = $state<string | null>(null)
  // unlockedLevel reflects the current profile; 1 when no profile selected.
  unlockedLevel = $state(1)
  // Where the rabbit currently sits on the map. Lags behind unlockedLevel
  // after a level is passed, so the map can animate the rabbit forward.
  prevUnlockedLevel = $state(1)

  // ── Practice state ──
  answeredCount = $state(0)
  question = $state<{ a: number; b: number } | null>(null)
  message = $state('')
  messageType = $state<MessageType>(null)
  celebrating = $state(false)
  activeField = $state<AnswerField>('quotient')
  elapsedMs = $state(0)
  wrongCount = $state(0)
  firstTryWrongs = $state(0)
  levelResult = $state<LevelResult | null>(null)
  // True while the post-pass celebration animation is on screen, before the
  // result modal appears. Set in _finishLevel() on pass; cleared after the
  // animation finishes (see finishCelebration).
  passingCelebration = $state(false)

  // ── Answer inputs ──
  quotientInput = $state('')
  remainderInput = $state('')
  // True while an answer is being processed (the 800ms correct-answer delay,
  // or the synchronous wrong-answer path). Blocks re-entrant taps so a fast
  // double-tap on 送出 can't double-count or skip a question. The keypad reads
  // this to disable itself.
  submitting = $state(false)

  private usedQuestions = new Set<string>()
  // 答錯過、等著在本組內重播的題目 → 它最早可以再出現的「題序」。
  // _onWrong 時登記為「現在的題序 + REPLAY_GAP + 1」，抽題時只放行已到期的，
  // 這樣答錯的題目能在同一組內即時複習，又不會連續出現。
  private replayAfter = new Map<string, number>()
  // 本組已經出過幾題（含目前這題），replayAfter 的到期判斷基準。
  private questionsShown = 0
  startTime = 0
  private currentQuestionWrong = false
  // 這一題出現在畫面上的時刻，用來算「花幾秒答出來」餵給難度分公式。
  // 每次 _nextQuestion() 重設；答錯後不重設，所以慢慢試錯的時間會累計進去。
  private questionShownAt = 0
  // Result computed when a level is passed; held aside while the celebration
  // plays, then promoted to levelResult when the animation finishes.
  private pendingResult: LevelResult | null = null

  // ── Derived ──
  get inSettings() {
    return this.view === 'settings'
  }

  get inMap() {
    return this.view === 'map'
  }

  get progress() {
    return this.questionsPerSet > 0 ? this.answeredCount / this.questionsPerSet : 0
  }

  get currentQuestionNumber() {
    return Math.min(this.answeredCount + 1, this.questionsPerSet)
  }

  get currentFlowers(): number {
    if (!this.currentProfileName) return 0
    return this.profiles.find((p) => p.name === this.currentProfileName)?.flowers ?? 0
  }

  // 每收集滿 FLOWERS_PER_STAR 朵小花，就進位成 1 顆星星。
  // currentStars = 已進位的星星數；currentFlowersRemainder = 尚未進位的剩餘小花數。
  get currentStars(): number {
    return Math.floor(this.currentFlowers / FLOWERS_PER_STAR)
  }

  get currentFlowersRemainder(): number {
    return this.currentFlowers % FLOWERS_PER_STAR
  }

  get elapsedDisplay() {
    const totalSec = Math.round(this.elapsedMs / 1000)
    const min = Math.floor(totalSec / 60)
    const sec = totalSec % 60
    return min > 0 ? `${min} 分 ${sec} 秒` : `${sec} 秒`
  }

  // ── Actions ──
  /**
   * Add a new profile without entering the game. No-op if the name already
   * exists or is whitespace-only.
   */
  addProfile(rawName: string) {
    const name = rawName.trim()
    if (!name) return
    if (this.profiles.find((p) => p.name === name)) return
    this.profiles = [...this.profiles, { name, unlockedLevel: 1, flowers: 0, questionStats: {} }]
    saveProfiles(this.profiles)
  }

  /**
   * 選一個玩家（首頁的第一步），兩種模式都用這個身分記錄答題狀況。
   * profile 不存在就建立。傳 null 表示不指定玩家（此時不會累積紀錄）。
   * 只切換身分，不進入任何模式。
   */
  selectProfile(rawName: string | null) {
    // Unlock audio FIRST while we're still synchronously inside the user's
    // click handler — iOS Safari needs the play() call to happen before any
    // significant work (storage writes, reactive re-renders) drains the gesture.
    unlockSounds()
    if (rawName === null) {
      this.currentProfileName = null
      this.unlockedLevel = 1
      this.prevUnlockedLevel = 1
      return
    }
    const name = rawName.trim()
    if (!name) return
    if (!this.profiles.find((p) => p.name === name)) {
      this.profiles = [...this.profiles, { name, unlockedLevel: 1, flowers: 0, questionStats: {} }]
      saveProfiles(this.profiles)
    }
    const profile = this.profiles.find((p) => p.name === name)!
    this.currentProfileName = name
    this.unlockedLevel = profile.unlockedLevel
    this.prevUnlockedLevel = profile.unlockedLevel
  }

  /**
   * Enter game mode under the given player name. Creates the profile if new;
   * otherwise loads its saved progress. Whitespace-only names are ignored.
   */
  startGameMode(rawName: string) {
    const name = rawName.trim()
    if (!name) return
    this.selectProfile(name)
    this.gameMode = true
    this.view = 'map'
    this.levelResult = null
  }

  /** 用目前已選的玩家進遊戲模式（首頁已先選好名字的流程）。 */
  enterGameMode() {
    if (!this.currentProfileName) return
    this.startGameMode(this.currentProfileName)
  }

  deleteProfile(name: string) {
    this.profiles = this.profiles.filter((p) => p.name !== name)
    saveProfiles(this.profiles)
    if (this.currentProfileName === name) {
      this.currentProfileName = null
      this.unlockedLevel = 1
      this.prevUnlockedLevel = 1
    }
  }

  /** 清掉目前玩家的答題紀錄（難度分歸零重新來）。 */
  resetCurrentStats() {
    const name = this.currentProfileName
    if (!name) return
    this.profiles = this.profiles.map((p) =>
      p.name === name ? { ...p, questionStats: {} } : p,
    )
    saveProfiles(this.profiles)
  }

  /** 目前玩家在目前運算下、還沒熟練的題數（給首頁顯示）。 */
  get reviewPoolSize(): number {
    const profile = this._currentProfile()
    if (!profile) return 0
    return Object.values(profile.questionStats ?? {}).filter(
      (s) => s.op === this.operation && this._inCurrentRange(s.a, s.b),
    ).length
  }

  returnToSettings() {
    this.view = 'settings'
    this.gameMode = false
    this.currentLevel = 0
    this.celebrating = false
    this.passingCelebration = false
    this.pendingResult = null
    this.levelResult = null
    this._resetQuestionHistory()
    this.message = ''
    this.messageType = null
  }

  returnToMap() {
    this.view = 'map'
    this.celebrating = false
    this.passingCelebration = false
    this.pendingResult = null
    this.levelResult = null
    this._resetQuestionHistory()
    this.message = ''
    this.messageType = null
  }

  startLevel(n: number) {
    if (n < 1 || n > TOTAL_LEVELS) return
    if (n > this.unlockedLevel) return
    // Unlock audio FIRST inside the gesture (see startGameMode comment).
    unlockSounds()
    const cfg = LEVELS[n - 1]
    this.currentLevel = n
    this.questionsPerSet = cfg.questions
    this.gameMode = true
    this.view = 'practice'
    this.levelResult = null
    this._resetPracticeState()
  }

  startPractice() {
    unlockSounds()
    this.gameMode = false
    this.currentLevel = 0
    this.view = 'practice'
    this._resetPracticeState()
  }

  startAnotherSet() {
    this._resetPracticeState()
  }

  private _resetPracticeState() {
    this.answeredCount = 0
    this._resetQuestionHistory()
    this.submitting = false
    this.celebrating = false
    this.elapsedMs = 0
    this.wrongCount = 0
    this.firstTryWrongs = 0
    this.startTime = Date.now()
    this._nextQuestion()
  }

  appendDigit(digit: number) {
    // Each tap is a real user gesture — refresh audio unlock here so iOS
    // Safari can't keep us suspended after focus changes / virtual keyboard
    // pop-ins from earlier in the flow.
    unlockSounds()
    if (this.submitting) return
    if (this.operation === Operation.Divide && this.activeField === 'remainder') {
      this.remainderInput += digit.toString()
    } else {
      this.quotientInput += digit.toString()
    }
  }

  clearActiveInput() {
    if (this.submitting) return
    if (this.operation === Operation.Divide && this.activeField === 'remainder') {
      this.remainderInput = ''
    } else {
      this.quotientInput = ''
    }
  }

  backspace() {
    if (this.submitting) return
    if (this.operation === Operation.Divide && this.activeField === 'remainder') {
      this.remainderInput = this.remainderInput.slice(0, -1)
    } else {
      this.quotientInput = this.quotientInput.slice(0, -1)
    }
  }

  setActiveField(field: AnswerField) {
    this.activeField = field
  }

  async submitAnswer() {
    // Submit is a real click — refresh audio unlock right at the moment we're
    // about to need to play ding/eoh.
    unlockSounds()
    // Guard against re-entrant taps. A correct answer holds `submitting` for
    // the full 800ms feedback delay (released in _onCorrect's finally); a fast
    // double-tap during that window would otherwise double-count or skip a
    // question. Validation failures / wrong answers release it immediately so
    // the child can retry without waiting.
    if (this.submitting) return
    if (!this.question) return
    this.submitting = true
    const { a, b } = this.question

    if (this.operation === Operation.Divide) {
      const q = parseInt(this.quotientInput)
      const r = parseInt(this.remainderInput)
      if (isNaN(q) || this.quotientInput === '') {
        this._setMessage('請輸入商', 'info')
        this.activeField = 'quotient'
        this.submitting = false
        return
      }
      if (isNaN(r) || this.remainderInput === '') {
        this._setMessage('請輸入餘數', 'info')
        this.activeField = 'remainder'
        this.submitting = false
        return
      }
      const result = checkDivisionAnswer(a, b, q, r)
      if (result.error) {
        this._setMessage(result.error, 'info')
        this.submitting = false
        return
      }
      if (result.correct) {
        await this._onCorrect()
      } else {
        this._onWrong()
        this.submitting = false
      }
    } else {
      const answer = parseInt(this.quotientInput)
      if (isNaN(answer) || this.quotientInput === '') {
        this._setMessage('請先輸入答案', 'info')
        this.submitting = false
        return
      }
      if (checkAnswer(this.operation, a, b, answer)) {
        await this._onCorrect()
      } else {
        this._onWrong()
        this.submitting = false
      }
    }
  }

  private async _onCorrect() {
    // 記錄這題花了幾秒。只有「一次就答對」才算表現好；先答錯又改對的，
    // 難度分已在 _onWrong 推高，這裡不讓它靠最後一次答對抵銷掉。
    if (this.question) {
      const elapsedSec = (Date.now() - this.questionShownAt) / 1000
      if (!this.currentQuestionWrong) {
        this._recordAttempt(this.question.a, this.question.b, true, elapsedSec)
      }
    }
    this._setMessage('答對了！太棒了 🎉', 'correct')
    playSound('ding')
    try {
      await delay(800)
      this.answeredCount++
      if (this.answeredCount >= this.questionsPerSet) {
        this.elapsedMs = Date.now() - this.startTime
        if (this.gameMode && this.currentLevel > 0) {
          this._finishLevel()
        } else {
          this.celebrating = true
          playSound('cheer')
        }
      } else {
        this._nextQuestion()
      }
    } finally {
      // Released after the feedback delay so the keypad stays disabled the
      // whole time the “答對了” message is up; re-enabled for the next question.
      this.submitting = false
    }
  }

  private _finishLevel() {
    const cfg = LEVELS[this.currentLevel - 1]
    const elapsedSec = Math.round(this.elapsedMs / 1000)
    const timeOk = elapsedSec <= cfg.timeLimitSec
    const errorsOk = this.firstTryWrongs <= cfg.maxErrors
    const passed = timeOk && errorsOk
    const result: LevelResult = {
      level: this.currentLevel,
      passed,
      elapsedSec,
      firstTryWrongs: this.firstTryWrongs,
      timeLimitSec: cfg.timeLimitSec,
      maxErrors: cfg.maxErrors,
      questions: cfg.questions,
      timeOk,
      errorsOk,
    }
    if (passed && this.currentLevel === TOTAL_LEVELS) {
      this._incrementFlowers()
    }
    if (passed && this.currentLevel >= this.unlockedLevel) {
      this.unlockedLevel = this.currentLevel + 1
      this._persistCurrentProgress()
    }
    if (passed) {
      // Defer the result modal until the celebration animation completes
      playSound('cheer')
      this.pendingResult = result
      this.passingCelebration = true
    } else {
      this.levelResult = result
    }
  }

  /** Called by PassCelebration after its 3s animation finishes. */
  finishCelebration() {
    this.passingCelebration = false
    if (this.pendingResult) {
      this.levelResult = this.pendingResult
      this.pendingResult = null
    }
  }

  retryLevel() {
    if (this.currentLevel < 1) return
    this.levelResult = null
    this.view = 'practice'
    this._resetPracticeState()
  }

  nextLevel() {
    const next = this.currentLevel + 1
    if (next > TOTAL_LEVELS || next > this.unlockedLevel) {
      this.returnToMap()
      return
    }
    this.startLevel(next)
  }

  currentLevelConfig(): LevelConfig | null {
    if (this.currentLevel < 1) return null
    return LEVELS[this.currentLevel - 1]
  }

  startOver() {
    this.unlockedLevel = 1
    this.prevUnlockedLevel = 1
    this._persistCurrentProgress()
    this.levelResult = null
    this.view = 'map'
  }

  private _incrementFlowers() {
    const name = this.currentProfileName
    if (!name) return
    this.profiles = this.profiles.map((p) =>
      p.name === name ? { ...p, flowers: (p.flowers ?? 0) + 1 } : p,
    )
    saveProfiles(this.profiles)
  }

  private _persistCurrentProgress() {
    const name = this.currentProfileName
    if (!name) return
    this.profiles = this.profiles.map((p) =>
      p.name === name ? { ...p, unlockedLevel: this.unlockedLevel } : p,
    )
    saveProfiles(this.profiles)
  }

  private _onWrong() {
    const wrong = this.quotientInput
    const msg = this.operation === Operation.Divide
      ? '不對喔，再試試 🙈'
      : `不是 ${wrong} 喔，再試試 🙈`
    this._setMessage(msg, 'wrong')
    playSound('eoh')
    this.wrongCount++
    if (!this.currentQuestionWrong) {
      this.currentQuestionWrong = true
      this.firstTryWrongs++
      // 第一次答錯才記錄（同一題重複按錯不重複計），難度分會被推到高位
      if (this.question) {
        const elapsedSec = (Date.now() - this.questionShownAt) / 1000
        this._recordAttempt(this.question.a, this.question.b, false, elapsedSec)
        // 解除本組的「不重複」限制，隔 REPLAY_GAP 題後可以再出現（即時複習）
        const key = questionKey(this.operation, this.question.a, this.question.b)
        this.replayAfter.set(key, this.questionsShown + REPLAY_GAP + 1)
      }
    }
    this.quotientInput = ''
    this.remainderInput = ''
    this.activeField = 'quotient'
  }

  private _setMessage(msg: string, type: MessageType) {
    this.message = msg
    this.messageType = type
  }

  private _nextQuestion() {
    const q = this._generateNonRepeating()
    this.question = q
    this.quotientInput = ''
    this.remainderInput = ''
    this.message = ''
    this.messageType = null
    this.activeField = 'quotient'
    this.currentQuestionWrong = false
    this.questionShownAt = Date.now()
  }

  // ── 錯題複習 ──
  private _currentProfile(): Profile | null {
    if (!this.currentProfileName) return null
    return this.profiles.find((p) => p.name === this.currentProfileName) ?? null
  }

  /**
   * 記錄一次作答結果並更新該題的難度分（見 mastery.ts 的公式）。
   * 一般模式與遊戲模式共用同一份 profile 紀錄——在一般模式常錯的題目，
   * 進遊戲模式也會比較常出現，反之亦然。
   * 沒選玩家時（沒有身分可掛）就不記錄。
   */
  private _recordAttempt(a: number, b: number, correct: boolean, elapsedSec: number) {
    const name = this.currentProfileName
    if (!name) return
    const key = questionKey(this.operation, a, b)
    const op = this.operation
    this.profiles = this.profiles.map((p) => {
      if (p.name !== name) return p
      const stats = { ...(p.questionStats ?? {}) }
      const prev = stats[key]
      const prevDifficulty = prev?.difficulty ?? DEFAULT_DIFFICULTY
      const difficulty = updateDifficulty(prevDifficulty, correct, elapsedSec)
      // 熟練到門檻以下就移除，紀錄不會無限長大
      if (isMastered(difficulty)) {
        if (!prev) return p
        delete stats[key]
        return { ...p, questionStats: stats }
      }
      stats[key] = {
        op,
        a,
        b,
        difficulty,
        attempts: (prev?.attempts ?? 0) + 1,
        wrongs: (prev?.wrongs ?? 0) + (correct ? 0 : 1),
        lastSec: correct ? Math.round(elapsedSec * 10) / 10 : (prev?.lastSec ?? null),
      }
      return { ...p, questionStats: stats }
    })
    saveProfiles(this.profiles)
  }

  /** 錯題是否還在目前設定的數字範圍內（規則型運算的範圍固定，一律有效）。 */
  private _inCurrentRange(a: number, b: number): boolean {
    if (FIXED_RANGE_OPERATIONS.includes(this.operation)) return true
    const fits = (x: number, min: number, max: number) => x >= min && x <= max
    const direct = fits(a, this.minA, this.maxA) && fits(b, this.minB, this.maxB)
    if (this.operation === Operation.Add || this.operation === Operation.Multiply) {
      return direct || (fits(b, this.minA, this.maxA) && fits(a, this.minB, this.maxB))
    }
    return direct
  }

  /**
   * 這一題在本組內能不能出（現在）。沒出過的可以出；出過的只有在答錯後
   * 登記重播、且已經隔滿 REPLAY_GAP 題時才放行。
   */
  private _isSelectable(key: string): boolean {
    if (!this.usedQuestions.has(key)) return true
    const due = this.replayAfter.get(key)
    return due !== undefined && this.questionsShown >= due
  }

  /**
   * 以 REVIEW_CHANCE 的機率從紀錄裡抽一題複習，抽中哪一題按 difficultyWeight()
   * 加權——答錯過或答得慢的題目權重最高（最不熟的可達最熟的 25 倍）。
   * 難度分在答完那一刻就更新，所以剛答錯的題目隔幾題後就能以最高權重回來
   * （即時複習），不必等整組結束。
   * 一般模式與遊戲模式都適用，只要選了玩家就生效。
   * 沒有可用舊題或沒抽中時回傳 null，走一般隨機出題。
   */
  private _pickReviewQuestion(): { a: number; b: number } | null {
    const profile = this._currentProfile()
    if (!profile) return null
    const candidates = Object.entries(profile.questionStats ?? {}).filter(
      ([key, s]) =>
        s.op === this.operation &&
        this._isSelectable(key) &&
        this._inCurrentRange(s.a, s.b),
    )
    if (candidates.length === 0) return null
    if (Math.random() >= REVIEW_CHANCE) return null
    const weights = candidates.map(([, s]) => difficultyWeight(s.difficulty))
    const total = weights.reduce((sum, w) => sum + w, 0)
    if (total <= 0) return null
    let r = Math.random() * total
    let picked = candidates[candidates.length - 1][1]
    for (let i = 0; i < candidates.length; i++) {
      r -= weights[i]
      if (r < 0) {
        picked = candidates[i][1]
        break
      }
    }
    // 交換律運算隨機交換順序，複習題看起來才不會一成不變
    const commutative =
      this.operation === Operation.Add ||
      this.operation === Operation.AddCarry ||
      this.operation === Operation.Multiply
    if (commutative && Math.random() < 0.5) return { a: picked.b, b: picked.a }
    return { a: picked.a, b: picked.b }
  }

  private _generateNonRepeating(): { a: number; b: number } {
    const review = this._pickReviewQuestion()
    if (review) {
      this._markShown(questionKey(this.operation, review.a, review.b))
      return review
    }
    const MAX_TRIES = 100
    for (let i = 0; i < MAX_TRIES; i++) {
      const q = generateQuestion(this.operation, this.minA, this.maxA, this.minB, this.maxB)
      const key = questionKey(this.operation, q.a, q.b)
      if (this._isSelectable(key)) {
        this._markShown(key)
        return q
      }
    }
    // All questions exhausted — allow repeats
    const q = generateQuestion(this.operation, this.minA, this.maxA, this.minB, this.maxB)
    this._markShown(questionKey(this.operation, q.a, q.b))
    return q
  }

  /**
   * 登記這一題已經出現。清掉它的重播登記——重播機會用掉了，之後要再出現得
   * 再答錯一次；不清的話同一題會在到期後每次都被放行。
   */
  private _markShown(key: string) {
    this.usedQuestions.add(key)
    this.replayAfter.delete(key)
    this.questionsShown++
  }

  /** 開新一組時把「本組出過哪些題」的狀態全部歸零。 */
  private _resetQuestionHistory() {
    this.usedQuestions.clear()
    this.replayAfter.clear()
    this.questionsShown = 0
  }
}

function delay(ms: number) {
  return new Promise(resolve => setTimeout(resolve, ms))
}

export const practice = new PracticeStore()
