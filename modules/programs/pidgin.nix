{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.pidgin;

in {
  meta.maintainers = [ maintainers.rycee ];

  options = {
    programs.pidgin = {
      enable = mkEnableOption (lib.mdDoc "Pidgin messaging client");

      package = mkOption {
        type = types.package;
        default = pkgs.pidgin;
        defaultText = literalExpression "pkgs.pidgin";
        description = lib.mdDoc "The Pidgin package to use.";
      };

      plugins = mkOption {
        default = [ ];
        example = literalExpression "[ pkgs.pidgin-otr pkgs.pidgin-osd ]";
        description = lib.mdDoc "Plugins that should be available to Pidgin.";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ (cfg.package.override { inherit (cfg) plugins; }) ];
  };
}
