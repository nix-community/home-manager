{ config, lib, pkgs, ... }:

let
  cfg = config.services.glance;

  inherit (lib) mkEnableOption mkPackageOption mkOption mkIf getExe;

  settingsFormat = pkgs.formats.yaml { };

  settingsFile = settingsFormat.generate "glance.yml" cfg.settings;

  configFilePath = "${config.xdg.configHome}/glance/glance.yml";
in {
  meta.maintainers = [ pkgs.lib.maintainers.gepbird ];

  options.services.glance = {
    enable = mkEnableOption "glance";

    package = mkPackageOption pkgs "glance" { };

    settings = mkOption {
      type = settingsFormat.type;
      default = {
        pages = [{
          name = "Calendar";
          columns = [{
            size = "full";
            widgets = [{ type = "calendar"; }];
          }];
        }];
      };
      example = {
        server.port = 5678;
        pages = [{
          name = "Home";
          columns = [{
            size = "full";
            widgets = [
              { type = "calendar"; }
              {
                type = "weather";
                location = "London, United Kingdom";
              }
            ];
          }];
        }];
      };
      description = ''
        Configuration written to a yaml file that is read by glance. See
        <https://github.com/glanceapp/glance/blob/main/docs/configuration.md>
        for more.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.glance" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile."glance/glance.yml".source = settingsFile;

    systemd.user.services.glance = {
      Unit = {
        Description = "Glance feed dashboard server";
        PartOf = [ "graphical-session.target" ];
      };

      Install.WantedBy = [ "graphical-session.target" ];

      Service.ExecStart = "${getExe cfg.package} --config ${configFilePath}";
    };
  };
}
