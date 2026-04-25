<script lang="ts">
  import { practice } from '../practiceStore.svelte'

  const BASE = import.meta.env.BASE_URL

  let showDialog = $state(false)
  let imgReady = $state(false)

  $effect(() => {
    // Preload rabbit image so it's ready as soon as we mount
    const img = new Image()
    img.onload = () => (imgReady = true)
    img.onerror = () => (imgReady = true) // still proceed if it fails
    img.src = `${BASE}assets/pictures/celebrate2_transparent.png`

    const t = setTimeout(() => (showDialog = true), 4000)
    return () => clearTimeout(t)
  })
</script>

<!-- Full-screen overlay with soft backdrop so it's visually obvious -->
<div
  class="fixed inset-0 z-50 flex items-center justify-center
         bg-gradient-to-b from-amber-100/70 via-rose-100/70 to-violet-100/70
         backdrop-blur-sm"
>
  {#if !showDialog}
    <div class="flex flex-col items-center gap-6">
      <!-- Big text that shows immediately, independent of image loading -->
      <div class="celebrate-text text-5xl font-black text-amber-500 drop-shadow-lg sm:text-6xl">
        🎉 太棒了！🎉
      </div>

      {#if imgReady}
        <div class="celebrate-rabbit">
          <img
            src="{BASE}assets/pictures/celebrate2_transparent.png"
            alt="慶祝"
            class="w-80 select-none drop-shadow-xl sm:w-96"
            draggable="false"
          />
        </div>
      {/if}
    </div>
  {:else}
    <div
      class="mx-4 w-full max-w-sm rounded-2xl bg-white p-8 shadow-2xl"
      style="animation: pop-in 0.3s ease-out"
    >
      <p class="mb-2 text-center text-4xl">🎉</p>
      <h2 class="mb-2 text-center text-xl font-bold text-slate-800">本次練習完成！</h2>
      <p class="mb-3 text-center text-slate-500">
        你已完成 {practice.questionsPerSet} 題練習！
      </p>
      <div class="mb-6 space-y-1 text-center text-lg font-semibold text-slate-700">
        <p>用時：{practice.elapsedDisplay}</p>
        <p>
          答錯：
          {#if practice.wrongCount === 0}
            <span class="text-green-600">全對！🎯</span>
          {:else}
            {practice.wrongCount} 次
          {/if}
        </p>
      </div>
      <div class="flex gap-3">
        <button
          class="flex-1 rounded-xl border border-slate-300 py-3.5 text-lg font-bold text-slate-600 hover:bg-slate-50"
          onclick={() => practice.returnToSettings()}
        >
          回到設定
        </button>
        <button
          class="flex-1 rounded-xl bg-blue-500 py-3.5 text-lg font-bold text-white hover:bg-blue-600"
          onclick={() => practice.startAnotherSet()}
        >
          再做一組
        </button>
      </div>
    </div>
  {/if}
</div>

<style>
  @keyframes celebrate-text {
    0%   { transform: scale(0.3) rotate(-15deg); opacity: 0; }
    50%  { transform: scale(1.15) rotate(5deg);  opacity: 1; }
    100% { transform: scale(1)    rotate(0);     opacity: 1; }
  }
  .celebrate-text {
    animation:
      celebrate-text 0.6s cubic-bezier(0.34, 1.56, 0.64, 1) forwards,
      celebrate-text-wiggle 1.5s ease-in-out 0.6s infinite;
  }
  @keyframes celebrate-text-wiggle {
    0%, 100% { transform: rotate(0deg)  scale(1); }
    25%      { transform: rotate(-3deg) scale(1.05); }
    75%      { transform: rotate(3deg)  scale(1.05); }
  }

  @keyframes celebrate-rabbit {
    0%, 100% { transform: scale(1)    rotate(0deg); }
    25%      { transform: scale(1.15) rotate(-3deg); }
    50%      { transform: scale(0.95) rotate(0deg); }
    75%      { transform: scale(1.15) rotate(3deg); }
  }
  .celebrate-rabbit {
    animation: celebrate-rabbit 1.2s ease-in-out infinite;
  }

  @keyframes pop-in {
    from { transform: scale(0.85); opacity: 0; }
    to   { transform: scale(1);    opacity: 1; }
  }
</style>
