{ config, lib, pkgs, utils, ... }:

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
    users.users = mapAttrs (username: usercfg: {
      packages = usercfg.home.packages;
    }) cfg.users;

    systemd.services = mapAttrs' (username: usercfg:
      nameValuePair ("home-manager-${utils.escapeSystemdPath username}") {
        description = "Home Manager environment for ${username}";
        wantedBy = [ "multi-user.target" ];
        wants = [ "nix-daemon.socket" ];
        after = [ "nix-daemon.socket" ];

        serviceConfig = {
          User = username;
          Type = "oneshot";
          RemainAfterExit = "yes";
          SyslogIdentifier = "hm-activate-${username}";

          # The activation script is run by a login shell to make sure
          # that the user is given a sane Nix environment.
          ExecStart = pkgs.writeScript "activate-${username}" ''
            #! ${pkgs.stdenv.shell} -el
            echo Activating home-manager configuration for ${username}
            exec ${usercfg.home.activationPackage}/activate
          '';
        };
      }
    ) cfg.users;
  };
}
