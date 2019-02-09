{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.home-manager;

  hmModule = types.submodule ({name, ...}: {
    imports = import ../modules/modules.nix { inherit lib pkgs; };

    config = {
      submoduleSupport.enable = true;
      home.username = config.users.users.${name}.name;
      home.homeDirectory = config.users.users.${name}.home;
    };
  });

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

  config = mkIf (cfg.users != {}) {
    system.activationScripts.extraActivation.text =
      lib.concatStringsSep "\n" (lib.mapAttrsToList (username: usercfg: ''
        echo Activating home-manager configuration for ${username}
        sudo -u ${username} ${usercfg.home.activationPackage}/activate
      '') cfg.users);
  };
}
