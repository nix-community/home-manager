{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  inherit (lib)
    escapeShellArg
    listToAttrs
    literalExpression
    mkIf
    mkOption
    types
    ;

  cfg = config.programs.prismlauncher;

  iniFormat = pkgs.formats.ini { };
  jsonFormat = pkgs.formats.json { };
  isStorePathString = value: builtins.isString value && lib.hasPrefix "${builtins.storeDir}/" value;
  isPathLike = value: lib.isPath value || isStorePathString value || lib.isDerivation value;
in

{
  meta.maintainers = with lib.maintainers; [
    ErinaYip
    mikaeladev
  ];

  options.programs.prismlauncher = {
    enable = lib.mkEnableOption "Prism Launcher";

    package = lib.mkPackageOption pkgs "prismlauncher" { nullable = true; };

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = ''
        Additional theme packages to install to the user environment.

        Themes can be sourced from <https://github.com/PrismLauncher/Themes> and should
        install to `$out/share/PrismLauncher/{themes,iconthemes,catpacks}`.
      '';
    };

    icons = mkOption {
      type = types.listOf types.path;
      default = [ ];
      example = literalExpression "[ ./java.png ]";
      description = ''
        List of paths to instance icons.

        These will be linked in {file}`$XDG_DATA_HOME/PrismLauncher/icons` on Linux and
        {file}`~/Library/Application Support/PrismLauncher/icons` on macOS.
      '';
    };

    themes = mkOption {
      type = types.attrsOf (
        types.either types.path (
          types.submodule {
            options = {
              theme = mkOption {
                inherit (jsonFormat) type;
                default = { };
                description = ''
                  Contents of the theme's {file}`theme.json`.
                '';
              };

              style = mkOption {
                type = types.nullOr (types.either types.lines types.path);
                default = null;
                description = ''
                  Contents of, or path to, the theme's {file}`themeStyle.css`.
                '';
              };
            };
          }
        )
      );
      default = { };
      example = literalExpression ''
        {
          Tokyo-Night = ./Tokyo-Night;

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
        }
      '';
      description = ''
        Prism Launcher widget themes.

        Attribute names are used as theme directory names. A theme can either be
        a path to a complete theme directory, or an attribute set used to
        generate {file}`theme.json` and optionally {file}`themeStyle.css`.

        These will be linked in {file}`$XDG_DATA_HOME/PrismLauncher/themes` on
        Linux and {file}`~/Library/Application Support/PrismLauncher/themes` on
        macOS.
      '';
    };

    settings = mkOption {
      type = types.attrsOf iniFormat.lib.types.atom;
      default = { };
      example = {
        ShowConsole = true;
        ConsoleMaxLines = 100000;
      };
      description = ''
        Configuration written to {file}`prismlauncher.cfg`.
      '';
    };
  };

  config =
    let
      dataDir =
        if (isDarwin && !config.xdg.enable) then
          "Library/Application Support/PrismLauncher"
        else
          "${config.xdg.dataHome}/PrismLauncher";

      impureConfigMerger = filePath: staticSettingsFile: emptySettingsFile: ''
        mkdir -p "$(dirname ${escapeShellArg filePath})"

        if [ ! -e ${escapeShellArg filePath} ]; then
          cat ${escapeShellArg emptySettingsFile} > ${escapeShellArg filePath}
        fi

        ${lib.getExe pkgs.crudini} --merge --ini-options=nospace \
          ${escapeShellArg filePath} < ${escapeShellArg staticSettingsFile}
      '';

      themeFiles = lib.concatMapAttrs (
        name: theme:
        if isPathLike theme then
          {
            "${dataDir}/themes/${name}" = {
              source = theme;
              recursive = true;
            };
          }
        else
          {
            "${dataDir}/themes/${name}/theme.json" = {
              source = jsonFormat.generate "prismlauncher-${name}-theme.json" theme.theme;
            };
          }
          // lib.optionalAttrs (theme.style != null) {
            "${dataDir}/themes/${name}/themeStyle.css" =
              if isPathLike theme.style then { source = theme.style; } else { text = theme.style; };
          }
      ) cfg.themes;
    in
    mkIf cfg.enable {
      assertions =
        lib.mapAttrsToList (name: theme: {
          assertion = !isPathLike theme || lib.pathIsDirectory theme;
          message = "`programs.prismlauncher.themes.${name}` must be a directory when set to a path.";
        }) cfg.themes
        ++ lib.mapAttrsToList (name: theme: {
          assertion = isPathLike theme || theme.theme != { };
          message = "`programs.prismlauncher.themes.${name}.theme` must not be empty.";
        }) cfg.themes;

      home = {
        packages = lib.mkMerge ([ (mkIf (cfg.package != null) [ cfg.package ]) ] ++ cfg.extraPackages);

        activation = lib.mkIf (cfg.settings != { }) {
          prismlauncherConfigActivation = lib.hm.dag.entryAfter [ "linkGeneration" ] (
            impureConfigMerger "${dataDir}/prismlauncher.cfg" (iniFormat.generate "prismlauncher-static.cfg" {
              General = cfg.settings;
            }) (iniFormat.generate "prismlauncher-empty.cfg" { General = { }; })
          );
        };

        file = lib.mkMerge [
          (mkIf (cfg.icons != [ ]) (
            listToAttrs (
              map (source: {
                name = "${dataDir}/icons/${baseNameOf source}";
                value = { inherit source; };
              }) cfg.icons
            )
          ))
          themeFiles
        ];
      };
    };
}
