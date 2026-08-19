# OpenClaw Home Manager Service

This module manages OpenClaw as a per-user gateway runtime service: it installs
the OpenClaw package, manages the live OpenClaw JSON settings file, and keeps
`openclaw gateway run` running as a user service.

## Runtime Service

- `services.openclaw.enable` installs OpenClaw and enables the module.
- `services.openclaw.package` selects the OpenClaw package to install.
- The module creates a user service for `openclaw gateway run`: systemd on
  Linux and launchd on macOS.
- `services.openclaw.gateway.port` passes `--port` to the gateway command.
- `services.openclaw.gateway.tailscale` passes `--tailscale on` or
  `--tailscale off` to the gateway command.

## Settings

- `services.openclaw.settings` contains Nix-declared OpenClaw JSON settings.
- When `settings` is empty, Home Manager does not manage OpenClaw's live config
  file.
- When `settings` is non-empty, Home Manager writes
  `~/.openclaw/openclaw.json` during activation.

## Mutable Settings

- `services.openclaw.mutableSettings = true` is the default.
- In mutable mode, Home Manager merges declared settings into the live OpenClaw
  config file and preserves unknown keys written by OpenClaw or plugins at
  runtime.
- This mode is useful when OpenClaw owns some runtime state and Home Manager
  owns only the declared subset.

## Authoritative Settings

- Set `services.openclaw.mutableSettings = false` when the declared settings
  should be authoritative.
- In authoritative mode, Home Manager replaces the live config file with the
  declared settings during activation.
- This avoids symlinking the OpenClaw config file while still supporting an
  immutable-style workflow.

## Acknowledgements

The `mutableSettings` option is inspired by the Zed Home Manager module's
mutable settings options, which let users choose whether Home Manager should
coexist with application-managed settings or fully own the generated settings
file.
