{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    getExe
    literalExpression
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    types
    ;

  cfg = config.services.wayvnc;

  format = pkgs.formats.keyValue { };
in
{
  meta.maintainers = with lib.maintainers; [ Scrumplex ];

  options.services.wayvnc = {
    enable = mkEnableOption "wayvnc VNC server";

    package = mkPackageOption pkgs "wayvnc" { };

    autoStart = mkEnableOption "autostarting of wayvnc";

    systemdTarget = mkOption {
      type = types.str;
      default = config.wayland.systemd.target;
      defaultText = literalExpression "config.wayland.systemd.target";
      description = ''
        Systemd target to bind to.
      '';
    };

    settings = mkOption {
      type = types.submodule {
        freeformType = format.type;

        options = {
          address = mkOption {
            description = ''
              The address to which the server shall bind, e.g. 0.0.0.0 or
              localhost.
            '';
            type = types.str;
            example = "0.0.0.0";
          };
          port = mkOption {
            description = ''
              The port to which the server shall bind.
            '';
            type = types.port;
            example = 5901;
          };
        };
      };
      description = ''
        See CONFIGURATION section in {manpage}`wayvnc(1)`.
      '';
      default = { };
      example = {
        address = "0.0.0.0";
        port = 5901;
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.wayvnc" pkgs lib.platforms.linux)
    ];

    systemd.user.services."wayvnc" = {
      Unit = {
        Description = "wayvnc VNC server";
        Documentation = [ "man:wayvnc(1)" ];
        After = [ cfg.systemdTarget ];
        PartOf = [ cfg.systemdTarget ];
      };
      Service.ExecStart = [ (getExe cfg.package) ];
      Install.WantedBy = lib.mkIf cfg.autoStart [ cfg.systemdTarget ];
    };

    # For manpage and wayvncctl
    home.packages = [ cfg.package ];

    xdg.configFile."wayvnc/config".source = format.generate "wayvnc.conf" cfg.settings;
  };
}
