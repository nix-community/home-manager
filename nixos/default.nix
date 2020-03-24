nixpkgs:
{ config, lib, pkgs, utils, ... }:

with lib;

let

  cfg = config.home-manager;

  extendedLib = import ../modules/lib/stdlib-extended.nix pkgs.lib;

  hmModule = types.submoduleWith {
    specialArgs = { lib = extendedLib; };
    modules = [
      ({ name, ... }: {
        imports = import ../modules/modules.nix nixpkgs {
          inherit pkgs;
          lib = extendedLib;
          useNixpkgsModule = !cfg.useGlobalPkgs;
        };
 
        config = {
          submoduleSupport.enable = true;
          submoduleSupport.externalPackageInstall = cfg.useUserPackages;
 
          # The per-user directory inside /etc/profiles is not known by
          # fontconfig by default.
          fonts.fontconfig.enable =
            cfg.useUserPackages && config.fonts.fontconfig.enable;
 
          home.username = config.users.users.${name}.name;
          home.homeDirectory = config.users.users.${name}.home;
        };
      })
    ];
  };

  serviceEnvironment =
    optionalAttrs (cfg.backupFileExtension != null) {
      HOME_MANAGER_BACKUP_EXT = cfg.backupFileExtension;
    }
    // optionalAttrs cfg.verbose {
      VERBOSE = "1";
    };

in {
  options = {
    home-manager = {
      useUserPackages = mkEnableOption ''
        installation of user packages through the
        <option>users.users.‹name?›.packages</option> option.
      '';

      useGlobalPkgs = mkEnableOption ''
        using the system configuration's <literal>pkgs</literal>
        argument in Home Manager. This disables the Home Manager
        options <option>nixpkgs.*</option>
      '';

      backupFileExtension = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "backup";
        description = ''
          On activation move existing files by appending the given
          file extension rather than exiting with an error.
        '';
      };

      verbose = mkEnableOption "verbose output on activation";

      users = mkOption {
        type = types.attrsOf hmModule;
        default = { };
        description = ''
          Per-user Home Manager configuration.
        '';
      };
    };
  };

  config = mkIf (cfg.users != { }) {
    warnings = flatten (flip mapAttrsToList cfg.users (user: config:
      flip map config.warnings (warning: "${user} profile: ${warning}")));

    assertions = flatten (flip mapAttrsToList cfg.users (user: config:
      flip map config.assertions (assertion: {
        inherit (assertion) assertion;
        message = "${user} profile: ${assertion.message}";
      })));

    users.users = mkIf cfg.useUserPackages
      (mapAttrs (username: usercfg: { packages = usercfg.home.packages; })
        cfg.users);

    systemd.services = mapAttrs' (_: usercfg:
      let username = usercfg.home.username;
      in nameValuePair ("home-manager-${utils.escapeSystemdPath username}") {
        description = "Home Manager environment for ${username}";
        wantedBy = [ "multi-user.target" ];
        wants = [ "nix-daemon.socket" ];
        after = [ "nix-daemon.socket" ];

        environment = serviceEnvironment;

        serviceConfig = {
          User = usercfg.home.username;
          Type = "oneshot";
          RemainAfterExit = "yes";
          SyslogIdentifier = "hm-activate-${username}";

          # The activation script is run by a login shell to make sure
          # that the user is given a sane Nix environment.
          ExecStart = pkgs.writeScript "activate-${username}" ''
            #! ${pkgs.runtimeShell} -el
            echo Activating home-manager configuration for ${username}
            exec ${usercfg.home.activationPackage}/activate
          '';
        };
      }) cfg.users;
  };
}
