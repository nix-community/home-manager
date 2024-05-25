{ pkgs, config, lib, ... }:

let

  inherit (lib) mkEnableOption mkPackageOption mkOption literalExpression;

  tomlFormat = pkgs.formats.toml { };

  configDir = if pkgs.stdenv.isDarwin then
    "Library/Application Support"
  else
    config.xdg.configHome;

  cfg = config.programs.poetry;

in {
  meta.maintainers = with lib.maintainers; [ mirkolenz ];

  options.programs.poetry = {
    enable = mkEnableOption "poetry";

    package = mkPackageOption pkgs "poetry" {
      example = "pkgs.poetry.withPlugins (ps: with ps; [ poetry-plugin-up ])";
      extraDescription = "May be used to install custom poetry plugins.";
    };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      example = literalExpression ''
        {
          virtualenvs.create = true;
          virtualenvs.in-project = true;
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/pypoetry/config.toml` on Linux or
        {file}`$HOME/Library/Application Support/pypoetry/config.toml` on Darwin.
        See
        <https://python-poetry.org/docs/configuration/>
        for more information.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file."${configDir}/pypoetry/config.toml" =
      lib.mkIf (cfg.settings != { }) {
        source = tomlFormat.generate "poetry-config" cfg.settings;
      };
  };
}
