{ lib, ... }:
import ./common.nix {
  inherit lib;
  name = "floorp";
}
