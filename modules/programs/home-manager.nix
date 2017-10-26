{ config, lib, pkgs, ... }:

with lib;
with import ../lib/dag.nix { inherit lib; };

let

  cfg = config.programs.home-manager;

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

      modulesPath = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "$HOME/devel/home-manager/modules";
        description = ''
          The default path to use for Home Manager modules. If this
          path does not exist then
          <filename>$HOME/.config/nixpkgs/home-manager/modules</filename>
          and <filename>$HOME/.nixpkgs/home-manager/modules</filename>
          will be attempted. DEPRECATED: Use
          <varname>programs.home-manager.path</varname> instead.
        '';
      };
    };
  };

  config = mkIf (cfg.enable && !config.nixosSubmodule) {
    assertions = [{
      assertion = cfg.path == null || cfg.modulesPath == null;
      message = "Cannot simultaneously use "
        + "'programs.home-manager.path' and "
        + "'programs.home-manager.modulesPath'.";
    }];

    home.packages = [
      (import ../../home-manager {
        inherit pkgs;
        path =
          if cfg.modulesPath != null
          then "$(dirname ${cfg.modulesPath})"
          else cfg.path;
      })
    ];

    # Uninstall manually installed home-manager, if such exists.
    # Without this a file collision error will be printed.
    home.activation.uninstallHomeManager =
      dagEntryBetween [ "installPackages" ] [ "writeBoundary" ] ''
        if nix-env -q | grep -q "^home-manager$" ; then
          $DRY_RUN_CMD nix-env -e home-manager

          echo "You can now remove the 'home-manager' packageOverride"
          echo "or overlay in '~/.config/nixpkgs/', if you want."
        fi
      '';
  };
}
