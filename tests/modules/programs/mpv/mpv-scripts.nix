{
  pkgs,
  ...
}:

{
  imports = [ ./stubs.nix ];

  programs.mpv = {
    enable = true;
    scripts = [ pkgs.mpvScript ];
  };

  nmt.script = ''
    mpvbin="home-path/bin/mpv"
    assertFileRegex "$mpvbin" 'script=.*/share/mpv/scripts/mpvScript'
  '';
}
