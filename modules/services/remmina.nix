{ config, lib, pkgs, ... }:

let cfg = config.services.remmina;
in {
  options.services.remmina = {
    enable = lib.mkEnableOption "Remmina";

    package = lib.mkPackageOption pkgs "remmina" { };

    addRdpMimeTypeAssoc = lib.mkEnableOption "Remmina RDP file open option" // {
      default = true;
    };

    systemdService = {
      enable = lib.mkEnableOption "Systemd Remmina service" // {
        default = true;
      };

      startupFlags = lib.mkOption {
        type = with lib.types; listOf str;
        default = [ "--icon" ];
        description = ''
          Startup flags documented in the manpage to run at service startup.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    { home.packages = [ cfg.package ]; }

    (lib.mkIf cfg.systemdService.enable {
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

    (lib.mkIf (config.xdg.mimeApps.enable && cfg.addRdpMimeTypeAssoc) {
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

  meta.maintainers = with lib.maintainers; [ cyntheticfox ];
}
