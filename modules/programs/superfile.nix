{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.superfile;
  tomlFormat = pkgs.formats.toml { };
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  inherit (lib)
    literalExpression
    mapAttrs'
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    mkPackageOption
    nameValuePair
    recursiveUpdate
    types
    hm
    ;
in
{
  meta.maintainers = [ hm.maintainers.LucasWagler ];

  options.programs.superfile = {
    enable = mkEnableOption "superfile - Pretty fancy and modern terminal file manager";

    package = mkPackageOption pkgs "superfile" { nullable = true; };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/superfile/config.toml`
        (linux) or {file}`Library/Application Support/superfile/config.toml` (darwin), See
        <https://superfile.netlify.app/configure/superfile-config/> for supported values.
      '';
      example = literalExpression ''
        theme = "catppuccin-frappe";
        default_sort_type = 0;
        transparent_background = false;
      '';
    };

    hotkeys = mkOption {
      type = tomlFormat.type;
      default = { };
      description = ''
        Hotkey configuration written to {file}`$XDG_CONFIG_HOME/superfile/hotkeys.toml`
        (linux) or {file}`Library/Application Support/superfile/hotkeys.toml` (darwin), See
        <https://superfile.netlify.app/configure/custom-hotkeys/> for supported values.
      '';
      example = literalExpression ''
        confirm = [
          "enter"
          "right"
          "l"
        ];
      '';
    };

    themes = mkOption {
      type = with types; attrsOf (either tomlFormat.type path);
      default = { };
      description = ''
        Theme files written to {file}`$XDG_CONFIG_HOME/superfile/theme/`
        (linux) or {file}`Library/Application Support/superfile/theme/` (darwin), See
        <https://superfile.netlify.app/configure/custom-theme/> for supported values.
      '';
      example = literalExpression ''
        myTheme = {
          code_syntax_highlight = "catppuccin-latte";

          file_panel_border = "#101010";
          sidebar_border = "#101011";
          footer_border = "#101012";

          gradient_color = [
            "#101013"
            "#101014"
          ];

          # ...
        };
        myOtherFavoriteTheme = {
          code_syntax_highlight = "catppuccin-mocha";

          file_panel_border = "#505050";
          sidebar_border = "#505051";
          footer_border = "#505052";

          gradient_color = [
            "#505053"
            "#505054"
          ];

          # ...
        };
      '';
    };
  };

  config =
    let
      enableXdgConfig = !isDarwin || config.xdg.enable;
      themeSetting =
        if (!(cfg.settings ? theme) && cfg.themes != { }) then
          {
            theme = "${builtins.elemAt (builtins.attrNames cfg.themes) 0}";
          }
        else
          { };
      baseConfigPath = if enableXdgConfig then "superfile" else "Library/Application Support/superfile";
      configFile = mkIf (cfg.settings != { }) {
        "${baseConfigPath}/config.toml".source = tomlFormat.generate "superfile-config.toml" (
          recursiveUpdate themeSetting cfg.settings
        );
      };
      hotkeysFile = mkIf (cfg.hotkeys != { }) {
        "${baseConfigPath}/hotkeys.toml".source = tomlFormat.generate "superfile-hotkeys.toml" (
          cfg.hotkeys
        );
      };
      themeFiles = mapAttrs' (
        name: value:
        nameValuePair "${baseConfigPath}/theme/${name}.toml" {
          source =
            if types.path.check value then
              value
            else
              (tomlFormat.generate "superfile-theme-${name}.toml" value);
        }
      ) cfg.themes;
      configFiles = mkMerge [
        configFile
        hotkeysFile
        themeFiles
      ];
    in
    mkIf cfg.enable {
      home.packages = mkIf (cfg.package != null) [ cfg.package ];

      xdg.configFile = mkIf enableXdgConfig configFiles;
      home.file = mkIf (!enableXdgConfig) configFiles;
    };
}
