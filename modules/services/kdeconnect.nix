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
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.kdePackages.kdeconnect-kde;
        example = lib.literalExpression "pkgs.plasma5Packages.kdeconnect-kde";
        description = "The KDE connect package to use";
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
      home.packages = [ cfg.package ];

      assertions = [
        (lib.hm.assertions.assertPlatform "services.kdeconnect" pkgs lib.platforms.linux)
      ];

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
            "tray.target"
          ];
          PartOf = [ "graphical-session.target" ];
          Requires = [ "tray.target" ];
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
