{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.programs.stylua;
  inherit (lib)
    mkOption
    mkEnableOption
    mkPackageOption
    mkIf
    ;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = [ lib.maintainers.rachitvrma ];

  options.programs.stylua = {
    enable = mkEnableOption "stylua, a formatter for lua";
    package = mkPackageOption pkgs "stylua" { };
    settings = mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = {
        call_parentheses = "Always";
        collapse_simple_statement = "Always";
        column_width = 85;
        indent_type = "Spaces";
        indent_width = 2;
        line_endings = "Unix";
        quote_style = "AutoPreferSingle";
      };
      description = ''
        Configuration options that are written to {file}`XDG_CONFIG_HOME/stylua/stylua.toml`.
        To use this configuration file pass the `--search-parent-directories` flag to `stylua`.
        Many formatters use this flag by default (for example `conform.nvim` passes this flag to stylua
        by default).

        See <https://github.com/JohnnyMorganz/StyLua#options> for more options.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."stylua/stylua.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "hm_stylua.toml" cfg.settings;
    };
  };
}
