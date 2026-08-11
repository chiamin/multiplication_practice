<script lang="ts">
  import { practice } from '../practiceStore.svelte'
  import {
    Operation,
    OPERATION_LABEL,
    OPERATION_ICON,
    QUESTION_COUNT_OPTIONS,
    FIXED_RANGE_OPERATIONS,
  } from '../types'
  import { TOTAL_LEVELS } from '../levels'

  const BASE = import.meta.env.BASE_URL

  let nameInput = $state('')
  const MAX_NAME_LEN = 12

  function trimmedName() {
    return nameInput.trim().slice(0, MAX_NAME_LEN)
  }

  const nameExists = $derived(
    !!trimmedName() && practice.profiles.some((p) => p.name === trimmedName()),
  )

  function pickProfile(name: string) {
    // Dismiss the iOS keyboard before any reactive churn — the dvh-shrink-then-grow
    // transition would otherwise run concurrently with the next click, and any
    // layout work during that window uses a stale viewport height.
    ;(document.activeElement as HTMLElement)?.blur()
    // 點名字只切換身分，不直接進遊戲——下面兩個按鈕才決定要玩哪一種模式
    practice.selectProfile(practice.currentProfileName === name ? null : name)
    nameInput = ''
  }

  function onAddAndSelect() {
    const name = trimmedName()
    if (!name) return
    ;(document.activeElement as HTMLElement)?.blur()
    practice.selectProfile(name)
    nameInput = ''
  }

  function resetStats() {
    const name = practice.currentProfileName
    if (!name) return
    if (confirm(`要把「${name}」的答題紀錄清空嗎？（關卡進度和小花不會清掉）`)) {
      practice.resetCurrentStats()
    }
  }

  function removeProfile(name: string) {
    if (confirm(`真的要刪掉「${name}」的進度嗎？`)) {
      practice.deleteProfile(name)
    }
  }

  function passedCount(unlocked: number): number {
    return Math.min(TOTAL_LEVELS, Math.max(0, unlocked - 1))
  }

  // 每滿 10 朵小花進位成 1 顆星星（與 store 的 FLOWERS_PER_STAR 一致）
  const FLOWERS_PER_STAR = 10
  const stars = (flowers: number) => Math.floor(flowers / FLOWERS_PER_STAR)
  const flowerRemainder = (flowers: number) => flowers % FLOWERS_PER_STAR

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

  const operations = [
    Operation.Add,
    Operation.Subtract,
    Operation.Multiply,
    Operation.Divide,
    Operation.AddCarry,
    Operation.SubtractBorrow,
  ]

  // 進位加法／借位減法的題目由規則決定，數字範圍設定用不到，直接藏起來。
  const fixedRange = $derived(FIXED_RANGE_OPERATIONS.includes(practice.operation))

  const FIXED_RANGE_HINT: Partial<Record<Operation, string>> = {
    [Operation.AddCarry]: '兩位數加個位數、個位一定要進位的題目，例如 38 + 9。',
    [Operation.SubtractBorrow]: '兩位數減個位數、個位一定要借位的題目，例如 71 − 3。',
  }
</script>

<div class="flex flex-col gap-6 py-2">
  <h2 class="text-center text-2xl font-bold text-slate-700">請選擇練習設定</h2>

  <!-- 玩家選擇：兩種模式共用同一個身分，答題紀錄才能互通 -->
  <section class="rounded-2xl border-2 border-pink-200 bg-pink-50/60 p-4">
    <p class="mb-2 text-base font-semibold text-slate-700">
      <span class="text-lg">🐰</span> 今天是誰要練習？
    </p>

    {#if practice.profiles.length > 0}
      <div class="mb-3 flex flex-wrap gap-2.5">
        {#each practice.profiles as p (p.name)}
          {@const selected = practice.currentProfileName === p.name}
          <div class="relative">
            <button
              class="flex items-center gap-2 rounded-full border-2 py-2 pl-4 pr-9 text-base font-semibold shadow-sm transition-colors
                {selected
                  ? 'border-pink-500 bg-white text-pink-700'
                  : 'border-slate-200 bg-white text-slate-700 hover:border-pink-300'}"
              onclick={() => pickProfile(p.name)}
            >
              <span class="text-lg">{selected ? '✅' : '🐰'}</span>
              <span>{p.name}</span>
              <span class="text-sm font-normal text-slate-400">
                · {passedCount(p.unlockedLevel)}/{TOTAL_LEVELS} 關
              </span>
              {#if p.flowers > 0}
                <span class="flex items-center gap-1 text-sm font-semibold">
                  {#if stars(p.flowers) > 0}
                    <span class="text-amber-500">🌟×{stars(p.flowers)}</span>
                  {/if}
                  {#if flowerRemainder(p.flowers) > 0}
                    <span class="text-pink-400">🌸×{flowerRemainder(p.flowers)}</span>
                  {/if}
                </span>
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

    <div class="flex gap-2">
      <input
        type="text"
        class="flex-1 rounded-lg border border-slate-300 bg-white px-3 py-2.5 text-lg focus:border-pink-400 focus:outline-none"
        placeholder="新名字，例如：小明"
        bind:value={nameInput}
        maxlength={MAX_NAME_LEN}
        onkeydown={(e) => { if (e.key === 'Enter') onAddAndSelect() }}
        aria-label="玩家名字"
      />
      <button
        class="rounded-lg bg-gradient-to-r from-pink-400 to-orange-400 px-5 py-2.5 text-lg font-bold text-white shadow-sm hover:from-pink-500 hover:to-orange-500 disabled:cursor-not-allowed disabled:opacity-40"
        onclick={onAddAndSelect}
        disabled={!nameInput.trim() || nameExists}
      >
        新增
      </button>
    </div>
    {#if nameExists}
      <p class="mt-1.5 text-sm text-pink-600">這個名字已經有了，直接點上面的名字就好。</p>
    {/if}

    {#if practice.currentProfileName}
      <p class="mt-2.5 text-sm text-slate-600">
        會記住 <span class="font-semibold text-pink-700">{practice.currentProfileName}</span>
        答錯和答得比較慢的題目，之後兩種模式都會多出現這些題。
        {#if practice.reviewPoolSize > 0}
          <button class="ml-1 underline hover:text-red-500" onclick={resetStats}>
            （目前 {practice.reviewPoolSize} 題要加強，清掉）
          </button>
        {/if}
      </p>
    {:else}
      <p class="mt-2.5 text-sm text-slate-500">
        先選一個名字，才能記住常錯的題目、下次多出現。不選也可以直接練習。
      </p>
    {/if}
  </section>

  <!-- Operation selector -->
  <section>
    <p class="mb-2 text-base font-semibold text-slate-600">要練習的運算</p>
    <div class="grid grid-cols-3 gap-2">
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

  {#if fixedRange}
    <!-- 進位加法／借位減法：題目範圍固定，說明一下就好 -->
    <p class="rounded-xl bg-amber-50 px-4 py-3 text-base text-amber-800">
      {FIXED_RANGE_HINT[practice.operation]}
    </p>
  {:else}
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
  {/if}

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
    <span>或玩闖關遊戲 🐰</span>
    <div class="h-px flex-1 bg-slate-200"></div>
  </div>

  <!-- 遊戲模式：用上面選好的玩家進入 -->
  <button
    class="rounded-xl bg-gradient-to-r from-pink-400 to-orange-400 py-3.5 text-xl font-bold text-white shadow-sm hover:from-pink-500 hover:to-orange-500 disabled:cursor-not-allowed disabled:from-slate-300 disabled:to-slate-300"
    onclick={() => practice.enterGameMode()}
    disabled={!practice.currentProfileName}
  >
    {#if practice.currentProfileName}
      {practice.currentProfileName} 的冒險地圖 🐰
    {:else}
      先選一個名字才能闖關 🐰
    {/if}
  </button>
</div>
