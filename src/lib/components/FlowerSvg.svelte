<script lang="ts">
  let { size = 60, class: className = '' }: { size?: number; class?: string } = $props()

  const PETAL_ANGLES = [0, 60, 120, 180, 240, 300]
</script>

<!--
  viewBox 0 0 40 70
  flower center: (20, 24)
  petals: ellipses offset 11px above center, rotated around (20,24)
  stem: (20,32)→(20,67)
  leaves: one left ~y44, one right ~y54
-->
<svg
  viewBox="0 0 40 70"
  width={Math.round((size * 40) / 70)}
  height={size}
  class={className}
  xmlns="http://www.w3.org/2000/svg"
  aria-hidden="true"
>
  <!-- Stem -->
  <line x1="20" y1="32" x2="20" y2="67" stroke="#16a34a" stroke-width="3.5" stroke-linecap="round" />
  <!-- Left leaf -->
  <ellipse cx="13" cy="44" rx="9" ry="4" fill="#4ade80" transform="rotate(-40 13 44)" />
  <!-- Right leaf -->
  <ellipse cx="27" cy="54" rx="9" ry="4" fill="#4ade80" transform="rotate(40 27 54)" />
  <!-- 6 petals around center (20, 24) -->
  {#each PETAL_ANGLES as angle, i}
    <ellipse
      cx="20" cy="13" rx="5.5" ry="9"
      fill={i % 2 === 0 ? '#f9a8d4' : '#fda4af'}
      transform="rotate({angle} 20 24)"
    />
  {/each}
  <!-- Flower center -->
  <circle cx="20" cy="24" r="7.5" fill="#fef9c3" />
  <circle cx="20" cy="24" r="5" fill="#fde047" />
</svg>
