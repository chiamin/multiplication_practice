import { Operation } from './types'

export function checkAnswer(
  operation: Operation,
  a: number,
  b: number,
  userAnswer: number
): boolean {
  switch (operation) {
    case Operation.Add:      return userAnswer === a + b
    case Operation.Subtract: return userAnswer === a - b
    case Operation.Multiply: return userAnswer === a * b
    case Operation.Divide:   throw new Error('Use checkDivisionAnswer for division')
  }
}

export interface DivisionResult {
  correct: boolean
  error?: string
}

export function checkDivisionAnswer(
  a: number,
  b: number,
  quotient: number,
  remainder: number
): DivisionResult {
  if (remainder >= b) {
    return { correct: false, error: '餘數應該小於除數喔' }
  }
  const correctQuotient = Math.trunc(a / b)
  const correctRemainder = a % b
  return {
    correct: quotient === correctQuotient && remainder === correctRemainder,
  }
}
