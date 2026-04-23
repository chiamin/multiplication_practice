<script lang="ts">
  import { practice } from '../practiceStore.svelte'
  import { Operation, OPERATION_SYMBOL } from '../types'

  function onInputKeydown(e: KeyboardEvent, field: 'quotient' | 'remainder') {
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

  <div class="flex items-center justify-center gap-2 text-4xl font-bold text-slate-800 sm:text-5xl">
    <span>{a} {sym} {b} =</span>

    {#if isDivide}
      <!-- Quotient box -->
      <button
        class="min-w-16 rounded-xl border-2 px-3 py-1 text-center text-4xl font-bold transition-colors
          {practice.activeField === 'quotient'
            ? 'border-blue-500 bg-blue-50 text-blue-700'
            : 'border-slate-300 bg-white text-slate-700'}"
        onclick={() => practice.setActiveField('quotient')}
        onkeydown={(e) => onInputKeydown(e, 'quotient')}
      >
        {practice.quotientInput || ' '}
      </button>

      <span class="text-3xl text-slate-500">...</span>

      <!-- Remainder box -->
      <button
        class="min-w-16 rounded-xl border-2 px-3 py-1 text-center text-4xl font-bold transition-colors
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
        class="min-w-20 rounded-xl border-2 border-slate-300 bg-white px-3 py-1
               text-center text-4xl font-bold text-slate-700 focus:border-blue-500 focus:outline-none sm:text-5xl"
        onkeydown={(e) => onInputKeydown(e, 'quotient')}
      >
        {practice.quotientInput || ' '}
      </button>
    {/if}
  </div>

  {#if practice.operation === Operation.Divide}
    <p class="mt-1 text-center text-xs text-slate-400">Tab 切換商／餘數，Enter 送出</p>
  {/if}
{/if}
