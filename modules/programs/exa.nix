{ lib, ... }:

{
  imports = let
    msg = ''
      'program.exa' has been removed because it is unmaintained upstream. Consider using 'program.eza', a maintained fork.
      See https://github.com/NixOS/nixpkgs/pull/253683'';

    removed = opt: lib.mkRemovedOptionModule [ "programs" "exa" opt ] msg;
  in map removed [ "enable" "enableAliases" "extraOptions" "icons" "git" ];
}
