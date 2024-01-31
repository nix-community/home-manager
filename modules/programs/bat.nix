{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.bat;

  package = pkgs.bat;

  toConfigFile = attrs:
    let
      inherit (builtins) isBool attrNames;
      nonBoolFlags = filterAttrs (_: v: !(isBool v)) attrs;
      enabledBoolFlags = filterAttrs (_: v: isBool v && v) attrs;

      keyValuePairs = generators.toKeyValue {
        mkKeyValue = k: v: "--${k}=${lib.escapeShellArg v}";
        listsAsDuplicateKeys = true;
      } nonBoolFlags;
      switches = concatMapStrings (k: ''
        --${k}
      '') (attrNames enabledBoolFlags);
    in keyValuePairs + switches;

in {
  meta.maintainers = [ ];

  options.programs.bat = {
    enable = mkEnableOption "bat, a cat clone with wings";

    config = mkOption {
      type = with types; attrsOf (oneOf [ str (listOf str) bool ]);
      default = { };
      example = {
        theme = "TwoDark";
        pager = "less -FR";
        map-syntax = [ "*.jenkinsfile:Groovy" "*.props:Java Properties" ];
      };
      description = ''
        Bat configuration.
      '';
    };

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      example = literalExpression
        "with pkgs.bat-extras; [ batdiff batman batgrep batwatch ];";
      description = ''
        Additional bat packages to install.
      '';
    };

    themes = mkOption {
      type = types.attrsOf (types.either types.lines (types.submodule {
        options = {
          src = mkOption {
            type = types.path;
            description = "Path to the theme folder.";
          };

          file = mkOption {
            type = types.nullOr types.str;
            default = null;
            description =
              "Subpath of the theme file within the source, if needed.";
          };
        };
      }));
      default = { };
      example = literalExpression ''
        {
          dracula = {
            src = pkgs.fetchFromGitHub {
              owner = "dracula";
              repo = "sublime"; # Bat uses sublime syntax for its themes
              rev = "26c57ec282abcaa76e57e055f38432bd827ac34e";
              sha256 = "019hfl4zbn4vm4154hh3bwk6hm7bdxbr1hdww83nabxwjn99ndhv";
            };
            file = "Dracula.tmTheme";
          };
        }
      '';
      description = ''
        Additional themes to provide.
      '';
    };

    syntaxes = mkOption {
      type = types.attrsOf (types.either types.lines (types.submodule {
        options = {
          src = mkOption {
            type = types.path;
            description = "Path to the syntax folder.";
          };
          file = mkOption {
            type = types.nullOr types.str;
            default = null;
            description =
              "Subpath of the syntax file within the source, if needed.";
          };
        };
      }));
      default = { };
      example = literalExpression ''
        {
          gleam = {
            src = pkgs.fetchFromGitHub {
              owner = "molnarmark";
              repo = "sublime-gleam";
              rev = "2e761cdb1a87539d827987f997a20a35efd68aa9";
              hash = "sha256-Zj2DKTcO1t9g18qsNKtpHKElbRSc9nBRE2QBzRn9+qs=";
            };
            file = "syntax/gleam.sublime-syntax";
          };
        }
      '';
      description = ''
        Additional syntaxes to provide.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf (any isString (attrValues cfg.themes)) {
      warnings = [''
        Using programs.bat.themes as a string option is deprecated and will be
        removed in the future. Please change to using it as an attribute set
        instead.
      ''];
    })
    (mkIf (any isString (attrValues cfg.syntaxes)) {
      warnings = [''
        Using programs.bat.syntaxes as a string option is deprecated and will be
        removed in the future. Please change to using it as an attribute set
        instead.
      ''];
    })
    {
      home.packages = [ package ] ++ cfg.extraPackages;

      xdg.configFile = mkMerge ([({
        "bat/config" =
          mkIf (cfg.config != { }) { text = toConfigFile cfg.config; };
      })] ++ (flip mapAttrsToList cfg.themes (name: val: {
        "bat/themes/${name}.tmTheme" = if isString val then {
          text = val;
        } else {
          source =
            if isNull val.file then "${val.src}" else "${val.src}/${val.file}";
        };
      })) ++ (flip mapAttrsToList cfg.syntaxes (name: val: {
        "bat/syntaxes/${name}.sublime-syntax" = if isString val then {
          text = val;
        } else {
          source =
            if isNull val.file then "${val.src}" else "${val.src}/${val.file}";
        };
      })));

      home.activation.batCache = hm.dag.entryAfter [ "linkGeneration" ] ''
        (
          export XDG_CACHE_HOME=${escapeShellArg config.xdg.cacheHome}
          verboseEcho "Rebuilding bat theme cache"
          run ${lib.getExe package} cache --build
        )
      '';
    }
  ]);
}
