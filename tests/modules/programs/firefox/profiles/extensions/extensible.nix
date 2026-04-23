modulePath:
{ lib, pkgs, ... }:

let
  homeManagerModules = import ../../../../../../modules/modules.nix {
    inherit lib pkgs;
    check = false;
  };
  extensionsOptionPath = modulePath ++ [
    "profiles"
    "default"
    "extensions"
  ];
  thirdPartyOptionPath = extensionsOptionPath ++ [ "thirdParty" ];
  packagesOptionPath = extensionsOptionPath ++ [ "packages" ];

  evalResult = builtins.tryEval (
    let
      evaluated = lib.evalModules {
        specialArgs = { inherit pkgs; };

        modules = homeManagerModules ++ [
          {
            home = {
              username = "hm-user";
              homeDirectory = "/home/hm-user";
              stateVersion = "25.05";
            };
          }
          {
            options = lib.setAttrByPath (modulePath ++ [ "profiles" ]) (
              lib.mkOption {
                type = lib.types.attrsOf (
                  lib.types.submodule {
                    options.extensions.thirdParty = lib.mkOption {
                      type = lib.types.bool;
                      default = false;
                      description = "Third-party regression test option.";
                    };
                  }
                );
              }
            );

            config = lib.setAttrByPath thirdPartyOptionPath true;
          }
          {
            config = lib.setAttrByPath packagesOptionPath [ pkgs.hello ];
          }
        ];
      };
    in
    {
      thirdParty = lib.getAttrFromPath thirdPartyOptionPath evaluated.config;
      packageCount = builtins.length (lib.getAttrFromPath packagesOptionPath evaluated.config);
    }
  );
in
{
  nmt.script = ''
    test '${builtins.toJSON evalResult.success}' = 'true'
    test '${
      builtins.toJSON (if evalResult.success then evalResult.value.thirdParty else null)
    }' = 'true'
    test '${builtins.toJSON (if evalResult.success then evalResult.value.packageCount else null)}' = '1'
  '';
}
