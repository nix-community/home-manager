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
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
      '__hm_entry="/home/hm-user/.local/state/nix/defexpr/50-home-manager"'
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
      '__hm_cur="''${NIX_PATH-}"'
    # Each value must be prepended, not appended. Checked inside that
    # variable's own merge block: on Darwin the terminfo fallback adds a
    # genuine append block elsewhere in the same file.
    grep -B 3 -F 'export NIX_PATH="$__hm_cur"' "$TESTED/home-path/etc/profile.d/hm-session-vars.sh" \
      | grep -qF '__hm_cur="$__hm_add' \
      || fail 'NIX_PATH must be prepended, not appended'
    assertFileContent \
      home-files/.local/state/nix/defexpr/50-home-manager/example/default.nix \
      ${exampleChannel}/default.nix
  '';
}
