{
  lib,
  config,
  pkgs,
  ...
}:

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
    package = config.lib.test.mkStubPackage {
      version = lib.getVersion pkgs.nixVersions.stable;
    };
    channels.example = exampleChannel;
    settings.use-xdg-base-directories = true;
  };

  nmt.script = ''
    (
      export NIX_PATH=/inherited
      . "$TESTED/home-path/etc/profile.d/hm-session-vars.sh"
      [ "$NIX_PATH" = "/home/hm-user/.local/state/nix/defexpr/50-home-manager:/inherited" ]
    ) || fail "XDG NIX_PATH channel was not prepended"
    assertFileContent \
      home-files/.local/state/nix/defexpr/50-home-manager/example/default.nix \
      ${exampleChannel}/default.nix
  '';
}
