{ pkgs, config, lib, ... }:
let
  tomlFormat = pkgs.formats.toml { };
  configDir = if pkgs.stdenv.isDarwin then
    "Library/Application Support"
  else
    config.xdg.configHome;
  cfg = config.programs.poetry;
in {
  meta.maintainers = with lib.maintainers; [ mirkolenz ];
  options.programs.poetry = with lib; {
    enable = mkEnableOption "poetry";
    package = mkOption {
      type = types.package;
      default = pkgs.poetry;
      defaultText = literalExpression "pkgs.poetry";
      description = "The poetry package to use (e.g., with custom plugins).";
      example = literalExpression
        "pkgs.poetry.withPlugins (ps: with ps; [ poetry-plugin-up ])";
    };
    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/pypoetry/config.toml` on Linux or
        {file}`$HOME/Library/Application Support/pypoetry/config.toml` on Darwin.
        See
        <https://python-poetry.org/docs/configuration/>
        for more information.
      '';
      example = literalExpression ''
        {
          virtualenvs.create = true;
          virtualenvs.in-project = true;
        }
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
