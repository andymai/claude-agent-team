---
name: unity-testing
description: Write and run Unity Test Framework tests — EditMode (fast, logic) and PlayMode (scene/lifecycle) — via headless batchmode, parse the NUnit XML results, and pair them with visual capture so "tests pass" actually means "the game works". Use when adding or running Unity tests, setting up test assemblies, or verifying gameplay behavior.
when_to_use: Adding or running Unity tests; editing *Tests.cs or files under a Tests/ folder; creating a test asmdef; questions about EditMode vs PlayMode, [UnityTest] coroutines, or running tests headlessly in CI; verifying that a gameplay change actually works.
---

# Unity testing (UTF) — EditMode, PlayMode, headless

Unity Test Framework is NUnit-based with two modes. The goal is a real correctness loop, not green checkmarks over an unplayable build.

## EditMode vs PlayMode

- **EditMode** — runs in the Editor without entering Play mode. Fast. For pure logic, ScriptableObject methods, tools, and anything not needing the runtime loop. Default target. Architect gameplay logic (per **unity-csharp**) so most of it is EditMode-testable without a scene.
- **PlayMode** — runs in a live scene with the full MonoBehaviour lifecycle. For coroutines, physics, frame-dependent behavior. Use `[UnityTest]` + `yield return null` to advance frames. Slower; keep these focused.

## Test assembly setup

Tests live in their own assembly. A test `.asmdef` must reference `UnityEngine.TestRunner`, `UnityEditor.TestRunner` (for EditMode), and every assembly under test. EditMode tests need the asmdef's `includePlatforms` set to `Editor` only; PlayMode test asmdefs include runtime platforms. If tests can't see the code under test, the missing `references` entry in the test asmdef is the usual cause.

```csharp
public sealed class DamageTests
{
    [Test]
    public void Weapon_AppliesDamage_ReducesHealthByExactAmount()
    {
        // Arrange the state explicitly — a fresh CreateInstance<T>() has default
        // field values (0/null), so never assert on those; set what you assert.
        var weapon = ScriptableObject.CreateInstance<WeaponSO>();
        weapon.Damage = 5f;
        var health = new Health(20f);

        weapon.ApplyDamage(health);

        Assert.AreEqual(15f, health.Current);   // exact predicted value
    }

    [UnityTest]   // PlayMode: advances a frame
    public System.Collections.IEnumerator Projectile_MovesForward()
    {
        var go = new GameObject().AddComponent<Projectile>();
        var start = go.transform.position;
        yield return null;
        Assert.AreNotEqual(start, go.transform.position);
    }
}
```

## Running headlessly

```bash
<unity-binary> -batchmode -runTests -projectPath <path> \
      -testPlatform EditMode \
      -testResults <abs>/results-editmode.xml \
      -logFile <abs>/test-editmode.log
```

(`Unity` is rarely on PATH — resolve `<unity-binary>` from `ProjectSettings/ProjectVersion.txt` + the Hub install dirs; see unity-editor-loop's CLI fallback for the per-OS paths. No matching binary → report NOT RUN and give the user the command.)

- `-testPlatform` = `EditMode` (default) or `PlayMode`.
- `-runTests` exits on its own (do **not** add `-quit`) and returns non-zero on failure.
- `-testFilter "Namespace.Class;Other.Test"` (semicolons or regex) to scope.
- Results are **NUnit XML** — parse `<test-case ... result="Failed">` and read `<failure><message>`.

```bash
# Quick pass/fail + failed test names:
grep -oE 'result="[A-Za-z]+"' <abs>/results-editmode.xml | sort | uniq -c
grep -B1 '<failure>' <abs>/results-editmode.xml
```

**PlayMode CLI gotcha:** running PlayMode tests more than once in the same process can hang. Use a **fresh process per PlayMode run**, and always include `-batchmode` so blocking dialogs don't stall it.

If `unity-mcp` is connected, its test tooling (run + poll) is an alternative to the CLI; otherwise the CLI above is the portable path.

## Reading results is not optional

Never claim tests passed from the exit code alone, and never from the absence of errors in the console. The gate: parse the results XML (or the MCP tool's result payload) and quote the counts in your report — `passed="12" failed="0"` — plus the failure messages for anything that failed. If the results file was never written (Unity crashed, license issue, wrong path), the run **did not happen**; report NOT RUN with the log excerpt showing why, and never summarize a run you couldn't read as a pass.

## Prove the test can fail

A test that cannot fail is decoration. When you write a regression test for a bug fix, run it against the pre-fix code first and confirm it fails there — that failure is the test's reason to exist. (Getting at pre-fix code must not endanger other work: only `git stash` if the fix is the sole dirty change in the tree; if the fix is committed, use a temporary `git worktree` at the prior commit; if neither is safe, temporarily set the test's expected value to the pre-fix behavior to confirm the runner reports a failure, restore it immediately and confirm via `git diff` that the test is back in its intended state, and note in your report that pre-fix verification was indirect.) For new-behavior tests, predict each expected value by reading the implementation and computing it yourself; never run the code, observe its output, and assert that observed output back (that only proves the code agrees with itself, bugs included). If a test you expected to fail passes, stop and reconcile — the runner's verdict wins over your expectation.

## Don't stop at green — verify playability

Unit tests do not capture playability. After tests pass on a gameplay change, pair them with a visual check via **unity-editor-loop** (`Unity_Camera_Capture` / multi-angle scene capture). Report test results and visual verification separately; if you only ran tests, say so — don't imply the game was seen working.

## Related skills

- **unity-csharp** — structure logic for EditMode testability.
- **unity-editor-loop** — capture-based visual verification to pair with tests.
- **unity-build** — wiring these test runs into CI.
