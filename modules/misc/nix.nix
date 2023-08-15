{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.nix;

  nixPackage = cfg.package;

  isNixAtLeast = versionAtLeast (getVersion nixPackage);

  nixPath = lib.concatStringsSep ":" cfg.nixPath;

  useXdg = config.nix.enable
    && (config.nix.settings.use-xdg-base-directories or false);
  defexprDir = if useXdg then
    "${config.xdg.stateHome}/nix/defexpr"
  else
    "${config.home.homeDirectory}/.nix-defexpr";

  # The deploy path for declarative channels. The directory name is prefixed
  # with a number to make it easier for files in defexprDir to control the order
  # they'll be read relative to each other.
  channelPath = "${defexprDir}/50-home-manager";

  channelsDrv = let
    mkEntry = name: drv: {
      inherit name;
      path = toString drv;
    };
  in pkgs.linkFarm "channels" (lib.mapAttrsToList mkEntry cfg.channels);

  nixConf = assert isNixAtLeast "2.2";
    let

      mkValueString = v:
        if v == null then
          ""
        else if isInt v then
          toString v
        else if isBool v then
          boolToString v
        else if isFloat v then
          floatToString v
        else if isList v then
          toString v
        else if isDerivation v then
          toString v
        else if builtins.isPath v then
          toString v
        else if isString v then
          v
        else if isConvertibleWithToString v then
          toString v
        else
          abort "The nix conf value: ${toPretty { } v} can not be encoded";

      mkKeyValue = k: v: "${escape [ "=" ] k} = ${mkValueString v}";

      mkKeyValuePairs = attrs:
        concatStringsSep "\n" (mapAttrsToList mkKeyValue attrs);

    in pkgs.writeTextFile {
      name = "nix.conf";
      text = ''
        # WARNING: this file is generated from the nix.settings option in
        # your Home Manager configuration at $XDG_CONFIG_HOME/nix/nix.conf.
        # Do not edit it!
        ${mkKeyValuePairs cfg.settings}
        ${cfg.extraOptions}
      '';
      checkPhase =
        if pkgs.stdenv.hostPlatform != pkgs.stdenv.buildPlatform then ''
          echo "Ignoring validation for cross-compilation"
        '' else ''
          echo "Validating generated nix.conf"
          ln -s $out ./nix.conf
          set -e
          set +o pipefail
          NIX_CONF_DIR=$PWD \
            ${cfg.package}/bin/nix show-config ${
              optionalString (isNixAtLeast "2.3pre")
              "--no-net --option experimental-features nix-command"
            } \
            |& sed -e 's/^warning:/error:/' \
            | (! grep '${
              if cfg.checkConfig then "^error:" else "^error: unknown setting"
            }')
          set -o pipefail
        '';
    };

  semanticConfType = with types;
    let
      confAtom = nullOr (oneOf [ bool int float str path package ]) // {
        description =
          "Nix config atom (null, bool, int, float, str, path or package)";
      };
    in attrsOf (either confAtom (listOf confAtom));

  jsonFormat = pkgs.formats.json { };

in {
  options.nix = {
    enable = mkEnableOption ''
      the Nix configuration module
    '' // {
      default = true;
      visible = false;
    };

    package = mkOption {
      type = types.nullOr types.package;
      default = null;
      example = literalExpression "pkgs.nix";
      description = ''
        The Nix package that the configuration should be generated for.
      '';
    };

    nixPath = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "$HOME/.nix-defexpr/channels"
        "darwin-config=$HOME/.config/nixpkgs/darwin-configuration.nix"
      ];
      description = lib.mdDoc ''
        Adds new directories to the Nix expression search path.

        Used by Nix when looking up paths in angular brackets
        (e.g. `<nixpkgs>`).
      '';
    };

    keepOldNixPath = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = lib.mdDoc ''
        Whether {option}`nix.nixPath` should keep the previously set values in
        {env}`NIX_PATH`.
      '';
    };

    channels = lib.mkOption {
      type = with lib.types; attrsOf package;
      default = { };
      example = lib.literalExpression "{ inherit nixpkgs; }";
      description = lib.mdDoc ''
        A declarative alternative to Nix channels. Whereas with stock channels,
        you would register URLs and fetch them into the Nix store with
        {manpage}`nix-channel(1)`, this option allows you to register the store
        path directly. One particularly useful example is registering flake
        inputs as channels.

        This option can coexist with stock Nix channels. If the same channel is
        defined in both, this option takes precedence.
      '';
    };

    registry = mkOption {
      type = types.attrsOf (types.submodule (let
        inputAttrs = types.attrsOf
          (types.oneOf [ types.str types.int types.bool types.package ]);
      in { config, name, ... }: {
        options = {
          from = mkOption {
            type = inputAttrs;
            example = {
              type = "indirect";
              id = "nixpkgs";
            };
            description = "The flake reference to be rewritten.";
          };
          to = mkOption {
            type = inputAttrs;
            example = {
              type = "github";
              owner = "my-org";
              repo = "my-nixpkgs";
            };
            description =
              "The flake reference to which {option}`from>` is to be rewritten.";
          };
          flake = mkOption {
            type = types.nullOr types.attrs;
            default = null;
            example = literalExpression "nixpkgs";
            description = ''
              The flake input to which {option}`from>` is to be rewritten.
            '';
          };
          exact = mkOption {
            type = types.bool;
            default = true;
            description = ''
              Whether the {option}`from` reference needs to match exactly. If set,
              a {option}`from` reference like `nixpkgs` does not
              match with a reference like `nixpkgs/nixos-20.03`.
            '';
          };
        };
        config = {
          from = mkDefault {
            type = "indirect";
            id = name;
          };
          to = mkIf (config.flake != null) ({
            type = "path";
            path = config.flake.outPath;
          } // lib.filterAttrs (n: v:
            n == "lastModified" || n == "rev" || n == "revCount" || n
            == "narHash") config.flake);
        };
      }));
      default = { };
      description = ''
        User level flake registry.
      '';
    };

    registryVersion = mkOption {
      type = types.int;
      default = 2;
      internal = true;
      description = "The flake registry format version.";
    };

    checkConfig = mkOption {
      type = types.bool;
      default = true;
      description = ''
        If enabled (the default), checks for data type mismatches and that Nix
        can parse the generated nix.conf.
      '';
    };

    extraOptions = mkOption {
      type = types.lines;
      default = "";
      example = ''
        keep-outputs = true
        keep-derivations = true
      '';
      description = "Additional text appended to {file}`nix.conf`.";
    };

    settings = mkOption {
      type = types.submodule { freeformType = semanticConfType; };
      default = { };
      example = literalExpression ''
        {
          use-sandbox = true;
          show-trace = true;
          system-features = [ "big-parallel" "kvm" "recursive-nix" ];
        }
      '';
      description = ''
        Configuration for Nix; see {manpage}`nix.conf(5)` for available options.
        The value declared here will be translated directly to the key-value pairs Nix expects.

        Configuration specified in [](#opt-nix.extraOptions) will be appended
        verbatim to the resulting config file.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf (cfg.nixPath != [ ] && !cfg.keepOldNixPath) {
      home.sessionVariables.NIX_PATH = "${nixPath}";
    })

    (mkIf (cfg.nixPath != [ ] && cfg.keepOldNixPath) {
      home.sessionVariables.NIX_PATH = "${nixPath}\${NIX_PATH:+:$NIX_PATH}";
    })

    (lib.mkIf (cfg.channels != { }) {
      nix.nixPath = [ channelPath ];
      home.file."${channelPath}".source = channelsDrv;
    })

    (mkIf (cfg.registry != { }) {
      xdg.configFile."nix/registry.json".source =
        jsonFormat.generate "registry.json" {
          version = cfg.registryVersion;
          flakes =
            mapAttrsToList (n: v: { inherit (v) from to exact; }) cfg.registry;
        };
    })

    (mkIf (cfg.settings != { } || cfg.extraOptions != "") {
      assertions = [{
        assertion = cfg.package != null;
        message = ''
          A corresponding Nix package must be specified via `nix.package` for generating
          nix.conf.
        '';
      }];

      xdg.configFile."nix/nix.conf".source = nixConf;
    })
  ]);

  meta.maintainers = [ maintainers.polykernel ];
}
