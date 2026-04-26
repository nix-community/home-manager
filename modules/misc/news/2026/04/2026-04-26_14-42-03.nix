{ config, lib, ... }:
{
  time = "2026-04-26T12:42:03+00:00";
  condition =
    let
      extraConfigFiles = lib.removeAttrs config.fonts.fontconfig.configFile [
        "fonts"
        "rendering"
        "default-fonts"
      ];
    in
    config.fonts.fontconfig.enable && extraConfigFiles != { };
  message = ''
    There is a new `fonts.fontconfig.configFile.<name>.settings` option to
    define Fontconfig configuration files via a structured attrs in the
    format of `pkgs.formats.xml {}`.
  '';
}
