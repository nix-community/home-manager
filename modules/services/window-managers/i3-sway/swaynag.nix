{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.wayland.windowManager.sway.swaynag;

  iniFormat = pkgs.formats.ini { };

  confFormat = with types;
    let
      confAtom = nullOr (oneOf [ bool int float str ]) // {
        description = "Swaynag config atom (null, bool, int, float, str)";
      };
    in attrsOf confAtom;
in {
  meta.maintainers = with maintainers; [ polykernel ];

  options = {
    wayland.windowManager.sway.swaynag = {
      enable = mkEnableOption
        "configuration of swaynag, a lightweight error bar for sway";

      settings = mkOption {
        type = types.attrsOf confFormat;
        default = { };
        description = ''
          Configuration written to
          <filename>$XDG_CONFIG_HOME/swaynag/config</filename>.
          </para><para>
          See
          <citerefentry>
            <refentrytitle>swaynag</refentrytitle>
            <manvolnum>5</manvolnum>
          </citerefentry>
          for a list of avaliable options and an example configuration.
          Note, configurations declared under <literal>&lt;config&gt;</literal>
          will override the default type values of swaynag.
        '';
        example = literalExpression ''
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

  config = mkIf cfg.enable {
    assertions = [
      (hm.assertions.assertPlatform "wayland.windowManager.sway.swaynag" pkgs
        platforms.linux)
    ];

    xdg.configFile."swaynag/config" = mkIf (cfg.settings != { }) {
      source = iniFormat.generate "swaynag.conf" cfg.settings;
    };
  };
}
