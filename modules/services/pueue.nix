{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.pueue;
  yamlFormat = pkgs.formats.yaml { };
  configFile = yamlFormat.generate "pueue.yaml" cfg.settings;

in {
  meta.maintainers = [ maintainers.AndersonTorres ];

  options.services.pueue = {
    enable = mkEnableOption "Pueue, CLI process scheduler and manager";

    package = mkPackageOption pkgs "pueue" { };

    settings = mkOption {
      type = yamlFormat.type;
      default = { };
      example = literalExpression ''
        {
          daemon = {
            default_parallel_tasks = 2;
          };
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/pueue/pueue.yml`.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions =
      [ (hm.assertions.assertPlatform "services.pueue" pkgs platforms.linux) ];

    home.packages = [ cfg.package ];

    xdg.configFile =
      mkIf (cfg.settings != { }) { "pueue/pueue.yml".source = configFile; };

    systemd.user = {
      services.pueued = {
        Unit = {
          Description = "Pueue Daemon - CLI process scheduler and manager";
        };

        Service = {
          Restart = "on-failure";
          ExecStart = "${cfg.package}/bin/pueued -v -c ${configFile}";
        };

        Install.WantedBy = [ "default.target" ];
      };
    };
  };
}
