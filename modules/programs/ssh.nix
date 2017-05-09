{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.ssh;

  yn = flag: if flag then "yes" else "no";

  hostModule = types.submodule ({...}: {
    options = {

      port = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Specifies port number to connect on remote host.";
      };

      forwardX11 = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Specifies whether X11 connections will be automatically redirected
          over the secure channel and DISPLAY set.
        '';
      };

      forwardX11Trusted = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Specifies whether remote X11 clients will have full access to the
          original X11 display.
        '';
      };

      identitiesOnly = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Specifies that ssh should only use the authentication identity
          explicitly configured in the .ssh/config files or passed on the
          ssh command-line, even if ssh-agent offers more identities.
        '';
      };

      identityFile = mkOption {
        type = types.nullOr types.string;
        default = null;
        description = ''
          Specifies a file from which user's identity is read.
        '';
      };

      user = mkOption {
        type = types.nullOr types.string;
        default = null;
        description = "Specifies the user to log in as.";
      };

      hostname = mkOption {
        type = types.nullOr types.string;
        default = null;
        description = "Specifies the real host name to log into.";
      };

      serverAliveInterval = mkOption {
        type = types.int;
        default = 0;
        description =
          "Set timeout in seconds after which response will be requested.";
      };

      checkHostIP = mkOption {
        type = types.bool;
        default = true;
        description = "Check that host IP address in the known_hosts file.";
      };
    };
  });

  hostStr = host: cf: concatStringsSep "\n" (
    ["Host ${host}"]
    ++ optional (cf.port != null)         "  Port ${toString cf.port}"
    ++ optional cf.forwardX11             "  ForwardX11 yes"
    ++ optional cf.forwardX11Trusted      "  ForwardX11Trusted yes"
    ++ optional cf.identitiesOnly         "  IdentitiesOnly yes"
    ++ optional (cf.user != null)         "  User ${cf.user}"
    ++ optional (cf.identityFile != null) "  IdentityFile ${cf.identityFile}"
    ++ optional (cf.hostname != null)     "  HostName ${cf.hostname}"
    ++ optional (cf.serverAliveInterval != 0)
         "  ServerAliveInterval ${toString cf.serverAliveInterval}"
    ++ optional (!cf.checkHostIP)         "  CheckHostIP no"
  );

in

{
  options.programs.ssh = {
    enable = mkEnableOption "SSH Client Configuration";

    forwardAgent = mkOption {
      default = false;
      type = types.bool;
      description = ''
        Whether connection to authentication agent (if any) will be forwarded
        to remote machine.
      '';
    };

    controlMaster = mkOption {
      default = "no";
      type = types.enum ["yes" "no" "ask" "auto" "autoask"];
      description = ''
        Configure sharing of multiple sessions over a single network connection.
      '';
    };

    controlPath = mkOption {
      type = types.string;
      default = "~/.ssh/master-%r@%h:%p";
      description = ''
        Specify path to the control socket used for connection sharing.
      '';
    };

    hosts = mkOption {
      type = types.attrsOf hostModule;
      default = {};
      description = ''
        Specify per-host settings.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.file.".ssh/config".text = ''
      ForwardAgent ${yn cfg.forwardAgent}
      ControlMaster ${cfg.controlMaster}
      ControlPath ${cfg.controlPath}

      ${concatStringsSep "\n\n" (mapAttrsToList hostStr cfg.hosts)}
    '';
  };
}
