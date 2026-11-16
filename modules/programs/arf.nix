{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.arf;
  tomlFormat = pkgs.formats.toml { };

  configDir =
    if pkgs.stdenv.hostPlatform.isDarwin then "Library/Application Support" else config.xdg.configHome;
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
        Configuration written to {file}`$XDG_CONFIG_HOME/arf/arf.toml` on Linux
        or {file}`$HOME/Library/Application Support/arf/arf.toml` on Darwin.
        See <https://github.com/eitsupi/arf/blob/main/docs/configuration.md>
        for all available options.
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

    home.file."${configDir}/arf/arf.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "arf.toml" cfg.settings;
    };
  };
}
