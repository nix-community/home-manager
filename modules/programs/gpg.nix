{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.gpg;

  mkKeyValue = key: value:
    if isString value then "${key} ${value}" else optionalString value key;

  cfgText = generators.toKeyValue {
    inherit mkKeyValue;
    listsAsDuplicateKeys = true;
  } cfg.settings;

  scdaemonCfgText = generators.toKeyValue {
    inherit mkKeyValue;
    listsAsDuplicateKeys = true;
  } cfg.scdaemonSettings;

  primitiveType = types.oneOf [ types.str types.bool ];

  publicKeyOpts = { config, ... }: {
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
        type = types.nullOr (types.enum [
          "unknown"
          1
          "never"
          2
          "marginal"
          3
          "full"
          4
          "ultimate"
          5
        ]);
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
          else
            v;
        description = ''
          The amount of trust you have in the key ownership and the care the
          owner puts into signing other keys. The available levels are

          `unknown` or `1`
          : I don't know or won't say.

          `never` or `2`
          : I do **not** trust.

          `marginal` or `3`
          : I trust marginally.

          `full` or `4`
          : I trust fully.

          `ultimate` or `5`
          : I trust ultimately.

          See the [Key Management chapter](https://www.gnupg.org/gph/en/manual/x334.html)
          of the GNU Privacy Handbook for more.
        '';
      };
    };

    config = {
      source =
        mkIf (config.text != null) (pkgs.writeText "gpg-pubkey" config.text);
    };
  };

  importTrustBashFunctions = let gpg = "${cfg.package}/bin/gpg";
  in ''
    function gpgKeyId() {
      ${gpg} --show-key --with-colons "$1" \
        | grep ^pub: \
        | cut -d: -f5
    }

    function importTrust() {
      local keyIds trust
      IFS='\n' read -ra keyIds <<< "$(gpgKeyId "$1")"
      trust="$2"
      for id in "''${keyIds[@]}" ; do
        { echo trust; echo "$trust"; (( trust == 5 )) && echo y; echo quit; } \
          | ${gpg} --no-tty --command-fd 0 --edit-key "$id"
      done
    }

  '';

  keyringFiles = let
    gpg = "${cfg.package}/bin/gpg";

    importKey = { source, trust, ... }: ''
      ${gpg} --import ${source}
      ${optionalString (trust != null)
      ''importTrust "${source}" ${toString trust}''}
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

in {
  options.programs.gpg = {
    enable = mkEnableOption "GnuPG";

    package = mkOption {
      type = types.package;
      default = pkgs.gnupg;
      defaultText = literalExpression "pkgs.gnupg";
      example = literalExpression "pkgs.gnupg23";
      description =
        "The Gnupg package to use (also used by the gpg-agent service).";
    };

    settings = mkOption {
      type =
        types.attrsOf (types.either primitiveType (types.listOf types.str));
      example = literalExpression ''
        {
          no-comments = false;
          s2k-cipher-algo = "AES128";
        }
      '';
      description = ''
        GnuPG configuration options. Available options are described
        in
        [
          {manpage}`gpg(1)`
        ](https://gnupg.org/documentation/manpage.html).

        Note that lists are converted to duplicate keys.
      '';
    };

    scdaemonSettings = mkOption {
      type =
        types.attrsOf (types.either primitiveType (types.listOf types.str));
      example = literalExpression ''
        {
          disable-ccid = true;
        }
      '';
      description = ''
        SCdaemon configuration options. Available options are described
        in
        [
          {manpage}`scdaemon(1)`
        ](https://www.gnupg.org/documentation/manuals/gnupg/Scdaemon-Options.html).
      '';
    };

    homedir = mkOption {
      type = types.path;
      example = literalExpression ''"''${config.xdg.dataHome}/gnupg"'';
      default = "${config.home.homeDirectory}/.gnupg";
      defaultText =
        literalExpression ''"''${config.home.homeDirectory}/.gnupg"'';
      description = "Directory to store keychains and configuration.";
    };

    mutableKeys = mkOption {
      type = types.bool;
      default = true;
      description = ''
        If set to `true`, you may manage your keyring as a user
        using the `gpg` command. Upon activation, the keyring
        will have managed keys added without overwriting unmanaged keys.

        If set to `false`, the path
        {file}`$GNUPGHOME/pubring.kbx` will become an immutable
        link to the Nix store, denying modifications.
      '';
    };

    mutableTrust = mkOption {
      type = types.bool;
      default = true;
      description = ''
        If set to `true`, you may manage trust as a user using
        the {command}`gpg` command. Upon activation, trusted keys have
        their trust set without overwriting unmanaged keys.

        If set to `false`, the path
        {file}`$GNUPGHOME/trustdb.gpg` will be
        *overwritten* on each activation, removing trust for
        any unmanaged keys. Be careful to make a backup of your old
        {file}`trustdb.gpg` before switching to immutable trust!
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
      default-preference-list = mkDefault
        "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
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
    home.sessionVariables = { GNUPGHOME = cfg.homedir; };

    home.file."${cfg.homedir}/gpg.conf".text = cfgText;

    home.file."${cfg.homedir}/scdaemon.conf".text = scdaemonCfgText;

    # Link keyring if keys are not mutable
    home.file."${cfg.homedir}/pubring.kbx" =
      mkIf (!cfg.mutableKeys && cfg.publicKeys != [ ]) {
        source = "${keyringFiles}/pubring.kbx";
      };

    home.activation = {
      createGpgHomedir =
        hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
          run mkdir -m700 -p $VERBOSE_ARG ${escapeShellArg cfg.homedir}
        '';

      importGpgKeys = let
        gpg = "${cfg.package}/bin/gpg";

        importKey = { source, trust, ... }:
          # Import mutable keys
          optional cfg.mutableKeys "run ${gpg} $QUIET_ARG --import ${source}"

          # Import mutable trust
          ++ optional (trust != null && cfg.mutableTrust)
          ''run importTrust "${source}" ${toString trust}'';

        anyTrust = any (k: k.trust != null) cfg.publicKeys;

        importKeys = concatStringsSep "\n" (concatMap importKey cfg.publicKeys);

        # If any key/trust should be imported then create the block. Otherwise
        # leave it empty.
        block = concatStringsSep "\n" (optional (importKeys != "") ''
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
          install -m 0700 ${keyringFiles}/trustdb.gpg "${cfg.homedir}/trustdb.gpg"'');
      in mkIf (cfg.publicKeys != [ ])
      (lib.hm.dag.entryAfter [ "linkGeneration" ] block);
    };
  };
}
