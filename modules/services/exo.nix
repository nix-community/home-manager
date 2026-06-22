{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.exo;
in
{
  meta.maintainers = [ lib.maintainers.dsqr ];

  options.services.exo = {
    enable = lib.mkEnableOption "exo local AI cluster node";

    package = lib.mkPackageOption pkgs "exo" { };

    environmentVariables = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        EXO_LIBP2P_NAMESPACE = "home-cluster";
        EXO_OFFLINE = "true";
      };
      description = ''
        Environment variables for the exo service.

        See <https://github.com/exo-explore/exo#environment-variables>
        for supported environment variables.
      '';
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "--no-worker" ];
      description = ''
        Extra command-line arguments passed to {command}`exo`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    systemd.user.services.exo = {
      Unit = {
        Description = "exo local AI cluster node";
        After = [ "network.target" ];
      };

      Service = {
        ExecStart = lib.escapeShellArgs ([ (lib.getExe cfg.package) ] ++ cfg.extraArgs);
        Environment = lib.mapAttrsToList (name: value: "${name}=${value}") cfg.environmentVariables;
        Restart = "on-failure";
      };

      Install.WantedBy = [ "default.target" ];
    };

    launchd.agents.exo = {
      enable = true;
      config = {
        ProgramArguments = [ (lib.getExe cfg.package) ] ++ cfg.extraArgs;
        EnvironmentVariables = cfg.environmentVariables;
        KeepAlive = {
          Crashed = true;
          SuccessfulExit = false;
        };
        ProcessType = "Background";
        RunAtLoad = true;
      };
    };
  };
}
