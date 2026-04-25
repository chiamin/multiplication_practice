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

  // On iPad, typing in a text input can scroll document.body even with
  // overflow:hidden, pushing the header off-screen. Reset on every view
  // transition so the layout stays anchored.
  $effect(() => {
    practice.view
    window.scrollTo(0, 0)
    document.documentElement.scrollTop = 0
    document.body.scrollTop = 0
  })
</script>

<!--
  Layout: html / body / #app are locked to 100% height with overflow:hidden
  (see app.css), so the page itself never scrolls. The header is just a
  normal flex item at the top of the column — it doesn't need `fixed` or
  `sticky`, it simply isn't part of any scrollable area. <main> takes the
  remaining height with `min-h-0` (so flex can shrink it) and scrolls
  internally via `overflow-y-auto`. This is the layout most native-feeling
  apps use and behaves identically across desktop and iOS browsers.
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
