{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;

  cfg = config.services.clipmenu;
in
{
  meta.maintainers = [ lib.maintainers.DamienCassou ];

  imports = [
    (lib.mkRenamedOptionModule
      [ "services" "clipmenu" "launcher" ]
      [ "services" "clipmenu" "environmentVariables" "CM_LAUNCHER" ]
    )
  ];

  options.services.clipmenu = {
    enable = lib.mkEnableOption "clipmenu, the clipboard management daemon";

    package = lib.mkPackageOption pkgs "clipmenu" { };

    environmentVariables = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = "{ CM_LAUNCHER = \"rofi\"; }";
      description = ''
        Environment variables to pass to the clipmenu daemon.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.clipmenu" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user.services.clipmenu = {
      Unit = {
        Description = "Clipboard management daemon";
        After = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${cfg.package}/bin/clipmenud";
        Environment = [
          "PATH=${
            lib.makeBinPath (
              with pkgs;
              [
                coreutils
                findutils
                gnugrep
                gnused
                systemd
              ]
            )
          }"
        ]
        ++ (lib.mapAttrsToList (name: value: "${name}=${value}") cfg.environmentVariables);
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
