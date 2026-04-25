export interface LevelDecoration {
  emoji: string
  x: number  // percent from left
  y: number  // percent from top
  size: string  // tailwind text-* class
}

export interface LevelTheme {
  gradient: string  // CSS background value
  decorations: LevelDecoration[]
}

export interface LevelConfig {
  level: number
  questions: number
  timeLimitSec: number
  maxErrors: number
  theme: LevelTheme
}

// firstTryWrongs: 每題只計入一次（第一次答錯才算），不是累計每次按錯
// L5 設成 15 題 60 秒 ＝ 每題平均 4 秒（熟練小孩可達的目標）
export const LEVELS: LevelConfig[] = [
  {
    level: 1, questions: 5, timeLimitSec: 90, maxErrors: 2,
    theme: {
      gradient: 'linear-gradient(160deg, #fdf2f8 0%, #fce7f3 40%, #fef9c3 100%)',
      decorations: [
        { emoji: '🌸', x: 5,  y: 8,  size: 'text-4xl' },
        { emoji: '🌼', x: 88, y: 12, size: 'text-3xl' },
        { emoji: '🐝', x: 80, y: 55, size: 'text-3xl' },
        { emoji: '🌷', x: 6,  y: 60, size: 'text-4xl' },
        { emoji: '🦋', x: 50, y: 5,  size: 'text-3xl' },
      ],
    },
  },
  {
    level: 2, questions: 7, timeLimitSec: 90, maxErrors: 2,
    theme: {
      gradient: 'linear-gradient(160deg, #e0f2fe 0%, #bae6fd 40%, #e0f7fa 100%)',
      decorations: [
        { emoji: '☁️', x: 8,  y: 6,  size: 'text-5xl' },
        { emoji: '☁️', x: 72, y: 10, size: 'text-4xl' },
        { emoji: '🌈', x: 78, y: 50, size: 'text-4xl' },
        { emoji: '🐦', x: 10, y: 55, size: 'text-3xl' },
        { emoji: '⛅', x: 45, y: 4,  size: 'text-3xl' },
      ],
    },
  },
  {
    level: 3, questions: 10, timeLimitSec: 90, maxErrors: 1,
    theme: {
      gradient: 'linear-gradient(160deg, #dcfce7 0%, #bbf7d0 40%, #d1fae5 100%)',
      decorations: [
        { emoji: '🌲', x: 4,  y: 5,  size: 'text-5xl' },
        { emoji: '🌳', x: 82, y: 8,  size: 'text-5xl' },
        { emoji: '🍄', x: 88, y: 58, size: 'text-3xl' },
        { emoji: '🦊', x: 5,  y: 58, size: 'text-4xl' },
        { emoji: '🌿', x: 48, y: 6,  size: 'text-3xl' },
      ],
    },
  },
  {
    level: 4, questions: 12, timeLimitSec: 72, maxErrors: 1,
    theme: {
      gradient: 'linear-gradient(160deg, #fff7ed 0%, #fed7aa 40%, #fde8d8 100%)',
      decorations: [
        { emoji: '🌊', x: 5,  y: 62, size: 'text-4xl' },
        { emoji: '🐚', x: 85, y: 60, size: 'text-3xl' },
        { emoji: '🌅', x: 80, y: 6,  size: 'text-4xl' },
        { emoji: '🦀', x: 8,  y: 8,  size: 'text-3xl' },
        { emoji: '⛵', x: 46, y: 5,  size: 'text-3xl' },
      ],
    },
  },
  {
    level: 5, questions: 15, timeLimitSec: 60, maxErrors: 0,
    theme: {
      gradient: 'linear-gradient(160deg, #faf5ff 0%, #ede9fe 40%, #fce7f3 100%)',
      decorations: [
        { emoji: '⭐', x: 8,  y: 8,  size: 'text-4xl' },
        { emoji: '🌟', x: 82, y: 6,  size: 'text-4xl' },
        { emoji: '🌈', x: 85, y: 55, size: 'text-4xl' },
        { emoji: '🎀', x: 6,  y: 58, size: 'text-3xl' },
        { emoji: '✨', x: 48, y: 5,  size: 'text-3xl' },
      ],
    },
  },
]

export const TOTAL_LEVELS = LEVELS.length

export function formatTime(totalSec: number): string {
  const min = Math.floor(totalSec / 60)
  const sec = totalSec % 60
  return min > 0 ? `${min} 分 ${sec} 秒` : `${sec} 秒`
}

// Compact mm:ss for tight UI (e.g. map nodes)
export function formatTimeShort(totalSec: number): string {
  const min = Math.floor(totalSec / 60)
  const sec = totalSec % 60
  return `${min}:${sec.toString().padStart(2, '0')}`
}
