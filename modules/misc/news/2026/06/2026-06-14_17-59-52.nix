{ config, ... }:
{
  time = "2026-06-14T17:59:52+00:00";
  condition = config.services.wayle.enable;
  message = ''
    A new option is available: `services.wayle.themes`.

    This option allows you to define custom themes that will be written to
    `$XDG_CONFIG_HOME/wayle/themes/''${name}.toml`. Each theme accepts either
    inline TOML content or a path to a theme file.
  '';
}
