import { Operation, type AnswerField } from './types'
import { generateQuestion } from './questionGenerator'
import { checkAnswer, checkDivisionAnswer } from './answerChecker'

// Normalize commutative operations so (3,5) and (5,3) count as the same question
function questionKey(op: Operation, a: number, b: number): string {
  if (op === Operation.Add || op === Operation.Multiply) {
    const [lo, hi] = a <= b ? [a, b] : [b, a]
    return `${op}:${lo},${hi}`
  }
  return `${op}:${a},${b}`
}

const SOUNDS = {
  ding: new Audio('assets/sounds/ding.mp3'),
  eoh: new Audio('assets/sounds/eoh.mp3'),
  cheer: new Audio('assets/sounds/cheer.mp3'),
}

function playSound(name: keyof typeof SOUNDS) {
  const audio = SOUNDS[name]
  audio.currentTime = 0
  audio.play().catch(() => {})
}

type MessageType = 'correct' | 'wrong' | 'info' | null

class PracticeStore {
  // ── Settings ──
  operation = $state<Operation>(Operation.Add)
  minA = $state(1)
  maxA = $state(9)
  minB = $state(1)
  maxB = $state(9)
  questionsPerSet = $state(10)

  // ── Practice state ──
  inSettings = $state(true)
  answeredCount = $state(0)
  question = $state<{ a: number; b: number } | null>(null)
  message = $state('')
  messageType = $state<MessageType>(null)
  celebrating = $state(false)
  activeField = $state<AnswerField>('quotient')

  // ── Answer inputs ──
  quotientInput = $state('')
  remainderInput = $state('')

  private usedQuestions = new Set<string>()

  // ── Derived ──
  get progress() {
    return this.questionsPerSet > 0 ? this.answeredCount / this.questionsPerSet : 0
  }

  get currentQuestionNumber() {
    return Math.min(this.answeredCount + 1, this.questionsPerSet)
  }

  // ── Actions ──
  startPractice() {
    this.answeredCount = 0
    this.usedQuestions.clear()
    this.celebrating = false
    this.inSettings = false
    this._nextQuestion()
  }

  returnToSettings() {
    this.inSettings = true
    this.celebrating = false
    this.usedQuestions.clear()
    this.message = ''
    this.messageType = null
  }

  startAnotherSet() {
    this.answeredCount = 0
    this.usedQuestions.clear()
    this.celebrating = false
    this._nextQuestion()
  }

  appendDigit(digit: number) {
    if (this.operation === Operation.Divide && this.activeField === 'remainder') {
      this.remainderInput += digit.toString()
    } else {
      this.quotientInput += digit.toString()
    }
  }

  clearActiveInput() {
    if (this.operation === Operation.Divide && this.activeField === 'remainder') {
      this.remainderInput = ''
    } else {
      this.quotientInput = ''
    }
  }

  backspace() {
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
    if (!this.question) return
    const { a, b } = this.question

    if (this.operation === Operation.Divide) {
      const q = parseInt(this.quotientInput)
      const r = parseInt(this.remainderInput)
      if (isNaN(q) || this.quotientInput === '') {
        this._setMessage('請輸入商', 'info')
        this.activeField = 'quotient'
        return
      }
      if (isNaN(r) || this.remainderInput === '') {
        this._setMessage('請輸入餘數', 'info')
        this.activeField = 'remainder'
        return
      }
      const result = checkDivisionAnswer(a, b, q, r)
      if (result.error) {
        this._setMessage(result.error, 'info')
        return
      }
      if (result.correct) {
        await this._onCorrect()
      } else {
        this._onWrong()
      }
    } else {
      const answer = parseInt(this.quotientInput)
      if (isNaN(answer) || this.quotientInput === '') {
        this._setMessage('請先輸入答案', 'info')
        return
      }
      if (checkAnswer(this.operation, a, b, answer)) {
        await this._onCorrect()
      } else {
        this._onWrong()
      }
    }
  }

  private async _onCorrect() {
    this._setMessage('答對了！太棒了 🎉', 'correct')
    playSound('ding')
    await delay(800)
    this.answeredCount++
    if (this.answeredCount >= this.questionsPerSet) {
      this.celebrating = true
      playSound('cheer')
    } else {
      this._nextQuestion()
    }
  }

  private _onWrong() {
    const wrong = this.quotientInput
    const msg = this.operation === Operation.Divide
      ? '不對喔，再試試 🙈'
      : `不是 ${wrong} 喔，再試試 🙈`
    this._setMessage(msg, 'wrong')
    playSound('eoh')
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
