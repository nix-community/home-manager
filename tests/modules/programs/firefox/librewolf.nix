{ lib, ... }:
import ./common.nix {
  inherit lib;
  name = "librewolf";
}
