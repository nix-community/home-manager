{ config, lib, pkgs, ... }:
let
  cfg = config.programs.topgrade;

  tomlFormat = pkgs.formats.toml { };
in {

  meta.maintainers = [ lib.hm.maintainers.msfjarvis ];

  options.programs.topgrade = {
    enable = lib.mkEnableOption "topgrade";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.topgrade;
      defaultText = lib.literalExpression "pkgs.topgrade";
      description = "The package to use for the topgrade binary.";
    };

    settings = lib.mkOption {
      type = tomlFormat.type;
      default = { };
      defaultText = lib.literalExpression "{ }";
      example = lib.literalExpression ''
        {
          misc = {
            assume_yes = true;
            disable = [
              "flutter"
              "node"
            ];
            set_title = false;
            cleanup = true;
          };
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

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."topgrade.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "topgrade-config" cfg.settings;
    };
  };
}
