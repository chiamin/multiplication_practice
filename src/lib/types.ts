export enum Operation {
  Add = 'add',
  Subtract = 'subtract',
  Multiply = 'multiply',
  Divide = 'divide',
  // 個位數 + 個位數，答案一定超過 10（有進位），例如 5 + 8
  AddCarry = 'add-carry',
  // 十幾 − 個位數，個位不夠減（一定要借位），例如 13 − 8
  SubtractBorrow = 'subtract-borrow',
}

export const OPERATION_SYMBOL: Record<Operation, string> = {
  [Operation.Add]: '+',
  [Operation.Subtract]: '−',
  [Operation.Multiply]: '×',
  [Operation.Divide]: '÷',
  [Operation.AddCarry]: '+',
  [Operation.SubtractBorrow]: '−',
}

export const OPERATION_LABEL: Record<Operation, string> = {
  [Operation.Add]: '加法',
  [Operation.Subtract]: '減法',
  [Operation.Multiply]: '乘法',
  [Operation.Divide]: '除法',
  [Operation.AddCarry]: '進位加法',
  [Operation.SubtractBorrow]: '借位減法',
}

export const OPERATION_ICON: Record<Operation, string> = {
  [Operation.Add]: 'add.png',
  [Operation.Subtract]: 'subtract.png',
  [Operation.Multiply]: 'multiply.png',
  [Operation.Divide]: 'divide.png',
  [Operation.AddCarry]: 'add.png',
  [Operation.SubtractBorrow]: 'subtract.png',
}

// 這兩種模式的題目由規則決定（一定進位／一定借位），忽略設定頁的數字範圍。
export const FIXED_RANGE_OPERATIONS: readonly Operation[] = [
  Operation.AddCarry,
  Operation.SubtractBorrow,
]

export interface Question {
  a: number
  b: number
  operation: Operation
}

export type AnswerField = 'quotient' | 'remainder'

export const QUESTION_COUNT_OPTIONS = [5, 10, 15, 20, 30]
