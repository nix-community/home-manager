{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.home-manager;

  hmModule = types.submodule (
    import ../modules/modules.nix {
      inherit lib pkgs;
      nixosSubmodule = true;
    }
  );

  activateUser = username: usercfg: ''
    echo Activating home-manager configuration for ${username}
    ${pkgs.sudo}/bin/sudo -u ${username} ${usercfg.home.activationPackage}/activate
  '';

in

{
  options = {
    home-manager.users = mkOption {
      type = types.attrsOf hmModule;
      default = {};
      description = ''
        Per-user Home Manager configuration.
      '';
    };
  };

  config = {
    system.activationScripts.home-manager =
      stringAfter [ "users" ] (
        concatStringsSep "\n" (
          mapAttrsToList activateUser cfg.users));

    users.users = mapAttrs (n: v: { packages = v.home.packages; } ) cfg.users;
  };
}
