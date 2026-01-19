# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-01-19

### Added

- Configurable sign-up disable option via `enable_sign_up` setting
- Sign-up link automatically hidden when registration is disabled

## [0.1.0] - 2025-01-18

### Added

- Initial release of BetterAuthy authentication engine
- Multi-scope support for multiple authenticatable models (users, accounts, admins)
- Scope-based configuration system
- Session-based authentication with encrypted cookies
- Remember me functionality with configurable duration
- Password reset flow with secure tokens
- Sign-in tracking (count, timestamps, IPs)
- Dynamic route generation per scope
- Controller helpers: `current_{scope}`, `{scope}_signed_in?`, `sign_in_{scope}`, `sign_out_{scope}`, `authenticate_{scope}!`
- `better_authy_authenticable` model macro
- Vite asset support
- BetterUI integration for views

### Fixed

- Corrected gem version in documentation
