{ config, lib, pkgs, utils, ... }:

with lib;

let

  cfg = config.home-manager;

  hmModule = types.submodule ({name, ...}: {
    imports = import ../modules/modules.nix { inherit lib pkgs; };

    config = {
      submoduleSupport.enable = true;
      submoduleSupport.externalPackageInstall = cfg.useUserPackages;

      # The per-user directory inside /etc/profiles is not known by
      # fontconfig by default.
      fonts.fontconfig.enableProfileFonts =
        cfg.useUserPackages && config.fonts.fontconfig.enable;

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
        <option>users.users.&lt;name?&gt;.packages</option> option.
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

    systemd.services = mapAttrs' (_: usercfg:
      let
        username = usercfg.home.username;
      in
        nameValuePair ("home-manager-${utils.escapeSystemdPath username}") {
          description = "Home Manager environment for ${username}";
          wantedBy = [ "multi-user.target" ];
          wants = [ "nix-daemon.socket" ];
          after = [ "nix-daemon.socket" ];

          serviceConfig = {
            User = usercfg.home.username;
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
