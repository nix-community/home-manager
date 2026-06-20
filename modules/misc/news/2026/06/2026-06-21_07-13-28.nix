{ pkgs, ... }:
{
  time = "2026-06-20T21:13:28+00:00";
  condition = pkgs.stdenv.isDarwin;
  message = ''
    The options `targets.darwin.defaults."com.apple.dock".persistent-apps`
    and `targets.darwin.defaults."com.apple.dock".persistent-others` now
    support shorthand entries for applications, files, folders, and spacers.

    These options configure the macOS Dock declaratively, similarly to
    nix-darwin. Existing native Dock tile dictionaries remain supported.
    Restart the Dock or log out and back in for changes to take effect.
  '';
}
