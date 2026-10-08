{ config, ... }:
{
  time = "2026-06-08T12:00:00+00:00";
  condition = config.programs.codex.enable;
  message = ''
    The `programs.codex.profiles` option was added to manage Codex CLI
    profile files under `CODEX_HOME`.

    These files are selected with `codex --profile <name>`, matching the
    profile behavior used by Codex 0.134.0 and later.
  '';
}
