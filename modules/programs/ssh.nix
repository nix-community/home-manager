{
  config,
  lib,
  options,
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
    optionalString
    types
    ;

  cfg = config.programs.ssh;

  isPath = x: builtins.substring 0 1 (toString x) == "/";

  addressPort =
    entry:
    let
      address = entry.address or "localhost";
      port = entry.port or null;
    in
    (lib.findFirst (candidate: candidate.when)
      {
        out = " [${address}]:${toString port}";
      }
      [
        {
          when = address == null;
          out = " ${toString port}";
        }
        {
          when = address != null && isPath address;
          out = " ${address}";
        }
      ]
    ).out;

  mkSetEnvStr =
    envStr:
    builtins.concatStringsSep " " (
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
        type = types.nullOr types.bool;
        default = null;
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
        apply = p: if p == null then [ ] else lib.toList p;
        description = ''
          Specifies files from which the user identity is read.
          Identities will be tried in the given order.
        '';
      };

      identityAgent = mkOption {
        type = with types; either (listOf str) (nullOr str);
        default = [ ];
        apply = p: if p == null then [ ] else lib.toList p;
        description = ''
          Specifies the location of the ssh identity agent.
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
        type = types.nullOr types.int;
        default = null;
        description = "Set timeout in seconds after which response will be requested.";
      };

      serverAliveCountMax = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
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
        apply = p: if p == null then [ ] else lib.toList p;
        description = ''
          Specifies files from which the user certificate is read.
        '';
      };

      addressFamily = mkOption {
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
        visible = false;
        description = ''
          Deprecated extra configuration options for this host. Use
          {option}`programs.ssh.settings` instead.
        '';
      };

      addKeysToAgent = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
            When enabled, a private key that is used during authentication will be
          added to ssh-agent if it is running (with confirmation enabled if
          set to 'confirm'). The argument must be 'no' (the default), 'yes', 'confirm'
          (optionally followed by a time interval), 'ask' or a time interval (e.g. '1h').
        '';
      };

      hashKnownHosts = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
           Indicates that
           {manpage}`ssh(1)`
           should hash host names and addresses when they are added to
          the known hosts file.
        '';
      };

      userKnownHostsFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Specifies one or more files to use for the user host key
          database, separated by whitespace. The default is
          {file}`~/.ssh/known_hosts`.
        '';
      };

      controlMaster = mkOption {
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

      controlPath = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Specify path to the control socket used for connection sharing.";
      };

      controlPersist = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "10m";
        description = "Whether control socket should remain open in the background.";
      };

      kexAlgorithms = mkOption {
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
    };

    #    config.host = mkDefault dagName;
  };

  renderValue = value: if lib.isBool value then lib.hm.booleans.yesNo value else toString value;

  renderValues = sep: values: concatStringsSep sep (map renderValue (lib.toList values));

  renderForward =
    f: if lib.isAttrs f then addressPort f.bind + addressPort f.host else " ${renderValue f}";

  renderDynamicForward = f: if lib.isAttrs f then addressPort f else " ${renderValue f}";

  renderDuplicateDirective =
    indent: name: renderItem: values:
    concatStringsSep "\n" (map (value: "${indent}${name}${renderItem value}") (lib.toList values));

  # Per ssh_config(5), the first obtained value for most parameters wins.
  # These directives take comma/space-separated lists, so rendering Nix lists as
  # duplicate directives can silently ignore values after the first line.
  # Reference: https://man.openbsd.org/ssh_config
  commaListDirectives = [
    "CASignatureAlgorithms"
    "Ciphers"
    "HostbasedAcceptedAlgorithms"
    "HostbasedKeyTypes"
    "HostKeyAlgorithms"
    "IgnoreUnknown"
    "KbdInteractiveDevices"
    "KexAlgorithms"
    "MACs"
    "PreferredAuthentications"
    "ProxyJump"
    "PubkeyAcceptedAlgorithms"
    "PubkeyAcceptedKeyTypes"
  ];

  spaceListDirectives = [
    "CanonicalDomains"
    "CanonicalizePermittedCNAMEs"
    "ChannelTimeout"
    "GlobalKnownHostsFile"
    "PermitRemoteOpen"
    "SendEnv"
    "UserKnownHostsFile"
  ];

  directiveRenderers =
    indent:
    lib.genAttrs commaListDirectives (name: value: "${indent}${name} ${renderValues "," value}")
    // lib.genAttrs spaceListDirectives (name: value: "${indent}${name} ${renderValues " " value}")
    // {
      SetEnv = value: "${indent}SetEnv ${mkSetEnvStr value}";
      LocalForward = renderDuplicateDirective indent "LocalForward" renderForward;
      RemoteForward = renderDuplicateDirective indent "RemoteForward" renderForward;
      DynamicForward = renderDuplicateDirective indent "DynamicForward" renderDynamicForward;
    };

  sshDirectiveStrWithIndent =
    indent: name: value:
    let
      renderDirective =
        (directiveRenderers indent).${name}
          or (values: renderDuplicateDirective indent name (v: " ${renderValue v}") values);
    in
    optionalString (value != null && value != [ ] && value != { }) (renderDirective value);

  sshDirectiveStr = sshDirectiveStrWithIndent "  ";

  blockHeader =
    name:
    let
      isLiteralHeader = lib.any (prefix: lib.hasPrefix prefix name) [
        "Host "
        "Match "
      ];
    in
    optionalString (!isLiteralHeader) "Host " + name;

  matchBlockStr =
    _key: cf:
    let
      inherit (cf) header;
      extraOptions = cf.__hmSshBlockExtraOptions or { };
      settings = lib.removeAttrs cf [
        "header"
        "__hmSshBlockExtraOptions"
        "extraOptions"
      ];
      orderedNames =
        # IgnoreUnknown only applies to unknown options that appear after it.
        optional (builtins.hasAttr "IgnoreUnknown" settings) "IgnoreUnknown"
        ++ builtins.filter (name: name != "IgnoreUnknown") (lib.attrNames settings);
    in
    concatStringsSep "\n" (
      [ header ]
      ++ lib.filter (line: line != "") (map (name: sshDirectiveStr name settings.${name}) orderedNames)
      ++ optional (extraOptions != { }) (
        lib.generators.toKeyValue {
          mkKeyValue = lib.generators.mkKeyValueDefault { } " ";
          listsAsDuplicateKeys = true;
          indent = "  ";
        } extraOptions
      )
    );

  legacyBlockSettings =
    cf:
    let
      headers =
        optional (cf.match != null) "Match ${cf.match}" ++ optional (cf.host != null) "Host ${cf.host}";
    in
    lib.filterAttrs (_: v: v != null && v != [ ] && v != { }) {
      header = lib.head (headers ++ [ null ]);
      Port = cf.port;
      ForwardAgent = cf.forwardAgent;
      ForwardX11 = if cf.forwardX11 then true else null;
      ForwardX11Trusted = if cf.forwardX11Trusted then true else null;
      IdentitiesOnly = cf.identitiesOnly;
      IdentityFile = cf.identityFile;
      IdentityAgent = cf.identityAgent;
      User = cf.user;
      HostName = cf.hostname;
      ServerAliveInterval = cf.serverAliveInterval;
      ServerAliveCountMax = cf.serverAliveCountMax;
      SendEnv = cf.sendEnv;
      SetEnv = cf.setEnv;
      Compression = cf.compression;
      CheckHostIP = if cf.checkHostIP then null else false;
      ProxyCommand = cf.proxyCommand;
      ProxyJump = cf.proxyJump;
      CertificateFile = cf.certificateFile;
      AddressFamily = cf.addressFamily;
      LocalForward = cf.localForwards;
      RemoteForward = cf.remoteForwards;
      DynamicForward = cf.dynamicForwards;
      AddKeysToAgent = cf.addKeysToAgent;
      HashKnownHosts = cf.hashKnownHosts;
      UserKnownHostsFile = cf.userKnownHostsFile;
      ControlMaster = cf.controlMaster;
      ControlPath = cf.controlPath;
      ControlPersist = cf.controlPersist;
      KexAlgorithms = cf.kexAlgorithms;
      __hmSshBlockExtraOptions = cf.extraOptions;
    };

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
        "settings"
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
      oldOptionNameToSetting = {
        forwardAgent = "ForwardAgent";
        addKeysToAgent = "AddKeysToAgent";
        compression = "Compression";
        serverAliveInterval = "ServerAliveInterval";
        serverAliveCountMax = "ServerAliveCountMax";
        hashKnownHosts = "HashKnownHosts";
        userKnownHostsFile = "UserKnownHostsFile";
        controlMaster = "ControlMaster";
        controlPath = "ControlPath";
        controlPersist = "ControlPersist";
      };
    in
    lib.hm.deprecations.mkSettingsRenamedOptionModules oldPrefix newPrefix {
      transform = x: oldOptionNameToSetting.${x};
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
      type = types.attrsOf types.anything;
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

    settings = mkOption {
      type = lib.hm.types.dagOf (
        types.submodule (
          { dagName, ... }:
          {
            freeformType = types.attrsOf types.anything;
            options.header = mkOption {
              type = types.str;
              default = blockHeader dagName;
              defaultText = lib.literalMD ''
                The attribute name, prefixed with `Host ` unless it already
                starts with `Host ` or `Match `.
              '';
              description = ''
                The literal `Host` or `Match` line that opens this block.
                Set this when the header cannot be expressed as the
                attribute name, e.g. when it carries Nix string context
                (store paths) or when a stable attribute name is wanted
                for {option}`lib.hm.dag` ordering.
              '';
            };
          }
        )
      );
      default = { };
      example = literalExpression ''
        {
          "github.com" = {
            HostName = "github.com";
            User = "git";
            IdentityFile = "~/.ssh/github";
          };

          "Host *.example.org" = lib.hm.dag.entryBefore [ "github.com" ] {
            IdentityFile = "~/.ssh/example";
            LocalForward = [
              {
                bind.port = 8080;
                host.address = "10.0.0.13";
                host.port = 80;
              }
              "9000 10.0.0.2:90"
            ];
            DynamicForward = "127.0.0.1:1080";
          };

          "Match host *.corp exec \"test -f ~/.corp\"" = {
            ProxyJump = "bastion";
            RemoteForward = {
              bind.port = 8081;
              host.address = "10.0.0.14";
              host.port = 80;
            };
          };
        }
      '';
      description = ''
        OpenSSH client configuration blocks written to
        {file}`~/.ssh/config`.

        Attribute names are interpreted as `Host` patterns unless they
        start with `Host ` or `Match `, in which case they are written
        literally as block headers. If the order of rules matter then
        use the DAG functions to express the dependencies as shown in
        the example.

        See
        {manpage}`ssh_config(5)`
        for more information.
      '';
    };

    matchBlocks = mkOption {
      type = lib.hm.types.dagOf matchBlockModule;
      default = { };
      visible = false;
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
        Deprecated alias for {option}`programs.ssh.settings`.
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

        ```nix
        programs.ssh.settings."*" = {
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
        ```
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        programs.ssh.settings = lib.mapAttrs (
          _name: entry:
          entry
          // {
            data = legacyBlockSettings entry.data;
          }
        ) cfg.matchBlocks;

        assertions = [
          {
            assertion =
              let
                # Check that if `entry.address` is defined, and is a path, that `entry.port` has not
                # been defined.
                noPathWithPort =
                  entry:
                  let
                    address = entry.address or null;
                    port = entry.port or null;
                  in
                  address != null && isPath address -> port == null;
                checkForwardValues = pred: values: lib.all pred (lib.filter lib.isAttrs (lib.toList values));
                checkDynamic = block: checkForwardValues noPathWithPort (block.DynamicForward or [ ]);
                checkBindAndHost = fwd: noPathWithPort fwd.bind && noPathWithPort fwd.host;
                checkLocal = block: checkForwardValues checkBindAndHost (block.LocalForward or [ ]);
                checkRemote = block: checkForwardValues checkBindAndHost (block.RemoteForward or [ ]);
                checkMatchBlock =
                  block:
                  lib.all (fn: fn block) [
                    checkLocal
                    checkRemote
                    checkDynamic
                  ];
              in
              lib.all checkMatchBlock (map (block: block.data) (builtins.attrValues cfg.settings));
            message = "Forwarded paths cannot have ports.";
          }
          {
            assertion = (cfg.extraConfig != "") -> (cfg.settings ? "*");
            message = ''Cannot set `programs.ssh.extraConfig` if `programs.ssh.settings."*"` (default host config) is not declared.'';
          }
          {
            assertion = lib.all (
              block: !(builtins.hasAttr "extraOptions" block.data) || block.data.extraOptions == { }
            ) (builtins.attrValues cfg.settings);
            message = ''
              `programs.ssh.settings.*.extraOptions` defined in ${lib.showFiles options.programs.ssh.settings.files} is not supported. Move these OpenSSH options directly into `programs.ssh.settings.*` using upstream directive names.
            '';
          }
        ];

        home.packages = optional (cfg.package != null) cfg.package;

        home.file.".ssh/config".text =
          let
            sortedMatchBlocks = lib.hm.dag.topoSort (lib.removeAttrs cfg.settings [ "*" ]);
            sortedMatchBlocksStr = builtins.toJSON sortedMatchBlocks;
            matchBlocks =
              sortedMatchBlocks.result or (abort "Dependency cycle in SSH match blocks: ${sortedMatchBlocksStr}");

            defaultHostBlock = cfg.settings."*" or null;
            globalConfig =
              (mapAttrsToList (sshDirectiveStrWithIndent "") cfg.extraOptionOverrides)
              ++ optional (cfg.includes != [ ]) "Include ${concatStringsSep " " cfg.includes}";
            blockConfig =
              (map (block: matchBlockStr block.name block.data) matchBlocks)
              ++ optional (defaultHostBlock != null) (matchBlockStr "*" defaultHostBlock.data);
            extraConfig = optional (cfg.extraConfig != "") (
              "  " + lib.replaceStrings [ "\n" ] [ "\n  " ] (lib.removeSuffix "\n" cfg.extraConfig)
            );
            sections =
              optional (globalConfig != [ ]) (concatStringsSep "\n" globalConfig) ++ blockConfig ++ extraConfig;
          in
          optionalString (sections != [ ]) (concatStringsSep "\n\n" sections + "\n");

        warnings =
          optional (cfg.matchBlocks != { }) ''
            `programs.ssh.matchBlocks` defined in ${lib.showFiles options.programs.ssh.matchBlocks.files} is deprecated. Use `programs.ssh.settings`.
          ''
          ++
            mapAttrsToList
              (n: _v: ''
                The SSH config match block `programs.ssh.matchBlocks.${n}` sets both of the host and match options.
                The match option takes precedence.'')
              (lib.filterAttrs (_n: v: v.data.host != null && v.data.match != null) cfg.matchBlocks)
          ++ mapAttrsToList (n: _v: ''
            `programs.ssh.matchBlocks.${n}.extraOptions` defined in ${lib.showFiles options.programs.ssh.matchBlocks.files} is deprecated. Move these OpenSSH options to `programs.ssh.settings.${n}` using upstream directive names.
          '') (lib.filterAttrs (_n: v: v.data.extraOptions != { }) cfg.matchBlocks);
      }
      (lib.mkIf cfg.enableDefaultConfig {
        warnings = [
          ''
            `programs.ssh` default values will be removed in the future.
            Consider setting `programs.ssh.enableDefaultConfig` to false,
            and manually set the default values you want to keep at
            `programs.ssh.settings."*"`.
          ''
        ];

        programs.ssh.settings."*" = {
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
