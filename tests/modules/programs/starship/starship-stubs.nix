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

  test.stubs.starship = {
    extraAttrs.passthru.jsonschema = {
      config = ./config-schema.json;
    };
  };
}
