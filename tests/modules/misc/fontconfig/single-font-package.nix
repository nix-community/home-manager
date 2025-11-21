{ realPkgs, ... }:

{
  fonts.fontconfig.enable = true;

  # Use `realPkgs` here since the creation of the fontconfig cache relies on the
  # `fc-cache` binary and actual (non-stubbed) fonts.
  test.unstubs = [ (self: super: { inherit (realPkgs) fontconfig; }) ];
  home.packages = [ realPkgs.comic-relief ];

  nmt.script = ''
    assertDirectoryNotEmpty home-path/lib/fontconfig/cache
  '';
}
