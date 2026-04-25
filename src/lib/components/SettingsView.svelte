<script lang="ts">
  import { practice } from '../practiceStore.svelte'
  import { Operation, OPERATION_LABEL, OPERATION_ICON, QUESTION_COUNT_OPTIONS } from '../types'
  import { TOTAL_LEVELS } from '../levels'

  const BASE = import.meta.env.BASE_URL

  let nameInput = $state('')
  const MAX_NAME_LEN = 12

  function trimmedName() {
    return nameInput.trim().slice(0, MAX_NAME_LEN)
  }

  function onAddProfile() {
    const name = trimmedName()
    if (!name) return
    practice.addProfile(name)
    nameInput = ''
  }

  const nameExists = $derived(
    !!trimmedName() && practice.profiles.some((p) => p.name === trimmedName()),
  )

  function pickProfile(name: string) {
    practice.startGameMode(name)
    nameInput = ''
  }

  function removeProfile(name: string) {
    if (confirm(`真的要刪掉「${name}」的進度嗎？`)) {
      practice.deleteProfile(name)
    }
  }

  function passedCount(unlocked: number): number {
    return Math.min(TOTAL_LEVELS, Math.max(0, unlocked - 1))
  }

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
  <h2 class="text-center text-2xl font-bold text-slate-700">請選擇練習設定</h2>

  <!-- Operation selector -->
  <section>
    <p class="mb-2 text-base font-semibold text-slate-600">要練習的運算</p>
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
            class="h-9 w-9 object-contain"
          />
          <span class="text-base font-semibold">{OPERATION_LABEL[op]}</span>
        </button>
      {/each}
    </div>
  </section>

  <!-- Range A -->
  <section>
    <p class="mb-2 text-base font-semibold text-slate-600">第一個數字的範圍</p>
    <div class="flex items-center gap-3">
      <input
        id="minA"
        type="number"
        class="w-28 rounded-lg border border-slate-300 px-3 py-2.5 text-center text-lg focus:border-blue-400 focus:outline-none"
        value={practice.minA}
        min="0" max="999"
        oninput={onMinAInput}
        aria-label="第一個數字最小值"
      />
      <span class="text-lg font-medium text-slate-500">～</span>
      <input
        id="maxA"
        type="number"
        class="w-28 rounded-lg border border-slate-300 px-3 py-2.5 text-center text-lg focus:border-blue-400 focus:outline-none"
        value={practice.maxA}
        min="0" max="999"
        oninput={onMaxAInput}
        aria-label="第一個數字最大值"
      />
    </div>
  </section>

  <!-- Range B -->
  <section>
    <p class="mb-2 text-base font-semibold text-slate-600">第二個數字的範圍</p>
    <div class="flex items-center gap-3">
      <input
        type="number"
        class="w-28 rounded-lg border border-slate-300 px-3 py-2.5 text-center text-lg focus:border-blue-400 focus:outline-none"
        value={practice.minB}
        min="0" max="999"
        oninput={onMinBInput}
        aria-label="第二個數字最小值"
      />
      <span class="text-lg font-medium text-slate-500">～</span>
      <input
        type="number"
        class="w-28 rounded-lg border border-slate-300 px-3 py-2.5 text-center text-lg focus:border-blue-400 focus:outline-none"
        value={practice.maxB}
        min="0" max="999"
        oninput={onMaxBInput}
        aria-label="第二個數字最大值"
      />
    </div>
  </section>

  <!-- Question count -->
  <section>
    <p class="mb-2 text-base font-semibold text-slate-600">一次要練習幾題</p>
    <div class="flex flex-wrap gap-2">
      {#each QUESTION_COUNT_OPTIONS as count}
        {@const selected = practice.questionsPerSet === count}
        <button
          class="h-14 w-14 rounded-xl border-2 text-lg font-bold transition-colors
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
    class="mt-2 rounded-xl bg-blue-500 py-3.5 text-xl font-bold text-white hover:bg-blue-600 active:bg-blue-700"
    onclick={() => practice.startPractice()}
  >
    開始練習
  </button>

  <!-- Divider -->
  <div class="my-1 flex items-center gap-3 text-sm font-medium text-slate-400">
    <div class="h-px flex-1 bg-slate-200"></div>
    <span>或進入遊戲模式 🐰</span>
    <div class="h-px flex-1 bg-slate-200"></div>
  </div>

  <!-- Game mode: name input + profiles -->
  <section>
    <p class="mb-2 text-base font-semibold text-slate-600">新增名字</p>
    <div class="flex gap-2">
      <input
        type="text"
        class="flex-1 rounded-lg border border-slate-300 px-3 py-2.5 text-lg focus:border-pink-400 focus:outline-none"
        placeholder="例如：小明"
        bind:value={nameInput}
        maxlength={MAX_NAME_LEN}
        onkeydown={(e) => { if (e.key === 'Enter') onAddProfile() }}
        aria-label="玩家名字"
      />
      <button
        class="rounded-lg bg-gradient-to-r from-pink-400 to-orange-400 px-5 py-2.5 text-lg font-bold text-white shadow-sm hover:from-pink-500 hover:to-orange-500 disabled:cursor-not-allowed disabled:opacity-40"
        onclick={onAddProfile}
        disabled={!nameInput.trim() || nameExists}
      >
        新增
      </button>
    </div>
    {#if nameExists}
      <p class="mt-1.5 text-sm text-pink-500">這個名字已經存在了，點下面的名字就可以進入遊戲。</p>
    {/if}

    {#if practice.profiles.length > 0}
      <p class="mt-3 mb-2 text-sm font-medium text-slate-500">點名字進入遊戲：</p>
      <div class="flex flex-wrap gap-2.5">
        {#each practice.profiles as p (p.name)}
          <div class="relative">
            <button
              class="flex items-center gap-2 rounded-full border border-slate-200 bg-white py-2 pl-4 pr-9 text-base font-semibold text-slate-700 shadow-sm hover:border-pink-300 hover:bg-pink-50"
              onclick={() => pickProfile(p.name)}
            >
              <span class="text-lg">🐰</span>
              <span>{p.name}</span>
              <span class="text-sm font-normal text-slate-400">
                · {passedCount(p.unlockedLevel)}/{TOTAL_LEVELS} 關
              </span>
              {#if p.flowers > 0}
                <span class="text-sm font-semibold text-pink-400">🌸×{p.flowers}</span>
              {/if}
            </button>
            <button
              class="absolute -top-1.5 -right-1.5 flex h-6 w-6 items-center justify-center rounded-full bg-slate-400 text-sm font-bold text-white shadow-sm hover:bg-red-500"
              onclick={() => removeProfile(p.name)}
              aria-label="刪掉 {p.name}"
              title="刪掉這個名字的進度"
            >
              ×
            </button>
          </div>
        {/each}
      </div>
    {/if}
  </section>
</div>
