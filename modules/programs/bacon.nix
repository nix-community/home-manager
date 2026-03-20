{
  config,
  lib,
  pkgs,
  ...
}:
let

  cfg = config.programs.bacon;

  settingsFormat = pkgs.formats.toml { };

  configDir =
    if pkgs.stdenv.isDarwin then
      "Library/Application Support/org.dystroy.bacon"
    else
      "${config.xdg.configHome}/bacon";

in
{
  meta.maintainers = [ lib.maintainers.shimun ];

  options.programs.bacon = {
    enable = lib.mkEnableOption "bacon, a background rust code checker";

    package = lib.mkPackageOption pkgs "bacon" { nullable = true; };

    settings = lib.mkOption {
      type = settingsFormat.type;
      default = { };
      example = {
        jobs.default = {
          command = [
            "cargo"
            "build"
            "--all-features"
            "--color"
            "always"
          ];
          need_stdout = true;
        };
      };
      description = ''
        Bacon configuration written to either {file}`Library/Application Support/org.dystroy.bacon/prefs.toml`
        (darwin) or {file}`$XDG_CONFIG_HOME/bacon/prefs.toml`.
        For available settings see <https://dystroy.org/bacon/#global-preferences>.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    home.file."${configDir}/prefs.toml" = lib.mkIf (cfg.settings != { }) {
      source = settingsFormat.generate "bacon-prefs" cfg.settings;
    };
  };
}
