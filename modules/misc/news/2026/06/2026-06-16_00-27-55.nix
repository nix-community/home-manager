{ config, ... }:
{
  time = "2026-06-16T00:27:55+00:00";
  condition = config.programs.television.enable;
  message = ''
    A new option is available: `programs.television.themes`.

    This option allows you to define custom themes that will be written to
    `$XDG_CONFIG_HOME/television/themes/''${name}.toml`. Each theme accepts
    either inline TOML content or a path to a theme file.
  '';
}
