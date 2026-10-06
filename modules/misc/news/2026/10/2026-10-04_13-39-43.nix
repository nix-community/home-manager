{ config, ... }:
{
  time = "2026-10-04T18:39:43+00:00";
  condition = config.programs.cudatext.enable;
  message = ''
    The CudaText module now supports mutable configuration through
    'programs.cudatext.mutableSettings'.

    When enabled, Home Manager merges declared user settings, hotkeys and
    lexer settings into writable files during activation. Declared values
    take precedence, while other settings are preserved. Removing a
    declaration does not remove its saved value. Comments and formatting are
    not preserved. This option defaults to false, so configuration remains
    read-only unless you opt in.
  '';
}
