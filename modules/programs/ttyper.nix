{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    literalExpression
    mkIf
    mkOption
    ;

  cfg = config.programs.ttyper;
  tomlFormat = pkgs.formats.toml { };

in
{
  meta.maintainers = [ lib.maintainers.philocalyst ];

  options.programs.ttyper = {
    enable = lib.mkEnableOption "ttyper, a terminal-based typing test";

    package = lib.mkPackageOption pkgs "ttyper" { nullable = true; };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/ttyper/config.toml`.
        See <https://github.com/max-niederman/ttyper> for all available options,
        including supported languages and theme keys.
      '';
      example = literalExpression ''
        {
          default_language = "english200";
          theme = {
            border_type = "rounded";
            prompt_correct = "green";
            prompt_incorrect = "red";
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile."ttyper/config.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "ttyper-config.toml" cfg.settings;
    };
  };
}
