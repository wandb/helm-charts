# Changelog

All notable changes to the wandb-base chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.11.1] - 2024-09-19

### Fixed
- **CRITICAL**: Fixed container image template logic to prevent missing image field when both `tag` and `digest` are empty
  - Added fallback case `image: "{{ .image.repository }}:latest"` when both `digest` and `tag` are empty
  - Prevents Kubernetes deployment failures due to missing image specification
  - Maintains proper precedence: digest > tag > latest fallback

### Added
- Enhanced image configuration documentation with digest support examples
- Added comprehensive examples showing digest, tag, and fallback scenarios

### Technical Details
- Updated `templates/_containers.tpl` in `wandb-base.container` template
- Image logic now properly handles all combinations of digest/tag values
- No breaking changes - fully backward compatible
