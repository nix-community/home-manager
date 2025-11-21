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
  pueuedBin = "${cfg.package}/bin/pueued";
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

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];
      }
      (lib.mkIf pkgs.stdenv.isLinux {
        xdg.configFile."pueue/pueue.yml".source = configFile;
        systemd.user = lib.mkIf (cfg.package != null) {
          services.pueued = {
            Unit = {
              Description = "Pueue Daemon - CLI process scheduler and manager";
            };

            Service = {
              Restart = "on-failure";
              ExecStart = "${pueuedBin} -v -c ${configFile}";
            };

            Install.WantedBy = [ "default.target" ];
          };
        };
      })
      (lib.mkIf pkgs.stdenv.isDarwin {
        # This is the default configuration file location for pueue on
        # darwin (https://github.com/Nukesor/pueue/wiki/Configuration)
        home.file."Library/Application Support/pueue/pueue.yml".source = configFile;
        launchd.agents.pueued = lib.mkIf (cfg.package != null) {
          enable = true;

          config = {
            ProgramArguments = [
              pueuedBin
              "-v"
              "-c"
              "${configFile}"
            ];
            KeepAlive = {
              Crashed = true;
              SuccessfulExit = false;
            };
            ProcessType = "Background";
            RunAtLoad = true;
          };
        };
      })
    ]
  );
}
