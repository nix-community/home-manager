{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.arf;
  tomlFormat = pkgs.formats.toml { };
in

{
  meta.maintainers = [ lib.maintainers.hectorgray ];

  options.programs.arf = {
    enable = lib.mkEnableOption "arf, a modern R console";
    package = lib.mkPackageOption pkgs "arf" { nullable = true; };

    settings = lib.mkOption {
      inherit (tomlFormat) type;
      default = { };

      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/arf/arf.toml`. See
        <https://github.com/eitsupi/arf/blob/main/docs/configuration.md> for
        all available options.
      '';

      example = {
        editor.auto_suggestions = "cwd";
        editor.key_map = {
          alt-a = " <- ";
          alt-p = " |>\n";
          alt-l = "\\(x) ";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."arf/arf.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "arf.toml" cfg.settings;
    };
  };
}
