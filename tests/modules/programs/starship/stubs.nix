{ pkgs, realPkgs, ... }:

{
  nixpkgs.overlays = [
    (_self: _super: { inherit (realPkgs) check-jsonschema; })
  ];

  test.stubs = {
    starship = {
      extraAttrs = {
        passthru.jsonschema =
          let
            schemas = pkgs.runCommandLocal "starship-schemas" { } ''
              install -Dm644 ${./schemas/config.json} $out/config.json
            '';
          in
          {
            config = "${schemas}/config.json";
          };
      };
    };
  };
}
