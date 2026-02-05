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
in

{
  meta.maintainers = with lib.hm.maintainers; [
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
        mkdir -p $(dirname '${escapeShellArg filePath}')

        if [ ! -e '${escapeShellArg filePath}' ]; then
          cat '${escapeShellArg emptySettingsFile}' > '${escapeShellArg filePath}'
        fi

        ${lib.getExe pkgs.crudini} --merge --ini-options=nospace \
          '${escapeShellArg filePath}' < '${escapeShellArg staticSettingsFile}'
      '';
    in
    mkIf cfg.enable {
      home = {
        packages = lib.mkMerge ([ (mkIf (cfg.package != null) [ cfg.package ]) ] ++ cfg.extraPackages);

        activation = {
          prismlauncherConfigActivation = lib.hm.dag.entryAfter [ "linkGeneration" ] (
            impureConfigMerger "${dataDir}/prismlauncher.cfg" (iniFormat.generate "prismlauncher-static.cfg" {
              General = cfg.settings;
            }) (iniFormat.generate "prismlauncher-empty.cfg" { General = { }; })
          );
        };

        file = mkIf (cfg.icons != [ ]) (
          listToAttrs (
            map (source: {
              name = "${dataDir}/icons/${baseNameOf source}";
              value = { inherit source; };
            }) cfg.icons
          )
        );
      };
    };
}
