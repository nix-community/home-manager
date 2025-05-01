{
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkOption
    optional
    optionalString
    types
    ;

  cfg = config.services.gpg-agent;
  gpgPkg = config.programs.gpg.package;

  homedir = config.programs.gpg.homedir;

  gpgSshSupportStr = ''
    ${gpgPkg}/bin/gpg-connect-agent updatestartuptty /bye > /dev/null
  '';

  gpgInitStr =
    ''
      GPG_TTY="$(tty)"
      export GPG_TTY
    ''
    + optionalString cfg.enableSshSupport gpgSshSupportStr;

  gpgZshInitStr =
    ''
      export GPG_TTY=$TTY
    ''
    + optionalString cfg.enableSshSupport gpgSshSupportStr;

  gpgFishInitStr =
    ''
      set -gx GPG_TTY (tty)
    ''
    + optionalString cfg.enableSshSupport gpgSshSupportStr;

  gpgNushellInitStr =
    ''
      $env.GPG_TTY = (tty)
    ''
    + optionalString cfg.enableSshSupport ''
      ${gpgPkg}/bin/gpg-connect-agent updatestartuptty /bye | ignore

      $env.SSH_AUTH_SOCK = ($env.SSH_AUTH_SOCK? | default (${gpgPkg}/bin/gpgconf --list-dirs agent-ssh-socket))
    '';

  # mimic `gpgconf` output for use in the service definitions.
  # we cannot use `gpgconf` directly because it heavily depends on system
  # state, but we need the values at build time. original:
  # https://github.com/gpg/gnupg/blob/c6702d77d936b3e9d91b34d8fdee9599ab94ee1b/common/homedir.c#L672-L681
  gpgconf =
    dir:
    let
      hash = lib.substring 0 24 (hexStringToBase32 (builtins.hashString "sha1" homedir));
      subdir = if homedir == options.programs.gpg.homedir.default then "${dir}" else "d.${hash}/${dir}";
    in
    if pkgs.stdenv.isDarwin then
      "/private/var/run/org.nix-community.home.gpg-agent/${subdir}"
    else
      "%t/gnupg/${subdir}";

  # Act like `xxd -r -p | base32` but with z-base-32 alphabet and no trailing padding.
  # Written in Nix for purity.
  hexStringToBase32 =
    let
      mod = a: b: a - a / b * b;
      pow2 = lib.elemAt [
        1
        2
        4
        8
        16
        32
        64
        128
        256
      ];

      base32Alphabet = lib.stringToCharacters "ybndrfg8ejkmcpqxot1uwisza345h769";
      hexToIntTable = lib.listToAttrs (
        lib.genList (x: {
          name = lib.toLower (lib.toHexString x);
          value = x;
        }) 16
      );

      initState = {
        ret = "";
        buf = 0;
        bufBits = 0;
      };
      go =
        {
          ret,
          buf,
          bufBits,
        }:
        hex:
        let
          buf' = buf * pow2 4 + hexToIntTable.${hex};
          bufBits' = bufBits + 4;
          extraBits = bufBits' - 5;
        in
        if bufBits >= 5 then
          {
            ret = ret + lib.elemAt base32Alphabet (buf' / pow2 extraBits);
            buf = mod buf' (pow2 extraBits);
            bufBits = bufBits' - 5;
          }
        else
          {
            ret = ret;
            buf = buf';
            bufBits = bufBits';
          };
    in
    hexString: (lib.foldl' go initState (lib.stringToCharacters hexString)).ret;

  # Systemd socket unit generator.
  mkSocket =
    {
      desc,
      docs,
      stream,
      fdName,
    }:
    {
      Unit = {
        Description = desc;
        Documentation = docs;
      };

      Socket = {
        ListenStream = gpgconf "${stream}";
        FileDescriptorName = "${fdName}";
        Service = "gpg-agent.service";
        SocketMode = "0600";
        DirectoryMode = "0700";
      };

      Install = {
        WantedBy = [ "sockets.target" ];
      };
    };

  # Launchd agent socket generator.
  mkAgentSock = name: {
    SockType = "stream";
    SockPathName = gpgconf name;
    SockPathMode = 384; # Property lists don't support octal literals (0600 = 384).
  };

in
{
  meta.maintainers = [ lib.maintainers.rycee ];

  imports = [
    (lib.mkRemovedOptionModule [
      "services"
      "gpg-agent"
      "pinentryFlavor"
    ] "Use services.gpg-agent.pinentryPackage instead")

    (lib.mkRenamedOptionModule
      [
        "services"
        "gpg-agent"
        "pinentryPackage"
      ]
      [
        "services"
        "gpg-agent"
        "pinentry"
        "package"
      ]
    )
  ];

  options = {
    services.gpg-agent = {
      enable = lib.mkEnableOption "GnuPG private key agent";

      defaultCacheTtl = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = ''
          Set the time a cache entry is valid to the given number of
          seconds.
        '';
      };

      defaultCacheTtlSsh = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = ''
          Set the time a cache entry used for SSH keys is valid to the
          given number of seconds.
        '';
      };

      maxCacheTtl = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = ''
          Set the maximum time a cache entry is valid to n seconds. After this
          time a cache entry will be expired even if it has been accessed
          recently or has been set using gpg-preset-passphrase. The default is
          2 hours (7200 seconds).
        '';
      };

      maxCacheTtlSsh = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = ''
          Set the maximum time a cache entry used for SSH keys is valid to n
          seconds. After this time a cache entry will be expired even if it has
          been accessed recently or has been set using gpg-preset-passphrase.
          The default is 2 hours (7200 seconds).
        '';
      };

      enableSshSupport = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to use the GnuPG key agent for SSH keys.
        '';
      };

      sshKeys = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        description = ''
          Which GPG keys (by keygrip) to expose as SSH keys.
        '';
      };

      enableExtraSocket = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable extra socket of the GnuPG key agent (useful for GPG
          Agent forwarding).
        '';
      };

      verbose = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to produce verbose output.
        '';
      };

      grabKeyboardAndMouse = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Tell the pinentry to grab the keyboard and mouse. This
          option should in general be used to avoid X-sniffing
          attacks. When disabled, this option passes
          {option}`no-grab` setting to gpg-agent.
        '';
      };

      enableScDaemon = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Make use of the scdaemon tool. This option has the effect of
          enabling the ability to do smartcard operations. When
          disabled, this option passes
          {option}`disable-scdaemon` setting to gpg-agent.
        '';
      };

      noAllowExternalCache = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Tell Pinentry not to enable features which use an external cache for
          passphrases.

          Some desktop environments prefer to unlock all credentials with one
          master password and may have installed a Pinentry which employs an
          additional external cache to implement such a policy. By using this
          option the Pinentry is advised not to make use of such a cache and
          instead always ask the user for the requested passphrase.
        '';
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        example = ''
          allow-emacs-pinentry
          allow-loopback-pinentry
        '';
        description = ''
          Extra configuration lines to append to the gpg-agent
          configuration file.
        '';
      };

      pinentry = {
        package = lib.mkPackageOption pkgs "pinentry-gnome3" {
          nullable = true;
          default = null;
          extraDescription = ''
            Which pinentry interface to use. If not `null`, it sets
            {option}`pinentry-program` in {file}`gpg-agent.conf`. Beware that
            `pinentry-gnome3` may not work on non-GNOME systems. You can fix it by
            adding the following to your configuration:
            ```nix
            home.packages = [ pkgs.gcr ];
            ```
          '';
        };

        program = lib.mkOption {
          type = types.nullOr types.str;
          example = "pinentry-wayprompt";
          description = ''
            Which program to search for in the configured `pinentry.package`.
          '';
        };
      };

      enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };

      enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };

      enableNushellIntegration = lib.hm.shell.mkNushellIntegrationOption { inherit config; };

      enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };
    };
  };

  config = mkIf cfg.enable (
    lib.mkMerge [
      {
        # Grab the default binary name and fallback to expected value if `meta.mainProgram` not set
        services.gpg-agent.pinentry.program = lib.mkOptionDefault (
          cfg.pinentry.package.meta.mainProgram or "pinentry"
        );

        home.file."${homedir}/gpg-agent.conf".text = lib.concatStringsSep "\n" (
          optional (cfg.enableSshSupport) "enable-ssh-support"
          ++ optional cfg.grabKeyboardAndMouse "grab"
          ++ optional (!cfg.enableScDaemon) "disable-scdaemon"
          ++ optional (cfg.noAllowExternalCache) "no-allow-external-cache"
          ++ optional (cfg.defaultCacheTtl != null) "default-cache-ttl ${toString cfg.defaultCacheTtl}"
          ++ optional (
            cfg.defaultCacheTtlSsh != null
          ) "default-cache-ttl-ssh ${toString cfg.defaultCacheTtlSsh}"
          ++ optional (cfg.maxCacheTtl != null) "max-cache-ttl ${toString cfg.maxCacheTtl}"
          ++ optional (cfg.maxCacheTtlSsh != null) "max-cache-ttl-ssh ${toString cfg.maxCacheTtlSsh}"
          ++ optional (
            cfg.pinentry.package != null
          ) "pinentry-program ${lib.getExe' cfg.pinentry.package cfg.pinentry.program}"
          ++ [ cfg.extraConfig ]
        );

        home.sessionVariablesExtra = optionalString cfg.enableSshSupport ''
          if [ -z "$SSH_AUTH_SOCK" ]; then
            export SSH_AUTH_SOCK="$(${gpgPkg}/bin/gpgconf --list-dirs agent-ssh-socket)"
          fi
        '';

        programs.bash.initExtra = mkIf cfg.enableBashIntegration gpgInitStr;
        programs.zsh.initContent = mkIf cfg.enableZshIntegration gpgZshInitStr;
        programs.fish.interactiveShellInit = mkIf cfg.enableFishIntegration gpgFishInitStr;

        programs.nushell.extraEnv = mkIf cfg.enableNushellIntegration gpgNushellInitStr;
      }

      (mkIf (cfg.sshKeys != null) {
        # Trailing newlines are important
        home.file."${homedir}/sshcontrol".text = lib.concatMapStrings (s: ''
          ${s}
        '') cfg.sshKeys;
      })

      (lib.mkMerge [
        (mkIf pkgs.stdenv.isLinux {
          systemd.user.services.gpg-agent = {
            Unit = {
              Description = "GnuPG cryptographic agent and passphrase cache";
              Documentation = "man:gpg-agent(1)";
              Requires = "gpg-agent.socket";
              After = "gpg-agent.socket";
              # This is a socket-activated service:
              RefuseManualStart = true;
            };

            Service = {
              ExecStart = "${gpgPkg}/bin/gpg-agent --supervised" + optionalString cfg.verbose " --verbose";
              ExecReload = "${gpgPkg}/bin/gpgconf --reload gpg-agent";
              Environment = [ "GNUPGHOME=${homedir}" ];
            };
          };

          systemd.user.sockets.gpg-agent = mkSocket {
            desc = "GnuPG cryptographic agent and passphrase cache";
            docs = "man:gpg-agent(1)";
            stream = "S.gpg-agent";
            fdName = "std";
          };

          systemd.user.sockets.gpg-agent-ssh = mkIf cfg.enableSshSupport (mkSocket {
            desc = "GnuPG cryptographic agent (ssh-agent emulation)";
            docs = "man:gpg-agent(1) man:ssh-add(1) man:ssh-agent(1) man:ssh(1)";
            stream = "S.gpg-agent.ssh";
            fdName = "ssh";
          });

          systemd.user.sockets.gpg-agent-extra = mkIf cfg.enableExtraSocket (mkSocket {
            desc = "GnuPG cryptographic agent and passphrase cache (restricted)";
            docs = "man:gpg-agent(1) man:ssh(1)";
            stream = "S.gpg-agent.extra";
            fdName = "extra";
          });
        })

        (mkIf pkgs.stdenv.isDarwin {
          launchd.agents.gpg-agent = {
            enable = true;
            config = {
              ProgramArguments = [
                "${gpgPkg}/bin/gpg-agent"
                "--supervised"
              ] ++ optional cfg.verbose "--verbose";
              EnvironmentVariables = {
                GNUPGHOME = homedir;
              };
              KeepAlive = {
                Crashed = true;
                SuccessfulExit = false;
              };
              ProcessType = "Background";
              RunAtLoad = cfg.enableSshSupport;
              Sockets = {
                Agent = mkAgentSock "S.gpg-agent";
                Ssh = mkIf cfg.enableSshSupport (mkAgentSock "S.gpg-agent.ssh");
                Extra = mkIf cfg.enableExtraSocket (mkAgentSock "S.gpg-agent.extra");
              };
            };
          };
        })
      ])
    ]
  );
}
