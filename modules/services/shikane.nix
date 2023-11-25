{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.shikane;
  tomlFormat = pkgs.formats.toml { };
in {
  meta.maintainers = [ maintainers.therealr5 ];
  options.services.shikane = {

    enable = mkEnableOption
      "shikane, A dynamic output configuration tool that automatically detects and configures connected outputs based on a set of profiles.";

    package = mkPackageOption pkgs "shikane" { };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      example = literalExpression ''
        {
          profile = [
            {
              name = "external-monitor-default";
              output = [
                {
                  match = "eDP-1";
                  enable = true;
                }
                {
                  match = "HDMI-A-1";
                  enable = true;
                  position = {
                    x = 1920;
                    y = 0;
                  };
                }
              ];
            }
            {
              name = "builtin-monitor-only";
              output = [
                {
                  match = "eDP-1";
                  enable = true;
                }
              ];
            }
          ];
        }
      '';
      description = ''
        Configuration written to
        <filename>$XDG_CONFIG_HOME/shikane/config.toml</filename>.
        </para><para>
        See <link xlink:href="https://gitlab.com/w0lff/shikane/-/blob/master/docs/shikane.5.man.md" />
        for more information.
      '';
    };
  };

  config = mkIf cfg.enable {
    xdg.configFile."shikane/config.toml".source =
      tomlFormat.generate "shikane-config" cfg.settings;

    systemd.user.services.shikane = {
      Unit = {
        Description = "Dynamic output configuration tool";
        Documentation = "man:shikane(1)";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = { ExecStart = "${cfg.package}/bin/shikane"; };

      Install = { WantedBy = [ "graphical-session.target" ]; };
    };
  };
}
