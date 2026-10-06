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

// 進位加法：兩位數 + 個位數，個位相加一定超過 10（要進位），例如 38 + 9。
// 先挑 a 的個位（1~9，0 不可能進位），再挑能讓個位和 ≥ 10 的 b；
// 十位挑 1~9，所以 a 落在 11~99。
function generateAddWithCarry() {
  const ones = randomInt(1, 9)
  const tens = randomInt(1, 9)
  const a = tens * 10 + ones
  const b = randomInt(10 - ones, 9) // ones + b ≥ 10 → 一定進位
  return { a, b }
}

// 借位減法：兩位數 − 個位數，個位一定不夠減（要向十位借），例如 71 − 3。
// 先挑 a 的個位（0~8，9 減任何個位數都不必借），b 必須 > 個位數才會借位；
// 十位挑 1~9，所以 a 落在 10~98，答案一定 ≥ 1。
function generateSubtractWithBorrow() {
  const ones = randomInt(0, 8)
  const tens = randomInt(1, 9)
  const a = tens * 10 + ones
  const b = randomInt(ones + 1, 9) // 大於個位數 → 一定要借位
  return { a, b }
}

function generateMultiplication(minA: number, maxA: number, minB: number, maxB: number) {
  return { a: randomInt(minA, maxA), b: randomInt(minB, maxB) }
}

// 帶零乘法：兩個因數中至少一個帶 0（例如 20、101、300），另一個不限。
function splitByZero(min: number, max: number): { zero: number[]; other: number[] } {
  if (min > max) [min, max] = [max, min]
  const zero: number[] = []
  const other: number[] = []
  for (let n = min; n <= max; n++) (String(n).includes('0') ? zero : other).push(n)
  return { zero, other }
}

function pick(nums: number[]): number {
  return nums[Math.floor(Math.random() * nums.length)]
}

// 沿用設定頁的範圍（上限 999，直接列舉就好），在所有合格的 (a, b) 組合中均勻抽一組：
// 合格組合 = 「a 帶 0、b 任意」加上「a 不帶 0、b 帶 0」，兩塊不重疊，按組合數決定抽哪塊。
// 兩個範圍都沒有帶 0 的數字（例如 11~19 × 1~9）時，退回一般乘法。
function generateMultiplyWithZero(minA: number, maxA: number, minB: number, maxB: number) {
  const A = splitByZero(minA, maxA)
  const B = splitByZero(minB, maxB)
  const aZeroPairs = A.zero.length * (B.zero.length + B.other.length)
  const bZeroPairs = A.other.length * B.zero.length
  if (aZeroPairs + bZeroPairs === 0) return generateMultiplication(minA, maxA, minB, maxB)
  if (Math.random() * (aZeroPairs + bZeroPairs) < aZeroPairs) {
    return { a: pick(A.zero), b: pick([...B.zero, ...B.other]) }
  }
  return { a: pick(A.other), b: pick(B.zero) }
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
    case Operation.MultiplyZero:    return generateMultiplyWithZero(minA, maxA, minB, maxB)
    // 這兩種靠規則決定範圍，不吃設定頁的 min/max
    case Operation.AddCarry:        return generateAddWithCarry()
    case Operation.SubtractBorrow:  return generateSubtractWithBorrow()
  }
}
