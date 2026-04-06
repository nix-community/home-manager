{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux (
  lib.pipe (builtins.readDir ./by-name) [
    (lib.filterAttrs (_: kind: kind == "regular"))
    (lib.mapAttrs' (
      name: _:
      lib.nameValuePair "retroarch-${lib.removeSuffix ".nix" name}" {
        imports = [
          (./by-name + "/${name}")
          ./stubs.nix
        ];
      }
    ))
  ]
)
