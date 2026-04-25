<script lang="ts">
  import { practice } from './lib/practiceStore.svelte'
  import { LEVELS } from './lib/levels'
  import SettingsView from './lib/components/SettingsView.svelte'
  import PracticeView from './lib/components/PracticeView.svelte'
  import GameMapView from './lib/components/GameMapView.svelte'
  import Celebration from './lib/components/Celebration.svelte'
  import GameResult from './lib/components/GameResult.svelte'
  import PassCelebration from './lib/components/PassCelebration.svelte'

  const mainBg = $derived(
    practice.view === 'practice' && practice.gameMode && practice.currentLevel >= 1
      ? LEVELS[practice.currentLevel - 1].theme.gradient
      : null,
  )

  function handleBack() {
    if (practice.view === 'map') {
      practice.returnToSettings()
    } else if (practice.view === 'practice') {
      if (practice.gameMode) practice.returnToMap()
      else practice.returnToSettings()
    }
  }

  const showBack = $derived(
    practice.view !== 'settings' &&
      !practice.celebrating &&
      !practice.levelResult &&
      !practice.passingCelebration,
  )

</script>

<!--
  Layout: html/body/#app use height:100dvh (dynamic viewport height, see
  app.css). dvh shrinks when the iOS keyboard appears, so the browser never
  needs to scroll window.scrollY to reveal a focused input — which is the
  root cause of the header being pushed off-screen. The header is a normal
  shrink-0 flex item; <main> takes the rest with overflow-y-auto.
-->
<div class="flex h-full flex-col bg-slate-50">
  <header class="flex h-14 shrink-0 items-center border-b border-slate-200 bg-white px-4 shadow-sm">
    {#if showBack}
      <button
        class="mr-2 flex h-10 w-10 items-center justify-center rounded-lg text-2xl text-slate-500 hover:bg-slate-100"
        onclick={handleBack}
        aria-label="返回"
      >
        ←
      </button>
    {/if}
    <h1 class="text-xl font-bold text-slate-700">算術練習</h1>
  </header>

  <main
    class="relative min-h-0 flex-1 overflow-y-auto transition-[background] duration-500"
    style={mainBg ? `background: ${mainBg};` : ''}
  >
    <div class="mx-auto flex w-full max-w-2xl flex-col px-4 py-4">
      {#if practice.view === 'settings'}
        <SettingsView />
      {:else if practice.view === 'map'}
        <GameMapView />
      {:else}
        <PracticeView />
      {/if}
    </div>
  </main>
</div>

{#if practice.celebrating}
  <Celebration />
{/if}

{#if practice.passingCelebration}
  <PassCelebration />
{/if}

{#if practice.levelResult}
  <GameResult />
{/if}
