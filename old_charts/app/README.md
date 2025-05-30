# Local

- [Local](#local)
  - [Requirements](#requirements)
  - [Configuration](#configuration)
    - [Globals](#globals)
    - [Options](#options)
    - [Chart configuration examples](#chart-configuration-examples)
      - [extraEnv](#extraenv)
      - [extraEnvFrom](#extraenvfrom)
      - [extraEnvFrom](#extraenvfrom-1)

## Requirements

This chart depends on Redis, Bucket and MySQL services, either as part of the
complete W&B Server chart or provided as external services reachable from the
Kubernetes cluster this chart is deployed onto.

## Configuration

### Globals

### Options

| Parameter           | Default       | Description                                                                                        |
| ------------------- | ------------- | -------------------------------------------------------------------------------------------------- |
| `enabled`           | `true`        | Server enable flag                                                                                 |
| `priorityClassName` | `""`          | Allow configuring pods priorityClassName, this is used to control pod priority in case of eviction |
| `common.labels`     |               | Supplemental labels that are applied to all objects created by this chart.                         |
| `podLabels`         |               | Supplemental Pod labels. Will not be used for selectors.                                           |
| `extraEnv`          |               | List of extra environment variables to expose                                                      |
| `extraEnvFrom`      |               | List of extra environment variables from other data sources to expose                              |
| `image.pullPolicy`  | `Always`      | Server image pull policy                                                                           |
| `image.pullSecrets` |               | Secrets for the image repository                                                                   |
| `image.repository`  | `wandb/local` | Server image repository                                                                            |
| `image.tag`         |               | Server image tag                                                                                   |
| `tolerations`       | `[]`          | Toleration labels for pod assignment                                                               |

### Chart configuration examples

#### extraEnv

#### extraEnvFrom

`extraEnv` allows you to expose additional environment variables in all
containers in the pods.

```yaml
extraEnv:
  SOME_KEY: some_value
  SOME_OTHER_KEY: some_other_value
```

When the container is started, you can confirm that the environment variables
are exposed:

Below is an example use of extraEnv:

```bash
env | grep SOME
SOME_KEY=some_value
SOME_OTHER_KEY=some_other_value
```

#### extraEnvFrom

`extraEnvFrom` allows you to expose additional environment variables from other
data sources in all containers in the pods. Subsequent variables can be
overridden per deployment.

Below is an example use of `extraEnvFrom`:

```yaml
extraEnvFrom:
  MY_NODE_NAME:
    fieldRef:
      fieldPath: spec.nodeName
  MY_CPU_REQUEST:
    resourceFieldRef:
      containerName: test-container
      resource: requests.cpu
  SECRET_THING:
    secretKeyRef:
      name: special-secret
      key: special_token
      # optional: boolean
```
