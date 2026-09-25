{ lib, ... }:
lib.pipe (builtins.readDir ./by-name) [
  (lib.filterAttrs (_: kind: kind == "regular"))
  (lib.mapAttrs' (
    name: _:
    lib.nameValuePair "retroarch-${lib.removeSuffix ".nix" name}" {
      _file = ./by-name + "/${name}";
      imports = [
        (./by-name + "/${name}")
        ./stubs.nix
      ];
    }
  ))
]
