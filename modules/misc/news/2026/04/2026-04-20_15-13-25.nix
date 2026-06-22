{ config, ... }:
{
  time = "2026-04-20T20:13:25+00:00";
  condition = config.programs.git.enable;
  message = ''
    The 'programs.git.settings' option now supports ordered configuration
    fragments in addition to the existing attrset shorthand.

    This allows repeated or order-sensitive Git config sections, such as
    multiple 'credential' blocks, to be expressed directly in Nix while keeping
    the simple attrset form for normal Git settings.
  '';
}
