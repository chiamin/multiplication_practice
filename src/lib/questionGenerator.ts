import { Operation } from './types'

function randomInt(min: number, max: number): number {
  if (min > max) [min, max] = [max, min]
  if (min === max) return min
  return min + Math.floor(Math.random() * (max - min + 1))
}

function generateAddition(minA: number, maxA: number, minB: number, maxB: number) {
  return { a: randomInt(minA, maxA), b: randomInt(minB, maxB) }
}

function generateSubtraction(minA: number, maxA: number, minB: number, maxB: number) {
  const b = randomInt(minB, maxB)
  const effectiveMinA = Math.max(minA, b)
  if (effectiveMinA > maxA) {
    const a = maxA
    const adjustedB = Math.min(b, a)
    return { a, b: Math.max(minB, Math.min(adjustedB, maxB)) }
  }
  return { a: randomInt(effectiveMinA, maxA), b }
}

// 進位加法：兩個個位數 (2~9) 相加，和一定 ≥ 10，例如 5 + 8。
// 直接挑 a，再從能讓 a + b ≥ 10 的 b 裡挑，保證一次就中。
function generateAddWithCarry() {
  const a = randomInt(2, 9)
  const b = randomInt(Math.max(2, 10 - a), 9)
  return { a, b }
}

// 借位減法：十幾 (11~18) 減個位數 (2~9)，個位一定不夠減，例如 13 − 8。
// 先挑被減數 a，b 必須 > a 的個位數（才要借位）且 ≤ 9，同時 a − b ≥ 1。
function generateSubtractWithBorrow() {
  const a = randomInt(11, 18)
  const ones = a % 10
  const minB = ones + 1        // 大於個位數 → 一定要借位
  const maxB = Math.min(9, a - 1) // 不讓答案變成 0 或負數
  return { a, b: randomInt(minB, maxB) }
}

function generateMultiplication(minA: number, maxA: number, minB: number, maxB: number) {
  return { a: randomInt(minA, maxA), b: randomInt(minB, maxB) }
}

function generateDivision(minA: number, maxA: number, minB: number, maxB: number) {
  const MAX_TRIES = 500

  // Strategy 1: pick b, derive valid quotient range
  for (let i = 0; i < MAX_TRIES; i++) {
    const b = randomInt(minB, maxB)
    const minQ = Math.max(1, Math.ceil((minA - (b - 1)) / b))
    const maxQ = Math.min(999, Math.floor(maxA / b))
    if (minQ > maxQ) continue
    const q = randomInt(minQ, maxQ)
    const r = Math.floor(Math.random() * b)
    const a = b * q + r
    if (a >= minA && a <= maxA) return { a, b }
  }

  // Strategy 2: pick a, derive valid b
  for (let i = 0; i < MAX_TRIES; i++) {
    const a = randomInt(minA, maxA)
    const maxBForA = Math.min(maxB, a)
    if (maxBForA < minB) continue
    const b = randomInt(minB, maxBForA)
    if (b > 0) return { a, b }
  }

  // Fallback
  const a = Math.max(minA, minB)
  const b = minB
  return { a: Math.max(a, b), b }
}

export function generateQuestion(
  operation: Operation,
  minA: number, maxA: number,
  minB: number, maxB: number
): { a: number; b: number } {
  switch (operation) {
    case Operation.Add:      return generateAddition(minA, maxA, minB, maxB)
    case Operation.Subtract: return generateSubtraction(minA, maxA, minB, maxB)
    case Operation.Multiply: return generateMultiplication(minA, maxA, minB, maxB)
    case Operation.Divide:   return generateDivision(minA, maxA, minB, maxB)
    // 這兩種靠規則決定範圍，不吃設定頁的 min/max
    case Operation.AddCarry:        return generateAddWithCarry()
    case Operation.SubtractBorrow:  return generateSubtractWithBorrow()
  }
}
