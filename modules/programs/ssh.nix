{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.ssh;

  yn = flag: if flag then "yes" else "no";

  unwords = builtins.concatStringsSep " ";

  localForwardModule = types.submodule ({ ... }: {
    options = {
      bind = {
        address = mkOption {
          type = types.str;
          default = "localhost";
          example = "example.org";
          description = "The address where to bind the port.";
        };

        port = mkOption {
          type = types.port;
          example = 8080;
          description = "Specifies port number to bind on bind address.";
        };
      };

      host = {
        address = mkOption {
          type = types.str;
          example = "example.org";
          description = "The address where to forward the traffic to.";
        };

        port = mkOption {
          type = types.port;
          example = 80;
          description = "Specifies port number to forward the traffic to.";
        };
      };
    };
  });

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
        type = types.nullOr types.port;
        default = null;
        description = "Specifies port number to connect on remote host.";
      };

      forwardAgent = mkOption {
        default = null;
        type = types.nullOr types.bool;
        description = ''
          Whether the connection to the authentication agent (if any)
          will be forwarded to the remote machine.
        '';
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
        type = with types; either (listOf str) (nullOr str);
        default = [];
        apply = p:
          if p == null then []
          else if isString p then [p]
          else p;
        description = ''
          Specifies files from which the user identity is read.
          Identities will be tried in the given order.
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

      sendEnv = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          Environment variables to send from the local host to the
          server.
        '';
      };

      compression = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          Specifies whether to use compression. Omitted from the host
          block when <literal>null</literal>.
        '';
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

      proxyJump = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The proxy host to use to connect to the server.";
      };

      certificateFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = ''
          Specifies a file from which the user certificate is read.
        '';
      };

      addressFamily = mkOption {
        default = null;
        type = types.nullOr (types.enum ["any" "inet" "inet6"]);
        description = ''
          Specifies which address family to use when connecting.
        '';
      };

      localForwards = mkOption {
        type = types.listOf localForwardModule;
        default = [];
        example = literalExample ''
          [
            {
              bind.port = 8080;
              host.address = "10.0.0.13";
              host.port = 80;
            }
          ];
        '';
        description = ''
          Specify local port forwardings. See
          <citerefentry>
            <refentrytitle>ssh_config</refentrytitle>
            <manvolnum>5</manvolnum>
          </citerefentry> for LocalForward.
        '';
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
    ++ optional (cf.port != null)            "  Port ${toString cf.port}"
    ++ optional (cf.forwardAgent != null)    "  ForwardAgent ${yn cf.forwardAgent}"
    ++ optional cf.forwardX11                "  ForwardX11 yes"
    ++ optional cf.forwardX11Trusted         "  ForwardX11Trusted yes"
    ++ optional cf.identitiesOnly            "  IdentitiesOnly yes"
    ++ optional (cf.user != null)            "  User ${cf.user}"
    ++ optional (cf.certificateFile != null) "  CertificateFile ${cf.certificateFile}"
    ++ optional (cf.hostname != null)        "  HostName ${cf.hostname}"
    ++ optional (cf.addressFamily != null)   "  AddressFamily ${cf.addressFamily}"
    ++ optional (cf.sendEnv != [])           "  SendEnv ${unwords cf.sendEnv}"
    ++ optional (cf.serverAliveInterval != 0)
         "  ServerAliveInterval ${toString cf.serverAliveInterval}"
    ++ optional (cf.compression != null)     "  Compression ${yn cf.compression}"
    ++ optional (!cf.checkHostIP)            "  CheckHostIP no"
    ++ optional (cf.proxyCommand != null)    "  ProxyCommand ${cf.proxyCommand}"
    ++ optional (cf.proxyJump != null)       "  ProxyJump ${cf.proxyJump}"
    ++ map (file: "  IdentityFile ${file}") cf.identityFile
    ++ map (f:
      let
        addressPort = entry: " [${entry.address}]:${toString entry.port}";
      in
        "  LocalForward"
        + addressPort f.bind
        + addressPort f.host
    ) cf.localForwards
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
        Whether the connection to the authentication agent (if any)
        will be forwarded to the remote machine.
      '';
    };

    compression = mkOption {
      default = false;
      type = types.bool;
      description = "Specifies whether to use compression.";
    };

    serverAliveInterval = mkOption {
      type = types.int;
      default = 0;
      description = ''
        Set default timeout in seconds after which response will be requested.
      '';
    };

    hashKnownHosts = mkOption {
      default = false;
      type = types.bool;
      description = ''
        Indicates that
        <citerefentry>
          <refentrytitle>ssh</refentrytitle>
          <manvolnum>1</manvolnum>
        </citerefentry>
        should hash host names and addresses when they are added to
        the known hosts file.
      '';
    };

    userKnownHostsFile = mkOption {
      type = types.str;
      default = "~/.ssh/known_hosts";
      description = ''
        Specifies one or more files to use for the user host key
        database, separated by whitespace. The default is
        <filename>~/.ssh/known_hosts</filename>.
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
      default = "~/.ssh/master-%r@%n:%p";
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

    extraOptionOverrides = mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = ''
        Extra SSH configuration options that take precedence over any
        host specific configuration.
      '';
    };

    matchBlocks = mkOption {
      type = types.loaOf matchBlockModule;
      default = {};
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
      ${concatStringsSep "\n" (
        mapAttrsToList (n: v: "${n} ${v}") cfg.extraOptionOverrides)}

      ${concatStringsSep "\n\n" (
        map matchBlockStr (
        builtins.attrValues cfg.matchBlocks))}

      Host *
        ForwardAgent ${yn cfg.forwardAgent}
        Compression ${yn cfg.compression}
        ServerAliveInterval ${toString cfg.serverAliveInterval}
        HashKnownHosts ${yn cfg.hashKnownHosts}
        UserKnownHostsFile ${cfg.userKnownHostsFile}
        ControlMaster ${cfg.controlMaster}
        ControlPath ${cfg.controlPath}
        ControlPersist ${cfg.controlPersist}

        ${replaceStrings ["\n"] ["\n  "] cfg.extraConfig}
    '';
  };
}
