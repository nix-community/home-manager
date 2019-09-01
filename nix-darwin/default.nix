{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.home-manager;

  hmModule = types.submodule ({name, ...}: {
    imports = import ../modules/modules.nix { inherit lib pkgs; };

    config = {
      submoduleSupport.enable = true;
      submoduleSupport.externalPackageInstall = cfg.useUserPackages;

      home.username = config.users.users.${name}.name;
      home.homeDirectory = config.users.users.${name}.home;
    };
  });

in

{
  options = {
    home-manager = {
      useUserPackages = mkEnableOption ''
        installation of user packages through the
        <option>users.users.‹name?›.packages</option> option.
      '';

      users = mkOption {
        type = types.attrsOf hmModule;
        default = {};
        description = ''
          Per-user Home Manager configuration.
        '';
      };
    };
  };

  config = mkIf (cfg.users != {}) {
    warnings =
      flatten (flip mapAttrsToList cfg.users (user: config:
        flip map config.warnings (warning:
          "${user} profile: ${warning}"
        )
      ));

    assertions =
      flatten (flip mapAttrsToList cfg.users (user: config:
        flip map config.assertions (assertion:
          {
            inherit (assertion) assertion;
            message = "${user} profile: ${assertion.message}";
          }
        )
      ));

    users.users = mkIf cfg.useUserPackages (
      mapAttrs (username: usercfg: {
        packages = usercfg.home.packages;
      }) cfg.users
    );

    system.activationScripts.postActivation.text =
      concatStringsSep "\n" (mapAttrsToList (username: usercfg: ''
        echo Activating home-manager configuration for ${username}
        sudo -u ${username} -i ${usercfg.home.activationPackage}/activate
      '') cfg.users);
  };
}
