{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.sheldon;
  tomlFormat = pkgs.formats.toml {};
in {
  meta.maintainers = pkgs.sheldon.meta.maintainers;

  options.programs.sheldon = {
    enable = mkEnableOption "sheldon";

    package = mkOption {
      type = types.package;
      default = pkgs.sheldon;
      defaultText = literalExpression "pkgs.sheldon";
      description = "The package to use for the sheldon binary.";
    };

    settings = mkOption {
      inherit (tomlFormat) type;
      default = { };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.packages ];

    xdg.configFile."sheldon/plugins.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "sheldon-config" cfg.settings;
    };
  };
}
