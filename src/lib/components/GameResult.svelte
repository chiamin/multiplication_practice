<script lang="ts">
  import { practice } from '../practiceStore.svelte'
  import { TOTAL_LEVELS, formatTime } from '../levels'
  import FlowerSvg from './FlowerSvg.svelte'

  const r = $derived(practice.levelResult)
  const isLastLevel = $derived(r ? r.level >= TOTAL_LEVELS : false)
  const hasNextUnlocked = $derived(
    r ? r.passed && r.level < TOTAL_LEVELS && r.level < practice.unlockedLevel : false,
  )

  const timeBarPct = $derived(
    r ? Math.min(100, (r.elapsedSec / Math.max(1, r.timeLimitSec)) * 100) : 0,
  )
  const errorBarPct = $derived(
    r ? Math.min(100, (r.firstTryWrongs / Math.max(1, r.maxErrors)) * 100) : 0,
  )
</script>

{#if r}
  <div
    class="fixed inset-0 z-50 flex items-center justify-center
           bg-gradient-to-b from-amber-100/70 via-rose-100/70 to-violet-100/70
           backdrop-blur-sm"
  >
    <div
      class="mx-4 w-full max-w-sm rounded-3xl bg-white p-7 shadow-2xl"
      style="animation: pop-in 0.3s ease-out"
    >
      <!-- Big emoji header -->
      <div class="mb-1 text-center text-6xl">
        {#if r.passed && isLastLevel}🏆
        {:else if r.passed}🎉
        {:else}💪
        {/if}
      </div>

      <!-- Level label (small) -->
      <p class="mb-1 text-center text-sm font-semibold text-slate-500">
        第 {r.level} 關
      </p>

      <!-- HUGE pass/fail text -->
      <div
        class="mb-3 text-center text-6xl font-black tracking-wide
          {r.passed ? 'text-green-500' : 'text-orange-500'}"
        style="animation: result-pop 0.45s cubic-bezier(0.34, 1.56, 0.64, 1) 0.05s both;"
      >
        {r.passed ? '過關！' : '沒過關'}
      </div>

      <p class="mb-6 text-center text-sm text-slate-500">
        {#if r.passed && isLastLevel}
          全部 {TOTAL_LEVELS} 關都通過了！你是算術高手 🌟
        {:else if r.passed}
          已解鎖第 {r.level + 1} 關
        {:else}
          沒通過也沒關係，再試一次就好
        {/if}
      </p>

      <!-- Time progress bar -->
      <div class="mb-4">
        <div class="mb-1.5 flex items-baseline justify-between">
          <span class="text-sm font-semibold text-slate-600">⏱ 用時</span>
          <span class="text-sm">
            <span class="font-bold {r.timeOk ? 'text-green-600' : 'text-red-500'}">
              {formatTime(r.elapsedSec)}
            </span>
            <span class="text-slate-400">/ {formatTime(r.timeLimitSec)}</span>
          </span>
        </div>
        <div class="h-3 overflow-hidden rounded-full bg-slate-100">
          <div
            class="h-full rounded-full transition-[width] duration-700 ease-out
              {r.timeOk
                ? 'bg-gradient-to-r from-emerald-300 to-green-500'
                : 'bg-gradient-to-r from-orange-300 to-red-500'}"
            style="width: {timeBarPct}%"
          ></div>
        </div>
      </div>

      <!-- Errors progress bar -->
      <div class="mb-6">
        <div class="mb-1.5 flex items-baseline justify-between">
          <span class="text-sm font-semibold text-slate-600">✏️ 錯誤</span>
          <span class="text-sm">
            <span class="font-bold {r.errorsOk ? 'text-green-600' : 'text-red-500'}">
              {r.firstTryWrongs} 題
            </span>
            <span class="text-slate-400">/ 最多 {r.maxErrors} 題</span>
          </span>
        </div>
        <div class="h-3 overflow-hidden rounded-full bg-slate-100">
          <div
            class="h-full rounded-full transition-[width] duration-700 ease-out
              {r.errorsOk
                ? 'bg-gradient-to-r from-emerald-300 to-green-500'
                : 'bg-gradient-to-r from-orange-300 to-red-500'}"
            style="width: {errorBarPct}%"
          ></div>
        </div>
      </div>

      <!-- Flower reward (only when all levels cleared) -->
      {#if r.passed && isLastLevel}
        <div class="flower-reward mb-5 flex flex-col items-center gap-1 rounded-2xl bg-pink-50 py-4">
          <p class="text-base font-bold text-pink-600">✨ 獲得一朵小花！</p>
          <FlowerSvg size={72} class="flower-pop" />
          <p class="text-sm font-semibold text-slate-500">
            你共收集了
            <span class="text-xl font-black text-pink-500">{practice.currentFlowers}</span>
            朵小花 🌸
          </p>
        </div>
      {/if}

      <!-- Actions -->
      <div class="flex flex-col gap-2">
        {#if r.passed && isLastLevel}
          <button
            class="w-full rounded-xl bg-gradient-to-r from-pink-400 to-orange-400 py-3.5 text-lg font-bold text-white shadow-sm hover:from-pink-500 hover:to-orange-500"
            onclick={() => practice.startOver()}
          >
            再挑戰！🐰
          </button>
        {:else if r.passed && !isLastLevel && hasNextUnlocked}
          <button
            class="w-full rounded-xl bg-gradient-to-r from-pink-400 to-orange-400 py-3.5 text-lg font-bold text-white shadow-sm hover:from-pink-500 hover:to-orange-500"
            onclick={() => practice.nextLevel()}
          >
            下一關 →
          </button>
        {/if}
        {#if !r.passed}
          <button
            class="w-full rounded-xl bg-gradient-to-r from-pink-400 to-orange-400 py-3.5 text-lg font-bold text-white shadow-sm hover:from-pink-500 hover:to-orange-500"
            onclick={() => practice.retryLevel()}
          >
            再試一次
          </button>
        {/if}
        <button
          class="w-full rounded-xl border border-slate-300 py-3.5 text-lg font-bold text-slate-600 hover:bg-slate-50"
          onclick={() => practice.returnToMap()}
        >
          回到地圖
        </button>
      </div>
    </div>
  </div>
{/if}

<style>
  @keyframes pop-in {
    from { transform: scale(0.85); opacity: 0; }
    to   { transform: scale(1);    opacity: 1; }
  }
  @keyframes result-pop {
    0%   { transform: scale(0.5)  rotate(-6deg); opacity: 0; }
    60%  { transform: scale(1.15) rotate(3deg);  opacity: 1; }
    100% { transform: scale(1)    rotate(0);     opacity: 1; }
  }
  @keyframes flower-pop {
    0%   { transform: scale(0) rotate(-30deg); opacity: 0; }
    60%  { transform: scale(1.3) rotate(10deg); opacity: 1; }
    80%  { transform: scale(0.9) rotate(-5deg); }
    100% { transform: scale(1) rotate(0); opacity: 1; }
  }
  :global(.flower-pop) {
    animation: flower-pop 0.7s cubic-bezier(0.34, 1.56, 0.64, 1) 0.1s both;
  }
  .flower-reward {
    animation: pop-in 0.3s ease-out 0.05s both;
  }
</style>
