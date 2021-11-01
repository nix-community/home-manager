{ config, lib, pkgs, utils, ... }:

with lib;

let

  cfg = config.home-manager;

  extendedLib = import ../modules/lib/stdlib-extended.nix pkgs.lib;

  hmModule = types.submoduleWith {
    specialArgs = {
      lib = extendedLib;
      nixosConfig = config;
      osConfig = config;
      modulesPath = ../modules;
    } // cfg.extraSpecialArgs;
    modules = [
      ({ name, ... }: {
        imports = import ../modules/modules.nix {
          inherit pkgs;
          lib = extendedLib;
          useNixpkgsModule = !cfg.useGlobalPkgs;
        };

        config = {
          submoduleSupport.enable = true;
          submoduleSupport.externalPackageInstall = cfg.useUserPackages;

          # The per-user directory inside /etc/profiles is not known by
          # fontconfig by default.
          fonts.fontconfig.enable = cfg.useUserPackages
            && config.fonts.fontconfig.enable;

          home.username = config.users.users.${name}.name;
          home.homeDirectory = config.users.users.${name}.home;

          # Make activation script use same version of Nix as system as a whole.
          # This avoids problems with Nix not being in PATH.
          home.extraActivationPath = [ config.nix.package ];
        };
      })
    ] ++ cfg.sharedModules;
  };

  serviceEnvironment = optionalAttrs (cfg.backupFileExtension != null) {
    HOME_MANAGER_BACKUP_EXT = cfg.backupFileExtension;
  } // optionalAttrs cfg.verbose { VERBOSE = "1"; };

in {
  options = {
    home-manager = {
      useUserPackages = mkEnableOption ''
        installation of user packages through the
        <option>users.users.&lt;name&gt;.packages</option> option.
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

      extraSpecialArgs = mkOption {
        type = types.attrs;
        default = { };
        example = literalExpression "{ inherit emacs-overlay; }";
        description = ''
          Extra <literal>specialArgs</literal> passed to Home Manager. This
          option can be used to pass additional arguments to all modules.
        '';
      };

      sharedModules = mkOption {
        type = with types;
        # TODO: use types.raw once this PR is merged: https://github.com/NixOS/nixpkgs/pull/132448
          listOf (mkOptionType {
            name = "submodule";
            inherit (submodule { }) check;
            merge = lib.options.mergeOneOption;
            description = "Home Manager modules";
          });
        default = [ ];
        example = literalExpression "[ { home.packages = [ nixpkgs-fmt ]; } ]";
        description = ''
          Extra modules added to all users.
        '';
      };

      verbose = mkEnableOption "verbose output on activation";

      users = mkOption {
        type = types.attrsOf hmModule;
        default = { };
        # Set as not visible to prevent the entire submodule being included in
        # the documentation.
        visible = false;
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
      (mapAttrs (username: usercfg: { packages = [ usercfg.home.path ]; })
        cfg.users);

    environment.pathsToLink = mkIf cfg.useUserPackages [ "/etc/profile.d" ];

    systemd.services = mapAttrs' (_: usercfg:
      let username = usercfg.home.username;
      in nameValuePair ("home-manager-${utils.escapeSystemdPath username}") {
        description = "Home Manager environment for ${username}";
        wantedBy = [ "multi-user.target" ];
        wants = [ "nix-daemon.socket" ];
        after = [ "nix-daemon.socket" ];
        before = [ "systemd-user-sessions.service" ];

        environment = serviceEnvironment;

        unitConfig = { RequiresMountsFor = usercfg.home.homeDirectory; };

        stopIfChanged = false;

        serviceConfig = {
          User = usercfg.home.username;
          Type = "oneshot";
          RemainAfterExit = "yes";
          TimeoutStartSec = 90;
          SyslogIdentifier = "hm-activate-${username}";

          ExecStart = let
            systemctl =
              "XDG_RUNTIME_DIR=\${XDG_RUNTIME_DIR:-/run/user/$UID} systemctl";

            sed = "${pkgs.gnused}/bin/sed";

            exportedSystemdVariables = concatStringsSep "|" [
              "DBUS_SESSION_BUS_ADDRESS"
              "DISPLAY"
              "WAYLAND_DISPLAY"
              "XAUTHORITY"
              "XDG_RUNTIME_DIR"
            ];

            setupEnv = pkgs.writeScript "hm-setup-env" ''
              #! ${pkgs.runtimeShell} -el

              # The activation script is run by a login shell to make sure
              # that the user is given a sane environment.
              # If the user is logged in, import variables from their current
              # session environment.
              eval "$(
                ${systemctl} --user show-environment 2> /dev/null \
                | ${sed} -En '/^(${exportedSystemdVariables})=/s/^/export /p'
              )"

              exec "$1/activate"
            '';
          in "${setupEnv} ${usercfg.home.activationPackage}";
        };
      }) cfg.users;
  };
}
