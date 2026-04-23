<script lang="ts">
  import { practice } from '../practiceStore.svelte'

  const BASE = import.meta.env.BASE_URL

  let showDialog = $state(false)

  $effect(() => {
    showDialog = false
    const t = setTimeout(() => (showDialog = true), 3500)
    return () => clearTimeout(t)
  })
</script>

<!-- Full-screen overlay -->
<div class="fixed inset-0 z-50 flex items-center justify-center">
  {#if !showDialog}
    <!-- Celebration animation -->
    <div class="animate-bounce">
      <img
        src="{BASE}assets/pictures/celebrate2_transparent.png"
        alt="慶祝"
        class="w-72 select-none sm:w-96"
        draggable="false"
      />
    </div>
  {:else}
    <!-- Completion dialog -->
    <div
      class="mx-4 w-full max-w-sm rounded-2xl bg-white p-8 shadow-2xl"
      style="animation: pop-in 0.3s ease-out"
    >
      <p class="mb-2 text-center text-4xl">🎉</p>
      <h2 class="mb-2 text-center text-xl font-bold text-slate-800">本次練習完成！</h2>
      <p class="mb-6 text-center text-slate-500">
        你已完成 {practice.questionsPerSet} 題練習，要再做一組嗎？
      </p>
      <div class="flex gap-3">
        <button
          class="flex-1 rounded-xl border border-slate-300 py-3 font-medium text-slate-600 hover:bg-slate-50"
          onclick={() => practice.returnToSettings()}
        >
          回到設定
        </button>
        <button
          class="flex-1 rounded-xl bg-blue-500 py-3 font-bold text-white hover:bg-blue-600"
          onclick={() => practice.startAnotherSet()}
        >
          再做一組
        </button>
      </div>
    </div>
  {/if}
</div>

<style>
  @keyframes pop-in {
    from { transform: scale(0.85); opacity: 0; }
    to   { transform: scale(1);    opacity: 1; }
  }
</style>
