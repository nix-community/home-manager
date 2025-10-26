{ realPkgs, ... }:

{
  nixpkgs.overlays = [
    (_: super: {
      inherit (realPkgs) remarshal;
      python3Packages = super.python3Packages.overrideScope (
        _self: _super: { inherit (realPkgs.python3Packages) pyyaml; }
      );
    })
  ];
}
