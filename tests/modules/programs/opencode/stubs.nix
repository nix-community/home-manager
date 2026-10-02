{ pkgs, realPkgs, ... }:

{
  nixpkgs.overlays = [
    (_self: _super: { inherit (realPkgs) check-jsonschema; })
  ];

  test.stubs = {
    opencode = {
      extraAttrs = {
        passthru.jsonschema =
          let
            schemas = pkgs.runCommandLocal "opencode-schemas" { } ''
              install -Dm644 ${./schemas/config.json} $out/config.json
              install -Dm644 ${./schemas/theme.json} $out/theme.json
              install -Dm644 ${./schemas/tui.json} $out/tui.json
            '';
          in
          {
            config = "${schemas}/config.json";
            theme = "${schemas}/theme.json";
            tui = "${schemas}/tui.json";
          };
      };
    };
  };
}
