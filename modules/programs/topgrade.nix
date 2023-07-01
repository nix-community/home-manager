{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.topgrade;

  tomlFormat = pkgs.formats.toml { };

in {

  meta.maintainers = [ hm.maintainers.msfjarvis ];

  options.programs.topgrade = {
    enable = mkEnableOption "topgrade";

    package = mkOption {
      type = types.package;
      default = pkgs.topgrade;
      defaultText = literalExpression "pkgs.topgrade";
      description = "The package to use for the topgrade binary.";
    };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      defaultText = literalExpression "{ }";
      example = literalExpression ''
        {
          assume_yes = true;
          disable = [
            "flutter"
            "node"
          ];
          set_title = false;
          cleanup = true;
          commands = {
            "Run garbage collection on Nix store" = "nix-collect-garbage";
          };
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/topgrade.toml`.

        See <https://github.com/r-darwish/topgrade/wiki/Step-list> for the full list
        of options.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."topgrade.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "topgrade-config" cfg.settings;
    };
  };
}
