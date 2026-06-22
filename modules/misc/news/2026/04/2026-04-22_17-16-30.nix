{ pkgs, ... }:

{
  time = "2026-04-22T17:16:30+00:00";
  condition = pkgs.stdenv.hostPlatform.isDarwin;
  message = ''
    A new module is available: 'programs.flashspace'. FlashSpace is
    an open-source, high-performance virtual workspace manager for
    macOS designed to replace or enhance the native macOS "Spaces"
    feature.
  '';
}
