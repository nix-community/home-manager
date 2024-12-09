# This module is the common base for the NixOS and nix-darwin modules.
# For OS-specific configuration, please edit nixos/default.nix or nix-darwin/default.nix instead.

{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.home-manager;

  extendedLib = import ../modules/lib/stdlib-extended.nix lib;

  hmModule = types.submoduleWith {
    description = "Home Manager module";
    class = "homeManager";
    specialArgs = {
      lib = extendedLib;
      osConfig = config;
      modulesPath = builtins.toString ../modules;
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

          home.username = config.users.users.${name}.name;
          home.homeDirectory = config.users.users.${name}.home;

          # Make activation script use same version of Nix as system as a whole.
          # This avoids problems with Nix not being in PATH.
          nix.package = config.nix.package;
        };
      })
    ] ++ cfg.sharedModules;
  };

in {
  options.home-manager = {
    useUserPackages = mkEnableOption ''
      installation of user packages through the
      {option}`users.users.<name>.packages` option'';

    useGlobalPkgs = mkEnableOption ''
      using the system configuration's `pkgs`
      argument in Home Manager. This disables the Home Manager
      options {option}`nixpkgs.*`'';

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
        Extra `specialArgs` passed to Home Manager. This
        option can be used to pass additional arguments to all modules.
      '';
    };

    sharedModules = mkOption {
      type = with types; listOf raw;
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
      # Prevent the entire submodule being included in the documentation.
      visible = "shallow";
      description = ''
        Per-user Home Manager configuration.
      '';
    };
  };

  config = (mkMerge [
    # Fix potential recursion when configuring home-manager users based on values in users.users #594
    (mkIf (cfg.useUserPackages && cfg.users != { }) {
      users.users =
        (mapAttrs (username: usercfg: { packages = [ usercfg.home.path ]; })
          cfg.users);
      environment.pathsToLink = [ "/etc/profile.d" ];
    })
    (mkIf (cfg.users != { }) {
      warnings = flatten (flip mapAttrsToList cfg.users (user: config:
        flip map config.warnings (warning: "${user} profile: ${warning}")));

      assertions = flatten (flip mapAttrsToList cfg.users (user: config:
        flip map config.assertions (assertion: {
          inherit (assertion) assertion;
          message = "${user} profile: ${assertion.message}";
        })));
    })
  ]);
}
