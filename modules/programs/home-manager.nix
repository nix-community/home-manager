{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.home-manager;

  dag = config.lib.dag;

in

{
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

  config = mkIf (cfg.enable && !config.nixosSubmodule) {
    home.packages = [
      (import ../../home-manager {
        inherit pkgs;
        inherit (cfg) path;
      })
    ];

    # Uninstall manually installed home-manager, if such exists.
    # Without this a file collision error will be printed.
    home.activation.uninstallHomeManager =
      dag.entryBetween [ "installPackages" ] [ "writeBoundary" ] ''
        if nix-env -q | grep -q "^home-manager$" ; then
          $DRY_RUN_CMD nix-env -e home-manager

          echo "You can now remove the 'home-manager' packageOverride"
          echo "or overlay in '~/.config/nixpkgs/', if you want."
        fi
      '';
  };
}
