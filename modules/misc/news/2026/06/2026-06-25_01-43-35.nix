{ config, ... }:
{
  time = "2026-06-25T01:43:35+00:00";
  condition = config.programs.codex.enable;
  message = ''
    The `programs.codex.contextOverride` option was added to manage Codex
    override context under `CODEX_HOME`.
  '';
}
