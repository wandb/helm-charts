## [operator-wandb-0.41.3] - 2026-03-24

### 🐛 Bug Fixes

- Use host,null as default CORS for api (#576)
## [operator-wandb-0.41.2] - 2026-03-20

### 💼 Other

- Fix to OIDC env var from GORILLA_OIDC_AUTH_METHOD to GORILLA_AUTH_METHOD (#575)
## [operator-wandb-0.41.1] - 2026-03-13

### ⚙️ Miscellaneous Tasks

- *(weave)* Add WEAVE_REDIS_URL to weave-trace configmap (#570)
## [operator-wandb-0.40.7] - 2026-03-04

### 🐛 Bug Fixes

- Console needs to point to the api instead of app when bypass is enabled (#567)
## [operator-wandb-0.40.5] - 2026-02-26

### ⚙️ Miscellaneous Tasks

- Dont use global mounts in prehooks (#563)
## [operator-wandb-0.40.4] - 2026-02-24

### 🚀 Features

- ONPREM-136 support for container opt out of global volumes (#562)
## [operator-wandb-0.40.3] - 2026-02-22

### 🐛 Bug Fixes

- *(weave)* Make horizontal pod autoscaler work for weave-trace and weave-trace-worker (#561)
## [operator-wandb-0.40.2] - 2026-02-12

### 🚀 Features

- Local image deprecation and migrate-db fix support (#549)
## [operator-wandb-0.40.1] - 2026-02-06

### 🐛 Bug Fixes

- Make bufstream hostname configurable for weave-trace (#559)
## [operator-wandb-0.40.0] - 2026-02-03

### 🚀 Features

- *(operator-wandb)* Added SMTP user defined secret (#556)
## [operator-wandb-0.39.5] - 2026-01-30

### 🚀 Features

- Add SSL_CERT_DIR to wandb.sslCertEnvs (#554)
## [operator-wandb-0.39.4] - 2026-01-27

### 🐛 Bug Fixes

- Remove weave-trace's override of envtpls (#553)
## [operator-wandb-0.39.3] - 2026-01-26

### 🐛 Bug Fixes

- Update wandb-base version for operator-wandb (#552)
## [operator-wandb-0.39.2] - 2026-01-15

### ⚙️ Miscellaneous Tasks

- *(dev)* More generous rate limits in dedicated to start (#548)
## [operator-wandb-0.39.1] - 2026-01-07

### 🐛 Bug Fixes

- Remove fallback of history store (bigtable/mysql) (#541)
## [operator-wandb-0.39.0] - 2026-01-06

### 🚀 Features

- Mysql ca cert config (#546)
## [operator-wandb-0.38.10] - 2026-01-05

### 🐛 Bug Fixes

- *(dev)* Keda defaults for frfu (#547)
## [operator-wandb-0.38.9] - 2025-12-19

### 🚀 Features

- *(weave)* Add SSL_CERT_FILE and REQUESTS_CA_BUNDLE environment variables (#538)
## [operator-wandb-0.38.8] - 2025-12-19

### 🚀 Features

- Allow rate limits to be configured (#542)
## [operator-wandb-0.38.7] - 2025-12-18

### 🚀 Features

- Add keda support (#522)
## [operator-wandb-0.38.6] - 2025-12-18

### 🐛 Bug Fixes

- Add bucket identity to env config map (#540)
## [operator-wandb-0.38.5] - 2025-12-18

### 🐛 Bug Fixes

- Remove WF_CLICKHOUSE_PASS from environment variables in mul… (#543)
## [operator-wandb-0.38.3] - 2025-11-26

### 🚀 Features

- *(weave)* Add CA cert support to weave-trace-migrate init container (#535)
## [operator-wandb-0.38.2] - 2025-11-25

### 🚀 Features

- *(weave-trace)* Add CA certificate support for weave deployments (#528)
## [operator-wandb-0.38.1] - 2025-11-21

### 🐛 Bug Fixes

- Default audit log collection to on (#533)
## [operator-wandb-0.38.0] - 2025-11-20

### 🚀 Features

- Add OIDC secret via k8s secret reference (#524)
## [operator-wandb-0.37.6] - 2025-11-20

### 🐛 Bug Fixes

- Allow global override of docker registry for all images (#530)
## [operator-wandb-0.37.4] - 2025-11-18

### 🚀 Features

- Add statsig to FRFU (#526)
## [operator-wandb-0.37.2] - 2025-11-12

### ⚙️ Miscellaneous Tasks

- Add reflection for configs and secrets required by weave trace (#523)
## [operator-wandb-0.37.1] - 2025-11-07

### 🚀 Features

- Add metrics observer in runs-v2-bufstream test config (#520)
## [operator-wandb-0.37.0] - 2025-11-06

### 🚀 Features

- Allow for advance global.mysql values (#500)

### ⚙️ Miscellaneous Tasks

- Update local-development.md (#519)
## [operator-wandb-0.36.1] - 2025-11-03

### 🐛 Bug Fixes

- These shouldn't be conditional, but will be removed entirely when ready (#518)
## [operator-wandb-0.36.0] - 2025-11-03

### 🚀 Features

- Nginx and OIDC configs to improve testing and local development (#514)
## [operator-wandb-0.35.16] - 2025-10-31

### 🐛 Bug Fixes

- Overlay emptyDir to contain certs that might be inserted. (#516)
## [operator-wandb-0.35.15] - 2025-10-31

### 🐛 Bug Fixes

- Adjust autoscaling for FRFU (#515)
## [operator-wandb-0.35.14] - 2025-10-16

### 🐛 Bug Fixes

- Enable live history cleanup on stable export in executor and glue (#506)
## [operator-wandb-0.35.13] - 2025-10-16

### 🐛 Bug Fixes

- Fix Weave related helm tests (#509)
## [operator-wandb-0.35.12] - 2025-10-16

### 🐛 Bug Fixes

- Bucket path conditional (#508)
## [operator-wandb-0.35.11] - 2025-10-16

### 🐛 Bug Fixes

- Include handle image digest in version labeling (#504)
## [operator-wandb-0.35.10] - 2025-10-07

### 🐛 Bug Fixes

- Use OIDC_SECRET for client secret env var (#503)
## [operator-wandb-0.35.9] - 2025-10-06

### 🐛 Bug Fixes

- Add /tmp emptyDir for services using the wandb-sdk (#501)
## [operator-wandb-0.35.8] - 2025-10-02

### 🐛 Bug Fixes

- Create and emptyDir to house the helm cache so we don't need to rely on container file permissions (#499)
## [operator-wandb-0.35.7] - 2025-09-30

### 🐛 Bug Fixes

- Assuming wandb verify is much more stable now and should not flake (#469)
## [operator-wandb-0.35.6] - 2025-09-30

### 🐛 Bug Fixes

- Support for image digest (#489)
## [operator-wandb-0.35.5] - 2025-09-29

### 🐛 Bug Fixes

- Include license cert path in wandb global (#492)

### ⚙️ Miscellaneous Tasks

- Fix bitnami testing issues (#498)
## [operator-wandb-0.35.4] - 2025-09-29

### 🐛 Bug Fixes

- Fix support for priorityClass (#497)
## [operator-wandb-0.35.3] - 2025-09-26

### 🐛 Bug Fixes

- Rollback adjustments for small and update pod resources for executor (#495)
## [operator-wandb-0.35.2] - 2025-09-25

### ⚙️ Miscellaneous Tasks

- Make snapshot testing more user friendly (#490)
## [operator-wandb-0.35.1] - 2025-09-24

### 🐛 Bug Fixes

- Update pod resources for app, api, and parquet. (#494)
## [operator-wandb-0.35.0] - 2025-09-19

### 🚀 Features

- Add tolerations and nodeSelector support (#480)
## [operator-wandb-0.34.16] - 2025-09-16

### ⚙️ Miscellaneous Tasks

- Increase default frfu replicas based on t-shirt size (#488)
## [operator-wandb-0.34.15] - 2025-09-12

### ⚙️ Miscellaneous Tasks

- Right-size parquet and frfu requests / limits (#487)
## [operator-wandb-0.34.14] - 2025-09-09

### 🐛 Bug Fixes

- Add ca certs to weave chart (#485)
## [operator-wandb-0.34.13] - 2025-09-04

### 🐛 Bug Fixes

- Don't set PUBLIC_URL (#483)
## [operator-wandb-0.34.12] - 2025-09-04

### 🐛 Bug Fixes

- Always template the backfill job, but suspend it if its not enabled (#481)
## [operator-wandb-0.34.11] - 2025-09-04

### 🐛 Bug Fixes

- Missed this executor configuration (#479)
## [operator-wandb-0.34.10] - 2025-08-29

### ⚙️ Miscellaneous Tasks

- *(dev)* Get statsig key from secret store (#476)
## [operator-wandb-0.34.9] - 2025-08-28

### 🐛 Bug Fixes

- Add additional volume mounts to filemeta (#475)
## [operator-wandb-0.34.8] - 2025-08-28

### 🐛 Bug Fixes

- Pass labels and annotations everywhere in wandb-base
## [operator-wandb-0.34.7] - 2025-08-27

### 🚀 Features

- Support defining update strategies for deployments and statefulsets (#473)
## [operator-wandb-0.34.6] - 2025-08-26

### 🐛 Bug Fixes

- Make cronjobs and jobs disableable, and disable parquet backfill by default (#472)
## [operator-wandb-0.34.5] - 2025-08-21

### 🐛 Bug Fixes

- Missing paths in ingress configs (#471)
## [operator-wandb-0.34.4] - 2025-08-21

### 🐛 Bug Fixes

- Change redis default to bitnami legacy (#470)
## [operator-wandb-0.34.3] - 2025-08-20

### 🐛 Bug Fixes

- Default GOMAXPROCS to the container's cpu limits (#467)
## [operator-wandb-0.34.2] - 2025-08-19

### 🐛 Bug Fixes

- Handle upgrade from pre 0.33.x within the chart with minimal disruptions (#466)
## [operator-wandb-0.34.1] - 2025-08-19

### ⚙️ Miscellaneous Tasks

- Add in corweave obs api key to helm charts (#448)
## [operator-wandb-0.34.0] - 2025-08-18

### 🚀 Features

- Anaconda2 (#430)
## [operator-wandb-0.33.14] - 2025-08-18

### 🐛 Bug Fixes

- Add CW identity to missing services (#463)
## [operator-wandb-0.33.13] - 2025-08-15

### 🐛 Bug Fixes

- Debugging HPA lookup (#461)
## [operator-wandb-0.33.12] - 2025-08-15

### 🐛 Bug Fixes

- Use currentReplicas instead of desiredReplicas (#460)
## [operator-wandb-0.33.11] - 2025-08-15

### 🐛 Bug Fixes

- Replica count from HPA, reloader annotations, merge order fixes (#459)
## [operator-wandb-0.33.10] - 2025-08-15

### 🐛 Bug Fixes

- Add operator enabled env flag to frontend container (#458)
## [operator-wandb-0.33.9] - 2025-08-15

### 🐛 Bug Fixes

- Exclude job pods from the PDB (#457)
## [operator-wandb-0.33.8] - 2025-08-15

### 🐛 Bug Fixes

- Bump resources and fix merge order (#456)
## [operator-wandb-0.33.7] - 2025-08-14

### 🐛 Bug Fixes

- Include local configmap for app pod (#455)
## [operator-wandb-0.33.6] - 2025-08-13

### 🚀 Features

- Add native coreweave bucket support (#453)
## [operator-wandb-0.33.4] - 2025-08-13

### 🚀 Features

- Add weave-trace-worker support to refactored charts (#449)
## [operator-wandb-0.33.3] - 2025-08-08

### ⚙️ Miscellaneous Tasks

- *(backend)* Add GORILLA_USAGE_METRICS_CACHE env (#454)
## [operator-wandb-0.33.2] - 2025-08-06

### 🐛 Bug Fixes

- Set defaults for weave query (#447)
## [operator-wandb-0.33.1] - 2025-08-06

### 🐛 Bug Fixes

- Multiple bug fixes (#451)
## [operator-wandb-0.33.0] - 2025-08-05

### 🚀 Features

- Refactor all charts to use wandb-base chart (#417)
## [operator-wandb-0.32.9] - 2025-07-29

### 🐛 Bug Fixes

- Better utilize license secrets (#445)
## [operator-wandb-0.32.7] - 2025-07-23

### 🐛 Bug Fixes

- Add custom ca for executor (#440)
## [operator-wandb-0.32.6] - 2025-07-22

### 🐛 Bug Fixes

- Use one replica by default for filemeta (#443)
## [operator-wandb-0.32.5] - 2025-07-22

### 🐛 Bug Fixes

- Properly handle url encoded passwords in mysql (#442)
## [operator-wandb-0.32.4] - 2025-07-02

### 🐛 Bug Fixes

- Install bigtable emulator and enable filestream for fmb configs (#433)
## [operator-wandb-0.32.3] - 2025-07-02

### 🐛 Bug Fixes

- Add custom image support for migraiton job (#432)
## [operator-wandb-0.32.2] - 2025-07-02

### 🐛 Bug Fixes

- Add pubsub testing configs (#431)
## [operator-wandb-0.32.1] - 2025-06-19

### 🐛 Bug Fixes

- Filemeta additional required envs (#427)
## [operator-wandb-0.32.0] - 2025-06-19

### 🚀 Features

- Filemeta as its own deployment (#425)
## [operator-wandb-0.31.13] - 2025-06-11

### 🐛 Bug Fixes

- Use metadata.namespace (#420)
## [operator-wandb-0.31.12] - 2025-06-10

### 🐛 Bug Fixes

- Patch illegal tpl char '-' (#424)
## [operator-wandb-0.31.11] - 2025-06-10

### 🐛 Bug Fixes

- Add missing frontend env (#423)
## [operator-wandb-0.31.10] - 2025-06-10

### 🐛 Bug Fixes

- Adding gorila secret to app (#422)
## [operator-wandb-0.31.9] - 2025-06-09

### 🐛 Bug Fixes

- App chart use redis conn string for select env variables (#421)
## [operator-wandb-0.31.8] - 2025-06-04

### 🐛 Bug Fixes

- Prevent recursive b64ing clickhouse passwords (#418)
## [operator-wandb-0.31.7] - 2025-05-29

### 🐛 Bug Fixes

- Wire statsig API key to all services (#416)
## [operator-wandb-0.31.6] - 2025-05-28

### 🐛 Bug Fixes

- Frontend load global extraENV & setup script (#414)
## [operator-wandb-0.31.5] - 2025-05-27

### 🐛 Bug Fixes

- Adding support for topologySpreadConstraints to operator-wandb charts (#412)
## [operator-wandb-0.31.4] - 2025-05-22

### 🐛 Bug Fixes

- Source weave venv (#411)
## [operator-wandb-0.31.3] - 2025-05-13

### 🐛 Bug Fixes

- HPA link (#409)
## [operator-wandb-0.31.2] - 2025-05-13

### 🐛 Bug Fixes

- Resources (#408)
## [operator-wandb-0.31.1] - 2025-05-13

### 🐛 Bug Fixes

- Allow k8s-secretmanager and fix weave-trace secret retrieval (#406)
## [operator-wandb-0.31.0] - 2025-05-13

### 🚀 Features

- Migrate frfu (#362)
## [operator-wandb-0.30.2] - 2025-05-12

### ⚙️ Miscellaneous Tasks

- More descriptive consumer group id (#405)
## [operator-wandb-0.30.1] - 2025-05-08

### 🐛 Bug Fixes

- Add the file meta data flag (#402)
## [operator-wandb-0.30.0] - 2025-05-08

### 🚀 Features

- Add clickhouse local install via bitnami charts (#390)
## [operator-wandb-0.29.3] - 2025-05-07

### 🐛 Bug Fixes

- Kafka env for executor (#401)
## [operator-wandb-0.29.2] - 2025-05-05

### 🐛 Bug Fixes

- Additional Frontend needed env vars (#397)
## [operator-wandb-0.29.1] - 2025-04-30

### 🐛 Bug Fixes

- Enable to slow rollout of additional api ingress routes (#398)
## [operator-wandb-0.29.0] - 2025-04-24

### 🚀 Features

- Initial frontend HA (#392)
## [operator-wandb-0.28.23] - 2025-04-23

### 🚀 Features

- Backfiller exports on executor, lower backfiller concurrency limits (#394)
## [operator-wandb-0.28.22] - 2025-04-23

### 🚀 Features

- Disable TASK QUEUE in parquet-backfill (#393)
## [operator-wandb-0.28.21] - 2025-04-21

### 🚀 Features

- Add t-shirt size to app, parquet, api, glue, executor, and parquet-backfill (#387)
## [operator-wandb-0.28.20] - 2025-04-21

### 🚀 Features

- Set parquet reader fuse enabled too (#391)
## [operator-wandb-0.28.19] - 2025-04-17

### 🐛 Bug Fixes

- Cleanup bufstream configs (#368)
- Bump version (#389)
## [operator-wandb-0.28.18] - 2025-04-17

### 🐛 Bug Fixes

- *(backend)* History store routing in api and glue (#388)
## [operator-wandb-0.28.17] - 2025-04-14

### 🐛 Bug Fixes

- Allow size passthrough (#373)
## [operator-wandb-0.28.16] - 2025-04-11

### 🐛 Bug Fixes

- Add missing env to API (#386)
## [operator-wandb-0.28.15] - 2025-04-09

### 🐛 Bug Fixes

- Bucket and Mysql secrets if externally defined (#383)
## [operator-wandb-0.28.14] - 2025-04-04

### 🐛 Bug Fixes

- Bucket env's (#382)
## [operator-wandb-0.28.13] - 2025-04-03

### ⚡ Performance

- Tune GCS fuse cache for parquet (#381)
## [operator-wandb-0.28.12] - 2025-04-03

### 🐛 Bug Fixes

- Less aggressive health checks for parquet (#380)
## [operator-wandb-0.28.11] - 2025-04-03

### 🐛 Bug Fixes

- Initial effort to Safeguard labels (#379)
## [operator-wandb-0.28.10] - 2025-04-02

### 💼 Other

- Promote api/glue to stable (#374)
## [operator-wandb-0.28.9] - 2025-04-02

### 🐛 Bug Fixes

- Pass executor concurrency correctly (#376)
## [operator-wandb-0.28.8] - 2025-04-01

### 🐛 Bug Fixes

- Tweak GCS Fuse settings for parquet (#375)
## [operator-wandb-0.28.7] - 2025-03-28

### 🐛 Bug Fixes

- Correctly enable fuse cache for parquet (#372)
## [operator-wandb-0.28.6] - 2025-03-19

### 🚀 Features

- *(deployer)* Redis URL construction overhaul (#366)
## [operator-wandb-0.28.5] - 2025-03-18

### 🐛 Bug Fixes

- Incorrect indentation for imagePullSecrets (#363)
## [operator-wandb-0.28.4] - 2025-03-18

### 🐛 Bug Fixes

- Incorrect mysql service name (#364)
## [operator-wandb-0.28.3] - 2025-03-17

### 🐛 Bug Fixes

- Prefix the OIDC envvars for gorilla apps to find them (#365)
## [operator-wandb-0.28.2] - 2025-03-12

### 🐛 Bug Fixes

- Incorrect StorageClass ref and indent (#360)
## [operator-wandb-0.28.1] - 2025-03-06

### 🐛 Bug Fixes

- Update how worker concurrency is templated to support all redis configs (#359)
## [operator-wandb-0.28.0] - 2025-03-04

### 🚀 Features

- Adding console proxy config (#355)
## [operator-wandb-0.27.0] - 2025-03-03

### 🚀 Features

- Add reloader to operator-wandb, add reloader annotations to wan… (#356)
## [operator-wandb-0.26.12] - 2025-03-03

### 🐛 Bug Fixes

- Filestream does not need a specific image version (#358)
## [operator-wandb-0.26.11] - 2025-02-28

### 🐛 Bug Fixes

- Disable redis auth by default (#357)
## [operator-wandb-0.26.10] - 2025-02-25

### 🚀 Features

- Default global.redis.external to false (#354)
## [operator-wandb-0.26.9] - 2025-02-19

### 🐛 Bug Fixes

- Bump otel limits (#352)
## [operator-wandb-0.26.8] - 2025-02-19

### 🐛 Bug Fixes

- Bad template (#351)
## [operator-wandb-0.26.7] - 2025-02-18

### ⚙️ Miscellaneous Tasks

- Set GORILLA_CACHE for filestream pod (#350)
## [operator-wandb-0.26.6] - 2025-02-13

### 🐛 Bug Fixes

- Allow executor to be installed, even if not enabled (#349)
## [operator-wandb-0.26.5] - 2025-02-13

### 🐛 Bug Fixes

- Set the task queue correctly (#348)
## [operator-wandb-0.26.4] - 2025-02-13

### 🐛 Bug Fixes

- Set host for email team invites (#347)
## [operator-wandb-0.26.3] - 2025-02-13

### 🐛 Bug Fixes

- Add tests for operator-wandb (#338)
## [operator-wandb-0.26.2] - 2025-02-12

### 🐛 Bug Fixes

- Fix pod annotations indentation (#345)
## [operator-wandb-0.26.1] - 2025-02-12

### 🐛 Bug Fixes

- Fix tolerations key in templates (#344)
## [operator-wandb-0.26.0] - 2025-02-12

### 🚀 Features

- Add imagePullSecrets for private deployment (#330)
## [operator-wandb-0.25.5] - 2025-02-11

### 🐛 Bug Fixes

- Add switch to enable replicated queries on Weave Trace (#342)
## [operator-wandb-0.25.4] - 2025-02-11

### ⚡ Performance

- Increase parquet arrow buffer size (#340)
## [operator-wandb-0.25.3] - 2025-02-07

### 🐛 Bug Fixes

- Bucket needs to be used via include (#341)
## [operator-wandb-0.25.2] - 2025-02-05

### 🐛 Bug Fixes

- Local auth fix (#333)
## [operator-wandb-0.25.1] - 2025-02-05

### 🐛 Bug Fixes

- Update weave-trace gcp related settings (#339)
## [operator-wandb-0.25.0] - 2025-02-05

### 🚀 Features

- Add `gcpSecurityPolicy` (#336)

### ⚙️ Miscellaneous Tasks

- Update lock file (#337)
## [operator-wandb-0.24.9] - 2025-02-03

### 🐛 Bug Fixes

- Make the otel trace endpoint configurable (#326)
## [operator-wandb-0.24.8] - 2025-01-30

### 🐛 Bug Fixes

- Fix indent for annotations block under `spec` (#332)
## [operator-wandb-0.24.7] - 2025-01-29

### 🐛 Bug Fixes

- Migrations don't block gorilla startup (#331)
## [operator-wandb-0.24.6] - 2025-01-28

### 🐛 Bug Fixes

- Anaconda for sweeps (#329)
## [operator-wandb-0.24.5] - 2025-01-28

### 🐛 Bug Fixes

- Use the same defaults (#328)
## [operator-wandb-0.24.4] - 2025-01-27

### 🐛 Bug Fixes

- Shadow queue hard coded variables (#327)
## [operator-wandb-0.24.2] - 2025-01-23

### 🐛 Bug Fixes

- Pass a port number to glue that doesn't collide with nginx (#325)
## [operator-wandb-0.24.1] - 2025-01-23

### 🐛 Bug Fixes

- Switch between default bucket and bucket based on name (#324)
## [operator-wandb-0.24.0] - 2025-01-22

### 🚀 Features

- Backend config, mysql connection string, hpa (#322)
## [operator-wandb-0.23.9] - 2025-01-21

### 🐛 Bug Fixes

- Default region (#321)
## [operator-wandb-0.23.8] - 2025-01-21

### 🐛 Bug Fixes

- Task Queue Templating (#318)
## [operator-wandb-0.23.7] - 2025-01-16

### 🐛 Bug Fixes

- Bucket postfix trailing slash (#317)
## [operator-wandb-0.23.6] - 2025-01-16

### 🐛 Bug Fixes

- Bump version (#316)
## [operator-wandb-0.23.5] - 2025-01-16

### 🐛 Bug Fixes

- Prevent restarts (#315)
## [operator-wandb-0.23.4] - 2025-01-15

### 🐛 Bug Fixes

- Create Secrets (#313)
## [operator-wandb-0.23.3] - 2025-01-15

### 🐛 Bug Fixes

- API service annotations (#310)
- Bumping the version (#312)
## [operator-wandb-0.23.2] - 2025-01-15

### 🐛 Bug Fixes

- Enable flat run field updates in executor pod (#311)
## [operator-wandb-0.23.1] - 2025-01-15

### 🐛 Bug Fixes

- HPA (#309)
## [operator-wandb-0.23.0] - 2025-01-14

### 🚀 Features

- Init Settings Migration Job (#298)
## [operator-wandb-0.22.5] - 2025-01-13

### 🐛 Bug Fixes

- Upgrade bufstream to 0.3.5 (#307)
## [operator-wandb-0.22.4] - 2025-01-10

### 🐛 Bug Fixes

- We dont want the username and password for bufstream at the moment (#305)
- Bump chart version (#306)
## [operator-wandb-0.22.3] - 2025-01-08

### 🚀 Features

- Add GCP backend config (#280)
## [operator-wandb-0.22.2] - 2025-01-08

### 🚀 Features

- Option to pass through reference to iam identity to console (#301)

### 🐛 Bug Fixes

- Release new version (due to previous pipeline failure) (#302)
## [operator-wandb-0.22.0] - 2025-01-06

### 🚀 Features

- GCS FUSE support (#283)
## [operator-wandb-0.21.8] - 2024-12-17

### 🐛 Bug Fixes

- If you don't do this it outputs "<no value>" (#294)
## [operator-wandb-0.21.7] - 2024-12-17

### 🐛 Bug Fixes

- Null provider with just default bucket (#293)
## [operator-wandb-0.21.6] - 2024-12-17

### 🐛 Bug Fixes

- Fix all the references to the secret to use the template (#292)
## [operator-wandb-0.21.5] - 2024-12-17

### 🐛 Bug Fixes

- Redis password (#290)
- Fix liveness probe (#291)
## [operator-wandb-0.21.4] - 2024-12-16

### 🐛 Bug Fixes

- 0.21.3 release process failed, so triggering a new release (#289)
## [operator-wandb-0.21.3] - 2024-12-16

### 🐛 Bug Fixes

- Fix azure storage key syntax (#288)
## [operator-wandb-0.21.2] - 2024-12-16

### 🚀 Features

- Bufstream POC (#278)

### 🐛 Bug Fixes

- Missing bucket path (#287)
## [operator-wandb-0.21.0] - 2024-12-11

### 🚀 Features

- Shift around some values and actually enable user supplied bucket access secrets (#279)
## [operator-wandb-0.20.3] - 2024-12-11

### ⚙️ Miscellaneous Tasks

- Update Helm version and add newline linting (#281)
## [operator-wandb-0.20.2] - 2024-12-06

### 🚀 Features

- Bucket configuration changes. (#276)
## [operator-wandb-0.20.1] - 2024-12-05

### 🐛 Bug Fixes

- Chomp the newlines (#275)
## [operator-wandb-0.20.0] - 2024-12-04

### 🚀 Features

- Init glue (#260)
## [operator-wandb-0.19.3] - 2024-12-02

### 🐛 Bug Fixes

- Additional bigtable and pubsub fixes (#268)
## [operator-wandb-0.19.2] - 2024-11-25

### 🐛 Bug Fixes

- Reorganize the way values are passed (#266)
## [operator-wandb-0.19.1] - 2024-11-23

### 🚀 Features

- Chart for executor service (#264)
## [operator-wandb-0.19.0] - 2024-11-20

### 🚀 Features

- WIP - Chart for filestream service (#262)
## [operator-wandb-0.18.18] - 2024-11-15

### ⚙️ Miscellaneous Tasks

- Set GOMEMLIMIT in app, parquet (#261)
## [operator-wandb-0.18.17] - 2024-11-14

### 🐛 Bug Fixes

- Add support for more security context (#240)
## [operator-wandb-0.18.16] - 2024-11-14

### 🚀 Features

- Support secret keys configurable (#257)
## [operator-wandb-0.18.15] - 2024-11-14

### 🚀 Features

- Add support to pull CA Certs from configMap (#255)
## [operator-wandb-0.18.13] - 2024-10-31

### ⚙️ Miscellaneous Tasks

- *(artifacts)* Convert gc env vars to strings (#253)
## [operator-wandb-0.18.12] - 2024-10-31

### ⚙️ Miscellaneous Tasks

- *(artifacts)* Expose artifacts garbage-collection env vars (#248)
## [operator-wandb-0.18.11] - 2024-10-18

### ⚙️ Miscellaneous Tasks

- *(dev)* Enable kafka jmx metrics (#243)
## [operator-wandb-0.18.9] - 2024-10-15

### 🐛 Bug Fixes

- Weave traces AWS ELB Health Check (#241)
## [operator-wandb-0.18.8] - 2024-10-10

### 🚀 Features

- Support to pull MySQL credentials from secrets (#222)
## [operator-wandb-0.18.7] - 2024-10-08

### 🚀 Features

- Support reading redis password from a user supplied secret (#229)

### ⚙️ Miscellaneous Tasks

- *(dev)* Change the number of default kafka partitions to 12 (#235)
## [operator-wandb-0.18.6] - 2024-10-08

### 🚀 Features

- Allow operator-wandb to accept license as a secret key value pair (#231)
## [operator-wandb-0.18.5] - 2024-10-03

### ⚙️ Miscellaneous Tasks

- *(dev)* Kafka controller persistence (#233)
## [operator-wandb-0.18.4] - 2024-10-03

### ⚙️ Miscellaneous Tasks

- *(dev)* Update kafka storage (#228)
## [operator-wandb-0.18.3] - 2024-09-30

### 🚀 Features

- Allow operator-wandb to accept license as a secret key value pair (#218)
## [operator-wandb-0.18.2] - 2024-09-30

### 🚀 Features

- Support to pull bucket configurations from secrets (#224)
## [operator-wandb-0.18.1] - 2024-09-27

### 🚀 Features

- Disable permissions for node-level metrics and logs (#219)
## [operator-wandb-0.18.0] - 2024-09-23

### 🚀 Features

- Init HPA workaround (#221)
## [operator-wandb-0.17.9] - 2024-09-20

### 🐛 Bug Fixes

- Unrevert private WANDB_BASE_URL for weave (#220)
## [operator-wandb-0.17.8] - 2024-08-29

### ⚙️ Miscellaneous Tasks

- Default traceRatio to 0 in parquet and frfu (#210)
## [operator-wandb-0.17.7] - 2024-08-27

### ⚙️ Miscellaneous Tasks

- Respect traceRatio in parquet and frfu (#208)
## [operator-wandb-0.17.6] - 2024-08-27

### 🐛 Bug Fixes

- Parquet service pod selector is not specific enough (#207)
## [operator-wandb-0.17.5] - 2024-08-14

### 🐛 Bug Fixes

- Console Password Creation (#205)
## [operator-wandb-0.17.4] - 2024-08-12

### ⚙️ Miscellaneous Tasks

- Allow for parquet replicas (#204)
## [operator-wandb-0.17.3] - 2024-08-05

### 🐛 Bug Fixes

- Add crd read permissions to console (#202)
## [operator-wandb-0.17.2] - 2024-08-02

### 🐛 Bug Fixes

- Default value for path (#201)
## [operator-wandb-0.17.1] - 2024-08-02

### 🐛 Bug Fixes

- Correct assignment operator (#200)
## [operator-wandb-0.17.0] - 2024-08-02

### 🚀 Features

- Differentiate between bucket settings provided as default and set explicitly by the user for wandb managed installs (#199)
## [operator-wandb-0.16.2] - 2024-08-01

### 🐛 Bug Fixes

- Fix CACert value reference (#195)
## [operator-wandb-0.16.1] - 2024-07-31

### 🐛 Bug Fixes

- Make console fully functional in non-restricted environments (#191)
## [operator-wandb-0.16.0] - 2024-07-31

### 🚀 Features

- Allow the operator to support installation without cluster level permissions (#189)
## [operator-wandb-0.15.9] - 2024-07-25

### 🐛 Bug Fixes

- Clean up DD_* env vars in weave-trace deployment (#188)
## [operator-wandb-0.15.8] - 2024-07-24

### ⚙️ Miscellaneous Tasks

- *(dev)* Increase default kafka partitions for frfu (#186)
## [operator-wandb-0.15.7] - 2024-07-24

### 🐛 Bug Fixes

- Revert private WANDB_BASE_URL for weave (#185)
## [operator-wandb-0.15.6] - 2024-07-23

### 🐛 Bug Fixes

- Add cert bundle (#179)
## [operator-wandb-0.15.5] - 2024-07-23

### 🐛 Bug Fixes

- Correct syntax for yace search tags (#184)
## [operator-wandb-0.15.4] - 2024-07-23

### 🐛 Bug Fixes

- Add search tags to YACE resources to scope metrics to customer (#183)
## [operator-wandb-0.15.3] - 2024-07-22

### 🐛 Bug Fixes

- Add an SA for weave-trace deployment (#182)
## [operator-wandb-0.15.2] - 2024-07-19

### 🐛 Bug Fixes

- Add an SA for parquet-backfill job (#180)

### ⚙️ Miscellaneous Tasks

- *(weave)* Revert weave cache import update (#181)
## [operator-wandb-0.15.1] - 2024-07-19

### 🚀 Features

- *(weave)* Add weave-trace (#157)
## [operator-wandb-0.15.0] - 2024-07-18

### 🐛 Bug Fixes

- Normalize the service account create logic for all wandb applications (#178)
## [operator-wandb-0.14.17] - 2024-07-18

### 🚀 Features

- *(backend)* Enable subpath in GCP (#173)
## [operator-wandb-0.14.16] - 2024-07-17

### ⚙️ Miscellaneous Tasks

- *(weave)* Fix weave cache import (#159)
## [operator-wandb-0.14.15] - 2024-07-17

### 🐛 Bug Fixes

- HPA could not scale weave  (#177)
## [operator-wandb-0.14.14] - 2024-07-17

### ⚙️ Miscellaneous Tasks

- *(dev)* Add AWS_REGION to frfu deployment (#176)
## [operator-wandb-0.14.13] - 2024-07-16

### ⚙️ Miscellaneous Tasks

- *(dev)* Run updates shadow partitions (#175)
## [operator-wandb-0.14.12] - 2024-07-16

### 🐛 Bug Fixes

- Added missing mysql port variable to init container (#146)
## [operator-wandb-0.14.11] - 2024-07-12

### ⚙️ Miscellaneous Tasks

- *(dev)* Kafka consumer terminationGracePeriodSeconds (#171)
## [operator-wandb-0.14.10] - 2024-07-11

### ⚙️ Miscellaneous Tasks

- *(dev)* Make frfu value a string (#169)
## [operator-wandb-0.14.9] - 2024-07-11

### 🐛 Bug Fixes

- Add hc annotation to the console service in AWS clusters (#163)
## [operator-wandb-0.14.8] - 2024-07-10

### ⚙️ Miscellaneous Tasks

- *(dev)* Fix frfu num partitions (#168)
## [operator-wandb-0.14.7] - 2024-07-10

### ⚙️ Miscellaneous Tasks

- *(dev)* Make kafka partitions configurable (#164)
## [operator-wandb-0.14.6] - 2024-07-10

### ⚙️ Miscellaneous Tasks

- *(dev)* Fix flat run fields updater redis volume (#167)
## [operator-wandb-0.14.5] - 2024-07-10

### ⚙️ Miscellaneous Tasks

- *(dev)* Redis certificate for flat run fields updater (#165)
## [operator-wandb-0.14.4] - 2024-07-02

### ⚙️ Miscellaneous Tasks

- *(weave)* Add weave public url (#161)
## [operator-wandb-0.14.3] - 2024-07-02

### 🐛 Bug Fixes

- Mount redis cert to parquet cron job (#158)
## [operator-wandb-0.14.2] - 2024-07-02

### 🐛 Bug Fixes

- Default metrics moniotors to false (#152)
## [operator-wandb-0.14.1] - 2024-06-24

### 🚀 Features

- Added yace support for aws rds and redis metrics (#140)
## [operator-wandb-0.13.13] - 2024-06-20

### 🐛 Bug Fixes

- Pass all oidc vars (#150)
## [operator-wandb-0.13.12] - 2024-06-18

### ⚙️ Miscellaneous Tasks

- Default mysql to false (#149)
## [operator-wandb-0.13.11] - 2024-06-17

### 🐛 Bug Fixes

- Remove empty attributes (#143)
## [operator-wandb-0.13.10] - 2024-06-05

### 🚀 Features

- Added stackdriver support for gcp metrics (#141)
## [operator-wandb-0.13.9] - 2024-06-05

### 🐛 Bug Fixes

- Do not install nginx by default (#144)
## [operator-wandb-0.13.8] - 2024-06-05

### 🚀 Features

- Added nginx support (#128)
## [operator-wandb-0.13.7] - 2024-05-28

### ◀️ Revert

- Fix: mount redis CA (#138)
## [operator-wandb-0.13.6] - 2024-05-28

### 🐛 Bug Fixes

- Use relative path for redis volume (#137)
## [operator-wandb-0.13.5] - 2024-05-28

### 🐛 Bug Fixes

- Mount Redis CA Cert (#136)
## [operator-wandb-0.13.4] - 2024-05-22

### ◀️ Revert

- Fix: mount redis ca cert to backfiller (#133)
## [operator-wandb-0.13.3] - 2024-05-22

### 🐛 Bug Fixes

- Check if secondary is nil (#134)
## [operator-wandb-0.13.2] - 2024-05-22

### 🚀 Features

- Option to create cert for gce (#132)
## [operator-wandb-0.13.1] - 2024-05-22

### 🐛 Bug Fixes

- Add empty field for attributes (#130)
## [operator-wandb-0.13.0] - 2024-05-17

### 🚀 Features

- Added internal ingress  (#102)
## [operator-wandb-0.12.11] - 2024-05-09

### 🐛 Bug Fixes

- Mount redis ca cert to backfiller (#122)
## [operator-wandb-0.12.8] - 2024-04-16

### ⚙️ Miscellaneous Tasks

- *(weave)* Use app fullname for weave auth (#115)
## [operator-wandb-0.12.7] - 2024-04-16

### 🚀 Features

- Allow ingress to be disabled for customers using Istio  (#114)
## [operator-wandb-0.12.6] - 2024-04-12

### 🐛 Bug Fixes

- Banner templating (#112)
## [operator-wandb-0.12.4] - 2024-04-04

### ⚙️ Miscellaneous Tasks

- *(backend)* Clean up runs v2 env variables (#107)
## [operator-wandb-0.12.3] - 2024-04-03

### 🚀 Features

- *(backend)* Add flat runs field updater (#91)
## [operator-wandb-0.12.2] - 2024-04-03

### 🐛 Bug Fixes

- Allow ALB time to register new pod ip for the wandb app and console pod (#76)
## [operator-wandb-0.12.1] - 2024-04-03

### ⚙️ Miscellaneous Tasks

- Update health checks (#106)
## [operator-wandb-0.12.0] - 2024-04-03

### ⚙️ Miscellaneous Tasks

- Console v2 (#105)
## [operator-wandb-0.11.5] - 2024-03-28

### ⚙️ Miscellaneous Tasks

- Email server (#100)
## [operator-wandb-0.11.3] - 2024-03-20

### ⚙️ Miscellaneous Tasks

- Readiness and liveness probes for parquet (#95)
## [operator-wandb-0.10.46] - 2024-03-06

### ⚙️ Miscellaneous Tasks

- Add nameOverride to ingress (#87)
## [operator-wandb-0.10.45] - 2024-03-01

### ⚙️ Miscellaneous Tasks

- Dont create managed cert in charts for google (#85)
## [operator-wandb-0.10.44] - 2024-02-29

### 📚 Documentation

- *(operator-wand)* Add a local-development.md (#79)

### ⚙️ Miscellaneous Tasks

- *(weave)* Change pvc to empty dir, add a sidecar container to run cache clearing (#81)
## [operator-wandb-0.10.43] - 2024-02-01

### 🚀 Features

- Set G_HOST_IP to allow GORILLA_STATSD_HOST to point to it (#71)
## [operator-wandb-0.10.42] - 2024-01-30

### 🐛 Bug Fixes

- Checksum (#70)
## [operator-wandb-0.10.41] - 2024-01-29

### 🚀 Features

- ExportHistoryToParquet Cron Job (#56)
## [operator-wandb-0.10.40] - 2024-01-29

### 🚀 Features

- Support for setting additional hosts on the ingress (#68)
## [operator-wandb-0.10.39] - 2024-01-29

### 🐛 Bug Fixes

- Checksum for License to force pod restart (#66)
## [operator-wandb-0.10.38] - 2024-01-27

### ◀️ Revert

- Additional hosts
## [operator-wandb-0.10.33] - 2024-01-10

### 🐛 Bug Fixes

- Auth conflict (#58)
## [operator-wandb-0.10.32] - 2024-01-09

### 🐛 Bug Fixes

- Slack quote bug fix (#57)
## [operator-wandb-0.10.31] - 2023-12-18

### 🚀 Features

- EFS compatibility Storage Class for AWS (#55)
## [operator-wandb-0.10.29] - 2023-12-13

### ⚙️ Miscellaneous Tasks

- Remove statd host port if otel is not enabled (#53)
## [operator-wandb-0.10.28] - 2023-12-12

### ⚙️ Miscellaneous Tasks

- 8125 is a port on observability service, not the source service (#50)
## [operator-wandb-0.10.26] - 2023-11-17

### ⚙️ Miscellaneous Tasks

- *(operator)* Stop the HPA for now (#44)
## [operator-wandb-0.10.14] - 2023-10-06

### 🐛 Bug Fixes

- Add app permissions to create secrets (#35)
## [operator-wandb-0.10.13] - 2023-09-29

### 🐛 Bug Fixes

- Access keys not working in s3
## [operator-wandb-0.10.10] - 2023-09-23

### 🐛 Bug Fixes

- OIDC variables not getting set correctly
## [operator-wandb-0.7.4] - 2023-09-01

### 🐛 Bug Fixes

- Proper OIDC config
## [operator-wandb-0.4.0] - 2023-08-29

### 🚀 Features

- Add cert options to ingress
## [operator-wandb-0.3.4] - 2023-08-28

### 🐛 Bug Fixes

- Deployment cach
## [operator-wandb-0.3.2] - 2023-08-28

### 🐛 Bug Fixes

- Mysql presistant volume
## [operator-wandb-0.1.9] - 2023-08-24

### 🐛 Bug Fixes

- Console permission not assign correctly
## [operator-wandb-0.1.8] - 2023-08-24

### 🐛 Bug Fixes

- Service account naming
## [operator-wandb-0.1.7] - 2023-08-24

### 🐛 Bug Fixes

- Add service account to console deployment
## [operator-wandb-0.1.6] - 2023-08-23

### 🐛 Bug Fixes

- Using correct console port
## [operator-wandb-0.1.2] - 2023-08-21

### ⚙️ Miscellaneous Tasks

- Add redis and parquet
## [operator-wandb-0.1.0] - 2023-08-18
