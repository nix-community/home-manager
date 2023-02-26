{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.nix;

  nixPackage = cfg.package;

  isNixAtLeast = versionAtLeast (getVersion nixPackage);

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
        else if isCoercibleToString v then
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
              "The flake reference to which <option>from></option> is to be rewritten.";
          };
          flake = mkOption {
            type = types.nullOr types.attrs;
            default = null;
            example = literalExpression "nixpkgs";
            description = ''
              The flake input to which <option>from></option> is to be rewritten.
            '';
          };
          exact = mkOption {
            type = types.bool;
            default = true;
            description = ''
              Whether the <option>from</option> reference needs to match exactly. If set,
              a <option>from</option> reference like <literal>nixpkgs</literal> does not
              match with a reference like <literal>nixpkgs/nixos-20.03</literal>.
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
      description =
        "Additional text appended to <filename>nix.conf</filename>.";
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
        Configuration for Nix, see
        <link xlink:href="https://nixos.org/manual/nix/stable/#sec-conf-file"/> or
        <citerefentry>
          <refentrytitle>nix.conf</refentrytitle>
          <manvolnum>5</manvolnum>
        </citerefentry> for available options.
        The value declared here will be translated directly to the key-value pairs Nix expects.
        </para>
        <para>
        Configuration specified in <option>nix.extraOptions</option> which will be appended
        verbatim to the resulting config file.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
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
