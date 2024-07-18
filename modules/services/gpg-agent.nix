{ config, options, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.gpg-agent;
  gpgPkg = config.programs.gpg.package;

  homedir = config.programs.gpg.homedir;

  gpgSshSupportStr = ''
    ${gpgPkg}/bin/gpg-connect-agent updatestartuptty /bye > /dev/null
  '';

  gpgInitStr = ''
    GPG_TTY="$(tty)"
    export GPG_TTY
  '' + optionalString cfg.enableSshSupport gpgSshSupportStr;

  gpgFishInitStr = ''
    set -gx GPG_TTY (tty)
  '' + optionalString cfg.enableSshSupport gpgSshSupportStr;

  gpgNushellInitStr = ''
    $env.GPG_TTY = (tty)
  '' + optionalString cfg.enableSshSupport ''
    ${gpgPkg}/bin/gpg-connect-agent updatestartuptty /bye | ignore

    $env.SSH_AUTH_SOCK = ($env.SSH_AUTH_SOCK? | default (${gpgPkg}/bin/gpgconf --list-dirs agent-ssh-socket))
  '';

  # mimic `gpgconf` output for use in `systemd` unit definitions.
  # we cannot use `gpgconf` directly because it heavily depends on system
  # state, but we need the values at build time. original:
  # https://github.com/gpg/gnupg/blob/c6702d77d936b3e9d91b34d8fdee9599ab94ee1b/common/homedir.c#L672-L681
  gpgconf = dir:
    let
      hash =
        substring 0 24 (hexStringToBase32 (builtins.hashString "sha1" homedir));
    in if homedir == options.programs.gpg.homedir.default then
      "%t/gnupg/${dir}"
    else
      "%t/gnupg/d.${hash}/${dir}";

  # Act like `xxd -r -p | base32` but with z-base-32 alphabet and no trailing padding.
  # Written in Nix for purity.
  hexStringToBase32 = let
    mod = a: b: a - a / b * b;
    pow2 = elemAt [ 1 2 4 8 16 32 64 128 256 ];

    base32Alphabet = stringToCharacters "ybndrfg8ejkmcpqxot1uwisza345h769";
    hexToIntTable = listToAttrs (genList (x: {
      name = toLower (toHexString x);
      value = x;
    }) 16);

    initState = {
      ret = "";
      buf = 0;
      bufBits = 0;
    };
    go = { ret, buf, bufBits }:
      hex:
      let
        buf' = buf * pow2 4 + hexToIntTable.${hex};
        bufBits' = bufBits + 4;
        extraBits = bufBits' - 5;
      in if bufBits >= 5 then {
        ret = ret + elemAt base32Alphabet (buf' / pow2 extraBits);
        buf = mod buf' (pow2 extraBits);
        bufBits = bufBits' - 5;
      } else {
        ret = ret;
        buf = buf';
        bufBits = bufBits';
      };
  in hexString: (foldl' go initState (stringToCharacters hexString)).ret;

in {
  meta.maintainers = [ maintainers.rycee ];

  imports = [
    (mkRemovedOptionModule [ "services" "gpg-agent" "pinentryFlavor" ]
      "Use services.gpg-agent.pinentryPackage instead")
  ];

  options = {
    services.gpg-agent = {
      enable = mkEnableOption "GnuPG private key agent";

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
      pinentryPackage = mkOption {
        type = types.nullOr types.package;
        example = literalExpression "pkgs.pinentry-gnome3";
        default = null;
        description = ''
          Which pinentry interface to use. If not
          `null`, it sets
          {option}`pinentry-program` in
          {file}`gpg-agent.conf`. Beware that
          `pinentry-gnome3` may not work on non-Gnome
          systems. You can fix it by adding the following to your
          system configuration:
          ```nix
          services.dbus.packages = [ pkgs.gcr ];
          ```
        '';
      };

      enableBashIntegration = mkEnableOption "Bash integration" // {
        default = true;
      };

      enableZshIntegration = mkEnableOption "Zsh integration" // {
        default = true;
      };

      enableFishIntegration = mkEnableOption "Fish integration" // {
        default = true;
      };

      enableNushellIntegration = mkEnableOption "Nushell integration" // {
        default = true;
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.file."${homedir}/gpg-agent.conf".text = concatStringsSep "\n"
        (optional (cfg.enableSshSupport) "enable-ssh-support"
          ++ optional cfg.grabKeyboardAndMouse "grab"
          ++ optional (!cfg.enableScDaemon) "disable-scdaemon"
          ++ optional (cfg.defaultCacheTtl != null)
          "default-cache-ttl ${toString cfg.defaultCacheTtl}"
          ++ optional (cfg.defaultCacheTtlSsh != null)
          "default-cache-ttl-ssh ${toString cfg.defaultCacheTtlSsh}"
          ++ optional (cfg.maxCacheTtl != null)
          "max-cache-ttl ${toString cfg.maxCacheTtl}"
          ++ optional (cfg.maxCacheTtlSsh != null)
          "max-cache-ttl-ssh ${toString cfg.maxCacheTtlSsh}"
          ++ optional (cfg.pinentryPackage != null)
          "pinentry-program ${lib.getExe cfg.pinentryPackage}"
          ++ [ cfg.extraConfig ]);

      home.sessionVariablesExtra = optionalString cfg.enableSshSupport ''
        if [[ -z "$SSH_AUTH_SOCK" ]]; then
          export SSH_AUTH_SOCK="$(${gpgPkg}/bin/gpgconf --list-dirs agent-ssh-socket)"
        fi
      '';

      programs.bash.initExtra = mkIf cfg.enableBashIntegration gpgInitStr;
      programs.zsh.initExtra = mkIf cfg.enableZshIntegration gpgInitStr;
      programs.fish.interactiveShellInit =
        mkIf cfg.enableFishIntegration gpgFishInitStr;

      programs.nushell.extraEnv =
        mkIf cfg.enableNushellIntegration gpgNushellInitStr;
    }

    (mkIf (cfg.sshKeys != null) {
      # Trailing newlines are important
      home.file."${homedir}/sshcontrol".text = concatMapStrings (s: ''
        ${s}
      '') cfg.sshKeys;
    })

    # The systemd units below are direct translations of the
    # descriptions in the
    #
    #   ${gpgPkg}/share/doc/gnupg/examples/systemd-user
    #
    # directory.
    {
      assertions = [
        (hm.assertions.assertPlatform "services.gpg-agent" pkgs platforms.linux)
      ];

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
          ExecStart = "${gpgPkg}/bin/gpg-agent --supervised"
            + optionalString cfg.verbose " --verbose";
          ExecReload = "${gpgPkg}/bin/gpgconf --reload gpg-agent";
          Environment = [ "GNUPGHOME=${homedir}" ];
        };
      };

      systemd.user.sockets.gpg-agent = {
        Unit = {
          Description = "GnuPG cryptographic agent and passphrase cache";
          Documentation = "man:gpg-agent(1)";
        };

        Socket = {
          ListenStream = gpgconf "S.gpg-agent";
          FileDescriptorName = "std";
          SocketMode = "0600";
          DirectoryMode = "0700";
        };

        Install = { WantedBy = [ "sockets.target" ]; };
      };
    }

    (mkIf cfg.enableSshSupport {
      systemd.user.sockets.gpg-agent-ssh = {
        Unit = {
          Description = "GnuPG cryptographic agent (ssh-agent emulation)";
          Documentation =
            "man:gpg-agent(1) man:ssh-add(1) man:ssh-agent(1) man:ssh(1)";
        };

        Socket = {
          ListenStream = gpgconf "S.gpg-agent.ssh";
          FileDescriptorName = "ssh";
          Service = "gpg-agent.service";
          SocketMode = "0600";
          DirectoryMode = "0700";
        };

        Install = { WantedBy = [ "sockets.target" ]; };
      };
    })

    (mkIf cfg.enableExtraSocket {
      systemd.user.sockets.gpg-agent-extra = {
        Unit = {
          Description =
            "GnuPG cryptographic agent and passphrase cache (restricted)";
          Documentation = "man:gpg-agent(1) man:ssh(1)";
        };

        Socket = {
          ListenStream = gpgconf "S.gpg-agent.extra";
          FileDescriptorName = "extra";
          Service = "gpg-agent.service";
          SocketMode = "0600";
          DirectoryMode = "0700";
        };

        Install = { WantedBy = [ "sockets.target" ]; };
      };
    })
  ]);
}
