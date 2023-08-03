{ pkgsPath, lib, check ? true }:

let
  baseModules = (import ./module-list.nix) ++ [
    ./misc/nixpkgs.nix
    ("${pkgsPath}/nixos/modules/misc/assertions.nix")
    ("${pkgsPath}/nixos/modules/misc/meta.nix")
  ];

in baseModules ++ [{
  _module = {
    inherit check;
    args = {
      inherit baseModules pkgsPath;
      modulesPath = toString ./.;
    };
  };
  lib = lib.hm;
}

]
