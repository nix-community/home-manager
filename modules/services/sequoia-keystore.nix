{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    optionals
    types
    ;

  cfg = config.services.sequoia-keystore;

  args =
    optionals (cfg.sequoiaHome != null) [
      "--sequoia-home"
      (toString cfg.sequoiaHome)
    ]
    ++ optionals (cfg.home != null) [
      "--home"
      (toString cfg.home)
    ]
    ++ optionals (cfg.ephemeral != null) [
      "--ephemeral"
      (lib.boolToString cfg.ephemeral)
    ]
    ++ optionals (cfg.lib != null) [
      "--lib"
      (toString cfg.lib)
    ]
    ++ optionals (cfg.socket != null) [
      "--socket"
      (toString cfg.socket)
    ]
    ++ cfg.extraArgs;
in
{
  meta.maintainers = [ lib.maintainers.philocalyst ];

  options.services.sequoia-keystore = {
    enable = lib.mkEnableOption "Sequoia Key Store";

    package = lib.mkPackageOption pkgs "sequoia-keystore-server" { nullable = true; };

    sequoiaHome = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "\${config.xdg.dataHome}/sequoia";
      description = "Value passed as `--sequoia-home`.";
    };

    home = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "\${config.xdg.dataHome}/sequoia/keystore";
      description = ''
        Keystore component home passed as `--home`. Overrides
        {option}`services.sequoia-keystore.sequoiaHome` for the keystore.
      '';
    };

    ephemeral = mkOption {
      type = types.nullOr types.bool;
      default = null;
      example = false;
      description = "Whether to pass the hidden `--ephemeral` server flag.";
    };

    lib = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/run/current-system/sw/libexec/sequoia";
      description = "Directory containing backend servers, passed as the hidden `--lib` flag.";
    };

    socket = mkOption {
      type = types.nullOr types.ints.unsigned;
      default = null;
      example = 0;
      description = ''
        File descriptor passed as `--socket`. Upstream currently only accepts
        `0`, and this is normally only used by programs that start the server.
      '';
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--debug" ];
      description = "Additional arguments appended to the `sequoia-keystore` invocation.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = cfg.package != null;
          message = ''
            services.sequoia-keystore.package is null because nixpkgs does not yet
            provide sequoia-keystore-server. Set this option to a package that
            provides the sequoia-keystore binary.
          '';
        }
        {
          assertion = cfg.socket == null || cfg.socket == 0;
          message = "services.sequoia-keystore.socket must be 0 when set; upstream currently rejects other descriptors.";
        }
      ];

      home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

      programs.sequoia-pgp = {
        enable = true;
        settings.servers.path = mkIf (cfg.package != null) (lib.mkDefault "${cfg.package}/libexec/sequoia");
      };

      home.sessionVariables = mkIf (cfg.sequoiaHome != null) {
        SEQUOIA_HOME = cfg.sequoiaHome;
      };
    }

    (mkIf (cfg.package != null) {
      systemd.user.services.sequoia-keystore = {
        Unit = {
          Description = "Sequoia Key Store";
          Documentation = "https://gitlab.com/sequoia-pgp/sequoia-keystore";
        };

        Service = {
          ExecStart = lib.escapeShellArgs ([ (lib.getExe' cfg.package "sequoia-keystore") ] ++ args);
          Restart = "on-failure";
        };

        Install.WantedBy = [ "default.target" ];
      };

      launchd.agents.sequoia-keystore = {
        enable = true;
        config = {
          ProgramArguments = [ (lib.getExe' cfg.package "sequoia-keystore") ] ++ args;
          KeepAlive = {
            Crashed = true;
            SuccessfulExit = false;
          };
          ProcessType = "Background";
          RunAtLoad = true;
          StandardOutPath = "${config.home.homeDirectory}/Library/Logs/sequoia-keystore/launchd-stdout.log";
          StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/sequoia-keystore/launchd-stderr.log";
        };
      };
    })
  ]);
}
