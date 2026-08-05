{ realPkgs, ... }:

{
  nixpkgs.overlays = [
    (_: super: {
      buildPackages = super.buildPackages.extend (
        _: _: {
          inherit (realPkgs) check-jsonschema remarshal;
        }
      );
    })
  ];
}
