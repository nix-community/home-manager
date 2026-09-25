{ lib, pkgs, ... }:
let
  darwinConfig = (
    lib.evalModules {
      specialArgs = {
        inherit pkgs;
        _class = "darwin";
      };

      modules = [
        ../../../nix-darwin
        (_: {
          options.users.users = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submodule (
                { name, ... }:
                {
                  options = {
                    name = lib.mkOption {
                      type = lib.types.str;
                      default = name;
                    };
                    home = lib.mkOption { type = lib.types.str; };
                    uid = lib.mkOption { type = lib.types.int; };
                    packages = lib.mkOption {
                      type = lib.types.listOf lib.types.package;
                      default = [ ];
                    };
                  };
                }
              )
            );
            default = { };
          };

          options.programs.fish.enable = lib.mkEnableOption "system Fish integration";

          options.environment.pathsToLink = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };

          options.system.activationScripts = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submodule (_: {
                options.text = lib.mkOption {
                  type = lib.types.lines;
                  default = "";
                };
              })
            );
            default = { };
          };

          options.nix.enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
          };

          options.nix.package = lib.mkOption {
            type = lib.types.package;
            default = pkgs.nix;
          };

          options.warnings = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };

          options.assertions = lib.mkOption {
            type = lib.types.listOf (
              lib.types.submodule (_: {
                options.assertion = lib.mkOption { type = lib.types.bool; };
                options.message = lib.mkOption { type = lib.types.str; };
              })
            );
            default = [ ];
          };

          config = {
            home-manager.useUserPackages = true;

            users.users.alice.home = "/Users/alice";

            home-manager.users.alice = {
              home.stateVersion = "24.11";
              programs.fish.enable = true;
            };
          };
        })
      ];
    }
  );

  warning = "Home Manager fish users may be missing package-provided completions.";
  hasWarning = cfg: lib.any (message: lib.hasInfix warning message) cfg.warnings;
  evaluate = extra: darwinConfig.extendModules { modules = [ extra ]; };
in
{
  nmt.script =
    let
      enabled = evaluate { programs.fish.enable = true; };
      disabled = evaluate { programs.fish.enable = false; };
      inherited = evaluate {
        home-manager.users.alice =
          { osConfig, ... }:
          {
            programs.fish.enable = lib.mkForce osConfig.programs.fish.enable;
          };
      };
      privateProfile = evaluate { home-manager.useUserPackages = lib.mkForce false; };
      noUsers = evaluate { home-manager.users = lib.mkForce { }; };
    in
    ''
      test "${builtins.toJSON (hasWarning darwinConfig.config)}" = true
      test "${builtins.toJSON (hasWarning enabled.config)}" = false
      test "${builtins.toJSON (hasWarning disabled.config)}" = false
      test "${builtins.toJSON (hasWarning inherited.config)}" = false
      test "${builtins.toJSON (hasWarning privateProfile.config)}" = false
      test "${builtins.toJSON (hasWarning noUsers.config)}" = false
    '';
}
