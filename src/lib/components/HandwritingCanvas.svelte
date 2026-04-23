<script lang="ts">
  type Point = { x: number; y: number }

  let canvas: HTMLCanvasElement
  let ctx: CanvasRenderingContext2D | null = null

  let strokes: Point[][] = []
  let current: Point[] = []
  let drawing = false

  function pos(e: PointerEvent): Point {
    const r = canvas.getBoundingClientRect()
    const dpr = window.devicePixelRatio || 1
    return {
      x: (e.clientX - r.left) * (canvas.width / r.width / dpr),
      y: (e.clientY - r.top) * (canvas.height / r.height / dpr),
    }
  }

  function setupCtx() {
    if (!ctx) return
    ctx.lineWidth = 3
    ctx.strokeStyle = '#1e293b'
    ctx.lineCap = 'round'
    ctx.lineJoin = 'round'
  }

  function onDown(e: PointerEvent) {
    e.preventDefault()
    canvas.setPointerCapture(e.pointerId)
    drawing = true
    const p = pos(e)
    current = [p]
    ctx?.beginPath()
    ctx?.moveTo(p.x, p.y)
  }

  function onMove(e: PointerEvent) {
    if (!drawing || !ctx) return
    const p = pos(e)
    const prev = current[current.length - 1]
    if (Math.hypot(p.x - prev.x, p.y - prev.y) < 2) return
    current.push(p)
    // Quadratic bezier through midpoints for smooth curve
    const mid = { x: (prev.x + p.x) / 2, y: (prev.y + p.y) / 2 }
    ctx.quadraticCurveTo(prev.x, prev.y, mid.x, mid.y)
    ctx.stroke()
    ctx.beginPath()
    ctx.moveTo(mid.x, mid.y)
    setupCtx()
  }

  function onUp(e: PointerEvent) {
    if (!drawing) return
    drawing = false
    if (current.length === 1 && ctx) {
      // Single tap: draw a dot
      ctx.beginPath()
      ctx.arc(current[0].x, current[0].y, 2, 0, Math.PI * 2)
      ctx.fill()
    }
    if (current.length > 0) strokes.push([...current])
    current = []
  }

  function redrawAll() {
    if (!ctx || !canvas) return
    ctx.clearRect(0, 0, canvas.width, canvas.height)
    setupCtx()
    for (const stroke of strokes) {
      if (stroke.length === 0) continue
      ctx.beginPath()
      ctx.moveTo(stroke[0].x, stroke[0].y)
      for (let i = 1; i < stroke.length; i++) {
        const prev = stroke[i - 1]
        const curr = stroke[i]
        const mid = { x: (prev.x + curr.x) / 2, y: (prev.y + curr.y) / 2 }
        ctx.quadraticCurveTo(prev.x, prev.y, mid.x, mid.y)
      }
      ctx.stroke()
    }
  }

  function resize() {
    if (!canvas) return
    const dpr = window.devicePixelRatio || 1
    const { width, height } = canvas.getBoundingClientRect()
    canvas.width = width * dpr
    canvas.height = height * dpr
    ctx = canvas.getContext('2d')
    if (ctx) {
      ctx.scale(dpr, dpr)
      setupCtx()
      redrawAll()
    }
  }

  function clearCanvas() {
    strokes = []
    current = []
    if (ctx && canvas) ctx.clearRect(0, 0, canvas.width, canvas.height)
  }

  $effect(() => {
    resize()
    const ro = new ResizeObserver(resize)
    ro.observe(canvas)
    return () => ro.disconnect()
  })
</script>

<div class="relative h-full w-full">
  <canvas
    bind:this={canvas}
    class="h-full w-full touch-none rounded-xl border border-slate-300 bg-white"
    onpointerdown={onDown}
    onpointermove={onMove}
    onpointerup={onUp}
    onpointercancel={onUp}
  ></canvas>

  <button
    class="absolute right-2 top-2 flex h-8 w-8 items-center justify-center
           rounded-full bg-white/80 shadow hover:bg-white"
    onclick={clearCanvas}
    aria-label="清除筆跡"
    title="清除筆跡"
  >
    🧹
  </button>
</div>
