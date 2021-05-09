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
          The default path to use for Home Manager. If this path does
          not exist then
          <filename>$HOME/.config/nixpkgs/home-manager</filename> and
          <filename>$HOME/.nixpkgs/home-manager</filename> will be
          attempted.
        '';
      };
    };
  };

  config = mkIf (cfg.enable && !config.submoduleSupport.enable) {
    home.packages =
      [ (pkgs.callPackage ../../home-manager { inherit (cfg) path; }) ];
  };
}
