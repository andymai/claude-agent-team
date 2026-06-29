---
name: unity-performance
description: Diagnose and fix Unity performance problems with a profiler-guided workflow — eliminate GC allocations and per-frame spikes, pool objects, batch work, and measure before and after. Use when a Unity game is slow, stuttering, dropping frames, or showing GC spikes, or when asked to optimize Unity runtime performance.
when_to_use: The game stutters, hitches, or drops frames; GC spikes or memory growth; "make this faster"/"optimize" for Unity runtime code; reviewing a hot path (Update, physics, spawning) for allocations.
---

# Unity performance — measure, then fix

Optimize against evidence, not vibes. The baseline performance-safe coding rules live in **unity-csharp** (no per-frame allocations, cached lookups, pooling) — this skill is the *workflow* for when something is already measurably slow.

## Workflow

1. **Measure first.** Capture a profile before changing anything. With `unity-mcp`, drive the Editor to enter Play mode and reproduce the slow scenario. If a `manage_profiler`-style tool is available, capture CPU/memory; otherwise instruct the user to capture a Profiler trace and share the dominant markers. Note frame time, GC alloc per frame, and the top markers.
2. **Find the dominant cost.** Optimize the biggest marker, not the easiest one. Common culprits, in rough priority:
   - **GC allocations in hot paths** → GC spikes/stutter. Hunt per-frame `new`, LINQ, boxing, `string` concatenation, closures, `params`, and allocating API overloads.
   - **Repeated lookups** → `GetComponent`, `Camera.main`, `GameObject.Find`, `FindObjectsOfType` in `Update`. Cache in `Awake`/`Start`.
   - **Instantiate/Destroy churn** → pool with `UnityEngine.Pool.ObjectPool<T>`.
   - **Overdraw / too many draw calls** → batching, atlasing, fewer transparent layers (URP: check the Frame Debugger).
   - **Physics** → too many active rigidbodies/colliders, expensive `FixedUpdate`, non-allocating raycasts (`Physics.RaycastNonAlloc`).
3. **Fix one thing.** Apply the smallest change that addresses the dominant marker.
4. **Re-measure.** Confirm the marker dropped and nothing regressed. Report the before/after numbers — an optimization without a measured delta is a guess.

## Allocation-free patterns

```csharp
// Bad: allocates a new array and a closure every frame
void Update() {
    var hits = Physics.RaycastAll(ray).Where(h => h.distance < 5f).ToArray();
}

// Good: reuse a buffer, no LINQ, no per-frame allocation
private readonly RaycastHit[] _hits = new RaycastHit[16];
void Update() {
    int n = Physics.RaycastNonAlloc(ray, _hits, 5f);
    for (int i = 0; i < n; i++) { /* ... */ }
}
```

Other staples: `StringBuilder` (or cached strings) instead of concatenation; reuse `List<T>` with `.Clear()` instead of `new List<T>()`; avoid `foreach` over allocating enumerables in hot paths; prefer structs for small short-lived data but watch for defensive copies.

## When to reach further

- **CPU-bound, embarrassingly parallel work** (lots of independent entities) → the C# Job System + Burst. Big paradigm step; only when the profiler shows main-thread compute dominating and the work parallelizes.
- **Mobile/thermal** → also profile on-device; Editor numbers mislead. GC and overdraw dominate on mobile.

Do not introduce Jobs/Burst/DOTS speculatively — they add complexity. Reach for them only when measurement justifies it.

## Related skills

- **unity-csharp** — the baseline rules that prevent most of these issues.
- **unity-editor-loop** — entering Play mode and reading the console while profiling.
