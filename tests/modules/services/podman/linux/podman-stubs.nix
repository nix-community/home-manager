{ realPkgs, ... }:

{
  nixpkgs.overlays = [ (_self: _super: { inherit (realPkgs) podman skopeo; }) ];
}
