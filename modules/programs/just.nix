{ lib, ... }:

{
  imports = let
    msg = ''
      'program.just' is deprecated, simply add 'pkgs.just' to 'home.packages' instead.
      See https://github.com/nix-community/home-manager/issues/3449#issuecomment-1329823502'';

    removed = opt: lib.mkRemovedOptionModule [ "programs" "just" opt ] msg;
  in map removed [
    "enable"
    "enableBashIntegration"
    "enableZshIntegration"
    "enableFishIntegration"
  ];
}
