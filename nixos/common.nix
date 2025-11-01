# This module is the common base for the NixOS and nix-darwin modules.
# For OS-specific configuration, please edit nixos/default.nix or nix-darwin/default.nix instead.

{
  options,
  config,
  lib,
  pkgs,
  _class,
  ...
}:

let
  inherit (lib)
    flip
    mkOption
    mkEnableOption
    mkIf
    types
    ;

  cfg = config.home-manager;

  extendedLib = import ../modules/lib/stdlib-extended.nix lib;

  hmModule = types.submoduleWith {
    description = "Home Manager module";
    class = "homeManager";
    specialArgs = {
      lib = extendedLib;
      osConfig = config;
      osClass = _class;
      modulesPath = builtins.toString ../modules;
    }
    // cfg.extraSpecialArgs;

    modules = [
      (
        { name, ... }:
        {
          imports =
            import ../modules/modules.nix {
              inherit pkgs;
              lib = extendedLib;
              useNixpkgsModule = !cfg.useGlobalPkgs;
            }
            ++ cfg.sharedModules;

          config = {
            submoduleSupport.enable = true;
            submoduleSupport.externalPackageInstall = cfg.useUserPackages;

            home.username = config.users.users.${name}.name;
            home.homeDirectory = config.users.users.${name}.home;

            # Forward `nix.enable` from the OS configuration. The
            # conditional is to check whether nix-darwin is new enough
            # to have the `nix.enable` option; it was previously a
            # `mkRemovedOptionModule` error, which we can crudely detect
            # by `visible` being set to `false`.
            nix.enable = mkIf (options.nix.enable.visible or true) config.nix.enable;

            # Make activation script use same version of Nix as system as a whole.
            # This avoids problems with Nix not being in PATH.
            nix.package = config.nix.package;
          };
        }
      )
    ];
  };

in
{
  options.home-manager = {
    useUserPackages = mkEnableOption ''
      installation of user packages through the
      {option}`users.users.<name>.packages` option'';

    useGlobalPkgs = mkEnableOption ''
      using the system configuration's `pkgs`
      argument in Home Manager. This disables the Home Manager
      options {option}`nixpkgs.*`'';

    backupCommand = mkOption {
      type = types.nullOr (types.either types.str types.path);
      default = null;
      example = lib.literalExpression "''${pkgs.trash-cli}/bin/trash";
      description = ''
        On activation run this command on each existing file
        rather than exiting with an error.
      '';
    };

    backupFileExtension = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "backup";
      description = ''
        On activation move existing files by appending the given
        file extension rather than exiting with an error.
      '';
    };

    overwriteBackup = mkEnableOption ''
      forced overwriting of existing backup files when using `backupFileExtension`
    '';

    extraSpecialArgs = mkOption {
      type = types.attrs;
      default = { };
      example = lib.literalExpression "{ inherit emacs-overlay; }";
      description = ''
        Extra `specialArgs` passed to Home Manager. This
        option can be used to pass additional arguments to all modules.
      '';
    };

    sharedModules = mkOption {
      type = with types; listOf raw;
      default = [ ];
      example = lib.literalExpression "[ { home.packages = [ nixpkgs-fmt ]; } ]";
      description = ''
        Extra modules added to all users.
      '';
    };

    verbose = mkEnableOption "verbose output on activation";

    enableOSConfigurationChanges = mkEnableOption ''
      Home Manager changing the OS configuration if necessary to make a Home Manager option work
    '';

    enableLegacyProfileManagement = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable legacy profile management during activation. When
        enabled, the Home Manager activation will produce a per-user
        `home-manager` Nix profile, just like in the standalone installation of
        Home Manager. Typically, this is not desired when Home Manager is
        embedded in the system configuration.
      '';
    };

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

  config = (
    lib.mkMerge [
      # Fix potential recursion when configuring home-manager users based on values in users.users #594
      (mkIf (cfg.useUserPackages && cfg.users != { }) {
        users.users = (lib.mapAttrs (_username: usercfg: { packages = [ usercfg.home.path ]; }) cfg.users);
        environment.pathsToLink = [ "/etc/profile.d" ];
      })
      (mkIf (cfg.users != { }) {
        warnings = lib.flatten (
          flip lib.mapAttrsToList cfg.users (
            user: config: flip map config.warnings (warning: "${user} profile: ${warning}")
          )
        );

        assertions = lib.flatten (
          flip lib.mapAttrsToList cfg.users (
            user: config:
            flip map config.assertions (assertion: {
              inherit (assertion) assertion;
              message = "${user} profile: ${assertion.message}";
            })
          )
        );
      })
    ]
  );
}
