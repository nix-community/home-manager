{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.chawan;
  tomlFormat = (pkgs.formats.toml { });
  tomlType = tomlFormat.type;
  toConf = tomlFormat.generate "config.toml";
in
{
  meta.maintainers = [ lib.maintainers.noodlez1232 ];

  options.programs.chawan = {
    enable = lib.mkEnableOption "chawan, A TUI web browser";
    package = lib.mkPackageOption pkgs "chawan" { nullable = true; };
    settings = lib.mkOption {
      default = { };
      type = tomlType;
      description = ''
        Configuration options for chawan.

        See {manpage}`cha-config(5)`
      '';
      example = lib.literalExpression ''
        {
          buffer = {
            images = true;
            autofocus = true;
          };
          pager."C-k" = "() => pager.load('https://duckduckgo.com/?=')";
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile = lib.mkIf (cfg.settings != { }) {
      "chawan/config.toml" = {
        source = toConf cfg.settings;
      };
    };
  };
}
