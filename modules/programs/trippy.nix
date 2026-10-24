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
    ;

  cfg = config.programs.trippy;
  tomlFormat = pkgs.formats.toml { };
in
{

  options.programs.trippy = {
    enable = mkEnableOption "trippy";
    package = mkPackageOption pkgs "trippy" { nullable = true; };
    settings = mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = {
        theme-colors = {
          bg-color = "black";
          border-color = "gray";
          text-color = "gray";
          tab-text-color = "green";
        };
        bindings = {
          toggle-help = "h";
          toggle-help-alt = "?";
          toggle-settings = "s";
          toggle-settings-tui = "1";
          toggle-settings-trace = "2";
          toggle-settings-dns = "3";
          toggle-settings-geoip = "4";
        };
      };
      description = ''
        Configuration settings for trippy. All the available options can be found
        here: <https://trippy.rs/reference/configuration/>
      '';
    };
    forceUserConfig = mkOption {
      type = types.bool;
      default = cfg.settings != { };
      defaultText = lib.literalExpression "config.programs.trippy.settings != { }";
      example = false;
      description = ''
        Whether to force trippy to use the config at
        {file}`$XDG_CONFIG_HOME/trippy/trippy.toml` through the -c flag. This
        defaults to true when settings are non-empty. Set it explicitly to true
        if the file is managed another way. This prevents
        certain commands such as 'sudo' from ignoring the configured settings.
        This will only work if you have 'programs.<shell>.enable' (bash, zsh,
        fish, ...), depending on your shell.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile."trippy/trippy.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "trippy-config" cfg.settings;
    };
    home.shellAliases = mkIf cfg.forceUserConfig {
      trip = "trip -c ${config.xdg.configHome}/trippy/trippy.toml";
    };
  };
}
