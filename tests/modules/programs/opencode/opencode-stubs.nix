{ realPkgs, ... }:

{
  nixpkgs.overlays = [
    (_: super: {
      buildPackages = super.buildPackages.extend (
        _: _: {
          inherit (realPkgs) check-jsonschema;
        }
      );
    })
  ];

  test.stubs.opencode = {
    extraAttrs.passthru.jsonschema = {
      config = ./config-schema.json;
      tui = ./tui-schema.json;
    };
  };
}
