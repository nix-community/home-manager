{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.ncspot;

  tomlFormat = pkgs.formats.toml { };

in {
  meta.maintainers = [ ];

  options.programs.ncspot = {
    enable = mkEnableOption "ncspot";

    package = mkOption {
      type = types.package;
      default = pkgs.ncspot;
      defaultText = literalExpression "pkgs.ncspot";
      description = "The package to use for ncspot.";
    };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      example = literalExpression ''
        {
          shuffle = true;
          gapless = true;
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/ncspot/config.toml`.

        See <https://github.com/hrkfdn/ncspot#configuration>
        for the full list of options.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."ncspot/config.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "ncspot-config" cfg.settings;
    };
  };
}
