# Just a convenience function that returns the given Nixpkgs standard
# library extended with the HM library.

nixpkgsLib:

let
  mkHmLib = import ./.;
in
nixpkgsLib.extend (
  self: super:
  let
    hmLib = mkHmLib { lib = self; };
  in
  {
    hm = hmLib;

    # Nixpkgs now validates meta.maintainers against lib.maintainers.
    # Mirror Home Manager-only maintainers there so existing lib.hm.maintainers
    # references continue to satisfy the upstream type check.
    maintainers = super.maintainers // hmLib.maintainers;
  }
)
