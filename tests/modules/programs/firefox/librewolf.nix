{ lib, ... }:
import ./common.nix {
  inherit lib;
  name = "librewolf";
  # These shared tests force the real browser wrapper or package into the test
  # derivation. Librewolf is insecure in nixpkgs, so keep testing the shared
  # module logic through Firefox and Floorp instead.
  excludeTests = [
    "librewolf-final-package"
    "librewolf-policies"
    "librewolf-profiles-bookmarks"
  ];
}
