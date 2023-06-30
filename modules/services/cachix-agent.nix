{ config, pkgs, lib, ... }:

with lib;

let

  cfg = config.services.cachix-agent;

in {
  meta.maintainers = [ maintainers.rycee ];

  options.services.cachix-agent = {
    enable = mkEnableOption
      (lib.mdDoc "Cachix Deploy Agent: <https://docs.cachix.org/deploy/>");

    name = mkOption {
      type = types.str;
      description = lib.mdDoc "The unique agent name.";
    };

    verbose = mkEnableOption (lib.mdDoc "verbose output");

    profile = mkOption {
      type = types.str;
      default = "home-manager";
      description = lib.mdDoc ''
        The Nix profile name.
      '';
    };

    host = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = lib.mdDoc "Cachix URI to use.";
    };

    package = mkPackageOptionMD pkgs "cachix" { };

    credentialsFile = mkOption {
      type = types.path;
      default = "${config.xdg.configHome}/cachix-agent.token";
      defaultText =
        literalExpression ''"''${config.xdg.configHome}/cachix-agent.token"'';
      description = lib.mdDoc ''
        Required file that needs to contain
        `CACHIX_AGENT_TOKEN=...`.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.cachix-agent" pkgs
        lib.platforms.linux)
    ];

    systemd.user.services.cachix-agent = {
      Unit.Description = "Cachix Deploy Agent";

      Service = {
        Environment = [
          "PATH=${
            if config.nix.enable && config.nix.package != null then
              config.nix.package
            else
              pkgs.nix
          }/bin"
        ];
        EnvironmentFile = cfg.credentialsFile;

        # We don't want to kill children processes as those are deployments.
        KillMode = "process";
        Restart = "on-failure";
        ExecStart = escapeShellArgs ([ "${cfg.package}/bin/cachix" ]
          ++ optional cfg.verbose "--verbose"
          ++ optional (cfg.host != null) "--host ${cfg.host}"
          ++ [ "deploy" "agent" cfg.name ]
          ++ optional (cfg.profile != null) cfg.profile);
      };

      Install.WantedBy = [ "default.target" ];
    };
  };
}
