# Changelog

All notable changes to the operator chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4.4] - 2024-09-19

### Changed
- No direct changes to operator chart code
- Updated for consistency with wandb-base digest feature enhancement

### Technical Details
- The operator chart already had correct image template logic with proper fallback to `:latest`
- Image configuration precedence: digest > tag > latest fallback was already implemented correctly
- This version bump ensures compatibility and alignment with wandb-base v0.11.1 improvements
