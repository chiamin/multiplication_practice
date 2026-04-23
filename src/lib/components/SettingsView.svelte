<script lang="ts">
  import { practice } from '../practiceStore.svelte'
  import { Operation, OPERATION_LABEL, OPERATION_ICON, QUESTION_COUNT_OPTIONS } from '../types'

  const BASE = import.meta.env.BASE_URL

  function clampRange(min: number, max: number): [number, number] {
    const lo = Math.max(0, Math.min(min, 999))
    const hi = Math.max(lo, Math.min(max, 999))
    return [lo, hi]
  }

  function onMinAInput(e: Event) {
    const v = parseInt((e.target as HTMLInputElement).value)
    if (!isNaN(v)) {
      const [lo] = clampRange(v, practice.maxA)
      practice.minA = lo
    }
  }

  function onMaxAInput(e: Event) {
    const v = parseInt((e.target as HTMLInputElement).value)
    if (!isNaN(v)) {
      const [, hi] = clampRange(practice.minA, v)
      practice.maxA = hi
    }
  }

  function onMinBInput(e: Event) {
    const v = parseInt((e.target as HTMLInputElement).value)
    if (!isNaN(v)) {
      const [lo] = clampRange(v, practice.maxB)
      practice.minB = lo
    }
  }

  function onMaxBInput(e: Event) {
    const v = parseInt((e.target as HTMLInputElement).value)
    if (!isNaN(v)) {
      const [, hi] = clampRange(practice.minB, v)
      practice.maxB = hi
    }
  }

  const operations = [Operation.Add, Operation.Subtract, Operation.Multiply, Operation.Divide]
</script>

<div class="flex flex-col gap-6 py-2">
  <h2 class="text-center text-xl font-bold text-slate-700">請選擇練習設定</h2>

  <!-- Operation selector -->
  <section>
    <p class="mb-2 text-sm font-medium text-slate-600">要練習的運算</p>
    <div class="grid grid-cols-4 gap-2">
      {#each operations as op}
        {@const selected = practice.operation === op}
        <button
          class="flex flex-col items-center gap-1.5 rounded-xl border-2 py-3 transition-colors
            {selected
              ? 'border-blue-500 bg-blue-50 text-blue-700'
              : 'border-slate-200 bg-white text-slate-600 hover:border-slate-300'}"
          onclick={() => (practice.operation = op)}
        >
          <img
            src="{BASE}assets/icons/{OPERATION_ICON[op]}"
            alt={OPERATION_LABEL[op]}
            class="h-8 w-8 object-contain"
          />
          <span class="text-sm font-medium">{OPERATION_LABEL[op]}</span>
        </button>
      {/each}
    </div>
  </section>

  <!-- Range A -->
  <section>
    <p class="mb-2 text-sm font-medium text-slate-600">第一個數字的範圍</p>
    <div class="flex items-center gap-3">
      <input
        id="minA"
        type="number"
        class="w-24 rounded-lg border border-slate-300 px-3 py-2 text-center text-base focus:border-blue-400 focus:outline-none"
        value={practice.minA}
        min="0" max="999"
        oninput={onMinAInput}
        aria-label="第一個數字最小值"
      />
      <span class="font-medium text-slate-500">～</span>
      <input
        id="maxA"
        type="number"
        class="w-24 rounded-lg border border-slate-300 px-3 py-2 text-center text-base focus:border-blue-400 focus:outline-none"
        value={practice.maxA}
        min="0" max="999"
        oninput={onMaxAInput}
        aria-label="第一個數字最大值"
      />
    </div>
  </section>

  <!-- Range B -->
  <section>
    <p class="mb-2 text-sm font-medium text-slate-600">第二個數字的範圍</p>
    <div class="flex items-center gap-3">
      <input
        type="number"
        class="w-24 rounded-lg border border-slate-300 px-3 py-2 text-center text-base focus:border-blue-400 focus:outline-none"
        value={practice.minB}
        min="0" max="999"
        oninput={onMinBInput}
        aria-label="第二個數字最小值"
      />
      <span class="font-medium text-slate-500">～</span>
      <input
        type="number"
        class="w-24 rounded-lg border border-slate-300 px-3 py-2 text-center text-base focus:border-blue-400 focus:outline-none"
        value={practice.maxB}
        min="0" max="999"
        oninput={onMaxBInput}
        aria-label="第二個數字最大值"
      />
    </div>
  </section>

  <!-- Question count -->
  <section>
    <p class="mb-2 text-sm font-medium text-slate-600">一次要練習幾題</p>
    <div class="flex flex-wrap gap-2">
      {#each QUESTION_COUNT_OPTIONS as count}
        {@const selected = practice.questionsPerSet === count}
        <button
          class="h-12 w-12 rounded-xl border-2 text-base font-bold transition-colors
            {selected
              ? 'border-green-500 bg-green-50 text-green-700'
              : 'border-slate-200 bg-white text-slate-600 hover:border-slate-300'}"
          onclick={() => (practice.questionsPerSet = count)}
        >
          {count}
        </button>
      {/each}
    </div>
  </section>

  <button
    class="mt-2 rounded-xl bg-blue-500 py-3 text-lg font-bold text-white hover:bg-blue-600 active:bg-blue-700"
    onclick={() => practice.startPractice()}
  >
    開始練習
  </button>
</div>
