{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.gpg;

  mkKeyValue = key: value:
    if isString value
    then "${key} ${value}"
    else optionalString value key;

  cfgText = generators.toKeyValue {
    inherit mkKeyValue;
    listsAsDuplicateKeys = true;
  } cfg.settings;

  scdaemonCfgText = generators.toKeyValue {
    inherit mkKeyValue;
    listsAsDuplicateKeys = true;
  } cfg.scdaemonSettings;

  primitiveType = types.oneOf [ types.str types.bool ];

  publicKeyOpts = { config, ...}: {
    options = {
      text = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Text of an OpenPGP public key.
        '';
      };

      source = mkOption {
        type = types.path;
        description = ''
          Path of an OpenPGP public key file.
        '';
      };

      trust = mkOption {
        type = types.nullOr (types.enum ["unknown" 1 "never" 2 "marginal" 3 "full" 4 "ultimate" 5]);
        default = null;
        apply = v:
          if isString v then
            {
              unknown = 1;
              never = 2;
              marginal = 3;
              full = 4;
              ultimate = 5;
            }.${v}
          else v;
        description = ''
          The amount of trust you have in the key ownership and the care the
          owner puts into signing other keys. The available levels are
          <variablelist>
            <varlistentry>
              <term><literal>unknown</literal> or <literal>1</literal></term>
              <listitem><para>I don't know or won't say.</para></listitem>
            </varlistentry>
            <varlistentry>
              <term><literal>never</literal> or <literal>2</literal></term>
              <listitem><para>I do NOT trust.</para></listitem>
            </varlistentry>
            <varlistentry>
              <term><literal>marginal</literal> or <literal>3</literal></term>
              <listitem><para>I trust marginally.</para></listitem>
            </varlistentry>
            <varlistentry>
              <term><literal>full</literal> or <literal>4</literal></term>
              <listitem><para>I trust fully.</para></listitem>
            </varlistentry>
            <varlistentry>
              <term><literal>ultimate</literal> or <literal>5</literal></term>
              <listitem><para>I trust ultimately.</para></listitem>
            </varlistentry>
          </variablelist>
          </para><para>
          See <link xlink:href="https://www.gnupg.org/gph/en/manual/x334.html"/>
          for more.
        '';
      };
    };

    config = {
      source = mkIf (config.text != null)
        (pkgs.writeText "gpg-pubkey" config.text);
    };
  };

  importTrustBashFunctions =
    let gpg = "${cfg.package}/bin/gpg";
    in ''
      function gpgKeyId() {
        ${gpg} --show-key --with-colons "$1" \
          | grep ^pub: \
          | cut -d: -f5
      }

      function importTrust() {
        local keyId trust
        keyId="$(gpgKeyId "$1")"
        trust="$2"
        if [[ -n $keyId ]] ; then
          { echo trust; echo "$trust"; (( trust == 5 )) && echo y; echo quit; } \
            | ${gpg} --no-tty --command-fd 0 --edit-key "$keyId"
        fi
      }
  '';

  keyringFiles =
    let
      gpg = "${cfg.package}/bin/gpg";

      importKey = { source, trust, ... }: ''
        ${gpg} --import ${source}
        ${optionalString (trust != null) ''
          importTrust "${source}" ${toString trust}''}
      '';

      importKeys = concatMapStringsSep "\n" importKey cfg.publicKeys;
    in pkgs.runCommand "gpg-pubring" { buildInputs = [ cfg.package ]; } ''
      export GNUPGHOME
      GNUPGHOME=$(mktemp -d)

      ${importTrustBashFunctions}
      ${importKeys}

      mkdir $out
      cp $GNUPGHOME/pubring.kbx $out/pubring.kbx
      if [[ -e $GNUPGHOME/trustdb.gpg ]] ; then
        cp $GNUPGHOME/trustdb.gpg $out/trustdb.gpg
      fi
    '';

in
{
  options.programs.gpg = {
    enable = mkEnableOption "GnuPG";

    package = mkOption {
      type = types.package;
      default = pkgs.gnupg;
      defaultText = literalExpression "pkgs.gnupg";
      example = literalExpression "pkgs.gnupg23";
      description = "The Gnupg package to use (also used the gpg-agent service).";
    };

    settings = mkOption {
      type = types.attrsOf (types.either primitiveType (types.listOf types.str));
      example = literalExpression ''
        {
          no-comments = false;
          s2k-cipher-algo = "AES128";
        }
      '';
      description = ''
        GnuPG configuration options. Available options are described
        in the gpg manpage:
        <link xlink:href="https://gnupg.org/documentation/manpage.html"/>.
        </para>
        <para>
        Note that lists are converted to duplicate keys.
      '';
    };

    scdaemonSettings = mkOption {
      type = types.attrsOf (types.either primitiveType (types.listOf types.str));
      example = literalExpression ''
        {
          disable-ccid = true;
        }
      '';
      description = ''
        SCdaemon configuration options. Available options are described
        in the gpg scdaemon manpage:
        <link xlink:href="https://www.gnupg.org/documentation/manuals/gnupg/Scdaemon-Options.html"/>.
      '';
    };

    homedir = mkOption {
      type = types.path;
      example = literalExpression "\"\${config.xdg.dataHome}/gnupg\"";
      default = "${config.home.homeDirectory}/.gnupg";
      defaultText = literalExpression "\"\${config.home.homeDirectory}/.gnupg\"";
      description = "Directory to store keychains and configuration.";
    };

    mutableKeys = mkOption {
      type = types.bool;
      default = true;
      description = ''
        If set to <literal>true</literal>, you may manage your keyring as a user
        using the <literal>gpg</literal> command. Upon activation, the keyring
        will have managed keys added without overwriting unmanaged keys.
        </para><para>
        If set to <literal>false</literal>, the path
        <filename>$GNUPGHOME/pubring.kbx</filename> will become an immutable
        link to the Nix store, denying modifications.
      '';
    };

    mutableTrust = mkOption {
      type = types.bool;
      default = true;
      description = ''
        If set to <literal>true</literal>, you may manage trust as a user using
        the <command>gpg</command> command. Upon activation, trusted keys have
        their trust set without overwriting unmanaged keys.
        </para><para>
        If set to <literal>false</literal>, the path
        <filename>$GNUPGHOME/trustdb.gpg</filename> will be
        <emphasis>overwritten</emphasis> on each activation, removing trust for
        any unmanaged keys. Be careful to make a backup of your old
        <filename>trustdb.gpg</filename> before switching to immutable trust!
      '';
    };

    publicKeys = mkOption {
      type = types.listOf (types.submodule publicKeyOpts);
      example = literalExpression ''
        [ { source = ./pubkeys.txt; } ]
      '';
      default = [ ];
      description = ''
        A list of public keys to be imported into GnuPG. Note, these key files
        will be copied into the world-readable Nix store.
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.gpg.settings = {
      personal-cipher-preferences = mkDefault "AES256 AES192 AES";
      personal-digest-preferences = mkDefault "SHA512 SHA384 SHA256";
      personal-compress-preferences = mkDefault "ZLIB BZIP2 ZIP Uncompressed";
      default-preference-list = mkDefault "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
      cert-digest-algo = mkDefault "SHA512";
      s2k-digest-algo = mkDefault "SHA512";
      s2k-cipher-algo = mkDefault "AES256";
      charset = mkDefault "utf-8";
      fixed-list-mode = mkDefault true;
      no-comments = mkDefault true;
      no-emit-version = mkDefault true;
      keyid-format = mkDefault "0xlong";
      list-options = mkDefault "show-uid-validity";
      verify-options = mkDefault "show-uid-validity";
      with-fingerprint = mkDefault true;
      require-cross-certification = mkDefault true;
      no-symkey-cache = mkDefault true;
      use-agent = mkDefault true;
    };

    programs.gpg.scdaemonSettings = {
      # no defaults for scdaemon
    };

    home.packages = [ cfg.package ];
    home.sessionVariables = {
      GNUPGHOME = cfg.homedir;
    };

    home.file."${cfg.homedir}/gpg.conf".text = cfgText;

    home.file."${cfg.homedir}/scdaemon.conf".text = scdaemonCfgText;

    # Link keyring if keys are not mutable
    home.file."${cfg.homedir}/pubring.kbx" =
      mkIf (!cfg.mutableKeys && cfg.publicKeys != []) {
        source = "${keyringFiles}/pubring.kbx";
      };

    home.activation = mkIf (cfg.publicKeys != []) {
      importGpgKeys =
        let
          gpg = "${cfg.package}/bin/gpg";

          importKey = { source, trust, ... }:
            # Import mutable keys
            optional cfg.mutableKeys ''
              $DRY_RUN_CMD ${gpg} $QUIET_ARG --import ${source}''

            # Import mutable trust
            ++ optional (trust != null && cfg.mutableTrust) ''
              $DRY_RUN_CMD importTrust "${source}" ${toString trust}'';

          anyTrust = any (k: k.trust != null) cfg.publicKeys;

          importKeys = concatStringsSep "\n" (concatMap importKey cfg.publicKeys);

          # If any key/trust should be imported then create the block. Otherwise
          # leave it empty.
          block = concatStringsSep "\n" (
            optional (importKeys != "") ''
              export GNUPGHOME=${escapeShellArg cfg.homedir}
              if [[ ! -v VERBOSE ]]; then
                QUIET_ARG="--quiet"
              else
                QUIET_ARG=""
              fi
              ${importTrustBashFunctions}
              ${importKeys}
              unset GNUPGHOME QUIET_ARG keyId importTrust
            '' ++ optional (!cfg.mutableTrust && anyTrust) ''
              install -m 0700 ${keyringFiles}/trustdb.gpg "${cfg.homedir}/trustdb.gpg"''
          );
        in lib.hm.dag.entryAfter ["linkGeneration"] block;
    };
  };
}
