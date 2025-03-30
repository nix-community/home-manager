{ config, lib, pkgs, ... }:
let cfg = config.programs.home-manager;
in {
  meta.maintainers = [ lib.maintainers.rycee ];

  options = {
    programs.home-manager = {
      enable = lib.mkEnableOption "Home Manager";

      path = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
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

  config = lib.mkIf (cfg.enable && !config.submoduleSupport.enable) {
    home.packages =
      [ (pkgs.callPackage ../../home-manager { inherit (cfg) path; }) ];
  };
}
