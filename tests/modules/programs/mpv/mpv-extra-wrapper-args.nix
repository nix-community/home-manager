{
  lib,
  pkgs,
  ...
}:

{
  imports = [ ./stubs.nix ];

  programs.mpv = {
    enable = true;
    extraMakeWrapperArgs = [
      "--prefix"
      "LD_LIBRARY_PATH"
      ":"
      (lib.makeLibraryPath [
        pkgs.libaacs
        pkgs.libbluray
      ])
    ];
  };

  nmt.script = ''
    mpvbin="home-path/bin/mpv"
    assertFileRegex "$mpvbin" 'LD_LIBRARY_PATH'
  '';
}
