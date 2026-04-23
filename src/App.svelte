<script lang="ts">
  import { practice } from './lib/practiceStore.svelte'
  import SettingsView from './lib/components/SettingsView.svelte'
  import PracticeView from './lib/components/PracticeView.svelte'
  import Celebration from './lib/components/Celebration.svelte'
</script>

<div class="flex min-h-screen flex-col bg-slate-50">
  <header class="flex h-12 items-center border-b border-slate-200 bg-white px-4 shadow-sm">
    {#if !practice.inSettings && !practice.celebrating}
      <button
        class="mr-2 flex h-8 w-8 items-center justify-center rounded-lg text-xl text-slate-500 hover:bg-slate-100"
        onclick={() => practice.returnToSettings()}
        aria-label="返回設定"
      >
        ←
      </button>
    {/if}
    <h1 class="text-base font-semibold text-slate-700">算術練習</h1>
  </header>

  <main class="mx-auto flex w-full max-w-2xl flex-1 flex-col px-4 py-4">
    {#if practice.inSettings}
      <SettingsView />
    {:else}
      <PracticeView />
    {/if}
  </main>
</div>

{#if practice.celebrating}
  <Celebration />
{/if}
