{ realPkgs, ... }:

{
  nixpkgs.overlays = [ (self: super: { inherit (realPkgs) podman skopeo; }) ];
}
