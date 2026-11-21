{ config, ... }:
{
  time = "2026-11-09T18:00:00+00:00";
  condition = config.programs.cline.enable;
  message = ''
    A new module is available: `programs.cline`.

    The module provides declarative configuration for Cline coding agent CLI,
    and integration with the existing `programs.mcp` settings.
  '';
}
