{
  config,
  lib,
  pkgs,
  ...
}:
let

  cfg = config.services.pueue;
  yamlFormat = pkgs.formats.yaml { };
  configFile = yamlFormat.generate "pueue.yaml" ({ shared = { }; } // cfg.settings);

in
{
  meta.maintainers = [ lib.maintainers.AndersonTorres ];

  options.services.pueue = {
    enable = lib.mkEnableOption "Pueue, CLI process scheduler and manager";

    package = lib.mkPackageOption pkgs "pueue" { nullable = true; };

    settings = lib.mkOption {
      type = yamlFormat.type;
      default = { };
      example = lib.literalExpression ''
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

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.pueue" pkgs lib.platforms.linux)
    ];

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."pueue/pueue.yml".source = configFile;

    systemd.user = lib.mkIf (cfg.package != null) {
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
