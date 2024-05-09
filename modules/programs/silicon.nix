{ pkgs, lib, config, ... }:

with lib;

let cfg = config.programs.silicon;
in {
  meta.maintainers = with hm.maintainers; [ afresquet ];

  options.programs.silicon = {
    enable =
      mkEnableOption "silicon, create beautiful image of your source code";

    package = mkPackageOption pkgs "silicon" { };

    settings = mkOption {
      type = types.str;
      default = "";
      example = literalExpression ''
        --shadow-color '#555'
        --background '#fff'
        --shadow-blur-radius 30
        --no-window-controls
      '';
      description = ''
        Silicon configuration.
      '';
    };

    themes = mkOption {
      type = types.attrsOf (types.submodule {
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
      });
      default = { };
      example = literalExpression ''
        {
          dracula = {
            src = pkgs.fetchFromGitHub {
              owner = "dracula";
              repo = "sublime"; # Silicon uses sublime syntax for its themes
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
      type = types.attrsOf (types.submodule {
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
      });
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

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile = mkMerge ([({
      "silicon/config" = mkIf (cfg.settings != "") { text = cfg.settings; };
    })] ++ (flip mapAttrsToList cfg.themes (name: val: {
      "silicon/themes/${name}.tmTheme" = {
        source =
          if isNull val.file then "${val.src}" else "${val.src}/${val.file}";
      };
    })) ++ (flip mapAttrsToList cfg.syntaxes (name: val: {
      "silicon/syntaxes/${name}.sublime-syntax" = {
        source =
          if isNull val.file then "${val.src}" else "${val.src}/${val.file}";
      };
    })));

    # NOTE: we are ensuring `themes` and `syntaxes` directories exist
    # because silicon assumes they do when running `--build-cache`
    # https://github.com/Aloxaf/silicon/issues/242
    home.activation.siliconCache = hm.dag.entryAfter [ "linkGeneration" ] ''
      (
        export XDG_CACHE_HOME=${escapeShellArg config.xdg.cacheHome}
        verboseEcho "Rebuilding silicon theme cache"
        mkdir -p ${
          escapeShellArg config.xdg.configHome
        }/silicon/{themes,syntaxes}
        cd ${escapeShellArg config.xdg.configHome}/silicon
        run ${getExe cfg.package} --build-cache
      )
    '';
  };
}
