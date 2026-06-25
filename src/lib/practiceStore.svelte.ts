import { Operation, type AnswerField } from './types'
import { generateQuestion } from './questionGenerator'
import { checkAnswer, checkDivisionAnswer } from './answerChecker'
import { LEVELS, TOTAL_LEVELS, type LevelConfig } from './levels'

// Normalize commutative operations so (3,5) and (5,3) count as the same question
function questionKey(op: Operation, a: number, b: number): string {
  if (op === Operation.Add || op === Operation.Multiply) {
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

// Preload files into browser HTTP cache at startup so first play is instant.
if (typeof window !== 'undefined') {
  for (const file of Object.values(SOUND_FILES)) {
    const a = new Audio(`${BASE}assets/sounds/${file}`)
    a.preload = 'auto'
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

// Create a fresh Audio element on every play — eliminates all element-reuse
// state bugs. Browser serves cached audio from HTTP cache, so no re-fetching.
function playSound(name: SoundName) {
  new Audio(`${BASE}assets/sounds/${SOUND_FILES[name]}`)
    .play()
    .catch(err => console.warn(`play ${name} failed:`, err))
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

// ── Per-name game progress ──
export interface Profile {
  name: string
  unlockedLevel: number
  flowers: number
}

const PROFILES_KEY = 'game.profiles.v1'
const LEGACY_UNLOCKED_KEY = 'game.unlockedLevel'

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
          .map((p) => ({
            name: p.name,
            unlockedLevel: Math.min(Math.max(1, p.unlockedLevel), TOTAL_LEVELS + 1),
            flowers: typeof p.flowers === 'number' && p.flowers >= 0 ? Math.floor(p.flowers) : 0,
          }))
      }
    }
    // Migrate from old single-profile key if present
    const legacy = localStorage.getItem(LEGACY_UNLOCKED_KEY)
    if (legacy) {
      const n = parseInt(legacy)
      if (!isNaN(n) && n >= 1) {
        const migrated: Profile[] = [
          { name: '小朋友', unlockedLevel: Math.min(n, TOTAL_LEVELS + 1), flowers: 0 },
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
  startTime = 0
  private currentQuestionWrong = false
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
    this.profiles = [...this.profiles, { name, unlockedLevel: 1, flowers: 0 }]
    saveProfiles(this.profiles)
  }

  /**
   * Enter game mode under the given player name. Creates the profile if new;
   * otherwise loads its saved progress. Whitespace-only names are ignored.
   */
  startGameMode(rawName: string) {
    const name = rawName.trim()
    if (!name) return
    // Unlock audio FIRST while we're still synchronously inside the user's
    // click handler — iOS Safari needs the play() call to happen before any
    // significant work (storage writes, reactive re-renders) drains the gesture.
    unlockSounds()
    if (!this.profiles.find((p) => p.name === name)) {
      this.profiles = [...this.profiles, { name, unlockedLevel: 1, flowers: 0 }]
      saveProfiles(this.profiles)
    }
    const profile = this.profiles.find((p) => p.name === name)!
    this.currentProfileName = name
    this.unlockedLevel = profile.unlockedLevel
    this.prevUnlockedLevel = profile.unlockedLevel
    this.gameMode = true
    this.view = 'map'
    this.levelResult = null
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

  returnToSettings() {
    this.view = 'settings'
    this.gameMode = false
    this.currentLevel = 0
    this.celebrating = false
    this.passingCelebration = false
    this.pendingResult = null
    this.levelResult = null
    this.usedQuestions.clear()
    this.message = ''
    this.messageType = null
  }

  returnToMap() {
    this.view = 'map'
    this.celebrating = false
    this.passingCelebration = false
    this.pendingResult = null
    this.levelResult = null
    this.usedQuestions.clear()
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
    this.usedQuestions.clear()
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
  }

  private _generateNonRepeating(): { a: number; b: number } {
    const MAX_TRIES = 100
    for (let i = 0; i < MAX_TRIES; i++) {
      const q = generateQuestion(this.operation, this.minA, this.maxA, this.minB, this.maxB)
      const key = questionKey(this.operation, q.a, q.b)
      if (!this.usedQuestions.has(key)) {
        this.usedQuestions.add(key)
        return q
      }
    }
    // All questions exhausted — allow repeats
    const q = generateQuestion(this.operation, this.minA, this.maxA, this.minB, this.maxB)
    this.usedQuestions.add(questionKey(this.operation, q.a, q.b))
    return q
  }
}

function delay(ms: number) {
  return new Promise(resolve => setTimeout(resolve, ms))
}

export const practice = new PracticeStore()
