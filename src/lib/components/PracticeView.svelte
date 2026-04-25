<script lang="ts">
  import { practice } from '../practiceStore.svelte'
  import { LEVELS } from '../levels'
  import QuestionDisplay from './QuestionDisplay.svelte'
  import NumericKeypad from './NumericKeypad.svelte'

  // Scroll the inner main container to top on entering practice — in game
  // mode the map usually leaves it scrolled down to the current level node.
  $effect(() => {
    const reset = () => {
      const main = document.querySelector('main')
      if (main) main.scrollTop = 0
    }
    reset()
    requestAnimationFrame(reset)
    const t = setTimeout(reset, 50)
    return () => clearTimeout(t)
  })

  const theme = $derived(
    practice.gameMode && practice.currentLevel >= 1
      ? LEVELS[practice.currentLevel - 1].theme
      : null,
  )

  const timeLimitSec = $derived(
    practice.gameMode && practice.currentLevel >= 1
      ? LEVELS[practice.currentLevel - 1].timeLimitSec
      : null,
  )

  let nowMs = $state(Date.now())
  $effect(() => {
    const id = setInterval(() => { nowMs = Date.now() }, 200)
    return () => clearInterval(id)
  })

  const timeRemainSec = $derived(
    timeLimitSec !== null && practice.startTime > 0
      ? Math.max(0, timeLimitSec - (nowMs - practice.startTime) / 1000)
      : (timeLimitSec ?? 0),
  )

  const timerRatio = $derived(
    timeLimitSec !== null && timeLimitSec > 0 ? timeRemainSec / timeLimitSec : 1,
  )

  const timerBarColor = $derived(
    timerRatio > 0.5 ? 'bg-green-400' :
    timerRatio > 0.2 ? 'bg-amber-400' : 'bg-red-500',
  )

</script>

<div class="relative flex h-full flex-col gap-6">
  <!-- Decorative emoji (game mode only) -->
  {#if theme}
    {#each theme.decorations as d, i (i)}
      <span
        class="pointer-events-none absolute select-none opacity-50 {d.size}"
        style="left: {d.x}%; top: {d.y}%; transform: translate(-50%, -50%);"
        aria-hidden="true"
      >{d.emoji}</span>
    {/each}
  {/if}
  {#if practice.gameMode && practice.currentLevel > 0}
    <div class="flex items-center justify-center">
      <span class="rounded-full bg-gradient-to-r from-pink-400 to-orange-400 px-5 py-2 text-xl font-bold text-white shadow-sm">
        🐰
        {#if practice.currentProfileName}
          {practice.currentProfileName} ·
        {/if}
        第 {practice.currentLevel} 關
      </span>
    </div>
  {/if}

  <!-- Progress bar -->
  <div class="flex items-center gap-3">
    <div class="h-3 flex-1 overflow-hidden rounded-full bg-slate-200">
      <div
        class="h-full rounded-full bg-blue-500 transition-all duration-300"
        style="width: {(practice.progress * 100).toFixed(1)}%"
      ></div>
    </div>
    <span class="shrink-0 text-base text-slate-500">
      第 {practice.currentQuestionNumber} / {practice.questionsPerSet} 題
    </span>
  </div>

  <!-- Countdown timer bar (game mode only) -->
  {#if timeLimitSec !== null}
    <div class="flex items-center gap-3">
      <div class="h-3 flex-1 overflow-hidden rounded-full bg-slate-200">
        <div
          class="h-full rounded-full transition-all duration-200 {timerBarColor}"
          style="width: {(timerRatio * 100).toFixed(1)}%"
        ></div>
      </div>
      <span class="shrink-0 tabular-nums text-base text-slate-500">
        ⏱ {Math.ceil(timeRemainSec)} 秒
      </span>
    </div>
  {/if}

  <!-- Question + answer boxes -->
  <QuestionDisplay />

  <!-- Feedback message -->
  <div class="min-h-9 text-center text-2xl font-medium
    {practice.messageType === 'correct' ? 'text-green-600' :
     practice.messageType === 'wrong'   ? 'text-red-500'   :
                                           'text-amber-600'}">
    {practice.message}
  </div>

  <!-- Numeric keypad -->
  <NumericKeypad />
</div>
