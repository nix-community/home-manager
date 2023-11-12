{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.git-cliff;
  tomlFormat = pkgs.formats.toml { };

in {
  meta.maintainers = [ hm.maintainers.NateCox ];

  options.programs.git-cliff = {
    enable = mkEnableOption "git-cliff changelog generator";

    package = mkPackageOption pkgs "git-cliff" { };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      example = literalExpression ''
        {
          header = "Changelog";
          trim = true;
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/git-cliff/cliff.toml`. See
        <https://git-cliff.org/docs/configuration>
        for the documentation.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile = {
      "git-cliff/cliff.toml" = mkIf (cfg.settings != { }) {
        source = tomlFormat.generate "git-cliff-config" cfg.settings;
      };
    };
  };
}
