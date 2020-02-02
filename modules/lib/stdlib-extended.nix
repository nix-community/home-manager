# Just a convenience function that returns the given Nixpkgs standard
# library extended with the HM library.

nixpkgsLib:

let mkHmLib = import ./.;
in nixpkgsLib.extend (self: super: { hm = mkHmLib { lib = super; }; })
