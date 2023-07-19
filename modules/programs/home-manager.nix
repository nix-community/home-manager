{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.home-manager;

in {
  meta.maintainers = [ maintainers.rycee ];

  options = {
    programs.home-manager = {
      enable = mkEnableOption "Home Manager";

      path = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "$HOME/devel/home-manager";
        description = ''
          The default path to use for Home Manager. When
          `null`, then the {file}`home-manager`
          channel, {file}`$HOME/.config/nixpkgs/home-manager`, and
          {file}`$HOME/.nixpkgs/home-manager` will be attempted.
        '';
      };
    };
  };

  config = mkIf (cfg.enable && !config.submoduleSupport.enable) {
    home.packages =
      [ (pkgs.callPackage ../../home-manager { inherit (cfg) path; }) ];
  };
}
