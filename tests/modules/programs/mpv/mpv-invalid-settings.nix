{ config, lib, pkgs, ... }:

{
  programs.mpv = {
    enable = true;
    package = pkgs.emptyDirectory;
    scripts = [ pkgs.mpvScript ];
  };

  test.stubs = {
    mpv = { extraAttrs.override = { ... }: pkgs.emptyDirectory; };

    mpvScript = { extraAttrs = { scriptName = "something"; }; };
  };

  test.asserts.assertions.expected = [
    ''
      The programs.mpv "package" option is mutually exclusive with "scripts" option.''
  ];
}
