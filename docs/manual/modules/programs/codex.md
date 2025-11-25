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

## Example full configuration

```nix
programs.codex = {
  enable = true;
  package = pkgs.codex; # ensures >= 0.2.0
  settings = {
    model = "gpt-5.1";
    model_provider = "openai";
    model_reasoning_effort = "medium";
    model_reasoning_summary = "auto";
    approval_policy = "on-request";
    sandbox_mode = "workspace-write";
    sandbox_workspace_write = {
      network_access = false;
      writable_roots = [ "${config.home.homeDirectory}/.cache" ];
    };
    features = {
      web_search_request = false;
      apply_patch_freeform = true;
      view_image_tool = true;
      unified_exec = true;
    };
    tools.view_image = true;
    shell_environment_policy = {
      inherit = "core";
      set = { CI = "1"; };
      exclude = [ "AWS_*" "GCP_*" ];
    };
    mcp_servers = {
      ripgrep = {
        command = "rg";
        args = [ "--json" ];
        enabled = true;
        tool_timeout_sec = 30;
      };
      github = {
        url = "https://github-mcp.example.com/mcp";
        bearer_token_env_var = "GITHUB_TOKEN";
        enabled_tools = [ "issues" "pulls" ];
      };
    };
    otel.exporter = "none";
  };
  custom-instructions = ''
    - Run `nix flake check` before suggesting commands
    - Avoid network access unless explicitly requested
  '';
};
```
