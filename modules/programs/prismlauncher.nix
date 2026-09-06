{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    concatLists
    concatMapAttrs
    escapeShellArg
    getExe
    hm
    listToAttrs
    literalExpression
    maintainers
    mapAttrsToList
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    mkRenamedOptionModule
    optional
    optionalAttrs
    pathIsDirectory
    types
    ;
  inherit (pkgs)
    buildEnv
    crudini
    formats
    stdenv
    writeShellScript
    ;

  concatMapAttrsToList = f: attrs: concatLists (mapAttrsToList f attrs);

  iniFormat = formats.ini { };
  jsonFormat = formats.json { };

  cfg = config.programs.prismlauncher;

  dataDir =
    (if stdenv.hostPlatform.isDarwin then "Library/Application Support" else config.xdg.dataHome)
    + "/PrismLauncher";
in

{
  meta.maintainers = with maintainers; [
    ErinaYip
    mikaeladev
  ];

  imports = [
    (mkRenamedOptionModule
      [ "programs" "prismlauncher" "extraPackages" ]
      [ "programs" "prismlauncher" "themePackages" ]
    )
  ];

  options.programs.prismlauncher = {
    enable = mkEnableOption "Prism Launcher";

    package = mkPackageOption pkgs "prismlauncher" { nullable = true; };

    settings = mkOption {
      type = types.attrsOf iniFormat.lib.types.atom;
      default = { };
      example = {
        ShowConsole = true;
        ConsoleMaxLines = 100000;
      };
      description = ''
        Set of settings to write to {file}`prismlauncher.cfg`.
      '';
    };

    icons = mkOption {
      type = with types; listOf path;
      default = [ ];
      example = literalExpression "[ ./fabulously-optimised.png ]";
      description = ''
        List of paths to instance icons.
      '';
    };

    themePackages = mkOption {
      type = with types; listOf package;
      default = [ ];
      description = ''
        List of theme packages to install.

        Themes may be sourced from Prism Launcher's [theme repository] and must
        install to either `themes`, `iconthemes`, or `catpacks` within
        `$out/share/PrismLauncher/`.

        [theme repository]: https://github.com/PrismLauncher/Themes
      '';
    };

    themes = mkOption {
      type =
        let
          themeSubmodule = types.submodule {
            options = {
              theme = mkOption {
                type = with types; either (attrsOf jsonFormat.type) lines;
                example = {
                  name = "Custom";
                  colors = {
                    background = "#1a1b26";
                    foreground = "#c0caf5";
                  };
                };
                description = ''
                  Set of [theme attributes] to write to {file}`themes/‹name›/theme.json`.

                  [theme attributes]: https://github.com/PrismLauncher/Themes/blob/main/themes/Catppuccin-Frappe/theme.json
                '';
              };

              style = mkOption {
                type = with types; nullOr (coercedTo path builtins.readFile lines);
                default = null;
                example = ''
                  QWidget {
                    font-family: "Inter";
                  }
                '';
                description = ''
                  Lines of [theme styles] to write to {file}`themes/‹name›/themeStyle.css`.

                  [theme styles]: https://github.com/PrismLauncher/Themes/blob/main/themes/Catppuccin-Frappe/themeStyle.css
                '';
              };
            };
          };
        in
        with types;
        attrsOf (either path themeSubmodule);
      default = { };
      example = literalExpression ''
        {
          # generates a theme at `themes/custom`
          custom = {
            theme = {
              name = "Custom";
              colors = {
                background = "#1a1b26";
                foreground = "#c0caf5";
              };
            };
            style = '''
              QWidget {
                font-family: "Inter";
              }
            ''';
          };
          # links `Tokyo-Night` at `themes/tokyo-night`
          tokyo-night = ./Tokyo-Night;
        }
      '';
      description = ''
        Set of application themes.

        Attribute names translate to theme directories, and attribute values
        describe their contents. Values may either be a path to a complete
        theme directory, or an attribute set used to generate one.

        See also:
        - <https://github.com/PrismLauncher/Themes>
        - <https://prismlauncher.org/wiki/getting-started/change-themes/#submitting-themes>
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = concatMapAttrsToList (name: value: [
      {
        assertion = !hm.strings.isPathLike value || pathIsDirectory value;
        message = "`programs.prismlauncher.themes.${name}` must be a directory when set to a path.";
      }
      {
        assertion = hm.strings.isPathLike value || value.theme != { };
        message = "`programs.prismlauncher.themes.${name}.theme` must not be empty.";
      }
    ]) cfg.themes;

    warnings = optional (stdenv.hostPlatform.isDarwin && cfg.settings != { }) ''
      The option `programs.prismlauncher.settings` is currently bugged on Darwin.

      See the related issue:
        https://github.com/nix-community/home-manager/issues/9916
    '';

    home.packages =
      (optional (cfg.package != null) cfg.package)
      ++ optional (cfg.themePackages != [ ]) (buildEnv {
        name = "prismlauncher-themes";
        paths = cfg.themePackages;
        pathsToLink = [
          "/share/PrismLauncher/themes"
          "/share/PrismLauncher/iconthemes"
          "/share/PrismLauncher/catpacks"
        ];
      });

    home.file =
      (listToAttrs (
        map (value: {
          name = "${dataDir}/icons/${baseNameOf value}";
          value.source = value;
        }) cfg.icons
      ))
      // (concatMapAttrs (
        name: value:
        if hm.strings.isPathLike value then
          { "${dataDir}/themes/${name}".source = value; }
        else
          {
            "${dataDir}/themes/${name}/theme.json".source =
              jsonFormat.generate "${name}-theme.json" value.theme;
          }
          // (optionalAttrs (value.style != null) {
            "${dataDir}/themes/${name}/themeStyle.css".text = value.style;
          })
      ) cfg.themes);

    home.activation.configurePrismLauncher =
      mkIf (!stdenv.hostPlatform.isDarwin && cfg.settings != { })
        (
          let
            settingsPath = dataDir + "/prismlauncher.cfg";
            settingsFile = iniFormat.generate "prismlauncher.cfg" { General = cfg.settings; };

            impureMergeScript = writeShellScript "configure-prismlauncher" ''
              set -euo pipefail

              settingsPath="$1"
              settingsFile="$2"

              if [ ! -e "$settingsPath" ]; then
                if [[ -v DRY_RUN ]]; then
                  echo "mkdir -p $(dirname "$settingsPath")"
                  echo "cat $settingsFile > $settingsPath"
                else
                  mkdir -p "$(dirname "$settingsPath")"
                  cat "$settingsFile" > "$settingsPath"
                fi
              else
                if [[ -v DRY_RUN ]]; then
                  echo "crudini --merge --ini-options=nospace $settingsPath < $settingsFile"
                else
                  ${getExe crudini} --merge --ini-options=nospace \
                    "$settingsPath" < "$settingsFile"
                fi
              fi
            '';
          in
          hm.dag.entryAfter [ "writeBoundary" ] ''
            ${impureMergeScript} \
              ${escapeShellArg settingsPath} \
              ${escapeShellArg settingsFile}
          ''
        );
  };
}
