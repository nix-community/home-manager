_: {
  time = "2026-04-19T12:05:24+00:00";
  # condition = pkgs.stdenv.hostPlatform.isLinux;
  # condition = config.programs.neovim.enable;
  condition = true;
  # if behavior changed, explain how to restore previous behavior.
  message = ''
    The {option}`programs.mcp.servers.<name>.envFiles` option has been added to {option}`programs.mcp`.
    It maps environment variable names to secret file paths (e.g. sops-nix, systemd credentials).

    In {file}`mcp.json` each entry is resolved to a {file}`{file:…}`-substitution in {option}`env`.
    Clients that do not support this syntax (e.g. claude-code, codex) receive a generated wrapper script that reads the secret at startup instead.
  '';
}
