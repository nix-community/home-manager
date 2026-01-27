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
    getExe
    listToAttrs
    literalExpression
    mkDefault
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    mkPackageOption
    types
    ;

  cfg = config.programs.prismlauncher;

  dataDir =
    if (isDarwin && !config.xdg.enable) then
      "Library/Application Support/PrismLauncher"
    else
      "${config.xdg.dataHome}/PrismLauncher";

  iniFormat = pkgs.formats.ini { };

  impureConfigMerger = filePath: staticSettingsFile: emptySettingsFile: ''
    mkdir -p $(dirname '${escapeShellArg filePath}')

    if [ ! -e '${escapeShellArg filePath}' ]; then
      cat '${escapeShellArg emptySettingsFile}' > '${escapeShellArg filePath}'
    fi

    ${getExe pkgs.crudini} --merge --ini-options=nospace \
      '${escapeShellArg filePath}' < '${escapeShellArg staticSettingsFile}'
  '';
in

{
  meta.maintainers = with lib.hm.maintainers; [
    mikaeladev
  ];

  options.programs.prismlauncher = {
    enable = mkEnableOption "Prism Launcher";

    package = mkPackageOption pkgs "prismlauncher" { nullable = true; };

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

    theme = {
      icons = mkOption {
        type = types.str;
        default = "flat";
        example = "breeze_light";
        description = ''
          Name of the selected icon theme.
        '';
      };

      widgets = mkOption {
        type = types.str;
        default = "system";
        example = "dark";
        description = ''
          Name of the selected widget theme.
        '';
      };

      cat = mkOption {
        type = types.str;
        default = "kitteh";
        example = "rory";
        description = ''
          Name of the selected cat theme.
        '';
      };

      extraPackages = mkOption {
        type = types.listOf types.package;
        default = [ ];
        description = ''
          Additional theme packages to install to the user environment.

          Themes can be sourced from <https://github.com/PrismLauncher/Themes> and should
          install to `$out/share/PrismLauncher/{themes,iconthemes,catpacks}`.
        '';
      };
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

    finalConfig = mkOption {
      internal = true;
      type = iniFormat.type;
      default = { };
    };
  };

  config = mkIf cfg.enable {
    programs.prismlauncher.finalConfig.General = mkMerge [
      (mkIf (cfg.icons != [ ]) { IconsDir = mkDefault "icons"; })

      (with cfg.theme; {
        IconTheme = icons;
        ApplicationTheme = widgets;
        BackgroundCat = cat;
      })

      cfg.settings
    ];

    home.packages = mkMerge (
      [ (mkIf (cfg.package != null) [ cfg.package ]) ] ++ cfg.theme.extraPackages
    );

    home.activation = {
      prismlauncherConfigActivation = (
        lib.hm.dag.entryAfter [ "linkGeneration" ] (
          impureConfigMerger "${dataDir}/prismlauncher.cfg"
            (iniFormat.generate "prismlauncher-static.cfg" cfg.finalConfig)
            (iniFormat.generate "prismlauncher-empty.cfg" { General = { }; })
        )
      );
    };

    home.file = mkIf (cfg.icons != [ ]) (
      listToAttrs (
        map (source: {
          name = "${dataDir}/icons/${baseNameOf source}";
          value = { inherit source; };
        }) cfg.icons
      )
    );
  };
}
