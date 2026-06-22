{ lib }:
{
  inherit ((import ../modules/lib/stdlib-extended.nix lib)) hm;

  homeManagerConfiguration = import ./eval-config.nix;
}
