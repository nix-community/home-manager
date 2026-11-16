{ config, ... }:
{
  time = "2026-10-21T06:43:34+00:00";
  condition = config.programs.fresh-editor.enable;
  message = ''
    Fresh now supports `programs.fresh-editor.mutableSettings` to load
    declarative settings from `config_linux.json` or `config_macos.json`,
    leaving `config.json` writable by Fresh. Declarative settings override
    the same keys in the user file. The option is disabled by default.
  '';
}
