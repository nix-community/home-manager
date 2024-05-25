{ config, lib, pkgs, ... }:

let

  inherit (lib) mkIf mkMerge mkEnableOption mkPackageOption mkOption;

  cfg = config.services.remmina;

in {
  meta.maintainers = with lib.maintainers; [ cyntheticfox ];

  options.services.remmina = {
    enable = mkEnableOption "Remmina";

    package = mkPackageOption pkgs "remmina" { };

    addRdpMimeTypeAssoc = mkEnableOption "Remmina RDP file open option" // {
      default = true;
    };

    systemdService = {
      enable = mkEnableOption "systemd Remmina service" // { default = true; };

      startupFlags = mkOption {
        type = with lib.types; listOf str;
        default = [ "--icon" ];
        description = ''
          Startup flags documented in the manpage to run at service startup.
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    { home.packages = [ cfg.package ]; }

    (mkIf cfg.systemdService.enable {
      systemd.user.services.remmina = {
        Unit = {
          Description = "Remmina remote desktop client";
          Documentation = "man:remmina(1)";
          Requires = [ "graphical-session-pre.target" ];
        };

        Service = {
          Type = "simple";
          ExecStart = "${lib.getExe cfg.package} ${
              lib.escapeShellArgs cfg.systemdService.startupFlags
            }";
          Restart = "on-failure";
        };

        Install.WantedBy = [ "graphical-session.target" ];
      };
    })

    (mkIf (config.xdg.mimeApps.enable && cfg.addRdpMimeTypeAssoc) {
      xdg.mimeApps.associations.added."application/x-rdp" =
        "org.remmina.Remmina.desktop";

      xdg.dataFile."mime/packages/application-x-rdp.xml".text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
          <mime-type type="application/x-rdp">
            <comment>rdp file</comment>
            <icon name="application-x-rdp"/>
            <glob-deleteall/>
            <glob pattern="*.rdp"/>
          </mime-type>
        </mime-info>
      '';
    })
  ]);
}
