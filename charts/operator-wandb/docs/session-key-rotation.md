# Session Key Rotation

`operator-wandb` generates `GORILLA_SESSION_KEY` on first install and stores it
in `<release>-gorilla-session-key`. Later reconciliations retain the stored key.

The chart can rotate this managed key without immediately invalidating existing
sessions. Rotation has three phases so every running pod learns the candidate
key before any pod starts signing with it.

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
candidate to `GORILLA_SESSION_KEY_PREVIOUS`. The rotation ID and phase also
change the API and app pod templates, which starts a rollout. Wait for every
enabled API and app pod to finish rolling before continuing.

Promote the candidate with the same ID:

```yaml
global:
  auth:
    sessionKeyRotation:
      id: "2026-07-session-key"
      phase: activate
```

`activate` makes the candidate the current signing key and retains the outgoing
key in `GORILLA_SESSION_KEY_PREVIOUS`. Reapplying the same ID and phase does not
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
```

For external keys, create and update `gorilla-session-keys` separately and use
the same prepare, activate, and clear ordering when changing its values.
External key overrides cannot be combined with `sessionKeyRotation`.
