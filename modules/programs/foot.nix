{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.foot;
  iniFormat = pkgs.formats.ini { };

in {
  meta.maintainers = with lib.maintainers; [ plabadens ];

  options.programs.foot = {
    enable = mkEnableOption "Foot terminal";

    package = mkOption {
      type = types.package;
      default = pkgs.foot;
      defaultText = literalExpression "pkgs.foot";
      description = "The foot package to install";
    };

    server.enable = mkEnableOption "Foot terminal server";

    settings = mkOption {
      type = iniFormat.type;
      default = { };
      description = ''
        Configuration written to
        <filename>$XDG_CONFIG_HOME/foot/foot.ini</filename>. See <link
        xlink:href="https://codeberg.org/dnkl/foot/src/branch/master/foot.ini"/>
        for a list of available options.
      '';
      example = literalExpression ''
        {
          main = {
            term = "xterm-256color";

            font = "Fira Code:size=11";
            dpi-aware = "yes";
          };

          mouse = {
            hide-when-typing = "yes";
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions =
      [ (hm.assertions.assertPlatform "programs.foot" pkgs platforms.linux) ];

    home.packages = [ cfg.package ];

    xdg.configFile."foot/foot.ini" = mkIf (cfg.settings != { }) {
      source = iniFormat.generate "foot.ini" cfg.settings;
    };

    systemd.user.services = mkIf cfg.server.enable {
      foot = {
        Unit = {
          Description =
            "Fast, lightweight and minimalistic Wayland terminal emulator.";
          Documentation = "man:foot(1)";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart = "${cfg.package}/bin/foot --server";
          Restart = "on-failure";
        };

        Install = { WantedBy = [ "graphical-session.target" ]; };
      };
    };
  };
}
