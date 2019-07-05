{ config, lib, pkgs, ... }:

with lib;

let

  homeDirectory = config.home.homeDirectory;

  fileType = (import ../../lib/file-type.nix {
    inherit homeDirectory lib pkgs;
  }).fileType;

  cfg = config.programs.spacemacs;
in
{
  meta.maintainers = [ ]; #TODO

  options = {
    programs.spacemacs = {
      enable = mkEnableOption "Spacemacs";

      configFile = mkOption {
        type = types.nullOr types.str;
        default = "${homeDirectory}/spacemacs";
        defaultText = "${homeDirectory}/spacemacs";
        example = "${homeDirectory}/dotfiles/spacemacs";
        description = "The spacemacs dotfile to use";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ (pkgs.callPackage ./. { spacemacs = cfg.configFile; }) ];
  };
}
