{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.btop;

  finalConfig =
    let
      toKeyValue = lib.generators.toKeyValue {
        mkKeyValue = lib.generators.mkKeyValueDefault {
          mkValueString =
            v:
            with builtins;
            if isBool v then
              (if v then "True" else "False")
            else if isString v then
              ''"${v}"''
            else
              toString v;
        } " = ";
      };
    in
    ''
      ${toKeyValue cfg.settings}
      ${lib.optionalString (cfg.extraConfig != "") cfg.extraConfig}
    '';
in
{
  meta.maintainers = with lib.maintainers; [
    GaetanLepage
    khaneliman
  ];

  options.programs.btop = {
    enable = lib.mkEnableOption "btop";

    package = lib.mkPackageOption pkgs "btop" { nullable = true; };

    settings = lib.mkOption {
      type =
        with lib.types;
        attrsOf (oneOf [
          bool
          float
          int
          str
        ]);
      default = { };
      example = {
        color_theme = "Default";
        theme_background = false;
      };
      description = ''
        Options to add to {file}`btop.conf` file.
        See <https://github.com/aristocratos/btop#configurability>
        for options.
      '';
    };

    themes = lib.mkOption {
      type = with lib.types; lazyAttrsOf (either path lines);
      default = { };
      example = {
        my-theme = ''
          theme[main_bg]="#282a36"
          theme[main_fg]="#f8f8f2"
          theme[title]="#f8f8f2"
          theme[hi_fg]="#6272a4"
          theme[selected_bg]="#ff79c6"
          theme[selected_fg]="#f8f8f2"
          theme[inactive_fg]="#44475a"
          theme[graph_text]="#f8f8f2"
          theme[meter_bg]="#44475a"
          theme[proc_misc]="#bd93f9"
          theme[cpu_box]="#bd93f9"
          theme[mem_box]="#50fa7b"
          theme[net_box]="#ff5555"
          theme[proc_box]="#8be9fd"
          theme[div_line]="#44475a"
          theme[temp_start]="#bd93f9"
          theme[temp_mid]="#ff79c6"
          theme[temp_end]="#ff33a8"
          theme[cpu_start]="#bd93f9"
          theme[cpu_mid]="#8be9fd"
          theme[cpu_end]="#50fa7b"
          theme[free_start]="#ffa6d9"
          theme[free_mid]="#ff79c6"
          theme[free_end]="#ff33a8"
          theme[cached_start]="#b1f0fd"
          theme[cached_mid]="#8be9fd"
          theme[cached_end]="#26d7fd"
          theme[available_start]="#ffd4a6"
          theme[available_mid]="#ffb86c"
          theme[available_end]="#ff9c33"
          theme[used_start]="#96faaf"
          theme[used_mid]="#50fa7b"
          theme[used_end]="#0dfa49"
          theme[download_start]="#bd93f9"
          theme[download_mid]="#50fa7b"
          theme[download_end]="#8be9fd"
          theme[upload_start]="#8c42ab"
          theme[upload_mid]="#ff79c6"
          theme[upload_end]="#ff33a8"
          theme[process_start]="#50fa7b"
          theme[process_mid]="#59b690"
          theme[process_end]="#6272a4"
        '';
      };
      description = ''
        Themes to be written to {file}`$XDG_CONFIG_HOME/btop/themes/''${name}.theme`
      '';
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Extra lines added to the {file}`btop.conf` file.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile =
      let
        mkThemeConfig = name: theme: {
          name = "btop/themes/${name}.theme";
          value = {
            source = (
              if builtins.isPath theme || lib.isStorePath theme then
                theme
              else
                pkgs.writeText "btop-theme.theme" theme
            );
          };
        };
      in
      {

        "btop/btop.conf" = lib.mkIf (cfg.settings != { }) { text = finalConfig; };
      }
      // lib.mapAttrs' mkThemeConfig cfg.themes;
  };
}
