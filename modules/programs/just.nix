{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.just;

in {
  meta.maintainers = [ hm.maintainers.maximsmol ];

  imports = let
    msg = ''
      'program.just' is deprecated, simply add 'pkgs.just' to 'home.packages' instead.
      See https://github.com/nix-community/home-manager/issues/3449#issuecomment-1329823502'';
  in [
    (mkRemovedOptionModule [ "programs" "just" "enable" ] msg)
    (mkRemovedOptionModule [ "programs" "just" "enableBashIntegration" ] msg)
    (mkRemovedOptionModule [ "programs" "just" "enableZshIntegration" ] msg)
    (mkRemovedOptionModule [ "programs" "just" "enableFishIntegration" ] msg)
  ];
}
