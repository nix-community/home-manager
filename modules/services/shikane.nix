{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.shikane;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = [ lib.maintainers.therealr5 ];

  options.services.shikane = {

    enable = lib.mkEnableOption "shikane, A dynamic output configuration tool that automatically detects and configures connected outputs based on a set of profiles.";

    package = lib.mkPackageOption pkgs "shikane" { };

    settings = lib.mkOption {
      type = tomlFormat.type;
      default = { };
      example = lib.literalExpression ''
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

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.shikane" pkgs lib.platforms.linux)
    ];

    xdg.configFile."shikane/config.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "shikane-config" cfg.settings;
    };

    systemd.user.services.shikane = {
      Unit = {
        Description = "Dynamic output configuration tool";
        Documentation = "man:shikane(1)";
        After = [ config.wayland.systemd.target ];
        PartOf = [ config.wayland.systemd.target ];
      };

      Service = {
        ExecStart = lib.getExe cfg.package;
      };

      Install = {
        WantedBy = [ config.wayland.systemd.target ];
      };
    };
  };
}
