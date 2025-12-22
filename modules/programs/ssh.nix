{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    literalExpression
    mapAttrsToList
    mkOption
    optional
    types
    ;

  cfg = config.programs.ssh;

  mkSshOptions =
    {
      indent ? "",
    }:
    let
      # OpenSSH is very inconsistent with options that can take multiple values.
      # For some of them, they can simply appear multiple times and are appended, for others the
      # values must be separated by whitespace or even commas.
      # Consult either ssh_config(5) or, as last resort, the OpehSSH source for parsing
      # the options at ssh.c:process_config_files() to determine the right "mode"
      # for each. But fortunately this fact is documented for most of them in the manpage.
      fixListValues =
        let
          commaSeparated = [
            "Ciphers"
            "HostbasedAcceptedAlgorithms"
            "MACs"
            "PubkeyAcceptedAlgorithms"
            # FIXME: Match?
          ];
          spaceSeparated = [
            "ChannelTimeout"
            "GlobalKnownHostsFile"
            "IPQoS"
            "PermitRemoteOpen"
            "UserKnownHostsFile"
            # FIXME: Host?
          ];
          multiLine = [
            "CertificateFile"
            "DynamicForward"
            "IdentityAgent"
            "IdentityFile"
            "LocalForward"
            "RemoteForward"
            "SendEnv" # NOTE: could be spaceSeparated instead
          ];
          transformList =
            key: val:
            if lib.isList val then
              if lib.elem key commaSeparated then
                lib.concatStringsSep "," val
              else if lib.elem key spaceSeparated then
                lib.concatStringsSep " " val
              else if lib.elem key multiLine then
                val
              else
                throw "list value for unknown key ${key}: ${(lib.generators.toPretty { }) val}"
            else
              val;
        in
        lib.mapAttrs transformList;

      removeNulls = lib.filterAttrs (_: v: v != null);

      # reports boolean as yes / no
      mkValueString =
        v:
        if lib.isInt v then
          toString v
        else if lib.isString v then
          v
        else if lib.isBool v then
          lib.hm.booleans.yesNo v
        else
          throw "unsupported type ${builtins.typeOf v}: ${(lib.generators.toPretty { }) v}";

      keyValue = lib.generators.toKeyValue {
        mkKeyValue = lib.generators.mkKeyValueDefault { inherit mkValueString; } " ";
        listsAsDuplicateKeys = true;
        inherit indent;
      };
    in
    conf: keyValue (fixListValues (removeNulls conf));

  sshConfigType =
    let
      singleAtom =
        with types;
        nullOr (oneOf [
          bool
          int
          str
        ]);
      atom =
        with types;
        (either singleAtom (listOf singleAtom))
        // {
          description = "SSH configuration atom (bool, int, string, or list there-of).";
        };
    in
    types.attrsOf atom;

  isPath = x: builtins.substring 0 1 (toString x) == "/";

  addressPort =
    entry:
    if isPath entry.address then " ${entry.address}" else " [${entry.address}]:${toString entry.port}";

  unwords = builtins.concatStringsSep " ";

  mkSetEnvStr =
    envStr:
    unwords (
      mapAttrsToList (name: value: ''${name}="${lib.escape [ ''"'' "\\" ] (toString value)}"'') envStr
    );

  mkAddressPortModule =
    {
      actionType,
      nullableAddress ? actionType == "forward",
    }:
    types.submodule {
      options = {
        address = mkOption {
          type = if nullableAddress then types.nullOr types.str else types.str;
          default = if nullableAddress then null else "localhost";
          example = "example.org";
          description = "The address to ${actionType} to.";
        };

        port = mkOption {
          type = types.nullOr types.port;
          default = null;
          example = 8080;
          description = "Specifies port number to ${actionType} to.";
        };
      };
    };

  dynamicForwardModule = mkAddressPortModule { actionType = "bind"; };

  forwardModule = types.submodule {
    options = {
      bind = mkOption {
        type = mkAddressPortModule { actionType = "bind"; };
        description = "Local port binding options";
      };
      host = mkOption {
        type = mkAddressPortModule { actionType = "forward"; };
        description = "Host port binding options";
      };
    };
  };

  matchBlockModule = types.submodule {
    # Rename options
    imports = lib.mapAttrsToList (prev: new: (lib.mkRenamedOptionModule [ prev ] [ new ])) {
      addKeysToAgent = "AddKeysToAgent";
      addressFamily = "AddressFamily";
      certificateFile = "CertificateFile";
      checkHostIP = "CheckHostIP";
      compression = "Compression";
      controlMaster = "ControlMaster";
      controlPath = "ControlPath";
      controlPersist = "ControlPersist";
      dynamicForwards = "DynamicForward";
      forwardAgent = "ForwardAgent";
      forwardX11 = "ForwardX11";
      forwardX11Trusted = "ForwardX11Trusted";
      hashKnownHosts = "HashKnownHosts";
      host = "Host";
      hostname = "Hostname";
      identitiesOnly = "IdentitiesOnly";
      identityAgent = "IdentityAgent";
      identityFile = "IdentityFile";
      kexAlgorithms = "KexAlgorithms";
      localForwards = "LocalForward";
      match = "Match";
      port = "Port";
      proxyCommand = "ProxyCommand";
      proxyJump = "ProxyJump";
      remoteForwards = "RemoteForward";
      sendEnv = "SendEnv";
      serverAliveCountMax = "ServerAliveCountMax";
      serverAliveInterval = "ServerAliveInterval";
      setEnv = "SetEnv";
      user = "User";
      userKnownHostsFile = "UserKnownHostsFile";
    };

    options = {
      Host = mkOption {
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

      Match = mkOption {
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

      Port = mkOption {
        type = types.nullOr types.port;
        default = null;
        description = "Specifies port number to connect on remote host.";
      };

      ForwardAgent = mkOption {
        default = null;
        type = types.nullOr types.bool;
        description = ''
          Whether the connection to the authentication agent (if any)
          will be forwarded to the remote machine.
        '';
      };

      ForwardX11 = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Specifies whether X11 connections will be automatically redirected
          over the secure channel and {env}`DISPLAY` set.
        '';
      };

      ForwardX11Trusted = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Specifies whether remote X11 clients will have full access to the
          original X11 display.
        '';
      };

      IdentitiesOnly = mkOption {
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

      IdentityFile = mkOption {
        type = with types; either (listOf str) (nullOr str);
        default = [ ];
        apply = p: if p == null then [ ] else lib.toList p;
        description = ''
          Specifies files from which the user identity is read.
          Identities will be tried in the given order.
        '';
      };

      IdentityAgent = mkOption {
        type = with types; either (listOf str) (nullOr str);
        default = [ ];
        apply = p: if p == null then [ ] else lib.toList p;
        description = ''
          Specifies the location of the ssh identity agent.
        '';
      };

      User = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Specifies the user to log in as.";
      };

      Hostname = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Specifies the real host name to log into.";
      };

      ServerAliveInterval = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Set timeout in seconds after which response will be requested.";
      };

      ServerAliveCountMax = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
        description = ''
          Sets the number of server alive messages which may be sent
          without SSH receiving any messages back from the server.
        '';
      };

      SendEnv = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Environment variables to send from the local host to the
          server.
        '';
      };

      SetEnv = mkOption {
        type =
          with types;
          attrsOf (oneOf [
            str
            path
            int
            float
          ]);
        default = { };
        description = ''
          Environment variables and their value to send to the server.
        '';
      };

      Compression = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          Specifies whether to use compression. Omitted from the host
          block when `null`.
        '';
      };

      CheckHostIP = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Check the host IP address in the
          {file}`known_hosts` file.
        '';
      };

      ProxyCommand = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The command to use to connect to the server.";
      };

      ProxyJump = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The proxy host to use to connect to the server.";
      };

      CertificateFile = mkOption {
        type = with types; either (listOf str) (nullOr str);
        default = [ ];
        apply = p: if p == null then [ ] else lib.toList p;
        description = ''
          Specifies files from which the user certificate is read.
        '';
      };

      AddressFamily = mkOption {
        default = null;
        type = types.nullOr (
          types.enum [
            "any"
            "inet"
            "inet6"
          ]
        );
        description = ''
          Specifies which address family to use when connecting.
        '';
      };

      LocalForward = mkOption {
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

      RemoteForward = mkOption {
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

      DynamicForward = mkOption {
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

      AddKeysToAgent = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
            When enabled, a private key that is used during authentication will be
          added to ssh-agent if it is running (with confirmation enabled if
          set to 'confirm'). The argument must be 'no' (the default), 'yes', 'confirm'
          (optionally followed by a time interval), 'ask' or a time interval (e.g. '1h').
        '';
      };

      HashKnownHosts = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
           Indicates that
           {manpage}`ssh(1)`
           should hash host names and addresses when they are added to
          the known hosts file.
        '';
      };

      UserKnownHostsFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Specifies one or more files to use for the user host key
          database, separated by whitespace. The default is
          {file}`~/.ssh/known_hosts`.
        '';
      };

      ControlMaster = mkOption {
        default = null;
        type = types.nullOr (
          types.enum [
            "yes"
            "no"
            "ask"
            "auto"
            "autoask"
          ]
        );
        description = "Configure sharing of multiple sessions over a single network connection.";
      };

      ControlPath = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Specify path to the control socket used for connection sharing.";
      };

      ControlPersist = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "10m";
        description = "Whether control socket should remain open in the background.";
      };

      KexAlgorithms = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        example = [
          "curve25519-sha256@libssh.org"
          "diffie-hellman-group-exchange-sha256"
        ];
        description = ''
          Specifies the available KEX (Key Exchange) algorithms.
        '';
      };

      # mkRemovedOptionModule does not work in submodules, so instead hide the
      # option and add a top-level assert
      # https://github.com/NixOS/nixpkgs/issues/96006
      extraOptions = mkOption {
        type = types.nullOr (types.attrsOf types.str);
        default = null;
        visible = false;
        internal = true;
      };
    };

    #    config.host = mkDefault dagName;
  };

  matchBlockStr =
    key: cf:
    concatStringsSep "\n" (
      let
        hostOrDagName = if cf.Host != null then cf.Host else key;
        matchHead = if cf.Match != null then "Match ${cf.Match}" else "Host ${hostOrDagName}";
      in
      [ "${matchHead}" ]
      ++ optional (cf.Port != null) "  Port ${toString cf.Port}"
      ++ optional (cf.ForwardAgent != null) "  ForwardAgent ${lib.hm.booleans.yesNo cf.ForwardAgent}"
      ++ optional cf.ForwardX11 "  ForwardX11 yes"
      ++ optional cf.ForwardX11Trusted "  ForwardX11Trusted yes"
      ++ optional cf.IdentitiesOnly "  IdentitiesOnly yes"
      ++ optional (cf.User != null) "  User ${cf.User}"
      ++ optional (cf.Hostname != null) "  Hostname ${cf.Hostname}"
      ++ optional (cf.AddressFamily != null) "  AddressFamily ${cf.AddressFamily}"
      ++ optional (cf.SendEnv != [ ]) "  SendEnv ${unwords cf.SendEnv}"
      ++ optional (cf.SetEnv != { }) "  SetEnv ${mkSetEnvStr cf.SetEnv}"
      ++ optional (
        cf.ServerAliveInterval != null
      ) "  ServerAliveInterval ${toString cf.ServerAliveInterval}"
      ++ optional (
        cf.ServerAliveCountMax != null
      ) "  ServerAliveCountMax ${toString cf.ServerAliveCountMax}"
      ++ optional (cf.Compression != null) "  Compression ${lib.hm.booleans.yesNo cf.Compression}"
      ++ optional (!cf.CheckHostIP) "  CheckHostIP no"
      ++ optional (cf.ProxyCommand != null) "  ProxyCommand ${cf.ProxyCommand}"
      ++ optional (cf.ProxyJump != null) "  ProxyJump ${cf.ProxyJump}"
      ++ optional (cf.AddKeysToAgent != null) "  AddKeysToAgent ${cf.AddKeysToAgent}"
      ++ optional (
        cf.HashKnownHosts != null
      ) "  HashKnownHosts ${lib.hm.booleans.yesNo cf.HashKnownHosts}"
      ++ optional (cf.UserKnownHostsFile != null) "  UserKnownHostsFile ${cf.UserKnownHostsFile}"
      ++ optional (cf.ControlMaster != null) "  ControlMaster ${cf.ControlMaster}"
      ++ optional (cf.ControlPath != null) "  ControlPath ${cf.ControlPath}"
      ++ optional (cf.ControlPersist != null) "  ControlPersist ${cf.ControlPersist}"
      ++ map (file: "  IdentityFile ${file}") cf.IdentityFile
      ++ map (file: "  IdentityAgent ${file}") cf.IdentityAgent
      ++ map (file: "  CertificateFile ${file}") cf.CertificateFile
      ++ map (f: "  LocalForward" + addressPort f.bind + addressPort f.host) cf.LocalForward
      ++ map (f: "  RemoteForward" + addressPort f.bind + addressPort f.host) cf.RemoteForward
      ++ map (f: "  DynamicForward" + addressPort f) cf.DynamicForward
      ++ optional (
        cf.KexAlgorithms != null
      ) "  KexAlgorithms ${builtins.concatStringsSep "," cf.KexAlgorithms}"
    );

in
{
  meta.maintainers = [ lib.maintainers.rycee ];

  imports =
    let
      oldPrefix = [
        "programs"
        "ssh"
      ];
      newPrefix = [
        "programs"
        "ssh"
        "matchBlocks"
        "*"
      ];
      renamedOptions = [
        "forwardAgent"
        "addKeysToAgent"
        "compression"
        "serverAliveInterval"
        "serverAliveCountMax"
        "hashKnownHosts"
        "userKnownHostsFile"
        "controlMaster"
        "controlPath"
        "controlPersist"
      ];
    in
    lib.hm.deprecations.mkSettingsRenamedOptionModules oldPrefix newPrefix {
      transform = x: x;
    } renamedOptions;

  options.programs.ssh = {
    enable = lib.mkEnableOption "SSH client configuration";

    package = lib.mkPackageOption pkgs "openssh" {
      nullable = true;
      default = null;
      extraDescription = "By default, the client provided by your system is used.";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Extra configuration.
      '';
    };

    extraOptionOverrides = mkOption {
      type = sshConfigType;
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
      type = lib.hm.types.dagOf matchBlockModule;
      default = { };
      example = literalExpression ''
        {
          "john.example.com" = {
            Hostname = "example.com";
            User = "john";
          };
          foo = lib.hm.dag.entryBefore ["john.example.com"] {
            Hostname = "example.com";
            IdentityFile = "/home/john/.ssh/foo_rsa";
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

    enableDefaultConfig = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = ''
        Whether to enable or not the old default config values.
        This option will become deprecated in the future.
        For an equivalent, copy and paste the following
        code snippet in your config:

        programs.ssh.matchBlocks."*" = {
          ForwardAgent = false;
          AddKeysToAgent = "no";
          Compression = false;
          ServerAliveInterval = 0;
          ServerAliveCountMax = 3;
          HashKnownHosts = false;
          UserKnownHostsFile = "~/.ssh/known_hosts";
          ControlMaster = "no";
          ControlPath = "~/.ssh/master-%r@%n:%p";
          ControlPersist = "no";
        };
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion =
              let
                # `builtins.any`/`lib.lists.any` does not return `true` if there are no elements.
                any' = pred: items: if items == [ ] then true else lib.any pred items;
                # Check that if `entry.address` is defined, and is a path, that `entry.port` has not
                # been defined.
                noPathWithPort = entry: entry.address != null && isPath entry.address -> entry.port == null;
                checkDynamic = block: any' noPathWithPort block.DynamicForward;
                checkBindAndHost = fwd: noPathWithPort fwd.bind && noPathWithPort fwd.host;
                checkLocal = block: any' checkBindAndHost block.LocalForward;
                checkRemote = block: any' checkBindAndHost block.RemoteForward;
                checkMatchBlock =
                  block:
                  lib.all (fn: fn block) [
                    checkLocal
                    checkRemote
                    checkDynamic
                  ];
              in
              any' checkMatchBlock (map (block: block.data) (builtins.attrValues cfg.matchBlocks));
            message = "Forwarded paths cannot have ports.";
          }
          {
            assertion = (cfg.extraConfig != "") -> (cfg.matchBlocks ? "*");
            message = ''Cannot set `programs.ssh.extraConfig` if `programs.ssh.matchBlocks."*"` (default host config) is not declared.'';
          }
        ]
        ++ (lib.flip mapAttrsToList cfg.matchBlocks (
          n: v: {
            assertion = v.data.extraOptions == null;
            message = ''
              `programs.ssh.matchBlocks.${n}` sets `extraOptions`, which has
              been removed.
            '';
          }
        ));

        home.packages = optional (cfg.package != null) cfg.package;

        home.file.".ssh/config".text =
          let
            sortedMatchBlocks = lib.hm.dag.topoSort (lib.removeAttrs cfg.matchBlocks [ "*" ]);
            sortedMatchBlocksStr = builtins.toJSON sortedMatchBlocks;
            matchBlocks =
              if sortedMatchBlocks ? result then
                sortedMatchBlocks.result
              else
                abort "Dependency cycle in SSH match blocks: ${sortedMatchBlocksStr}";

            defaultHostBlock = cfg.matchBlocks."*" or null;
          in
          ''
            ${concatStringsSep "\n" (
              [ (mkSshOptions { } cfg.extraOptionOverrides) ]
              ++ (optional (cfg.includes != [ ]) ''
                Include ${concatStringsSep " " cfg.includes}
              '')
              ++ (map (block: matchBlockStr block.name block.data) matchBlocks)
            )}

            ${if (defaultHostBlock != null) then (matchBlockStr "*" defaultHostBlock.data) else ""}
              ${lib.replaceStrings [ "\n" ] [ "\n  " ] cfg.extraConfig}
          '';

        warnings =
          mapAttrsToList
            (n: v: ''
              The SSH config match block `programs.ssh.matchBlocks.${n}` sets both of the host and match options.
              The match option takes precedence.'')
            (lib.filterAttrs (n: v: v.data.Host != null && v.data.Match != null) cfg.matchBlocks);
      }
      (lib.mkIf cfg.enableDefaultConfig {
        warnings = [
          ''
            `programs.ssh` default values will be removed in the future.
            Consider setting `programs.ssh.enableDefaultConfig` to false,
            and manually set the default values you want to keep at
            `programs.ssh.matchBlocks."*"`.
          ''
        ];

        programs.ssh.matchBlocks."*" = {
          ForwardAgent = lib.mkDefault false;
          AddKeysToAgent = lib.mkDefault "no";
          Compression = lib.mkDefault false;
          ServerAliveInterval = lib.mkDefault 0;
          ServerAliveCountMax = lib.mkDefault 3;
          HashKnownHosts = lib.mkDefault false;
          UserKnownHostsFile = lib.mkDefault "~/.ssh/known_hosts";
          ControlMaster = lib.mkDefault "no";
          ControlPath = lib.mkDefault "~/.ssh/master-%r@%n:%p";
          ControlPersist = lib.mkDefault "no";
        };
      })
    ]
  );
}
