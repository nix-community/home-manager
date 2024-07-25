{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.sheldon;
  tomlFormat = pkgs.formats.toml { };
  cmd = "${config.home.profileDirectory}/bin/sheldon";
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
      description = "";
      example = literalExpression "";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."sheldon/plugins.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "sheldon-config" cfg.settings;
    };

    programs.bash.initExtra = mkIf (cfg.settings != { }) ''
      eval "$(sheldon source)"
    '';

    programs.zsh.initExtra = mkIf (cfg.settings != { }) ''
      eval "$(sheldon source)"
    '';
  };
}
