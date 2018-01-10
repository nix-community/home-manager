{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.ssh;

  yn = flag: if flag then "yes" else "no";

  matchBlockModule = types.submodule ({ name, ... }: {
    options = {
      host = mkOption {
        type = types.str;
        example = "*.example.org";
        description = ''
          The host pattern used by this conditional block.
        '';
      };

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
          over the secure channel and <envar>DISPLAY</envar> set.
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
          Specifies that ssh should only use the authentication
          identity explicitly configured in the
          <filename>~/.ssh/config</filename> files or passed on the
          ssh command-line, even if <command>ssh-agent</command>
          offers more identities.
        '';
      };

      identityFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Specifies a file from which the user identity is read.
        '';
      };

      user = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Specifies the user to log in as.";
      };

      hostname = mkOption {
        type = types.nullOr types.str;
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
        description = ''
          Check the host IP address in the
          <filename>known_hosts</filename> file.
        '';
      };

      proxyCommand = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The command to use to connect to the server.";
      };

      extraOptions = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Extra configuration options for the host.";
      };
    };

    config.host = mkDefault name;
  });

  matchBlockStr = cf: concatStringsSep "\n" (
    ["Host ${cf.host}"]
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
    ++ optional (cf.proxyCommand != null) "  ProxyCommand ${cf.proxyCommand}"
    ++ mapAttrsToList (n: v: "  ${n} ${v}") cf.extraOptions
  );

in

{
  meta.maintainers = [ maintainers.rycee ];

  options.programs.ssh = {
    enable = mkEnableOption "SSH client configuration";

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
      type = types.str;
      default = "~/.ssh/master-%r@%h:%p";
      description = ''
        Specify path to the control socket used for connection sharing.
      '';
    };

    controlPersist = mkOption {
      type = types.str;
      default = "no";
      example = "10m";
      description = ''
        Whether control socket should remain open in the background.
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Extra configuration.
      '';
    };

    matchBlocks = mkOption {
      type = types.loaOf matchBlockModule;
      default = [];
      example = literalExample ''
        {
          "john.example.com" = {
            hostname = "example.com";
            user = "john";
          };
          foo = {
            hostname = "example.com";
            identityFile = "/home/john/.ssh/foo_rsa";
          };
        };
      '';
      description = ''
        Specify per-host settings. Note, if the order of rules matter
        then this must be a list. See
        <citerefentry>
          <refentrytitle>ssh_config</refentrytitle>
          <manvolnum>5</manvolnum>
        </citerefentry>.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.file.".ssh/config".text = ''
      ForwardAgent ${yn cfg.forwardAgent}
      ControlMaster ${cfg.controlMaster}
      ControlPath ${cfg.controlPath}
      ControlPersist ${cfg.controlPersist}

      ${cfg.extraConfig}

      ${concatStringsSep "\n\n" (
        map matchBlockStr (
        builtins.attrValues cfg.matchBlocks))}
    '';
  };
}
