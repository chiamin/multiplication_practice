import { Operation } from './types'

/**
 * 熟練度 / 出題權重公式
 * ─────────────────────
 * 每一題記一個「難度分」difficulty（0 = 很熟，1 = 很不熟），依每次作答的
 * 「答對／答錯」與「花多少秒」更新，再由難度分換算成出題權重。
 *
 * 為什麼用 0~1 的連續分數，而不是原本的整數次數：
 *   - 時間是連續量，「3 秒答對」和「12 秒答對」該有不同待遇，整數 ±1 表達不了。
 *   - 有上下界（clamp 到 0~1）就不會像累加計數那樣無限膨脹，權重也就有天花板。
 *
 * ## 1. 單次作答的表現分 performance ∈ [0, 1]
 * 1 = 表現完美（很快就答對），0 = 表現最差（答錯）。
 *
 *   答錯       → performance = 0
 *   一次答對   → performance = clamp01((SLOW_SEC - t) / (SLOW_SEC - FAST_SEC))
 *
 * 也就是在 FAST_SEC 秒內答完給滿分 1，超過 SLOW_SEC 秒給 0，中間線性內插。
 * 例：FAST=2、SLOW=10 → 2 秒→1.0、4 秒→0.75、6 秒→0.5、10 秒以上→0。
 * 用線性而非指數，是為了讓「快一秒」在整個區間的效果一致，好預測也好調參。
 *
 * ## 2. 難度分用指數移動平均（EMA）更新
 *
 *   difficulty ← clamp01( difficulty + LEARNING_RATE × (target - difficulty) )
 *   其中 target = 1 - performance
 *
 * EMA 的好處是「近期表現權重高、舊紀錄自然淡出」，孩子進步後分數會跟著下降，
 * 不需要另外做遺忘或衰減邏輯。LEARNING_RATE 越大則反應越快、越不穩。
 * 答錯時額外把難度分往上推至少 WRONG_FLOOR，確保「答錯過的題目」一定會被
 * 明顯地重新排進複習池——這是使用者明確要求的「答錯就把機率盡量升高」。
 *
 * ## 3. 難度分換算出題權重
 *
 *   weight = MIN_WEIGHT + (MAX_WEIGHT - MIN_WEIGHT) × difficulty ^ WEIGHT_EXPONENT
 *
 * WEIGHT_EXPONENT > 1 讓高難度分的題目權重拉開得更兇（凸函數），
 * 例：exponent=2、MIN=1、MAX=25 → difficulty 0.5 → 7，0.8 → 16.4，1.0 → 25。
 * 也就是最不熟的題目出現機率可達最熟題目的 25 倍。
 */

// ── 可調參數 ──

/** 這個秒數內答對算「很快」（表現滿分）。 */
export const FAST_SEC = 2
/** 超過這個秒數答對就算「很慢」（表現 0 分，與答錯同級的難度貢獻，但不觸發 WRONG_FLOOR）。 */
export const SLOW_SEC = 10
/** EMA 學習率：每次作答把難度分往目標值移動這個比例。 */
export const LEARNING_RATE = 0.5
/** 答錯後難度分至少要到這個值（把答錯的題目強力推回複習池）。 */
export const WRONG_FLOOR = 0.85
/** 熟到難度分低於這個值就從紀錄裡移除（畢業，不再佔空間）。 */
export const MASTERED_THRESHOLD = 0.05
/** 難度分 0 的題目權重。 */
export const MIN_WEIGHT = 1
/** 難度分 1 的題目權重（相對 MIN_WEIGHT 的倍率上限）。 */
export const MAX_WEIGHT = 25
/** 權重曲線的凸度，>1 表示越不熟的題目權重拉開越大。 */
export const WEIGHT_EXPONENT = 2

/** 新題目（沒有任何紀錄）的預設難度分，介於中間偏低。 */
export const DEFAULT_DIFFICULTY = 0.3

export function clamp01(x: number): number {
  if (!Number.isFinite(x)) return 0
  return x < 0 ? 0 : x > 1 ? 1 : x
}

/**
 * 單次作答的表現分：1 = 很快答對，0 = 答錯或慢到超過 SLOW_SEC。
 * elapsedSec 只在答對時有意義。
 */
export function performanceScore(correct: boolean, elapsedSec: number): number {
  if (!correct) return 0
  if (!Number.isFinite(elapsedSec) || elapsedSec <= FAST_SEC) return 1
  if (elapsedSec >= SLOW_SEC) return 0
  return clamp01((SLOW_SEC - elapsedSec) / (SLOW_SEC - FAST_SEC))
}

/**
 * 用一次作答結果更新難度分。答錯時保證難度分被推到 WRONG_FLOOR 以上。
 * 回傳新的難度分（0~1）。
 */
export function updateDifficulty(
  prev: number,
  correct: boolean,
  elapsedSec: number,
): number {
  const current = clamp01(prev)
  const target = 1 - performanceScore(correct, elapsedSec)
  const moved = clamp01(current + LEARNING_RATE * (target - current))
  // 答錯：難度分一律拉到 WRONG_FLOOR 以上，確保會被重新複習到
  return correct ? moved : Math.max(moved, WRONG_FLOOR)
}

/** 難度分換算成加權抽題用的權重（凸函數，越不熟拉開越大）。 */
export function difficultyWeight(difficulty: number): number {
  const d = clamp01(difficulty)
  return MIN_WEIGHT + (MAX_WEIGHT - MIN_WEIGHT) * Math.pow(d, WEIGHT_EXPONENT)
}

/** 難度分是否已低到可以從紀錄移除（已熟練）。 */
export function isMastered(difficulty: number): boolean {
  return clamp01(difficulty) < MASTERED_THRESHOLD
}

// ── 紀錄結構 ──

/** 單一題目的作答紀錄。difficulty 0 = 很熟、1 = 很不熟。 */
export interface QuestionStat {
  op: Operation
  a: number
  b: number
  /** 難度分 0~1，由 updateDifficulty 維護。 */
  difficulty: number
  /** 累計作答次數（僅供顯示／除錯）。 */
  attempts: number
  /** 累計第一次就答錯的次數（僅供顯示／除錯）。 */
  wrongs: number
  /** 最近一次一次答對所花的秒數；沒答對過則為 null。 */
  lastSec: number | null
}
