## [wandb-base-0.11.11] - 2026-02-24

### 🚀 Features

- ONPREM-136 support for container opt out of global volumes (#562)
## [wandb-base-0.11.9] - 2026-02-12

### 🚀 Features

- Local image deprecation and migrate-db fix support (#549)
## [wandb-base-0.11.7] - 2026-01-23

### 🚀 Features

- Wandb-base global volumes (#551)
## [wandb-base-0.11.6] - 2025-12-18

### 🚀 Features

- Add keda support (#522)
## [wandb-base-0.11.4] - 2025-11-20

### 🐛 Bug Fixes

- Allow global override of docker registry for all images (#530)
## [wandb-base-0.11.3] - 2025-10-16

### 🐛 Bug Fixes

- Include handle image digest in version labeling (#504)
## [wandb-base-0.11.2] - 2025-09-30

### 🐛 Bug Fixes

- Support for image digest (#489)
## [wandb-base-0.11.1] - 2025-09-29

### 🐛 Bug Fixes

- Fix support for priorityClass (#497)
## [wandb-base-0.11.0] - 2025-09-19

### 🚀 Features

- Add tolerations and nodeSelector support (#480)
## [wandb-base-0.10.2] - 2025-09-04

### 🐛 Bug Fixes

- Always template the backfill job, but suspend it if its not enabled (#481)
## [wandb-base-0.10.1] - 2025-08-28

### 🐛 Bug Fixes

- Pass labels and annotations everywhere in wandb-base
## [wandb-base-0.10.0] - 2025-08-27

### 🚀 Features

- Support defining update strategies for deployments and statefulsets (#473)
## [wandb-base-0.9.1] - 2025-08-26

### 🐛 Bug Fixes

- Make cronjobs and jobs disableable, and disable parquet backfill by default (#472)
## [wandb-base-0.9.0] - 2025-08-19

### 🚀 Features

- Add helm hook support for jobs with roles and SAs (#465)
## [wandb-base-0.8.6] - 2025-08-15

### 🐛 Bug Fixes

- Debugging HPA lookup (#461)
## [wandb-base-0.8.5] - 2025-08-15

### 🐛 Bug Fixes

- Use currentReplicas instead of desiredReplicas (#460)
## [wandb-base-0.8.4] - 2025-08-15

### 🐛 Bug Fixes

- Replica count from HPA, reloader annotations, merge order fixes (#459)
## [wandb-base-0.8.3] - 2025-08-15

### 🐛 Bug Fixes

- Exclude job pods from the PDB (#457)
## [wandb-base-0.8.2] - 2025-08-15

### 🐛 Bug Fixes

- Bump resources and fix merge order (#456)
## [wandb-base-0.8.1] - 2025-08-06

### 🐛 Bug Fixes

- Multiple bug fixes (#451)
## [wandb-base-0.8.0] - 2025-08-05

### 🚀 Features

- Refactor all charts to use wandb-base chart (#417)
## [wandb-base-0.7.2] - 2025-05-27

### 🐛 Bug Fixes

- Adding support for topologySpreadConstraints to wandb-base (#413)
## [wandb-base-0.7.1] - 2025-05-13

### 🐛 Bug Fixes

- HPA link (#409)
## [wandb-base-0.7.0] - 2025-05-13

### 🚀 Features

- Migrate frfu (#362)
## [wandb-base-0.6.1] - 2025-04-03

### 🐛 Bug Fixes

- Initial effort to Safeguard labels (#379)
## [wandb-base-0.6.0] - 2025-03-18

### 🐛 Bug Fixes

- Incorrect indentation for imagePullSecrets (#363)
## [wandb-base-0.5.0] - 2025-03-03

### 🚀 Features

- Add reloader to operator-wandb, add reloader annotations to wan… (#356)
## [wandb-base-0.4.1] - 2025-02-03

### 🚀 Features

- Add gcp Security Policy to wandb-base (#334)
## [wandb-base-0.4.0] - 2025-01-22

### 🚀 Features

- Backend config, mysql connection string, hpa (#322)
## [wandb-base-0.3.4] - 2025-01-16

### 🐛 Bug Fixes

- Bump version (#316)
## [wandb-base-0.3.3] - 2025-01-16

### 🐛 Bug Fixes

- API service annotations (#310)
- Prevent restarts (#315)
## [wandb-base-0.3.1] - 2025-01-15

### 🐛 Bug Fixes

- HPA (#309)
## [wandb-base-0.3.0] - 2025-01-14

### 🚀 Features

- Init Settings Migration Job (#298)
## [wandb-base-0.1.1] - 2024-12-04

### 🚀 Features

- Init glue (#260)
## [wandb-base-0.1.0] - 2024-11-12

### 🚀 Features

- Generic service chart and pr releases (#244)
