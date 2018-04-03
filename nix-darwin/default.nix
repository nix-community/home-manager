{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.home-manager;

  hmModule = types.submodule ({name, ...}: {
    imports = import ../modules/modules.nix {
      inherit lib pkgs;
      nixosSubmodule = true;
    };

    config = {
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
    launchd.daemons = mapAttrs' (username: usercfg:
      let escapeSystemdPath = s:
        replaceChars ["/" "-" " "] ["-" "\\x2d" "\\x20"]
          (if hasPrefix "/" s then substring 1 (stringLength s) s else s);
      in nameValuePair ("home-manager-${escapeSystemdPath username}") {
        # The activation script is run by a login shell to make sure
        # that the user is given a sane Nix environment.
        script = "${pkgs.writeScript "activate-${username}" ''
          #! ${pkgs.stdenv.shell} -el
          echo Activating home-manager configuration for ${username}
          exec ${usercfg.home.activationPackage}/activate
        ''}";

        serviceConfig = {
          UserName = username;
          RunAtLoad = true;
        };
      }
    ) cfg.users;
  };
}
