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
  }
}
