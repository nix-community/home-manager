{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.rbw;

  jsonFormat = pkgs.formats.json { };

  inherit (lib) mkOption types;

  settingsModule = types.submodule {
    freeformType = jsonFormat.type;
    options = {
      email = mkOption {
        type = types.str;
        example = "name@example.com";
        description = "The email address for your bitwarden account.";
      };

      base_url = mkOption {
        type = with types; nullOr str;
        default = null;
        example = "https://bitwarden.example.com/";
        description = "The base-url for a self-hosted bitwarden installation.";
      };

      identity_url = mkOption {
        type = with types; nullOr str;
        default = null;
        example = "https://identity.example.com/";
        description = "The identity url for your bitwarden installation.";
      };

      lock_timeout = mkOption {
        type = types.ints.unsigned;
        default = 3600;
        example = 300;
        description = ''
          The amount of time that your login information should be cached.
        '';
      };

      pinentry = mkOption {
        type = types.nullOr types.package;
        example = lib.literalExpression "pkgs.pinentry-gnome3";
        default = null;
        description = ''
          Which pinentry interface to use. Beware that
          `pinentry-gnome3` may not work on non-Gnome
          systems. You can fix it by adding the following to your
          system configuration:
          ```nix
          services.dbus.packages = [ pkgs.gcr ];
          ```
        '';
        # we want the program in the config
        apply = val: if val == null then val else lib.getExe val;
      };
    };
  };

  configDir =
    if pkgs.stdenv.hostPlatform.isDarwin then "Library/Application Support" else config.xdg.configHome;
  socketPath = "$XDG_RUNTIME_DIR/rbw/ssh-agent-socket";
in
{
  meta.maintainers = with lib.maintainers; [ ambroisie ];

  options.programs.rbw = {
    enable = lib.mkEnableOption "rbw, a CLI Bitwarden client";

    package = lib.mkPackageOption pkgs "rbw" {
      extraDescription = ''
        Package providing the {command}`rbw` tool and its
        {command}`rbw-agent` daemon.
      '';
    };

    settings = mkOption {
      type = types.nullOr settingsModule;
      default = null;
      example = lib.literalExpression ''
        {
          email = "name@example.com";
          lock_timeout = 300;
          pinentry = pkgs.pinentry-gnome3;
        }
      '';
      description = ''
        rbw configuration, if not defined the configuration will not be
        managed by Home Manager.
      '';
    };
    sshAgent = lib.mkOption {
      type = lib.types.bool;
      description = "rbw as an SSH Agent";
      default = false;
    };

    systemd = {
      enable = lib.mkOption {
        type = lib.types.bool;
        description = "run the rbw agent in systemd";
        default = true;
      };
      targets = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "targets for the rbw systemd service";
        default = [ "default.target" ];
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.rbw.sshAgent" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    home.file."${configDir}/rbw/config.json" = lib.mkIf (cfg.settings != null) {
      source = jsonFormat.generate "rbw-config.json" (lib.filterAttrs (_: v: v != null) cfg.settings);
    };

    systemd.user.services.rbw-agent = lib.mkIf cfg.systemd.enable {
      Service = {
        ExecStart = "${cfg.package}/bin/rbw-agent --no-daemonize";
        PIDFile = "rbw/pidfile";
      };
      Install = {
        WantedBy = cfg.systemd.targets;
      };
      Unit = {
        After = [ "network.target" ];
        Description = "rbw Agent";
        Documentation = "man:rbw-agent(1)";
      };
    };

    sshAuthSock = lib.mkIf cfg.sshAgent {
      enable = true;
      systemd = {
        socketProviderUnit = lib.mkIf cfg.systemd.enable "rbw-agent.service";
      };
      initialization = {
        bash = "export SSH_AUTH_SOCK=${socketPath}";
        fish = "set -x SSH_AUTH_SOCK ${socketPath}";
        zsh = "export SSH_AUTH_SOCK=${socketPath}";
        nushell = "$env.SSH_AUTH_SOCK = ${socketPath}";
      };
    };
  };
}
