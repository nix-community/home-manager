{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    types
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    nameValuePair
    mapAttrs'
    ;

  cfg = config.programs.cudatext;

  jsonFormat = pkgs.formats.json { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];
  options.programs.cudatext = {
    enable = mkEnableOption "cudatext";
    package = mkPackageOption pkgs "cudatext" { nullable = true; };
    hotkeys = mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = {
        "2823" = {
          name = "code tree: clear filter";
          s1 = [ "Home" ];
        };

        "153" = {
          name = "delete char right (delete)";
          s1 = [ "End" ];
        };

        "655465" = {
          name = "caret to line end";
          s1 = [ ];
        };

        "116" = {
          name = "column select: page up";
          s1 = [ ];
        };

        "655464" = {
          name = "caret to line begin";
          s1 = [ ];
        };
      };
      description = ''
        Hotkeys for Cudatext. To see the available options, change
        the settings in the dialog "Help | Command palette" and
        look at the changes in `settings/keys.json`.
      '';
    };

    userSettings = mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = {
        numbers_style = 2;
        numbers_center = false;
        numbers_for_carets = true;
      };
      description = ''
        User configuration for Cudatext.
      '';
    };

    lexerSettings = mkOption {
      type = types.attrsOf jsonFormat.type;
      default = { };
      example = {
        C = {
          numbers_style = 2;
        };
        Python = {
          numbers_style = 1;
          numbers_center = false;
        };
        Rust = {
          numbers_style = 2;
          numbers_center = false;
          numbers_for_carets = true;
        };
      };
      description = ''
        User configuration settings specific to each lexer.
      '';
    };

    lexerHotkeys = mkOption {
      type = types.attrsOf jsonFormat.type;
      default = { };
      example = {
        C = {
          "153" = {
            name = "delete char right (delete)";
            s1 = [ "End" ];
          };

          "655465" = {
            name = "caret to line end";
            s1 = [ ];
          };
        };

        Python = {
          "2823" = {
            name = "code tree: clear filter";
            s1 = [ "Home" ];
          };

          "655464" = {
            name = "caret to line begin";
            s1 = [ ];
          };
        };
      };
      description = ''
        Hotkeys settings specific to each lexer.
      '';
    };
  };

  config =
    let
      settingsPath =
        if pkgs.stdenv.isDarwin then
          "Library/Application Support/CudaText/settings"
        else
          "${lib.removePrefix config.home.homeDirectory config.xdg.configHome}/cudatext/settings";
    in
    mkIf cfg.enable {
      home.packages = mkIf (cfg.package != null) [ cfg.package ];
      home.file = {
        "${settingsPath}/keys.json" = mkIf (cfg.hotkeys != { }) {
          source = jsonFormat.generate "cudatext-keys.json" cfg.hotkeys;
        };
        "${settingsPath}/user.json" = mkIf (cfg.userSettings != { }) {
          source = jsonFormat.generate "cudatext-user.json" cfg.userSettings;
        };
      }
      // (mapAttrs' (
        k: v:
        nameValuePair "${settingsPath}/lexer ${k}.json" {
          source = jsonFormat.generate "cudatext-lexer-${k}" v;
        }
      ) cfg.lexerSettings)
      // (mapAttrs' (
        k: v:
        nameValuePair "${settingsPath}/keys lexer ${k}.json" {
          source = jsonFormat.generate "cudatext-lexer-keys-${k}" v;
        }
      ) cfg.lexerHotkeys);
    };
}
