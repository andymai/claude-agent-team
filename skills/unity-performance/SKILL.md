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

**Hard rules on claims:**

- Never report an optimization as an improvement without before/after numbers from the same scenario. If you could not measure (no profiler access, can't reproduce the slow scenario), the report must say **unmeasured** — describe the change as "expected to reduce allocations because X" and give the user the exact steps to measure. Do not convert an expectation into a result.
- The numbers must come from output you actually saw (profiler capture, `Time.deltaTime` logging you added and then removed, frame-time stats) — quote them. Take at least 3 samples for noisy measurements and report the spread; a delta inside the noise is not a win. Any measurement logging you added must be removed before finishing — then confirm removal via `git diff` (leftover per-frame logging in a hot path is itself a perf bug).
- If the re-measure shows no improvement or a regression, revert the change and say so — by editing your change back out (you read the prior code before changing it), never via `git checkout`/`git restore`/`git reset`, since the file may also hold uncommitted work you didn't author. A reverted non-win reported honestly is a good outcome; a kept "optimization" with no evidence is technical debt.
- Behavioral parity check: a perf fix that skips work (caching, pooling, early-out) can change behavior. State what you did to confirm the game still behaves the same (tests, capture comparison via unity-editor-loop) — or that you didn't.

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
