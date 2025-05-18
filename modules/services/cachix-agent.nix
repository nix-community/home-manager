{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkOption optional types;

  cfg = config.services.cachix-agent;

in
{
  meta.maintainers = [ lib.maintainers.rycee ];

  options.services.cachix-agent = {
    enable = lib.mkEnableOption "Cachix Deploy Agent: <https://docs.cachix.org/deploy/>";

    name = mkOption {
      type = types.str;
      description = "The unique agent name.";
    };

    verbose = lib.mkEnableOption "verbose output";

    profile = mkOption {
      type = types.str;
      default = "home-manager";
      description = ''
        The Nix profile name.
      '';
    };

    host = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Cachix URI to use.";
    };

    package = lib.mkPackageOption pkgs "cachix" { };

    credentialsFile = mkOption {
      type = types.path;
      default = "${config.xdg.configHome}/cachix-agent.token";
      defaultText = lib.literalExpression ''"''${config.xdg.configHome}/cachix-agent.token"'';
      description = ''
        Required file that needs to contain
        `CACHIX_AGENT_TOKEN=...`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.cachix-agent" pkgs lib.platforms.linux)
    ];

    systemd.user.services.cachix-agent = {
      Unit.Description = "Cachix Deploy Agent";

      Service = {
        Environment = [
          "PATH=${
            if config.nix.enable && config.nix.package != null then config.nix.package else pkgs.nix
          }/bin"
        ];
        EnvironmentFile = cfg.credentialsFile;

        # We don't want to kill children processes as those are deployments.
        KillMode = "process";
        Restart = "on-failure";
        ExecStart = lib.escapeShellArgs (
          [ "${cfg.package}/bin/cachix" ]
          ++ optional cfg.verbose "--verbose"
          ++ optional (cfg.host != null) "--host ${cfg.host}"
          ++ [
            "deploy"
            "agent"
            cfg.name
          ]
          ++ optional (cfg.profile != null) cfg.profile
        );
      };

      Install.WantedBy = [ "default.target" ];
    };
  };
}
