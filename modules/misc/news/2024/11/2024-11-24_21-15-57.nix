{ config, ... }:
{
  time = "2024-11-24T20:15:57+00:00";
  condition = config.programs.zed-editor.enable;
  message = ''
    The 'programs.zed-editor' module now supports the 'extraPackages' option.

    This option allows making language servers and other tools available to
    Zed without adding them to 'home.packages', providing cleaner package
    management for editor-specific dependencies.
  '';
}
