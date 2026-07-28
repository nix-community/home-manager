{ config, pkgs, ... }:

let
  exampleChannel = pkgs.writeTextDir "default.nix" ''
    { pkgs ? import <nixpkgs> { } }:

    {
      example = pkgs.emptyDirectory;
    }
  '';
in
{
  nix = {
    package = config.lib.test.mkStubPackage { };
    channels.example = exampleChannel;
  };

  nmt.script = ''
    (
      export NIX_PATH=/inherited
      . "$TESTED/home-path/etc/profile.d/hm-session-vars.sh"
      [ "$NIX_PATH" = "/home/hm-user/.nix-defexpr/50-home-manager:/inherited" ]
    ) || fail "NIX_PATH channel was not prepended"
    assertFileContent \
      home-files/.nix-defexpr/50-home-manager/example/default.nix \
      ${exampleChannel}/default.nix
  '';
}
