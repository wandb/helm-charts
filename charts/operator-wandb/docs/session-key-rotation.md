# Session Key Rotation

`operator-wandb` generates `GORILLA_SESSION_KEY` on first install and stores it
in `<release>-gorilla-session-key`. Later reconciliations retain the stored key.

The chart can rotate this managed key without immediately invalidating existing
sessions. The routine workflow has three phases so every running pod learns the
candidate key before any pod starts signing with it.

## Managed Rotation

Choose a unique rotation ID and start with `prepare`:

```yaml
global:
  auth:
    sessionKeyRotation:
      id: "2026-07-session-key"
      phase: prepare
```

`prepare` generates a candidate key, keeps the current signing key, and adds the
candidate to `GORILLA_SESSION_PREVIOUS_KEYS`. The rotation ID and phase also
change the API and app pod templates, which starts a rollout. Wait for every
enabled API and app pod to finish rolling before continuing. This wait is the
critical safety step: during the next rollout, prepared pods sign with A and
accept B, while activated pods sign with B and accept A.

Promote the candidate with the same ID:

```yaml
global:
  auth:
    sessionKeyRotation:
      id: "2026-07-session-key"
      phase: activate
```

`activate` makes the candidate the current signing key and retains the outgoing
key in `GORILLA_SESSION_PREVIOUS_KEYS`. Reapplying the same ID and phase does not
swap the keys again.

After the longest-lived session or token has expired, remove the verification
keys:

```yaml
global:
  auth:
    sessionKeyRotation:
      id: "2026-07-session-key"
      phase: clear
```

Wait for each rollout to complete before advancing the phase. Use a new ID for
the next rotation. To cancel before activation, advance a prepared rotation
directly to `clear`; the current signing key will remain unchanged.

## Choose a Rotation Policy

The phase sequence and wait policy determine the response:

| Policy | Procedure | User impact | Use when |
| ------ | --------- | ----------- | -------- |
| Routine graceful | `prepare`, `activate`, wait out the longest-lived cookie or token, then `clear` | Existing sessions and tokens remain valid | Scheduled rotation with no suspected exposure |
| Accelerated | `prepare` and wait, `activate` and wait, then `clear` immediately | Avoids cross-generation login loops, but invalidates sessions and tokens signed by the old key | A leak is plausible, but there is no evidence of active forgery |
| Emergency hard cutover | Apply `hard-cutover` with a new rotation ID | Logs users out and may cause transient authentication failures during rollout | There is high confidence of compromise or active abuse |

For an accelerated rotation, "immediately" means there is no token-lifetime
overlap period after the activation rollout. Do not advance the phase while a
rollout is still in progress.

An emergency hard cutover generates a new managed current key and removes all
previous verification keys in one reconciliation:

```yaml
global:
  auth:
    sessionKeyRotation:
      id: "incident-2026-07-29"
      phase: hard-cutover
```

This deliberately breaks compatibility between old and new pods. Coordinate it
as a disruptive change and complete the API and app rollouts as quickly as is
safe. Reapplying the same ID and phase retains the generated key; use a unique
ID for every hard cutover. A hard cutover with a new ID can interrupt a
prepared or activated rotation.

## External Secrets

`global.auth.sessionKey` and `global.auth.sessionKeyPrevious` accept literal
values or Kubernetes `valueFrom` maps. Prefer Secret references so key material
does not appear in rendered manifests:

```yaml
global:
  auth:
    sessionKey:
      valueFrom:
        secretKeyRef:
          name: gorilla-session-keys
          key: current
    sessionKeyPrevious:
      valueFrom:
        secretKeyRef:
          name: gorilla-session-keys
          key: previous
    sessionKeyRolloutId: "2026-07-session-key-prepare"
```

For external keys, create and update `gorilla-session-keys` separately.
Kubernetes does not refresh environment variables in existing containers.
However, an installed Secret-reload controller such as Stakater Reloader may
detect the referenced Secret update and start API and app rollouts immediately.
Monitor for that rollout before making another change.

Do not rely on a reload controller being installed or enabled. After each
Secret update, change `sessionKeyRolloutId` and apply the Helm release to
guarantee that the pod template changes and every enabled API and app replica
restarts. If a reload controller already completed a rollout, changing the
marker may cause a second, safe rollout:

1. **Prepare:** set `current` to A and `previous` to B, set the rollout ID to a
   unique value ending in `-prepare`, apply the release, and wait for rollout.
2. **Activate:** set `current` to B and `previous` to A, change the rollout ID
   to a value ending in `-activate`, apply the release, and wait for rollout.
3. **Clear:** set `previous` to an empty value, change the rollout ID to a value
   ending in `-clear`, apply the release, and wait for rollout.

`sessionKeyRolloutId` is only a pod-template marker; it must not contain key
material. External key overrides cannot be combined with
`sessionKeyRotation`, but they can and should be combined with
`sessionKeyRolloutId`.
