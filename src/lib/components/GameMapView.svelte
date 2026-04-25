<script lang="ts">
  import { practice } from '../practiceStore.svelte'
  import { LEVELS, TOTAL_LEVELS, formatTimeShort, type LevelConfig } from '../levels'
  import FlowerSvg from './FlowerSvg.svelte'

  type NodeState = 'completed' | 'current' | 'locked'

  // Level positions on the map. Row 0 = bottom (L1), row 4 = top (L5).
  // x is a percent (0-100) across the map width. Positions are intentionally
  // irregular — not strictly alternating left/right.
  const POSITIONS: { x: number; row: number }[] = [
    { x: 28, row: 0 }, // L1
    { x: 72, row: 1 }, // L2
    { x: 35, row: 2 }, // L3
    { x: 68, row: 3 }, // L4
    { x: 45, row: 4 }, // L5
  ]

  // Decorations scattered across the map (percent-based; y = 0 top, 100 bottom)
  const DECORATIONS: { x: number; y: number; emoji: string; size: string }[] = [
    { x: 8,  y: 96, emoji: '🌿', size: 'text-4xl' },
    { x: 88, y: 92, emoji: '🌸', size: 'text-4xl' },
    { x: 15, y: 80, emoji: '🥕', size: 'text-4xl' },
    { x: 90, y: 72, emoji: '🌳', size: 'text-5xl' },
    { x: 55, y: 62, emoji: '🍄', size: 'text-3xl' },
    { x: 8,  y: 55, emoji: '🌲', size: 'text-5xl' },
    { x: 85, y: 46, emoji: '☁️', size: 'text-4xl' },
    { x: 20, y: 38, emoji: '🌻', size: 'text-3xl' },
    { x: 90, y: 28, emoji: '🦋', size: 'text-3xl' },
    { x: 12, y: 20, emoji: '🌼', size: 'text-3xl' },
    { x: 88, y: 10, emoji: '☁️', size: 'text-4xl' },
    { x: 78, y: 3,  emoji: '🏁', size: 'text-4xl' },
  ]

  const ROW_HEIGHT_PX = 200
  const MAP_HEIGHT_PX = ROW_HEIGHT_PX * TOTAL_LEVELS // 1000
  const VB_H = TOTAL_LEVELS * 20 // viewBox y span = 100

  function nodeState(lvl: number): NodeState {
    if (lvl < practice.unlockedLevel) return 'completed'
    if (lvl === practice.unlockedLevel) return 'current'
    return 'locked'
  }

  function nodeTopPercent(row: number): number {
    // row 0 sits near the bottom
    return ((TOTAL_LEVELS - 0.5 - row) / TOTAL_LEVELS) * 100
  }

  function yVB(row: number): number {
    return VB_H - (0.5 + row) * (VB_H / TOTAL_LEVELS)
  }

  // Smooth cubic bezier path connecting consecutive nodes, with control
  // points offset vertically so the tangent at each node is ~vertical.
  function buildPath(): string {
    let d = ''
    const half = VB_H / TOTAL_LEVELS / 2 // 5
    for (let i = 0; i < POSITIONS.length; i++) {
      const p = POSITIONS[i]
      const x = p.x
      const y = yVB(p.row)
      if (i === 0) {
        d += `M ${x} ${y}`
      } else {
        const prev = POSITIONS[i - 1]
        const px = prev.x
        const py = yVB(prev.row)
        const c1x = px
        const c1y = py - half
        const c2x = x
        const c2y = y + half
        d += ` C ${c1x} ${c1y}, ${c2x} ${c2y}, ${x} ${y}`
      }
    }
    return d
  }
  const pathD = buildPath()

  function handleClick(lvl: number) {
    if (lvl <= practice.unlockedLevel) practice.startLevel(lvl)
  }

  // ── Rabbit animation ──
  // Snapshot on mount: where the rabbit was last standing, and where we want
  // it to be now (the current unlocked level). If different, animate.
  const startLvl = clampLvl(practice.prevUnlockedLevel)
  const targetLvl = clampLvl(practice.unlockedLevel)

  function clampLvl(n: number): number {
    return Math.min(Math.max(1, n), TOTAL_LEVELS)
  }

  let rabbitLvl = $state(startLvl)

  $effect(() => {
    if (rabbitLvl === targetLvl) return
    // Slight delay so the element is painted at startLvl before we change
    // left/top — otherwise the CSS transition has nothing to animate from.
    const t = setTimeout(() => {
      rabbitLvl = targetLvl
    }, 120)
    return () => clearTimeout(t)
  })

  $effect(() => {
    // After rabbit arrives, commit to store so we don't replay the same
    // animation on next map visit.
    if (
      rabbitLvl === targetLvl &&
      practice.prevUnlockedLevel !== practice.unlockedLevel
    ) {
      const t = setTimeout(() => {
        practice.prevUnlockedLevel = practice.unlockedLevel
      }, 1400)
      return () => clearTimeout(t)
    }
  })

  const rabbitPos = $derived(POSITIONS[rabbitLvl - 1])
  const allCleared = $derived(practice.unlockedLevel > TOTAL_LEVELS)

  // Show rabbit at the last level once everything is cleared (celebratory).
  const showRabbit = $derived(!allCleared || rabbitLvl <= TOTAL_LEVELS)

  // Requirements of the level the player is about to attempt
  const nextLevelCfg = $derived<LevelConfig | null>(
    practice.unlockedLevel >= 1 && practice.unlockedLevel <= TOTAL_LEVELS
      ? LEVELS[practice.unlockedLevel - 1]
      : null,
  )

  // Scroll current node into view on mount
  let mapEl = $state<HTMLElement | null>(null)
  $effect(() => {
    if (!mapEl) return
    const current = mapEl.querySelector('[data-current="1"]')
    if (current) {
      requestAnimationFrame(() => {
        current.scrollIntoView({ behavior: 'auto', block: 'center' })
      })
    } else if (allCleared) {
      const last = mapEl.querySelector('[data-level="' + TOTAL_LEVELS + '"]')
      last?.scrollIntoView({ behavior: 'auto', block: 'center' })
    }
  })
</script>

<div class="flex flex-col items-center gap-3 pb-4">
  <!-- Top banner: player name + progress -->
  <div class="flex w-full max-w-2xl items-center justify-between rounded-2xl bg-white/80 px-4 py-3 shadow-sm backdrop-blur">
    <span class="flex items-center gap-2 text-base font-bold text-slate-700">
      <span class="text-xl">🐰</span>
      <span>{practice.currentProfileName ?? '冒險地圖'}</span>
    </span>
    <div class="flex items-center gap-3">
      {#if practice.currentFlowers > 0}
        <span class="text-base font-bold text-pink-500">
          🌸×{practice.currentFlowers}
        </span>
      {/if}
      {#if nextLevelCfg}
        <span class="text-base font-bold text-pink-600">
          已通過 {Math.min(TOTAL_LEVELS, Math.max(0, practice.unlockedLevel - 1))} / {TOTAL_LEVELS} 關
        </span>
      {:else}
        <span class="text-base font-bold text-amber-600">🏆 全部通過！</span>
      {/if}
    </div>
  </div>

  <!-- Map container -->
  <div
    bind:this={mapEl}
    class="map-bg relative w-full max-w-2xl"
    style="height: {MAP_HEIGHT_PX}px;"
  >
    <!-- Decorations -->
    {#each DECORATIONS as d, i (i)}
      <span
        class="pointer-events-none absolute select-none opacity-80 {d.size}"
        style="left: {d.x}%; top: {d.y}%; transform: translate(-50%, -50%);"
        aria-hidden="true"
      >
        {d.emoji}
      </span>
    {/each}

    <!-- Curvy SVG path -->
    <svg
      class="pointer-events-none absolute inset-0 h-full w-full"
      viewBox="0 0 100 {VB_H}"
      preserveAspectRatio="none"
      aria-hidden="true"
    >
      <!-- Wider, lighter underlay for a cartoon-road feel -->
      <path
        d={pathD}
        fill="none"
        stroke="#fde68a"
        stroke-linecap="round"
        stroke-linejoin="round"
        vector-effect="non-scaling-stroke"
        style="stroke-width: 14px"
      />
      <!-- Dashed center line -->
      <path
        d={pathD}
        fill="none"
        stroke="#f59e0b"
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-dasharray="4 6"
        vector-effect="non-scaling-stroke"
        style="stroke-width: 3px"
      />
    </svg>

    <!-- Level nodes -->
    {#each LEVELS as cfg, i (cfg.level)}
      {@const pos = POSITIONS[i]}
      {@const state = nodeState(cfg.level)}
      <button
        type="button"
        data-level={cfg.level}
        data-current={state === 'current' ? '1' : null}
        class="absolute flex flex-col items-center justify-center gap-1 rounded-2xl border-2 px-2 py-2 transition-transform
          {state === 'locked'
            ? 'cursor-not-allowed border-slate-300 bg-slate-200 text-slate-400 shadow-inner'
            : state === 'current'
              ? 'border-white bg-gradient-to-br from-pink-300 to-orange-300 text-white shadow-lg node-current'
              : 'border-white bg-gradient-to-br from-emerald-300 to-teal-400 text-white shadow-md hover:scale-105'}"
        style="width: 116px; height: 140px; left: {pos.x}%; top: {nodeTopPercent(pos.row)}%; transform: translate(-50%, -50%);"
        onclick={() => handleClick(cfg.level)}
        disabled={state === 'locked'}
        aria-label={`第 ${cfg.level} 關`}
      >
        <span class="text-3xl leading-none">
          {#if state === 'completed'}⭐
          {:else if state === 'locked'}🔒
          {:else}✨
          {/if}
        </span>
        <span class="text-base font-bold leading-tight">第 {cfg.level} 關</span>
        <span class="text-xs font-semibold leading-tight opacity-95">
          {cfg.questions} 題
        </span>
        <span class="text-xs font-semibold leading-tight opacity-95">
          ⏱ {formatTimeShort(cfg.timeLimitSec)}
        </span>
        <span class="text-xs font-semibold leading-tight opacity-95">
          錯 ≤ {cfg.maxErrors}
        </span>
      </button>
    {/each}

    <!-- Rabbit overlay — positioned absolutely, animated via CSS transition -->
    {#if showRabbit}
      <div
        class="rabbit-marker pointer-events-none absolute z-10 text-5xl"
        style="left: {rabbitPos.x}%; top: {nodeTopPercent(rabbitPos.row)}%;"
        aria-hidden="true"
      >
        🐰
      </div>
    {/if}
  </div>

  <!-- Flower garden (shown when at least 1 flower collected) -->
  {#if practice.currentFlowers > 0}
    <div class="w-full max-w-2xl rounded-2xl bg-white/80 px-4 py-4 shadow-sm backdrop-blur">
      <p class="mb-3 text-sm font-bold text-pink-500">🌸 你的花圃（共 {practice.currentFlowers} 朵）</p>
      <div class="flex flex-wrap gap-3">
        {#each { length: practice.currentFlowers } as _, i (i)}
          <FlowerSvg size={56} />
        {/each}
      </div>
    </div>
  {/if}

  <!-- Re-challenge button when all levels cleared -->
  {#if allCleared}
    <button
      class="rounded-xl bg-gradient-to-r from-pink-400 to-orange-400 px-7 py-3.5 text-lg font-bold text-white shadow-sm hover:from-pink-500 hover:to-orange-500"
      onclick={() => practice.startOver()}
    >
      再挑戰！🐰
    </button>
  {/if}

  <!-- Back button -->
  <button
    class="mt-2 rounded-xl bg-white/80 px-7 py-3.5 text-lg font-bold text-slate-600 shadow-sm backdrop-blur hover:bg-white"
    onclick={() => practice.returnToSettings()}
  >
    ← 回到設定
  </button>
</div>

<style>
  .map-bg {
    background: linear-gradient(180deg, #e0f2fe 0%, #fef3c7 55%, #dcfce7 100%);
    border-radius: 1rem;
    overflow: hidden;
  }

  /* Rabbit sits just above the node (its feet near the node center) and
     transitions smoothly when left/top change. The hop keyframes preserve
     the centering translate so both can coexist. */
  .rabbit-marker {
    transition:
      left 1.2s cubic-bezier(0.45, 0, 0.25, 1),
      top 1.2s cubic-bezier(0.45, 0, 0.25, 1);
    animation: rabbit-hop 0.55s ease-in-out infinite alternate;
    filter: drop-shadow(0 4px 4px rgba(0, 0, 0, 0.18));
  }

  @keyframes rabbit-hop {
    from { transform: translate(-50%, -160%) translateY(0); }
    to   { transform: translate(-50%, -160%) translateY(-6px); }
  }

  @keyframes node-pulse {
    0%, 100% { box-shadow: 0 8px 18px -4px rgba(244, 114, 182, 0.55); }
    50%      { box-shadow: 0 14px 26px -4px rgba(244, 114, 182, 0.85); }
  }
  .node-current {
    animation: node-pulse 1.6s ease-in-out infinite;
  }
</style>
