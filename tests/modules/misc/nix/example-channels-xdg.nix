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
      unset __HM_SESS_VARS_SOURCED __HM_SESS_VARS_MERGED
      . "$TESTED/home-path/etc/profile.d/hm-session-vars.sh"
      [ "$NIX_PATH" = "/home/hm-user/.local/state/nix/defexpr/50-home-manager:/inherited" ] \
        || { echo "NIX_PATH: $NIX_PATH"; exit 1; }
    ) || fail "nix.nixPath was not prepended to NIX_PATH"
    assertFileContent \
      home-files/.local/state/nix/defexpr/50-home-manager/example/default.nix \
      ${exampleChannel}/default.nix
  '';
}
