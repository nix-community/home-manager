{ realPkgs, ... }:

{
  nixpkgs.overlays = [
    (_: super: {
      inherit (realPkgs) remarshal;
      python3Packages = super.python3Packages.overrideScope
        (self: super: { inherit (realPkgs.python3Packages) pyyaml; });
    })
  ];
}
