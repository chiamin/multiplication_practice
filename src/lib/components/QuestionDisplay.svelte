<script lang="ts">
  import { practice } from '../practiceStore.svelte'
  import { Operation, OPERATION_SYMBOL } from '../types'

  function onInputKeydown(e: KeyboardEvent, field: 'quotient' | 'remainder') {
    // Ignore input edits while an answer is being processed (mirrors the
    // keypad lock). Enter still falls through to submitAnswer(), which has its
    // own re-entrancy guard.
    if (practice.submitting && e.key !== 'Enter') {
      if (/^\d$/.test(e.key) || e.key === 'Backspace' || e.key === 'Tab') e.preventDefault()
      return
    }
    if (/^\d$/.test(e.key)) {
      e.preventDefault()
      practice.setActiveField(field)
      if (field === 'quotient') {
        practice.quotientInput += e.key
      } else {
        practice.remainderInput += e.key
      }
    } else if (e.key === 'Backspace') {
      e.preventDefault()
      practice.setActiveField(field)
      if (field === 'quotient') {
        practice.quotientInput = practice.quotientInput.slice(0, -1)
      } else {
        practice.remainderInput = practice.remainderInput.slice(0, -1)
      }
    } else if (e.key === 'Enter') {
      e.preventDefault()
      practice.submitAnswer()
    } else if (e.key === 'Tab' && practice.operation === Operation.Divide) {
      e.preventDefault()
      practice.setActiveField(field === 'quotient' ? 'remainder' : 'quotient')
    }
  }
</script>

{#if practice.question}
  {@const { a, b } = practice.question}
  {@const sym = OPERATION_SYMBOL[practice.operation]}
  {@const isDivide = practice.operation === Operation.Divide}

  <div
    class="flex flex-nowrap items-center justify-center font-bold text-slate-800
      {isDivide
        ? 'gap-2 text-4xl sm:gap-3 sm:text-8xl'
        : 'gap-3 text-6xl sm:text-8xl'}"
  >
    <span class="whitespace-nowrap">{a} {sym} {b} =</span>

    {#if isDivide}
      <!-- Quotient box -->
      <button
        class="min-w-12 rounded-xl border-2 px-2 py-2 text-center font-bold transition-colors sm:min-w-24 sm:px-4
          {practice.activeField === 'quotient'
            ? 'border-blue-500 bg-blue-50 text-blue-700'
            : 'border-slate-300 bg-white text-slate-700'}"
        onclick={() => practice.setActiveField('quotient')}
        onkeydown={(e) => onInputKeydown(e, 'quotient')}
      >
        {practice.quotientInput || ' '}
      </button>

      <span class="text-2xl text-slate-500 sm:text-5xl">...</span>

      <!-- Remainder box -->
      <button
        class="min-w-12 rounded-xl border-2 px-2 py-2 text-center font-bold transition-colors sm:min-w-24 sm:px-4
          {practice.activeField === 'remainder'
            ? 'border-blue-500 bg-blue-50 text-blue-700'
            : 'border-slate-300 bg-white text-slate-700'}"
        onclick={() => practice.setActiveField('remainder')}
        onkeydown={(e) => onInputKeydown(e, 'remainder')}
      >
        {practice.remainderInput || ' '}
      </button>
    {:else}
      <!-- Single answer box -->
      <button
        class="min-w-20 rounded-xl border-2 border-slate-300 bg-white px-3 py-2
               text-center text-6xl font-bold text-slate-700 focus:border-blue-500 focus:outline-none sm:min-w-32 sm:px-4 sm:text-8xl"
        onkeydown={(e) => onInputKeydown(e, 'quotient')}
      >
        {practice.quotientInput || ' '}
      </button>
    {/if}
  </div>

  {#if practice.operation === Operation.Divide}
    <p class="mt-2 text-center text-sm text-slate-400">Tab 切換商／餘數，Enter 送出</p>
  {/if}
{/if}
