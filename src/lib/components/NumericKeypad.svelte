<script lang="ts">
  import { practice } from '../practiceStore.svelte'
  import { Operation } from '../types'

  const BASE = import.meta.env.BASE_URL

  const ROW1 = [1, 2, 3, 4, 5]
  const ROW2 = [6, 7, 8, 9, 0]

  const isDivide = $derived(practice.operation === Operation.Divide)
  // Disable the whole keypad while an answer is being processed (the 800ms
  // correct-answer feedback window), so a fast double-tap can't double-count.
  const locked = $derived(practice.submitting)
</script>

<div class="flex flex-col gap-2">
  <!-- Row 1: 1-5 + submit -->
  <div class="flex justify-center gap-2">
    {#each ROW1 as digit}
      <button
        class="flex h-20 w-20 items-center justify-center rounded-xl border border-slate-300
               bg-white text-4xl font-bold text-slate-700 shadow-sm active:bg-slate-100
               hover:border-slate-400 sm:h-24 sm:w-24 sm:text-5xl
               disabled:opacity-40 disabled:active:bg-white disabled:hover:border-slate-300"
        disabled={locked}
        onclick={() => practice.appendDigit(digit)}
      >
        {digit}
      </button>
    {/each}

    <!-- Submit -->
    <button
      class="flex h-20 w-20 items-center justify-center rounded-xl border border-blue-300
             bg-blue-50 shadow-sm active:bg-blue-100 hover:border-blue-400 sm:h-24 sm:w-24
             disabled:opacity-40 disabled:active:bg-blue-50 disabled:hover:border-blue-300"
      disabled={locked}
      onclick={() => practice.submitAnswer()}
      aria-label="送出答案"
    >
      <img src="{BASE}assets/icons/send.png" alt="送出" class="h-12 w-12 object-contain sm:h-14 sm:w-14" />
    </button>
  </div>

  <!-- Row 2: 6-0 + clear -->
  <div class="flex justify-center gap-2">
    {#each ROW2 as digit}
      <button
        class="flex h-20 w-20 items-center justify-center rounded-xl border border-slate-300
               bg-white text-4xl font-bold text-slate-700 shadow-sm active:bg-slate-100
               hover:border-slate-400 sm:h-24 sm:w-24 sm:text-5xl
               disabled:opacity-40 disabled:active:bg-white disabled:hover:border-slate-300"
        disabled={locked}
        onclick={() => practice.appendDigit(digit)}
      >
        {digit}
      </button>
    {/each}

    <!-- Clear active field -->
    <button
      class="flex h-20 w-20 items-center justify-center rounded-xl border border-blue-300
             bg-blue-50 shadow-sm active:bg-blue-100 hover:border-blue-400 sm:h-24 sm:w-24
             disabled:opacity-40 disabled:active:bg-blue-50 disabled:hover:border-blue-300"
      disabled={locked}
      onclick={() => practice.clearActiveInput()}
      aria-label="清除答案"
    >
      <img src="{BASE}assets/icons/eraser.png" alt="清除" class="h-12 w-12 object-contain sm:h-14 sm:w-14" />
    </button>
  </div>

  <!-- Division: field switcher -->
  {#if isDivide}
    <div class="flex justify-center gap-3">
      <button
        class="rounded-lg px-6 py-2.5 text-lg font-medium transition-colors disabled:opacity-40
          {practice.activeField === 'quotient'
            ? 'bg-blue-500 text-white'
            : 'bg-slate-200 text-slate-600 hover:bg-slate-300'}"
        disabled={locked}
        onclick={() => practice.setActiveField('quotient')}
      >
        輸入商
      </button>
      <button
        class="rounded-lg px-6 py-2.5 text-lg font-medium transition-colors disabled:opacity-40
          {practice.activeField === 'remainder'
            ? 'bg-blue-500 text-white'
            : 'bg-slate-200 text-slate-600 hover:bg-slate-300'}"
        disabled={locked}
        onclick={() => practice.setActiveField('remainder')}
      >
        輸入餘數
      </button>
    </div>
  {/if}
</div>
