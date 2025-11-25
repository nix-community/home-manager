# Codex {#opt-programs.codex}

The Codex module configures the terminal AI assistant and writes its settings to
`config.toml`. Only Codex >= 0.2.0 is supported.

## Enabling

```nix
programs.codex.enable = true;
```

When `home.preferXdgDirectories = true;`, files are placed in
`~/.config/codex/`; otherwise in `~/.codex/`. The variable `CODEX_HOME` is set
automatically in the XDG case.

## Basic settings

```nix
programs.codex.settings = {
  model = "gpt-5.1";
  model_provider = "openai";
  model_reasoning_effort = "medium";
  approval_policy = "on-request";
  sandbox_mode = "workspace-write";
};
```

All keys map directly to `config.toml`; see the upstream reference at
<https://github.com/openai/codex/blob/main/codex-rs/config.md> for the full list
of options.

## Custom instructions

Provide repo- or user-specific guidance via an AGENTS file:

```nix
programs.codex.custom-instructions = ''
  - Run `nix flake check` before suggesting commands
  - Avoid network access unless requested
'';
```

This is written to `AGENTS.md` in the same directory as `config.toml`.

## Version guard

Set `programs.codex.package` to a 0.2.0+ build if you override the package. The
module asserts the version to avoid accidental YAML-era configurations.
