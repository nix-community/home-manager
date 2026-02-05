{
  config,
  lib,
  pkgs,
  ...
}:
let

  cfg = config.services.kdeconnect;

in
{
  meta.maintainers = [ lib.maintainers.adisbladis ];

  options = {
    services.kdeconnect = {
      enable = lib.mkEnableOption "KDE connect";
      package = lib.mkPackageOption pkgs.kdePackages "kdeconnect-kde" {
        example = "pkgs.plasma5Packages.kdeconnect-kde";
        pkgsText = "pkgs.kdePackages";
      };

      indicator = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to enable kdeconnect-indicator service.";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      assertions = [
        (lib.hm.assertions.assertPlatform "services.kdeconnect" pkgs lib.platforms.linux)
      ];

      home.packages = [ cfg.package ];

      systemd.user.services.kdeconnect = {
        Unit = {
          Description = "Adds communication between your desktop and your smartphone";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };

        Service = {
          Environment = [ "PATH=${config.home.profileDirectory}/bin" ];
          ExecStart =
            if lib.strings.versionAtLeast (lib.versions.majorMinor cfg.package.version) "24.05" then
              "${cfg.package}/bin/kdeconnectd"
            else
              "${cfg.package}/libexec/kdeconnectd";
          Restart = "on-abort";
        };
      };
    })

    (lib.mkIf cfg.indicator {
      assertions = [
        (lib.hm.assertions.assertPlatform "services.kdeconnect" pkgs lib.platforms.linux)
      ];

      systemd.user.services.kdeconnect-indicator = {
        Unit = {
          Description = "kdeconnect-indicator";
          After = [
            "graphical-session.target"
            "tray-sni.target"
          ]
          ++ config.lib.tray.sniWatcherAfter;
          PartOf = [ "graphical-session.target" ];
          Requires = [ "tray-sni.target" ] ++ config.lib.tray.sniWatcherRequires;
          Wants = config.lib.tray.sniWatcherWants;
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };

        Service = {
          Environment = [ "PATH=${config.home.profileDirectory}/bin" ];
          ExecStart = "${cfg.package}/bin/kdeconnect-indicator";
          Restart = "on-abort";
        };
      };
    })
  ];
}
