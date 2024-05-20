{ config, lib, pkgs, ... }:

{
  imports = [ ./mpv-stubs.nix ];

  programs.mpv = {
    enable = true;
    package = pkgs.emptyDirectory;
    scripts = [ pkgs.mpvScript ];
  };

  test.asserts.assertions.expected = [
    ''
      The programs.mpv "package" option is mutually exclusive with "scripts" option.''
  ];
}
