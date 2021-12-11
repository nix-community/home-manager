{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.ssh;

  isPath = x: builtins.substring 0 1 (toString x) == "/";

  addressPort = entry:
    if isPath entry.address then
      " ${entry.address}"
    else
      " [${entry.address}]:${toString entry.port}";

  unwords = builtins.concatStringsSep " ";

  mkSetEnvStr = envStr:
    unwords (mapAttrsToList
      (name: value: ''${name}="${escape [ ''"'' "\\" ] (toString value)}"'')
      envStr);

  bindOptions = {
    address = mkOption {
      type = types.str;
      default = "localhost";
      example = "example.org";
      description = "The address where to bind the port.";
    };

    port = mkOption {
      type = types.nullOr types.port;
      default = null;
      example = 8080;
      description = "Specifies port number to bind on bind address.";
    };
  };

  dynamicForwardModule = types.submodule { options = bindOptions; };

  forwardModule = types.submodule {
    options = {
      bind = bindOptions;

      host = {
        address = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "example.org";
          description = "The address where to forward the traffic to.";
        };

        port = mkOption {
          type = types.nullOr types.port;
          default = null;
          example = 80;
          description = "Specifies port number to forward the traffic to.";
        };
      };
    };
  };

  matchBlockModule = types.submodule ({ dagName, ... }: {
    options = {
      host = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "*.example.org";
        description = ''
          `Host` pattern used by this conditional block.
          See
          {manpage}`ssh_config(5)`
          for `Host` block details.
          This option is ignored if
          {option}`ssh.matchBlocks.*.match`
          if defined.
        '';
      };

      match = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = ''
          host <hostname> canonical
          host <hostname> exec "ping -c1 -q 192.168.17.1"'';
        description = ''
          `Match` block conditions used by this block. See
          {manpage}`ssh_config(5)`
          for `Match` block details.
          This option takes precedence over
          {option}`ssh.matchBlocks.*.host`
          if defined.
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
          over the secure channel and {env}`DISPLAY` set.
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
          {file}`~/.ssh/config` files or passed on the
          ssh command-line, even if {command}`ssh-agent`
          offers more identities.
        '';
      };

      identityFile = mkOption {
        type = with types; either (listOf str) (nullOr str);
        default = [ ];
        apply = p: if p == null then [ ] else if isString p then [ p ] else p;
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

      serverAliveCountMax = mkOption {
        type = types.ints.positive;
        default = 3;
        description = ''
          Sets the number of server alive messages which may be sent
          without SSH receiving any messages back from the server.
        '';
      };

      sendEnv = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Environment variables to send from the local host to the
          server.
        '';
      };

      setEnv = mkOption {
        type = with types; attrsOf (oneOf [ str path int float ]);
        default = { };
        description = ''
          Environment variables and their value to send to the server.
        '';
      };

      compression = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          Specifies whether to use compression. Omitted from the host
          block when `null`.
        '';
      };

      checkHostIP = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Check the host IP address in the
          {file}`known_hosts` file.
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
        type = with types; either (listOf str) (nullOr str);
        default = [ ];
        apply = p: if p == null then [ ] else if isString p then [ p ] else p;
        description = ''
          Specifies files from which the user certificate is read.
        '';
      };

      addressFamily = mkOption {
        default = null;
        type = types.nullOr (types.enum [ "any" "inet" "inet6" ]);
        description = ''
          Specifies which address family to use when connecting.
        '';
      };

      localForwards = mkOption {
        type = types.listOf forwardModule;
        default = [ ];
        example = literalExpression ''
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
          {manpage}`ssh_config(5)` for `LocalForward`.
        '';
      };

      remoteForwards = mkOption {
        type = types.listOf forwardModule;
        default = [ ];
        example = literalExpression ''
          [
            {
              bind.port = 8080;
              host.address = "10.0.0.13";
              host.port = 80;
            }
          ];
        '';
        description = ''
          Specify remote port forwardings. See
          {manpage}`ssh_config(5)` for `RemoteForward`.
        '';
      };

      dynamicForwards = mkOption {
        type = types.listOf dynamicForwardModule;
        default = [ ];
        example = literalExpression ''
          [ { port = 8080; } ];
        '';
        description = ''
          Specify dynamic port forwardings. See
          {manpage}`ssh_config(5)` for `DynamicForward`.
        '';
      };

      extraOptions = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = "Extra configuration options for the host.";
      };
    };

    #    config.host = mkDefault dagName;
  });

  matchBlockStr = key: cf:
    concatStringsSep "\n" (let
      hostOrDagName = if cf.host != null then cf.host else key;
      matchHead = if cf.match != null then
        "Match ${cf.match}"
      else
        "Host ${hostOrDagName}";
    in [ "${matchHead}" ]
    ++ optional (cf.port != null) "  Port ${toString cf.port}"
    ++ optional (cf.forwardAgent != null)
    "  ForwardAgent ${lib.hm.booleans.yesNo cf.forwardAgent}"
    ++ optional cf.forwardX11 "  ForwardX11 yes"
    ++ optional cf.forwardX11Trusted "  ForwardX11Trusted yes"
    ++ optional cf.identitiesOnly "  IdentitiesOnly yes"
    ++ optional (cf.user != null) "  User ${cf.user}"
    ++ optional (cf.hostname != null) "  HostName ${cf.hostname}"
    ++ optional (cf.addressFamily != null) "  AddressFamily ${cf.addressFamily}"
    ++ optional (cf.sendEnv != [ ]) "  SendEnv ${unwords cf.sendEnv}"
    ++ optional (cf.setEnv != { }) "  SetEnv ${mkSetEnvStr cf.setEnv}"
    ++ optional (cf.serverAliveInterval != 0)
    "  ServerAliveInterval ${toString cf.serverAliveInterval}"
    ++ optional (cf.serverAliveCountMax != 3)
    "  ServerAliveCountMax ${toString cf.serverAliveCountMax}"
    ++ optional (cf.compression != null)
    "  Compression ${lib.hm.booleans.yesNo cf.compression}"
    ++ optional (!cf.checkHostIP) "  CheckHostIP no"
    ++ optional (cf.proxyCommand != null) "  ProxyCommand ${cf.proxyCommand}"
    ++ optional (cf.proxyJump != null) "  ProxyJump ${cf.proxyJump}"
    ++ map (file: "  IdentityFile ${file}") cf.identityFile
    ++ map (file: "  CertificateFile ${file}") cf.certificateFile
    ++ map (f: "  LocalForward" + addressPort f.bind + addressPort f.host)
    cf.localForwards
    ++ map (f: "  RemoteForward" + addressPort f.bind + addressPort f.host)
    cf.remoteForwards
    ++ map (f: "  DynamicForward" + addressPort f) cf.dynamicForwards
    ++ mapAttrsToList (n: v: "  ${n} ${v}") cf.extraOptions);

in {
  meta.maintainers = [ maintainers.rycee ];

  options.programs.ssh = {
    enable = mkEnableOption "SSH client configuration";

    package = mkPackageOption pkgs "openssh" {
      nullable = true;
      default = null;
      extraDescription =
        "By default, the client provided by your system is used.";
    };

    forwardAgent = mkOption {
      default = false;
      type = types.bool;
      description = ''
        Whether the connection to the authentication agent (if any)
        will be forwarded to the remote machine.
      '';
    };

    addKeysToAgent = mkOption {
      type = types.str;
      default = "no";
      description = ''
        When enabled, a private key that is used during authentication will be
        added to ssh-agent if it is running (with confirmation enabled if
        set to 'confirm'). The argument must be 'no' (the default), 'yes', 'confirm'
        (optionally followed by a time interval), 'ask' or a time interval (e.g. '1h').
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

    serverAliveCountMax = mkOption {
      type = types.ints.positive;
      default = 3;
      description = ''
        Sets the default number of server alive messages which may be
        sent without SSH receiving any messages back from the server.
      '';
    };

    hashKnownHosts = mkOption {
      default = false;
      type = types.bool;
      description = ''
        Indicates that
        {manpage}`ssh(1)`
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
        {file}`~/.ssh/known_hosts`.
      '';
    };

    controlMaster = mkOption {
      default = "no";
      type = types.enum [ "yes" "no" "ask" "auto" "autoask" ];
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
      default = { };
      description = ''
        Extra SSH configuration options that take precedence over any
        host specific configuration.
      '';
    };

    includes = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        File globs of ssh config files that should be included via the
        `Include` directive.

        See
        {manpage}`ssh_config(5)`
        for more information.
      '';
    };

    matchBlocks = mkOption {
      type = hm.types.dagOf matchBlockModule;
      default = { };
      example = literalExpression ''
        {
          "john.example.com" = {
            hostname = "example.com";
            user = "john";
          };
          foo = lib.hm.dag.entryBefore ["john.example.com"] {
            hostname = "example.com";
            identityFile = "/home/john/.ssh/foo_rsa";
          };
        };
      '';
      description = ''
        Specify per-host settings. Note, if the order of rules matter
        then use the DAG functions to express the dependencies as
        shown in the example.

        See
        {manpage}`ssh_config(5)`
        for more information.
      '';
    };

    configPath = mkOption {
      type = types.path;
      internal = true;
      description = ''
        Path to the ssh configuration.
      '';
    };

    internallyManaged = mkOption {
      type = types.bool;
      default = true;
      internal = true;
      description = ''
        Whether to link .ssh/config to programs.ssh.configPath
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = let
        # `builtins.any`/`lib.lists.any` does not return `true` if there are no elements.
        any' = pred: items: if items == [ ] then true else any pred items;
        # Check that if `entry.address` is defined, and is a path, that `entry.port` has not
        # been defined.
        noPathWithPort = entry:
          entry.address != null && isPath entry.address -> entry.port == null;
        checkDynamic = block: any' noPathWithPort block.dynamicForwards;
        checkBindAndHost = fwd:
          noPathWithPort fwd.bind && noPathWithPort fwd.host;
        checkLocal = block: any' checkBindAndHost block.localForwards;
        checkRemote = block: any' checkBindAndHost block.remoteForwards;
        checkMatchBlock = block:
          all (fn: fn block) [ checkLocal checkRemote checkDynamic ];
      in any' checkMatchBlock
      (map (block: block.data) (builtins.attrValues cfg.matchBlocks));
      message = "Forwarded paths cannot have ports.";
    }];

    home.packages = optional (cfg.package != null) cfg.package;

    home.file.".ssh/config".source = mkIf cfg.internallyManaged cfg.configPath;

    programs.ssh.configPath =
      let
        sortedMatchBlocks = hm.dag.topoSort cfg.matchBlocks;
        sortedMatchBlocksStr = builtins.toJSON sortedMatchBlocks;
        matchBlocks =
          sortedMatchBlocks.result or abort "Dependency cycle in SSH match blocks: ${sortedMatchBlocksStr}";
      in pkgs.writeText "ssh_config" ''
      ${concatStringsSep "\n" (
        (mapAttrsToList (n: v: "${n} ${v}") cfg.extraOptionOverrides)
        ++ (optional (cfg.includes != [ ]) ''
          Include ${concatStringsSep " " cfg.includes}
        '') ++ (map (block: matchBlockStr block.name block.data) matchBlocks))}

      Host *
        ForwardAgent ${lib.hm.booleans.yesNo cfg.forwardAgent}
        AddKeysToAgent ${cfg.addKeysToAgent}
        Compression ${lib.hm.booleans.yesNo cfg.compression}
        ServerAliveInterval ${toString cfg.serverAliveInterval}
        ServerAliveCountMax ${toString cfg.serverAliveCountMax}
        HashKnownHosts ${lib.hm.booleans.yesNo cfg.hashKnownHosts}
        UserKnownHostsFile ${cfg.userKnownHostsFile}
        ControlMaster ${cfg.controlMaster}
        ControlPath ${cfg.controlPath}
        ControlPersist ${cfg.controlPersist}

        ${replaceStrings [ "\n" ] [ "\n  " ] cfg.extraConfig}
    '';

    warnings = mapAttrsToList (n: v: ''
      The SSH config match block `programs.ssh.matchBlocks.${n}` sets both of the host and match options.
      The match option takes precedence.'')
      (filterAttrs (n: v: v.data.host != null && v.data.match != null)
        cfg.matchBlocks);
  };
}
