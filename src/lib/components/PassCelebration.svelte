<script lang="ts">
  import { practice } from '../practiceStore.svelte'

  const BASE = import.meta.env.BASE_URL

  let imgReady = $state(false)

  // Floating sparkles scattered across the screen
  const SPARKLES = [
    { left: 12, top: 18, emoji: '⭐', delay: 0.0, size: 'text-4xl' },
    { left: 84, top: 22, emoji: '✨', delay: 0.2, size: 'text-5xl' },
    { left: 22, top: 70, emoji: '✨', delay: 0.4, size: 'text-4xl' },
    { left: 78, top: 76, emoji: '⭐', delay: 0.1, size: 'text-5xl' },
    { left: 50, top: 14, emoji: '🎊', delay: 0.3, size: 'text-4xl' },
    { left: 8,  top: 48, emoji: '🌟', delay: 0.5, size: 'text-4xl' },
    { left: 90, top: 50, emoji: '🌟', delay: 0.0, size: 'text-4xl' },
    { left: 40, top: 88, emoji: '🎉', delay: 0.25, size: 'text-5xl' },
    { left: 64, top: 92, emoji: '✨', delay: 0.45, size: 'text-3xl' },
    { left: 30, top: 30, emoji: '🌸', delay: 0.15, size: 'text-3xl' },
  ]

  $effect(() => {
    // Preload the celebration image so it's ready as soon as we mount
    const img = new Image()
    img.onload = () => (imgReady = true)
    img.onerror = () => (imgReady = true)
    img.src = `${BASE}assets/pictures/celebrate2_transparent.png`

    const t = setTimeout(() => practice.finishCelebration(), 3000)
    return () => clearTimeout(t)
  })
</script>

<div
  class="fixed inset-0 z-50 overflow-hidden
         bg-gradient-to-b from-amber-100/85 via-rose-100/85 to-violet-100/85
         backdrop-blur-sm"
  style="animation: bg-fade-out 0.5s ease-in 2.5s forwards;"
>
  <!-- Floating sparkles -->
  {#each SPARKLES as s, i (i)}
    <span
      class="sparkle absolute select-none {s.size}"
      style="left: {s.left}%; top: {s.top}%; animation-delay: {s.delay}s;"
      aria-hidden="true"
    >
      {s.emoji}
    </span>
  {/each}

  <!-- Center stack: text + celebration image -->
  <div class="absolute inset-0 flex flex-col items-center justify-center gap-4">
    <div class="pass-text text-6xl font-black text-amber-500 drop-shadow-lg sm:text-7xl">
      🎉 過關！🎉
    </div>

    {#if imgReady}
      <div class="celebrate-rabbit">
        <img
          src="{BASE}assets/pictures/celebrate2_transparent.png"
          alt="慶祝"
          class="w-72 select-none drop-shadow-xl sm:w-96"
          draggable="false"
        />
      </div>
    {/if}
  </div>
</div>

<style>
  /* Sparkles twinkle and drift up */
  @keyframes sparkle {
    0%   { transform: scale(0.4) translateY(15px); opacity: 0; }
    20%  { transform: scale(1.2) translateY(0);    opacity: 1; }
    80%  { transform: scale(1)   translateY(-20px); opacity: 1; }
    100% { transform: scale(0.6) translateY(-40px); opacity: 0; }
  }
  .sparkle {
    animation: sparkle 2.4s ease-out infinite;
  }

  /* "過關！" pops in big, then keeps a wiggle */
  @keyframes pass-in {
    0%   { transform: scale(0.2) rotate(-15deg); opacity: 0; }
    55%  { transform: scale(1.25) rotate(8deg);  opacity: 1; }
    100% { transform: scale(1)   rotate(0);      opacity: 1; }
  }
  @keyframes pass-wiggle {
    0%, 100% { transform: rotate(0deg)  scale(1); }
    25%      { transform: rotate(-4deg) scale(1.06); }
    75%      { transform: rotate(4deg)  scale(1.06); }
  }
  .pass-text {
    animation:
      pass-in 0.55s cubic-bezier(0.34, 1.56, 0.64, 1) forwards,
      pass-wiggle 1.2s ease-in-out 0.55s infinite;
  }

  /* Celebration image — same wiggle as the practice-mode celebration */
  @keyframes celebrate-rabbit {
    0%, 100% { transform: scale(1)    rotate(0deg); }
    25%      { transform: scale(1.15) rotate(-3deg); }
    50%      { transform: scale(0.95) rotate(0deg); }
    75%      { transform: scale(1.15) rotate(3deg); }
  }
  .celebrate-rabbit {
    animation: celebrate-rabbit 1.2s ease-in-out infinite;
  }

  /* Fade out the whole overlay near the end */
  @keyframes bg-fade-out {
    from { opacity: 1; }
    to   { opacity: 0; }
  }
</style>
