{ config, lib, pkgs, ... }:
let cfg = config.programs.pidgin;
in {
  meta.maintainers = [ lib.maintainers.rycee ];

  options = {
    programs.pidgin = {
      enable = lib.mkEnableOption "Pidgin messaging client";

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.pidgin;
        defaultText = lib.literalExpression "pkgs.pidgin";
        description = "The Pidgin package to use.";
      };

      plugins = lib.mkOption {
        default = [ ];
        example = lib.literalExpression "[ pkgs.pidgin-otr pkgs.pidgin-osd ]";
        description = "Plugins that should be available to Pidgin.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ (cfg.package.override { inherit (cfg) plugins; }) ];
  };
}
