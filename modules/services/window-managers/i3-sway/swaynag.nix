{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.wayland.windowManager.sway.swaynag;

  iniFormat = pkgs.formats.ini { };

  confFormat =
    with lib.types;
    let
      confAtom =
        nullOr (oneOf [
          bool
          int
          float
          str
        ])
        // {
          description = "Swaynag config atom (null, bool, int, float, str)";
        };
    in
    attrsOf confAtom;
in
{
  meta.maintainers = [ ];

  options = {
    wayland.windowManager.sway.swaynag = {
      enable = lib.mkEnableOption "configuration of swaynag, a lightweight error bar for sway";

      settings = lib.mkOption {
        type = lib.types.attrsOf confFormat;
        default = { };
        description = ''
          Configuration written to
          {file}`$XDG_CONFIG_HOME/swaynag/config`.

          See
          {manpage}`swaynag(5)`
          for a list of available options and an example configuration.
          Note, configurations declared under `<config>`
          will override the default type values of swaynag.
        '';
        example = lib.literalExpression ''
          {
            "<config>" = {
              edge = "bottom";
              font = "Dina 12";
            };

            green = {
              edge = "top";
              background = "00AA00";
              text = "FFFFFF";
              button-background = "00CC00";
              message-padding = 10;
            };
          }
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "wayland.windowManager.sway.swaynag" pkgs lib.platforms.linux)
    ];

    xdg.configFile."swaynag/config" = lib.mkIf (cfg.settings != { }) {
      source = iniFormat.generate "swaynag.conf" cfg.settings;
    };
  };
}
