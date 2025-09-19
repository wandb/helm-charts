# Changelog

All notable changes to the operator-wandb chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.35.1] - 2025-09-19

### Fixed
- **Inherited Critical Fix**: Fixed container image template logic for all wandb-base dependencies
  - All W&B services (app, api, console, weave, parquet, executor, etc.) now properly handle empty image digest/tag values
  - Prevents Kubernetes deployment failures due to missing image specification
  - Maintains proper image precedence: digest > tag > latest fallback

### Enhanced
- **Image Digest Support**: All wandb-base dependent services now support secure digest-based image references
  - Services can now use immutable image digests for enhanced security
  - Full backward compatibility maintained

### Technical Details
- Inherits improvements from wandb-base v0.11.1 via chart dependencies
- All components using `wandb-base` now benefit from the fixed image template logic
- No configuration changes required - existing deployments continue to work
- Components affected: app, api, console, weave, weave-trace, weave-trace-worker, executor, parquet, filestream, filemeta, glue, anaconda2, frontend, flat-run-fields-updater, metric-observer, settingsMigrationJob
