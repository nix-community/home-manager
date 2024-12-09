{ ... }:

{
  nix = {
    registry = {
      nixpkgs = {
        to = {
          type = "github";
          owner = "my-org";
          repo = "my-nixpkgs";
        };
      };
    };
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/nix/registry.json \
      ${./example-registry-expected.json}
  '';
}
