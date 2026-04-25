export interface LevelConfig {
  level: number
  questions: number
  timeLimitSec: number
  maxErrors: number
}

// firstTryWrongs: 每題只計入一次（第一次答錯才算），不是累計每次按錯
// L5 設成 15 題 60 秒 ＝ 每題平均 4 秒（熟練小孩可達的目標）
export const LEVELS: LevelConfig[] = [
  { level: 1, questions: 5,  timeLimitSec: 90, maxErrors: 2 }, // 18 秒 / 題
  { level: 2, questions: 7,  timeLimitSec: 90, maxErrors: 2 }, // ~13 秒 / 題
  { level: 3, questions: 10, timeLimitSec: 90, maxErrors: 1 }, // 9 秒 / 題
  { level: 4, questions: 12, timeLimitSec: 72, maxErrors: 1 }, // 6 秒 / 題
  { level: 5, questions: 15, timeLimitSec: 60, maxErrors: 0 }, // 4 秒 / 題
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
