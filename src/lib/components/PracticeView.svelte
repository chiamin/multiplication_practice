<script lang="ts">
  import { practice } from '../practiceStore.svelte'
  import QuestionDisplay from './QuestionDisplay.svelte'
  import NumericKeypad from './NumericKeypad.svelte'
  import HandwritingCanvas from './HandwritingCanvas.svelte'

  let questionKey = $derived(
    practice.question ? `${practice.question.a}-${practice.question.b}-${practice.answeredCount}` : ''
  )
</script>

<div class="flex h-full flex-col gap-3">
  <!-- Progress bar -->
  <div class="flex items-center gap-3">
    <div class="h-3 flex-1 overflow-hidden rounded-full bg-slate-200">
      <div
        class="h-full rounded-full bg-blue-500 transition-all duration-300"
        style="width: {(practice.progress * 100).toFixed(1)}%"
      ></div>
    </div>
    <span class="shrink-0 text-sm text-slate-500">
      第 {practice.currentQuestionNumber} / {practice.questionsPerSet} 題
    </span>
  </div>

  <!-- Question + answer boxes -->
  <QuestionDisplay />

  <!-- Feedback message -->
  <div class="min-h-7 text-center text-lg font-medium
    {practice.messageType === 'correct' ? 'text-green-600' :
     practice.messageType === 'wrong'   ? 'text-red-500'   :
                                           'text-amber-600'}">
    {practice.message}
  </div>

  <!-- Numeric keypad -->
  <NumericKeypad />

  <!-- Handwriting canvas (fills remaining space) -->
  <div class="min-h-0 flex-1">
    {#key questionKey}
      <HandwritingCanvas />
    {/key}
  </div>
</div>
