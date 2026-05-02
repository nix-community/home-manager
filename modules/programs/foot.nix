{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.foot;
  iniFormat = pkgs.formats.ini { listsAsDuplicateKeys = true; };
in
{
  meta.maintainers = with lib.maintainers; [ plabadens ];

  options.programs.foot = {
    enable = lib.mkEnableOption "Foot terminal";

    package = lib.mkPackageOption pkgs "foot" { };

    server = {
      enable = lib.mkEnableOption "Foot terminal server";

      systemdTarget = lib.mkOption {
        type = lib.types.str;
        default = config.wayland.systemd.target;
        defaultText = lib.literalExpression "config.wayland.systemd.target";
        example = "sway-session.target";
        description = ''
          The systemd target that will automatically start the Foot server service.

          When setting this value to `"sway-session.target"`,
          make sure to also enable {option}`wayland.windowManager.sway.systemd.enable`,
          otherwise the service may never be started.
        '';
      };
    };

    settings = lib.mkOption {
      inherit (iniFormat) type;
      default = { };
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/foot/foot.ini`. See <https://codeberg.org/dnkl/foot/src/branch/master/foot.ini>
        for a list of available options.
      '';
      example = lib.literalExpression ''
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

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.foot" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile."foot/foot.ini" = lib.mkIf (cfg.settings != { }) {
      source = iniFormat.generate "foot.ini" cfg.settings;
    };

    systemd.user.services = lib.mkIf cfg.server.enable {
      foot = {
        Unit = {
          Description = "Fast, lightweight and minimalistic Wayland terminal emulator.";
          Documentation = "man:foot(1)";
          PartOf = [ cfg.server.systemdTarget ];
          After = [ cfg.server.systemdTarget ];
          ConditionEnvironment = "WAYLAND_DISPLAY";
        };

        Service = {
          ExecStart = "${cfg.package}/bin/foot --server";
          Restart = "on-failure";
          OOMPolicy = "continue";
        };

        Install = {
          WantedBy = [ cfg.server.systemdTarget ];
        };
      };
    };
  };
}
