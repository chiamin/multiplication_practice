<script lang="ts">
  import { practice } from '../practiceStore.svelte'
  import { Operation } from '../types'

  const BASE = import.meta.env.BASE_URL

  const ROW1 = [1, 2, 3, 4, 5]
  const ROW2 = [6, 7, 8, 9, 0]

  const isDivide = $derived(practice.operation === Operation.Divide)
</script>

<div class="flex flex-col gap-2">
  <!-- Row 1: 1-5 + submit -->
  <div class="flex justify-center gap-2">
    {#each ROW1 as digit}
      <button
        class="flex h-14 w-14 items-center justify-center rounded-xl border border-slate-300
               bg-white text-2xl font-bold text-slate-700 shadow-sm active:bg-slate-100
               hover:border-slate-400 sm:h-16 sm:w-16 sm:text-3xl"
        onclick={() => practice.appendDigit(digit)}
      >
        {digit}
      </button>
    {/each}

    <!-- Submit -->
    <button
      class="flex h-14 w-14 items-center justify-center rounded-xl border border-blue-300
             bg-blue-50 shadow-sm active:bg-blue-100 hover:border-blue-400 sm:h-16 sm:w-16"
      onclick={() => practice.submitAnswer()}
      aria-label="送出答案"
    >
      <img src="{BASE}assets/icons/send.png" alt="送出" class="h-8 w-8 object-contain sm:h-9 sm:w-9" />
    </button>
  </div>

  <!-- Row 2: 6-0 + clear -->
  <div class="flex justify-center gap-2">
    {#each ROW2 as digit}
      <button
        class="flex h-14 w-14 items-center justify-center rounded-xl border border-slate-300
               bg-white text-2xl font-bold text-slate-700 shadow-sm active:bg-slate-100
               hover:border-slate-400 sm:h-16 sm:w-16 sm:text-3xl"
        onclick={() => practice.appendDigit(digit)}
      >
        {digit}
      </button>
    {/each}

    <!-- Clear active field -->
    <button
      class="flex h-14 w-14 items-center justify-center rounded-xl border border-blue-300
             bg-blue-50 shadow-sm active:bg-blue-100 hover:border-blue-400 sm:h-16 sm:w-16"
      onclick={() => practice.clearActiveInput()}
      aria-label="清除答案"
    >
      <img src="{BASE}assets/icons/eraser.png" alt="清除" class="h-8 w-8 object-contain sm:h-9 sm:w-9" />
    </button>
  </div>

  <!-- Division: field switcher -->
  {#if isDivide}
    <div class="flex justify-center gap-3">
      <button
        class="rounded-lg px-4 py-1.5 text-sm font-medium transition-colors
          {practice.activeField === 'quotient'
            ? 'bg-blue-500 text-white'
            : 'bg-slate-200 text-slate-600 hover:bg-slate-300'}"
        onclick={() => practice.setActiveField('quotient')}
      >
        輸入商
      </button>
      <button
        class="rounded-lg px-4 py-1.5 text-sm font-medium transition-colors
          {practice.activeField === 'remainder'
            ? 'bg-blue-500 text-white'
            : 'bg-slate-200 text-slate-600 hover:bg-slate-300'}"
        onclick={() => practice.setActiveField('remainder')}
      >
        輸入餘數
      </button>
    </div>
  {/if}
</div>
