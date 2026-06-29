# ScriptableObject + event-channel architecture

The greenfield default for Unity 6 gameplay code: Unity-native, zero third-party dependencies, testable without a running scene. Based on Unity's own "Open Project" patterns. Apply only when no other architecture is established (see `detect-project.md`).

## Table of contents
- Why this default
- Data as ScriptableObjects
- Event channels
- Runtime sets
- When to deviate

## Why this default

- **Decoupling without a framework.** Systems communicate through SO assets, not direct references or singletons. No `GameObject.Find`, no static god-objects.
- **Designer-editable data.** Tunables live in `.asset` files editable in the Inspector without recompiling.
- **Testable.** Logic on plain C# / SO methods runs in EditMode tests with no scene.

## Data as ScriptableObjects

Put configuration and shared data in SOs, not literals in MonoBehaviours.

```csharp
[CreateAssetMenu(menuName = "Game/Weapon")]
public sealed class WeaponSO : ScriptableObject
{
    [SerializeField] private float damage = 10f;
    [SerializeField] private float fireRate = 0.2f;

    public float Damage => damage;
    public float FireRate => fireRate;
}
```

Gotcha: if you mutate an SO from editor scripts in Edit mode, call `EditorUtility.SetDirty(obj)` (and `AssetDatabase.SaveAssets()`) or the change won't persist. For large data arrays, add `[PreferBinarySerialization]` to the SO — YAML is slow and bloated for bulk data.

## Event channels

A channel is an SO that raises an event; listeners subscribe. Publishers and subscribers never reference each other — only the shared channel asset.

```csharp
[CreateAssetMenu(menuName = "Events/Void Event Channel")]
public sealed class VoidEventChannelSO : ScriptableObject
{
    public event Action OnRaised;
    public void Raise() => OnRaised?.Invoke();
}
```

Typed variant: `IntEventChannelSO : ScriptableObject` with `event Action<int> OnRaised` and `Raise(int value)`.

Listener:

```csharp
public sealed class ScoreDisplay : MonoBehaviour
{
    [SerializeField] private IntEventChannelSO scoreChanged;

    private void OnEnable()  => scoreChanged.OnRaised += HandleScore;
    private void OnDisable() => scoreChanged.OnRaised -= HandleScore;

    private void HandleScore(int value) { /* update UI */ }
}
```

Always unsubscribe in `OnDisable`/`OnDestroy` — SO events outlive scene objects, so a missing unsubscribe leaks and can call into destroyed objects.

## Runtime sets

An SO holding a live list (e.g. all active enemies) that systems query without `FindObjectsOfType`. Members register in `OnEnable`, deregister in `OnDisable`.

## When to deviate

- **Already using DI or MVC** → conform to it; do not introduce SO channels alongside.
- **High-frequency events** (per-frame, thousands/sec) → C# `event`/`Action` or a direct interface call is cheaper than SO-channel indirection. SO channels are for decoupled, low-to-moderate-frequency game events.
- **DOTS/ECS systems** → different paradigm entirely; this guidance does not apply.
