{ lib, pkgs, ... }:
let
  nixosLib = import /${pkgs.path}/nixos/lib { inherit lib; };

  getHomeUid =
    userConfig:
    (nixosLib.evalTest {
      hostPkgs = pkgs;
      nodes.machine.imports = [
        ../../../nixos
        {
          users.users.alice = {
            isNormalUser = true;
          }
          // userConfig;

          home-manager.users.alice.home.stateVersion = "24.11";
        }
      ];
    }).config.nodes.machine.home-manager.users.alice.home.uid;

  getCommonModuleHomeUidResult =
    userConfig:
    builtins.tryEval (
      (lib.evalModules {
        specialArgs = {
          inherit pkgs;
          _class = "darwin";
        };

        modules = [
          ../../../nixos/common.nix
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

            options.environment.pathsToLink = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
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

            config.users.users.alice = {
              home = "/Users/alice";
            }
            // userConfig;

            config.home-manager.users.alice.home.stateVersion = "24.11";
          })
        ];
      }).config.home-manager.users.alice.home.uid
    );

  forwardedUid = builtins.toJSON (getHomeUid {
    uid = 1000;
  });
  unsetUid = builtins.toJSON (getHomeUid { });
  commonUnsetUidResult = getCommonModuleHomeUidResult { };
  commonUnsetUidSuccess = builtins.toJSON commonUnsetUidResult.success;
  commonUnsetUidValue = builtins.toJSON (
    if commonUnsetUidResult.success then commonUnsetUidResult.value else "failed"
  );
in
{
  nmt.script = ''
    test "${forwardedUid}" = '1000'
    test "${unsetUid}" = 'null'
    test "${commonUnsetUidSuccess}" = 'true'
    test "${commonUnsetUidValue}" = 'null'
  '';
}
