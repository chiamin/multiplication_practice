export enum Operation {
  Add = 'add',
  Subtract = 'subtract',
  Multiply = 'multiply',
  Divide = 'divide',
}

export const OPERATION_SYMBOL: Record<Operation, string> = {
  [Operation.Add]: '+',
  [Operation.Subtract]: '−',
  [Operation.Multiply]: '×',
  [Operation.Divide]: '÷',
}

export const OPERATION_LABEL: Record<Operation, string> = {
  [Operation.Add]: '加法',
  [Operation.Subtract]: '減法',
  [Operation.Multiply]: '乘法',
  [Operation.Divide]: '除法',
}

export const OPERATION_ICON: Record<Operation, string> = {
  [Operation.Add]: 'add.png',
  [Operation.Subtract]: 'subtract.png',
  [Operation.Multiply]: 'multiply.png',
  [Operation.Divide]: 'divide.png',
}

export interface Question {
  a: number
  b: number
  operation: Operation
}

export type AnswerField = 'quotient' | 'remainder'

export const QUESTION_COUNT_OPTIONS = [5, 10, 15, 20, 30]
